-- ============================================================================
-- Symbol lexicon v2 — gaps exposed by a rare-keyword stress test
--
-- Test query: "ฝันเห็นม้านิลมังกร ดำน้ำไปเจอปลาฉลามยัก"
-- Result: น้ำ and ปลา matched; ม้านิลมังกร fell through entirely — no horse,
-- no dragon in the lexicon. Worse, the horse was already IN our ingested
-- source: Mahasupina dream #5 (ม้ามีปากสองข้าง) sits in the passage we quote,
-- unmapped because no DREAM_HORSE symbol existed to attach it to.
--
-- Two kinds of addition, with different evidence requirements:
--   * DREAM_HORSE — symbol + interpretation, because a cleared source
--     (tipitaka-27-77, already ingested) attests a meaning.
--   * DREAM_DRAGON — symbol + terms ONLY. มังกร is a real symbol Thai users
--     search for, so it must be findable; but no cleared source yet attests
--     its meaning, so it publishes with an EMPTY interpretations array. The
--     app says "ยังไม่มีคำแปลในคลัง" — never invents. The gap is the honest
--     state, and logged misses like this are how the editorial backlog forms.
--
-- ม้านิลมังกร itself is not a traditional dream omen at all — it is the
-- horse-dragon mount from พระอภัยมณี (สุนทรภู่, ถึงแก่กรรม พ.ศ. 2398 — PD).
-- The lexicon handles it as a compound term pointing at BOTH parent symbols,
-- so the match surfaces horse and dragon side by side.
-- ============================================================================

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'published', now()
from (values
  ('DREAM_HORSE',  'horse',  'ม้า',    'horse',  'dream-symbols'),
  ('DREAM_DRAGON', 'dragon', 'มังกร',  'dragon', 'dream-symbols')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('DREAM_HORSE',  'ม้า',          'primary',   100),
  ('DREAM_HORSE',  'ม้าขาว',       'compound',   90),
  ('DREAM_HORSE',  'อาชา',         'synonym',    60),
  -- The Phra Aphai Mani hybrid points at both parents; longest-match will
  -- prefer it over bare ม้า, and the result shows horse AND dragon.
  ('DREAM_HORSE',  'ม้านิลมังกร',   'compound',   90),
  ('DREAM_DRAGON', 'ม้านิลมังกร',   'compound',   95),
  ('DREAM_DRAGON', 'มังกร',        'primary',   100),
  ('DREAM_DRAGON', 'มังกรทอง',     'compound',   90),
  ('DREAM_FISH',   'ปลาฉลาม',      'compound',   90),
  ('DREAM_FISH',   'ฉลาม',         'synonym',    85),
  ('DREAM_FISH',   'ปลาวาฬ',       'compound',   85)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

-- Dragon relates to the naga in Thai-Chinese belief; surface the neighbour.
insert into content.symbol_relation (symbol_id, related_id, kind)
select a.id, b.id, 'see_also'
from content.symbol a, content.symbol b
where a.concept_key = 'DREAM_DRAGON' and b.concept_key = 'DREAM_NAGA'
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Horse interpretation from the ALREADY-INGESTED Mahasupina passage:
-- dream #5, the two-mouthed horse fed at both mouths.
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
select s.id, p.id, tr.id,
  'ในมหาสุบินชาดก ม้าปรากฏในนิมิตข้อที่ห้า: ม้าตัวหนึ่งมีปากสองข้าง คนให้หญ้าที่ปากทั้งสอง '
  'มันก็เคี้ยวกินทั้งสองทาง ตัวบทอธิบายว่าเป็นภาพของผู้ตัดสินคดีในยุคเสื่อม '
  'ที่รับสินบนจากคู่ความทั้งสองฝ่าย — ม้าในบริบทนี้ไม่ใช่ลางของการเดินทางหรือความสำเร็จ '
  'อย่างที่ตำราพื้นบ้านมักว่า แต่เป็นภาพเตือนเรื่องความโลภของผู้มีอำนาจ',
  'historical_belief',
  'ในวรรณกรรมพุทธ ความฝันชุดนี้เป็นคำพยากรณ์สังคมในยุคเสื่อมอันไกล '
  'ไม่ใช่ลางบอกโชคลาภของผู้ฝัน และไม่ควรนำไปโยงกับการเสี่ยงโชคโดยเด็ดขาด',
  corr.ids, 'published', now()
from content.symbol s
cross join p cross join tr cross join corr
where s.concept_key = 'DREAM_HORSE'
  and not exists (
    select 1 from content.interpretation i
    where i.symbol_id = s.id and i.passage_id = p.id
  );

insert into content.review (entity_type, entity_id, role, reviewer, verdict, note_th)
select 'interpretation', i.id, 'editorial',
  'Claude (AI) — อ่านตัวบทจริงจาก 84000.org ฉบับหลวง 26 ก.ค. 2569',
  'checked',
  'นิมิตข้อ ๕ อ่านจากอรรถกถาหน้าเดียวกับชุดแรก; body_th เป็นสำนวนเรียบเรียงใหม่ '
  '— ยังควรได้รับการทานซ้ำโดยผู้เชี่ยวชาญพุทธศาสน์'
from content.interpretation i
join content.symbol s on s.id = i.symbol_id
where s.concept_key = 'DREAM_HORSE'
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
  if bad > 0 then
    raise exception 'gapfill aborted: % invariant(s) violated', bad;
  end if;
end $$;

select
  (select count(*) from content.symbol where status = 'published') as symbols,
  (select count(*) from content.symbol_term) as terms,
  (select count(*) from content.interpretation where status = 'published') as interpretations;
