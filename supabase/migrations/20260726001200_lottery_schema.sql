-- ============================================================================
-- The `lottery` schema — official draw results from สำนักงานสลากกินแบ่งรัฐบาล
--
-- WHY THIS IS NOT IN `content`
--
-- `content` holds the ตำรา library and is governed by the rights firewall: the
-- composite FK + CHECK that prevent verbatim text from a copyrighted work ever
-- being stored, and ops.assert_rights_invariants() which polices it. That
-- apparatus exists because interpretations are someone's *expression*.
--
-- Lottery results are the opposite kind of thing: facts published by a
-- government agency. Winning numbers are not a copyrightable work (พ.ร.บ.
-- ลิขสิทธิ์ พ.ศ. 2537 ม.7(1) — ข่าวประจำวันและข้อเท็จจริงต่าง ๆ ที่มีลักษณะเป็นเพียงข่าวสาร).
-- Filing them into `content` would subject public facts to a rights model built
-- for private expression, and would make every rights invariant harder to reason
-- about for no benefit. They get their own schema, with its own locks.
--
-- WHAT THE SOURCE ACTUALLY RETURNS (probed 2026-07-26, not assumed)
--
-- Two endpoints with DIFFERENT envelopes — this cost a design revision and is
-- the single most important thing recorded in this file:
--
--   POST /api/lottery/getLatestLottery   -> response.data.<tier>
--   POST /api/checking/getLotteryResult  -> response.result.data.<tier>
--        body {"date":"01","month":"03","year":"2024"}
--
-- Each tier is {price: "6000000.00", number: [{round, value}]} — `value` is a
-- STRING and leading zeros are significant (a real draw returned "097863").
-- A date with no draw returns response = null, which is an ANSWER, not an error.
--
-- The nine official tiers total exactly 173 numbers. That constant is asserted
-- in the test suite, because a truncated fetch and a real result are otherwise
-- indistinguishable, and the difference is whether a winner is told they lost.
--
-- `response.n3` (สลากดิจิทัล N3: straight3/shuffle3/straight2) is a DIFFERENT
-- product with pari-mutuel prizes that change every draw. It is deliberately
-- ignored — see lottery.prize_tier.glo_key, which enumerates exactly what we map.
-- ============================================================================

create schema if not exists lottery;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'lottery' and t.typname = 'draw_status') then
    -- 'partial' is load-bearing, not a nicety. GLO announces รางวัลที่ 1 and
    -- เลขท้าย 2 ตัว first and finishes the remaining tiers over roughly two
    -- hours. Without a distinct state, a payload fetched inside that window
    -- writes an "announced" draw missing 4th and 5th prize — and then tells
    -- 150 real winners per draw that they lost. Every fortnight, predictably.
    create type lottery.draw_status as enum
      ('scheduled', 'partial', 'announced', 'superseded');
  end if;

  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'lottery' and t.typname = 'match_kind') then
    create type lottery.match_kind as enum
      ('exact6', 'prefix3', 'suffix3', 'suffix2');
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Provenance
--
-- Mirrors how content.edition records a custodian, so an editor reads it the
-- same way — without dragging the rights firewall across. The app renders its
-- attribution FROM this row rather than from a string literal in Dart, so the
-- credit shown to a user cannot drift from the source actually used.
-- ---------------------------------------------------------------------------

