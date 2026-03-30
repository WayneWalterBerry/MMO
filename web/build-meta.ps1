<#
.SYNOPSIS
    Copies individual meta .lua files into the web/dist/meta/ directory tree
    for JIT loading.

.DESCRIPTION
    Multi-world build: discovers ALL worlds under src/meta/worlds/ and bundles
    their content into web/dist/meta/.

    - Objects from all worlds: renamed by GUID -> meta/objects/{guid}.lua
    - Creatures from all worlds: renamed by GUID -> meta/creatures/{guid}.lua
    - Rooms from all worlds: copied as-is -> meta/rooms/{filename}
    - World definitions: meta/worlds/{world_id}/world.lua (per-world)
    - Levels: meta/worlds/{world_id}/levels/{file} (per-world)
    - Levels (manor): also copied to flat meta/levels/ (backward compat)
    - Shared dirs (templates, materials): meta/{dirname}/{filename}
    - World-specific dirs (injuries): merged into flat meta/{dirname}/

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

$MetaRoot  = Join-Path $RepoRoot "src\meta"
$WorldsDir = Join-Path $MetaRoot "worlds"
$MetaOut   = Join-Path $OutDir "meta"

Write-Host "=== build-meta.ps1 (multi-world) ==="

# Capture build timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$timestampCompact = Get-Date -Format "yyyyMMddHHmmss"
Write-Host "Build timestamp: $timestamp ($timestampCompact)"

Write-Host "Copying meta files to $MetaOut..."

# Clean stale output
if (Test-Path $MetaOut) {
    Remove-Item -Recurse -Force $MetaOut
}

# Discover all worlds
$allWorlds = @()
if (Test-Path $WorldsDir) {
    $allWorlds = Get-ChildItem -Path $WorldsDir -Directory | Select-Object -ExpandProperty Name
}
Write-Host "  Worlds found: $($allWorlds -join ', ')"

# Shared dirs live at src/meta/ level (not per-world)
$sharedDirs = @()
foreach ($d in @("templates", "materials")) {
    if (Test-Path (Join-Path $MetaRoot $d)) { $sharedDirs += $d }
}

# GUID-renamed categories (objects, creatures) — merge from all worlds
$guidCategories = @("objects", "creatures")
# Copy-as-is categories — merge from all worlds into flat dirs
$flatCategories = @("rooms", "injuries")

# Create output directories
foreach ($d in ($sharedDirs + $guidCategories + $flatCategories + @("levels"))) {
    New-Item -ItemType Directory -Path (Join-Path $MetaOut $d) -Force | Out-Null
}

$counts = @{}
$warnings = @()

# --- Per-world content ---
foreach ($worldName in $allWorlds) {
    $worldRoot = Join-Path $WorldsDir $worldName
    Write-Host "  --- World: $worldName ---"

    # World definition → meta/worlds/{world_id}/world.lua
    $worldDefSrc = Join-Path $worldRoot "world.lua"
    if (Test-Path $worldDefSrc) {
        $worldDefDir = Join-Path $MetaOut "worlds\$worldName"
        New-Item -ItemType Directory -Path $worldDefDir -Force | Out-Null
        Copy-Item $worldDefSrc (Join-Path $worldDefDir "world.lua")
        Write-Host "    world.lua -> meta/worlds/$worldName/world.lua"
    }

    # Levels → meta/worlds/{world_id}/levels/ (per-world)
    $levelDir = Join-Path $worldRoot "levels"
    if (Test-Path $levelDir) {
        $levelFiles = Get-ChildItem -Path $levelDir -File -Filter "*.lua" | Sort-Object Name
        if ($levelFiles.Count -gt 0) {
            $worldLevelOut = Join-Path $MetaOut "worlds\$worldName\levels"
            New-Item -ItemType Directory -Path $worldLevelOut -Force | Out-Null
            $countKey = "levels($worldName)"
            $counts[$countKey] = 0
            foreach ($file in $levelFiles) {
                Copy-Item $file.FullName (Join-Path $worldLevelOut $file.Name)
                $counts[$countKey]++
            }
            # Backward compat: manor levels also go to flat meta/levels/
            if ($worldName -eq "manor") {
                foreach ($file in $levelFiles) {
                    Copy-Item $file.FullName (Join-Path $MetaOut "levels\$($file.Name)")
                }
                Write-Host "    levels: $($counts[$countKey]) files -> meta/worlds/$worldName/levels/ + meta/levels/ (compat)"
            } else {
                Write-Host "    levels: $($counts[$countKey]) files -> meta/worlds/$worldName/levels/"
            }
        }
    }

    # GUID-renamed categories (objects, creatures)
    foreach ($cat in $guidCategories) {
        $catDir = Join-Path $worldRoot $cat
        if (-not (Test-Path $catDir)) { continue }
        $catFiles = Get-ChildItem -Path $catDir -File -Filter "*.lua" | Sort-Object Name
        if ($catFiles.Count -eq 0) { continue }
        $countKey = "$cat($worldName)"
        $counts[$countKey] = 0
        foreach ($file in $catFiles) {
            $content = Get-Content $file.FullName -Raw
            if ($content -match 'guid\s*=\s*"\{?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\}?"') {
                $guid = $Matches[1]
                $dest = Join-Path $MetaOut "$cat\$guid.lua"
                Copy-Item $file.FullName $dest
                $counts[$countKey]++
            } else {
                $warnings += "No GUID found in $worldName/$cat/$($file.Name) -- skipping"
                Write-Warning "No GUID found in $worldName/$cat/$($file.Name) -- skipping"
            }
        }
        Write-Host "    $($cat): $($counts[$countKey]) files -> meta/$cat/ (renamed by GUID)"
    }

    # Flat-merge categories (rooms, injuries)
    foreach ($cat in $flatCategories) {
        $catDir = Join-Path $worldRoot $cat
        if (-not (Test-Path $catDir)) { continue }
        $catFiles = Get-ChildItem -Path $catDir -File -Filter "*.lua" | Sort-Object Name
        if ($catFiles.Count -eq 0) { continue }
        $countKey = "$cat($worldName)"
        $counts[$countKey] = 0
        foreach ($file in $catFiles) {
            Copy-Item $file.FullName (Join-Path $MetaOut "$cat\$($file.Name)")
            $counts[$countKey]++
        }
        Write-Host "    $($cat): $($counts[$countKey]) files -> meta/$cat/"
    }
}

