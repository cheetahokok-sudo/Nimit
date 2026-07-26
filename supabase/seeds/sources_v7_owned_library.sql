-- ============================================================================
-- The owner's personal library becomes a working source base
--
-- TWO CORRECTIONS to over-restriction, plus registration of the first book.
--
-- ── Correction 1: BLOCKED-proommachat-thep was wrong at the WORK level ──────
--
-- That row conflated two different things and archived the whole work:
--   * the Internet Archive FILE is an unauthorised upload — still true, still
--     must never be ingested;
--   * the WORK itself (ตำราพรหมชาติ by เทพย์ สาริกบุตร) is an ordinary
--     copyrighted book, which anyone owning a legitimate copy may read, cite
--     and paraphrase like any other copyrighted source.
--
-- Archiving the work blocked the lawful path along with the unlawful one. It
-- is now a normal copyrighted_cite_only work; the warning moves to the
-- EDITION row, where it belongs, since it is that specific copy that is bad.
--
-- ── Correction 2: reading an owned book was never restricted ────────────────
--
-- The firewall guards passage.original_text_th only. body_th — our own prose —
-- has always been permitted against copyrighted sources, and the suite asserts
-- it. Nothing in the schema ever blocked working from a book you own.
--
-- ── What stays, and why it serves the project rather than obstructing it ────
--
-- The two-source rule still gates PUBLICATION of claims drawn from a single
-- copyrighted work. This is not caution for its own sake: a belief attested in
-- one book is that book's expression, while the same belief attested across
-- several independent books is a cultural FACT, which no publisher owns. Since
-- the working method here is a shelf of books rather than one, the rule will
-- usually be satisfied simply by recording which of them agree — and a reading
-- backed by three ตำรา is also better content than one backed by none.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Correction 1
-- ---------------------------------------------------------------------------

update content.work set
  slug = 'phrommachat-thep-sarikabut',
  canonical_title_th = 'ตำราพรหมชาติ (ฉบับเทพย์ สาริกบุตร)',
  status = 'published',
  rights = 'copyrighted_cite_only',
  copyright_holder = 'ทายาทของเทพย์ สาริกบุตร',
  rights_note_th =
    'ผู้เรียบเรียงถึงแก่กรรม พ.ศ. 2536 ลิขสิทธิ์คุ้มครองถึง พ.ศ. 2586 — '
    'เป็นงานมีลิขสิทธิ์ตามปกติ ใช้อ้างอิงและถอดความได้ ห้ามคัดลอกคำต่อคำ | '
    'แก้ไขจากเดิมที่ตั้งสถานะ archived ทั้งงาน ซึ่งกันเกินไป: '
    'ไฟล์บน Internet Archive เป็นการอัปโหลดโดยไม่ได้รับอนุญาต (ดูหมายเหตุระดับ edition) '
    'แต่ตัวงานเองอ่านและถอดความได้ตามปกติหากมีฉบับที่ได้มาโดยชอบ'
where slug = 'BLOCKED-proommachat-thep';

update content.edition set
  label_th = 'ไฟล์อัปโหลดที่ไม่ได้รับอนุญาต — ห้ามใช้',
  status = 'archived',
  rights_note_th =
    'ห้ามนำไฟล์นี้มาใช้โดยเด็ดขาด — เป็นการอัปโหลดโดยไม่ได้รับอนุญาต '
    'ข้อห้ามอยู่ที่ "สำเนาชุดนี้" ไม่ใช่ที่ตัวงาน หากมีฉบับพิมพ์ที่ซื้อมาโดยชอบ '
    'ให้สร้าง edition ใหม่พร้อมบันทึกใน editorial.holding แล้วทำงานจากฉบับนั้น'
where citekey = 'BLOCKED-ia-proommachat';

-- ---------------------------------------------------------------------------
-- ฝันพยากรณ์ — the first book from the owner's shelf
--
-- Registered as an ordinary copyrighted source: cite and paraphrase, never
-- verbatim. Its real product value is that it is the SHARED BASELINE — the
-- book a large part of the audience already believes, whether or not it agrees
-- with older ตำรา. Recording it lets the app show that baseline honestly and
-- set older readings beside it later.
-- ---------------------------------------------------------------------------

insert into content.work
  (slug, canonical_title_th, attributed_author_th, composed_period_th,
   rights, pd_basis, copyright_holder, rights_note_th, status)
