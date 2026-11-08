# Local standalone Windows x64 export. No system-wide editor settings are changed.
[CmdletBinding()]
param(
    [string]$GodotExe = 'C:\Godot\Godot_v4.7.1-stable_win64_console.exe',
    [string]$TemplateDir = '',
    [string]$OutputExe = '',
    [string]$RuntimeDir = '',
    [switch]$DebugBuild
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = Split-Path -Parent $projectRoot
$workspaceRoot = Split-Path -Parent $outputsRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw 'Godot executable not found. Pass -GodotExe <path>.' }
$versionOutput = (& $GodotExe --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $versionOutput -notmatch '^(\d+\.\d+(?:\.\d+)?\.stable)') { throw "Unsupported Godot version output: $versionOutput" }
$templateVersion = $Matches[1]
$templateFilename = if ($DebugBuild) { 'windows_debug_x86_64.exe' } else { 'windows_release_x86_64.exe' }
if (-not $TemplateDir) {
    $templateCandidates = @((Join-Path $env:APPDATA "Godot\export_templates\$templateVersion"), (Join-Path $workspaceRoot "work\toolchain\templates\$templateVersion"))
    $TemplateDir = $templateCandidates | Where-Object { Test-Path -LiteralPath (Join-Path $_ $templateFilename) } | Select-Object -First 1
}
if (-not $TemplateDir -or -not (Test-Path -LiteralPath (Join-Path $TemplateDir $templateFilename))) { throw "Matching Windows export template missing ($templateVersion). Install it in Godot or pass -TemplateDir <directory containing $templateFilename>." }
if (-not $RuntimeDir) { $RuntimeDir = Join-Path $workspaceRoot 'work\windows-export' }
if (-not $OutputExe) { $OutputExe = Join-Path $outputsRoot 'UnmatchedPocket-windows.exe' }
$RuntimeDir = [System.IO.Path]::GetFullPath($RuntimeDir)
$OutputExe = [System.IO.Path]::GetFullPath($OutputExe)
$appDataDir = Join-Path $RuntimeDir 'appdata'
$isolatedTemplateDir = Join-Path $appDataDir "Godot\export_templates\$templateVersion"
New-Item -ItemType Directory -Path $isolatedTemplateDir, (Split-Path -Parent $OutputExe) -Force | Out-Null
$sourceTemplate = Join-Path $TemplateDir $templateFilename
$targetTemplate = Join-Path $isolatedTemplateDir $templateFilename
if (-not (Test-Path -LiteralPath $targetTemplate) -or (Get-Item -LiteralPath $targetTemplate).Length -ne (Get-Item -LiteralPath $sourceTemplate).Length) { Copy-Item -LiteralPath $sourceTemplate -Destination $targetTemplate -Force }
[System.IO.File]::WriteAllText((Join-Path $isolatedTemplateDir 'version.txt'), $templateVersion, [System.Text.UTF8Encoding]::new($false))
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $appDataDir
    Write-Host "Godot: $versionOutput"
    Write-Host "EXE: $OutputExe"
    & $GodotExe --headless --path $projectRoot --editor --import
    if ($LASTEXITCODE -ne 0) { throw 'Project import failed.' }
    $exportMode = if ($DebugBuild) { '--export-debug' } else { '--export-release' }
    & $GodotExe --headless --path $projectRoot $exportMode Windows $OutputExe
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputExe)) { throw 'Windows export failed.' }
    $hash = Get-FileHash -LiteralPath $OutputExe -Algorithm SHA256
    Write-Host ("Done: {0:N1} MB; SHA256 {1}" -f ((Get-Item -LiteralPath $OutputExe).Length / 1MB), $hash.Hash)
}
finally { $env:APPDATA = $previousAppData }
