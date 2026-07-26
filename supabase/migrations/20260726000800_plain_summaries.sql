-- ============================================================================
-- Plain-language summaries (ภาษาชาวบ้าน) on interpretations
--
-- Product finding from the target audience: the core users — lottery players,
-- provincial readers — want the point in ONE OR TWO LINES first. Scholarly
-- prose up front loses them; anything past two lines goes unread. So every
-- interpretation gains a plain-language summary that renders FIRST, with the
-- full cited text below for readers who want depth.
--
-- The honesty rule is unchanged: summary_plain_th is EDITORIAL TEXT — a
-- human-reviewed compression of our own body_th, carrying the same citation
-- and the same review discipline. It is never generated at runtime; a
-- runtime-generated sentence has no citation and cannot carry a tier badge.
-- ============================================================================

alter table content.interpretation
  add column if not exists summary_plain_th text;

comment on column content.interpretation.summary_plain_th is
  'ภาษาชาวบ้าน: editorial one-to-two-line compression of body_th for readers '
  'who will not read long prose. Same authorship and review rules as body_th '
  '(never machine-generated at runtime), same citation. Aim <= ~90 Thai chars.';

-- ---------------------------------------------------------------------------
-- analyze_dream: emit summaryPlainTh and symbolTh (the UI groups the plain
-- lines by symbol name)
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
       where i.symbol_id = any(taken_syms)
         and i.status = 'published'
       order by e.tier, i.prevalence desc nulls last
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

-- ---------------------------------------------------------------------------
-- get_symbol: same field for the future library browser
-- ---------------------------------------------------------------------------

create or replace function api.get_symbol(p_slug text)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  result jsonb;
begin
  select jsonb_build_object(
    'slug', s.slug,
    'conceptKey', s.concept_key,
    'nameTh', s.name_th,
    'nameEn', s.name_en,
    'category', c.name_th,
    'summaryTh', s.summary_th,
    'ethicsNoteTh', s.ethics_note_th,
    'interpretations', coalesce((
      select jsonb_agg(jsonb_build_object(
               'tier', e.tier::text,
               'claimType', i.claim_type::text,
               'sourceNameTh', e.label_th,
               'symbolTh', s.name_th,
               'summaryPlainTh', i.summary_plain_th,
               'sourceId', e.id,
               'custodianTh', e.custodian_th,
               'traditionTh', tr.name_th,
               'textTh', i.body_th,
               'contextNoteTh', i.context_note_th,
               'locatorTh', p.locator,
               'quoteTh', case
                            when p.work_rights in
                              ('public_domain','cc0','cc_by','cc_by_sa','licensed_permission')
                            then p.original_text_th
                            else null
                          end,
               'corroborationCount', coalesce(array_length(i.corroborating_edition_ids, 1), 0)
             ) order by e.tier, i.prevalence desc nulls last)
        from content.interpretation i
        join content.passage  p  on p.id = i.passage_id
        join content.edition  e  on e.id = p.edition_id
        left join content.tradition tr on tr.id = i.tradition_id
       where i.symbol_id = s.id and i.status = 'published'
    ), '[]'::jsonb),
    'numbers', coalesce((
      select jsonb_agg(distinct n.number)
        from content.number_association n
       where n.symbol_id = s.id and n.status = 'published'
    ), '[]'::jsonb),
    'related', coalesce((
      select jsonb_agg(jsonb_build_object('slug', r2.slug, 'nameTh', r2.name_th, 'kind', rel.kind::text))
        from content.symbol_relation rel
        join content.symbol r2 on r2.id = rel.related_id
       where rel.symbol_id = s.id and r2.status = 'published'
    ), '[]'::jsonb)
  )
  into result
  from content.symbol s
  join content.category c on c.id = s.category_id
  where s.slug = p_slug and s.status = 'published';

  if result is null then
    raise exception 'symbol not found' using errcode = 'no_data_found';
  end if;

  insert into ops.api_access (fn, arg_digest, row_count) values ('get_symbol', p_slug, 1);
  return result;
end $$;
