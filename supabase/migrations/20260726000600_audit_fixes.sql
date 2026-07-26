-- ============================================================================
-- Audit fixes: broken read path, seed idempotency, ranking, ops hygiene
--
-- Findings from a live audit of project xfxzykbciqgjgendwgey, each verified
-- against the running database before being fixed here.
--
-- 1. api.get_symbol was BROKEN for every legitimate caller.
--
--    Declared STABLE but performing an INSERT into ops.api_access. PostgreSQL
--    forbids writes in non-volatile functions, so the first authenticated call
--    against a published symbol failed with:
--
--      ERROR 0A000: INSERT is not allowed in a non-volatile function
--
--    Nothing caught it because nothing ever EXECUTED the function: the test
--    suite asserted on its ACLs, and live probes as anon were rejected at the
--    permission gate (401) before the body ran. A function whose only
--    exercised path is "denied" is untested where it matters. The suite now
--    executes it and checks the shape of the result.
--
-- 2. Seed re-runs would duplicate the acquisition tracker.
--
--    editorial.acquisition had no unique constraint, so the seeds'
--    `on conflict do nothing` had nothing to conflict with — a silent no-op.
--    Re-running the documented apply workflow would have inserted all 18
--    outreach rows again. Verified live: 0 unique constraints on the table.
--
-- 3. Search results ranked alphabetically, not by relevance.
--
--    DISTINCT ON (s.slug) requires ORDER BY to lead with slug, and the LIMIT
--    applied directly to that ordering — so callers got the first N symbols
--    in ALPHABETICAL ORDER of slug, with weight only breaking ties within a
--    single symbol. A query matching many symbols would return 'baby' before
--    a heavier match starting with 'z'. Fixed by ranking in an outer query
--    before the cap.
--
-- 4. ops.api_access grew without bound and had no pruning path.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. get_symbol: make volatile so the access log insert is legal
--    (CREATE OR REPLACE preserves the existing ACL, which grants only
--    authenticated — verified after apply by the test suite.)
-- ---------------------------------------------------------------------------

create or replace function api.get_symbol(p_slug text)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
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

-- ---------------------------------------------------------------------------
-- 2. Acquisition tracker: give ON CONFLICT something to conflict with.
--    Dedupe first so the constraint can always be created (live DB verified
--    clean, but this migration must also work on a DB where seeds ran twice).
-- ---------------------------------------------------------------------------

delete from editorial.acquisition a
 using editorial.acquisition b
 where a.edition_id = b.edition_id
   and a.registry_ref is not distinct from b.registry_ref
   and a.id > b.id;

alter table editorial.acquisition
  add constraint acquisition_edition_ref_uniq unique (edition_id, registry_ref);

-- ---------------------------------------------------------------------------
-- 3. Relevance-ranked search: rank across symbols BEFORE the cap
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

  -- Stage 1: exact match on the normalised term.
  -- DISTINCT ON picks the best term per symbol; the outer ORDER BY then ranks
  -- symbols against each other by that weight, and only then does the cap
  -- apply. Without the outer sort, LIMIT truncated an alphabetical list.
  return query
    select x.slug, x.name_th, x.category, x.teaser, 'exact'
      from (
        select distinct on (s.slug)
               s.slug, s.name_th, c.name_th as category,
               left(coalesce(s.summary_th, ''), 140) as teaser,
               t.weight
          from content.symbol_term t
          join content.symbol   s on s.id = t.symbol_id
          join content.category c on c.id = s.category_id
         where t.term_norm = nq and s.status = 'published'
         order by s.slug, t.weight desc
      ) x
     order by x.weight desc, x.slug
     limit cap;
  if found then return; end if;

  -- Stage 2: tone marks ignored — the commonest Thai input error.
  return query
    select x.slug, x.name_th, x.category, x.teaser, 'loose'
      from (
        select distinct on (s.slug)
               s.slug, s.name_th, c.name_th as category,
               left(coalesce(s.summary_th, ''), 140) as teaser,
               t.weight
          from content.symbol_term t
          join content.symbol   s on s.id = t.symbol_id
          join content.category c on c.id = s.category_id
         where t.term_loose = lq and s.status = 'published'
         order by s.slug, t.weight desc
      ) x
     order by x.weight desc, x.slug
     limit cap;
  if found then return; end if;

  -- Stage 3: trigram similarity, ranked by similarity across symbols.
  return query
    select x.slug, x.name_th, x.category, x.teaser, 'fuzzy'
      from (
        select distinct on (s.slug)
               s.slug, s.name_th, c.name_th as category,
               left(coalesce(s.summary_th, ''), 140) as teaser,
               content.sim(t.term_loose, lq) as sim
          from content.symbol_term t
          join content.symbol   s on s.id = t.symbol_id
          join content.category c on c.id = s.category_id
         where s.status = 'published'
           and content.sim(t.term_loose, lq) > 0.3
         order by s.slug, content.sim(t.term_loose, lq) desc
      ) x
     order by x.sim desc, x.slug
     limit cap;
end $$;

-- ---------------------------------------------------------------------------
-- 4. Missing foreign-key indexes
--    Joins and cascades on these paths would each have cost a seq scan.
-- ---------------------------------------------------------------------------

create index if not exists interpretation_tradition_idx
  on content.interpretation (tradition_id) where tradition_id is not null;
create index if not exists number_association_passage_idx
  on content.number_association (passage_id) where passage_id is not null;
create index if not exists symbol_relation_related_idx
  on content.symbol_relation (related_id);
create index if not exists acquisition_edition_idx
  on editorial.acquisition (edition_id);
create index if not exists source_excerpt_edition_idx
  on editorial.source_excerpt (edition_id);
create index if not exists scan_ref_edition_idx
  on editorial.scan_ref (edition_id);
create index if not exists api_access_at_idx
  on ops.api_access (at);

-- ---------------------------------------------------------------------------
-- 5. Access-log retention
--    Unbounded audit tables are how free-tier databases fill up. Schedule
--    `select ops.prune_api_access();` via pg_cron (weekly is plenty).
-- ---------------------------------------------------------------------------

create or replace function ops.prune_api_access(retain_days int default 90)
returns bigint
language plpgsql volatile security definer set search_path = '' as $$
declare removed bigint;
begin
  delete from ops.api_access
   where at < now() - make_interval(days => greatest(retain_days, 7));
  get diagnostics removed = row_count;
  return removed;
end $$;

revoke execute on function ops.prune_api_access(int) from public, anon, authenticated;
