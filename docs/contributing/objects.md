# Creating New Objects

**Author:** Brockman (Documentation)  
**Date:** 2026-03-20  
**Status:** Contributor Guide  
**Related:** `docs/architecture/object-model.md`, `docs/architecture/src-structure.md`

---

## Overview

This guide walks you through creating a new object from zero to playable. Objects are the core content of the MMO engine — every item, container, room, and creature is an object.

Objects live in `src/meta/objects/` as `.lua` files. Each file defines one object's properties, interactions, and mutations.

---

## Step 1: Plan Your Object

Before writing code, ask yourself:

- **What is it?** A sword, a room, a door, a creature?
- **What can players do with it?** Pick it up? Put things in it? Break it? Use it?
- **Does it transform?** (mutations) — e.g., mirror breaks, door unlocks, letter is read
- **Can it be crafted?** Does it appear as a recipe result?
- **What's its size and weight?** Can it fit in a sack?
- **What categories does it belong to?** (weapon, fragile, food, book, etc.)

Write this down in a comment. Example:

```lua
-- A simple iron sword
-- - Size: 3 (medium)
-- - Player can: take it, drop it, use it to fight
-- - Mutations: break (becomes broken sword, spawns rusty hilt)
-- - Categories: weapon, bladed, metal
```

---

## Step 2: Create the File

Create a file in `src/meta/objects/` named after your object's ID (lowercase, dashes).

```bash
src/meta/objects/iron-sword.lua
src/meta/objects/ancient-library.lua
src/meta/objects/leather-sack.lua
```

Open it in your editor and start with the skeleton:

```lua
-- src/meta/objects/your-object-id.lua

return {
  id          = "your-object-id",
  name        = "a descriptive name",
  keywords    = { "keyword", "another", "shorthand" },
  room_presence = "A descriptive name sits against the wall.",
  description = "Detailed description shown when examined.",
}
```

---

## Step 3: Fill in Required Fields

### `id` (required, string)
Unique identifier. Used in containment, mutations, and lookups. Use lowercase with dashes (no spaces, underscores, or special characters).

```lua
id = "iron-sword"
```

### `name` (required, string)
Display name. Can be verbose and include articles.

```lua
name = "an iron sword"
```

### `keywords` (required, array)
Search terms. Include the name, synonyms, and related parts. Players type these to interact.

```lua
keywords = { "sword", "iron sword", "blade", "iron" }
```

Tip: Include the ID (or its components) and common synonyms. "A sword" might be referenced as `take sword`, `wield iron`, or `examine blade`.

### `description` (required, string)
Prose shown when a player examines the object directly. Should evoke atmosphere and hint at interactions. This is the DETAILED view — what the player sees when they specifically examine this object.

**Important:** The `description` must NOT reference other movable objects by name. Position the object relative to permanent features only (walls, floor, corners). See the `room_presence` field below.

```lua
description = "A practical iron sword, its blade well-maintained. "
           .. "The handle is wrapped in worn leather. It feels balanced in your hand."
```

### `room_presence` (required for room objects, string)
A complete prose sentence describing how this object appears at a glance from across the room. This is what players see in the room view — not the detailed examine text, but the first-impression sentence.

```lua
room_presence = "A practical iron sword leans against the wall near the doorway."
```

**Rules for `room_presence`:**
1. Must be a complete sentence (capitalised, punctuated).
2. Must NOT reference other movable objects ("beside the bed", "near the wardrobe" — NO). Position relative to permanent features: walls, corners, floor, ceiling.
3. Should convey scale, character, and spatial position.
4. Mutated variants should have their own `room_presence` reflecting their new state.

If omitted, the engine falls back to "There is {name} here." — functional but lifeless. All authored room objects should have this field.

---

## Step 4: Add Physical Properties

### `size` (required, number 1–6)
Physical tier. Determines if it fits in containers.

```lua
-- Size tiers:
-- 1 = tiny (coin, key, ring)
-- 2 = small (book, dagger, mirror)
-- 3 = medium (sword, lantern, sack)
-- 4 = large (chest, backpack, drawer)
-- 5 = huge (desk, wardrobe)
-- 6 = massive (elephant, boulder, room)

size = 3  -- a sword is medium
```

### `weight` (optional, number, default 0)
Burden units. Use for Layer 5 containment validation.

```lua
weight = 8  -- fairly heavy
```

Rough guide:
- Lightweight (1–3): paper, coin, key
- Medium (4–10): sword, book, small tool
- Heavy (11–20): chest, pony saddle
- Very heavy (20+): boulder, statue

