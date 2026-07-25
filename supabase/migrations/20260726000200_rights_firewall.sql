-- ============================================================================
-- The rights firewall
--
-- Enforces one rule: VERBATIM SOURCE TEXT MAY ONLY EXIST WHERE THE UNDERLYING
-- WORK IS FREE.  Paraphrase is always allowed; copying is not.
--
-- Implemented as composite foreign keys + CHECK constraints rather than
-- triggers, deliberately:
--
--   * a trigger can be disabled (ALTER TABLE ... DISABLE TRIGGER), skipped by
--     COPY in some configurations, and silently lost in a restore
--   * a foreign key and a check constraint cannot
--
-- The rights value is PULLED down the bibliographic chain by ON UPDATE CASCADE
-- rather than typed in at each level, so the layers cannot drift apart:
--
--   work.rights ──cascade──> edition.work_rights ──cascade──> passage.work_rights
--                                                                    │
--                                                          CHECK verbatim_requires_free_work
--
-- The behaviour this produces is the point.  Reclassifying a work downward —
-- say you discover the "ancient text" you transcribed is really a 1997 edited
-- edition — cascades to every passage and the CHECK REJECTS THE RECLASSIFICATION
-- until the verbatim text hanging off it is removed.  You cannot quietly
-- downgrade a source while infringing copies remain attached to it.
--
-- Failure is a loud error at WRITE time, never a silent leak at READ time.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Carry work rights down to the edition
-- ---------------------------------------------------------------------------

alter table content.edition
  add column work_rights content.work_rights not null default 'unknown';

-- Backfill before locking the constraint on (empty at migration time, but the
-- statement makes the intent explicit and keeps re-runs honest).
update content.edition e
   set work_rights = w.rights
  from content.work w
 where w.id = e.work_id
   and e.work_rights is distinct from w.rights;

alter table content.edition
  add constraint edition_work_rights_fk
  foreign key (work_id, work_rights)
  references content.work (id, rights)
  on update cascade;

-- Lets content.passage chain its own composite key off the edition.
alter table content.edition
  add constraint edition_id_work_rights_uniq unique (id, work_rights);

comment on column content.edition.work_rights is
  'Mirror of work.rights, maintained by ON UPDATE CASCADE — never set by hand. '
  'Exists so passage can enforce the verbatim rule declaratively. Distinct from '
  'custodian_rights, which governs this physical copy rather than the text.';

-- ---------------------------------------------------------------------------
-- Carry it one level further, to the passage, and enforce
-- ---------------------------------------------------------------------------

alter table content.passage
  add column work_rights content.work_rights not null default 'unknown';

update content.passage p
   set work_rights = e.work_rights
  from content.edition e
 where e.id = p.edition_id
   and p.work_rights is distinct from e.work_rights;

alter table content.passage
  add constraint passage_work_rights_fk
  foreign key (edition_id, work_rights)
  references content.edition (id, work_rights)
  on update cascade;

-- THE FIREWALL.
alter table content.passage
  add constraint verbatim_requires_free_work
  check (
    original_text_th is null
    or work_rights in ('public_domain','cc0','cc_by','cc_by_sa','licensed_permission')
  );

comment on constraint verbatim_requires_free_work on content.passage is
  'Verbatim source text is permitted only where the underlying work is out of '
  'copyright or explicitly licensed. Our own modern_th transcription of a public '
  'domain work is separate editorial labour and is not restricted by this rule.';

-- ---------------------------------------------------------------------------
-- Keep the mirrored columns honest on INSERT
--
-- ON UPDATE CASCADE maintains these on later changes, but a fresh INSERT could
-- still supply a stale value that happens to satisfy the FK at that instant.
-- These triggers overwrite the column from the parent so it is never authored
-- by hand. Belt and braces: the FK remains the thing that cannot be bypassed.
-- ---------------------------------------------------------------------------

create or replace function content.sync_edition_work_rights()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  select w.rights into new.work_rights
    from content.work w where w.id = new.work_id;
  return new;
end $$;

create trigger trg_sync_work_rights
  before insert or update of work_id on content.edition
  for each row execute function content.sync_edition_work_rights();

create or replace function content.sync_passage_work_rights()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  select e.work_rights into new.work_rights
    from content.edition e where e.id = new.edition_id;
  return new;
end $$;

