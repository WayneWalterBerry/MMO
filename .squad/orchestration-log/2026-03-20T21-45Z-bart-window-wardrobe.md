# Orchestration: bart-window-wardrobe-fsm

**Agent:** Bart (Architect)  
**Spawn:** 2026-03-20T21:45Z  
**Status:** Completed  
**Mode:** background  

## Manifest

- **Task:** Merge `window.lua` + `window-open.lua` into single-file FSM. Delete legacy `wardrobe-open.lua`.
- **Outcome:** ✅ SUCCESS — FSM consolidation complete. No engine code changes needed.

## What Was Done

1. **window.lua** — Rewritten as unified FSM with `closed` and `open` states, inline transitions, per-state sensory text (on_feel, on_listen, on_smell). GUID preserved: `4ecd1058-5cbe-4601-a98e-c994631f7d6b`.

2. **window-open.lua** — Deleted. All content merged into window.lua's `open` state.

3. **wardrobe-open.lua** — Deleted. Already superseded by wardrobe.lua's FSM. No code references found.

## Engine Impact

None. The engine's open/close verb handlers already check FSM before falling back to mutations. Window now takes the FSM path automatically.

## Verification

- ✅ `open window` / `close window` — correct transitions, correct descriptions
- ✅ `open wardrobe` / `close wardrobe` — still works, contents displayed
- ✅ No stray references to deleted files

## Pattern Established

All openable objects use single-file FSM:
- `initial_state` + `_state` fields
- `states` table with per-state properties
- `transitions` table with verb-driven state changes
- No separate `-open` files

---

**Decision logged:** `.squad/decisions.md` (merged from inbox)  
**History updated:** `.squad/agents/bart/history.md`  
**Commit:** Included in 2026-03-20T21:45Z batch commit
