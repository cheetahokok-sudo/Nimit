-- ============================================================================
-- Content set 6: คำทำนายฝัน — ประมวลตำราทำนาย (ของเก่า) ภาค ๑, พ.ศ. 2477
--
-- The dream section itself, pp. ๔–๑๐. This is the first content that speaks to
-- the app's CORE loop: someone types a dream and gets a sourced reading. Until
-- now the library answered dreams with 19 interpretations across 81 symbols,
-- so most dreams returned "พบสัญลักษณ์ แต่ยังไม่มีคำแปล".
--
-- HOW THIS SECTION IS STRUCTURED, AND WHY A READING IS DEFENSIBLE
--
-- Each Pali คาถา is followed by a Thai กาพย์ gloss. The verses do not give a
-- verdict per symbol; they enumerate dream images, and the section states its
-- verdict COLLECTIVELY. It says so twice, explicitly:
--
--   หน้า ๖  "…สะมนุษย์ในสุบิน  จะเสพยสุขสวัสดี"
--   หน้า ๑๐ "จะปราศจากทุกข  ทั้งโรคไภยบพึงมี
--            สมคิดประสิทธิ์  แลประเสริฐเป็นมงคล ฯ"
--
-- So the claim recorded here is exactly what the book claims and no more: this
-- ตำรา places the image among นิมิตมงคล, and closes by saying the dreamer will
-- be free of suffering, illness and fear, and will have their wishes prosper.
-- That is a reading OF the source, not an inference about each animal.
--
-- WHY original_text_th IS NULL ON MOST PASSAGES
--
-- The work is public domain and the firewall would admit verbatim text. But the
-- pages are set in TWO COLUMNS, and reconstructing line order from the images
-- is not reliable enough to store as "the original text" — a garbled verse
-- presented as a faithful quote is worse than no quote. Only หน้า ๑๐, whose
-- closing verse is short and unambiguous, carries verbatim text. Lawful and
-- accurate are different tests and both have to pass.
--
-- NUMBERS: none. This source predates the lottery number convention entirely.
-- ============================================================================

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, v.locator, v.seq, v.orig, v.modern,
  'Claude (AI) — อ่านจากภาพสแกน D-Library 6238 เมื่อ 27 ก.ค. 2569',
  'อ่านและสรุปจากภาพหน้าหนังสือ; หน้าเรียงเป็นสองคอลัมน์ จึงยังไม่เก็บข้อความ '
  'ต้นฉบับแบบคำต่อคำ ยกเว้นบทสรุปหน้า ๑๐ ซึ่งอ่านลำดับบรรทัดได้ชัดเจน | '
  'ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สอง (double-key) ตามระเบียบ B5',
  'published'
from (values
  ('หน้า ๔ ส่วนคำทำนายฝัน', 4, null,
   'บัญชีนิมิตหมวดแรก: เทวดา พระอาทิตย์ พระจันทร์ ดวงดาว ปราสาท แก้วมณี '
   'พระราชาและพระอัครมเหสี'),
  ('หน้า ๕ ส่วนคำทำนายฝัน', 5, null,
   'บัญชีนิมิต: แท่นอาสน์และเตียงตั่ง การขึ้นภูเขาสู่สรวงสวรรค์ '
   'เสียงฆ้อง กลอง แตร สังข์ และดุริยางค์ การนมัสการพระวิหารเจดีย์และพระปฏิมา '
   'ตลอดจนการได้ทรงจักรอาวุธ'),
  ('หน้า ๖ ส่วนคำทำนายฝัน', 6, null,
   'บัญชีนิมิต: ขี่ช้าง ม้า และรถ พบโค โคอุสภ ราชสีห์ หมู่นก และพญานาค '
   'ได้ดื่มน้ำผึ้ง น้ำอ้อย น้ำนมและนมส้ม จนถึงช้างเผือกเอราวัณ ฉัตร ธงทอง '
   'และกลิ่นดอกปทุม | หน้านี้ระบุผลไว้ตรง ๆ ว่า "สะมนุษย์ในสุบิน จะเสพยสุขสวัสดี"'),
  ('หน้า ๘ ส่วนคำทำนายฝัน', 8, null,
   'บัญชีนิมิต: กระต่ายในดงรัง จระเข้ นกยูง งู เต่าและปลา การได้พบครู '
   'การเหาะไปในอากาศ การได้นารีและพวงมาลา การกินใบไม้และผลไม้ '
   'ตลอดจนไม้จันทน์แดงและรากเหง้าดอกปทุม'),
  ('หน้า ๑๐ ส่วนคำทำนายฝัน (บทสรุป)', 10,
   'นิราสะทุกขา นิภยา อะโรคัง ปะสิทธิกัมมัง ปัฏฐะนัญจะวุฑฒํ '
   'จะปราศจากทุกข ทั้งโรคไภยบพึงมี สมคิดประสิทธิ์ แลประเสริฐเป็นมงคล ฯ',
   'บทปิดหมวดคำทำนายฝัน สรุปผลของนิมิตทั้งหมดที่ไล่เรียงมาว่า '
   'ผู้ฝันจะปราศจากทุกข์ ไม่มีโรคภัยและความกลัว สมความคิด และเป็นมงคล')
) as v(locator, seq, orig, modern)
cross join content.edition e
where e.citekey = 'nlt-6238-2477'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- Readings. Every body_th says the same thing in substance, because the source
-- says the same thing about every image in the list — the honest shape of this
-- content is a catalogue with one shared verdict, and pretending each animal
-- has its own distinct fortune would be inventing detail the ตำรา never gave.
-- What differs per row is WHICH image, on WHICH page.
-- ---------------------------------------------------------------------------

