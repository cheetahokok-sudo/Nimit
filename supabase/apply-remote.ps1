<#
.SYNOPSIS
  Apply the Nimit content library to a Supabase project: migrations, seeds, then
  the verification suite.

.DESCRIPTION
  Migrations go through `supabase db push` so they are recorded in the CLI's
  migration table. Seeds are data rather than schema and are applied with psql —
  seeding through migrations would replay them per environment and collide with
  live editorial edits.

  The script refuses to run against a project whose name does not look like
  Nimit, so a mistyped ref cannot drop this schema onto an unrelated database.

.PARAMETER ProjectRef
  Supabase project ref (the 20-character id in the dashboard URL).

.PARAMETER DbUrl
  Direct Postgres connection string. Get it from
  Dashboard -> Project Settings -> Database -> Connection string -> URI.
  Prefer setting $env:SUPABASE_DB_URL instead of passing it on the command line,
  so the password does not land in your shell history.

.EXAMPLE
  $env:SUPABASE_DB_URL = "postgresql://postgres:...@db.xxx.supabase.co:5432/postgres"
  .\supabase\apply-remote.ps1 -ProjectRef xxxxxxxxxxxxxxxxxxxx
#>
param(
  [Parameter(Mandatory = $true)][string]$ProjectRef,
  [string]$DbUrl = $env:SUPABASE_DB_URL,
  [switch]$SkipSeeds,
  [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not $DbUrl) {
  Write-Error "No database URL. Set `$env:SUPABASE_DB_URL or pass -DbUrl. Find it in Dashboard -> Project Settings -> Database -> Connection string (URI)."
}

$psql = "$env:USERPROFILE\scoop\apps\postgresql\current\bin\psql.exe"
if (-not (Test-Path $psql)) {
  $cmd = Get-Command psql -ErrorAction SilentlyContinue
  if ($cmd) { $psql = $cmd.Source } else { Write-Error "psql not found. Install with: scoop install postgresql" }
}

# ---------------------------------------------------------------------------
# Guard: confirm the target is the project we think it is.
# A ref typo would otherwise apply this schema to an unrelated database.
# ---------------------------------------------------------------------------
Write-Host "`n== Target check ==" -ForegroundColor Cyan
$projects = supabase projects list -o json 2>$null | ConvertFrom-Json
$target = $projects.projects | Where-Object { $_.ref -eq $ProjectRef }
if (-not $target) { Write-Error "Project ref '$ProjectRef' not found in your Supabase account." }

Write-Host "  name   : $($target.name)"
Write-Host "  region : $($target.region)"
Write-Host "  status : $($target.status)"

if ($target.name -notmatch 'nimit') {
  Write-Error "Refusing to continue: project '$($target.name)' does not look like a Nimit project. If this is deliberate, apply the files manually."
}
if ($target.status -ne 'ACTIVE_HEALTHY') {
  Write-Warning "Project status is $($target.status); it may still be provisioning."
}

# ---------------------------------------------------------------------------
Write-Host "`n== Linking ==" -ForegroundColor Cyan
supabase link --project-ref $ProjectRef
if ($LASTEXITCODE -ne 0) { Write-Error "supabase link failed." }

Write-Host "`n== Migrations (supabase db push) ==" -ForegroundColor Cyan
supabase db push
if ($LASTEXITCODE -ne 0) { Write-Error "supabase db push failed." }

# ---------------------------------------------------------------------------
if (-not $SkipSeeds) {
  Write-Host "`n== Seeds ==" -ForegroundColor Cyan
  # PGCLIENTENCODING is mandatory on Windows: psql defaults to WIN1252 here and
  # every one of these files is full of Thai, which fails with
  # "character with byte sequence 0x81 ... has no equivalent in encoding UTF8".
  $env:PGCLIENTENCODING = 'UTF8'

  # THIS LIST MUST MATCH .github/workflows/db-verify.yml, IN ORDER.
  # It has now drifted twice. First time: 5 of 18 files missing, notably
  # lottery_reference_v1.sql, without which api.lottery_ingest rejects every
  # payload with "ยังไม่ได้ลงทะเบียนแหล่งข้อมูล glo-api". Second time
  # (caught 2026-07-29): 17 of 35 missing — everything from dream_symbols_v5
  # onward, i.e. the entire กระเหม่น p.24, animals, p.11–17 and พรหมชาติ ๒๕๐๖
  # material. A database applied with this script and a database verified by
  # CI were different databases, again. If you add a seed, add it in BOTH
  # places, and put it in the SAME position — order is part of the contract.
  #
  # Order is load-bearing: provenance before content, and publish_v1 before the
  # interpretation sets, because those publish their own rows and need the
  # work/edition chain published first. All files carry on-conflict guards or
  # stage-and-join inserts, so re-running against a live project is safe — CI
  # proves it by applying several of these twice. publish_v1 touches only
  # work/edition/symbol — it will NOT publish draft interpretations.
  $seeds = @(
    'supabase/seed.sql',
    'supabase/seeds/sources_v1.sql',
    'supabase/seeds/sources_v2_research.sql',
    'supabase/seeds/sources_v3_legal_corrections.sql',
    'supabase/seeds/sources_v4_tipitaka.sql',
    'supabase/seeds/sources_v5_wisan_research.sql',
    'supabase/seeds/dream_symbols_v1.sql',
    'supabase/seeds/lottery_reference_v1.sql',
    'supabase/seeds/publish_v1.sql',
    'supabase/seeds/interpretations_v1.sql',
    'supabase/seeds/interpretations_v2_subinasutta.sql',
    'supabase/seeds/dream_symbols_v2_gapfill.sql',
    'supabase/seeds/interpretations_v3_plain_summaries.sql',
    'supabase/seeds/dream_symbols_v3_colors_weather.sql',
    'supabase/seeds/sources_v6_pramuan.sql',
    'supabase/seeds/dream_symbols_v4_body_omens.sql',
    'supabase/seeds/interpretations_v4_krachamen.sql',
    'supabase/seeds/dream_symbols_v5_krachamen_p24.sql',
    'supabase/seeds/interpretations_v6_krachamen_p24.sql',
    'supabase/seeds/interpretations_v7_khamthamnaifan.sql',
    'supabase/seeds/sources_v7_owned_library.sql',
    'supabase/seeds/interpretations_v5_owned_books_template.sql',
    'supabase/seeds/dream_symbols_v6_animals.sql',
    'supabase/seeds/interpretations_v8_retire_placeholders.sql',
    'supabase/seeds/dream_symbols_v7_p11_p12.sql',
    'supabase/seeds/interpretations_v9_p11_p12.sql',
    'supabase/seeds/interpretations_v10_p13.sql',
    'supabase/seeds/publish_v2_numbers.sql',
    'supabase/seeds/dream_symbols_v8_p14_p17.sql',
    'supabase/seeds/interpretations_v11_p14_p17.sql',
    'supabase/seeds/taksa_v1_phrommachat_2506.sql',
    'supabase/seeds/sources_v8_phrommachat_owned.sql',
    'supabase/seeds/zodiac_v1_phrommachat_owned.sql',
    'supabase/seeds/agewheel_v1_phrommachat_owned.sql',
    'supabase/seeds/zodiac_v2_month_groups.sql'
  )
  foreach ($s in $seeds) {
    Write-Host "  applying $s"
    & $psql $DbUrl -v ON_ERROR_STOP=1 -q -f $s
    if ($LASTEXITCODE -ne 0) { Write-Error "Seed failed: $s" }
  }
}

# ---------------------------------------------------------------------------
if (-not $SkipTests) {
  Write-Host "`n== Verification ==" -ForegroundColor Cyan
  # The suite runs in a transaction and rolls back, so it leaves no residue.
  & $psql $DbUrl -v ON_ERROR_STOP=1 -f 'supabase/tests/rights_firewall_test.sql'
  if ($LASTEXITCODE -ne 0) { Write-Error "Verification FAILED. Do not treat this database as sound." }
}

# ---------------------------------------------------------------------------
Write-Host "`n== Contents ==" -ForegroundColor Cyan
& $psql $DbUrl -t -c @"
select 'works=' || (select count(*) from content.work)
    || ' editions=' || (select count(*) from content.edition)
    || ' symbols=' || (select count(*) from content.symbol)
    || ' terms=' || (select count(*) from content.symbol_term)
    || ' interpretations=' || (select count(*) from content.interpretation);
"@

& $psql $DbUrl -t -c @"
select 'lottery: prize_tiers=' || (select count(*) from lottery.prize_tier)
    || ' (must be 9)  pool=' || (select sum(amount_thb * winner_count) from lottery.prize_tier where effective_to is null)
    || ' (must be 12018000)  draws=' || (select count(*) from lottery.draw)
    || '  results=' || (select count(*) from lottery.result);
"@

Write-Host @"

Done. Three settings must still be changed by hand in the dashboard — the
migrations cannot set them, and each silently undoes part of the design:

  1. Project Settings -> API -> Exposed schemas: set to 'api' ONLY.
     Never add 'content' or 'editorial'.
  2. Database -> Extensions: DISABLE pg_graphql.
     It is a second, introspectable enumeration path that bypasses the
     RPC-only read design entirely.
  3. Project Settings -> API -> Max rows: set to 100.
     A global backstop in case a view is ever exposed by mistake.

For ตรวจหวย, two more steps happen outside this script:

  4. GitHub -> Settings -> Secrets and variables -> Actions -> Secrets:
     add SUPABASE_SERVICE_ROLE_KEY. A SECRET, not a variable — it bypasses RLS
     entirely, unlike the anon key which ships in the JS bundle by design.
  5. GitHub -> Actions -> "Ingest lottery results" -> Run workflow
     with mode=backfill to load ~2 years of history. Takes a few minutes;
     it pauses 2s between calls to stay polite to a government API.

"@ -ForegroundColor Yellow
