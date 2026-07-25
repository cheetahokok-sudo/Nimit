-- ============================================================================
-- Dream symbol lexicon v1 — search vocabulary only
--
-- WHAT THIS IS: the term index that makes Thai lookup work — headwords plus
-- synonyms, colloquialisms, regional variants and the common misspellings real
-- users type. This is linguistic data. It carries no claim about meaning, so it
-- needs no source attribution and infringes nothing.
--
-- WHAT THIS DELIBERATELY IS NOT: interpretations, and number associations.
--
-- Those are claims about what a symbol MEANS, and every one of them must cite a
-- passage in an actual manuscript. Nobody has yet read NLT 447 — rights
-- clearance for it is still at P0 in the acquisition tracker. Writing
-- "ตำราทำนายฝัน เลขทะเบียน 447 says a white snake means X" without having read
-- folio one would be fabricating a citation, which is precisely the failure the
-- entire A1–D trust apparatus exists to prevent. A plausible invented citation
-- is worse than no citation, because it is unfalsifiable by the reader and it
-- poisons the corpus for everyone downstream.
--
-- So: interpretations enter only through transcription from cleared sources.
-- content.interpretation stays empty until then, and api.get_symbol will
-- correctly return an empty array for every symbol here.
--
-- All rows are status='draft'.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Symbols
-- ---------------------------------------------------------------------------

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, ethics_note_th, status)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, v.ethics_note_th, 'draft'
from (values
  -- สัตว์
  ('DREAM_SNAKE',      'snake',        'งู',            'snake',        'dream-symbols', null),
  ('DREAM_NAGA',       'naga',         'พญานาค',        'naga',         'dream-symbols', null),
  ('DREAM_ELEPHANT',   'elephant',     'ช้าง',          'elephant',     'dream-symbols', null),
  ('DREAM_TIGER',      'tiger',        'เสือ',          'tiger',        'dream-symbols', null),
  ('DREAM_CROCODILE',  'crocodile',    'จระเข้',        'crocodile',    'dream-symbols', null),
  ('DREAM_FISH',       'fish',         'ปลา',           'fish',         'dream-symbols', null),
  ('DREAM_BIRD',       'bird',         'นก',            'bird',         'dream-symbols', null),
  ('DREAM_CAT',        'cat',          'แมว',           'cat',          'dream-symbols', null),
  ('DREAM_DOG',        'dog',          'สุนัข',         'dog',          'dream-symbols', null),
  ('DREAM_RAT',        'rat',          'หนู',           'rat',          'dream-symbols', null),
  ('DREAM_BUFFALO',    'buffalo',      'ควาย',          'buffalo',      'dream-symbols', null),
  ('DREAM_TURTLE',     'turtle',       'เต่า',          'turtle',       'dream-symbols', null),
  ('DREAM_INSECT',     'insect',       'แมลง',          'insect',       'dream-symbols', null),

  -- คนและความสัมพันธ์
  ('DREAM_MONK',       'monk',         'พระสงฆ์',       'monk',         'dream-symbols',
   'เนื้อหาเกี่ยวกับพระสงฆ์ต้องนำเสนอด้วยความเคารพ และไม่สื่อว่าพุทธศาสนารับรองการเสี่ยงโชค'),
  ('DREAM_CHILD',      'child',        'เด็ก',          'child',        'dream-symbols', null),
  ('DREAM_BABY',       'baby',         'ทารก',          'baby',         'dream-symbols', null),
  ('DREAM_PREGNANCY',  'pregnancy',    'ตั้งครรภ์',     'pregnancy',    'dream-symbols', null),
  ('DREAM_WEDDING',    'wedding',      'แต่งงาน',       'wedding',      'dream-symbols', null),
  ('DREAM_ANCESTOR',   'ancestor',     'บรรพบุรุษ',     'ancestor',     'dream-symbols', null),
  ('DREAM_GHOST',      'ghost',        'ผี',            'ghost',        'dream-symbols', null),
  ('DREAM_DEAD_PERSON','dead-person',  'คนตาย',         'the dead',     'dream-symbols',
   'อาจกระทบผู้ที่กำลังสูญเสีย ควรใช้ถ้อยคำระมัดระวัง'),

  -- ความตายและพิธีกรรม
  ('DREAM_COFFIN',     'coffin',       'โลงศพ',         'coffin',       'dream-symbols', null),
  ('DREAM_FUNERAL',    'funeral',      'งานศพ',         'funeral',      'dream-symbols', null),
  ('DREAM_TEMPLE',     'temple',       'วัด',           'temple',       'dream-symbols', null),
  ('DREAM_PAGODA',     'pagoda',       'เจดีย์',        'pagoda',       'dream-symbols', null),
  ('DREAM_BUDDHA_IMAGE','buddha-image','พระพุทธรูป',    'Buddha image', 'dream-symbols', null),

  -- ร่างกาย
  ('DREAM_BLOOD',      'blood',        'เลือด',         'blood',        'dream-symbols', null),
  ('DREAM_TOOTH',      'tooth',        'ฟัน',           'tooth',        'dream-symbols', null),
  ('DREAM_HAIR',       'hair',         'ผม',            'hair',         'dream-symbols', null),
  ('DREAM_NAKED',      'naked',        'เปลือยกาย',     'nakedness',    'dream-symbols', null),
  ('DREAM_ILLNESS',    'illness',      'เจ็บป่วย',      'illness',      'dream-symbols',
   'ห้ามตีความเป็นการวินิจฉัยหรือคำแนะนำทางการแพทย์'),

  -- ธรรมชาติ
  ('DREAM_WATER',      'water',        'น้ำ',           'water',        'dream-symbols', null),
  ('DREAM_FLOOD',      'flood',        'น้ำท่วม',       'flood',        'dream-symbols', null),
  ('DREAM_RAIN',       'rain',         'ฝน',            'rain',         'dream-symbols', null),
  ('DREAM_FIRE',       'fire',         'ไฟ',            'fire',         'dream-symbols', null),
  ('DREAM_LIGHTNING',  'lightning',    'ฟ้าผ่า',        'lightning',    'dream-symbols', null),
  ('DREAM_MOUNTAIN',   'mountain',     'ภูเขา',         'mountain',     'dream-symbols', null),
  ('DREAM_SEA',        'sea',          'ทะเล',          'sea',          'dream-symbols', null),
  ('DREAM_SUN',        'sun',          'พระอาทิตย์',    'sun',          'dream-symbols', null),
  ('DREAM_MOON',       'moon',         'พระจันทร์',     'moon',         'dream-symbols', null),
  ('DREAM_STAR',       'star',         'ดาว',           'star',         'dream-symbols', null),
  ('DREAM_TREE',       'tree',         'ต้นไม้',        'tree',         'dream-symbols', null),
  ('DREAM_FLOWER',     'flower',       'ดอกไม้',        'flower',       'dream-symbols', null),
  ('DREAM_FRUIT',      'fruit',        'ผลไม้',         'fruit',        'dream-symbols', null),
  ('DREAM_RICE',       'rice',         'ข้าว',          'rice',         'dream-symbols', null),

  -- วัตถุและทรัพย์
  ('DREAM_GOLD',       'gold',         'ทอง',           'gold',         'dream-symbols', null),
  ('DREAM_MONEY',      'money',        'เงิน',          'money',        'dream-symbols', null),
  ('DREAM_RING',       'ring',         'แหวน',          'ring',         'dream-symbols', null),
  ('DREAM_HOUSE',      'house',        'บ้าน',          'house',        'dream-symbols', null),
  ('DREAM_BOAT',       'boat',         'เรือ',          'boat',         'dream-symbols', null),
  ('DREAM_CAR',        'car',          'รถ',            'car',          'dream-symbols', null),
  ('DREAM_BRIDGE',     'bridge',       'สะพาน',         'bridge',       'dream-symbols', null),
  ('DREAM_STAIRS',     'stairs',       'บันได',         'stairs',       'dream-symbols', null),

  -- เหตุการณ์ในฝัน
  ('DREAM_FALLING',    'falling',      'ตกจากที่สูง',   'falling',      'dream-symbols', null),
  ('DREAM_FLYING',     'flying',       'บินได้',        'flying',       'dream-symbols', null),
  ('DREAM_CHASED',     'being-chased', 'ถูกไล่',        'being chased', 'dream-symbols', null),
  ('DREAM_LOST',       'lost',         'หลงทาง',        'being lost',   'dream-symbols', null),
  ('DREAM_BATHING',    'bathing',      'อาบน้ำ',        'bathing',      'dream-symbols', null),
  ('DREAM_EATING',     'eating',       'กินอาหาร',      'eating',       'dream-symbols', null)
) as v(concept_key, slug, name_th, name_en, category_slug, ethics_note_th)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do update set
  name_th = excluded.name_th,
  ethics_note_th = excluded.ethics_note_th;

