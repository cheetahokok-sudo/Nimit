-- ============================================================================
-- Verification suite for the rights firewall, Thai lookup and access control.
--
-- Deliberately free of psql meta-commands (\set, \echo) so the same file runs
-- under both runners:
--
--   psql -v ON_ERROR_STOP=1 -f supabase/tests/rights_firewall_test.sql
--   supabase db query --linked --file supabase/tests/rights_firewall_test.sql
--
-- The second route goes through the Management API, which rejects meta-commands —
-- and being able to verify the LIVE database, not just a local copy, is worth
-- more than the formatting they provided.
--
-- Every check raises an exception on failure, so a clean run means every
-- assertion below actually held. Runs in a transaction and rolls back.
-- ============================================================================

begin;

-- Results are accumulated into a table and selected at the end, not just raised
-- as NOTICEs. The Management API returns rows but discards notices, so without
-- this the only evidence of success over that route is the absence of an error
-- — and "nothing went wrong" is a much weaker claim than "34 checks ran and
-- each one asserted what it was supposed to".
create temporary table check_log (
  seq     serial primary key,
  section text,
  name    text,
  detail  text
) on commit drop;

create or replace function pg_temp.section(t text)
returns void language plpgsql as $$
begin
  insert into check_log (section, name) values (t, '--- section ---');
  raise notice '';
  raise notice '== % ==', t;
end $$;

create or replace function pg_temp.log_pass(what text, detail text default null)
returns void language plpgsql as $$
begin
  insert into check_log (section, name, detail)
  values ((select section from check_log order by seq desc limit 1), what, detail);
  raise notice '  PASS  % %', what, coalesce('(' || detail || ')', '');
end $$;

create or replace function pg_temp.expect_fail(sql text, what text)
returns void language plpgsql as $$
begin
  begin
    execute sql;
  exception when others then
    perform pg_temp.log_pass(what, 'rejected: ' || left(sqlerrm, 60));
    return;
  end;
  raise exception 'FAIL: % — the statement was ACCEPTED but should have been rejected', what;
end $$;

create or replace function pg_temp.expect_ok(sql text, what text)
returns void language plpgsql as $$
begin
  execute sql;
  perform pg_temp.log_pass(what);
end $$;

create or replace function pg_temp.expect_eq(actual anyelement, expected anyelement, what text)
returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAIL: % — expected %, got %', what, expected, actual;
  end if;
  perform pg_temp.log_pass(what, '= ' || expected::text);
end $$;

-- ---------------------------------------------------------------------------
select pg_temp.section('1. Rights firewall: verbatim text');
-- ---------------------------------------------------------------------------

insert into content.work (slug, canonical_title_th, rights, pd_basis, status)
values ('t-pd', 'ตำราทดสอบ (พ้นลิขสิทธิ์)', 'public_domain', 'published_50y_anon', 'draft');

insert into content.work (slug, canonical_title_th, rights, copyright_holder, status)
values ('t-cr', 'ตำราทดสอบ (มีลิขสิทธิ์)', 'copyrighted_cite_only', 'สำนักพิมพ์ทดสอบ', 'draft');

insert into content.edition (work_id, citekey, tier, label_th, custodian_th)
select id, 't-pd-ed', 'a1', 'ฉบับทดสอบ', 'สถาบันทดสอบ' from content.work where slug = 't-pd';

insert into content.edition (work_id, citekey, tier, label_th, custodian_th)
select id, 't-cr-ed', 'b2', 'ฉบับทดสอบ', 'สำนักพิมพ์ทดสอบ' from content.work where slug = 't-cr';

-- The mirrored rights columns must be populated by the sync triggers, not left
-- at the 'unknown' default.
select pg_temp.expect_eq(
  (select work_rights::text from content.edition where citekey = 't-pd-ed'),
  'public_domain', 'edition.work_rights mirrors work.rights on insert');

select pg_temp.expect_eq(
  (select work_rights::text from content.edition where citekey = 't-cr-ed'),
  'copyrighted_cite_only', 'edition.work_rights mirrors a copyrighted work');

select pg_temp.expect_ok($$
  insert into content.passage (edition_id, locator, original_text_th, modern_th)
  select id, 'folio 1', 'ข้อความต้นฉบับที่พ้นลิขสิทธิ์แล้ว', 'คำปริวรรตปัจจุบัน'
    from content.edition where citekey = 't-pd-ed'
$$, 'verbatim text permitted on a public-domain work');

select pg_temp.expect_fail($$
  insert into content.passage (edition_id, locator, original_text_th)
  select id, 'page 12', 'ข้อความคัดลอกจากหนังสือที่ยังมีลิขสิทธิ์'
    from content.edition where citekey = 't-cr-ed'
$$, 'verbatim text BLOCKED on a copyrighted work');

-- Paraphrase against the same copyrighted work is always allowed. That is the
-- whole point: citing and paraphrasing is legitimate, copying is not.
select pg_temp.expect_ok($$
  insert into content.passage (edition_id, locator, modern_th)
  select id, 'page 12', 'สรุปความด้วยสำนวนของเราเอง'
    from content.edition where citekey = 't-cr-ed'
$$, 'paraphrase permitted on a copyrighted work');

-- ---------------------------------------------------------------------------
select pg_temp.section('2. Reclassification cascade');
-- ---------------------------------------------------------------------------

