#!/usr/bin/env node
// ============================================================================
// Ingest official สลากกินแบ่งรัฐบาล results into Supabase.
//
// This script does exactly three things: fetch, forward, check the answer.
// All parsing, validation, idempotency and status logic live in SQL, inside
// api.lottery_ingest — so the rules that decide whether a draw is "announced"
// are covered by the assertion suite rather than by a script nobody tests.
//
// Zero dependencies on purpose: Node 20 has global fetch, so there is no
// `npm install` step that can break a scheduled run, and the same file runs
// under PowerShell on Windows for a manual retry.
//
// Why this runs server-side at all: the app is Flutter web on GitHub Pages and
// cannot call glo.or.th from the browser (CORS). Ingesting here also means the
// app keeps working when GLO is down, and gets history for statistics.
//
// Usage:
//   node scripts/ingest-lottery.mjs --mode=latest
//   node scripts/ingest-lottery.mjs --mode=backfill --from=2024-08-01 --to=2026-07-16
//   node scripts/ingest-lottery.mjs --mode=probe
//   node scripts/ingest-lottery.mjs --dates=2025-05-02,2024-12-30
//
// Env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// ============================================================================

const GLO_LATEST  = 'https://www.glo.or.th/api/lottery/getLatestLottery';
const GLO_BY_DATE = 'https://www.glo.or.th/api/checking/getLotteryResult';

// Identify ourselves with a contact URL, and keep requests sequential and
// spaced. GLO is a government service under no obligation to serve us; a
// backfill that hammers it is both rude and the fastest way to get blocked.
const UA = 'Nimit/0.1 (+https://github.com/cheetahokok-sudo/Nimit) lottery-result-ingest';
const GAP_MS = 2000;
const RETRY_BACKOFF_MS = [5000, 20000, 60000];

const args = Object.fromEntries(
  process.argv.slice(2).map(a => {
    const m = /^--([^=]+)(?:=(.*))?$/.exec(a);
    return m ? [m[1], m[2] ?? 'true'] : [a, 'true'];
  }));

const MODE = args.mode ?? (args.dates ? 'dates' : 'latest');
const RUN  = process.env.GITHUB_RUN_ID
  ? `${process.env.GITHUB_WORKFLOW}#${process.env.GITHUB_RUN_ID}`
  : 'manual';

const SUPABASE_URL = (process.env.SUPABASE_URL ?? '').replace(/\/+$/, '');
const SERVICE_KEY  = process.env.SUPABASE_SERVICE_ROLE_KEY ?? '';

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('FATAL: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set.');
  process.exit(2);
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

// ---------------------------------------------------------------------------
// Fetch with retry. Retries network errors and 5xx; a 4xx is a real answer
// about our request and retrying it just wastes the server's time.
// ---------------------------------------------------------------------------
async function fetchGlo(url, body) {
  let lastErr;
  for (let attempt = 0; attempt <= RETRY_BACKOFF_MS.length; attempt++) {
    if (attempt > 0) {
      const wait = RETRY_BACKOFF_MS[attempt - 1];
      console.log(`   retry ${attempt} in ${wait / 1000}s (${lastErr})`);
      await sleep(wait);
    }
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'User-Agent': UA },
        body: JSON.stringify(body ?? {}),
        signal: AbortSignal.timeout(30000),
      });
      const text = await res.text();
      if (res.status >= 500) { lastErr = `HTTP ${res.status}`; continue; }
      let json;
      try { json = JSON.parse(text); }
      catch {
        // Not JSON: still forward it, so the raw payload is retained and the
        // shape change is visible in the database rather than only in a log
        // that expires in 90 days.
        json = { _unparseable: true, _body: text.slice(0, 4000) };
      }
      return { status: res.status, json };
    } catch (e) {
      lastErr = e.name === 'TimeoutError' ? 'timeout' : (e.message ?? String(e));
    }
  }
  return { status: 0, json: { _fetchFailed: true, _reason: String(lastErr) } };
}

// ---------------------------------------------------------------------------
// Forward to the one write path. Everything downstream is SQL.
// ---------------------------------------------------------------------------
async function ingest(payload, endpoint, httpStatus) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/lottery_ingest`, {
    method: 'POST',
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      'Content-Type': 'application/json; charset=utf-8',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      p_payload: payload, p_endpoint: endpoint,
      p_http_status: httpStatus, p_run: RUN,
    }),
    signal: AbortSignal.timeout(30000),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`lottery_ingest returned HTTP ${res.status}: ${text.slice(0, 400)}`);
  return JSON.parse(text);
}

const pad = n => String(n).padStart(2, '0');
const toParts = iso => {
  const [y, m, d] = iso.split('-');
  return { date: pad(d), month: pad(m), year: y };
};
const isoOf = d => `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
const shift = (iso, days) => {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return isoOf(d);
};

