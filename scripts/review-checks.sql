-- ============================================================================
-- Automated review sweep — the "agent" half of the editorial pipeline
--
-- Run this against the library whenever content changes, or on a schedule. It
-- writes rows into editorial.review_finding and CHANGES NOTHING ELSE. There is
-- deliberately no UPDATE of any status in this file: an agent proposes, an
-- editor decides. If a future version of this script could publish, the whole
-- point of the library would be gone.
--
-- Findings are re-derived from scratch each run, so a fixed problem disappears
-- rather than lingering as a stale warning that everyone learns to ignore.
--
-- Severity means what it says:
--   blocker  — do not publish; this breaks a rule the project committed to
--   warning  — a human must look before publishing
--   note     — backlog information, no action implied
-- ============================================================================

begin;

delete from editorial.review_finding where found_by = 'auto' and not resolved;

-- ── blocker: a published claim resting on ONE copyrighted book ─────────────
-- The two-source rule is what turns a publisher's expression into a cultural
-- fact. PD sources are exempt: nobody owns the expression there.
insert into editorial.review_finding
  (interpretation_id, check_code, severity, message_th, detail)
select i.id, 'single_source_copyrighted', 'blocker',
  'เผยแพร่แล้วแต่อ้างอิงหนังสือมีลิขสิทธิ์เพียงเล่มเดียว และยังไม่บันทึกแหล่งที่สอง — '
  || 'ต้องเพิ่ม corroborating_edition_ids หรือถอนกลับเป็นฉบับร่าง',
  jsonb_build_object('symbol', s.name_th, 'work', w.canonical_title_th,
                     'rights', w.rights::text, 'locator', p.locator)
from content.interpretation i
join content.passage p on p.id = i.passage_id
join content.edition e on e.id = p.edition_id
join content.work    w on w.id = e.work_id
join content.symbol  s on s.id = i.symbol_id
where i.status = 'published'
  and w.rights <> 'public_domain'
  and coalesce(array_length(i.corroborating_edition_ids, 1), 0) = 0;

-- ── blocker: sensitive content published without recorded clearance ────────
-- A CHECK constraint already makes this impossible to insert. The sweep exists
-- because constraints can be dropped, and a silent drop is exactly the failure
-- worth catching.
insert into editorial.review_finding
  (interpretation_id, check_code, severity, message_th, detail)
select i.id, 'sensitive_without_counsel', 'blocker',
  'เนื้อหาอ่อนไหว (' || i.sensitivity::text || ') เผยแพร่อยู่โดยยังไม่บันทึกการตรวจของที่ปรึกษากฎหมาย',
  jsonb_build_object('symbol', s.name_th, 'sensitivity', i.sensitivity::text)
from content.interpretation i
join content.symbol s on s.id = i.symbol_id
where i.status = 'published' and i.sensitivity <> 'routine' and not i.counsel_cleared;

-- ── blocker: verbatim text stored against a work that does not permit it ───
insert into editorial.review_finding
  (check_code, severity, message_th, detail)
select 'verbatim_on_restricted_work', 'blocker',
  'พบข้อความต้นฉบับคำต่อคำในงานที่ไม่อนุญาตให้ทำซ้ำ',
  jsonb_build_object('locator', p.locator, 'work', w.canonical_title_th,
                     'rights', w.rights::text)
from content.passage p
join content.edition e on e.id = p.edition_id
join content.work    w on w.id = e.work_id
where p.original_text_th is not null
  and w.rights not in ('public_domain','cc0','cc_by','cc_by_sa','licensed_permission');

-- ── warning: a published reading with no page locator ──────────────────────
-- Without one a reader cannot check us, which is the entire proposition.
insert into editorial.review_finding
  (interpretation_id, check_code, severity, message_th, detail)
select i.id, 'missing_locator', 'warning',
  'คำแปลที่เผยแพร่แล้วไม่มีตัวชี้ตำแหน่งในเล่ม ผู้อ่านตามกลับไปตรวจไม่ได้',
  jsonb_build_object('symbol', s.name_th)
from content.interpretation i
join content.passage p on p.id = i.passage_id
join content.symbol  s on s.id = i.symbol_id
where i.status = 'published' and coalesce(nullif(trim(p.locator), ''), '') = '';

-- ── warning: transcription never double-keyed ──────────────────────────────
insert into editorial.review_finding
  (check_code, severity, message_th, detail)
select 'single_key_transcription', 'warning',
  'ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สองตามระเบียบ B5',
  jsonb_build_object('locator', p.locator, 'note', left(p.transcription_note_th, 120))
from content.passage p
where p.status = 'published'
  and p.transcription_note_th ilike '%double-key%';

-- ── warning: circulating belief whose window has closed ────────────────────
-- Viral content rots. "คนพูดกันเดือนนี้" stops being true next month, and a
-- rumour left published past its window quietly becomes a claim about now.
insert into editorial.review_finding
  (check_code, severity, message_th, detail)
select 'stale_circulation', 'warning',
  'ความเชื่อที่บันทึกว่ากำลังแพร่หลาย เลยช่วงเวลาที่สังเกตไว้แล้วแต่ยังเผยแพร่อยู่ — '
  || 'ควรปิดหรือระบุช่วงเวลาให้ชัด',
  jsonb_build_object('occasion', c.occasion_th, 'number', c.number,
                     'observedTo', c.observed_to)
from content.circulation c
where c.status = 'published'
  and c.observed_to is not null
  and c.observed_to < (now() at time zone 'Asia/Bangkok')::date - 45;

-- ── note: symbols the matcher can find but cannot explain ──────────────────
insert into editorial.review_finding
  (check_code, severity, message_th, detail)
select 'symbol_without_reading', 'note',
  'สัญลักษณ์นี้จับคู่ในฝันได้ แต่ยังไม่มีคำแปลที่มีตำรารองรับ',
  jsonb_build_object('symbol', s.name_th, 'conceptKey', s.concept_key)
from content.symbol s
where s.status = 'published'
  and not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.status = 'published');

-- ── note: draft numbers waiting on a second source ─────────────────────────
insert into editorial.review_finding
  (check_code, severity, message_th, detail)
select 'number_awaiting_corroboration', 'note',
  'เลขฉบับร่างรอสอบทานกับแหล่งที่สองก่อนเผยแพร่',
  jsonb_build_object('symbol', s.name_th, 'number', n.number)
from content.number_association n
join content.symbol s on s.id = n.symbol_id
where n.status = 'draft';

commit;

select severity, check_code, count(*) as n
  from editorial.review_finding
 where not resolved
 group by 1, 2
 order by case severity when 'blocker' then 1 when 'warning' then 2 else 3 end, n desc;
