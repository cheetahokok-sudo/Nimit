-- ============================================================================
-- Source registry v1 — 30 works, 37 editions
--
-- Derived from nimit_library_trusted_sources_v1, restructured onto the
-- work/edition split. The restructure exists because the registry's single
-- "rights" column conflated two different permissions:
--
--   * may we reproduce the TEXT?          -> work.rights
--   * may we redistribute THIS COPY?      -> edition.custodian_rights
--
-- Almost every A1 entry is a 19th-century anonymous สมุดไทย whose TEXT is long
-- out of copyright, held by an institution that asserts All Rights Reserved
-- over ITS SCAN. Both statements are true at once. Collapsing them either
-- forfeits material that is legitimately usable, or invites infringement.
--
-- EVERY ROW IS status='draft'. Nothing here reaches the app until a human
-- verifies it. rights_verified_by is null throughout — these are considered
-- assessments, not clearances.
--
-- Bibliography is public by design: a product whose pitch is verifiable
-- sourcing must let anyone check its citations.
--
-- Idempotent on citekey/slug.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- WORKS
-- ---------------------------------------------------------------------------

insert into content.work
  (slug, canonical_title_th, attributed_author_th, composed_period_th,
   rights, pd_basis, copyright_holder, rights_note_th, status)
values

-- ── Public domain: named author, died well over 50 years ago ────────────────
('chakkathipani', 'คัมภีร์จักรทีปนี',
 'สมเด็จพระมหาสมณเจ้า กรมพระปรมานุชิตชิโนรส', 'ต้นรัตนโกสินทร์',
 'public_domain', 'author_died_50y', null,
 'ผู้นิพนธ์สิ้นพระชนม์ พ.ศ. 2396 พ้นอายุคุ้มครองตามมาตรา 19 อย่างชัดเจน; '
 'สิทธิ์ในภาพสแกนของแต่ละฉบับเป็นคนละเรื่อง ดู edition.custodian_rights', 'draft'),

-- ── Public domain: anonymous manuscripts, far beyond any term ───────────────
-- Thai law protects anonymous works for 50 years from creation/publication.
-- These สมุดไทย predate the 20th century, so the term expired long ago on any
-- reading. The residual question is the custodian's claim over its scans.
('tamra-thamnai-fan-nlt447', 'ตำราทำนายฝัน (ฉบับหอสมุดแห่งชาติ เลขทะเบียน 447)',
 null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'ต้นฉบับไม่ปรากฏชื่อผู้แต่ง เป็นสมุดไทยเก่ากว่าหนึ่งศตวรรษ; '
 'ข้อความพ้นอายุคุ้มครองแล้ว แต่ห้ามเผยแพร่ภาพสแกนของหอสมุดโดยไม่ได้รับอนุญาต', 'draft'),

('tamra-phrommachat', 'ตำราพรหมชาติ',
 null, 'ไม่ระบุ; สายตำราเก่า',
 'public_domain', 'published_50y_anon', null,
 'สายตำราพื้นบ้านที่มีหลายฉบับ ไม่ปรากฏผู้แต่ง; '
 'เก็บเป็น work เดียวและผูกหลาย edition เพื่อให้เปรียบเทียบความต่างระหว่างฉบับได้', 'draft'),

('tamra-horasat-sakarat', 'ตำราโหราศาสตร์ ว่าด้วยวิธีบอกศักราชและอธิกมาส',
 null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null, null, 'draft'),

('tamra-phayakon-khamchan', 'ตำราพยากรณ์คำฉันท์',
 null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'คำพยากรณ์ในรูปฉันท์ เหมาะกับฟีเจอร์อ่านต้นฉบับคู่คำแปลปัจจุบัน', 'draft'),

('tamra-mordu-nlt433', 'ตำราหมอดู (ฉบับหอสมุดแห่งชาติ เลขทะเบียน 433)',
 null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'ระเบียนไม่มีสาระสังเขป ต้องเปิดภาพตรวจเนื้อหาก่อนจัดหมวด', 'draft'),

