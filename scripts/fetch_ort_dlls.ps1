<#
.SYNOPSIS
  Fetch the ONNX Runtime GPU DLLs that the Parakeet path needs at runtime.

.DESCRIPTION
  The `ort` crate is built with `load-dynamic`, so the build does NOT bundle
  onnxruntime.dll — it's resolved at runtime from next to handy.exe (or
  ORT_DYLIB_PATH). These DLLs are NOT our artifacts: they are Microsoft's stock,
  unmodified ONNX Runtime GPU release (they work on RTX 50-series / sm_120, which
  is why we use them instead of building ORT from source).

  This downloads Microsoft's official, version-pinned release ZIP and extracts the
  three DLLs next to handy.exe:
    - onnxruntime.dll                  (CPU + the load-dynamic GPU EPs)
    - onnxruntime_providers_cuda.dll   (CUDA EP — ~324 MB)
    - onnxruntime_providers_shared.dll

  Idempotent: skips the download if the DLLs are already present.

.EXAMPLE
  pwsh scripts/fetch_ort_dlls.ps1                       # default cargo target
  pwsh scripts/fetch_ort_dlls.ps1 -OutDir C:\hb\release # custom CARGO_TARGET_DIR
#>
param(
  [string]$Version = "1.26.0",
  [string]$OutDir  = "$PSScriptRoot\..\src-tauri\target\release"
)
$ErrorActionPreference = "Stop"
$dlls = @("onnxruntime.dll", "onnxruntime_providers_cuda.dll", "onnxruntime_providers_shared.dll")

if (-not (($dlls | ForEach-Object { Test-Path (Join-Path $OutDir $_) }) -contains $false)) {
  Write-Host "ORT $Version GPU DLLs already present in $OutDir"
  return
}

$zipUrl = "https://github.com/microsoft/onnxruntime/releases/download/v$Version/onnxruntime-win-x64-gpu-$Version.zip"
$zip = Join-Path $env:TEMP "onnxruntime-win-x64-gpu-$Version.zip"
if (-not (Test-Path $zip)) {
  Write-Host "Downloading $zipUrl ..."
  Invoke-WebRequest -Uri $zipUrl -OutFile $zip
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
try {
  foreach ($name in $dlls) {
    $entry = $archive.Entries | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (-not $entry) { throw "Entry '$name' not found in $zipUrl" }
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $OutDir $name), $true)
    Write-Host "  extracted $name"
  }
} finally {
  $archive.Dispose()
}
Write-Host "ORT $Version GPU DLLs ready in $OutDir"
