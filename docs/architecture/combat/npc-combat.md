# NPC Combat Architecture

**Scope:** NPC-vs-NPC resolution, turn order, morale/flee, witness narration  
**Owner:** Bart (Architecture Lead)  
**References:** `src/engine/combat/init.lua`, `src/engine/combat/npc-behavior.lua`, `src/engine/creatures/init.lua`

---

## NPC Combat Resolution Flow

When two or more NPCs fight, combat uses the **same unified combatant pipeline** as player combat. The resolution follows 6 phases:

1. **INITIATE** — Determine turn order (speed, size, player-last tiebreak)
2. **DECLARE** — Attacker picks weapon and target zone via `npc_behavior.select_*()` or falls back to random
3. **RESPOND** — Defender auto-selects response (dodge/block/flee/counter) from `combat.behavior.defense`
4. **RESOLVE** — Compute hit severity, penetrate tissue layers, map to damage
5. **NARRATE** — Generate witness-visible text (light-dependent, budgeted)
6. **UPDATE** — Mutate defender health, inflict injuries, check death/morale

**Code entry point:**
```lua
local result = combat.run_combat(context, attacker, defender)
```

If both combatants are NPCs, `run_combat()` internally calls `npc_behavior` modules to populate stance, target zone, and defense choice. The damage calculation itself is **stance-agnostic** — all combatants use the same material/tissue/severity pipeline.

---

## Combatant Interface

Any creature (NPC or player) entering combat must provide:

### Required Fields
```lua
combat = {
    speed = 5,              -- Tier in turn order (higher first)
    size = "medium",        -- Size class: tiny/small/medium/large/huge
                            -- Affects zone hit chance and size modifier
    natural_weapons = {     -- Array of { id, name, material, type, force }
        { id = "fangs", material = "tooth-enamel", type = "pierce", force = 3 }
    }
}

body_tree = {               -- Zone → tissue layers (filled at instance time)
    head = {
        size = 2,
        vital = true,
        tissue = { "skin", "bone", "organ" }
    },
    body = {
        size = 3,
        tissue = { "hide", "flesh", "organ" }
    }
}

health = 30                 -- Current health (clamped to [0, max_health])
max_health = 30             -- For morale: health / max_health < flee_threshold
```

### Optional Fields (NPC-specific)
```lua
combat.behavior = {
    attack_pattern = "aggressive",   -- Maps to engine stance
    defense = "dodge",               -- Auto-selected response type
    target_priority = "weakest",     -- "weakest"=vital zones, "threatening"=largest
}

-- Morale system (checked after RESOLVE phase)
flee_threshold = 0.3        -- Fraction of max_health; flee if health falls below
cornered_bonus = 1.5        -- Attack multiplier when no valid exits (fallback)

-- Location for flee pathfinding
location = "forest-1"       -- Room ID (set by creatures.tick)
```

---

## Turn Order Algorithm

Multi-combatant fights resolve in **priority order**:

```lua
-- Pseudocode from M.initiate()
function turn_order(combatants)
    local sorted = {}
    for _, c in ipairs(combatants) do
        sorted[#sorted + 1] = c
    end
    
    table.sort(sorted, function(a, b)
        local a_speed = a.combat and a.combat.speed or 0
        local b_speed = b.combat and b.combat.speed or 0
        
        if a_speed ~= b_speed then
            return a_speed > b_speed  -- Higher speed first
        end
        
        -- Tiebreak: smaller size acts first (more agile)
        local a_size_mod = SIZE_MODIFIERS[a.combat.size] or 1.0
        local b_size_mod = SIZE_MODIFIERS[b.combat.size] or 1.0
        if a_size_mod ~= b_size_mod then
            return a_size_mod < b_size_mod
        end
        
        -- Final tiebreak: player always acts last (humanoid disadvantage)
        return not is_player(a)
    end)
    return sorted
end
```