-- The scenario where you discover your "ancient text" was really a 1997 edited
-- edition: the database refuses to let you relabel it while infringing copies
-- still hang off it.
select pg_temp.expect_fail($$
  update content.work set rights = 'copyrighted_cite_only',
                          pd_basis = null,
                          copyright_holder = 'ผู้ตรวจชำระ พ.ศ. 2540'
   where slug = 't-pd'
$$, 'reclassifying PD -> copyrighted BLOCKED while verbatim text exists');

update content.passage p set original_text_th = null
  from content.edition e
 where e.id = p.edition_id and e.citekey = 't-pd-ed';

select pg_temp.expect_ok($$
  update content.work set rights = 'copyrighted_cite_only',
                          pd_basis = null,
                          copyright_holder = 'ผู้ตรวจชำระ พ.ศ. 2540'
   where slug = 't-pd'
$$, 'reclassification succeeds once verbatim text is removed');

select pg_temp.expect_eq(
  (select p.work_rights::text from content.passage p
     join content.edition e on e.id = p.edition_id where e.citekey = 't-pd-ed' limit 1),
  'copyrighted_cite_only', 'reclassification cascaded work -> edition -> passage');

update content.work set rights = 'public_domain', pd_basis = 'published_50y_anon',
       copyright_holder = null where slug = 't-pd';

-- ---------------------------------------------------------------------------
select pg_temp.section('3. Constraint integrity');
-- ---------------------------------------------------------------------------

select pg_temp.expect_fail($$
  insert into content.work (slug, canonical_title_th, rights, status)
  values ('t-nobasis', 'ตำราไม่ระบุเหตุผล', 'public_domain', 'draft')
$$, 'public_domain without pd_basis BLOCKED');

select pg_temp.expect_fail($$
  insert into content.work (slug, canonical_title_th, rights, status)
  values ('t-noholder', 'ตำราไม่ระบุเจ้าของสิทธิ์', 'copyrighted_cite_only', 'draft')
$$, 'copyrighted without copyright_holder BLOCKED');

-- ---------------------------------------------------------------------------
select pg_temp.section('4. Two-source rule');
-- ---------------------------------------------------------------------------

insert into content.symbol (concept_key, slug, name_th, category_id, status)
select 'T_SYM', 't-sym', 'สัญลักษณ์ทดสอบ', id, 'draft'
  from content.category where slug = 'dream-symbols';

select pg_temp.expect_fail($$
  insert into content.interpretation
    (symbol_id, passage_id, body_th, claim_type, status)
  select s.id, p.id, 'คำอธิบายด้วยสำนวนของเรา', 'historical_belief', 'published'
    from content.symbol s, content.passage p
    join content.edition e on e.id = p.edition_id
   where s.concept_key = 'T_SYM' and e.citekey = 't-cr-ed' limit 1
$$, 'publishing from a lone copyrighted source BLOCKED');

select pg_temp.expect_ok($$
  insert into content.interpretation
    (symbol_id, passage_id, body_th, claim_type, status)
  select s.id, p.id, 'ร่างคำอธิบาย', 'historical_belief', 'draft'
    from content.symbol s, content.passage p
    join content.edition e on e.id = p.edition_id
   where s.concept_key = 'T_SYM' and e.citekey = 't-cr-ed' limit 1
$$, 'draft from a lone copyrighted source allowed');

-- Provenance must be published before anything resting on it can be. Publishing
-- a claim whose source edition is still a draft would show users a citation
-- they cannot follow; ops.assert_rights_invariants() flags exactly that, and it
-- caught this fixture the first time round.
update content.work    set status = 'published' where slug in ('t-pd','t-cr');
update content.edition set status = 'published' where citekey in ('t-pd-ed','t-cr-ed');
update content.passage p set status = 'published'
  from content.edition e where e.id = p.edition_id and e.citekey in ('t-pd-ed','t-cr-ed');

select pg_temp.expect_ok($$
  update content.interpretation
     set corroborating_edition_ids =
           array(select id from content.edition where citekey = 't-pd-ed'),
         summary_plain_th = 'สรุปสั้นสำหรับทดสอบ',
         status = 'published'
   where body_th = 'ร่างคำอธิบาย'
$$, 'publishing allowed once corroborated by a second source');

-- ---------------------------------------------------------------------------
select pg_temp.section('5. Standing assertions');
-- ---------------------------------------------------------------------------

do $$
declare r record;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then
      raise exception 'FAIL: invariant % reported % violations (%)',
        r.check_name, r.violations, r.detail;
    end if;
    perform pg_temp.log_pass('invariant ' || r.check_name, '= 0');
  end loop;
end $$;

-- ---------------------------------------------------------------------------
select pg_temp.section('6. Thai normalisation and lookup');
-- ---------------------------------------------------------------------------

select pg_temp.expect_eq(content.norm_th('  งู  '), 'งู', 'norm trims whitespace');
select pg_temp.expect_eq(content.norm_th('๑๖'), '16', 'norm folds Thai digits');
select pg_temp.expect_eq(content.norm_loose_th('เสือ'), content.norm_loose_th('เสื่อ'),
  'loose norm makes tone-mark variants equal');

select pg_temp.expect_eq(
  (select term from content.symbol_term
    where term_norm = content.norm_th('งูเหลือม') limit 1),
  'งูเหลือม', 'compound term indexed distinctly from the generic term');

-- Draft exclusion, checked against a fixture this test owns rather than
-- against seed state. The previous version asserted that a search for งู
-- returned nothing "while all symbols are draft" — true only until the library
-- was published, at which point a correct system would have failed the test.
-- A test that breaks when the product starts working is testing the wrong
-- thing.
insert into content.symbol_term (symbol_id, term, kind, weight)
select id, 'สัญลักษณ์ทดสอบเฉพาะกิจ', 'primary', 100
  from content.symbol where concept_key = 'T_SYM';

