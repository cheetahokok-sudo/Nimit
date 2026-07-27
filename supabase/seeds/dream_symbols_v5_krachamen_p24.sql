-- ============================================================================
-- Lexicon v5 — the กระเหม่น omens on หน้า ๒๔
--
-- dream_symbols_v4 covered หน้า ๒๕ (ใจ, แขนซ้าย, แขนขวา, นาสา). The FACING page
-- carries five more omens that nothing has touched, transcribed from the
-- D-Library scan: หูซ้าย, หูขวา, ศีร์ษะเบื้องบน, ผีปากล่าง, and one more whose
-- body part is ambiguous in the verse (see the interpretation seed).
--
-- Left/right is lexicalised the same way v4 does it, and for the same reason:
-- the source gives OPPOSITE readings for หูซ้าย (ข่าวร้าย) and หูขวา (ลาภ), so
-- the side-bearing compound must outrank the bare term under longest-match. A
-- user who types "หูซ้ายกระตุก" and gets the generic กระเหม่น reading has been
-- told the wrong thing, not merely a vaguer thing.
--
-- Modern spellings are carried as synonyms because nobody types 1934
-- orthography: ผีปาก is ริมฝีปาก today, and most people say "กระตุก" rather
-- than "กระเหม่น".
-- ============================================================================

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'published', now()
from (values
  ('OMEN_TWITCH_EAR_L', 'twitch-ear-left',  'กระเหม่นหูซ้าย',    'left ear twitch',  'omens-signs'),
  ('OMEN_TWITCH_EAR_R', 'twitch-ear-right', 'กระเหม่นหูขวา',     'right ear twitch', 'omens-signs'),
  ('OMEN_TWITCH_HEAD',  'twitch-head',      'กระเหม่นศีรษะ',      'head twitch',      'omens-signs'),
  ('OMEN_TWITCH_LIP',   'twitch-lip',       'กระเหม่นริมฝีปากล่าง','lower lip twitch', 'omens-signs')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('OMEN_TWITCH_EAR_L', 'กระเหม่นหูซ้าย', 'primary',  100),
  ('OMEN_TWITCH_EAR_L', 'เขม่นหูซ้าย',    'synonym',   95),
  ('OMEN_TWITCH_EAR_L', 'หูซ้ายกระตุก',   'colloquial',90),
  ('OMEN_TWITCH_EAR_R', 'กระเหม่นหูขวา',  'primary',  100),
  ('OMEN_TWITCH_EAR_R', 'เขม่นหูขวา',     'synonym',   95),
  ('OMEN_TWITCH_EAR_R', 'หูขวากระตุก',    'colloquial',90),
  ('OMEN_TWITCH_HEAD',  'กระเหม่นศีรษะ',   'primary',  100),
  ('OMEN_TWITCH_HEAD',  'เขม่นศีรษะ',      'synonym',   95),
  ('OMEN_TWITCH_HEAD',  'กระเหม่นหัว',     'colloquial',88),
  ('OMEN_TWITCH_HEAD',  'หัวกระตุก',       'colloquial',85),
  ('OMEN_TWITCH_LIP',   'กระเหม่นริมฝีปากล่าง', 'primary', 100),
  ('OMEN_TWITCH_LIP',   'กระเหม่นปากล่าง',      'synonym',  95),
  ('OMEN_TWITCH_LIP',   'ริมฝีปากล่างกระตุก',   'colloquial',90),
  ('OMEN_TWITCH_LIP',   'ปากกระตุก',            'colloquial',80)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

insert into content.symbol_relation (symbol_id, related_id, kind)
select a.id, b.id, 'narrower'
from (values
  ('OMEN_TWITCH_EAR_L', 'OMEN_TWITCH'),
  ('OMEN_TWITCH_EAR_R', 'OMEN_TWITCH'),
  ('OMEN_TWITCH_HEAD',  'OMEN_TWITCH'),
  ('OMEN_TWITCH_LIP',   'OMEN_TWITCH')
) as v(a_key, b_key)
join content.symbol a on a.concept_key = v.a_key
join content.symbol b on b.concept_key = v.b_key
on conflict do nothing;

select count(*) as omen_symbols_total
  from content.symbol where concept_key like 'OMEN_TWITCH%';
