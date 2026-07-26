-- ============================================================================
-- Content set 3: ทำนายกระเหม่น + ทำนายสัตว์ตก
-- ประมวลตำราทำนาย (ของเก่า) ภาค ๑, พ.ศ. 2477 — the first FOLK-BELIEF content
--
-- This set matters for three reasons beyond its own value:
--   1. It is the first content in the app's ACTUAL register — ความเชื่อ ลาง
--      โชคชะตา — not doctrine. tradition.display_rank puts omen-* at 15 vs
--      buddhist-canon at 90, so from this moment folk readings LEAD.
--   2. The source is PD on two independent grounds, so verbatim quoting is
--      lawful and the firewall admits the original verse.
--   3. The verse format here is genuinely tabular (ถ้า X → Y), unlike the
--      dream section's Pali-plus-gloss, so it maps to data without
--      interpretive strain.
--
-- Transcription: typed from the D-Library page images (no text layer exists).
-- 1934 orthography preserved verbatim in original_text_th; modern_th holds a
-- reading aid; summary_plain_th is the two-sentence ภาษาชาวบ้าน layer.
--
-- NOTE ON NUMBERS: this source contains none. It predates the lottery
-- number-extraction convention entirely, so no number_association rows follow
-- from it — recorded here so nobody later assumes the omission was an
-- oversight and "fills it in".
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Passages: two, one per section, quoting the verse verbatim (lawful: PD)
-- ---------------------------------------------------------------------------

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, v.locator, v.seq, v.orig, v.modern,
  'Claude (AI) — พิมพ์เรียงจากภาพสแกน D-Library 6238 เมื่อ 26 ก.ค. 2569',
  'คงอักขรวิธีฉบับ พ.ศ. 2477 ไว้ตามต้นฉบับ; ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สอง '
  '(double-key) ตามระเบียบ B5 — ควรทานก่อนขยายเนื้อหาชุดนี้',
  'published'
from (values
  ('หน้า ๒๕ ส่วนทำนายกระเหม่น', 1,
   'ถ้ากระเหม่นใจอยู่ไหวไหว จะเกิดโจรภัย มาลักจะทำโทษตัว '
   'ถ้ากระเหม่นแขนซ้ายพิงกลัว ทุกข์โทษจะพัว จะเพิ่มจะพันกายา '
   'ถ้าแม้นกระเหม่นแขนขวา ท่านผู้อิศรา จะรักจะค้ำชูตน '
   'ถ้าแม้นกระเหม่นนาสา จะได้โสกา แลโศกรำจวนครวญคราง',
   'ตำราว่าอาการกระตุกของอวัยวะแต่ละส่วนเป็นลางบอกเหตุต่างกัน '
   'และแยกความหมายระหว่างข้างซ้ายกับข้างขวาอย่างชัดเจน'),
  ('หน้า ๑๙ ส่วนทำนายสัตว์ตก', 1,
   'ถ้าตกลงเบื้องซ้ายหมาย จักทุกข์ทุ่มกาย อุบาทว์จะเบียนบีฑา '
   'ถ้าแม้นตกลงเบื้องขวา พี่น้องจักมา ประสพประสมปรีดี '
   'ตกถูกศีร์ษะอย่าขาม ไทท้าวจะปาม จะปูนบำเหน็จยศตน',
   'ตำราว่าสัตว์ที่ตกลงมาถูกตัวหรือตกทางทิศใด เป็นลางบอกเหตุตามทิศและตำแหน่งที่ตก')
) as v(locator, seq, orig, modern)
cross join content.edition e
where e.citekey = 'nlt-6238-2477'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- Interpretations — folk register, plain-language summary leads
-- ---------------------------------------------------------------------------

with p_kra as (
  select p.id from content.passage p join content.edition e on e.id = p.edition_id
   where e.citekey = 'nlt-6238-2477' and p.locator = 'หน้า ๒๕ ส่วนทำนายกระเหม่น' limit 1
),
p_sat as (
  select p.id from content.passage p join content.edition e on e.id = p.edition_id
   where e.citekey = 'nlt-6238-2477' and p.locator = 'หน้า ๑๙ ส่วนทำนายสัตว์ตก' limit 1
),
tr_kra as (select id from content.tradition where slug = 'omen-krachamen'),
tr_sat as (select id from content.tradition where slug = 'omen-satok')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id,
       case when v.section = 'kra' then (select id from p_kra) else (select id from p_sat) end,
       case when v.section = 'kra' then (select id from tr_kra) else (select id from tr_sat) end,
       v.body, v.plain, 'historical_belief',
       'เป็นความเชื่อเรื่องลางบอกเหตุที่บันทึกไว้ในตำราของเก่า ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
       'และตำราเล่มนี้ไม่ได้ผูกลางเหล่านี้เข้ากับตัวเลขใด ๆ',
       '{}', 'published', now()
