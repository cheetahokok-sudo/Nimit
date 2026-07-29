-- ============================================================================
-- ปีนักษัตร v2 — เดือนเกิด subdivisions, and the reopening of A10
--
-- WHAT THE ROADMAP SAID WAS IMPOSSIBLE. A10 built ดวงของฉัน around เดือนเกิด,
-- could not fill it, and recorded the reason: 'ตำราที่อ่านตามวันเกิดไม่อ่าน
-- ตามเดือน'. taksa_v1 routed around it by reading วันเกิด instead, and the
-- lunar-month calculation in core/calendar has had no reader since — verified
-- against Eade and against announced religious dates, and used for nothing.
--
-- That was true of the ตำรา the project had. It is not true of this one. Every
-- ปีนักษัตร section here subdivides into four groups of three lunar months, and
-- each group gets its own sub-animal, its own sub-ธาตุ, and its own reading. The
-- animal is not decoration: ปีชวด born เดือน ๕–๗ is หนูท้องขาว of ธาตุน้ำทะเล
-- มหาสมุทร and the ตำรา promises สติปัญญามาก; born เดือน ๘–๑๐ it is a different
-- creature of ธาตุน้ำค้างกลางคืน and the ตำรา promises ความเดือดร้อนยุ่งยาก. Same
-- year, opposite verdicts, decided by the month.
--
-- ── HOW THESE ATTACH ───────────────────────────────────────────────────────
--
-- Not as new symbols. These are the twelve existing ZODIAC_* symbols read at
-- finer resolution, so each refinement is an interpretation on the SAME symbol
-- carrying applies_to_lunar_months (migration 20260729000200). One query on
-- ZODIAC_RAT returns the year reading plus at most one month refinement, and no
-- new lookup key is invented for the app to learn.
--
-- ── THE PARTITION INVARIANT ────────────────────────────────────────────────
--
-- For each year the four groups must cover all twelve เดือน exactly once — no
-- month unread, no month claimed twice. The book's groups are ๕-๖-๗, ๘-๙-๑๐,
-- ๑๑-๑๒-อ้าย, and ยี่-๓-๔, where อ้าย is เดือน ๑ and ยี่ is เดือน ๒, so they wrap
-- the year end. Asserted per year below, which is what catches a mis-read range:
-- transcribing '๑๑-๑๒-อ้าย' as '๑๑-๑๒-๑๓' or dropping อ้าย both break it, and
-- neither would be visible by eye in twenty rows of Thai numerals.
--
-- ── WHAT IS ILLEGIBLE, AND HOW IT IS HANDLED ───────────────────────────────
--
-- The scan loses several sub-animal names and several sub-ธาตุ qualifiers —
-- ปีฉลู loses three of four animal names, ปีเถาะ two. Where the name is lost the
-- reading still stands, because the VERDICT is legible even when its label is
-- not, and the body says so in plain words rather than inventing a creature.
-- A missing name is a gap; a guessed name is a fabrication with a citation
-- attached, which is worse than the gap by the whole width of this project.
-- ============================================================================

drop table if exists tmp_months;
create temporary table tmp_months (
  concept_key text, seq int, months smallint[], sub_animal text, sub_element text,
  body text, plain text
);

-- เดือน ๕-๖-๗ = {5,6,7} · ๘-๙-๑๐ = {8,9,10} · ๑๑-๑๒-อ้าย = {11,12,1} · ยี่-๓-๔ = {2,3,4}
insert into tmp_months values

-- ── ปีชวด · หน้า ๑๔–๑๕ ─────────────────────────────────────────────────────
('ZODIAC_RAT', 14, '{5,6,7}', 'หนูท้องขาว', 'ธาตุน้ำทะเลมหาสมุทร',
 'ตำราจัดผู้เกิดปีชวด เดือน ๕–๗ เป็นหนูท้องขาว ธาตุน้ำทะเลมหาสมุทร '
 'ว่ามักเป็นคนมีสติปัญญามากและใจบุญสุนทาน รับราชการจะมีเกียรติถึงขั้นมีอำนาจ '
 'มีข้าทาสบริวารมาก ทำไร่ทำสวนจะมีกำไรได้ทรัพย์มาก และถ้าบวชจะได้เป็นหัวหน้าคณะ',
 'ตำราว่าคนปีชวดที่เกิดเดือน ๕–๗ เป็นหนูท้องขาว ปัญญาดี ใจบุญ '
 'ทำราชการมีเกียรติ ทำไร่สวนได้กำไร'),