**Size modifiers:**
- `tiny`: 0.5 (acts first in tiebreak)
- `small`: 1.0
- `medium`: 2.0
- `large`: 4.0
- `huge`: 8.0

This ensures faster creatures and smaller creatures act before slower/larger ones, with the player at a slight initiative disadvantage.

---

## active_fights Tracking

The engine tracks **ongoing multi-combatant fights** in `context.active_fights`:

```lua
context.active_fights = {
    [fight_id] = {
        id = "forest-1_cat_rat_0",     -- Unique ID (room + participants + seed)
        combatants = { cat, rat },     -- Ordered by turn_order()
        room_id = "forest-1",
        round = 1,
        narration_budget = 6,          -- Lines remaining this round
        narration_used = 0,
    }
}
```

### Fight Lifecycle

**Create** — When NPC attacks NPC:
```lua
local fight = {
    id = room_id .. "_" .. math.random(10000),
    combatants = turn_order({ attacker, defender }),
    room_id = attacker.location or defender.location,
    round = 1,
    narration_budget = 6,
    narration_used = 0,
}
context.active_fights[fight.id] = fight
context.combat_active = true  -- Signal to creatures.tick() to suppress wander
```

**Round Loop** — Each game tick executes one exchange per combatant pair (or subset for 3+ combatants):
1. `attacker = combatants[next_priority]`
2. `defender = combatants[(next_priority % #combatants) + 1]`
3. `result = combat.resolve_exchange(attacker, defender, ...)`
4. Emit narration if budget allows, update morale
5. Check death/flee → prune combatant list
6. If `#combatants <= 1`, **resolve fight**

**Resolve** — When fight ends (all dead or fled):
```lua
context.active_fights[fight.id] = nil
context.combat_active = nil  -- Allow wander again
```

---

## Morale & Flee System

### Flee Threshold Check

After RESOLVE phase, check defender health:

```lua
if defender.health / defender.max_health < (defender.flee_threshold or 0.3) then
    -- Trigger flee logic
    local exits = get_valid_exits(context, defender.location, defender)
    if #exits > 0 then
        -- Flee to random exit
        local exit = exits[math.random(#exits)]
        defender.location = exit.target
        -- Emit narration: "{creature} flees toward {direction}!"
        fight.combatants = remove(fight.combatants, defender)  -- Drop from fight
    else
        -- Cornered: no valid exits
        defender.cornered = true
        -- Next attack gets × 1.5 force multiplier
    end
end
```

### Creature-Specific Thresholds

Per creature metadata (set by Flanders in `src/meta/creatures/*.lua`):

| Creature | Threshold | Reasoning |
|----------|-----------|-----------|
| Rat | 0.3 | Fearful, flees early |
| Cat | 0.4 | Cautious, abandons weak opponent |
| Wolf | 0.2 | Pack tactic, fights longer |
| Spider | 0.1 | Territorial, rarely flees |

### Cornered Fallback

When a creature has no valid exits, it cannot flee. Instead:

```lua
-- In combat resolution, cornered creatures get × 1.5 attack force
if creature.cornered then
    base_force = base_force * 1.5
    -- Stance forces balanced regardless
end
```

This models desperation — a trapped creature fights harder.

---

## Witness Narration Tiers

Combat text is **locality-aware** and **light-dependent**:

### Tier 1: Same Room + Light
**Condition:** Player in same room as fight, light available  
**Output:** Visual, third-person, action-heavy  
**Example:**  
```
"The cat pounces on the rat, fangs sinking into its flank."
"The rat shrieks and writhes, blood streaming from the wound."
```

### Tier 2: Same Room + Dark
**Condition:** Player in same room but dark  
**Output:** Audio-only, sensation + sound, no visual details  
**Example:**  
```
"You hear a wet crack and a sharp scream in the darkness."
"In the dark: a thrashing sound, then sudden silence."
```

