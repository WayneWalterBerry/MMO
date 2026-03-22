# Spatial Relationships Architecture

**Version:** 1.0  
**Date:** 2026-03-26  
**Author:** Bart (Architect)  
**Status:** Active  
**Companion doc:** `docs/design/spatial-system.md` (Comic Book Guy — game design spec)

---

## Overview

Objects in the MMO world exist in spatial relationships with each other. A candle sits ON a nightstand. A rug COVERS a trap door. A key hides INSIDE a drawer. These are not just description flavor — they are **engine-level metadata** that determines what a player can see, find, and interact with.

This document defines the **engine architecture** for spatial relationships: how they are expressed in object metadata, how the engine resolves them at runtime, and how the search/traversal system respects them.

---

## 1. Relationship Type Taxonomy

Five spatial relationships exist, organized by their **visibility semantics**:

### Visible Relationships (both objects perceivable)

| Relationship | Preposition | Example | Both Visible? |
|---|---|---|---|
| `on_top_of` | ON | candle on nightstand | ✅ Yes |
| `inside` | IN | matchbox in drawer | Depends on container state |

### Concealment Relationships (one object hidden)

| Relationship | Preposition | Example | Cover Visible? | Hidden Visible? |
|---|---|---|---|---|
| `covering` | OVER / ON | rug over trap door | ✅ Yes | ❌ No — until cover moved |
| `under` | UNDER | trap door under rug | ❌ No (inverse of covering) | — |
| `behind` | BEHIND | note behind wardrobe | ✅ Yes (blocker visible) | ❌ No — until blocker moved |

### Key Distinction: ON vs COVERING

This is the fundamental gap Wayne identified. Two objects can be in the same physical arrangement (A is above B) but have completely different visibility semantics:

- **ON:** Candle sits on nightstand. Both visible. Player sees candle and nightstand.
- **COVERING:** Rug lies on trap door. Rug visible. Trap door invisible until rug is moved.

The difference is **intent** — declared by the object author, not inferred by the engine. The `covering` field on an object is a first-class declaration that the covered object is hidden.

---

## 2. Metadata Design

### 2.1 The Covering Object (the thing on top)

The covering object declares what it hides via a `covering` array and manages its own moved/unmoved state:

```lua
-- rug.lua (THE COVERING OBJECT)
return {
    id = "rug",
    name = "a threadbare rug",

    -- Spatial properties
    movable = true,          -- can be moved by the player
    moved = false,           -- tracks whether player has moved it
    covering = {"trap-door"},-- list of object IDs this object hides

    -- State after being moved
    move_message = "You grab the edge of the threadbare rug and pull it aside...",
    moved_room_presence = "The threadbare rug lies bunched against the wall...",
    moved_description = "The threadbare rug has been pulled aside...",

    -- Optional: surface underneath for small hidden items
    surfaces = {
        underneath = { capacity = 3, max_item_size = 2, contents = {"brass-key"} },
    },
}
```

**Design rationale:** The relationship lives on the **covering** object, not the room. This follows the engine's core principle: objects declare their own behavior. The rug knows it covers the trap door. The room just lists both objects in its instances table.

### 2.2 The Hidden Object (the thing underneath)

The hidden object declares its initial hidden state and its discovery narrative:

```lua
-- trap-door.lua (THE HIDDEN OBJECT)
return {
    id = "trap-door",
    name = "a trap door",

    hidden = true,           -- invisible to player until revealed
    discovery_message = "As you pull the rug aside, your foot catches on a wooden edge...",

    -- FSM: hidden → revealed → open
    initial_state = "hidden",
    _state = "hidden",

    states = {
        hidden = {
            hidden = true,
            room_presence = "",   -- empty: invisible in room description
            description = "",     -- empty: nothing to examine
        },
        revealed = {
            hidden = false,
            room_presence = "A trap door is set into the stone floor...",
            description = "A heavy wooden trap door set flush with the flagstones...",
        },
        open = { ... },
    },

    transitions = {
        { from = "hidden", to = "revealed", verb = "reveal", trigger = "reveal" },
        { from = "revealed", to = "open", verb = "open", ... },
    },
}
```

### 2.3 Why Object-Level, Not Room-Level

We considered expressing relationships at the room level:

```lua
-- REJECTED: room-level relationship table
relationships = {
    { subject = "rug", relation = "covers", object = "trap-door" },
}
```

**Rejected because:**
1. Violates Principle 8 (objects declare behavior; engine executes metadata)
2. Creates a second source of truth — the rug already knows it covers things
3. Doesn't compose: if the rug is moved to another room, the relationship data stays behind
4. Room files would grow complex with redundant cross-references

The current pattern — `covering` on the rug, `hidden` + FSM on the trap door — keeps each object self-describing. The room just instantiates both; the engine reads their metadata to resolve spatial visibility.

### 2.4 The `behind` Relationship (Future Extension)

For objects hidden behind furniture (note behind wardrobe, lever behind curtains), use the same pattern:

