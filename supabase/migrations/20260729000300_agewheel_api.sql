-- ============================================================================
-- api.agewheel_age — the วงราศีตามอายุ verdict for a given age
--
-- หน้า ๑–๓ of the owned พรหมชาติ: twelve figures in a circle, counted off
-- against the reader's current age starting from เจดีย์, and the figure you
-- land on is that year of life. ชายเวียนขวา หญิงเวียนซ้าย.
--
-- ── WHAT TRAVELS ───────────────────────────────────────────────────────────
--
-- An integer age. Not a birth date, not a year, not a weekday. The same
-- property api.taksa_birthday has and for the same reason: the device knows
-- when you were born and the server never needs to.
--
-- ── NO GENDER PARAMETER, AND THAT IS DELIBERATE ────────────────────────────
--
-- The ตำรา's rule turns on sex, so the obvious signature was
-- agewheel_age(p_age, p_female). It is not the signature, because the app does
-- not know the user's sex and this feature is a poor reason to start asking:
-- ดวงของฉัน holds a birth date that never leaves the device, and bolting a
-- second personal attribute onto that to save one round trip is the wrong
-- trade.
--
-- So this returns BOTH readings — the figure a man of this age lands on and
-- the figure a woman lands on — and the screen shows both, labelled. Nothing
-- personal is collected, nothing is guessed, and a reader can see the ตำรา's
-- own structure instead of having it silently resolved for them.
--
-- ── THE ORDER IS UNCONFIRMED, AND THIS FUNCTION IS WHERE IT LIVES ──────────
--
-- The mapping below is the numbered order ๑–๑๒ that หน้า ๑–๒ states outright,
-- and it is the only evidence there is. หน้า ๒ ends with หมายเหตุ : ดูภาพประกอบ
-- หน้า ๓ — so a wheel diagram exists in the printed book — but หน้า ๓ is blank
-- in the scan we hold. (An earlier version of this file claimed the diagram
-- ordered the figures differently; that came from a machine transcription that
-- invented the page, and no such conflict exists.)
--
-- This matters here more than anywhere else: every other use of these symbols
-- is order-independent, but the counting rule IS the order. If the diagram ever
-- surfaces and disagrees, the fix is this case statement and nothing else.
--
-- Meanwhile no wrong verdict can reach a reader, because every reading is
-- draft and the query below filters to published. The function returns the
-- correct SHAPE with an empty readings list, which is exactly what the screen
-- needs to render its honest empty state.
--
-- ── AGE CONVENTION ─────────────────────────────────────────────────────────
--
-- p_age is completed years — the unambiguous, checkable definition, and what
-- the client computes from the stored birth date. The ตำรา says เท่าจำนวนอายุ
-- ปัจจุบัน without saying whether the year of birth counts as year one, which
-- is a real fork: Thai age reckoning sometimes does. The client labels what it
-- sent (ปีเต็ม) so the assumption is visible rather than buried, and if the
-- other convention proves correct it is an off-by-one applied in one place.
-- ============================================================================

create or replace function api.agewheel_age(p_age int)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  result   jsonb;
  male_pos int;
  fem_pos  int;
begin
  -- Fail closed rather than coerce. A negative or absurd age is a client bug,
  -- and answering it with position 1 would hide that bug behind a reading.
  if p_age is null or p_age < 1 or p_age > 150 then
    return null;
  end if;

  -- ชาย เวียนขวา: age 1 lands on เจดีย์, each further year steps forward one.
  male_pos := ((p_age - 1) % 12) + 1;
  -- หญิง เวียนซ้าย: the same start, stepping the other way round the circle.
  -- Written with the extra + 12 because PostgreSQL's % keeps the sign of the
  -- left operand, so (-1) % 12 is -1 and not 11.
  fem_pos  := (((12 - ((p_age - 1) % 12)) % 12)) + 1;

  select jsonb_build_object(
    'age',    p_age,
    'male',   content._agewheel_figure(male_pos),
    'female', content._agewheel_figure(fem_pos)
  ) into result;

  return result;
end $$;

