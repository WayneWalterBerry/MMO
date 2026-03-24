# D-COMPOUND-COMMAND-SPLITTING
**Author:** Smithers (UI Engineer)
**Date:** 2026-07-18
**Status:** Implemented
**Issue:** #168

## Decision

Added verb-aware compound command splitting to the parser pipeline.

**Key design choices:**

1. **Static KNOWN_VERBS table** in `preprocess.lua` (~100 verbs) rather than a runtime lookup against `context.verbs`. This keeps preprocess.lua as a pure-function module with no side effects or external dependencies.

2. **Split on ` and ` only when the next word is a recognized verb.** This prevents breaking multi-object commands like "get candle and matchbox" while correctly splitting "take key and unlock door".

3. **`, and` handled by stripping leading "and "** from segments after comma-based splitting, rather than adding a separate character-level tokenizer rule. Simpler and handles edge cases like `, and then`.

## Who Should Know

- **Nelson (QA):** 29 new tests in `test/parser/test-compound-commands.lua`. The KNOWN_VERBS set should be updated if new verb handlers are added.
- **Bart (Architect):** Game loop's naive ` and ` while-loop replaced with `preprocess.split_compound()`. Much simpler control flow.
- **All verb authors:** When registering a NEW verb not in the KNOWN_VERBS table, add it to the set in `preprocess.lua` so compound splitting recognizes it.