select pg_temp.expect_eq(
  (select count(*)::int from api.search_symbols('สัญลักษณ์ทดสอบเฉพาะกิจ', 30)), 0,
  'search excludes a DRAFT symbol');

update content.symbol set status = 'published' where concept_key = 'T_SYM';

select pg_temp.expect_eq(
  (select slug from api.search_symbols('สัญลักษณ์ทดสอบเฉพาะกิจ', 5) limit 1), 't-sym',
  'search finds the same symbol once PUBLISHED');

update content.symbol set status = 'published' where concept_key = 'DREAM_SNAKE';

select pg_temp.expect_eq(
  (select slug from api.search_symbols('งู', 5) limit 1), 'snake',
  'search finds a published symbol by exact term');

select pg_temp.expect_eq(
  (select slug from api.search_symbols('งูเหลือม', 5) limit 1), 'snake',
  'search resolves a compound term');

select pg_temp.expect_fail($$select * from api.search_symbols('ง', 5)$$,
  'search rejects a 1-character query');

select pg_temp.expect_eq(
  (select count(*)::int from api.search_symbols('งู', 9999)) <= 30, true,
  'search caps rows regardless of requested max');

-- ---------------------------------------------------------------------------
select pg_temp.section('7. Access control');
-- ---------------------------------------------------------------------------

-- Catches a well-meaning GRANT added later through the Studio UI.
select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_table_grants
    where grantee in ('anon','authenticated')
      and table_schema in ('content','editorial','ops','lottery')), 0,
  'anon/authenticated hold ZERO grants in content, editorial, ops and lottery');

select pg_temp.expect_eq(
  (select count(*)::int from pg_tables t
     join pg_class c on c.relname = t.tablename
     join pg_namespace n on n.oid = c.relnamespace and n.nspname = t.schemaname
    where t.schemaname in ('content','editorial','ops','lottery')
      and not (c.relrowsecurity and c.relforcerowsecurity)), 0,
  'every protected table has RLS enabled and forced');

select pg_temp.expect_eq(
  (select count(*)::int from pg_policies
    where schemaname in ('content','editorial','ops','lottery')), 0,
  'no permissive policies exist on protected tables');

-- Assert on the ACL itself, not on a role grant and not on an HTTP status.
--
-- The original version of this check only looked for an `anon` grant, and
-- passed while PUBLIC still held EXECUTE — which anon inherits. A live probe
-- appeared to confirm the block, but the 500 it returned was the function's own
-- 'symbol not found', not a permission denial. Two different mistakes agreeing
-- with each other is not corroboration.
--
-- In PostgreSQL ACL notation an empty grantee before '=' means PUBLIC. Match
-- per ACL ENTRY, not against the joined string: a substring test for '=X/'
-- also matches 'postgres=X/postgres', which would fail on a correctly locked
-- function. A null proacl means default privileges, which include PUBLIC.
select pg_temp.expect_eq(
  (select count(*)::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'api' and p.proname = 'get_symbol'
      and (p.proacl is null
           or exists (select 1 from unnest(p.proacl) a where a::text like '=%'))), 0,
  'PUBLIC cannot execute api.get_symbol (no empty-grantee ACL entry)');

select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee = 'anon' and routine_schema = 'api'
      and routine_name = 'get_symbol'), 0,
  'anon holds no explicit grant on api.get_symbol');

select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee = 'authenticated' and routine_schema = 'api'
      and routine_name = 'get_symbol') > 0, true,
  'authenticated CAN execute api.get_symbol');

-- No internal helper may be callable from the API surface.
select pg_temp.expect_eq(
  (select count(*)::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('content','ops','lottery')
      and (p.proacl is null
           or exists (select 1 from unnest(p.proacl) a where a::text like '=%'))), 0,
  'PUBLIC cannot execute any function in content, ops or lottery');

-- Every function reachable from the API must pin its search_path, so a caller
-- cannot shadow what the body resolves.
select pg_temp.expect_eq(
  (select count(*)::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('api','content','ops','lottery')
      and p.prokind = 'f'
      and (p.proconfig is null
           or not exists (select 1 from unnest(p.proconfig) c where c like 'search_path=%'))), 0,
  'every function in api, content, ops and lottery pins search_path');

select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee = 'anon' and routine_schema = 'api'
      and routine_name = 'search_symbols') > 0, true,
  'anon CAN execute api.search_symbols');

-- ---------------------------------------------------------------------------
select pg_temp.section('8. Read path actually executes');
-- ---------------------------------------------------------------------------
-- get_symbol shipped declared STABLE while inserting into the access log,
-- which PostgreSQL rejects at runtime (0A000) — so the flagship read function
-- failed for every legitimate caller. It survived review because the suite
-- only ever asserted on its ACLs and every live probe was rejected at the
-- permission gate before the body ran. Lesson encoded here: a function whose
-- only exercised path is "denied" is untested where it matters. EXECUTE it.

select pg_temp.expect_eq(
  (select (api.get_symbol('snake') ->> 'slug')), 'snake',
  'get_symbol executes end-to-end and returns the symbol');

-- State-agnostic: the array must exist and its length must equal the number
-- of published interpretations — zero before content lands, real counts after.
-- (An earlier version asserted length 0, which broke the day content shipped:
-- a test that fails when the product starts working tests the wrong thing.)
select pg_temp.expect_eq(
  (select jsonb_array_length(api.get_symbol('snake') -> 'interpretations')),
  (select count(*)::int from content.interpretation i
     join content.symbol s on s.id = i.symbol_id
    where s.slug = 'snake' and i.status = 'published'),
  'get_symbol interpretations array matches published count');

