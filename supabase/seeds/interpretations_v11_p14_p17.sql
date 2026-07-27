-- ============================================================================
-- Content set 9: ประมวลตำราทำนาย ภาค ๑ หน้า ๑๔–๑๗ — ปิดหมวดตำราทำนายฝัน
--
-- หน้า ๑๗ ends with a rule drawn across the page and the rest left blank. The
-- dream treatise is ๑–๑๗; หน้า ๑๘ opens คำทำนายสัตว์ตก under its own heading.
-- So this file completes the dream section of this edition.
--
-- THE REMEDY PATTERN, which no earlier page had. Up to now the book has said
-- what a dream means. Here it starts saying what to DO about it: a dream of
-- fire sends you to แก้ at a flowing river and "โทษภัยจะผิน จะผันกลับได้ไชยา";
-- a dream of a noble lady is not to be retold, and is แก้ at a sandbar or a
-- tree; a parasol dream wants a ทำขวัญ before the gain arrives. The readings
-- carry the remedy in body_th rather than flattening each entry to a verdict,
-- because the remedy is the substance of the claim, not decoration on it.
--
-- Six symbols here already carry a reading from an earlier page (เต่า ม้า ไฟ
-- บินได้ วัด พระพุทธรูป). These are SECOND readings on a different passage, not
-- replacements — the same shape as แหวน holding both หน้า ๑๒ and หน้า ๑๓.
-- บินได้ ends up with two readings from this file alone, because เดินกลางเวหา
-- on ๑๔ and เหาะลอยเทียมลม on ๑๗ are separate entries in the book.
--
-- Public domain, so original_text_th carries the verse verbatim. Still
-- single-key; the B5 caveat rides on every passage.
--
-- NUMBERS: none, as everywhere in this source.
-- ============================================================================

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, v.locator, v.seq, v.orig, v.modern,
  'Claude (AI) — อ่านจากภาพสแกน D-Library 6238 เมื่อ 27 ก.ค. 2569',
  'คงอักขรวิธีฉบับ พ.ศ. 2477 ไว้ตามต้นฉบับ; หน้าเรียงสองคอลัมน์ '
  'อ่านซ้ายแล้วขวาเป็นบรรทัด ๆ | ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สอง (double-key) '
  'ตามระเบียบ B5',
  'published'
