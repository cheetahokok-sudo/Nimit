-- ============================================================================
-- api.taksa_birthday — the ทักษา reading for a day of the week.
--
-- ดวงของฉัน computes the user's weekday on the device, from a birth date that
-- never leaves it. This is the only thing it asks the server: "what does the
-- ตำรา say about people born on day N". No birth date, no year, nothing
-- identifying — the same privacy property the lottery checker has, where the
-- user's numbers never travel.
--
-- p_weekday is 1=Monday .. 7=Sunday, matching Dart's DateTime.weekday so the
-- client never has to remap and get it wrong.
--
-- RETURNS NULL WHEN NOTHING IS PUBLISHED, and that is the expected state right
-- now: the only source for these readings is a single copyrighted 1963
-- printing, so every row sits at status='draft' pending a second witness. The
-- screen renders its honest empty state in that case. Publishing is a status
-- change, not a code change.
-- ============================================================================

create or replace function api.taksa_birthday(p_weekday int)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  result jsonb;
  target text;
begin
  -- Fail closed on a nonsense weekday rather than coercing it into range. A
  -- clamped 0 would hand somebody Monday's reading.
  target := case p_weekday
    when 1 then 'BIRTHDAY_MON' when 2 then 'BIRTHDAY_TUE'
    when 3 then 'BIRTHDAY_WED' when 4 then 'BIRTHDAY_THU'
    when 5 then 'BIRTHDAY_FRI' when 6 then 'BIRTHDAY_SAT'
    when 7 then 'BIRTHDAY_SUN' else null end;
  if target is null then
    return null;
  end if;

  select jsonb_build_object(
    'slug',       s.slug,
    'nameTh',     s.name_th,
    'weekday',    p_weekday,
    'readings',   coalesce((
      select jsonb_agg(jsonb_build_object(
               'bodyTh',        i.body_th,
               'summaryTh',     i.summary_plain_th,
               'contextNoteTh', i.context_note_th,
               'source', jsonb_build_object(
                 'titleTh',    w.canonical_title_th,
                 'authorTh',   w.attributed_author_th,
                 'editionTh',  e.label_th,
                 'yearBe',     e.year_published,
                 'locator',    p.locator,
                 'tier',       e.tier::text
               )
             ) order by e.tier)
      from content.interpretation i
      join content.passage p on p.id = i.passage_id
      join content.edition e on e.id = p.edition_id
      join content.work    w on w.id = e.work_id
      where i.symbol_id = s.id
        and i.status = 'published'          -- draft never reaches a reader
    ), '[]'::jsonb)
  )
  into result
  from content.symbol s
  where s.concept_key = target
    and s.status = 'published';

  return result;   -- null when the symbol itself is not published yet
end $$;

-- Grants in the order migration 500 proved is the only correct one: revoke
-- from PUBLIC first, because anon inherits PUBLIC and revoking from anon alone
-- does nothing.
revoke all on function api.taksa_birthday(int) from public;
grant execute on function api.taksa_birthday(int) to anon;
grant execute on function api.taksa_birthday(int) to authenticated;
