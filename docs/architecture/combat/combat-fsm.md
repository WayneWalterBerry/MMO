# Combat FSM (Finite State Machine)

**File:** `src/engine/combat/init.lua`  
**Author:** Bart (Architecture)  
**Date:** 2026-07-XX  
**Version:** 1.0 (GATE-6)

---

## Overview

Combat is a 6-phase state machine that orchestrates a single attack/defense exchange:

1. **INITIATE** — Determine attack order (initiative)
2. **DECLARE** — Attacker chooses weapon and target zone
3. **RESPOND** — Defender chooses response (block/dodge/counter/flee)
4. **RESOLVE** — Calculate damage using weapon/defense properties
5. **NARRATE** — Generate severity-scaled combat text
6. **UPDATE** — Apply damage, trigger injuries, check for death

After each exchange, the system checks for **interrupts** (weapon break, stance ineffective, health crisis). On interrupt, the combat loop pauses and re-prompts the player for a new stance or action.

---

## Phase Constants

```lua
M.PHASE = {
    INITIATE = 1,
    DECLARE = 2,
    RESPOND = 3,
    RESOLVE = 4,
    NARRATE = 5,
    UPDATE = 6,
}
```

---

## Phase 1: INITIATE — Determine Turn Order

**Function:** `M.initiate(attacker, defender) -> (first_actor, second_actor)`

Initiative is determined by:

1. **Speed comparison** — Higher `combat.speed` acts first
2. **Tiebreaker 1** — Smaller size acts first (quicker targets)
3. **Tiebreaker 2** — Player acts first (if still tied)

**Code:**
```lua
function M.initiate(attacker, defender)
    local a_speed = attacker and attacker.combat and attacker.combat.speed or 0
    local d_speed = defender and defender.combat and defender.combat.speed or 0
    if a_speed ~= d_speed then
        return a_speed > d_speed and attacker or defender,
            a_speed > d_speed and defender or attacker
    end
    local a_size = attacker and attacker.combat and attacker.combat.size or "medium"
    local d_size = defender and defender.combat and defender.combat.size or "medium"
    local a_mod = SIZE_MODIFIERS[a_size] or 1.0
    local d_mod = SIZE_MODIFIERS[d_size] or 1.0
    if a_mod ~= d_mod then
        return a_mod < d_mod and attacker or defender,
            a_mod < d_mod and defender or attacker
    end
    return attacker, defender
end
```

**Example:**
- Player (speed=4, size=medium) vs Rat (speed=6, size=tiny)
- Rat's speed (6) > Player's speed (4) → **Rat acts first**

---

## Phase 2: DECLARE — Attacker Selects Action

**Function:** `M.declare(attacker, weapon, target_zone, opts) -> action`

The attacker declares:
- Which weapon to use (held or natural weapon)
- Which body zone to target (if aimed attack)
- Stance (aggressive/defensive/balanced)

**Return value:**
```lua
{
    weapon = normalized_weapon,       -- { id, name, material, combat = { type, force, message, ... } }
    target_zone = zone_id or nil,     -- "head", "arms", "torso", "legs", etc. (nil = random)
    stance = "aggressive"|"defensive"|"balanced",
}
```

**Weapon Resolution:**
- If no weapon provided, select first held item with `combat` table
- If no held weapon, use first natural weapon from `attacker.combat.natural_weapons`
- If no natural weapon, default to bare fist (blunt, force=2)

**Stance Modifiers:**
```lua
STANCE_MODIFIERS = {
    aggressive = { attack = 1.3, defense = 1.3 },
    defensive = { attack = 0.7, defense = 0.7 },
    balanced = { attack = 1.0, defense = 1.0 },
}
```

---

## Phase 3: RESPOND — Defender Chooses Response

**Function:** `M.respond(defender, response, opts) -> response_action`

The defender chooses how to react:

| Response | Effect | Defense Multiplier |
|----------|--------|-------------------|
| `block` | Raise shields/armor | 0.3× force |
| `dodge` | Attempt to evade (40% success) | 0× (if successful) / 1× (if failed) |
| `counter` | Attack while defending | 1× (defender hits back) |
| `flee` | Escape combat | 0.5× force (if successful) |
| (nil/default) | Stand and take it | 1× force |

**Return value:**
```lua
{
    type = "block"|"dodge"|"counter"|"flee"|nil,
    stance = "aggressive"|"defensive"|"balanced",
}
```

**Code:**
```lua
function M.respond(defender, response, opts)
    local r = response
    if type(r) == "table" then r = r.type end
    return {
        type = r,
        stance = opts and opts.stance or "balanced",
    }
end
```

---

## Phase 4: RESOLVE — Calculate Damage

**Function:** `M.resolve(attacker, defender, weapon, target_zone, response, opts) -> result`

This phase performs the actual combat calculation:

1. Determine if defender is in light or darkness
2. Apply stance modifiers to base force
3. Apply defense multiplier based on response type
4. Select target zone (aimed or random)
5. Penetrate tissue layers from outside-in
6. Determine deepest layer hit
7. Map layer to severity level

