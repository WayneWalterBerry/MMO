# Room Exit Architecture

**Author:** Bart (Architect)  
**Date:** 2026-03-19  
**Status:** Proposed — awaiting team review  
**Related:** `docs/design/containment-constraints.md`, `copilot-directive-exits-as-objects.md`, `copilot-directive-room-exits.md`

---

## 1. The Problem

Rooms currently connect with a flat map: `exits = { north = "hallway" }`. This says nothing about *how* you get there. A doorway, a window, a ladder, and a crawlspace are all "north" — but they impose radically different constraints on what can pass through them.

Wayne's core example: a sack can leave the room through a door, but a bed cannot. Even if a bed were `portable = true`, it won't fit through a window. The exit itself must enforce physical constraints.

This intersects with three existing systems:
- **Containment** — size tiers, weight, the 4-layer validator
- **Portability** — `portable = true | "heavy" | false`
- **Mutations** — exits change state (doors break, passages are discovered)

---

## 2. Core Design: Exits Are Mutable Objects

An exit is a **first-class object** embedded in the room's `exits` table. It follows the same self-describing pattern as every other object in the engine: it has properties, keywords, a description, and a mutations table that declares its own lifecycle.

### Why Inline, Not Separate Files

Exits live inside the room definition, not as standalone registered objects. Rationale:

1. **Self-describing rooms.** Reading `start-room.lua` tells you everything about that room — its contents, its exits, and their constraints. No chasing references.
2. **Mutation scope.** When a door breaks, the room file gets rewritten. The mutation is on the room, not on a floating exit object. This is consistent with how surface contents work on furniture.
3. **No orphans.** Exits without rooms are meaningless. Keeping them inline prevents orphaned exit objects in the registry.
4. **Topology is readable.** A room's exit table IS the adjacency list. You can read the world graph from room files alone.

### Backward Compatibility

If an exit value is a **string**, it's shorthand for an unrestricted doorway:

```lua
exits = {
    north = "hallway",           -- shorthand: doorway, no constraints
    south = { target = "cellar", type = "trapdoor", ... },  -- rich exit
}
```

The engine normalizes string exits to `{ target = "hallway", type = "doorway" }` at load time. No existing room files break.

---

## 3. Exit Object Structure

```lua
{
    target = "hallway",              -- room id this exit connects to
    type = "door",                   -- exit type (see taxonomy below)
    name = "a heavy oak door",       -- display name
    keywords = {"door", "oak door"}, -- for parser matching
    description = "A heavy oak door with iron hinges, standing slightly ajar.",

    -- Passage constraints
    max_carry_size = 4,              -- largest item size that fits through
    max_carry_weight = 50,           -- heaviest single item allowed through
    requires_hands_free = false,     -- must drop carried items to use?
    player_max_size = 5,             -- largest player/creature size that fits

    -- State
    open = true,                     -- can be traversed right now?
    locked = false,                  -- requires unlocking first?
    key_id = nil,                    -- item id that unlocks (nil = no key)
    hidden = false,                  -- invisible until discovered?
    broken = false,                  -- has been destroyed/forced open?

    -- Direction
    one_way = false,                 -- can only traverse in this direction?
    direction_hint = nil,            -- "up", "down" — for ladders, stairs, etc.

    -- Durability
    breakable = true,                -- can this exit be broken/forced?
    break_difficulty = 3,            -- 1-5 scale, how hard to break

    -- Self-describing mutations
    mutations = {
        break = {
            becomes_exit = {
                type = "hole in wall",
                name = "a splintered doorframe",
                description = "Where the oak door once stood, only splintered wood and twisted hinges remain.",
                open = true,
                locked = false,
                breakable = false,
                broken = true,
                max_carry_size = 4,
                max_carry_weight = 50,
            },
            spawns = {"wood-splinters"},
            message = "The door bursts inward with a crack of splintering oak!",
        },
        lock = {
            becomes_exit = {
                open = false,
                locked = true,
                description = "The heavy oak door is shut tight. You hear the click of the lock.",
            },
            message = "You turn the key. The lock clicks shut.",
        },
        unlock = {
            requires = "brass-key",
            becomes_exit = {
                open = false,
                locked = false,
                description = "The heavy oak door is closed but unlocked.",
            },
            message = "The key turns with a satisfying click.",
        },
        open = {
            becomes_exit = {
                open = true,
                description = "The heavy oak door stands open, revealing the hallway beyond.",
            },
            message = "The door swings open on groaning hinges.",
        },
        close = {
            becomes_exit = {
                open = false,
                description = "The heavy oak door is closed.",
            },
            message = "You push the door shut. It closes with a heavy thud.",
        },
    },
}
```

