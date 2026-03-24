### D-ENGINE-REFACTORING-REVIEW
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Status:** Proposed (awaiting Chalmers approval)  
**Affects:** All engine files >500 lines, especially `src/engine/verbs/init.lua`

**Summary:** Completed P0-A senior code review of all engine files >500 lines. Full analysis in `docs/architecture/engine/refactoring-review.md`.

**Key Decisions:**

1. **`verbs/init.lua` (5,884 lines): SPLIT into 12 files** — 1 registry (`init.lua` ~80 lines), 1 shared helpers module (`helpers.lua` ~650 lines), 10 verb category modules (sensory, acquisition, containers, destruction, fire, combat, crafting, equipment, survival, movement, meta). Each verb module exports a `register(handlers)` function. LLM context reduction: 74-84% per edit.

2. **`preprocess.lua` (1,059 lines): SPLIT into 3 files (P2)** — core, transforms, patterns. Low urgency — file is well-organized and independently tested.

3. **`traverse.lua` (871 lines): KEEP as-is** — high internal cohesion, single FSM, no split value.

4. **`goal_planner.lua` (848 lines): SPLIT into 2 files (P3)** — queries vs planner. Low urgency unless file grows further.

5. **`loop/init.lua` (585 lines): KEEP as-is** — safety barrier ordering is critical, size reflects genuine complexity.

6. **Sequencing: Refactor BEFORE meta-compiler (P0-B)** — meta-check validates file paths; building it against a 5,884-line monolith then splitting creates wasted work. Refactor first gives meta-check a clean target.

7. **Utility deduplication prerequisite:** `strip_articles()`, `kw_match()`/`matches_keyword()`, and hand accessors are duplicated across 3+ files. Centralize before any split (30-minute task, zero behavioral risk).

**Blockers:**
- Nelson must write pre-refactoring tests for `helpers.lua` functions before extraction begins (especially `find_visible`, `remove_from_location`, `matches_keyword`, `perform_mutation`)
- Chalmers must approve the refactoring-before-meta-compiler sequencing

**Estimated effort:** 18-22 hours total across Bart + Nelson.
