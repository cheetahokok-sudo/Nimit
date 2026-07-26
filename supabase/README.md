# Nimit — Supabase backend

Schema, access control and seed data for the Nimit content library.

> **This repository is public.** These files contain DDL and bibliography only —
> no secrets, no copyrighted source text, no personal data. That is deliberate:
> publishing the access-control policies is a trust asset for a product whose
> proposition is verifiable sourcing. It costs nothing in security, because the
> anon key ships in the web bundle regardless, so obscurity was never providing
> anything here.

## Layout

```
migrations/
  20260726000100_content_schema.sql   tables, enums, Thai normalisation
  20260726000200_rights_firewall.sql  the copyright constraints
  20260726000300_rls_and_api.sql      RLS, grants, the api schema
seed.sql                              tiers, categories, traditions
seeds/
  sources_v1.sql                      30 works / 37 editions (bibliography)
  dream_symbols_v1.sql                59 symbols + 140 search terms
tests/
  rights_firewall_test.sql            verification suite
```

## Applying

```bash
supabase link --project-ref <ref>
supabase db push
psql "$DATABASE_URL" -f supabase/seed.sql
psql "$DATABASE_URL" -f supabase/seeds/sources_v1.sql
psql "$DATABASE_URL" -f supabase/seeds/dream_symbols_v1.sql
```

Then verify:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rights_firewall_test.sql
```

## Settings that are NOT in these files

Three things must be configured in the Supabase dashboard. The migrations cannot
set them, and each one silently undoes part of the design if missed:

1. **Exposed schemas = `api` only.** Never add `content` or `editorial`. This is
   the boundary that makes the editorial schema unreachable rather than merely
   unauthorised.
2. **Disable `pg_graphql` / the `graphql_public` schema.** It is a second,
   auto-generated, introspectable enumeration path that bypasses the RPC-only
   read design entirely.
3. **PostgREST `max-rows` = 100.** A global backstop for the case where a view
   is exposed by mistake.

## Finding your tables in the dashboard

**The Table Editor opens on the `public` schema, which is empty. Nothing is
broken — none of this project's tables belong there.**

| Schema | Contains | Visible in Table Editor? |
|---|---|---|
| `public` | nothing (until Phase 4 user data) | yes, and empty |
| `content` | 13 tables — work, edition, passage, symbol, symbol_term, interpretation, … | yes, after switching schema |
| `editorial` | 5 tables — source_excerpt, scan_ref, rights_grant, acquisition, editor_note | yes, after switching schema |
| `ops` | 1 table — api_access | yes, after switching schema |
| `api` | 3 views — tier_definition, library_stats, category | yes, after switching schema |

**To see them:** Table Editor → the schema dropdown at the top-left (it reads
`public`) → pick `content`.

The dashboard connects as a privileged role, so it bypasses RLS and shows
everything. That is expected and is not a hole — the anon key cannot do this,
which is what the deployment checks verified.

### Do NOT "fix" the Security Advisor warnings

Supabase's advisor will flag every table in `content`, `editorial` and `ops`
with something like *"RLS is enabled but no policies exist"*, and offer to help
you add one.

**That warning is describing the design working correctly.** RLS with zero
policies is deny-all, and it is one of the two locks protecting the library —
the other being revoked grants. Adding a permissive policy to silence the
advisor would hand the entire corpus to anyone holding the anon key, which is
published in the web bundle.

The only intended read path is the `api.*` functions, which are
`security definer` and carry their own filters. If you ever genuinely need a new
access route, add an `api` function — never a policy on a `content` table.

## The three ideas worth understanding

### Rights live on two axes, not one

The registry this was built from had a single "rights" column, which conflated
two different permissions and made every source look equally encumbered.

```
work.rights              may we reproduce the TEXT?
edition.custodian_rights may we redistribute THIS COPY?
```

A 19th-century สมุดไทย is `public_domain` — its text is long out of copyright.
The National Library's scan of it is `all_rights_reserved`. Both are true at
once. Collapsing them either forfeits material you may lawfully use, or invites
infringement. Our own transcription of a public-domain work is separate
editorial labour and is ours to publish.

### The firewall is declarative, so it cannot be turned off

Verbatim source text may exist only where the underlying work is free. That is
enforced by composite foreign keys plus a CHECK, not a trigger, because a
trigger can be disabled, skipped by `COPY`, and lost in a restore.

```
work.rights ──cascade──> edition.work_rights ──cascade──> passage.work_rights
                                                                 │
                                                       CHECK verbatim_requires_free_work
```

The useful consequence: reclassifying a work downward — you discover the
"ancient text" is really a 1997 edited edition — cascades and **the
reclassification itself is rejected** until the verbatim text hanging off it is
removed. You cannot quietly downgrade a source while infringing copies remain
attached. Failure is a loud error at write time, never a silent leak at read
time.

### Thai lookup is a curated index, not full-text search

Thai is written without word spaces and Postgres ships no Thai dictionary, so
`to_tsvector('simple','ฝันเห็นงูเผือกหน้าบ้าน')` yields exactly **one token**.
FTS here fails while appearing to work in casual testing, which is worse than
not having it.

Instead `content.symbol_term` holds curated headwords, synonyms, colloquialisms,
regional variants and common misspellings, with a three-stage lookup: exact →
tone-marks-stripped → trigram. Dream text is scanned by longest match over known
terms, so `งูเหลือม` beats `งู` and word segmentation never enters the picture.

## What is deliberately absent

`content.interpretation` ships **empty**, and there are no number associations.

Interpretations are claims about what a symbol *means*, and each must cite a
passage in a real manuscript. Rights clearance for the P0 sources is still
outstanding, so nobody has read them yet. Writing "ตำราทำนายฝัน เลขทะเบียน 447
says a white snake means X" without having read folio one would be fabricating a
citation — precisely the failure the A1–D apparatus exists to prevent, and worse
than no citation at all because the reader cannot falsify it.

Interpretations enter only through transcription from cleared sources. Until
then `api.get_symbol` correctly returns an empty array, and the search index —
which is linguistic data needing no attribution — works today.
