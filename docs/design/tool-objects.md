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
-- match-lit.lua (the lit match, after striking)
provides_tool = "fire_source",
consumable = true,
burn_remaining = 30,
on_consumed = {
    message = "The match flame reaches your fingers...",
    becomes = nil,
},
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `provides_tool` | string or list | The capability this tool provides (e.g., `"fire_source"`, `"lock_pick"`, `"cutting_edge"`) |
| `consumable` | boolean | Whether this tool is consumed after use (e.g., lit match is consumed when used to LIGHT) |
| `burn_remaining` | number | Game seconds until auto-consumption (for burning/timed items) |
| `on_consumed.message` | string | Message displayed when the item is consumed |
| `on_consumed.becomes` | string or nil | Object to replace with when consumed (nil = destroyed entirely) |
| `charges` | number | How many uses the tool has. `nil` or absent = infinite uses. *(Note: prefer container-with-contents for discrete items like matches)* |
| `on_tool_use.use_message` | string | Message shown when the tool is used (before the target's mutation message) |

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
6. IF FOUND (e.g., match-lit):
   a. Display target mutation message
   b. Execute target mutation: candle → candle-lit (full code rewrite)
   c. IF tool.consumable == true:
      - Consume the tool (destroy it or mutate to on_consumed.becomes)
      - Display on_consumed.message (if any)
   d. Room is now illuminated (candle-lit.casts_light = true)
```

### Key Design Decisions in This Flow

1. **Capability matching, not item matching.** The engine searches for `provides_tool == "fire_source"`, not `id == "match-lit"`. This keeps the design extensible. A lighter, a torch, or a fire spell could all satisfy the same requirement.

2. **Consumable tools are destroyed after use.** The lit match provides fire_source once, then it's gone. The fire was transferred to the candle. This is how fire works.

3. **Container contents are the state.** The matchbox's state is its `contents` array. When a match is taken out, the engine rewrites `matchbox.lua` with one fewer entry in contents. No abstract counters — the matches are real objects you can count.

4. **Compound actions precede simple tool use.** Before the player can LIGHT anything, they must first STRIKE a match ON the matchbox. The compound action (STRIKE) produces the tool (match-lit) that the simple action (LIGHT) requires. This creates a natural two-step puzzle.

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
| `fire_source` | Can ignite flammable things | match-lit (consumable, 1 use) | candle (LIGHT verb) |
| `cutting_edge` | Can cut/slice things | knife, glass shard | rope, fabric, food (CUT verb) |
| `injury_source` | Can draw blood from self | knife, pin | player (CUT SELF / PRICK SELF verb) |
| `writing_instrument` | Can write/mark things | pen, pencil, blood | paper (WRITE verb) |
| `sewing_tool` | Can stitch materials together | needle | cloth (SEW verb, requires sewing skill) |
| `sewing_material` | Provides thread/material for sewing | thread | cloth (SEW verb, compound with needle) |
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

## The Matchbox: Container + Striker Surface

> "The matchbox is not a tool. It is a box. A container that holds matches and has a rough strip on the side. The match is the tool — but only AFTER you strike it on the box. Neither alone produces fire. Together, they create the first spark of the game." — Comic Book Guy

### Object: `matchbox.lua`

- **Location:** Inside the nightstand drawer (nightstand.surfaces.inside)
- **Type:** Container (`container = true`) with `has_striker = true`
- **Contents:** 7 individual match objects (`match-1` through `match-7`)
- **Does NOT provide:** `fire_source` — the matchbox is not a tool, it's a container with a striker surface

### Object: `match.lua`

- **Type:** Small item, individual consumable
- **Default state:** Inert. NOT a fire source. Cannot light anything.
- **Mutation:** `STRIKE match ON matchbox` → `match-lit` (requires matchbox with `has_striker`)
- **Key insight:** The match is useless without the matchbox's striker. This is a compound tool dependency.

### Object: `match-lit.lua`

- **Type:** Mutation variant of match (lit state)
- **Provides:** `fire_source` capability
- **Properties:** `casts_light = true` (small radius), `consumable = true`, `burn_remaining = 30`
- **Consumed:** After one LIGHT action on a target, or burns out after ~30 game seconds
- **On burnout:** Match is destroyed (becomes nil)

### Design Rationale

**Why container, not charges?** The old matchbox used an abstract `charges = 3` counter. The new matchbox is a real container with real match objects inside. Each match is a thing you can hold, examine, smell. This is more immersive and more consistent with the "code IS state" philosophy — the matchbox's state is literally its contents array, not a hidden counter.

**Why 7 matches?** This is the first puzzle. Seven provides generous margin for experimentation without making matches feel infinite. The player can waste a few learning the STRIKE verb, light a candle, and still have spares for later rooms. Seven is also a number with fairy-tale resonance.

**Why the nightstand drawer?** The candle sits ON TOP of the nightstand. The matches are IN the drawer (inside the matchbox). This creates a nested discovery: open drawer → find matchbox → open matchbox → find matches. Each step teaches the containment system.

**Why separate match vs. match-lit?** A match that is always a fire source makes no design sense. You can't light a candle by rubbing an unlit match on it. The STRIKE action — match against striker — is the compound action that transforms the match from inert stick to burning tool. This teaches players that some tools require activation.

---

## Compound Tool Actions

> "STRIKE match ON matchbox. Two objects. One verb. One result. This is the compound tool pattern, and it is the first truly interesting thing the player does in this game." — Comic Book Guy

### The Pattern

Some actions require TWO objects working together. Neither alone produces the desired effect:

| Action | Object A | Object B | Result |
|--------|----------|----------|--------|
| STRIKE match ON matchbox | match (inert) | matchbox (has_striker) | match-lit (fire_source) |
| SEW cloth WITH needle + thread | cloth (material) | needle (sewing_tool) + thread (sewing_material) | terrible-jacket |
| WRITE ON paper WITH pen | paper (writable surface) | pen (writing_instrument) | paper-with-writing |

### Engine Resolution

For compound actions involving a target property check (like `has_striker`):

```
1. Player: STRIKE match ON matchbox
2. Engine identifies verb = "strike", subject = match, target = matchbox
3. Engine finds match.mutations.strike
4. Checks requires_property = "has_striker" on target (matchbox)
5. matchbox.has_striker == true → proceed
6. Execute mutation: match → match-lit
7. Display mutation message
```

For compound actions involving multiple tool capabilities:

```
1. Player: SEW cloth WITH needle
2. Engine finds cloth.crafting.sew
3. Checks requires_tool = "sewing_tool" → finds needle in inventory ✓
4. Checks requires_tool = "sewing_material" → finds thread in inventory ✓
5. Checks requires_skill = "sewing" → player has skill? ✓ or ✗
6. Execute crafting
```

### Key Rules

1. **The verb determines the action.** STRIKE, SEW, WRITE — the verb tells the engine which mutation or crafting block to check.
2. **The target resolves requirements.** The match's `strike` mutation declares what it needs (a has_striker surface). The engine checks the target.
3. **Both objects must be accessible.** Player must have both the match and the matchbox (or at least be able to reach them).
4. **Compound actions are NOT the same as simple tool actions.** LIGHT candle requires any fire_source (capability match). STRIKE match ON matchbox requires a specific property on a specific target. Different resolution paths.

---

## Consumable Tools

> "The match burns for thirty seconds. Thirty. Then it reaches your fingers and you learn a lesson about urgency that no tutorial popup could teach." — Comic Book Guy

### The Pattern

Some tools have limited lifespans. They provide their capability temporarily, then are consumed:

```lua
-- match-lit.lua
provides_tool = "fire_source",
consumable = true,
burn_remaining = 30,
on_consumed = {
    message = "The match flame reaches your fingers...",
    becomes = nil,
},
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `consumable` | boolean | This object will be consumed after use or timeout |
| `burn_remaining` | number | Game seconds until auto-consumption (for burning items) |
| `on_consumed.message` | string | Message displayed when the item is consumed |
| `on_consumed.becomes` | string or nil | Object to replace with (nil = destroyed entirely) |

### Consumption Triggers

1. **Tool use:** When a consumable fire_source is used to LIGHT something, the match is consumed. One use.
2. **Timer expiry:** When `burn_remaining` reaches 0, the engine auto-consumes the object.
3. **Manual extinguish:** Player can EXTINGUISH a lit match (becomes nil — wasted).

### Design Rules

1. **Consumables are always destroyed after use.** The lit match doesn't survive lighting the candle. Fire was transferred.
2. **Timer creates urgency.** The player must act within ~30 seconds of striking the match. This is the first time pressure in the game.
3. **Wasted consumables are gone.** If you light a match and let it burn out without using it, that match is lost forever.

---

## Container-with-Contents vs. File-per-State

> "The old matchbox had matchbox.lua and matchbox-empty.lua. Two files for one box with a counter. The new matchbox is a container. Its state IS its contents. When the matches are gone, the box is empty — no mutation needed, no special file. This is how containers should work." — Comic Book Guy

### The Distinction

| Pattern | When to Use | State Tracking | Example |
|---------|-------------|----------------|---------|
| **Container-with-contents** | Object holds discrete, independent sub-objects | `contents` array (items come and go) | Matchbox, sack, wardrobe |
| **File-per-state** | Object has qualitative state changes | Full code rewrite per D-14 | Candle → candle-lit, mirror → mirror-broken |
| **Charges counter** | *(DEPRECATED for matchbox)* | `charges` number field | Old matchbox pattern — replaced by container |

### When Contents > Charges

Use a container with individual objects when:
- Each sub-object has independent identity (a match can be taken, held, examined, struck)
- Sub-objects can exist outside the container (match in inventory, not in matchbox)
- The "charge count" is really a count of discrete things, not an abstract resource
- The sub-objects have their own mutations (match → match-lit)

Use charges when:
- The resource is truly abstract (a wand with 3 charges of magic — there's no "magic charge" object)
- Individual units have no independent identity or behavior
- The resource cannot exist outside the tool

### Why This Matters

The container pattern is more immersive and more consistent with "code IS state":
- **Old:** `matchbox.charges = 3` — hidden counter, abstract
- **New:** `matchbox.contents = {"match-1", "match-2", "match-3", ...}` — you can count the matches. You can take one out and look at it. Each match is real.

The file-per-state pattern is still correct for qualitative changes:
- A candle that is lit is fundamentally different from one that isn't. The entire description, behavior, and capabilities change. This warrants a full code rewrite.
- A matchbox that has 6 matches instead of 7 is not fundamentally different. It's just a container with one fewer item. No rewrite needed.

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

4. Player: OPEN MATCHBOX
   → Matchbox contents revealed: "Inside: 7 wooden matches."

5. Player: TAKE MATCH (from matchbox)
   → One match moves from matchbox.contents to player inventory

6. Player: STRIKE MATCH ON MATCHBOX
   → Engine checks match.mutations.strike
   → Requires matchbox with has_striker = true → found ✓
   → Match mutates to match-lit (provides_tool = "fire_source", casts_light = true)
   → A tiny flame. The clock is ticking (~30 game seconds).

7. Player: LIGHT CANDLE (or LIGHT CANDLE WITH MATCH)
   → Engine checks candle.mutations.light.requires_tool = "fire_source"
   → Finds match-lit in inventory (provides_tool = "fire_source") ✓
   → Candle mutates to candle-lit (casts_light = true)
   → Match-lit is consumed (destroyed)
   → Room is now illuminated. Player can see.

8. Player explores the now-visible room
   → Finds the rug, looks under it, discovers brass key
   → Uses brass key on the door... adventure continues
```

### Alternative Paths

- **Daytime:** Open curtains → `curtains-open` lets natural light in. No match needed for basic visibility, but candle still useful for carrying light to dark rooms later.
- **Match wasted:** Player strikes a match and lets it burn out (~30 seconds). Match is destroyed. They have 6 more. Generous margin for learning.
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
- The matchbox has 7 matches — generous margin for multiple attempts and experimentation.
- Daytime provides natural light through the window/curtains as an alternative.
- Even in total darkness, the player can navigate by feel to the exit.

This follows the anti-pattern rule from `game-design-foundations.md`: never hide critical-path items without a hint, and never create unwinnable states through resource depletion.

## Implementation Notes for Bart

1. **Engine must search inventory for capability matches.** When processing `requires_tool`, iterate player inventory and check `provides_tool` on each item.

2. **Compound actions need two-object resolution.** STRIKE match ON matchbox requires the engine to check the target object for `has_striker` (or whatever property the mutation's `requires_property` demands). This is different from simple capability matching.

3. **Container contents are real objects.** When the player does TAKE match FROM matchbox, the engine removes one match ID from `matchbox.contents` and places the match object in player inventory. The matchbox's code is rewritten per D-14 with the updated contents array.

4. **Consumable timer.** The engine must track `burn_remaining` on lit matches and auto-consume them when the timer expires. This is the first time-sensitive mechanic.

5. **Tool messages compose with target messages.** Display order: tool.use_message → target.message. For compound actions (STRIKE), display the mutation message.

6. **`provides_tool` can be a string or a list.** For simple tools (match-lit → `"fire_source"`), a string suffices. For multi-purpose tools (glass shard → `{"cutting_edge", "prying_tool"}`), use a list. Engine should handle both.

7. **`casts_light` is a room-level query.** The engine should check all objects in the room (including on surfaces, in player inventory if present) for `casts_light = true` to determine room illumination state.

8. **Match instancing.** The matchbox contents reference `match-1` through `match-7`. These are instances of the `match.lua` archetype. The engine should resolve `match-N` IDs to the `match` object definition when creating instances.
