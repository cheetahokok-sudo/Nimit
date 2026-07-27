-- ============================================================================
-- Retire the placeholder number rows now that the real book has been read
--
-- interpretations_v5_owned_books_template.sql seeded two draft rows for ช้าง
-- ('00' and '0') explicitly marked "รอยืนยันจากเล่มจริง" — invented shapes to
-- prove the pipeline had somewhere to put numbers.
--
-- The real reading exists now: ฝันพยากรณ์ หน้า 7 gives ช้าง = 11 และ 77, and
-- หน้า 11 confirms it reciprocally (77 → 11). Leaving the placeholders would
-- mean ช้าง carried four numbers, two of them made up by me, sitting in the
-- same draft queue as sourced ones and indistinguishable from them once a
-- reviewer stopped reading the note.
--
-- Deleting rather than superseding: they never recorded a belief anyone held.
-- ============================================================================

delete from content.number_association n
using content.symbol s
where s.id = n.symbol_id
  and s.concept_key = 'DREAM_ELEPHANT'
  and n.status = 'draft'
  and n.number in ('0', '00')
  and n.note_th like '%รอยืนยันจากเล่มจริง%';

-- The draft interpretation from the same template is left alone on purpose: it
-- still marks a real gap (ช้าง has no reading from this book yet, only numbers)
-- and the review sweep reports it as such.

select
  (select count(*) from content.number_association) as number_rows,
  (select count(*) from content.number_association where status = 'draft') as draft,
  (select string_agg(n.number, ',' order by n.number)
     from content.number_association n
     join content.symbol s on s.id = n.symbol_id
    where s.concept_key = 'DREAM_ELEPHANT') as elephant_numbers;
