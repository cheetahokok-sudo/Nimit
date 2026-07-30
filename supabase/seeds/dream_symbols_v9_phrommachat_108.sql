-- ============================================================================
-- Lexicon v9 — สัญลักษณ์ใหม่จาก ตำรับทำนายฝัน ๑๐๘ ข้อ (พรหมชาติ หน้า ๒๒๗–๒๓๑)
--
-- Source: the owned 730-page พรหมชาติ ฉบับสมบูรณ์, registered by
-- sources_v8_phrommachat_owned. The 108-item dream list is the largest single
-- block of dream material this ตำรา holds, and the first one this project has
-- read from the owned copy rather than from a scan of the ๒๕๐๖ edition.
--
-- WHAT IS HERE AND WHAT IS DELIBERATELY NOT. This file creates symbols only —
-- the names of things a person can dream about. A symbol name is not anyone's
-- copyrightable expression; รองเท้า is รองเท้า. The READINGS are a different
-- matter entirely and are handled in interpretations_v12, where every one of
-- them lands as a draft. See that file for why.
--
-- Of the 108 items, 90 name a concept the lexicon already carries — งู แมว
-- สุนัข ช้าง เรือ รถ อาบน้ำ ฟันหัก ศพ พระพุทธรูป ดอกไม้ ดวงอาทิตย์ and the
-- rest. Those are NOT recreated here; they gain a reading on a new passage,
-- the same way แหวน carries readings from two different pages. Only genuinely
-- new concepts appear below.
--
-- ── One symbol here is evidence, not just vocabulary ───────────────────────
--
-- DREAM_AIRPLANE. Items ๓๒ and ๓๓ read ฝันว่า ขึ้นเครื่องบิน and ฝันว่า เห็น
-- เครื่องบินตก. An anonymous ตำรา old enough to be public domain under ม.19/21
-- cannot contain aeroplane omens. Whoever compiled this edition wrote those
-- two entries himself, and they sit in the same numbered list, in the same
-- typeface, as material that genuinely is old.
--
-- That is exactly the seam sources_v8 warned about — "the compiler's OWN
-- additions ... his copyrighted expression however old the material he is
-- explaining" — caught in the act. The word is worth recording, because people
-- do dream about aeroplanes and a later source may carry a usable reading. But
-- no reading for it may ever come from THIS book, and interpretations_v12
-- refuses to write one and asserts that none exists.
--
-- The lesson generalises: the modern layer in this compilation is not confined
-- to prefaces and worked examples. It is interleaved item by item.
-- ============================================================================