### How Exit Mutations Work

Exit mutations use `becomes_exit` instead of `becomes`. The value is a **partial table** — only the fields that change. The engine deep-merges the partial over the current exit state, then rewrites the room. This is a surgical mutation: changing `open = false` to `open = true` doesn't require restating the entire exit.

This follows the same self-describing principle as object mutations: reading the exit tells you everything it can become.

### What `becomes_exit` Does NOT Carry

- `target` never changes (an exit doesn't relocate)
- `mutations` carry forward unless explicitly overwritten in `becomes_exit`
- If `becomes_exit` sets `breakable = false`, break mutations are removed

---

## 4. Exit Type Taxonomy

Exit types are **descriptive labels**, not enforcement categories. The LLM sets all physical properties directly (per Decision: LLM responsible for physical properties). The type name tells the parser and the player what kind of passage this is; the numeric properties enforce constraints.

These are reference ranges, not lookup tables. The LLM should use judgment for each specific instance.

| Exit Type | max_carry_size | max_carry_weight | requires_hands_free | breakable | Typical State |
|---|---|---|---|---|---|
| **doorway** | 5 | 100 | no | no | Always open, no door |
| **door** | 4 | 50 | no | yes | Open/closed/locked |
| **trapdoor** | 3 | 30 | no | yes | Closed, floor-level |
| **window** | 2 | 10 | yes | yes (glass) | Closed/latched |
| **stairs** | 4 | 50 | no | no | Always passable |
| **ladder** | 2 | 15 | yes | no | Always passable |
| **crawlspace** | 2 | 10 | no | no | Always open, very tight |
| **rope** | 1 | 5 | yes | yes (cut) | Hanging, requires climb |
| **grate/drain** | 1 | 2 | no | yes (pry) | Usually locked/barred |
| **chimney** | 1 | 5 | yes | no | Narrow vertical shaft |
| **balcony/ledge** | 3 | 30 | yes | no | Open, often one-way down |
| **secret passage** | 3 | 30 | no | no | Hidden until discovered |
| **hole in wall** | 3 | 20 | no | no | Created by destruction |
| **bridge** | 4 | 50 | no | yes (collapse) | Spans a gap |
| **portal/rift** | 5 | 100 | no | no | Magical, unrestricted |
| **gate/portcullis** | 4 | 50 | no | yes | Open/closed/locked |

### Size Tier Reference (from containment design)

| Tier | Label | Examples |
|---|---|---|
| 1 | Tiny | Key, coin, shard, ring |
| 2 | Small | Book, dagger, potion, sack |
| 3 | Medium | Sword, shield, lantern, stool |
| 4 | Large | Chair, chest, barrel |
| 5 | Huge | Bed, wardrobe, desk |
| 6 | Massive | Piano, statue, cart |

A door with `max_carry_size = 4` lets you bring a chair through but not a bed. A window at `max_carry_size = 2` only allows small items. A crawlspace at `max_carry_size = 2` plus `player_max_size = 3` means only smaller creatures fit.

---

## 5. Exit Traversal Validation

When a player attempts to move through an exit, the engine runs a validation chain. This is analogous to the containment validator but operates on exits instead of containers.

### Layer 1: Visibility

```
Is the exit hidden?
  → "You don't see any way to go [direction]."
```

Hidden exits (`hidden = true`) are invisible to `look` and to movement. They become visible when a mutation sets `hidden = false` (e.g., discovering a secret passage).

### Layer 2: Accessibility

```
Is the exit open?
  → If locked: "The [name] is locked."
  → If closed: "The [name] is closed."
```

Closed but unlocked exits can be opened (triggering the `open` mutation). Locked exits require the matching `key_id` item.

### Layer 3: Player Fit

```
Does the player physically fit?
  → player.size > exit.player_max_size: "You're too large to fit through the [name]."
```

Most exits allow any player. Crawlspaces, chimneys, and drains restrict by player/creature size.

### Layer 4: Carry Constraints

For each item the player is carrying:

```
item.size > exit.max_carry_size?
  → "You can't bring [item.name] through the [exit.name] — it won't fit."

item.weight > exit.max_carry_weight?
  → "You can't bring [item.name] through the [exit.name] — it's too heavy to manage."

exit.requires_hands_free and player is carrying items?
  → "You need your hands free to climb the [exit.name]."
```

**Note on `requires_hands_free`:** This doesn't mean "drop everything." It means items must be in a container (sack, pack, belt) rather than held directly. A player with items in a sack slung over their shoulder can climb a ladder. A player clutching a sword in each hand cannot. This interacts with the inventory model (future design).

### Layer 5: Direction

```
exit.one_way and player is going the wrong direction?
  → Not shown in exits list for reverse direction.
```

One-way exits only appear from the declared side. A balcony drop is one-way down; the reverse direction simply doesn't list that exit.

### Portability Tiers and Exits

The three-tier portability system (`portable = false | "heavy" | true`) interacts with exits:

| Portability | Meaning | Exit Interaction |
|---|---|---|
| `false` | Fixed in place | Cannot move through any exit |
| `"heavy"` | Push/drag only | Only through exits where `requires_hands_free = false` AND large enough |
| `true` | Carry in inventory | Normal exit constraint checks apply |

A bed (`portable = "heavy"`, size 5) can be dragged through a doorway (max_carry_size 5) but not through a door (max_carry_size 4) — unless the door is wide enough (LLM sets this per-instance). It definitely can't go up a ladder (`requires_hands_free = true`).

---

## 6. Bidirectionality

### Rule: Both Sides Are Explicit

If Room A has a door north to Room B, Room B **must** declare its own exit south to Room A. There is no automatic mirroring.

### Why Explicit Over Automatic

1. **Asymmetric exits are common.** A balcony lets you drop down but not climb back up. A trapdoor opens from above but is flush with the floor below. A secret passage is visible from one side but hidden from the other.
2. **Different descriptions.** The door looks different from each side — "a heavy oak door" vs. "a battered door with deep scratches on this side."
3. **Independent mutations.** Breaking down a door from Room A doesn't necessarily change how it looks from Room B (the debris falls toward A, B's side might look different).
4. **Simplicity.** No implicit state sync between rooms. Each room is fully self-describing.

