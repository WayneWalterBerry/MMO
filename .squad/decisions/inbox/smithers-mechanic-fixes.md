# Smithers — Game Mechanic Bug Fixes (Pass 026)

**Author:** Smithers (UI Engineer)  
**Date:** 2026-07-24  
**Status:** Implemented  

---

## D-BUG091: Terminal item fallback must search all visible containers

**Affects:** `src/engine/verbs/init.lua` — `take` handler  

When a terminal (spent) item is found on the floor, the `take` handler now searches for a fresh alternative in ALL accessible containers: hand-held bags, containers on surfaces, and open containers in room contents. Previously only checked hand-held bags, causing spent matches to be picked up over fresh ones in the matchbox on the nightstand.

---

## D-BUG092: Status bar must use live object references, not registry lookups

**Affects:** `src/engine/ui/status.lua`  

After a `becomes` mutation, `registry:register(id, new_obj)` replaces the registry entry, but player hand references still point to the old object. Status bar (and any state-reading code) must prefer the actual object from player hands over a static `registry:get()` lookup. Pattern: search hands → search visible containers → registry fallback.

**Broader implication:** Any post-mutation code that reads object state should be aware that hand references can be stale relative to the registry. Consider updating hand references during mutation in the future (architectural concern for Bart).

---

## D-BUG089: Prepositional scope must be respected in feel/examine handlers

**Affects:** `src/engine/verbs/init.lua` — `feel` handler  

When the player says "feel inside X" or "feel in X", only the "inside" surface zone should be enumerated. The `surface_prep` mechanism (already working for "under/beneath") was extended to handle "in/inside". This prevents scope bleed where interior queries also show top/other surface contents.

---

## D-SYNONYM: hunt/rummage added as search synonyms

**Affects:** `src/engine/parser/preprocess.lua`  

Added `hunt for`, `hunt around`, `rummage for`, `rummage through`, `rummage around` as natural language patterns mapping to the `search` verb. Nelson reported `hunt for matches` was unrecognized.