('ZODIAC_RAT', 14, '{8,9,10}', null, 'ธาตุน้ำค้างกลางคืน',
 'ตำราจัดผู้เกิดปีชวด เดือน ๘–๑๐ ไว้ในธาตุน้ำค้างกลางคืน '
 'ว่ามักได้รับความเดือดร้อนยุ่งยากใจ ถูกผู้อื่นเบียดเบียนกลั่นแกล้ง สิ่งที่ได้มาไม่ยั่งยืน '
 'รับราชการมักต้องออกจากหน้าที่การงาน ส่วนทำไร่ทำสวนจะมีอยู่มีกินพอประมาณ | '
 'ชื่อสัตว์ประจำกลุ่มเดือนนี้อ่านไม่ชัดในฉบับสแกน จึงยังไม่บันทึก',
 'ตำราว่าคนปีชวดที่เกิดเดือน ๘–๑๐ ธาตุน้ำค้างกลางคืน มักมีเรื่องยุ่งยากใจ '
 'งานราชการไม่ยั่งยืน แต่ทำไร่สวนพออยู่ได้'),
('ZODIAC_RAT', 14, '{11,12,1}', 'หนูผี', 'ธาตุน้ำในลำธาร',
 'ตำราจัดผู้เกิดปีชวด เดือน ๑๑–๑๒ และเดือนอ้าย เป็นหนูผี ธาตุน้ำในลำธาร '
 'ว่ามักลำบากและใจเบา รับราชการอาสาเจ้านายจะดี '
 'ถ้ารักการทำไร่ทำนาจะมีอยู่มีกินเสมอหน้าผู้อื่น',
 'ตำราว่าคนปีชวดที่เกิดเดือน ๑๑–๑๒ และเดือนอ้าย เป็นหนูผี ชีวิตลำบากอยู่บ้าง '
 'แต่ถ้าอาสางานเจ้านายหรือทำไร่นาจะพออยู่พอกิน'),
('ZODIAC_RAT', 14, '{2,3,4}', 'หนูตะเภา', 'ธาตุน้ำ',
 'ตำราจัดผู้เกิดปีชวด เดือนยี่ ๓ และ ๔ เป็นหนูตะเภา '
 'ว่ามักอยู่นิ่งไม่เป็น มีความขยันหมั่นเพียร มีความคิดแปลกใหม่ '
 'ทำกิจการค้าขายมีความก้าวหน้า มีเพื่อนมากและมีผู้อุปถัมภ์ '
 'ไปอยู่ต่างถิ่นก็มีอยู่มีกินไปกับหน้าที่การงาน | '
 'คำขยายธาตุประจำกลุ่มเดือนนี้อ่านไม่ชัด บันทึกไว้เพียงธาตุน้ำตามปีเกิด',
 'ตำราว่าคนปีชวดที่เกิดเดือนยี่ ๓ และ ๔ เป็นหนูตะเภา ขยัน คิดแปลกใหม่ '
 'ค้าขายก้าวหน้า เพื่อนมาก และไปอยู่ที่ไหนก็พออยู่ได้'),

-- ── ปีฉลู · หน้า ๒๒–๒๓ ─────────────────────────────────────────────────────
('ZODIAC_OX', 22, '{5,6,7}', null, 'ธาตุดิน',
 'ตำราจัดผู้เกิดปีฉลู เดือน ๕–๗ ว่าชอบใช้ชีวิตแบบอิสระ ใจร้อนและชอบต่อสู้ '
 'รับราชการจะได้มียศสูง จะมีข้าวของเงินทองมากและมีโอกาสร่ำรวย | '
 'ชื่อวัวประจำกลุ่มเดือนนี้และคำขยายธาตุอ่านไม่ชัดในฉบับสแกน',
 'ตำราว่าคนปีฉลูที่เกิดเดือน ๕–๗ รักอิสระ ใจร้อน ชอบต่อสู้ '
 'ทำราชการได้ยศสูงและมีโอกาสร่ำรวย'),
