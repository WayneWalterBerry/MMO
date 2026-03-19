# Dynamic Room Description Architecture

**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Proposed — awaiting team review  
**Related:** `docs/design/containment-constraints.md`, `docs/design/room-exits.md`, `docs/architecture/src-structure.md`

---

## 1. The Problem

Room descriptions hardcode references to mutable, movable objects. The start room says:

> "A massive four-poster bed dominates the center, its heavy curtains hanging in moth-eaten folds."

But the bed can be moved, destroyed, or mutated. If the bed is dragged out, the room description still talks about it. This violates the engine's core principle: **code IS state**, and state changes via rewrite.

### What's Broken

1. **Room `description`** references objects in `contents` (the bed, the window light).
2. **Room `on_look`** hardcodes a paragraph listing every object by name and position.
3. If any object is moved, removed, or mutated, the room text becomes a lie.

### Wayne's Directives

> "In a room with lots of objects, the player should NOT see everything at once. Players need to examine things to see more. Players can't see stuff in sacks unless they look in the sack. They can't see stuff behind the bed unless they look there. The interrelationship of things matters."

> "It is the responsibility of the LLM writing the objects and rooms to understand their size, weight, and other characteristics."

---

## 2. Core Design: Three-Part Composition

A room's `look` output is composed at runtime from three independent sources:

```
┌─────────────────────────────────────────────┐
│  1. Room Description (permanent features)   │
│     Walls, floor, ceiling, atmosphere,      │
│     light, smell, built-in architecture     │
├─────────────────────────────────────────────┤
│  2. Object Presences (dynamic)              │
│     Each object in contents contributes     │
│     its room_presence sentence              │
├─────────────────────────────────────────────┤
│  3. Exits (auto-composed)                   │
│     Visible exits listed with state         │
└─────────────────────────────────────────────┘
```

Each part is independently sourced. No part references data owned by another part. If an object is removed from `contents`, its sentence vanishes. If an exit is hidden, it disappears from the list.

---

## 3. Part 1: Room Description (Permanent Features Only)

The room's `description` field contains ONLY permanent, immovable features of the space:

- **Architecture:** walls, floor, ceiling, alcoves, pillars, built-in stonework
- **Atmosphere:** smell, temperature, ambient sound, humidity, air quality
- **Ambient light:** natural light from permanent openings (not from candles or lamps — those are objects)
- **Fixed features:** fireplace hearths (the structure, not the fire), wall sconces (the fixture, not the candle), built-in shelving (the shelf, not the books)

### What NEVER Goes in Room Description

- Any object listed in `contents`
- Any movable furniture (bed, desk, wardrobe)
- Any portable item (candle, sack, sword)
- References to objects by name ("the four-poster bed", "the nightstand")
- Light from movable light sources (candles, lanterns, torches held in sconces)

### Example: Before and After

**Before (broken):**
```lua
description = "You stand in a dim bedchamber that smells of tallow, old wool,
and the faintest ghost of lavender. The stone walls are bare save for the
shadows that cling to them like ivy. A massive four-poster bed dominates the
center, its heavy curtains hanging in moth-eaten folds. Pale grey light seeps
through velvet drapes drawn across a window in the far wall."
```

**After (correct):**
```lua
description = "You stand in a dim bedchamber that smells of tallow, old wool,
and the faintest ghost of lavender. The stone walls are bare save for the
shadows that cling to them like ivy. A deep stone alcove in the far wall
admits a sliver of pale grey light."
```

The "deep stone alcove" is permanent architecture — even if the window breaks, the alcove remains. The bed, curtains, and window are all objects that contribute their own presence.

---

## 4. Part 2: Object Presence via `room_presence`

Each object defines how it appears in a room at a glance via a `room_presence` field.

### The `room_presence` Field

```lua
-- bed.lua
return {
    id = "bed",
    name = "a large four-poster bed",
    room_presence = "A massive four-poster bed dominates the center of the room, its heavy curtains hanging in moth-eaten folds.",
    description = "A massive four-poster bed...",  -- full examine text
    ...
}
```

**`room_presence`** is a complete prose sentence describing how this object appears when you're standing in the room. It includes:

- The object's visual identity (what it looks like from across the room)
- Its spatial position relative to PERMANENT features (walls, corners, floor — never other objects)
- A hint of character or atmosphere

**`description`** remains the detailed examine text shown when the player looks AT the object specifically.

### Rules for `room_presence`

1. **Must be a complete sentence.** Not a fragment. Capitalised, punctuated.
2. **Must NOT reference other movable objects.** "A nightstand sits beside the bed" — NO. The bed might be gone. "A nightstand crusted with candle wax sits against the wall" — YES.
3. **Should reference permanent features for positioning.** Walls, corners, floor, ceiling, alcoves. These don't move.
4. **Should convey scale and character.** This is the player's first impression. "A nightstand sits here" is technically correct but lifeless.
5. **Is separate from `description`.** The `room_presence` is the at-a-glance sentence. The `description` is the detailed examination. They serve different purposes and will often share some language, but they are independent fields.