-- ---------------------------------------------------------------------------
-- Terms
--
-- Kinds: primary (headword) | synonym | colloquial | regional | misspelling |
-- compound. Weight ranks competing matches.
--
-- Two deliberate inclusions:
--   * `compound` terms (งูเหลือม, งูเห่า) exist so the longest-match scan
--     resolves them to the specific symbol rather than bare งู
--   * `misspelling` terms capture what people actually type. Thai tone marks are
--     dropped or mistyped constantly; norm_loose_th strips them anyway, but
--     genuinely different spellings (เจดี vs เจดีย์) need their own row.
-- ---------------------------------------------------------------------------

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  -- งู and its species, which must outrank the generic term
  ('DREAM_SNAKE','งู','primary',100),
  ('DREAM_SNAKE','งูใหญ่','compound',90),
  ('DREAM_SNAKE','งูเห่า','compound',95),
  ('DREAM_SNAKE','งูเหลือม','compound',95),
  ('DREAM_SNAKE','งูจงอาง','compound',95),
  ('DREAM_SNAKE','งูสีขาว','compound',95),
  ('DREAM_SNAKE','งูเผือก','compound',95),
  ('DREAM_SNAKE','อสรพิษ','synonym',70),
  ('DREAM_NAGA','พญานาค','primary',100),
  ('DREAM_NAGA','นาค','synonym',90),
  ('DREAM_NAGA','พระยานาค','misspelling',60),
  ('DREAM_ELEPHANT','ช้าง','primary',100),
  ('DREAM_ELEPHANT','ช้างเผือก','compound',95),
  ('DREAM_ELEPHANT','คชสาร','synonym',60),
  ('DREAM_TIGER','เสือ','primary',100),
  ('DREAM_TIGER','เสือโคร่ง','compound',90),
  ('DREAM_CROCODILE','จระเข้','primary',100),
  ('DREAM_CROCODILE','ตะโขง','regional',50),
  ('DREAM_CROCODILE','จรเข้','misspelling',60),
  ('DREAM_FISH','ปลา','primary',100),
  ('DREAM_FISH','ปลาใหญ่','compound',85),
  ('DREAM_FISH','ปลาช่อน','compound',85),
  ('DREAM_BIRD','นก','primary',100),
  ('DREAM_BIRD','นกยูง','compound',85),
  ('DREAM_CAT','แมว','primary',100),
  ('DREAM_CAT','แมวดำ','compound',90),
  ('DREAM_DOG','สุนัข','primary',100),
  ('DREAM_DOG','หมา','colloquial',95),
  ('DREAM_RAT','หนู','primary',100),
  ('DREAM_RAT','หนูใหญ่','compound',80),
  ('DREAM_BUFFALO','ควาย','primary',100),
  ('DREAM_BUFFALO','กระบือ','synonym',70),
  ('DREAM_TURTLE','เต่า','primary',100),
  ('DREAM_INSECT','แมลง','primary',100),
  ('DREAM_INSECT','ผึ้ง','compound',80),
  ('DREAM_INSECT','มด','compound',80),

  ('DREAM_MONK','พระสงฆ์','primary',100),
  ('DREAM_MONK','พระ','colloquial',95),
  ('DREAM_MONK','หลวงพ่อ','colloquial',85),
  ('DREAM_MONK','พระภิกษุ','synonym',80),
  ('DREAM_CHILD','เด็ก','primary',100),
  ('DREAM_CHILD','เด็กเล็ก','compound',85),
  ('DREAM_BABY','ทารก','primary',100),
  ('DREAM_BABY','เด็กแรกเกิด','compound',90),
  ('DREAM_PREGNANCY','ตั้งครรภ์','primary',100),
  ('DREAM_PREGNANCY','ท้อง','colloquial',85),
  ('DREAM_PREGNANCY','มีลูก','colloquial',75),
  ('DREAM_WEDDING','แต่งงาน','primary',100),
  ('DREAM_WEDDING','งานแต่ง','colloquial',90),
  ('DREAM_ANCESTOR','บรรพบุรุษ','primary',100),
  ('DREAM_ANCESTOR','ปู่ย่าตายาย','colloquial',85),
  ('DREAM_GHOST','ผี','primary',100),
  ('DREAM_GHOST','วิญญาณ','synonym',85),
  ('DREAM_DEAD_PERSON','คนตาย','primary',100),
  ('DREAM_DEAD_PERSON','ศพ','synonym',90),
  ('DREAM_DEAD_PERSON','คนที่เสียไปแล้ว','colloquial',75),

  ('DREAM_COFFIN','โลงศพ','primary',100),
  ('DREAM_COFFIN','หีบศพ','synonym',80),
  ('DREAM_FUNERAL','งานศพ','primary',100),
  ('DREAM_FUNERAL','เผาศพ','compound',80),
  ('DREAM_TEMPLE','วัด','primary',100),
  ('DREAM_TEMPLE','โบสถ์','compound',75),
  ('DREAM_PAGODA','เจดีย์','primary',100),
  ('DREAM_PAGODA','พระธาตุ','synonym',85),
  ('DREAM_PAGODA','เจดี','misspelling',50),
  ('DREAM_BUDDHA_IMAGE','พระพุทธรูป','primary',100),
  ('DREAM_BUDDHA_IMAGE','องค์พระ','colloquial',75),

  ('DREAM_BLOOD','เลือด','primary',100),
  ('DREAM_BLOOD','เลือดออก','compound',90),
  ('DREAM_TOOTH','ฟัน','primary',100),
  ('DREAM_TOOTH','ฟันหัก','compound',95),
  ('DREAM_TOOTH','ฟันหลุด','compound',95),
  ('DREAM_HAIR','ผม','primary',100),
  ('DREAM_HAIR','ตัดผม','compound',90),
  ('DREAM_HAIR','ผมร่วง','compound',90),
  ('DREAM_NAKED','เปลือยกาย','primary',100),
  ('DREAM_NAKED','แก้ผ้า','colloquial',90),
  ('DREAM_NAKED','ไม่ใส่เสื้อผ้า','colloquial',70),
  ('DREAM_ILLNESS','เจ็บป่วย','primary',100),
  ('DREAM_ILLNESS','ป่วย','colloquial',95),
  ('DREAM_ILLNESS','เข้าโรงพยาบาล','compound',70),

  ('DREAM_WATER','น้ำ','primary',100),
  ('DREAM_WATER','น้ำใส','compound',85),
  ('DREAM_WATER','น้ำขุ่น','compound',85),
  ('DREAM_FLOOD','น้ำท่วม','primary',100),
  ('DREAM_RAIN','ฝน','primary',100),
  ('DREAM_RAIN','ฝนตก','compound',95),
  ('DREAM_FIRE','ไฟ','primary',100),
  ('DREAM_FIRE','ไฟไหม้','compound',95),
  ('DREAM_LIGHTNING','ฟ้าผ่า','primary',100),
  ('DREAM_LIGHTNING','ฟ้าร้อง','compound',80),
  ('DREAM_MOUNTAIN','ภูเขา','primary',100),
  ('DREAM_MOUNTAIN','ดอย','regional',70),
  ('DREAM_SEA','ทะเล','primary',100),
  ('DREAM_SUN','พระอาทิตย์','primary',100),
  ('DREAM_SUN','ดวงอาทิตย์','synonym',95),
  ('DREAM_MOON','พระจันทร์','primary',100),
  ('DREAM_MOON','ดวงจันทร์','synonym',95),
  ('DREAM_STAR','ดาว','primary',100),
  ('DREAM_STAR','ดวงดาว','synonym',90),
  ('DREAM_TREE','ต้นไม้','primary',100),
  ('DREAM_TREE','ต้นไม้ใหญ่','compound',85),
  ('DREAM_FLOWER','ดอกไม้','primary',100),
  ('DREAM_FLOWER','ดอกบัว','compound',90),
  ('DREAM_FRUIT','ผลไม้','primary',100),
  ('DREAM_FRUIT','กล้วย','compound',85),
  ('DREAM_RICE','ข้าว','primary',100),
  ('DREAM_RICE','ข้าวเปลือก','compound',85),

  ('DREAM_GOLD','ทอง','primary',100),
  ('DREAM_GOLD','ทองคำ','synonym',95),
  ('DREAM_GOLD','สร้อยทอง','compound',85),
  ('DREAM_MONEY','เงิน','primary',100),
  ('DREAM_MONEY','ธนบัตร','synonym',80),
  ('DREAM_MONEY','เก็บเงินได้','compound',80),
  ('DREAM_RING','แหวน','primary',100),
  ('DREAM_HOUSE','บ้าน','primary',100),
  ('DREAM_HOUSE','บ้านใหม่','compound',85),
  ('DREAM_BOAT','เรือ','primary',100),
  ('DREAM_CAR','รถ','primary',100),
  ('DREAM_CAR','รถยนต์','synonym',90),
  ('DREAM_BRIDGE','สะพาน','primary',100),
  ('DREAM_STAIRS','บันได','primary',100),
  ('DREAM_STAIRS','ขึ้นบันได','compound',85),

  ('DREAM_FALLING','ตกจากที่สูง','primary',100),
  ('DREAM_FALLING','ตกเหว','compound',90),
  ('DREAM_FALLING','ร่วงลงมา','colloquial',75),
  ('DREAM_FLYING','บินได้','primary',100),
  ('DREAM_FLYING','ลอยได้','synonym',80),
  ('DREAM_CHASED','ถูกไล่','primary',100),
  ('DREAM_CHASED','วิ่งหนี','colloquial',90),
  ('DREAM_LOST','หลงทาง','primary',100),
  ('DREAM_BATHING','อาบน้ำ','primary',100),
  ('DREAM_EATING','กินอาหาร','primary',100),
  ('DREAM_EATING','กินข้าว','colloquial',90)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do update set
  kind = excluded.kind, weight = excluded.weight;

