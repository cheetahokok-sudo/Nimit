-- ============================================================================
-- The lottery API surface
--
-- WHY FUNCTIONS AND NOT VIEWS. supabase/config.toml sets max_rows = 100. A
-- draw is 173 numbers. Exposing lottery.result as a PostgREST view would return
-- the first 100 and silently drop 73 — and the 73 dropped are the tail of
-- รางวัลที่ 4 and รางวัลที่ 5, so roughly 150 real winners per งวด would be told
-- they lost. A function returning jsonb is one row and is immune to the cap.
--
-- READ FUNCTIONS ARE `stable` AND MUST NOT WRITE. api.get_symbol was once
-- declared stable while INSERTing an access-log row, which made it fail with
-- SQLSTATE 0A000 for every legitimate caller while the tests still passed
-- (they only asserted ACLs, and the probe hit the 401 gate first). Nothing here
-- logs. The suite additionally EXECUTES each read path rather than only
-- checking who may call it.
--
-- THE WRITE SURFACE IS EXACTLY ONE FUNCTION. api.lottery_ingest is security
-- definer and granted only to service_role, so the lottery schema needs no
-- table grants for anyone. A leaked service key can insert draw results and
-- nothing else.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- lottery.next_draw_estimate
--
-- GLO's API does not publish future draw dates — the payload carries the งวด
-- being announced and nothing further ahead. So a "next draw" is either a row
-- we already hold, or an ESTIMATE from the 1st/16th convention.
--
-- The convention is not reliable: GLO moves draws (1 ม.ค. is drawn in late
-- ธ.ค.; 16 พ.ค. 2568 was drawn 2 พ.ค.). Rather than let the client do this
-- arithmetic and present the answer as fact, the estimate is computed here and
-- returned WITH a flag saying it is an estimate, so the UI can say
-- "โดยประมาณ" and be honest about what it knows.
-- ---------------------------------------------------------------------------

create or replace function lottery.next_draw_estimate(p_after date)
returns date
language sql immutable set search_path = '' as $$
  select case
           when extract(day from p_after) < 16
             then make_date(extract(year from p_after)::int, extract(month from p_after)::int, 16)
           else (date_trunc('month', p_after::timestamp) + interval '1 month')::date
         end;
$$;

-- ---------------------------------------------------------------------------
-- api.lottery_ingest — the only write path
--
-- Handles BOTH envelopes the source uses, which are genuinely different and
-- were confirmed by probing rather than from documentation:
--   getLatestLottery   -> response.data
--   getLotteryResult   -> response.result.data   (plus response.responseStatus)
-- A date with no draw returns response = null. That is an ANSWER, not a
-- failure, and the backfill hits it often — it reports outcome 'no_draw'.
-- ---------------------------------------------------------------------------

create or replace function api.lottery_ingest(
  p_payload     jsonb,
  p_endpoint    text default 'unknown',
  p_http_status int  default null,
  p_run         text default null
) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  v_raw_id      bigint;
  v_root        jsonb;
  v_tiers       jsonb;
  v_date        date;
  v_periods     int[];
  v_source_id   uuid;
  v_draw_id     uuid;
  v_prev_status lottery.draw_status;
  v_prev_rev    int;
  v_prev_hash   text;
  v_new_hash    text;
  v_bad         int;
  v_full_tiers  int;
  v_total       int;
  v_first_ok    boolean;
  v_status      lottery.draw_status;
  v_outcome     text;
  v_reason      text;