select pg_temp.expect_eq(
  (select count(*)::int from ops.api_access
    where fn = 'get_symbol' and at > now() - interval '1 minute') > 0, true,
  'get_symbol logged the access (write is legal: function is volatile)');

-- Ranking: results must be ordered by match weight across symbols, not by
-- slug. Two fixture symbols share a term with different weights; the heavier
-- one must come first even though its slug sorts later alphabetically.
insert into content.symbol (concept_key, slug, name_th, category_id, status)
select 'T_RANK_HEAVY', 'zz-heavy', 'ทดสอบอันดับหนัก', id, 'published'
  from content.category where slug = 'dream-symbols';
insert into content.symbol (concept_key, slug, name_th, category_id, status)
select 'T_RANK_LIGHT', 'aa-light', 'ทดสอบอันดับเบา', id, 'published'
  from content.category where slug = 'dream-symbols';
insert into content.symbol_term (symbol_id, term, kind, weight)
select id, 'คำทดสอบอันดับ', 'primary', 100 from content.symbol where concept_key = 'T_RANK_HEAVY';
insert into content.symbol_term (symbol_id, term, kind, weight)
select id, 'คำทดสอบอันดับ', 'synonym', 50 from content.symbol where concept_key = 'T_RANK_LIGHT';

select pg_temp.expect_eq(
  (select slug from api.search_symbols('คำทดสอบอันดับ', 5) limit 1), 'zz-heavy',
  'search ranks by weight across symbols, not alphabetically by slug');

-- Real content, when present, must be complete: this suite runs both before
-- and after interpretations_v1.sql, so assert SHAPE consistency rather than a
-- fixed count. Whatever number of published interpretations exist for snake,
-- get_symbol must return exactly that many; and each must carry the fields
-- the trust apparatus promises — a tier from the edition, own prose, and a
-- verbatim quote ONLY where the work is free.
do $$
declare
  expected int;
  payload jsonb;
  item jsonb;
begin
  select count(*) into expected
    from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where s.slug = 'snake' and i.status = 'published';

  payload := api.get_symbol('snake');

  if jsonb_array_length(payload -> 'interpretations') <> expected then
    raise exception
      'FAIL: get_symbol returns % interpretations, % are published',
      jsonb_array_length(payload -> 'interpretations'), expected;
  end if;
  perform pg_temp.log_pass(
    'get_symbol returns every published interpretation', '= ' || expected);

  if expected > 0 then
    item := payload -> 'interpretations' -> 0;
    if item ->> 'tier' is null or item ->> 'textTh' is null then
      raise exception 'FAIL: interpretation missing tier or body';
    end if;
    if item ->> 'quoteTh' is not null then
      -- A quote implies the underlying work is free; re-derive and confirm.
      if not exists (
        select 1 from content.interpretation i
          join content.passage p on p.id = i.passage_id
          join content.symbol s on s.id = i.symbol_id
         where s.slug = 'snake' and i.status = 'published'
           and p.work_rights in
             ('public_domain','cc0','cc_by','cc_by_sa','licensed_permission')
      ) then
        raise exception 'FAIL: quoteTh emitted for a non-free work';
      end if;
    end if;
    perform pg_temp.log_pass(
      'published interpretation carries tier, body and lawful quote handling');
  end if;
end $$;

-- Editorial completeness: every published interpretation carries its
-- plain-language summary (ภาษาชาวบ้าน). A published row without one renders
-- as a wall of prose for exactly the readers the product serves.
select pg_temp.expect_eq(
  (select count(*)::int from content.interpretation
    where status = 'published' and summary_plain_th is null), 0,
  'every published interpretation has a plain-language summary');

-- Buddhist canon must NEVER produce number associations — permanent policy,
-- asserted so a future seed cannot quietly cross the line. Covers every
-- canonical edition (citekey tipitaka-*) and the whole buddhist-canon
-- tradition, not just the first text ingested.
select pg_temp.expect_eq(
  (select count(*)::int from content.number_association n
     left join content.passage p on p.id = n.passage_id
     left join content.edition e on e.id = p.edition_id
     left join content.tradition tr on tr.id = n.tradition_id
    where e.citekey like 'tipitaka-%' or tr.slug = 'buddhist-canon'), 0,
  'no number associations derive from Buddhist canonical text');

-- Seed idempotency: the acquisition tracker must have a unique constraint so
-- ON CONFLICT DO NOTHING actually has something to conflict with. Without it,
-- every seed re-run silently duplicated the outreach list.
select pg_temp.expect_eq(
  (select count(*)::int from pg_constraint c
     join pg_class t on t.oid = c.conrelid
     join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'editorial' and t.relname = 'acquisition'
      and c.contype = 'u') >= 1, true,
  'acquisition tracker carries a unique constraint for idempotent seeds');

-- ---------------------------------------------------------------------------
select pg_temp.section('9. analyze_dream — the core loop');
-- ---------------------------------------------------------------------------

-- This assertion used to read expect_fail(analyze_dream('งู')) — it required
-- the matcher to REJECT the Thai word for snake, and passed for months while
-- doing it. The floor was four code points, งู is two, and the test agreed with
-- the code instead of with the product. Thirty-six curated terms were
-- unreachable behind it.
--
-- A test can only defend a boundary if the boundary is right. The floor is now
-- the shortest curated term, so what must be rejected is input below THAT, and
-- what must be accepted is every word the library actually holds.
select pg_temp.expect_fail($$select api.analyze_dream('ก')$$,
  'analyze rejects input below the shortest curated term');

