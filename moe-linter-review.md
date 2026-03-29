# Mutation Graph Linter Review — Moe (World Builder)

**Date:** 2026-08-23  
**Reviewed by:** Moe (World Builder)  
**Requested by:** Wayne Berry  
**Plans reviewed:**
- `plans/linter/mutation-graph-linter-design.md`
- `plans/linter/mutation-graph-linter-implementation-phase1.md`

---

## Executive Summary

From the room/world perspective, the mutation-graph linter plan has **strong coverage** of actual mutation edges in my domain. All 7 room files in `src/meta/rooms/` are mutation-free at the room level, but door portal objects (which bridge rooms) spawn wood-splinters transitions. The plan correctly identifies 3 door-to-wood-splinters broken edges from my world. **No additional room-level mutations or cross-reference concerns beyond what the plan already documents.**

---

## ROOM MUTATIONS FOUND

**Status:** ✅ None  
**Details:**
- Scanned all 7 room .lua files: `cellar.lua`, `courtyard.lua`, `crypt.lua`, `deep-cellar.lua`, `hallway.lua`, `start-room.lua`, `storage-cellar.lua`
- All 7 have `mutations = {}` (empty table)
- All 7 have **no FSM transitions** (rooms are static)
- No room has `.mutations[verb].becomes` or `.mutations[verb].spawns` edges
- **Conclusion:** Rooms themselves do not mutate — they are spatial containers only

---

## DOOR EDGE CONCERNS

**Status:** ✅ Fully identified in the plan  
**Details:**

Three door objects defined in `src/meta/objects/` have spawns edges to `wood-splinters`:

| Door File | Room Placement | Transition | Target | Exists? |
|-----------|---|---|---|---|
| `bedroom-hallway-door-north.lua` | start-room | `barred → broken` verb: `break` | `wood-splinters` | ❌ No |
| `bedroom-hallway-door-south.lua` | hallway | `barred → broken` verb: `break` | `wood-splinters` | ❌ No |
| `courtyard-kitchen-door.lua` | courtyard | `locked → broken` verb: `break` | `wood-splinters` | ❌ No |

**Line references:**
- `bedroom-hallway-door-north.lua:133` — `spawns = {"wood-splinters"}`
- `bedroom-hallway-door-south.lua:141` — `spawns = {"wood-splinters"}`
- `courtyard-kitchen-door.lua:122, 132` — `spawns = {"wood-splinters"}` (two transitions)

**Note:** The plan lists these as 3 broken edges (lines 28–30 of design doc):
```
- bedroom-hallway-door-north.lua → wood-splinters (file does not exist)
- bedroom-hallway-door-south.lua → wood-splinters (file does not exist)
- courtyard-kitchen-door.lua → wood-splinters (file does not exist)
```

Technically, if `courtyard-kitchen-door` has 2 break transitions (lines 118 and 128), this could be counted as 4 edges, but the design doc counts by unique target file, so 3 is correct. **The plan's analysis is accurate.**

---

## TRIGGER/REFERENCE ISSUES

**Status:** ⚠️ Triggers found, but no mutation edges; cross-reference concern noted

### Triggers in `deep-cellar.lua`

The `deep-cellar` room defines a `triggers` table (lines 74–79):

```lua
triggers = {
    {
        when   = { object = "chain", enters_state = "pulled" },
        action = { object = "stone-alcove", transition_to = "revealed" },
    },
},
```

**Analysis:**
- **Type:** Object state transition trigger (not a mutation edge)
- **What happens:** When the `chain` object enters the `"pulled"` state, the room triggers `stone-alcove` to transition to `"revealed"` state
- **Is it a mutation edge?** **No** — both objects remain in place. Only their FSM state changes. No `becomes`, `spawns`, or `crafting.becomes` involved.
- **Should the extractor follow it?** **No** — triggers are architectural actions, not data mutations. The plan correctly ignores them (only extraction covers: `mutations[verb].becomes`, `mutations[verb].spawns`, `transitions[i].spawns`, `crafting[verb].becomes`, `on_tool_use.when_depleted`)

### Cross-Reference Concern: type_id GUIDs

**Issue:** Room instances reference objects by `type_id` (GUID), not `id` (string):

Example from `deep-cellar.lua` lines 25, 42:
```lua
{ id = "stone-altar", type = "Stone Altar", type_id = "a5fbf32f-530b-49af-9a19-255575a5eb77" },
{ id = "chain", type = "Chain", type_id = "5f18202e-220f-4a16-b75e-170595f22845" },
```

**The extractor works by file ID (string), not GUID:**
- Extractor loads `src/meta/objects/chain.lua`, extracts `obj.id` = `"chain"`
- Extractor builds `file_map["chain"] → "src/meta/objects/chain.lua"`
- Extractor resolves targets like `"wood-splinters"` via `file_map`

**Is this a problem?**
- **No.** Room files are *not* scanned by the extractor (rooms have no mutations or spawns)
- Room instances use GUIDs only for object instantiation at runtime
- The engine's object loader resolves GUIDs at startup; the extractor only cares about object definition files
- **Conclusion:** Type IDs in room files are for the engine, not for the linter. No concern.

---

## Findings Summary

| Category | Finding | Status |
|----------|---------|--------|
| **Room mutations** | None found | ✅ Safe |
| **Door spawns edges** | 3 broken (wood-splinters) | ✅ Already in plan |
| **Triggers as mutations** | Triggers exist but are NOT mutation edges | ✅ Correctly excluded |
| **Cross-ref GUIDs** | Room type_ids are not extracted | ✅ Not a concern |

---

## Recommendations for the Linter

1. **Door objects are correctly handled** — the plan's edge extraction will find all 3 door-spawn transitions
2. **Rooms are mutation-free** — no special room-level handling needed beyond scanning the `src/meta/rooms/` directory (already in plan)
3. **Triggers are NOT mutation edges** — the extractor correctly ignores them; they are architectural, not data mutations
4. **No new edge types discovered** — all mutations in my domain fit the 5 extraction categories (becomes, spawns, crafting, tool_depletion)

---

## Questions / Clarifications for Bart

None. The plan is sound from the world perspective. All door edges are identified, and the extraction logic is comprehensive.

