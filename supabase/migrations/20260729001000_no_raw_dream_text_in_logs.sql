-- ============================================================================
-- The ops log stops keeping what people dreamt about
--
-- THE BUG. On the no-match path analyze_dream wrote this:
--
--   insert into ops.api_access (fn, arg_digest, row_count)
--   values ('analyze_dream', 'no_match:' || left(norm_text, 40), 0);
--
-- The first forty characters of the user's dream, verbatim, with a timestamp,
-- in a table with no retention policy. The column is named arg_digest. It was
-- not holding a digest.
--
-- WHY IT MATTERS MORE HERE THAN ALMOST ANYWHERE. The text is what someone typed
-- about their own dream — reached for at 3 a.m., about a dead relative, an
-- illness, a fear they have told nobody. Forty characters is the whole of most
-- of them. And it is written on the no-match path specifically: the rows
-- accumulate fastest for the people the library failed, who typed something
-- personal and got nothing back.
--
-- IT ALSO MADE THE APP'S OWN CLAIMS FALSE. PrivacyInfo.xcprivacy declares
-- NSPrivacyCollectedDataTypes as empty and the ดวง screen promises in Thai that
-- what you enter stays yours. Apple's definition of "collect" is transmitting
-- data off the device and keeping it beyond servicing the request in real time.
-- Storing the text indefinitely is exactly that, so the privacy label would
-- have been a false statement — the kind App Review rejects under 5.1.1, and
-- the kind that deserves to be rejected.
--
-- WHAT REPLACES IT. The length, and nothing else: 'no_match:len:12'. That still
-- answers the operational question the log exists for — are misses coming from
-- one-word inputs or from long ones the scanner failed on — without keeping a
-- syllable of what was written.
--
-- WHAT IS GIVEN UP, HONESTLY. Reading the misses would have been a good way to
-- find gaps in the symbol library. It is not available for free. If it is ever
-- wanted, it is a feature with a consent screen and a disclosed privacy label,
-- not a default that nobody was told about. The library grows from transcribed
-- ตำรา, which is where its authority comes from anyway.
--
-- The body below is 20260729000500_dream_min_length.sql's, unchanged except for
-- that one insert. plpgsql has no way to patch one line of a function.
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
  if length(norm_text) < content.dream_min_len() then
    raise exception 'dream text too short: need at least % characters', content.dream_min_len()
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
    -- The length of the miss, never the text of it.
    insert into ops.api_access (fn, arg_digest, row_count)
    values ('analyze_dream', 'no_match:len:' || length(norm_text), 0);
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

comment on column ops.api_access.arg_digest is
  'A DIGEST — never raw user input. Symbol slugs and match counts are fine; '
  'dream text, birth dates and ticket numbers are not, at any length. The '
  'privacy label depends on this column and the no_raw_dream_text check in '
  'supabase/tests/rights_firewall_test.sql enforces it.';

-- Purge what the old version already wrote. These rows are from development
-- against the live project, so this deletes the author's own test dreams — but
-- the fix is not finished while the data it was fixing is still on disk.
delete from ops.api_access
 where fn = 'analyze_dream'
   and arg_digest like 'no_match:%'
   and arg_digest not like 'no_match:len:%';