### Fallback

If an object has no `room_presence`, the engine falls back to:

```
"There is {name} here."
```

This is functional but bland. All authored objects should have `room_presence`.

### Hidden Objects

Objects with `hidden = true` do not contribute their `room_presence` to the room view. They are invisible until discovered via a mutation or interaction.

---

## 5. Part 3: Exit Rendering

Exits are auto-composed from the room's `exits` table. This is already partially implemented in `start-room.lua` and documented in `docs/design/room-exits.md`.

The engine iterates `room.exits`, skips hidden exits, and renders each visible exit with its current state (open, closed, locked).

```
Exits:
  north: a heavy oak door (closed)
  window: the leaded glass window (locked)
```

No changes to exit rendering are required. The existing design is compatible with dynamic composition.

---

## 6. Engine Composition Algorithm

The engine's `look` handler composes the three parts:

```lua
function compose_room_view(room, registry)
    local parts = {}

    -- Part 1: Permanent room description
    parts[#parts + 1] = room.description

    -- Part 2: Object presences
    local presences = {}
    for _, obj_id in ipairs(room.contents) do
        local obj = registry:get(obj_id)
        if obj and not obj.hidden then
            if obj.room_presence then
                presences[#presences + 1] = obj.room_presence
            else
                presences[#presences + 1] = "There is " .. (obj.name or obj.id) .. " here."
            end
        end
    end
    if #presences > 0 then
        parts[#parts + 1] = table.concat(presences, " ")
    end

    -- Part 3: Visible exits
    local exit_lines = {}
    for dir, exit in pairs(room.exits) do
        local e = type(exit) == "string" and {name = dir, hidden = false} or exit
        if not e.hidden then
            local state = ""
            if e.open == false and e.locked then
                state = " (locked)"
            elseif e.open == false then
                state = " (closed)"
            end
            exit_lines[#exit_lines + 1] = "  " .. dir .. ": " .. (e.name or dir) .. state
        end
    end
    if #exit_lines > 0 then
        parts[#parts + 1] = "Exits:\n" .. table.concat(exit_lines, "\n")
    end

    return table.concat(parts, "\n\n")
end
```

### Key Behaviors

- **Order matters.** Objects appear in the order they're listed in `room.contents`. The LLM should order them from most prominent to least prominent when authoring the room.
- **Concatenation.** Object presences are joined with spaces into a single paragraph. This reads as natural prose, not a bullet list.
- **Separation.** The three parts are separated by blank lines (`\n\n`).
- **No `on_look` needed for standard rooms.** The engine composes the view. Custom `on_look` is reserved for truly special rooms (magical visions, darkness, etc.).

### Replacing `on_look`

Rooms should NOT define `on_look` for standard description composition. The engine handles it. If a room defines `on_look`, the engine calls it instead of composing — this is the escape hatch for special cases.

The `on_look` override should be rare. If you need custom behavior, you almost certainly need a mutation or a special event, not a custom look handler.

---

## 7. Visibility and Occlusion

Wayne's directive: "Players can't see stuff in sacks unless they look in the sack. They can't see stuff behind the bed unless they look there."

### Layer 1: Room-Level Visibility

Only objects directly in `room.contents` appear in the room view. Objects on surfaces of other objects (on the nightstand, in the wardrobe, under the rug) are NOT shown.

This is already correct in the data model:
- `room.contents = {"bed", "nightstand", ...}` — top-level objects
- `bed.surfaces.top.contents = {"pillow", "blanket"}` — NOT in room view

The pillow only appears when the player examines the bed.

### Layer 2: Surface Visibility

When a player examines an object, its `on_look` handler reveals contents of **visible** surfaces only.

Each surface has an implicit visibility based on its nature:

| Surface Type | Default Visibility | Player Must... |
|---|---|---|
| `top` | Visible | Just examine the object |
| `inside` (closed) | Hidden | Open it first, then examine |
| `inside` (open) | Visible | Just examine the object |
| `underneath` | Hidden | "look under [object]" |
| `behind` | Hidden | "look behind [object]" |

The `on_look` handler on each object controls what's shown. When the nightstand drawer is closed, `on_look` says "The drawer is closed" — it doesn't list the contents. When the drawer is opened (via mutation to `nightstand-open`), the mutated object's `on_look` reveals the inside contents.

### Layer 3: Container Occlusion

Objects inside closed containers are invisible:
- Sack contents → only visible when player "look in sack"
- Wardrobe contents → only visible when wardrobe is open AND player examines it
- Closed desk drawer → invisible until opened

This is enforced by the object's `on_look` handler and the container's state. The engine does NOT automatically list container contents in the room view.

### Layer 4: Hidden Objects

