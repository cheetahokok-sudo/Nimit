-- ============================================================================
-- Content set 7: ประมวลตำราทำนาย ภาค ๑ หน้า ๑๑–๑๒
--
-- หน้า ๑๑ — the day of the week decides WHOM the dream concerns. Seven rows,
-- each unambiguous, and structurally the cleanest table in the book.
--
-- หน้า ๑๒ — the first per-symbol readings with their OWN verdicts. Unlike
-- pp. ๔–๑๐, where a catalogue shared one closing verdict, here each image has
-- a distinct outcome. This is the material that makes the app's answers differ
-- from one another instead of all reading alike.
--
-- Public domain, so original_text_th carries the verse verbatim. The two-column
-- caution from content set 6 still applies and is recorded on the passage: the
-- reading order is left column then right, line by line, which is consistent
-- across every page of this edition I have transcribed — but it is single-key
-- and wants a second reader before the set grows much further.
--
-- One line is deliberately softened rather than reproduced literally in the
-- plain summary: the ตำรา reads dreams of excrement, drunkenness and a bloated
-- corpse as omens of incoming wealth. That IS what the book says and it is
-- recorded faithfully in body_th; the ภาษาชาวบ้าน line simply does not dwell on
-- the imagery, because a two-sentence summary is read at a glance by people who
-- did not ask for it.
--
-- NUMBERS: none, as everywhere in this source.
-- ============================================================================

insert into content.passage
  (edition_id, locator, sequence, original_text_th, modern_th,
   transcribed_by, transcription_note_th, status)
select e.id, v.locator, v.seq, v.orig, v.modern,
  'Claude (AI) — อ่านจากภาพสแกน D-Library 6238 เมื่อ 27 ก.ค. 2569',
  'คงอักขรวิธีฉบับ พ.ศ. 2477 ไว้ตามต้นฉบับ; หน้าเรียงสองคอลัมน์ '
  'อ่านซ้ายแล้วขวาเป็นบรรทัด ๆ ตามรูปแบบเดียวกันทั้งเล่ม | '
  'ยังไม่ได้ทานซ้ำโดยผู้อ่านคนที่สอง (double-key) ตามระเบียบ B5',
  'published'
from (values
  ('หน้า ๑๑ ส่วนวันที่ฝัน', 11,
   'ขอแต่งตำราเรื่องยุบล ฝันแห่งนรชน อันเกิดอุบัติอัศจรรย์ '
   'แม้นวันอาทิตย์ใครฝัน สุขทุกขไภยัน จะได้แก่คนทั้งมูล '
   'วันจันทร์ได้แก่ประยูร วงษาตระกูล ของตนจะได้บมิคลาย '
   'ฝันวันอังคารท่านหมาย นิมิตรทำนาย ว่าได้แก่พ่อแม่ตน '
   'ถ้าฝันวันพุธพึงยล ทุกข์สุขเหตุผล ว่าได้แก่บุตรภรรยา '
   'วันพฤหัสได้แก่ครูบา อาจารย์อุบัชฌาย์ แลท่านผู้ใหญ่โดยวาร '
   'วันศุกร์ได้แก่ศฤงคาร วัวควายใช้การ แลคชมิ่งอาชา '
   'วันเสาร์ได้แก่อาตมา สุขทุกข์นานา บ่ห่อนจะผิดพันพัว',
   'ตำราระบุว่าวันที่ฝันเป็นตัวกำหนดว่าผลของความฝันจะตกแก่ผู้ใด '
   'ไล่เรียงครบทั้งเจ็ดวันตั้งแต่วันอาทิตย์ถึงวันเสาร์'),
  ('หน้า ๑๒ ส่วนคำทำนายฝันรายสัญลักษณ์', 12,
   'ฝันว่ามูตรคูถต้องตัว กินเหล้าเมามัว หนึ่งพบอาศภเน่าพอง '
   'จะได้สุลาภเนื่องนอง ตำหรับกล่าวสนอง จะสมนิยมจินดา '
   'ฝันว่าผ้าแพรภูษา จะอยู่สุขา ไม่มีใครบุกรุกราน '
   'ฝันเห็นว่าทอดแหพาน ตกเบ็ดแห่งละหาน หาปลาในท้องนที '
   'จักคิดสิ่งใดก็ดี แต่ล้วนจักมี สวัสดิจิตต์ปอง '
   'ฝันว่านาคเกยวตระกอง ตัวกลัวอย่าหมอง จะมีซึ่งผู้รักษา '
   'ฝันเห็นว่าได้แหวนมา จักได้ภรรยา แลบุตรอันรักร่วมใจ '
   'ฝันว่าลูกไม้อันใด แม้นว่าได้ใช้ จะสมสำเร็จปรารถนา',
   'หมวดนี้ให้คำทำนายเฉพาะรายสัญลักษณ์ ต่างจากหน้า ๔–๑๐ ที่สรุปผลรวมไว้ครั้งเดียว')
) as v(locator, seq, orig, modern)
cross join content.edition e
where e.citekey = 'nlt-6238-2477'
on conflict (edition_id, locator, sequence) do nothing;