### Consistency Convention

By **convention** (enforced by the LLM at authoring time, not by the engine):
- If Room A has a non-hidden, non-one-way exit north to Room B, Room B should have an exit south to Room A.
- Both exits should reference the same logical passage (same type, compatible constraints).
- The LLM should describe both sides when creating rooms.

The engine does **not** enforce bidirectional consistency. A room with a north exit to "hallway" is valid even if "hallway" has no south exit back. This allows one-way passages, asymmetric secret doors, and in-progress world building.

### Shared Exit Identity

When both sides of a passage need to mutate together (breaking a door affects both rooms), the mutation handler should rewrite both room files. The exit's `target` field provides the link: the engine can find the other room and its corresponding exit.

Convention: exits that share a physical passage should use a `passage_id` field:

```lua
-- In start-room.lua
north = { target = "hallway", passage_id = "bedroom-hallway-door", type = "door", ... }

-- In hallway.lua
south = { target = "start-room", passage_id = "bedroom-hallway-door", type = "door", ... }
```

The `passage_id` lets the mutation engine find and rewrite the paired exit. It's optional — one-way exits and exits without shared mutation needs don't require it.

---

## 7. Mutations on Exits

Exit mutations follow the self-describing pattern. The exit's `mutations` table declares what can happen and what it becomes. When a mutation fires:

1. The `becomes_exit` partial is deep-merged over the current exit state.
2. Any `spawns` items are created in the room.
3. The room definition is rewritten (standard mutation flow).
4. If `passage_id` exists, the paired exit in the target room is also mutated.

### Example: Breaking a Window

