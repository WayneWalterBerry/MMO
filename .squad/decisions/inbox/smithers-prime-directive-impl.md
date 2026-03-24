# Decision: Prime Directive Tiers 1-5 Implementation Complete

**Author:** Smithers (UI Engineer)
**Date:** 2026-07-20
**Issue:** #106 Phase 3

## Decision

All 5 Prime Directive parser tiers are implemented as standalone data-driven modules. The implementation follows the architecture doc exactly, with one adjustment: the fuzzy typo scoring formula was changed from `4 - dist` to `max_dist - dist + 3` to ensure all accepted matches meet the 0.3 confidence threshold.

## What Changed

| Tier | Module | Status |
|------|--------|--------|
| Tier 3: Idiom Library | `src/engine/parser/idioms.lua` (NEW) | 21/21 tests |
| Tier 1: Question Transforms | `src/engine/parser/questions.lua` (NEW) | 16/16 tests |
| Tier 2: Error Messages | `src/engine/errors.lua` (NEW) | 19/19 tests |
| Tier 4: Context Window | `src/engine/parser/context.lua` (MODIFIED) | 53/53 tests |
| Tier 5: Fuzzy Enhancement | `src/engine/parser/fuzzy.lua` (MODIFIED) | 18/18 tests |

## Who This Affects

- **Bart (Engine):** New `errors.lua` module can be used by verb handlers to replace bare error strings. Integration is optional — the module works standalone.
- **Nelson (QA):** All 73 TDD tests pass. The existing `test-fuzzy-nouns.lua` was updated to reflect the new 4-char typo threshold.
- **Flanders (Objects):** Objects can now declare `error_responses` for per-object error messages (Tier 2 integration point, not yet wired).
- **All:** The 3 new modules (`idioms.lua`, `questions.lua`, `errors.lua`) are not yet integrated into the preprocess pipeline or verb handlers. They work as standalone modules called by their respective test files. Pipeline integration is Phase 4.

## Open Items

1. **Pipeline integration:** `preprocess.lua` still uses inline IDIOM_TABLE and inline transform_questions. These should delegate to the new modules.
2. **Verb handler integration:** Error messages in verb handlers still use bare strings. Migrating to `errors.context()` + `errors.format()` is a separate task.
3. **Loop integration:** "again" repeat and direction tracking need wiring in `loop/init.lua`.
