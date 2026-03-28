#!/usr/bin/env pwsh
# test/run-tests-parallel.ps1
# Parallel test runner for MMO test suite.
# Requires PowerShell 7+ for ForEach-Object -Parallel.
#
# Usage:
#   ./test/run-tests-parallel.ps1              # Run test-* files, 8 workers
#   ./test/run-tests-parallel.ps1 -Workers 4   # Run with 4 workers
#   ./test/run-tests-parallel.ps1 -Bench        # Include bench-* files
#   ./test/run-tests-parallel.ps1 -Shard parser # Run only test/parser/ files

param(
    [int]$Workers = 8,
    [switch]$Bench,
    [string]$Shard = ""
)

$ErrorActionPreference = "Stop"

# PowerShell 7 guard
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "PowerShell 7+ is required for parallel execution. Current version: $($PSVersionTable.PSVersion). Use 'pwsh' instead of 'powershell'."
    exit 1
}

# Test directories (mirrors run-tests.lua)
$testDirs = @(
    "test\parser",
    "test\parser\pipeline",
    "test\inventory",
    "test\injuries",
    "test\verbs",
    "test\search",
    "test\nightstand",
    "test\integration",
    "test\ui",
    "test\rooms",
    "test\objects",
    "test\armor",
    "test\wearables",
    "test\sensory",
    "test\fsm",
    "test\creatures",
    "test\combat",
    "test\food",
    "test\butchery",
    "test\loot",
    "test\stress",
    "test\crafting",
    "test\engine"
)

# Shard filter
if ($Shard) {
    $testDirs = @($testDirs | Where-Object { $_ -match "test\\$Shard" })
    if ($testDirs.Count -eq 0) {
        Write-Error "No test directories match shard: $Shard"
        exit 1
    }
}

# File discovery
$testFiles = @()
foreach ($dir in $testDirs) {
    if (Test-Path $dir) {
        $found = Get-ChildItem -Path $dir -Filter "test-*.lua" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch "helpers" }
        foreach ($f in $found) {
            $rel = $f.FullName.Substring((Get-Location).Path.Length + 1)
            $subdir = (Split-Path $rel -Parent) -replace '\\', '/'
            $display = "$subdir/$($f.Name)"
            $testFiles += [PSCustomObject]@{
                FullName     = $f.FullName
                RelativePath = $rel
                Display      = $display
            }
        }

        if ($Bench) {
            $benchFound = Get-ChildItem -Path $dir -Filter "bench-*.lua" -File -ErrorAction SilentlyContinue
            foreach ($f in $benchFound) {
                $rel = $f.FullName.Substring((Get-Location).Path.Length + 1)
                $subdir = (Split-Path $rel -Parent) -replace '\\', '/'
                $display = "$subdir/$($f.Name)"
                $testFiles += [PSCustomObject]@{
                    FullName     = $f.FullName
                    RelativePath = $rel
                    Display      = $display
                }
            }
        }
    }
}

$testFiles = $testFiles | Sort-Object Display

if ($testFiles.Count -eq 0) {
    Write-Host "`nNo test files found"
    exit 1
}

# Header
$label = "Parallel — $Workers workers"
if ($Shard) { $label += ", shard: $Shard" }
if ($Bench) { $label += ", +bench" }

Write-Host "========================================"
Write-Host "  MMO Test Suite ($label)"
Write-Host "========================================"
Write-Host ""
Write-Host "Found $($testFiles.Count) test file(s)"
Write-Host ""

# Parallel execution
$wallTimer = [System.Diagnostics.Stopwatch]::StartNew()

$results = $testFiles | ForEach-Object -Parallel {
    $file = $_
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & lua $file.FullName 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    $sw.Stop()
    [PSCustomObject]@{
        Display  = $file.Display
        TimeMs   = $sw.ElapsedMilliseconds
        ExitCode = $exitCode
        Output   = $output
        Passed   = ($exitCode -eq 0)
    }
} -ThrottleLimit $Workers

$wallTimer.Stop()

# Results per file
$passCount = 0
$failCount = 0
$failures = @()

foreach ($r in $results) {
    if ($r.Passed) {
        $passCount++
        Write-Host "  $([char]0x2713) $($r.Display) ($($r.TimeMs)ms)"
    } else {
        $failCount++
        $failures += $r
        Write-Host "  $([char]0x2717) $($r.Display) ($($r.TimeMs)ms)"
    }
}

# Failed output
if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Failures:"
    Write-Host "========================================"
    foreach ($f in $failures) {
        Write-Host ""
        Write-Host ">> $($f.Display):"
        Write-Host $f.Output
    }
}

# Summary
$wallSeconds = [math]::Round($wallTimer.Elapsed.TotalSeconds, 1)
Write-Host ""
Write-Host "========================================"
if ($failCount -gt 0) {
    Write-Host "  RESULT: $passCount passed, $failCount failed ($($wallSeconds)s wall time, $Workers workers)"
} else {
    Write-Host "  RESULT: All $passCount passed ($($wallSeconds)s wall time, $Workers workers)"
}
Write-Host "========================================"

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
