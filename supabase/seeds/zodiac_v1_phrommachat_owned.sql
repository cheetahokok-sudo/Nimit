-- ============================================================================
-- ปีนักษัตร v1 — สิบสองปีนักษัตรจากพรหมชาติฉบับรวมเล่มที่ถือครอง
--
-- THE SECOND CATEGORY TO BE FILLED FROM พรหมชาติ, and the first content ever
-- to land in folk-brahmajati, which has sat empty since seed.sql defined it.
--
-- ทักษาวันเกิด reads by วันเกิด; this reads by ปีเกิด. Together they are the two
-- keys ดวงของฉัน can actually compute from a stored birth date without asking
-- the user for anything more.
--
-- ── SEARCH TERMS ARE DELIBERATELY ABSENT, and here it is not merely tidy ────
--
-- taksa_v1 left the seven BIRTHDAY_* symbols without symbol_term rows so that
-- "ฝันเมื่อคืนวันอาทิตย์" could not match a birth-day reading. The same rule
-- applies here with far more force, because ELEVEN of these twelve animals are
-- already live dream symbols carrying real search terms:
--
--   DREAM_RAT, DREAM_COW, DREAM_TIGER, DREAM_RABBIT, DREAM_DRAGON, DREAM_NAGA,
--   DREAM_SNAKE, DREAM_HORSE, DREAM_GOAT, DREAM_MONKEY, DREAM_CHICKEN, DREAM_DOG
--
-- Someone writing "ฝันเห็นเสือ" must get the dream reading from ประมวลตำราทำนาย,
-- never a personality profile about people born in ปีขาล. Giving these symbols
-- terms would put the two in direct competition inside the longest-match
-- scanner, and the zodiac reading would sometimes win. The app looks these up
-- from the computed year, never by scanning prose. Asserted below, and the
-- carry-over check confirms the dream symbols kept their own terms.
--
-- ── WHAT THE SOURCE PAYLOAD ASSERTS ABOUT ITSELF ───────────────────────────
--
-- หน้า ๑๐ classifies each year by ธาตุ and by ชั้นมา (เทวดา / มนุษย์ / ผีเสื้อ,
-- each ผู้ชาย or ผู้หญิง). ชั้นมา is the book's own word — an earlier draft of
-- this file called it รูปประจำปี, which was our coinage, not the ตำรา's.
--
-- Those classifications are perfectly symmetric: four years per ชั้นมา class,
-- six per sex, and each ธาตุ falling on exactly two years. That symmetry is
-- strong evidence the reading is faithful rather than reconstructed, so it is
-- asserted here as a checkable invariant BEFORE anything is inserted. A typo
-- in one ธาตุ breaks the pairing and fails the seed on the machine that made
-- it.
--
-- หน้า ๑๑ goes on to explain what ชั้นมา MEANS, and the scan is illegible
-- across the key clauses. So the classification is recorded and used as an
-- identifier, and no reading here claims to interpret it. An unread definition
-- is not a licence to invent one.
--
-- ── WHAT IS DELIBERATELY NOT CARRIED ACROSS ────────────────────────────────
--
-- The source's ลักษณะ sections also make claims about sexual conduct and
-- marital fortune — that people born in one year are 'มากในกามคุณ', that women
-- born in another are 'อาภัพสามี', and a line about ปีเถาะ the transcriber
-- marked [ข้อความตามต้นฉบับ] because of what it asserts about women's chastity.
--
-- None of it is carried into body_th. This is an editorial decision, not an
-- omission by accident, and it is written down here so a later editor can
-- disagree with it deliberately: category folk-brahmajati carries the standing
-- note 'หลีกเลี่ยงการเหมารวมและการตัดสินความสัมพันธ์', surfaced in the UI, and
-- a personality verdict about a stranger's sex life keyed off their birth year
-- is the clearest case that note can have. The material stays in the source and
-- stays citable; it is simply not something this app puts in front of a reader
-- as a reading about them.
--
-- ── EVERYTHING HERE IS DRAFT, AND WHY ──────────────────────────────────────
--
-- The source is 'phrommachat-owned', flagged has_modern_editorial_layer. Its
-- compiler's own commentary cannot be told apart from the traditional ตำรา by
-- one reader with one book, so the two-source rule applies even though the
-- underlying work is public domain (see sources_v8 and the
-- mixed_compilation_uncorroborated blocker). The ๒๕๐๖ edition is the obvious
-- second witness; until someone opens it, these readings stay draft.
--
-- ── THE LOCATORS ARE PRINTED PAGES, AND THAT WAS A CORRECTION ──────────────
--
-- The first version of this file cited หน้า ๒๔ / ๔๐ / ๕๖ / ๗๒ / ๘๘, taken
-- straight from the extraction's source_pages, and flagged the perfectly
-- regular sixteen-page spacing as possible extrapolation. The full
-- transcription settled it: those were PDF PAGE numbers, and the PDF
-- interleaves a blank after every printed page, so the true printed pages are
-- half of them. The regularity is real — each year occupies exactly eight
-- printed pages — and the extraction was faithful.
--
-- The suspicion was wrong; the citations were nonetheless wrong, and worse
-- than suspected. หน้า ๕๖ pointed a reader at ปีขาล's day-by-day table instead
-- of its opening. Every locator below is now the PRINTED page, cross-checked
-- against the transcription's 'PRINTED PAGE ๒๘ / PDF PAGE 56' headers:
--
--   ตารางปีนักษัตร  printed ๑๐–๑๑   (pdf 20–22)
--   ปีชวด           printed ๑๒–๑๓   (pdf 24–26)
--   ปีฉลู           printed ๒๐–๒๑   (pdf 40–42)
--   ปีขาล           printed ๒๘–๒๙   (pdf 56–58)
--   ปีเถาะ          printed ๓๖–๓๗   (pdf 72–74)
--   ปีมะโรง         printed ๔๔–๔๕   (pdf 88–90)
--
-- Each year's full section runs eight printed pages: a plate, the ลักษณะ
-- reading, two pages of เดือนเกิด subdivisions, a ชาตา day table, and three
-- pages of day-and-month figures. Only the first two are used here.
--
-- ── ETHICS ─────────────────────────────────────────────────────────────────
--
-- category folk-brahmajati carries the note 'แสดงความต่างระหว่างฉบับ
-- หลีกเลี่ยงการเหมารวมและการตัดสินความสัมพันธ์', and it is surfaced in the UI
-- rather than merely recorded. These readings describe what a ตำรา says about a
-- birth year. They are not an assessment of any person, and the body text is
-- written so that the ข้อควรระวัง read as what the book warns of, not as a
-- verdict on the reader.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- The payload, staged so its internal symmetry can be checked before use.
-- ---------------------------------------------------------------------------

