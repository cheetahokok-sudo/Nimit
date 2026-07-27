-- ============================================================================
-- Lexicon v7 — วันที่ฝัน และสัญลักษณ์จากหน้า ๑๑–๑๒
--
-- Two new kinds of thing from ประมวลตำราทำนาย ภาค ๑, both absent until now.
--
-- 1. THE DAY YOU DREAMT. หน้า ๑๑ opens a section saying the day of the week
--    decides WHOM the dream concerns — Sunday everyone, Monday one's lineage,
--    Tuesday one's parents, and so on. That is not a dream symbol; it is a
--    modifier on any dream. Modelled as symbols anyway, because the existing
--    longest-match scanner then picks up "ฝันวันอังคาร" for free, and because
--    the app already knows the date a dream was recorded — so a later change
--    can look the reading up by concept_key without new plumbing.
--
--    Note the app does NOT yet apply this automatically. The content exists
--    first; wiring it to DreamEntry.createdAt is a separate, honest step.
--
-- 2. SYMBOLS WITH THEIR OWN VERDICTS. หน้า ๑๒ is structurally different from
--    pp. ๔–๑๐: instead of one shared verdict for a catalogue, each image gets
--    its own outcome — a ring means a wife and children, silk cloth means
--    living unmolested, a naga coiling round you means gaining a protector.
--    That is the richer material, and it needs symbols the library lacked.
-- ============================================================================

insert into content.symbol (concept_key, slug, name_th, name_en, category_id, status, published_at)
select v.concept_key, v.slug, v.name_th, v.name_en, c.id, 'published', now()
from (values
  ('DREAM_DAY_SUN', 'dream-day-sunday',    'ฝันวันอาทิตย์', 'dreamt on Sunday',    'omens-signs'),
  ('DREAM_DAY_MON', 'dream-day-monday',    'ฝันวันจันทร์',  'dreamt on Monday',    'omens-signs'),
  ('DREAM_DAY_TUE', 'dream-day-tuesday',   'ฝันวันอังคาร',  'dreamt on Tuesday',   'omens-signs'),
  ('DREAM_DAY_WED', 'dream-day-wednesday', 'ฝันวันพุธ',     'dreamt on Wednesday', 'omens-signs'),
  ('DREAM_DAY_THU', 'dream-day-thursday',  'ฝันวันพฤหัสบดี','dreamt on Thursday',  'omens-signs'),
  ('DREAM_DAY_FRI', 'dream-day-friday',    'ฝันวันศุกร์',   'dreamt on Friday',    'omens-signs'),
  ('DREAM_DAY_SAT', 'dream-day-saturday',  'ฝันวันเสาร์',   'dreamt on Saturday',  'omens-signs'),

  ('DREAM_EXCREMENT', 'excrement',  'อุจจาระปัสสาวะ', 'excrement',  'dream-symbols'),
  ('DREAM_LIQUOR',    'liquor',     'เหล้า',          'liquor',     'dream-symbols'),
  ('DREAM_CORPSE',    'corpse',     'ศพ',             'corpse',     'dream-symbols'),
  ('DREAM_SILK',      'silk-cloth', 'ผ้าแพร',         'silk cloth', 'dream-symbols'),
  ('DREAM_FISHING',   'fishing',    'ทอดแห',          'fishing',    'dream-symbols')
) as v(concept_key, slug, name_th, name_en, category_slug)
join content.category c on c.slug = v.category_slug
on conflict (concept_key) do nothing;

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, v.kind::content.term_kind, v.weight
from (values
  ('DREAM_DAY_SUN','ฝันวันอาทิตย์','primary',100),
  ('DREAM_DAY_SUN','ฝันคืนวันอาทิตย์','synonym',98),
  ('DREAM_DAY_MON','ฝันวันจันทร์','primary',100),
  ('DREAM_DAY_MON','ฝันคืนวันจันทร์','synonym',98),
  ('DREAM_DAY_TUE','ฝันวันอังคาร','primary',100),
  ('DREAM_DAY_TUE','ฝันคืนวันอังคาร','synonym',98),
  ('DREAM_DAY_WED','ฝันวันพุธ','primary',100),
  ('DREAM_DAY_WED','ฝันคืนวันพุธ','synonym',98),
  ('DREAM_DAY_THU','ฝันวันพฤหัสบดี','primary',100),
  ('DREAM_DAY_THU','ฝันวันพฤหัส','synonym',98),
  ('DREAM_DAY_FRI','ฝันวันศุกร์','primary',100),
  ('DREAM_DAY_FRI','ฝันคืนวันศุกร์','synonym',98),
  ('DREAM_DAY_SAT','ฝันวันเสาร์','primary',100),
  ('DREAM_DAY_SAT','ฝันคืนวันเสาร์','synonym',98),

  ('DREAM_EXCREMENT','อุจจาระ','primary',100),
  ('DREAM_EXCREMENT','ปัสสาวะ','synonym',95),
  ('DREAM_EXCREMENT','อุจจาระปัสสาวะ','synonym',96),
  ('DREAM_EXCREMENT','ขี้','colloquial',85),
  ('DREAM_LIQUOR','เหล้า','primary',100),
  ('DREAM_LIQUOR','สุรา','synonym',95),
  ('DREAM_LIQUOR','กินเหล้า','compound',92),
  ('DREAM_CORPSE','ศพ','primary',100),
  ('DREAM_CORPSE','ซากศพ','synonym',95),
  ('DREAM_SILK','ผ้าแพร','primary',100),
  ('DREAM_SILK','ผ้าไหม','synonym',92),
  ('DREAM_SILK','ผ้าแพรภูษา','synonym',95),
  ('DREAM_FISHING','ทอดแห','primary',100),
  ('DREAM_FISHING','หาปลา','synonym',95),
  ('DREAM_FISHING','ตกเบ็ด','synonym',95)
) as v(concept_key, term, kind, weight)
join content.symbol s on s.concept_key = v.concept_key
on conflict (symbol_id, term) do nothing;

-- ---------------------------------------------------------------------------
-- Did this file actually do what it says?
--
-- A total row count cannot answer that. Every insert here joins another table
-- (`content.category`, `content.symbol`), and in Postgres a join that matches
-- nothing is not an error — it is zero rows, silently. A seed can therefore
-- insert none of its content and still print a reassuring number, which is
-- exactly what made the ๑๑–๑๒ set impossible to verify from its own output.
--
-- So assert the intent, not the total. Scoped by concept_key, so it stays true
-- on a re-run.
-- ---------------------------------------------------------------------------
do $$
declare got int;
begin
  select count(*) into got from content.symbol
   where concept_key in ('DREAM_DAY_SUN','DREAM_DAY_MON','DREAM_DAY_TUE',
     'DREAM_DAY_WED','DREAM_DAY_THU','DREAM_DAY_FRI','DREAM_DAY_SAT',
     'DREAM_EXCREMENT','DREAM_LIQUOR','DREAM_CORPSE','DREAM_SILK','DREAM_FISHING')
     and status = 'published';
  if got <> 12 then
    raise exception 'lexicon v7: expected 12 published symbols, found %', got;
  end if;

  select count(*) into got from content.symbol_term t
    join content.symbol s on s.id = t.symbol_id
   where s.concept_key like 'DREAM_DAY_%'
      or s.concept_key in ('DREAM_EXCREMENT','DREAM_LIQUOR','DREAM_CORPSE',
                           'DREAM_SILK','DREAM_FISHING');
  if got <> 29 then
    raise exception 'lexicon v7: expected 29 search terms, found %', got;
  end if;
end $$;

select count(*) as published_symbols from content.symbol where status = 'published';
