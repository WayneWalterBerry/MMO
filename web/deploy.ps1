<#
.SYNOPSIS
    Deploys web/dist/ to the GitHub Pages repository for live play.

.DESCRIPTION
    1. Runs build-engine.ps1 and build-meta.ps1
    2. Copies static assets (index.html, bootstrapper.js, game-adapter.lua)
    3. Copies web/dist/** to the GitHub Pages repo at /play/
    4. Git add, commit, push

.EXAMPLE
    powershell web/deploy.ps1
#>
param(
    [string]$PagesRepo = "C:\Users\wayneb\source\repos\WayneWalterBerry.github.io",
    [string]$CommitMessage = "Deploy three-layer web architecture"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$DistDir   = Join-Path $ScriptDir "dist"
$PlayDir   = Join-Path $PagesRepo "play"

Write-Host "=== deploy.ps1 ==="

# Step 1: Build
Write-Host "Building engine bundle..."
& powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "build-engine.ps1")

Write-Host ""
Write-Host "Building meta files..."
& powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "build-meta.ps1")

# Step 2: Copy static assets to dist
# Remove before copy — Copy-Item -Force silently fails to overwrite on Windows (#25)
Write-Host ""
Write-Host "Copying static assets to dist/..."
foreach ($file in @("index.html", "bootstrapper.js", "game-adapter.lua")) {
    $dest = Join-Path $DistDir $file
    if (Test-Path $dest) { Remove-Item $dest -Force }
    Copy-Item (Join-Path $ScriptDir $file) $DistDir -Force
}

# Copy SLM data if it exists
$slmFile = Join-Path $RepoRoot "src\assets\parser\embedding-index.json"
if (Test-Path $slmFile) {
    # Don't copy the raw 15MB file - it's lazy-loaded and handled separately
    Write-Host "  (SLM data not copied - lazy-loaded separately)"
}

# Step 3: Copy dist to GitHub Pages /play/
Write-Host ""
Write-Host "Deploying to $PlayDir..."

if (-not (Test-Path $PagesRepo)) {
    Write-Error "GitHub Pages repo not found at $PagesRepo"
    exit 1
}

# Clean old /play/ content
if (Test-Path $PlayDir) {
    Remove-Item -Recurse -Force $PlayDir
}

# Copy entire dist to /play/
Copy-Item -Recurse $DistDir $PlayDir

$fileCount = (Get-ChildItem -Recurse -File $PlayDir).Count
Write-Host "  Copied $fileCount files to $PlayDir"

# Step 4: Git add, commit, push
Write-Host ""
Write-Host "Committing to GitHub Pages repo..."
Push-Location $PagesRepo
try {
    git add play/
    git commit -m "$CommitMessage`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
    git push
    Write-Host "Deployed successfully!"
} finally {
    Pop-Location
}

Write-Host "Done. Site: https://waynewalterberry.github.io/play/"