begin
  -- STEP 1 — retain the payload unconditionally, before any judgement about it.
  insert into lottery.raw_payload
    (endpoint, response, http_status, payload_sha256, workflow_run, ok)
  values
    (coalesce(p_endpoint, 'unknown'),
     coalesce(p_payload, 'null'::jsonb),
     p_http_status,
     encode(sha256(convert_to(coalesce(p_payload, 'null'::jsonb)::text, 'UTF8')), 'hex'),
     p_run,
     false)
  returning id into v_raw_id;

  -- STEP 2 — validate. NOTE THE `return`: this function must never `raise` on
  -- bad input. A raise rolls back the transaction, which would discard the raw
  -- payload inserted above — precisely the payload worth keeping when the shape
  -- has changed. Raising is reserved for programmer error. The suite asserts a
  -- failed parse still leaves its raw row behind.
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    v_reason := 'payload ไม่ใช่ JSON object';
    update lottery.raw_payload set reason_th = v_reason where id = v_raw_id;
    return jsonb_build_object('ok', false, 'outcome', 'invalid', 'reasonTh', v_reason);
  end if;

  -- Both envelopes, preferring the nested one.
  if jsonb_typeof(p_payload #> '{response,result}') = 'object' then
    v_root := p_payload #> '{response,result}';
  elsif jsonb_typeof(p_payload -> 'response') = 'object' then
    v_root := p_payload -> 'response';
  elsif p_payload ? 'response' and jsonb_typeof(p_payload -> 'response') = 'null' then
    -- response: null — the source's way of saying "no draw on that date". A
    -- legitimate answer, hit often during backfill, and NOT a failure.
    v_reason := 'ไม่มีงวดในวันที่ร้องขอ';
    update lottery.raw_payload set ok = true, reason_th = v_reason where id = v_raw_id;
    return jsonb_build_object('ok', true, 'outcome', 'no_draw', 'reasonTh', v_reason);
  else
    -- No `response` key at all, or one that is neither object nor null. This is
    -- a SHAPE CHANGE, not an empty date, and the two must not be conflated:
    -- treating it as 'no_draw' would let a GLO redesign report "no draw" for
    -- every date in a backfill while the workflow stayed green.
    v_reason := 'payload ไม่มีคีย์ response ตามรูปแบบที่รู้จัก — โครงสร้างต้นทางอาจเปลี่ยน';
    update lottery.raw_payload set reason_th = v_reason where id = v_raw_id;
    return jsonb_build_object('ok', false, 'outcome', 'invalid', 'reasonTh', v_reason);
  end if;

  v_tiers := v_root -> 'data';
  begin
    v_date := (v_root ->> 'date')::date;
  exception when others then
    v_date := null;
  end;

  if v_date is null then
    v_reason := 'ไม่พบวันที่ของงวดใน payload';
    update lottery.raw_payload set reason_th = v_reason where id = v_raw_id;
    return jsonb_build_object('ok', false, 'outcome', 'invalid', 'reasonTh', v_reason);
  end if;

  if jsonb_typeof(v_tiers) <> 'object' then
    v_reason := 'ไม่พบชุดข้อมูลรางวัล (data) ใน payload';
    update lottery.raw_payload set reason_th = v_reason where id = v_raw_id;
    return jsonb_build_object('ok', false, 'outcome', 'invalid',
                              'drawDate', v_date, 'reasonTh', v_reason);
  end if;

  -- STEP 3 — malformed numbers abort BEFORE any insert. If they reached the
  -- table the CHECK would raise, rolling back the raw payload with it.
  select count(*) into v_bad
    from lottery.prize_tier pt
    cross join lateral jsonb_array_elements(
      case when jsonb_typeof(v_tiers -> pt.glo_key -> 'number') = 'array'
           then v_tiers -> pt.glo_key -> 'number' else '[]'::jsonb end) e
   where pt.effective_to is null
     and ( (e ->> 'value') is null
        or (e ->> 'value') !~ '^[0-9]+$'
        or length(e ->> 'value') <> case pt.match_kind
             when 'exact6'  then 6
             when 'prefix3' then 3
             when 'suffix3' then 3
             else 2 end );

  if v_bad > 0 then
    v_reason := format('พบเลขรางวัลผิดรูปแบบ %s รายการ', v_bad);
    update lottery.raw_payload set reason_th = v_reason where id = v_raw_id;
    return jsonb_build_object('ok', false, 'outcome', 'invalid',
                              'drawDate', v_date, 'reasonTh', v_reason);
  end if;

  -- STEP 4 — how complete is this payload?
  select
    count(*) filter (
      where jsonb_typeof(v_tiers -> pt.glo_key -> 'number') = 'array'
        and jsonb_array_length(v_tiers -> pt.glo_key -> 'number') = pt.winner_count),
    coalesce(sum(
      case when jsonb_typeof(v_tiers -> pt.glo_key -> 'number') = 'array'
           then jsonb_array_length(v_tiers -> pt.glo_key -> 'number') else 0 end), 0)
    into v_full_tiers, v_total
    from lottery.prize_tier pt
   where pt.effective_to is null;

  v_first_ok := jsonb_typeof(v_tiers -> 'first' -> 'number') = 'array'
                and jsonb_array_length(v_tiers -> 'first' -> 'number') = 1;

  if v_full_tiers = 9 and v_total = 173 then
    v_status := 'announced'; v_outcome := 'announced';
  elsif v_first_ok then
    -- Mid-announcement. Store what exists so the app can show รางวัลที่ 1, but
    -- never flip to announced: api.lottery_draw filters on announced, so a
    -- ticket is never checked against an incomplete draw.
    v_status := 'partial';   v_outcome := 'partial';
  else
    v_status := 'scheduled'; v_outcome := 'scheduled';
  end if;

  select id into v_source_id from lottery.source_registration where citekey = 'glo-api';
  if v_source_id is null then
    v_reason := 'ยังไม่ได้ลงทะเบียนแหล่งข้อมูล glo-api (ต้องรัน seed ก่อน)';
    update lottery.raw_payload set reason_th = v_reason where id = v_raw_id;
    return jsonb_build_object('ok', false, 'outcome', 'invalid', 'reasonTh', v_reason);
  end if;

  if jsonb_typeof(v_root -> 'period') = 'array' then
    select array_agg(x::int) into v_periods
      from jsonb_array_elements_text(v_root -> 'period') x
     where x ~ '^[0-9]+$';
  end if;

  select status, result_revision into v_prev_status, v_prev_rev
    from lottery.draw where draw_date = v_date;

  select md5(coalesce(string_agg(tier_code || ':' || number, ',' order by tier_code, number), ''))
    into v_prev_hash
    from lottery.result r join lottery.draw d on d.id = r.draw_id
   where d.draw_date = v_date;

  insert into lottery.draw
    (draw_date, period_nos, status, announced_at, pdf_url, youtube_url, source_id)
  values
    (v_date, v_periods, v_status,
     case when v_status = 'announced' then now() else null end,
     v_root ->> 'pdf_url', v_root ->> 'youtube_url', v_source_id)
  on conflict (draw_date) do update set
    period_nos   = coalesce(excluded.period_nos, lottery.draw.period_nos),
    -- Never regress an announced draw to a lesser state on a later poll.
    status       = case when lottery.draw.status = 'announced' and excluded.status <> 'announced'
                        then lottery.draw.status else excluded.status end,
    announced_at = coalesce(lottery.draw.announced_at, excluded.announced_at),
    pdf_url      = coalesce(excluded.pdf_url, lottery.draw.pdf_url),
    youtube_url  = coalesce(excluded.youtube_url, lottery.draw.youtube_url),
    updated_at   = now()
  returning id into v_draw_id;

  -- STEP 5 — replace the result set wholesale, in this same transaction, so no
  -- window exists in which a draw is half-populated.
  delete from lottery.result where draw_id = v_draw_id;

  insert into lottery.result (draw_id, tier_code, match_kind, number, ordinal)
  select v_draw_id, pt.code, pt.match_kind, e.value ->> 'value', e.ord::int
    from lottery.prize_tier pt
    cross join lateral jsonb_array_elements(
      case when jsonb_typeof(v_tiers -> pt.glo_key -> 'number') = 'array'
           then v_tiers -> pt.glo_key -> 'number' else '[]'::jsonb end)
      with ordinality as e(value, ord)
   where pt.effective_to is null
  on conflict (draw_id, tier_code, number) do nothing;

  select md5(coalesce(string_agg(tier_code || ':' || number, ',' order by tier_code, number), ''))
    into v_new_hash from lottery.result where draw_id = v_draw_id;

  -- A correction to an already-published result bumps the revision so a client
  -- can invalidate a figure it has already shown someone.
  if v_prev_status = 'announced' and v_prev_hash is distinct from v_new_hash then
    update lottery.draw
       set result_revision = result_revision + 1, updated_at = now()
     where id = v_draw_id;
  end if;

  select count(*) into v_total from lottery.result where draw_id = v_draw_id;

  update lottery.raw_payload
     set ok = true, draw_id = v_draw_id, reason_th = null
   where id = v_raw_id;

  return jsonb_build_object(
    'ok', true,
    'outcome', v_outcome,
    'drawDate', v_date,
    'numbers', v_total,
    'revision', coalesce((select result_revision from lottery.draw where id = v_draw_id), 0));
end $$;

-- ---------------------------------------------------------------------------
-- Shared builder for a draw object
-- ---------------------------------------------------------------------------

-- Buddhist-era date in Thai, so the label the app shows and the label an
-- operator sees in SQL are produced by the same code. Defined before its
-- callers: SQL function bodies are parsed at creation time.
create or replace function lottery.thai_date(p_date date)
returns text
language sql immutable set search_path = '' as $$
  select extract(day from p_date)::int::text || ' ' ||
         (array['มกราคม','กุมภาพันธ์','มีนาคม','เมษายน','พฤษภาคม','มิถุนายน',
                'กรกฎาคม','สิงหาคม','กันยายน','ตุลาคม','พฤศจิกายน','ธันวาคม'])
           [extract(month from p_date)::int] || ' ' ||
         (extract(year from p_date)::int + 543)::text;
$$;

create or replace function lottery.draw_json(p_draw_id uuid)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'drawDate',        d.draw_date,
    'periodLabelTh',   'งวดวันที่ ' || lottery.thai_date(d.draw_date),
    'status',          d.status::text,
    -- draw.announced_at is deliberately NOT emitted. It records when WE first
    -- saw the draw announced, which for a backfilled งวด is the day of the
    -- backfill — publishing it as "ประกาศเมื่อ" would state a falsehood about a
    -- 2024 draw. GLO does not give us its announcement timestamp, so the app
    -- shows the draw DATE, which we do know.
    'resultRevision',  d.result_revision,
    'pdfUrl',          d.pdf_url,
    -- Computed HERE, never in the client: it is the gate that decides whether
    -- the words "ไม่ถูกรางวัล" may be rendered at all.
    'complete',        (select count(*) from lottery.result r where r.draw_id = d.id)
                       = (select sum(winner_count) from lottery.prize_tier where effective_to is null),
    'dutyRate',        (select max(duty_rate) from lottery.prize_tier where effective_to is null),
    'source', jsonb_build_object(
      'custodianTh', s.custodian_th,
      'url',         s.api_url,
      'licenceTh',   s.licence_note_th,
      'retrievedAt', d.updated_at),
    'prizes', coalesce((
      select jsonb_agg(jsonb_build_object(
               'code',        pt.code,
               'nameTh',      pt.name_th,
               'shortNameTh', pt.short_name_th,
               'amountThb',   pt.amount_thb,
               'winnerCount', pt.winner_count,
               'matchKind',   pt.match_kind::text,
               'sort',        pt.sort,
               'numbers',     coalesce((
                 select jsonb_agg(r.number order by r.ordinal)
                   from lottery.result r
                  where r.draw_id = d.id and r.tier_code = pt.code), '[]'::jsonb))
             order by pt.sort)
        from lottery.prize_tier pt where pt.effective_to is null), '[]'::jsonb),
    'nextDrawDate', coalesce(
      (select min(d2.draw_date) from lottery.draw d2 where d2.draw_date > d.draw_date),
      lottery.next_draw_estimate(d.draw_date)),
    'nextDrawEstimated', not exists (
      select 1 from lottery.draw d2 where d2.draw_date > d.draw_date)
  )
  from lottery.draw d
  join lottery.source_registration s on s.id = d.source_id
  where d.id = p_draw_id;
