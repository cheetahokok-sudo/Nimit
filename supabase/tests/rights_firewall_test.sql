-- ============================================================================
-- Verification suite for the rights firewall, Thai lookup and access control.
--
-- Run against a scratch database that already has the migrations and seeds:
--   psql -v ON_ERROR_STOP=1 -f supabase/tests/rights_firewall_test.sql
--
-- Every check raises an exception on failure, so a clean run means every
-- assertion below actually held. Runs inside a transaction and rolls back.
-- ============================================================================

\set ON_ERROR_STOP on
begin;

create or replace function pg_temp.expect_fail(sql text, what text)
returns void language plpgsql as $$
begin
  begin
    execute sql;
  exception when others then
    raise notice '  PASS  % (rejected: %)', what, left(sqlerrm, 70);
    return;
  end;
  raise exception 'FAIL: % — the statement was ACCEPTED but should have been rejected', what;
end $$;

create or replace function pg_temp.expect_ok(sql text, what text)
returns void language plpgsql as $$
begin
  execute sql;
  raise notice '  PASS  %', what;
end $$;

create or replace function pg_temp.expect_eq(actual anyelement, expected anyelement, what text)
returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAIL: % — expected %, got %', what, expected, actual;
  end if;
  raise notice '  PASS  % (= %)', what, expected;
end $$;

-- ---------------------------------------------------------------------------
\echo '== 1. Rights firewall: verbatim text =='
-- ---------------------------------------------------------------------------

-- Fixtures: one public-domain work, one copyrighted.
insert into content.work (slug, canonical_title_th, rights, pd_basis, status)
values ('t-pd', 'ตำราทดสอบ (พ้นลิขสิทธิ์)', 'public_domain', 'published_50y_anon', 'draft');

insert into content.work (slug, canonical_title_th, rights, copyright_holder, status)
values ('t-cr', 'ตำราทดสอบ (มีลิขสิทธิ์)', 'copyrighted_cite_only', 'สำนักพิมพ์ทดสอบ', 'draft');

insert into content.edition (work_id, citekey, tier, label_th, custodian_th)
select id, 't-pd-ed', 'a1', 'ฉบับทดสอบ', 'สถาบันทดสอบ' from content.work where slug = 't-pd';

insert into content.edition (work_id, citekey, tier, label_th, custodian_th)
select id, 't-cr-ed', 'b2', 'ฉบับทดสอบ', 'สำนักพิมพ์ทดสอบ' from content.work where slug = 't-cr';

-- The mirrored rights columns must have been populated by the sync triggers,
-- not left at the 'unknown' default.
select pg_temp.expect_eq(
  (select work_rights::text from content.edition where citekey = 't-pd-ed'),
  'public_domain', 'edition.work_rights mirrors work.rights on insert');

select pg_temp.expect_eq(
  (select work_rights::text from content.edition where citekey = 't-cr-ed'),
  'copyrighted_cite_only', 'edition.work_rights mirrors a copyrighted work');

-- Verbatim text against a PUBLIC DOMAIN work: allowed.
select pg_temp.expect_ok($$
  insert into content.passage (edition_id, locator, original_text_th, modern_th)
  select id, 'folio 1', 'ข้อความต้นฉบับที่พ้นลิขสิทธิ์แล้ว', 'คำปริวรรตปัจจุบัน'
    from content.edition where citekey = 't-pd-ed'
$$, 'verbatim text permitted on a public-domain work');

-- Verbatim text against a COPYRIGHTED work: must be rejected by CHECK.
select pg_temp.expect_fail($$
  insert into content.passage (edition_id, locator, original_text_th)
  select id, 'page 12', 'ข้อความคัดลอกจากหนังสือที่ยังมีลิขสิทธิ์'
    from content.edition where citekey = 't-cr-ed'
$$, 'verbatim text BLOCKED on a copyrighted work');

-- Paraphrase against the same copyrighted work: always allowed. This is the
-- whole point — citing and paraphrasing is legitimate, copying is not.
select pg_temp.expect_ok($$
  insert into content.passage (edition_id, locator, modern_th)
  select id, 'page 12', 'สรุปความด้วยสำนวนของเราเอง'
    from content.edition where citekey = 't-cr-ed'
$$, 'paraphrase permitted on a copyrighted work');

-- ---------------------------------------------------------------------------
\echo '== 2. Reclassification cascade =='
-- ---------------------------------------------------------------------------

-- Downgrading a work that still has verbatim text attached must be REJECTED.
-- This is the scenario where you discover your "ancient text" was really a
-- 1997 edited edition: the database refuses to let you quietly relabel it while
-- infringing copies still hang off it.
select pg_temp.expect_fail($$
  update content.work set rights = 'copyrighted_cite_only',
                          pd_basis = null,
                          copyright_holder = 'ผู้ตรวจชำระ พ.ศ. 2540'
   where slug = 't-pd'
$$, 'reclassifying PD -> copyrighted BLOCKED while verbatim text exists');

-- Remove the verbatim text, and the same reclassification now succeeds.
update content.passage p set original_text_th = null
  from content.edition e
 where e.id = p.edition_id and e.citekey = 't-pd-ed';

select pg_temp.expect_ok($$
  update content.work set rights = 'copyrighted_cite_only',
                          pd_basis = null,
                          copyright_holder = 'ผู้ตรวจชำระ พ.ศ. 2540'
   where slug = 't-pd'
$$, 'reclassification succeeds once verbatim text is removed');

-- And the new status must have cascaded all the way down to the passage.
select pg_temp.expect_eq(
  (select p.work_rights::text from content.passage p
     join content.edition e on e.id = p.edition_id where e.citekey = 't-pd-ed' limit 1),
  'copyrighted_cite_only', 'reclassification cascaded work -> edition -> passage');

