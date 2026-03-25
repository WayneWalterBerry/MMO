# D-PARSER-SYNONYM-CORRECTIONS

**Author:** Smithers (UI Engineer / Parser)  
**Date:** 2026-03-25  
**Status:** Implemented  
**Issues:** #242, #243, #244

## Decision

Changed synonym mappings for `peer` and `check` from `look` to `examine`. These verbs imply close inspection, not casual glancing.

Also changed typo correction thresholds:
- 4-char words: now corrected at distance 1 (was: no correction)
- 5-char words: max distance 1 (was: 2)
- 6+ char words: max distance 2 (was: 3)

## Who Should Know

- **Nelson (QA):** Benchmark updated to expect `examine` for peer/check/check-out. Old test expectations from #174 updated. Benchmark score: 134/147 (91.2%).
- **Flanders (Objects):** No object changes needed.
- **Brockman (Docs):** Parser improvement plan updated in `plans/parser-improvement-plan.md`.

## Rationale

"Peer" and "check" semantically mean "examine closely", not "glance at". The old mappings were a carryover from #174 when `check` was removed from synonyms to preserve "check out" routing. Now both "check" and "check out" correctly resolve to `examine`.