-- ── SAC manuscripts: each is a unique miscellany, so each is its own work ───
('npt003-010', 'NPT003-010 ตำรายาและตำราโหราศาสตร์',
 null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'ส่วนท้ายเป็นตำราทำนายฝันแบบร้อยกรอง; ภาพดิจิทัลของ ศมส. เป็น CC BY-NC-ND '
 'ซึ่งจำกัดการใช้ภาพ ไม่ได้ทำให้ข้อความเก่ากลับมามีลิขสิทธิ์', 'draft'),

('rbr003-012', 'RBR003-012 ตำราฤกษ์', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'อักษรธรรมล้านนา ต้องมีผู้เชี่ยวชาญร่วมปริวรรต', 'draft'),

('rbr003-077', 'RBR003-077 ตำราดูฤกษ์ยาม', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'มีคำบูชา/คาถา ควรแยกออกจากโมดูลพยากรณ์ทั่วไป', 'draft'),

('rbr003-073', 'RBR003-073 ตำราพยากรณ์', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null, null, 'draft'),

('pbi001-013', 'PBI001-013 ตำราโหราศาสตร์', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'เนื้อหาการค้าและการเกษตร ห้ามนำเสนอเป็นคำแนะนำธุรกิจแบบรับรองผล', 'draft'),

('pbi001-017', 'PBI001-017 ตำราโหราศาสตร์', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'ฤกษ์ปลูกเรือนและลงเสาเข็ม นำเสนอเป็นประวัติความเชื่อ ไม่ใช่มาตรฐานวิศวกรรม', 'draft'),

('npt007-014', 'NPT007-014 ตำราดูฤกษ์ยาม', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null, null, 'draft'),

('rbr003-057', 'RBR003-057 ตำราฤกษ์ยามและคาถา', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'มีคาถาและภาพยันต์ ต้องมี content warning และแยกจากพุทธธรรม; '
 'ห้ามสร้างขั้นตอนพิธีกรรมอัตโนมัติจากต้นฉบับ', 'draft'),

('rbr003-042', 'RBR003-042 ตำรายา ตำราทายฤกษ์ยาม', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'มีตำรับยา ตั้ง medical safety flag: ห้ามแปลงเป็นคำแนะนำการรักษาโรคเด็ดขาด', 'draft'),

('rbr007-017', 'RBR007-017 ตำรายาและตำราดูทิศ', null, 'ไม่ระบุ; สมุดไทยเก่า',
 'public_domain', 'published_50y_anon', null,
 'ต้องแยกเนื้อหาโหราศาสตร์ออกจากเนื้อหาการแพทย์', 'draft'),

-- ── Canonical Buddhist text: ancient, but the modern Thai rendering is not ──
('mahasupina-jataka', 'มหาสุบินชาดก',
 null, 'ชาดกในพระไตรปิฎก',
 'public_domain', 'pre_copyright_era', null,
 'ตัวชาดกเป็นวรรณกรรมโบราณพ้นลิขสิทธิ์; แต่คำแปลภาษาไทยสมัยใหม่และการจัดทำเว็บ '
 'เป็นงานของผู้จัดทำแต่ละราย ต้องดูสิทธิ์ระดับ edition แยกต่างหาก', 'draft'),

-- ── UNKNOWN: needs verification before any verbatim use ─────────────────────
-- These are the genuine traps. Each looks old but has a modern editorial or
-- compilation layer whose status is unresolved.
('pramuan-tamra-thamnai-1', 'ประมวลตำราทำนาย (ของเก่า) ภาค 1',
 null, 'ฉบับพิมพ์เก่า ไม่ทราบปีแน่ชัด',
 'unknown', null, null,
 'ตัวตำราที่นำมารวมเป็นของเก่าและพ้นลิขสิทธิ์ แต่ "การประมวล/เรียบเรียง" '
 'เป็นงานสร้างสรรค์ต่างหาก ต้องหาปีพิมพ์และผู้เรียบเรียงก่อนสรุปสถานะ', 'draft'),