$$;

-- ---------------------------------------------------------------------------
-- Read functions
-- ---------------------------------------------------------------------------

-- Null argument = the latest ANNOUNCED draw. A partial or scheduled row can
-- never be returned by the null form, so a ticket is never checked against an
-- incomplete result set. An explicit date returns whatever exists, with its
-- status in the payload for the client to gate on.
create or replace function api.lottery_draw(p_draw_date date default null)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_id uuid;
begin
  if p_draw_date is null then
    select id into v_id from lottery.draw
     where status = 'announced' order by draw_date desc limit 1;
  else
    select id into v_id from lottery.draw where draw_date = p_draw_date;
  end if;

  if v_id is null then
    return null;
  end if;
  return lottery.draw_json(v_id);
end $$;

create or replace function api.lottery_recent_draws(p_limit int default 12)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(lottery.draw_json(t.id) order by t.draw_date desc), '[]'::jsonb)
    from (select id, draw_date from lottery.draw
           where status = 'announced'
           order by draw_date desc
           limit least(greatest(coalesce(p_limit, 12), 1), 24)) t;
$$;

-- Separate from lottery_draw because it must answer even when no result exists
-- — that is exactly the state the banner needs to render before an announcement.
create or replace function api.lottery_calendar(p_limit int default 4)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'today', (now() at time zone 'Asia/Bangkok')::date,
    'latestAnnounced', (select max(draw_date) from lottery.draw where status = 'announced'),
    'nextEstimated', lottery.next_draw_estimate((now() at time zone 'Asia/Bangkok')::date),
    'draws', coalesce((
      select jsonb_agg(jsonb_build_object(
               'drawDate', d.draw_date,
               'labelTh',  'งวดวันที่ ' || lottery.thai_date(d.draw_date),
               'status',   d.status::text)
             order by d.draw_date desc)
        from (select draw_date, status from lottery.draw
               order by draw_date desc
               limit least(greatest(coalesce(p_limit, 4), 1), 24)) d), '[]'::jsonb));