select pg_temp.expect_eq(
  (select jsonb_array_length(api.analyze_dream('งู') -> 'symbols')), 1,
  'a single short Thai word finds its symbol — งู is a dream, not a typo');

select pg_temp.expect_eq(
  (select count(*)::int from content.symbol_term t
     join content.symbol s on s.id = t.symbol_id
    where s.status = 'published'
      and length(t.term_norm) < content.dream_min_len()), 0,
  'no published term is shorter than the matcher will accept');

select pg_temp.expect_eq(
  (select jsonb_array_length(api.analyze_dream('ประชุมเรื่องงบประมาณประจำปี') -> 'symbols')), 0,
  'analyze returns honest empty for text with no known symbols');

-- Snake was published by the earlier fixture, so it must be found; its
-- interpretation count must mirror what is actually published (0 in the
-- draft CI phase, real counts live) — same state-agnostic pattern as before.
do $$
declare
  payload jsonb;
  expected int;
begin
  payload := api.analyze_dream('เมื่อคืนฝันเห็นงูเผือกตัวใหญ่เลื้อยเข้ามาในบ้าน');

  if not exists (
    select 1 from jsonb_array_elements(payload -> 'symbols') e
    where e ->> 'slug' = 'snake'
  ) then
    raise exception 'FAIL: analyze did not surface the snake symbol';
  end if;
  perform pg_temp.log_pass('analyze surfaces the snake from a dream sentence');

  -- บ้าน is published? Only in live runs; count interpretations for exactly
  -- the symbols the call matched, so the assertion is state-agnostic.
  select count(*) into expected
    from content.interpretation i
    join content.symbol s on s.id = i.symbol_id
   where i.status = 'published'
     and s.slug in (
       select e ->> 'slug' from jsonb_array_elements(payload -> 'symbols') e);

  if jsonb_array_length(payload -> 'interpretations') <> least(expected, 12) then
    raise exception 'FAIL: analyze returned % interpretations, % published for matched symbols',
      jsonb_array_length(payload -> 'interpretations'), expected;
  end if;
  perform pg_temp.log_pass('analyze returns every published interpretation for its matches',
    '= ' || least(expected, 12));

  -- Numbers must come only from published associations — with canon-only
  -- content that means EMPTY, and never anything else invented.
  if (select count(*) from jsonb_array_elements_text(payload -> 'numbers')) <>
     (select count(distinct n.number) from content.number_association n
       where n.status = 'published'
         and n.symbol_id in (select s.id from content.symbol s
                              where s.slug in (
                                select e ->> 'slug'
                                from jsonb_array_elements(payload -> 'symbols') e)))
  then
    raise exception 'FAIL: analyze numbers do not match published associations';
  end if;
  perform pg_temp.log_pass('analyze numbers come only from published associations');
end $$;

select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee = 'anon' and routine_schema = 'api'
      and routine_name = 'analyze_dream') > 0, true,
  'anon CAN execute api.analyze_dream (the product front door)');

-- Span resolution: shorter terms of OTHER symbols must not fire inside a
-- longer claimed match. Found live: ท้อง (pregnancy) fired inside ท้องฟ้า
-- (sky), so a dream about the sky reported a pregnancy omen.
--
-- These assertions test the MATCHING ALGORITHM, so they build their own
-- fixtures rather than relying on seed content. An earlier version used the
-- real ท้อง/ท้องฟ้า pair and passed against the live database but failed in
-- CI's draft state, where the lexicon adding ท้องฟ้า had not been applied yet
-- — so ท้อง fired legitimately, with nothing longer to suppress it. A test
-- that depends on which seeds happen to have run is testing the fixtures, not
-- the code. The surrounding transaction rolls all of this back.

insert into content.symbol (concept_key, slug, name_th, category_id, status)
select v.k, v.s, v.n, c.id, 'published'
from (values
  ('T_SPAN_LONG',  't-span-long',  'คำทดสอบยาว'),
  ('T_SPAN_SHORT', 't-span-short', 'คำทดสอบสั้น'),
  ('T_DUAL_A',     't-dual-a',     'คู่ทดสอบเอ'),
  ('T_DUAL_B',     't-dual-b',     'คู่ทดสอบบี')
) as v(k, s, n)
cross join (select id from content.category where slug = 'dream-symbols' limit 1) c;

insert into content.symbol_term (symbol_id, term, kind, weight)
select s.id, v.term, 'primary', 100
from (values
  -- 'ฟ้าทดสอบยาว' strictly contains 'ทดสอบ': the short term must be suppressed.
  ('T_SPAN_LONG',  'ฟ้าทดสอบยาว'),
  ('T_SPAN_SHORT', 'ทดสอบ'),
  -- Identical term on two symbols: an equal span must surface BOTH.
  ('T_DUAL_A',     'สัตว์ผสมทดสอบ'),
  ('T_DUAL_B',     'สัตว์ผสมทดสอบ')
) as v(k, term)
join content.symbol s on s.concept_key = v.k;

do $$
declare payload jsonb;
begin
  payload := api.analyze_dream('เมื่อคืนฝันเห็นฟ้าทดสอบยาวลอยอยู่');
  if exists (select 1 from jsonb_array_elements(payload -> 'symbols') e
              where e ->> 'slug' = 't-span-short') then
    raise exception
      'FAIL: a shorter foreign term fired inside a longer claimed span';
  end if;
  if not exists (select 1 from jsonb_array_elements(payload -> 'symbols') e
                  where e ->> 'slug' = 't-span-long') then
    raise exception 'FAIL: the longer term did not match at all';
  end if;
  perform pg_temp.log_pass('shorter foreign terms suppressed inside longer spans');