('ZODIAC_OX', 22, '{8,9,10}', 'วัวด่าง', 'ธาตุดินโคลนตม',
 'ตำราจัดผู้เกิดปีฉลู เดือน ๘–๑๐ เป็นวัวด่าง ธาตุดินโคลนตม '
 'ว่าเป็นคนอดทน ใจแข็ง ขยันหมั่นเพียร และทำงานได้ทุกอย่าง '
 'แต่ตำราว่าจะต้องลำบากอยู่ช่วงหนึ่ง (ช่วงที่ระบุอ่านไม่ชัด)',
 'ตำราว่าคนปีฉลูที่เกิดเดือน ๘–๑๐ เป็นวัวด่าง อดทน ใจแข็ง ขยัน ทำได้ทุกอย่าง '
 'แต่จะลำบากอยู่ช่วงหนึ่ง'),
('ZODIAC_OX', 22, '{11,12,1}', null, 'ธาตุดิน',
 'ตำราจัดผู้เกิดปีฉลู เดือน ๑๑–๑๒ และเดือนอ้าย ว่ามีปัญญาดี เป็นผู้ดี '
 'รับราชการจะได้เป็นใหญ่โต และทำกิจการค้าได้ | '
 'ชื่อวัวประจำกลุ่มเดือนนี้และคำขยายธาตุอ่านไม่ชัด',
 'ตำราว่าคนปีฉลูที่เกิดเดือน ๑๑–๑๒ และเดือนอ้าย ปัญญาดี เป็นผู้ดี '
 'ทำราชการได้เป็นใหญ่'),
('ZODIAC_OX', 22, '{2,3,4}', null, 'ธาตุดิน',
 'ตำราจัดผู้เกิดปีฉลู เดือนยี่ ๓ และ ๔ ว่าเป็นคนใจบุญ มีผู้อุปถัมภ์ '
 'จะได้เป็นใหญ่และร่ำรวย คิดการสิ่งใดไม่ขัดสน ชีวิตจะมีความสุขสบาย | '
 'ชื่อวัวประจำกลุ่มเดือนนี้และคำขยายธาตุอ่านไม่ชัด',
 'ตำราว่าคนปีฉลูที่เกิดเดือนยี่ ๓ และ ๔ ใจบุญ มีผู้อุปถัมภ์ '
 'ได้เป็นใหญ่ และชีวิตสุขสบาย'),

-- ── ปีขาล · หน้า ๓๐–๓๑ ─────────────────────────────────────────────────────
('ZODIAC_TIGER', 30, '{5,6,7}', 'เสือดาว', 'ธาตุไม้กองเพลิง',
 'ตำราจัดผู้เกิดปีขาล เดือน ๕–๗ เป็นเสือดาว ธาตุไม้กองเพลิง '
 'ว่ารักชื่อเสียงเกียรติยศมากกว่าเงินทอง รับราชการจะได้เป็นใหญ่และมีอายุยืนยาว '
 'ถ้าคิดทำการค้าขายจะเจริญก้าวหน้าและมีบริวารมาก',
 'ตำราว่าคนปีขาลที่เกิดเดือน ๕–๗ เป็นเสือดาว รักเกียรติมากกว่าเงิน '
 'ทำราชการได้เป็นใหญ่ อายุยืน และค้าขายเจริญ'),
('ZODIAC_TIGER', 30, '{8,9,10}', 'เสือเหลือง', 'ธาตุไม้แห้งมักหัก',
 'ตำราจัดผู้เกิดปีขาล เดือน ๘–๑๐ เป็นเสือเหลือง ธาตุไม้แห้งมักหัก '
 'ว่าเป็นคนเจ้าสำราญ ชอบสนุกและมีเพื่อนฝูงมาก ไปทางใดก็ไม่อดอยาก '
 'ไม่ชอบรับราชการแต่ชอบค้าขายเป็นของตนเอง และจะได้ผู้ใหญ่สนับสนุน',
 'ตำราว่าคนปีขาลที่เกิดเดือน ๘–๑๐ เป็นเสือเหลือง เจ้าสำราญ เพื่อนมาก '
 'ชอบค้าขายของตัวเองมากกว่ารับราชการ'),