-- ---------------------------------------------------------------------------
-- One figure, by position. Internal to content — not exposed on the API
-- surface, which stays deliberately small.
-- ---------------------------------------------------------------------------
create or replace function content._agewheel_figure(p_pos int)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  target text;
  result jsonb;
begin
  -- The provisional order. See the header: this is the single place to change
  -- if the หน้า ๓ diagram overrides the numbered list.
  target := case p_pos
    when 1  then 'AGEWHEEL_CHEDI'
    when 2  then 'AGEWHEEL_SILVER_PARASOL'
    when 3  then 'AGEWHEEL_BEHEADING'
    when 4  then 'AGEWHEEL_ROYAL_HOUSE'
    when 5  then 'AGEWHEEL_PALACE'
    when 6  then 'AGEWHEEL_RAHU'
    when 7  then 'AGEWHEEL_GOLD_PARASOL'
    when 8  then 'AGEWHEEL_DEVA_ON_TURTLE'
    when 9  then 'AGEWHEEL_CANGUE'
    when 10 then 'AGEWHEEL_SORCERER'
    when 11 then 'AGEWHEEL_WITCH'
    when 12 then 'AGEWHEEL_NAGA_KING'
    else null end;
  if target is null then
    return null;
  end if;

  select jsonb_build_object(
    'position', p_pos,
    'slug',     s.slug,
    'nameTh',   s.name_th,
    'readings', coalesce((
      select jsonb_agg(jsonb_build_object(
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
             ) order by e.tier)
      from content.interpretation i
      join content.passage p on p.id = i.passage_id
      join content.edition e on e.id = p.edition_id
      join content.work    w on w.id = e.work_id
      where i.symbol_id = s.id
        and i.status = 'published'        -- draft never reaches a reader
    ), '[]'::jsonb)
  ) into result
  from content.symbol s
  where s.concept_key = target and s.status = 'published';

  return result;
end $$;

-- Grants in the order migration 500 proved is the only correct one: revoke
-- from PUBLIC first, because anon inherits PUBLIC and revoking from anon alone
-- does nothing. The internal helper is never granted to a client role.
revoke all on function content._agewheel_figure(int) from public;
revoke all on function api.agewheel_age(int) from public;
grant execute on function api.agewheel_age(int) to anon;
grant execute on function api.agewheel_age(int) to authenticated;

-- ---------------------------------------------------------------------------
-- The counting rule, asserted. These are pure arithmetic and hold whatever the
-- content status is, so they are checked here rather than left to a seed.
-- ---------------------------------------------------------------------------
do $$
declare m int; f int;
begin
  -- Age 1: both sexes start on เจดีย์.
  m := ((1 - 1) % 12) + 1;
  f := (((12 - ((1 - 1) % 12)) % 12)) + 1;
  if m <> 1 or f <> 1 then
    raise exception 'agewheel: age 1 must land on position 1 for both — got %, %', m, f;
  end if;

  -- Age 2: the directions separate, and by one step each way.
  m := ((2 - 1) % 12) + 1;
  f := (((12 - ((2 - 1) % 12)) % 12)) + 1;
  if m <> 2 or f <> 12 then
    raise exception 'agewheel: age 2 must be 2 (ชาย) and 12 (หญิง) — got %, %', m, f;
  end if;

  -- Age 13 wraps to the start again.
  m := ((13 - 1) % 12) + 1;
  if m <> 1 then
    raise exception 'agewheel: age 13 must wrap to position 1 — got %', m;
  end if;

  -- No age may fall outside the wheel. The negative-modulo trap this catches
  -- is real: without the + 12 the หญิง branch returns 0 for every age.
  for m in 1..150 loop
    f := (((12 - ((m - 1) % 12)) % 12)) + 1;
    if f < 1 or f > 12 then
      raise exception 'agewheel: age % gives หญิง position % outside 1–12', m, f;
    end if;
    if ((m - 1) % 12) + 1 not between 1 and 12 then
      raise exception 'agewheel: age % gives ชาย position outside 1–12', m;
    end if;
  end loop;
end $$;
