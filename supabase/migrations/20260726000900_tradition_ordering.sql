-- ============================================================================
-- Presentation order: folk-belief and astrology traditions lead; the Buddhist
-- canon becomes the depth layer.
--
-- Product direction: this app's register is ความขลัง ความศรัทธา ความเชื่อ
-- ดวงชะตา — users come for นิมิต and ลิขิต, not doctrine lessons. The canon
-- entries were the FIRST content only because they were the first
-- rights-cleared source; they remain valuable, honestly labelled depth. But
-- when a symbol has readings from both a folk/astrology ตำรา and the canon,
-- the ตำรา reading must lead.
--
-- Implemented as an explicit display_rank per tradition (not hardcoded slug
-- checks scattered through queries), so adding พรหมชาติ or จักรทีปนี content
-- later slots in without another migration.
--
-- Honesty unchanged: nothing is hidden or relabelled — the canon entries keep
-- their tradition label and citations, they just don't open the show.
-- ============================================================================

alter table content.tradition
  add column if not exists display_rank smallint not null default 50;

comment on column content.tradition.display_rank is
  'Presentation priority (lower = shown first). Folk-belief and astrology '
  'traditions lead; Buddhist canon renders last as the depth layer. Ordering '
  'only — labels and citations are never altered by rank.';

update content.tradition set display_rank = v.rank
from (values
  ('folk-central',   10),
  ('brahmajati',     20),
  ('taksa',          30),
  ('chakkathipani',  30),
  ('lanna',          40),
  ('buddhist-canon', 90)
) as v(slug, rank)
where content.tradition.slug = v.slug;

-- ---------------------------------------------------------------------------
-- analyze_dream: order interpretations by tradition rank, then tier
-- ---------------------------------------------------------------------------

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
  norm_text := left(norm_text, 2000);

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
