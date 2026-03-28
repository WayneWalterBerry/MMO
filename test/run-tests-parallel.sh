#!/bin/bash
# test/run-tests-parallel.sh
# Parallel test runner for MMO test suite (Unix/macOS/CI).
# Mirrors test directories from run-tests.lua and run-tests-parallel.ps1.
#
# Usage:
#   ./test/run-tests-parallel.sh              # 8 workers
#   ./test/run-tests-parallel.sh -w 4         # 4 workers
#   ./test/run-tests-parallel.sh --bench      # Include benchmarks
#   ./test/run-tests-parallel.sh --shard parser  # Run only parser tests

set -euo pipefail

WORKERS=8
BENCH=false
SHARD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--workers) WORKERS="$2"; shift 2 ;;
        --bench) BENCH=true; shift ;;
        --shard) SHARD="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Test directories (mirrors run-tests.lua / run-tests-parallel.ps1)
TEST_DIRS=(
    "test/parser"
    "test/parser/pipeline"
    "test/inventory"
    "test/injuries"
    "test/verbs"
    "test/search"
    "test/nightstand"
    "test/integration"
    "test/ui"
    "test/rooms"
    "test/objects"
    "test/armor"
    "test/wearables"
    "test/sensory"
    "test/fsm"
    "test/creatures"
    "test/combat"
    "test/food"
    "test/butchery"
    "test/loot"
    "test/stress"
    "test/crafting"
    "test/engine"
)

# Shard filter — keep only directories whose path contains the shard name
if [[ -n "$SHARD" ]]; then
    FILTERED=()
    for dir in "${TEST_DIRS[@]}"; do
        if echo "$dir" | grep -q "test/$SHARD"; then
            FILTERED+=("$dir")
        fi
    done
    if [[ ${#FILTERED[@]} -eq 0 ]]; then
        echo "No test directories match shard: $SHARD"
        exit 1
    fi
    TEST_DIRS=("${FILTERED[@]}")
fi

# File discovery
find_test_files() {
    for dir in "${TEST_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -maxdepth 1 -name "test-*.lua" ! -name "*helpers*" -type f
            if [[ "$BENCH" == "true" ]]; then
                find "$dir" -maxdepth 1 -name "bench-*.lua" -type f
            fi
        fi
    done | sort
}

FILE_LIST=$(find_test_files)

if [[ -z "$FILE_LIST" ]]; then
    echo ""
    echo "No test files found"
    exit 1
fi

FILE_COUNT=$(echo "$FILE_LIST" | wc -l | tr -d ' ')

# Header
LABEL="Parallel — $WORKERS workers"
if [[ -n "$SHARD" ]]; then LABEL="$LABEL, shard: $SHARD"; fi
if [[ "$BENCH" == "true" ]]; then LABEL="$LABEL, +bench"; fi

echo "========================================"
echo "  MMO Test Suite ($LABEL)"
echo "========================================"
echo ""
echo "Found $FILE_COUNT test file(s)"
echo ""

# Temp files for result aggregation
RESULT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mmo-test-XXXXXX")
FAIL_LOG="$RESULT_DIR/failures.log"
PASS_LOG="$RESULT_DIR/passes.log"
touch "$FAIL_LOG" "$PASS_LOG"

# Cleanup on exit
cleanup() {
    rm -rf "$RESULT_DIR"
}
trap cleanup EXIT

WALL_START=$(date +%s)

# Parallel execution via xargs
# xargs returns non-zero if any child fails; we handle exit codes ourselves
echo "$FILE_LIST" | xargs -P "$WORKERS" -I{} bash -c '
    file="{}"
    start_ms=$(($(date +%s%N 2>/dev/null || echo 0) / 1000000))
    output=$(lua "$file" 2>&1)
    exitcode=$?
    end_ms=$(($(date +%s%N 2>/dev/null || echo 0) / 1000000))
    elapsed=$((end_ms - start_ms))

    if [ $exitcode -eq 0 ]; then
        echo "  ✓ $file (${elapsed}ms)"
        echo "$file" >> "'"$PASS_LOG"'"
    else
        echo "  ✗ $file (${elapsed}ms)"
        {
            echo ">> $file:"
            echo "$output"
            echo ""
        } >> "'"$FAIL_LOG"'"
        echo "$file" >> "'"$RESULT_DIR"'/failed_files.log"
    fi
' || true

WALL_END=$(date +%s)
WALL_SECONDS=$((WALL_END - WALL_START))

PASS_COUNT=$(wc -l < "$PASS_LOG" | tr -d ' ')
FAIL_COUNT=0
if [[ -f "$RESULT_DIR/failed_files.log" ]]; then
    FAIL_COUNT=$(wc -l < "$RESULT_DIR/failed_files.log" | tr -d ' ')
fi

# Print failure details
if [[ $FAIL_COUNT -gt 0 ]]; then
    echo ""
    echo "========================================"
    echo "  Failures:"
    echo "========================================"
    cat "$FAIL_LOG"
fi

# Summary
echo ""
echo "========================================"
if [[ $FAIL_COUNT -gt 0 ]]; then
    echo "  RESULT: $PASS_COUNT passed, $FAIL_COUNT failed (${WALL_SECONDS}s wall time, $WORKERS workers)"
else
    echo "  RESULT: All $PASS_COUNT passed (${WALL_SECONDS}s wall time, $WORKERS workers)"
fi
echo "========================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
