#!/usr/bin/env node
// ============================================================================
// Render the editorial review desk from a database dump.
//
//   psql "$PGURL" -t -A -f scripts/review-dump.sql > review.json
//   node scripts/build-review-desk.mjs review.json > desk.html
//
// The desk exists because the pipeline has a human in it by design. Automated
// checks (scripts/review-checks.sql) can find problems but may never publish;
// this page is where a person sees what the checks found and decides.
//
// Self-contained output: no external fonts, scripts or images, so it can be
// published as an artifact under a strict CSP or opened straight off disk.
// Zero dependencies for the same reason the ingest script has none — a build
// step that can break is a build step that will, on the day it matters.
// ============================================================================

import { readFileSync } from 'node:fs';

const file = process.argv[2];
if (!file) {
  console.error('usage: node scripts/build-review-desk.mjs <review.json> > desk.html');
  process.exit(2);
}
const DATA = JSON.parse(readFileSync(file, 'utf8'));

const CSS = `
:root{
  /* Lifted from app/lib/core/theme/nimit_theme.dart so the desk and the
     product read as one thing rather than two unrelated tools. */
  --ground:#F6F0E4; --well:#EFE7D8; --surface:#FFFCF5; --line:#E7DECB;
  --ink:#2B1B27; --ink-soft:#877880;
  --aubergine:#3B1E33; --gold:#E9C878; --gold-deep:#D9B45C;
  --ok-bg:#DFEBD9; --ok-ink:#3E6242;
  --warn-bg:#F7E3E0; --warn-ink:#A05548;
  --hold-bg:#F3EBDC; --hold-ink:#7A6438;
  --radius:14px;
}
@media (prefers-color-scheme:dark){
  :root{
    --ground:#20101B; --well:#2A1524; --surface:#33192B; --line:#4A2C40;
    --ink:#F3E7DE; --ink-soft:#B8A2B0; --aubergine:#F0DFC2;
    --ok-bg:#24382A; --ok-ink:#A8D0AE; --warn-bg:#43241F; --warn-ink:#EFAE9F;
    --hold-bg:#3A2E1C; --hold-ink:#E2C68A;
  }
}
:root[data-theme="dark"]{
  --ground:#20101B; --well:#2A1524; --surface:#33192B; --line:#4A2C40;
  --ink:#F3E7DE; --ink-soft:#B8A2B0; --aubergine:#F0DFC2;
  --ok-bg:#24382A; --ok-ink:#A8D0AE; --warn-bg:#43241F; --warn-ink:#EFAE9F;
  --hold-bg:#3A2E1C; --hold-ink:#E2C68A;
}
:root[data-theme="light"]{
  --ground:#F6F0E4; --well:#EFE7D8; --surface:#FFFCF5; --line:#E7DECB;
  --ink:#2B1B27; --ink-soft:#877880; --aubergine:#3B1E33;
  --ok-bg:#DFEBD9; --ok-ink:#3E6242; --warn-bg:#F7E3E0; --warn-ink:#A05548;
  --hold-bg:#F3EBDC; --hold-ink:#7A6438;
}
*{box-sizing:border-box}
body{margin:0;background:var(--ground);color:var(--ink);line-height:1.65;
  font-family:"Sarabun","Noto Sans Thai","Leelawadee UI","Tahoma",system-ui,sans-serif;
  -webkit-font-smoothing:antialiased}
.wrap{max-width:1000px;margin:0 auto;padding:32px 20px 72px}
.tnum{font-variant-numeric:tabular-nums}
header.top{border-bottom:2px solid var(--line);padding-bottom:20px;margin-bottom:24px}
.eyebrow{font-size:.78rem;letter-spacing:.14em;text-transform:uppercase;color:var(--ink-soft);font-weight:700}
h1{font-size:clamp(1.5rem,4vw,2.1rem);margin:.3em 0 .2em;font-weight:800;text-wrap:balance}
.sub{color:var(--ink-soft);font-size:.95rem;max-width:64ch}
.grid{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));margin:22px 0}
.stat{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);padding:14px 16px}
.stat b{display:block;font-size:1.9rem;font-weight:800;line-height:1.1}
.stat span{font-size:.82rem;color:var(--ink-soft)}
.stat.flag{background:var(--warn-bg);border-color:transparent}
.stat.flag b,.stat.flag span{color:var(--warn-ink)}
.stat.good{background:var(--ok-bg);border-color:transparent}
.stat.good b,.stat.good span{color:var(--ok-ink)}
.callout{background:var(--well);border-left:4px solid var(--gold-deep,var(--gold));
  border-radius:0 var(--radius) var(--radius) 0;padding:16px 18px;margin:22px 0}
.callout h3{margin:0 0 6px;font-size:1rem;font-weight:800}
.callout p{margin:0 0 8px;font-size:.92rem;color:var(--ink-soft)}
.callout p:last-child{margin-bottom:0}
nav.tabs{display:flex;gap:6px;flex-wrap:wrap;margin:30px 0 16px;border-bottom:1px solid var(--line)}
.tab{appearance:none;border:0;background:transparent;cursor:pointer;font:inherit;padding:9px 14px;
  color:var(--ink-soft);font-weight:700;font-size:.93rem;border-bottom:3px solid transparent}
.tab[aria-selected="true"]{color:var(--ink);border-bottom-color:var(--gold-deep,var(--gold))}
.tab:focus-visible{outline:2px solid var(--gold-deep,var(--gold));outline-offset:2px}
.search{width:100%;padding:11px 14px;border-radius:12px;border:1px solid var(--line);
  background:var(--surface);color:var(--ink);font:inherit;margin-bottom:18px}
.search:focus-visible{outline:2px solid var(--gold-deep,var(--gold));outline-offset:1px}
.srcgroup{margin-bottom:26px}
.srchead{display:flex;align-items:baseline;gap:10px;flex-wrap:wrap;padding:8px 0 10px;
  border-bottom:1px solid var(--line);margin-bottom:12px}
.srchead h2{font-size:1.05rem;margin:0;font-weight:800}
.srchead .count{font-size:.82rem;color:var(--ink-soft)}
.item{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);
  padding:14px 16px;margin-bottom:10px}
.item.blocker{border-left:4px solid var(--warn-ink)}
.item.warning{border-left:4px solid var(--gold-deep,var(--gold))}
.row1{display:flex;align-items:center;gap:9px;flex-wrap:wrap}
.sym{font-weight:800;font-size:1.05rem}
.loc{font-size:.82rem;color:var(--ink-soft)}
.plain{margin:8px 0 0;font-size:.94rem}
.quote{margin:10px 0 0;padding:10px 12px;background:var(--well);border-radius:10px;
  font-size:.88rem;border-left:3px solid var(--gold)}
.quote small{display:block;color:var(--ink-soft);font-size:.72rem;margin-bottom:4px;
  letter-spacing:.06em;text-transform:uppercase;font-weight:700}
.pill{display:inline-flex;align-items:center;padding:3px 10px;border-radius:999px;
  font-size:.76rem;font-weight:800}
.p-tier{background:var(--aubergine);color:var(--ground)}
.p-ok{background:var(--ok-bg);color:var(--ok-ink)}
.p-hold{background:var(--hold-bg);color:var(--hold-ink)}
.p-warn{background:var(--warn-bg);color:var(--warn-ink)}
.num{font-weight:800;font-variant-numeric:tabular-nums;letter-spacing:.06em;
  background:var(--gold);color:#2C1626;padding:3px 10px;border-radius:8px}
.chips{display:flex;flex-wrap:wrap;gap:7px}
.chip{background:var(--surface);border:1px solid var(--line);border-radius:999px;padding:5px 12px;font-size:.86rem}
.empty{color:var(--ink-soft);font-size:.92rem;padding:20px;text-align:center;
  background:var(--surface);border:1px dashed var(--line);border-radius:var(--radius)}
footer{margin-top:44px;padding-top:18px;border-top:1px solid var(--line);color:var(--ink-soft);font-size:.82rem}
.hidden{display:none}
@media (prefers-reduced-motion:reduce){*{transition:none!important;animation:none!important}}
`;