-- DRAFT, deliberately. api.search_symbols excludes draft symbols, and that is
-- the behaviour we want: a published symbol whose every reading is still a
-- draft would appear in search and then open a story screen with nothing on
-- it. A dead end reads as a broken app, not as an honest gap. These promote to
-- published together with their readings, when corroboration arrives.
insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'draft', null
from (values
  ('DREAM_CROWN',          'crown',          'มงกุฎ',        'crown',            'dream-symbols'),
  ('DREAM_PRISON',         'prison',         'คุก ตรวน',     'prison or shackles','dream-symbols'),
  ('DREAM_BEHEADING',      'beheading',      'ถูกตัดหัว',    'beheading',        'dream-symbols'),
  ('DREAM_STABBED',        'stabbed',        'ถูกแทง',       'being stabbed',    'dream-symbols'),
  ('DREAM_SOLDIER',        'soldier',        'ทหาร',         'soldier',          'dream-symbols'),
  ('DREAM_RICH_MAN',       'rich-man',       'เศรษฐี',       'a rich man',       'dream-symbols'),
  ('DREAM_NECKLACE',       'necklace',       'สร้อยคอ',      'necklace',         'dream-symbols'),
  ('DREAM_HANDKERCHIEF',   'handkerchief',   'ผ้าเช็ดหน้า',  'handkerchief',     'dream-symbols'),
  ('DREAM_HONEY',          'honey',          'น้ำผึ้ง',      'honey',            'dream-symbols'),
  ('DREAM_SHOES',          'shoes',          'รองเท้า',      'shoes',            'dream-symbols'),
  ('DREAM_LOTUS',          'lotus',          'ดอกบัว',       'lotus flower',     'dream-symbols'),
  ('DREAM_HAT',            'hat',            'หมวก',         'hat',              'dream-symbols'),
  ('DREAM_PALACE',         'palace',         'ปราสาทราชวัง', 'palace',           'dream-symbols'),
  ('DREAM_FORTUNE_TELLER', 'fortune-teller', 'หมอดู',        'fortune teller',   'dream-symbols'),
  ('DREAM_CRYING',         'crying',         'ร้องไห้',      'crying',           'dream-symbols'),
  -- Modern. See the header. Registered so the word is searchable; its reading
  -- is quarantined in interpretations_v12.
  ('DREAM_AIRPLANE',       'airplane',       'เครื่องบิน',   'aeroplane',        'dream-symbols')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

-- ---------------------------------------------------------------------------
-- Search terms. Weights follow the house scale: 100 primary, synonyms just
-- under, compounds lower. Terms are recorded now even though the symbols are
-- draft and therefore unsearchable: the vocabulary is the part that was read
-- off the page, and re-deriving it later would mean re-reading the book.
-- ---------------------------------------------------------------------------

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('DREAM_CROWN','มงกุฎ','primary',100),
  ('DREAM_CROWN','ชฎา','synonym',88),
  ('DREAM_PRISON','คุก','primary',100),
  ('DREAM_PRISON','ตะราง','synonym',96),
  ('DREAM_PRISON','ติดคุก','compound',95),
  ('DREAM_PRISON','ตรวน','synonym',92),
  ('DREAM_PRISON','โซ่ตรวน','compound',92),
  ('DREAM_PRISON','ถูกจับ','compound',85),
  ('DREAM_BEHEADING','ถูกตัดหัว','primary',100),
  ('DREAM_BEHEADING','ตัดคอ','synonym',94),
  ('DREAM_BEHEADING','ตัดศีรษะ','synonym',93),
  ('DREAM_STABBED','ถูกแทง','primary',100),
  ('DREAM_STABBED','ถูกมีดแทง','compound',96),
  ('DREAM_STABBED','โดนแทง','synonym',95),
  ('DREAM_SOLDIER','ทหาร','primary',100),
  ('DREAM_SOLDIER','เห็นทหาร','compound',90),
  ('DREAM_RICH_MAN','เศรษฐี','primary',100),
  ('DREAM_RICH_MAN','คนรวย','synonym',90),
  ('DREAM_NECKLACE','สร้อยคอ','primary',100),
  ('DREAM_NECKLACE','สร้อย','synonym',94),
  ('DREAM_NECKLACE','ใส่สร้อย','compound',90),
  ('DREAM_HANDKERCHIEF','ผ้าเช็ดหน้า','primary',100),
  ('DREAM_HONEY','น้ำผึ้ง','primary',100),
  ('DREAM_HONEY','กินน้ำผึ้ง','compound',94),
  ('DREAM_SHOES','รองเท้า','primary',100),
  ('DREAM_SHOES','ใส่รองเท้า','compound',95),
  ('DREAM_SHOES','รองเท้าใหม่','compound',93),
  ('DREAM_LOTUS','ดอกบัว','primary',100),
  ('DREAM_LOTUS','บัว','synonym',92),
  ('DREAM_HAT','หมวก','primary',100),
  ('DREAM_HAT','ใส่หมวก','compound',94),
  ('DREAM_HAT','สวมหมวก','compound',94),
  ('DREAM_PALACE','ปราสาท','primary',100),
  ('DREAM_PALACE','ราชวัง','synonym',96),
  ('DREAM_PALACE','วัง','synonym',90),
  ('DREAM_FORTUNE_TELLER','หมอดู','primary',100),
  ('DREAM_FORTUNE_TELLER','ดูดวง','compound',82),
  ('DREAM_CRYING','ร้องไห้','primary',100),
  ('DREAM_CRYING','น้ำตา','synonym',86),
  ('DREAM_AIRPLANE','เครื่องบิน','primary',100),
  ('DREAM_AIRPLANE','ขึ้นเครื่องบิน','compound',95),
  ('DREAM_AIRPLANE','เครื่องบินตก','compound',95)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

-- ---------------------------------------------------------------------------
-- Guard. If the category slug ever changes, the join above silently inserts
-- nothing and the file looks like it ran. Say so instead.
-- ---------------------------------------------------------------------------
do $$
declare got int;
begin
  select count(*) into got from content.symbol
   where concept_key in ('DREAM_CROWN','DREAM_PRISON','DREAM_BEHEADING',
     'DREAM_STABBED','DREAM_SOLDIER','DREAM_RICH_MAN','DREAM_NECKLACE',
     'DREAM_HANDKERCHIEF','DREAM_HONEY','DREAM_SHOES','DREAM_LOTUS','DREAM_HAT',
     'DREAM_PALACE','DREAM_FORTUNE_TELLER','DREAM_CRYING','DREAM_AIRPLANE');
  if got <> 16 then
    raise exception 'phrommachat 108 lexicon: expected 16 symbols, found % — '
      'check that category dream-symbols exists', got;
  end if;
end $$;
