# Mutation Lint - Full Pipeline with Sequential Output Collection
# Decision: D-MUTATION-LINT-PARALLEL - parallel lint per-file, sequential output display [Smithers blocker #2]
# Step 1: Edge check (broken edges report)
# Step 2: Lint all valid targets - collect output per-file, then print sequentially

param(
    [switch]$EdgesOnly,    # Skip lint step, just check edges
    [string]$Format = "text",
    [string]$Env = $null,
    [int]$ThrottleLimit = 4  # Parallel lint workers
)

# Pre-check: Python availability [Nelson #13, Gil #4]
if (-not $EdgesOnly) {
    $pythonCheck = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCheck) {
        Write-Error "Python not found - required for lint step. Install Python or use -EdgesOnly."
        exit 2
    }
}

Write-Host "=== Phase 1: Edge Existence Check ==="

# Step 1: Edge check
lua scripts/mutation-edge-check.lua
$edgeExit = $LASTEXITCODE
if ($edgeExit -ne 0) {
    Write-Host "`n* Broken mutation edges found (see above)"
}

if (-not $EdgesOnly) {
    Write-Host "`n=== Phase 2: Target Lint Validation ==="

    # Step 2: Lint all valid targets
    $targets = lua scripts/mutation-edge-check.lua --targets
    # Build optional --env argument
    $envArg = if ($Env) { @("--env", $Env) } else { @() }

    if ($targets) {
        # [Smithers blocker #2] Collect output per-file, then print sequentially
        # PS7 path: ForEach-Object -Parallel [Gil #4]
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $results = $targets | ForEach-Object -Parallel {
                $output = python scripts/meta-lint/lint.py $_ --format $using:Format @using:envArg 2>&1
                [PSCustomObject]@{ File = $_; Output = $output }
            } -ThrottleLimit $ThrottleLimit

            foreach ($r in $results) {
                if ($r.Output) {
                    Write-Host "`n--- $($r.File) ---"
                    Write-Host $r.Output
                }
            }
        } else {
            # [Gil #4] Fallback for PS5: sequential execution (no -Parallel)
            Write-Warning "PowerShell less than 7 detected - running lint sequentially (install PS7 for parallel)"
            foreach ($t in $targets) {
                $output = python scripts/meta-lint/lint.py $t --format $Format @envArg 2>&1
                if ($output) {
                    Write-Host "`n--- $t ---"
                    Write-Host $output
                }
            }
        }
    }

    Write-Host "`n=== Summary ==="
    Write-Host "Edge check exit code: $edgeExit"
}

