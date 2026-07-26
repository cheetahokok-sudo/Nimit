-- ============================================================================
-- First real content: มหาสุบินชาดก — the sixteen dreams of King Pasenadi
--
-- Every rule this library was built around is exercised here, deliberately:
--
--   * The passage quotes the CANONICAL VERSE verbatim — legal because the work
--     row (updated in sources_v4) is public_domain; the firewall CHECK admits
--     the text only for that reason. Try this against a copyrighted work and
--     the INSERT fails.
--   * body_th is ORIGINAL PROSE composed after reading the actual text at
--     84000.org (canonical verse + อรรถกถา) in a browser session on
--     2026-07-26. The อรรถกถา translation (มหามกุฏฯ) remains copyrighted, so
--     its wording is never reproduced — only the attested MEANINGS, which are
--     textual facts about a 2,000-year-old work.
--   * Corroborated by an independent scholarly source (two-source rule),
--     even though a PD passage does not strictly require it.
--   * claim_type='historical_belief' — these are what the TEXT says the
--     dreams mean, clearly separated from fact and from modern opinion.
--   * ZERO number associations, permanently. The registry rule for this
--     source: Buddhist literature must never be presented as lottery
--     guidance. The context notes carry that framing to the reader.
--
-- The frame that matters culturally: in this jataka the dreams are omens of a
-- distant degenerate age, explicitly NOT personal fortune — and the story's
-- point is the Buddha stopping a sacrificial slaughter that self-interested
-- interpreters had prescribed. It is, among other things, a warning about
-- fortune-tellers with a business model. A fitting first entry for this app.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- The passage: canonical verse [๗๗], ฉบับหลวง as displayed by 84000.org
-- ---------------------------------------------------------------------------

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id,
  'เล่ม ๒๗ ข้อ ๗๗ บรรทัด ๕๐๒–๕๐๙ หน้า ๒๖', 1,
  'หม่อมฉันได้ฝันเห็นโคอุสุภราช ๑ ต้นไม้ ๑ แม่โค ๑ โคสามัญ ๑ ม้า ๑ '
  'ถาดทองคำ ๑ สุนัขจิ้งจอก ๑ หม้อน้ำ ๑ สระโบกขรณี ๑ ข้าวสารที่หุงไม่สุก ๑ '
  'แก่นจันทน์ ๑ น้ำเต้าจมน้ำ ๑ หินลอยน้ำ ๑ นางเขียดกลืนกินงูเห่า ๑ '
  'หงส์ทองแวดล้อมกา ๑ เสือกลัวแพะ ๑ ดังนี้ ปริยายอันผิดจะเป็นไปในยุคนี้ ยังไม่สำเร็จ.',
  'คาถาสรุปมหาสุบิน ๑๖ ประการที่พระเจ้าปเสนทิโกศลกราบทูลพระพุทธเจ้า: '
  'ความฝันทั้งสิบหกเป็นนิมิตของยุคเสื่อมในอนาคตอันไกล มิใช่ลางร้ายของผู้ฝันเอง',
  'คัดจากการแสดงผลของ 84000.org (อ้างพระไตรปิฎกฉบับหลวง) โดยการอ่านหน้าเว็บโดยตรง',
  'ตรวจทานกับหน้า v.php?B=27&A=502&Z=509 เมื่อ 26 ก.ค. 2569; '
  'อักขรวิธีตามการแสดงผลของเว็บ ยังไม่ได้เทียบกับฉบับพิมพ์กระดาษ',
  'published'
from content.edition e where e.citekey = 'tipitaka-27-77'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- Interpretations: five dream omens that map to already-indexed symbols
-- ---------------------------------------------------------------------------

with p as (
  select p.id from content.passage p
  join content.edition e on e.id = p.edition_id
  where e.citekey = 'tipitaka-27-77' limit 1
),
tr as (select id from content.tradition where slug = 'buddhist-canon'),
corr as (
  select array[e.id] as ids from content.edition e
  where e.citekey = 'thaijo-apbj-249166'
)
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id, v.body_th, 'historical_belief',
  'ในวรรณกรรมพุทธ ความฝันชุดนี้เป็นคำพยากรณ์ถึงสังคมในยุคเสื่อมอันไกล '
  'ไม่ใช่ลางบอกโชคลาภหรือเคราะห์ของผู้ฝัน และเรื่องนี้จบลงที่พระพุทธเจ้าทรงให้ '
  'เลิกพิธีบูชายัญที่ผู้ทำนายแสวงประโยชน์เสนอไว้ — จึงไม่ควรนำไปโยงกับการเสี่ยงโชคโดยเด็ดขาด',
  corr.ids, 'published', now()
