# Decision: Meta-lint Audit Baseline Established

**Author:** Bart (Architecture Lead)
**Date:** 2026-03-25
**Scope:** All squad members

## Decision

The meta-lint system has been run against all 134 meta files. The baseline is:
- **0 errors** across all 182 rules
- **152 warnings** (143 are XF-03 keyword collisions)
- **6 info** findings

## Implications

1. **Flanders:** 4 new issues assigned (#245–#248) — injury sensory gaps, trap-door description, and 4 missing healing item objects.
2. **All members:** New meta file additions should pass `python scripts/meta-lint/lint.py` with zero new findings before PR.
3. **XF-03 is the dominant issue.** 90% of all findings are keyword collisions. Smithers and Flanders should coordinate on disambiguation (#190).

## Affected Issues
- #245, #246, #247, #248 (new)
- #190, #195, #196 (existing, unchanged)
