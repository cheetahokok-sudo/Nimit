// ============================================================================
// ทำนายฝันสัตว์ต่าง ๆ 100 ตัวเลข — ฝันพยากรณ์ หน้า 13–23
//
// The table is built out of RECIPROCAL PAIRS: each animal occupies two slots,
// and each slot prints its partner's number. มังกรบิน is slot 01 printing 95,
// and slot 95 printing 01. That redundancy is the whole reason this file
// exists — a misread digit almost always breaks its pair, so the book checks
// my transcription for me.
//
// 100 slots, 50 animals, every number appearing exactly twice.
//
// Slots are STRINGS throughout. '00' and '0' are different lottery numbers and
// there is no parseInt anywhere in this file, deliberately — same rule as
// import-book-numbers.mjs.
//
// Run: node supabase/seeds/incoming/verify-100-animals.mjs
// ============================================================================

// slot, animal as printed at that slot, partner slot printed beside it
const SLOTS = [
  ['01', 'มังกรบิน', '95'], ['02', 'หงส์', '53'], ['03', 'กิเลน', '52'],
  ['04', 'นกยูง', '65'], ['05', 'สิงโต', '89'], ['06', 'นกอินทรี', '91'],
  ['07', 'เสือโคร่ง', '58'], ['08', 'นกกระเรียน', '57'], ['09', 'เสือดาว', '87'],
  ['10', 'นกกาเหว่า', '82'], ['11', 'ช้าง', '77'], ['12', 'ห่านฟ้า', '69'],
  ['13', 'กวางดาว', '79'], ['14', 'นกขมิ้น', '96'], ['15', 'ม้า', '54'],
  ['16', 'นกนางแอ่น', '74'], ['17', 'วัวกระทิง', '88'], ['18', 'เป็ดแมนดาริน', '78'],
  ['19', 'แพะ', '62'], ['20', 'กา (อีกา)', '72'], ['21', 'ลิง', '93'],
  ['22', 'นกกระทา', '70'], ['23', 'หมูป่า', '84'], ['24', 'นกพิราบ', '66'],
  ['25', 'สุนัขขาว', '85'], ['26', 'นกกระจาบ', '90'], ['27', 'แมว', '61'],
  ['28', 'ค้างคาว', '68'], ['29', 'สุนัขจิ้งจอก', '63'], ['30', 'ไก่ ไก่ขัน', '99'],
  ['31', 'สุนัขป่า', '94'], ['32', 'นกกระจอก', '60'], ['33', 'กระต่าย', '86'],
  ['34', 'คางคก กบ', '73'], ['35', 'หนู', '75'], ['36', 'ตะขาบ', '83'],
  ['37', 'ปลาวาฬ', '59'], ['38', 'แมงมุม', '67'], ['39', 'จระเข้', '55'],
  ['40', 'แมลงปอ', '76'], ['41', 'ปลาฉลาม', '56'], ['42', 'จิ้งหรีด', '97'],
  ['43', 'ปลาเงิน', '71'], ['44', 'แมวน้ำ นาก', '81'], ['45', 'กุ้ง กุ้งนาง', '51'],
  ['46', 'ปู', '64'], ['47', 'ผีเสื้อ', '92'], ['48', 'ผึ้ง', '00'],
  ['49', 'จักจั่น', '80'], ['50', 'หอยขม', '98'], ['51', 'กุ้งก้ามกราม', '45'],
  ['52', 'กิเลน', '03'], ['53', 'หงส์', '02'], ['54', 'ม้า', '15'],
  ['55', 'จระเข้', '39'], ['56', 'ปลาฉลาม', '41'], ['57', 'นกกระเรียน', '08'],
  ['58', 'เสือโคร่ง', '07'], ['59', 'ปลาวาฬ', '37'], ['60', 'นกกระจอก', '32'],
  ['61', 'แมว', '27'], ['62', 'แพะ', '19'], ['63', 'สุนัขจิ้งจอก', '29'],
  ['64', 'ปู', '46'], ['65', 'นกยูง', '04'], ['66', 'นกพิราบ', '24'],
  ['67', 'แมงมุม', '38'], ['68', 'ค้างคาว', '28'], ['69', 'ห่านฟ้า', '12'],
  ['70', 'นกกระทา', '22'], ['71', 'ปลาเงิน ปลาทอง', '43'], ['72', 'กา (อีกา)', '20'],
  ['73', 'กบ คางคก', '34'], ['74', 'นกนางแอ่น', '16'], ['75', 'หนู', '35'],
  ['76', 'แมลงปอ', '40'], ['77', 'ช้าง', '11'], ['78', 'เป็ดแมนดาริน', '18'],
  ['79', 'กวางดาว', '13'], ['80', 'จักจั่น', '49'], ['81', 'แมวน้ำ นาก', '44'],
  ['82', 'นกกาเหว่า', '10'], ['83', 'ตะขาบ', '36'], ['84', 'หมูป่า', '23'],
  ['85', 'สุนัข', '25'], ['86', 'กระต่าย', '33'], ['87', 'เสือดาว', '09'],
  ['88', 'วัวกระทิง', '17'], ['89', 'สิงโต', '05'], ['90', 'นกกระจาบ', '26'],
  ['91', 'นกอินทรี', '06'], ['92', 'ผีเสื้อ', '47'], ['93', 'ลิง', '21'],
  ['94', 'สุนัขป่า', '31'], ['95', 'มังกรบิน', '01'], ['96', 'นกขมิ้น', '14'],
  ['97', 'จิ้งหรีด', '42'], ['98', 'หอยขม หอยโข่ง', '50'], ['99', 'ไก่ ไก่ขัน', '30'],
  ['00', 'ผึ้ง', '48'],
];

