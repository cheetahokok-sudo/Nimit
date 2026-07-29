-- ============================================================================
-- The owned พรหมชาติ — a 730-page copy on the shelf, registered as readable
--
-- WHAT THIS UNLOCKS. Until now the library held exactly four pages of
-- พรหมชาติ: หน้า ๑๔–๑๗ of the 145-page ๒๕๐๖ funeral edition, read from a
-- Thammasat scan. Seven ทักษาวันเกิด readings came out of those four pages and
-- nothing else has ever been extracted from this ตำรา. The owner holds a
-- 730-page compilation edition, which is roughly five times the text of the
-- ๒๕๐๖ copy and the largest single body of พรหมชาติ material this project can
-- lawfully work from.
--
-- WHAT THIS DOES NOT DO. It registers an ENTITLEMENT TO READ, not content.
-- No passage, no symbol, no reading is created here. Reading a book you own
-- has never needed permission and was never blocked by the firewall — see the
-- editorial.holding migration — but the entitlement was undocumented, and an
-- editor six months from now must be able to see WHY working from this book
-- was lawful without asking anyone.
--
-- ── Which work does it hang off? ───────────────────────────────────────────
--
-- The anonymous one. taksa_v1 already made this correction once, and the
-- rights firewall is what caught it: พรหมชาติ is a traditional compilation of
-- unknown authorship, and a modern printing is an EDITION of it, not a new
-- work by whoever prepared that printing. Registering a second "พรหมชาติ by
-- <compiler>" work would re-make the exact error Path A undid.
--
-- So this edition attaches to the anonymous work, which is public domain under
-- ม.19/21 (published_50y_anon).
--
-- ── Published immediately, with the two-source rule made to actually apply ─
--
-- A compilation edition contains two kinds of text that look identical on the
-- page:
--
--   1. the traditional ตำรา, public domain, ours to use freely;
--   2. the compiler's OWN additions — commentary, arrangement, worked
--      examples, modern explanations, illustrations — which are his
--      copyrighted expression however old the material he is explaining.
--
-- Nothing in the schema can tell those apart, and neither can a reader working
-- from this book alone. Publishing a summary of the compiler's commentary as
-- though it came from an anonymous 19th-century ตำรา would launder copyrighted
-- expression through a public-domain label — a false provenance claim, which
-- is worse than a rights slip, because provenance is the only thing this
-- library actually offers.
--
-- The decision was to register the edition as published and let the two-source
-- rule carry that weight. Doing so required BUILDING the two-source rule for
-- this case, because it did not previously reach here:
--
--   * content.enforce_corroboration() fires only on copyrighted_cite_only;
--   * the single_source_copyrighted sweep is scoped where w.rights is not
--     public_domain.
--
-- พรหมชาติ the WORK is public domain, so an edition published under it cleared
-- both, uncorroborated, silently. has_modern_editorial_layer (migration
-- 20260729000100) marks the seam, and the mixed_compilation_uncorroborated
-- blocker in scripts/review-checks.sql enforces it. Nothing drawn from this
-- book publishes on its own say-so; the 145-page ๒๕๐๖ edition is the obvious
-- second witness for material the two share.
--
-- ── What still has to be read off the book ─────────────────────────────────
--
-- From หน้าปกใน and หน้าลิขสิทธิ์ — four fields, all of them refusals to guess.
-- These no longer gate publication; they complete the citation, and a b2 tier
-- promises ผู้เขียน + ฉบับพิมพ์ + เลขหน้า in its citation rule:
--
--   * ผู้เรียบเรียง — and whether the title page says เรียบเรียง (compiler,
--     confirming the anonymous-work model) or แต่ง (author, which would mean
--     this is a different work and this whole file is misfiled)
--   * สำนักพิมพ์
--   * ปีพิมพ์ครั้งแรก and ครั้งที่พิมพ์ of this copy
--   * ISBN, if the printing is recent enough to carry one
--
-- Two candidate compilations dominate the 700-page พรหมชาติ market and they
-- have different rightsholders and different death dates, so the copyright
-- term differs between them. This file names neither, because the copy on the
-- shelf settles it and a guess recorded in a database becomes a fact nobody
-- re-checks.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- The edition. work_rights mirrors down from the work by trigger — not set
-- here, and it must not be: an edition that disagrees with its parent is
-- exactly what edition_rights_drift watches for.
-- ---------------------------------------------------------------------------