-- ---------------------------------------------------------------------------
-- หน้า ๑๑ — whom the dream concerns
-- ---------------------------------------------------------------------------

with p as (select p.id from content.passage p join content.edition e on e.id = p.edition_id
            where e.citekey = 'nlt-6238-2477' and p.locator = 'หน้า ๑๑ ส่วนวันที่ฝัน' limit 1),
tr as (select id from content.tradition where slug = 'folk-central')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id,
  'ตำราประมวลตำราทำนาย ภาค ๑ (พ.ศ. 2477) ว่าความฝันที่เกิดใน' || v.day ||
  ' ผลของความฝันนั้นจะตกแก่' || v.who || ' ' ||
  'หมวดนี้ไม่ได้ทำนายว่าฝันดีหรือร้าย แต่ระบุว่าใครคือผู้รับผลของนิมิตนั้น',
  'ถ้าฝันใน' || v.day || ' ตำราเก่าว่าผลของฝันจะตกแก่' || v.who,
  'historical_belief',
  'เป็นความเชื่อที่บันทึกไว้ในตำรา พ.ศ. 2477 ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
  'และตำราเล่มนี้ไม่ได้ผูกเลขกับหมวดนี้',
  '{}', 'published', now()
from (values
  ('DREAM_DAY_SUN','วันอาทิตย์','คนทั้งหมู่ ไม่เจาะจงผู้ใดผู้หนึ่ง'),
  ('DREAM_DAY_MON','วันจันทร์','วงศ์ตระกูลของผู้ฝัน'),
  ('DREAM_DAY_TUE','วันอังคาร','บิดามารดาของผู้ฝัน'),
  ('DREAM_DAY_WED','วันพุธ','บุตรและภรรยา'),
  ('DREAM_DAY_THU','วันพฤหัสบดี','ครูบาอาจารย์ อุปัชฌาย์ และผู้ใหญ่'),
  ('DREAM_DAY_FRI','วันศุกร์','ทรัพย์สิน วัวควาย ช้างและม้า'),
  ('DREAM_DAY_SAT','วันเสาร์','ตัวผู้ฝันเอง')
) as v(concept_key, day, who)
join content.symbol s on s.concept_key = v.concept_key and s.status = 'published'
cross join p cross join tr
where not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.passage_id = (select id from p));

-- ---------------------------------------------------------------------------
-- หน้า ๑๒ — each image with its own outcome
-- ---------------------------------------------------------------------------

with p as (select p.id from content.passage p join content.edition e on e.id = p.edition_id
            where e.citekey = 'nlt-6238-2477'
              and p.locator = 'หน้า ๑๒ ส่วนคำทำนายฝันรายสัญลักษณ์' limit 1),
tr as (select id from content.tradition where slug = 'folk-central')
insert into content.interpretation
  (symbol_id, passage_id, tradition_id, body_th, summary_plain_th, claim_type,
   context_note_th, corroborating_edition_ids, status, published_at)
select s.id, p.id, tr.id, v.body, v.plain, 'historical_belief',
  'เป็นความเชื่อที่บันทึกไว้ในตำรา พ.ศ. 2477 ไม่ใช่คำรับรองว่าจะเกิดขึ้นจริง '
  'และตำราเล่มนี้ไม่ได้ผูกเลขกับสัญลักษณ์เหล่านี้',
  '{}', 'published', now()
