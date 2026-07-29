-- ============================================================================
-- The dream matcher stops rejecting Thai words for being Thai
--
-- THE BUG. analyze_dream refused any input shorter than four characters. In
-- English that is a reasonable floor. In Thai it silently removes the most
-- common things anyone dreams about:
--
--   งู ไฟ ผี ศพ ฝน นก ปู กบ กา มด รถ ผม โค        (2 characters)
--   แมว ม้า หมา ลิง วัว หนู ปลา พระ วัด ดาว ทอง น้ำ นาค ไก่  (3 characters)
--
-- Thirty-six curated terms — fourteen at length two and twenty-two at length
-- three — were unreachable to anyone who typed a single word, which is exactly
-- how someone recounts a dream they half remember. 'ฝันเห็นแมว' worked and
-- 'แมว' did not, and nothing told the user why.
--
-- WHY THE FLOOR WAS WRONG IN PRINCIPLE, NOT JUST IN VALUE. length() counts
-- Unicode code points, and Thai spends them differently from English. Vowels
-- and tone marks are separate code points that attach to a consonant rather
-- than following it, so a one-syllable word can be anywhere from two code
-- points (งู) to five (เสื้อ). ช้าง is one syllable and four code points, which
-- is why it slipped past the floor while ม้า, also one syllable, did not. Code
-- points are simply not a measure of how much a Thai reader has typed.
--
-- THE FLOOR THAT IS DEFENSIBLE is the shortest term the library actually
-- curates, because an input shorter than that cannot contain any term and a
-- scan would be certain to find nothing. That is two. It is now stated once, in
-- content.dream_min_len(), and the review sweep fails if any published term
-- ever drops below it — which would make that term unreachable in exactly the
-- silent way this bug was.
--
-- WHAT IS NOT CHANGED. Matching stays exact, including tone marks. Loosening it
-- was tempting — a wrong or missing tone mark is the commonest Thai input error
-- and content.norm_loose_th already exists for it — but tone marks distinguish
-- real words: เสือ is a tiger and เสื่อ is a floor mat, ไก่ is a chicken and ไก
-- is not. Stripping them would answer a dream about a mat with a reading about
-- tigers, and a confident wrong answer is worse here than an honest empty one.
-- A fallback that only loosens when the exact scan finds nothing is the right
-- shape for that, and it is a separate change with its own risks.
--
-- The body below is 20260726001000_span_matching.sql's, unchanged except for
-- the guard. plpgsql has no way to patch one line of a function.
-- ============================================================================

-- search_path pinned like every other function here. It returns a literal and
-- resolves nothing, so it changes no behaviour — but the suite asserts the rule
-- without exceptions, and an exception is how the rule stops being one.
create or replace function content.dream_min_len()
returns int language sql immutable parallel safe
set search_path = '' as $$ select 2 $$;

comment on function content.dream_min_len is
  'Shortest input analyze_dream will scan, in code points. Equals the shortest '
  'curated term: below it a scan cannot match anything. Enforced against the '
  'data by the term_below_match_floor check in scripts/review-checks.sql.';

-- Every function in content is closed to PUBLIC — the standing invariant from
-- migration 500, asserted by the suite, which failed on this the moment it was
-- added. analyze_dream reaches it as SECURITY DEFINER, so revoking costs
-- nothing; leaving it granted would have widened the callable surface by one
-- function for no reason.
revoke all on function content.dream_min_len() from public;

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