### `categories` (optional, array, default {})
Semantic tags. Used in Layer 4 (accepts/rejects).

```lua
categories = { "weapon", "bladed", "metal", "valuable" }
```

Common categories:
- **Types:** weapon, tool, furniture, clothing, container, book, food, drink, key, decoration
- **Properties:** fragile, reflective, metal, wood, paper, living, food, poison, fire, water
- **Status:** broken, locked, open, sealed

---

## Step 5: Decide if It's a Container

If players can put things inside (or on top of), add a `container` field.

### Single-Surface Container

```lua
container = {
  max_item_size    = 3,     -- tier 3 and smaller fit through opening
  capacity         = 10,    -- total size-tier units it holds
  weight_capacity  = 50,    -- burden units (optional)
  contents         = {},    -- starts empty (engine populates at runtime)
}
```

### Multi-Surface Container

For objects with distinct zones (desk: top, inside drawer, underneath):

```lua
container = {
  surfaces = {
    top = {
      max_item_size    = 4,
      capacity         = 12,
      weight_capacity  = 100,
      accepts          = { "writing-utensil", "document" },
      contents         = {},
    },
    inside = {
      max_item_size    = 3,
      capacity         = 6,
      weight_capacity  = 40,
      contents         = {},
    },
  }
}
```

### Optional: `accepts` and `rejects`

```lua
container = {
  max_item_size    = 2,
  capacity         = 20,
  accepts          = { "book", "scroll", "tome" },  -- whitelist
  contents         = {},
}
```

If `accepts` is present, only items with matching categories fit. If `rejects` is present, items with those categories are rejected. Most containers have neither (accept anything).

---

## Step 6: Add Mutations (Optional)

If the object transforms when verbs are applied (BREAK, OPEN, READ, etc.), add a `mutations` table.

```lua
mutations = {
  break = {
    becomes = "iron-sword-broken",  -- object ID it becomes
    spawns  = { broken_piece = 1 },  -- optional: objects created
  }
}
```

This means: when the BREAK verb is applied to this sword, it becomes a broken sword and spawns a broken piece.

**Important:** You must create the target object file too. In this case, create `src/meta/objects/iron-sword-broken.lua`.

### Multiple Mutations

An object can have multiple mutations:

```lua
mutations = {
  break = { becomes = "iron-sword-broken", spawns = { piece = 1 } },
  rust  = { becomes = "iron-sword-rusty" },
  sharpen = { becomes = "iron-sword" },  -- maybe cycling?
}
```

Each mutation is independent. A verb handler looks up the mutation and triggers it if present.

---

## Step 7: Add Crafting Recipes (Optional)

If the object is created by a crafting verb (SEW, FORGE, BREW, etc.), add a `crafting` table.

```lua
crafting = {
  forge = {
    consumes = { iron_ingot = 1, leather_strip = 1 },
    produces = { iron_sword = 1 },
  }
}
```

This means: the FORGE verb can consume 1 iron ingot and 1 leather strip to produce 1 iron sword.

If `produces` is omitted, the default is one copy of the object itself:

```lua
crafting = {
  sew = {
    consumes = { cloth = 2, thread = 1 },
    -- produces = { stitched_tunic = 1 },  -- implicit
  }
}
```

---

## Step 8: Add Interactive Handlers (Optional)

Custom `on_look`, `on_enter`, `on_exit` handlers let you run code when players interact.

### `on_look`

Runs when a player examines the object. Overrides the default `description`.

```lua
on_look = function(ctx)
  if ctx.object.location == "abandoned-library" then
    return "The sword lies here, dust-covered. Strange runes glow faintly along the blade."
  else
    return "A practical iron sword, its blade well-maintained."
  end
end
```

### `on_enter` (Rooms Only)

Runs when a player enters a room.

```lua
on_enter = function(ctx)
  return "You step into the ancient library. The air smells of old leather and forgotten knowledge."
end
```

### `on_exit` (Rooms Only)

Runs when a player leaves a room.

```lua
on_exit = function(ctx)
  return "You leave the library behind, its silence following you."
end
```

---

## Step 9: Use Templates for Reuse

If you're creating multiple similar objects (many weapons, many books), define a template once and reuse it.

### Create a Template

```lua
-- src/meta/templates/weapon.lua
return {
  size        = 3,
  weight      = 8,
  categories  = { "weapon" },
  portable    = true,
}
```

### Use the Template

```lua
-- src/meta/objects/iron-sword.lua
return {
  template    = "weapon",    -- inherits size, weight, categories
  id          = "iron-sword",
  name        = "an iron sword",
  -- ... override as needed
  weight      = 7,           -- slightly lighter
}

-- src/meta/objects/wooden-sword.lua
return {
  template    = "weapon",
  id          = "wooden-sword",
  name        = "a wooden sword",
  -- inherits size=3, weight=8, categories={weapon}
}
```

