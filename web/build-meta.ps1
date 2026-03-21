<#
.SYNOPSIS
    Copies individual meta .lua files into the web/dist/meta/ directory tree
    for JIT loading.

.DESCRIPTION
    - Objects: renamed by their GUID field -> meta/objects/{guid}.lua
    - Rooms (world/): copied as-is -> meta/rooms/{filename}
    - Levels: copied as-is -> meta/levels/{filename}
    - Templates: copied as-is -> meta/templates/{filename}

.EXAMPLE
    powershell web/build-meta.ps1
#>
param(
    [string]$OutDir
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir

if (-not $OutDir) { $OutDir = Join-Path $ScriptDir "dist" }

$MetaRoot = Join-Path $RepoRoot "src\meta"
$MetaOut  = Join-Path $OutDir "meta"

Write-Host "=== build-meta.ps1 ==="
Write-Host "Copying meta files to $MetaOut..."

# Clean stale output
if (Test-Path $MetaOut) {
    Remove-Item -Recurse -Force $MetaOut
}

# Create output directories
$dirs = @("objects", "rooms", "levels", "templates")
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path (Join-Path $MetaOut $d) -Force | Out-Null
}

$objectCount = 0
$roomCount = 0
$levelCount = 0
$templateCount = 0
$warnings = @()

# --- Objects: rename by GUID ---
$objectDir = Join-Path $MetaRoot "objects"
if (Test-Path $objectDir) {
    $objectFiles = Get-ChildItem -Path $objectDir -File -Filter "*.lua" | Sort-Object Name
    foreach ($file in $objectFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match 'guid\s*=\s*"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"') {
            $guid = $Matches[1]
            $dest = Join-Path $MetaOut "objects\$guid.lua"
            Copy-Item $file.FullName $dest
            $objectCount++
        } else {
            $warnings += "No GUID found in $($file.Name) -- skipping"
            Write-Warning "No GUID found in $($file.Name) -- skipping"
        }
    }
}

# --- Rooms: world/ -> rooms/ ---
$roomDir = Join-Path $MetaRoot "world"
if (Test-Path $roomDir) {
    $roomFiles = Get-ChildItem -Path $roomDir -File -Filter "*.lua" | Sort-Object Name
    foreach ($file in $roomFiles) {
        $dest = Join-Path $MetaOut "rooms\$($file.Name)"
        Copy-Item $file.FullName $dest
        $roomCount++
    }
}

# --- Levels ---
$levelDir = Join-Path $MetaRoot "levels"
if (Test-Path $levelDir) {
    $levelFiles = Get-ChildItem -Path $levelDir -File -Filter "*.lua" | Sort-Object Name
    foreach ($file in $levelFiles) {
        $dest = Join-Path $MetaOut "levels\$($file.Name)"
        Copy-Item $file.FullName $dest
        $levelCount++
    }
}

# --- Templates ---
$templateDir = Join-Path $MetaRoot "templates"
if (Test-Path $templateDir) {
    $templateFiles = Get-ChildItem -Path $templateDir -File -Filter "*.lua" | Sort-Object Name
    foreach ($file in $templateFiles) {
        $dest = Join-Path $MetaOut "templates\$($file.Name)"
        Copy-Item $file.FullName $dest
        $templateCount++
    }
}

$total = $objectCount + $roomCount + $levelCount + $templateCount

Write-Host "  Objects:   $objectCount files -> meta/objects/ (renamed by GUID)"
Write-Host "  Rooms:     $roomCount files -> meta/rooms/"
Write-Host "  Levels:    $levelCount files -> meta/levels/"
Write-Host "  Templates: $templateCount files -> meta/templates/"
Write-Host "  Total:     $total files"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    foreach ($w in $warnings) {
        Write-Host "  $w"
    }
}

Write-Host "Done."
