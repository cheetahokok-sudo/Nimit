-- ============================================================================
-- Content set 2: สุบินสูตร — the five great dreams of the Bodhisatta
-- (อังคุตตรนิกาย ปัญจกนิบาต, พระไตรปิฎกเล่ม ๒๒ ข้อ ๑๙๖)
--
-- Read directly from 84000.org in a browser session on 2026-07-26; the page
-- states การแสดงผลอ้างอิงพระไตรปิฎกฉบับหลวง — same s.23 public-domain
-- determination as the Mahasupina Jataka (sources_v4).
--
-- This text is special: unlike the jataka, THE MEANINGS ARE IN THE CANONICAL
-- TEXT ITSELF — the sutta's second half states what each dream was a นิมิต of.
-- No commentary layer is needed, so every claim here derives entirely from
-- public-domain text.
--
-- Editorial value: these five dreams are AUSPICIOUS (omens of the awakening),
-- where the Pasenadi sixteen are omens of decline. Two canonical sources now
-- give the same symbols different valences — which is precisely the point the
-- product exists to show: แต่ละแหล่งตีความไม่เหมือนกัน, and an honest library
-- presents them side by side instead of flattening them into one answer.
--
-- Zero number associations, as with all Buddhist canonical text. Permanent.
-- ============================================================================

-- Work + edition
insert into content.work
  (slug, canonical_title_th, attributed_author_th, composed_period_th,
   rights, pd_basis, copyright_holder, rights_note_th, status)
values
  ('subina-sutta', 'สุบินสูตร (มหาสุบิน ๕ ของพระโพธิสัตว์)',
   null, 'พระสูตรในพระไตรปิฎก',
   'public_domain', 'government_work_50y', null,
   'ตัวพระสูตรเป็นวรรณกรรมโบราณ; คำแปลไทยที่ใช้คือพระไตรปิฎกฉบับหลวง '
   '(กรมการศาสนา พ.ศ. 2500) พ้นอายุคุ้มครองตามมาตรา 23 ราว พ.ศ. 2550 — '
   'ใช้การพิจารณาเดียวกับ mahasupina-jataka; ข้อควรระวังเรื่องฉบับพิมพ์แก้ไข '
   'ใช้ร่วมกัน | จุดพิเศษ: ความหมายของฝันอยู่ในตัวพระสูตรเอง ไม่ต้องพึ่งอรรถกถา',
   'published')
on conflict (slug) do update set rights_note_th = excluded.rights_note_th;

insert into content.edition
  (work_id, citekey, tier, label_th, custodian_th, stable_identifier,
   physical_desc_th, languages, url, custodian_rights, rights_note_th, status)
select w.id, 'tipitaka-22-196', 'a2',
       'พระไตรปิฎกเล่ม ๒๒ ข้อ ๑๙๖', '84000.org (อ้างฉบับหลวง)',
       'ข้อ ๑๙๖ บรรทัด ๕๕๘๓–๕๖๓๔', 'HTML', array['th'],
       'https://84000.org/tipitaka/read/byitem.php?book=22&item=196&items=1',
       'unknown',
       'หน้าเว็บระบุว่าอ้างอิงฉบับหลวง; เงื่อนไขการใช้ของเว็บไม่ชัดเจน '
       'แต่ตัวข้อความที่พ้นลิขสิทธิ์ไม่ผูกกับสิทธิ์ของผู้จัดทำเว็บ',
       'published'
from content.work w where w.slug = 'subina-sutta'
on conflict (citekey) do nothing;