// Which printed page each slot came from — so a citation points at the page a
// reader can actually open, and so a whole misread page is traceable.
// Pages 13–22 print nine entries each; page 23 prints TEN (91–00), because the
// hundredth slot is '00' rather than a further page. A flat i/9 would put '00'
// on a page 24 that does not exist. The TSV never happens to ask for it — every
// pair's first occurrence lands in 13–18 — but a citation generator that is
// quietly wrong for one input is not one to leave in place.
const PAGE_OF = (slot) => {
  const i = SLOTS.findIndex(([s]) => s === slot);
  return String(i < 90 ? 13 + Math.floor(i / 9) : 23);
};

// Three entries name an animal the lexicon already holds under a broader
// primary term, with the book's name recorded there as a synonym. The importer
// matches primary terms ONLY — deliberately, since matching any term is what
// once gave the generic ปลา four numbers belonging to a whale and a shark — so
// without this map these three would be silently dropped as "missing symbols"
// that in fact exist.
//
// This is safe here in a way the ปลา case was not: each is a one-to-one
// synonym the lexicon itself asserts, and the book has no separate plain
// กวาง / วัว entry whose numbers could collide. If a later edition adds one,
// these become their own symbols instead.
const LEXICON_ALIAS = {
  'กวางดาว': 'กวาง',            // DREAM_DEER
  'วัวกระทิง': 'วัว',             // DREAM_COW
  'ปลาทอง': 'ปลาเงินปลาทอง',   // DREAM_GOLDFISH — printed with a space, stored without
};

const fail = [];
const bySlot = new Map(SLOTS.map(([s, name, partner]) => [s, { name, partner }]));

if (SLOTS.length !== 100) fail.push(`expected 100 slots, got ${SLOTS.length}`);
if (bySlot.size !== 100) fail.push(`duplicate slot numbers present`);

