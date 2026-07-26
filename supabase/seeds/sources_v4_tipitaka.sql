-- ============================================================================
-- Source registry v4 — rights determination for the Tipitaka translation,
-- plus the scholarly corroborating source for the first content set.
--
-- The มหาสุบินชาดก text displayed at 84000.org states at page bottom:
-- "การแสดงผลนี้อ้างอิงข้อมูลจากพระไตรปิฎกฉบับหลวง". ฉบับหลวง is the royal Thai
-- translation prepared and published by กรมการศาสนา (Department of Religious
-- Affairs) — a government work under s.14, first published พ.ศ. 2500 for the
-- 25th Buddhist centenary. Under s.23 the term is 50 years from first
-- publication → expired ~พ.ศ. 2550. The underlying Jataka is ancient in any
-- case; the translation layer is what this determination covers.
--
-- Caveat kept in the row: later revised printings (2514, 2525) could carry
-- fresh editorial matter; the determination applies to the 2500 translation
-- text. Verify the printing history before relying on verbatim use at scale.
-- ============================================================================

update content.work set
  rights = 'public_domain',
  pd_basis = 'government_work_50y',
  copyright_holder = null,
  rights_note_th =
    'ตัวชาดกเป็นวรรณกรรมโบราณพ้นลิขสิทธิ์อยู่แล้ว; คำแปลภาษาไทยที่ใช้คือ '
    'พระไตรปิฎกฉบับหลวงของกรมการศาสนา พิมพ์ครั้งแรก พ.ศ. 2500 — งานของหน่วยงานรัฐ '
    'ตามมาตรา 14 อายุคุ้มครอง 50 ปีนับแต่โฆษณาครั้งแรกตามมาตรา 23 จึงพ้นอายุราว '
    'พ.ศ. 2550 | ข้อควรระวัง: ฉบับพิมพ์แก้ไข พ.ศ. 2514/2525 อาจมีงานบรรณาธิการใหม่ '
    'การใช้คำต่อคำจำนวนมากควรยืนยันประวัติการพิมพ์ก่อน; ข้อความที่เก็บในระบบนี้อ้างจาก '
    'การแสดงผลของ 84000.org ซึ่งระบุว่าอ้างอิงฉบับหลวง | '
    'คำแปลอรรถกถา (มหามกุฏฯ พ.ศ. 2525) ยังมีลิขสิทธิ์ — ห้ามคัดลอก ใช้ถอดความเท่านั้น'
where slug = 'mahasupina-jataka';

-- The scholarly corroborating source: a ThaiJO open-access article analysing
-- the sixteen dreams of King Pasenadi. CC BY-NC-ND → cite and paraphrase
-- only; its role here is corroboration (the two-source rule) and a pointer
-- for readers who want the academic treatment.
insert into content.work
  (slug, canonical_title_th, attributed_author_th, composed_period_th,
   rights, pd_basis, copyright_holder, rights_note_th, status)
values
  ('thaijo-buddhist-dream-pasenadi',
   'พุทธทำนายความฝันพระเจ้าปเสนทิโกศล (บทความวิชาการ)',
   'ผู้เขียนบทความ วารสาร APBJ', 'เผยแพร่ผ่าน ThaiJO',
   'copyrighted_cite_only', null, 'ผู้เขียนและวารสาร (CC BY-NC-ND 4.0)',
   'บทความ open access ภายใต้ CC BY-NC-ND ซึ่งแอปเชิงพาณิชย์ปฏิบัติตามไม่ได้ '
   'จึงใช้เป็นแหล่งอ้างอิงประกอบ (อ้างและถอดความ) เท่านั้น ห้ามคัดลอกข้อความ',
   'published')
on conflict (slug) do update set rights_note_th = excluded.rights_note_th;

insert into content.edition
  (work_id, citekey, tier, label_th, custodian_th, stable_identifier,
   physical_desc_th, languages, url, custodian_rights, rights_note_th, status)
select w.id, 'thaijo-apbj-249166', 'b1',
       'บทความวารสารผ่านระบบ ThaiJO', 'Thai Journals Online (ThaiJO)',
       'APBJ article 249166', 'PDF open access', array['th'],
       'https://so02.tci-thaijo.org/index.php/APBJ/article/view/249166',
       'cc_by_nc_nd',
       'ใช้อ้างอิงประกอบและถอดความ; NC/ND ปิดการนำข้อความมาใช้ตรงในระบบเชิงพาณิชย์',
       'published'
from content.work w where w.slug = 'thaijo-buddhist-dream-pasenadi'
on conflict (citekey) do nothing;