-- Passage: the canonical enumeration of the five dreams, verbatim (PD)
insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id,
  'เล่ม ๒๒ ข้อ ๑๙๖ บรรทัด ๕๕๘๓–๕๖๓๔ หน้า ๒๔๓–๒๔๕', 1,
  '[๑๙๖] ดูกรภิกษุทั้งหลาย มหาสุบิน ๕ ประการ ปรากฏแก่ตถาคตอรหันตสัมมาสัมพุทธะ '
  'ก่อนแต่ตรัสรู้ ยังไม่ได้ตรัสรู้ ยังเป็นโพธิสัตว์อยู่ ๕ ประการเป็นไฉน คือ '
  'แผ่นดินใหญ่นี้เป็นที่นอนใหญ่ ขุนเขาหิมวันต์เป็นเขนย มือซ้ายหย่อนลงในสมุทรด้านทิศบูรพา '
  'มือขวาหย่อนลงในสมุทรด้านทิศประจิม เท้าทั้งสองหย่อนลงในสมุทรด้านทิศทักษิณ ... '
  'หญ้าคาได้ขึ้นจากนาภี ... จดท้องฟ้า ตั้งอยู่ ... หมู่หนอนมีสีขาว ศีรษะดำ ได้ไต่ขึ้นมาจากเท้า '
  '... ปกปิดตลอดถึงชานุมณฑล ... นกสี่เหล่ามีสีต่างๆ กัน บินมาจากทิศทั้งสี่ ตกลงแทบเท้า '
  '... แล้วกลับกลายเป็นสีขาวทุกตัว ... เดินไปมาบนภูเขาคูถลูกใหญ่ (แต่) ไม่แปดเปื้อนคูถ',
  'พระสูตรว่าด้วยมหาสุบิน ๕ ประการของพระโพธิสัตว์ก่อนตรัสรู้ พร้อมคำอธิบายในตัวพระสูตรเอง '
  'ว่าแต่ละข้อเป็นนิมิตแห่งการตรัสรู้และความเจริญของพระศาสนา',
  'คัดจากการแสดงผลของ 84000.org (อ้างพระไตรปิฎกฉบับหลวง) โดยการอ่านหน้าเว็บโดยตรง',
  'ตรวจทานกับ byitem.php?book=22&item=196 เมื่อ 26 ก.ค. 2569; '
  'คัดเฉพาะท่อนแจกแจงมหาสุบิน ๕ (ตัดด้วย ...) เพื่อความกระชับ ข้อความเต็มดูตามตัวชี้',
  'published'
from content.edition e where e.citekey = 'tipitaka-22-196'
on conflict (edition_id, locator, sequence) do nothing;

-- Interpretations: four symbols, meanings from the sutta's own second half
with p as (
  select p.id from content.passage p
  join content.edition e on e.id = p.edition_id
  where e.citekey = 'tipitaka-22-196' limit 1
),
tr as (select id from content.tradition where slug = 'buddhist-canon')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id, v.body_th, 'historical_belief',
  'มหาสุบินชุดนี้เป็นนิมิตมงคลก่อนการตรัสรู้ — ต่างจากมหาสุบิน ๑๖ ของพระเจ้าปเสนทิโกศล '
  'ที่เป็นลางของยุคเสื่อม สัญลักษณ์เดียวกันจึงมีความหมายต่างกันตามแหล่ง '
  'และเช่นเดียวกับพุทธวรรณกรรมทั้งหมดในคลังนี้ ไม่เกี่ยวข้องกับการเสี่ยงโชคใด ๆ',
  '{}', 'published', now()