**Result table:**
```lua
{
    attacker = attacker_obj,
    defender = defender_obj,
    weapon = weapon_obj,
    zone = zone_id,                  -- "head", "arms", etc.
    tissue_hit = layer_name,         -- "skin", "flesh", "bone", "organ"
    severity = SEVERITY.HIT,         -- 0=DEFLECT, 1=GRAZE, 2=HIT, 3=SEVERE, 4=CRITICAL
    material_name = weapon_material,
    action_verb = "slashes",         -- weapon's combat.message
    light = true|false,              -- used for narration variant selection
    dodged = true|false,             -- if dodge succeeded
    fled = true|false,               -- if flee succeeded
    counter = true|false,            -- if counter is active
    damage = 0-10,                   -- health points reduced
    target_health = remaining_health,-- defender's health after damage
}
```

### Force Calculation

```
base_force = material.density × SIZE_MODIFIERS[attacker.size] × weapon.force × FORCE_SCALE

if is_player(attacker):
    base_force = base_force × STANCE_MODIFIERS[stance].attack

base_force = base_force × defense_multiplier (based on response type)

if base_force <= 0:
    severity = DEFLECT (no damage)
```

### Tissue Penetration

For **edged/pierce weapons:**
```lua
local edge_force = base_force * (mat.max_edge or 1)
for _, layer in ipairs(layers) do
    local layer_mat = get_material(layer)
    edge_force = edge_force - ((layer_mat.hardness or 1) * THICKNESS)
    if edge_force > 0 then
        deepest = layer  -- This layer penetrated
    else
        break  -- Stopped here
    end
end
```

For **blunt weapons:**
```lua
local remaining = base_force
for _, layer in ipairs(layers) do
    local layer_mat = get_material(layer)
    local transfer = remaining * (1.0 - (layer_mat.flexibility or 0))
    local layer_damage = transfer - ((layer_mat.hardness or 1) * THICKNESS * 0.5)
    if layer_damage > 0 then
        deepest = layer
    end
    remaining = transfer * 0.8  -- 20% energy lost per layer
    if remaining <= 0 then break end
end
```

### Severity Mapping

```lua
local function map_severity(layer)
    if not layer then return M.SEVERITY.DEFLECT end
    if layer == "organ" then return M.SEVERITY.CRITICAL end
    if layer == "bone" then return M.SEVERITY.SEVERE end
    if layer == "flesh" then return M.SEVERITY.HIT end
    return M.SEVERITY.GRAZE
end
```

---

## Phase 5: NARRATE — Generate Combat Text

**Function:** `M.narrate(result, light_level) -> text`

Generates severity-scaled, material-aware narration. See **Combat Narration** documentation for template details.

**Example outputs:**

Light (visual):
- DEFLECT: "The steel skitters off the rat's body as you swing."
- CRITICAL: "You plunge the dagger into the rat's flank, hitting something vital."

Dark (auditory/tactile):
- DEFLECT: "You hear a sharp clack as the blade glances off in the dark."
- CRITICAL: "A sickening crunch and spray of warmth — the blow is fatal."

---

## Phase 6: UPDATE — Apply Damage & State Changes

**Function:** `M.update(result, opts) -> updated_result`

Applies damage to defender and triggers system-level effects:

1. Reduce defender health by damage amount
2. Inflict injury via `injuries.inflict()` (if available)
3. Check for death (health ≤ 0)
4. Transition creature to `dead` state (if deceased)
5. Emit `creature_died` stimulus (for other creatures to react)

**Damage mapping by severity:**

| Severity | Damage | Example |
|----------|--------|---------|
| DEFLECT | 0 | Glances off |
| GRAZE | 1 | Minor scratch |
| HIT | 3 | Moderate wound |
| SEVERE | 6 | Major trauma |
| CRITICAL | 10 | Vital damage |

**Code:**
```lua
local damage_map = {
    [M.SEVERITY.DEFLECT] = 0,
    [M.SEVERITY.GRAZE] = 1,
    [M.SEVERITY.HIT] = 3,
    [M.SEVERITY.SEVERE] = 6,
    [M.SEVERITY.CRITICAL] = 10,
}
defender.health = math.max(0, defender.health - damage_map[result.severity])
```

### Death Transition

When a creature's health reaches 0:

```lua
if defender.health <= 0 then
    defender._state = "dead"
    defender.animate = false
    defender.portable = true
    defender.alive = false
    result.defender_dead = true
    
    -- Pull death narration from creature's dead state
    local dead_state = defender.states and defender.states.dead
    if dead_state then
        result.death_narration = dead_state.description or (defender.name .. " is dead.")
    end
end
```

---

## Full Exchange: resolve_exchange()

**Function:** `M.resolve_exchange(attacker, defender, weapon, target_zone, response, opts) -> full_result`

Runs all 6 phases in sequence:

```lua
function M.resolve_exchange(attacker, defender, weapon, target_zone, response, opts)
    local attack_action = M.declare(attacker, weapon, target_zone, opts)
    local defense_action = M.respond(defender, response, opts)
    local result = resolve_damage(attacker, defender, attack_action.weapon, 
                                   attack_action.target_zone, defense_action.type, opts)
    
    result.phase_log = {
        M.PHASE.INITIATE,
        M.PHASE.DECLARE,
        M.PHASE.RESPOND,
        M.PHASE.RESOLVE,
        M.PHASE.NARRATE,
        M.PHASE.UPDATE,
    }
    
    result.narration = M.narrate(result, result.light ~= false)
    result.text = result.narration
    
    local update_result = M.update(result, opts)
    if update_result then
        for k, v in pairs(update_result) do result[k] = v end
    end
    
    return result
end
```

---

## Interrupt Detection

**Function:** `M.interrupt_check(result, combat_state) -> interrupt_reason|nil`

Signals the combat loop to pause and re-prompt when:

1. **Weapon breaks** — Material failure during penetration
2. **Armor fails** — Tissue layer fully compromised
3. **Stance ineffective** — 2+ consecutive DEFLECT results
4. **Creature flees** — Morale break detected
5. **Critical health** — Health drops below 30%

**Code:**
```lua
function M.interrupt_check(result, combat_state)
    if not combat_state then return nil end
    if result.weapon_broke then return "weapon_break" end
    if result.armor_failed then return "armor_fail" end
    if result.severity == M.SEVERITY.DEFLECT then
        combat_state.deflect_streak = (combat_state.deflect_streak or 0) + 1
    else
        combat_state.deflect_streak = 0
    end
    if (combat_state.deflect_streak or 0) >= 2 then
        return "stance_ineffective"
    end
    return nil
end
```

---

## Hybrid Stance Model

**Status:** Implemented in WAVE-5 (Bart), verb integration in WAVE-6 (Smithers)

The stance system allows players to set a stance before combat, which auto-resolves multiple rounds without per-round input.

### Stance Types

```lua
STANCE_MODIFIERS = {
    aggressive = { attack = 1.3, defense = 1.3 },
    defensive = { attack = 0.7, defense = 0.7 },
    balanced = { attack = 1.0, defense = 1.0 },
}
```

### Auto-Resolve Loop (Smithers, verbs layer)

```
1. Prompt player: "Combat stance? > aggressive | defensive | balanced"
2. Loop until combat ends:
   a. Call M.resolve_exchange(attacker, defender, weapon, nil, nil, { stance = player_stance })
   b. Print round narration
   c. interrupt_reason = M.interrupt_check(result, combat_state)
   d. If interrupt_reason: re-prompt with options (new stance, flee, target zone)
   e. If combat_over or health <= 0: exit loop
```

### Headless Mode

In `--headless` mode (automated testing), auto-select `balanced` stance and never interrupt (run combat to completion).

---

## Combat Darkness Rules

**Light detection:**
```lua
local light = true
if opts and opts.light ~= nil then
    light = opts.light
elseif opts and presentation_ok and presentation and presentation.get_light_level then
    light = presentation.get_light_level(opts) ~= "dark"
end
```

**Darkness effects:**
- **Zone targeting disabled** — All attacks use random zone selection (60% accuracy disabled)
- **Narration variant** — Sound/tactile templates instead of visual (see Combat Narration doc)
- **No player feedback** — Player doesn't see exact zone hit or tissue layer

**Code:**
```lua
if not light then
    -- All zone attacks become random
    zone = weighted_zone(defender.body_tree, nil)  -- Random, not aimed
end
```

---

## Main Entry Point: run_combat()

**Function:** `M.run_combat(context, attacker, defender) -> full_exchange_result`

High-level function that orchestrates a complete combat encounter:

```lua
function M.run_combat(context, attacker, defender)
    local light = presentation.get_light_level(context) ~= "dark"
    if context then context.combat_active = true end
    
    local stance = context and context.combat_stance or "balanced"
    local weapon = pick_weapon(attacker)
    local result = M.resolve_exchange(attacker, defender, weapon, nil, nil, { light = light, stance = stance })
    
    if result.defender_dead then
        creatures.emit_stimulus(current_room.id, "creature_died", { ... })
    end
    
    if result.defender_dead or result.fled or result.combat_over then
        if context then context.combat_active = nil end
    end
    
    return result
end
```

---

## Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `FORCE_SCALE` | 0.1 | Base force tuning factor |
| `THICKNESS` | 200 | Hardness factor for penetration |
| Default accuracy | 0.6 | 60% chance to hit aimed zone |
| Dodge success rate | 0.4 | 40% chance dodge succeeds |
| Deflect streak threshold | 2 | Interrupts after 2 consecutive misses |

---

## See Also

- **Body Zone System:** `docs/architecture/combat/body-zone-system.md` — Zone selection and targeting
- **Damage Resolution:** `docs/architecture/combat/damage-resolution.md` — Force/penetration math
- **Combat Narration:** `docs/architecture/combat/combat-narration.md` — Template generation
- **Combat System (Design):** `docs/design/combat-system.md` — Player-facing guide
