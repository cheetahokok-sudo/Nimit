-- ============================================================================
-- Nimit content library — core schema
--
-- Schema topology (the rights firewall is a SCHEMA boundary, not a column
-- check — PostgREST is structurally incapable of reaching what it cannot see):
--
--   editorial  verbatim excerpts from rights-encumbered works, scan pointers,
--              permission letters, editor notes.  NEVER in the exposed-schemas
--              list.  No PostgREST route exists to it.
--   content    the publishable library.  RLS on, zero grants to anon.
--   api        views + RPC.  The ONLY schema anon/authenticated may touch.
--   ops        counters and access logs.  Not exposed.
--
-- Bibliographic model follows FRBR-style layering, because rights differ per
-- layer and conflating them is the central legal hazard of this project:
--
--   work        the abstract text ("ตำราทำนายฝัน").  Usually PUBLIC DOMAIN —
--               a 19th-century สมุดไทย is long out of copyright.
--   edition     one manifestation of that work (a specific D-Library scanned
--               item, or the กรมศิลปากร 2508 print).  The CUSTODIAN may assert
--               rights over THIS COPY even when the work itself is free.
--   passage     a located chunk within an edition (folio / page).
--
-- The practical consequence, which the whole schema exists to encode:
--   * reproducing the TEXT of a public-domain work is governed by work.rights
--   * redistributing SOMEONE ELSE'S SCAN is governed by edition.custodian_rights
-- These are different permissions and must never be collapsed into one flag.
-- ============================================================================

create extension if not exists pg_trgm;

create schema if not exists content;
create schema if not exists editorial;
create schema if not exists ops;

-- ---------------------------------------------------------------------------
-- Enumerations
-- ---------------------------------------------------------------------------

-- Trust tier. Measures VERIFIABILITY OF PROVENANCE — explicitly not predictive
-- accuracy. Mirrors app/lib/data/models/source.dart; SourceTier.fromCode()
-- fails closed to 'd', so an unknown code can never be badged as A1.
create type content.trust_tier as enum ('a1','a2','b1','b2','c','d');

-- What KIND of statement a claim is. This is the fact / belief / opinion
-- separation the product's trust proposition rests on, made explicit per claim
-- rather than per article.
create type content.claim_type as enum (
  'historical_belief',   -- "ตำรา X ระบุว่า…" — attested in a source
  'cultural_context',    -- background explaining practice or provenance
  'modern_opinion',      -- a named contemporary practitioner's reading
  'factual_info'         -- verifiable fact (draw dates, probability, history)
);

-- Rights in the underlying WORK.  Defaults to the most restrictive value.
create type content.work_rights as enum (
  'public_domain',
  'cc0','cc_by','cc_by_sa',
  'licensed_permission',      -- written permission held; see editorial.rights_grant
  'copyrighted_cite_only',    -- CITE + PARAPHRASE ONLY.  Never verbatim.
  'unknown'                   -- DEFAULT.  Behaves as most restrictive.
);

-- Why a work is out of copyright.  Grounded in พ.ร.บ. ลิขสิทธิ์ พ.ศ. 2537.
create type content.pd_basis as enum (
  'author_died_50y',      -- s.19 — the usual basis for ตำราโบราณ
  'published_50y_anon',   -- anonymous / pseudonymous / juristic-person author
  'government_material',  -- s.7 — legislation, regulations, official notices
  'pre_copyright_era',
  'explicit_dedication'
);

-- What the CUSTODIAN of a particular copy asserts.  Independent of work rights:
-- D-Library asserts All Rights Reserved over scans of works that are themselves
-- centuries out of copyright.
create type content.custodian_rights as enum (
  'open',                 -- no restriction asserted
  'cc_by','cc_by_sa','cc_by_nc','cc_by_nc_nd','cc_by_nd',
  'all_rights_reserved',
  'permission_granted',   -- we hold written permission for this copy
  'unknown'
);

-- Editorial workflow.  Public read sees ONLY 'published'.
create type content.editorial_status as enum (
  'draft','needs_sources','in_review','approved','published','retracted','archived'
);

