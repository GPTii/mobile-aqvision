<#
  setup.ps1 - Cai dat toan bo moi truong de chay / build AQPConnect tren Windows.

  Cach chay: double-click setup.bat
        hoac: powershell -ExecutionPolicy Bypass -File setup.ps1

  Script se tu cai (neu may chua co):
    - Git, bat Windows Developer Mode
    - JDK 17 (Eclipse Temurin)
    - Flutter (dung ban ghim trong .fvmrc)
    - Android SDK: platform-tools, platform, build-tools, NDK, USB driver + chap nhan license
  roi chay `flutter pub get` va build thu 1 ban debug de tai san Gradle.
  Chay lai nhieu lan van an toan: buoc nao da xong se duoc bo qua.

  Tham so:
    -InstallDir <path>  Thu muc cai JDK / Flutter / Android SDK (mac dinh C:\dev, khong duoc co dau cach)
    -SkipWarmup         Bo qua buoc build thu (nhanh hon, lan build dau se tai Gradle sau)
#>
param(
    [string]$InstallDir = "$env:SystemDrive\dev",
    [switch]$SkipWarmup
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ProjectRoot = $PSScriptRoot
$FlutterVersion = (Get-Content "$ProjectRoot\.fvmrc" -Raw | ConvertFrom-Json).flutter
$gradleFile = Get-Content "$ProjectRoot\android\app\build.gradle.kts" -Raw
$CompileSdk = [regex]::Match($gradleFile, 'compileSdk\s*=\s*(\d+)').Groups[1].Value
$NdkVersion = [regex]::Match($gradleFile, 'ndkVersion\s*=\s*"([^"]+)"').Groups[1].Value
$BuildTools = '35.0.0'

$JdkUrl = 'https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse'
$FlutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$FlutterVersion-stable.zip"
$CmdlineToolsUrl = 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip'

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg) { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "    [!] $msg" -ForegroundColor Yellow }

function Invoke-Native([string]$Exe, [string[]]$Arguments) {
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Lenh that bai (exit $LASTEXITCODE): $Exe $($Arguments -join ' ')" }
}

# Chay lenh native va lay ca stdout + stderr thanh chuoi, khong de PowerShell 5.1 nem loi vi stderr.
function Get-NativeOutput([string]$Exe, [string[]]$Arguments) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { return (& $Exe @Arguments 2>&1 | ForEach-Object { "$_" }) -join "`n" }
    catch { return '' }
    finally { $ErrorActionPreference = $prev }
}

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

