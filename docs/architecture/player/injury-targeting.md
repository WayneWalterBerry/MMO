# Injury Targeting & Accumulation — Architecture

**Version:** 1.0  
**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-07-25  
**Status:** Design  
**Purpose:** Technical specification for injury targeting resolution, bandage-injury dual binding, treatment removal, and accumulative damage math. Written for Bart to implement in `src/engine/injuries.lua`.

---

## Overview

Players apply treatment objects to **specific** injury instances, not generic health. This document specifies:

1. How the parser resolves "apply X to Y" into object + injury target
2. How treatment objects (bandage) bind to injury instances (dual reference)
3. How removal works (unbind + state transition)
4. How multiple injuries accumulate damage (the math)

**Core invariant:** A treatment object can only be attached to ONE injury at a time. An injury can only have ONE treatment at a time. Both sides reference each other.

---

## 1. Targeting Resolution: "Apply X to Y"

### Parser Output

The parser extracts three components from treatment commands:

```
"apply bandage to left arm stab wound"
  → verb     = "apply"
  → object   = "bandage"          (resolved from player.inventory)
  → target   = "left arm stab wound"  (injury description fragment)
```

### Function Signature

```lua
--- Resolve which injury the player is targeting.
--- @param player table       — player.lua instance (has .injuries[])
--- @param target_str string  — raw text after "to" (e.g., "left arm stab wound")
--- @param cures_list table   — treatment object's cures field (e.g., {"bleeding", "minor-cut"})
--- @return injury table|nil  — matched injury instance, or nil
--- @return string            — error message if no match, or "" on success
function injury_targeting.resolve(player, target_str, cures_list)
```

### Match Strategy (priority order)

The engine searches `player.injuries[]` for a match. It tries these matchers in order, stopping at the first hit:

| Priority | Match Type | Example Input | Matches Against |
|---|---|---|---|
| 1 | **Instance ID** | `"bleeding-a7f3"` | `injury.id` (exact) |
| 2 | **Display name** | `"bleeding wound"` | `injury_def.name` (substring, case-insensitive) |
| 3 | **Body location** | `"left arm"` | `injury.body_location` (substring, case-insensitive) |
| 4 | **Injury type** | `"bleeding"` | `injury.type` (exact match against `cures_list`) |
| 5 | **Ordinal index** | `"first wound"`, `"second"` | Position in `player.injuries[]` |

### Implementation

```lua
function injury_targeting.resolve(player, target_str, cures_list)
    if not player.injuries or #player.injuries == 0 then
        return nil, "You don't have any injuries."
    end

    -- Filter to injuries this treatment can actually cure
    local treatable = {}
    for _, injury in ipairs(player.injuries) do
        if table_contains(cures_list, injury.type) and not injury.treatment then
            treatable[#treatable + 1] = injury
        end
    end

    if #treatable == 0 then
        return nil, "You don't have any injuries that would help."
    end

    -- Auto-target: if only one treatable injury, bare command works
    if target_str == nil or target_str == "" then
        if #treatable == 1 then
            return treatable[1], ""
        else
            return nil, injury_targeting.format_options(treatable)
        end
    end

    -- Try matchers in priority order
    local normalized = string.lower(target_str)

    -- Priority 1: Exact instance ID
    for _, injury in ipairs(treatable) do
        if injury.id == target_str then
            return injury, ""
        end
    end

    -- Priority 2: Display name substring
    for _, injury in ipairs(treatable) do
        local def = load_injury_definition(injury.type)
        local state_def = def.states[injury._state]
        if state_def and string.find(string.lower(state_def.name), normalized, 1, true) then
            return injury, ""
        end
    end

    -- Priority 3: Body location substring
    for _, injury in ipairs(treatable) do
        if injury.body_location and
           string.find(string.lower(injury.body_location), normalized, 1, true) then
            return injury, ""
        end
    end

    -- Priority 4: Injury type (exact against cures list)
    for _, injury in ipairs(treatable) do
        if injury.type == normalized then
            return injury, ""
        end
    end

    -- Priority 5: Ordinal index ("first", "second", etc.)
    local ordinal_map = {first = 1, second = 2, third = 3, fourth = 4, fifth = 5}
    local ordinal_index = ordinal_map[normalized] or tonumber(normalized)
    if ordinal_index and treatable[ordinal_index] then
        return treatable[ordinal_index], ""
    end

    return nil, "You don't see that injury. " .. injury_targeting.format_options(treatable)
end
```