Objects with `hidden = true` are completely invisible:
- Not shown in room view
- Not findable by parser (can't "examine hidden thing")
- Become visible when a mutation or interaction sets `hidden = false`

Example: A trapdoor under the rug. The rug's `surfaces.underneath` contains the trapdoor ID. The trapdoor object has `hidden = true`. Even if the player "look under rug", the engine checks the trapdoor's hidden flag. The trapdoor becomes visible only when discovered (e.g., moving the rug triggers a mutation that sets `hidden = false` on the trapdoor).

### Layer 5: Depth of Examination

The principle: **each interaction reveals one layer.**

- `look` → room description + top-level objects + exits
- `examine bed` → bed's detailed description + visible surface contents (on top)
- `look under bed` → what's underneath the bed
- `look in sack` → sack contents
- `examine pillow` (after seeing it on the bed) → pillow's detailed description

Players peel the onion. They don't get a dump of every object and sub-object in the room at once.

---

## 8. Object Ordering in `room.contents`

The order of IDs in `room.contents` determines the order object presences appear in the room view. The LLM should order them by visual prominence:

1. **Dominant feature first.** The biggest, most eye-catching thing (the bed).
2. **Supporting features next.** Things that define the room's character (furniture, fixtures).
3. **Background details last.** Small, subtle things (chamber pot, rug).

This is an authoring convention, not an engine enforcement. The engine iterates in order.

---

## 9. Mutations and `room_presence`

When an object mutates, its replacement object can have a different `room_presence`. This is how the room view updates automatically:

```lua
-- wardrobe.lua (closed)
room_presence = "A towering wardrobe lurks in the corner like a dark sentinel, its doors firmly shut."

-- wardrobe-open.lua (opened)
room_presence = "A towering wardrobe stands open in the corner, its doors flung wide to reveal the dark interior."
```

When the player opens the wardrobe, the mutation replaces the object. The next `look` picks up the new `room_presence`. No room rewrite needed — the room's `contents` still lists "wardrobe" (or "wardrobe-open" if the ID changes), and the registry returns the current version.

If the mutation uses `becomes` with a new ID, the room's `contents` must be updated by the mutation engine. If the object is mutated in-place (same ID, different properties), the `room_presence` change is automatic.

---

## 10. Interaction with Room Template

The room template (`src/meta/templates/room.lua`) does not need changes. The template provides structural defaults. The dynamic composition is an engine behavior, not a template property.

However, the template documentation should note that room `description` must follow the permanent-features-only rule.

---

## 11. What This Means for Authors

### For Room Authors

1. **`description`** = permanent features only. Walls, floor, ceiling, atmosphere, light, smell. NEVER reference any object in `contents`.
2. **`contents`** = ordered list of object IDs, most prominent first.
3. **No `on_look` needed** for standard rooms. The engine composes the view.
4. **Exits** are unchanged — still inline in the room definition.

### For Object Authors

1. **Add `room_presence`** to every object that can appear in a room. A complete sentence describing how it looks at a glance from across the room.
2. **`room_presence` must NOT reference other movable objects.** Position relative to walls, corners, floor — never "beside the bed" or "near the wardrobe".
3. **`description`** is the detailed examine text. Can be as long and evocative as needed.
4. **`on_look`** reveals surface contents selectively based on visibility rules.
5. **Mutated variants** should have their own `room_presence` reflecting their new state.

---

## 12. File Changes Required

### Room File Updates
- `src/meta/world/start-room.lua` — remove object references from `description`, remove custom `on_look` (engine handles it)

### Object File Updates
All objects that appear in rooms need a `room_presence` field:
- `src/meta/objects/bed.lua`
- `src/meta/objects/nightstand.lua`
- `src/meta/objects/vanity.lua`
- `src/meta/objects/wardrobe.lua`
- `src/meta/objects/rug.lua`
- `src/meta/objects/window.lua`
- `src/meta/objects/curtains.lua`
- `src/meta/objects/chamber-pot.lua`
- (Plus their mutated variants where applicable)

### Engine Updates
- `src/engine/loop/init.lua` — update `cmd_look` to use `compose_room_view` pattern (iterate `room.contents`, use `room_presence`, render exits)

### Documentation Updates
- `docs/architecture/src-structure.md` — note dynamic composition pattern
- `docs/design/containment-constraints.md` — add surface visibility rules
- `docs/design/room-exits.md` — update section 9 about `on_look`
- `docs/contributing/objects.md` — add `room_presence` field, authoring rules

---

## 13. Open Questions

1. **Object ordering across mutations.** When an object mutates and the ID changes, does the ordering in `room.contents` update? The mutation engine should handle this.
2. **Ambient light from objects.** A lit candle changes room ambiance. Should objects have a `room_ambient` field that modifies the room atmosphere? Future design.
3. **Spatial relationships.** "The curtains hang in front of the window" — spatial relationships between objects are not modeled. This is a future concern; for now, each object's `room_presence` is independent.
4. **Object grouping.** In rooms with many objects, should they be grouped? ("Several pieces of furniture line the walls.") Future UX design.

---

*Bart — Architect*
