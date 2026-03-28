#!/bin/bash
# Mutation Lint — Full Pipeline with Sequential Output Collection
# Decision: D-MUTATION-LINT-PARALLEL [Smithers blocker #2: sequential phases, parallel per-file]
WORKERS=${1:-4}

# Pre-check: Python availability [Nelson #13, Gil #4]
if ! command -v python &>/dev/null; then
    echo "ERROR: Python not found — required for lint step." >&2
    echo "Run 'lua scripts/mutation-edge-check.lua' alone for edge checking without Python." >&2
    exit 2
fi

echo "=== Phase 1: Edge Existence Check ==="

# Step 1: Edge check — runs FIRST, completes before lint [Smithers blocker #2: no concurrent output]
lua scripts/mutation-edge-check.lua
EDGE_EXIT=$?
if [ $EDGE_EXIT -ne 0 ]; then
    echo ""
    echo "⚠ Broken mutation edges found (see above)"
fi

echo ""
echo "=== Phase 2: Target Lint Validation ==="

# Step 2: Lint targets in parallel, collect output per-file then display [Smithers blocker #2]
OUTDIR=$(mktemp -d)
lua scripts/mutation-edge-check.lua --targets | xargs -P "$WORKERS" -I {} sh -c '
    OUTFILE="$1/$(echo "$2" | tr "/" "_")"
    python scripts/meta-lint/lint.py "$2" > "$OUTFILE" 2>&1
' _ "$OUTDIR" {}

# Print collected results sequentially
for f in "$OUTDIR"/*; do
    [ -s "$f" ] && {
        TARGET=$(basename "$f" | tr "_" "/")
        echo ""
        echo "--- $TARGET ---"
        cat "$f"
    }
done
rm -rf "$OUTDIR"

echo ""
echo "=== Summary ==="
echo "Edge check exit code: $EDGE_EXIT"