-- Who signed off.  Different claims need different expertise; a paleographer
-- is not qualified to clear rights and a lawyer cannot read อักษรธรรมล้านนา.
create type content.reviewer_role as enum (
  'paleography','astrology_history','buddhist_studies','legal','editorial'
);

-- ---------------------------------------------------------------------------
-- Reference tables
-- ---------------------------------------------------------------------------

-- Tier wording lives in the DB so it can be corrected without an app release.
-- Badge COLOURS stay in Dart (core/widgets/source_badge.dart) keyed on the enum.
create table content.tier_definition (
  tier              content.trust_tier primary key,
  title_th          text        not null,
  description_th    text        not null,
  sort              smallint    not null,
  -- From the Trust Framework: may a claim at this tier stand as a core answer?
  allowed_as_core   boolean     not null,
  allowed_for_trend boolean     not null,
  citation_rule_th  text        not null
);

create table content.category (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,
  name_th     text not null,
  domain_th   text not null,
  sort        smallint not null default 100,
  -- Per-domain safety framing from the Taxonomy sheet, e.g. medical, financial
  -- and relationship-determinism warnings. Surfaced in the UI, not just policy.
  ethics_note_th text
);

-- สำนัก / lineage.  First-class so the product can show that พรหมชาติ editions
-- disagree, instead of flattening them into one answer.
create table content.tradition (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,
  name_th     text not null,
  note_th     text
);

-- ---------------------------------------------------------------------------
-- work — the abstract text
-- ---------------------------------------------------------------------------

create table content.work (
  id                uuid primary key default gen_random_uuid(),
  slug              text not null unique,
  canonical_title_th text not null,
  title_variants_th text[] not null default '{}',
  attributed_author_th text,
  composed_period_th text,

  rights            content.work_rights not null default 'unknown',
  pd_basis          content.pd_basis,
  copyright_holder  text,
  rights_note_th    text,
  rights_verified_by text,
  rights_verified_at timestamptz,

  status            content.editorial_status not null default 'draft',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint work_pd_needs_basis
    check (rights <> 'public_domain' or pd_basis is not null),
  constraint work_copyrighted_needs_holder
    check (rights <> 'copyrighted_cite_only' or copyright_holder is not null),

  -- Load-bearing: lets content.passage build a DECLARATIVE foreign key on the
  -- rights value rather than duplicating it. See 20260726000200.
  unique (id, rights)
);

comment on table content.work is
  'The abstract text. Rights here govern reproduction of the TEXT. A 19th-century '
  'manuscript work is normally public_domain even when every surviving scan of it '
  'is asserted All Rights Reserved by its custodian.';

-- ---------------------------------------------------------------------------
-- edition — one manifestation, held by one custodian
-- ---------------------------------------------------------------------------

