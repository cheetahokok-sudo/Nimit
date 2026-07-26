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
      and table_schema in ('content','editorial','ops')), 0,
  'anon/authenticated hold ZERO grants in content, editorial and ops');

select pg_temp.expect_eq(
  (select count(*)::int from pg_tables t
     join pg_class c on c.relname = t.tablename
     join pg_namespace n on n.oid = c.relnamespace and n.nspname = t.schemaname
    where t.schemaname in ('content','editorial','ops')
      and not (c.relrowsecurity and c.relforcerowsecurity)), 0,
  'every protected table has RLS enabled and forced');

select pg_temp.expect_eq(
  (select count(*)::int from pg_policies
    where schemaname in ('content','editorial','ops')), 0,
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
    where n.nspname in ('content','ops')
      and (p.proacl is null
           or exists (select 1 from unnest(p.proacl) a where a::text like '=%'))), 0,
  'PUBLIC cannot execute any function in content or ops');

-- Every function reachable from the API must pin its search_path, so a caller
-- cannot shadow what the body resolves.
select pg_temp.expect_eq(
  (select count(*)::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('api','content','ops')
      and p.prokind = 'f'
      and (p.proconfig is null
           or not exists (select 1 from unnest(p.proconfig) c where c like 'search_path=%'))), 0,
  'every function in api, content and ops pins search_path');

select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee = 'anon' and routine_schema = 'api'
      and routine_name = 'search_symbols') > 0, true,
  'anon CAN execute api.search_symbols');

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
