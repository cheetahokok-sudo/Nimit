-- ============================================================================
-- content.interpretation.applies_to_lunar_months — the column that reopens A10
--
-- WHAT A10 RECORDED AS A DEAD END. ดวงของฉัน was designed around เดือนเกิด and
-- could never be filled, and the roadmap says why: 'ตำราที่อ่านตามวันเกิด
-- ไม่อ่านตามเดือน'. taksa_v1 worked around it by reading วันเกิด instead, and
-- the calendar code that computes the Thai lunar month has had no reader since.
--
-- That turned out to be true of the ตำรา we had, not of the tradition. The
-- owned พรหมชาติ compilation reads BOTH: each ปีนักษัตร section subdivides into
-- four groups of three lunar months, and each group gets its own sub-animal,
-- its own sub-ธาตุ, and its own reading. ปีชวด born in เดือน ๕–๗ is หนูท้องขาว
-- of ธาตุน้ำทะเลมหาสมุทร; born in เดือน ๑๑–อ้าย it is หนูผี of ธาตุน้ำในลำธาร,
-- and the two readings differ sharply.
--
-- WHY A COLUMN AND NOT MORE SYMBOLS. The obvious alternative was the pattern
-- BIRTHDAY_* and ZODIAC_* already use — one symbol per lookup key, found by a
-- key the app computes. Applied here that means ZODIAC_RAT_M05_07 and 47
-- siblings, and it would be wrong: these are not forty-eight different things
-- to know about, they are twelve things read at finer resolution. A reader born
-- in ปีชวด wants the ปีชวด reading AND the month-group refinement, which one
-- query on one symbol should return.
--
-- It also makes a real invariant expressible. For any one year the four groups
-- must partition all twelve months — no month unread, no month claimed twice.
-- A mis-transcribed range breaks that, and the seeds assert it.
--
-- SEMANTICS. Empty array (the default, and every existing row) means the
-- reading applies to the whole year — no behaviour changes anywhere. A
-- non-empty array means it applies only when the reader's birth month is in the
-- set. Months are the Thai lunar เดือน ๑–๑๒, which core/calendar already
-- computes: เดือนอ้าย is 1 and เดือนยี่ is 2, matching how the book writes them.
-- ============================================================================

alter table content.interpretation
  add column if not exists applies_to_lunar_months smallint[] not null default '{}';

-- A junk month is a silent mis-read: 0 or 13 simply never matches, and the
-- reading disappears for everyone rather than failing loudly.
alter table content.interpretation
  drop constraint if exists interpretation_lunar_months_valid;
alter table content.interpretation
  add constraint interpretation_lunar_months_valid check (
    applies_to_lunar_months <@ array[1,2,3,4,5,6,7,8,9,10,11,12]::smallint[]
  );

comment on column content.interpretation.applies_to_lunar_months is
  'Thai lunar เดือน 1–12 this reading is scoped to (เดือนอ้าย = 1, เดือนยี่ = 2). '
  'Empty means the reading applies to the whole year, which is the default and '
  'the case for every reading written before the owned พรหมชาติ compilation was '
  'read. Non-empty scopes a refinement — the same symbol read at finer '
  'resolution, not a different symbol.';

create index if not exists interpretation_lunar_months_idx
  on content.interpretation using gin (applies_to_lunar_months);