('horasat-buangton-ruek', 'โหราศาสตร์เบื้องต้นและการใช้ฤกษ์',
 null, 'พิมพ์ครั้งแรก พ.ศ. 2505',
 'unknown', null, null,
 'พิมพ์ พ.ศ. 2505 (64 ปีมาแล้ว) — มีโอกาสสูงที่จะพ้นอายุคุ้มครองหากเป็นงานนิรนาม '
 'หรือของนิติบุคคล และอาจเข้าข่ายมาตรา 7 หากเป็นเอกสารราชการ; '
 'เป็นรายการที่คุ้มค่าที่สุดในการให้ทนายตรวจ เพราะถ้าเป็น PD จะปลดล็อกเนื้อหาจำนวนมาก', 'draft'),

('horasat-samret', 'โหราศาสตร์สำเร็จ',
 null, 'ไม่ทราบปีเรียบเรียงเดิม',
 'unknown', null, null,
 'เผยแพร่ดิจิทัล พ.ศ. 2568 แต่ไม่ทราบปีเรียบเรียงต้นฉบับ; '
 'ต้องเปิดหน้า title/copyright เพื่อตรวจผู้แต่งและปีพิมพ์', 'draft'),

('khamphi-horasat-thai', 'คัมภีร์โหราศาสตร์ไทย มาตรฐานฉบับสมบูรณ์',
 'หลวงวิศาลดรุณกร (อั้น สาริกบุตร)', 'เรียบเรียง พ.ศ. 2466–2480',
 'unknown', null, null,
 'ตัวอย่างชัดเจนของกับดัก: งานเรียบเรียง พ.ศ. 2466–2480 อาจพ้นลิขสิทธิ์แล้ว '
 'หากผู้เรียบเรียงถึงแก่กรรมเกิน 50 ปี — แต่ฉบับพิมพ์ใหม่ พ.ศ. 2563 มีงานบรรณาธิการ '
 'ที่มีลิขสิทธิ์ของตนเอง ต้องหาปีถึงแก่กรรมก่อน แล้วจึงใช้เฉพาะฉบับเดิมเท่านั้น', 'draft'),

('ich-nature-cosmos', 'ความรู้และแนวปฏิบัติเกี่ยวกับธรรมชาติและจักรวาล',
 null, 'เผยแพร่โดยกระทรวงวัฒนธรรม',
 'unknown', null, 'กรมส่งเสริมวัฒนธรรม กระทรวงวัฒนธรรม',
 'เอกสารราชการ อาจเข้าข่ายมาตรา 7 ซึ่งไม่ถือเป็นงานอันมีลิขสิทธิ์ '
 'แต่ต้องยืนยันว่าเป็น "คำสั่ง ระเบียบ ประกาศ" หรือเป็นงานวิชาการที่ยังมีลิขสิทธิ์', 'draft'),

('suriyayat-narai-evidence', 'หลักฐานประวัติศาสตร์คัมภีร์สุริยยาตร์สมัยสมเด็จพระนารายณ์',
 null, 'อ้างบันทึกลาลูแบร์ คริสต์ศตวรรษที่ 17',
 'unknown', null, null,
 'หลักฐานชั้นรอง; ตัวบทความสมัยใหม่มีลิขสิทธิ์แม้เนื้อหาที่กล่าวถึงจะเก่า', 'draft'),

('orst-taksa', 'ทักษา — คำอธิบายศัพท์ สำนักงานราชบัณฑิตยสภา',
 null, 'เผยแพร่ 18 ธันวาคม 2552',
 'unknown', null, 'สำนักงานราชบัณฑิตยสภา',
 'เป็น authority ด้านนิยามศัพท์ ไม่ใช่หลักฐานความแม่นของคำพยากรณ์; '
 'อาจเข้าข่ายมาตรา 7 ต้องตรวจ', 'draft'),

