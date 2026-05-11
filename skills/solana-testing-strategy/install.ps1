$SkillName = "solana-testing-strategy"
$Upstream  = "https://github.com/solana-foundation/solana-dev-skill"
$SrcDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dest      = Join-Path $env:USERPROFILE ".claude/skills/$SkillName"

Write-Host "  Installing $SkillName from upstream..."

$npxAvailable = Get-Command npx -ErrorAction SilentlyContinue
if ($npxAvailable) {
    $result = npx skills add $Upstream 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Installed via npx skills add" -ForegroundColor Green
    } else {
        Write-Host "  npx skills add failed - using local pointer" -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $Dest | Out-Null
        Copy-Item (Join-Path $SrcDir "SKILL.md") $Dest -Force
        $keysEx = Join-Path $SrcDir ".keys.example"
        if (Test-Path $keysEx) { Copy-Item $keysEx $Dest -Force }
    }
} else {
    Write-Host "  npx not found - using local pointer" -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    Copy-Item (Join-Path $SrcDir "SKILL.md") $Dest -Force
}

$ClaudeMd = Join-Path $env:USERPROFILE ".claude/CLAUDE.md"
if (-not (Test-Path $ClaudeMd)) { New-Item -ItemType File -Force -Path $ClaudeMd | Out-Null }
$c = Get-Content $ClaudeMd -Raw -ErrorAction SilentlyContinue
if (-not ($c -like "*skills/$SkillName*")) {
    Add-Content -Path $ClaudeMd -Value ""
    Add-Content -Path $ClaudeMd -Value "## Skill: $SkillName"
    Add-Content -Path $ClaudeMd -Value "See: ~/.claude/skills/$SkillName/SKILL.md"
}
Write-Host "  Installed: $SkillName" -ForegroundColor Green