```lua
-- wardrobe.lua
return {
    id = "wardrobe",
    hiding_behind = {"secret-note"},  -- objects hidden behind this object
    -- Revealed by: "look behind wardrobe" or "move wardrobe"
}

-- secret-note.lua
return {
    id = "secret-note",
    hidden = true,
    discovery_message = "Behind the wardrobe, pressed flat against the stone wall...",
    -- FSM: hidden → revealed (same pattern as trap door)
}
```

The engine treats `hiding_behind` identically to `covering` for visibility purposes — both suppress the hidden object from search results, room descriptions, and sensory verbs. The difference is **which verb reveals them**: `move` for covering, `look behind` or `move` for behind.

---

## 3. Visibility Rules

### 3.1 The Visibility Contract

An object is **visible** (and therefore findable, examinable, interactable) if and only if:

1. `obj.hidden` is `nil` or `false`
2. The object's current FSM state does not set `hidden = true`

An object is **invisible** (skipped by all engine systems) if:

1. `obj.hidden == true`, OR
2. The object's current FSM state has `hidden = true`

### 3.2 Room Description (`look`)

The `look` handler already respects this. When rendering room contents:

```lua
-- From verbs/init.lua, line ~1253
if obj and not obj.hidden then
    local text = obj.room_presence
    -- render it
end
```

Hidden objects have empty `room_presence` in their hidden state, and the `not obj.hidden` check filters them from the description entirely.

### 3.3 Sensory Verbs (`smell`, `listen`)

Sensory verbs already filter hidden objects:

```lua
-- smell handler, line ~2074
if obj and not obj.hidden and obj.on_smell then ...

-- listen handler, line ~2186
if obj and not obj.hidden and obj.on_listen then ...
```

### 3.4 Search/Traverse — THE GAP

**This is the design gap Wayne identified.** The search traversal system (`src/engine/search/traverse.lua`) does NOT check the `hidden` flag:

```lua
-- traverse.lua, expand_object() — NO hidden check
local obj = registry:get(object_id)
if not obj then return {} end
-- Proceeds to add obj to search queue regardless of obj.hidden
```

**Required fix:** `expand_object()` must skip hidden objects:

```lua
local function expand_object(object_id, registry, depth, include_nested_containers, visited)
    -- ... existing cycle/depth checks ...

    local obj = registry:get(object_id)
    if not obj then return {} end

    -- SPATIAL VISIBILITY: skip hidden objects
    if obj.hidden then return {} end

    -- ... rest of expansion ...
end
```

Similarly, `matches_target()` should skip hidden objects:

```lua
local function matches_target(object, target, registry, depth, visited)
    if not object or not target then return false end
    if object.hidden then return false end
    -- ... rest of matching ...
end
```

This ensures that `search nightstand` doesn't accidentally discover the trap door (which is in the room's proximity list but hidden). Hidden objects are ghosts until revealed.

### 3.5 Keyword Resolution in Verb Handler

The verb handler's keyword resolution (line ~435-439) already respects `hidden`:

```lua
-- verbs/init.lua line ~439
if obj and not obj.hidden and matches_keyword(obj, kw) then
```

This means `examine trap door` correctly fails when the trap door is still hidden.

---

## 4. The Reveal Mechanism

### 4.1 Trigger: Moving the Covering Object

When a player moves a covering object, the engine executes a two-phase reveal:

**Phase 1: Dump underneath surface items**
```lua
-- verbs/init.lua, ~line 1168
if obj.covering and obj.surfaces and obj.surfaces.underneath then
    -- Items hidden under the rug (brass key, etc.) spill onto the floor
    for i = #underneath.contents, 1, -1 do
        local item_id = underneath.contents[i]
        room.contents[#room.contents + 1] = item_id
        item.location = room.id
        print("Something clatters to the floor -- " .. item.name .. "!")
    end
end
```

**Phase 2: Reveal covered hidden objects**
```lua
-- verbs/init.lua, ~line 1184
if obj.covering then
    for _, covered_id in ipairs(obj.covering) do
        local covered = reg:get(covered_id)
        if covered and covered.hidden then
            -- Prefer FSM transition (hidden → revealed)
            if covered.states and covered._state == "hidden" then
                fsm_mod.transition(reg, covered_id, "revealed", {})
            else
                -- Fallback: clear hidden flag directly
                covered.hidden = false
            end
            -- Fire the discovery narration
            if covered.discovery_message then
                print(covered.discovery_message)
            end
        end
    end
end
```

### 4.2 Discovery Narration Flow

The reveal produces a layered narrative:

1. **Move message** (from the covering object): "You grab the edge of the threadbare rug and pull it aside, bunching it against the wall."
2. **Underneath items** (if any): "Something clatters to the floor — a brass key!"
3. **Discovery message** (from the hidden object): "As you pull the rug aside, your foot catches on a wooden edge — a seam in the flagstones. No... a trap door!"

This ordering creates a natural narrative beat: action → incidental discovery → major discovery.

### 4.3 FSM Transition on Reveal

The reveal prefers FSM transitions over raw flag-clearing:

- **FSM path (preferred):** `hidden → revealed` via `fsm_mod.transition()`. This lets the object's FSM update all state-dependent properties (room_presence, description, on_feel, etc.) in one atomic operation. The trap door uses this path.
- **Flag path (fallback):** `covered.hidden = false`. For simpler objects that don't have a full FSM, just clearing the flag makes them visible. The brass key under the rug uses this path (it's just an item, not an FSM object).

