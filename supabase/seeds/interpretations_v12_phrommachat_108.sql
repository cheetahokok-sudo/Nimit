-- ============================================================================
-- Content set 12: ตำรับทำนายฝัน ๑๐๘ ข้อ — พรหมชาติ ฉบับสมบูรณ์ หน้า ๒๒๗–๒๓๑
--
-- EVERYTHING IN THIS FILE IS A DRAFT, ON PURPOSE. Read this before changing
-- any status to 'published'.
--
-- The source is the owned 730-page compilation registered by
-- sources_v8_phrommachat_owned. That file spelled out the rule this one obeys:
-- a compilation edition mixes public-domain ตำรา with the compiler's own
-- copyrighted commentary, nothing in the schema can tell them apart, and so
-- "nothing drawn from this book publishes on its own say-so". The
-- mixed_compilation_uncorroborated blocker in scripts/review-checks.sql
-- enforces it, and would fire on all 64 readings below the moment they went
-- published with an empty corroborating_edition_ids.
--
-- So they land as drafts, with the corroboration left for whoever finds the
-- second witness. The obvious candidate is the 145-page ๒๕๐๖ edition, which is
-- already in the library as a scanned source.
--
-- ── The compiler's hand is provably in this list ───────────────────────────
--
-- This is not a precaution against a theoretical risk. Items ๓๒ and ๓๓ read
-- ฝันว่า ขึ้นเครื่องบิน and ฝันว่า เห็นเครื่องบินตก. An anonymous ตำรา old
-- enough to be public domain under ม.19/21 does not contain aeroplane omens.
-- Those two entries were written by the compiler, in the same numbered
-- sequence and the same typeface as material that genuinely is old.
--
-- They are therefore NOT inserted below at all — not even as drafts. The
-- symbol DREAM_AIRPLANE exists (see dream_symbols_v9) so the word is
-- searchable and a dreamer meets the honest empty state instead of silence,
-- but no reading is recorded from this book, because the only thing this book
-- can tell us about that reading is that a living author wrote it.
--
-- The remaining 106 items are not thereby cleared. They are merely not
-- self-evidently modern. That is a weaker claim, and the draft status carries
-- the difference.
--
-- ── What the transcription is ──────────────────────────────────────────────
--
-- First pass over an image-only scan, marked by its own header as requiring a
-- second visual review. Roughly twenty of the 108 items carry [อ่านไม่ชัด] in
-- the operative clause — the symbol, the verdict, or both. Those are omitted
-- rather than guessed: an omen list where the reader cannot tell which word
-- was reconstructed is worth less than a shorter one that is certain.
--
-- 63 readings are recorded from 106 eligible items.
--
-- ── One genuine contradiction, preserved ───────────────────────────────────
--
-- ข้อ ๗ says dreaming of eating with family brings ลาภ. ข้อ ๙๗ says dreaming
-- of eating brings ป่วยไข้. Both are recorded, on their own pages, because the
-- book says both and flattening them into one verdict would be the editor
-- deciding what the ตำรา meant. The app already shows multiple readings per
-- symbol with their locators.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Passages. Draft, like everything here — the transcription has not had its
-- second visual review, and the page images are the only witness.
-- ---------------------------------------------------------------------------

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, v.locator, v.seq, v.orig, v.modern,
  'Claude (AI) — อ่านจากไฟล์ถอดความรอบแรกของสำเนาที่เจ้าของถือครอง',
  -- The English "double-key" is load-bearing, not decoration. The
  -- single_key_transcription check in scripts/review-checks.sql finds
  -- un-reviewed transcriptions by matching that literal substring in this
  -- column. A Thai-only note reads identically to a human and is invisible to
  -- the check, so promoting these passages would put a first-pass reading of an
  -- image-only scan into the app with nothing warning about it.
  'ถอดความรอบแรกจากสแกนภาพ ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สอง (double-key) '
  'ตามระเบียบ B5 | ต้นฉบับมีเครื่องหมาย [อ่านไม่ชัด] หลายแห่ง '
  'ข้อที่คำสำคัญอ่านไม่ออกไม่ได้บันทึกเป็นคำทำนาย',
  'draft'
