# Creature Inventory & Loot Drops Design Plan

**Author:** Comic Book Guy (Creative Director / Design Department Lead)  
**Date:** 2026-08-15  
**Status:** Design Proposal — Awaiting Wayne Approval  
**Requested By:** Wayne Berry  
**Design Philosophy:** Dwarf Fortress (emergent behavior via metadata) + Material Physics (Principle 9)

---

## Preamble

> "A skeleton doesn't just *stand there*. It wears what it died in. It carries what it owned. Death is not a reset — it's a transition."

This document designs creature inventory and loot drops for the MMO text adventure engine. When a player kills an animated skeleton, what drops? The armor the skeleton wears. The sword in its hand. The coins in its pocket. The system must answer: **What can creatures carry? How do they equip it? What happens when they die?**

The guiding principle: **Creatures are just objects that happen to be animate.** Their inventory system reuses the existing containment model, wear slot model, and hand inventory model. We don't invent new mechanics — we extend metadata-driven behavior to express *creature possession* the same way we express *player possession*.

---

## Table of Contents

1. [Philosophical Foundation](#1-philosophical-foundation)
2. [Inventory Model](#2-inventory-model)
3. [Equipment vs. Carrying](#3-equipment-vs-carrying)
4. [Death Drops](#4-death-drops)
5. [Loot Tables](#5-loot-tables)
6. [Creature Equipment Metadata](#6-creature-equipment-metadata)
7. [Interaction with Existing Systems](#7-interaction-with-existing-systems)
8. [Scaling Path](#8-scaling-path)
9. [Edge Cases](#9-edge-cases)
10. [Implementation Phases](#10-implementation-phases)
11. [Open Questions](#11-open-questions)

---

## 1. Philosophical Foundation

### Principle E1: Creatures Are Objects with Metadata

A creature in the MMO engine is fundamentally an object with `animate = true`. It has:
- A GUID and template
- Sensory properties (on_feel, on_smell, etc.)
- Location tracking (which room, on what surface)
- An FSM with states (alive, dead, etc.)
- Optional: inventory and equipment

Creature inventory is **not** a special system. It's the *same* containment system the player uses, exposed through metadata instead of verbs. The player carries items in hands and inventory slots; a creature carries items in the same slots, just declared in its `.lua` file.

### Principle E2: Metadata Declares Possession

When Wayne writes:
```lua
return {
    id = "skeleton-warrior",
    animate = true,
    inventory = {
        hands = { "steel-sword", "shield" },
        head = "iron-helmet",
        torso = "iron-plate-armor",
        waist = { "coins", "keys" }
    }
}
```

The engine reads this and understands:
- The skeleton wears the helmet and armor (worn equipment, affects combat + sensory)
- The skeleton grips the sword and shield (hand inventory, affects combat capabilities)
- The skeleton carries coins and keys (stored items, drops on death)

No creature-specific code executes. The metadata tells the engine what to simulate.

### Principle E3: Loot is Deterministic (But Can Be Probabilistic)

There are two valid approaches to loot:

1. **Fixed per-creature:** Every warrior skeleton carries the same sword, armor, and 50 coins. Predictable, repeatable, balanceable.
2. **Table-driven:** Each skeleton type has a loot table; death rolls the table to select items.

We support both. Fixed inventory is simpler (Principle 1: simple rules). Loot tables enable variety and can be introduced later as complexity scales. A skeleton in the practice room always has the same sword; a skeleton in a randomized dungeon rolls its loot from a table.

### Principle E4: Death is Mutation

When a creature dies (via the combat/injury system), its `.lua` file mutates from `alive` state to `dead` state. At that moment, the engine **instantiates the dead creature's inventory into the room**. Items that were abstract references in the creature's metadata become real objects present in the room.

This is **Principle D-14 in action:** *Code Mutation IS State Change.* The skeleton file becomes `skeleton-dead.lua`, and the engine instantiates the items it carried into the room floor.

---

## 2. Inventory Model

### Inventory Layers

A creature's inventory has **three distinct layers**:

| Layer | Purpose | Size Constraint | Examples | Persistence |
|-------|---------|-----------------|----------|-------------|
| **Hands** | Actively wielded equipment | Max 2 items (2-hand rule) | Sword, shield, torch | Drops immediately on death |
| **Worn** | Equipped on body slots | 9 slots (head, hands, torso, etc.) | Helmet, armor, gloves | Drops immediately on death |
| **Carried** | Stored in containers/pockets | Capacity-limited per container | Coins, keys, potions | Drops immediately on death |

### Size Constraints

Each layer respects size constraints:

- **Hands:** Limited to items the creature can grip (size 1–3). A rat holds a needle; a wolf holds a sword.
- **Worn:** Limited by slot definition (existing wearable system applies unchanged).
- **Carried:** Limited by container capacity (existing containment system applies unchanged).

### Instantiation vs. Reference

A creature's inventory can be expressed two ways:

**Option A: Direct Reference (Early Phases)**
```lua
inventory = {
    hands = { sword_guid, shield_guid },
    head = helmet_guid,
    carried = { { container = "pouch_guid", items = { coin_guid_1, coin_guid_2 } } }
}
```

The creature's `.lua` references GUIDs of objects that already exist in the registry. The skeleton "carries" pre-existing objects.

**Option B: Generative (Later Phases)**
```lua
inventory = {
    hands = { { template = "steel-sword", count = 1 } },
    head = { template = "iron-helmet", count = 1 },
    carried = { { template = "coins", count = 50 } }
}
```

The creature's `.lua` specifies templates and counts. On instantiation (creature spawns), the engine generates unique objects from these templates. On death, those generated objects drop to the room.

**Decision:** Phase 1 uses **Option A** (direct reference) for simplicity. Phase 2 explores generative inventory if randomized dungeons are built.

### Carrying Capacity Rules

A creature's capacity is **not** a magic number. It emerges from:

1. **Hand slots:** Max 2 items total (enforced, non-negotiable)
2. **Wear slots:** 9 slots, each with 1 item per layer (enforced by existing wearable system)
3. **Carried items:** Must fit into container(s) the creature wears or holds (enforced by existing containment system)

A skeleton with a backpack can carry more. A rat with no hands cannot carry anything. The rules already exist — we just apply them to creatures.

---

## 3. Equipment vs. Carrying

### The Distinction

| Aspect | Equipment (Worn) | Carrying (Stored) |
|--------|------------------|-------------------|
| **System** | Wearable slots | Containment model |
| **Effect on combat** | YES — armor affects damage reduction; weapon affects damage output | NO — items in a pouch don't affect combat |
| **Sensory description** | YES — armor and helmet appear in creature's "look" description | NO — carried items don't appear unless you examine the creature |
| **Drop location** | Drops to ground on death | Drops to ground on death (or stays in container if corpse becomes persistent) |
| **Example** | Iron helmet (head slot), steel sword (hands), armor (torso) | Coins in a leather pouch, keys on a belt ring |

### How Creatures Wear Equipment

A creature *wears* equipment via the **same metadata the player uses**. The `wearable` table on an object includes:

```lua
wearable = {
    slot = "head",
    layer = "outer",
    coverage = 0.8,
    protection_multiplier = 1.0
}
```

When a creature declares `head = "iron-helmet-guid"` in its inventory, the engine:
1. Resolves the helmet object from the registry
2. Checks the helmet's wearable metadata
3. Updates the creature's body_tree coverage in the `head` zone (Combat Phase 1)
4. Includes the helmet in the creature's sensory description: "A skeleton warrior, clad in iron plate and helm, grips a steel sword"

The creature **doesn't wear** equipment through special verb actions. It wears equipment because its `.lua` file declares it. The engine reads the declaration and acts on it immediately.

### Combat Integration

When a creature is engaged in combat (Combat Phase 1+), the engine resolves damage against its equipped armor, not bare flesh:

```
Steel sword vs. armored skeleton:
  Attacker: steel sword (hardness 9, edge quality 8)
  Defender: iron armor (hardness 8, density 8000) + skeleton body
  Result: Armor absorbs impact, skeleton takes reduced damage
  Narration: "The sword scrapes across iron plate, leaving a dent. The skeleton staggers."
```

The weapon's material properties interact with the armor's material properties (existing material system). No special-case combat code.

### Weapon Integration

If a creature wields a weapon, that weapon's properties directly affect combat:

```lua
steel_sword = {
    template = "weapon",
    damage_class = "cutting",
    material = "steel",
    weight = 3,
    wearable = { slot = "hands", layer = "inner" },
    combat = {
        damage_type = "cutting",
        force_class = "heavy",
        reach = 1
    }
}
```

When the skeleton wields this sword, the combat resolution uses the sword's `force_class` and `damage_type`. The engine doesn't ask "does the skeleton have a +3 attack bonus?" — it asks "what is this weapon made of, and how much force can the skeleton apply with it?"

---

## 4. Death Drops

### What Happens on Death

When a creature transitions from `alive` state to `dead` state:

**Existing Behavior (already implemented):**
- The creature's FSM triggers the `dead` state
- The creature's object mutates from `skeleton-warrior.lua` → `skeleton-warrior-dead.lua`
- The creature becomes immobile (corpse can't move)

**New Behavior (Inventory Phase 1):**
- The engine instantiates the dead creature's inventory into the room
- Worn items (helmet, armor, weapons) drop to the floor
- Carried items (coins, keys) drop to the floor
- All items are now independent objects in the room registry

### Drop Location

**Option A: Scatter to Floor**
Items appear directly on the room floor, independent:
```
You see: iron-helmet, steel-sword, shield, leather-pouch
```

**Option B: Create Corpse Container**
Items fall into a temporary "corpse" container:
```
You see: corpse of skeleton (contains iron-helmet, steel-sword, leather-pouch)
open corpse
You look inside a corpse of skeleton. It contains: iron-helmet, steel-sword, leather-pouch
```

**Decision:** Phase 1 uses **Option A** (scatter to floor) for simplicity. Phase 2 can explore corpse containers if we want to model grave-robbing or corpse desecration mechanics.

### Timing

The instantiation happens **immediately** when the creature enters the `dead` state. The inventory doesn't persist in the dead creature object — the items materialize as independent room-floor objects. This aligns with Principle D-14: state is code. When the code changes, the system state changes.

### Stackability

If multiple creatures of the same type die in the same room, each drops its own inventory. If both skeletons drop 50 coins, the room now has 100 coins (two separate coin stacks or one merged stack, depending on containment rules).

---

## 5. Loot Tables

### Loot Tables: What and Why

A loot table is a **data structure that probabilistically selects items** when a creature dies. Instead of:

```lua
inventory = {
    hands = { sword_guid },
    head = helmet_guid
}
```

We write:

```lua
loot_table = {
    always = { { template = "iron-helmet" } },
    on_death = {
        { item = { template = "steel-sword" }, weight = 70 },
        { item = { template = "iron-sword" }, weight = 20 },
        { item = { template = "rusted-sword" }, weight = 10 }
    },
    coins = { min = 10, max = 50 }
}
```

On death, the engine rolls the loot table and instantiates the selected items. This enables **variety without authoring each variant individually**.

### When Are Loot Tables Necessary?

| Scenario | Best Approach |
|----------|---------------|
| Practice room skeleton (same every time) | Fixed inventory (Option A) |
| Dungeon skeletons (randomized difficulty) | Loot table (Phase 2) |
| Boss skeleton (unique sword) | Fixed inventory + guaranteed drop |
| Rats (each has 1–3 coins) | Loot table with weighted distribution |

**Decision:** Phase 1 uses **fixed inventory** (no loot tables). Loot tables are introduced in Phase 2 when randomized dungeons are implemented.

### Loot Table Structure (Future)

For reference, Phase 2 loot tables will support:

```lua
loot_table = {
    -- Guaranteed drops (always present)
    always = {
        { template = "iron-helmet", quantity = 1 }
    },

    -- Weighted rolls (pick one at death)
    on_death = {
        { item = { template = "steel-sword" }, weight = 50 },
        { item = { template = "silver-dagger" }, weight = 30 },
        { item = nil, weight = 20 }  -- No item (20% chance of nothing)
    },

    -- Quantity rolls (coins, ammo)
    coins = {
        min = 10,
        max = 100,
        distribution = "uniform"  -- or "weighted"
    },

    -- Skill-based loot (drops if creature was killed by specific method)
    conditional = {
        poison_kill = { { template = "antidote-potion" } },
        backstab_kill = { { template = "rogue-badge" } }
    }
}
```

---

## 6. Creature Equipment Metadata

### Complete Creature Inventory Structure

A creature's `.lua` file declares inventory via an `inventory` table:

```lua
return {
    guid = "{windows-guid}",
    template = "creature",
    id = "skeleton-warrior",
    name = "a skeleton warrior",
    animate = true,

    -- Creature behavior (existing)
    behavior = { /* … */ },
    drives = { /* … */ },
    body_tree = { /* … */ },  -- From Combat Phase 1

    -- NEW: Inventory declaration
    inventory = {
        -- Hands: actively wielded (max 2 items)
        hands = {
            "steel-sword-warrior-01",  -- GUID of object in registry
            "shield-warrior-01"
        },

        -- Worn equipment: one item per slot
        worn = {
            head = "iron-helmet-warrior-01",
            torso = "iron-plate-armor-warrior-01",
            legs = "iron-greaves-warrior-01",
            feet = "iron-boots-warrior-01"
        },

        -- Carried: items in containers or direct items
        carried = {
            { container = "leather-pouch-warrior-01" },  -- Pouch contains its own items
            "rope-50ft",  -- Loose item
            "key-01"
        }
    },

    -- Alternative: fixed loot table (Phase 2)
    loot_table = {
        always = { { template = "iron-helmet" } },
        on_death = { { item = { template = "steel-sword" }, weight = 70 } },
        coins = { min = 20, max = 80 }
    }

    -- Initial state
    initial_state = "alive",
    _state = "alive",
    states = {
        alive = {
            description = "A skeleton warrior in full plate armor, gripping a steel sword and shield.",
            casts_light = false
        },
        dead = {
            description = "A pile of scattered bones. The armor and weapons are gone.",
            casts_light = false
        }
    },
    transitions = {
        { from = "alive", to = "dead", verb = "death" }
    }
}
```

### Metadata Validation

The meta-linter (Nelson) validates:

1. **Hand constraint:** `inventory.hands` has max 2 items
2. **Slot constraint:** `inventory.worn` has max 1 item per valid slot (head, torso, etc.)
3. **GUID resolution:** Every GUID in inventory resolves to an object in the registry
4. **Size constraints:** Items in `carried` respect container capacity limits
5. **Mutually exclusive:** Can't have both `inventory` and `loot_table` (Phase 1 restriction)

---

## 7. Interaction with Existing Systems

### Containment System

The creature's `carried` inventory uses the **existing containment model** unchanged:

```lua
carried = {
    { container = "leather-pouch-guid", items = { "coin-01", "coin-02", "coin-03" } },
    "rope-50ft"  -- Loose item
}
```

The engine validates:
- Can the pouch hold coins? (Layer 4: category acceptance)
- Do the coins fit through the pouch opening? (Layer 2: physical size)
- Is there room in the pouch? (Layer 3: capacity)

No new containment rules. Creatures follow the same rules as players.

### Wear Slot System

The creature's `worn` equipment uses the **existing wearable system** unchanged:

```lua
worn = {
    head = "iron-helmet-guid",
    torso = "iron-plate-armor-guid"
}
```

The engine applies:
- Helmet covers the head zone
- Armor covers the torso zone
- Material properties of armor affect damage reduction (Combat Phase 1+)
- Worn items appear in creature's sensory description

No new wearable rules. Creatures wear items exactly as players do.

### Combat System

When a creature with equipped armor is attacked (Combat Phase 1+):

**Existing combat flow:**
1. Attacker selects target (creature)
2. Combat FSM resolves exchange:
   - Weapon material vs. armor material → damage severity
   - Armor coverage vs. hit zone → protection applied
   - Body tissue properties → final injury
3. Injury system applies (health, stress, wounds)

**Creature inventory addition:**
- The armor's material properties are read from the worn equipment's metadata
- No special combat code for creatures — just read the wore object's properties

### Mutation System

When a creature dies and items are instantiated:

**Before death:**
- Creature's inventory is abstract (array of GUIDs)
- Objects exist in the registry but are "possessed"

**At death moment:**
- Creature's state transitions to `dead`
- Creature's `.lua` file mutates (Principle D-14)
- Engine instantiates inventory: each item becomes a room-floor object
- Items are now independent, can be picked up, traded, etc.

**After death:**
- Dead creature object remains (corpse)
- Inventory is gone (instantiated into the room)
- Dead creature no longer carries anything

---

## 8. Scaling Path

### Phase 1: Fixed Inventory (Creature Death Basics)

**What's included:**
- Creatures can declare fixed inventory via `inventory` table
- Death instantiates inventory items to the room floor
- Combat integration: equipped armor affects combat (from Combat Phase 1)
- No loot tables, no randomization

**Example creature:**
```lua
skeleton_warrior = {
    hands = { "steel-sword-01", "shield-01" },
    worn = { head = "helmet-01", torso = "armor-01" },
    carried = { "coins-20", "key-01" }
}
```

Every warrior skeleton carries exactly this inventory. Repeatable. Testable.

**Agent work:** Flanders (objects) + Bart (engine mutation integration)

### Phase 2: Loot Tables & Randomization

**What's added:**
- Loot table support (weighted probability per item slot)
- Coin roll ranges (e.g., 10–50 gold per creature)
- Conditional loot (special drops for specific kill methods)
- Generative inventory (templates + quantities instead of GUIDs)

**Example creature:**
```lua
rat = {
    loot_table = {
        always = { },
        on_death = {
            { item = { template = "steel-needle" }, weight = 30 },
            { item = nil, weight = 70 }
        },
        coins = { min = 1, max = 5 }
    }
}
```

30% of rat deaths drop a needle; 70% drop nothing. 1–5 coins always.

**Dependencies:** Phase 1 must be stable first.

**Agent work:** Nelson (test framework for loot table validation)

### Phase 3: Creature-to-Creature Looting

**What's added:**
- Creatures can steal from living creatures (pickpocket mechanics)
- Creatures can loot corpses (scavenge behavior)
- Behavioral drives: greed, hunger, theft
- NPC-vs-NPC economic interactions

**Example scenario:**
A rat can steal a coin from the skeleton warrior while it's alive. A wolf can scavenge a corpse's meat.

**Dependencies:** Phase 1 + Phase 2 + NPC behavior system (from NPC System Plan Phase 2+)

**Agent work:** TBD (coordination with NPC Phase 2)

---

## 9. Edge Cases

### Case 1: Creature Carrying Unsizable Items

A rat tries to carry a sword. The sword is size 4; the rat's hand capacity is size 1–2.

**Resolution:** The rat cannot carry the sword. Its inventory remains empty. Either:
- The rat's spawn fails (validation error)
- The item is silently rejected (graceful degradation)
- The engineer is warned in meta-lint

**Decision:** Meta-lint warns; spawn fails with a clear error message.

### Case 2: Item Doesn't Exist in Registry

A creature's inventory references a GUID that doesn't exist in the registry.

**Resolution:** On spawn:
- Engine checks all GUIDs resolve
- If any GUID is invalid, creature spawn fails
- Error log: "Creature skeleton-01 references invalid GUID: {bad-guid}"

**Implementation:** Part of creature validation in the loader.

### Case 3: Creature Dies with No Inventory

A creature has `inventory = {}` or no inventory declared at all.

**Resolution:** Nothing drops. Room remains unchanged. This is valid — a bare skeleton dies, leaves only bones.

### Case 4: Multi-Room Loot Drop

A creature dies in the Great Hall. Its inventory drops to the Great Hall floor. Later, the player leaves and returns. Are the items still there?

**Resolution:** Yes. Items persist in the room registry. The dead creature object remains (corpse). Both are saved/loaded as part of room state.

**Note:** This enables tomb-looting, but also scavenger cleanup mechanics for later phases (rats eating corpses, NPCs collecting loot).

### Case 5: Creature Wears Incompatible Item

A creature declares `worn = { head = "sword-guid" }` — but a sword is not wearable.

**Resolution:** Meta-lint validation catches this.
- Sword object has no `wearable` table
- Validator rejects: "Creature skeleton-01 tries to wear sword (not wearable)"
- Error logged; creature spawn fails

### Case 6: Creature Exceeds Hand Limit

A creature declares `hands = { "sword-1", "sword-2", "torch" }` — three items.

**Resolution:** Meta-lint validation catches this.
- Error: "Creature skeleton-01 has 3 hand items; max is 2"
- Creature spawn fails

### Case 7: Item Already Worn by Something Else

A skeleton and a player both try to wear the same helmet GUID.

**Resolution:** Object registry prevents duplicate possession. When a creature spawns with an item, that item is "owned" by the creature. If the player later tries to take it, the player picks it up (normal movement semantics). If the creature tries to wear the same item, ownership conflict.

**Decision:** Creatures reference **distinct object copies**, not shared references. Each creature gets its own sword, helmet, etc. (established by Phase 1 spawn rules). Collisions don't happen.

### Case 8: Creature Wearing Conditional Item

A helmet that only works during nighttime. A creature is wearing it at dawn.

**Resolution:** The helmet's `state` or `conditions` field handles this (existing FSM system). If the helmet has a condition `active_if = { time_of_day = "night" }`, the engine evaluates it. The creature might be wearing a dormant helmet.

**Implementation:** No change to creature inventory. Existing FSM system handles it.

---

## 10. Implementation Phases

### Phase 1: Fixed Inventory (Deliverable)

| Task | Owner | Scope |
|------|-------|-------|
| Define `inventory` metadata table (spec) | CBG | 2 days |
| Update creature template with inventory fields | Flanders | 1 day |
| Implement inventory → room instantiation on death | Bart | 3 days |
| Meta-lint: validate creature inventory | Nelson | 2 days |
| Write tests: creature death + loot drop | Nelson | 3 days |
| Document creature equipment pattern | Brockman | 1 day |

**Total:** ~12 days

**Dependencies:** None (integrates with existing Combat Phase 1)

**Verification:**
```bash
lua test/creatures/test-death-inventory.lua
```

Sample test:
```lua
t.test("skeleton warrior drops all equipped items on death", function()
    -- Creature has: sword, shield, helmet, armor, 50 coins
    -- Kill creature
    -- Assert: room contains sword, shield, helmet, armor, 50 coins
end)
```

### Phase 2: Loot Tables & Generative Inventory

| Task | Owner | Scope |
|------|-------|-------|
| Define `loot_table` metadata structure (spec) | CBG | 3 days |
| Implement loot table rolling logic | Bart | 4 days |
| Update creature template with loot_table fields | Flanders | 1 day |
| Generative inventory (templates → objects on death) | Bart | 4 days |
| Meta-lint: validate loot table structure | Nelson | 2 days |
| Write tests: loot probability distribution | Nelson | 4 days |
| Document loot table patterns | Brockman | 1 day |

**Total:** ~19 days

**Dependencies:** Phase 1 complete

**Verification:**
```bash
lua test/creatures/test-loot-table-distribution.lua
```

Sample test:
```lua
t.test("rat death: 30% drop needle, 70% drop nothing", function()
    -- Kill 100 rats, track drops
    -- Assert: ~30 drop needle, ~70 drop nothing (within ±5%)
end)
```

### Phase 3: Creature-to-Creature Looting

Deferred to NPC System Phase 2+ (requires creature behavior drives).

---

## 11. Open Questions

### Q1: Corpse Objects vs. Scattered Items

**Question:** When a creature dies, should we create a temporary "corpse" container, or scatter items to the floor?

**Options:**
- A) Scatter items to room floor (simpler, loses corpse context)
- B) Create corpse container, items fall inside (enables grave-robbing, necromancy)
- C) Hybrid: small items scatter, large items stay with corpse (contextual)

**Phase 1 decision:** Option A (scatter)  
**Future:** Option B could enable corpse mechanics in a later phase

**Wayne's input needed:** Do we want corpses to be first-class game objects (grave desecration, zombie risk)?

---

### Q2: Item Reuse vs. Per-Spawn Generation

**Question:** Should multiple creatures of the same type share object references, or does each get unique instances?

**Options:**
- A) Shared: All warrior skeletons carry the same 3 sword GUIDs (efficient, but single item can't be in two places)
- B) Per-spawn: Each warrior skeleton carries a generated sword from a template (memory cost, but independent items)

**Phase 1 decision:** Option A (shared references, GUID-based)  
**Phase 2:** Option B (loot tables generate new items per death)

**Wayne's input needed:** What's the memory/performance budget for per-spawn generation?

---

### Q3: Creature Theft / Pickpocket

**Question:** Can the player pickpocket items from a living creature?

**Options:**
- A) No theft system (creatures only drop items on death)
- B) Theft requires stealth check (NPC unaware behavior)
- C) Theft triggers combat (creature notices, retaliates)
- D) NPC skill-based (high-level thieves steal; low-level fail and alert)

**Phase 1 decision:** Option A (no theft, Phase 3 feature)

**Wayne's input needed:** Is theft-from-creatures a core mechanic or future flavor?

---

### Q4: Loot Tied to Kill Method

**Question:** Should certain items only drop if killed via a specific method (poisoned, burned, starved, etc.)?

**Options:**
- A) All loot drops regardless of method (simpler)
- B) Method-specific drops (poison kill drops antidote; burn kill drops ash)
- C) Method affects loot probability (burn kill: 50% fire-resistant armor instead of normal)

**Phase 1 decision:** Option A (all drops)  
**Phase 2+:** Explore method-specific drops

**Wayne's input needed:** Do kill methods affect narrative closure / reward feedback?

---

### Q5: Resurrection / Creature Respawning

**Question:** When a creature dies, is it permanent or can it respawn?

**Options:**
- A) Permanent death (creature gone forever)
- B) Respawn at a fixed point (creature reappears after N turns)
- C) Respawn table (some creatures respawn, others don't)

**Phase 1 decision:** Option A (permanent)  
**Phase 2+:** Respawn mechanics

**Wayne's input needed:** What's the economy of creature death? Should a player be able to farm loot from infinite respawns?

---

### Q6: Container Decay

**Question:** If a creature carries a leather pouch with coins, and the creature decays after N turns, does the pouch decay too?

**Options:**
- A) All items persist indefinitely
- B) Perishable items (food, corpses) decay; durable items (coins, weapons) persist
- C) Containers decay (pouch rots), items scatter

