-- ============================================================================
-- Structural seed: trust tiers, categories, traditions.
--
-- This is reference data the app cannot run without, and it carries no
-- intellectual property — it is the trust framework itself. Content (symbols,
-- interpretations) is NOT seeded here; it is authored in the database and
-- exported separately.
--
-- Idempotent: safe to re-run.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Trust tiers
--
-- These measure VERIFIABILITY OF PROVENANCE, not predictive accuracy. Nothing
-- in this system claims a forecast is correct — only that a belief is genuinely
-- attested somewhere checkable.
--
-- allowed_as_core encodes the editorial rule directly: C may never stand as a
-- core answer, D may never be republished as fact at all.
-- ---------------------------------------------------------------------------

insert into content.tier_definition
  (tier, title_th, description_th, sort, allowed_as_core, allowed_for_trend, citation_rule_th)
values
  ('a1', 'ต้นฉบับทางประวัติศาสตร์',
   'ต้นฉบับหรือหลักฐานชั้นต้นที่สถาบันเก็บรักษา และมีเลขทะเบียนอ้างอิงได้',
   1, true,  true,  'ชื่อเรื่อง + เลขทะเบียนต้นฉบับ + เลขหน้า/folio'),
  ('a2', 'ฉบับอ้างอิงทางการ',
   'ฉบับพิมพ์ทางการ ฉบับตรวจชำระ หรือข้อความสถาบันที่ระบุต้นทางชัดเจน',
   2, true,  true,  'ชื่อฉบับ + ปีพิมพ์ + เลขหน้า'),
  ('b1', 'งานวิเคราะห์ทางวิชาการ',
   'วิทยานิพนธ์หรือบทความวิจัยที่วิเคราะห์หลักฐานอย่างมีระเบียบวิธี',
   3, false, true,  'ผู้เขียน + ปี + เลขหน้า'),
  ('b2', 'ตำรามาตรฐานสมัยใหม่',
   'ตำรารวบรวมที่ระบุผู้เขียนและฉบับพิมพ์ชัดเจน',
   4, false, true,  'ผู้เขียน + ฉบับพิมพ์ + เลขหน้า'),
  ('c',  'การตีความร่วมสมัย',
   'สื่อหรือแพลตฟอร์มร่วมสมัยที่ระบุตัวตนผู้เผยแพร่',
   5, false, true,  'URL + วันที่บันทึกข้อมูล'),
  ('d',  'ยังไม่ยืนยันที่มา',
   'เนื้อหาที่ไม่ระบุแหล่ง ข่าวลือ หรือคำอ้างความแม่นยำ',
   6, false, false, 'เก็บ URL/ภาพหน้าจอไว้ภายในเท่านั้น ไม่เผยแพร่ซ้ำเป็นข้อเท็จจริง')
on conflict (tier) do update set
  title_th = excluded.title_th,
  description_th = excluded.description_th,
  sort = excluded.sort,
  allowed_as_core = excluded.allowed_as_core,
  allowed_for_trend = excluded.allowed_for_trend,
  citation_rule_th = excluded.citation_rule_th;

-- ---------------------------------------------------------------------------
-- Categories
--
-- ethics_note_th is surfaced in the UI, not merely recorded as policy. Several
-- of these domains carry real potential for harm — physiognomy invites
-- discrimination, ตำรายา content must never read as medical advice, and
-- ปลูกเรือน timing is not structural engineering guidance.
-- ---------------------------------------------------------------------------

