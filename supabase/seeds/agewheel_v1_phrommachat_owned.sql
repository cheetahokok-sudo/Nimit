-- ============================================================================
-- วงราศีตามอายุ v1 — the twelve-figure wheel on หน้า ๑–๓
--
-- The book opens with this, before any ปีนักษัตร material, and it is a complete
-- self-contained system: twelve figures arranged in a circle, counted off
-- against the reader's CURRENT AGE, with the figure you land on giving the
-- verdict for that year of life.
--
--   ชาย  — count from เจดีย์ เวียนขวา, one step per year of age
--   หญิง — count from เจดีย์ เวียนซ้าย, one step per year of age
--
-- หน้า ๒ closes with the หมายเหตุ restating it: 'หญิงนับไปซ้าย ชายนับไปขวา
-- จนครบเท่าอายุปัจจุบันของท่าน'. The direction is the only thing that differs.
--
-- WHY THIS ONE FIRST. The app already stores a birth date and computes from it;
-- age is the cheapest key it has, and nothing in the library uses it yet. All
-- twelve verdicts are fully legible in the scan — unusually, no [อ่านไม่ชัด]
-- interrupts any of them except two short clauses noted below. That makes this
-- the most complete stretch of ตำรา the project has ever held.
--
-- ── THE COUNTING RULE IS NOT MODELLED HERE, ON PURPOSE ─────────────────────
--
-- Only the twelve verdicts are content. The arithmetic that picks one — modulo
-- twelve, direction by sex — is app logic, and it is recorded in the passage's
-- modern_th so it is citable rather than folklore in someone's head. Putting a
-- formula in the database would give it a provenance it does not have: the ตำรา
-- states a procedure, and our implementation of that procedure is ours.
--
-- ── WHY astrology-natal AND NOT folk-brahmajati ────────────────────────────
--
-- The ปีนักษัตร material is about who you are, and sits in folk-brahmajati. This
-- is about what a given year of your life holds — ผูกดวงตามตำรา, which is what
-- astrology-natal was defined for and it has been empty since seed.sql. Its
-- standing ethics note is also the one this content needs: 'นำเสนอเชิงวัฒนธรรม
-- และความบันเทิง ไม่ใช่คำแนะนำเรื่องการเงิน สุขภาพ หรือกฎหมาย'. Two of the
-- twelve verdicts are precisely why — คอขาด promises 'คดีความถึงโรงถึงศาล' and
-- ราหู promises 'ปวดหัวตัวร้อนเป็นประจำ'. Neither may ever read as legal or
-- medical guidance, and the category note is surfaced in the UI, not filed away.
--
-- ── TERM-LESS, AND THE COLLISION IS ALREADY LIVE ───────────────────────────
--
-- Same rule as BIRTHDAY_* and ZODIAC_*, with a concrete casualty waiting: เจดีย์
-- is ALREADY a primary search term on two dream symbols, DREAM_PAGODA and
-- DREAM_STUPA. A user writing 'ฝันเห็นเจดีย์' must get the dream reading, not a
-- verdict about their current year of life. นาคราช likewise sits near
-- DREAM_NAGA. So no symbol_term rows, and the seed refuses to apply if one
-- appears.
--
-- ── ๑๒ ราศี IS THE BOOK'S PHRASE, NOT THE ZODIAC ───────────────────────────
--
-- The heading reads 'หลักการทำนายตาม ๑๒ ราศี', but these twelve are เจดีย์,
-- ฉัตรเงิน, คอขาด … not เมษ พฤษภ มิถุน. The concept keys therefore say AGEWHEEL
-- rather than RASI, so that real ราศี content arriving later from จักรทีปนี or
-- คัมภีร์โหราศาสตร์ cannot be confused with these.
--
-- ── ORDER, AND A TRANSCRIPTION THAT INVENTED ITS EVIDENCE ──────────────────
--
-- The sequence below is the book's own numbering ๑–๑๒ from หน้า ๑–๒, stated
-- outright in the text. That is now the ONLY evidence of order, and the reason
-- is worth recording.
--
-- The first version of this file said หน้า ๓ carried a wheel diagram whose
-- figures were captioned in a DIFFERENT order, and held the counting rule as
-- unverified because of it. That conflict did not exist. หน้า ๓ is blank in
-- this scan, and the machine transcription's '[ภาพประกอบ: วงกลมแสดงตำแหน่ง...]'
-- block — twelve figure names and all — was fabricated.
--
-- The book itself points at that page: หน้า ๒ closes with หมายเหตุ : ดูภาพประกอบ
-- หน้า ๓. So the diagram is real in the printed volume and simply missing from
-- the scan. What cannot be confirmed is whether the numbered order matches the
-- circular arrangement; nothing contradicts it, and counting ๑, ๒, ๓ round a
-- circle is the ordinary reading, so it is used and labelled as unconfirmed
-- rather than treated as settled.
--
-- ── FOUR FIGURE NAMES WERE WRONG, FROM THE SAME TRANSCRIPTION ──────────────
--
-- Read off the page image of หน้า ๒, positions ๘–๑๑ are:
--
--   ๘  เทวดาขี่เต่า   (transcribed as เทวดาขี่ม้า)
--   ๙  คนต้องขื่อคา   (transcribed as คนต้องเชือก)
--   ๑๐ พ่อมด        (transcribed as หอคอย)
--   ๑๑ แม่มด        (transcribed as แม่หม้าย)
--
-- พ่อมด and แม่มด are a matched pair, which is a good sign the corrected
-- reading is right and the transcription's หอคอย/แม่หม้าย were not near-misses
-- but substitutions. The concept keys changed with them; the retired ones are
-- cleaned up below because they never reached a live database, only CI.
--
-- The bodies for ๘–๑๒ are also rewritten from the page rather than from the
-- transcription, which lost ชะตากำลังดี มีผู้มาอ่อนน้อมยอมเป็นคนรับใช้ from ๑๒
-- to [อ่านไม่ชัด] and turned บริวาร into ธุระ in ๘.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Retire the four concept keys that came from the fabricated transcription.
-- Safe: they were never published and never left CI, and interpretation
-- cascades from symbol. Guarded to the exact four so it can never widen.
-- ---------------------------------------------------------------------------
delete from content.symbol
 where concept_key in ('AGEWHEEL_DEVA_ON_HORSE', 'AGEWHEEL_BOUND_MAN',
                       'AGEWHEEL_WATCHTOWER', 'AGEWHEEL_WIDOW');

