-- ============================================================================
-- Publish the เลขประจำสัญลักษณ์ from ฝันพยากรณ์
--
-- A DELIBERATE CHANGE OF POLICY, recorded because it reverses an earlier one.
--
-- The two-source rule was written to gate INTERPRETATIONS, and there it still
-- holds: a reading is a publisher's expression, and repeating one book's prose
-- is a copyright question. A NUMBER is not expression. "This ตำรา assigns 11 and
-- 77 to ช้าง" is a fact about the book, and facts are outside copyright
-- entirely (พ.ร.บ. ลิขสิทธิ์ ม.6 วรรคสอง, ม.7(1)) — the same reasoning that lets
-- the app carry GLO's winning numbers.
--
-- What remains true is that a single source can be WRONG, or can disagree with
-- another ตำรา. That is an editorial risk, not a legal one, and the project
-- owner's decision is that it should be FLAGGED rather than block publication:
-- the review agent surfaces conflicts, a human decides what to do about them.
-- scripts/review-checks.sql is amended to match — single-source numbers are a
-- warning, and a new check reports genuine disagreement between sources.
--
-- The app already tells the user what these are: "เลขเชิงสัญลักษณ์ — สร้างจาก
-- สัญลักษณ์ในฝัน ไม่ใช่โอกาสถูกรางวัล", and every reading carries the source and
-- page so a reader can check the book.
--
-- NOT published by this file: anything sensitive. The CHECK constraint would
-- refuse it anyway, which is the point of having it in the database.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- FIRST, remove numbers attached to a GENERAL symbol that belong to a specific
-- animal. An early run of the importer matched on any symbol_term, so นกยูง's
-- numbers landed on นก, ผึ้ง's on แมลง, and ปลาวาฬ's AND ปลาฉลาม's both landed
-- on ปลา — four numbers from two animals on one symbol, which would have shown
-- a user four "fish numbers" that no ตำรา ever gave for fish.
--
-- The importer now requires a primary-term match so this cannot recur, but
-- publishing is the wrong moment to discover leftovers. Defensive and
-- idempotent: on a clean database it deletes nothing.
-- ---------------------------------------------------------------------------

delete from content.number_association n
using content.symbol s
where s.id = n.symbol_id
  and s.concept_key in ('DREAM_FISH', 'DREAM_BIRD', 'DREAM_INSECT',
                        'DREAM_TIGER', 'DREAM_DOG', 'DREAM_DRAGON')
  and exists (
    -- the same number belongs to a NARROWER symbol, which is where it came from
    select 1
      from content.number_association n2
      join content.symbol_relation rel
        on rel.symbol_id = n2.symbol_id and rel.related_id = s.id
     where n2.number = n.number);

update content.number_association n
   set status = 'published'
  from content.symbol s
 where s.id = n.symbol_id
   and n.status = 'draft'
   and n.sensitivity = 'routine'
   and s.status = 'published';

-- The template's placeholder interpretation stays draft: it is a real gap
-- (ช้าง has numbers from this book but no reading yet), not something to ship.

do $$
declare r record; bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then bad := bad + 1; end if;
  end loop;
  if bad > 0 then raise exception 'aborted: % rights invariant(s)', bad; end if;
end $$;

select
  (select count(*) from content.number_association where status = 'published') as numbers_published,
  (select count(*) from content.number_association where status = 'draft')     as numbers_draft,
  (select count(distinct symbol_id) from content.number_association
     where status = 'published')                                              as symbols_with_numbers;
