# Build Saara for Windows and install it over the local copy.
#
#   powershell -ExecutionPolicy Bypass -File tool\deploy_desktop.ps1
#   ... -Dest "E:\Apps\Saara"     # install somewhere else
#   ... -NoLaunch                 # build + install, don't start it
#
# Why a script: the Release folder lives under build\ and is wiped by any
# rebuild or `flutter clean`, so the app must be copied out to a stable folder.
# Files are also locked while Saara is running, hence the stop-first step.

param(
  [string]$Dest = "D:\Saara",
  [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

# SQLCipher's CMake needs OpenSSL (see DESKTOP_BUILD.md).
if (-not $env:OPENSSL_ROOT_DIR) {
  $env:OPENSSL_ROOT_DIR = "C:/Program Files/OpenSSL-Win64"
}

$version = (Select-String -Path "pubspec.yaml" -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
Write-Host "Building Saara $version for Windows..." -ForegroundColor Cyan

flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed" }

$src = Join-Path $repo "build\windows\x64\runner\Release"
if (-not (Test-Path (Join-Path $src "saara.exe"))) { throw "No saara.exe at $src" }

# Saara holds its DLLs open; close it before overwriting.
$running = Get-Process -Name "saara" -ErrorAction SilentlyContinue
if ($running) {
  Write-Host "Closing running Saara..." -ForegroundColor Yellow
  $running | Stop-Process -Force
  Start-Sleep -Seconds 2
}

if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Force $Dest | Out-Null }
Copy-Item -Recurse -Force (Join-Path $src "*") $Dest

Write-Host "Installed Saara $version to $Dest" -ForegroundColor Green
Write-Host "Your data is untouched (%APPDATA%\com.realmaya\saara)." -ForegroundColor DarkGray

if (-not $NoLaunch) { Start-Process (Join-Path $Dest "saara.exe") }
