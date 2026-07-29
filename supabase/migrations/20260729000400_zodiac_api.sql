-- ============================================================================
-- api.zodiac_year — the ปีนักษัตร reading, and its เดือนเกิด refinement
--
-- The third and last lookup ดวงของฉัน can compute from a birth date it never
-- sends: ทักษา keys on the weekday, วงราศี on the age, and this on the lunar
-- year and lunar month. Between them they use every part of the date and
-- transmit none of it.
--
-- ── TWO LISTS COME BACK, NOT ONE ───────────────────────────────────────────
--
-- yearReadings are the ตำรา's general reading for the ปีนักษัตร. monthReadings
-- are the refinement for the three-month group the birth falls in — ปีชวด born
-- เดือน ๕–๗ is หนูท้องขาว of ธาตุน้ำทะเลมหาสมุทร, born เดือน ๘–๑๐ it is another
-- creature entirely and the verdict inverts.
--
-- They are returned separately rather than merged because they are not
-- interchangeable: the year reading applies to everyone born that year, and the
-- month one only to a quarter of them. A screen that stacked them without
-- distinction would present a refinement as if it were the general case.
--
-- ── p_lunar_month MAY BE NULL ──────────────────────────────────────────────
--
-- Null means "just the year", which is what a caller has when it knows the
-- นักษัตร but not the month. monthReadings is then empty rather than absent, so
-- the client never has to distinguish "no month given" from "no month reading
-- published" — both are an empty list and both render the same way.
--
-- ── INDEX, NOT A THAI STRING ───────────────────────────────────────────────
--
-- p_zodiac_index is 0=ชวด .. 11=กุน, matching the order of _zodiacNames in
-- core/calendar/thai_lunar_birth.dart so the client sends what it already
-- computed. Passing 'มะโรง' as text would make the contract depend on two
-- codebases spelling a Thai word identically forever, and the taksa function
-- already set the precedent of sending an integer.
--
-- ── MONTH NUMBERING ────────────────────────────────────────────────────────
--
-- p_lunar_month is the Thai lunar เดือน 1–12 with เดือนอ้าย = 1 and เดือนยี่ = 2,
-- which is both what package:thai_lunar returns as lunar.month and how the
-- ตำรา writes its groups (๑๑-๑๒-อ้าย wraps the year end). A birth in the
-- intercalary เดือน ๘ หลัง is still month 8 and lands in the ๘-๙-๑๐ group with
-- everyone else, so อธิกมาส needs no special case here.
--
-- ── NOTHING PUBLISHED YET, BY DESIGN ───────────────────────────────────────
--
-- Every ปีนักษัตร reading is draft: they come from the owned compilation, which
-- carries has_modern_editorial_layer, so the two-source rule applies even
-- though the underlying work is public domain. This function returns the right
-- symbol with empty lists until that clears. Publishing is a status change.
-- ============================================================================

create or replace function api.zodiac_year(p_zodiac_index int, p_lunar_month int)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  target text;
  result jsonb;
