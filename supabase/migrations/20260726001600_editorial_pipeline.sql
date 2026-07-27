-- ============================================================================
-- The editorial pipeline: intake → automated checks → human decision → publish
--
-- Until now content arrived by someone writing a seed file. That works for a
-- few books read carefully. It does not work for what is coming: more ตำรา, and
-- beliefs that go viral among ผู้เล่นหวย for a single งวด and are gone by the
-- next — which have to be captured while they are circulating or not at all.
--
-- THE RULE THIS SCHEMA ENFORCES: an agent may CHECK, only a human may PUBLISH.
-- Automated findings are advisory rows, never a status change. Nothing here can
-- move content to 'published'; that stays a deliberate act by an editor who has
-- read the findings. An agent that could publish would dissolve the entire
-- discipline the library is built on.
--
-- ── circulating_belief is a different KIND of claim ─────────────────────────
--
-- "ตำราพรหมชาติว่าฝันเห็นช้างคือ…" and "เดือนนี้คนแห่กันเล่นเลข ๙ เพราะ…" are not
-- the same sort of statement, and flattening them into one claim_type would let
-- a rumour inherit the credibility of a 90-year-old ตำรา. The new value keeps
-- them apart, and content.circulation records WHEN and WHERE a belief was
-- observed circulating — because for this class of content the provenance IS
-- the observation, not a page in a book.
--
-- ── The sensitivity gate ───────────────────────────────────────────────────
--
-- Beliefs attaching numbers to the monarchy, to living public figures, or to
-- national events are the ones most likely to go viral and the ones that carry
-- real legal exposure in Thailand — ม.112 among others. The gate is declarative
-- for the same reason the rights firewall is: a CHECK constraint cannot be
-- forgotten in a hurry, and "we go viral in a hurry" is precisely the situation.
--
-- Non-routine sensitivity + published REQUIRES recorded counsel clearance. Not
-- a warning, not a comment: the row will not insert.
-- ============================================================================

-- ADD VALUE runs outside the surrounding transaction in older servers and the
-- new label cannot be used until the enclosing transaction commits, so this
-- migration only DECLARES it; seeds that use it run later.
do $$
begin
  if not exists (
    select 1 from pg_enum e join pg_type t on t.oid = e.enumtypid
     where t.typname = 'claim_type' and e.enumlabel = 'circulating_belief') then
    alter type content.claim_type add value 'circulating_belief';
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'editorial' and t.typname = 'sensitivity') then
    create type editorial.sensitivity as enum (
      'routine',
      'public_figure',      -- a living named person
      'monarchy',           -- พระราชวงศ์ — ม.112 exposure
      'religion_sensitive',
      'legal_risk'          -- anything counsel has flagged for another reason
    );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- The gate, applied to both things a user can be shown
-- ---------------------------------------------------------------------------

alter table content.interpretation
  add column if not exists sensitivity editorial.sensitivity not null default 'routine',
  add column if not exists counsel_cleared boolean not null default false,
  add column if not exists counsel_note_th text;

alter table content.number_association
  add column if not exists sensitivity editorial.sensitivity not null default 'routine',
  add column if not exists counsel_cleared boolean not null default false;

alter table content.interpretation
  drop constraint if exists sensitive_needs_counsel;
alter table content.interpretation
  add constraint sensitive_needs_counsel check (
    status <> 'published' or sensitivity = 'routine' or counsel_cleared);

alter table content.number_association
  drop constraint if exists sensitive_number_needs_counsel;
alter table content.number_association
  add constraint sensitive_number_needs_counsel check (
    status <> 'published' or sensitivity = 'routine' or counsel_cleared);

comment on constraint sensitive_needs_counsel on content.interpretation is
  'Content touching the monarchy, a living public figure, religion or a '
  'counsel-flagged risk cannot reach published without recorded clearance. '
  'Declarative on purpose: this class of content is exactly what gets rushed.';

-- ---------------------------------------------------------------------------
-- Intake
-- ---------------------------------------------------------------------------

create table if not exists editorial.submission (
  id            uuid primary key default gen_random_uuid(),
  kind          text not null check (kind in ('book','circulating','correction','other')),
  title_th      text not null,
  summary_th    text,

  -- Freeform because intake must never be the thing that blocks capture. A
  -- belief circulating this งวด is gone next week; get it in, check it after.
  payload       jsonb not null default '{}'::jsonb,

  proposed_sensitivity editorial.sensitivity not null default 'routine',
  submitted_by  text,
  source_hint_th text,
  state         text not null default 'new'
                check (state in ('new','checked','approved','rejected','applied')),
  decided_by    text,
  decided_at    timestamptz,
  decision_note_th text,
  created_at    timestamptz not null default now()
);

create index if not exists submission_state_idx on editorial.submission (state, created_at desc);

-- ---------------------------------------------------------------------------
-- Automated findings — advisory only
-- ---------------------------------------------------------------------------

create table if not exists editorial.review_finding (
  id            bigserial primary key,
  submission_id uuid references editorial.submission(id) on delete cascade,

  -- Findings can also attach to content already in the library, so the same
  -- checks can sweep what is already published.
  interpretation_id uuid references content.interpretation(id) on delete cascade,

  check_code    text not null,
  severity      text not null check (severity in ('blocker','warning','note')),
  message_th    text not null,
  detail        jsonb,
  found_by      text not null default 'auto',
  found_at      timestamptz not null default now(),
  resolved      boolean not null default false,
  resolved_note_th text
);

create index if not exists finding_open_idx
  on editorial.review_finding (resolved, severity, found_at desc);

comment on table editorial.review_finding is
  'Output of automated review. ADVISORY ONLY — nothing here changes a status. '
  'An agent proposes; an editor decides.';

-- ---------------------------------------------------------------------------
-- Provenance for beliefs that circulate rather than sit in a book
-- ---------------------------------------------------------------------------

create table if not exists content.circulation (
  id            uuid primary key default gen_random_uuid(),
  symbol_id     uuid references content.symbol(id) on delete cascade,
  number        text check (number is null or number ~ '^[0-9]{1,3}$'),

  occasion_th   text not null,      -- what people connected it to
  observed_from date not null,
  observed_to   date,
  channel_th    text,               -- where it was seen circulating
  evidence_url  text,
  note_th       text,

  sensitivity   editorial.sensitivity not null default 'routine',
  counsel_cleared boolean not null default false,
  status        content.editorial_status not null default 'draft',
  created_at    timestamptz not null default now(),

  constraint circulation_sensitive_needs_counsel check (
    status <> 'published' or sensitivity = 'routine' or counsel_cleared),
  constraint circulation_has_subject check (symbol_id is not null or number is not null)
);

create index if not exists circulation_period_idx
  on content.circulation (observed_from desc);

comment on table content.circulation is
  'A belief observed circulating at a point in time — the provenance unit for '
  'viral numbers, where the evidence is the observation itself rather than a '
  'page. Dated on purpose: "people said this in ก.ค. 2569" stays true forever, '
  'whereas "people say this" rots.';

-- ---------------------------------------------------------------------------
-- Locks: editorial stays unreachable; content.circulation follows content rules
-- ---------------------------------------------------------------------------

revoke all on editorial.submission, editorial.review_finding from anon, authenticated;
revoke all on content.circulation from anon, authenticated;

alter table editorial.submission     enable row level security;
alter table editorial.submission     force  row level security;
alter table editorial.review_finding enable row level security;
alter table editorial.review_finding force  row level security;
alter table content.circulation      enable row level security;
alter table content.circulation      force  row level security;