from (values
  ('DREAM_EXCREMENT',
   'ตำราจัดการฝันว่าอุจจาระปัสสาวะเปื้อนต้องตัวไว้ในกลุ่มเดียวกับการฝันว่ากินเหล้าเมามาย '
   'และการฝันว่าพบซากศพเน่าพอง โดยระบุผลตรงกันว่าจะได้ลาภมาก และจะสมดังที่คิดไว้',
   'ตำราเก่าว่าฝันเห็นของสกปรกเปื้อนตัว เป็นลางว่าจะได้ลาภและสมหวัง'),
  ('DREAM_LIQUOR',
   'ตำราจัดการฝันว่ากินเหล้าเมามายไว้ในกลุ่มเดียวกับการฝันว่าถูกของโสโครกและการพบซากศพ '
   'โดยระบุผลตรงกันว่าจะได้ลาภมาก และจะสมดังที่คิดไว้',
   'ตำราเก่าว่าฝันว่ากินเหล้าเมา เป็นลางว่าจะได้ลาภและสมหวัง'),
  ('DREAM_CORPSE',
   'ตำราจัดการฝันว่าพบซากศพเน่าพองไว้ในกลุ่มเดียวกับการฝันว่าถูกของโสโครกและการกินเหล้าเมา '
   'โดยระบุผลตรงกันว่าจะได้ลาภมาก และจะสมดังที่คิดไว้',
   'ตำราเก่าว่าฝันเห็นศพ ไม่ใช่ลางร้าย แต่เป็นลางว่าจะได้ลาภและสมหวัง'),
  ('DREAM_SILK',
   'ตำราว่าการฝันเห็นผ้าแพรภูษา ผู้ฝันจะอยู่เป็นสุข ไม่มีผู้ใดมาบุกรุกรานเบียดเบียน',
   'ฝันเห็นผ้าแพรผ้าไหม ตำราเก่าว่าจะอยู่สบาย ไม่มีใครมารบกวน'),
  ('DREAM_FISHING',
   'ตำราว่าการฝันว่าทอดแห ตกเบ็ด หรือหาปลาในแม่น้ำ ผู้ฝันคิดสิ่งใดก็จะมีแต่ความสวัสดี '
   'สมดังที่ใจปอง',
   'ฝันว่าทอดแหหาปลา ตำราเก่าว่าคิดทำอะไรก็จะราบรื่นสมใจ'),
  ('DREAM_NAGA',
   'ตำราว่าการฝันเห็นนาคเลื้อยเกี่ยวกอดรัดตัว ไม่ให้ตกใจกลัว เพราะเป็นนิมิตว่าจะมีผู้คุ้มครองรักษา',
   'ฝันว่านาคพันตัว ตำราเก่าว่าไม่ต้องกลัว เป็นลางว่าจะมีคนคอยคุ้มครอง'),
  ('DREAM_RING',
   'ตำราว่าการฝันว่าได้แหวนมา ผู้ฝันจะได้ภรรยาและบุตรที่รักใคร่ร่วมใจกัน',
   'ฝันว่าได้แหวน ตำราเก่าว่าจะได้คู่ครองและลูกที่รักกันดี'),
  ('DREAM_FRUIT',
   'ตำราว่าการฝันเห็นผลไม้ชนิดใดก็ตาม หากได้ใช้ได้กิน จะสมความปรารถนา',
   'ฝันเห็นผลไม้แล้วได้กิน ตำราเก่าว่าจะสมหวังดังตั้งใจ')
) as v(concept_key, body, plain)
join content.symbol s on s.concept_key = v.concept_key and s.status = 'published'
cross join p cross join tr
where not exists (select 1 from content.interpretation i
                   where i.symbol_id = s.id and i.passage_id = (select id from p));

do $$
declare r record; bad int := 0;
begin
  for r in select * from ops.assert_rights_invariants() loop
    if r.violations > 0 then bad := bad + 1; end if;
  end loop;
  if bad > 0 then raise exception 'aborted: % rights invariant(s)', bad; end if;
end $$;

select
  (select count(*) from content.interpretation where status='published') as published_interpretations,
  (select count(*) from content.symbol where status='published')         as published_symbols;
