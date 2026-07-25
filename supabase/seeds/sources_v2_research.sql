-- ============================================================================
-- Source registry v2 — additions from independent research
--
-- The registry v1 covered Thai institutional holdings thoroughly, but every one
-- of those is All Rights Reserved or CC BY-NC-ND, which for a commercial app
-- means nothing usable without a negotiated grant. This pass went looking
-- specifically for material that permits COMMERCIAL and DERIVATIVE use, since
-- that is what actually unblocks the library.
--
-- Result: three genuine openings, one large "unstated rights" pool worth
-- assessing item by item, and one trap that had to be recorded so nobody walks
-- into it later.
--
-- Idempotent. Everything status='draft'.
-- ============================================================================

insert into content.work
  (slug, canonical_title_th, attributed_author_th, composed_period_th,
   rights, pd_basis, copyright_holder, rights_note_th, status)
values

-- ── THE UNLOCK: a phrommachat that is genuinely free to use ────────────────
('bl-or4830-phrommachat', 'ตำราพรหมชาติ (ฉบับหอสมุดแห่งชาติอังกฤษ Or. 4830)',
 null, 'คริสต์ศตวรรษที่ 19',
 'public_domain', 'author_died_50y', null,
 'สมุดไทยพับ ภาพนักษัตรจีนสี คำทำนายคู่สมพงษ์ — British Library ระบุสถานะ '
 'Public Domain Mark 1.0 ชัดเจน จึงใช้เชิงพาณิชย์และดัดแปลงได้ '
 'เป็นแหล่งพรหมชาติแหล่งเดียวที่ตรวจแล้วว่าใช้ได้เต็มรูปแบบ '
 'ข้อควรระวัง: PDM เป็นการแถลงสถานะ ไม่ใช่สัญญาอนุญาต และการเข้าถึงผ่าน '
 'Digitised Manuscripts ของ BL ยังไม่เสถียรหลังเหตุโจมตีไซเบอร์ พ.ศ. 2566', 'draft'),

-- ── Wikisource: full transcriptions, but two very different rights pictures ─
-- Same work as khamphi-horasat-thai in v1; this records the transcription as a
-- separate edition below rather than duplicating the work.

('ws-kham-thamnai-fan', 'คำทำนายฝัน (ฉบับวิกิซอร์ซ)',
 'พระอรรถวสิษฐสุธี (ช. อิศรภักดี)', 'ไม่ทราบปีพิมพ์ต้นฉบับ',
 'unknown', null, null,
 'โครงสร้างตรงกับที่ NIMIT ต้องการที่สุดที่พบมา: คู่มือทำนายฝันจัดหมวด 15 หมวด '
 'พร้อมกฎเรื่องยามที่ฝันและวันในสัปดาห์ '
 '*** ห้ามนำเข้าจนกว่าจะตรวจสอบได้ *** — หน้าวิกิซอร์ซติดแท็ก {{no source}} '
 'และไม่มีเทมเพลตลิขสิทธิ์ใด ๆ แปลว่าชุมชนวิกิซอร์ซเองยังไม่ยืนยันสถานะ '
 'ต้องสืบหาฉบับพิมพ์ต้นทางและปีพิมพ์ก่อน', 'draft'),

-- ── Internet Archive: Thammasat cremation volumes ──────────────────────────
-- หนังสืออนุสรณ์งานศพ are the classic Thai vehicle for reprinting divination
-- texts. 3,873 items, several directly on target. Rights unstated at both
-- collection and item level, so each needs its own s.19/s.20 assessment.
('ia-tewada-noppakhro', 'ตำราเทวดานพเคราะห์แลวิธีรักษาอุโบสถ',
 null, 'พิมพ์ พ.ศ. 2499',
 'unknown', null, null,
 'หนังสืออนุสรณ์งานศพ พิมพ์ พ.ศ. 2499 (70 ปีมาแล้ว) — หากไม่ปรากฏชื่อผู้แต่ง '
 'อายุคุ้มครอง 50 ปีน่าจะสิ้นสุดแล้ว ต้องเปิดหน้าปกในตรวจว่ามีผู้เรียบเรียงระบุชื่อหรือไม่', 'draft'),

('ia-horasat-wannakhadi', 'โหราศาสตร์ในวรรณคดี (ตำราโหราศาสตร์ฉบับพิสดาร)',
 null, 'พิมพ์ พ.ศ. 2502',
 'unknown', null, null,
 'หนังสืออนุสรณ์งานศพ พ.ศ. 2502; ตรวจผู้เรียบเรียงก่อนสรุปสถานะ', 'draft'),