from (values

  ('kra', 'OMEN_TWITCH_HEART',
   'ตำราประมวลตำราทำนายว่า เมื่อใจสั่นไหวขึ้นมาเอง เป็นลางเตือนเรื่องโจรภัย '
   'คือจะมีผู้คิดร้ายเข้ามาลักขโมยหรือทำให้เดือดร้อน',
   'ใจสั่นขึ้นมาเฉย ๆ ตำราเก่าถือเป็นลางเตือนเรื่องขโมยหรือคนคิดร้าย '
   'ช่วงนี้ให้ระวังทรัพย์สินและคนแปลกหน้าไว้สักหน่อย'),

  ('kra', 'OMEN_TWITCH_ARM_L',
   'ตำราว่า กระเหม่นที่แขนซ้ายเป็นลางฝ่ายร้าย บอกว่าทุกข์โทษจะพัวพันเข้ามาถึงตัว',
   'แขนซ้ายกระตุก ตำราเก่าถือเป็นลางไม่ค่อยดี ว่าจะมีเรื่องเดือดร้อนพัวพันเข้ามา '
   'เป็นที่มาของคำที่คนโบราณพูดกันว่า "ซ้ายร้าย ขวาดี"'),

  ('kra', 'OMEN_TWITCH_ARM_R',
   'ตำราว่า กระเหม่นที่แขนขวาเป็นลางฝ่ายดี บอกว่าผู้ใหญ่หรือผู้มีอำนาจจะเมตตาค้ำชู',
   'แขนขวากระตุก ตำราเก่าถือเป็นลางดี ว่าจะมีผู้ใหญ่หรือผู้มีอำนาจเมตตาช่วยเหลือ '
   'ถ้ากำลังจะไปขอความช่วยเหลือใคร ตำราถือว่าเป็นจังหวะที่ดี'),

  ('kra', 'OMEN_TWITCH_NOSE',
   'ตำราว่า กระเหม่นที่จมูกเป็นลางบอกความโศก คือจะมีเรื่องให้เศร้าโศกครวญคราง',
   'จมูกกระตุก ตำราเก่าว่าจะมีเรื่องให้เศร้าใจ '
   'เป็นลางฝ่ายอารมณ์มากกว่าลางเรื่องทรัพย์สินหรืออันตราย'),

  ('sat', 'OMEN_ANIMAL_FALL',
   'ตำราทำนายสัตว์ตกแยกความหมายตามทิศและตำแหน่งที่ตก: ตกทางซ้ายเป็นลางทุกข์และอุบาทว์ '
   'ตกทางขวาว่าพี่น้องญาติมิตรจะมาพบกันด้วยความยินดี '
   'ส่วนตกลงถูกศีรษะตำราบอกว่าไม่ต้องกลัว เพราะเป็นลางว่าผู้ใหญ่จะให้ยศให้รางวัล',
   'สัตว์ตกใส่ตัว ตำราเก่าดูที่ทิศและตำแหน่ง ตกซ้ายเป็นลางไม่ดี ตกขวาว่าจะได้เจอญาติมิตร '
   'ที่คนมักตกใจกันคือตกใส่หัว แต่ตำราว่าเป็นลางดี จะได้ลาภยศจากผู้ใหญ่')

) as v(section, concept_key, body, plain)
join content.symbol s on s.concept_key = v.concept_key
where not exists (
  select 1 from content.interpretation i
  where i.symbol_id = s.id
    and i.passage_id = case when v.section = 'kra' then (select id from p_kra)
                            else (select id from p_sat) end
);

insert into content.review (entity_type, entity_id, role, reviewer, verdict, note_th)
select 'interpretation', i.id, 'editorial',
  'Claude (AI) — พิมพ์เรียงและเรียบเรียงจากภาพสแกน D-Library 6238 เมื่อ 26 ก.ค. 2569',
  'checked',
  'ตัวบทพ้นลิขสิทธิ์ทั้งงานและคำนำ จึงอ้าง verbatim ได้; body_th เป็นสำนวนเรียบเรียงใหม่ '
  'จากเนื้อความในกาพย์ — ควรทานซ้ำโดยผู้อ่านคนที่สองก่อนขยายเนื้อหาชุดนี้'
from content.interpretation i
join content.passage p on p.id = i.passage_id
join content.edition e on e.id = p.edition_id
where e.citekey = 'nlt-6238-2477'
  and not exists (
    select 1 from content.review r
    where r.entity_type = 'interpretation' and r.entity_id = i.id
  );

do $$
declare r record; bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then bad := bad + 1; end if;
  end loop;
  if bad > 0 then raise exception 'interpretations_v4 aborted: % invariant(s)', bad; end if;
end $$;

select (select count(*) from content.interpretation where status='published') as interpretations,
       (select count(*) from content.passage where status='published') as passages,
       (select count(*) from content.number_association) as numbers;
