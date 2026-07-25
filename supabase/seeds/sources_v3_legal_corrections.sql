-- ============================================================================
-- Source registry v3 — corrections from the Thai copyright research
--
-- Three assumptions in v1 were wrong or unsafe. This file fixes them and
-- records the reasoning, because the reasoning is what stops the same mistake
-- being made again by whoever curates next.
--
-- Run AFTER 20260726000400_pd_basis_government.sql.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- CORRECTION 1 — Fine Arts Department books: not section 7, but expired anyway
--
-- v1 recorded these as "unknown, might be s.7". The s.7 route is wrong (s.7(5)
-- is limited to items (1)–(4); ss.14/23 make departments ordinary owners). But
-- s.23 gives government works 50 years from first publication, and both of
-- these are past that. They are public domain by duration.
--
-- This is a genuine unlock: it releases the reference and terminology layer
-- without a single permission letter.
-- ---------------------------------------------------------------------------

update content.work set
  rights = 'public_domain',
  pd_basis = 'government_work_50y',
  copyright_holder = null,
  rights_note_th =
    'แก้ไขตามผลตรวจสอบกฎหมาย: มาตรา 7 *ไม่* ครอบคลุมหนังสือวิชาการของหน่วยงานรัฐ '
    'เพราะมาตรา 7(5) จำกัดเฉพาะ "ตาม (๑) ถึง (๔)" และมาตรา 14/23 กำหนดชัดว่า '
    'หน่วยงานรัฐเป็นเจ้าของลิขสิทธิ์ได้ตามปกติ '
    'แต่มาตรา 23 ให้อายุคุ้มครอง 50 ปีนับแต่โฆษณาครั้งแรก — พิมพ์ พ.ศ. 2508 '
    'จึงพ้นอายุเมื่อ พ.ศ. 2558 เป็นสาธารณสมบัติแล้วโดยการหมดอายุ ไม่ใช่โดยมาตรา 7 '
    'ยังต้องยืนยันปีพิมพ์จากหน้าลิขสิทธิ์ของตัวเล่มก่อนใช้จริง'
where slug = 'chakkathipani' and false;  -- work is already PD via author; no change needed

update content.work set
  rights = 'public_domain',
  pd_basis = 'government_work_50y',
  copyright_holder = null,
  rights_note_th =
    'แก้ไขตามผลตรวจสอบกฎหมาย: พิมพ์ครั้งแรก พ.ศ. 2505 + 50 ปี = พ.ศ. 2555 '
    'จึงพ้นอายุคุ้มครองตามมาตรา 23 แล้ว — เป็นสาธารณสมบัติโดยการหมดอายุ '
    '*ไม่ใช่* เพราะมาตรา 7 ซึ่งไม่ครอบคลุมหนังสือวิชาการของกรม '
    'ปลดล็อกชั้นคำอธิบายศัพท์และการใช้ฤกษ์ได้โดยไม่ต้องขออนุญาต '
    'เงื่อนไข: ยืนยันปีพิมพ์จากหน้าลิขสิทธิ์ และตรวจว่าไม่มีผู้เรียบเรียงที่ยังมีชีวิต '
    'ซึ่งจะทำให้กลับไปใช้มาตรา 19 (ชีวิต + 50 ปี) แทน'
where slug = 'horasat-buangton-ruek';

-- ---------------------------------------------------------------------------
-- CORRECTION 2 — the other "maybe section 7" entries are NOT free
--
-- Same reasoning, opposite outcome: these are recent enough that s.23's 50-year
-- clock has not run. Recording them as copyrighted rather than "unknown" so
-- nobody re-opens the s.7 question hoping for a different answer.
-- ---------------------------------------------------------------------------