drop table if exists tmp_zodiac;
create temporary table tmp_zodiac (
  concept_key text, slug text, name_th text, name_en text,
  thai_year text, animal_th text, element_th text,
  form_class text, form_sex text
);

insert into tmp_zodiac values
  ('ZODIAC_RAT',     'year-rat',     'คนเกิดปีชวด',    'born in the year of the rat',    'ปีชวด',   'หนู',              'ธาตุน้ำ',   'เทวดา', 'ชาย'),
  ('ZODIAC_OX',      'year-ox',      'คนเกิดปีฉลู',    'born in the year of the ox',     'ปีฉลู',   'วัว',              'ธาตุดิน',   'มนุษย์', 'ชาย'),
  ('ZODIAC_TIGER',   'year-tiger',   'คนเกิดปีขาล',    'born in the year of the tiger',  'ปีขาล',   'เสือ',             'ธาตุไม้',   'ผีเสื้อ', 'หญิง'),
  ('ZODIAC_RABBIT',  'year-rabbit',  'คนเกิดปีเถาะ',   'born in the year of the rabbit', 'ปีเถาะ',  'กระต่าย',          'ธาตุไม้',   'มนุษย์', 'หญิง'),
  ('ZODIAC_DRAGON',  'year-dragon',  'คนเกิดปีมะโรง',  'born in the year of the dragon', 'ปีมะโรง', 'งูใหญ่ / พญานาค',  'ธาตุทอง',  'เทวดา', 'ชาย'),
  ('ZODIAC_SNAKE',   'year-snake',   'คนเกิดปีมะเส็ง', 'born in the year of the snake',  'ปีมะเส็ง','งูเล็ก',           'ธาตุไฟ',    'มนุษย์', 'ชาย'),
  ('ZODIAC_HORSE',   'year-horse',   'คนเกิดปีมะเมีย', 'born in the year of the horse',  'ปีมะเมีย','ม้า',              'ธาตุไฟ',    'เทวดา', 'หญิง'),
  ('ZODIAC_GOAT',    'year-goat',    'คนเกิดปีมะแม',   'born in the year of the goat',   'ปีมะแม',  'แพะ',              'ธาตุทอง',  'เทวดา', 'หญิง'),
  ('ZODIAC_MONKEY',  'year-monkey',  'คนเกิดปีวอก',    'born in the year of the monkey', 'ปีวอก',   'ลิง',              'ธาตุเหล็ก', 'ผีเสื้อ', 'ชาย'),
  ('ZODIAC_ROOSTER', 'year-rooster', 'คนเกิดปีระกา',   'born in the year of the rooster','ปีระกา',  'ไก่',              'ธาตุเหล็ก', 'ผีเสื้อ', 'ชาย'),
  ('ZODIAC_DOG',     'year-dog',     'คนเกิดปีจอ',     'born in the year of the dog',    'ปีจอ',    'หมา',              'ธาตุดิน',   'ผีเสื้อ', 'หญิง'),
  ('ZODIAC_PIG',     'year-pig',     'คนเกิดปีกุน',    'born in the year of the pig',    'ปีกุน',   'หมู',              'ธาตุน้ำ',   'มนุษย์', 'หญิง');