// The reciprocity check. Both directions, and the NAME must agree too — a
// partner number that happens to line up while naming a different animal is
// the exact mistake a digit-only check would wave through.
const norm = (s) => s.replace(/\s*\(.*?\)\s*/g, ' ').split(/\s+/).filter(Boolean);
for (const [slot, name, partner] of SLOTS) {
  const other = bySlot.get(partner);
  if (!other) { fail.push(`${slot} (${name}) points at ${partner}, which does not exist`); continue; }
  if (other.partner !== slot) {
    fail.push(`${slot} → ${partner}, but ${partner} → ${other.partner} (not back to ${slot})`);
  }
  // The two slots often print the same animal differently: shorter or longer
  // (สุนัข / สุนัขขาว, กุ้ง / กุ้งก้ามกราม), or with the two names of a pair
  // swapped (คางคก กบ / กบ คางคก). So require that SOME word of one is a
  // substring of some word of the other, in either direction — not word
  // equality, which reads a prefix as a different animal.
  const a = norm(name), b = norm(other.name);
  const related = a.some((x) => b.some((y) => x.includes(y) || y.includes(x)));
  if (!related) {
    fail.push(`${slot} "${name}" pairs with ${partner} "${other.name}" — unrelated names`);
  }
}

// Group by the PAIR, not by the printed name. The pairing is what the book
// asserts structurally; the name is just how that slot happened to print it.
// Keying on a name would split สุนัข from สุนัขขาว into two "animals" and
// report a table of 50 as a table of 56.
const animals = new Map();
for (const [slot, , partner] of SLOTS) {
  const key = [slot, partner].sort().join('-');
  if (!animals.has(key)) animals.set(key, []);
  animals.get(key).push(slot);
}
for (const [key, slots] of animals) {
  if (slots.length !== 2) fail.push(`pair ${key} has ${slots.length} slot(s) (${slots.join(',')}), expected 2`);
}

if (fail.length) {
  console.error(`\n== ${fail.length} problem(s) — transcription is NOT verified ==`);
  for (const f of fail) console.error('  ' + f);
  process.exit(1);
}

console.error(`OK: 100 slots, ${animals.size} animals, all pairs reciprocal.`);

// Emit the importer's TSV: one line per animal, both of its numbers, cited to
// the page its lower slot appears on. No gist column — this table prints
// numbers only, and inventing a meaning is exactly what the library forbids.
// The importer matches content.symbol_term.term EXACTLY, on kind='primary'.
// So the word emitted here must be the canonical name, not the fullest label:
// 'กา (อีกา)' and 'ไก่ ไก่ขัน' would never match a term, and would be reported
// as missing symbols that in fact already exist.
//
// Rule: take every name printed at either slot, split off parentheticals and
// alternates, and use the SHORTEST — which is the generic form the lexicon
// keys on (สุนัข not สุนัขขาว, กุ้ง not กุ้งก้ามกราม, กา not กา (อีกา)).
// The discarded variants are emitted as comments so the fuller readings are
// not lost; they belong in symbol_term as synonyms, not in this column.
const seen = new Set();
const out = [];
for (const [slot, , partner] of SLOTS) {
  const key = [slot, partner].sort().join('-');
  if (seen.has(key)) continue;
  seen.add(key);
  const [a, b] = key.split('-');
  const printed = SLOTS.filter(([s]) => s === a || s === b).map(([, n]) => n);
  const names = [...new Set(printed.flatMap(norm))];
  const shortest = names.reduce((x, y) => (y.length < x.length ? y : x));
  const canonical = LEXICON_ALIAS[shortest] ?? shortest;
  const others = names.filter((n) => n !== canonical);
  if (others.length) out.push(`# ${canonical} — ตำราพิมพ์ว่า: ${others.join(', ')}`);
  out.push([PAGE_OF(slot), canonical, `${a},${b}`].join('\t'));
}
console.log('# ฝันพยากรณ์ หน้า 13–23 — ทำนายฝันสัตว์ต่าง ๆ 100 ตัวเลข');
console.log('# 50 animals, two numbers each, verified reciprocal by pair.');
console.log('# Comment lines record the alternate names the book prints for an entry.');
console.log(out.join('\n'));