drop table if exists tmp_agewheel;
create temporary table tmp_agewheel (
  pos int, concept_key text, slug text, name_th text, name_en text,
  verdict text, body text, plain text
);

insert into tmp_agewheel values
(1, 'AGEWHEEL_CHEDI', 'age-wheel-chedi', 'เจดีย์', 'the stupa', 'ดี',
 'ตำราว่าปีที่ตกเจดีย์ จะอยู่ร่มเย็นเป็นสุข มีความสุขกายสบายใจ '
 'จะได้ทำบุญกุศลในศาสนา และปรารถนาสิ่งใดมักได้สมใจนึก',
 'ตำราว่าปีที่ตกเจดีย์เป็นปีที่ร่มเย็นเป็นสุข ได้ทำบุญ และมักได้สมใจที่คิดไว้'),
(2, 'AGEWHEEL_SILVER_PARASOL', 'age-wheel-silver-parasol', 'ฉัตรเงิน', 'the silver parasol', 'ดี',
 'ตำราว่าปีที่ตกฉัตรเงิน จะมีลาภพอใช้สอยสบาย ไม่เดือดร้อนภายในครอบครัว '
 'และไปทางทิศใดก็มักมีผู้อุปถัมภ์ค้ำชูพอประมาณ',
 'ตำราว่าปีที่ตกฉัตรเงินจะมีลาภพอใช้ ครอบครัวไม่เดือดร้อน และมีคนช่วยเหลือพอสมควร'),
(3, 'AGEWHEEL_BEHEADING', 'age-wheel-beheading', 'คอขาด', 'the beheading', 'ร้าย',
 'ตำราว่าปีที่ตกคอขาดเป็นปีไม่ดี ว่าจะร้อนอกร้อนใจ มีเรื่องถึงโรงถึงศาล '
 'ต้องเสียเงินทองของรัก ไม่มีเวลาประกอบอาชีพ และการค้าจะฝืดเคือง',
 'ตำราว่าปีที่ตกคอขาดเป็นปีไม่ดี มีเรื่องร้อนใจ เสียทรัพย์ และการงานติดขัด'),
