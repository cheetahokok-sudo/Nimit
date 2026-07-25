-- ============================================================================
-- Add a public-domain basis for government works that expired by DURATION
--
-- Legal research corrected an assumption baked into the v1 seed: several
-- กรมศิลปากร publications were recorded as "possibly section 7, needs checking".
-- Section 7 almost certainly does NOT reach them:
--
--   * s.7(5) is limited by its own words "ตาม (๑) ถึง (๔)" — it covers only
--     translations and compilations OF news, the constitution and laws,
--     administrative instruments, and judgments. A scholarly edition of a
--     divination manual is in none of those categories.
--   * s.7(3) is a closed list of governance instruments (ระเบียบ ข้อบังคับ
--     ประกาศ คำสั่ง คำชี้แจง หนังสือโต้ตอบ). A monograph is not a ประกาศ.
--   * ss.14 and 23 would be dead letters if government publications were
--     categorically excluded: s.14 makes the agency the OWNER of works made
--     under its employment or order, and s.23 gives them a 50-year term.
--     The Act plainly treats a department as an ordinary copyright owner.
--
-- But the correction cuts both ways, and mostly in our favour. Section 23 runs
-- **50 years from first publication**. A Fine Arts Department book published in
-- พ.ศ. 2508 (1965) therefore left copyright in 2015 — it is public domain
-- today, by ordinary expiry rather than by any government exemption.
--
-- That distinction is worth a separate enum value, because the two routes fail
-- differently: a s.7 claim fails if the document turns out to be scholarship,
-- whereas a duration claim fails only if the publication date is wrong.
--
-- Caveat retained in the data: no Thai case law construes s.7(3) at all.
-- ============================================================================

alter type content.pd_basis add value if not exists 'government_work_50y';

comment on type content.pd_basis is
  'Why a work is out of copyright under พ.ร.บ. ลิขสิทธิ์ พ.ศ. 2537. '
  'government_work_50y = s.23: work made under government employment, order or '
  'control, 50 years from first publication. Distinct from government_material '
  '(s.7), which excludes only governance instruments and does NOT cover '
  'departmental scholarship.';