### Disambiguation (Multiple Matches)

When the player has multiple treatable injuries and doesn't specify which:

```lua
--- Format the list of treatable injuries for the player to choose from.
--- @param treatable table — array of injury instances
--- @return string — formatted prompt
function injury_targeting.format_options(treatable)
    local lines = {"Which injury? You have:"}
    for i, injury in ipairs(treatable) do
        local def = load_injury_definition(injury.type)
        local state_name = def.states[injury._state].name or injury.type
        local location = injury.body_location and (" (" .. injury.body_location .. ")") or ""
        lines[#lines + 1] = "  " .. i .. ". " .. state_name .. location
    end
    return table.concat(lines, "\n")
end
```

**Example output:**
```
Which injury? You have:
  1. bleeding wound (left arm)
  2. bleeding wound (right leg)
```

---

## 2. Dual Binding: Bandage ↔ Injury

When a bandage is applied to an injury, **both sides** store a reference to the other. This is the "dual binding" pattern.

### On Apply (clean → applied)

```lua
--- Attach a treatment object to an injury instance.
--- Called by the engine when APPLY verb fires and targeting resolves.
--- @param player table          — player.lua instance
--- @param treatment_obj table   — the bandage (or other treatment) instance from inventory
--- @param injury table          — the target injury instance from player.injuries[]
function injury_treatment.apply(player, treatment_obj, injury)
    -- 1. Bind treatment → injury
    treatment_obj.applied_to = injury.id

    -- 2. Bind injury → treatment
    injury.treatment = {
        type = treatment_obj.id,
        item_id = treatment_obj.id,
        healing_boost = treatment_obj.healing_boost or 1,
    }

    -- 3. Transition bandage FSM: clean → applied
    treatment_obj._state = "applied"

    -- 4. Transition injury FSM if applicable (e.g., active → treated)
    local injury_def = load_injury_definition(injury.type)
    local interaction = injury_def.healing_interactions[treatment_obj.id]
    if interaction and table_contains(interaction.from_states, injury._state) then
        injury._state = interaction.transitions_to
        injury.damage_per_tick = 0  -- Stop damage accumulation
    end

    -- 5. Bandage stays in inventory but is marked in-use
    -- (engine skips in-use items for other APPLY commands)
end
```

### Data After Apply

```lua
-- Bandage instance (in player.inventory)
{
    id = "bandage",
    _state = "applied",
    applied_to = "bleeding-a7f3",      -- points to injury instance
    -- ...
}

-- Injury instance (in player.injuries[])
{
    id = "bleeding-a7f3",
    type = "bleeding",
    _state = "treated",
    treatment = {
        type = "bandage",
        item_id = "bandage",
        healing_boost = 2,
    },
    damage_per_tick = 0,               -- Stopped by treatment
    -- ...
}
```

### Engine Loop Integration

Each tick, the engine checks injury treatment status:

```lua
--- Called each tick for every active injury.
--- If injury has treatment with healing_boost, accelerate heal timer.
--- @param injury table — injury instance from player.injuries[]
--- @param elapsed number — seconds elapsed this tick (360)
function injury_system.tick_injury(injury, elapsed)
    -- Accumulate damage (0 if treated)
    injury.damage = injury.damage + (injury.damage_per_tick or 0)

    -- Tick heal timer (if injury has one)
    if injury._timer and not injury._timer.paused then
        local boost = 1
        if injury.treatment then
            boost = injury.treatment.healing_boost or 1
        end
        injury._timer.remaining = injury._timer.remaining - (elapsed * boost)

        if injury._timer.remaining <= 0 then
            -- Trigger timed auto-transition (e.g., treated → healed)
            injury_system.auto_transition(injury)
        end
    end
end
```

**Key:** `healing_boost = 2` means the heal timer counts down at 2× speed. A 40-turn heal becomes 20 turns with a bandage applied.

---

## 3. Removal: Unbinding Treatment

### Player Commands

```
"remove bandage"
"remove bandage from left arm"
"unwrap bandage"
```

### Function Signature

```lua
--- Remove a treatment object from its attached injury.
--- @param player table         — player.lua instance
--- @param treatment_obj table  — the bandage instance to remove
--- @return boolean             — true if removal succeeded
function injury_treatment.remove(player, treatment_obj)
```

### Implementation