const BODY = `
<div class="wrap">
<header class="top">
  <div class="eyebrow">Nimit · คลังตำรา</div>
  <h1>โต๊ะตรวจทานคลังนิมิต</h1>
  <p class="sub">เครื่องตรวจอัตโนมัติหาข้อผิดพลาดให้ได้ แต่เผยแพร่เองไม่ได้ —
  หน้านี้คือจุดที่คนอ่านผลตรวจแล้วตัดสินใจ ทุกตัวเลขดึงจากฐานข้อมูลจริง</p>
</header>
<div class="grid" id="stats"></div>
<div id="alerts"></div>
<nav class="tabs" role="tablist">
  <button class="tab" role="tab" aria-selected="true"  data-panel="findings">ผลตรวจอัตโนมัติ</button>
  <button class="tab" role="tab" aria-selected="false" data-panel="published">เผยแพร่แล้ว</button>
  <button class="tab" role="tab" aria-selected="false" data-panel="drafts">รอสอบทาน</button>
  <button class="tab" role="tab" aria-selected="false" data-panel="gaps">ยังไม่มีคำแปล</button>
</nav>
<input class="search" id="q" type="search" placeholder="ค้นหา…" aria-label="ค้นหา">
<section id="panel-findings"></section>
<section id="panel-published" class="hidden"></section>
<section id="panel-drafts" class="hidden"></section>
<section id="panel-gaps" class="hidden"></section>
<footer>
  <p><strong>กติกาของสายงานนี้</strong> — เครื่องตรวจเสนอได้อย่างเดียว คนเท่านั้นที่เผยแพร่ได้
  ผลตรวจเป็นเพียงข้อสังเกต ไม่เปลี่ยนสถานะเนื้อหาใด ๆ เอง</p>
  <p>ข้อความในกรอบเส้นทองคือต้นฉบับคำต่อคำ เก็บได้เฉพาะงานที่พ้นลิขสิทธิ์
  งานที่ยังมีลิขสิทธิ์มีแต่ตัวชี้หน้าให้เปิดเล่มตรวจ ·
  เนื้อหาอ่อนไหว (พระราชวงศ์ บุคคลสาธารณะ ศาสนา) เผยแพร่ไม่ได้จนกว่าจะบันทึกการตรวจของที่ปรึกษากฎหมาย —
  บังคับด้วย CHECK constraint ในฐานข้อมูล ไม่ใช่ข้อตกลงกันเอง</p>
</footer>
</div>`;

