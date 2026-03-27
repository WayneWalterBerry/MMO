# Creature Inventory Architecture

**Version:** 1.0  
**Date:** 2026-08-16  
**Author:** Brockman (Documentation) — Bart (Architecture Lead) review  
**Status:** ✅ SPECIFIED — Ready for WAVE-2 implementation  
**Decision:** D-CREATURE-INVENTORY (Phase 3, WAVE-2)  
**Requested by:** Wayne "Effe" Berry  
**Prerequisite reading:** `docs/architecture/engine/creature-death-reshape.md` (WAVE-1), `docs/architecture/engine/containment-constraints.md`

---

## 1. Problem Statement

Phase 1–2 creatures are empty: they have no possessions, no worn equipment, no loot. When a player kills a wolf, nothing drops. Phase 3 adds creature inventory: each creature can declare items it carries (hands, worn, carried). On death, these items scatter to the room floor as independent objects, giving players tactical loot to pick up and use.

### Design Goals

1. **Direct GUID References:** Phase 3 creatures reference specific item GUIDs directly (no loot tables — Phase 4).
2. **Death Drop Pipeline:** When creature reshapes (WAVE-1), inventory drop instantiates items to room floor.
3. **Validation:** Meta-lint ensures inventory declarations are well-formed (hands max 2, worn slots valid, GUIDs resolve, size constraints respected).
4. **Containment Reuse:** Reshaped corpse inherits container capacity from `death_state`; existing containment engine handles search/take.

---

## 2. Inventory Metadata Format

### 2.1 Structure

Each creature `.lua` file can declare an `inventory` metadata block:

```lua
-- Inside creature.lua
inventory = {
    hands = {},                    -- max 2 items (array of GUIDs)
    worn = {                       -- slot → GUID mapping
        head = nil,                -- specific slot names
        torso = nil,
        arms = nil,
        legs = nil,
        feet = nil,
    },
    carried = {},                  -- loose items (array of GUIDs)
},
```

### 2.2 Inventory Categories

| Category | Max Count | Description | Example |
|----------|-----------|-------------|---------|
| **hands** | 2 | Dual-wield capable; items player can grab immediately | Weapon, tool, torch |
| **worn** | 5 (one per slot) | Equipped gear; visible in description | Armor, helmet, boots, cloak |
| **carried** | ∞ | Loose items in bag/satchel; requires opening container to access | Scroll, potion, food ration |

### 2.3 Worn Slots

Valid `worn` slot names (immutable):

```lua
worn = {
    head = "helmet-leather",       -- helmet, hat, crown, circlet
    torso = "armor-chainmail",     -- armor, shirt, tunic, vest
    arms = "gloves-leather",       -- gloves, bracers, sleeves
    legs = "greaves-steel",        -- legs armor, kilt, pants
    feet = "boots-leather",        -- boots, shoes, sandals
}
```

Any slot can be `nil` (creature not wearing that slot). All five slots must be declared, even if empty.

### 2.4 Example: Wolf with Gnawed Bone

```lua
-- Inside wolf.lua
inventory = {
    hands = {},                    -- wolves don't hold things
    worn = {
        head = nil,
        torso = nil,
        arms = nil,
        legs = nil,
        feet = nil,
    },
    carried = {
        "gnawed-bone-01",          -- wolf carries leftover bone from prey
    },
},
```

On wolf death (WAVE-1 reshape), the death drop process (WAVE-2) instantiates `gnawed-bone-01` to the room floor alongside the reshaped wolf corpse.

---

## 3. Death Drop Instantiation Pipeline

### 3.1 Sequence

When creature reshapes (WAVE-1):

1. **Engine detects death:** Creature health reaches 0
2. **reshape_instance() called:** Instance template switches creature → small-item/furniture (WAVE-1)
3. **Death drop process starts:** Iterate `inventory.hands`, `inventory.worn`, `inventory.carried`
4. **For each item:**
   - Retrieve item definition from registry via GUID
   - Create room-floor instance of that item
   - Register as room object (player can take/examine)
5. **Reshaped corpse + dropped items coexist** in room as independent objects

### 3.2 Code Pattern (WAVE-2 Implementation)

```lua
-- In src/engine/creatures/init.lua, death drop handler
function M.drop_inventory_on_death(creature_instance, room, registry)
    local inventory = creature_instance.inventory
    if not inventory then return end

    local dropped_guids = {}

    -- Drop hands
    if inventory.hands then
        for _, item_guid in ipairs(inventory.hands) do
            table.insert(dropped_guids, item_guid)
        end
    end

    -- Drop worn
    if inventory.worn then
        for slot_name, item_guid in pairs(inventory.worn) do
            if item_guid then
                table.insert(dropped_guids, item_guid)
            end
        end
    end

    -- Drop carried
    if inventory.carried then
        for _, item_guid in ipairs(inventory.carried) do
            table.insert(dropped_guids, item_guid)
        end
    end

    -- Instantiate each item as room-floor object
    for _, item_guid in ipairs(dropped_guids) do
        local item_def = registry:get(item_guid)
        if item_def then
            registry:register_as_room_object(item_def, room)
        end
    end
end
```

