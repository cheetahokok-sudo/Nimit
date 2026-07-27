-- ============================================================================
-- Content set 8: ประมวลตำราทำนาย ภาค ๑ หน้า ๑๓
--
-- Two things appear here that no earlier page had.
--
-- GENDER-DIFFERENTIATED READINGS. The gold-ring omen splits three ways: an
-- unmarried woman will get a husband, a married one will get children, a man
-- will get a wife. Recorded as written. The app has no gender field and this
-- content does not add one — the reading states the ตำรา's conditions and lets
-- the reader locate themselves, which is also the honest way to carry a belief
-- whose categories are not ours.
--
-- AN INVERSION. Dreaming of one's hands bound in chains and fetters is
-- auspicious: a noble will come to rule a city, a commoner will come to be well
-- off. Worth noting because it is exactly the sort of reading a modern reader
-- would guess backwards, and it is the reason this library quotes ตำรา rather
-- than reasoning from the imagery.
--
-- แหวน already carries a หน้า ๑๒ reading. This is a SECOND reading on a
-- different passage rather than a replacement — two pages of the same book
-- saying related things is normal, and the app shows both with their locators.
-- ============================================================================

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'published', now()
from (values
  ('DREAM_BOUND',        'bound',        'ถูกมัด โซ่ตรวน', 'bound in chains',  'dream-symbols'),
  ('DREAM_WHITE_CLOTHES','white-clothes','นุ่งขาว',        'wearing white',    'dream-symbols')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('DREAM_BOUND','ถูกมัด','primary',100),
  ('DREAM_BOUND','โซ่ตรวน','synonym',96),
  ('DREAM_BOUND','ถูกล่ามโซ่','synonym',95),
  ('DREAM_BOUND','มัดมือ','synonym',94),
  ('DREAM_WHITE_CLOTHES','นุ่งขาว','primary',100),
  ('DREAM_WHITE_CLOTHES','ใส่ชุดขาว','synonym',95),
  ('DREAM_WHITE_CLOTHES','นุ่งขาวห่มขาว','synonym',96)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, 'หน้า ๑๓ ส่วนคำทำนายฝันรายสัญลักษณ์', 13,
  'ฝันว่ากินโภชนา กับบุตรภรรยา แลกินกับพี่น้องตน '
  'กินกับพ่อแม่พึงยล จะได้ศุภผล อยู่สุขสวัสดิสมปอง '
  'ถ้าฝันว่าใส่แหวนทอง แม้นหญิงสายยอง เปลือยเปล่าจะได้สามี '
  'ถ้าผัวมีแล้วสมศรี จะได้บุตรี บุตราอันพึงพอใจ '
  'ชายฝันจะได้อรทัย เมียมิ่งพิศมัย ประไพประพักตรพึงชม '
  'ฝันว่านุ่งขาวงามสม สาวจักนิยม มายั่วมาเย้าใส่ใจ '
  'ฝันว่ามัดมือโดยใน โซ่ตรวนแลเครื่องพันธนา '
  'แม้นขุนจะครองนัครา ถ้าไพร่ทรพา ทรพลจะได้เป็นดี',
  'หน้านี้ให้คำทำนายรายสัญลักษณ์ต่อจากหน้า ๑๒ '
  'และเป็นหน้าแรกที่แยกคำทำนายตามเพศและตามสถานะของผู้ฝัน',
  'Claude (AI) — อ่านจากภาพสแกน D-Library 6238 เมื่อ 27 ก.ค. 2569',
  'คงอักขรวิธีฉบับ พ.ศ. 2477 ไว้ตามต้นฉบับ; หน้าเรียงสองคอลัมน์ '
  'อ่านซ้ายแล้วขวาเป็นบรรทัด ๆ | ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สอง (double-key) '
  'ตามระเบียบ B5',
  'published'
from content.edition e where e.citekey = 'nlt-6238-2477'
on conflict (edition_id, locator, sequence) do nothing;

with p as (select p.id from content.passage p join content.edition e on e.id = p.edition_id
            where e.citekey = 'nlt-6238-2477'
              and p.locator = 'หน้า ๑๓ ส่วนคำทำนายฝันรายสัญลักษณ์' limit 1),
tr as (select id from content.tradition where slug = 'folk-central')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id, v.body, v.plain, 'historical_belief',
  'เป็นความเชื่อที่บันทึกไว้ในตำรา พ.ศ. 2477 ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
  'และตำราเล่มนี้ไม่ได้ผูกเลขกับสัญลักษณ์เหล่านี้',
  '{}', 'published', now()
from (values
  ('DREAM_EATING',
   'ตำราว่าการฝันว่าได้กินอาหารร่วมกับบุตรภรรยา กับพี่น้อง หรือกับบิดามารดา '
   'ผู้ฝันจะได้ผลอันเป็นมงคล อยู่เป็นสุขสวัสดีสมดังปรารถนา',
   'ฝันว่ากินข้าวกับครอบครัว ตำราเก่าว่าเป็นฝันดี จะอยู่เย็นเป็นสุขสมหวัง'),
  ('DREAM_RING',
   'ตำราหน้านี้แยกคำทำนายแหวนทองตามผู้ฝัน: หญิงที่ยังไม่มีคู่จะได้สามี '
   'หญิงที่มีสามีแล้วจะได้บุตรธิดาอันเป็นที่พอใจ ส่วนชายจะได้ภรรยาที่งดงามน่าชม '
   'เป็นการแยกตามเพศและสถานะตามที่ตำราระบุไว้ ไม่ใช่การตีความเพิ่ม',
   'ฝันว่าใส่แหวนทอง ตำราเก่าแยกไว้ว่า หญิงโสดจะได้คู่ หญิงมีคู่แล้วจะได้ลูก ชายจะได้ภรรยา'),
  ('DREAM_WHITE_CLOTHES',
   'ตำราว่าการฝันว่านุ่งขาวห่มขาวดูงดงาม จะเป็นที่นิยมชมชอบของหญิงสาว '
   'มีผู้มาทักทายเย้าแหย่ด้วยความเอ็นดู',
   'ฝันว่านุ่งขาวสวยงาม ตำราเก่าว่าจะเป็นที่ชอบใจของผู้คนรอบข้าง'),
  ('DREAM_BOUND',
   'ตำราว่าการฝันว่าถูกมัดมือด้วยโซ่ตรวนหรือเครื่องพันธนาการ เป็นนิมิตฝ่ายดี '
   'ไม่ใช่ลางร้าย: ผู้มียศจะได้ครองบ้านเมือง ส่วนสามัญชนจะได้ดีมีฐานะขึ้น '
   'เป็นคำทำนายที่กลับทางกับภาพในฝัน ซึ่งเป็นเหตุผลที่ต้องอ้างตำราแทนการเดาจากภาพ',
   'ฝันว่าถูกมัดหรือถูกล่ามโซ่ ตำราเก่าว่าไม่ใช่ลางร้าย กลับเป็นลางว่าจะได้ดีมีฐานะขึ้น')
) as v(concept_key, body, plain)
join content.symbol s on s.concept_key = v.concept_key and s.status = 'published'
cross join p cross join tr
where not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.passage_id = (select id from p));

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