insert into content.category (slug, name_th, domain_th, sort, ethics_note_th) values
  ('dream-symbols', 'สัญลักษณ์ในความฝัน', 'ความฝัน', 10,
   'เลขที่เชื่อมโยงกับสัญลักษณ์เป็นความเชื่อทางวัฒนธรรม ต้องแสดงเป็นตัวเลือก และไม่อ้างว่าเพิ่มโอกาสถูกรางวัล'),
  ('dream-buddhist', 'ความฝันในวรรณกรรมพุทธ', 'ความฝัน', 20,
   'อธิบายในฐานะวรรณกรรมและบริบททางประวัติศาสตร์ ห้ามสื่อว่าพุทธศาสนารับรองการเสี่ยงโชค'),
  ('astrology-natal', 'ผูกดวงตามตำรา', 'โหราศาสตร์', 30,
   'นำเสนอเชิงวัฒนธรรมและความบันเทิง ไม่ใช่คำแนะนำเรื่องการเงิน สุขภาพ หรือกฎหมาย'),
  ('astrology-taksa', 'ทักษาวันเกิด', 'โหราศาสตร์', 40,
   'หลีกเลี่ยงการตัดสินบุคคลแบบชี้ขาด โดยเฉพาะเรื่องกาลกิณี'),
  ('calendar-auspicious', 'ฤกษ์ตามต้นฉบับ', 'ปฏิทินและฤกษ์', 50,
   'เป็นความเชื่อดั้งเดิม ไม่ใช้แทนคำแนะนำทางกฎหมาย การแพทย์ หรือวิศวกรรม'),
  ('folk-brahmajati', 'พรหมชาติหลายฉบับ', 'ความเชื่อพื้นบ้าน', 60,
   'แสดงความต่างระหว่างฉบับ หลีกเลี่ยงการเหมารวมและการตัดสินความสัมพันธ์'),
  ('cultural-life', 'ความเชื่อในวิถีชีวิต', 'วิถีชีวิตและวัฒนธรรม', 70,
   'นำเสนอเป็นประวัติความเชื่อเท่านั้น ไม่ใช่คำแนะนำเชิงเทคนิคหรือการเกษตรสมัยใหม่'),
  ('omens-signs', 'ลางและอาการบอกเหตุ', 'ความเชื่อพื้นบ้าน', 80,
   'เช่น สัตว์ตก อาการกระเหม่น — เป็นความเชื่อ ไม่ใช่การวินิจฉัยทางการแพทย์'),
  ('contemporary-trends', 'กระแสร่วมสมัย', 'ร่วมสมัย', 90,
   'ความถี่ที่ถูกพูดถึงไม่เกี่ยวข้องกับผลการออกรางวัล ต้องระบุให้ชัด')
on conflict (slug) do update set
  name_th = excluded.name_th,
  domain_th = excluded.domain_th,
  sort = excluded.sort,
  ethics_note_th = excluded.ethics_note_th;

-- ---------------------------------------------------------------------------
-- Traditions (สำนัก / สายตำรา)
--
-- First-class so the product can show that editions disagree rather than
-- flattening them into a single answer. Per the research, presenting one
-- authoritative reading would misrepresent how these texts actually work.
-- ---------------------------------------------------------------------------

insert into content.tradition (slug, name_th, note_th) values
  ('brahmajati',   'พรหมชาติ',
   'สายตำราพยากรณ์พื้นบ้านที่มีหลายฉบับ เนื้อหาและคำทำนายต่างกันตามฉบับและท้องถิ่น'),
  ('chakkathipani','จักรทีปนี',
   'คัมภีร์โหราศาสตร์ว่าด้วยลัคนาและดาวในราศี'),
  ('taksa',        'ทักษา',
   'ระบบดาวแปดดวงตามวันเกิด: บริวาร อายุ เดช ศรี มูละ อุตสาหะ มนตรี กาลกิณี'),
  ('lanna',        'สายล้านนา',
   'ต้นฉบับอักษรธรรมล้านนา คำศัพท์และวิธีนับฤกษ์ต่างจากสายภาคกลาง'),
  ('folk-central', 'พื้นบ้านภาคกลาง',
   'ความเชื่อท้องถิ่นภาคกลางที่ปรากฏในสมุดไทย'),
  ('buddhist-canon','วรรณกรรมพุทธ',
   'ข้อความจากพระไตรปิฎกและอรรถกถา อ้างอิงในฐานะวรรณกรรม')
on conflict (slug) do update set
  name_th = excluded.name_th,
  note_th = excluded.note_th;