# Dua thu muc len dau PATH cua user (luu vinh vien) va cua phien hien tai.
function Add-UserPath([string]$Dir) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($userPath -split ';' | Where-Object { $_ -and ($_.TrimEnd('\') -ne $Dir.TrimEnd('\')) })
    [Environment]::SetEnvironmentVariable('Path', ((@($Dir) + $parts) -join ';'), 'User')
    $env:Path = "$Dir;$env:Path"
}

function Set-UserEnv([string]$Name, [string]$Value) {
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    Set-Item "env:$Name" $Value
}

function Get-File([string]$Url, [string]$OutFile) {
    Write-Host "    Dang tai: $Url"
    Invoke-Native 'curl.exe' @('-L', '--fail', '--retry', '3', '-o', $OutFile, $Url)
}

# Giai nen zip vao thu muc tam roi chuyen thu muc con duy nhat ben trong sang $Dest.
function Install-Zip([string]$Url, [string]$Dest) {
    $zip = "$InstallDir\.download.zip"
    $tmp = "$InstallDir\.extract"
    Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Get-File $Url $zip
    New-Item -ItemType Directory -Force $tmp | Out-Null
    Write-Host '    Dang giai nen...'
    Invoke-Native 'tar.exe' @('-xf', $zip, '-C', $tmp)
    $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
    New-Item -ItemType Directory -Force (Split-Path $Dest) | Out-Null
    Move-Item $inner.FullName $Dest
    Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

function Get-JavaMajor([string]$JavaHome) {
    if (-not $JavaHome) { return 0 }
    $java = Join-Path $JavaHome 'bin\java.exe'
    if (-not (Test-Path $java)) { return 0 }
    $m = [regex]::Match((Get-NativeOutput $java @('-version')), 'version "(\d+)')
    if ($m.Success) { return [int]$m.Groups[1].Value } else { return 0 }
}

function Get-FlutterVersion([string]$FlutterBat) {
    $m = [regex]::Match((Get-NativeOutput $FlutterBat @('--version', '--machine')), '"frameworkVersion"\s*:\s*"([^"]+)"')
    if ($m.Success) { return $m.Groups[1].Value } else { return $null }
}

if ($InstallDir -match '\s') { throw "InstallDir khong duoc chua dau cach: $InstallDir" }
New-Item -ItemType Directory -Force $InstallDir | Out-Null

Write-Host "AQPConnect setup  |  Flutter $FlutterVersion  |  compileSdk $CompileSdk  |  NDK $NdkVersion  |  cai vao $InstallDir" -ForegroundColor White

# ---------------------------------------------------------------- Git
Step 'Git'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Invoke-Native 'winget' @('install', '--id', 'Git.Git', '-e', '--silent', '--accept-package-agreements', '--accept-source-agreements')
        Update-SessionPath
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Chua cai duoc Git. Hay cai tu https://git-scm.com/download/win roi chay lai setup.'
    }
}
Ok (Get-NativeOutput 'git' @('--version'))

# ---------------------------------------------------------------- Developer Mode
# Flutter tren Windows can symlink cho plugin, neu khong `flutter pub get` se bao loi.
Step 'Windows Developer Mode'
$devKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
function Test-DevMode { (Get-ItemProperty $devKey -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense -eq 1 }
if (-not (Test-DevMode)) {
    Warn 'Dang bat Developer Mode. Windows se hien hop thoai quyen Admin (UAC), hay chon Yes.'
    try {
        Start-Process reg.exe -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList 'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v AllowDevelopmentWithoutDevLicense /d 1'
    } catch { }
}
if (Test-DevMode) { Ok 'Developer Mode da bat' }
else {
    Start-Process 'ms-settings:developers'
    throw 'Chua bat duoc Developer Mode. Settings da duoc mo: hay bat "Developer Mode" roi chay lai setup.'
}

# ---------------------------------------------------------------- JDK 17
Step 'JDK 17'
$JdkHome = $null
foreach ($candidate in @($env:JAVA_HOME, "$InstallDir\jdk-17")) {
    $major = Get-JavaMajor $candidate
    if ($major -ge 17 -and $major -le 21) { $JdkHome = $candidate; break }
}
if ($JdkHome) { Ok "Da co JDK: $JdkHome" }
else {
    $JdkHome = "$InstallDir\jdk-17"
    Install-Zip $JdkUrl $JdkHome
    Ok "Da cai JDK 17: $JdkHome"
}
Set-UserEnv 'JAVA_HOME' $JdkHome
Add-UserPath "$JdkHome\bin"

# ---------------------------------------------------------------- Flutter
Step "Flutter $FlutterVersion"
$FlutterRoot = "$InstallDir\flutter-$FlutterVersion"
$FlutterBat = "$FlutterRoot\bin\flutter.bat"
$existing = Get-Command flutter.bat -ErrorAction SilentlyContinue
if ($existing -and (Get-FlutterVersion $existing.Source) -eq $FlutterVersion) {
    $FlutterBat = $existing.Source
    $FlutterRoot = Split-Path (Split-Path $FlutterBat)
    Ok "Da co Flutter $FlutterVersion`: $FlutterRoot"
}
else {
    if (-not (Test-Path $FlutterBat)) {
        Write-Host '    (file ~1 GB, co the mat vai phut)'
        Install-Zip $FlutterUrl $FlutterRoot
    }
    Add-UserPath "$FlutterRoot\bin"
    Ok "Flutter $FlutterVersion`: $FlutterRoot"
    if ($existing) {
        Warn "May dang co mot ban Flutter khac: $($existing.Source)"
        Warn "Da dua Flutter $FlutterVersion len dau PATH cua user. Neu ban kia nam trong PATH he thong (System) thi hay go no ra."
    }
}
Invoke-Native $FlutterBat @('config', '--no-analytics')

# ---------------------------------------------------------------- Android SDK
Step 'Android SDK'
$SdkRoot = $null
foreach ($candidate in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, "$env:LOCALAPPDATA\Android\Sdk")) {
    if ($candidate -and (Test-Path $candidate)) { $SdkRoot = $candidate; break }
}
if (-not $SdkRoot) { $SdkRoot = "$InstallDir\android-sdk" }
New-Item -ItemType Directory -Force $SdkRoot | Out-Null
Ok "Thu muc SDK: $SdkRoot"

$SdkManager = "$SdkRoot\cmdline-tools\latest\bin\sdkmanager.bat"
if (-not (Test-Path $SdkManager)) {
    $found = Get-ChildItem "$SdkRoot\cmdline-tools\*\bin\sdkmanager.bat" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $SdkManager = $found.FullName }
    else {
        Install-Zip $CmdlineToolsUrl "$SdkRoot\cmdline-tools\latest"
        Ok 'Da cai Android command-line tools'
    }
}

Write-Host '    Chap nhan license Android SDK...'
$yes = (1..50 | ForEach-Object { 'y' }) -join "`n"
$yes | & $SdkManager --licenses "--sdk_root=$SdkRoot" | Out-Null

$packages = @('platform-tools', "platforms;android-$CompileSdk", "build-tools;$BuildTools", "ndk;$NdkVersion", 'extras;google;usb_driver')
Write-Host "    Cai: $($packages -join ', ')  (NDK ~1 GB)"
Invoke-Native $SdkManager (@("--sdk_root=$SdkRoot") + $packages)

Set-UserEnv 'ANDROID_HOME' $SdkRoot
Set-UserEnv 'ANDROID_SDK_ROOT' $SdkRoot
Add-UserPath "$SdkRoot\platform-tools"
Ok 'Android SDK san sang'

# ---------------------------------------------------------------- Project
Step 'Cau hinh Flutter + tai thu vien cua project'
Invoke-Native $FlutterBat @('config', '--android-sdk', $SdkRoot)
Invoke-Native $FlutterBat @('config', '--jdk-dir', $JdkHome)
Push-Location $ProjectRoot
try {
    Invoke-Native $FlutterBat @('pub', 'get')

    if (-not $SkipWarmup) {
        Step 'Build thu ban debug (tai Gradle + thu vien Android, lan dau mat 5-15 phut)'
        Invoke-Native $FlutterBat @('build', 'apk', '--debug')
        Ok 'Build thu thanh cong'
    }
}
finally { Pop-Location }

# ---------------------------------------------------------------- Doctor
Step 'flutter doctor'
& $FlutterBat doctor

Write-Host ''
Write-Host '======================================================================' -ForegroundColor Green
Write-Host ' CAI DAT XONG!' -ForegroundColor Green
Write-Host ' Mo mot cua so terminal MOI (de nhan PATH moi), cd vao project, roi:' -ForegroundColor Green
Write-Host '     flutter devices     # kiem tra dien thoai da ket noi' -ForegroundColor Green
Write-Host '     flutter run         # chay app len dien thoai' -ForegroundColor Green
Write-Host '======================================================================' -ForegroundColor Green
