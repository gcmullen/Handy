<#
.SYNOPSIS
  Fetch the ONNX Runtime GPU DLLs that the Parakeet path needs at runtime.

.DESCRIPTION
  The `ort` crate is built with `load-dynamic`, so the build does NOT bundle
  onnxruntime.dll — it's resolved at runtime from the bundled resources (or
  ORT_DYLIB_PATH). These DLLs are NOT our artifacts: they are Microsoft's stock,
  unmodified ONNX Runtime GPU release (they work on RTX 50-series / sm_120, which
  is why we use them instead of building ORT from source).

  This downloads Microsoft's official, version-pinned release ZIP and extracts the
  three DLLs:
    - onnxruntime.dll                  (CPU + the load-dynamic GPU EPs)
    - onnxruntime_providers_cuda.dll   (CUDA EP — ~285 MB)
    - onnxruntime_providers_shared.dll

  Content-verified, not just presence: the script (re)fetches unless every DLL is
  present AND its SHA-256 matches the pinned value below. This is deliberate — a
  presence-only check previously let stale ORT 1.22 DLLs (left over from an earlier
  resources folder) survive and get bundled, which hung Parakeet model loads with
  no error. Hash pinning guarantees the *correct* build ends up in the bundle.

  By default the DLLs land in `src-tauri/resources/onnxruntime/`, which Tauri
  packs into the bundle (`bundle.resources`). At runtime `setup_ort_dylib` in
  lib.rs points `ORT_DYLIB_PATH` at the bundled copy. These DLLs are gitignored
  (they are large Microsoft binaries fetched on demand, not committed sources).

.EXAMPLE
  pwsh scripts/fetch_ort_dlls.ps1                        # -> src-tauri/resources/onnxruntime
  pwsh scripts/fetch_ort_dlls.ps1 -OutDir C:\hb\release  # next to a dev exe (load-dynamic fallback)
  pwsh scripts/fetch_ort_dlls.ps1 -Force                 # re-extract even if already verified
#>
param(
  [string]$Version = "1.26.0",
  [string]$OutDir  = "$PSScriptRoot\..\src-tauri\resources\onnxruntime",
  [switch]$Force
)
$ErrorActionPreference = "Stop"

# SHA-256 of the three DLLs as shipped in the official
# onnxruntime-win-x64-gpu-1.26.0.zip (FileVersion 1.26.20260508.3.8c546c3).
# Update these together with $Version / $ZipSha256 when bumping ORT.
$PinnedVersion  = "1.26.0"
$ExpectedHashes = @{
  "onnxruntime.dll"                  = "214D1E074B59066264F598760CE63BAB24A20769D9AEB445B6DCAFDF24845AD1"
  "onnxruntime_providers_cuda.dll"   = "06777E469EF5FDB414FC18B8273A09241A9D8A2EDAB6BCA0600B9F2087236664"
  "onnxruntime_providers_shared.dll" = "F2760E9F6E82C8E12FB7D8ECCE0290731445E816CDCB6534FF75F3BD72CB4BDD"
}
$ZipSha256 = "1133B1BCB0FB6F82B1C5B470B7CC15F9080A58B27DBC7B579A1FD63125EC2A15"

$dlls = @("onnxruntime.dll", "onnxruntime_providers_cuda.dll", "onnxruntime_providers_shared.dll")

# Hashes are only valid for the pinned version. For any other -Version, fall back
# to a presence check and warn (we can't vouch for the bytes).
$verifyHashes = ($Version -eq $PinnedVersion)
if (-not $verifyHashes) {
  Write-Warning "Version $Version != pinned $PinnedVersion; content hashes are NOT verified for this version."
}

function Test-DllOk([string]$path, [string]$name) {
  if (-not (Test-Path $path)) { return $false }
  if (-not $verifyHashes)     { return $true }   # presence-only for non-pinned versions
  return ((Get-FileHash $path -Algorithm SHA256).Hash -eq $ExpectedHashes[$name])
}

# Skip only if every DLL is present AND matches its pinned hash.
if (-not $Force) {
  $allOk = $true
  foreach ($name in $dlls) {
    if (-not (Test-DllOk (Join-Path $OutDir $name) $name)) { $allOk = $false; break }
  }
  if ($allOk) {
    Write-Host "ORT $Version GPU DLLs already present and verified in $OutDir"
    return
  }
  Write-Host "ORT GPU DLLs missing or wrong version in $OutDir -- (re)fetching $Version"
}

$zipUrl = "https://github.com/microsoft/onnxruntime/releases/download/v$Version/onnxruntime-win-x64-gpu-$Version.zip"
$zip = Join-Path $env:TEMP "onnxruntime-win-x64-gpu-$Version.zip"

# Reuse a cached zip only if it matches the pinned hash; otherwise (re)download.
$needDownload = $true
if (Test-Path $zip) {
  if (-not $verifyHashes) {
    $needDownload = $false
  } elseif ((Get-FileHash $zip -Algorithm SHA256).Hash -eq $ZipSha256) {
    $needDownload = $false
    Write-Host "Using cached verified zip $zip"
  }
}
if ($needDownload) {
  Write-Host "Downloading $zipUrl ..."
  Invoke-WebRequest -Uri $zipUrl -OutFile $zip
  if ($verifyHashes) {
    $zh = (Get-FileHash $zip -Algorithm SHA256).Hash
    if ($zh -ne $ZipSha256) { throw "Downloaded zip SHA-256 $zh does not match pinned $ZipSha256" }
  }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
try {
  foreach ($name in $dlls) {
    $entry = $archive.Entries | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (-not $entry) { throw "Entry '$name' not found in $zipUrl" }
    $dst = Join-Path $OutDir $name
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dst, $true)
    if ($verifyHashes) {
      $h = (Get-FileHash $dst -Algorithm SHA256).Hash
      if ($h -ne $ExpectedHashes[$name]) {
        throw "Extracted $name SHA-256 $h does not match pinned $($ExpectedHashes[$name])"
      }
      Write-Host "  extracted + verified $name"
    } else {
      Write-Host "  extracted $name"
    }
  }
} finally {
  $archive.Dispose()
}
Write-Host "ORT $Version GPU DLLs ready in $OutDir"
