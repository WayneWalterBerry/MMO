# Decision: Window & Wardrobe FSM Consolidation

**Author:** Bart (Architect)  
**Date:** 2026-03-26  
**Status:** Implemented  

## Summary

Merged `window.lua` + `window-open.lua` into a single FSM file (`window.lua`). Deleted the legacy `wardrobe-open.lua` since `wardrobe.lua` already had a complete FSM.

## What Changed

1. **window.lua** — Rewritten as single-file FSM with `closed` and `open` states, inline transitions, and per-state sensory text (on_feel, on_listen, on_smell). GUID preserved: `4ecd1058-5cbe-4601-a98e-c994631f7d6b`.

2. **window-open.lua** — Deleted. All content merged into window.lua's `open` state.

3. **wardrobe-open.lua** — Deleted. Was already superseded by wardrobe.lua's FSM. No code referenced it.

## Engine Impact

None. The engine's open/close verb handlers already check FSM (`obj.states`) before falling back to mutations. Window now takes the FSM path automatically. The empty `mutations = {}` table on both objects is harmless — `find_mutation` returns nil for empty tables.

## Pattern Established

All openable objects should use the single-file FSM pattern:
- `initial_state` + `_state` fields
- `states` table with per-state properties (name, description, room_presence, sensory text, surfaces)
- `transitions` table with verb-driven state changes
- No separate `-open` files; no mutation `becomes` references

## Verified

- `open window` / `close window` — correct transition messages, correct descriptions per state
- `open wardrobe` / `close wardrobe` — still works, contents displayed in open state
- No remaining references to `window-open` or `wardrobe-open` in the codebase