create table if not exists lottery.source_registration (
  id                uuid primary key default gen_random_uuid(),
  citekey           text not null unique,
  custodian_th      text not null,
  label_th          text not null,
  api_url           text,
  catalogue_url     text,
  licence_code      text,
  licence_note_th   text,

  -- Why we may hold and republish these numbers at all. Recorded as data so the
  -- reasoning survives the person who made it.
  fact_basis_note_th text,

  first_retrieved_at timestamptz,
  status            text not null default 'published',
  created_at        timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Draws
-- ---------------------------------------------------------------------------

create table if not exists lottery.draw (
  id            uuid primary key default gen_random_uuid(),

  -- A งวด is a calendar day in Thailand, never an instant. Storing this as
  -- timestamptz would make the draw shift date for a user in another timezone.
  draw_date     date not null unique,

  period_nos    int[],
  status        lottery.draw_status not null default 'scheduled',
  announced_at  timestamptz,

  -- Bumped whenever an already-announced result set changes. The client compares
  -- it against what it cached and invalidates any "you won ฿X" it has displayed.
  -- GLO corrections are rare; silently overwriting a figure we already showed
  -- someone is not an acceptable way to handle them.
  result_revision int not null default 0,

  pdf_url       text,
  youtube_url   text,
  source_id     uuid not null references lottery.source_registration(id),

  first_seen_at timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  constraint announced_needs_timestamp
    check (status <> 'announced' or announced_at is not null)
);

-- DELIBERATELY ABSENT: a CHECK constraining draw_date to the 1st or 16th.
-- GLO moves draws. Verified against the live API: 1 มกราคม 2568 returns
-- response = null (no draw that day) while 2 พฤษภาคม 2568 is a real งวด.
-- Such a constraint would make the moved draw un-ingestable, which is the
-- failure mode where the app reports a completed draw as still pending.

comment on column lottery.draw.draw_date is
  'Calendar date of the งวด in Thailand. Comes from GLO, never computed as '
  '1st/16th — GLO moves draws (1 ม.ค. is drawn in late ธ.ค.; 16 พ.ค. 2568 was '
  'drawn 2 พ.ค.). Any client-side arithmetic here is wrong in the dangerous '
  'direction.';

-- ---------------------------------------------------------------------------
-- Prize tiers — the only place money lives
--
-- Amounts are never a literal in Dart and never fetched separately from the
-- numbers they price: a client holding this งวด's numbers and a previous
-- structure's amounts pays a user the wrong money. api.lottery_draw emits both
-- in one object for exactly that reason.
--
-- effective_from/effective_to make a future restructure a data change rather
-- than a migration, and make it impossible to price a 2014 draw with 2015
-- amounts.
-- ---------------------------------------------------------------------------

create table if not exists lottery.prize_tier (
  code           text primary key,
  name_th        text not null,
  short_name_th  text not null,
  amount_thb     bigint not null,
  winner_count   int not null,
  match_kind     lottery.match_kind not null,

  -- The GLO payload key this tier is parsed from. Keeping the mapping here
  -- rather than in plpgsql means the ingest function is data-driven, the
  -- last3f/last3b question is answered in exactly one auditable place, and
  -- anything not listed (n3.*) is ignored by construction rather than by an
  -- if-statement someone can forget to update.
  glo_key        text not null unique,

  -- Stamp duty withheld when the prize is claimed: 0.5% for สลากกินแบ่งรัฐบาล,
  -- 1% for สลากการกุศล. Held per tier so charity draws are a data change.
  -- CARRIED, NOT APPLIED: displayed prize figures are gross by product
  -- decision, and the duty is surfaced as claim guidance instead.
  duty_rate      numeric(5,4) not null default 0.0050,

  sort           int not null,
  effective_from date not null,
  effective_to   date,

  constraint amount_positive       check (amount_thb > 0),
  constraint winner_count_positive check (winner_count > 0),

  -- Lets lottery.result carry a truthful mirror of match_kind (see below).
  constraint prize_tier_code_kind unique (code, match_kind)
);

-- ---------------------------------------------------------------------------
-- Results
--
-- match_kind is MIRRORED from prize_tier through a composite FK — the same
-- device content.edition uses for work_rights. It buys a purely declarative
-- digit-length CHECK instead of a trigger, and a trigger is the wrong tool
-- here: triggers can be disabled, and are skipped by COPY.
-- ---------------------------------------------------------------------------

create table if not exists lottery.result (
  draw_id    uuid not null references lottery.draw(id) on delete cascade,
  tier_code  text not null,
  match_kind lottery.match_kind not null,
  number     text not null,
  ordinal    int  not null,

  primary key (draw_id, tier_code, number),

  foreign key (tier_code, match_kind)
    references lottery.prize_tier (code, match_kind) on update cascade,

  constraint number_is_digits check (number ~ '^[0-9]+$'),

  -- A 5-digit "6-digit" number is a parse bug that would silently never match
  -- any ticket. Rejected at write time, loudly.
  constraint number_length_matches_kind check (
    (match_kind = 'exact6'  and length(number) = 6) or
    (match_kind = 'prefix3' and length(number) = 3) or
    (match_kind = 'suffix3' and length(number) = 3) or
    (match_kind = 'suffix2' and length(number) = 2)
  )
);

-- ---------------------------------------------------------------------------
-- Raw payloads — the audit trail
--
-- Every response is retained, parsed or not. draw_id is NULLABLE on purpose:
-- a payload we could not parse is precisely the one worth keeping, and it is
-- the only way to re-parse history after GLO changes shape without re-fetching
-- a government API that may not serve old periods.
-- ---------------------------------------------------------------------------

create table if not exists lottery.raw_payload (
  id            bigserial primary key,
  draw_id       uuid references lottery.draw(id) on delete set null,
  endpoint      text not null,
  request_body  jsonb,
  response      jsonb not null,
  http_status   int,
  payload_sha256 text not null,
  ok            boolean not null default false,
  reason_th     text,
  workflow_run  text,
  fetched_at    timestamptz not null default now()
);

create index if not exists draw_date_idx        on lottery.draw (draw_date desc);
create index if not exists draw_status_idx      on lottery.draw (status, draw_date desc);
create index if not exists result_number_idx    on lottery.result (number);
create index if not exists result_tier_num_idx  on lottery.result (tier_code, number);
create index if not exists raw_payload_draw_idx on lottery.raw_payload (draw_id, fetched_at desc);

-- Retention: 400 days keeps a full year of draws re-parsable, so a shape change
-- discovered late can still be applied retroactively.
create or replace function lottery.prune_raw_payload(retain_days int default 400)
returns bigint
language plpgsql security definer set search_path = '' as $$
declare n bigint;
begin
  delete from lottery.raw_payload
   where fetched_at < now() - make_interval(days => greatest(retain_days, 30));
  get diagnostics n = row_count;
  return n;
end $$;

-- ---------------------------------------------------------------------------
-- Locks
--
-- Repeated in full because 20260726000300_rls_and_api.sql cannot reach forward:
-- its revokes, its default-privilege statements and its RLS loop all enumerate
-- 'content','editorial','ops' literally, so a schema created later inherits
-- NONE of it. The suite asserts these hold for 'lottery' too.
-- ---------------------------------------------------------------------------

revoke all on schema lottery from anon, authenticated;
revoke all on all tables    in schema lottery from anon, authenticated;
revoke all on all functions in schema lottery from public, anon, authenticated;

alter default privileges in schema lottery revoke all on tables from anon, authenticated;
alter default privileges in schema lottery revoke execute on functions from public;

-- service_role deliberately gets USAGE only and no table DML. Ingestion goes
-- through api.lottery_ingest (security definer), so the entire write surface of
-- this schema is one function with one grantee. A leaked service key can then
-- insert lottery results and nothing else — a materially better failure than a
-- role holding broad DML.
grant usage on schema lottery to service_role;

do $$
declare t record;
begin
  for t in select tablename from pg_tables where schemaname = 'lottery' loop
    execute format('alter table lottery.%I enable row level security', t.tablename);
    execute format('alter table lottery.%I force row level security',  t.tablename);
  end loop;
end $$;

comment on schema lottery is
  'Official สลากกินแบ่งรัฐบาล draw results. Public facts, deliberately kept out '
  'of content/ so the rights firewall governs expression only. Reachable solely '
  'through api.lottery_* functions; no table is exposed.';
