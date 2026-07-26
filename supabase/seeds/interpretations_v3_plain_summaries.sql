-- ============================================================================
-- Plain-language summaries (ภาษาชาวบ้าน) for the ten published interpretations
--
-- Each is an editorial compression of our own body_th: short, everyday Thai,
-- one idea, faithful to what the source actually says — including keeping the
-- auspicious/ominous direction of the original. No lottery framing, ever.
-- Written and reviewed under the same rules as the full text.
-- ============================================================================

-- ---- Content set 1: Mahasupina Jataka (Pasenadi's sixteen dreams) ----------

update content.interpretation i
   set summary_plain_th = v.plain
  from (values
    ('DREAM_SNAKE',
     'ตำราว่า ของที่ดูตัวเล็กกลับชนะของตัวใหญ่ คนที่เคยมีอำนาจจะกลับเป็นฝ่ายแพ้'),
    ('DREAM_TREE',
     'ต้นไม้ออกดอกก่อนวัย ตำราว่าเป็นภาพของการรีบโตรีบได้เกินเวลา ไม่ใช่ลางดี'),
    ('DREAM_RICE',
     'ข้าวหม้อเดียวสุกบ้างดิบบ้าง ตำราว่าบ้านเมืองไม่เป็นธรรม ฝนฟ้าไม่ตกตามฤดู'),
    ('DREAM_WATER',
     'น้ำล้นตุ่มที่เต็ม แต่ตุ่มเปล่าไม่มีใครเติม ตำราว่าของดีไหลไปหาคนมีอำนาจหมด'),
    ('DREAM_GOLD',
     'ถาดทองถูกเอาไปให้หมาจิ้งจอก ตำราว่าของมีค่าตกอยู่กับคนไม่คู่ควร'),
    ('DREAM_HORSE',
     'ม้ากินหญ้าสองปาก ตำราว่าคนมีอำนาจกินสองทาง รับผลประโยชน์จากทุกฝ่าย')
  ) as v(concept_key, plain)
 where i.symbol_id = (select id from content.symbol s where s.concept_key = v.concept_key)
   and i.passage_id in (
     select p.id from content.passage p
     join content.edition e on e.id = p.edition_id
     where e.citekey = 'tipitaka-27-77');

-- ---- Content set 2: Subina Sutta (the Bodhisatta's five dreams) ------------

update content.interpretation i
   set summary_plain_th = v.plain
  from (values
    ('DREAM_SEA',
     'ฝันยิ่งใหญ่ถึงทะเลถึงขุนเขา ตำราฝ่ายพุทธว่าเป็นลางดี จะได้พบสิ่งยิ่งใหญ่ในชีวิต'),
    ('DREAM_MOUNTAIN',
     'เดินบนกองสิ่งสกปรกแต่ไม่เปื้อน ตำราว่าจะได้ลาภมาแล้วไม่หลงมัวเมากับมัน'),
    ('DREAM_INSECT',
     'สัตว์เล็กจำนวนมากมาห้อมล้อม ตำราฝ่ายพุทธว่าเป็นลางดี จะมีคนมาพึ่งพาอาศัย'),
    ('DREAM_BIRD',
     'นกต่างสีบินมารวมกันแล้วกลายเป็นสีเดียว ว่าคนต่างพวกต่างฐานะจะกลมเกลียวกัน')
  ) as v(concept_key, plain)
 where i.symbol_id = (select id from content.symbol s where s.concept_key = v.concept_key)
   and i.passage_id in (
     select p.id from content.passage p
     join content.edition e on e.id = p.edition_id
     where e.citekey = 'tipitaka-22-196');

-- Review records for the new editorial layer
insert into content.review (entity_type, entity_id, role, reviewer, verdict, note_th)
select 'interpretation', i.id, 'editorial',
  'Claude (AI) — สรุปภาษาชาวบ้านจาก body_th ของตนเอง 26 ก.ค. 2569',
  'checked',
  'ตรวจว่า summary_plain_th สั้นไม่เกินสองบรรทัด คงทิศทางดี/ร้ายตามต้นฉบับ '
  'ไม่เพิ่มการตีความใหม่ และไม่มีการโยงเลขหรือโชคลาภ'
from content.interpretation i
where i.summary_plain_th is not null
  and i.status = 'published'
  and not exists (
    select 1 from content.review r
    where r.entity_type = 'interpretation' and r.entity_id = i.id
      and r.note_th like 'ตรวจว่า summary_plain_th%'
  );

-- Editorial completeness gate: a published interpretation without a plain
-- summary would render as a wall of prose for exactly the readers the product
-- serves — treat it as a defect, not a nice-to-have.
do $$
declare missing int;
begin
  select count(*) into missing
    from content.interpretation
   where status = 'published' and summary_plain_th is null;
  if missing > 0 then
    raise exception 'plain summaries incomplete: % published interpretation(s) missing summary_plain_th', missing;
  end if;
end $$;

select count(*) as published_with_plain_summary
  from content.interpretation
 where status = 'published' and summary_plain_th is not null;