(4, 'AGEWHEEL_ROYAL_HOUSE', 'age-wheel-royal-house', 'เรือนหลวง', 'the royal house', 'ดี',
 'ตำราว่าปีที่ตกเรือนหลวง จะมีความสุขกายสบายใจ มีที่พึ่งพิงในความเป็นอยู่ '
 'และผู้รับราชการจะได้เลื่อนยศฐานบรรดาศักดิ์',
 'ตำราว่าปีที่ตกเรือนหลวงจะสุขสบาย มีที่พึ่ง และคนรับราชการมักได้เลื่อนขั้น'),
(5, 'AGEWHEEL_PALACE', 'age-wheel-palace', 'ปราสาท', 'the palace', 'ดีมาก',
 'ตำราว่าปีที่ตกปราสาทเป็นปีดีที่สุดในวง ว่าจะมีความสุขอย่างยิ่ง '
 'ประสบโชคลาภมากมาย และคิดสิ่งใดจะได้สมความปรารถนา',
 'ตำราว่าปีที่ตกปราสาทเป็นปีดีที่สุด มีความสุขมาก โชคลาภดี และสมหวังในสิ่งที่คิด'),
(6, 'AGEWHEEL_RAHU', 'age-wheel-rahu', 'ราหู', 'Rahu', 'ร้าย',
 'ตำราว่าปีที่ตกราหูเป็นปีไม่ดี ว่าจะเดือดร้อนใจ อาจมีเรื่องทะเลาะวิวาทเป็นคดีความ '
 'มีผู้คอยยุแหย่ให้วุ่นวาย และมักมีอาการปวดหัวตัวร้อนอยู่เป็นประจำ',
 'ตำราว่าปีที่ตกราหูเป็นปีไม่ดี ใจไม่สงบ มีเรื่องกระทบกระทั่ง และสุขภาพไม่ค่อยสบาย'),
(7, 'AGEWHEEL_GOLD_PARASOL', 'age-wheel-gold-parasol', 'ฉัตรทอง', 'the golden parasol', 'ดีมาก',
 'ตำราว่าปีที่ตกฉัตรทองเป็นปีดีมาก ว่าจะมีเกียรติยศปรากฏในหมู่คนทั่วไป '
 'ไปสารทิศใดก็จะมีผู้คอยอุปถัมภ์ค้ำชู ไม่เดือดร้อน',
 'ตำราว่าปีที่ตกฉัตรทองเป็นปีดีมาก มีชื่อเสียงเป็นที่รู้จัก และมีคนคอยช่วยเหลือ'),
(8, 'AGEWHEEL_DEVA_ON_TURTLE', 'age-wheel-deva-on-turtle', 'เทวดาขี่เต่า', 'the deva on a turtle', 'ปานกลาง',
 'ตำราว่าปีที่ตกเทวดาขี่เต่าเป็นปีค่อนข้างดี ว่าจะมีผู้คอยช่วยเหลือในหน้าที่การงาน '
 'แต่ให้ระวังบริวารจะนำความเดือดร้อนมาให้ จัดเป็นปีดีปานกลาง',
 'ตำราว่าปีที่ตกเทวดาขี่เต่าค่อนข้างดี มีคนช่วยเรื่องงาน แต่ให้ระวังบริวารจะพาให้เดือดร้อน'),
(9, 'AGEWHEEL_CANGUE', 'age-wheel-cangue', 'คนต้องขื่อคา', 'the man in the cangue', 'ร้าย',
 'ตำราว่าปีที่ตกคนต้องขื่อคาเป็นปีไม่ดี ว่าถึงคราวเคราะห์หามยามร้าย '
 'จะมีเรื่องวุ่นวายทั้งกับตนเองและครอบครัว จะถูกจองจำ '
 'หรือไม่มีความสุขกายสบายใจเลย',
 'ตำราว่าปีที่ตกคนต้องขื่อคาเป็นปีไม่ดี เคราะห์หามยามร้าย '
 'มีเรื่องวุ่นวายทั้งกับตัวเองและทางบ้าน'),
(10, 'AGEWHEEL_SORCERER', 'age-wheel-sorcerer', 'พ่อมด', 'the sorcerer', 'ปานกลาง',
 'ตำราว่าปีที่ตกพ่อมดเป็นปีดีปานกลาง ว่าจะมีผู้มาขอความช่วยเหลือ '
 'และการรับอาสาเจ้านายจะได้ดี แต่ความสุขไม่มากนัก '
 'และจะทุกข์กายทุกข์ใจอยู่พอประมาณ',
 'ตำราว่าปีที่ตกพ่อมดดีปานกลาง มีคนมาขอให้ช่วย รับอาสาเจ้านายแล้วได้ดี '
 'แต่ก็เหนื่อยกายเหนื่อยใจอยู่บ้าง'),