### 3.3 Inventory vs. Container (Post-Reshape)

After reshape, the corpse instance becomes a **container** (via `death_state.container` metadata):

```lua
death_state = {
    container = {
        capacity = 2,              -- small corpse can hold 2 items
        categories = { "tiny" },   -- size constraints
    },
}
```

This container capacity is **separate from the dropped inventory**:

- **Dropped inventory:** Items that were in creature's possession before death; now on room floor
- **Corpse container:** Empty space inside the dead creature's body; player can put items into it after death

If designer wants the dropped items to end up **inside** the corpse (not on floor), that's a WAVE-3 design choice (food placement) — not automatic.

---

## 4. Meta-Lint Validation Rules

Meta-lint verifies all creature inventory declarations at build time. Rules use codes `INV-01` through `INV-04`:

### 4.1 INV-01: Hands Capacity

**Rule:** `inventory.hands` array has max 2 items.

```lua
-- ✅ Valid
inventory.hands = {}                -- empty OK
inventory.hands = { "sword-01" }    -- 1 item OK
inventory.hands = { "sword-01", "shield-01" }  -- 2 items OK

-- ❌ Invalid
inventory.hands = { "sword-01", "shield-01", "torch-01" }  -- 3 items → LINT ERROR
```

**Error message:** `INV-01: creature {id} has {n} items in hands; max is 2`

### 4.2 INV-02: Worn Slots

**Rule:** `inventory.worn` keys are exactly one of: `head`, `torso`, `arms`, `legs`, `feet`.

```lua
-- ✅ Valid
inventory.worn = {
    head = nil,
    torso = "armor-chainmail",
    arms = "gloves-leather",
    legs = nil,
    feet = "boots-steel",
}

-- ❌ Invalid (extra slot)
inventory.worn = {
    head = nil,
    torso = "armor",
    back = "backpack-01",          -- "back" is not a valid slot
    arms = nil,
    legs = nil,
    feet = nil,
}
```

**Error message:** `INV-02: creature {id} has invalid worn slot '{slot}'; valid slots are: head, torso, arms, legs, feet`

### 4.3 INV-03: GUID Resolution

**Rule:** Every GUID in `inventory.hands`, `inventory.worn`, `inventory.carried` must resolve to an object in the registry.

```lua
-- ✅ Valid (GUIDs exist in registry)
inventory = {
    hands = { "{valid-sword-guid}" },
    worn = { head = "{valid-helmet-guid}" },
    carried = { "{valid-potion-guid}" },
}

-- ❌ Invalid (GUID doesn't exist)
inventory = {
    hands = { "{nonexistent-guid-12345}" },  -- Not in registry → LINT ERROR
}
```

**Error message:** `INV-03: creature {id} inventory references non-existent GUID {guid}`

### 4.4 INV-04: Size Constraints

**Rule:** Carried/worn items respect size constraints defined in creature.

```lua
-- Example: wolf with size_limit = 3 (can carry items up to "small" size)
-- ✅ Valid (item fits)
inventory.carried = { "tiny-potion-guid" }  -- potion size = "tiny" OK

-- ❌ Invalid (item too large)
inventory.carried = { "large-sword-guid" }  -- sword size = "large" exceeds wolf limit → LINT ERROR
```

**Error message:** `INV-04: creature {id} carries item {item_id} (size {item_size}) exceeds size limit {creature_limit}`

---

## 5. Phase 3 Creature Inventory Assignments

| Creature | Inventory | Rationale |
|----------|-----------|-----------|
| **rat** | empty | Rats carry nothing; loot comes later (Phase 4) |
| **cat** | empty | Cats are hunters but don't carry prey (Phase 4 feature) |
| **wolf** | `carried = { "gnawed-bone-01" }` | Wolves carry prey remains |
| **spider** | (none) | Silk is death byproduct, not inventory (see creature-death-reshape.md §6.2) |
| **bat** | empty | Bats carry nothing |

### 5.1 Gnawed Bone Object

**File:** `src/meta/objects/gnawed-bone.lua`

```lua
return {
    guid = "{gnawed-bone-guid}",
    template = "small-item",
    id = "gnawed-bone",
    name = "a gnawed bone",
    keywords = {"bone", "gnawed bone", "prey remains"},
    description = "A bone, gnawed and scraped clean by predator teeth. Strips of sinew still cling to one end.",

    -- Sensory
    on_feel = "Hard, smooth bone with rough gnaw marks. Still slightly warm.",
    on_smell = "Faint blood and old meat.",
    on_listen = "Silent.",
    on_taste = "Bitter bone dust and old blood. Not recommended.",

    -- Physical
    size = "small",
    weight = 0.2,
    material = "bone",
    portable = true,
    animate = false,
}
```

