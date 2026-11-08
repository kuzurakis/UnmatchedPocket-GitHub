# Local debug APK export. This script does not alter system-wide Godot settings.
[CmdletBinding()]
param(
    [string]$GodotExe = 'C:\Godot\Godot_v4.7.1-stable_win64_console.exe',
    [string]$JavaHome = 'C:\Program Files\Java\jdk-17',
    [string]$AndroidSdk = '',
    [string]$TemplateDir = '',
    [string]$OutputApk = '',
    [string]$RuntimeDir = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = Split-Path -Parent $projectRoot
$workspaceRoot = Split-Path -Parent $outputsRoot
$localToolchain = Join-Path $workspaceRoot 'work\toolchain'

if (-not $AndroidSdk) {
    $sdkCandidates = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android\Sdk'), (Join-Path $localToolchain 'android-sdk'))
    $AndroidSdk = $sdkCandidates | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'platform-tools\adb.exe')) -and (Test-Path -LiteralPath (Join-Path $_ 'build-tools')) } | Select-Object -First 1
}
if (-not (Test-Path -LiteralPath $GodotExe)) { throw 'Godot executable not found. Pass -GodotExe <path>.' }
if (-not (Test-Path -LiteralPath (Join-Path $JavaHome 'bin\java.exe'))) { throw 'JDK not found. Pass -JavaHome <JDK 17 directory>.' }
if (-not $AndroidSdk) { throw 'Android SDK not found. Pass -AndroidSdk <directory containing build-tools and platform-tools>.' }
$versionOutput = (& $GodotExe --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $versionOutput -notmatch '^(\d+\.\d+(?:\.\d+)?\.stable)') { throw "Unsupported Godot version output: $versionOutput" }
$templateVersion = $Matches[1]
$editorMajorMinor = ($templateVersion -split '\.')[0..1] -join '.'
if (-not $TemplateDir) {
    $templateCandidates = @((Join-Path $env:APPDATA "Godot\export_templates\$templateVersion"), (Join-Path $localToolchain "templates\$templateVersion"))
    $TemplateDir = $templateCandidates | Where-Object { (Test-Path -LiteralPath (Join-Path $_ 'android_debug.apk')) -and ((-not (Test-Path -LiteralPath (Join-Path $_ 'version.txt'))) -or (Get-Content -LiteralPath (Join-Path $_ 'version.txt') -Raw).Trim() -eq $templateVersion) } | Select-Object -First 1
}
if (-not $TemplateDir -or -not (Test-Path -LiteralPath (Join-Path $TemplateDir 'android_debug.apk'))) { throw "Matching Android export template missing ($templateVersion). Install it in Godot or pass -TemplateDir <directory containing android_debug.apk>." }
if (-not $RuntimeDir) { $RuntimeDir = Join-Path $workspaceRoot 'work\android-export' }
if (-not $OutputApk) { $OutputApk = Join-Path $outputsRoot 'UnmatchedPocket-android.apk' }
$RuntimeDir = [System.IO.Path]::GetFullPath($RuntimeDir)
$OutputApk = [System.IO.Path]::GetFullPath($OutputApk)
$appDataDir = Join-Path $RuntimeDir 'appdata'
$settingsDir = Join-Path $appDataDir 'Godot'
$isolatedTemplateDir = Join-Path $settingsDir "export_templates\$templateVersion"
New-Item -ItemType Directory -Path $isolatedTemplateDir, (Split-Path -Parent $OutputApk) -Force | Out-Null
$sourceTemplate = Join-Path $TemplateDir 'android_debug.apk'
$targetTemplate = Join-Path $isolatedTemplateDir 'android_debug.apk'
if (-not (Test-Path -LiteralPath $targetTemplate) -or (Get-Item -LiteralPath $targetTemplate).Length -ne (Get-Item -LiteralPath $sourceTemplate).Length) { Copy-Item -LiteralPath $sourceTemplate -Destination $targetTemplate -Force }
[System.IO.File]::WriteAllText((Join-Path $isolatedTemplateDir 'version.txt'), $templateVersion, [System.Text.UTF8Encoding]::new($false))
$slashJava = $JavaHome.Replace('\', '/')
$slashSdk = $AndroidSdk.Replace('\', '/')
$settings = @"
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$slashJava"
export/android/android_sdk_path = "$slashSdk"
"@
[System.IO.File]::WriteAllText((Join-Path $settingsDir "editor_settings-$editorMajorMinor.tres"), $settings, [System.Text.UTF8Encoding]::new($false))
$keystorePath = Join-Path $RuntimeDir 'debug.keystore'
if (-not (Test-Path -LiteralPath $keystorePath)) {
    & (Join-Path $JavaHome 'bin\keytool.exe') -genkeypair -keystore $keystorePath -storepass android -keypass android -alias androiddebugkey -dname 'CN=Android Debug,O=Android,C=US' -validity 10000 -keyalg RSA -keysize 2048 -noprompt
    if ($LASTEXITCODE -ne 0) { throw 'Debug key generation failed.' }
}
$envNames = @('APPDATA','JAVA_HOME','GODOT_ANDROID_KEYSTORE_DEBUG_PATH','GODOT_ANDROID_KEYSTORE_DEBUG_USER','GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD')
$previousEnv = @{}
foreach ($name in $envNames) { $previousEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    $env:APPDATA = $appDataDir
    $env:JAVA_HOME = $JavaHome
    $env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH = $keystorePath
    $env:GODOT_ANDROID_KEYSTORE_DEBUG_USER = 'androiddebugkey'
    $env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = 'android'
    Write-Host "Godot: $versionOutput"
    Write-Host "APK: $OutputApk"
    & $GodotExe --headless --path $projectRoot --editor --import
    if ($LASTEXITCODE -ne 0) { throw 'Project import failed.' }
    & $GodotExe --headless --path $projectRoot --export-debug Android $OutputApk
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputApk)) { throw 'Android export failed.' }
    $buildTools = Get-ChildItem -LiteralPath (Join-Path $AndroidSdk 'build-tools') -Directory | Sort-Object Name -Descending | Select-Object -First 1
    & (Join-Path $buildTools.FullName 'apksigner.bat') verify --verbose $OutputApk
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    & (Join-Path $buildTools.FullName 'zipalign.exe') -c -P 16 4 $OutputApk
    if ($LASTEXITCODE -ne 0) { throw 'APK alignment verification failed.' }
    $hash = Get-FileHash -LiteralPath $OutputApk -Algorithm SHA256
    Write-Host ("Done: {0:N1} MB; SHA256 {1}" -f ((Get-Item -LiteralPath $OutputApk).Length / 1MB), $hash.Hash)
}
finally {
    foreach ($name in $envNames) { [Environment]::SetEnvironmentVariable($name, $previousEnv[$name], 'Process') }
}