insert into content.edition
  (work_id, citekey, tier, label_th, custodian_th, publisher_th,
   stable_identifier, edition_statement, year_published, isbn,
   physical_desc_th, script_th, languages,
   custodian_rights, has_modern_editorial_layer, rights_note_th, status)
select w.id, 'phrommachat-owned', 'b2',
  'พรหมชาติ ฉบับรวมเล่ม (ฉบับพิมพ์ที่ถือครอง ประมาณ ๗๓๐ หน้า)',
  'ห้องสมุดส่วนตัวของเจ้าของโครงการ',
  null,                                   -- รอจากหน้าลิขสิทธิ์
  null,                                   -- รอ ISBN หรือเลขทะเบียนอื่น
  null,                                   -- รอ "พิมพ์ครั้งที่ ..."
  null,                                   -- รอปีพิมพ์
  null,                                   -- รอ ISBN
  'หนังสือรวมเล่ม ประมาณ 730 หน้า — ใหญ่กว่าฉบับ ๒๕๐๖ ที่มี 145 หน้า ราวห้าเท่า',
  'ไทย', array['th'],
  'unknown', true,
  'ถือครองฉบับพิมพ์จริงโดยชอบ จึงอ่านและสกัดข้อเท็จจริงเชิงความเชื่อได้ '
  'บันทึกสิทธิ์การอ่านไว้ที่ editorial.holding | '
  'ตัวตำราพรหมชาติเป็นงานเก่าไม่ปรากฏผู้แต่ง พ้นลิขสิทธิ์แล้ว '
  'แต่ส่วนที่ผู้เรียบเรียงฉบับนี้เขียนเพิ่ม (คำอธิบาย การจัดหมวด ตัวอย่าง ภาพประกอบ) '
  'ยังเป็นงานมีลิขสิทธิ์ของผู้เรียบเรียง แยกจากกันด้วยตาเปล่าไม่ได้ '
  'จึงบังคับกฎสองแหล่งกับทุกคำแปลจากเล่มนี้ แม้งานต้นทางจะพ้นลิขสิทธิ์แล้ว '
  '(has_modern_editorial_layer = true) ห้ามคัดลอกคำต่อคำ ห้ามทำซ้ำภาพหน้าหนังสือ | '
  'ยังรอบันทึก ผู้เรียบเรียง/สำนักพิมพ์/ปีพิมพ์/ครั้งที่พิมพ์ จากหน้าลิขสิทธิ์ '
  'เพื่อให้การอ้างอิงครบตามเกณฑ์ชั้น b2',
  'published'
from content.work w where w.slug = 'phrommachat-wirophat'
on conflict (citekey) do update set
  rights_note_th             = excluded.rights_note_th,
  physical_desc_th           = excluded.physical_desc_th,
  has_modern_editorial_layer = excluded.has_modern_editorial_layer,
  status                     = excluded.status;

-- ---------------------------------------------------------------------------
-- The holding — the actual point of this file.
--
-- counsel_reviewed carries forward the standing advice already recorded
-- against ฝันพยากรณ์ in sources_v7: read from a lawfully held copy, extract
-- the belief as fact, write it in our own prose, cite every time. The same
-- method applied to a second owned book is the same decision, not a new one.
-- ---------------------------------------------------------------------------

insert into editorial.holding
  (edition_id, copy_type, acquired_note_th,
   counsel_reviewed, counsel_name, counsel_note_th, reviewed_at)
select e.id, 'owned_physical',
  'เจ้าของโครงการถือครองฉบับพิมพ์จริง ประมาณ 730 หน้า '
  'ใช้เป็นฐานอ่านและสกัดข้อเท็จจริงเชิงความเชื่อ '
  'ไม่ทำซ้ำภาพหน้าหนังสือ ไม่คัดลอกข้อความคำต่อคำ',
  true,
  'ที่ปรึกษากฎหมายของโครงการ (รอระบุชื่อ)',
  'ใช้แนวทางเดียวกับที่บันทึกไว้กับ ฝันพยากรณ์ ใน sources_v7: '
  'อ่านจากฉบับที่ถือครองโดยชอบ สกัดข้อเท็จจริง เรียบเรียงด้วยสำนวนของเราเอง อ้างอิงทุกครั้ง | '
  'ข้อต่างของเล่มนี้: เป็นฉบับรวมเล่มที่มีคำอธิบายของผู้เรียบเรียงปนอยู่กับตำราเก่า '
  'จึงบังคับกฎสองแหล่งกับทุกคำแปลที่มาจากเล่มนี้ แม้ตัวงานต้นทางจะพ้นลิขสิทธิ์แล้วก็ตาม',
  current_date
