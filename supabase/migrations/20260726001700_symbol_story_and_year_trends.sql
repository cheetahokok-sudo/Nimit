-- ============================================================================
-- Two read paths the product has been missing: the symbol story, and a กระแส
-- built on real draws instead of invented community numbers.
--
-- WHY THIS REPLACES A FABRICATION
--
-- The กระแส tab shipped mock data to production — a trending symbol at "+38%",
-- four numbers with mention counts, and a caption claiming the figures came
-- from public posts and in-app searches. None of it existed. For a lottery
-- audience, numbers presented with counts read as consensus and get bought.
--
-- Real community trends need user data the app deliberately does not collect
-- (the journal is local, there is no auth), so they cannot exist before the
-- consent work. What CAN exist is the year of GLO draws already ingested, and
-- the library already built — and joining them is more interesting than the
-- fiction was: a number that really came out, and what the ตำรา say it means.
--
-- THE JOIN THAT MAKES IT WORK. เลขท้าย 2 ตัว is two digits. The numbers ตำรา
-- assign to symbols are two digits. So "45 came out twice this year" and
-- "ตำราว่า 45 คือ กุ้ง" are the same key, with no interpretation needed to
-- connect them.
--
-- BOTH FUNCTIONS ARE anon-CALLABLE. api.get_symbol stays authenticated-only:
-- it is the bulk-detail endpoint whose enumeration the RPC design guards
-- against. api.symbol_story is a narrower, single-slug read that the browse UI
-- needs, and withholding it would only prevent honest use — the same reasoning
-- migration 000300 already applied to api.cite.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- api.symbol_story — everything the story screen renders, in one call
-- ---------------------------------------------------------------------------

create or replace function api.symbol_story(p_slug text)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'slug',        s.slug,
    'conceptKey',  s.concept_key,
    'nameTh',      s.name_th,
    'nameEn',      s.name_en,
    'category',    c.name_th,
    'summaryTh',   s.summary_th,
    'ethicsNoteTh', s.ethics_note_th,

    -- Published only. Draft numbers must never surface here any more than they
    -- do through analyze_dream.
    'numbers', coalesce((
      select jsonb_agg(distinct n.number order by n.number)
        from content.number_association n
       where n.symbol_id = s.id and n.status = 'published'), '[]'::jsonb),

    'readings', coalesce((
      select jsonb_agg(jsonb_build_object(
               'tier',        e.tier::text,
               'workTh',      w.canonical_title_th,
               'sourceTh',    e.label_th,
               'custodianTh', e.custodian_th,
               'locatorTh',   p.locator,
               'bodyTh',      i.body_th,
               'plainTh',     i.summary_plain_th,
               'traditionTh', tr.name_th,
               'claimType',   i.claim_type::text,
               'contextNoteTh', i.context_note_th,
               -- Verbatim only where the work is free. The client never
               -- decides what may lawfully be shown.
               'quoteTh', case
                            when w.rights in ('public_domain','cc0','cc_by',
                                              'cc_by_sa','licensed_permission')
                            then p.original_text_th else null end)
             order by e.tier, i.prevalence desc nulls last)
        from content.interpretation i
        join content.passage p on p.id = i.passage_id
        join content.edition e on e.id = p.edition_id
        join content.work    w on w.id = e.work_id
        left join content.tradition tr on tr.id = i.tradition_id
       where i.symbol_id = s.id and i.status = 'published'), '[]'::jsonb),

    'related', coalesce((
      select jsonb_agg(jsonb_build_object(
               'slug', r2.slug, 'nameTh', r2.name_th, 'kind', rel.kind::text))
        from content.symbol_relation rel
        join content.symbol r2 on r2.id = rel.related_id
       where rel.symbol_id = s.id and r2.status = 'published'), '[]'::jsonb),

    -- The reverse direction too, so a general symbol lists its specifics —
    -- นก should offer นกยูง, นกกระเรียน and the rest.
    'narrower', coalesce((
      select jsonb_agg(jsonb_build_object('slug', r3.slug, 'nameTh', r3.name_th))
        from content.symbol_relation rel
        join content.symbol r3 on r3.id = rel.symbol_id
       where rel.related_id = s.id and rel.kind = 'narrower'
         and r3.status = 'published'), '[]'::jsonb)
  )
  from content.symbol s
  join content.category c on c.id = s.category_id
  where s.slug = p_slug and s.status = 'published';
$$;

-- ---------------------------------------------------------------------------
-- api.lottery_year_trends — what actually came out, and what ตำรา say it means
-- ---------------------------------------------------------------------------

create or replace function api.lottery_year_trends(p_window int default 24)
returns jsonb
language sql stable security definer set search_path = '' as $$
  with w as (
    select id, draw_date from lottery.draw
     where status = 'announced'
     order by draw_date desc
     limit least(greatest(coalesce(p_window, 24), 1), 120)
  ),
  drawn as (
    select r.number, count(*)::int as times, max(d.draw_date) as last_seen
      from lottery.result r
      join w d on d.id = r.draw_id
     where r.tier_code = 'last2'
     group by r.number
  ),
  ranked as (
    select drawn.*,
      -- Symbols the ตำรา tie to this number. Empty is common and honest: the
      -- library covers 52 of 100 two-digit numbers so far.
      coalesce((
        select jsonb_agg(jsonb_build_object(
                 'slug', s.slug, 'nameTh', s.name_th,
                 'plainTh', (select i.summary_plain_th
                               from content.interpretation i
                              where i.symbol_id = s.id and i.status='published'
                              order by i.prevalence desc nulls last limit 1))
               order by s.name_th)
          from content.number_association n
          join content.symbol s on s.id = n.symbol_id
         where n.number = drawn.number and n.status = 'published'
           and s.status = 'published'), '[]'::jsonb) as symbols
    from drawn
  )
  select jsonb_build_object(
    'windowDraws', (select count(*) from w),
    'fromDate',    (select min(draw_date) from w),
    'toDate',      (select max(draw_date) from w),
    'drawn', coalesce((
      select jsonb_agg(jsonb_build_object(
               'number', number, 'times', times,
               'lastSeen', last_seen, 'symbols', symbols)
             order by times desc, last_seen desc)
        from ranked), '[]'::jsonb),
    'coveredByLibrary', (select count(*) from ranked
                          where jsonb_array_length(symbols) > 0),
    -- Served with the data, so the screen cannot show frequencies without it.
    'noteTh', 'นี่คือเลขที่ออกจริงในรอบปีที่ผ่านมา ไม่ใช่การทำนายงวดหน้า '
              'การออกรางวัลแต่ละงวดสุ่มใหม่ทั้งหมด และความหมายจากตำราเป็นความเชื่อ '
              'ไม่ได้เพิ่มโอกาสถูกรางวัล'
  );
$$;

revoke execute on function api.symbol_story(text)        from public;
revoke execute on function api.lottery_year_trends(int)  from public;
grant  execute on function api.symbol_story(text)        to anon, authenticated;
grant  execute on function api.lottery_year_trends(int)  to anon, authenticated;

comment on function api.lottery_year_trends(int) is
  'Real เลขท้าย 2 ตัว frequency over a window of announced draws, each number '
  'joined to the symbols ตำรา assign it. Replaces fabricated community trend '
  'data; carries its own randomness caveat so the UI cannot omit it.';