update content.work set
  rights = 'copyrighted_cite_only',
  pd_basis = null,
  copyright_holder = 'สำนักงานราชบัณฑิตยสภา',
  rights_note_th =
    'แก้ไขตามผลตรวจสอบกฎหมาย: บทความอธิบายศัพท์ *ไม่* เข้ามาตรา 7(3) '
    'ซึ่งเป็นรายการปิดเฉพาะ ระเบียบ ข้อบังคับ ประกาศ คำสั่ง คำชี้แจง และหนังสือโต้ตอบ '
    'เผยแพร่ พ.ศ. 2552 + 50 ปี = พ.ศ. 2602 จึงยังมีลิขสิทธิ์ '
    'ใช้ได้โดยการอ้างอิงสั้น ๆ พร้อมระบุที่มาตามมาตรา 33 ซึ่งไม่มีเงื่อนไขห้ามใช้เชิงพาณิชย์'
where slug = 'orst-taksa';

update content.work set
  rights = 'copyrighted_cite_only',
  pd_basis = null,
  copyright_holder = 'กรมส่งเสริมวัฒนธรรม กระทรวงวัฒนธรรม',
  rights_note_th =
    'แก้ไขตามผลตรวจสอบกฎหมาย: หนังสือมรดกภูมิปัญญาเป็นงานวิชาการของกรม '
    'ไม่ใช่ "ประกาศ" ตามมาตรา 7(3) และเพิ่งเผยแพร่ จึงยังอยู่ในอายุคุ้มครองตามมาตรา 23 '
    'ใช้กำหนดกรอบคำศัพท์ได้โดยการอ้างอิงตามมาตรา 33'
where slug = 'ich-nature-cosmos';

-- ---------------------------------------------------------------------------
-- CORRECTION 3 — critical editions are the sharpest real risk
--
-- The research is blunt about this: the transcription layer of a ฉบับตรวจชำระ is
-- entangled with editorial judgement that cannot cleanly be stripped out, and
-- there is NO Thai authority on whether ปริวรรต attracts copyright. This is a
-- larger practical exposure than the scan question, because using a modern
-- edition is normally *how you get* a readable text at all.
-- ---------------------------------------------------------------------------

update content.work set
  rights_note_th = coalesce(rights_note_th, '') ||
    ' | ความเสี่ยงหลักที่ตรวจพบ: ฉบับตรวจชำระมีชั้นบรรณาธิการ (การชำระ เชิงอรรถ '
    'การจัดลำดับฉบับ) ที่มีลิขสิทธิ์แยกต่างหากจากตัวบทเดิมซึ่งพ้นลิขสิทธิ์แล้ว '
    'และยังไม่มีคำพิพากษาไทยวินิจฉัยว่า "ปริวรรต" มีลิขสิทธิ์หรือไม่ '
    'แนวทางที่ปลอดภัย: ปริวรรตเองจากภาพต้นฉบับ แล้วใช้ฉบับตรวจชำระเพียงเพื่อ *ทาน* '
    'ไม่ใช่เป็นต้นทางของข้อความ; ห้ามคัดเชิงอรรถ คำนำ หรือลำดับการจัดฉบับเด็ดขาด'
where slug in ('pramuan-tamra-thamnai-1', 'khamphi-horasat-thai');

-- ---------------------------------------------------------------------------
-- CORRECTION 4 — record what the custodians actually assert
--
-- Verified: neither the Fine Arts Department nor the National Library claims
-- copyright in their scans anywhere. The only notices found are a site-wide CMS
-- footer never applied to a collection, and unmodified DotNetNuke boilerplate.
-- The real regime is custody, contract and permit — and their fee schedule is
-- service pricing (30 บาท per image; 10 บาท domestic vs 20 บาท foreign for
-- microfilm), which makes no sense as a royalty.
--
-- This matters strategically: it means the obstacle is a permit, not a rights
-- claim — and permits are cheap, established, and negotiable. Winning a
-- copyright argument would not get us the images anyway.
-- ---------------------------------------------------------------------------