(11, 'AGEWHEEL_WITCH', 'age-wheel-witch', 'แม่มด', 'the witch', 'ปานกลาง',
 'ตำราว่าปีที่ตกแม่มดเป็นปีดีปานกลาง ว่าจะมีผู้นำลาภมาให้ '
 'แต่ต้องแลกเปลี่ยนกับความช่วยเหลือจากตนเอง '
 'จะสบายใจพอประมาณแต่ก็จะเหนื่อยใจ',
 'ตำราว่าปีที่ตกแม่มดดีปานกลาง มีลาภเข้ามาแต่ต้องออกแรงแลก และเหนื่อยใจอยู่บ้าง'),
(12, 'AGEWHEEL_NAGA_KING', 'age-wheel-naga-king', 'นาคราช', 'the naga king', 'ปานกลาง',
 'ตำราว่าปีที่ตกนาคราชเป็นปีดีปานกลาง ว่าจะมีอำนาจวาสนา ชะตากำลังดี '
 'มีผู้มาอ่อนน้อมยอมเป็นคนรับใช้ และจะได้ลาภจากบริวารและผู้ใหญ่ '
 'แต่ให้ระวังคำพูดและอารมณ์ของตนให้มาก',
 'ตำราว่าปีที่ตกนาคราชดีปานกลาง ชะตากำลังดี มีคนยอมอ่อนน้อม '
 'ได้ลาภจากคนรอบตัว แต่ให้ระวังคำพูดและอารมณ์');

-- ---------------------------------------------------------------------------
-- Check the payload before writing. Twelve positions, each used once.
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  select count(*) into n from tmp_agewheel;
  if n <> 12 then raise exception 'agewheel v1: the wheel has 12 positions, payload has %', n; end if;

  select count(*) into n from tmp_agewheel where pos not between 1 and 12;
  if n > 0 then raise exception 'agewheel v1: % position(s) outside 1–12', n; end if;

  select count(*) into n from (select pos from tmp_agewheel group by 1 having count(*) > 1) d;
  if n > 0 then raise exception 'agewheel v1: % duplicated position(s) — the counting rule '
    'depends on each step landing somewhere distinct', n; end if;

  select count(*) into n from (select concept_key from tmp_agewheel group by 1 having count(*) > 1) d;
  if n > 0 then raise exception 'agewheel v1: % duplicated concept_key(s)', n; end if;
end $$;

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select a.concept_key, a.slug, a.name_th, a.name_en, c.id, 'published', now()
from tmp_agewheel a
join content.category c on c.slug = 'astrology-natal'
on conflict (concept_key) do nothing;

-- ---------------------------------------------------------------------------
-- One passage for the whole system. The counting rule lives in modern_th so it
-- is citable; no original_text_th, per the guard in sources_v8.
-- ---------------------------------------------------------------------------
insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, 'หน้า ๑–๓ หลักการทำนายตาม ๑๒ ราศี', 1, null,
  'ระบบทำนายดวงประจำปีตามอายุ ประกอบด้วยรูปสิบสองรูปเรียงเป็นวง '
  'วิธีนับตามตำรา: เริ่มนับปีที่หนึ่งจากรูปเจดีย์ ผู้ชายเวียนขวา ผู้หญิงเวียนซ้าย '
  'นับไปทีละรูปจนครบเท่าจำนวนอายุปัจจุบัน แล้วถือคำทำนายของรูปที่อายุไปตกนั้น '
  'หน้า ๓ เป็นแผนภาพวงราศีพร้อมชื่อรูปทั้งสิบสอง',
  'เจ้าของโครงการ อ่านจากฉบับสแกน',
  'ทานหน้า ๑–๒ กับภาพหน้าจริงแล้ว แก้ชื่อรูปข้อ ๘–๑๑ และคำทำนายข้อ ๘ กับ ๑๒ '
  'ตามที่อ่านได้จากภาพ | '
  'ลำดับที่ใช้คือลำดับตัวเลข ๑–๑๒ ที่ตำราระบุไว้ในหน้า ๑–๒ ซึ่งเป็นหลักฐานเดียวที่มี | '
  'หน้า ๒ ปิดท้ายว่า "ดูภาพประกอบหน้า ๓" แต่หน้า ๓ ในฉบับสแกนนี้เป็นหน้าว่าง '
  'จึงยังยืนยันไม่ได้ว่าลำดับตัวเลขตรงกับการเรียงรูปบนวงจริงหรือไม่ '
  'ไม่มีหลักฐานใดขัดแย้ง จึงใช้ลำดับตัวเลขไปก่อนและระบุไว้ว่ายังไม่ยืนยัน',
  'draft'