from (values
  ('หน้า ๑๔ ส่วนคำทำนายฝันรายสัญลักษณ์', 14,
   'ฝันว่าได้เต่าจักมี ทาสาทาสี เมียมิ่งแลคชอาชา '
   'อีกทั้งพี่น้องบุตรา จะมาสู่หา ให้สมที่นึกตริกตรอง '
   'ฝันว่าได้ม้าลำพอง จักรพรรดิจะปอง ยกตนให้เป็นราชา '
   'ฝันว่ากินชลสุธา จะได้ทาสา มาเลี้ยงเป็นลูกเมียตน '
   'ฝันว่าไฟไหม้ร้อนรน จงเร่งขวายขวน แก้ที่แม่น้ำไหลริน '
   'จะค่อยบรรเทามลทิน โทษภัยจะผิน จะผันกลับได้ไชยา '
   'ฝันว่าเดินกลางเวหา จักจงจินดา อันใดจะได้โดยใจ '
   'ฝันว่าถูกอ่อนเต็มใน เรือนตนจะได้ ข้าคนแต่ล้วนดีดี',
   'หน้านี้ให้คำทำนายรายสัญลักษณ์ต่อจากหน้า ๑๓ และเป็นหน้าแรกที่สั่ง "วิธีแก้" '
   'เมื่อฝันร้าย ไม่ใช่บอกความหมายอย่างเดียว'),
  ('หน้า ๑๕ ส่วนคำทำนายฝันรายสัญลักษณ์', 15,
   'ฝันว่านุ่งห่มแดงศรี เร่งเกรงไพรี ระมัดระวังกายา '
   'ฝันว่านุ่งห่มกาสาว์ จะอยู่ปรีดา ไม่มีใครเบียดเบียนตน '
   'ฝันว่านอนเรือเบื้องบน ต้นหนึ่งตกชล แลเคียรกตกน้ำรา '
   'ให้แก้ที่ต้นพฤกษา อันใหญ่โสภา นานไปจะได้เมียงาม '
   'ฝันว่านางพญานงราม แม้นว่าใครถาม อย่าบอกอย่าเล่าบรรยาย '
   'ให้แก้ที่กลางหาดทราย นัยหนึ่งอุบาย ให้แก้ต้นไม้จึงดี '
   'ฝันว่าสาวพรหมจารี ถือประทีปเทียนศรี สว่างมาเข้าเรือนตน '
   'จะมียศศักดิ์ยิ่งคน จะเลื่อนที่ตน มีศักดิยศเป็นพญา',
   'หน้านี้จับคู่สีของเครื่องนุ่งห่มกับผลของฝัน และให้วิธีแก้ฝันไว้หลายแห่ง'),
  ('หน้า ๑๖ ส่วนคำทำนายฝันรายสัญลักษณ์', 16,
   'ถ้าหญิงสาวศรีโสภา จะได้ภัสดา อันสบประสงค์พึงใจ '
   'ฝันว่าสวดพุทธมนต์สิ่งใด จะเปลื้องปลดภัย อุบาทว์บเบียนบีฑา '
   'ฝันว่ากั้นกลดสุริยา กางร่มจักผา- สุกสวัสดิโภคี '
   'ให้ทำขวัญตัวก่อนจึงดี ลาภจักพูนมี เอนกล้ำเหลือประมาณ '
   'ฝันว่าเข้ากุฏิวิหาร อาวาสสถาน นิเวศแคว้นบริวง '
   'แห่งพระสยมพุทธพงศ์ จะเปลื้องทุกข์ปลง จะเรืองไชยเดชา '
   'ฝันว่ารูปพระปฏิมา หนึ่งพระจุฬา มณีซึ่งเป็นเจดีย์ '
   'หนึ่งได้เจรจาพาที กับใครก็ดี จะเรืองอุดมปรีดา',
   'หน้านี้รวมฝันที่เกี่ยวกับพุทธศาสนา และบอกให้ทำขวัญก่อนรับลาภ'),
  ('หน้า ๑๗ ส่วนคำทำนายฝันรายสัญลักษณ์', 17,
   'ฝันว่าอาจารย์ทิศา หนึ่งพราหมณจรรยา แม้นนึกสิ่งใดจะได้สม '
   'ฝันว่าเหาะลอยเทียมลม ลีลาศนิยม มาโดยอากาศเวหา '
   'เร่งให้ทำขวัญกายา จะยิ่งยศถา ปรากฏแก่ชนทั้งหลาย',
   'หน้าสุดท้ายของหมวดตำราทำนายฝัน จบด้วยเส้นคั่นกลางหน้า '
   'ถัดจากนี้เป็นหมวดคำทำนายสัตว์ตก')
) as v(locator, seq, orig, modern)
cross join content.edition e
where e.citekey = 'nlt-6238-2477'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- Readings. One insert per page so a locator typo cannot silently move a
-- reading onto the wrong passage.
-- ---------------------------------------------------------------------------

