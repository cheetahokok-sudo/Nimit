-- ============================================================================
-- api.analyze_dream — the core product function
--
-- Takes the user's dream text, returns real interpretations from the library.
-- Deterministic by design and by policy: longest-match against the curated
-- term index, then a join to published interpretations. No generation, ever —
-- generated text has no citation and cannot honestly carry a tier badge.
--
-- Matching rules (documented because they are product behaviour):
--   * Terms are matched longest-first. Per symbol, only its LONGEST matching
--     term counts (งูเผือก suppresses งู for the snake), so counts are not
--     inflated by substrings of themselves.
--   * CROSS-symbol overlaps are deliberately kept: ม้านิลมังกร surfaces both
--     horse and dragon — for hybrid creatures that is correct behaviour, not
--     a collision.
--   * Thai needs no word segmentation here: we only ever look for terms we
--     curate, and substring semantics suit Thai morphology (ดำน้ำ contains
--     น้ำ legitimately).
--
-- Access: anon MAY execute. This deliberately differs from get_symbol
-- (authenticated-only): analyze is the product's front door and the app has
-- no auth until Phase A4. The exposure is bounded — results only cover
-- symbols present in the caller's own text, the response is capped, input
-- length is capped, and calls are logged to ops.api_access. get_symbol stays
-- gated because slug-walking enumerates the library; analyze does not.
--
-- Honesty guarantees in the response:
--   * themeTh names the TRADITIONS the interpretations come from — never an
--     invented "meaning of your dream".
--   * numbers[] comes only from published number_association rows. With only
--     Buddhist-canon content loaded this is EMPTY — correct, per the
--     permanent no-numbers-from-canon policy.
--   * Unmatched text yields an honest empty result, not a guess.
-- ============================================================================

create or replace function api.analyze_dream(p_text text)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  norm_text  text;
  rec        record;
  taken_syms uuid[] := '{}';
  sym_rows   jsonb := '[]'::jsonb;
  sym_count  int := 0;
  occurrences int;
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
  -- Cap input: beyond this length matching cost grows for no product benefit.
  norm_text := left(norm_text, 2000);

  -- Longest-first scan; first (longest) hit per symbol wins.
  for rec in
    select t.term, t.term_norm, t.symbol_id, s.name_th, s.slug
      from content.symbol_term t
      join content.symbol s on s.id = t.symbol_id
     where s.status = 'published'
     order by length(t.term_norm) desc, t.weight desc
  loop
    exit when sym_count >= 8;
    continue when rec.symbol_id = any(taken_syms);
    if position(rec.term_norm in norm_text) > 0 then
      occurrences :=
        (length(norm_text) - length(replace(norm_text, rec.term_norm, '')))
        / length(rec.term_norm);
      taken_syms := taken_syms || rec.symbol_id;
      sym_count := sym_count + 1;
      sym_rows := sym_rows || jsonb_build_object(
        'nameTh', rec.name_th,
        'count', occurrences,
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

  -- Headline: up to three matched symbol names, in match order.
  select string_agg(x.value ->> 'nameTh', ' • ')
    into headline
    from (select value from jsonb_array_elements(sym_rows) with ordinality o(value, n)
           where o.n <= 3) x;

  -- Interpretations for the matched symbols, best tier first, capped.
  select coalesce(jsonb_agg(j), '[]'::jsonb), coalesce(count(distinct j ->> 'sourceId'), 0)
    into interps, src_count
    from (
      select jsonb_build_object(
               'tier', e.tier::text,
               'sourceNameTh', e.label_th,
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
        join content.passage p on p.id = i.passage_id
        join content.edition e on e.id = p.edition_id
       where i.symbol_id = any(taken_syms)
         and i.status = 'published'
       order by e.tier, i.prevalence desc nulls last
       limit 12
    ) q;

  -- The theme is WHERE the readings come from, never what the dream "means".
  select coalesce(
           'ตีความตาม' || string_agg(distinct tr.name_th, ' และ '),
           'พบสัญลักษณ์ในคลัง แต่ยังไม่มีคำแปลที่ผ่านการตรวจแหล่ง')
    into theme
    from content.interpretation i
    join content.tradition tr on tr.id = i.tradition_id
   where i.symbol_id = any(taken_syms) and i.status = 'published';

  -- Symbolic numbers: only from published associations. Empty is honest.
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

revoke execute on function api.analyze_dream(text) from public;
grant execute on function api.analyze_dream(text) to anon, authenticated;
