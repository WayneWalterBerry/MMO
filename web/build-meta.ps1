<#
.SYNOPSIS
    Copies individual meta .lua files into the web/dist/meta/ directory tree
    for JIT loading.

.DESCRIPTION
    Auto-discovers ALL subdirectories under src/meta/.
    - Objects: renamed by their GUID field -> meta/objects/{guid}.lua
    - Rooms (rooms/): copied as-is -> meta/rooms/{filename}
    - All other dirs: copied as-is -> meta/{dirname}/{filename}

    Adding new meta categories (injuries, materials, etc.) requires zero
    build script changes.

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

# Capture build timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$timestampCompact = Get-Date -Format "yyyyMMddHHmmss"
Write-Host "Build timestamp: $timestamp ($timestampCompact)"

Write-Host "Copying meta files to $MetaOut..."

# Clean stale output
if (Test-Path $MetaOut) {
    Remove-Item -Recurse -Force $MetaOut
}

# Auto-discover ALL subdirectories under src/meta (no hardcoded list)
$srcDirs = Get-ChildItem -Path $MetaRoot -Directory | Select-Object -ExpandProperty Name

# No dir name mapping needed — source and output names match
$dirMap = @{}

# Create output directories
$outputDirs = $srcDirs | ForEach-Object { if ($dirMap[$_]) { $dirMap[$_] } else { $_ } } | Sort-Object -Unique
foreach ($d in $outputDirs) {
    New-Item -ItemType Directory -Path (Join-Path $MetaOut $d) -Force | Out-Null
}

$counts = @{}
$warnings = @()

# --- Objects: special handling — rename by GUID ---
$objectDir = Join-Path $MetaRoot "objects"
if (Test-Path $objectDir) {
    $objectFiles = Get-ChildItem -Path $objectDir -File -Filter "*.lua" | Sort-Object Name
    $counts["objects"] = 0
    foreach ($file in $objectFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match 'guid\s*=\s*"\{?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\}?"') {
            $guid = $Matches[1]
            $dest = Join-Path $MetaOut "objects\$guid.lua"
            Copy-Item $file.FullName $dest
            $counts["objects"]++
        } else {
            $warnings += "No GUID found in $($file.Name) -- skipping"
            Write-Warning "No GUID found in $($file.Name) -- skipping"
        }
    }
}

# --- Creatures: special handling — rename by GUID (like objects) ---
$creatureDir = Join-Path $MetaRoot "creatures"
if (Test-Path $creatureDir) {
    $creatureFiles = Get-ChildItem -Path $creatureDir -File -Filter "*.lua" | Sort-Object Name
    $counts["creatures"] = 0
    foreach ($file in $creatureFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match 'guid\s*=\s*"\{?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\}?"') {
            $guid = $Matches[1]
            $dest = Join-Path $MetaOut "creatures\$guid.lua"
            Copy-Item $file.FullName $dest
            $counts["creatures"]++
        } else {
            $warnings += "No GUID found in creature $($file.Name) -- skipping"
            Write-Warning "No GUID found in creature $($file.Name) -- skipping"
        }
    }
}

# --- All other directories: copy as-is ---
$specialDirs = @("objects", "creatures")
foreach ($srcName in $srcDirs) {
    if ($specialDirs -contains $srcName) { continue }
    $srcPath = Join-Path $MetaRoot $srcName
    $outName = if ($dirMap[$srcName]) { $dirMap[$srcName] } else { $srcName }
    $outPath = Join-Path $MetaOut $outName
    $counts[$outName] = 0
    $files = Get-ChildItem -Path $srcPath -File -Filter "*.lua" | Sort-Object Name
    foreach ($file in $files) {
        $dest = Join-Path $outPath $file.Name
        Copy-Item $file.FullName $dest
        $counts[$outName]++
    }
}

$total = ($counts.Values | Measure-Object -Sum).Sum

