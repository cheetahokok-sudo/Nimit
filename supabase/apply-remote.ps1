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
  $env:PGCLIENTENCODING = 'UTF8'
  $seeds = @(
    'supabase/seed.sql',
    'supabase/seeds/sources_v1.sql',
    'supabase/seeds/sources_v2_research.sql',
    'supabase/seeds/sources_v3_legal_corrections.sql',
    'supabase/seeds/dream_symbols_v1.sql'
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

"@ -ForegroundColor Yellow