-- ---------------------------------------------------------------------------
-- The symmetry of the source, checked before a single row is written.
-- ---------------------------------------------------------------------------
do $$
declare n int; detail text;
begin
  select count(*) into n from tmp_zodiac;
  if n <> 12 then raise exception 'zodiac v1: the cycle has 12 years, payload has %', n; end if;

  select count(*) into n from (select concept_key from tmp_zodiac group by 1 having count(*) > 1) d;
  if n > 0 then raise exception 'zodiac v1: % duplicated concept_key(s)', n; end if;

  -- Four years per ชั้นมา class. A miscopied class shows up here and nowhere else.
  select string_agg(form_class || '=' || c, ', ' order by form_class) into detail
    from (select form_class, count(*) c from tmp_zodiac group by 1) d where c <> 4;
  if detail is not null then
    raise exception 'zodiac v1: ชั้นมา must be 4/4/4 across เทวดา/มนุษย์/ผีเสื้อ — got %', detail;
  end if;

  select string_agg(form_sex || '=' || c, ', ' order by form_sex) into detail
    from (select form_sex, count(*) c from tmp_zodiac group by 1) d where c <> 6;
  if detail is not null then
    raise exception 'zodiac v1: ชาย/หญิง must split 6/6 — got %', detail;
  end if;

  -- Six ธาตุ, each falling on exactly two years.
  select string_agg(element_th || '=' || c, ', ' order by element_th) into detail
    from (select element_th, count(*) c from tmp_zodiac group by 1) d where c <> 2;
  if detail is not null then
    raise exception 'zodiac v1: each ธาตุ must fall on exactly 2 years — got %', detail;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Symbols. Published as lexicon entries so ดวงของฉัน can name a user's year
-- even before a reading exists for it — an honest gap is a queue, not a bug
-- (ROADMAP principle 7). No symbol_term rows, ever. See the header.
-- ---------------------------------------------------------------------------

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select z.concept_key, z.slug, z.name_th, z.name_en, c.id, 'published', now()
from tmp_zodiac z
join content.category c on c.slug = 'folk-brahmajati'
on conflict (concept_key) do nothing;