// The nominal calendar: the 1st and 16th of each month in range. GLO moves
// draws off these dates, which is handled by the ±window scan below rather
// than by pretending the convention is reliable.
function nominalDates(fromIso, toIso) {
  const out = [];
  const start = new Date(`${fromIso.slice(0, 7)}-01T00:00:00Z`);
  const end = new Date(`${toIso}T00:00:00Z`);
  for (let d = new Date(start); d <= end; d.setUTCMonth(d.getUTCMonth() + 1)) {
    for (const day of [1, 16]) {
      const iso = `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(day)}`;
      if (iso >= fromIso && iso <= toIso) out.push(iso);
    }
  }
  return out;
}

async function ingestDate(iso, label = '') {
  const { status, json } = await fetchGlo(GLO_BY_DATE, toParts(iso));
  const verdict = await ingest(json, 'getLotteryResult', status);
  const tag = verdict.ok ? verdict.outcome : `INVALID (${verdict.reasonTh ?? ''})`;
  console.log(`   ${iso}${label}  -> ${tag}${verdict.numbers ? ` (${verdict.numbers} numbers)` : ''}`);
  return verdict;
}

// ---------------------------------------------------------------------------
async function main() {
  const failures = [];
  let ingested = 0;

  if (MODE === 'probe') {
    // Capture real payloads without interpreting them. Used before changing the
    // parser: the shape gets confirmed from a payload sitting in raw_payload,
    // not from documentation.
    console.log('== probe: getLatestLottery');
    const a = await fetchGlo(GLO_LATEST, {});
    console.log('   top-level keys:', Object.keys(a.json).join(', '));
    console.log('   ->', JSON.stringify(await ingest(a.json, 'probe:getLatestLottery', a.status)));
    await sleep(GAP_MS);
    console.log('== probe: getLotteryResult (2024-03-01)');
    const b = await fetchGlo(GLO_BY_DATE, toParts('2024-03-01'));
    console.log('   ->', JSON.stringify(await ingest(b.json, 'probe:getLotteryResult', b.status)));
    return 0;
  }

  if (MODE === 'latest') {
    console.log('== latest draw');
    const { status, json } = await fetchGlo(GLO_LATEST, {});
    const verdict = await ingest(json, 'getLatestLottery', status);
    console.log('   ->', JSON.stringify(verdict));
    if (!verdict.ok) { failures.push(`latest: ${verdict.reasonTh}`); }
    else if (verdict.outcome === 'announced') ingested++;
  }

  if (MODE === 'dates' || args.dates) {
    const list = String(args.dates ?? '').split(',').map(s => s.trim()).filter(Boolean);
    console.log(`== explicit dates (${list.length})`);
    for (const iso of list) {
      const v = await ingestDate(iso);
      if (!v.ok) failures.push(`${iso}: ${v.reasonTh}`);
      else if (v.outcome === 'announced') ingested++;
      await sleep(GAP_MS);
    }
  }

  if (MODE === 'backfill') {
    const to = args.to ?? isoOf(new Date());
    const from = args.from ?? shift(to, -730);   // two years
    const dates = nominalDates(from, to);
    console.log(`== backfill ${from} .. ${to} (${dates.length} nominal draw dates)`);

    for (const iso of dates) {
      const v = await ingestDate(iso);
      if (!v.ok) failures.push(`${iso}: ${v.reasonTh}`);
      else if (v.outcome === 'announced') ingested++;
      await sleep(GAP_MS);

      // A nominal date with no draw usually means GLO MOVED that งวด — 1 ม.ค.
      // is drawn in late ธ.ค., and 16 พ.ค. 2568 was drawn 2 พ.ค. Rather than
      // hardcode the exceptions (which change), scan a small window around the
      // miss. Misses are rare, so this costs little.
      if (v.ok && v.outcome === 'no_draw') {
        console.log(`   ${iso} has no draw — scanning ±5 days for a moved งวด`);
        for (const delta of [-1, 1, -2, 2, -3, 3, -4, 4, -5, 5]) {
          const alt = shift(iso, delta);
          const av = await ingestDate(alt, ' (moved?)');
          await sleep(GAP_MS);
          if (av.ok && av.outcome === 'announced') { ingested++; break; }
        }
      }
    }
  }

  console.log(`\n== ingested ${ingested} announced draw(s)`);
  if (failures.length) {
    console.error(`== ${failures.length} failure(s):`);
    for (const f of failures) console.error(`   - ${f}`);
    return 1;
  }
  return 0;
}

main().then(c => process.exit(c)).catch(e => {
  console.error('FATAL:', e?.stack ?? e);
  process.exit(1);
});