('ZODIAC_TIGER', 30, '{11,12,1}', 'เสือปลา', 'ธาตุไม้พื้นที่แฉะ',
 'ตำราจัดผู้เกิดปีขาล เดือน ๑๑–๑๒ และเดือนอ้าย เป็นเสือปลา ธาตุไม้พื้นที่แฉะ '
 'ว่ารับราชการจะมีอำนาจมาก และจะมีคนภายนอกคอยอุปถัมภ์จนเป็นเศรษฐี',
 'ตำราว่าคนปีขาลที่เกิดเดือน ๑๑–๑๒ และเดือนอ้าย เป็นเสือปลา '
 'ทำราชการมีอำนาจ และมีคนช่วยจนร่ำรวย'),
('ZODIAC_TIGER', 30, '{2,3,4}', 'เสือโคร่ง', 'ธาตุไม้เนื้อแข็ง',
 'ตำราจัดผู้เกิดปีขาล เดือนยี่ ๓ และ ๔ เป็นเสือโคร่ง ธาตุไม้เนื้อแข็ง '
 'ว่าชอบอาสาเจ้านาย มีตระกูลดี รับราชการก้าวหน้าและเป็นผู้มีอำนาจ '
 'ถ้าทำบุญกุศลจะเป็นประโยชน์ต่อสังคมและเป็นที่รักใคร่ของคนทั่วไป',
 'ตำราว่าคนปีขาลที่เกิดเดือนยี่ ๓ และ ๔ เป็นเสือโคร่ง ชอบอาสาเจ้านาย '
 'ราชการก้าวหน้า มีอำนาจ และเป็นที่รักของคนทั่วไป'),

-- ── ปีเถาะ · หน้า ๓๘–๓๙ ────────────────────────────────────────────────────
('ZODIAC_RABBIT', 38, '{5,6,7}', null, 'ธาตุไม้',
 'ตำราจัดผู้เกิดปีเถาะ เดือน ๕–๗ ว่าเป็นคนมีบุญวาสนา แม้จะถูกหลอกลวงได้ง่าย '
 'รับราชการจะได้เป็นขุนนางที่ปกครองดี หรือเป็นอาจารย์ผู้ให้คำปรึกษา '
 'ถ้าค้าขายจะร่ำรวย และเป็นที่รักของผู้ใหญ่ | '
 'ชื่อกระต่ายประจำกลุ่มเดือนนี้และคำขยายธาตุอ่านไม่ชัด',
 'ตำราว่าคนปีเถาะที่เกิดเดือน ๕–๗ มีบุญวาสนา แม้จะถูกหลอกง่าย '
 'ทำราชการหรือเป็นครูอาจารย์ได้ดี ค้าขายร่ำรวย'),
('ZODIAC_RABBIT', 38, '{8,9,10}', null, 'ธาตุไม้',
 'ตำราจัดผู้เกิดปีเถาะ เดือน ๘–๑๐ ว่ารับราชการจะได้เลื่อนตำแหน่งอย่างรวดเร็ว '
 'มีชื่อเสียงและมีชั้นยศดี ส่วนทรัพย์สินมีพอประมาณ | '
 'ชื่อกระต่ายประจำกลุ่มเดือนนี้และคำขยายธาตุอ่านไม่ชัด',
 'ตำราว่าคนปีเถาะที่เกิดเดือน ๘–๑๐ ทำราชการเลื่อนตำแหน่งเร็ว มีชื่อเสียง '
 'ทรัพย์สินพอประมาณ'),
('ZODIAC_RABBIT', 38, '{11,12,1}', 'กระต่ายป่วยไข้', 'ธาตุไม้อับแสง',
 'ตำราจัดผู้เกิดปีเถาะ เดือน ๑๑–๑๒ และเดือนอ้าย เป็นกระต่ายป่วยไข้ ธาตุไม้อับแสง '
 'ว่ามักยากจนและเจ็บป่วยง่าย แต่เมื่อบวชแล้วกลับดีมีชื่อเสียง เป็นที่นับถือ '
 'รับราชการเหมาะแก่การอาสาเจ้านาย หรือค้าขายพอมีพอกินไม่เหลือเก็บ',
 'ตำราว่าคนปีเถาะที่เกิดเดือน ๑๑–๑๒ และเดือนอ้าย เป็นกระต่ายป่วยไข้ '
 'ชีวิตช่วงต้นลำบากและป่วยง่าย แต่ถ้าบวชจะได้ดีมีคนนับถือ'),