-- ---------------------------------------------------------------------------
-- Passages. modern_th only — sources_v8 forbids original_text_th on this
-- edition until the compiler is identified, and that guard is the reason the
-- extraction was written as paraphrase in the first place.
-- ---------------------------------------------------------------------------

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, v.locator, v.seq, null, v.modern, 'เจ้าของโครงการ อ่านจากฉบับสแกน', v.note, 'draft'
from content.edition e
cross join (values
  ('หน้า ๑๐–๑๑ ตารางปีนักษัตร ธาตุ และชั้นมา', 10,
   'ตารางสิบสองปีนักษัตร ระบุธาตุประจำปีและชั้นมาประจำปี '
   'แบ่งเป็นเทวดา มนุษย์ และผีเสื้อ อย่างละสี่ปี พร้อมเพศประจำชั้นมา '
   'ตามด้วยรายการจับคู่ชื่อปีกับสัตว์ประจำปี',
   'ถอดครั้งแรกจากฉบับสแกน ยังไม่ได้ทานซ้ำ | หน้า ๑๑ '
   'ส่วนที่อธิบายความหมายของคำว่า "ชั้นมา" อ่านไม่ชัดหลายช่วง'),
  ('หน้า ๑๒–๑๓ คนเกิดปีชวด', 12,
   'ภาพประจำปีและคำทำนายผู้เกิดปีชวด ระบุขวัญประจำปี '
   'การกำหนดพระเคราะห์ประจำอวัยวะ เวลาเกิด และของที่ควรปลูกไว้เป็นสิริมงคล',
   'ถอดครั้งแรกจากฉบับสแกน ยังไม่ได้ทานซ้ำ'),
  ('หน้า ๒๐–๒๑ คนเกิดปีฉลู', 20,
   'ภาพประจำปีและคำทำนายผู้เกิดปีฉลู ระบุขวัญประจำปี '
   'การกำหนดพระเคราะห์ประจำอวัยวะ เวลาเกิด และการทำบุญประจำปีเกิด',
   'ถอดครั้งแรกจากฉบับสแกน ยังไม่ได้ทานซ้ำ'),
  ('หน้า ๒๘–๒๙ คนเกิดปีขาล', 28,
   'ภาพประจำปีและคำทำนายผู้เกิดปีขาล ระบุขวัญประจำปี '
   'และการกำหนดพระเคราะห์ประจำอวัยวะ',
   'ถอดครั้งแรกจากฉบับสแกน ยังไม่ได้ทานซ้ำ | ช่วง "จันทร์เป็นที่นั่ง" '
   'และข้อความท้ายเรื่องเวลาเกิดอ่านไม่ชัด'),
  ('หน้า ๓๖–๓๗ คนเกิดปีเถาะ', 36,
   'ภาพประจำปีและคำทำนายผู้เกิดปีเถาะ ระบุขวัญประจำปี '
   'และการกำหนดพระเคราะห์ประจำอวัยวะ',
   'ถอดครั้งแรกจากฉบับสแกน ยังไม่ได้ทานซ้ำ'),
  ('หน้า ๔๔–๔๕ คนเกิดปีมะโรง', 44,
   'ภาพประจำปีและคำทำนายผู้เกิดปีมะโรง ระบุขวัญประจำปี '
   'และการกำหนดพระเคราะห์ประจำอวัยวะ',
   'ถอดครั้งแรกจากฉบับสแกน ยังไม่ได้ทานซ้ำ')
) as v(locator, seq, modern, note)
where e.citekey = 'phrommachat-owned'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- Readings — five of twelve. The other seven are simply not read yet, and
-- symbol_without_reading will list them as notes, which is the queue working.
--
-- ข้อควรระวัง is phrased as what the ตำรา warns of, never as a judgement of the
-- reader, per the folk-brahmajati ethics note.
-- ---------------------------------------------------------------------------

