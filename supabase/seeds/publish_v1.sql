-- ============================================================================
-- Publish the safe layer
--
-- Until this runs, everything is status='draft' and the API correctly returns
-- nothing: api.library_stats reports zeros and api.search_symbols returns [].
-- The database is live but invisible.
--
-- WHAT IS PUBLISHED, and why each is safe to publish:
--
--   content.symbol   Thai headwords and vocabulary. A symbol name makes no
--                    claim about meaning, so it needs no source and can carry
--                    no misattribution.
--   content.work
--   content.edition  Bibliography. Citations are MEANT to be public — a product
--                    whose pitch is verifiable sourcing must let anyone check
--                    them. This also makes api.cite() resolvable, since it
--                    filters on status='published'.
--
-- WHAT IS NOT PUBLISHED:
--
--   content.interpretation      Zero rows exist and none may exist until
--                               someone has read a manuscript we are cleared to
--                               use. Publishing an invented meaning would be
--                               fabricating a citation, which is precisely what
--                               the A1–D apparatus exists to prevent.
--   content.passage             Zero rows; carries verbatim source text.
--   content.number_association  Zero rows; carries sourced claims.
--   status='archived' rows      BLOCKED-proommachat-thep is copyrighted until
--                               พ.ศ. 2586. The WHERE clauses below target
--                               'draft' only, so archived rows are untouched by
--                               construction rather than by remembering to
--                               exclude them.
--
-- Idempotent: re-running publishes only whatever is still draft.
-- ============================================================================

begin;

-- Provenance first. A citation must resolve before anything can point at it,
-- and ops.assert_rights_invariants() flags published content whose work or
-- edition is not itself published.
update content.work
   set status = 'published'
 where status = 'draft';

update content.edition
   set status = 'published'
 where status = 'draft';

update content.symbol
   set status = 'published',
       published_at = coalesce(published_at, now())
 where status = 'draft';

-- ---------------------------------------------------------------------------
-- Refuse to commit if publishing broke an invariant.
--
-- Publishing is the moment orphaned provenance and uncorroborated claims would
-- become visible, so check here rather than trusting that it went fine.
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
  bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then
      raise warning 'invariant % : % violations (%)', r.check_name, r.violations, r.detail;
      bad := bad + 1;
    end if;
  end loop;
  if bad > 0 then
    raise exception 'Publish aborted: % invariant(s) violated. Nothing was committed.', bad;
  end if;
end $$;

-- Belt and braces: the blocked copyrighted upload must never be published,
-- whatever else happens above.
do $$
declare n int;
begin
  select count(*) into n from content.work
   where slug = 'BLOCKED-proommachat-thep' and status = 'published';
  if n > 0 then
    raise exception 'Publish aborted: the BLOCKED copyrighted work became published.';
  end if;
end $$;

commit;

-- Report what is now visible through the API.
select
  (select count(*) from content.work           where status = 'published') as works_published,
  (select count(*) from content.edition        where status = 'published') as editions_published,
  (select count(*) from content.symbol         where status = 'published') as symbols_published,
  (select count(*) from content.interpretation where status = 'published') as interpretations_published,
  (select count(*) from content.work           where status = 'archived')  as works_archived;
