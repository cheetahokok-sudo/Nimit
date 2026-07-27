-- ============================================================================
-- ทักษาวันเกิด v1 — คนเกิดวัน ๗ วัน จากพรหมชาติ ฉบับ พ.ศ. ๒๕๐๖
--
-- THIS IS THE FIRST CONTENT IN THE astrology-taksa CATEGORY, which has sat
-- empty since the schema was written.
--
-- WHY DAY OF BIRTH AND NOT MONTH. ดวงของฉัน was designed around เดือนเกิด and
-- could never be filled, because the ตำรา that read by birth do not read by
-- month — they read by วันเกิด. This book states it outright on หน้า ๑๔:
-- พระอิศวร named the seven planetary days, "ถ้าหากผู้หญิงผู้ชายใดเกิดมาในวันทั้ง ๗
-- ความเป็นไปจะต่างกันตามวันที่เกิด". Seven sections follow, one per day.
--
-- The app already computes the weekday from the stored birth date, honouring
-- the Thai dawn boundary, so these readings have a key to be found by on the
-- day they land.
--
-- SOURCE AND RIGHTS. พรหมชาติ, เรียบเรียงโดย สุนันท์ วิโรภาส, พิมพ์เป็นที่ระลึก
-- ในงานพระราชทานเพลิงศพ รองอำมาตย์เอก หลวงชลาสัยสวัสดิ์ (ต่อง โชตยาน)
-- ๔ เมษายน พ.ศ. ๒๕๐๖. Copy scanned from สำนักหอสมุด มหาวิทยาลัยธรรมศาสตร์.
--
-- Registered as copyrighted_cite_only, and every row lands as DRAFT. The
-- underlying พรหมชาติ is a traditional anonymous compilation and is very
-- probably out of copyright as a work — but this is a 1963 printing with a
-- named compiler, and it cannot be shown from the page alone that this
-- WORDING is old rather than his. So: page locator, no original_text_th, no
-- verbatim. The readings below are summaries written for this app.
--
-- That is the same posture ฝันพยากรณ์ takes, and the same escape route
-- applies: พรหมชาติ was printed by many houses in many editions, so a second
-- witness is a realistic thing to find rather than a formality. A belief
-- attested across independent editions stops being one publisher's expression
-- and becomes a cultural fact nobody owns. Corroborate, then publish.
-- ============================================================================

insert into content.work
  (slug, canonical_title_th, attributed_author_th, composed_period_th,
   rights, pd_basis, copyright_holder, rights_note_th, status)
values
('phrommachat-wirophat', 'พรหมชาติ (ฉบับสุนันท์ วิโรภาส)',
 'สุนันท์ วิโรภาส (ผู้เรียบเรียง)', 'พิมพ์ พ.ศ. 2506',
 'copyrighted_cite_only', null, 'สุนันท์ วิโรภาส และผู้จัดพิมพ์',
 'ตัวตำราพรหมชาติเป็นของเก่าไม่ปรากฏผู้แต่ง และน่าจะพ้นลิขสิทธิ์ในฐานะ "งาน" '
 'แล้ว แต่ฉบับนี้พิมพ์ พ.ศ. 2506 และระบุผู้เรียบเรียงไว้ จึงยังพิสูจน์ไม่ได้ว่า '
 'สำนวนที่พิมพ์นี้เก่าหรือเป็นของผู้เรียบเรียง | ใช้อ้างอิงและถอดความได้ '
 'ห้ามคัดลอกข้อความตรงหรือภาพ | รอสอบทานกับฉบับพิมพ์อื่นก่อนเผยแพร่',
 'draft')
on conflict (slug) do nothing;

insert into content.edition
  (work_id, citekey, tier, label_th, custodian_th, stable_identifier,
   year_published, physical_desc_th, script_th, languages, url,
   custodian_rights, rights_note_th, status)
