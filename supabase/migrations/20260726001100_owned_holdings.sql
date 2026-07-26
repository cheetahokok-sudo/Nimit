-- ============================================================================
-- editorial.holding — how we are entitled to READ a source
--
-- Added because the model had a gap that was slowing real work. It recorded
-- whether a work's TEXT could be reproduced (work.rights) and whether a
-- CUSTODIAN's copy could be redistributed (edition.custodian_rights), but had
-- nowhere to record the ordinary case that unblocks most editorial work:
--
--   "we own a legitimate copy of this book and may read it."
--
-- Reading a book you own has never required permission. Extracting the FACTS
-- from it — which beliefs a culture holds — is outside copyright entirely
-- (s.6 ¶2, s.7(1)). Writing those facts up in your own prose and citing the
-- book is normal scholarship. None of that was ever blocked by the firewall;
-- the CHECK constraint only guards passage.original_text_th, the verbatim
-- column. The suite has always asserted "paraphrase permitted on a
-- copyrighted work".
--
-- What this table adds is PROVENANCE for the reading right, so an editor
-- looking at a row six months later can tell why it was lawful to work from
-- that source, and counsel review is recorded rather than remembered.
-- ============================================================================

create table if not exists editorial.holding (
  id            uuid primary key default gen_random_uuid(),
  edition_id    uuid not null references content.edition(id) on delete cascade,
  copy_type     text not null check (copy_type in
                  ('owned_physical','owned_digital','library_access','publisher_licence')),
  acquired_note_th text,

  -- Counsel sign-off is recorded, not assumed. A named reviewer and a date
  -- are what make this defensible later; "the lawyer said it was fine" in
  -- someone's memory is not.
  counsel_reviewed boolean not null default false,
  counsel_name     text,
  counsel_note_th  text,
  reviewed_at      date,

  created_at    timestamptz not null default now(),
  unique (edition_id, copy_type)
);

create index if not exists holding_edition_idx on editorial.holding (edition_id);

comment on table editorial.holding is
  'Records HOW we may lawfully read a source (owned copy, library access, '
  'publisher licence). Distinct from work.rights (may we reproduce the text) '
  'and edition.custodian_rights (may we redistribute this copy). Reading and '
  'fact-extraction from an owned copy needs no permission; this table exists '
  'so that entitlement is documented rather than assumed.';

-- Not exposed: editorial schema is outside the API surface by design.
revoke all on editorial.holding from anon, authenticated;
alter table editorial.holding enable row level security;
alter table editorial.holding force row level security;
