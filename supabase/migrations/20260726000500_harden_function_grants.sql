-- ============================================================================
-- Harden function privileges and pin search paths
--
-- Two real defects, both surfaced by Supabase's Security Advisor and both
-- missed by the original test suite.
--
-- 1. PUBLIC could execute api.get_symbol.
--
--    Migration 300 did `revoke execute on function api.get_symbol(text) from
--    anon`, intending to make full interpretation bodies require a session.
--    That revoke accomplished nothing: PostgreSQL grants EXECUTE to PUBLIC by
--    default on every new function, and `anon` inherits from PUBLIC. The ACL
--    read `=X/postgres | postgres=X/postgres | authenticated=X/postgres` — that
--    leading `=X` is the PUBLIC grant, still intact.
--
--    Revoking from a role does not remove a privilege held via PUBLIC. The
--    correct pattern is to revoke from PUBLIC first, then grant explicitly.
--
--    This was not caught earlier because the live probe returned HTTP 500 and
--    that was read as a permission denial. It was not — it was the function's
--    own `raise exception 'symbol not found'`, because no symbol is published
--    yet. An error is not evidence of the error you expected. The test suite
--    now asserts on the ACL directly rather than inferring from a response
--    code.
--
-- 2. Mutable search_path on three functions.
--
--    content.norm_th, content.norm_loose_th and content.touch_updated_at were
--    created without `set search_path`. A function with a mutable search path
--    resolves unqualified names against the caller's path, so anyone able to
--    create objects in a schema earlier in that path can shadow a function the
--    body relies on. Low risk for these three, but it is free to close and they
--    are called from generated columns and triggers on every write.
--
--    ALTER FUNCTION is used rather than CREATE OR REPLACE because norm_th and
--    norm_loose_th back the generated columns content.symbol_term.term_norm and
--    .term_loose; altering only the search_path setting leaves the body — and
--    therefore those columns — untouched. pg_catalog is always searched first
--    regardless of search_path, so the built-ins these bodies call still
--    resolve, and norm_loose_th already schema-qualifies its call to norm_th.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Explicit function privileges
--
-- Revoke from PUBLIC across the whole api schema, then re-grant deliberately.
-- Doing this schema-wide rather than per function means a function added later
-- and forgotten fails closed instead of open.
-- ---------------------------------------------------------------------------

revoke execute on all functions in schema api from public;
revoke execute on all functions in schema api from anon, authenticated;

-- Future functions in api default to no PUBLIC execute.
alter default privileges in schema api revoke execute on functions from public;

-- Anonymous surface: search by name, and read a citation. Never a body.
grant execute on function api.search_symbols(text, int) to anon, authenticated;
grant execute on function api.cite(uuid)               to anon, authenticated;

-- Full interpretation bodies require a session. Supabase anonymous sign-in
-- satisfies this, so it costs a real user nothing while removing the
-- curl-with-the-published-key path to the whole corpus.
grant execute on function api.get_symbol(text) to authenticated;

-- Internal helpers must not be reachable from the API at all.
revoke execute on all functions in schema content from public, anon, authenticated;
revoke execute on all functions in schema ops     from public, anon, authenticated;
alter default privileges in schema content revoke execute on functions from public;
alter default privileges in schema ops     revoke execute on functions from public;

-- ---------------------------------------------------------------------------
-- 2. Pin search paths
-- ---------------------------------------------------------------------------

alter function content.norm_th(text)        set search_path = '';
alter function content.norm_loose_th(text)  set search_path = '';
alter function content.touch_updated_at()   set search_path = '';

-- ---------------------------------------------------------------------------
-- Note on the three "Security Definer View" errors the advisor reports for
-- api.tier_definition, api.library_stats and api.category.
--
-- Those are intentional and must NOT be "fixed". The advisor flags definer
-- views because in a conventional Supabase project RLS policies are the access
-- control, and a definer view silently bypasses them. Here the base tables are
-- deny-all by design and the view body IS the policy — being a view rather than
-- a table is what stops a caller filtering around it. Converting them to
-- security_invoker would make them return nothing at all, since anon holds no
-- grants on content.
-- ---------------------------------------------------------------------------