select w.id, 'phrommachat-2506', 'b2', 'พรหมชาติ ฉบับอนุสรณ์งานศพ พ.ศ. 2506',
  'สำนักหอสมุด มหาวิทยาลัยธรรมศาสตร์ (ฉบับที่สแกน)',
  'TULIB 3 1379 01497507 3', 2506,
  'หนังสืออนุสรณ์งานพระราชทานเพลิงศพ หลวงชลาสัยสวัสดิ์ (ต่อง โชตยาน) '
  'ณ สุสานหลวง วัดเทพศิรินทราวาส ๔ เมษายน ๒๕๐๖ · 145 หน้า',
  'ไทย', array['th'], null,
  'unknown',
  'สำเนาที่ใช้เป็นของห้องสมุดมหาวิทยาลัยธรรมศาสตร์ ไม่ได้เผยแพร่ภาพสแกนซ้ำ '
  'บันทึกเฉพาะเลขหน้าและคำสรุปที่เขียนขึ้นเอง',
  'draft'
from content.work w where w.slug = 'phrommachat-wirophat'
on conflict (citekey) do nothing;

-- ---------------------------------------------------------------------------
-- The seven days as symbols.
--
-- DELIBERATELY WITHOUT symbol_term ROWS. Every other symbol in this library
-- carries search terms so the dream scanner can match it in free text. These
-- must not: a user writing "ฝันเมื่อคืนวันอาทิตย์" would otherwise match a
-- birth-day reading and be told about their character. The app looks these up
-- by slug from the computed weekday, never by scanning prose, so terms would
-- be pure downside. Same reasoning as the primary-terms-only rule that stopped
-- ปลาวาฬ's numbers landing on the generic ปลา.
-- ---------------------------------------------------------------------------
insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'draft', null
from (values
  ('BIRTHDAY_SUN', 'born-sunday',    'คนเกิดวันอาทิตย์',   'born on Sunday',    'astrology-taksa'),
  ('BIRTHDAY_MON', 'born-monday',    'คนเกิดวันจันทร์',    'born on Monday',    'astrology-taksa'),
  ('BIRTHDAY_TUE', 'born-tuesday',   'คนเกิดวันอังคาร',    'born on Tuesday',   'astrology-taksa'),
  ('BIRTHDAY_WED', 'born-wednesday', 'คนเกิดวันพุธ',       'born on Wednesday', 'astrology-taksa'),
  ('BIRTHDAY_THU', 'born-thursday',  'คนเกิดวันพฤหัสบดี',  'born on Thursday',  'astrology-taksa'),
  ('BIRTHDAY_FRI', 'born-friday',    'คนเกิดวันศุกร์',     'born on Friday',    'astrology-taksa'),
  ('BIRTHDAY_SAT', 'born-saturday',  'คนเกิดวันเสาร์',     'born on Saturday',  'astrology-taksa')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

-- ---------------------------------------------------------------------------
-- Passage: page locator only. NO original_text_th — the rights firewall
-- rejects verbatim text from a copyrighted_cite_only work, correctly.
-- ---------------------------------------------------------------------------
insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, 'หน้า ๑๔–๑๗ หมวดคนเกิดวัน', 14, null,
  'หมวดคำทำนายตามวันเกิดทั้งเจ็ดวัน แต่ละวันระบุนามประจำวัน ธาตุ นิสัย '
  'เกณฑ์ชะตาตามช่วงอายุ และทิศทางตามคติทักษา',
  'เจ้าของโครงการ อ่านจากฉบับพิมพ์ที่ถือครอง',
  'ไม่เก็บข้อความต้นฉบับ เพราะฉบับนี้เป็น copyrighted_cite_only '
  'บันทึกเฉพาะเลขหน้าและคำสรุปที่เรียบเรียงขึ้นใหม่ | '
  'ยังไม่ได้สอบทานกับฉบับพิมพ์อื่น',
  'draft'
from content.edition e where e.citekey = 'phrommachat-2506'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- Readings. Summaries, not transcription.
--
-- Each day's entry in the book opens with a นาม (an emblem animal) and a ธาตุ
-- (element), then character, then fortune by age band, then ทักษา directions.
-- The นาม and ธาตุ are recorded because they are short factual attributes that
-- identify the reading, and because they are what a user recognises. The
-- age-band fortunes are summarised rather than reproduced.
-- ---------------------------------------------------------------------------
with v(concept_key, body, plain) as (values
('BIRTHDAY_SUN',
 'ตำราพรหมชาติให้นามประจำวันอาทิตย์ว่า "ครุฑ" และธาตุประจำวันคือธาตุหิน '
 'ว่าผู้เกิดวันนี้เป็นคนใจกว้างชอบเข้าสังคม ทำคุณคนมักไม่ได้ผลตอบแทน '
 'ใจร้อนเชื่อคนง่ายแต่ภายหลังมักได้ดี และมีเกณฑ์ชะตาผันผวนเป็นช่วงตามอายุ',
 'ตำราเก่าว่าคนเกิดวันอาทิตย์ นามครุฑ ธาตุหิน ใจกว้างเข้ากับคนง่าย '
 'แต่ทำดีกับใครมักไม่ค่อยได้ผลตอบแทน'),
('BIRTHDAY_MON',
 'ตำราพรหมชาติให้นามประจำวันจันทร์ว่า "พยัคฆ์" (เสือ) และธาตุประจำวันคือธาตุไม้ '
 'ว่าผู้เกิดวันนี้มีวาทศิลป์ มานะทะยานสูง โกรธเร็วหายเร็ว '
 'แต่ปากมากจึงมักมีศัตรู และมีเกณฑ์ระวังเคราะห์ในบางช่วงอายุ',
 'ตำราเก่าว่าคนเกิดวันจันทร์ นามเสือ ธาตุไม้ พูดเก่งมีความมานะ '
 'โกรธเร็วหายเร็ว แต่ปากมักพาให้มีศัตรู'),
('BIRTHDAY_TUE',
 'ตำราพรหมชาติให้นามประจำวันอังคารว่า "สีหราช" (สิงห์) และธาตุประจำวันคือธาตุเหล็ก '
 'ว่าผู้เกิดวันนี้ใจเด็ดดุจไฟ กอบด้วยศรัทธาและความกล้า มีมิตรสหายมาก '
 'ทำคุณคนมักไม่มีผู้เห็น เก็บทรัพย์ไม่ค่อยอยู่',
 'ตำราเก่าว่าคนเกิดวันอังคาร นามสิงห์ ธาตุเหล็ก ใจกล้าเด็ดขาด เพื่อนฝูงมาก '
 'แต่เก็บเงินไม่ค่อยอยู่'),
('BIRTHDAY_WED',
 'ตำราพรหมชาติให้นามประจำวันพุธว่า "สุนัข" และธาตุประจำวันคือธาตุเถ้า '
 'ว่าผู้เกิดวันนี้ขยันหมั่นเพียรและรอบรู้การงาน พูดจาอาจหาญ '
 'ทำคุณท่านมักอาภัพ หาทรัพย์ได้แต่ไม่ค่อยอยู่คง ภายหลังจึงมั่งคั่งเป็นสุข',
 'ตำราเก่าว่าคนเกิดวันพุธ นามสุนัข ธาตุเถ้า ขยันและรู้งานรอบด้าน '
 'ช่วงต้นหาได้ไม่ค่อยอยู่ แต่ภายหลังจะมั่งมีเป็นสุข'),
('BIRTHDAY_THU',
 'ตำราพรหมชาติให้นามประจำวันพฤหัสบดีว่า "หนู" และธาตุประจำวันคือธาตุน้ำ '
 'ว่าผู้เกิดวันนี้มีปัญญามาก เป็นผู้เพียรเรียนและเชี่ยวชาญการขีดเขียน '
 'มีโวหารรอบรู้ ชอบคบสมณะและผู้มีศีล มักได้ลาภเรืองผล',
 'ตำราเก่าว่าคนเกิดวันพฤหัสบดี นามหนู ธาตุน้ำ ปัญญาดี ชอบเรียนชอบเขียน '
 'พูดจามีหลัก มักได้ลาภ'),
('BIRTHDAY_FRI',
 'ตำราพรหมชาติให้นามประจำวันศุกร์ว่า "เมษา" (แพะ) และธาตุประจำวันคือธาตุลม '
 'ว่าผู้เกิดวันนี้ใจทะยานมุ่งมั่น มีโวหารคมคาย โกรธเร็ว '
 'หาทรัพย์ติดตัวได้น้อยเพราะใช้จ่ายง่าย ภายหลังจึงมียศถาบรรดาศักดิ์',
 'ตำราเก่าว่าคนเกิดวันศุกร์ นามแพะ ธาตุลม ใจสู้ พูดคม โกรธเร็ว '
 'เงินทองมาแล้วไปเพราะใช้ง่าย ภายหลังจะได้ยศ'),
('BIRTHDAY_SAT',
 'ตำราพรหมชาติให้นามประจำวันเสาร์ว่า "นาคา" (นาค) และธาตุประจำวันคือธาตุไฟ '
 'ว่าผู้เกิดวันนี้ใจแข็งโกรธแรงดุจเพลิง มีศรัทธาหาญกล้า มิตรสหายมาก '
 'เก็บเงินทองได้มั่นคง ชายมักชอบทางบรรพชิต',
 'ตำราเก่าว่าคนเกิดวันเสาร์ นามนาค ธาตุไฟ ใจแข็งโกรธแรง กล้าหาญ '
 'เพื่อนมาก และเก็บเงินอยู่')
),
p as (
  select p.id from content.passage p
  join content.edition e on e.id = p.edition_id
  where e.citekey = 'phrommachat-2506' and p.sequence = 14 limit 1
),
tr as (select id from content.tradition where slug = 'folk-central')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id, v.body, v.plain, 'historical_belief',
  'เป็นความเชื่อที่บันทึกไว้ในตำราพรหมชาติ ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
  'และไม่ใช่การประเมินนิสัยของบุคคล | รอสอบทานกับพรหมชาติฉบับพิมพ์อื่นก่อนเผยแพร่',
  '{}', 'draft', null
from v
join content.symbol s on s.concept_key = v.concept_key
cross join p cross join tr
where not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.passage_id = (select id from p));