from (values
  ('หน้า ๒๒๗ ตำรับทำนายฝัน ๑๐๘ ข้อ (ข้อ ๑–๑๐ และตารางฝันตามวัน)', 227,
   'ตำรับทำนายฝัน ๑๐๘ ข้อ สิทธิการิยะ เกจิอาจารย์ท่านรวบรวมไว้ '
   'ใช้ถือสืบต่อกันมา เรื่องนิมิตฝันของคนเราว่าเกิดขึ้นได้อย่างไร '
   'ถ้าฝันวันอาทิตย์ นิมิตนั้นได้แก่ ปวงประชา วันจันทร์ ญาติ '
   'วันอังคาร บิดามารดา วันพุธ บุตร ภริยา วันพฤหัสบดี ครูอาจารย์ '
   'วันศุกร์ เพื่อนฝูง วันเสาร์ ตัวเอง',
   'หน้าเปิดหมวด ให้ตารางว่าฝันในวันใดเป็นนิมิตถึงผู้ใด '
   'แล้วจึงขึ้นรายการคำทำนาย ๑๐๘ ข้อ'),
  ('หน้า ๒๒๘ ตำรับทำนายฝัน ๑๐๘ ข้อ (ข้อ ๑๑–๓๒)', 228,
   'ตำราพรหมชาติ ข้อ ๑๑ ถึง ๓๒ ว่าด้วยคำทำนายฝันรายสัญลักษณ์',
   'หน้านี้มีข้อ ๓๒ ว่าด้วยเครื่องบิน ซึ่งเป็นข้อความของผู้เรียบเรียงยุคใหม่ '
   'ไม่ใช่ตำราเก่า'),
  ('หน้า ๒๒๙ ตำรับทำนายฝัน ๑๐๘ ข้อ (ข้อ ๓๓–๕๘)', 229,
   'ตำรับทำนายฝัน ๑๐๘ ข้อ ข้อ ๓๓ ถึง ๕๘ ว่าด้วยคำทำนายฝันรายสัญลักษณ์',
   'หน้านี้มีข้อ ๓๓ ว่าด้วยเครื่องบินตก ซึ่งเป็นข้อความของผู้เรียบเรียงยุคใหม่'),
  ('หน้า ๒๓๐ ตำรับทำนายฝัน ๑๐๘ ข้อ (ข้อ ๕๙–๘๔)', 230,
   'ตำราพรหมชาติ ข้อ ๕๙ ถึง ๘๔ ว่าด้วยคำทำนายฝันรายสัญลักษณ์',
   'หน้านี้รวมฝันเกี่ยวกับความตาย สัตว์ และทรัพย์'),
  ('หน้า ๒๓๑ ตำรับทำนายฝัน ๑๐๘ ข้อ (ข้อ ๘๕–๑๐๘)', 231,
   'ตำรับทำนายฝัน ๑๐๘ ข้อ ข้อ ๘๕ ถึง ๑๐๘ อันเป็นข้อสุดท้ายของหมวด',
   'หน้าปิดหมวด ข้อ ๑๐๘ อ่านไม่ออกทั้งข้อ')
) as v(locator, seq, orig, modern)
cross join content.edition e
where e.citekey = 'phrommachat-owned'
on conflict (edition_id, locator, sequence) do nothing;

-- Repair for rows applied before the note carried the double-key marker. The
-- insert above is on-conflict-do-nothing, so an earlier run's note would
-- survive untouched and stay invisible to single_key_transcription. Idempotent:
-- once the marker is present the predicate matches nothing.
update content.passage p
   set transcription_note_th =
       'ถอดความรอบแรกจากสแกนภาพ ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สอง (double-key) '
       'ตามระเบียบ B5 | ต้นฉบับมีเครื่องหมาย [อ่านไม่ชัด] หลายแห่ง '
       'ข้อที่คำสำคัญอ่านไม่ออกไม่ได้บันทึกเป็นคำทำนาย'
  from content.edition e
 where e.id = p.edition_id
   and e.citekey = 'phrommachat-owned'
   and p.sequence between 227 and 231
   and p.transcription_note_th not ilike '%double-key%';

-- ---------------------------------------------------------------------------
-- Readings. Draft. corroborating_edition_ids stays empty and MUST be filled
-- before any of these is promoted — that is the whole point of the file.
-- ---------------------------------------------------------------------------

