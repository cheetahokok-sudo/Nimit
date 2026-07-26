-- ============================================================================
-- ประมวลตำราทำนาย (ของเก่า) ภาค ๑ — the first FOLK-BELIEF source, PD confirmed
--
-- This is the source that shifts the app's primary voice from Buddhist
-- literature to ความเชื่อ/โหราศาสตร์, exactly as intended: the book states its
-- own register on page ๓ —
--   "เรื่องการทำนายฝันหรือทำนายโชคลางต่าง ๆ เช่นเรื่องสัตว์ตกและเรื่องเขม่น
--    เป็นต้นนั้น เกิดขึ้นจากความเชื่อถือของคนโบราณ มีมาแต่ดึกดำบรรพ์"
--
-- PUBLIC DOMAIN on two independent grounds — neither needs an author's death
-- date, which is why this clears where คัมภีร์โหราศาสตร์ไทย still cannot:
--
--   1. The underlying work is ANONYMOUS ("ของเก่า", no author named anywhere;
--      the คำนำ says the National Library merely selected and titled it).
--      s.21: 50 years from first publication → published พ.ศ. 2477, expired
--      พ.ศ. 2527.
--   2. The 2477 คำนำ itself is a work of หอสมุดแห่งชาติ / กรมศิลปากร, signed
--      institutionally with no individual author. s.14/s.23: 50 years from
--      publication → also expired พ.ศ. 2527. So there is NO protected
--      editorial layer to carve out — unusual and valuable.
--
-- s.26 disposes of the rest: the 2019 digitisation creates no new copyright in
-- the text. D-Library's page carries a site-level rights notice, which is a
-- claim over the SCAN, not the work — recorded in custodian_rights, and the
-- reason transcription policy below says re-typeset rather than redistribute
-- their PDF.
--
-- Digitisation reality: 38 pages of DCTDecode JPEGs with ZERO font objects —
-- no text layer at all. pdftotext yields 38 bytes. Transcription is manual
-- (~25 pages of body text), over 1934 orthography (นน for นั้น, archaic tone
-- placement, Pali with dot-below). This is a day of careful work, not an OCR
-- job, and it is B5 territory.
-- ============================================================================

insert into content.work
  (slug, canonical_title_th, attributed_author_th, composed_period_th,
   rights, pd_basis, copyright_holder, rights_note_th,
   rights_verified_by, rights_verified_at, status)
values
  ('pramuan-tamra-thamnai-1-2477',
   'ประมวลตำราทำนาย (ของเก่า) ภาค ๑',
   null, 'ตัวบทเป็นของเก่า ไม่ปรากฏผู้แต่ง; รวมพิมพ์ครั้งแรก พ.ศ. 2477',
   'public_domain', 'published_50y_anon', null,
   'สาธารณสมบัติด้วยสองเหตุผลอิสระต่อกัน ไม่ต้องพึ่งปีถึงแก่กรรมของผู้ใด: '
   '(1) ตัวบทไม่ปรากฏชื่อผู้แต่ง คำนำระบุว่าเป็น "ของเก่า" และหอสมุดแห่งชาติเป็นผู้คัดเลือก '
   'และตั้งชื่อให้ — มาตรา 21 นับ 50 ปีจากการโฆษณาครั้งแรก พิมพ์ พ.ศ. 2477 จึงพ้นอายุ พ.ศ. 2527 '
   '(2) ตัวคำนำ พ.ศ. 2477 เป็นงานของหอสมุดแห่งชาติ/กรมศิลปากร ลงนามในนามหน่วยงาน '
   'ไม่มีผู้เขียนรายบุคคล — มาตรา 14/23 นับ 50 ปีจากการโฆษณา พ้นอายุ พ.ศ. 2527 เช่นกัน '
   'จึงไม่มีชั้นบรรณาธิการที่ยังมีลิขสิทธิ์ให้ต้องแยกออก | '
   'หลักฐานหน้าปกใน: "พระยาสากลกิจประมวญ พิมพ์เป็นที่ระลึกในการพระราชทานเพลิงศพ '
   'คุณหญิงสากลกิจประมวญ (พลอย เสนีวงศ์ ณอยุธยา) เมื่อเดือนพฤศจิกายน พุทธศักราช ๒๔๗๗" '
   'ท้ายคำนำลงนาม "หอสมุดแห่งชาติ กรมศิลปากร วันที่ ๔ สิงหาคม พ.ศ. ๒๔๗๗" | '
   'หมายเหตุการใช้งาน: ให้พิมพ์เรียงข้อความใหม่จากภาพสแกน ไม่นำไฟล์ PDF ของ D-Library '
   'ไปเผยแพร่ซ้ำหรือ hotlink — สิทธิ์ที่หอสมุดอ้างเป็นสิทธิ์ในภาพสแกน ไม่ใช่ในตัวบท',
   'Claude (AI) — ตรวจ metadata และภาพหน้าปกใน/คำนำจากไฟล์สแกนโดยตรง 26 ก.ค. 2569',
   now(), 'published')