---

## 5. Search Engine Interaction

### 5.1 What Search MUST NOT Find

The search engine (traverse.lua) walks the room's proximity list and expands objects into searchable entries. Hidden objects must be excluded:

- `search room` — must NOT mention the trap door while it's hidden
- `search rug` — must NOT reveal the trap door (the rug's `covering` list is metadata, not searchable content)
- `look under rug` — this is a separate verb handler, not search; it may give a hint

### 5.2 What Search SHOULD Find

- The covering object itself: "You notice a threadbare rug on the floor"
- Items on accessible surfaces of the covering object: brass key (only after rug is moved, since `underneath` surface accessibility depends on the `moved` flag)
- All non-hidden objects in the room

### 5.3 The underneath Surface Problem

The rug has a `surfaces.underneath` with `contents = {"brass-key"}`. Currently, search can discover this surface and its contents even while the rug hasn't been moved. This needs a visibility gate:

**Recommended approach:** The `underneath` surface should be `accessible = false` when the rug hasn't been moved, and `accessible = true` after. The rug's `on_look` function already hints at something beneath — but search should not auto-discover it.

```lua
-- rug.lua — recommended addition
surfaces = {
    underneath = {
        capacity = 3,
        max_item_size = 2,
        contents = {"brass-key"},
        accessible = false,    -- becomes true when rug is moved
    },
},
```

The move handler should set `accessible = true` on the underneath surface when the rug is moved:

```lua
-- In the move handler, after moving a covering object:
if obj.surfaces and obj.surfaces.underneath then
    obj.surfaces.underneath.accessible = true
end
```

---

## 6. How This Changes start-room.lua (The Bedroom)

### 6.1 Current State (Already Working)

The bedroom already expresses the rug-trapdoor relationship correctly:

```lua
-- start-room.lua instances (current)
{ id = "rug",       type = "Rug",       location = "room" },
{ id = "trap-door", type = "Trap Door", location = "room" },
{ id = "brass-key", type = "Brass Key", location = "rug.underneath" },
```

The room lists both objects. The rug has `covering = {"trap-door"}`. The trap door has `hidden = true` and an FSM starting in `"hidden"` state. The relationship is entirely expressed in the objects, not the room.

### 6.2 The Move Verb Handler (Current Implementation)

Already implemented in `src/engine/verbs/init.lua` (~line 1120-1206). The handler:

1. Checks `obj.movable` — only movable objects respond to `move`
2. Sets `obj.moved = true`
3. Swaps description/room_presence to moved variants
4. Dumps `surfaces.underneath.contents` to the floor
5. Iterates `obj.covering` and reveals each hidden object via FSM or flag

### 6.3 What Needs to Change

**traverse.lua** — Add hidden-object filtering (see Section 3.4 above).

**rug.lua** — Add `accessible = false` to the `underneath` surface (see Section 5.3 above). The move handler should set it to `true` when the rug is moved.

No changes needed to:
- `trap-door.lua` — already correct
- `start-room.lua` — already correct
- `verbs/init.lua` reveal logic — already correct

---

## 7. Design Summary

### The Pattern

```
COVERING OBJECT                    HIDDEN OBJECT
┌─────────────────┐                ┌─────────────────┐
│ covering = [id] │───reveals──▶   │ hidden = true    │
│ movable = true  │                │ _state = "hidden"│
│ moved = false   │                │ discovery_message│
│ surfaces = {    │                │ states = {       │
│   underneath={} │                │   hidden = {...} │
│ }               │                │   revealed ={...}│
└─────────────────┘                └─────────────────┘
```

### Decision Matrix

| Question | Answer |
|---|---|
| Where does the relationship live? | On the covering object (`covering` array) |
| Where does hidden state live? | On the hidden object (`hidden` flag + FSM) |
| Does the room know about the relationship? | No — room just lists both objects |
| Who decides when to reveal? | The move verb handler in the engine |
| Does search find hidden objects? | No — traverse.lua must filter them out |
| Is this a new system? | No — it's a formalization of what already works, plus a traverse.lua fix |

### Principles Respected

- **Principle 7** (Spatial Relationships): Relationships are metadata, not engine code
- **Principle 8** (Engine Executes Metadata): Objects declare covering/hidden; engine reads and acts
- **Principle 3** (FSM States): Hidden → Revealed is an FSM transition, not a flag toggle
- **Principle 6** (Sensory Space): Hidden objects have empty sensory text; revealed objects have full descriptions

---

## 8. Implementation Checklist

1. **traverse.lua** — Add `if obj.hidden then return {} end` to `expand_object()` and `if object.hidden then return false end` to `matches_target()`
2. **rug.lua** — Add `accessible = false` to the `underneath` surface
3. **Move handler** — Set `underneath.accessible = true` when moving a covering object
4. **Test** — Verify `search room` doesn't mention trap door while rug is in place; verify it does after `move rug`
5. **Future: `behind` relationship** — Implement `hiding_behind` field following the same pattern as `covering`
