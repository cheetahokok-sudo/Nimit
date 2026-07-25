-- ============================================================================
-- Row Level Security and the public API surface
--
-- Context that determines the whole design: the Nimit app repository is PUBLIC
-- and ships a web build, so the Supabase anon key is recoverable from the JS
-- bundle by anyone. RLS is therefore not one layer of the security model — it
-- IS the security model. Nothing may rely on the key being secret.
--
-- Two independent locks on every content table:
--   1. no GRANT to anon/authenticated (and default privileges revoked, so a
--      future CREATE TABLE does not silently become reachable)
--   2. RLS enabled with ZERO policies, which denies by default
-- Both must fail before anything leaks.
--
-- The only reachable surface is the `api` schema, and it exposes FUNCTIONS
-- rather than tables. There is deliberately no PostgREST table endpoint to
-- point `?select=*&limit=999999` at, and no OpenAPI listing of the library.
-- ============================================================================

-- Supabase provisions these roles; create them when absent so the migration
-- also applies to a vanilla Postgres for local validation and CI.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Lock 1: no grants, now or in future
-- ---------------------------------------------------------------------------

revoke all on schema content, editorial, ops from anon, authenticated;
revoke all on all tables in schema content, editorial, ops from anon, authenticated;
revoke all on all functions in schema content, editorial, ops from anon, authenticated;

alter default privileges in schema content revoke all on tables from anon, authenticated;
alter default privileges in schema editorial revoke all on tables from anon, authenticated;
alter default privileges in schema ops revoke all on tables from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Lock 2: RLS on, no policies (= deny all)
--
-- FORCE also subjects the table owner, so a mistake made while logged in as the
-- owner does not quietly bypass the model.
-- ---------------------------------------------------------------------------

do $$
declare t record;
begin
  for t in
    select schemaname, tablename from pg_tables
     where schemaname in ('content','editorial','ops')
  loop
    execute format('alter table %I.%I enable row level security', t.schemaname, t.tablename);
    execute format('alter table %I.%I force row level security', t.schemaname, t.tablename);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- The api schema
-- ---------------------------------------------------------------------------

create schema if not exists api;
grant usage on schema api to anon, authenticated;

-- Views here are SECURITY DEFINER by default (security_invoker off). They
-- bypass base-table RLS on purpose: the view body IS the policy, and being a
-- view rather than a table means callers cannot filter around it.

-- Tier wording, so the app can render badge labels from the DB. Public: this is
-- the trust framework itself, and publishing it is part of the proposition.
create view api.tier_definition as
  select tier::text as code, title_th, description_th, sort,
         allowed_as_core, allowed_for_trend, citation_rule_th
    from content.tier_definition
   order by sort;

grant select on api.tier_definition to anon, authenticated;

-- Aggregate counts only. Never row-level detail.
create view api.library_stats as
  select
    (select count(*) from content.symbol where status = 'published')         as symbol_count,
    (select count(*) from content.interpretation where status = 'published') as interpretation_count,
    (select count(*) from content.edition where status = 'published')        as edition_count,
    (select count(*) from content.work where status = 'published')           as work_count;

grant select on api.library_stats to anon, authenticated;

-- Category list is small, public, and needed for browse UI.
create view api.category as
  select slug, name_th, domain_th, ethics_note_th, sort
    from content.category
   order by sort;

grant select on api.category to anon, authenticated;

-- ---------------------------------------------------------------------------
-- api.search_symbols — the only anon read path into the library
--
-- Returns names and teasers, never interpretation bodies. Hard row cap, minimum
-- query length, no offset pagination (so it cannot be walked exhaustively).
--
-- Three-stage lookup, first non-empty stage wins:
--   1. exact on the normalised term
--   2. exact on the tone-mark-stripped term  (the commonest Thai input error)
--   3. trigram similarity                    (genuine fuzziness)
-- ---------------------------------------------------------------------------

create or replace function api.search_symbols(q text, max_rows int default 20)
returns table (slug text, name_th text, category text, teaser_th text, match_kind text)
language plpgsql stable security definer set search_path = '' as $$
declare
  nq text;
  lq text;
  cap int;
begin
  nq := content.norm_th(coalesce(q, ''));
  if length(nq) < 2 then
    raise exception 'query must be at least 2 characters'
      using errcode = 'invalid_parameter_value';
  end if;

  cap := least(greatest(coalesce(max_rows, 20), 1), 30);
  lq  := content.norm_loose_th(q);

  -- Stage 1: exact
  return query
    select distinct on (s.slug)
           s.slug, s.name_th, c.name_th, left(coalesce(s.summary_th, ''), 140), 'exact'
      from content.symbol_term t
      join content.symbol   s on s.id = t.symbol_id
      join content.category c on c.id = s.category_id
     where t.term_norm = nq and s.status = 'published'
     order by s.slug, t.weight desc
     limit cap;
  if found then return; end if;

  -- Stage 2: tone marks ignored
  return query
    select distinct on (s.slug)
           s.slug, s.name_th, c.name_th, left(coalesce(s.summary_th, ''), 140), 'loose'
      from content.symbol_term t
      join content.symbol   s on s.id = t.symbol_id
      join content.category c on c.id = s.category_id
     where t.term_loose = lq and s.status = 'published'
     order by s.slug, t.weight desc
     limit cap;
  if found then return; end if;

  -- Stage 3: fuzzy. The 0.3 threshold is a starting point — Thai trigram
  -- density differs from Latin scripts, so tune it against real queries.
  return query
    select distinct on (s.slug)
           s.slug, s.name_th, c.name_th, left(coalesce(s.summary_th, ''), 140), 'fuzzy'
      from content.symbol_term t
      join content.symbol   s on s.id = t.symbol_id
      join content.category c on c.id = s.category_id
     where s.status = 'published'
       and content.sim(t.term_loose, lq) > 0.3
     order by s.slug, content.sim(t.term_loose, lq) desc
     limit cap;
