-- ============================================================================
-- Content set 5: ทำนายกระเหม่น หน้า ๒๔
-- ประมวลตำราทำนาย (ของเก่า) ภาค ๑, พ.ศ. 2477
--
-- The page facing the one interpretations_v4 already covers. Same source, same
-- lawful basis, same tabular ถ้า X → Y structure that maps to data without
-- interpretive strain.
--
-- PUBLIC DOMAIN, so original_text_th carries the 2477 verse VERBATIM and the
-- firewall admits it. This is the layer that lets a user read what the ตำรา
-- actually says instead of taking our word for it.
--
-- WHAT IS DELIBERATELY NOT PUBLISHED HERE
--
-- The page's last couplet reads "ถ้ากระเหม่นข้างบนจักมี ทุกข์แทบกาย จะถึงซึ่ง
-- ความเข็ญใจ". "ข้างบน" does not identify a body part unambiguously — it could
-- be the upper flank/ribs (ข้าง = side) or a continuation of the preceding
-- line. The verse is transcribed in full because that is a faithful record of
-- the page, but NO interpretation row is created for it: guessing which body
-- part a folk omen refers to and publishing the guess is exactly the invented
-- content this library exists to refuse. It needs a Thai classical reader.
--
-- NUMBERS: none, as with the rest of this source. It predates the lottery
-- number convention entirely.
--
-- TRANSCRIPTION STATUS: single-key from the page image, not yet double-keyed
-- by a second reader per rule B5 — recorded on the passage row, not hidden.
-- ============================================================================

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, v.locator, v.seq, v.orig, v.modern,
  'Claude (AI) — พิมพ์เรียงจากภาพสแกน D-Library 6238 เมื่อ 27 ก.ค. 2569',
  'คงอักขรวิธีฉบับ พ.ศ. 2477 ไว้ตามต้นฉบับ; ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สอง '
  '(double-key) ตามระเบียบ B5 | วรรคสุดท้าย "กระเหม่นข้างบน" ระบุอวัยวะไม่ชัด '
  'จึงบันทึกข้อความไว้ครบถ้วนแต่ยังไม่ตั้งเป็นคำทำนายของสัญลักษณ์ใด',
  'published'
from (values
  ('หน้า ๒๔ ส่วนทำนายกระเหม่น', 1,
   'จักแถลงแสดงโดยคัมภีร์ องค์พระศุลี ประสาทประสิทธิ์สรรพญาณ '
   'แจ้งกลกระเหม่นบันดาล ในขันธประการ ประกาศไว้แก่นรชน '
   'ถ้ากระเหม่นหูซ้ายพึงยล ข่าวร้ายจักดล มาแจ้งประจักษ์ในใจ '
   'กระเหม่นหูขวาจะมีไชย ลาภอันใด ๆ แต่ล้วนอันมีศุภผล '
   'ถ้ากระเหม่นศีร์ษะเบื้องบน จะได้แห่งผล อันดีมาถึงพึงใจ '
   'กระเหม่นผีปากล่างท่านไข ว่าโรคภายใน โลหิตอุบัติมิดี '
   'ถ้ากระเหม่นข้างบนจักมี ทุกข์แทบกาย จะถึงซึ่งความเข็ญใจ',
   'ตำราเปิดหมวดด้วยการอ้างคัมภีร์ แล้วไล่เรียงว่าอาการกระตุกของอวัยวะแต่ละส่วน '
   'เป็นลางบอกเหตุอย่างไร โดยแยกความหมายซ้าย-ขวาชัดเจน: หูซ้ายเป็นข่าวร้าย '
   'หูขวาเป็นลาภ ศีรษะเป็นผลดี ส่วนริมฝีปากล่างเป็นลางเรื่องโรคภายใน')
) as v(locator, seq, orig, modern)
cross join content.edition e
where e.citekey = 'nlt-6238-2477'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- Four readings. body_th is our own prose; the verse itself is in the passage.
-- ---------------------------------------------------------------------------

with p as (
  select p.id from content.passage p
  join content.edition e on e.id = p.edition_id
  where e.citekey = 'nlt-6238-2477'
    and p.locator = 'หน้า ๒๔ ส่วนทำนายกระเหม่น' limit 1
),
tr as (select id from content.tradition where slug = 'omen-krachamen')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id, v.body, v.plain, 'historical_belief',
  'เป็นความเชื่อเรื่องลางที่บันทึกไว้ในตำราเมื่อ พ.ศ. 2477 '
  'ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง และตำราเล่มนี้ไม่ได้ผูกเลขกับลางเหล่านี้',
  '{}', 'published', now()
from (values
  ('OMEN_TWITCH_EAR_L',
   'ตำราว่าถ้าหูข้างซ้ายกระเหม่น จะมีข่าวร้ายมาถึงให้รู้ชัดแก่ใจ '
   'เป็นลางฝ่ายร้ายที่คู่กับหูขวาซึ่งเป็นลางฝ่ายดี',
   'หูซ้ายกระตุก ตำราเก่าว่าจะมีข่าวร้ายมาถึง เป็นความเชื่อโบราณ ไม่ใช่เรื่องที่ต้องกังวล'),
  ('OMEN_TWITCH_EAR_R',
   'ตำราว่าถ้าหูข้างขวากระเหม่น จะมีชัยและได้ลาภ โดยระบุว่าลาภที่ได้ล้วนเป็นผลดี '
   'ตรงข้ามกับหูซ้ายซึ่งเป็นลางข่าวร้าย',
   'หูขวากระตุก ตำราเก่าว่าจะมีโชคมีลาภเข้ามา เป็นความเชื่อโบราณ ไม่ได้แปลว่าจะถูกหวย'),
  ('OMEN_TWITCH_HEAD',
   'ตำราว่าถ้าศีรษะเบื้องบนกระเหม่น จะได้รับผลอันดีมาถึงให้สมใจ '
   'จัดเป็นลางฝ่ายดีในหมวดนี้',
   'หัวกระตุกด้านบน ตำราเก่าว่าจะมีเรื่องดีเข้ามาให้สมใจ'),
  ('OMEN_TWITCH_LIP',
   'ตำราว่าถ้าริมฝีปากล่างกระเหม่น ท่านอธิบายว่าเป็นลางเรื่องโรคภายใน '
   'เกี่ยวกับโลหิตซึ่งไม่ดี',
   'ริมฝีปากล่างกระตุก ตำราเก่าว่าเป็นลางเรื่องโรคภายใน ถ้ากังวลเรื่องสุขภาพควรไปพบแพทย์')
) as v(concept_key, body, plain)
join content.symbol s on s.concept_key = v.concept_key
cross join p cross join tr
where not exists (
  select 1 from content.interpretation i
  where i.symbol_id = s.id and i.passage_id = (select id from p)
);

do $$
declare r record; bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then bad := bad + 1; end if;
  end loop;
  if bad > 0 then raise exception 'aborted: % rights invariant(s) violated', bad; end if;
end $$;

select
  (select count(*) from content.interpretation where status = 'published') as published_interpretations,
  (select count(*) from content.symbol where status = 'published') as published_symbols;