```lua
function injury_treatment.remove(player, treatment_obj)
    if not treatment_obj.applied_to then
        return false, "That isn't applied to anything."
    end

    -- 1. Find the injury this treatment is attached to
    local injury = find_injury_by_id(player, treatment_obj.applied_to)
    if not injury then
        -- Injury healed while bandage was on — just clean up bandage side
        treatment_obj.applied_to = nil
        treatment_obj._state = "soiled"
        return true
    end

    -- 2. Clear injury → treatment reference
    injury.treatment = nil

    -- 3. If injury is still active/treated, it may resume damage
    local injury_def = load_injury_definition(injury.type)
    local state_def = injury_def.states[injury._state]
    if state_def and state_def.damage_per_tick then
        injury.damage_per_tick = state_def.damage_per_tick
    end

    -- 4. Clear treatment → injury reference
    treatment_obj.applied_to = nil

    -- 5. Transition bandage FSM: applied → soiled
    treatment_obj._state = "soiled"

    -- 6. Bandage returns to player inventory (already there, just no longer in-use)
    return true
end
```

### Edge Cases

| Scenario | Behavior |
|---|---|
| Injury healed while bandage applied | Bandage auto-transitions to `soiled`. `applied_to` cleared. Injury removed from array. |
| Player drops bandage while applied | **Blocked.** Engine rejects DROP for items with `applied_to ~= nil`. |
| Player has two bandages on two wounds | Each bandage tracks its own `applied_to`. Removal targets the specified bandage. |
| Remove without specifying which bandage | If player has one applied bandage, auto-target. If multiple, disambiguate. |

---

## 4. Accumulation Damage Math

### Core Formula

Health is **derived**, not stored. It is computed every tick from max health minus all active injury damage:

```
health = max_health - sum(injury.damage for all injuries in player.injuries)
```

### Accumulation Per Tick

Each turn (360 game seconds), every injury's `damage_per_tick` is added to its running `damage` total:

```lua
--- Compute total health drain per tick from all untreated injuries.
--- @param player table — player.lua instance
--- @return number — total damage per tick
function injury_system.compute_total_drain(player)
    local total_drain = 0
    for _, injury in ipairs(player.injuries) do
        total_drain = total_drain + (injury.damage_per_tick or 0)
    end
    return total_drain
end

--- Compute current derived health.
--- @param player table — player.lua instance
--- @return number — current health (>= 0)
function injury_system.compute_health(player)
    local total_damage = 0
    for _, injury in ipairs(player.injuries) do
        total_damage = total_damage + (injury.damage or 0)
    end
    return math.max(0, player.max_health - total_damage)
end
```

### Worked Examples

**Example 1: Two bleeding wounds, no treatment**

```
max_health = 100
injuries:
  bleeding-a7f3: damage = 15, damage_per_tick = 5
  bleeding-b2c1: damage = 10, damage_per_tick = 5

Turn N:
  health = 100 - (15 + 10) = 75
  total_drain = 5 + 5 = 10/turn

Turn N+1:
  bleeding-a7f3.damage = 15 + 5 = 20
  bleeding-b2c1.damage = 10 + 5 = 15
  health = 100 - (20 + 15) = 65
  total_drain = 10/turn (unchanged — both still bleeding)
```

**Example 2: One wound bandaged, one untreated**

```
max_health = 100
injuries:
  bleeding-a7f3: damage = 20, damage_per_tick = 0  (bandaged → treated state)
  bleeding-b2c1: damage = 15, damage_per_tick = 5  (untreated → active state)

Turn N:
  health = 100 - (20 + 15) = 65
  total_drain = 0 + 5 = 5/turn  (only untreated wound drains)

Turn N+1:
  bleeding-a7f3.damage = 20 + 0 = 20  (frozen — bandage stops accumulation)
  bleeding-b2c1.damage = 15 + 5 = 20
  health = 100 - (20 + 20) = 60
  total_drain = 5/turn
```

**Example 3: Bandage applied with healing_boost**

```
max_health = 100
injuries:
  bleeding-a7f3:
    damage = 20
    damage_per_tick = 0  (treated)
    treatment = { type = "bandage", healing_boost = 2 }
    _timer = { remaining = 14400 }  (40 turns to heal normally)

Each tick, timer decrements by: 360 seconds × healing_boost(2) = 720 effective seconds
Actual turns to heal: 14400 / 720 = 20 turns (half the normal time)

When timer expires → treated → healed (terminal)
Engine removes injury from player.injuries[]
health rises: 100 - 0 = 100 (injury damage gone)
Bandage auto-transitions to soiled (applied_to cleared)
```