-- ---------------------------------------------------------------------------
-- Relations — so specific symbols connect to general ones
-- ---------------------------------------------------------------------------

insert into content.symbol_relation (symbol_id, related_id, kind)
select a.id, b.id, v.kind::content.relation_kind
from (values
  ('DREAM_NAGA','DREAM_SNAKE','variant_of'),
  ('DREAM_FLOOD','DREAM_WATER','narrower'),
  ('DREAM_RAIN','DREAM_WATER','narrower'),
  ('DREAM_SEA','DREAM_WATER','narrower'),
  ('DREAM_BABY','DREAM_CHILD','narrower'),
  ('DREAM_PAGODA','DREAM_TEMPLE','narrower'),
  ('DREAM_BUDDHA_IMAGE','DREAM_TEMPLE','see_also'),
  ('DREAM_COFFIN','DREAM_FUNERAL','see_also'),
  ('DREAM_DEAD_PERSON','DREAM_FUNERAL','see_also'),
  ('DREAM_DEAD_PERSON','DREAM_GHOST','see_also'),
  ('DREAM_GOLD','DREAM_MONEY','see_also'),
  ('DREAM_RING','DREAM_WEDDING','see_also'),
  ('DREAM_FLYING','DREAM_FALLING','contrasts_with'),
  ('DREAM_MONK','DREAM_TEMPLE','see_also'),
  ('DREAM_FRUIT','DREAM_TREE','narrower')
) as v(a_key, b_key, kind)
join content.symbol a on a.concept_key = v.a_key
join content.symbol b on b.concept_key = v.b_key
on conflict do nothing;
