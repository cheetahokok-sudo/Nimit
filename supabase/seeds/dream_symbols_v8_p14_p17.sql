-- ============================================================================
-- Lexicon v8 — สัญลักษณ์จากหน้า ๑๔–๑๗ (ปิดหมวดตำราทำนายฝัน)
--
-- หน้า ๑๗ closes the dream section with a rule across the page: ตำราทำนายฝัน
-- runs ๑–๑๗, and everything from ๑๘ on is คำทำนายสัตว์ตก, a different domain
-- entirely. So this is the last lexicon file the dream section will need from
-- this edition.
--
-- Six symbols these pages name already exist and are NOT recreated here — เต่า,
-- ม้า, ไฟ, บินได้, วัด, พระพุทธรูป. They gain a second reading on a new passage,
-- the same way แหวน carries both a หน้า ๑๒ and a หน้า ๑๓ reading. Two pages of
-- one book saying related things is normal and the app shows both with their
-- locators.
--
-- WHAT IS NEW IN THIS STRETCH: the ตำรา starts prescribing REMEDIES. A dream of
-- fire is not simply a bad omen — it says to go and แก้ at a flowing river, and
-- the trouble turns back. Elsewhere it says to ทำขวัญ first, then the gain
-- follows. That is a different kind of claim from "this means that", and the
-- readings carry it in the body text rather than flattening it to a verdict.
-- ============================================================================

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'published', now()
from (values
  ('DREAM_DRINK_WATER', 'drinking-water', 'กินน้ำ',         'drinking water',      'dream-symbols'),
  ('DREAM_PARASOL',     'parasol',        'กลด ร่ม',        'parasol',             'dream-symbols'),
  ('DREAM_CHANTING',    'chanting',       'สวดมนต์',        'chanting prayers',    'dream-symbols'),
  ('DREAM_BRAHMIN',     'brahmin',        'พราหมณ์',        'brahmin',             'dream-symbols'),
  ('DREAM_TEACHER',     'teacher',        'ครูอาจารย์',     'teacher',             'dream-symbols'),
  ('DREAM_RED_CLOTHES', 'red-clothes',    'นุ่งแดง',        'wearing red',         'dream-symbols'),
  ('DREAM_MONK_ROBE',   'monk-robe',      'ผ้ากาสาวพัสตร์', 'monastic robe',       'dream-symbols'),
  ('DREAM_NOBLE_LADY',  'noble-lady',     'นางพญา',         'noble lady',          'dream-symbols'),
  ('DREAM_LAMP',        'lamp',           'ประทีป เทียน',   'lamp or candle',      'dream-symbols'),
  ('DREAM_STUPA',       'stupa',          'เจดีย์',         'stupa',               'dream-symbols')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('DREAM_DRINK_WATER','กินน้ำ','primary',100),
  ('DREAM_DRINK_WATER','ดื่มน้ำ','synonym',98),
  ('DREAM_DRINK_WATER','กินชลสุธา','synonym',90),
  ('DREAM_PARASOL','กลด','primary',100),
  ('DREAM_PARASOL','ร่ม','synonym',95),
  ('DREAM_PARASOL','กางร่ม','compound',92),
  ('DREAM_PARASOL','กั้นกลด','compound',92),
  ('DREAM_CHANTING','สวดมนต์','primary',100),
  ('DREAM_CHANTING','สวดพุทธมนต์','synonym',96),
  ('DREAM_CHANTING','ไหว้พระสวดมนต์','synonym',94),
  ('DREAM_BRAHMIN','พราหมณ์','primary',100),
  ('DREAM_TEACHER','อาจารย์','primary',100),
  ('DREAM_TEACHER','ครู','synonym',96),
  ('DREAM_TEACHER','ครูบาอาจารย์','synonym',95),
  ('DREAM_RED_CLOTHES','นุ่งแดง','primary',100),
  ('DREAM_RED_CLOTHES','ใส่ชุดแดง','synonym',95),
  ('DREAM_RED_CLOTHES','นุ่งห่มแดง','synonym',96),
  ('DREAM_MONK_ROBE','ผ้ากาสาวพัสตร์','primary',100),
  ('DREAM_MONK_ROBE','ผ้าเหลือง','synonym',92),
  ('DREAM_MONK_ROBE','นุ่งห่มกาสาว์','synonym',94),
  ('DREAM_MONK_ROBE','ห่มจีวร','synonym',90),
  ('DREAM_NOBLE_LADY','นางพญา','primary',100),
  ('DREAM_NOBLE_LADY','นางงาม','synonym',90),
  ('DREAM_LAMP','ประทีป','primary',100),
  ('DREAM_LAMP','เทียน','synonym',95),
  ('DREAM_LAMP','จุดเทียน','compound',92),
  ('DREAM_STUPA','เจดีย์','primary',100),
  ('DREAM_STUPA','พระเจดีย์','synonym',96),
  ('DREAM_STUPA','พระจุฬามณี','synonym',90),

  -- Added to symbols that already exist. The scanner had no way to reach
  -- DREAM_FLYING from the words this page actually uses.
  ('DREAM_FLYING','เหาะ','synonym',96),
  ('DREAM_FLYING','เหาะเหิน','synonym',95),
  ('DREAM_FLYING','เดินกลางเวหา','synonym',88),
  ('DREAM_FIRE','ไฟไหม้','compound',96),
  ('DREAM_TEMPLE','กุฏิ','synonym',90),
  ('DREAM_TEMPLE','วิหาร','synonym',92),
  ('DREAM_BUDDHA_IMAGE','พระปฏิมา','synonym',94)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

-- ---------------------------------------------------------------------------
-- Assert the intent, not the total. See dream_symbols_v7_p11_p12.sql for why:
-- these inserts join content.category and content.symbol, and a join that
-- matches nothing is zero rows, not an error.
-- ---------------------------------------------------------------------------
do $$
declare got int;
begin
  select count(*) into got from content.symbol
   where concept_key in ('DREAM_DRINK_WATER','DREAM_PARASOL','DREAM_CHANTING',
     'DREAM_BRAHMIN','DREAM_TEACHER','DREAM_RED_CLOTHES','DREAM_MONK_ROBE',
     'DREAM_NOBLE_LADY','DREAM_LAMP','DREAM_STUPA')
     and status = 'published';
  if got <> 10 then
    raise exception 'lexicon v8: expected 10 published symbols, found %', got;
  end if;

  -- The six pre-existing symbols must still be reachable by the words these
  -- pages use; a rename upstream would silently strand the new readings.
  select count(*) into got from content.symbol_term t
    join content.symbol s on s.id = t.symbol_id
   where (s.concept_key, t.term) in (
     ('DREAM_TURTLE','เต่า'), ('DREAM_HORSE','ม้า'), ('DREAM_FIRE','ไฟไหม้'),
     ('DREAM_FLYING','เหาะ'), ('DREAM_TEMPLE','วิหาร'),
     ('DREAM_BUDDHA_IMAGE','พระปฏิมา'));
  if got <> 6 then
    raise exception 'lexicon v8: expected 6 carry-over terms, found %', got;
  end if;
end $$;

select count(*) as published_symbols from content.symbol where status = 'published';
