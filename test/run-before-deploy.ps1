<#
.SYNOPSIS
    Runs all parser unit tests, then (if they pass) triggers the engine build.

.DESCRIPTION
    Pre-deployment gate: tests must pass before build-engine.ps1 runs.
    Called manually or from CI. Exit code 0 = safe to deploy.

.EXAMPLE
    powershell test/run-before-deploy.ps1
#>

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir

Write-Host "=== Pre-Deploy Gate ==="
Write-Host ""

# --- Step 1: Run unit tests ---
Write-Host "Step 1: Running parser unit tests..."
$luaExe = "lua"
$testRunner = Join-Path $RepoRoot "test\run-tests.lua"

Push-Location $RepoRoot
try {
    & $luaExe $testRunner
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "DEPLOY BLOCKED: Unit tests failed. Fix tests before deploying." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "DEPLOY BLOCKED: Could not run tests — $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "All tests passed. Proceeding to build..." -ForegroundColor Green
Write-Host ""

# --- Step 2: Build engine ---
$buildScript = Join-Path $RepoRoot "web\build-engine.ps1"
if (Test-Path $buildScript) {
    & powershell -File $buildScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BUILD FAILED." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Warning: build-engine.ps1 not found at $buildScript" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Pre-Deploy Gate: PASSED ===" -ForegroundColor Green
