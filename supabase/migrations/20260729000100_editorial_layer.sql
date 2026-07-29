-- ============================================================================
-- content.edition.has_modern_editorial_layer — the seam the two-axis model
-- could not yet express
--
-- THE GAP. The model already separates "may we reproduce the TEXT" (work.rights)
-- from "may we redistribute THIS COPY" (edition.custodian_rights). Both are
-- about whole objects. Neither can say the thing that is true of most modern
-- ตำรา on sale today:
--
--   this printing is a public-domain traditional text WITH a living compiler's
--   own writing mixed into it, page by page, indistinguishably.
--
-- A 700-page พรหมชาติ ฉบับรวมเล่ม is the ordinary case, not the exotic one.
-- The underlying ตำรา is anonymous and long out of copyright; the compiler's
-- commentary, section arrangement, worked examples, modernised explanations and
-- illustrations are his copyrighted expression, however old the material he is
-- explaining. A reader working from that one book cannot reliably tell which
-- sentence is which, and neither can this schema.
--
-- WHY THAT MATTERS HERE SPECIFICALLY. The corroboration machinery keys off
-- work.rights:
--
--   * content.enforce_corroboration() fires only when work_rights =
--     'copyrighted_cite_only';
--   * the single_source_copyrighted sweep is scoped where w.rights <>
--     'public_domain'.
--
-- So an edition hung off a public-domain work clears BOTH, uncorroborated,
-- silently. For a faithful reprint of a 19th-century manuscript that is exactly
-- right. For a modern compilation it is a hole: a summary of the compiler's own
-- commentary would publish under a public-domain provenance label. That is
-- worse than a rights slip — it is a false provenance claim, and provenance is
-- the only thing this library actually offers.
--
-- WHY A COLUMN RATHER THAN A RULE ABOUT พรหมชาติ. Hardcoding a citekey into the
-- review sweep would fix one book and leave the next one to be remembered by a
-- human. Every ฉบับรวมเล่ม the project acquires has this shape, so the property
-- belongs on the edition and the check reads it.
--
-- WHAT IT DOES NOT DO. It grants nothing and forbids nothing on its own. It
-- does not alter work.rights, does not re-copyright a public-domain text, and
-- does not affect what may be READ — reading a lawfully held book was never
-- gated. It marks an edition as one whose claims need a second witness before
-- publication, which is the two-source rule the project already believes in,
-- applied where the existing predicates could not reach.
-- ============================================================================

alter table content.edition
  add column if not exists has_modern_editorial_layer boolean not null default false;

comment on column content.edition.has_modern_editorial_layer is
  'True when this printing interleaves a public-domain traditional text with a '
  'modern compiler''s own copyrighted additions (commentary, arrangement, '
  'examples, illustrations) that a reader cannot separate by eye. Claims drawn '
  'from such an edition require a corroborating source before publication even '
  'though the parent work is free — enforced by the '
  'mixed_compilation_uncorroborated check in scripts/review-checks.sql. '
  'Says nothing about the right to READ the book, which an owned copy already '
  'confers (see editorial.holding).';

-- Faithful reprints and manuscript facsimiles keep the default false: their
-- whole content is the old text, so the parent work's rights describe them
-- completely. Nothing existing changes, and no backfill is needed.