end $$;

do $$
declare payload jsonb;
begin
  payload := api.analyze_dream('เมื่อคืนฝันเห็นสัตว์ผสมทดสอบบินอยู่');
  if not (exists (select 1 from jsonb_array_elements(payload -> 'symbols') e
                   where e ->> 'slug' = 't-dual-a')
      and exists (select 1 from jsonb_array_elements(payload -> 'symbols') e
                   where e ->> 'slug' = 't-dual-b')) then
    raise exception
      'FAIL: equal-span dual mapping lost — one term on two symbols must surface both';
  end if;
  perform pg_temp.log_pass('equal-span compounds still surface both symbols');
end $$;

-- ---------------------------------------------------------------------------
select pg_temp.section('10. Lottery — official draw results');
-- ---------------------------------------------------------------------------
-- Everything in this section guards one outcome: a user being shown the wrong
-- money, or being told they lost when they won. Fixtures are built inside this
-- transaction and roll back with it, so no seed step is needed.

-- --- Money integrity ------------------------------------------------------
-- Two constants that are properties of the published GLO prize structure. A
-- typo in the reference seed changes one of them, and CI fails here instead of
-- a user reading a wrong figure on a screen.
select pg_temp.expect_eq(
  (select sum(winner_count)::int from lottery.prize_tier where effective_to is null), 173,
  'a draw is exactly 173 winning numbers');

select pg_temp.expect_eq(
  (select sum(amount_thb * winner_count)::bigint from lottery.prize_tier
    where effective_to is null), 12018000::bigint,
  'the prize pool per draw is exactly 12,018,000 baht');

-- The mapping that pays different people if reversed. Verified against งวด
-- 16 ธันวาคม 2567, where GLO returned last3f = 290,742 (published as เลขหน้า)
-- and last3b = 339,881 (published as เลขท้าย). The key names read the other
-- way round, which is exactly why this is pinned.
select pg_temp.expect_eq(
  (select match_kind::text from lottery.prize_tier where glo_key = 'last3f'), 'prefix3',
  'GLO last3f maps to เลขหน้า 3 ตัว (prefix match)');

select pg_temp.expect_eq(
  (select match_kind::text from lottery.prize_tier where glo_key = 'last3b'), 'suffix3',
  'GLO last3b maps to เลขท้าย 3 ตัว (suffix match)');

-- --- Access control -------------------------------------------------------
select pg_temp.expect_eq(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'api' and p.proname = 'lottery_ingest'
      and (p.proacl is null
           or exists (select 1 from unnest(p.proacl) a where a::text like '=%'))), 0,
  'PUBLIC cannot execute api.lottery_ingest (no empty-grantee ACL entry)');

select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee in ('anon','authenticated') and routine_schema = 'api'
      and routine_name = 'lottery_ingest'), 0,
  'neither anon nor authenticated may execute api.lottery_ingest');

select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee = 'service_role' and routine_schema = 'api'
      and routine_name = 'lottery_ingest') > 0, true,
  'service_role CAN execute api.lottery_ingest (the sole write path)');

-- EXECUTE on a function is worthless without USAGE on its schema, and the two
-- are checked independently. Shipping without this grant produced
-- "permission denied for schema api" on every ingestion attempt while the ACL
-- assertion above passed — the same shape of failure as api.get_symbol, where
-- the suite inspected privileges instead of exercising them.
select pg_temp.expect_eq(
  has_schema_privilege('service_role', 'api', 'usage'), true,
  'service_role has USAGE on schema api (EXECUTE alone cannot reach it)');

-- And the assertion that actually settles it: hold the role and CALL the
-- function. Any missing privilege in the chain raises here rather than in
-- production at 16:30 on a draw day.
do $$
declare v jsonb;
begin
  set local role service_role;
  v := api.lottery_ingest('{"response": null}'::jsonb, 'suite-role-check', 200, 'suite');
  reset role;

  if v ->> 'outcome' <> 'no_draw' then
    raise exception 'FAIL: service_role call returned %, expected no_draw', v;
  end if;
  perform pg_temp.log_pass(
    'service_role can actually CALL api.lottery_ingest, not merely be granted it');
exception when others then
  reset role;
  raise;
end $$;

-- The other side of the same coin: anon must NOT be able to reach it.
do $$
declare denied boolean := false;
begin
  begin
    set local role anon;
    perform api.lottery_ingest('{"response": null}'::jsonb, 'suite-anon-check', 200, 'suite');
    reset role;
  exception when insufficient_privilege then
    denied := true;
    reset role;
  end;
  if not denied then
    raise exception 'FAIL: anon was able to call api.lottery_ingest';
  end if;
  perform pg_temp.log_pass('anon is denied when it actually tries to call api.lottery_ingest');
end $$;

select pg_temp.expect_eq(
  (select count(distinct routine_name)::int from information_schema.role_routine_grants
    where grantee = 'anon' and routine_schema = 'api'
      and routine_name in ('lottery_draw','lottery_recent_draws',
                           'lottery_calendar','lottery_digit_stats',
                           'lottery_history')), 5,
  'anon CAN execute all five lottery read functions');