### Summary Table

| Scenario | damage_per_tick | Drain Effect |
|---|---|---|
| Untreated bleeding | 5 | +5 damage/turn, health drops |
| Bandaged bleeding | 0 | Frozen, no further drain |
| Two untreated bleedings | 5 + 5 = 10 | +10 damage/turn combined |
| One bandaged + one untreated | 0 + 5 = 5 | Only untreated drains |
| Bandage removed (injury reverts) | State's `damage_per_tick` | Drain resumes at state rate |

---

## 5. Integration Checklist for Bart

### New Functions Required in `src/engine/injuries.lua`

| Function | Purpose |
|---|---|
| `injury_targeting.resolve(player, target_str, cures_list)` | Resolve player text → injury instance |
| `injury_targeting.format_options(treatable)` | Disambiguation prompt for multiple matches |
| `injury_treatment.apply(player, treatment_obj, injury)` | Dual-bind treatment to injury |
| `injury_treatment.remove(player, treatment_obj)` | Unbind treatment, transition bandage to soiled |
| `injury_system.compute_total_drain(player)` | Sum damage_per_tick across all injuries |
| `injury_system.tick_injury(injury, elapsed)` | Per-injury tick with healing_boost support |

### Verb Handler Changes

| Verb | Handler Change |
|---|---|
| `apply` / `use` | Call `injury_targeting.resolve()`, then `injury_treatment.apply()` |
| `remove` / `unwrap` | Find applied treatment in inventory, call `injury_treatment.remove()` |
| `wash` / `clean` | Check `requires_tool = "water_source"`, transition soiled → clean |
| `drop` | Block if `treatment_obj.applied_to ~= nil` |

### Data Flow Diagram

```
Player: "apply bandage to bleeding wound"
  │
  ├─ Parser → verb="apply", object="bandage", target="bleeding wound"
  │
  ├─ Engine: inventory_find(player.inventory, "bandage")
  │   └─ Found: bandage instance, _state = "clean"
  │
  ├─ Engine: injury_targeting.resolve(player, "bleeding wound", {"bleeding", "minor-cut"})
  │   └─ Found: bleeding-a7f3 in player.injuries[]
  │
  ├─ Engine: Validate bandage.cures contains injury.type ("bleeding" ∈ {"bleeding", "minor-cut"})
  │   └─ Pass
  │
  ├─ Engine: injury_treatment.apply(player, bandage, bleeding-a7f3)
  │   ├─ bandage.applied_to = "bleeding-a7f3"
  │   ├─ bandage._state = "applied"
  │   ├─ injury.treatment = { type="bandage", item_id="bandage", healing_boost=2 }
  │   ├─ injury._state = "treated"
  │   └─ injury.damage_per_tick = 0
  │
  └─ Output: "You press the bandage firmly against the wound and wrap it tight."
```

---

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-TARGET001 | Injury targeting uses priority-ordered matchers | Flexible input: players can say "bleeding wound", "left arm", or just "apply bandage" for single-injury cases. |
| D-TARGET002 | Auto-target when only one treatable injury exists | Reduces friction. "Apply bandage" just works when unambiguous. |
| D-TARGET003 | Dual binding (treatment ↔ injury) | Both sides know about the relationship. Prevents orphaned references. Engine can traverse either direction. |
| D-TARGET004 | Treatment objects stay in inventory while applied | Bandage is still "carried" — just marked in-use. Simpler than moving to a separate "equipped" slot. |
| D-TARGET005 | `healing_boost` is a timer multiplier, not damage reduction | Accelerates healing time without changing the damage model. Clean separation of concerns. |
| D-TARGET006 | Removal resumes injury's state-defined `damage_per_tick` | Removing a bandage from an active wound means it starts bleeding again. Consequence for premature removal. |
| D-TARGET007 | Drop blocked for applied treatments | Prevents "drop bandage" from silently orphaning the injury reference. Player must remove first, then drop. |

---

## Related

- [injuries.md](injuries.md) — Injury FSM system, ticking, derived health
- [inventory.md](inventory.md) — Object storage, inventory traversal
- [health.md](health.md) — Derived health computation
- [injury-template-example.md](injury-template-example.md) — Canonical injury template format
