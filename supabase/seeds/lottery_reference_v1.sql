-- ============================================================================
-- Lottery reference data: the source, and the nine prize tiers
--
-- This file is where every baht figure in the product comes from. Nothing in
-- the Flutter app hardcodes a prize amount; api.lottery_draw reads these rows
-- and emits them alongside the winning numbers, in one object, so a client can
-- never hold this งวด's numbers next to a previous structure's amounts.
--
-- Two totals are asserted in supabase/tests/rights_firewall_test.sql:
--   sum(winner_count)              = 173
--   sum(amount_thb * winner_count) = 12,018,000
-- Both are properties of the published GLO prize structure. If a typo here
-- changes one, CI fails rather than a user being shown the wrong money.
--
-- Idempotent: safe to re-run, which db-verify.yml does on purpose.
-- ============================================================================

insert into lottery.source_registration
  (citekey, custodian_th, label_th, api_url, catalogue_url,
   licence_code, licence_note_th, fact_basis_note_th, status)
values
  ('glo-api',
   'สำนักงานสลากกินแบ่งรัฐบาล',
   'API ผลการออกรางวัลสลากกินแบ่งรัฐบาล (ทางการ)',
   'https://www.glo.or.th/api/lottery/getLatestLottery',
   'https://gdcatalog.glo.or.th/dataset/dataset_c4-9_01',
   'cc-by-nc',
   'ชุดข้อมูลในบัญชีข้อมูลภาครัฐระบุสัญญาอนุญาต Creative Commons Non-Commercial '
   'และเงื่อนไขการเข้าถึง "GLO Public Used"',
   'ตัวเลขที่ออกรางวัลเป็นข้อเท็จจริง ไม่ใช่งานอันมีลิขสิทธิ์ ตาม พ.ร.บ. ลิขสิทธิ์ '
   'พ.ศ. 2537 มาตรา 7(1) ซึ่งยกเว้นข่าวประจำวันและข้อเท็จจริงต่าง ๆ ที่มีลักษณะเป็นเพียงข่าวสาร '
   'แอปแสดงเครดิตแหล่งที่มาทุกหน้าที่แสดงผลรางวัล และไม่ทำซ้ำชุดข้อมูลของ GLO เพื่อเผยแพร่ต่อ',
   'published')
on conflict (citekey) do update set
  custodian_th       = excluded.custodian_th,
  label_th           = excluded.label_th,
  api_url            = excluded.api_url,
  catalogue_url      = excluded.catalogue_url,
  licence_code       = excluded.licence_code,
  licence_note_th    = excluded.licence_note_th,
  fact_basis_note_th = excluded.fact_basis_note_th;

-- ---------------------------------------------------------------------------
-- The nine tiers
--
-- glo_key is the payload key each tier is parsed from. The two that are easy to
-- get backwards, and which pay different people if swapped:
--
--   last3f -> front3  (เลขหน้า 3 ตัว, matches the FIRST three digits)
--   last3b -> last3   (เลขท้าย 3 ตัว, matches the LAST three digits)
--
-- Verified against งวด 16 ธันวาคม 2567: the API returned last3f = 290,742 and
-- last3b = 339,881, and independent published results for that งวด list
-- เลขหน้า 3 ตัว = 290, 742 and เลขท้าย 3 ตัว = 339, 881. Not inferred from the
-- key names, which read the other way round.
--
-- Anything not listed here is ignored by construction — notably response.n3
-- (สลากดิจิทัล N3), a separate product whose prizes are pari-mutuel and differ
-- every draw. It must never be priced from this table.
--
-- effective_from is งวด 16 สิงหาคม 2558, when the current structure took effect.
-- ---------------------------------------------------------------------------

insert into lottery.prize_tier
  (code, name_th, short_name_th, amount_thb, winner_count,
   match_kind, glo_key, duty_rate, sort, effective_from)
values
  ('first',      'รางวัลที่ 1',                  'ที่ 1',        6000000,   1, 'exact6',  'first',  0.0050, 10, date '2015-08-16'),
  ('near_first', 'รางวัลข้างเคียงรางวัลที่ 1',   'ข้างเคียง',     100000,   2, 'exact6',  'near1',  0.0050, 20, date '2015-08-16'),
  ('second',     'รางวัลที่ 2',                  'ที่ 2',         200000,   5, 'exact6',  'second', 0.0050, 30, date '2015-08-16'),
  ('third',      'รางวัลที่ 3',                  'ที่ 3',          80000,  10, 'exact6',  'third',  0.0050, 40, date '2015-08-16'),
  ('fourth',     'รางวัลที่ 4',                  'ที่ 4',          40000,  50, 'exact6',  'fourth', 0.0050, 50, date '2015-08-16'),
  ('fifth',      'รางวัลที่ 5',                  'ที่ 5',          20000, 100, 'exact6',  'fifth',  0.0050, 60, date '2015-08-16'),
  ('front3',     'รางวัลเลขหน้า 3 ตัว',          'หน้า 3 ตัว',      4000,   2, 'prefix3', 'last3f', 0.0050, 70, date '2015-08-16'),
  ('last3',      'รางวัลเลขท้าย 3 ตัว',          'ท้าย 3 ตัว',      4000,   2, 'suffix3', 'last3b', 0.0050, 80, date '2015-08-16'),
  ('last2',      'รางวัลเลขท้าย 2 ตัว',          'ท้าย 2 ตัว',      2000,   1, 'suffix2', 'last2',  0.0050, 90, date '2015-08-16')
on conflict (code) do update set
  name_th       = excluded.name_th,
  short_name_th = excluded.short_name_th,
  amount_thb    = excluded.amount_thb,
  winner_count  = excluded.winner_count,
  match_kind    = excluded.match_kind,
  glo_key       = excluded.glo_key,
  duty_rate     = excluded.duty_rate,
  sort          = excluded.sort;

-- Fail the seed itself rather than waiting for the test suite: if these totals
-- are wrong, every downstream figure is wrong, and this is the cheapest place
-- to find out.
do $$
declare v_numbers int; v_pool bigint;
begin
  select sum(winner_count), sum(amount_thb * winner_count)
    into v_numbers, v_pool
    from lottery.prize_tier where effective_to is null;

  if v_numbers <> 173 then
    raise exception 'prize_tier winner_count total is %, expected 173', v_numbers;
  end if;
  if v_pool <> 12018000 then
    raise exception 'prize_tier prize pool is %, expected 12018000', v_pool;
  end if;
end $$;

select code, name_th, amount_thb, winner_count, match_kind, glo_key
  from lottery.prize_tier order by sort;
