-- ============================================================================
-- Lexicon v6 — the animals ฝันพยากรณ์ names, as symbols in their own right
--
-- The library had 81 symbols and matched only 11 of the 59 animal words in the
-- book's number table. Worse, 5 of those 11 matched a COMPOUND term under a
-- broader symbol: นกยูง sat under นก, ผึ้ง under แมลง, and both ปลาฉลาม and
-- ปลาวาฬ under ปลา. Attaching the book's numbers through those matches would
-- have given every bird the peacock's numbers, and given the generic ปลา four
-- numbers belonging to two different animals.
--
-- So the importer now requires a PRIMARY term match, and the animals the book
-- names get symbols of their own. That is the correct fix rather than a
-- workaround: these are the creatures people actually dream about and type,
-- and a lexicon that collapses ปลาฉลาม into ปลา was always going to answer
-- "ฝันเห็นฉลาม" with a reading about fish in general.
--
-- Broader terms stay where they are. นก and ปลา keep their compounds, and the
-- new specific symbols are related as `narrower`, so longest-match prefers the
-- specific one while the general symbol still catches everything else.
--
-- No numbers here — this file is vocabulary only. The numbers arrive from the
-- book through scripts/import-book-numbers.mjs, as drafts.
-- ============================================================================

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'published', now()
from (values
  -- มงคล / สัตว์ในคติความเชื่อ
  ('DREAM_DRAGON_FLYING','dragon-flying','มังกรบิน','flying dragon','dream-symbols'),
  ('DREAM_SWAN',      'swan',        'หงส์',        'swan',            'dream-symbols'),
  ('DREAM_QILIN',     'qilin',       'กิเลน',       'qilin',           'dream-symbols'),
  ('DREAM_PEACOCK',   'peacock',     'นกยูง',       'peacock',         'dream-symbols'),
  ('DREAM_LION',      'lion',        'สิงโต',       'lion',            'dream-symbols'),
  ('DREAM_EAGLE',     'eagle',       'นกอินทรี',    'eagle',           'dream-symbols'),
  ('DREAM_CRANE',     'crane',       'นกกระเรียน',  'crane',           'dream-symbols'),
  ('DREAM_GOOSE',     'goose',       'ห่านฟ้า',     'goose',           'dream-symbols'),
  -- สัตว์ใหญ่ / สัตว์เลี้ยง
  ('DREAM_TIGER_STRIPED','tiger-striped','เสือโคร่ง','indochinese tiger','dream-symbols'),
  ('DREAM_LEOPARD',   'leopard',     'เสือดาว',     'leopard',         'dream-symbols'),
  ('DREAM_DEER',      'deer',        'กวาง',        'deer',            'dream-symbols'),
  ('DREAM_COW',       'cow',         'วัว',         'cow',             'dream-symbols'),
  ('DREAM_GOAT',      'goat',        'แพะ',         'goat',            'dream-symbols'),
  ('DREAM_MONKEY',    'monkey',      'ลิง',         'monkey',          'dream-symbols'),
  ('DREAM_WILD_BOAR', 'wild-boar',   'หมูป่า',      'wild boar',       'dream-symbols'),
  ('DREAM_FOX',       'fox',         'สุนัขจิ้งจอก','fox',             'dream-symbols'),
  ('DREAM_WOLF',      'wolf',        'สุนัขป่า',    'wolf',            'dream-symbols'),
  ('DREAM_RABBIT',    'rabbit',      'กระต่าย',     'rabbit',          'dream-symbols'),
  ('DREAM_BAT',       'bat',         'ค้างคาว',     'bat',             'dream-symbols'),
  ('DREAM_OTTER',     'otter',       'นาก',         'otter',           'dream-symbols'),
  -- นก
  ('DREAM_CROW',      'crow',        'กา',          'crow',            'dream-symbols'),
  ('DREAM_ORIOLE',    'oriole',      'นกขมิ้น',     'oriole',          'dream-symbols'),
  ('DREAM_SWALLOW',   'swallow',     'นกนางแอ่น',   'swallow',         'dream-symbols'),
  ('DREAM_MANDARIN_DUCK','mandarin-duck','เป็ดแมนดาริน','mandarin duck','dream-symbols'),
  ('DREAM_PARTRIDGE', 'partridge',   'นกกระทา',     'partridge',       'dream-symbols'),
  ('DREAM_PIGEON',    'pigeon',      'นกพิราบ',     'pigeon',          'dream-symbols'),
  ('DREAM_WEAVER_BIRD','weaver-bird','นกกระจาบ',    'weaver bird',     'dream-symbols'),
  ('DREAM_SPARROW',   'sparrow',     'นกกระจอก',    'sparrow',         'dream-symbols'),
  ('DREAM_CUCKOO',    'cuckoo',      'นกกาเหว่า',   'koel',            'dream-symbols'),
  ('DREAM_CHICKEN',   'chicken',     'ไก่',         'chicken',         'dream-symbols'),
  -- สัตว์น้ำ
  ('DREAM_WHALE',     'whale',       'ปลาวาฬ',      'whale',           'dream-symbols'),
  ('DREAM_SHARK',     'shark',       'ปลาฉลาม',     'shark',           'dream-symbols'),
  ('DREAM_GOLDFISH',  'goldfish',    'ปลาเงินปลาทอง','goldfish',       'dream-symbols'),
  ('DREAM_SEAL',      'seal',        'แมวน้ำ',      'seal',            'dream-symbols'),
  ('DREAM_SHRIMP',    'shrimp',      'กุ้ง',        'shrimp',          'dream-symbols'),
  ('DREAM_PRAWN_GIANT','prawn-giant','กุ้งก้ามกราม','giant river prawn','dream-symbols'),
  ('DREAM_CRAB',      'crab',        'ปู',          'crab',            'dream-symbols'),
  ('DREAM_SNAIL',     'snail',       'หอยขม',       'freshwater snail','dream-symbols'),
  -- แมลงและสัตว์เล็ก
  ('DREAM_TOAD',      'toad',        'คางคก',       'toad',            'dream-symbols'),
  ('DREAM_FROG',      'frog',        'กบ',          'frog',            'dream-symbols'),
  ('DREAM_CENTIPEDE', 'centipede',   'ตะขาบ',       'centipede',       'dream-symbols'),
  ('DREAM_SPIDER',    'spider',      'แมงมุม',      'spider',          'dream-symbols'),
  ('DREAM_DRAGONFLY', 'dragonfly',   'แมลงปอ',      'dragonfly',       'dream-symbols'),
  ('DREAM_CRICKET',   'cricket',     'จิ้งหรีด',    'cricket',         'dream-symbols'),
  ('DREAM_BUTTERFLY', 'butterfly',   'ผีเสื้อ',     'butterfly',       'dream-symbols'),
  ('DREAM_BEE',       'bee',         'ผึ้ง',        'bee',             'dream-symbols'),
  ('DREAM_CICADA',    'cicada',      'จักจั่น',     'cicada',          'dream-symbols')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

-- Primary terms, plus the variants the book itself lists and the spellings
-- people actually type. Weight follows the existing convention.
insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('DREAM_DRAGON_FLYING','มังกรบิน','primary',100),
  ('DREAM_SWAN','หงส์','primary',100),
  ('DREAM_QILIN','กิเลน','primary',100),
  ('DREAM_PEACOCK','นกยูง','primary',100),
  ('DREAM_LION','สิงโต','primary',100),
  ('DREAM_LION','ราชสีห์','synonym',90),
  ('DREAM_EAGLE','นกอินทรี','primary',100),
  ('DREAM_CRANE','นกกระเรียน','primary',100),
  ('DREAM_GOOSE','ห่านฟ้า','primary',100),
  ('DREAM_GOOSE','ห่าน','synonym',90),
  ('DREAM_TIGER_STRIPED','เสือโคร่ง','primary',100),
  ('DREAM_LEOPARD','เสือดาว','primary',100),
  ('DREAM_DEER','กวาง','primary',100),
  ('DREAM_DEER','กวางดาว','synonym',95),
  ('DREAM_COW','วัว','primary',100),
  ('DREAM_COW','วัวกระทิง','synonym',95),
  ('DREAM_COW','โค','synonym',88),
  ('DREAM_GOAT','แพะ','primary',100),
  ('DREAM_MONKEY','ลิง','primary',100),
  ('DREAM_WILD_BOAR','หมูป่า','primary',100),
  ('DREAM_FOX','สุนัขจิ้งจอก','primary',100),
  ('DREAM_FOX','หมาจิ้งจอก','synonym',95),
  ('DREAM_WOLF','สุนัขป่า','primary',100),
  ('DREAM_WOLF','หมาป่า','synonym',95),
  ('DREAM_RABBIT','กระต่าย','primary',100),
  ('DREAM_BAT','ค้างคาว','primary',100),
  ('DREAM_OTTER','นาก','primary',100),
  ('DREAM_CROW','กา','primary',100),
  ('DREAM_CROW','อีกา','synonym',98),
  ('DREAM_ORIOLE','นกขมิ้น','primary',100),
  ('DREAM_SWALLOW','นกนางแอ่น','primary',100),
  ('DREAM_MANDARIN_DUCK','เป็ดแมนดาริน','primary',100),
  ('DREAM_MANDARIN_DUCK','เป็ด','synonym',85),
  ('DREAM_PARTRIDGE','นกกระทา','primary',100),
  ('DREAM_PIGEON','นกพิราบ','primary',100),
  ('DREAM_WEAVER_BIRD','นกกระจาบ','primary',100),
  ('DREAM_SPARROW','นกกระจอก','primary',100),
  ('DREAM_CUCKOO','นกกาเหว่า','primary',100),
  ('DREAM_CHICKEN','ไก่','primary',100),
  ('DREAM_CHICKEN','ไก่ขัน','synonym',95),
  ('DREAM_WHALE','ปลาวาฬ','primary',100),
  ('DREAM_SHARK','ปลาฉลาม','primary',100),
  ('DREAM_SHARK','ฉลาม','synonym',95),
  ('DREAM_GOLDFISH','ปลาเงินปลาทอง','primary',100),
  ('DREAM_GOLDFISH','ปลาทอง','synonym',92),
  ('DREAM_SEAL','แมวน้ำ','primary',100),
  ('DREAM_SHRIMP','กุ้ง','primary',100),
  ('DREAM_SHRIMP','กุ้งนาง','synonym',95),
  ('DREAM_PRAWN_GIANT','กุ้งก้ามกราม','primary',100),
  ('DREAM_CRAB','ปู','primary',100),
  ('DREAM_SNAIL','หอยขม','primary',100),
  ('DREAM_SNAIL','หอยโข่ง','synonym',95),
  ('DREAM_TOAD','คางคก','primary',100),
  ('DREAM_FROG','กบ','primary',100),
  ('DREAM_CENTIPEDE','ตะขาบ','primary',100),
  ('DREAM_SPIDER','แมงมุม','primary',100),
  ('DREAM_DRAGONFLY','แมลงปอ','primary',100),
  ('DREAM_CRICKET','จิ้งหรีด','primary',100),
  ('DREAM_BUTTERFLY','ผีเสื้อ','primary',100),
  ('DREAM_BEE','ผึ้ง','primary',100),
  ('DREAM_CICADA','จักจั่น','primary',100)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

-- Specific under general, so the browse UI can walk the hierarchy and the
-- matcher still resolves the broad word when nothing narrower fits.
insert into content.symbol_relation (symbol_id, related_id, kind)
select a.id, b.id, 'narrower'
from (values
  ('DREAM_PEACOCK','DREAM_BIRD'), ('DREAM_EAGLE','DREAM_BIRD'),
  ('DREAM_CRANE','DREAM_BIRD'),   ('DREAM_CROW','DREAM_BIRD'),
  ('DREAM_ORIOLE','DREAM_BIRD'),  ('DREAM_SWALLOW','DREAM_BIRD'),
  ('DREAM_PARTRIDGE','DREAM_BIRD'),('DREAM_PIGEON','DREAM_BIRD'),
  ('DREAM_WEAVER_BIRD','DREAM_BIRD'),('DREAM_SPARROW','DREAM_BIRD'),
  ('DREAM_CUCKOO','DREAM_BIRD'),  ('DREAM_SWAN','DREAM_BIRD'),
  ('DREAM_GOOSE','DREAM_BIRD'),   ('DREAM_CHICKEN','DREAM_BIRD'),
  ('DREAM_MANDARIN_DUCK','DREAM_BIRD'),
  ('DREAM_WHALE','DREAM_FISH'),   ('DREAM_SHARK','DREAM_FISH'),
  ('DREAM_GOLDFISH','DREAM_FISH'),
  ('DREAM_SPIDER','DREAM_INSECT'),('DREAM_DRAGONFLY','DREAM_INSECT'),
  ('DREAM_CRICKET','DREAM_INSECT'),('DREAM_BUTTERFLY','DREAM_INSECT'),
  ('DREAM_BEE','DREAM_INSECT'),   ('DREAM_CICADA','DREAM_INSECT'),
  ('DREAM_CENTIPEDE','DREAM_INSECT'),
  ('DREAM_TIGER_STRIPED','DREAM_TIGER'),('DREAM_LEOPARD','DREAM_TIGER'),
  ('DREAM_FOX','DREAM_DOG'),      ('DREAM_WOLF','DREAM_DOG'),
  ('DREAM_DRAGON_FLYING','DREAM_DRAGON')
) as v(a_key, b_key)
join content.symbol a on a.concept_key = v.a_key
join content.symbol b on b.concept_key = v.b_key
on conflict do nothing;

select count(*) as published_symbols from content.symbol where status = 'published';