with v(seq, item, concept_key, body, plain) as (values
-- ── หน้า ๒๒๗ ───────────────────────────────────────────────────────────────
(227,3,'DREAM_CORPSE',
 'ตำราว่าการฝันว่าได้กอดศพ ผู้ฝันมักจะเสียของรัก',
 'ฝันว่ากอดศพ ตำราเก่าว่ามักจะเสียของรัก'),
(227,5,'DREAM_RING',
 'ตำราว่าการฝันว่าได้แหวนและได้สวม ผู้ฝันจะได้เนื้อคู่ที่ถูกใจ '
 'ถ้ามีสามีภรรยาอยู่แล้ว ท่านว่าจะมีบุตรอันเป็นที่รัก',
 'ฝันว่าได้แหวนมาสวม ตำราเก่าว่าจะได้คู่ที่ถูกใจ ถ้ามีคู่แล้วจะได้ลูก'),
(227,6,'DREAM_FRUIT',
 'ตำราว่าการฝันว่าเก็บผลไม้ได้ ผู้ฝันจะได้ของที่รักอันถูกอกถูกใจ',
 'ฝันว่าเก็บผลไม้ได้ ตำราเก่าว่าจะได้ของที่ถูกใจ'),
(227,7,'DREAM_EATING',
 'ตำราว่าการฝันว่าได้กินอาหารร่วมกับพ่อ แม่ ลูก และภรรยา '
 'ผู้ฝันจะได้ลาภผลเป็นที่ถูกใจยิ่งนัก',
 'ฝันว่าได้กินข้าวร่วมกับคนในครอบครัว ตำราเก่าว่าจะได้ลาภที่ถูกใจ'),
(227,8,'DREAM_PRISON',
 'ตำราว่าการฝันว่าถูกจับเข้าคุกตะราง หรือถูกใส่ตรวน '
 'ผู้ฝันจะได้เปลี่ยนงาน หรือได้หน้าที่สูงขึ้นไป',
 'ฝันว่าติดคุกหรือถูกใส่ตรวน ตำราเก่าว่าจะได้เปลี่ยนงานหรือได้ตำแหน่งสูงขึ้น'),
(227,9,'DREAM_BEHEADING',
 'ตำราว่าการฝันว่าถูกตัดหัวหรือตัดมือ ผู้ฝันจะได้เลื่อนยศ',
 'ฝันว่าถูกตัดหัวหรือตัดมือ ตำราเก่าว่าจะได้เลื่อนยศ'),
-- ── หน้า ๒๒๘ ───────────────────────────────────────────────────────────────
(228,11,'DREAM_DRINK_WATER',
 'ตำราว่าการฝันว่าได้ดื่มน้ำหรือเครื่องดื่ม ท่านทายว่าจะได้กินส่วนที่เหลือ',
 'ฝันว่าได้ดื่มน้ำ ตำราเก่าว่าจะได้ของที่เหลือจากคนอื่น'),
(228,12,'DREAM_FIRE',
 'ตำราว่าการฝันว่าไฟไหม้เรือนของตน ผู้ฝันจะเดือดร้อนเรื่องที่อยู่อาศัย '
 'แต่ถ้าฝันว่าไฟไหม้เรือนผู้อื่น ท่านทายว่าตนจะอยู่เย็นเป็นสุข',
 'ฝันว่าไฟไหม้บ้านตัวเอง ตำราเก่าว่าจะเดือดร้อนเรื่องที่อยู่ '
 'แต่ถ้าไหม้บ้านคนอื่นกลับว่าจะอยู่เย็นเป็นสุข'),
(228,13,'DREAM_FLYING',
 'ตำราว่าการฝันว่าเหาะเหินเดินอากาศได้ ผู้ฝันจะได้สิ่งใดสมใจนึก',
 'ฝันว่าเหาะได้ ตำราเก่าว่าจะสมหวังดังใจ'),
(228,14,'DREAM_CHILD',
 'ตำราว่าการฝันว่ามีเด็กเล็ก ๆ มาอาศัยเต็มบ้านเรือน '
 'ผู้ฝันจะได้บริวาร และจะได้เป็นเจ้าคนนายคน',
 'ฝันว่ามีเด็กเล็กมาอยู่เต็มบ้าน ตำราเก่าว่าจะมีคนช่วยงานและได้เป็นหัวหน้าคน'),
(228,17,'DREAM_SOLDIER',
 'ตำราว่าการฝันว่าเห็นทหาร ผู้ฝันจะถูกเพื่อนฝูงใส่ความ',
 'ฝันเห็นทหาร ตำราเก่าว่าจะถูกเพื่อนใส่ความ'),
(228,22,'DREAM_TEMPLE',
 'ตำราว่าการฝันว่าได้เข้าวัดฟังเทศน์ ผู้ฝันจะสุขสบายใจยิ่งนัก',
 'ฝันว่าได้เข้าวัดฟังเทศน์ ตำราเก่าว่าจะสบายใจมาก'),
(228,23,'DREAM_BUDDHA_IMAGE',
 'ตำราว่าการฝันว่าเห็นพระพุทธรูป ผู้ฝันจะมีอำนาจ และศัตรูจะพ่ายแพ้',
 'ฝันเห็นพระพุทธรูป ตำราเก่าว่าจะมีอำนาจ ศัตรูจะแพ้ไป'),
(228,24,'DREAM_TEACHER',
 'ตำราว่าการฝันว่าเห็นครูอาจารย์ ผู้ฝันมีสิ่งใดปรารถนาจะสมประสงค์',
 'ฝันเห็นครูอาจารย์ ตำราเก่าว่าจะสมประสงค์'),
(228,26,'DREAM_RICH_MAN',
 'ตำราว่าการฝันเกี่ยวกับเศรษฐี ผู้ฝันจะมีอำนาจวาสนา ผู้คนจะสรรเสริญ',
 'ฝันเห็นเศรษฐี ตำราเก่าว่าจะมีอำนาจวาสนาและมีคนสรรเสริญ'),
(228,27,'DREAM_LIGHTNING',
 'ตำราว่าการฝันว่าฟ้าผ่าตน ผู้ฝันจะเดือดร้อนเพราะผู้ใหญ่',
 'ฝันว่าฟ้าผ่าตัวเอง ตำราเก่าว่าจะเดือดร้อนเพราะผู้ใหญ่'),
(228,28,'DREAM_SNAKE',
 'ตำราว่าการฝันว่างูเขียวมาพันตัว ผู้ฝันจะพบเนื้อคู่ในเร็ววัน '
 'และข้อถัดมาว่าถ้าถูกงูพิษไล่ตามหลัง จะได้คู่ครองที่ต้องอารมณ์',
 'ฝันว่างูเขียวมาพันตัว ตำราเก่าว่าจะพบเนื้อคู่ในไม่ช้า'),
(228,30,'DREAM_HOUSE',
 'ตำราว่าการฝันว่าขึ้นบ้านใหม่ ผู้ฝันจะได้เลื่อนยศเลื่อนตำแหน่งการงาน',
 'ฝันว่าขึ้นบ้านใหม่ ตำราเก่าว่าจะได้เลื่อนตำแหน่ง'),
(228,31,'DREAM_BOAT',
 'ตำราว่าการฝันว่านั่งเรือข้ามน้ำ ผู้ฝันจะมีศัตรูคอยปองร้าย แต่ทำอะไรไม่ได้',
 'ฝันว่านั่งเรือข้ามน้ำ ตำราเก่าว่าจะมีคนคิดร้ายแต่ทำอะไรไม่ได้'),
-- ── หน้า ๒๒๙ ───────────────────────────────────────────────────────────────
(229,35,'DREAM_TOOTH',
 'ตำราว่าการฝันว่าฟันกรามหัก พ่อแม่หรือญาติผู้ใหญ่จะเสียชีวิต '
 'และอีกข้อหนึ่งในหน้าเดียวกันว่า ฝันว่าฟันหัก จะเจ็บไข้และได้รับข่าวร้าย',
 'ฝันว่าฟันหัก ตำราเก่าว่าจะเจ็บไข้และได้ข่าวร้าย ถ้าเป็นฟันกราม '
 'ว่าถึงญาติผู้ใหญ่'),
(229,37,'DREAM_MONEY',
 'ตำราว่าการฝันว่าเก็บเงินทองได้ไม่รู้จักหมด ผู้ฝันคิดสิ่งใดจะสมปรารถนา',
 'ฝันว่าเก็บเงินทองได้ไม่หมด ตำราเก่าว่าคิดสิ่งใดจะสมหวัง'),
(229,39,'DREAM_CHASED',
 'ตำราว่าการฝันว่าเสือ ช้าง หรือหมาไล่ ผู้ฝันจะถูกศัตรูกลั่นแกล้งปองร้าย',
 'ฝันว่าถูกเสือ ช้าง หรือหมาไล่ ตำราเก่าว่าจะถูกคนกลั่นแกล้ง'),
(229,42,'DREAM_MONK',
 'ตำราว่าการฝันเกี่ยวกับการถวายแก่พระสงฆ์ ผู้ฝันจะสุขกายสบายใจ แต่ไม่สู้จะมีลาภ',
 'ฝันว่าได้ถวายของพระ ตำราเก่าว่าจะสบายใจ แต่ไม่ค่อยมีลาภ'),
(229,43,'DREAM_LIQUOR',
 'ตำราว่าการฝันว่าได้ดื่มกินสุรา อาหาร หรือเลือด ผู้ฝันจะป่วยไข้ไม่สบาย',
 'ฝันว่าได้ดื่มเหล้าหรือเลือด ตำราเก่าว่าจะเจ็บป่วย'),
(229,44,'DREAM_TREE',
 'ตำราว่าการฝันว่านั่งอยู่ใต้ร่มไม้ใหญ่ ผู้ฝันจะได้เป็นหัวหน้าหมู่คน',
 'ฝันว่านั่งใต้ต้นไม้ใหญ่ ตำราเก่าว่าจะได้เป็นหัวหน้าคน'),
(229,45,'DREAM_STABBED',
 'ตำราว่าการฝันว่าถูกมีดแทง ผู้ฝันจะเกิดศัตรูหรืออันตราย',
 'ฝันว่าถูกมีดแทง ตำราเก่าว่าจะมีศัตรูหรืออันตราย'),
(229,46,'DREAM_CRYING',
 'ตำราว่าการฝันว่าร้องไห้ ผู้ฝันจะมีเรื่องกลุ้มใจ แต่ต่อไปจะได้ลาภ',
 'ฝันว่าร้องไห้ ตำราเก่าว่าจะกลุ้มใจก่อน แล้วจึงได้ลาภ'),
(229,47,'DREAM_MOON',
 'ตำราว่าการฝันเห็นเดือนหงาย ท่านทายว่าคู่ครองจะนอกใจ '
 'และข้อถัดมาว่าฝันเห็นเดือนมืด จะมีเรื่องขุ่นใจกับคู่ครองคนรัก',
 'ฝันเห็นเดือนหงาย ตำราเก่าว่าคู่จะนอกใจ ถ้าเดือนมืดว่าจะขุ่นใจกัน'),
(229,50,'DREAM_FLOWER',
 'ตำราว่าการฝันว่าได้ตัดดอกไม้ ผู้ฝันจะได้เนื้อคู่ที่พอใจ',
 'ฝันว่าได้ตัดดอกไม้ ตำราเก่าว่าจะได้คู่ที่พอใจ'),
(229,52,'DREAM_PREGNANCY',
 'ตำราว่าการฝันว่าได้ลูกหรือคลอดลูก ผู้ฝันจะได้ลาภ โชควาสนากำลังดี',
 'ฝันว่าได้ลูกหรือคลอดลูก ตำราเก่าว่าจะได้ลาภ ดวงกำลังดี'),
(229,53,'DREAM_FALLING',
 'ตำราว่าการฝันว่าตกจากที่สูง ผู้ฝันจะเสียของรัก และลำบากกายลำบากใจ',
 'ฝันว่าตกจากที่สูง ตำราเก่าว่าจะเสียของรักและลำบากใจ'),
(229,56,'DREAM_DOG',
 'ตำราว่าการฝันว่าเห็นสุนัข ผู้ฝันจะมีเพื่อนฝูงที่เชื่อใจได้',
 'ฝันเห็นหมา ตำราเก่าว่าจะมีเพื่อนที่เชื่อใจได้'),
(229,57,'DREAM_CAT',
 'ตำราว่าการฝันว่าเห็นแมว ผู้ฝันจะเสียเงินทองไปกับการช่วยเหลือคนอื่น',
 'ฝันเห็นแมว ตำราเก่าว่าจะเสียเงินไปช่วยคนอื่น'),
-- ── หน้า ๒๓๐ ───────────────────────────────────────────────────────────────
(230,59,'DREAM_DEAD_PERSON',
 'ตำราว่าการฝันเกี่ยวกับคนตายในลักษณะนี้ ผู้ฝันจะอายุยืน ถ้าป่วยไข้อยู่จะหายดี',
 'ฝันแบบนี้เกี่ยวกับคนตาย ตำราเก่าว่าจะอายุยืน ถ้าป่วยอยู่จะหาย'),
(230,60,'DREAM_CROW',
 'ตำราว่าการฝันว่าเห็นแร้งกา ผู้ฝันจะเสียของรักของชอบใจ',
 'ฝันเห็นแร้งกา ตำราเก่าว่าจะเสียของรัก'),
(230,61,'DREAM_SNAKE',
 'ตำราว่าการฝันว่าเห็นงู ผู้ฝันจะมีเพศตรงข้ามมาเกี้ยวพาราสี',
 'ฝันเห็นงู ตำราเก่าว่าจะมีคนมาชอบ'),
(230,63,'DREAM_STABBED',
 'ตำราว่าการฝันว่าถูกแทงจนไส้ทะลัก ผู้ฝันจะได้เป็นใหญ่ ศัตรูจะเกรงขาม',
 'ฝันว่าถูกแทงจนไส้ทะลัก ตำราเก่าว่าจะได้เป็นใหญ่ ศัตรูจะเกรงกลัว'),
(230,64,'DREAM_CAR',
 'ตำราว่าการฝันว่านั่งรถลงเรือ ผู้ฝันจะโยกย้ายหน้าที่การงาน',
 'ฝันว่านั่งรถลงเรือ ตำราเก่าว่าจะย้ายงาน'),
(230,67,'DREAM_NECKLACE',
 'ตำราว่าการฝันว่าได้สวมสร้อยคอ ผู้ฝันจะได้คู่ครองที่รักใคร่กันมาก',
 'ฝันว่าได้ใส่สร้อยคอ ตำราเก่าว่าจะได้คู่ที่รักกันมาก'),
(230,68,'DREAM_CORPSE',
 'ตำราว่าการฝันว่าเห็นคนตายหรือเห็นศพผู้อื่น ผู้ฝันจะหมดเคราะห์ร้ายกลายเป็นดี',
 'ฝันเห็นศพคนอื่น ตำราเก่าว่าเคราะห์ร้ายจะกลายเป็นดี'),
(230,69,'DREAM_COW',
 'ตำราว่าการฝันว่าเห็นวัวควาย ผู้ฝันจะเหนื่อยกายและไม่สบายใจ',
 'ฝันเห็นวัวควาย ตำราเก่าว่าจะเหนื่อยกายไม่สบายใจ'),
(230,69,'DREAM_BUFFALO',
 'ตำราว่าการฝันว่าเห็นวัวควาย ผู้ฝันจะเหนื่อยกายและไม่สบายใจ '
 'ตำราไม่ได้แยกวัวออกจากควาย',
 'ฝันเห็นวัวควาย ตำราเก่าว่าจะเหนื่อยกายไม่สบายใจ'),
(230,70,'DREAM_MONEY',
 'ตำราว่าการฝันว่ามีคนเอาเงินมาให้ ผู้ฝันจะได้ลาภ '
 'แต่ให้ระวังจะถูกเอาเปรียบหรือถูกโกง',
 'ฝันว่ามีคนเอาเงินมาให้ ตำราเก่าว่าจะได้ลาภ แต่ให้ระวังถูกโกง'),
(230,74,'DREAM_INSECT',
 'ตำราว่าการฝันว่าเห็นแมลงต่าง ๆ ผู้ฝันจะเกิดทุกข์ยาก อันเกิดจากบุตรและบริวาร',
 'ฝันเห็นแมลง ตำราเก่าว่าจะมีเรื่องทุกข์ใจจากลูกหลานหรือคนใกล้ตัว'),
(230,76,'DREAM_RICE',
 'ตำราว่าการฝันว่าเห็นข้าวสารหรือข้าวสุก ผู้ฝันจะมีโชคลาภดี',
 'ฝันเห็นข้าวสารหรือข้าวสุก ตำราเก่าว่าจะมีโชคลาภ'),
(230,77,'DREAM_HANDKERCHIEF',
 'ตำราว่าการฝันว่ามีคนให้ผ้าเช็ดหน้า ผู้ฝันจะเกิดความยากลำบากและมีน้ำตาตก',
 'ฝันว่ามีคนให้ผ้าเช็ดหน้า ตำราเก่าว่าจะลำบากและต้องเสียน้ำตา'),
(230,79,'DREAM_HONEY',
 'ตำราว่าการฝันว่าได้กินน้ำผึ้ง ผู้ฝันจะได้เป็นใหญ่เป็นหัวหน้าคน',
 'ฝันว่าได้กินน้ำผึ้ง ตำราเก่าว่าจะได้เป็นใหญ่'),
(230,80,'DREAM_BATHING',
 'ตำราว่าการฝันว่าอาบน้ำ ผู้ฝันจะอยู่เย็นเป็นสุข',
 'ฝันว่าได้อาบน้ำ ตำราเก่าว่าจะอยู่เย็นเป็นสุข'),
-- ── หน้า ๒๓๑ ───────────────────────────────────────────────────────────────
(231,85,'DREAM_TREE',
 'ตำราว่าการฝันว่าเห็นต้นไม้เขียวชอุ่ม ผู้ฝันจะมีโชคข้าวของเงินทอง '
 'และข้อถัดมาว่าถ้าเห็นป่าไม้แห้งแล้ง จะเสียของรักของชอบใจ',
 'ฝันเห็นต้นไม้เขียวชอุ่ม ตำราเก่าว่าจะมีโชคลาภ ถ้าเห็นป่าแห้งแล้งว่าจะเสียของรัก'),
(231,88,'DREAM_SHOES',
 'ตำราว่าการฝันว่าเห็นรองเท้าหรือได้ใส่รองเท้า ผู้ฝันจะมีการเดินทางไกล '
 'และอีกข้อหนึ่งว่าถ้าได้สวมรองเท้าใหม่ จะได้บริวารที่ซื่อสัตย์',
 'ฝันเห็นหรือได้ใส่รองเท้า ตำราเก่าว่าจะได้เดินทางไกล '
 'ถ้าเป็นรองเท้าใหม่ว่าจะได้คนซื่อสัตย์มาช่วยงาน'),
(231,90,'DREAM_SUN',
 'ตำราว่าการฝันว่าเห็นดวงอาทิตย์ ผู้ฝันจะมีอำนาจวาสนา ศัตรูจะพ่ายแพ้',
 'ฝันเห็นดวงอาทิตย์ ตำราเก่าว่าจะมีอำนาจวาสนา ศัตรูจะแพ้'),
(231,91,'DREAM_LOTUS',
 'ตำราว่าการฝันว่าเห็นดอกบัว ผู้ฝันจะได้ยศบรรดาศักดิ์ มีบริวาร '
 'และจะได้ข่าวดี',
 'ฝันเห็นดอกบัว ตำราเก่าว่าจะได้ยศ ได้บริวาร และได้ข่าวดี'),
(231,93,'DREAM_MOUNTAIN',
 'ตำราว่าการฝันว่าขึ้นไปบนเขาหรือบนดอย ผู้ฝันจะได้เลื่อนตำแหน่งหน้าที่การงานสูงขึ้นไป',
 'ฝันว่าขึ้นเขาขึ้นดอย ตำราเก่าว่าจะได้เลื่อนตำแหน่งสูงขึ้น'),
(231,94,'DREAM_HAT',
 'ตำราว่าการฝันว่าได้หมวกหรือได้สวมหมวก ผู้ฝันจะมีผู้ใหญ่ให้พึ่งพาอาศัย '
 'ศัตรูจะไม่กล้าปองร้าย',
 'ฝันว่าได้หมวกหรือได้ใส่หมวก ตำราเก่าว่าจะมีผู้ใหญ่ช่วยเหลือ ศัตรูไม่กล้าทำร้าย'),
(231,96,'DREAM_WATER',
 'ตำราว่าการฝันว่าได้สัมผัสน้ำ ผู้ฝันจะเริ่มเป็นสุขปราศจากทุกข์',
 'ฝันว่าได้ถูกน้ำ ตำราเก่าว่าจะเริ่มเป็นสุข หมดทุกข์'),
(231,97,'DREAM_EATING',
 'ตำราว่าการฝันว่าได้รับประทานอาหาร ผู้ฝันจะเกิดป่วยไข้ไม่สบาย '
 'ข้อนี้ต่างจากข้อ ๗ ในหน้า ๒๒๗ ซึ่งว่าการกินอาหารร่วมกับครอบครัวจะได้ลาภ '
 'ตำราให้ไว้ทั้งสองอย่าง',
 'ฝันว่าได้กินอาหาร ตำราเก่าว่าจะเจ็บป่วย — ต่างจากข้อ ๗ ที่ว่าจะได้ลาภ '
 'ตำราบันทึกไว้ทั้งสองแบบ'),
(231,98,'DREAM_CRYING',
 'ตำราว่าการฝันว่าร้องไห้ ผู้ฝันจะหมดเคราะห์ร้ายต่าง ๆ',
 'ฝันว่าร้องไห้ ตำราเก่าว่าจะหมดเคราะห์'),
(231,100,'DREAM_STAR',
 'ตำราว่าการฝันว่าเห็นดาวและเดือน ผู้ฝันจะได้ลาภจากผู้ใหญ่',
 'ฝันเห็นดาวเห็นเดือน ตำราเก่าว่าจะได้ลาภจากผู้ใหญ่'),
(231,101,'DREAM_ELEPHANT',
 'ตำราว่าการฝันว่าเห็นช้างหรือควายเผือก ผู้ฝันจะได้ของรักของชอบใจ',
 'ฝันเห็นช้างเผือกหรือควายเผือก ตำราเก่าว่าจะได้ของที่ถูกใจ'),
(231,102,'DREAM_PALACE',
 'ตำราว่าการฝันว่าเห็นปราสาทราชวัง ผู้ฝันจะได้เป็นหัวหน้าคน มีอำนาจวาสนา',
 'ฝันเห็นปราสาทราชวัง ตำราเก่าว่าจะได้เป็นหัวหน้าคนและมีอำนาจ'),
(231,105,'DREAM_FORTUNE_TELLER',
 'ตำราว่าการฝันว่าพบหมอดู ผู้ฝันจะมีเรื่องเดือดร้อนกายและใจ',
 'ฝันว่าไปพบหมอดู ตำราเก่าว่าจะมีเรื่องเดือดร้อนกายใจ'),
(231,106,'DREAM_FRUIT',
 'ตำราว่าการฝันว่าได้รับประทานผลไม้ ผู้ฝันจะได้รับข่าวจากคนที่อยู่ไกล',
 'ฝันว่าได้กินผลไม้ ตำราเก่าว่าจะได้ข่าวจากคนไกล'),
(231,107,'DREAM_FALLING',
 'ตำราว่าการฝันว่าตกเขาหรือตกจากที่สูง ผู้ฝันจะเสื่อมเกียรติ '
 'จะถูกคนหมิ่นอำนาจวาสนา',
 'ฝันว่าตกเขาตกที่สูง ตำราเก่าว่าจะเสียเกียรติ ถูกคนดูหมิ่น')
),
p as (
  select p.id, p.sequence from content.passage p
  join content.edition e on e.id = p.edition_id
  where e.citekey = 'phrommachat-owned' and p.sequence between 227 and 231
),
tr as (select id from content.tradition where slug = 'folk-central')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status)
select s.id, p.id, tr.id, v.body, v.plain, 'historical_belief',
  'เป็นความเชื่อที่บันทึกไว้ในตำราพรหมชาติ ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
  'ฉบับนี้เป็นฉบับรวมเล่มที่มีคำอธิบายของผู้เรียบเรียงปนอยู่ '
  'ยังไม่ได้เผยแพร่จนกว่าจะพบแหล่งที่สองยืนยัน',
  '{}', 'draft'