# --- Shared directories (templates, materials) ---
foreach ($srcName in $sharedDirs) {
    $srcPath = Join-Path $MetaRoot $srcName
    $outPath = Join-Path $MetaOut $srcName
    $counts[$srcName] = 0
    $files = Get-ChildItem -Path $srcPath -File -Filter "*.lua" | Sort-Object Name
    foreach ($file in $files) {
        Copy-Item $file.FullName (Join-Path $outPath $file.Name)
        $counts[$srcName]++
    }
    Write-Host "  $($srcName): $($counts[$srcName]) files -> meta/$srcName/ (shared)"
}

# --- Summary ---
$total = ($counts.Values | Measure-Object -Sum).Sum

Write-Host ""
Write-Host "  Summary:"
foreach ($key in ($counts.Keys | Sort-Object)) {
    $label = $key.PadRight(22)
    Write-Host "    ${label} $($counts[$key]) files"
}
Write-Host "    Total:                 $total files"

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
# Merged rooms from all worlds, shared categories
$indexLines = @("return {")

# Collect all rooms across worlds
$allRooms = @()
foreach ($worldName in $allWorlds) {
    $roomDir = Join-Path $WorldsDir "$worldName\rooms"
    if (Test-Path $roomDir) {
        $roomFiles = Get-ChildItem -Path $roomDir -File -Filter "*.lua" | Sort-Object Name
        $allRooms += $roomFiles | ForEach-Object { $_.BaseName }
    }
}
$allRooms = $allRooms | Sort-Object -Unique
$roomNames = ($allRooms | ForEach-Object { '    "' + $_ + '"' }) -join ",`n"
$indexLines += "  rooms = {"
$indexLines += $roomNames
$indexLines += "  },"

# Collect all injuries across worlds
$allInjuries = @()
foreach ($worldName in $allWorlds) {
    $injuryDir = Join-Path $WorldsDir "$worldName\injuries"
    if (Test-Path $injuryDir) {
        $injuryFiles = Get-ChildItem -Path $injuryDir -File -Filter "*.lua" | Sort-Object Name
        $allInjuries += $injuryFiles | ForEach-Object { $_.BaseName }
    }
}
if ($allInjuries.Count -gt 0) {
    $allInjuries = $allInjuries | Sort-Object -Unique
    $injuryNames = ($allInjuries | ForEach-Object { '    "' + $_ + '"' }) -join ",`n"
    $indexLines += "  injuries = {"
    $indexLines += $injuryNames
    $indexLines += "  },"
}

# Collect all levels (manor flat for backward compat)
$manorLevelDir = Join-Path $WorldsDir "manor\levels"
if (Test-Path $manorLevelDir) {
    $levelFiles = Get-ChildItem -Path $manorLevelDir -File -Filter "*.lua" | Sort-Object Name
    $levelNames = ($levelFiles | ForEach-Object { '    "' + $_.BaseName + '"' }) -join ",`n"
    $indexLines += "  levels = {"
    $indexLines += $levelNames
    $indexLines += "  },"
}

# Shared dirs
foreach ($srcName in ($sharedDirs | Sort-Object)) {
    $srcPath = Join-Path $MetaRoot $srcName
    $files = Get-ChildItem -Path $srcPath -File -Filter "*.lua" | Sort-Object Name
    $names = ($files | ForEach-Object { '    "' + $_.BaseName + '"' }) -join ",`n"
    $indexLines += "  $srcName = {"
    $indexLines += $names
    $indexLines += "  },"
}

# Worlds list
$worldNames = ($allWorlds | Sort-Object | ForEach-Object { '    "' + $_ + '"' }) -join ",`n"
$indexLines += "  worlds = {"
$indexLines += $worldNames
$indexLines += "  },"

$indexLines += "}"
$indexPath = Join-Path $MetaOut "_index.lua"
$indexContent = $indexLines -join "`n"
[System.IO.File]::WriteAllText($indexPath, $indexContent, $utf8NoBom)
Write-Host "  Generated meta/_index.lua manifest"

# Per-world totals
$totalObjects = 0
$totalRooms = 0
foreach ($key in $counts.Keys) {
    if ($key -like "objects(*") { $totalObjects += $counts[$key] }
    if ($key -like "rooms(*") { $totalRooms += $counts[$key] }
}
Write-Host "Meta built ($timestamp) -> $totalObjects objects, $totalRooms rooms, $total total ($($allWorlds.Count) worlds)"

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