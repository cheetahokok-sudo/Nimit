-- ============================================================================
-- api.lottery_history — a light list for the ผลย้อนหลัง screen
--
-- WHY A SEPARATE FUNCTION rather than raising lottery_recent_draws' cap.
--
-- Measured against the live database: lottery_recent_draws returns 52 KB for 12
-- draws and 104 KB for 24, because each draw carries all 173 numbers, nine tier
-- objects with Thai names, and a repeated source block including the full
-- licence note. Two years is 48 draws, so the same shape would be roughly
-- 208 KB — for a screen whose rows show only a date, รางวัลที่ 1 and เลขท้าย 2
-- ตัว until the user taps one.
--
-- The audience is on inexpensive phones and mobile data. Sending 200 KB so that
-- 95% of it can be ignored is the kind of decision that makes an app feel slow
-- in exactly the places it is most used.
--
-- So: this returns ~60 bytes per draw (two years in a few KB), and the full
-- 173-number detail is fetched per draw by api.lottery_draw(date) only when a
-- row is actually expanded.
--
-- yearBe is emitted rather than derived in the client so the list can be
-- grouped under a Buddhist-era heading. Without one, two draws per month reads
-- as duplicated rows — a real piece of user feedback, not a hypothetical.
-- ============================================================================

create or replace function api.lottery_history(p_limit int default 48)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'drawDate', d.draw_date,
           'labelTh',  lottery.thai_date(d.draw_date),
           'yearBe',   (extract(year from d.draw_date)::int + 543),
           'first',    (select r.number from lottery.result r
                         where r.draw_id = d.id and r.tier_code = 'first' limit 1),
           'last2',    (select r.number from lottery.result r
                         where r.draw_id = d.id and r.tier_code = 'last2' limit 1),
           -- Carried so a งวด whose data we hold incompletely can say so in the
           -- list rather than looking like any other row.
           'complete', (select count(*) from lottery.result r where r.draw_id = d.id)
                       = (select sum(winner_count) from lottery.prize_tier
                           where effective_to is null)
         ) order by d.draw_date desc), '[]'::jsonb)
    from (select id, draw_date from lottery.draw
           where status = 'announced'
           order by draw_date desc
           -- 60 is a little over two years of draws (24/year), which is the
           -- window the product asks for. Above that, paginate rather than
           -- raising this.
           limit least(greatest(coalesce(p_limit, 48), 1), 60)) d;
$$;

revoke execute on function api.lottery_history(int) from public;
grant  execute on function api.lottery_history(int) to anon, authenticated;

comment on function api.lottery_history(int) is
  'Light list for ผลย้อนหลัง: date, รางวัลที่ 1 and เลขท้าย 2 ตัว only. Full '
  'detail comes from api.lottery_draw(date) when a row is expanded, so two '
  'years of history costs a few KB instead of ~200.';