-- ── Copyrighted, cite and paraphrase only ──────────────────────────────────
('su-taksa-animals', 'คติสัตว์ตัวนามในคัมภีร์ทักษาพยากรณ์และอิทธิพลต่อศิลปะไทย',
 'ผู้วิจัย มหาวิทยาลัยศิลปากร', 'พ.ศ. 2563',
 'copyrighted_cite_only', null, 'ผู้วิจัยและมหาวิทยาลัยศิลปากร',
 'อ้างอิงและถอดความได้ ห้ามคัดลอกภาพหรือตาราง; ใช้เป็นบริบทวิชาการ '
 'ไม่ใช่หลักฐานคำพยากรณ์โดยตรง', 'draft'),

('su-phrakhro-thasa', 'การศึกษาเปรียบเทียบแนวคิดเรื่องพระเคราะห์ ทศา และนรลักษณ์',
 'ผู้วิจัย มหาวิทยาลัยศิลปากร', 'พ.ศ. 2562',
 'copyrighted_cite_only', null, 'ผู้วิจัยและมหาวิทยาลัยศิลปากร',
 'มีคุณค่าสูงในการทำ provenance graph ระหว่างคัมภีร์', 'draft'),

('cu-astrologer-media', 'แนวทางการสร้างความเชื่อของนักโหราศาสตร์ผ่านสื่อสิ่งพิมพ์',
 'ผู้วิจัย จุฬาลงกรณ์มหาวิทยาลัย', 'ไม่ระบุในระเบียนย่อ',
 'copyrighted_cite_only', null, 'ผู้วิจัยและจุฬาลงกรณ์มหาวิทยาลัย',
 'ใช้ออกแบบ trust label และนโยบายการเปิดเผยของครีเอเตอร์', 'draft'),

('tu-chaloem-traiphop', 'เฉลิมไตรภพ: การศึกษาแนวคิดและกลวิธีสร้างสรรค์',
 'ผู้วิจัย มหาวิทยาลัยธรรมศาสตร์', 'พ.ศ. 2560',
 'copyrighted_cite_only', null, 'ผู้วิจัยและมหาวิทยาลัยธรรมศาสตร์',
 'สำคัญต่อการไม่เหมารวมว่าทุกฉบับมาจากผู้แต่งคนเดียว', 'draft'),

('thairath-dream', 'ฐานทำนายฝันและคำค้นยอดนิยม ไทยรัฐออนไลน์',
 'ไทยรัฐออนไลน์', 'อัปเดตต่อเนื่อง',
 'copyrighted_cite_only', null, 'บริษัท วัชรพล จำกัด',
 'ใช้เฝ้าดูแนวโน้มและคำค้นเท่านั้น ห้ามคัดลอกฐานข้อมูลหรือข้อความ '
 'และห้ามใช้เป็น authority ของคำพยากรณ์โบราณ', 'draft'),

('myhora-platform', 'MyHora: ทำนายฝันและโหราศาสตร์ไทย',
 'MyHora', 'อัปเดตต่อเนื่อง',
 'copyrighted_cite_only', null, 'MyHora',
 'ใช้เป็น competitive benchmark เท่านั้น ห้าม scrape; '
 'ไม่ถือเป็นหลักฐานทางประวัติศาสตร์แม้จะอ้างว่าใช้ศาสตร์โบราณ', 'draft')

on conflict (slug) do update set
  canonical_title_th = excluded.canonical_title_th,
  rights = excluded.rights,
  pd_basis = excluded.pd_basis,
  rights_note_th = excluded.rights_note_th;

-- ---------------------------------------------------------------------------
-- EDITIONS
--
-- custodian_rights records what the HOLDER of this copy asserts, which is
-- independent of the work's copyright status above.
-- ---------------------------------------------------------------------------

insert into content.edition
  (work_id, citekey, tier, label_th, custodian_th, stable_identifier,
   year_published, physical_desc_th, script_th, languages, url,
   custodian_rights, rights_note_th, status)
select w.id, v.citekey, v.tier::content.trust_tier, v.label_th, v.custodian_th,
       v.stable_identifier, v.year_published, v.physical_desc_th, v.script_th,
       v.languages, v.url, v.custodian_rights::content.custodian_rights,
       v.rights_note_th, 'draft'