with tr as (select id from content.tradition where slug = 'folk-central'),
ed as (select id from content.edition where citekey = 'nlt-6238-2477')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id,
  'ตำราประมวลตำราทำนาย ภาค ๑ (พ.ศ. 2477) จัด' || v.phrase ||
  'ไว้ในบัญชีนิมิตมงคล ท้ายหมวดสรุปรวมไว้ว่าผู้ที่ฝันเห็นนิมิตในบัญชีนี้ '
  'จะปราศจากทุกข์ ไม่มีโรคภัยและความกลัว สมความคิด และเป็นมงคล ' ||
  'ตำราไม่ได้แยกคำทำนายเป็นรายสัญลักษณ์ แต่ให้ผลรวมไว้อย่างเดียวกันทั้งหมวด',
  'ตำราเก่าปี 2477 นับ' || v.phrase || 'เป็นฝันดี '
  'ท้ายบทบอกว่าคนที่ฝันแบบนี้จะพ้นทุกข์ พ้นโรค และสมหวัง',
  'historical_belief',
  'เป็นความเชื่อที่บันทึกไว้ในตำรา พ.ศ. 2477 ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
  'และตำราเล่มนี้ไม่ได้ผูกเลขใด ๆ กับนิมิตเหล่านี้',
  '{}', 'published', now()
from (values
  ('DREAM_SUN',          'หน้า ๔ ส่วนคำทำนายฝัน', 'การฝันเห็นดวงอาทิตย์'),
  ('DREAM_MOON',         'หน้า ๔ ส่วนคำทำนายฝัน', 'การฝันเห็นดวงจันทร์'),
  ('DREAM_STAR',         'หน้า ๔ ส่วนคำทำนายฝัน', 'การฝันเห็นดวงดาว'),
  ('DREAM_MOUNTAIN',     'หน้า ๕ ส่วนคำทำนายฝัน', 'การฝันว่าได้ขึ้นภูเขา'),
  ('DREAM_PAGODA',       'หน้า ๕ ส่วนคำทำนายฝัน', 'การฝันว่าได้นมัสการพระวิหารเจดีย์'),
  ('DREAM_BUDDHA_IMAGE', 'หน้า ๕ ส่วนคำทำนายฝัน', 'การฝันว่าได้นบพระปฏิมา'),
  ('DREAM_ELEPHANT',     'หน้า ๖ ส่วนคำทำนายฝัน', 'การฝันว่าได้ขี่ช้าง'),
  ('DREAM_HORSE',        'หน้า ๖ ส่วนคำทำนายฝัน', 'การฝันว่าได้ขี่ม้า'),
  ('DREAM_BIRD',         'หน้า ๖ ส่วนคำทำนายฝัน', 'การฝันเห็นหมู่นก'),
  ('DREAM_NAGA',         'หน้า ๖ ส่วนคำทำนายฝัน', 'การฝันเห็นพญานาค'),
  ('DREAM_EATING',       'หน้า ๖ ส่วนคำทำนายฝัน', 'การฝันว่าได้ดื่มกินน้ำผึ้ง น้ำอ้อยและน้ำนม'),
  ('DREAM_CROCODILE',    'หน้า ๘ ส่วนคำทำนายฝัน', 'การฝันเห็นจระเข้'),
  ('DREAM_SNAKE',        'หน้า ๘ ส่วนคำทำนายฝัน', 'การฝันเห็นงู'),
  ('DREAM_TURTLE',       'หน้า ๘ ส่วนคำทำนายฝัน', 'การฝันเห็นเต่า'),
  ('DREAM_FISH',         'หน้า ๘ ส่วนคำทำนายฝัน', 'การฝันเห็นปลา'),
  ('DREAM_FLYING',       'หน้า ๘ ส่วนคำทำนายฝัน', 'การฝันว่าได้เหาะไปในอากาศ'),
  ('DREAM_FLOWER',       'หน้า ๘ ส่วนคำทำนายฝัน', 'การฝันเห็นดอกปทุมและพวงมาลา'),
  ('DREAM_FRUIT',        'หน้า ๘ ส่วนคำทำนายฝัน', 'การฝันว่าได้กินผลไม้')
) as v(concept_key, locator, phrase)
join content.symbol s on s.concept_key = v.concept_key and s.status = 'published'
join ed on true
join content.passage p on p.edition_id = ed.id and p.locator = v.locator
cross join tr
where not exists (
  select 1 from content.interpretation i
  where i.symbol_id = s.id and i.passage_id = p.id
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
  (select count(*) from content.number_association where status = 'published') as published_numbers;
