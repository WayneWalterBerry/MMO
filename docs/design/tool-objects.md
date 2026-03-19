# Tool Objects Design Pattern

> "A match is not just a match. It is the key to a puzzle, the enabler of verbs, the bridge between player intent and world response. And also a fire hazard." — Comic Book Guy

## Overview

Tool objects are items that **enable verb actions on other objects**. They are the bridge between what the player wants to do and what the world allows. Without the right tool, certain mutations are impossible — creating the foundation for inventory puzzles.

This is not a new concept. Zork had the torch. Monkey Island had the rubber chicken with a pulley in the middle. What IS new is the way tools integrate with the mutation system: the tool provides a **capability**, and the target **requires** that capability.

## The Tool Convention

### On the Target: `requires_tool`

Any object mutation can declare a required tool capability:

```lua
-- candle.lua
mutations = {
    light = {
        becomes = "candle-lit",
        requires_tool = "fire_source",
        message = "The wick catches the flame...",
        fail_message = "You have nothing to light it with.",
    },
},
```

The `requires_tool` field is a **capability string**, not an item ID. This means ANY object that provides `"fire_source"` can satisfy the requirement. This is critical for extensibility — a tinderbox, a torch, a fire spell, or a friendly dragon could all provide `"fire_source"`.

### On the Tool: `provides_tool`

Tool objects declare the capability they provide:

```lua
-- matchbox.lua
provides_tool = "fire_source",
charges = 3,
on_tool_use = {
    consumes_charge = true,
    when_depleted = "matchbox-empty",
    use_message = "You strike a match...",
    depleted_message = "That was your last match.",
},
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `provides_tool` | string | The capability this tool provides (e.g., `"fire_source"`, `"lock_pick"`, `"cutting_edge"`) |
| `charges` | number | How many uses the tool has. `nil` or absent = infinite uses. |
| `on_tool_use.consumes_charge` | boolean | Whether each use decrements `charges` |
| `on_tool_use.when_depleted` | string | Object ID to mutate into when `charges` reaches 0 |
| `on_tool_use.use_message` | string | Message shown when the tool is used (before the target's mutation message) |
| `on_tool_use.depleted_message` | string | Additional message appended when the last charge is consumed |

## Engine Resolution Flow

When the player types a verb + target (e.g., "light candle"):

```
1. Parser identifies verb = "light", target = "candle"
2. Engine finds candle object, looks up mutations.light
3. Engine sees requires_tool = "fire_source"
4. Engine searches player inventory for any object where provides_tool == "fire_source"
5. IF NOT FOUND:
   → Display fail_message ("You have nothing to light it with.")
   → STOP
