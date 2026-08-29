# Zen PDF Viewer launcher — Windows (PowerShell)
# Usage:  .\launch.ps1 C:\path\to\file.pdf
#         .\launch.ps1 https://example.com/doc.pdf
#
# Requirements: Python 3 on PATH, a modern browser.

param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- locate viewer -----------------------------------------------------------

$viewerDir  = Join-Path $env:APPDATA "zen-pdf-viewer"
$viewerHtml = Join-Path $viewerDir "viewer.html"
$serverPy   = Join-Path $viewerDir "zen-server.py"

if (-not (Test-Path $viewerHtml)) {
    Write-Error @"
viewer.html not found at $viewerHtml
Run the install step from the README and try again:
  New-Item -ItemType Directory -Force "$viewerDir"
  Copy-Item viewer.html "$viewerDir"
"@
    exit 1
}

if (-not (Test-Path $serverPy)) {
    Write-Error @"
zen-server.py not found at $serverPy
Run the install step from the README and try again:
  Copy-Item zen-server.py "$viewerDir"
"@
    exit 1
}

# --- create a temp dir -------------------------------------------------------

$tmpDir  = Join-Path $env:TEMP ("zen-pdf-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmpDir | Out-Null
Copy-Item $viewerHtml $tmpDir
Copy-Item $serverPy $tmpDir

# --- resolve PDF -------------------------------------------------------------

$tmpPdf = Join-Path $tmpDir "doc.pdf"
if ($Path -match '^https?://') {
    Write-Host "Downloading $Path ..."
    Invoke-WebRequest -Uri $Path -OutFile $tmpPdf -UseBasicParsing
} else {
    $resolved = (Resolve-Path $Path).Path
    Copy-Item $resolved $tmpPdf
}

# --- start the server (binds port 0 directly; no TOCTOU race) ----------------

$portFile = Join-Path $tmpDir "port"
$serverProc = Start-Process python -ArgumentList @(
    (Join-Path $tmpDir "zen-server.py"),
    $tmpDir,
    "--port-file", $portFile
) -WindowStyle Hidden -PassThru

$port = $null
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 100
    if (Test-Path $portFile) {
        $port = Get-Content $portFile -Raw
        break
    }
}

if (-not $port) {
    Write-Error "Local viewer server did not report a port in time."
    exit 1
}

# Wait up to 3 s for the server to respond
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 100
    try {
        $r = Invoke-WebRequest "http://127.0.0.1:$port/viewer.html" `
            -UseBasicParsing -ErrorAction Stop
        if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
}

if (-not $ready) {
    Write-Error "Local viewer server did not start in time."
    exit 1
}

# --- open browser ------------------------------------------------------------

$encFile = [Uri]::EscapeDataString("doc.pdf")
$encFg   = [Uri]::EscapeDataString("#e6e6e6")
$url     = "http://127.0.0.1:$port/viewer.html?file=$encFile&zen=1&fg=$encFg"

Start-Process $url
Write-Host "Zen PDF viewer: $url  (server pid $($serverProc.Id), tmpdir $tmpDir)"