```lua
window_exit = {
    target = "courtyard",
    type = "window",
    passage_id = "bedroom-courtyard-window",
    name = "a leaded glass window",
    description = "A tall window of diamond-paned glass. Through it you see a moonlit courtyard.",
    max_carry_size = 2,
    max_carry_weight = 10,
    requires_hands_free = true,
    open = false,
    locked = true,
    breakable = true,
    break_difficulty = 2,

    mutations = {
        break = {
            becomes_exit = {
                type = "hole in wall",
                name = "a shattered window frame",
                description = "Jagged shards of glass cling to the window frame. Cold air rushes through.",
                open = true,
                locked = false,
                breakable = false,
                broken = true,
                requires_hands_free = false,
                max_carry_size = 3,
            },
            spawns = {"glass-shard", "glass-shard"},
            message = "The window explodes inward in a shower of glass!",
        },
        open = {
            condition = function(self) return not self.locked end,
            becomes_exit = {
                open = true,
                description = "The window stands open. Cool night air drifts in.",
            },
            message = "You unlatch the window and push it open.",
        },
        unlock = {
            -- No key required — just unlatch from inside
            becomes_exit = {
                locked = false,
                description = "The window is unlatched but still closed.",
            },
            message = "You slide the iron latch aside.",
        },
    },
}
```

### Exit Mutations vs. Object Mutations

| Aspect | Object Mutation | Exit Mutation |
|---|---|---|
| Where it lives | Object's `mutations` table | Exit's `mutations` table |
| What changes | Entire object is replaced | Exit is partially updated (deep merge) |
| Side effects | `spawns` items in room | `spawns` items in room |
| Paired updates | N/A | Paired exit via `passage_id` |
| Engine mechanism | `mutation.mutate()` rewrites object | Room rewriter updates exit in-place |

Exit mutations use **partial merge** (not full replacement) because exits have many stable fields (target, passage_id, constraints) that shouldn't be restated for every state change. Object mutations use full replacement because the object's identity can change entirely (mirror → shattered mirror).

---

## 8. Room Template

Rooms share common boilerplate. A base room template reduces repetition:

```lua
-- template: room
return {
    size = nil,
    weight = nil,
    portable = false,
    categories = {"room"},
    container = true,
    capacity = 999,
    contents = {},
    location = nil,
    exits = {},
    mutations = {},
}
```

Room instances declare `template = "room"` and override what's unique (name, description, contents, exits). The template resolution is handled by the existing `loader.resolve_template()`.

---

## 9. Integration with Existing Systems

### Containment Validator

The containment validator (`engine/containment/init.lua`) is **not** involved in exit traversal. Containment validates "can item X go inside container Y." Exit traversal validates "can the player bring item X through passage Z." These are orthogonal checks with different failure messages and different validation layers.

A new `engine/traversal/init.lua` module should handle exit validation. It follows the same pattern: pure function, layered checks, returns `(bool, reason_string)`.

### Parser Integration

The parser needs to recognize exit keywords. When a player types "open door" or "break window," the parser should:
1. Check if the current room has an exit matching those keywords.
2. If yes, look up the mutation in the exit's `mutations` table.
3. Dispatch to the room mutation handler.

This is a parser concern, not an architecture concern, but the exit structure supports it by including `keywords` on every exit.

### The `on_look` Function

Room `on_look` is now handled dynamically by the engine (see `dynamic-room-descriptions.md`). The engine's `cmd_look` composes the room view from three sources: room description (permanent features), object `room_presence` fields (dynamic), and visible exits (auto-composed from exit data). Hidden exits are excluded automatically.

Rooms should NOT define custom `on_look` for standard description — the engine handles it. Custom `on_look` is reserved for truly special rooms (magical visions, darkness, rooms that defy normal description). If a room defines `on_look`, the engine calls it instead of composing.

---

## 10. File Layout

No new folders needed. The design fits cleanly into existing structure:

```
src/meta/templates/room.lua          — base room template
src/meta/world/start-room.lua        — updated with rich exits
src/meta/world/*.lua                 — future rooms use same format
src/engine/traversal/init.lua        — exit validation (future)
docs/architecture/room-exits.md            — this document
```

---

## 11. Open Questions

1. **Inventory model.** `requires_hands_free` needs an inventory system that distinguishes "held" from "stored in container." Not yet designed.
2. **NPC traversal.** Do NPCs check exit constraints? Probably yes, but NPC movement isn't designed yet.
3. **Vehicle traversal.** Can a player push a cart through a doorway? Needs `portable = "heavy"` + exit size check. The framework supports it.
4. **Exit descriptions in `look`.** Now resolved: auto-generated from exit data by the engine's dynamic room composition system. See `dynamic-room-descriptions.md`.