-- The light list must stay light. It exists because two years of full draws is
-- ~208 KB, which is the wrong thing to send a phone on mobile data for a list
-- showing two numbers per row. If someone later adds the number arrays back,
-- this fails.
do $$
declare row1 jsonb;
begin
  row1 := api.lottery_history(1) -> 0;
  if row1 is null then
    perform pg_temp.log_pass('lottery_history returns empty on a draw-less database (no fixture here)');
    return;
  end if;
  if row1 ? 'prizes' or row1 ? 'numbers' then
    raise exception 'FAIL: lottery_history leaked full prize data into the light list';
  end if;
  if not (row1 ? 'yearBe') then
    raise exception 'FAIL: lottery_history must emit yearBe for year grouping';
  end if;
  perform pg_temp.log_pass('lottery_history stays light and carries yearBe for grouping');
end $$;

-- service_role holds no table DML: the entire write surface is one function.
select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_table_grants
    where grantee = 'service_role' and table_schema = 'lottery'), 0,
  'service_role holds no direct table grants in lottery');

-- --- Fixtures -------------------------------------------------------------
-- A complete draw and a mid-announcement one, built from the real payload
-- shape (response.data.<glo_key>.number[].value) rather than a guess.
create or replace function pg_temp.fake_payload(p_date text, p_omit text[] default '{}')
returns jsonb language sql as $$
  select jsonb_build_object('response', jsonb_build_object(
    'date', p_date,
    'period', jsonb_build_array(1, 2),
    'data', coalesce((
      select jsonb_object_agg(pt.glo_key, jsonb_build_object(
               'price', pt.amount_thb::text || '.00',
               'number', (
                 select jsonb_agg(jsonb_build_object(
                          'round', g,
                          'value', case pt.match_kind
                            when 'exact6'  then lpad(((g * 7919) % 1000000)::text, 6, '0')
                            when 'suffix2' then lpad(((g * 13) % 100)::text, 2, '0')
                            else lpad(((g * 137) % 1000)::text, 3, '0') end))
                   from generate_series(1, pt.winner_count) g)))
        from lottery.prize_tier pt
       where pt.effective_to is null and not (pt.glo_key = any(p_omit))), '{}'::jsonb)));
$$;

do $$
declare v jsonb;
begin
  v := api.lottery_ingest(pg_temp.fake_payload('2099-01-01'), 'test', 200, 'suite');
  if v ->> 'outcome' <> 'announced' or (v ->> 'numbers')::int <> 173 then
    raise exception 'FAIL: complete payload did not ingest as announced/173: %', v;
  end if;
  perform pg_temp.log_pass('a complete payload ingests as announced with 173 numbers');
end $$;

-- Read path must EXECUTE, not merely be callable. api.get_symbol once shipped
-- declared STABLE while writing, so it failed for every real caller while an
-- ACL-only suite stayed green. Same mistake is not repeatable here.
do $$
declare d jsonb;
begin
  d := api.lottery_draw('2099-01-01'::date);
  if d ->> 'status' <> 'announced' then
    raise exception 'FAIL: fixture draw not announced: %', d ->> 'status';
  end if;
  if (d ->> 'complete')::boolean is not true then
    raise exception 'FAIL: complete flag false on a full draw';
  end if;
  if jsonb_array_length(d -> 'prizes') <> 9 then
    raise exception 'FAIL: expected 9 prize tiers, got %', jsonb_array_length(d -> 'prizes');
  end if;
  if (select sum(jsonb_array_length(p -> 'numbers'))
        from jsonb_array_elements(d -> 'prizes') p) <> 173 then
    raise exception 'FAIL: draw payload does not carry 173 numbers';
  end if;
  -- Amounts must travel WITH the numbers; a client that had to fetch them
  -- separately could pair this draw with a previous structure's prices.
  if (select p ->> 'amountThb' from jsonb_array_elements(d -> 'prizes') p
       where p ->> 'code' = 'first') <> '6000000' then
    raise exception 'FAIL: first prize amount missing or wrong in the draw payload';
  end if;
  perform pg_temp.log_pass('api.lottery_draw executes and returns 9 tiers, 173 numbers, with amounts');
end $$;

-- Idempotency: the ingest workflow runs several times per draw day on purpose.
do $$
declare v jsonb; n int; raw_before int; raw_after int;
begin
  select count(*) into raw_before from lottery.raw_payload;
  v := api.lottery_ingest(pg_temp.fake_payload('2099-01-01'), 'test', 200, 'suite');
  select count(*) into n from lottery.result r
    join lottery.draw d on d.id = r.draw_id where d.draw_date = '2099-01-01';
  select count(*) into raw_after from lottery.raw_payload;

  if n <> 173 then raise exception 'FAIL: re-ingest changed result count to %', n; end if;
  if (select result_revision from lottery.draw where draw_date = '2099-01-01') <> 0 then
    raise exception 'FAIL: identical re-ingest bumped result_revision';
  end if;
  if (select count(*) from lottery.draw where draw_date = '2099-01-01') <> 1 then
    raise exception 'FAIL: re-ingest duplicated the draw row';
  end if;
  if raw_after <> raw_before + 1 then
    raise exception 'FAIL: re-ingest did not retain its own raw payload';
  end if;
  perform pg_temp.log_pass('re-ingesting an identical payload is idempotent (1 draw, 173 results, revision 0)');
end $$;