on conflict (slug) do update set
  rights = excluded.rights,
  pd_basis = excluded.pd_basis,
  rights_note_th = excluded.rights_note_th,
  status = excluded.status;

insert into content.edition
  (work_id, citekey, tier, label_th, custodian_th, publisher_th,
   stable_identifier, year_published, physical_desc_th, languages, url,
   custodian_rights, rights_note_th, status)
select w.id, 'nlt-6238-2477', 'a2',
       'ฉบับพิมพ์ พ.ศ. 2477 (หนังสืออนุสรณ์งานศพ)',
       'สำนักหอสมุดแห่งชาติ (D-Library)', 'โรงพิมพ์พระจันทร์',
       'D-Library 6238', 1934,
       'หนังสือ 38 หน้า; ไฟล์สแกนเป็นภาพ ไม่มีชั้นข้อความ (ต้องพิมพ์เรียงใหม่)',
       array['th','pi'],
       'https://digital.nlt.go.th/dlib/items/show/6238',
       'all_rights_reserved',
       'หอสมุดอ้างสิทธิ์ในไฟล์สแกน (ไม่ใช่ในตัวบทซึ่งพ้นลิขสิทธิ์แล้ว) — '
       'ให้พิมพ์เรียงข้อความใหม่จากภาพ ห้ามนำ PDF ไปเผยแพร่ซ้ำ | '
       'เนื้อหาสามส่วน: คำทำนายฝัน (หน้า ๑–๑๐), ทำนายสัตว์ตก (ถึงหน้า ๒๓), '
       'ทำนายกระเหม่น (ถึงหน้า ๒๕)',
       'published'
from content.work w where w.slug = 'pramuan-tamra-thamnai-1-2477'
on conflict (citekey) do update set
  rights_note_th = excluded.rights_note_th,
  status = excluded.status;

-- Two new traditions this source opens, ranked ABOVE the Buddhist canon so
-- they lead the moment content lands (see 20260726000900_tradition_ordering).
insert into content.tradition (slug, name_th, note_th, display_rank) values
  ('omen-satok', 'ทำนายสัตว์ตก',
   'ความเชื่อเรื่องลางจากสัตว์ที่ตกลงมาถูกตัวหรือตกในทิศต่าง ๆ '
   'รูปแบบในตำราเป็นเงื่อนไขชัดเจน: ตกทิศใด/ถูกอวัยวะใด → ผลอย่างใด', 15),
  ('omen-krachamen', 'ทำนายกระเหม่น',
   'ความเชื่อเรื่องลางจากอาการกระตุกของอวัยวะ (เขม่น) '
   'รูปแบบเป็นเงื่อนไขต่ออวัยวะและข้างซ้าย/ขวา', 15)
on conflict (slug) do update set
  note_th = excluded.note_th,
  display_rank = excluded.display_rank;

-- Acquisition: no permission needed — the barrier is transcription labour.
insert into editorial.acquisition (edition_id, registry_ref, priority, stage, note_th)
select e.id, 'NIM-V6-001', 'P0', 'granted',
  'ไม่ต้องขออนุญาต — พ้นลิขสิทธิ์ทั้งตัวบทและคำนำตั้งแต่ พ.ศ. 2527 '
  'อุปสรรคเดียวคือการถอดความ: ไฟล์สแกนไม่มีชั้นข้อความ (38 หน้า ภาพ JPEG ล้วน) '
  'ต้องพิมพ์เรียงใหม่ด้วยมือ อักขรวิธี พ.ศ. 2477 (นน = นั้น, วรรณยุกต์วางต่างปัจจุบัน) '
  'OCR ไทยทั่วไปทำไม่ได้ | ลำดับความง่าย: กระเหม่น > สัตว์ตก > ทำนายฝัน '
  '(สองส่วนแรกเป็นเงื่อนไข ถ้า X → Y ตรงไปตรงมา ส่วนทำนายฝันเป็นบาลี + กาพย์ '
  'ต้องตีความจับคู่สัญลักษณ์ ซึ่งเป็นงานบรรณาธิการไม่ใช่งานเครื่อง)'
from content.edition e where e.citekey = 'nlt-6238-2477'
on conflict do nothing;

select w.slug, w.rights::text, w.pd_basis::text, e.citekey, e.year_published
from content.work w join content.edition e on e.work_id = w.id
where w.slug = 'pramuan-tamra-thamnai-1-2477';