6. IF FOUND (e.g., matchbox):
   a. Check tool.charges > 0 (if charges property exists)
   b. IF charges == 0: "The matchbox is empty." → STOP
   c. Display tool.on_tool_use.use_message
   d. Decrement tool.charges (rewrite the tool's code per D-14)
   e. IF tool.charges == 0:
      - Display tool.on_tool_use.depleted_message
      - Mutate tool → tool.on_tool_use.when_depleted (full code rewrite)
   f. Execute target mutation: candle → candle-lit (full code rewrite)
   g. Display target mutation message
```

### Key Design Decisions in This Flow

1. **The tool is consumed BEFORE the target mutates.** If the match is struck, it's gone regardless of what happens next. This is how fire works.

2. **Capability matching, not item matching.** The engine searches for `provides_tool == "fire_source"`, not `id == "matchbox"`. This keeps the design extensible.

3. **Charges are rewritten per D-14.** When a match is consumed, the engine rewrites `matchbox.lua` with `charges = 2` (or 1, or 0). The code IS the state. There are no hidden counters.

4. **Depletion is a mutation.** When charges hit 0, the tool undergoes a full code-rewrite mutation to its depleted variant. `matchbox.lua` is replaced wholesale by `matchbox-empty.lua`. The old matchbox ceases to exist.

## Tool vs. Key: Two Complementary Patterns

The existing `requires = "brass-key"` pattern on door exits uses **specific item matching** — only the brass key opens this specific lock. This is correct for keys, which are unique to their locks.

Tools use **capability matching** — any `fire_source` can light any `fire_target`. These patterns coexist:

| Pattern | Field | Matches | Example |
|---------|-------|---------|---------|
| **Key** | `requires = "item-id"` | Specific item by ID | Brass key → bedroom door |
| **Tool** | `requires_tool = "capability"` | Any item with matching capability | Any fire source → any candle |

A single object can be BOTH. A magical torch might be a specific key (`requires = "phoenix-torch"`) for one puzzle AND a general fire source (`provides_tool = "fire_source"`) for any lighting need.

## Known Tool Capabilities

| Capability | Description | Known Providers | Known Consumers |
|------------|-------------|-----------------|-----------------|
| `fire_source` | Can ignite flammable things | matchbox (3 charges) | candle (LIGHT verb) |
| `cutting_edge` | Can cut/slice things | knife, glass shard | rope, fabric, food (CUT verb) |
| `injury_source` | Can draw blood from self | knife, pin | player (CUT SELF / PRICK SELF verb) |
| `writing_instrument` | Can write/mark things | pen, pencil, blood | paper (WRITE verb) |
| `sewing_tool` | Can stitch materials together | needle | cloth (SEW verb, requires sewing skill) |
| `lockpick` | Can pick locks | pin (with lockpicking skill) | locked doors (PICK LOCK verb) |
| *(future)* `prying_tool` | Can lever/pry things open | *(crowbar, glass shard)* | *(stuck lid, loose floorboard)* |

Note: the glass shard (already exists as `glass-shard.lua`) is a natural candidate for `cutting_edge` and `prying_tool` capabilities in the future. Objects can provide multiple capabilities via a list: `provides_tool = {"cutting_edge", "prying_tool"}`.

---

## Dynamic Mutation Pattern

> "The words on the paper ARE the paper. The paper's code is rewritten to include whatever the player chose to write. This is code-as-state taken to its logical extreme." — Comic Book Guy

### The Problem

Most mutations swap one pre-built file for another (`candle.lua` → `candle-lit.lua`). But what happens when the player types something the designer cannot predict? The paper's WRITE mutation must incorporate **arbitrary player text** into the object definition.

### The Solution: Dynamic Mutation

When a mutation is declared with `dynamic = true`, the engine does NOT look up a pre-built variant file. Instead, it generates a new object definition at runtime by:

1. Taking the current object definition as a template
2. Applying the mutator function (identified by `mutator` field) to transform it
3. Baking the player's input into the new definition
4. Writing the new definition as the object's code (per D-14)

```lua
-- paper.lua (before writing)
mutations = {
    write = {
        requires_tool = "writing_instrument",
        dynamic = true,
        mutator = "write_on_surface",
        message = "You write carefully on the paper.",
        fail_message = "You have nothing to write with.",
    },
},
```

After the player types `WRITE "hello world" ON paper WITH pen`, the engine generates:

```lua
-- paper.lua (AFTER writing — dynamically generated)
return {
    id = "paper",
    name = "a sheet of paper with writing",
    keywords = {"paper", "sheet", "page", "note", "written paper"},
    description = "A sheet of cream-coloured paper with writing on it.",
    written_text = "hello world",
    writable = false,  -- already written on (pen ink is permanent)
    -- ... rest of object definition ...
    on_look = function(self)
        return "A sheet of paper with writing on it. It reads:\n\n  \"" .. self.written_text .. "\""
    end,
}
```

### Key Rules

1. **No variant files.** Dynamic mutations do NOT use `becomes = "some-id"`. The mutation IS the code generation.
2. **Player input is sanitized and baked in.** The engine must sanitize player text before embedding it in Lua source code. No code injection.
3. **The mutated object is a complete standalone definition.** Just like file-per-state mutations, the result is a full object table — no partial patches.
4. **Future writes depend on tool type.** Pen ink is permanent (paper becomes non-writable after first write). Pencil is erasable (future ERASE verb can restore writability). Blood is permanent and disturbing.
5. **The `mutator` field names a registered engine function.** The engine maintains a registry of mutator functions (`write_on_surface`, etc.) that know how to transform object definitions.

### When to Use Dynamic vs. Static Mutation

| Pattern | Use When | Example |
|---------|----------|---------|
| Static (`becomes = "id"`) | Finite, known states | candle → candle-lit |
| Dynamic (`dynamic = true`) | Player-generated content | WRITE words ON paper |

---

## Skill-Gated Tools

> "The pin is a pin. Unless you know lockpicking, in which case it is a key, a lockpick, and a pin. The tool doesn't change — the player does." — Comic Book Guy

### The Problem

Some tools should unlock new capabilities as the player gains skills. A pin is just a sharp object to a novice. To a trained lockpick, it's a way past any locked door.

### The Pattern: `skill_tools`

Objects declare **base capabilities** via `provides_tool` and **skill-gated capabilities** via `skill_tools`:

```lua
-- pin.lua
provides_tool = "injury_source",        -- always available
skill_tools = {
    lockpicking = "lockpick",            -- available when player has lockpicking skill
},
```

### Engine Resolution

When the engine searches for a tool capability, it checks:

1. `object.provides_tool` — always available (string or list)
2. `object.skill_tools` — check each key against `player.skills`. If the player has the skill, add the corresponding capability to the object's effective tool set.

```
Effective capabilities = provides_tool + (skill_tools where player has skill)
```

### Example: Pin

| Player Skills | Pin Provides | Available Actions |
|---------------|-------------|-------------------|
| (none) | `injury_source` | PRICK SELF WITH pin → blood |
| lockpicking | `injury_source`, `lockpick` | PRICK SELF or PICK LOCK WITH pin |

### Design Rules

1. **Skills ADD capabilities; they never remove base ones.** The pin always provides `injury_source`, even with lockpicking.
2. **Skill names are simple strings.** `"lockpicking"`, `"sewing"`, `"crafting"`. No numeric levels for V1.
3. **The skill_tools table is declarative.** The engine reads it; the object doesn't execute skill checks itself.
4. **Multiple skills can gate different capabilities on the same object.** A Swiss army knife of the medieval era.

---

## Multi-Capability Tools

> "The knife cuts. The knife wounds. It does both because those are simply two applications of a sharp edge. The engine resolves by context, not by configuration." — Comic Book Guy

### The Problem

Some tools provide more than one capability. The knife is both a `cutting_edge` (CUT rope, CUT cloth) and an `injury_source` (CUT SELF → blood). How does the engine know which capability the player wants?

### The Pattern

Objects declare multiple capabilities as a list:

```lua
-- knife.lua
provides_tool = {"cutting_edge", "injury_source"},
```

### Engine Resolution: By Verb Context

The engine resolves capability selection based on the **verb + target combination**, not by asking the player to choose:

| Player Command | Verb | Target | Required Capability | Resolved |
|---------------|------|--------|-------------------|----------|
| CUT rope WITH knife | CUT | rope | `cutting_edge` | rope.mutations.cut.requires_tool |
| CUT SELF WITH knife | CUT | SELF | `injury_source` | player.mutations.cut_self.requires_tool |
| PRICK SELF WITH knife | PRICK | SELF | `injury_source` | player.mutations.prick_self.requires_tool |

The target object's mutation declares which capability it requires. The engine checks whether the tool provides that specific capability. No ambiguity — the target decides what it needs.

### Design Rules

1. **List capabilities in `provides_tool` as an array.** The engine iterates and checks for matches.
2. **Never ask "which capability?"** The target's `requires_tool` field resolves the choice automatically.
3. **A tool can provide capabilities from different categories.** Knife is both tool and weapon. Glass shard is both cutting edge and prying tool.
4. **Capabilities are independent.** Using the knife to cut rope doesn't affect its ability to draw blood.

---

## Crafting Pattern

> "SEW cloth WITH needle. Skill plus tool plus material equals product. The first true crafting mechanic, and I refuse to call it a 'recipe system' because that implies it was designed by committee." — Comic Book Guy

### The Problem

Tools like the needle don't just enable mutations on existing objects — they CREATE new objects from materials. This is fundamentally different from the candle puzzle (tool enables state change) and the paper puzzle (tool enables content injection). Crafting is: **skill + tool + materials → new product**.

### The Pattern: `crafting` Block

Craftable materials declare their crafting recipes in a `crafting` table:

```lua
-- cloth.lua
crafting = {
    sew = {
        consumes = {"cloth", "cloth"},          -- materials consumed
        requires_tool = "sewing_tool",          -- tool capability needed
        requires_skill = "sewing",              -- player skill needed
        becomes = "terrible-jacket",            -- product created
        message = "You stitch the pieces together...",
        fail_message_no_tool = "You have nothing to sew with.",
        fail_message_no_skill = "You wouldn't know where to begin.",
    },
},
```

### Engine Resolution Flow

```
1. Player: SEW cloth WITH needle
2. Engine finds cloth, looks up crafting.sew
3. Check requires_tool = "sewing_tool" → search inventory → find needle ✓
4. Check requires_skill = "sewing" → check player.skills → has sewing? ✓ or ✗
5. Check consumes = {"cloth", "cloth"} → player has 2 cloth in inventory? ✓ or ✗
6. IF all checks pass:
   a. Remove consumed materials from inventory
   b. Use tool (no charge consumed for needle)
   c. Create product object ("terrible-jacket")
   d. Place product in player inventory
   e. Display message
7. IF any check fails: display appropriate fail message
```

### Key Differences from Mutation

| Aspect | Mutation | Crafting |
|--------|----------|----------|
| Materials | Target object transforms | Multiple materials consumed |
| Product | Target becomes something else | New object created |
| Reversibility | Some mutations reversible (open/close) | Crafting is permanent |
| Skill | Usually not required | Often requires a skill |

### Design Rules

1. **Crafting consumes materials.** The input cloth objects are destroyed. This is permanent.
2. **The tool is NOT consumed** (unless it has charges). Needles last forever.
3. **Skills gate crafting.** You can't just mash cloth together — you need to know how to sew.
4. **The `crafting` block lives on the material, not the tool.** Cloth knows it can be sewn; the needle just provides the capability.
5. **Products are pre-built objects.** `terrible-jacket.lua` already exists as a file. Crafting uses static products, not dynamic mutation (unlike paper writing).

## The Matchbox: First Tool Implementation

### Object: `matchbox.lua`

- **Location:** Inside the nightstand drawer (nightstand.surfaces.inside)
- **Charges:** 3 matches
- **Provides:** `fire_source`
- **Depleted form:** `matchbox-empty.lua` (useless junk, can be discarded or kept as a souvenir of poor resource management)

### Design Rationale

**Why 3 matches?** Enough to light the candle and have margin for error. If the player somehow wastes all 3 without lighting the candle, they're in trouble — but the game should provide an alternative path (perhaps the window/curtains for daytime light). Three is the classic fairy-tale number. It feels right. One match is cruel. Five is generous. Three is *interesting*.

**Why the nightstand drawer?** The candle sits ON TOP of the nightstand. The matches are IN the drawer. This creates a micro-puzzle: you see the candle, want to light it, need to figure out where matches might be. The nightstand is the obvious first place to look — rewarding logical thinking, not pixel-hunting. The drawer is closed by default, requiring an OPEN action first. This is a two-step discovery (open drawer → find matches) that teaches the player the containment system.

**Why not under the rug?** The brass key is already there. One hidden object per rug is the legal limit in good game design. Also, matches under a rug make no sense — they'd be crushed.

## The Light Puzzle: First Puzzle of the Game

### Flow (Nighttime Start)

```
1. Player wakes in dark bedroom
   → Room description mentions darkness, shapes felt more than seen
   → The nightstand is described as "beside the bed" (reachable by feel)

2. Player: OPEN NIGHTSTAND (or OPEN DRAWER)
   → Nightstand mutates to nightstand-open
   → "Inside the drawer: a small matchbox"

3. Player: TAKE MATCHBOX
   → Matchbox moves to player inventory

4. Player: TAKE CANDLE (from nightstand top — described even in dark)
   → Candle moves to player inventory

5. Player: LIGHT CANDLE
   → Engine checks requires_tool = "fire_source"
   → Finds matchbox in inventory (provides_tool = "fire_source", charges = 3)
   → Strikes match (charges → 2), candle mutates to candle-lit
   → Room is now illuminated (candle-lit.casts_light = true)
   → Player can now see the full room description with all objects

6. Player explores the now-visible room
   → Finds the rug, looks under it, discovers brass key
   → Uses brass key on the door... adventure continues
```

### Alternative Paths

- **Daytime:** Open curtains → `curtains-open` lets natural light in. No match needed for basic visibility, but candle still useful for carrying light to dark rooms later.
- **Match wasted:** Player lights candle, extinguishes it, relights (2 matches left). If they use all 3 without keeping the candle lit, they need the daytime curtain path. This is a soft failure — inconvenient, not softlocking.
- **Candle not taken:** Player can light the candle while it sits on the nightstand. It illuminates the room either way. Taking it is only needed for carrying light elsewhere.

### Dark Room Rules (Engine Requirement)

When a room has no active light source (`casts_light = true` object present):

1. Room description shifts to a "dark" variant (felt textures, sounds, spatial orientation)
2. Objects with `room_presence` are NOT shown (you can't see them)
3. Objects explicitly described as touchable/nearby (nightstand "beside the bed") can still be interacted with
4. LOOK commands return "It is too dark to see clearly."
5. TAKE, OPEN, and other tactile verbs work on known/nearby objects
6. The player is not helpless — they can feel around — but they cannot see details

### Anti-Softlock Guarantee

The bedroom CANNOT softlock the player:

- The door to the hallway is already open and unlocked (ajar). The player can leave even in the dark.
- The matchbox has 3 charges — enough for multiple attempts.
- Daytime provides natural light through the window/curtains as an alternative.
- Even in total darkness, the player can navigate by feel to the exit.

This follows the anti-pattern rule from `game-design-foundations.md`: never hide critical-path items without a hint, and never create unwinnable states through resource depletion.

## Implementation Notes for Bart

1. **Engine must search inventory for capability matches.** When processing `requires_tool`, iterate player inventory and check `provides_tool` on each item.

2. **Charge decrement is a code rewrite.** Per D-14, the engine rewrites the matchbox's `charges` field in its Lua source. This is not a runtime variable — it's a literal code change.

3. **Tool messages compose with target messages.** Display order: tool.use_message → target.message. If the tool is depleted, append depleted_message after use_message.

4. **`provides_tool` can be a string or a list.** For simple tools (matchbox → `"fire_source"`), a string suffices. For multi-purpose tools (glass shard → `{"cutting_edge", "prying_tool"}`), use a list. Engine should handle both.

5. **`casts_light` is a room-level query.** The engine should check all objects in the room (including on surfaces, in player inventory if present) for `casts_light = true` to determine room illumination state.