begin
  -- Fail closed on a nonsense index rather than coercing it into range: a
  -- wrapped 12 would hand somebody ชวด's reading and look like it worked.
  target := case p_zodiac_index
    when 0  then 'ZODIAC_RAT'     when 1  then 'ZODIAC_OX'
    when 2  then 'ZODIAC_TIGER'   when 3  then 'ZODIAC_RABBIT'
    when 4  then 'ZODIAC_DRAGON'  when 5  then 'ZODIAC_SNAKE'
    when 6  then 'ZODIAC_HORSE'   when 7  then 'ZODIAC_GOAT'
    when 8  then 'ZODIAC_MONKEY'  when 9  then 'ZODIAC_ROOSTER'
    when 10 then 'ZODIAC_DOG'     when 11 then 'ZODIAC_PIG'
    else null end;
  if target is null then
    return null;
  end if;

  -- An out-of-range month is a client bug. Treat it as "no month" rather than
  -- refusing the whole call: the year reading is still correct and still worth
  -- returning, and swallowing it would lose good content over a bad argument.
  if p_lunar_month is not null and (p_lunar_month < 1 or p_lunar_month > 12) then
    p_lunar_month := null;
  end if;

  select jsonb_build_object(
    'index',      p_zodiac_index,
    'lunarMonth', p_lunar_month,
    'slug',       s.slug,
    'nameTh',     s.name_th,

    'yearReadings', coalesce((
      select jsonb_agg(content._reading_json(i, p, e, w) order by e.tier)
      from content.interpretation i
      join content.passage p on p.id = i.passage_id
      join content.edition e on e.id = p.edition_id
      join content.work    w on w.id = e.work_id
      where i.symbol_id = s.id
        and i.status = 'published'
        and coalesce(array_length(i.applies_to_lunar_months, 1), 0) = 0
    ), '[]'::jsonb),

    'monthReadings', coalesce((
      select jsonb_agg(content._reading_json(i, p, e, w) order by e.tier)
      from content.interpretation i
      join content.passage p on p.id = i.passage_id
      join content.edition e on e.id = p.edition_id
      join content.work    w on w.id = e.work_id
      where i.symbol_id = s.id
        and i.status = 'published'
        and p_lunar_month is not null
        and p_lunar_month::smallint = any(i.applies_to_lunar_months)
    ), '[]'::jsonb)
  )
  into result
  from content.symbol s
  where s.concept_key = target
    and s.status = 'published';

  return result;   -- null when the symbol itself is not published
end $$;

-- ---------------------------------------------------------------------------
-- One reading as the client expects it. Extracted because zodiac_year builds
-- the same object twice and taksa_birthday/agewheel already build it inline —
-- three hand-written copies of a citation shape is how a source line goes
-- missing from one of them.
-- ---------------------------------------------------------------------------
create or replace function content._reading_json(
  i content.interpretation, p content.passage,
  e content.edition, w content.work)
returns jsonb
language sql immutable security definer set search_path = '' as $$
  select jsonb_build_object(
    'bodyTh',        i.body_th,
    'summaryTh',     i.summary_plain_th,
    'contextNoteTh', i.context_note_th,
    'source', jsonb_build_object(
      'titleTh',   w.canonical_title_th,
      'authorTh',  w.attributed_author_th,
      'editionTh', e.label_th,
      'yearBe',    e.year_published,
      'locator',   p.locator,
      'tier',      e.tier::text
    )
  );
$$;

revoke all on function content._reading_json(
  content.interpretation, content.passage, content.edition, content.work) from public;
revoke all on function api.zodiac_year(int, int) from public;
grant execute on function api.zodiac_year(int, int) to anon;
grant execute on function api.zodiac_year(int, int) to authenticated;

-- ---------------------------------------------------------------------------
-- The index mapping, asserted. A silent shift here gives every user the wrong
-- year's reading while everything still looks like it works — the failure mode
-- with no symptom.
-- ---------------------------------------------------------------------------
do $$
declare got text; n int;
begin
  -- Only checkable once the symbols exist; skip cleanly on a bare schema so
  -- migration order never depends on seed order.
  select count(*) into n from content.symbol where concept_key like 'ZODIAC_%';
  if n = 0 then
    raise notice 'zodiac api: no ZODIAC_ symbols yet, mapping check deferred to CI';
    return;
  end if;

  select api.zodiac_year(0, null)->>'nameTh' into got;
  if got <> 'คนเกิดปีชวด' then
    raise exception 'zodiac api: index 0 must be ชวด, got %', got;
  end if;

  select api.zodiac_year(11, null)->>'nameTh' into got;
  if got <> 'คนเกิดปีกุน' then
    raise exception 'zodiac api: index 11 must be กุน, got %', got;
  end if;

  select api.zodiac_year(4, null)->>'nameTh' into got;
  if got <> 'คนเกิดปีมะโรง' then
    raise exception 'zodiac api: index 4 must be มะโรง, got %', got;
  end if;

  if api.zodiac_year(12, null) is not null or api.zodiac_year(-1, null) is not null then
    raise exception 'zodiac api: an out-of-range index must fail closed, not wrap';
  end if;

  -- A bad month must not cost the caller the year reading.
  if api.zodiac_year(0, 99)->>'nameTh' is distinct from 'คนเกิดปีชวด' then
    raise exception 'zodiac api: an out-of-range month must degrade to year-only';
  end if;
end $$;