('ZODIAC_RABBIT', 38, '{2,3,4}', 'กระต่ายในดวงจันทร์', 'ธาตุไม้ชอบแสง',
 'ตำราจัดผู้เกิดปีเถาะ เดือนยี่ ๓ และ ๔ เป็นกระต่ายในดวงจันทร์ ธาตุไม้ชอบแสง '
 'ว่าจะมีความสุข ได้เป็นใหญ่ มีชื่อเสียงและมีชั้นยศดี มีอำนาจ '
 'เป็นที่รักของคนทั่วไป และมีทรัพย์สินเงินทองมาก',
 'ตำราว่าคนปีเถาะที่เกิดเดือนยี่ ๓ และ ๔ เป็นกระต่ายในดวงจันทร์ '
 'มีความสุข ได้เป็นใหญ่ มีชื่อเสียง และเป็นที่รักของคนทั่วไป'),

-- ── ปีมะโรง · หน้า ๔๖–๔๗ ───────────────────────────────────────────────────
('ZODIAC_DRAGON', 46, '{5,6,7}', 'งูนาคราชเป็นพระยางู', 'ธาตุทอง',
 'ตำราจัดผู้เกิดปีมะโรง เดือน ๕–๗ เป็นงูนาคราชผู้เป็นพระยางู '
 'ว่าจะมีบริวาร รับราชการจะได้เป็นใหญ่มีอำนาจวาสนา '
 'ไม่ประสบความลำบากใจ พูดจาดี และการค้าจะร่ำรวยมาก | '
 'คำขยายธาตุประจำกลุ่มเดือนนี้อ่านไม่ชัด',
 'ตำราว่าคนปีมะโรงที่เกิดเดือน ๕–๗ เป็นพระยางู มีบริวาร '
 'ทำราชการได้เป็นใหญ่ และค้าขายร่ำรวย'),
('ZODIAC_DRAGON', 46, '{8,9,10}', 'พระยางูเหลือง', 'ธาตุทองบริสุทธิ์',
 'ตำราจัดผู้เกิดปีมะโรง เดือน ๘–๑๐ เป็นพระยางูเหลือง ธาตุทองบริสุทธิ์ '
 'ว่ารับราชการจะเจริญด้วยยศและตำแหน่งที่ดี มีผู้อุปถัมภ์ '
 'และเกิดเรื่องใดขึ้นก็มักมีคนช่วยเหลือเสมอ',
 'ตำราว่าคนปีมะโรงที่เกิดเดือน ๘–๑๐ เป็นพระยางูเหลือง '
 'ราชการเจริญด้วยยศตำแหน่ง และมีคนช่วยเหลือเสมอ'),
('ZODIAC_DRAGON', 46, '{11,12,1}', 'พระยางูเผือกมีพิษมาก', 'ธาตุทอง',
 'ตำราจัดผู้เกิดปีมะโรง เดือน ๑๑–๑๒ และเดือนอ้าย เป็นพระยางูเผือกที่มีพิษมาก '
 'ว่าจะมีชื่อเสียงขึ้นมาได้เพราะคำพูดของตน มีอำนาจ และจะได้ลาภจากญาติ | '
 'คำขยายธาตุและข้อความบางช่วงอ่านไม่ชัด',
 'ตำราว่าคนปีมะโรงที่เกิดเดือน ๑๑–๑๒ และเดือนอ้าย เป็นพระยางูเผือก '
 'มีชื่อเสียงเพราะคำพูด มีอำนาจ และได้ลาภจากญาติ'),