from content.edition e where e.citekey = 'phrommachat-owned'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- The twelve verdicts.
-- ---------------------------------------------------------------------------
with p as (
  select p.id from content.passage p
  join content.edition e on e.id = p.edition_id
  where e.citekey = 'phrommachat-owned' and p.sequence = 1 limit 1
),
tr as (select id from content.tradition where slug = 'brahmajati')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status)
select s.id, p.id, tr.id, a.body, a.plain, 'historical_belief',
  'เป็นความเชื่อตามตำราพรหมชาติ ไม่ใช่ข้อเท็จจริงทางวิทยาศาสตร์ '
  'ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง และไม่ใช่คำแนะนำทางกฎหมาย การเงิน หรือการแพทย์ | '
  'คำทำนายนี้ผูกกับอายุปัจจุบัน ไม่ใช่ปีเกิด และเปลี่ยนทุกปี | '
  'อ่านจากฉบับรวมเล่มที่มีคำอธิบายของผู้เรียบเรียงปนอยู่ รอสอบทานกับฉบับอื่นก่อนเผยแพร่',
  '{}', 'draft'
from tmp_agewheel a
join content.symbol s on s.concept_key = a.concept_key
cross join p cross join tr
where not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.passage_id = (select id from p));

-- ---------------------------------------------------------------------------
-- Assert the intent.
-- ---------------------------------------------------------------------------
do $$
declare got int;
begin
  select count(*) into got from content.symbol s
    join content.category c on c.id = s.category_id
   where s.concept_key like 'AGEWHEEL_%' and c.slug = 'astrology-natal'
     and s.status = 'published';
  if got <> 12 then
    raise exception 'agewheel v1: expected 12 published symbols in astrology-natal, found %', got;
  end if;

  -- เจดีย์ and นาคราช are live dream vocabulary. One term here and
  -- 'ฝันเห็นเจดีย์' starts competing with a verdict about the reader's age.
  select count(*) into got from content.symbol_term t
    join content.symbol s on s.id = t.symbol_id
   where s.concept_key like 'AGEWHEEL_%';
  if got > 0 then
    raise exception 'agewheel v1: % search term(s) on age-wheel symbols — a dream '
      'about a เจดีย์ would match a fortune-by-age verdict', got;
  end if;

  -- And the dream symbols must still own those words.
  select count(*) into got from content.symbol_term t
    join content.symbol s on s.id = t.symbol_id
   where (s.concept_key, t.term) in (
     ('DREAM_PAGODA','เจดีย์'), ('DREAM_STUPA','เจดีย์'));
  if got <> 2 then
    raise exception 'agewheel v1: expected 2 carry-over เจดีย์ dream terms, found %', got;
  end if;

  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.concept_key like 'AGEWHEEL_%';
  if got <> 12 then
    raise exception 'agewheel v1: expected 12 verdicts, found % '
      '(is sources_v8_phrommachat_owned.sql applied?)', got;
  end if;

  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.concept_key like 'AGEWHEEL_%' and i.status <> 'draft';
  if got > 0 then
    raise exception 'agewheel v1: % verdict(s) left draft before a second source '
      'was consulted', got;
  end if;

  -- This wheel keys off age, never off birth month. A stray month scope here
  -- would silently hide verdicts from most readers.
  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.concept_key like 'AGEWHEEL_%'
     and coalesce(array_length(i.applies_to_lunar_months, 1), 0) > 0;
  if got > 0 then
    raise exception 'agewheel v1: % verdict(s) scoped to lunar months — this system '
      'reads by age, not by birth month', got;
  end if;
end $$;

do $$
declare bad int;
begin
  select coalesce(sum(violations), 0) into bad from ops.assert_rights_invariants();
  if bad > 0 then raise exception 'aborted: % rights invariant(s)', bad; end if;
end $$;

drop table if exists tmp_agewheel;

select s.name_th, i.status::text as reading_status,
       left(i.summary_plain_th, 44) || '…' as summary
from content.symbol s
join content.interpretation i on i.symbol_id = s.id
where s.concept_key like 'AGEWHEEL_%'
order by s.slug;