('ia-khwamru-horasat', 'ความรู้บางเรื่องเกี่ยวกับโหราศาสตร์',
 null, 'พิมพ์ พ.ศ. 2511',
 'unknown', null, null,
 'หนังสืออนุสรณ์งานศพ พ.ศ. 2511; ตรวจผู้เรียบเรียงก่อนสรุปสถานะ', 'draft'),

('ia-chakkathipani-dika', 'พระคัมภีร์จักรทีปนี ฎีกาโหราศาสตร์ (ฉบับ Internet Archive)',
 null, 'ไม่ทราบปีพิมพ์',
 'unknown', null, null,
 'ตรงกับเป้าหมายจักรทีปนี 178 หน้า แต่เป็นไฟล์ที่ผู้ใช้ทั่วไปอัปโหลด '
 'ไม่มีสัญญาอนุญาตและไม่มีเครื่องหมาย PD — ถือว่ายังไม่ยืนยัน', 'draft'),

-- ── Wellcome: not digitised, but the licence default makes it worth asking ──
('wellcome-ms-thai-10', 'MS Thai 10 — คู่มือโหราจารย์และการพยากรณ์',
 null, 'คริสต์ศตวรรษที่ 19',
 'unknown', null, null,
 'สมุดไทยพับ อักษรไทยและขอม ระบุเป็น "คู่มือสำหรับโหราจารย์และผู้พยากรณ์" '
 'ยังไม่ถูกแปลงเป็นดิจิทัล (อยู่ใน closed stores) '
 'โอกาสสำคัญ: Wellcome เผยแพร่เนื้อหาดิจิทัลส่วนใหญ่ภายใต้ CC BY 4.0 '
 'ซึ่งอนุญาตใช้เชิงพาณิชย์ได้ — การยื่นขอให้แปลงเป็นดิจิทัลจึงเป็นการลงแรง '
 'ที่ให้ผลตอบแทนสูงที่สุดรายการเดียวที่พบ', 'draft'),

-- ── Northern Thai / Lanna: large but non-commercial ────────────────────────
('dlntm-lanna-astrology', 'เอกสารโบราณล้านนา หมวดโหราศาสตร์และไสยศาสตร์ (DLNTM)',
 null, 'เอกสารโบราณล้านนา',
 'public_domain', 'published_50y_anon', null,
 'คลัง 6,137 ฉบับ 234,752 ภาพ รวมไมโครฟิล์มโครงการอนุรักษ์คัมภีร์ล้านนา '
 'มหาวิทยาลัยเชียงใหม่ มีหมวด "โหราศาสตร์และไสยศาสตร์" โดยตรง '
 'ตัวเอกสารเก่าพ้นลิขสิทธิ์ แต่ภาพดิจิทัลเผยแพร่ภายใต้ CC BY-NC 4.0 '
 'ซึ่ง NC ปิดกั้นการใช้เชิงพาณิชย์ — ต้องขอสิทธิ์แยก', 'draft'),

-- ── THE TRAP: recorded so nobody ingests it by mistake ─────────────────────
-- This is the top search result for Thai phrommachat and carries no licence.
-- Recording it as a work with a loud note is the only way the knowledge
-- survives past whoever did the research.
('BLOCKED-proommachat-thep', 'ตำราพรหมชาติ โดย เทพย์ สาริกบุตร (ห้ามใช้)',
 'เทพย์ สาริกบุตร', 'ผู้แต่ง พ.ศ. 2462–2536',
 'copyrighted_cite_only', null, 'ทายาทของเทพย์ สาริกบุตร',
 '*** ห้ามนำเข้าโดยเด็ดขาด *** ไฟล์ขนาด 480 MB บน Internet Archive '
 'เป็นผลการค้นหาอันดับต้นสำหรับคำว่า "ตำราพรหมชาติ" และไม่ระบุสัญญาอนุญาต '
 'ผู้แต่งถึงแก่กรรม พ.ศ. 2536 ลิขสิทธิ์จึงคุ้มครองถึง พ.ศ. 2586 '
 'เกือบแน่นอนว่าเป็นการอัปโหลดโดยไม่ได้รับอนุญาต '
 'สำเนาบน pubhtml5 SlideShare และ 4shared ก็เข้าข่ายเดียวกัน '
 'บันทึกไว้ที่นี่เพื่อไม่ให้ผู้ทำงานรุ่นถัดไปเดินซ้ำรอย', 'archived')

on conflict (slug) do update set
  rights = excluded.rights,
  rights_note_th = excluded.rights_note_th,
  status = excluded.status;

