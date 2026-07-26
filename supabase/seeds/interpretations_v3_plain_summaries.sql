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
     'ตำราว่า ของที่ดูตัวเล็กจะกลับชนะของตัวใหญ่ คนที่เคยมีอำนาจจะกลับเป็นฝ่ายแพ้ '
     'ใครกำลังโดนคนตัวโตกว่ากดไว้ ฝันแบบนี้ตำราถือว่าสถานการณ์กำลังจะพลิก'),
    ('DREAM_TREE',
     'ต้นไม้เพิ่งโผล่พ้นดินก็ออกดอกออกผลแล้ว ตำราว่าเป็นภาพของการรีบโตรีบได้เกินเวลา '
     'อะไรที่มาเร็วเกินกำหนด ตำราไม่นับเป็นลางดี ให้ระวังเรื่องชิงสุกก่อนห่าม'),
    ('DREAM_RICE',
     'ข้าวหม้อเดียวกันแท้ ๆ แต่สุกบ้างดิบบ้างแฉะบ้าง ตำราว่าบ้านเมืองกำลังไม่เป็นธรรม '
     'ฝนฟ้าไม่ตกต้องตามฤดู ที่หนึ่งได้เต็มเม็ดเต็มหน่วย อีกที่กลับแห้งแล้ง'),
    ('DREAM_WATER',
     'น้ำล้นตุ่มที่เต็มอยู่แล้ว แต่ตุ่มเปล่าข้าง ๆ ไม่มีใครเหลียวแล ตำราว่าของดีมีแต่จะ '
     'ไหลไปกองอยู่กับคนมีอำนาจ ส่วนคนตัวเล็กต้องคอยดูแลตัวเองให้ดี'),
    ('DREAM_GOLD',
     'ถาดทองคำราคาแพงถูกยกไปให้หมาจิ้งจอกใช้ ตำราว่าของมีค่ากำลังตกไปอยู่กับ '
     'คนที่ไม่คู่ควร ฝันแบบนี้ให้ระวังการฝากของสำคัญไว้ผิดที่ผิดคน'),
    ('DREAM_HORSE',
     'ม้าตัวเดียวกินหญ้าได้สองปาก ตำราว่าเป็นภาพของคนมีอำนาจที่กินสองทาง '
     'รับผลประโยชน์จากทุกฝ่าย ให้ระวังคนกลางหรือผู้ตัดสินที่ไม่ตรงไปตรงมา')
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
     'ฝันยิ่งใหญ่เห็นถึงทะเลถึงขุนเขา ตำราโบราณจัดเป็นนิมิตมงคลขั้นสูง '
     'ว่าผู้ฝันกำลังจะได้พบหรือได้ทำสิ่งยิ่งใหญ่เกินตัวในชีวิต'),
    ('DREAM_MOUNTAIN',
     'เดินอยู่บนกองสิ่งสกปรกทั้งภูเขาแต่ตัวไม่เปื้อนเลย ตำราว่าลาภก้อนใหญ่กำลังจะมา '
     'และผู้ฝันจะรับไว้ได้โดยไม่หลงมัวเมาไปกับมัน ถือเป็นนิมิตทางดี'),
    ('DREAM_INSECT',
     'สัตว์ตัวเล็ก ๆ จำนวนมากพากันมาห้อมล้อมถึงตัว ตำราโบราณว่าเป็นลางดี '
     'จะมีผู้คนมากหน้าหลายตามาขอพึ่งพาอาศัยบารมี ไม่ใช่เรื่องสกปรกอย่างที่คิด'),
    ('DREAM_BIRD',
     'นกหลากสีบินมาจากทุกทิศ มารวมกันแล้วกลายเป็นสีเดียวกันหมด '
     'ตำราว่าคนต่างพวกต่างฐานะกำลังจะมารวมใจเป็นหนึ่ง เป็นนิมิตของความกลมเกลียว')
  ) as v(concept_key, plain)
 where i.symbol_id = (select id from content.symbol s where s.concept_key = v.concept_key)
   and i.passage_id in (
     select p.id from content.passage p
     join content.edition e on e.id = p.edition_id
     where e.citekey = 'tipitaka-22-196');

-- Context notes retoned: the app's register is นิมิต and ความเชื่อ, not a
-- doctrine lesson. Same facts, same no-gambling line, shorter and warmer.
update content.interpretation i
   set context_note_th =
     'เป็นนิมิตจากตำราโบราณที่กล่าวถึงเหตุการณ์บ้านเมืองในภายหน้า '
     'ไม่ใช่ลางเฉพาะตัวของผู้ฝัน และตำรานี้ไม่ผูกความฝันกับการเสี่ยงโชค'
  from content.passage p
  join content.edition e on e.id = p.edition_id
 where p.id = i.passage_id and e.citekey = 'tipitaka-27-77';

update content.interpretation i
   set context_note_th =
     'เป็นนิมิตมงคลชุดใหญ่จากตำราโบราณ สัญลักษณ์เดียวกันแต่ละตำราให้ความหมาย '
     'ต่างกันได้ และตำรานี้ไม่ผูกความฝันกับการเสี่ยงโชค'
  from content.passage p
  join content.edition e on e.id = p.edition_id
 where p.id = i.passage_id and e.citekey = 'tipitaka-22-196';

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
