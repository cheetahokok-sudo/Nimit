-- ============================================================================
-- Lexicon v4 — body-twitch omens (กระเหม่น/เขม่น)
--
-- Opens a whole new category the app did not cover: omens that are not dreams
-- at all. ประมวลตำราทำนาย ภาค ๑ devotes pp. ๒๓–๒๕ to กระเหม่น — the belief that
-- an involuntary twitch in a body part foretells something, differing by part
-- and by left/right side. This is living Thai folk belief (people still say
-- "ขวาร้าย ซ้ายดี"), and it belongs in the omens category, not dream-symbols.
--
-- Left/right matters and is lexicalised: the source gives DIFFERENT readings
-- for แขนซ้าย vs แขนขวา, so the compound terms carry the side and outrank the
-- bare body-part term via longest-match.
-- ============================================================================

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'published', now()
from (values
  ('OMEN_TWITCH',        'twitch',        'กระเหม่น',       'body twitch',  'omens-signs'),
  ('OMEN_TWITCH_HEART',  'twitch-heart',  'ใจสั่น',         'heart flutter','omens-signs'),
  ('OMEN_TWITCH_ARM_L',  'twitch-arm-left',  'กระเหม่นแขนซ้าย', 'left arm twitch',  'omens-signs'),
  ('OMEN_TWITCH_ARM_R',  'twitch-arm-right', 'กระเหม่นแขนขวา',  'right arm twitch', 'omens-signs'),
  ('OMEN_TWITCH_NOSE',   'twitch-nose',   'กระเหม่นจมูก',    'nose twitch',  'omens-signs'),
  ('OMEN_ANIMAL_FALL',   'animal-fall',   'สัตว์ตก',        'falling animal','omens-signs')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('OMEN_TWITCH',       'กระเหม่น',        'primary',   100),
  ('OMEN_TWITCH',       'เขม่น',           'synonym',    95),
  ('OMEN_TWITCH',       'ตากระตุก',        'compound',   85),
  ('OMEN_TWITCH_HEART', 'ใจสั่น',          'primary',   100),
  ('OMEN_TWITCH_HEART', 'ใจไหว',           'synonym',    80),
  ('OMEN_TWITCH_ARM_L', 'กระเหม่นแขนซ้าย',  'primary',   100),
  ('OMEN_TWITCH_ARM_L', 'เขม่นแขนซ้าย',     'synonym',    95),
  ('OMEN_TWITCH_ARM_R', 'กระเหม่นแขนขวา',   'primary',   100),
  ('OMEN_TWITCH_ARM_R', 'เขม่นแขนขวา',      'synonym',    95),
  ('OMEN_TWITCH_NOSE',  'กระเหม่นจมูก',     'primary',   100),
  ('OMEN_TWITCH_NOSE',  'เขม่นจมูก',        'synonym',    95),
  ('OMEN_ANIMAL_FALL',  'สัตว์ตก',          'primary',   100),
  ('OMEN_ANIMAL_FALL',  'สัตว์ตกใส่',       'compound',   95),
  ('OMEN_ANIMAL_FALL',  'จิ้งจกตก',         'compound',   90),
  ('OMEN_ANIMAL_FALL',  'ตุ๊กแกตก',         'compound',   90)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

insert into content.symbol_relation (symbol_id, related_id, kind)
select a.id, b.id, 'narrower'
from (values
  ('OMEN_TWITCH_ARM_L', 'OMEN_TWITCH'),
  ('OMEN_TWITCH_ARM_R', 'OMEN_TWITCH'),
  ('OMEN_TWITCH_NOSE',  'OMEN_TWITCH'),
  ('OMEN_TWITCH_HEART', 'OMEN_TWITCH')
) as v(a_key, b_key)
join content.symbol a on a.concept_key = v.a_key
join content.symbol b on b.concept_key = v.b_key
on conflict do nothing;

select (select count(*) from content.symbol where status='published') as symbols,
       (select count(*) from content.symbol_term) as terms;
