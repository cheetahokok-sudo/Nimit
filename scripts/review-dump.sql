-- ============================================================================
-- One query, one JSON object: everything the review desk renders.
--
-- Paired with scripts/build-review-desk.mjs. Kept as SQL rather than built up
-- by a script with database access, so the desk can only ever show what the
-- database actually contains — there is no layer in between that could
-- summarise, round, or quietly omit.
--
--   psql "$PGURL" -t -A -f scripts/review-dump.sql > review.json
--   node scripts/build-review-desk.mjs review.json > desk.html
-- ============================================================================

select jsonb_build_object(
  'generatedAt', (now() at time zone 'Asia/Bangkok')::date,

  'stats', jsonb_build_object(
    'symbols',          (select count(*) from content.symbol where status='published'),
    'interpPublished',  (select count(*) from content.interpretation where status='published'),
    'interpDraft',      (select count(*) from content.interpretation where status='draft'),
    'numbersPublished', (select count(*) from content.number_association where status='published'),
    'numbersDraft',     (select count(*) from content.number_association where status='draft'),
    'works',            (select count(*) from content.work where status='published'),
    'editions',         (select count(*) from content.edition where status='published'),
    'circulation',      (select count(*) from content.circulation where status='published'),
    'submissionsOpen',  (select count(*) from editorial.submission where state in ('new','checked'))),

  -- Findings first: this is the actionable half of the page.
  'findings', (select coalesce(jsonb_agg(jsonb_build_object(
        'severity', f.severity, 'code', f.check_code,
        'message', f.message_th, 'detail', f.detail) order by
        case f.severity when 'blocker' then 1 when 'warning' then 2 else 3 end,
        f.check_code), '[]'::jsonb)
     from editorial.review_finding f where not f.resolved),

  'findingCounts', (select coalesce(jsonb_object_agg(severity, n), '{}'::jsonb)
     from (select severity, count(*) as n from editorial.review_finding
            where not resolved group by 1) t),

  'submissions', (select coalesce(jsonb_agg(jsonb_build_object(
        'title', sb.title_th, 'kind', sb.kind, 'state', sb.state,
        'sensitivity', sb.proposed_sensitivity::text,
        'summary', sb.summary_th, 'created', sb.created_at::date) order by sb.created_at desc), '[]'::jsonb)
     from editorial.submission sb where sb.state in ('new','checked')),

  'published', (select coalesce(jsonb_agg(x order by x->>'work', x->>'symbol'), '[]'::jsonb) from (
     select jsonb_build_object(
       'symbol', s.name_th, 'tier', e.tier::text, 'work', w.canonical_title_th,
       'locator', p.locator, 'plain', i.summary_plain_th,
       'sensitivity', i.sensitivity::text,
       'quote', case when w.rights in ('public_domain','cc0','cc_by','cc_by_sa','licensed_permission')
                     then p.original_text_th else null end,
       'rights', w.rights::text,
       'corroboration', coalesce(array_length(i.corroborating_edition_ids,1),0)) as x
     from content.interpretation i
     join content.passage p on p.id = i.passage_id
     join content.edition e on e.id = p.edition_id
     join content.work    w on w.id = e.work_id
     join content.symbol  s on s.id = i.symbol_id
     where i.status = 'published') t),

  'drafts', (select coalesce(jsonb_agg(x order by x->>'symbol'), '[]'::jsonb) from (
     select jsonb_build_object('symbol', s.name_th, 'source', e.label_th,
       'locator', p.locator, 'body', i.body_th, 'sensitivity', i.sensitivity::text) as x
     from content.interpretation i
     join content.passage p on p.id = i.passage_id
     join content.edition e on e.id = p.edition_id
     join content.symbol  s on s.id = i.symbol_id
     where i.status = 'draft') t),

  'draftNumbers', (select coalesce(jsonb_agg(x order by x->>'symbol'), '[]'::jsonb) from (
     select jsonb_build_object('symbol', s.name_th, 'number', n.number,
       'source', e.label_th, 'locator', p.locator,
       'sensitivity', n.sensitivity::text) as x
     from content.number_association n
     join content.symbol s on s.id = n.symbol_id
     left join content.passage p on p.id = n.passage_id
     left join content.edition e on e.id = p.edition_id
     where n.status = 'draft') t),

  'circulating', (select coalesce(jsonb_agg(jsonb_build_object(
        'number', c.number, 'occasion', c.occasion_th,
        'from', c.observed_from, 'to', c.observed_to,
        'channel', c.channel_th, 'status', c.status::text,
        'sensitivity', c.sensitivity::text, 'cleared', c.counsel_cleared)
        order by c.observed_from desc), '[]'::jsonb)
     from content.circulation c),

  'coverage', (select coalesce(jsonb_agg(jsonb_build_object('symbol', s.name_th, 'n', c.n)
       order by c.n desc, s.name_th), '[]'::jsonb)
     from content.symbol s
     join lateral (select count(i.id) as n from content.interpretation i
                    where i.symbol_id = s.id and i.status='published') c on true
     where s.status = 'published')
);