from (values

  ('DREAM_SNAKE',
   'ในมหาสุบินชาดก งูเห่าปรากฏในนิมิตข้อที่สิบสี่: ฝูงเขียดตัวเล็กไล่กวดและกลืนกิน '
   'งูเห่าตัวใหญ่ ตัวบทอธิบายว่าเป็นภาพของยุคที่ลำดับอำนาจกลับตาลปัตร — '
   'ผู้ที่ดูอ่อนแอกว่ากลับครอบงำผู้มีกำลัง ดังบุรุษผู้ตกอยู่ในอำนาจภรรยาเด็ก '
   'งูในบริบทนี้จึงเป็นสัญลักษณ์ของพลังอำนาจที่ถูกพลิกกลับ ไม่ใช่ลางเนื้อคู่หรือโชคลาภ '
   'อย่างที่ตำราทำนายฝันพื้นบ้านมักตีความ'),

  ('DREAM_TREE',
   'นิมิตข้อที่สอง: ต้นไม้เล็กและกอไผ่ที่โผล่พ้นดินเพียงคืบศอกก็ผลิดอกออกผลเสียแล้ว '
   'ตัวบทอธิบายว่าเป็นภาพของยุคที่ผู้คนเติบโตและมีภาระเกินวัย — '
   'เด็กสาวที่ยังไม่ถึงวัยอันควรก็มีครรภ์มีบุตร ต้นไม้ที่ออกผลก่อนกำหนด '
   'จึงเป็นภาพของความรีบร้อนผิดธรรมชาติ ความอุดมที่มาก่อนเวลาไม่ใช่ลางดีในบริบทนี้'),

  ('DREAM_RICE',
   'นิมิตข้อที่สิบ: ข้าวในหม้อเดียวกันสุกไม่เท่ากัน — ส่วนหนึ่งแฉะ ส่วนหนึ่งดิบ '
   'ส่วนหนึ่งสุกดี ตัวบทอธิบายว่าเมื่อผู้ปกครองไม่ตั้งอยู่ในธรรม ฝนฟ้าจะไม่สม่ำเสมอ '
   'ที่หนึ่งท่วม ที่หนึ่งแล้ง ที่หนึ่งพอดี ผลผลิตในแผ่นดินเดียวกันจึงได้สามอย่าง '
   'ข้าวที่หุงไม่ทั่วหม้อเป็นภาพของความไม่เสมอภาคทั่วแผ่นดิน ไม่ใช่เรื่องโชคของครัวเรือน'),

  ('DREAM_WATER',
   'น้ำปรากฏสองนิมิตติดกัน ข้อแปด: ตุ่มน้ำที่เต็มแล้วแต่ผู้คนยังขนน้ำมาเทจนล้น '
   'ขณะตุ่มเปล่ารายรอบไม่มีใครเหลียวแล — ภาพของทรัพยากรที่ไหลไปกองอยู่กับผู้มีอำนาจ '
   'ข้อเก้า: สระบัวที่ขุ่นตรงกลางแต่ใสตามริมฝั่งที่ฝูงสัตว์เหยียบย่ำ — '
   'ภาพของศูนย์กลางอำนาจที่บีบคั้นจนผู้คนอพยพไปตั้งหลักแหล่งชายแดน '
   'น้ำในชาดกนี้จึงพูดเรื่องความเป็นธรรมของการแบ่งปัน ไม่ใช่โชคลาภจากสายน้ำ'),

  ('DREAM_GOLD',
   'นิมิตข้อที่หก: มหาชนขัดถาดทองคำราคาแสนกษาปณ์แล้วยกให้สุนัขจิ้งจอกแก่ถ่ายปัสสาวะใส่ '
   'ตัวบทอธิบายว่าเป็นภาพของยุคที่ของสูงค่าตกไปอยู่ในมือผู้ไม่คู่ควร — '
   'ตระกูลสูงต้องยกธิดาให้ผู้ไร้สกุลเพื่อความอยู่รอด ทองในนิมิตนี้เป็นเครื่องวัดว่า '
   'สังคมยังรู้ค่าของสิ่งมีค่าหรือไม่ มิใช่ลางว่าจะได้ลาภ')

) as v(concept_key, body_th)
join content.symbol s on s.concept_key = v.concept_key
cross join p cross join tr cross join corr
where not exists (
  select 1 from content.interpretation i
  where i.symbol_id = s.id and i.passage_id = p.id
);

-- ---------------------------------------------------------------------------
-- Review provenance: who checked this, honestly stated
-- ---------------------------------------------------------------------------

insert into content.review (entity_type, entity_id, role, reviewer, verdict, note_th)
select 'interpretation', i.id, 'editorial',
  'Claude (AI) — อ่านตัวบทจริงจาก 84000.org ฉบับหลวง 26 ก.ค. 2569',
  'checked',
  'ตรวจว่า body_th เป็นสำนวนเรียบเรียงใหม่ตรงตามเนื้อความอรรถกถา ไม่คัดลอกคำแปลที่มีลิขสิทธิ์ '
  'และ locator ชี้ตำแหน่งที่ตรวจสอบได้จริง — ยังควรได้รับการทานซ้ำโดยผู้เชี่ยวชาญพุทธศาสน์'
from content.interpretation i
join content.passage p on p.id = i.passage_id
join content.edition e on e.id = p.edition_id
where e.citekey = 'tipitaka-27-77'
  and not exists (
    select 1 from content.review r
    where r.entity_type = 'interpretation' and r.entity_id = i.id
  );

-- ---------------------------------------------------------------------------
-- Gate: refuse to leave an inconsistent state behind
-- ---------------------------------------------------------------------------

do $$
declare r record; bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then
      raise warning 'invariant % : % violations', r.check_name, r.violations;
      bad := bad + 1;
    end if;
  end loop;
  if bad > 0 then
    raise exception 'interpretations_v1 aborted: % invariant(s) violated', bad;
  end if;
end $$;

select
  (select count(*) from content.interpretation where status = 'published') as interpretations_published,
  (select count(*) from content.passage where status = 'published') as passages_published,
  (select count(*) from content.number_association) as number_associations_ever;