end $$;

grant execute on function api.search_symbols(text, int) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- api.get_symbol — full detail, one symbol at a time
--
-- Requires a session. Supabase anonymous sign-in satisfies this, so it costs a
-- real user nothing while removing the trivial curl-with-the-public-key path to
-- the entire corpus.
--
-- Note what is assembled here: the trust tier is JOINED from the edition rather
-- than stored on the interpretation, so a badge can never disagree with the
-- bibliography it cites. Verbatim quote text is emitted only where the work is
-- free — the client never decides what may lawfully be shown.
-- ---------------------------------------------------------------------------

create or replace function api.get_symbol(p_slug text)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  result jsonb;
begin
  select jsonb_build_object(
    'slug', s.slug,
    'conceptKey', s.concept_key,
    'nameTh', s.name_th,
    'nameEn', s.name_en,
    'category', c.name_th,
    'summaryTh', s.summary_th,
    'ethicsNoteTh', s.ethics_note_th,
    'interpretations', coalesce((
      select jsonb_agg(jsonb_build_object(
               'tier', e.tier::text,
               'claimType', i.claim_type::text,
               'sourceNameTh', e.label_th,
               'sourceId', e.id,
               'custodianTh', e.custodian_th,
               'traditionTh', tr.name_th,
               'textTh', i.body_th,
               'contextNoteTh', i.context_note_th,
               'locatorTh', p.locator,
               -- Verbatim only where the underlying work is free.
               'quoteTh', case
                            when p.work_rights in
                              ('public_domain','cc0','cc_by','cc_by_sa','licensed_permission')
                            then p.original_text_th
                            else null
                          end,
               'corroborationCount', coalesce(array_length(i.corroborating_edition_ids, 1), 0)
             ) order by e.tier, i.prevalence desc nulls last)
        from content.interpretation i
        join content.passage  p  on p.id = i.passage_id
        join content.edition  e  on e.id = p.edition_id
        left join content.tradition tr on tr.id = i.tradition_id
       where i.symbol_id = s.id and i.status = 'published'
    ), '[]'::jsonb),
    'numbers', coalesce((
      select jsonb_agg(distinct n.number)
        from content.number_association n
       where n.symbol_id = s.id and n.status = 'published'
    ), '[]'::jsonb),
    'related', coalesce((
      select jsonb_agg(jsonb_build_object('slug', r2.slug, 'nameTh', r2.name_th, 'kind', rel.kind::text))
        from content.symbol_relation rel
        join content.symbol r2 on r2.id = rel.related_id
       where rel.symbol_id = s.id and r2.status = 'published'
    ), '[]'::jsonb)
  )
  into result
  from content.symbol s
  join content.category c on c.id = s.category_id
  where s.slug = p_slug and s.status = 'published';

  if result is null then
    raise exception 'symbol not found' using errcode = 'no_data_found';
  end if;

  insert into ops.api_access (fn, arg_digest, row_count) values ('get_symbol', p_slug, 1);
  return result;
end $$;

revoke execute on function api.get_symbol(text) from anon;
grant execute on function api.get_symbol(text) to authenticated;

-- ---------------------------------------------------------------------------
-- api.cite — the bibliography behind a claim
--
-- Public on purpose. A product whose pitch is verifiable sourcing must let
-- anyone check a citation; withholding it would undercut the proposition.
-- Returns bibliographic facts only, never source text.
-- ---------------------------------------------------------------------------

create or replace function api.cite(p_edition_id uuid)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
           'tier', e.tier::text,
           'workTitleTh', w.canonical_title_th,
           'editionLabelTh', e.label_th,
           'custodianTh', e.custodian_th,
           'stableIdentifier', e.stable_identifier,
           'shelfmark', e.shelfmark,
           'yearPublished', e.year_published,
           'yearOriginal', e.year_original,
           'scriptTh', e.script_th,
           'physicalDescTh', e.physical_desc_th,
           'url', e.url,
           'workRights', w.rights::text,
           'custodianRights', e.custodian_rights::text
         )
    from content.edition e
    join content.work w on w.id = e.work_id
   where e.id = p_edition_id and e.status = 'published';
$$;

grant execute on function api.cite(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Anti-enumeration notes (honest about what these do and do not achieve)
--
-- Anything the app can render, a determined competitor can collect by driving
-- the app. These measures raise the cost of copying; they do not prevent it.
-- The durable moat is editorial freshness and the citation apparatus, neither
-- of which survives being scraped as a snapshot. So: take the cheap wins, then
-- stop, and do not degrade the product chasing scrape-proofing.
--
-- Still to configure OUTSIDE these migrations, in project settings:
--   * PostgREST max-rows = 100  (a global backstop if a view is ever exposed)
--   * exposed schemas = api     (NEVER add content or editorial)
--   * DISABLE pg_graphql / the graphql_public schema — it is a second,
--     auto-generated, introspectable enumeration path that would bypass all of
--     the RPC-only design above
-- ---------------------------------------------------------------------------