**Phase 1 decision:** Option A (all items persist)

**Wayne's input needed:** Do we want a decay/scavenging system later?

---

### Q7: Creature Inventory Discovery

**Question:** How does the player know what a creature carries before killing it?

**Options:**
- A) No hint (surprise loot)
- B) Creature description hints ("The skeleton is burdened with armor")
- C) EXAMINE verb reveals inventory (if creature visible)
- D) Smell/feel can detect metal (sensory clues)

**Phase 1 decision:** Option B (descriptive hints)  
**Future:** Option C (EXAMINE integration with creature sensory)

**Wayne's input needed:** Should creature inventory be a mystery or a promise?

---

## Appendix A: Comparison with Competitors

### Dwarf Fortress (Creature Inventory)

**How DF handles it:**
- Every creature has an inventory (backpack slots)
- Creatures wear equipment (armor, clothing, weapons)
- Equipment affects combat + material interactions
- Death drops all inventory to a "corpse" object
- Loot is fully deterministic (dictated by creature definition)

**What we adopt:**
- Fixed inventory per creature type
- Equipment affects combat (body_tree integration, Phase 1+)
- Death drops to room (we use scattered floor, not corpse container yet)

**What we differ:**
- DF has 200 body parts; we have 4–6 zones (Wayne's D-COMBAT-1)
- DF has complex item degradation; we use mutation (code rewrite)
- DF has world-scale persistence; we have per-room persistence (Phase 1)

### NetHack (Creature Inventory)

**How NetHack handles it:**
- Monsters carry items (determined by creature definition)
- Death creates a "corpse" object (temporary, decays)
- Some creatures can use equipment (wands, potions)
- Loot is fixed per creature type

**What we adopt:**
- Fixed inventory per creature type
- Death drops to room

**What we differ:**
- NetHack corpses are containers; we scatter items initially
- NetHack creatures use potions/wands (creatures have limited agency); we have pure metadata

### MUDs (NPCs & Loot)

**How MUDs handle it:**
- NPCs have inventory slots (fixed or dynamic)
- Loot tables with weighted drops
- Some items quest-specific (untradeable, unique)
- Economy system (NPCs buy/sell)

**What we adopt (Phase 2+):**
- Loot tables with weighted probability
- Creature-to-creature economy (Phase 3+)

**What we differ:**
- We use code mutation for state; MUDs use object flags
- We don't have NPC commerce yet (Phase 3+ feature)

### Roguelikes (Loot & Randomization)

**How roguelikes (Hades, Binding of Isaac) handle it:**
- Enemies drop randomized loot based on tables
- High variance (rare vs. common drops)
- Scaling: harder enemies drop better loot
- Economy: loot sells for gold, gold buys upgrades

**What we adopt (Phase 2+):**
- Loot table randomization
- Creature difficulty → loot quality (future)

**What we differ:**
- We don't have loot economy yet (Phase 3+)
- We emphasize narrative over progression mechanics (text IF tradition)

---

## Appendix B: Glossary

| Term | Definition |
|------|-----------|
| **Fixed inventory** | Creature carries the same items every time (Phase 1) |
| **Loot table** | Probabilistic item selection on death (Phase 2+) |
| **Generative inventory** | Items created from templates on spawn/death (Phase 2+) |
| **Equipment** | Items worn on body slots (head, torso, etc.) — affects combat |
| **Carrying** | Items stored in containers or loose in inventory — doesn't affect combat |
| **Instantiation** | Creating independent room-floor objects from creature inventory metadata |
| **Mutation** | Rewriting creature `.lua` file from `alive` state to `dead` state |
| **Body zone** | Combat target area (head, torso, arms, legs) |
| **Hand slot** | One of 2 hand inventory slots (2-hand rule) |
| **Wear slot** | Body part where items can be equipped (9 total: head, hands, torso, etc.) |

---

## Summary

This design plan establishes creature inventory and loot drops as a **metadata-driven extension** of the existing player inventory system. Creatures declare what they carry via `inventory` or `loot_table` fields. On death, their inventory instantiates into the room. Equipment (worn armor, weapons) affects combat via the existing body_tree system. Carrying (stored items) is inert until picked up.

**Phase 1 (Immediate):** Fixed inventory + death drops  
**Phase 2 (Next Sprint):** Loot tables + generative inventory  
**Phase 3+ (Future):** Creature-to-creature looting + economic interactions

No new engine subsystems required. We compose existing systems: containment, wear slots, FSM, mutation, combat. Creatures are objects with an `animate = true` flag that happen to carry stuff.

---

**Status:** Ready for Wayne's architectural review  
**Decision Filing:** `.squad/decisions/inbox/cbg-creature-inventory-plan.md`