-- Restore for later checks.
update content.work set rights = 'public_domain', pd_basis = 'published_50y_anon',
       copyright_holder = null where slug = 't-pd';

-- ---------------------------------------------------------------------------
\echo '== 3. Constraint integrity =='
-- ---------------------------------------------------------------------------

-- public_domain without a stated basis is meaningless and must be refused.
select pg_temp.expect_fail($$
  insert into content.work (slug, canonical_title_th, rights, status)
  values ('t-nobasis', 'ตำราไม่ระบุเหตุผล', 'public_domain', 'draft')
$$, 'public_domain without pd_basis BLOCKED');

-- copyrighted without a named holder cannot be actioned on a takedown.
select pg_temp.expect_fail($$
  insert into content.work (slug, canonical_title_th, rights, status)
  values ('t-noholder', 'ตำราไม่ระบุเจ้าของสิทธิ์', 'copyrighted_cite_only', 'draft')
$$, 'copyrighted without copyright_holder BLOCKED');

-- ---------------------------------------------------------------------------
\echo '== 4. Two-source rule =='
-- ---------------------------------------------------------------------------

insert into content.symbol (concept_key, slug, name_th, category_id, status)
select 'T_SYM', 't-sym', 'สัญลักษณ์ทดสอบ', id, 'draft'
  from content.category where slug = 'dream-symbols';

-- Publishing a claim derived from a single copyrighted work must be refused:
-- paraphrasing one book is a derivative work.
select pg_temp.expect_fail($$
  insert into content.interpretation
    (symbol_id, passage_id, body_th, claim_type, status)
  select s.id, p.id, 'คำอธิบายด้วยสำนวนของเรา', 'historical_belief', 'published'
    from content.symbol s, content.passage p
    join content.edition e on e.id = p.edition_id
   where s.concept_key = 'T_SYM' and e.citekey = 't-cr-ed' limit 1
$$, 'publishing from a lone copyrighted source BLOCKED');

-- Draft status is fine — the rule gates publication, not editorial work.
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

-- With a corroborating independent source, publication is permitted: a belief
-- attested in two places is a cultural fact, and facts are not copyrightable.
select pg_temp.expect_ok($$
  update content.interpretation
     set corroborating_edition_ids =
           array(select id from content.edition where citekey = 't-pd-ed'),
         status = 'published'
   where body_th = 'ร่างคำอธิบาย'
$$, 'publishing allowed once corroborated by a second source');

-- ---------------------------------------------------------------------------
\echo '== 5. Standing assertions =='
-- ---------------------------------------------------------------------------

do $$
declare r record;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then
      raise exception 'FAIL: invariant % reported % violations (%)',
        r.check_name, r.violations, r.detail;
    end if;
    raise notice '  PASS  invariant % = 0', r.check_name;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
\echo '== 6. Thai normalisation and lookup =='
-- ---------------------------------------------------------------------------

select pg_temp.expect_eq(content.norm_th('  งู  '), 'งู', 'norm trims whitespace');
select pg_temp.expect_eq(content.norm_th('๑๖'), '16', 'norm folds Thai digits');
-- Tone marks stripped: เสือ -> เสอ. Wrong tone marks are the commonest Thai
-- input error and must not prevent a match.
select pg_temp.expect_eq(content.norm_loose_th('เสือ'), content.norm_loose_th('เสื่อ'),
  'loose norm makes tone-mark variants equal');

-- Longest match must win: งูเหลือม is its own term, not bare งู.
select pg_temp.expect_eq(
  (select term from content.symbol_term
    where term_norm = content.norm_th('งูเหลือม') limit 1),
  'งูเหลือม', 'compound term indexed distinctly from the generic term');

-- The search RPC returns the right symbol and enforces its guards.
select pg_temp.expect_eq(
  (select count(*)::int from api.search_symbols('งู', 30)), 0,
  'search returns nothing while all symbols are draft (published-only)');

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
\echo '== 7. Access control =='
-- ---------------------------------------------------------------------------

-- No grant may exist for anon or authenticated anywhere in the protected
-- schemas. This is the check that catches a well-meaning GRANT added later
-- through the Studio UI.
select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_table_grants
    where grantee in ('anon','authenticated')
      and table_schema in ('content','editorial','ops')), 0,
  'anon/authenticated hold ZERO grants in content, editorial and ops');

-- RLS must be enabled AND forced on every table in those schemas.
select pg_temp.expect_eq(
  (select count(*)::int from pg_tables t
     join pg_class c on c.relname = t.tablename
     join pg_namespace n on n.oid = c.relnamespace and n.nspname = t.schemaname
    where t.schemaname in ('content','editorial','ops')
      and not (c.relrowsecurity and c.relforcerowsecurity)), 0,
  'every protected table has RLS enabled and forced');

-- Zero policies is what makes RLS deny-all here.
select pg_temp.expect_eq(
  (select count(*)::int from pg_policies
    where schemaname in ('content','editorial','ops')), 0,
  'no permissive policies exist on protected tables');

-- get_symbol must not be reachable without a session.
select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee = 'anon' and routine_schema = 'api'
      and routine_name = 'get_symbol'), 0,
  'anon cannot execute api.get_symbol');

select pg_temp.expect_eq(
  (select count(*)::int from information_schema.role_routine_grants
    where grantee = 'anon' and routine_schema = 'api'
      and routine_name = 'search_symbols') > 0, true,
  'anon CAN execute api.search_symbols');

\echo ''
\echo '=========================================='
\echo ' ALL CHECKS PASSED'
\echo '=========================================='

rollback;