('ZODIAC_DRAGON', 46, '{2,3,4}', 'พระยางูดำไม่มีพิษ', 'ธาตุทองบริสุทธิ์',
 'ตำราจัดผู้เกิดปีมะโรง เดือนยี่ ๓ และ ๔ เป็นพระยางูดำที่ไม่มีพิษ ธาตุทองบริสุทธิ์ '
 'ว่าเป็นผู้ที่ต้องรับผิดชอบต่อผู้อื่น จะมีทรัพย์สินพอประมาณ '
 'ค้าขายมีกำไรพอเลี้ยงตัว เป็นที่รักของผู้คน แต่ตำราเตือนว่าอาจถูกหักหลัง',
 'ตำราว่าคนปีมะโรงที่เกิดเดือนยี่ ๓ และ ๔ เป็นพระยางูดำไม่มีพิษ '
 'ต้องรับผิดชอบผู้อื่น มีพอกินพอใช้ เป็นที่รัก แต่ให้ระวังการถูกหักหลัง');

-- ---------------------------------------------------------------------------
-- The partition invariant, checked before anything is written.
-- ---------------------------------------------------------------------------
do $$
declare n int; detail text;
begin
  select count(*) into n from tmp_months;
  if n <> 20 then raise exception 'zodiac v2: expected 20 month-group readings, got %', n; end if;

  -- Four groups per year.
  select string_agg(concept_key || '=' || c, ', ' order by concept_key) into detail
    from (select concept_key, count(*) c from tmp_months group by 1) d where c <> 4;
  if detail is not null then
    raise exception 'zodiac v2: each year needs exactly 4 month groups — got %', detail;
  end if;

  -- Every เดือน ๑–๑๒ claimed exactly once per year. Catches a dropped อ้าย or
  -- an off-by-one range, neither of which is visible by eye in Thai numerals.
  select string_agg(concept_key || ' เดือน ' || m || '×' || c, ', ') into detail
    from (select concept_key, m, count(*) c
            from tmp_months, unnest(months) as m group by 1, 2) d
   where c <> 1;
  if detail is not null then
    raise exception 'zodiac v2: months must partition the year exactly once each — %', detail;
  end if;

  select string_agg(concept_key || '=' || c, ', ' order by concept_key) into detail
    from (select concept_key, count(*) c from (
            select distinct concept_key, m from tmp_months, unnest(months) as m) u
          group by 1) d where c <> 12;
  if detail is not null then
    raise exception 'zodiac v2: each year must cover all 12 เดือน — got %', detail;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Passages — the เดือนเกิด spread for each year, two printed pages apiece.
-- ---------------------------------------------------------------------------
insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, v.locator, v.seq, null,
  'หมวดแบ่งผู้เกิดในปีนี้ตามเดือนเกิดออกเป็นสี่กลุ่ม กลุ่มละสามเดือน '
  'แต่ละกลุ่มมีสัตว์ประจำกลุ่มและธาตุย่อยของตนเอง พร้อมคำทำนายแยกกัน',
  'เจ้าของโครงการ อ่านจากฉบับสแกน',
  'ถอดครั้งแรกจากฉบับสแกน ยังไม่ได้ทานซ้ำ | ' || v.note,
  'draft'
from content.edition e
cross join (values
  ('หน้า ๑๔–๑๕ ปีชวดแบ่งตามเดือนเกิด', 14,
   'ชื่อสัตว์ประจำกลุ่มเดือน ๘–๑๐ และคำขยายธาตุของกลุ่มเดือนยี่–๔ อ่านไม่ชัด'),
  ('หน้า ๒๒–๒๓ ปีฉลูแบ่งตามเดือนเกิด', 22,
   'ชื่อวัวประจำกลุ่มอ่านไม่ชัดสามในสี่กลุ่ม และคำขยายธาตุอ่านไม่ชัดเกือบทั้งหมด'),
  ('หน้า ๓๐–๓๑ ปีขาลแบ่งตามเดือนเกิด', 30,
   'อ่านได้ครบทั้งสี่กลุ่ม ทั้งชื่อเสือและธาตุย่อย'),
  ('หน้า ๓๘–๓๙ ปีเถาะแบ่งตามเดือนเกิด', 38,
   'ชื่อกระต่ายประจำกลุ่มเดือน ๕–๗ และ ๘–๑๐ อ่านไม่ชัด'),
  ('หน้า ๔๖–๔๗ ปีมะโรงแบ่งตามเดือนเกิด', 46,
   'คำขยายธาตุของกลุ่มเดือน ๕–๗ และ ๑๑–อ้าย อ่านไม่ชัด')
) as v(locator, seq, note)
where e.citekey = 'phrommachat-owned'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- The twenty refinements.
-- ---------------------------------------------------------------------------
with tr as (select id from content.tradition where slug = 'brahmajati')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, applies_to_lunar_months, corroborating_edition_ids, status)
select s.id, p.id, tr.id, m.body, m.plain, 'historical_belief',
  'เป็นความเชื่อตามตำราพรหมชาติ ไม่ใช่ข้อเท็จจริงทางวิทยาศาสตร์ '
  'ไม่ใช่คำรับรองอนาคต และไม่ใช่การประเมินนิสัยของบุคคลใด | '
  'เป็นคำทำนายย่อยตามเดือนเกิดทางจันทรคติ ใช้ประกอบกับคำทำนายประจำปีเกิด | '
  'อ่านจากฉบับรวมเล่มที่มีคำอธิบายของผู้เรียบเรียงปนอยู่ '
  'รอสอบทานกับพรหมชาติฉบับอื่นก่อนเผยแพร่',
  m.months, '{}', 'draft'