### Tier 3: Adjacent Room (Any Light)
**Condition:** Player within 1 room distance  
**Output:** Distant echo, 1 line max, muted severity  
**Example:**  
```
"Distant sounds of conflict drift from the north."
"A faint cry echoes from the other side of the door."
```

### Tier 4: Out of Range
**Condition:** Player 2+ rooms away  
**Output:** Nothing (narration suppressed)

---

## Narration Budget Protocol

To prevent **witness narration spam** (the CBG blocker), each round has a **6-line cap**:

```lua
function narration.emit(text, context, fight)
    if fight.narration_used >= fight.narration_budget then
        if not text:match("CRITICAL") and not text:match("dies") then
            -- Defer GRAZE/DEFLECT; keep HIT/CRITICAL/DEATH always
            return
        end
    end
    
    print(text)
    fight.narration_used = fight.narration_used + 1
end
```

### Exemptions

- **Player's own action:** Always shown (not counted against cap)
- **Death narration:** Always shown, counts toward cap
- **Critical hits (HIT/CRITICAL severity):** Always shown
- **Morale break narration:** Counts toward cap (1 line each)
- **GRAZE/DEFLECT in grazes:** Deferred to next round with marker *"[The melee continues...]"*

### Budget Reset

At the start of each new round:
```lua
fight.narration_used = 0
fight.narration_budget = 6
```

---

## Integration with Other Systems

### Creature Stimulus
When an NPC-vs-NPC fight occurs, the combat module emits stimuli:

```lua
-- After attack resolves
creatures.emit_stimulus(room_id, "creature_attacked", {
    attacker_id = attacker.id,
    defender_id = defender.id,
    attacker_name = attacker.name,
    defender_name = defender.name,
})

-- On death
creatures.emit_stimulus(room_id, "creature_died", {
    creature_id = defender.id,
    creature_name = defender.name,
})
```

Nearby creatures in adjacent rooms react via `creature.reactions` table (fear drive delta).

### Injury System
Combat damage maps to injury types via severity:

```lua
local SEVERITY_INJURY_MAP = {
    edged = { "minor-cut", "bleeding", "bleeding", "bleeding" },  -- by severity 1–4
    pierce = { "minor-cut", "bleeding", "bleeding", "bleeding" },
    blunt = { "bruised", "bruised", "crushing-wound", "crushing-wound" },
}
```

Injuries are inflicted when `damage > 0` and the defender has an `injuries` field.

### NPC Behavior Decisions

Three decision functions in `npc_behavior.lua`:

1. **`select_response(creature, attacker)`** — Returns defender response type ("dodge", "block", "flee", "counter", or nil)
2. **`select_stance(creature)`** — Maps `combat.behavior.attack_pattern` → engine stance (aggressive/defensive/balanced)
3. **`select_target_zone(creature, defender)`** — Uses `combat.behavior.target_priority` to bias zone selection (vital/threatening zones)

---

## Code References

| Function | File | Purpose |
|----------|------|---------|
| `combat.initiate(a, d)` | `init.lua` | Turn order (speed, size, player-last) |
| `combat.declare(attacker, weapon)` | `init.lua` | Weapon + stance selection |
| `combat.respond(defender, response)` | `init.lua` | Defense action declaration |
| `combat.resolve_exchange(a, d, w, zone, resp)` | `init.lua` | Full 6-phase exchange |
| `combat.run_combat(context, a, d)` | `init.lua` | Player or NPC entry point |
| `npc_behavior.select_response()` | `npc-behavior.lua` | NPC defense choice |
| `npc_behavior.select_stance()` | `npc-behavior.lua` | NPC attack pattern → stance |
| `npc_behavior.select_target_zone()` | `npc-behavior.lua` | NPC zone targeting |
| `narration.generate(result, light)` | `narration.lua` | Light-aware narration |
| `creatures.emit_stimulus()` | `creatures/init.lua` | Witness stimuli to other creatures |