from content.edition e where e.citekey = 'phrommachat-owned'
on conflict (edition_id, copy_type) do nothing;

-- ---------------------------------------------------------------------------
-- Assert the intent, not the totals. Both inserts above are select-driven; a
-- join that matches nothing is zero rows and no error, which is precisely how
-- a registration file fails silently.
-- ---------------------------------------------------------------------------
do $$
declare got int; drift int;
begin
  select count(*) into got from content.edition where citekey = 'phrommachat-owned';
  if got <> 1 then
    raise exception 'phrommachat owned: expected 1 edition, found % '
      '(is the work phrommachat-wirophat present? run taksa_v1 first)', got;
  end if;

  select count(*) into got from editorial.holding h
    join content.edition e on e.id = h.edition_id
   where e.citekey = 'phrommachat-owned' and h.copy_type = 'owned_physical'
     and h.counsel_reviewed;
  if got <> 1 then
    raise exception 'phrommachat owned: reading entitlement not recorded (found %)', got;
  end if;

  -- The edition must sit under the ANONYMOUS work. If a later change reattaches
  -- it to a compiler-named work, the Path A correction has been undone and the
  -- 730 pages start laundering a copyright claim the ตำรา does not carry.
  select count(*) into drift from content.edition e
    join content.work w on w.id = e.work_id
   where e.citekey = 'phrommachat-owned'
     and (w.attributed_author_th not like 'ไม่ปรากฏผู้แต่ง%'
          or w.rights <> 'public_domain');
  if drift > 0 then
    raise exception 'phrommachat owned: edition no longer hangs off the anonymous '
      'public-domain work — Path A has been reverted';
  end if;

  -- The flag is the whole mechanism by which the two-source rule reaches this
  -- edition. If it is ever cleared, publication silently becomes unguarded
  -- again — the exact hole this file was written to close.
  select count(*) into got from content.edition
   where citekey = 'phrommachat-owned' and has_modern_editorial_layer;
  if got <> 1 then
    raise exception 'phrommachat owned: has_modern_editorial_layer is not set — '
      'readings from this compilation would publish with no second witness';
  end if;

  -- And the rule itself, asserted where the promise was made. The review sweep
  -- enforces this across the library as a blocker; this catches it at seed time
  -- so a bad content file fails on the machine that wrote it.
  select count(*) into got from content.interpretation i
    join content.passage p on p.id = i.passage_id
    join content.edition e on e.id = p.edition_id
   where e.citekey = 'phrommachat-owned' and i.status = 'published'
     and coalesce(array_length(i.corroborating_edition_ids, 1), 0) < 1;
  if got > 0 then
    raise exception 'phrommachat owned: % published reading(s) from the compilation '
      'carry no corroborating edition — the compiler''s own commentary cannot be '
      'told apart from the public-domain ตำรา by one reader with one book', got;
  end if;

  -- Verbatim text is a separate and narrower point from the publication gate:
  -- until we know who compiled this printing we cannot know which sentences are
  -- his. Stricter than the firewall, which would allow it because the parent
  -- work is public domain.
  select count(*) into got from content.passage p
    join content.edition e on e.id = p.edition_id
   where e.citekey = 'phrommachat-owned' and p.original_text_th is not null;
  if got > 0 then
    raise exception 'phrommachat owned: % passage(s) hold verbatim text from an '
      'unidentified compilation edition', got;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- The standing smoke alarm must still be clean after this file.
-- ---------------------------------------------------------------------------
do $$
declare bad int;
begin
  select coalesce(sum(violations), 0) into bad from ops.assert_rights_invariants();
  if bad > 0 then raise exception 'aborted: % rights invariant(s)', bad; end if;
end $$;

select e.citekey, e.status::text as edition_status, w.rights::text as work_rights,
       e.has_modern_editorial_layer as needs_second_source,
       h.copy_type, h.counsel_reviewed,
       (select count(*) from content.passage p where p.edition_id = e.id) as passages
from content.edition e
join content.work w on w.id = e.work_id
left join editorial.holding h on h.edition_id = e.id
where e.citekey in ('phrommachat-2506', 'phrommachat-owned')
order by e.citekey;