from tmp_months m
join content.symbol s on s.concept_key = m.concept_key
join content.passage p on p.sequence = m.seq
join content.edition e on e.id = p.edition_id and e.citekey = 'phrommachat-owned'
cross join tr
where not exists (
  select 1 from content.interpretation i
   where i.symbol_id = s.id and i.passage_id = p.id
     and i.applies_to_lunar_months = m.months);

-- ---------------------------------------------------------------------------
-- Assert the intent.
-- ---------------------------------------------------------------------------
do $$
declare got int; detail text;
begin
  select count(*) into got from content.passage p
    join content.edition e on e.id = p.edition_id
   where e.citekey = 'phrommachat-owned' and p.sequence in (14,22,30,38,46);
  if got <> 5 then
    raise exception 'zodiac v2: expected 5 เดือนเกิด passages, found % '
      '(is zodiac_v1_phrommachat_owned.sql applied?)', got;
  end if;

  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.concept_key like 'ZODIAC_%'
     and coalesce(array_length(i.applies_to_lunar_months, 1), 0) > 0;
  if got <> 20 then
    raise exception 'zodiac v2: expected 20 month-scoped readings, found %', got;
  end if;

  -- The partition again, this time as it actually landed in the database. The
  -- payload check above proves the literal; this proves the insert.
  select string_agg(concept_key || '=' || c, ', ' order by concept_key) into detail
    from (select s.concept_key, count(*) c
            from content.interpretation i
            join content.symbol s on s.id = i.symbol_id,
                 unnest(i.applies_to_lunar_months) as m
           where s.concept_key like 'ZODIAC_%' group by 1) d
   where c <> 12;
  if detail is not null then
    raise exception 'zodiac v2: stored month coverage is not 12 per year — %', detail;
  end if;

  -- Every year reading must still be unscoped, or a reader born in the wrong
  -- month loses the general reading as well as the refinement.
  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
    join content.passage p on p.id = i.passage_id
   where s.concept_key like 'ZODIAC_%' and p.sequence in (12,20,28,36,44)
     and coalesce(array_length(i.applies_to_lunar_months, 1), 0) > 0;
  if got > 0 then
    raise exception 'zodiac v2: % year reading(s) became month-scoped', got;
  end if;

  select count(*) into got from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.concept_key like 'ZODIAC_%' and i.status <> 'draft';
  if got > 0 then
    raise exception 'zodiac v2: % reading(s) left draft state', got;
  end if;
end $$;

do $$
declare bad int;
begin
  select coalesce(sum(violations), 0) into bad from ops.assert_rights_invariants();
  if bad > 0 then raise exception 'aborted: % rights invariant(s)', bad; end if;
end $$;

drop table if exists tmp_months;

select s.name_th,
       count(*) filter (where coalesce(array_length(i.applies_to_lunar_months,1),0) = 0) as year_reading,
       count(*) filter (where coalesce(array_length(i.applies_to_lunar_months,1),0) > 0) as month_groups,
       sum(coalesce(array_length(i.applies_to_lunar_months,1),0)) as months_covered
from content.symbol s
join content.interpretation i on i.symbol_id = s.id
where s.concept_key like 'ZODIAC_%'
group by s.name_th, s.slug
order by s.slug;
