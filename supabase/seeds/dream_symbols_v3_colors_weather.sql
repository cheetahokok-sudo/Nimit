-- ============================================================================
-- Symbol lexicon v3 — colors, weather, and numbers-as-dream-objects
--
-- Audience finding: dreams full of สีแดง สีเหลือง ตัวเลข สภาพอากาศ were
-- invisible to the analyzer — no symbols existed to match. These are LEXICON
-- additions (like dragon before them): linguistic data requiring no source,
-- published so they are findable, with EMPTY interpretations until a cleared
-- folk ตำรา attests meanings. The app says "ยังไม่มีคำแปลในคลัง" — never
-- invents. When the folk source lands, its readings attach here.
--
-- Colors matter double: they modify other symbols (นก "สีขาว" หน้าบ้าน) and
-- folk ตำรา treat them as omens in their own right.
--
-- Deliberate exclusions, with reasons:
--   * ลม (wind) as a bare term — substring-matches inside กลม and friends;
--     storms are covered by พายุ and compound terms instead.
--   * ขนาด (big/small) — modifiers, not symbols; they qualify another symbol
--     rather than carrying meaning alone. Handled later at extraction level.
-- ============================================================================

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'published', now()
from (values
  -- สี
  ('DREAM_COLOR_WHITE',  'color-white',  'สีขาว',   'white',   'dream-symbols'),
  ('DREAM_COLOR_RED',    'color-red',    'สีแดง',   'red',     'dream-symbols'),
  ('DREAM_COLOR_YELLOW', 'color-yellow', 'สีเหลือง', 'yellow',  'dream-symbols'),
  ('DREAM_COLOR_BLACK',  'color-black',  'สีดำ',    'black',   'dream-symbols'),
  ('DREAM_COLOR_GREEN',  'color-green',  'สีเขียว',  'green',   'dream-symbols'),
  -- สภาพอากาศ (ฝน และ ฟ้าผ่า มีอยู่แล้ว)
  ('DREAM_STORM',        'storm',        'พายุ',    'storm',   'dream-symbols'),
  ('DREAM_FOG',          'fog',          'หมอก',    'fog',     'dream-symbols'),
  ('DREAM_RAINBOW',      'rainbow',      'รุ้ง',     'rainbow', 'dream-symbols'),
  ('DREAM_SKY',          'sky',          'ท้องฟ้า',  'sky',     'dream-symbols'),
  -- ตัวเลขในฝัน (dreaming OF numbers — distinct from เลขเชิงสัญลักษณ์ output)
  ('DREAM_NUMBERS',      'numbers',      'ตัวเลข',   'numbers', 'dream-symbols')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('DREAM_COLOR_WHITE',  'สีขาว',      'primary',   100),
  ('DREAM_COLOR_WHITE',  'ขาวสะอาด',   'compound',   80),
  ('DREAM_COLOR_WHITE',  'เผือก',      'synonym',    70), -- ช้างเผือก งูเผือก
  ('DREAM_COLOR_RED',    'สีแดง',      'primary',   100),
  ('DREAM_COLOR_RED',    'แดงฉาน',     'compound',   80),
  ('DREAM_COLOR_YELLOW', 'สีเหลือง',    'primary',   100),
  ('DREAM_COLOR_YELLOW', 'เหลืองทอง',   'compound',   85),
  ('DREAM_COLOR_BLACK',  'สีดำ',       'primary',   100),
  ('DREAM_COLOR_BLACK',  'ดำมืด',      'compound',   80),
  ('DREAM_COLOR_GREEN',  'สีเขียว',     'primary',   100),

  ('DREAM_STORM',        'พายุ',       'primary',   100),
  ('DREAM_STORM',        'ลมแรง',      'compound',   90),
  ('DREAM_STORM',        'ลมพัดแรง',   'compound',   85),
  ('DREAM_FOG',          'หมอก',       'primary',   100),
  ('DREAM_FOG',          'หมอกลง',     'compound',   90),
  ('DREAM_RAINBOW',      'รุ้ง',        'primary',   100),
  ('DREAM_RAINBOW',      'รุ้งกินน้ำ',   'compound',   95),
  ('DREAM_SKY',          'ท้องฟ้า',     'primary',   100),
  ('DREAM_SKY',          'ฟ้าแจ้ง',     'compound',   85),
  ('DREAM_SKY',          'แดดออก',     'compound',   80),
  ('DREAM_SKY',          'แดดจ้า',     'compound',   80),

  ('DREAM_NUMBERS',      'ตัวเลข',      'primary',   100),
  ('DREAM_NUMBERS',      'เห็นเลข',     'compound',   90),
  ('DREAM_NUMBERS',      'เลขเด่น',     'compound',   70)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

-- เผือก (albino) doubles as a white-variant marker on animals; relate white to
-- the animal symbols users pair it with most.
insert into content.symbol_relation (symbol_id, related_id, kind)
select a.id, b.id, v.kind::content.relation_kind
from (values
  ('DREAM_COLOR_WHITE', 'DREAM_BIRD',     'see_also'),
  ('DREAM_COLOR_WHITE', 'DREAM_ELEPHANT', 'see_also'),
  ('DREAM_STORM',       'DREAM_RAIN',     'see_also'),
  ('DREAM_RAINBOW',     'DREAM_RAIN',     'see_also'),
  ('DREAM_SKY',         'DREAM_SUN',      'see_also')
) as v(a_key, b_key, kind)
join content.symbol a on a.concept_key = v.a_key
join content.symbol b on b.concept_key = v.b_key
on conflict do nothing;

select
  (select count(*) from content.symbol where status = 'published') as symbols,
  (select count(*) from content.symbol_term) as terms;