-- THE MOST IMPORTANT ASSERTION IN THIS SECTION.
-- GLO publishes รางวัลที่ 1 and เลขท้าย 2 ตัว first and completes the remaining
-- tiers over about two hours. If a payload fetched inside that window were
-- treated as announced, roughly 150 real 4th/5th-prize winners per งวด would be
-- told they lost. The partial draw must be stored but must never become the
-- draw that api.lottery_draw(null) hands back for checking.
do $$
declare v jsonb; d jsonb;
begin
  v := api.lottery_ingest(
         pg_temp.fake_payload('2099-01-16', array['fourth','fifth']), 'test', 200, 'suite');
  if v ->> 'outcome' <> 'partial' then
    raise exception 'FAIL: mid-announcement payload ingested as %, expected partial', v ->> 'outcome';
  end if;

  d := api.lottery_draw(null);
  if d ->> 'drawDate' = '2099-01-16' then
    raise exception 'FAIL: a PARTIAL draw was served as the latest announced draw';
  end if;
  if d ->> 'drawDate' <> '2099-01-01' then
    raise exception 'FAIL: expected the complete 2099-01-01 draw, got %', d ->> 'drawDate';
  end if;

  d := api.lottery_draw('2099-01-16'::date);
  if (d ->> 'complete')::boolean is not false then
    raise exception 'FAIL: partial draw reports complete = true';
  end if;
  perform pg_temp.log_pass('a PARTIAL draw is stored but never served as the latest announced draw');
end $$;

-- A malformed number must be rejected before it reaches the table, because the
-- CHECK would raise and roll back the raw payload with it.
do $$
declare v jsonb; bad jsonb;
begin
  bad := pg_temp.fake_payload('2099-02-01');
  bad := jsonb_set(bad, '{response,data,second,number,0,value}', '"0411"'::jsonb);
  v := api.lottery_ingest(bad, 'test', 200, 'suite');
  if (v ->> 'ok')::boolean is not false then
    raise exception 'FAIL: a 4-digit six-digit prize number was accepted';
  end if;
  if exists (select 1 from lottery.draw where draw_date = '2099-02-01') then
    raise exception 'FAIL: a rejected payload still created a draw row';
  end if;
  perform pg_temp.log_pass('a malformed prize number is rejected and creates no draw');
end $$;

-- The retention rule that makes a shape change recoverable. If someone changes
-- the function to `raise` on bad input, the transaction rolls back and the
-- payload is lost — this is the assertion that catches it.
do $$
declare v jsonb;
begin
  v := api.lottery_ingest('{"nope": 1}'::jsonb, 'test-shape', 200, 'suite');
  if (v ->> 'ok')::boolean is not false then
    raise exception 'FAIL: an unrecognised envelope was accepted';
  end if;
  -- A missing `response` key is a SHAPE CHANGE and must not be reported as
  -- "no draw that day", or a GLO redesign would look like an empty calendar.
  if v ->> 'outcome' <> 'invalid' then
    raise exception 'FAIL: unknown shape reported as %, expected invalid', v ->> 'outcome';
  end if;
  if not exists (select 1 from lottery.raw_payload
                  where endpoint = 'test-shape' and not ok and reason_th is not null) then
    raise exception 'FAIL: a failed parse did not retain its raw payload';
  end if;
  perform pg_temp.log_pass('a failed parse is retained in raw_payload with a reason, not rolled back');
end $$;

-- response: null is a legitimate answer (no draw that date), not a failure.
do $$
declare v jsonb;
begin
  v := api.lottery_ingest('{"response": null}'::jsonb, 'test', 200, 'suite');
  if v ->> 'outcome' <> 'no_draw' or (v ->> 'ok')::boolean is not true then
    raise exception 'FAIL: response:null should be outcome no_draw / ok true, got %', v;
  end if;
  perform pg_temp.log_pass('response:null reports no_draw rather than an error');
end $$;

-- --- Constraints ----------------------------------------------------------
select pg_temp.expect_fail($$
  insert into lottery.result (draw_id, tier_code, match_kind, number, ordinal)
  select id, 'first', 'exact6', '12345', 99 from lottery.draw where draw_date = '2099-01-01'
$$, 'a 5-digit number is rejected from a 6-digit tier');

select pg_temp.expect_fail($$
  update lottery.draw set status = 'announced', announced_at = null
   where draw_date = '2099-01-16'
$$, 'a draw cannot be announced without an announcement timestamp');

select pg_temp.expect_fail($$
  insert into lottery.result (draw_id, tier_code, match_kind, number, ordinal)
  select id, 'last2', 'exact6', '123456', 99 from lottery.draw where draw_date = '2099-01-01'
$$, 'match_kind cannot be forged: the composite FK pins it to the tier');

-- --- Statistics -----------------------------------------------------------
select pg_temp.expect_eq(
  jsonb_array_length(api.lottery_digit_stats(24) -> 'last2'), 100,
  'digit stats emit all 100 two-digit buckets, including zeros');

select pg_temp.expect_eq(
  (api.lottery_digit_stats(24) ->> 'noteTh') is not null, true,
  'digit stats carry the randomness caveat in the same object as the numbers');

-- The window cap is what keeps this affordable to compute on the fly.
select pg_temp.expect_eq(
  (api.lottery_digit_stats(99999) ->> 'windowDraws')::int <= 120, true,
  'the statistics window is capped regardless of what is requested');

do $$ begin
  raise notice '';
  raise notice '==========================================';
  raise notice ' ALL CHECKS PASSED';
  raise notice '==========================================';
end $$;

-- Final result set. Reaching this statement at all means no assertion raised.
select
  (select count(*) from check_log where name <> '--- section ---') as checks_passed,
  (select count(*) from check_log where name = '--- section ---') as sections,
  'ALL CHECKS PASSED' as verdict;

rollback;
