-- ============================================================================
-- Span-resolved matching in analyze_dream
--
-- Found via stress test: 'ท้อง' (pregnancy, colloquial) matched INSIDE
-- 'ท้องฟ้า' (sky), and 'น้ำ' inside 'รุ้งกินน้ำ' (rainbow) — a dream about the
-- sky reported a pregnancy omen. Substring counting per term was not enough:
-- Thai's lack of word boundaries means shorter terms of OTHER symbols fire
-- inside longer matches.
--
-- Rule now implemented (true longest-match span resolution):
--   * Terms scan longest-first; each counted occurrence CLAIMS its character
--     span.
--   * An occurrence lying STRICTLY inside an already-claimed longer span is
--     suppressed — ท้อง inside ท้องฟ้า no longer fires.
--   * An occurrence whose span EXACTLY EQUALS a claimed span still fires —
--     preserving the deliberate dual mapping where one compound term points
--     at two symbols (ม้านิลมังกร → horse AND dragon).
--   * Consequence accepted and documented: เผือก no longer fires inside
--     งูเผือก/ช้างเผือก (the compound wins); bare สีขาว still fires next to
--     other symbols (นกสีขาว has no compound, so both bird and white match).
-- ============================================================================

create or replace function api.analyze_dream(p_text text)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  norm_text  text;
  rec        record;
  taken_syms uuid[] := '{}';
  claimed    int4range[] := '{}';
  new_spans  int4range[];
  sym_rows   jsonb := '[]'::jsonb;
  sym_count  int := 0;
  cnt        int;
  scan_pos   int;
  hit        int;
  abs_pos    int;
  term_len   int;
  span       int4range;
  headline   text;
  theme      text;
  interps    jsonb;
  nums       jsonb;
  src_count  int;
begin
  norm_text := content.norm_th(coalesce(p_text, ''));
  if length(norm_text) < 4 then
    raise exception 'dream text too short'
      using errcode = 'invalid_parameter_value';
  end if;
  norm_text := left(norm_text, 2000);

  for rec in
    select t.term_norm, t.symbol_id, s.name_th, s.slug
      from content.symbol_term t
      join content.symbol s on s.id = t.symbol_id
     where s.status = 'published'
     order by length(t.term_norm) desc, t.weight desc
  loop
    exit when sym_count >= 8;
    continue when rec.symbol_id = any(taken_syms);

    term_len := length(rec.term_norm);
    cnt := 0;
    scan_pos := 1;
    new_spans := '{}';

    loop
      hit := position(rec.term_norm in substr(norm_text, scan_pos));
      exit when hit = 0;
      abs_pos := scan_pos + hit - 1;
      span := int4range(abs_pos, abs_pos + term_len);

      -- Strictly-inside a longer claimed span → suppressed.
      -- Equal span → allowed (intentional multi-symbol compounds).
      if not exists (
        select 1 from unnest(claimed) c
        where c @> span and (upper(c) - lower(c)) > term_len
      ) then
        cnt := cnt + 1;
        new_spans := new_spans || span;
      end if;

      scan_pos := abs_pos + term_len;  -- non-overlapping same-term repeats
    end loop;

    if cnt > 0 then
      taken_syms := taken_syms || rec.symbol_id;
      sym_count := sym_count + 1;
      claimed := claimed || new_spans;
      sym_rows := sym_rows || jsonb_build_object(
        'nameTh', rec.name_th,
        'count', cnt,
        'slug', rec.slug
      );
    end if;
  end loop;

  if sym_count = 0 then
    insert into ops.api_access (fn, arg_digest, row_count)
    values ('analyze_dream', 'no_match:' || left(norm_text, 40), 0);
    return jsonb_build_object(
      'headlineTh', 'ยังไม่พบสัญลักษณ์ที่รู้จักในคลัง',
      'themeTh', 'ลองเล่าด้วยคำที่เจาะจงขึ้น เช่น สิ่งที่เห็น สัตว์ สถานที่ หรือเหตุการณ์',
      'symbols', '[]'::jsonb,
      'interpretations', '[]'::jsonb,
      'numbers', '[]'::jsonb,
      'sourceCount', 0
    );
  end if;

  select string_agg(x.value ->> 'nameTh', ' • ')
    into headline
    from (select value from jsonb_array_elements(sym_rows) with ordinality o(value, n)
           where o.n <= 3) x;

  select coalesce(jsonb_agg(j), '[]'::jsonb), coalesce(count(distinct j ->> 'sourceId'), 0)
    into interps, src_count
    from (
      select jsonb_build_object(
               'tier', e.tier::text,
               'sourceNameTh', e.label_th,
               'symbolTh', s.name_th,
               'summaryPlainTh', i.summary_plain_th,
               'textTh', i.body_th,
               'sourceId', e.id,
               'locatorTh', p.locator,
               'quoteTh', case
                            when p.work_rights in
                              ('public_domain','cc0','cc_by','cc_by_sa','licensed_permission')
                            then p.original_text_th
                            else null
                          end,
               'contextNoteTh', i.context_note_th
             ) as j
        from content.interpretation i
        join content.symbol  s on s.id = i.symbol_id
        join content.passage p on p.id = i.passage_id
        join content.edition e on e.id = p.edition_id
        left join content.tradition tr on tr.id = i.tradition_id
       where i.symbol_id = any(taken_syms)
         and i.status = 'published'
       order by coalesce(tr.display_rank, 50), e.tier,
                i.prevalence desc nulls last
       limit 12
    ) q;

  select coalesce(
           'ตีความตาม' || string_agg(distinct tr.name_th, ' และ '),
           'พบสัญลักษณ์ในคลัง แต่ยังไม่มีคำแปลที่ผ่านการตรวจแหล่ง')
    into theme
    from content.interpretation i
    join content.tradition tr on tr.id = i.tradition_id
   where i.symbol_id = any(taken_syms) and i.status = 'published';

  select coalesce(jsonb_agg(distinct n.number), '[]'::jsonb)
    into nums
    from content.number_association n
   where n.symbol_id = any(taken_syms) and n.status = 'published';

  insert into ops.api_access (fn, arg_digest, row_count)
  values ('analyze_dream', 'match:' || sym_count, jsonb_array_length(interps));

  return jsonb_build_object(
    'headlineTh', headline,
    'themeTh', theme,
    'symbols', sym_rows,
    'interpretations', interps,
    'numbers', nums,
    'sourceCount', src_count
  );
end $$;