create table content.edition (
  id                uuid primary key default gen_random_uuid(),
  work_id           uuid not null references content.work(id) on delete restrict,
  citekey           text not null unique,     -- ascii, stable, e.g. 'nlt-3742'
  tier              content.trust_tier not null,

  label_th          text not null,            -- 'ฉบับกรมศิลปากร พ.ศ. 2508'
  custodian_th      text not null,            -- 'สำนักหอสมุดแห่งชาติ'
  publisher_th      text,
  -- Never rely on title alone to identify a manuscript.
  stable_identifier text,                     -- 'เลขทะเบียน 447', 'RBR003-012'
  shelfmark         text,
  year_published    int,
  year_original     int,                      -- a modern reprint of an old text
  edition_statement text,
  isbn              text,
  physical_desc_th  text,                     -- 'สมุดไทยขาว 66 หน้า'
  script_th         text,                     -- 'อักษรธรรมล้านนา', 'ขอมไทย'
  languages         text[] not null default '{th}',
  url               text,
  archive_url       text,

  -- What the holder of THIS COPY asserts. Distinct from work.rights.
  custodian_rights  content.custodian_rights not null default 'unknown',
  rights_note_th    text,

  status            content.editorial_status not null default 'draft',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index on content.edition (work_id);
create index on content.edition (tier);

comment on column content.edition.custodian_rights is
  'Governs redistribution of THIS COPY (its scans, its edited text). Says nothing '
  'about the underlying work: cc_by_nc_nd here blocks reusing the custodian''s '
  'images, but does not re-copyright a public-domain text.';

-- ---------------------------------------------------------------------------
-- passage — a located chunk of an edition
-- ---------------------------------------------------------------------------

create table content.passage (
  id            uuid primary key default gen_random_uuid(),
  edition_id    uuid not null references content.edition(id) on delete cascade,
  -- Mandatory. Every interpretation must be traceable to a specific place.
  locator       text not null,                -- 'folio 12 หน้า', 'หน้า 27'
  sequence      int,

  -- Verbatim source text. Guarded by constraints in 20260726000200 — permitted
  -- only when the WORK is free. Nullable and normally null.
  original_text_th text,
  -- Our own transcription into modern orthography. A transcription of a PD work
  -- is our editorial labour, and is ours to publish.
  modern_th     text,
  transcribed_by text,
  transcription_note_th text,

  status        content.editorial_status not null default 'draft',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  unique (edition_id, locator, sequence)
);

create index on content.passage (edition_id);

-- ---------------------------------------------------------------------------
-- symbol — the concept layer users actually search
-- ---------------------------------------------------------------------------

create table content.symbol (
  id          uuid primary key default gen_random_uuid(),
  -- Stable taxonomy key, e.g. 'DREAM_SNAKE'. Never renumbered.
  concept_key text not null unique,
  slug        text not null unique,           -- ascii, URL-safe
  name_th     text not null,
  name_en     text,
  category_id uuid not null references content.category(id) on delete restrict,
  -- ORIGINAL editorial prose only. Always safe to ship.
  summary_th  text,
  ethics_note_th text,
  status      content.editorial_status not null default 'draft',
  published_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index on content.symbol (category_id);
create index on content.symbol (status);

-- Relations between symbols, so งูเหลือม can narrow งู without duplicating text.
create type content.relation_kind as enum
  ('variant_of','narrower','broader','see_also','contrasts_with');

create table content.symbol_relation (
  symbol_id   uuid not null references content.symbol(id) on delete cascade,
  related_id  uuid not null references content.symbol(id) on delete cascade,
  kind        content.relation_kind not null,
  primary key (symbol_id, related_id, kind),
  constraint no_self_relation check (symbol_id <> related_id)
);

-- ---------------------------------------------------------------------------
-- Thai lookup terms
--
-- DELIBERATELY NOT postgres full-text search.  Thai is written without word
-- spaces and Postgres ships no Thai dictionary, so
--   to_tsvector('simple','ฝันเห็นงูเผือกหน้าบ้าน')
-- yields ONE token.  FTS here fails while appearing to work in casual testing,
-- which is worse than not having it.  A curated term index is also simply the
-- right model for a dream dictionary.
-- ---------------------------------------------------------------------------

create type content.term_kind as enum
  ('primary','synonym','colloquial','regional','misspelling','compound');

-- Normalisation: strip zero-width chars, collapse whitespace, fold Thai digits
-- to Arabic, lowercase Latin.
create or replace function content.norm_th(t text)
returns text language sql immutable strict as $$
  select lower(
           btrim(
             regexp_replace(
               translate(
                 regexp_replace(t, '[​‌‍﻿]', '', 'g'),
                 '๐๑๒๓๔๕๖๗๘๙', '0123456789'
               ),
               '\s+', ' ', 'g'
             )
           )
         );
$$;

-- Looser form: additionally strips Thai tone marks (U+0E48–U+0E4B) and
-- thanthakhat (U+0E4C).  Wrong or missing tone marks are the single most common
-- Thai input error, and matter for matching but not for meaning.
create or replace function content.norm_loose_th(t text)
returns text language sql immutable strict as $$
  select regexp_replace(content.norm_th(t), '[่-์]', '', 'g');
$$;

-- Portable wrapper around pg_trgm's similarity().
--
-- Needed because the API functions run with `search_path = ''` (correct for
-- SECURITY DEFINER), which makes unqualified extension functions unresolvable —
-- and pg_trgm does not live in the same schema everywhere: vanilla Postgres
-- puts it in `public`, Supabase in `extensions`. Hard-coding either breaks the
-- other. This wrapper carries its own search_path so callers can stay strict.
create or replace function content.sim(a text, b text)
returns real language sql immutable strict
set search_path = public, extensions
as $$ select similarity(a, b); $$;

create table content.symbol_term (
  id          uuid primary key default gen_random_uuid(),
  symbol_id   uuid not null references content.symbol(id) on delete cascade,
  term        text not null,
  kind        content.term_kind not null,
  weight      smallint not null default 100,   -- ranking when several match
  term_norm   text generated always as (content.norm_th(term)) stored,
  term_loose  text generated always as (content.norm_loose_th(term)) stored,
  unique (symbol_id, term)
);

create index on content.symbol_term (term_norm);
create index symbol_term_loose_trgm on content.symbol_term using gin (term_loose gin_trgm_ops);
-- Longest-match dictionary scan over dream text reads terms longest-first, so
-- งูเหลือม wins over งู. This sidesteps Thai word segmentation entirely: we only
-- ever look for terms we already hold entries for.
create index symbol_term_len on content.symbol_term ((length(term_norm)) desc);

-- ---------------------------------------------------------------------------
-- interpretation — a sourced claim about a symbol
-- ---------------------------------------------------------------------------

create table content.interpretation (
  id            uuid primary key default gen_random_uuid(),
  symbol_id     uuid not null references content.symbol(id) on delete cascade,
  -- No orphan claims: every interpretation points at a passage, which points at
  -- an edition, which points at a work. Provenance is structural.
  passage_id    uuid not null references content.passage(id) on delete restrict,
  tradition_id  uuid references content.tradition(id) on delete set null,

  -- ALWAYS our own prose. Always shippable regardless of source rights.
  body_th       text not null,
  claim_type    content.claim_type not null,
  context_note_th text,
  prevalence    smallint check (prevalence between 0 and 100),

  -- Corroboration. Enforced for copyright-derived claims in 20260726000200:
  -- a belief attested in several independent sources is a cultural FACT, which
  -- is not copyrightable. Paraphrasing one book is a derivative work.
  corroborating_edition_ids uuid[] not null default '{}',

  status        content.editorial_status not null default 'draft',
  published_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index on content.interpretation (symbol_id);
create index on content.interpretation (passage_id);
create index on content.interpretation (status);

comment on column content.interpretation.body_th is
  'Original editorial prose, never a copy of the source. Trust tier is NOT stored '
  'here — it is joined from edition.tier so a badge can never disagree with the '
  'bibliography it claims to come from.';

-- ---------------------------------------------------------------------------
-- number_association — เลขเชิงสัญลักษณ์
-- ---------------------------------------------------------------------------

create table content.number_association (
  id            uuid primary key default gen_random_uuid(),
  symbol_id     uuid not null references content.symbol(id) on delete cascade,
  -- TEXT, not integer: '09' and '9' are different symbols, and DreamAnalysis
  -- already carries List<String>.
  number        text not null check (number ~ '^[0-9]{1,3}$'),
  passage_id    uuid references content.passage(id) on delete set null,
  tradition_id  uuid references content.tradition(id) on delete set null,
  note_th       text,
  status        content.editorial_status not null default 'draft',
  created_at    timestamptz not null default now(),
  unique (symbol_id, number, tradition_id)
);

create index on content.number_association (symbol_id);

-- ---------------------------------------------------------------------------
-- review — sign-off, per required expertise
-- ---------------------------------------------------------------------------

create table content.review (
  id            uuid primary key default gen_random_uuid(),
  entity_type   text not null check (entity_type in
                  ('work','edition','passage','symbol','interpretation','number_association')),
  entity_id     uuid not null,
  role          content.reviewer_role not null,
  reviewer      text not null,
  verdict       text not null check (verdict in ('checked','approved','rejected')),
  note_th       text,
  reviewed_at   timestamptz not null default now()
);

create index on content.review (entity_type, entity_id);

-- ---------------------------------------------------------------------------
-- revision — append-only history
--
-- When a takedown notice or accuracy complaint arrives, this answers "who added
-- this claim, when, citing what" in one query. That capability is worth more
-- than it costs.
-- ---------------------------------------------------------------------------

create table content.revision (
  id            bigserial primary key,
  entity_type   text not null,
  entity_id     uuid not null,
  revision      int  not null,
  data          jsonb not null,
  changed_by    text,
  changed_at    timestamptz not null default now(),
  note          text,
  unique (entity_type, entity_id, revision)
);

create index on content.revision (entity_type, entity_id);

create or replace function content.record_revision()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  next_rev int;
  eid uuid;
begin
  eid := case when tg_op = 'DELETE' then old.id else new.id end;
  select coalesce(max(r.revision), 0) + 1 into next_rev
    from content.revision r
   where r.entity_type = tg_table_name and r.entity_id = eid;
  insert into content.revision (entity_type, entity_id, revision, data, changed_by, note)
  values (
    tg_table_name, eid, next_rev,
    to_jsonb(case when tg_op = 'DELETE' then old else new end),
    current_user, tg_op
  );
  return case when tg_op = 'DELETE' then old else new end;
end $$;

create trigger trg_revision after insert or update or delete on content.work
  for each row execute function content.record_revision();
create trigger trg_revision after insert or update or delete on content.edition
  for each row execute function content.record_revision();
create trigger trg_revision after insert or update or delete on content.passage
  for each row execute function content.record_revision();
create trigger trg_revision after insert or update or delete on content.symbol
  for each row execute function content.record_revision();
create trigger trg_revision after insert or update or delete on content.interpretation
  for each row execute function content.record_revision();

-- ---------------------------------------------------------------------------
-- editorial — never exposed through the API
-- ---------------------------------------------------------------------------

-- Verbatim excerpts from rights-encumbered works, held so editors can write
-- paraphrases from them. Legitimate under research/quotation handling; must
-- never reach a client. Safety rests on the schema boundary, not on a flag.
create table editorial.source_excerpt (
  id            uuid primary key default gen_random_uuid(),
  passage_id    uuid references content.passage(id) on delete cascade,
  edition_id    uuid references content.edition(id) on delete cascade,
  excerpt_text  text not null,
  locator       text,
  captured_by   text,
  captured_at   timestamptz not null default now(),
  note          text,
  constraint excerpt_needs_anchor check (passage_id is not null or edition_id is not null)
);

-- Pointers into a PRIVATE storage bucket. Never public URLs to third-party scans.
create table editorial.scan_ref (
  id            uuid primary key default gen_random_uuid(),
  edition_id    uuid not null references content.edition(id) on delete cascade,
  storage_path  text not null,
  page_label    text,
  -- Redistribution of a scan is governed by the CUSTODIAN's terms, separately
  -- from the underlying work's copyright status.
  may_redistribute boolean not null default false,
  note          text,
  created_at    timestamptz not null default now()
);

create table editorial.rights_grant (
  id            uuid primary key default gen_random_uuid(),
  edition_id    uuid references content.edition(id) on delete set null,
  work_id       uuid references content.work(id) on delete set null,
  grantor       text not null,
  scope_th      text not null,           -- exactly what was permitted
  permits_commercial boolean not null default false,
  permits_derivative boolean not null default false,
  permits_verbatim   boolean not null default false,
  document_path text,                    -- the signed letter, private bucket
  granted_at    date,
  expires_at    date,
  note_th       text
);

-- Acquisition / permission tracking. Internal operational state.
create table editorial.acquisition (
  id            uuid primary key default gen_random_uuid(),
  edition_id    uuid references content.edition(id) on delete cascade,
  registry_ref  text,                    -- e.g. 'NIM-A1-011' from the v1 sheet
  priority      text not null default 'P2' check (priority in ('P0','P1','P2')),
  stage         text not null default 'metadata'
                  check (stage in ('metadata','outreach','negotiating','granted','denied','blocked')),
  owner_role    text,
  contacted_at  date,
  responded_at  date,
  note_th       text,
  updated_at    timestamptz not null default now()
);

create table editorial.editor_note (
  id            uuid primary key default gen_random_uuid(),
  entity_type   text not null,
  entity_id     uuid not null,
  author        text,
  body          text not null,
  created_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- ops
-- ---------------------------------------------------------------------------

create table ops.api_access (
  id          bigserial primary key,
  fn          text not null,
  actor       uuid,
  arg_digest  text,
  row_count   int,
  at          timestamptz not null default now()
);

create index on ops.api_access (fn, at desc);
