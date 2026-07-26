-- ============================================================================
-- service_role needs USAGE on schema api
--
-- THE BUG THIS FIXES. api.lottery_ingest was granted EXECUTE to service_role
-- and to nobody else, which is correct — but 20260726000300_rls_and_api.sql
-- grants `usage on schema api` to anon and authenticated ONLY. service_role was
-- never given it, so every ingestion attempt died before the function was even
-- resolved:
--
--   HTTP 403  {"code":"42501","message":"permission denied for schema api"}
--
-- EXECUTE on a function is worthless without USAGE on its schema. They are two
-- independent privileges and PostgreSQL checks the schema first.
--
-- Why the suite did not catch it: the lottery assertions checked the function
-- ACL (`has_function_privilege('service_role', ...)` → true) and stopped there,
-- while a different privilege blocked the call. This is the same shape as the
-- api.get_symbol failure recorded in migration 000500 — a check that asserts
-- one layer while another one denies. The fix there was to make the suite
-- EXECUTE the path rather than only inspect its ACLs, and the same fix applies
-- here: section 10 now calls api.lottery_ingest while actually holding the
-- service_role role, which fails loudly if either privilege is missing.
--
-- Scope: USAGE on a schema only permits looking up objects inside it. It grants
-- nothing on any table or function; every one of those still needs its own
-- grant, and the lottery schema deliberately gives service_role no table
-- privileges at all. The write surface remains exactly one function.
-- ============================================================================

grant usage on schema api to service_role;

-- Deliberately NOT granted: usage on content, editorial, ops or lottery.
-- Ingestion reaches the lottery tables only through the security-definer
-- function, which runs as its owner. A leaked service key can therefore insert
-- draw results and do nothing else.

do $$
begin
  if not has_schema_privilege('service_role', 'api', 'usage') then
    raise exception 'service_role still lacks USAGE on schema api';
  end if;
  if not has_function_privilege('service_role',
        'api.lottery_ingest(jsonb,text,int,text)', 'execute') then
    raise exception 'service_role still lacks EXECUTE on api.lottery_ingest';
  end if;
end $$;
