-- ============================================================================
-- Source registry v5 — research findings on หลวงวิศาลดรุณกร (อั้น สาริกบุตร)
--
-- Finding (26 ก.ค. 2569): The People magazine's biography of เทพย์ สาริกบุตร
-- states his uncle's dates in passing: "หลวงวิศาลดรุณกร (อั้น สาริกบุตร
-- พ.ศ. 2427-93)" — i.e. died พ.ศ. 2493 (1950). If correct, life+50 expired at
-- the end of พ.ศ. 2543 and the compilation has been PUBLIC DOMAIN in Thailand
-- since 2544 — which would unlock the full Thai Wikisource transcription of
-- คัมภีร์โหราศาสตร์ไทยมาตรฐานฉบับสมบูรณ์ (ฤกษ์, นวางศ์, ตำนานดาวฤกษ์ ๒๗,
-- นพเคราะห์, สุริยยาตร์) for commercial use.
--
-- WHY THE FLAG STAYS 'unknown' ANYWAY: the date rests on ONE secondary source.
-- Corroborating circumstances are consistent (teaching career ends 2477, last
-- dated work 26 ก.ค. 2488, works reprinted as memorial classics in others'
-- cremation volumes by 2504, Wikisource itself says "ไม่ทราบปีเกิดปีตาย") and
-- nothing contradicts it — but our own rights policy says a status changes on
-- evidence that would survive scrutiny, and "a parenthetical in one magazine"
-- is not yet that. The row records the full evidence chain so the flip is a
-- one-line change the day primary confirmation lands.
--
-- Primary confirmation routes (human required — the Gazette site blocks
-- automation): search ratchakitcha.soc.go.th for "วิศาลดรุณกร" around
-- พ.ศ. 2493 (decoration-return/funeral entries), or the publisher's foreword
-- of the พ.ศ. 2540 reprint, or a National Library cremation-volume search.
--
-- Separate layer once PD is confirmed: the Wikisource TRANSCRIPTION carries
-- CC BY-SA on the transcription itself — share-alike attaches to reused text.
-- ============================================================================

update content.work set
  rights_note_th =
    'หลักฐานปีถึงแก่กรรม (ตรวจ 26 ก.ค. 2569): The People ระบุ "หลวงวิศาลดรุณกร '
    '(อั้น สาริกบุตร พ.ศ. 2427-93)" = ถึงแก่กรรม พ.ศ. 2493 → ลิขสิทธิ์หมดอายุ '
    'สิ้นปี พ.ศ. 2543 หากถูกต้อง | หลักฐานแวดล้อมสอดคล้อง: เป็นครูสวนกุหลาบถึง '
    'พ.ศ. 2477, งานลงวันที่ล่าสุด 26 ก.ค. 2488 (คำนำคัมภีร์สารัมภ์), ผลงานถูกพิมพ์ '
    'ในหนังสืออนุสรณ์งานศพของผู้อื่นตั้งแต่ พ.ศ. 2504 อย่างงานของผู้ล่วงลับ | '
    'คงสถานะ unknown เพราะยังอิงแหล่งรองแหล่งเดียว — ต้องยืนยันจากแหล่งปฐมภูมิ: '
    'ค้นราชกิจจานุเบกษา "วิศาลดรุณกร" ราว พ.ศ. 2493 (เว็บบล็อกบอทต้องค้นด้วยมือ) '
    'หรือคำนำฉบับพิมพ์ พ.ศ. 2540 หรือหนังสืออนุสรณ์งานศพของท่านเองในหอสมุดแห่งชาติ | '
    'เมื่อยืนยันแล้ว: งานต้นฉบับเป็น PD แต่ฉบับถอดความวิกิซอร์ซมี CC BY-SA '
    'ติดชั้นการถอดความ (ภาระ share-alike) และฉบับพิมพ์ใหม่ พ.ศ. 2563 มีชั้นบรรณาธิการ '
    'ที่ยังมีลิขสิทธิ์เช่นเดิม'
where slug = 'khamphi-horasat-thai';

-- Track the confirmation as an acquisition action so it appears in the
-- editorial workflow rather than only in a note.
update editorial.acquisition a set
  stage = 'outreach',
  note_th = coalesce(a.note_th, '') ||
    ' | พบหลักฐานปีถึงแก่กรรม พ.ศ. 2493 (แหล่งรองหนึ่งแหล่ง ดู work.rights_note_th) — '
    'เหลือขั้นยืนยันปฐมภูมิ: ราชกิจจานุเบกษา / คำนำฉบับ 2540 / หนังสืออนุสรณ์ '
    'ถ้ายืนยันได้ ปลดล็อกคลังวิกิซอร์ซทั้งชุดโดยไม่ต้องขออนุญาตใคร'
from content.edition e
where e.id = a.edition_id and e.citekey = 'chula-2283555';

select w.slug, w.rights, left(w.rights_note_th, 80) as note_head
from content.work w where w.slug = 'khamphi-horasat-thai';