---

## Step 10: Validate and Test

Run a syntax check on your file:

```bash
lua -c src/meta/objects/your-object.lua
```

Check:
- [ ] ID is lowercase with dashes (no spaces, underscores, special chars)
- [ ] All required fields are present: `id`, `name`, `keywords`, `description`, `size`
- [ ] `room_presence` is set for objects that appear in rooms (complete sentence, no references to other movable objects)
- [ ] `keywords` is an array (not a string)
- [ ] `size` is a number between 1–6
- [ ] If `container` is present, it has `max_item_size`, `capacity`, and `contents`
- [ ] If mutations are present, the target objects exist or are created
- [ ] Description is evocative and hints at interactions

---

## Complete Example: Simple Item

```lua
-- src/meta/objects/iron-sword.lua
-- A basic iron sword
-- - Size: 3 (medium)
-- - Can be picked up and used
-- - Breaks if struck hard enough

return {
  id          = "iron-sword",
  name        = "an iron sword",
  keywords    = { "sword", "iron", "blade", "weapon" },
  room_presence = "An iron sword leans against the wall, its blade catching the dim light.",
  description = "A practical iron sword, its blade well-maintained. "
             .. "The handle is wrapped in worn leather. It feels balanced in your hand.",
  
  size        = 3,
  weight      = 8,
  categories  = { "weapon", "bladed", "metal" },
  portable    = true,
  
  mutations = {
    break = {
      becomes = "iron-sword-broken",
      spawns  = { rust_chunk = 1 },
    }
  }
}
```

---

## Complete Example: Container with Surfaces

```lua
-- src/meta/objects/oak-desk.lua
-- A desk with storage
-- - Size: 5 (huge, not portable)
-- - Surfaces: top (for writing), inside (drawer), underneath (leg space)
-- - Top accepts writing utensils and documents
-- - Inside has limited space
-- - Underneath is open

return {
  id          = "oak-desk",
  name        = "an oak desk",
  keywords    = { "desk", "oak", "furniture", "table", "writing desk" },
  description = "A sturdy oak desk with a polished top. A single drawer is "
             .. "carved into the front. There's ample space underneath for a chair.",
  
  size        = 5,
  weight      = 40,
  categories  = { "furniture", "wood", "storage" },
  portable    = false,
  
  container = {
    surfaces = {
      top = {
        max_item_size    = 4,
        capacity         = 12,
        weight_capacity  = 100,
        accepts          = { "writing-utensil", "document", "small-object" },
        contents         = {},
      },
      inside = {
        max_item_size    = 3,
        capacity         = 6,
        weight_capacity  = 40,
        contents         = {},
      },
      underneath = {
        max_item_size    = 5,
        capacity         = 8,
        weight_capacity  = 75,
        contents         = {},
      },
    }
  }
}
```

---

## Naming Conventions

| What | Convention | Examples |
|------|-----------|----------|
| Object IDs | Lowercase, dashes | `iron-sword`, `oak-desk`, `ancient-library` |
| Object names | Natural English, lowercase | `"an iron sword"`, `"the oak desk"` |
| Keywords | Lowercase, natural | `{ "sword", "iron", "blade" }` |
| Templates | Lowercase, descriptive | `weapon`, `furniture`, `small-item` |
| Categories | Lowercase, semantic | `{ "weapon", "bladed", "metal" }` |

---

## Where Objects Go

- **Regular objects:** `src/meta/objects/your-object-id.lua`
- **Templates:** `src/meta/templates/template-name.lua`
- **Rooms:** `src/meta/objects/` (rooms are objects with `container` and no `portable`)

---

## Summary

To create a new object:

1. **Plan** what it is and what players can do with it
2. **Create** a file in `src/meta/objects/`
3. **Fill** required fields: `id`, `name`, `keywords`, `description`, `size`
4. **Add** `room_presence` — a complete sentence for the room view (NEVER reference other movable objects)
5. **Add** physical properties: `weight`, `categories`
6. **Define** containment if applicable
7. **Add** mutations if it transforms (each mutated variant needs its own `room_presence`)
8. **Add** crafting if it's created by recipes
9. **Add** handlers for rich interactivity
10. **Use** templates to reduce repetition
11. **Validate** syntax and dependencies

Objects are declarative and composable. They're designed to be read, understood, and generated by both humans and LLMs.

---

*Brockman — Documentation*