$$;

-- ---------------------------------------------------------------------------
-- api.lottery_digit_stats
--
-- Computed on the fly. The widest window a caller can ask for is 120 draws =
-- ~20,000 indexed rows, which is milliseconds. A materialized view would buy
-- nothing measurable and introduce a refresh path that can go stale — and stale
-- statistics in a product whose pitch is verifiable data is a worse failure
-- than a slow query.
--
-- Deliberately NO 3-digit frequency table. เลขหน้า and เลขท้าย 3 ตัว supply four
-- samples per draw against 1,000 buckets; over 24 draws every bucket is 0 or 1.
-- That is noise, and rendering it as "สถิติ" would dress it up as signal.
--
-- noteTh is served from here rather than written in Dart so the UI cannot show
-- the statistics without also showing the caveat — they arrive in one object.
-- ---------------------------------------------------------------------------

create or replace function api.lottery_digit_stats(p_window int default 24)
returns jsonb
language sql stable security definer set search_path = '' as $$
  with w as (
    select id, draw_date from lottery.draw
     where status = 'announced'
     order by draw_date desc
     limit least(greatest(coalesce(p_window, 24), 1), 120)
  ),
  last2 as (
    select r.number, count(*)::int as c, max(d.draw_date) as last_seen
      from lottery.result r
      join w d on d.id = r.draw_id
     where r.tier_code = 'last2'
     group by r.number
  ),
  buckets as (
    select lpad(i::text, 2, '0') as n,
           coalesce(l.c, 0) as c,
           l.last_seen
      from generate_series(0, 99) i
      left join last2 l on l.number = lpad(i::text, 2, '0')
  ),
  firsts as (
    select r.number from lottery.result r join w d on d.id = r.draw_id
     where r.tier_code = 'first'
  ),
  positions as (
    select p.pos,
           jsonb_agg(jsonb_build_object('d', dg.d, 'count', coalesce(c.c, 0))
                     order by dg.d) as digits
      from generate_series(1, 6) p(pos)
      cross join generate_series(0, 9) dg(d)
      left join lateral (
        select count(*)::int as c from firsts f
         where substring(f.number from p.pos for 1) = dg.d::text) c on true
     group by p.pos
  )
  select jsonb_build_object(
    'windowDraws',  (select count(*) from w),
    'fromDate',     (select min(draw_date) from w),
    'toDate',       (select max(draw_date) from w),
    -- Every bucket is emitted, including zeros. A missing bucket is ambiguous
    -- between "never drawn" and "the query is broken"; an explicit 0 is not.
    'last2', (select jsonb_agg(jsonb_build_object(
                       'n', n, 'count', c, 'lastSeenDate', last_seen) order by n)
                from buckets),
    'positionDigits', (select jsonb_agg(jsonb_build_object(
                                'position', pos, 'digits', digits) order by pos)
                         from positions),
    'neverSeenLast2', (select count(*) from buckets where c = 0),
    'noteTh', 'สถิติคือสิ่งที่เคยออกมาแล้ว ไม่ใช่สิ่งที่จะออกงวดหน้า '
              'การออกรางวัลแต่ละงวดสุ่มใหม่ทั้งหมด ทุกเลขมีโอกาสเท่ากันเสมอ',
    'sourceTh', 'คำนวณจากผลรางวัลทางการของสำนักงานสลากกินแบ่งรัฐบาล'
  );