from (values

  ('DREAM_SEA',
   'ในสุบินสูตร มหาสมุทรปรากฏในมหาสุบินข้อแรกของพระโพธิสัตว์: ทรงฝันว่าแผ่นดินใหญ่ '
   'เป็นที่บรรทม ขุนเขาหิมวันต์เป็นเขนย พระหัตถ์และพระบาทหย่อนลงในมหาสมุทรทั้งสามทิศ '
   'ตัวพระสูตรอธิบายเองว่านิมิตนี้หมายถึงการที่จะได้ตรัสรู้พระสัมมาสัมโพธิญาณอันไม่มีธรรมอื่น '
   'ยิ่งกว่า — ทะเลในบริบทนี้เป็นภาพของความยิ่งใหญ่ที่ผู้ฝันจะหยั่งถึง'),

  ('DREAM_MOUNTAIN',
   'ภูเขาปรากฏสองแห่งในสุบินสูตร: ขุนเขาหิมวันต์เป็นเขนยในข้อแรก และในข้อห้า '
   'ทรงฝันว่าเดินไปมาบนภูเขาคูถลูกใหญ่โดยไม่แปดเปื้อน ตัวพระสูตรอธิบายข้อหลังว่า '
   'เป็นนิมิตของการได้รับลาภสักการะมากมายแล้วไม่ลุ่มหลงติดพัน ใช้สอยด้วยปัญญาเห็นโทษ — '
   'ภูเขาจึงเป็นได้ทั้งที่พำนักอันมั่นคงและกองสิ่งเย้ายวนที่ต้องเดินผ่านโดยไม่จมลงไป'),

  ('DREAM_INSECT',
   'ในมหาสุบินข้อสาม หมู่หนอนสีขาวศีรษะดำไต่ขึ้นจากพระบาทถึงพระชานุ (เข่า) '
   'ตัวพระสูตรอธิบายว่าเป็นนิมิตของคฤหัสถ์ผู้นุ่งห่มขาวจำนวนมากที่จะถึงพระตถาคต '
   'เป็นสรณะตลอดชีวิต — สัตว์เล็กจำนวนมากในฝัน ในที่นี้ไม่ใช่ลางร้ายหรือความสกปรก '
   'แต่เป็นภาพของมหาชนที่เข้ามาพึ่งพิง'),

  ('DREAM_BIRD',
   'ในมหาสุบินข้อสี่ นกสี่เหล่าสีต่างกันบินมาจากทิศทั้งสี่ มาตกแทบพระบาทแล้ว '
   'กลับกลายเป็นสีขาวทุกตัว ตัวพระสูตรอธิบายว่าเป็นนิมิตของวรรณะทั้งสี่ — กษัตริย์ '
   'พราหมณ์ แพศย์ ศูทร — ที่จะออกบวชในธรรมวินัยแล้วทำให้แจ้งซึ่งวิมุตติ '
   'นกต่างสีที่กลายเป็นสีเดียวจึงเป็นภาพของความแตกต่างที่มลายไปในจุดหมายเดียวกัน')

) as v(concept_key, body_th)
join content.symbol s on s.concept_key = v.concept_key
cross join p cross join tr
where not exists (
  select 1 from content.interpretation i
  where i.symbol_id = s.id and i.passage_id = p.id
);

-- Review provenance
insert into content.review (entity_type, entity_id, role, reviewer, verdict, note_th)
select 'interpretation', i.id, 'editorial',
  'Claude (AI) — อ่านตัวบทจริงจาก 84000.org ฉบับหลวง 26 ก.ค. 2569',
  'checked',
  'ความหมายทุกข้อมาจากตัวพระสูตรเองซึ่งพ้นลิขสิทธิ์ ไม่ได้พึ่งอรรถกถา; '
  'body_th เป็นสำนวนเรียบเรียงใหม่ — ยังควรได้รับการทานซ้ำโดยผู้เชี่ยวชาญพุทธศาสน์'
from content.interpretation i
join content.passage p on p.id = i.passage_id
join content.edition e on e.id = p.edition_id
where e.citekey = 'tipitaka-22-196'
  and not exists (
    select 1 from content.review r
    where r.entity_type = 'interpretation' and r.entity_id = i.id
  );

-- Invariant gate
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
    raise exception 'interpretations_v2 aborted: % invariant(s) violated', bad;
  end if;
end $$;

select
  (select count(*) from content.interpretation where status = 'published') as interpretations_published,
  (select count(*) from content.passage where status = 'published') as passages_published,
  (select count(*) from content.number_association) as number_associations_ever;