-- ---------------------------------------------------------------------------
-- EDITIONS
-- ---------------------------------------------------------------------------

insert into content.edition
  (work_id, citekey, tier, label_th, custodian_th, stable_identifier,
   year_published, physical_desc_th, script_th, languages, url,
   custodian_rights, rights_note_th, status)
select w.id, v.citekey, v.tier::content.trust_tier, v.label_th, v.custodian_th,
       v.stable_identifier, v.year_published, v.physical_desc_th, v.script_th,
       v.languages, v.url, v.custodian_rights::content.custodian_rights,
       v.rights_note_th, v.status::content.editorial_status
from (values

('bl-or4830-phrommachat','bl-or4830','a1','ต้นฉบับ Or. 4830','British Library',
 'Or. 4830',null,'สมุดไทยพับ มีภาพประกอบสี','ไทย',array['th'],
 'https://artsandculture.google.com/asset/yAFsIKlxMVzqtQ','open',
 'Public Domain Mark 1.0 — ใช้เชิงพาณิชย์และดัดแปลงได้ '
 'ปัจจุบันเข้าถึงผ่าน Google Arts & Culture ได้เสถียรกว่าเว็บ BL เอง','draft'),

('khamphi-horasat-thai','wikisource-khamphi','a2','ฉบับถอดความวิกิซอร์ซ','วิกิซอร์ซภาษาไทย',
 'คัมภีร์โหราศาสตร์ไทยมาตรฐานฉบับสมบูรณ์',null,'ข้อความถอดความครบ ~14 ภาค',null,array['th'],
 'https://th.wikisource.org/wiki/คัมภีร์โหราศาสตร์ไทยมาตรฐานฉบับสมบูรณ์','cc_by_sa',
 'ถอดความครบทั้งเล่ม ครอบคลุมฤกษ์ นวางศ์ ตำนานดาวฤกษ์ 27 นพเคราะห์ สุริยยาตร์ '
 'หน้าติดเทมเพลต {{ลิขสิทธิ์หมดอายุ-ไทย}} และมีคำรับรองโดยพระยาโหราธิบดี '
 'แต่แท็ก PD ของวิกิซอร์ซเป็นการยืนยันของชุมชน ไม่ใช่ความเห็นทางกฎหมาย '
 'ต้องหาปีถึงแก่กรรมของหลวงวิศาลดรุณกรก่อน; ตัวข้อความถอดความอยู่ใต้ CC BY-SA '
 'จึงมีภาระ share-alike ติดมาด้วย','draft'),

('ws-kham-thamnai-fan','wikisource-thamnai-fan','b2','ฉบับวิกิซอร์ซ','วิกิซอร์ซภาษาไทย',
 'คำทำนายฝัน',null,'ข้อความถอดความ 15 หมวด',null,array['th'],
 'https://th.wikisource.org/wiki/คำทำนายฝัน','unknown',
 'ห้ามนำเข้าจนกว่าจะสืบหาฉบับพิมพ์ต้นทางได้','draft'),

('ia-tewada-noppakhro','ia-unset0000unse-g6s9','a2','ฉบับดิจิทัล Internet Archive',
 'มหาวิทยาลัยธรรมศาสตร์ / Internet Archive','unset0000unse_g6s9', 1956,'หนังสืออนุสรณ์',null,array['th'],
 'https://archive.org/details/unset0000unse_g6s9','unknown',
 'คอลเลกชัน thaicremationcopy ไม่ระบุ rights และ licenseurl ทั้งระดับคอลเลกชันและรายการ','draft'),

('ia-horasat-wannakhadi','ia-unset0000unse-s3a3','a2','ฉบับดิจิทัล Internet Archive',
 'มหาวิทยาลัยธรรมศาสตร์ / Internet Archive','unset0000unse_s3a3', 1959,'หนังสืออนุสรณ์',null,array['th'],
 'https://archive.org/details/unset0000unse_s3a3','unknown',null,'draft'),

('ia-khwamru-horasat','ia-unset00002435','a2','ฉบับดิจิทัล Internet Archive',
 'มหาวิทยาลัยธรรมศาสตร์ / Internet Archive','unset00002435', 1968,'หนังสืออนุสรณ์',null,array['th'],
 'https://archive.org/details/unset00002435','unknown',null,'draft'),

('ia-chakkathipani-dika','ia-phrakhamphi','b2','ไฟล์อัปโหลดโดยผู้ใช้','Internet Archive (opensource)',
 'Phrakhamphichakthipani',null,'178 หน้า',null,array['th'],
 'https://archive.org/details/Phrakhamphichakthipani','unknown',
 'ไม่มีสัญญาอนุญาตและไม่มีเครื่องหมาย PD — ใช้เป็นเบาะแสตามหาฉบับพิมพ์จริงเท่านั้น','draft'),

('wellcome-ms-thai-10','wellcome-ms-thai-10','a1','ต้นฉบับ (ยังไม่แปลงดิจิทัล)','Wellcome Collection',
 'MS Thai 10',null,'สมุดไทยพับ','ไทยและขอม',array['th','km'],
 'https://wellcomecollection.org/works/qet5pjeu','unknown',
 'ยังไม่แปลงเป็นดิจิทัล อยู่ใน closed stores — ยื่นคำขอแปลงดิจิทัล '
 'เนื้อหาดิจิทัลของ Wellcome ส่วนใหญ่เป็น CC BY 4.0 ซึ่งอนุญาตเชิงพาณิชย์','draft'),

('dlntm-lanna-astrology','dlntm-lanna','a1','คลังดิจิทัลเอกสารล้านนา','CrossAsia / DLNTM',
 'หมวด Astrology and magic',null,'6,137 ฉบับ 234,752 ภาพ','อักษรธรรมล้านนา',array['th','pi'],
 'https://digital.crossasia.org/digital-library-of-northern-thai-manuscripts','cc_by_nc',
 'CC BY-NC 4.0 — ดัดแปลงได้แต่ห้ามใช้เชิงพาณิชย์ '
 'ข้อยกเว้น: ตำรายาและเวชศาสตร์ในคอลเลกชัน PNTMP ไม่อยู่ใต้สัญญาอนุญาตนี้','draft'),

('BLOCKED-proommachat-thep','BLOCKED-ia-proommachat','d','ไฟล์อัปโหลดที่ไม่ได้รับอนุญาต',
 'Internet Archive (ผู้ใช้ทั่วไป)','proommachat', 2020,'480 MB',null,array['th'],
 'https://archive.org/details/proommachat','all_rights_reserved',
 'ห้ามใช้ — ลิขสิทธิ์คุ้มครองถึง พ.ศ. 2586','archived')

) as v(work_slug, citekey, tier, label_th, custodian_th, stable_identifier,
       year_published, physical_desc_th, script_th, languages, url,
       custodian_rights, rights_note_th, status)
