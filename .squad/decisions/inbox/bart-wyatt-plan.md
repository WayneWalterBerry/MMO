## D-WYATT-PLAN: Wyatt's World Implementation Plan v2.0

**Status:** 🟢 Active  
**Author:** Bart (Architect)  
**Date:** 2026-08-22  
**Category:** Architecture / Planning  
**Affects:** All agents — Bart (WAVE-0 engine), Moe (rooms), Flanders (objects), Bob (puzzles), Smithers (parser), Nelson (testing), Gil (web), CBG (review), Wayne (audit)

### Summary

Wrote the full implementation plan for Wyatt's World (`projects/wyatt-world/plan.md` v2.0), replacing Kirk's v1.0 placeholder. 4 waves, 3 gates, 15 new test files, ~6,050 estimated LOC.

### Key Decisions

1. **Multi-world engine in WAVE-0 (Bart):** The world loader's `select()` currently errors on 2+ worlds. Must be upgraded before any Wyatt content is loadable. Wayne overruled Kirk's "no engine changes."

2. **`content_root` convention:** Each world .lua file gains optional `content_root` field (relative to `src/meta/`). If nil, use legacy paths. If set, load rooms/objects/levels from that subdirectory. The Manor stays at legacy paths. Wyatt's World uses `worlds/wyatt-world`.

3. **`--world <id>` CLI flag:** Required when 2+ world files exist. Auto-select when 1 world (backward compat).

4. **Player-state scoreboard (recommended, not confirmed):** Track puzzle completion in `player.state.puzzles_completed = {}`. Scoreboard reads from player state on examine. Avoids cross-room mutations and world-specific engine code. To be confirmed by Bob + Flanders in WAVE-1.

5. **GUID pre-assignment before WAVE-1:** Bart reserves a GUID block for all Wyatt objects to prevent collisions during parallel authoring by Moe and Flanders.

### Impact

- **Bart:** Executes WAVE-0 (engine loader upgrade, main.lua refactoring)
- **Moe:** WAVE-1a rooms blocked on GATE-0
- **Flanders:** WAVE-1b objects + level file blocked on GATE-0
- **Bob:** WAVE-1c puzzle specs blocked on GATE-0
- **Nelson:** WAVE-1d test scaffolding blocked on GATE-0
- **Smithers:** WAVE-2a parser polish blocked on GATE-1
- **Gil:** WAVE-3c web deploy blocked on GATE-2
- **Board updated:** `projects/wyatt-world/board.md` reflects wave structure