create trigger trg_sync_work_rights
  before insert or update of edition_id on content.passage
  for each row execute function content.sync_passage_work_rights();

-- ---------------------------------------------------------------------------
-- The two-source rule
--
-- A claim derived from a single COPYRIGHTED work is a paraphrase of that work —
-- a derivative, however the sentences are rearranged. The same belief attested
-- in two independent sources is a cultural FACT, and facts are not
-- copyrightable. That distinction is the real safe harbour, so it is enforced
-- rather than left to editorial discipline.
--
-- This one must be a trigger: a CHECK constraint cannot reach across tables.
-- It is therefore backed by the assertion function below, which is scheduled.
-- ---------------------------------------------------------------------------

create or replace function content.enforce_corroboration()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  w_rights content.work_rights;
begin
  if new.status <> 'published' then
    return new;
  end if;

  select p.work_rights into w_rights
    from content.passage p where p.id = new.passage_id;

  if w_rights = 'copyrighted_cite_only'
     and coalesce(array_length(new.corroborating_edition_ids, 1), 0) < 1 then
    raise exception
      'Cannot publish interpretation %: derived from a copyrighted work with no '
      'corroborating source. Add at least one independent edition to '
      'corroborating_edition_ids (the two-source rule).', new.id
      using errcode = 'check_violation';
  end if;

  return new;
end $$;

create trigger trg_corroboration
  before insert or update of status, corroborating_edition_ids, passage_id
  on content.interpretation
  for each row execute function content.enforce_corroboration();

-- ---------------------------------------------------------------------------
-- Standing assertions — the smoke alarm
--
-- Everything above is designed to make violations impossible. Assume anyway
-- that some path was not anticipated, and check. Wire to pg_cron and alert on
-- any non-empty result.
-- ---------------------------------------------------------------------------

create or replace function ops.assert_rights_invariants()
returns table (check_name text, violations bigint, detail text)
language sql stable security definer set search_path = '' as $$
  -- Verbatim text attached to a work that is not free.
  select 'verbatim_on_encumbered_work',
         count(*),
         'passages holding original_text_th where the work is not public domain or licensed'
    from content.passage p
   where p.original_text_th is not null
     and p.work_rights not in ('public_domain','cc0','cc_by','cc_by_sa','licensed_permission')
  union all
  -- Mirrored rights drifting from the parent.
  select 'edition_rights_drift', count(*), 'edition.work_rights disagrees with work.rights'
    from content.edition e join content.work w on w.id = e.work_id
   where e.work_rights is distinct from w.rights
  union all
  select 'passage_rights_drift', count(*), 'passage.work_rights disagrees with edition.work_rights'
    from content.passage p join content.edition e on e.id = p.edition_id
   where p.work_rights is distinct from e.work_rights
  union all
  -- Published claims from copyrighted works lacking corroboration.
  select 'published_without_corroboration', count(*),
         'published interpretations from copyrighted works with no second source'
    from content.interpretation i join content.passage p on p.id = i.passage_id
   where i.status = 'published'
     and p.work_rights = 'copyrighted_cite_only'
     and coalesce(array_length(i.corroborating_edition_ids, 1), 0) < 1
  union all
  -- Published content hanging off unpublished provenance.
  select 'published_orphan_provenance', count(*),
         'published interpretations whose edition or work is not itself published'
    from content.interpretation i
    join content.passage p on p.id = i.passage_id
    join content.edition e on e.id = p.edition_id
    join content.work    w on w.id = e.work_id
   where i.status = 'published'
     and (e.status <> 'published' or w.status <> 'published');
$$;

comment on function ops.assert_rights_invariants is
  'Every row returned with violations > 0 is a defect. Schedule this and alert '
  'on any non-zero count; a passing run is not proof of correctness, only the '
  'absence of the failures we thought to look for.';

-- ---------------------------------------------------------------------------
-- updated_at maintenance
-- ---------------------------------------------------------------------------

create or replace function content.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger trg_touch before update on content.work
  for each row execute function content.touch_updated_at();
create trigger trg_touch before update on content.edition
  for each row execute function content.touch_updated_at();
create trigger trg_touch before update on content.passage
  for each row execute function content.touch_updated_at();
create trigger trg_touch before update on content.symbol
  for each row execute function content.touch_updated_at();
create trigger trg_touch before update on content.interpretation
  for each row execute function content.touch_updated_at();
