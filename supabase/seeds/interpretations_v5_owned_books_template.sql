-- ============================================================================
-- WORKING TEMPLATE: entering content from books you own
--
-- This file is the pattern to copy for every future batch. It proves the
-- whole path end to end — copyrighted source, owned copy, own prose, numbers
-- attached — and it is deliberately SMALL so the shape is obvious.
--
-- The method, which is the ordinary one for reference works:
--   1. Read the book you own. (No permission needed. Never was.)
--   2. Extract the FACT — which belief the book records. Facts are outside
--      copyright (s.6 ¶2, s.7(1)).
--   3. Write body_th and summary_plain_th in YOUR OWN WORDS. Never transcribe.
--   4. Cite the book so a reader can check you.
--   5. For a claim drawn from ONE copyrighted book, name a second independent
--      source in corroborating_edition_ids before publishing.
--
-- On step 5: this is the difference between reproducing a publisher's work and
-- recording a cultural fact, and it is also why the content is worth trusting.
-- Draft rows need no corroboration — write freely, corroborate before publish.
--
-- IMPORTANT — passage without verbatim text:
-- content.passage for a copyrighted source carries locator + modern_th only.
-- original_text_th stays NULL; the firewall rejects it, correctly. The locator
-- still lets a reader open the book at the right page and check the claim.
-- ============================================================================

-- One passage per section of the book being worked through. Locator points to
-- the page; no source text is stored.
insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, 'หมวดสัตว์ (รอเลขหน้าจากเล่มจริง)', 1,
  null,   -- verbatim intentionally absent: copyrighted source
  'หมวดว่าด้วยการฝันเห็นสัตว์ชนิดต่าง ๆ พร้อมเลขประจำสัญลักษณ์',
  'เจ้าของโครงการ อ่านจากฉบับพิมพ์ที่ถือครอง',
  'ไม่เก็บข้อความต้นฉบับ — สกัดเฉพาะข้อเท็จจริงเชิงความเชื่อแล้วเรียบเรียงใหม่ '
  'ตัวชี้ตำแหน่งมีไว้ให้ผู้อ่านเปิดเล่มตรวจสอบได้',
  'published'
from content.edition e where e.citekey = 'fan-phayakon-owned'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- EXAMPLE ROW — ช้าง, the symbol that prompted this
--
-- Left as status='draft' ON PURPOSE. The prose below is a placeholder written
-- without the book in hand: the actual reading and its numbers must come from
-- the page. Replace body_th, summary_plain_th and the numbers with what the
-- book records, add a corroborating source, then flip to 'published'.
-- Publishing invented content would defeat the entire apparatus.
-- ---------------------------------------------------------------------------

with p as (
  select p.id from content.passage p
  join content.edition e on e.id = p.edition_id
  where e.citekey = 'fan-phayakon-owned' limit 1
),
tr as (select id from content.tradition where slug = 'folk-central')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status)
select s.id, p.id, tr.id,
  '[รอเนื้อหาจากเล่มจริง] เรียบเรียงด้วยสำนวนของเราเองว่าตำราเล่มนี้ให้ความหมายอย่างไร',
  '[รอเนื้อหาจากเล่มจริง] สรุปสองประโยคภาษาชาวบ้าน',
  'historical_belief',
  'เป็นความเชื่อที่บันทึกในตำราทำนายฝันร่วมสมัย ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
  'และเลขที่ปรากฏเป็นเลขเชิงสัญลักษณ์ ไม่ได้เพิ่มโอกาสถูกรางวัล',
  '{}', 'draft'
from content.symbol s cross join p cross join tr
where s.concept_key = 'DREAM_ELEPHANT'
  and not exists (
    select 1 from content.interpretation i
    where i.symbol_id = s.id and i.passage_id = (select id from p)
  );

-- ---------------------------------------------------------------------------
-- Numbers: the pipeline that has been empty until now
--
-- content.number_association takes number as TEXT ('09' ≠ '9'), ties to the
-- passage so every number is traceable to a page, and publishes only when the
-- editor is satisfied. Rows below are draft placeholders showing the shape.
-- ---------------------------------------------------------------------------

insert into content.number_association
  (symbol_id, number, passage_id, tradition_id, note_th, status)
select s.id, v.num, p.id, tr.id,
  'เลขประจำสัญลักษณ์ตามตำราทำนายฝันร่วมสมัย — รอยืนยันจากเล่มจริง',
  'draft'
from (values ('00'), ('0')) as v(num)
cross join (select id from content.symbol where concept_key = 'DREAM_ELEPHANT') s
cross join (select p.id from content.passage p
              join content.edition e on e.id = p.edition_id
             where e.citekey = 'fan-phayakon-owned' limit 1) p
cross join (select id from content.tradition where slug = 'folk-central') tr
on conflict (symbol_id, number, tradition_id) do nothing;

do $$
declare r record; bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then bad := bad + 1; end if;
  end loop;
  if bad > 0 then raise exception 'template aborted: % invariant(s)', bad; end if;
end $$;

select
  (select count(*) from content.interpretation where status = 'draft') as drafts_awaiting_content,
  (select count(*) from content.number_association) as number_rows_total,
  (select count(*) from content.number_association where status = 'published') as numbers_published;