$$;

-- ---------------------------------------------------------------------------
-- Grants
--
-- PUBLIC first. `revoke ... from anon` alone does nothing here: PostgreSQL
-- grants EXECUTE on new functions to PUBLIC by default and anon inherits it.
-- That exact mistake once left api.get_symbol callable by anon while a test
-- asserted the opposite.
-- ---------------------------------------------------------------------------

revoke execute on function api.lottery_ingest(jsonb, text, int, text) from public;
revoke execute on function api.lottery_draw(date)          from public;
revoke execute on function api.lottery_recent_draws(int)   from public;
revoke execute on function api.lottery_calendar(int)       from public;
revoke execute on function api.lottery_digit_stats(int)    from public;
revoke execute on function lottery.draw_json(uuid)         from public;
revoke execute on function lottery.thai_date(date)         from public;
revoke execute on function lottery.next_draw_estimate(date) from public;
revoke execute on function lottery.prune_raw_payload(int)  from public;

-- Public facts published by a government agency: readable without a session,
-- on the same reasoning as api.cite. Withholding them would be theatre.
grant execute on function api.lottery_draw(date)        to anon, authenticated;
grant execute on function api.lottery_recent_draws(int) to anon, authenticated;
grant execute on function api.lottery_calendar(int)     to anon, authenticated;
grant execute on function api.lottery_digit_stats(int)  to anon, authenticated;

-- The single write path.
grant execute on function api.lottery_ingest(jsonb, text, int, text) to service_role;

comment on function api.lottery_ingest(jsonb, text, int, text) is
  'Sole write path into the lottery schema. service_role only. Retains every '
  'payload in lottery.raw_payload BEFORE validating, and returns {ok:false} '
  'rather than raising on bad input so that retention survives a parse failure.';