from v
-- Not restricted to published symbols. 47 of these 63 readings hang off
-- symbols the lexicon already publishes; the remaining 16 hang off symbols
-- that dream_symbols_v9 creates as drafts. Filtering on 'published' here would
-- drop those 16 without a word, and the count guard below would be the only
-- sign anything had gone wrong.
--
-- Two of the 16 new symbols end up with no reading at all: เครื่องบิน by the
-- refusal described above, and มงกุฎ because ข้อ ๑ is illegible at the noun.
join content.symbol s on s.concept_key = v.concept_key
                     and s.status in ('draft','published')
join p on p.sequence = v.seq
cross join tr
where not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.passage_id = p.id);

-- ---------------------------------------------------------------------------
-- Guards.
-- ---------------------------------------------------------------------------
do $$
declare got int; leaked int; plane int; unmarked int;
begin
  -- Every passage must stay findable by single_key_transcription. If the note
  -- is ever rewritten without the marker, these pages could be promoted and go
  -- live as an un-reviewed first-pass reading with no warning attached.
  select count(*) into unmarked
    from content.passage p
    join content.edition e on e.id = p.edition_id
   where e.citekey = 'phrommachat-owned' and p.sequence between 227 and 231
     and p.transcription_note_th not ilike '%double-key%';
  if unmarked > 0 then
    raise exception 'phrommachat 108: % passage(s) lack the double-key marker — '
      'scripts/review-checks.sql matches that literal string and would not '
      'flag them once published', unmarked;
  end if;

  select count(*) into got
    from content.interpretation i
    join content.passage p on p.id = i.passage_id
    join content.edition e on e.id = p.edition_id
   where e.citekey = 'phrommachat-owned' and p.sequence between 227 and 231;
  if got <> 63 then
    raise exception 'phrommachat 108: expected 63 readings, found % — '
      'a missing symbol would make the join drop rows silently', got;
  end if;

  -- Nothing here may be published while corroboration is empty. If a later
  -- edit flips the status without filling corroborating_edition_ids, the
  -- review blocker would catch it — but catching it here is cheaper and names
  -- the reason.
  select count(*) into leaked
    from content.interpretation i
    join content.passage p on p.id = i.passage_id
    join content.edition e on e.id = p.edition_id
   where e.citekey = 'phrommachat-owned' and p.sequence between 227 and 231
     and i.status = 'published'
     and coalesce(array_length(i.corroborating_edition_ids, 1), 0) < 1;
  if leaked > 0 then
    raise exception 'phrommachat 108: % reading(s) published without a second '
      'witness — this edition mixes the compiler''s own text with the old '
      'ตำรา and cannot vouch for itself', leaked;
  end if;

  -- The two aeroplane items must never acquire a reading from this book.
  select count(*) into plane
    from content.interpretation i
    join content.passage p on p.id = i.passage_id
    join content.edition e on e.id = p.edition_id
    join content.symbol s on s.id = i.symbol_id
   where e.citekey = 'phrommachat-owned' and s.concept_key = 'DREAM_AIRPLANE';
  if plane > 0 then
    raise exception 'phrommachat 108: เครื่องบิน has a reading from this '
      'edition — ข้อ ๓๒ and ๓๓ are the compiler''s own modern writing, not '
      'the anonymous ตำรา, and cannot be published under a public-domain work';
  end if;
end $$;