with v(concept_key, seq, body, plain) as (values
('ZODIAC_RAT', 12,
 'ตำราจัดปีชวดเป็นธาตุน้ำ ชั้นมาเทวดาผู้ชาย ขวัญประจำปีสถิตอยู่ที่ต้นมะพร้าวหรือต้นกล้วย | '
 'ตำราอ่านนิสัยด้วยการวางพระเคราะห์ประจำอวัยวะ: อาทิตย์เป็นปาก ว่าพูดจาเด็ดขาดจริงใจ '
 'มักทำตามความคิดของตนเป็นใหญ่ · อังคารเป็นใจ ว่าโลเล ชอบความเปลี่ยนแปลง · '
 'พฤหัสบดีเป็นที่นั่ง ว่ามักมีหลักแหล่งที่ดี · จันทร์กับพุธเป็นมือ ว่าไม่ชอบอยู่นิ่ง '
 'ขยันหาอาชีพ ถ้าได้เรียนหนังสือจะมีตำแหน่งหน้าที่ · ศุกร์กับเสาร์เป็นเท้า '
 'ว่าชอบเดินทางไกล มักไปตั้งถิ่นฐานที่อื่นและพึ่งพาญาติพี่น้องได้ไม่มาก | '
 'ตำราว่าผู้เกิดกลางวันดีกว่าเกิดกลางคืน และชีวิตจะดีขึ้นเมื่ออายุราว ๓๐ ปี | '
 'ของประจำปีเกิด: ตำราแนะให้ปลูกต้นมะพร้าวหรือต้นกล้วยไว้ในรั้วบ้าน ว่าจะอยู่ร่มเย็นเป็นสุข',
 'ตำราว่าคนปีชวด ธาตุน้ำ ขวัญอยู่ที่ต้นมะพร้าวหรือต้นกล้วย พูดตรงและทำตามใจตัว '
 'ชอบเดินทางจนมักไปอยู่ถิ่นอื่น ตำราว่าชีวิตจะดีขึ้นราวอายุ ๓๐ '
 'และแนะให้ปลูกมะพร้าวหรือกล้วยไว้ในบ้าน'),
('ZODIAC_OX', 20,
 'ตำราจัดปีฉลูเป็นธาตุดิน ชั้นมามนุษย์ผู้ชาย ขวัญประจำปีสถิตอยู่ที่ต้นตาล | '
 'พระเคราะห์ประจำอวัยวะ: พฤหัสบดีเป็นปาก ว่าเจรจาดีเป็นที่พอใจของคนทั่วไป มีเสน่ห์ · '
 'พุธเป็นใจ ว่ามีความคิดสุขุมรอบคอบ มีเมตตา แต่ทำคุณแก่ผู้อื่นแล้วมักไม่มีใครเห็น '
 'ตำราเปรียบว่าเหมือนปิดทองหลังพระ · เสาร์เป็นที่นั่ง · อาทิตย์กับอังคารเป็นมือ '
 'ว่าทำงานได้ทุกอย่าง ถ้าได้เรียนจะก้าวหน้าในทางนักบวช แพทย์ ครูอาจารย์ และโหราศาสตร์ '
 'แต่มักถูกหลอกจนเสียเงินอยู่เสมอ · ศุกร์เป็นเท้า ว่าชอบท่องเที่ยวไปทั่ว | '
 'ตำราว่าผู้เกิดกลางคืนจะมีความสุขมากกว่าเกิดกลางวัน | '
 'การทำบุญประจำปีเกิด: ตำราแนะให้ทำบุญปล่อยวัวหรือโค',
 'ตำราว่าคนปีฉลู ธาตุดิน ขวัญอยู่ที่ต้นตาล เจรจาดีมีเสน่ห์ คิดรอบคอบ '
 'แต่ทำดีกับใครมักไม่มีคนเห็น ตำราแนะให้ทำบุญปล่อยวัวหรือโค'),
('ZODIAC_TIGER', 28,
 'ตำราจัดปีขาลเป็นธาตุไม้ ชั้นมาผีเสื้อผู้หญิง ขวัญประจำปีสถิตอยู่ที่ต้นขนุนและต้นรัง | '
 'พระเคราะห์ประจำอวัยวะ: อังคารเป็นปาก ว่ามีโวหาร พูดจาเด็ดขาด '
 'คิดทำการใดก็มักเอาตัวรอดได้และคิดพึ่งตนเอง · พฤหัสบดีเป็นใจ ว่ามีจิตใจมั่นในศีลธรรม '
 'เชื่อโชคลาง ชอบของขลัง และเลื่อมใสครูบาอาจารย์ · จันทร์เป็นที่นั่ง · '
 'พุธกับศุกร์เป็นมือ ว่าชอบงานช่างและศิลปวิทยา มีความอุตสาหะในการทำมาหากิน '
 'และเป็นผู้กตัญญูต่อผู้มีพระคุณ · เสาร์กับอาทิตย์เป็นเท้า ว่ามักเดินทางไกลเสมอ '
 'เหมาะกับงานค้าและงานราชการ',
 'ตำราว่าคนปีขาล ธาตุไม้ ขวัญอยู่ที่ต้นขนุนและต้นรัง พูดเด็ดขาดและพึ่งตนเอง '
 'ใจมั่นในศีลธรรม ชอบของขลัง ถนัดงานช่าง และกตัญญูต่อผู้มีพระคุณ'),
('ZODIAC_RABBIT', 36,
 'ตำราจัดปีเถาะเป็นธาตุไม้ ชั้นมามนุษย์ผู้หญิง ขวัญประจำปีสถิตอยู่ที่ต้นมะพร้าวหรือต้นงิ้ว | '
 'พระเคราะห์ประจำอวัยวะ: พุธเป็นปาก ว่าเจรจาเป็นที่ต้องใจคนทั่วไป '
 'แต่มักพูดเชิงประชดกับเพื่อนฝูง · ศุกร์เป็นใจ ว่าใจมักง่าย โกรธง่ายหายเร็ว '
 'และชอบอาสาเจ้านาย · จันทร์เป็นที่นั่ง ว่าระงับอารมณ์ได้เร็ว '
 'ทำกิจการใดมักมีคนมาช่วยเหลือ · พฤหัสบดีกับเสาร์เป็นมือ ว่าทำงานเรียบร้อย '
 'รักสวยรักงาม มีแผนงาน เจ้าระเบียบ และมีฝีมือในการปรุงอาหาร · '
 'อาทิตย์กับอังคารเป็นเท้า ว่าชอบท่องเที่ยวหาความรู้ '
 'และจะได้เดินทางไกลหลายครั้งในชีวิต',
 'ตำราว่าคนปีเถาะ ธาตุไม้ ขวัญอยู่ที่ต้นมะพร้าวหรือต้นงิ้ว เจรจาถูกใจคน '
 'โกรธง่ายหายเร็ว ทำงานเรียบร้อยเจ้าระเบียบ และได้เดินทางไกลหลายครั้ง'),
('ZODIAC_DRAGON', 44,
 'ตำราจัดปีมะโรงเป็นธาตุทอง ชั้นมาเทวดาผู้ชาย ขวัญประจำปีสถิตอยู่ที่กอไผ่ใกล้ต้นงิ้ว | '
 'พระเคราะห์ประจำอวัยวะ: พฤหัสบดีเป็นปาก ว่าเจรจาเป็นที่พอใจของคนทั่วไป มีไหวพริบ '
 'และมักเอาตัวรอดได้ด้วยคำพูดของตนเอง · เสาร์เป็นใจ ว่าใจแข็ง ไม่ยอมใครง่าย ๆ '
 'โกรธง่ายแต่หายเร็ว และมีใจซื่อสัตย์ต่อคนทั่วไป · อังคารเป็นที่นั่ง · '
 'ศุกร์กับอาทิตย์เป็นมือ ว่าทำได้ทุกอย่างแต่ไม่เอาดีทางฝีมือ '
 'เว้นแต่ผู้หญิงที่ตำราว่ามักมีเสน่ห์ในทางช่างฝีมือและเป็นแม่บ้านที่ดี · '
 'จันทร์กับพุธเป็นเท้า ว่าชอบการท่องเที่ยวและการหาความรู้',
 'ตำราว่าคนปีมะโรง ธาตุทอง ขวัญอยู่ที่กอไผ่ใกล้ต้นงิ้ว เจรจาเก่งมีไหวพริบ '
 'ใจแข็งไม่ยอมคนแต่ซื่อสัตย์ และชอบเดินทางหาความรู้')
),
tr as (select id from content.tradition where slug = 'brahmajati')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status)
select s.id, p.id, tr.id, v.body, v.plain, 'historical_belief',
  'เป็นความเชื่อตามตำราพรหมชาติ ไม่ใช่ข้อเท็จจริงทางวิทยาศาสตร์ '
  'ไม่ใช่คำรับรองอนาคต และไม่ใช่การประเมินนิสัยของบุคคลใด | '
  'อ่านจากฉบับรวมเล่มที่มีคำอธิบายของผู้เรียบเรียงปนอยู่ '
  'รอสอบทานกับพรหมชาติ ฉบับ ๒๕๐๖ ก่อนเผยแพร่',
  '{}', 'draft'