-- Values live in a CTE, not a temporary table. `create temporary table ... on
-- commit drop` survives in the Supabase SQL editor, which wraps a whole script
-- in one transaction, but under psql autocommit each statement is its own
-- transaction — the table would be dropped before the insert could read it, and
-- the seed would work in one runner and fail in the other.
with v(seq, concept_key, body, plain) as (values
(14,'DREAM_TURTLE',
 'ตำราว่าการฝันว่าได้เต่า ผู้ฝันจะมีข้าทาสบริวาร ได้ภรรยาที่ดี มีช้างและม้า '
 'ทั้งพี่น้องและบุตรจะมาหา และจะสมดังที่คิดตริตรองไว้',
 'ฝันว่าได้เต่า ตำราเก่าว่าจะมีคนช่วยงาน ได้คู่ที่ดี และสมหวังดังที่คิดไว้'),
(14,'DREAM_HORSE',
 'ตำราว่าการฝันว่าได้ม้าลำพอง เป็นนิมิตว่าผู้มีอำนาจสูงสุดจะยกย่องผู้ฝันขึ้นเป็นใหญ่',
 'ฝันว่าได้ม้าคึกคะนอง ตำราเก่าว่าจะมีผู้ใหญ่ยกย่องให้ได้ดี'),
(14,'DREAM_DRINK_WATER',
 'ตำราว่าการฝันว่าได้กินน้ำ ผู้ฝันจะได้คนมาอยู่ในความดูแล เลี้ยงไว้เสมือนลูกเมียของตน',
 'ฝันว่าได้กินน้ำ ตำราเก่าว่าจะได้คนมาอยู่ร่วมชายคาเป็นครอบครัว'),
(14,'DREAM_FIRE',
 'ตำราว่าการฝันว่าไฟไหม้ร้อนรน ไม่ได้ปล่อยไว้เป็นลางร้ายเฉย ๆ แต่สั่งให้รีบไปแก้ '
 'ที่แม่น้ำอันไหลริน แล้วมลทินจะค่อยบรรเทา โทษภัยจะผันกลับกลายเป็นชัยชนะ '
 'เป็นหน้าแรกที่ตำราให้ "วิธีแก้" ควบคู่กับคำทำนาย',
 'ฝันว่าไฟไหม้ ตำราเก่าไม่ได้ให้กลัวอย่างเดียว แต่บอกให้ไปแก้ที่แม่น้ำที่น้ำไหล '
 'แล้วเรื่องร้ายจะกลับกลายเป็นดี'),
(14,'DREAM_FLYING',
 'ตำราว่าการฝันว่าเดินไปกลางอากาศ ผู้ฝันคิดสิ่งใดก็จะได้ดังใจ',
 'ฝันว่าเดินอยู่กลางฟ้า ตำราเก่าว่าคิดอะไรไว้ก็จะได้ดังใจ'),
(15,'DREAM_RED_CLOTHES',
 'ตำราว่าการฝันว่านุ่งห่มสีแดง ให้เร่งระวังศัตรู และระมัดระวังร่างกายของตน '
 'เป็นคำเตือน ไม่ใช่คำอวยพร ตรงข้ามกับการฝันว่านุ่งขาวในหน้า ๑๓',
 'ฝันว่านุ่งห่มสีแดง ตำราเก่าว่าให้ระวังคนคิดร้าย และระวังตัวเองให้ดี'),
(15,'DREAM_MONK_ROBE',
 'ตำราว่าการฝันว่านุ่งห่มผ้ากาสาวพัสตร์ ผู้ฝันจะอยู่เป็นสุข ไม่มีผู้ใดมาเบียดเบียน',
 'ฝันว่าห่มผ้าเหลืองอย่างพระ ตำราเก่าว่าจะอยู่สบาย ไม่มีใครมาเบียดเบียน'),
(15,'DREAM_NOBLE_LADY',
 'ตำราว่าการฝันเห็นนางพญาผู้งดงาม แม้นมีผู้ใดถาม อย่าบอกอย่าเล่าให้ฟัง '
 'และให้แก้ที่กลางหาดทราย หรืออีกนัยหนึ่งให้แก้ที่ต้นไม้จึงจะดี',
 'ฝันเห็นนางพญาหรือหญิงงามสูงศักดิ์ ตำราเก่าว่าอย่าเล่าให้ใครฟัง '
 'และให้ไปแก้ที่หาดทรายหรือที่ต้นไม้'),
(15,'DREAM_LAMP',
 'ตำราว่าการฝันเห็นหญิงสาวพรหมจารีถือประทีปเทียนสว่างเข้ามาในเรือน '
 'ผู้ฝันจะมียศศักดิ์เหนือผู้คน จะได้เลื่อนตำแหน่งขึ้นเป็นพญา '
 'และหากผู้ฝันเป็นหญิงสาว จะได้สามีอันต้องใจ',
 'ฝันเห็นสาวถือเทียนสว่างเข้าบ้าน ตำราเก่าว่าจะได้เลื่อนยศเลื่อนตำแหน่ง '
 'ถ้าคนฝันเป็นหญิงสาวจะได้คู่ที่ถูกใจ'),
(16,'DREAM_CHANTING',
 'ตำราว่าการฝันว่าได้สวดพุทธมนต์ ผู้ฝันจะพ้นจากภัย จากเสนียดจัญไรและสิ่งเบียดเบียนทั้งปวง',
 'ฝันว่าได้สวดมนต์ ตำราเก่าว่าจะพ้นเคราะห์พ้นภัย'),
(16,'DREAM_PARASOL',
 'ตำราว่าการฝันว่าได้กั้นกลดกางร่มบังแดด เป็นความสุขสวัสดีและมีโภคทรัพย์ '
 'แต่ให้ทำขวัญตัวเสียก่อนจึงจะดี แล้วลาภจะพูนขึ้นมากมายเหลือประมาณ',
 'ฝันว่าได้กางร่มหรือกั้นกลด ตำราเก่าว่าจะอยู่ดีมีสุข แต่ให้ทำขวัญเสียก่อน '
 'แล้วลาภจะมามาก'),
(16,'DREAM_TEMPLE',
 'ตำราว่าการฝันว่าได้เข้าไปในกุฏิ วิหาร หรืออาวาสอันเป็นที่ประทับแห่งพระพุทธองค์ '
 'ผู้ฝันจะเปลื้องความทุกข์ลงได้ และจะรุ่งเรืองด้วยชัยชนะและเดชานุภาพ',
 'ฝันว่าได้เข้าวัดเข้าวิหาร ตำราเก่าว่าจะหมดทุกข์ และจะรุ่งเรืองขึ้น'),
(16,'DREAM_BUDDHA_IMAGE',
 'ตำราว่าการฝันเห็นพระปฏิมา หรือได้สนทนากับผู้ใดก็ตามในฝันนั้น '
 'ผู้ฝันจะรุ่งเรืองและอิ่มเอมยิ่ง',
 'ฝันเห็นพระพุทธรูป ตำราเก่าว่าจะรุ่งเรืองและมีความสุขใจ'),
(16,'DREAM_STUPA',
 'ตำราว่าการฝันเห็นพระจุฬามณีเจดีย์ จัดอยู่ในกลุ่มเดียวกับการฝันเห็นพระปฏิมา '
 'ผู้ฝันจะรุ่งเรืองและอิ่มเอมยิ่ง',
 'ฝันเห็นพระเจดีย์ ตำราเก่าว่าจะรุ่งเรืองและมีความสุขใจ'),
(17,'DREAM_TEACHER',
 'ตำราว่าการฝันเห็นครูอาจารย์ ผู้ฝันนึกสิ่งใดไว้ก็จะได้สมดังนั้น',
 'ฝันเห็นครูบาอาจารย์ ตำราเก่าว่าคิดหวังสิ่งใดไว้ก็จะสมหวัง'),
(17,'DREAM_BRAHMIN',
 'ตำราจัดการฝันเห็นพราหมณ์ผู้ทรงพรหมจรรย์ไว้ในกลุ่มเดียวกับการฝันเห็นครูอาจารย์ '
 'ผู้ฝันนึกสิ่งใดไว้ก็จะได้สมดังนั้น',
 'ฝันเห็นพราหมณ์ ตำราเก่าว่าคิดหวังสิ่งใดไว้ก็จะสมหวัง'),
(17,'DREAM_FLYING',
 'ตำราว่าการฝันว่าได้เหาะลอยไปตามลมกลางอากาศ ให้เร่งทำขวัญแก่ตัวเสียก่อน '
 'แล้วจะยิ่งด้วยยศถาบรรดาศักดิ์ ปรากฏแก่ผู้คนทั้งหลาย '
 'เป็นคนละรายการกับ "เดินกลางเวหา" ในหน้า ๑๔ ตามที่ตำราแยกไว้',
 'ฝันว่าเหาะลอยไปในอากาศ ตำราเก่าว่าให้ทำขวัญก่อน แล้วจะได้ยศได้ชื่อเสียง')
),
p as (
  select p.id, p.sequence from content.passage p
  join content.edition e on e.id = p.edition_id
  where e.citekey = 'nlt-6238-2477' and p.sequence between 14 and 17
),
tr as (select id from content.tradition where slug = 'folk-central')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id, v.body, v.plain, 'historical_belief',
  'เป็นความเชื่อที่บันทึกไว้ในตำรา พ.ศ. 2477 ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
  'และตำราเล่มนี้ไม่ได้ผูกเลขกับสัญลักษณ์เหล่านี้',
  '{}', 'published', now()