-- ---------------------------------------------------------------------------
-- Assert the intent. These inserts join content.category, content.edition and
-- content.symbol; a join that matches nothing is zero rows, not an error.
-- ---------------------------------------------------------------------------
do $$
declare got int;
begin
  select count(*) into got from content.symbol
   where concept_key like 'BIRTHDAY_%';
  if got <> 7 then
    raise exception 'taksa v1: expected 7 birthday symbols, found %', got;
  end if;

  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.concept_key like 'BIRTHDAY_%';
  if got <> 7 then
    raise exception 'taksa v1: expected 7 readings, found % '
      '(is the edition phrommachat-2506 present?)', got;
  end if;

  -- Nothing here may be published: single copyrighted source, no corroboration.
  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.concept_key like 'BIRTHDAY_%' and i.status = 'published';
  if got <> 0 then
    raise exception 'taksa v1: % reading(s) published without a second source', got;
  end if;

  -- And they must stay invisible to the dream scanner.
  select count(*) into got from content.symbol_term t
    join content.symbol s on s.id = t.symbol_id
   where s.concept_key like 'BIRTHDAY_%';
  if got <> 0 then
    raise exception 'taksa v1: % search term(s) on birthday symbols — a dream '
      'mentioning วันอาทิตย์ would match a birth reading', got;
  end if;
end $$;

do $$
declare r record; bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then bad := bad + 1; end if;
  end loop;
  if bad > 0 then raise exception 'aborted: % rights invariant(s)', bad; end if;
end $$;

select
  (select count(*) from content.symbol where concept_key like 'BIRTHDAY_%') as birthday_symbols,
  (select count(*) from content.interpretation i
     join content.symbol s on s.id = i.symbol_id
    where s.concept_key like 'BIRTHDAY_%' and i.status = 'draft')            as draft_readings;