foreach ($key in ($counts.Keys | Sort-Object)) {
    $label = $key.PadRight(12)
    $suffix = if ($key -eq "objects") { "(renamed by GUID)" } else { "" }
    Write-Host "  ${label} $($counts[$key]) files -> meta/$key/ $suffix"
}
Write-Host "  Total:       $total files"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    foreach ($w in $warnings) {
        Write-Host "  $w"
    }
}

# Embed build timestamp and version in game-adapter.lua
$adapterPath = Join-Path $ScriptDir "game-adapter.lua"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$adapterContent = [System.IO.File]::ReadAllText($adapterPath, $utf8NoBom)
$adapterContent = $adapterContent -replace 'local BUILD_TIMESTAMP = ".*?"', "local BUILD_TIMESTAMP = `"$timestamp`""
$commitHash = (git -C $RepoRoot rev-parse --short HEAD 2>$null) | Out-String
$commitHash = $commitHash.Trim()
if ($commitHash) {
    $adapterContent = $adapterContent -replace 'local BUILD_VERSION = ".*?"', "local BUILD_VERSION = `"$commitHash`""
    Write-Host "  Stamped game-adapter.lua: BUILD_VERSION = `"$commitHash`""
}
[System.IO.File]::WriteAllText($adapterPath, $adapterContent, $utf8NoBom)
Write-Host "  Stamped game-adapter.lua: BUILD_TIMESTAMP = `"$timestamp`""

# Generate meta/_index.lua manifest for browser JIT loading
# Lists filenames (without .lua extension) per non-object meta directory
$indexLines = @("return {")
foreach ($srcName in ($srcDirs | Sort-Object)) {
    if ($specialDirs -contains $srcName) { continue }
    $outName = if ($dirMap[$srcName]) { $dirMap[$srcName] } else { $srcName }
    $srcPath = Join-Path $MetaRoot $srcName
    $files = Get-ChildItem -Path $srcPath -File -Filter "*.lua" | Sort-Object Name
    $names = ($files | ForEach-Object { '    "' + $_.BaseName + '"' }) -join ",`n"
    $indexLines += "  $outName = {"
    $indexLines += $names
    $indexLines += "  },"
}
$indexLines += "}"
$indexPath = Join-Path $MetaOut "_index.lua"
$indexContent = $indexLines -join "`n"
[System.IO.File]::WriteAllText($indexPath, $indexContent, $utf8NoBom)
Write-Host "  Generated meta/_index.lua manifest"

$objectCount = if ($counts["objects"]) { $counts["objects"] } else { 0 }
$roomCount = if ($counts["rooms"]) { $counts["rooms"] } else { 0 }
Write-Host "Meta built ($timestamp) -> $objectCount objects, $roomCount rooms, $total total"

# --- Sound assets: copy assets/sounds/ to dist/sounds/ ---
$soundSrc = Join-Path $RepoRoot "assets\sounds"
$soundOut = Join-Path $OutDir "sounds"

if (Test-Path $soundSrc) {
    $soundFiles = Get-ChildItem -Path $soundSrc -File -Filter "*.opus" -Recurse
    if ($soundFiles.Count -gt 0) {
        # Clean stale sound output
        if (Test-Path $soundOut) {
            Remove-Item -Recurse -Force $soundOut
        }

        $soundCount = 0
        foreach ($file in $soundFiles) {
            # Preserve category subdirectory structure
            $relPath = $file.FullName.Substring($soundSrc.Length + 1)
            $destPath = Join-Path $soundOut $relPath
            $destDir = Split-Path -Parent $destPath
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item $file.FullName $destPath
            $soundCount++
        }
        Write-Host "  Sounds:      $soundCount .opus files -> dist/sounds/"
    } else {
        Write-Host "  Sounds:      0 .opus files found (directory exists, no assets yet)"
    }
} else {
    Write-Host "  Sounds:      skipped (assets/sounds/ not found)"
}

Write-Host "Done."