On wolf death, this object instantiates to room floor. Player can pick it up, examine it, cook it (Phase 3), or break it down further (Phase 4 butchery).

---

## 6. Containment Engine Reuse

### 6.1 Architecture Decision

The existing `src/engine/containment/init.lua` module handles:
- Size/weight constraints
- Capacity checks
- Search within containers
- Take/put operations

**Design principle:** The reshaped corpse is just another container. No special logic needed.

### 6.2 Example: Dead Rat as Container

After wolf dies and reshapes, the corpse container is available:

```lua
reshaped_wolf = {
    template = "furniture",         -- large, not portable
    container = {
        capacity = 5,               -- wolf corpse can hold 5 items
        categories = { "small", "tiny" },
    },
}
```

Player can:
1. `examine wolf` — see sensory description + `room_presence` text
2. `look inside wolf` — open container, see what's inside
3. `take bone from wolf` — extract gnawed-bone from container
4. `put potion in wolf` — player adds their own item (if it fits)

Containment engine handles all of this automatically. No creature-specific code needed.

---

## 7. Testing Strategy (WAVE-2)

| Test Suite | Coverage |
|-----------|----------|
| `test/creatures/test-creature-inventory.lua` | Load inventory metadata, validate wolf carries bone, hands/worn/carried arrays parse correctly |
| `test/creatures/test-death-drops.lua` | Kill wolf → gnawed-bone appears on room floor as independent object, kill spider → silk appears, can take dropped items |
| `test/creatures/test-inventory-edge-cases.lua` | Empty inventory, over-hand-limit validation, GUID resolution failure, size constraint violation |
| `test/meta-lint/test-inv-rules.lua` | INV-01 through INV-04 pass/fail on test creatures |

**Critical gates:**
- Wolf dies → gnawed-bone appears on room floor
- Dropped item is an independent object (can take, examine, drop, etc.)
- Meta-lint INV-01–INV-04 catch all constraint violations
- Reshaped corpse container works (can open, search, take from)

---

## 8. Backward Compatibility

Creatures without an `inventory` declaration have empty inventory (no dropped items). This is safe:

```lua
if not creature.inventory then
    -- No inventory to drop
    return
end
```

Existing Phase 2 creatures can be updated incrementally:
- **Phase 3 creatures:** Include full `inventory` blocks
- **Future creatures:** Include `inventory` from day one
- **Legacy creatures:** Leave as-is; they work (just with no drops)

---

## 9. Future Extensions (Phase 4+)

### 9.1 Loot Tables

Phase 3 uses direct GUID references. Phase 4+ could add loot tables:

```lua
-- Phase 4 pattern (not Phase 3)
inventory = {
    loot_table = "wolf-prey-table",  -- name → { weight, items[] }
}
```

Engine would weight-roll the table to decide what drops. This keeps Phase 3 simple (direct GUIDs only).

### 9.2 Wear Effects

Phase 3 creatures wear items but it's cosmetic (visible in description). Phase 4+ could add:

```lua
-- Phase 4 pattern (not Phase 3)
worn = {
    head = {
        item = "helmet-01",
        effect = "armor_rating_5",  -- passive defense bonus
    }
}
```

For now (Phase 3), worn items are just worn (appear in description, drop on death, can be looted).

---

## 10. Implementation Checklist (for WAVE-2)

- [ ] `inventory` metadata block added to wolf.lua (with gnawed-bone reference)
- [ ] `gnawed-bone.lua` object created with GUID
- [ ] Death drop handler in `src/engine/creatures/init.lua` (~40 LOC)
- [ ] Drop handler called from reshape_instance() or death pathway
- [ ] Dropped items registered as room objects (findable, takeable)
- [ ] INV-01 meta-lint rule (hands max 2)
- [ ] INV-02 meta-lint rule (worn slots valid)
- [ ] INV-03 meta-lint rule (GUIDs resolve)
- [ ] INV-04 meta-lint rule (size constraints)
- [ ] All WAVE-2 tests pass
- [ ] No regressions in WAVE-1 + Phase 2 tests

---

## 11. Related Documents

- **Death Reshape:** `docs/architecture/engine/creature-death-reshape.md` (WAVE-1)
- **Containment System:** `docs/architecture/engine/containment-constraints.md`
- **Creatures Overview:** `docs/architecture/engine/creature-system.md`
- **Phase 3 Plan:** `plans/npc-combat/npc-combat-implementation-phase3.md` (full spec)
- **Creature Inventory Plan:** `plans/npc-combat/creature-inventory-plan.md` (design source)

---

**Authored by:** Brockman (Documentation)  
**Reviewed by:** Bart (Architecture Lead) — WAVE-0 gate sign-off pending  
**Status:** Ready for WAVE-2 implementation
