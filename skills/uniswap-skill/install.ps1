# Install uniswap-skill (Windows PowerShell)
$SkillName = "uniswap-skill"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dest = Join-Path $env:USERPROFILE ".claude\skills\uniswap-skill"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item "$ScriptDir\SKILL.md" "$Dest\SKILL.md" -Force
if (Test-Path "$ScriptDir\.keys.example") {
  Copy-Item "$ScriptDir\.keys.example" "$Dest\.keys.example" -Force
}
$ClaudeMd = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"
New-Item -ItemType File -Force -Path $ClaudeMd | Out-Null
$content = Get-Content $ClaudeMd -Raw -ErrorAction SilentlyContinue
if (-not ($content -match "skills/uniswap-skill")) {
  Add-Content $ClaudeMd "`n## Skill: uniswap-skill`nSee: ~/.claude/skills/uniswap-skill/SKILL.md"
}
if ($args[0] -ne "--quiet") { Write-Host "  Installed: uniswap-skill" }