const APP = String.raw`
(function(){
  var D = window.__NIMIT__;
  var $ = function(s){ return document.querySelector(s); };
  function esc(s){ return String(s==null?'':s).replace(/[&<>"]/g,function(c){
    return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]; }); }

  var st = D.stats, fc = D.findingCounts || {};
  var blockers = fc.blocker || 0, warnings = fc.warning || 0;
  var noReading = D.coverage.filter(function(c){ return c.n===0; }).length;

  $('#stats').innerHTML = [
    { n: blockers, l: 'ต้องแก้ก่อนเผยแพร่', flag: blockers>0, good: blockers===0 },
    { n: warnings, l: 'ต้องมีคนดู', flag: warnings>0 },
    { n: st.interpPublished, l: 'คำแปลที่เผยแพร่' },
    { n: noReading, l: 'สัญลักษณ์ที่ยังไม่มีคำแปล', flag: noReading>0 },
    { n: st.numbersPublished, l: 'เลขที่เผยแพร่', flag: st.numbersPublished===0 },
    { n: st.submissionsOpen, l: 'เรื่องเข้าใหม่รอตรวจ' }
  ].map(function(c){
    return '<div class="stat'+(c.flag?' flag':(c.good?' good':''))+'">'+
      '<b class="tnum">'+c.n+'</b><span>'+esc(c.l)+'</span></div>';
  }).join('');

  $('#alerts').innerHTML = (st.numbersPublished === 0)
    ? '<div class="callout"><h3>คอขวด · เลขประจำสัญลักษณ์ยังเผยแพร่ 0 รายการ</h3>'
      + '<p>กลไก ฝัน → เลข → ตรวจหวย ต่อครบแล้ว แต่ยังไม่มีเลขไหลผ่าน '
      + 'ตำราสาธารณสมบัติที่ถอดความมาไม่ได้ผูกเลขไว้เลย เลขต้องมาจากหนังสือที่ถือครอง '
      + 'และทุกแถวเข้าเป็นฉบับร่างรอแหล่งที่สองเสมอ</p></div>'
    : '';

  function pill(cls, txt){ return '<span class="pill '+cls+'">'+esc(txt)+'</span>'; }

  function renderFindings(f){
    var sev = { blocker:'ต้องแก้ก่อนเผยแพร่', warning:'ต้องมีคนดู', note:'บันทึกไว้' };
    var groups = {};
    D.findings.forEach(function(x){
      var hay = (x.code+' '+x.message+' '+JSON.stringify(x.detail||{})).toLowerCase();
      if (f && hay.indexOf(f)===-1) return;
      (groups[x.severity] = groups[x.severity] || []).push(x);
    });
    var order = ['blocker','warning','note'].filter(function(s){ return groups[s]; });
    if (!order.length) return '<p class="empty">ไม่มีผลตรวจที่ตรงกับคำค้น</p>';
    return order.map(function(s){
      var items = groups[s].map(function(x){
        var d = x.detail || {};
        var bits = Object.keys(d).map(function(k){ return esc(k)+': '+esc(d[k]); }).join(' · ');
        return '<div class="item '+s+'"><div class="row1">'
          + pill(s==='blocker'?'p-warn':(s==='warning'?'p-hold':'p-ok'), sev[s])
          + '<span class="loc">'+esc(x.code)+'</span></div>'
          + '<p class="plain">'+esc(x.message)+'</p>'
          + (bits ? '<p class="plain" style="color:var(--ink-soft);font-size:.85rem">'+bits+'</p>' : '')
          + '</div>';
      }).join('');
      return '<div class="srcgroup"><div class="srchead"><h2>'+esc(sev[s])+'</h2>'
        + '<span class="count tnum">'+groups[s].length+' รายการ</span></div>'+items+'</div>';
    }).join('');
  }

  function renderPublished(f){
    var groups = {};
    D.published.forEach(function(p){
      var hay = (p.symbol+' '+p.work+' '+p.locator+' '+(p.plain||'')).toLowerCase();
      if (f && hay.indexOf(f)===-1) return;
      (groups[p.work] = groups[p.work] || []).push(p);
    });
    var keys = Object.keys(groups).sort(function(a,b){ return groups[b].length-groups[a].length; });
    if (!keys.length) return '<p class="empty">ไม่พบรายการที่ตรงกับคำค้น</p>';
    return keys.map(function(w){
      return '<div class="srcgroup"><div class="srchead"><h2>'+esc(w)+'</h2>'
        + '<span class="count tnum">'+groups[w].length+' คำแปล</span></div>'
        + groups[w].map(function(p){
            return '<div class="item"><div class="row1"><span class="sym">'+esc(p.symbol)+'</span>'
              + pill('p-tier', (p.tier||'?').toUpperCase())
              + (p.rights==='public_domain' ? pill('p-ok','พ้นลิขสิทธิ์') : pill('p-hold','มีลิขสิทธิ์'))
              + (p.sensitivity && p.sensitivity!=='routine' ? pill('p-warn', p.sensitivity) : '')
              + '<span class="loc">'+esc(p.locator)+'</span></div>'
              + (p.plain ? '<p class="plain">'+esc(p.plain)+'</p>' : '')
              + (p.quote ? '<div class="quote"><small>ข้อความต้นฉบับ</small>'+esc(p.quote)+'</div>' : '')
              + '</div>';
          }).join('')
        + '</div>';
    }).join('');
  }

  function renderDrafts(f){
    var out = '';
    var nums = D.draftNumbers.filter(function(n){
      return !f || (n.symbol+' '+n.number+' '+(n.source||'')).toLowerCase().indexOf(f)!==-1; });
    var ints = D.drafts.filter(function(i){
      return !f || (i.symbol+' '+(i.source||'')).toLowerCase().indexOf(f)!==-1; });
    var circ = (D.circulating||[]).filter(function(c){
      return !f || ((c.occasion||'')+' '+(c.number||'')).toLowerCase().indexOf(f)!==-1; });

    if (nums.length){
      var byS = {};
      nums.forEach(function(n){ (byS[n.symbol]=byS[n.symbol]||[]).push(n); });
      out += '<div class="srcgroup"><div class="srchead"><h2>เลขประจำสัญลักษณ์ (ฉบับร่าง)</h2>'
        + '<span class="count tnum">'+nums.length+' เลข</span></div>'
        + Object.keys(byS).map(function(s){
            var g = byS[s];
            return '<div class="item"><div class="row1"><span class="sym">'+esc(s)+'</span>'
              + g.map(function(n){ return '<span class="num">'+esc(n.number)+'</span>'; }).join(' ')
              + pill('p-hold','รอแหล่งที่สอง')+'</div>'
              + '<p class="plain">'+esc(g[0].source||'ยังไม่ระบุฉบับ')
              + (g[0].locator ? ' · '+esc(g[0].locator) : '')+'</p></div>';
          }).join('') + '</div>';
    }
    if (circ.length){
      out += '<div class="srcgroup"><div class="srchead"><h2>ความเชื่อที่กำลังแพร่หลาย</h2>'
        + '<span class="count tnum">'+circ.length+' รายการ</span></div>'
        + circ.map(function(c){
            return '<div class="item"><div class="row1">'
              + (c.number ? '<span class="num">'+esc(c.number)+'</span>' : '')
              + '<span class="sym">'+esc(c.occasion)+'</span>'
              + (c.sensitivity!=='routine' ? pill('p-warn', c.sensitivity + (c.cleared?' · ผ่านที่ปรึกษา':' · ยังไม่ผ่าน')) : '')
              + pill(c.status==='published'?'p-ok':'p-hold', c.status)
              + '</div><p class="plain">'+esc(c.from||'')+(c.to?' – '+esc(c.to):'')
              + (c.channel ? ' · '+esc(c.channel) : '')+'</p></div>';
          }).join('') + '</div>';
    }
    if (ints.length){
      out += '<div class="srcgroup"><div class="srchead"><h2>คำแปล (ฉบับร่าง)</h2>'
        + '<span class="count tnum">'+ints.length+' รายการ</span></div>'
        + ints.map(function(i){
            return '<div class="item"><div class="row1"><span class="sym">'+esc(i.symbol)+'</span>'
              + pill('p-hold','รอเนื้อหาจริง')+'<span class="loc">'+esc(i.locator||'')+'</span></div>'
              + '<p class="plain">'+esc((i.body||'').slice(0,160))+'</p></div>';
          }).join('') + '</div>';
    }
    return out || '<p class="empty">ไม่มีรายการฉบับร่างที่ตรงกับคำค้น</p>';
  }

  function renderGaps(f){
    var gaps = D.coverage.filter(function(c){
      return c.n===0 && (!f || c.symbol.toLowerCase().indexOf(f)!==-1); });
    if (!gaps.length) return '<p class="empty">ไม่พบสัญลักษณ์ที่ตรงกับคำค้น</p>';
    return '<div class="srcgroup"><div class="srchead"><h2>สัญลักษณ์ที่ยังไม่มีคำแปล</h2>'
      + '<span class="count tnum">'+gaps.length+' คำ</span></div>'
      + '<p class="plain" style="margin-bottom:12px;color:var(--ink-soft)">'
      + 'คำเหล่านี้จับคู่ในฝันได้ แต่แอปจะตอบตรงไปตรงมาว่ายังไม่มีคำแปลที่มีตำรารองรับ</p>'
      + '<div class="chips">'+gaps.map(function(g){
          return '<span class="chip">'+esc(g.symbol)+'</span>'; }).join('')+'</div></div>';
  }

  function draw(){
    var f = ($('#q').value||'').trim().toLowerCase();
    $('#panel-findings').innerHTML  = renderFindings(f);
    $('#panel-published').innerHTML = renderPublished(f);
    $('#panel-drafts').innerHTML    = renderDrafts(f);
    $('#panel-gaps').innerHTML      = renderGaps(f);
  }
  Array.prototype.forEach.call(document.querySelectorAll('.tab'), function(btn){
    btn.addEventListener('click', function(){
      Array.prototype.forEach.call(document.querySelectorAll('.tab'), function(b){
        b.setAttribute('aria-selected', String(b===btn)); });
      ['findings','published','drafts','gaps'].forEach(function(p){
        $('#panel-'+p).classList.toggle('hidden', p!==btn.dataset.panel); });
    });
  });
  $('#q').addEventListener('input', draw);
  draw();
})();`;

const OPEN = '<' + 'script>';
const CLOSE = '<' + '/script>';

process.stdout.write(
  '<title>โต๊ะตรวจทานคลังนิมิต — Nimit editorial desk</title>\n' +
  '<style>' + CSS + '</style>\n' +
  BODY + '\n' +
  OPEN + 'window.__NIMIT__=' + JSON.stringify(DATA) + ';' + CLOSE + '\n' +
  OPEN + APP + CLOSE + '\n'
);

console.error('review desk built · ' + (DATA.published || []).length + ' published · ' +
  (DATA.findings || []).length + ' findings');