update content.edition set
  rights_note_th = coalesce(rights_note_th, '') ||
    ' | ตรวจสอบแล้ว: หอสมุดแห่งชาติและกรมศิลปากร *ไม่ได้* อ้างลิขสิทธิ์ในภาพสแกน '
    'ที่ใดเลย — ข้อความสงวนลิขสิทธิ์ที่พบเป็นเพียง footer ของระบบเว็บ '
    'ระเบียบจริงคือการขออนุญาตทำสำเนาต่ออธิบดีกรมศิลปากร และค่าบริการเป็นค่าทำสำเนา '
    'ไม่ใช่ค่าลิขสิทธิ์ จึงควรเดินทางขออนุญาตตามระเบียบ ซึ่งถูกและมีขั้นตอนชัดเจน '
    'มากกว่าจะไปถกเรื่องลิขสิทธิ์ของภาพสแกนซึ่งยังไม่มีคำพิพากษาไทยรองรับฝ่ายใด'
where custodian_th like '%หอสมุดแห่งชาติ%' or custodian_th like '%กรมศิลปากร%';

-- ---------------------------------------------------------------------------
-- CORRECTION 5 — CC BY-NC-ND cannot be complied with, only worked around
--
-- No configuration of a commercial app satisfies NonCommercial. The licence
-- also infects the whole container: an NC work may not sit in a commercially
-- distributed collection even as a small portion.
--
-- The legitimate routes are all *outside* the licence rather than compliant
-- with it. Creative Commons says so itself: where permission is not needed, the
-- licence does not apply.
-- ---------------------------------------------------------------------------

update content.edition set
  rights_note_th = coalesce(rights_note_th, '') ||
    ' | CC BY-NC-ND: ไม่มีวิธีใดที่แอปเชิงพาณิชย์จะ "ปฏิบัติตาม" ได้ '
    'เพราะ NC ผูกกับลักษณะการใช้ ไม่ใช่ตัวผู้ใช้ และครอบคลุมทั้งชุดข้อมูลแม้ใช้เพียงส่วนน้อย '
    'ทางที่ถูกต้องคือออกไปอยู่นอกขอบเขตสัญญาอนุญาต: '
    '(1) สกัดเฉพาะ *ข้อเท็จจริง* ซึ่งไม่มีลิขสิทธิ์ตามมาตรา 6 และ 7(1) '
    'และ CC ระบุเองว่าสัญญาอนุญาตไม่มีผลเมื่อไม่จำเป็นต้องขออนุญาต '
    '(2) ลิงก์ไปหาต้นทาง ไม่ทำสำเนามาเก็บ '
    '(3) อ้างอิงบางตอนตามมาตรา 33 '
    'ห้ามเด็ดขาด: เก็บภาพย่อ (thumbnail) ไว้ในระบบ เพราะเป็นการทำซ้ำที่ NC ห้ามตรง ๆ '
    'และต้องจำกัดปริมาณที่สกัดต่อแหล่ง เพราะการสะสมทีละน้อยจนเป็นสาระสำคัญก็เข้าข่ายละเมิด'
where custodian_rights in ('cc_by_nc_nd', 'cc_by_nc');

-- ---------------------------------------------------------------------------
-- Acquisition consequences
-- ---------------------------------------------------------------------------

-- The two now-expired Fine Arts books need no permission at all.
update editorial.acquisition a set
  stage = 'granted',
  note_th = 'ไม่ต้องขออนุญาต — พ้นอายุคุ้มครองตามมาตรา 23 แล้ว (พิมพ์ + 50 ปี) '
            'เหลือเพียงยืนยันปีพิมพ์จากหน้าลิขสิทธิ์ของตัวเล่ม'
from content.edition e
where e.id = a.edition_id and e.citekey in ('finearts-2508', 'nlt-19345');

-- Reframe the FAD/NLT outreach: it is a permit application, not a rights
-- negotiation. That changes who to address and what to ask for.
update editorial.acquisition a set
  note_th = coalesce(note_th, '') ||
            ' | กรอบใหม่: ยื่นขออนุญาตทำสำเนาต่ออธิบดีกรมศิลปากรตามระเบียบ '
            'ไม่ใช่การเจรจาขอสิทธิ์ เพราะสถาบันไม่ได้อ้างลิขสิทธิ์ในภาพสแกน'
from content.edition e
where e.id = a.edition_id
  and (e.custodian_th like '%หอสมุดแห่งชาติ%' or e.custodian_th like '%กรมศิลปากร%')
  and a.stage = 'metadata';