values
  ('fan-phayakon', 'ฝันพยากรณ์',
   null, 'พิมพ์เผยแพร่ต่อเนื่องหลายทศวรรษ; ฉบับที่ถือครองราว พ.ศ. 2546',
   'copyrighted_cite_only', null, 'สำนักพิมพ์เสริมวิทย์ (ยืนยันจากหน้าลิขสิทธิ์)',
   'หนังสือทำนายฝันยอดนิยม เป็นฐานความเชื่อร่วมของผู้ใช้กลุ่มเป้าหมายจำนวนมาก '
   'ครอบคลุมสัตว์ สิ่งของ เหตุการณ์ พร้อมตัวเลขประจำสัญลักษณ์ | '
   'สถานะ: มีลิขสิทธิ์ ใช้อ้างอิงและถอดความได้ ห้ามคัดลอกคำต่อคำและห้ามทำซ้ำภาพหน้าหนังสือ | '
   'ยังไม่ทราบปีพิมพ์ครั้งแรกและชื่อผู้เรียบเรียง — ต้องดูหน้าลิขสิทธิ์ในเล่ม '
   'หากพิมพ์ครั้งแรกก่อน พ.ศ. 2519 และไม่ปรากฏชื่อผู้แต่ง อาจพ้นอายุแล้วตามมาตรา 21 '
   'ซึ่งจะเปลี่ยนสถานะเป็น public_domain ได้ทันที',
   'published')
on conflict (slug) do update set rights_note_th = excluded.rights_note_th;

insert into content.edition
  (work_id, citekey, tier, label_th, custodian_th, publisher_th,
   stable_identifier, physical_desc_th, languages,
   custodian_rights, rights_note_th, status)
select w.id, 'fan-phayakon-owned', 'b2',
       'ฉบับพิมพ์ที่ถือครอง (ราว พ.ศ. 2546)',
       'ห้องสมุดส่วนตัวของเจ้าของโครงการ', 'สำนักพิมพ์เสริมวิทย์',
       'รอเลข ISBN และปีพิมพ์ครั้งแรกจากหน้าลิขสิทธิ์',
       'หนังสือปกอ่อน ประมาณ 200 หน้า', array['th'],
       'unknown',
       'ถือครองฉบับจริงโดยชอบ จึงอ่านและสกัดข้อเท็จจริงได้ '
       'บันทึกสิทธิ์การอ่านไว้ที่ editorial.holding',
       'published'
from content.work w where w.slug = 'fan-phayakon'
on conflict (citekey) do nothing;

-- ---------------------------------------------------------------------------
-- Holdings: the reading entitlement, with counsel review recorded
-- ---------------------------------------------------------------------------

insert into editorial.holding
  (edition_id, copy_type, acquired_note_th,
   counsel_reviewed, counsel_name, counsel_note_th, reviewed_at)
select e.id, 'owned_physical',
  'เจ้าของโครงการถือครองฉบับพิมพ์จริง ใช้เป็นฐานอ่านและสกัดข้อเท็จจริง '
  'ไม่ทำซ้ำภาพหน้าหนังสือ ไม่คัดลอกข้อความคำต่อคำ',
  true,
  'ที่ปรึกษากฎหมายของโครงการ (รอระบุชื่อ)',
  'เจ้าของโครงการแจ้งว่าที่ปรึกษากฎหมายเห็นชอบแนวทาง: อ่านจากฉบับที่ถือครองโดยชอบ '
  'สกัดข้อเท็จจริงเชิงความเชื่อ เรียบเรียงด้วยสำนวนของเราเอง และอ้างอิงที่มาทุกครั้ง '
  '— บันทึกไว้เป็นหลักฐานการตัดสินใจ ควรเติมชื่อผู้ให้ความเห็นและวันที่จริงเมื่อสะดวก',
  current_date
from content.edition e where e.citekey = 'fan-phayakon-owned'
on conflict (edition_id, copy_type) do nothing;

select w.canonical_title_th, w.rights::text, e.citekey, h.copy_type, h.counsel_reviewed
from content.work w
join content.edition e on e.work_id = w.id
left join editorial.holding h on h.edition_id = e.id
where w.slug in ('fan-phayakon', 'phrommachat-thep-sarikabut')
order by w.slug;
