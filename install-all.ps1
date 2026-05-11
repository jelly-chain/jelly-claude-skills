# ─────────────────────────────────────────────────────────────────────────────
# install-all.ps1  —  Install all Jelly-Claude skills (Windows)
# ─────────────────────────────────────────────────────────────────────────────

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsDir = Join-Path $ScriptDir "skills"

Write-Host ""
Write-Host "  Installing all Jelly-Claude skills..." -ForegroundColor Cyan
Write-Host ""

$installed = 0
$skipped   = 0

Get-ChildItem -Path $SkillsDir -Directory | ForEach-Object {
    $skillName = $_.Name
    $installer = Join-Path $_.FullName "install.ps1"
    if (Test-Path $installer) {
        Write-Host "  -> $skillName" -ForegroundColor Cyan
        & $installer
        $installed++
    } else {
        Write-Host "  !  $skillName - no install.ps1, skipping" -ForegroundColor Yellow
        $skipped++
    }
}

Write-Host ""
Write-Host "  Done! Installed: $installed   Skipped: $skipped" -ForegroundColor Green
Write-Host ""