from v
join content.symbol s on s.concept_key = v.concept_key and s.status = 'published'
join p on p.sequence = v.seq
cross join tr
where not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.passage_id = p.id);

-- ---------------------------------------------------------------------------
-- Assert per page. A missing lexicon file would make these joins match nothing
-- and the closing count would still look healthy.
-- ---------------------------------------------------------------------------
do $$
declare r record;
begin
  for r in select * from (values (14,5),(15,4),(16,5),(17,3)) as x(seq, want) loop
    if (select count(*) from content.interpretation i
          join content.passage p on p.id = i.passage_id
          join content.edition e on e.id = p.edition_id
         where e.citekey = 'nlt-6238-2477' and p.sequence = r.seq
           and i.status = 'published') <> r.want then
      raise exception 'content set 9: หน้า % expected % readings, found % '
        '(run dream_symbols_v8_p14_p17.sql first)', r.seq, r.want,
        (select count(*) from content.interpretation i
           join content.passage p on p.id = i.passage_id
           join content.edition e on e.id = p.edition_id
          where e.citekey = 'nlt-6238-2477' and p.sequence = r.seq
            and i.status = 'published');
    end if;
  end loop;
end $$;

do $$
declare r record; bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then bad := bad + 1; end if;
  end loop;
  if bad > 0 then raise exception 'aborted: % rights invariant(s)', bad; end if;
end $$;

select
  (select count(*) from content.interpretation where status='published') as published_interpretations,
  (select count(*) from content.symbol where status='published')         as published_symbols;