from v
join content.symbol s on s.concept_key = v.concept_key
join content.passage p on p.sequence = v.seq
join content.edition e on e.id = p.edition_id and e.citekey = 'phrommachat-owned'
cross join tr
where not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.passage_id = p.id);

-- ---------------------------------------------------------------------------
-- Assert the intent. Every insert above is select-driven, and a join matching
-- nothing is zero rows rather than an error.
-- ---------------------------------------------------------------------------
do $$
declare got int;
begin
  select count(*) into got from content.symbol s
    join content.category c on c.id = s.category_id
   where s.concept_key like 'ZODIAC_%' and c.slug = 'folk-brahmajati'
     and s.status = 'published';
  if got <> 12 then
    raise exception 'zodiac v1: expected 12 published symbols in folk-brahmajati, found %', got;
  end if;

  -- The collision guard, and the reason this file can coexist with the dream
  -- lexicon at all. One term here and "ฝันเห็นเสือ" starts competing with a
  -- reading about people born in ปีขาล.
  select count(*) into got from content.symbol_term t
    join content.symbol s on s.id = t.symbol_id
   where s.concept_key like 'ZODIAC_%';
  if got > 0 then
    raise exception 'zodiac v1: % search term(s) on zodiac symbols — a dream about '
      'an animal would match a birth-year profile', got;
  end if;

  -- The dream symbols must still own the animal words. A rename or a merge
  -- upstream would strand both sides silently.
  select count(*) into got from content.symbol_term t
    join content.symbol s on s.id = t.symbol_id
   where (s.concept_key, t.term) in (
     ('DREAM_RAT','หนู'), ('DREAM_TIGER','เสือ'), ('DREAM_HORSE','ม้า'),
     ('DREAM_MONKEY','ลิง'), ('DREAM_DOG','หมา'));
  if got <> 5 then
    raise exception 'zodiac v1: expected 5 carry-over dream terms, found %', got;
  end if;

  select count(*) into got from content.passage p
    join content.edition e on e.id = p.edition_id
   where e.citekey = 'phrommachat-owned' and p.sequence in (10,12,20,28,36,44);
  if got <> 6 then
    raise exception 'zodiac v1: expected 6 passages, found % '
      '(is sources_v8_phrommachat_owned.sql applied?)', got;
  end if;

  -- Scoped to the year passages this file owns, NOT to every reading on a
  -- ZODIAC_* symbol. zodiac_v2 legitimately adds twenty more against the
  -- เดือนเกิด passages, and a global count here made this seed fail on any
  -- re-run once v2 had been applied — which is exactly what a re-run must
  -- survive, since that is how the live database gets updated.
  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
    join content.passage p on p.id = i.passage_id
    join content.edition e on e.id = p.edition_id
   where s.concept_key like 'ZODIAC_%' and e.citekey = 'phrommachat-owned'
     and p.sequence in (12,20,28,36,44);
  if got <> 5 then
    raise exception 'zodiac v1: expected 5 year readings, found %', got;
  end if;

  -- Nothing here may publish on one book's say-so. The two-source rule reaches
  -- this edition only because sources_v8 flags it; assert the outcome here too.
  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.concept_key like 'ZODIAC_%' and i.status <> 'draft';
  if got > 0 then
    raise exception 'zodiac v1: % reading(s) left draft state before the ๒๕๐๖ '
      'edition was consulted', got;
  end if;
end $$;

do $$
declare bad int;
begin
  select coalesce(sum(violations), 0) into bad from ops.assert_rights_invariants();
  if bad > 0 then raise exception 'aborted: % rights invariant(s)', bad; end if;
end $$;

drop table if exists tmp_zodiac;

select s.name_th, s.status::text as symbol_status,
       coalesce(i.status::text, '— ยังไม่มีคำแปล') as reading_status,
       p.locator
from content.symbol s
left join content.interpretation i on i.symbol_id = s.id
left join content.passage p on p.id = i.passage_id
where s.concept_key like 'ZODIAC_%'
order by s.slug;