join content.work w on w.slug = v.work_slug
on conflict (citekey) do update set
  custodian_rights = excluded.custodian_rights,
  rights_note_th = excluded.rights_note_th,
  status = excluded.status;

-- ---------------------------------------------------------------------------
-- Acquisition actions arising from this research
-- ---------------------------------------------------------------------------

insert into editorial.acquisition (edition_id, registry_ref, priority, stage, note_th)
select e.id, v.ref, v.priority, v.stage, v.note
from (values
  ('bl-or4830','NIM-V2-001','P0','granted',
   'ไม่ต้องขออนุญาต — PDM 1.0 เริ่มปริวรรตได้ทันที เป็นแหล่งพรหมชาติที่ใช้ได้จริงแหล่งแรก'),
  ('wikisource-khamphi','NIM-V2-002','P0','metadata',
   'หาปีถึงแก่กรรมของหลวงวิศาลดรุณกรจากหอจดหมายเหตุ/ราชกิจจานุเบกษา '
   'ถ้ายืนยันว่าพ้น 50 ปี จะได้เนื้อหาฤกษ์และนพเคราะห์ครบชุดโดยไม่ต้องเจรจา'),
  ('wellcome-ms-thai-10','NIM-V2-003','P0','outreach',
   'ยื่นคำขอแปลงเป็นดิจิทัล — สถาบันเดียวที่ค่าตั้งต้นเป็น CC BY 4.0 ใช้เชิงพาณิชย์ได้'),
  ('ia-unset0000unse-g6s9','NIM-V2-004','P1','metadata',
   'เปิดหน้าปกในตรวจว่ามีผู้เรียบเรียงระบุชื่อหรือไม่ — ถ้านิรนาม พ.ศ. 2499 ก็พ้นแล้ว'),
  ('dlntm-lanna','NIM-V2-005','P2','outreach',
   'ขอสิทธิ์เชิงพาณิชย์เพิ่มจาก CC BY-NC; คลังใหญ่ที่สุดสำหรับสายล้านนา')
) as v(citekey, ref, priority, stage, note)
join content.edition e on e.citekey = v.citekey
on conflict do nothing;