from (values

-- จักรทีปนี — three witnesses, which is what makes cross-checking possible
('chakkathipani','nlt-2202','a1','ต้นฉบับคัมภีร์จักรทีปนี','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 369', null,'สมุดไทยขาว',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/2202','all_rights_reserved',
 'D-Library สงวนสิทธิ์ในภาพสแกน; ข้อความต้นฉบับเองพ้นลิขสิทธิ์แล้ว'),
('chakkathipani','finearts-2508','a2','ฉบับกรมศิลปากร พ.ศ. 2508','กรมศิลปากร',
 '48 หน้า', 1965,'หนังสืออนุสรณ์ / PDF',null,array['th'],
 'https://www.finearts.go.th/storage/contents/2022/02/file/SF3mob1FiLnC5zMNqVuV590zgS2gfbs8C1RXXZBn.pdf',
 'unknown','ต้องตรวจว่าเข้าข่ายมาตรา 7 (เอกสารราชการ) หรือเป็นงานมีลิขสิทธิ์ของกรมศิลปากร'),
('chakkathipani','vajirayana-chakkathipani','a2','ฉบับข้อความค้นได้','ห้องสมุดดิจิทัลวชิรญาณ',
 'หน้าเว็บรายบท',null,'HTML ค้นหาได้','ไทยอักขรวิธีเก่า',array['th'],
 'https://vajirayana.org/หนังสือจักรทีปนี-ตำราโหราศาสตร์/ตำราจักรทีปนี','unknown',
 'ใช้เป็นเครื่องมือค้น ไม่ใช่ฉบับฐาน; ต้องเทียบกับต้นฉบับก่อนเผยแพร่'),

-- ตำราทำนายฝัน — the anchor of the dream library
('tamra-thamnai-fan-nlt447','nlt-3742','a1','ต้นฉบับตำราทำนายฝัน','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 447',null,'สมุดไทยดำ',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/3742','all_rights_reserved',
 'P0: ติดต่อหอสมุดแห่งชาติขอสำเนาความละเอียดสูงและสิทธิ์ใช้ภาพ'),

('pramuan-tamra-thamnai-1','nlt-6238','a2','ประมวลตำราทำนาย (ของเก่า) ภาค 1','สำนักหอสมุดแห่งชาติ',
 'D-Library 6238',null,'หนังสือดิจิทัล',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/6238','all_rights_reserved',
 'ครอบคลุมฝัน สัตว์ตก และกระเหม่น เหมาะกับ taxonomy ข้ามหมวด'),

-- พรหมชาติ — six witnesses of one work, so the app can show them disagreeing
('tamra-phrommachat','nlt-1165','a1','ฉบับมีภาพพรหมชาติ','สำนักหอสมุดแห่งชาติ',
 'D-Library 1165',null,'สมุดไทยขาว มีภาพประกอบ',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/1165','all_rights_reserved',null),
('tamra-phrommachat','nlt-1177','a1','ฉบับมีภาพประกอบ (พระเคราะห์)','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 43',null,'สมุดไทยขาว มีภาพประกอบ',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/1177','all_rights_reserved',null),
('tamra-phrommachat','nlt-1388','a1','ฉบับว่าด้วยชะตาวัน เดือน ปี','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 151',null,'สมุดไทยดำ',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/1388','all_rights_reserved',null),
('tamra-phrommachat','nlt-1239','a1','ฉบับว่าด้วยคู่สมพงษ์','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 80',null,'สมุดไทยขาว',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/1239','all_rights_reserved',
 'ใช้เชิงวัฒนธรรมเท่านั้น ไม่ใช้ตัดสินความสัมพันธ์จริง'),
('tamra-phrommachat','nlt-3939','a1','ฉบับว่าด้วยฤกษ์ยามและวันเดือนปี','สำนักหอสมุดแห่งชาติ',
 'D-Library 3939',null,'สมุดไทยขาว',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/3939','all_rights_reserved',null),
('tamra-phrommachat','nlt-3795','a1','ฉบับว่าด้วยทำนายลักษณะบุคคล','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 618',null,'สมุดไทยขาว มีภาพประกอบ',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/3795','all_rights_reserved',
 'ethics flag: เนื้อหาทำนายจากรูปลักษณ์ เสี่ยงต่อการเหมารวม ต้องมีกรอบนำเสนอชัดเจน'),

('tamra-horasat-sakarat','nlt-2985','a1','ต้นฉบับว่าด้วยศักราชและอธิกมาส','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 604',null,'สมุดไทย',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/2985','all_rights_reserved',null),
('tamra-phayakon-khamchan','nlt-1400','a1','ต้นฉบับตำราพยากรณ์คำฉันท์','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 137',null,'สมุดไทยดำ',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/1400','all_rights_reserved',null),
('tamra-mordu-nlt433','nlt-3123','a1','ต้นฉบับตำราหมอดู','สำนักหอสมุดแห่งชาติ',
 'เลขทะเบียน 433',null,'สมุดไทยดำ',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/3123','all_rights_reserved',null),

-- SAC — CC BY-NC-ND. The NC and ND limbs both bite for a commercial app.
('npt003-010','sac-300','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'NPT003-010',null,'สมุดไทยขาว 66 หน้า','ไทยและขอมไทย',array['th','pi'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=300','cc_by_nc_nd',
 'NC ห้ามใช้เชิงพาณิชย์ และ ND ห้ามดัดแปลง ซึ่งรวมถึงการปรับสีภาพ; '
 'ต้องขอสิทธิ์เพิ่มก่อนใช้ภาพในแอป'),
('rbr003-012','sac-388','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'RBR003-012',null,'สมุดไทยขาว 60 หน้า','อักษรธรรมล้านนา',array['th','pi'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=388','cc_by_nc_nd',null),
('rbr003-077','sac-465','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'RBR003-077',null,'สมุดไทย',null,array['th'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=465','cc_by_nc_nd',null),
('rbr003-073','sac-456','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'RBR003-073',null,'สมุดไทย 48 หน้า',null,array['th'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=456','cc_by_nc_nd',null),
('pbi001-013','sac-1325','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'PBI001-013',null,'สมุดไทยขาว 91 หน้า',null,array['th'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=1325','cc_by_nc_nd',null),
('pbi001-017','sac-1329','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'PBI001-017',null,'สมุดไทยขาว 63 หน้า',null,array['th'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=1329','cc_by_nc_nd',null),
('npt007-014','sac-13','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'NPT007-014',null,'สมุดไทย 62 หน้า',null,array['th'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=13','cc_by_nc_nd',null),
('rbr003-057','sac-440','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'RBR003-057',null,'สมุดไทย 44 หน้า','อักษรธรรมล้านนา',array['th','pi'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=440','cc_by_nc_nd',
 'มีคาถาและภาพยันต์ ต้องมี content warning'),
('rbr003-042','sac-425','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'RBR003-042',null,'สมุดไทยดำ 52 หน้า',null,array['th','pi'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=425','cc_by_nc_nd',
 'medical safety flag'),
('rbr007-017','sac-1227','a1','ฉบับดิจิทัล ศมส.','ศูนย์มานุษยวิทยาสิรินธร',
 'RBR007-017',null,'เอกสารตัวเขียนดิจิทัล',null,array['th'],
 'https://manuscripts.sac.or.th/manuscript-info.php?id=1227','cc_by_nc_nd',null),

-- Official printed editions
('horasat-buangton-ruek','nlt-19345','a2','ฉบับพิมพ์ พ.ศ. 2505','กรมศิลปากร / สำนักหอสมุดแห่งชาติ',
 'D-Library 19345', 1962,'หนังสืออนุสรณ์ / PDF',null,array['th'],
 'https://digital.nlt.go.th/dlib/items/show/19345','unknown',
 'ผู้สมัครที่ดีที่สุดสำหรับการตรวจสถานะ PD — พิมพ์มาแล้ว 64 ปี'),
('horasat-samret','finearts-samret','a2','ฉบับดิจิทัลกรมศิลปากร','กรมศิลปากร',
 'Fine Arts PDF', 2025,'PDF',null,array['th'],
 'https://finearts.go.th/storage/contents/2025/03/file/TvIt17ZdROhIAQIYsW8kClpvyPovH7H9MZI65tit.pdf',
 'unknown','ต้องเปิดหน้า title/copyright ก่อนนำเข้า'),

('khamphi-horasat-thai','chula-2283555','b2','ฉบับพิมพ์ใหม่ พ.ศ. 2563','ระเบียนจุฬาลงกรณ์มหาวิทยาลัย',
 'Chula bib 2283555', 2020,'หนังสือ 896 หน้า',null,array['th'],
 'https://www.car.chula.ac.th/display7.php?bib=2283555','all_rights_reserved',
 'ระบุว่ารวบรวมจากตำราพยากรณ์ 153 คัมภีร์ — ใช้เป็นดัชนีตามหาต้นทาง '
 'ไม่ใช้แทนต้นฉบับ'),

-- Academic
('su-taksa-animals','su-58107312','b1','วิทยานิพนธ์ ม.ศิลปากร พ.ศ. 2563','มหาวิทยาลัยศิลปากร',
 '58107312', 2020,'PDF',null,array['th'],
 'https://ithesis-ir.su.ac.th/dspace/bitstream/123456789/2554/1/58107312.pdf',
 'all_rights_reserved',null),
('su-phrakhro-thasa','su-57116801','b1','วิทยานิพนธ์ ม.ศิลปากร พ.ศ. 2562','มหาวิทยาลัยศิลปากร',
 '57116801', 2019,'PDF',null,array['th'],
 'https://ithesis-ir.su.ac.th/dspace/bitstream/123456789/2543/1/57116801.pdf',
 'all_rights_reserved',null),
('cu-astrologer-media','cu-69275','b1','ระเบียนงานวิจัย จุฬาฯ','จุฬาลงกรณ์มหาวิทยาลัย',
 'CU handle 123456789/69275',null,'ระเบียนและ e-book',null,array['th'],
 'https://cuir.car.chula.ac.th/handle/123456789/69275','all_rights_reserved',null),
('tu-chaloem-traiphop','tu-5606032315','b1','วิทยานิพนธ์ ม.ธรรมศาสตร์ พ.ศ. 2560','มหาวิทยาลัยธรรมศาสตร์',
 'TU_2017_5606032315_6858_5947', 2017,'PDF',null,array['th'],
 'https://ethesisarchive.library.tu.ac.th/thesis/2017/TU_2017_5606032315_6858_5947.pdf',
 'all_rights_reserved',null),
('orst-taksa','orst-taksa-2552','b1','บทความคำว่า ทักษา','สำนักงานราชบัณฑิตยสภา',
 'เผยแพร่ 18 ธ.ค. 2552', 2009,'หน้าเว็บ',null,array['th'],
 'https://legacy.orst.go.th/?knowledges=ทักษา','unknown',
 'อ้างอิงสั้นพร้อม citation ได้; ตรวจมาตรา 7 หากต้องการใช้มากกว่านั้น'),

-- Buddhist canon and cultural framing
('mahasupina-jataka','tipitaka-27-77','a2','พระไตรปิฎกเล่ม 27 ข้อ 77','84000.org (อ้างฉบับหลวง)',
 'ข้อ 77 บรรทัด 451–509',null,'HTML',null,array['th'],
 'https://84000.org/tipitaka//english/v.php?A=502&B=27&Z=509','unknown',
 'ไม่พบเงื่อนไขสิทธิ์ชัดเจน; ใช้ citation/link และขออนุญาตก่อนนำข้อความจำนวนมาก'),
('ich-nature-cosmos','ich-culture-3','a2','ฉบับเผยแพร่ กระทรวงวัฒนธรรม','กรมส่งเสริมวัฒนธรรม',
 'ICH category publication',null,'PDF',null,array['th'],
 'https://qrcode.culture.go.th/pdfbook/ich%20%283%29.pdf','unknown',
 'ใช้กำหนดกรอบคำว่า "มรดกภูมิปัญญา" ให้ถูกต้อง'),
('suriyayat-narai-evidence','vajirayana-suriyayat','a2','บทความประวัติศาสตร์','ห้องสมุดดิจิทัลวชิรญาณ',
 'บทความเอกสารไทยสมัยพระนารายณ์',null,'HTML',null,array['th'],
 'https://vajirayana.org/ปูมราชธรรม','unknown',null),

-- Contemporary — trend and benchmark only, never a core answer
('thairath-dream','thairath-dream','c','หมวดทำนายฝัน ไทยรัฐออนไลน์','ไทยรัฐออนไลน์',
 'หมวด Horoscope/Dream',null,'เว็บไซต์',null,array['th'],
 'https://www.thairath.co.th/horoscope/dream','all_rights_reserved',
 'เฝ้าดูแนวโน้มเท่านั้น ห้ามคัดลอกฐานข้อมูล'),
('myhora-platform','myhora','c','เว็บไซต์ MyHora','MyHora',
 'Dream and Thai Astrology sections',null,'เว็บไซต์',null,array['th'],
 'https://myhora.com/','all_rights_reserved',
 'benchmark เท่านั้น ห้าม scrape')

) as v(work_slug, citekey, tier, label_th, custodian_th, stable_identifier,
       year_published, physical_desc_th, script_th, languages, url,
       custodian_rights, rights_note_th)
join content.work w on w.slug = v.work_slug
on conflict (citekey) do update set
  label_th = excluded.label_th,
  custodian_rights = excluded.custodian_rights,
  rights_note_th = excluded.rights_note_th;

-- ---------------------------------------------------------------------------
-- Acquisition tracker (editorial schema — never exposed)
-- P0 = contact first. These are the twelve that unlock the launch corpus.
-- ---------------------------------------------------------------------------

insert into editorial.acquisition (edition_id, registry_ref, priority, stage, note_th)
select e.id, v.ref, v.priority, 'metadata', v.note
from (values
  ('nlt-3742','NIM-A1-011','P0','ขอสำเนาความละเอียดสูงและสิทธิ์ใช้ภาพ — เป็นฐานหลักของ Dream Library'),
  ('nlt-2202','NIM-A1-001','P0','ต้นฉบับจักรทีปนี ขอสิทธิ์ภาพและ OCR'),
  ('finearts-2508','NIM-A2-001','P0','ตรวจสถานะมาตรา 7 ก่อน — อาจไม่ต้องขออนุญาตเลย'),
  ('nlt-6238','NIM-A2-003','P0','ตรวจปีพิมพ์และผู้เรียบเรียงเพื่อสรุปสถานะลิขสิทธิ์'),
  ('nlt-1165','NIM-A1-005','P0','พรหมชาติฉบับมีภาพ ขอสิทธิ์ใช้ภาพประกอบ'),
  ('nlt-1177','NIM-A1-006','P0','พรหมชาติพระเคราะห์'),
  ('nlt-1388','NIM-A1-007','P0','พรหมชาติวันเดือนปี'),
  ('sac-300','NIM-A1-012','P0','ขอ commercial + derivative licence จาก ศมส. (CC BY-NC-ND ไม่พอ)'),
  ('sac-388','NIM-A1-013','P0','ขอ commercial licence และหาผู้เชี่ยวชาญอักษรธรรมล้านนา'),
  ('chula-2283555','NIM-B2-001','P0','ซื้อหนังสือ และหาปีถึงแก่กรรมของหลวงวิศาลดรุณกร'),
  ('orst-taksa-2552','NIM-B1-005','P0','ยืนยันสถานะมาตรา 7 สำหรับ glossary'),
  ('tipitaka-27-77','NIM-A2-006','P0','ตรวจสิทธิ์คำแปลไทยสมัยใหม่'),
  ('nlt-19345','NIM-A2-004','P1','ตรวจสถานะ PD — คุ้มค่าที่สุดถ้าปลดล็อกได้')
) as v(citekey, ref, priority, note)
join content.edition e on e.citekey = v.citekey
on conflict do nothing;
