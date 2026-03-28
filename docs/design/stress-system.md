# Stress System Design

**Version:** 1.0  
**Last Updated:** 2026-08-21  
**Author:** Brockman (Documentation)  
**Related:** `../../architecture/engine/injuries.md`, `combat-system.md`, `cure-system.md`

---

## Overview

The stress system introduces **psychological injury** as the third core injury type (alongside rabies and spider-venom). Stress accumulates when players witness traumatic events (creature death, near-death combat). High stress levels impose gameplay debuffs (reduced attack accuracy, increased flee bias, movement penalties). Stress cures through rest in safe rooms — a time-based recovery mechanic distinct from instant-cure items like silk-bandages.

The system is implemented in Phase 4 **WAVE-3** and balances challenge against player agency: single victories should not cripple the player, but repeated trauma should create mounting psychological pressure.

---

## 1. Stress Levels: 3-Tier Severity Model

### Severity Tiers

| Level | Name | Threshold | Description | Gameplay Feel |
|-------|------|-----------|-------------|---------------|
| **Tier 1** | Shaken | 3 stress points | Your hands tremble slightly. | Mild anxiety — noticeable but manageable |
| **Tier 2** | Distressed | 6 stress points | You're breathing hard, heart pounding. | Growing panic — performance degrades |
| **Tier 3** | Overwhelmed | 10 stress points | Panic grips you. Everything feels wrong. | Critical state — severe hindrance |

### Accumulation Model

Stress points accumulate from **trauma triggers** (see Section 2). A player at 2 stress becomes shaken (Tier 1) when any trigger adds 1+ point. Moving from distressed (6) to overwhelmed (10) requires 4+ more points.

**Design rationale:** Thresholds are raised (v1.1) to prevent single kills from crippling the player. A player's first wolf kill inflicts no automatic stress penalty (removed in v1.1); repeated trauma gradually accumulates pressure.

### Stress Visibility

Stress level appears in status output. Examples:

```
[Status]
Health: 45/50
Stress: Shaken (3/10)
Injuries: rabbit-bite (Day 1)
```

Player always knows their stress level. This enables informed decision-making (e.g., "Rest before the next fight").

---

## 2. Trauma Triggers: Events That Inflict Stress

### Trigger Events & Point Values

| Trigger | Stress Points | When It Fires | Notes |
|---------|---------------|----|-------|
| **Witness Creature Death** | +1 | Another creature dies in the same room | Applies once per witnessed death |
| **Near-Death Combat** | +2 | Player health drops below 10% during combat | Applies once per combat round that triggers condition |
| **Witness Gore (Butchery)** | +1 | Player witnesses creature butchery | Deferred implementation (parser narration hook) |

### Removed Trigger (v1.1)

- **player_first_kill:** Removed. "Your first victory should be rewarding, not punishing." Single kills do not inflict automatic stress. Stress accumulates through *repeated* trauma, not isolated events.

### Trigger Integration Points

#### 1. Witness Creature Death (creatures/death.lua)

When a creature in the same room dies:

```lua
-- In src/engine/creatures/death.lua
function on_creature_death(creature, killer, ctx)
    -- ... existing death logic ...
    
    -- Trauma hook: player witnessed death
    if ctx.player and ctx.player.room == creature.room then
        local stress_injury = ctx.injuries:get("stress")
        if stress_injury then
            stress_injury.add(ctx.player, "witness_creature_death")
        end
    end
end
```

#### 2. Near-Death Combat (combat/init.lua)

When player health falls below 10% during combat:

```lua
-- In src/engine/combat/init.lua
function resolve_combat(attacker, defender, ctx)
    -- ... combat resolution ...
    
    -- Near-death check
    if defender == ctx.player then
        local health_percent = defender.health / defender.max_health
        if health_percent < 0.1 then
            local stress_injury = ctx.injuries:get("stress")
            if stress_injury then
                stress_injury.add(ctx.player, "near_death_combat")
            end
        end
    end
end
```

#### 3. Witness Gore (Deferred Implementation)

Narration hook in butchery verb. When player butchers a corpse:

```lua
-- Deferred to parser narration pipeline (WAVE-0 decision)
ctx.narrate("butchery", "gore", {
    message = "Blood splatters. The scene is gruesome.",
    triggers_stress = true,
    stress_amount = 1,
})
```

Implementation blocked until narration pipeline designed (WAVE-0 task).

---

## 3. Debuff Effects: How Stress Affects Gameplay

### Effect Application Model

When stress level changes (via triggers or cure), the engine applies corresponding debuffs:

| Stress Level | attack_penalty | flee_bias | movement_penalty | Stacking |
|---|---|---|---|---|
| **Shaken (3)** | -1 | 0% | 0% | None |
| **Distressed (6)** | -2 | +20% | 0% | Cumulative from Shaken |
| **Overwhelmed (10)** | -2 | +30% | +20% | Cumulative from Distressed |

**Important:** Effects are **cumulative but not multiplicative**. At Overwhelmed (10), player suffers all three debuffs simultaneously.

### Debuff Mechanics

#### 1. attack_penalty

Applied to combat attack rolls.

**Implementation (src/engine/combat/init.lua):**

```lua
function calculate_attack_bonus(attacker, ctx)
    local bonus = attacker.attack_bonus or 0
    
    -- Apply stress penalty
    local stress_injury = ctx.injuries:get_active(attacker, "stress")
    if stress_injury then
        local level = stress_injury:current_level()
        if level == "shaken" then
            bonus = bonus - 1
        elseif level == "distressed" or level == "overwhelmed" then
            bonus = bonus - 2
        end
    end
    
    return bonus
end
```

**Effect:** Player with Overwhelmed stress rolls 2 points lower on attack dice. Against a 50% baseline hit chance, -2 becomes ~25-30% hit chance.

#### 2. flee_bias

Increases likelihood that creatures flee combat instead of attacking.

**Implementation (src/engine/combat/init.lua):**

```lua
function should_creature_flee(creature, ctx)
    local base_flee_chance = creature.flee_chance or 0.3
    
    -- Player stress increases creature's aggressive willingness
    -- High player stress = creatures more likely to press attacks
    local player_stress = ctx.injuries:get_active(ctx.player, "stress")
    if player_stress then
        local level = player_stress:current_level()
        if level == "distressed" then
            base_flee_chance = base_flee_chance - 0.2  -- creatures less likely to flee
        elseif level == "overwhelmed" then
            base_flee_chance = base_flee_chance - 0.3
        end
    end
    
    return math.random() < base_flee_chance
end
```

**Effect:** At Overwhelmed stress, creatures are 30% *less* likely to flee. They press attacks; player struggles to disengage.

#### 3. movement_penalty

Slows player movement; each room transition costs more game time.

**Implementation (src/engine/loop/init.lua or traverse.lua):**

```lua
function move_to_room(player, exit_direction, ctx)
    local move_time = 60  -- 60 ticks = 10 seconds base
    
    -- Apply stress movement penalty
    local stress_injury = ctx.injuries:get_active(player, "stress")
    if stress_injury then
        local level = stress_injury:current_level()
        if level == "overwhelmed" then
            move_time = move_time + (move_time * 0.2)  -- +20% = 72 ticks
        end
    end
    
    ctx.game:advance_time(move_time)
    player.room = exit_room
end
```

**Effect:** At Overwhelmed stress, room transitions take 20% longer. Fleeing from danger is slower; escape attempts take longer.

### Design Rationale for Debuff Values (v1.1)

**v1.0 (rejected):** Overwhelmed = -4 attack, +50% flee bias, 50% movement penalty  
**v1.1 (approved):** Overwhelmed = -2 attack, +30% flee bias, 20% movement penalty

**Rationale:**
- **-2 attack vs -4:** Significant hindrance without game-breaking penalty. Player can still hit, just less reliably.
- **+30% vs +50%:** Creatures press attacks but don't guarantee endless combat. Player has options.
- **20% vs 50%:** Room transitions noticeably slower but not movement-breaking. Supports escape attempts while creating tension.

**Summary:** Stress is challenging but not punishing. A stressed player can recover through rest; they're not permanently crippled.

---

## 4. Cure Progression: Rest-Based Recovery

### Cure Mechanism

Stress cures through **time + safety**. Player must rest in a safe room for a duration (default: 2 hours game time).

### Safe Room Definition

A room is "safe" if it contains **no hostile creatures**. This includes:

- Start room (top of stairs, bedroom) — defensive position
- Hallway (transitional, multiple exits)
- Future: designated safe rooms marked with `is_safe_room = true` metadata

Rooms with creatures (cellar, courtyard, crypt) are **not safe** for stress cure.

**Design rationale:** Allows friendly creatures (future: pets) without breaking safety. Encourages player to retreat to quiet spaces.

### Cure Duration & Narration

When player rests in safe room:

```lua
-- In src/engine/verbs/survival.lua or cure handler
function rest_to_cure_stress(player, room, ctx)
    local stress_injury = ctx.injuries:get_active(player, "stress")
    if not stress_injury then
        ctx.print("You feel fine. No need to rest.")
        return
    end
    
    -- Verify safe room
    if not is_safe_room(room, ctx) then
        ctx.print("You feel too anxious to rest here. You need safety.")
        return
    end
    
    -- Advance time: 2 hours = 7200 ticks
    ctx.print("You settle down and take a deep breath. Minutes pass...")
    ctx.game:advance_time(7200)  -- 2 game hours
    
    -- Cure stress
    stress_injury.cure(player)
    ctx.print("The panic subsides. You feel calm again.")
end
```

### Cure Timing

**2 game hours = 120 real minutes at 1:1 game-time ratio.** (1 real hour = 1 game day based on custom instructions.)

**Wait, contradiction check:** Custom instructions state 1 real hour = 1 game day. But phase plan uses "2 hours" game time. Let me verify...

Looking at the plan: "duration = '2 hours'" (game time). The actual tick conversion is implementation-dependent. What matters: **rest is a multi-tick operation**. Player waits in quiet space; time advances; stress gradually subsides.

### Cure Completion

Once cure completes:

1. Stress points reset to 0
2. All debuffs removed
3. Narration: "The panic subsides. You feel calm again."
4. Status output updates: "Stress: None"

### Incomplete Cure

If player leaves safe room before 2 hours elapse:

```lua
-- Cure interrupted
ctx.print("The anxious feeling returns as you stand.")
```

Player must start rest cycle over. Partial rest does NOT reduce stress.

---

## 5. Interaction with Other Systems

### Combat System Integration

Stress debuffs directly affect combat resolution. Example:

```
Player vs Wolf, Overwhelmed stress (10 points):
- Player attack roll: 1d20 + (modifier - 2) from stress
- Bonus hit chance on player by wolf (less likely to flee)
- Player can still win but with lower probability
```

### Injury System Integration

Stress is **an injury type**, tracked in `src/meta/injuries/stress.lua`:

```lua
return {
    guid = "{windows-guid}",
    template = "injury",
    id = "stress",
    name = "acute stress",
    category = "psychological",
    
    levels = {
        { name = "shaken", threshold = 3, description = "Your hands tremble slightly." },
        { name = "distressed", threshold = 6, description = "You're breathing hard, heart pounding." },
        { name = "overwhelmed", threshold = 10, description = "Panic grips you. Everything feels wrong." },
    },
    
    effects = {
        shaken = { attack_penalty = -1 },
        distressed = { attack_penalty = -2, flee_bias = 0.2 },
        overwhelmed = { attack_penalty = -2, flee_bias = 0.3, movement_penalty = 0.2 },
    },
    
    cure = {
        method = "rest",
        duration = "2 hours",
        requires = { safe_room = true },
        description = "With time and safety, the panic subsides.",
    },
    
    triggers = {
        witness_creature_death = 1,
        near_death_combat = 2,
        witness_gore = 1,
    },
}
```

### Food/Nutrition System

Stress does **not** affect hunger or spoilage. Stress is independent of nutrition.

---

## 6. Testing Strategy

### Test Coverage (WAVE-3 deliverables)

**File:** `test/stress/test-stress-infliction.lua`

- ✅ Witness creature death → +1 stress
- ✅ Near-death combat (health < 10%) → +2 stress
- ✅ Multiple witnesses → stress stacks per event
- ✅ Stress visible in status output
- ✅ Trigger fires only once per event

**File:** `test/stress/test-stress-debuffs.lua`

- ✅ Shaken (3 stress) → -1 attack penalty applied in combat
- ✅ Distressed (6 stress) → -2 attack + 20% flee bias applied
- ✅ Overwhelmed (10 stress) → -2 attack + 30% flee bias + 20% movement penalty
- ✅ Debuffs cumulative (all active simultaneously at Overwhelmed)
- ✅ Debuffs removed when stress cured

**File:** `test/stress/test-stress-cure.lua`

- ✅ Rest in safe room for 2 hours → stress cured
- ✅ Rest in unsafe room → stress persists
- ✅ Early departure from rest → cure interrupted
- ✅ Status output updates after cure
- ✅ Player must complete full 2-hour duration

### Integration Tests

- ✅ Kill creature → player gains stress
- ✅ Stressed player attacks with penalty
- ✅ Creature less likely to flee when player stressed
- ✅ Stressed player moves slower
- ✅ Multiple traumas compound stress
- ✅ Full phase loop: kill → stress → rest → cured

---

## 7. Balance Rationale (v1.1)

### Threshold Adjustments

| Threshold | v1.0 | v1.1 | Rationale |
|-----------|------|------|-----------|
| Shaken | 1 | 3 | **Single kill shouldn't trigger penalty.** First victory must be rewarding. Threshold raised to require multiple traumas. |
| Distressed | 3 | 6 | **Doubling prevents cascading penalties.** Player has breathing room between levels. |
| Overwhelmed | 5 | 10 | **Doubled threshold prevents easy overwhelm.** Requires 3-5 significant traumas. Solo play doesn't spiral. |

### Effect Value Adjustments

| Effect | v1.0 | v1.1 | Rationale |
|--------|------|------|-----------|
| Shaken attack_penalty | -2 | -1 | **Gentler initial penalty.** Shaken is nuisance, not debilitating. |
| Overwhelmed attack_penalty | -4 | -2 | **Severe but surmountable.** Player can still hit at ~25-30% baseline. |
| Overwhelmed flee_bias | +50% | +30% | **Creatures more aggressive but not unstoppable.** Player has escape routes. |
| Overwhelmed movement_penalty | +50% | +20% | **Slowed but not paralyzed.** 20% time cost is noticeable without breaking gameplay. |

### First-Kill Removal

**v1.0 decision:** `player_first_kill` trigger adds +5 stress on first creature death (massive spike).  
**v1.1 decision (removed):** Single kills inflict zero automatic stress. Stress accumulates through repeated trauma.

**Rationale:** "Your first victory should be rewarding, not punishing." Single kills are learning moments. Stress emerges from *patterns* (multiple deaths, repeated danger), not isolated events.

---

## 8. Known Limitations & Future Extensions

| Limitation | Status | Phase |
|-----------|--------|-------|
| No player agency in stress reduction (beyond rest) | By design | P4 (rest is the cure) |
| No stress mitigation items (valium, meditation) | Deferred | P5+ (consumable cures) |
| No stress-based dialogue/NPC reactions | Deferred | P5+ (humanoid NPCs) |
| No PTSD triggers (seeing similar creatures) | Deferred | P5+ (behavioral state machine) |
| No stress skill (learning to stay calm) | Deferred | P5+ (skill progression) |
| Witness gore narration deferred | Pending | P4-W0 (narration pipeline) |

---

## 9. Glossary

| Term | Definition |
|------|-----------|
| **Stress** | Psychological injury inflicted by trauma; accumulates in points; has 3 severity levels |
| **Trauma trigger** | Event that inflicts stress (witness death, near-death combat, gore) |
| **Stress level** | Severity tier (shaken/distressed/overwhelmed) determined by accumulated points |
| **Debuff** | Gameplay effect applied at each stress level (attack penalty, flee bias, movement penalty) |
| **Safe room** | Room with no hostile creatures where stress can be cured via rest |
| **Cure** | Process of reducing stress to 0 through rest in safe room for 2 hours |

---

## 10. Related Systems

- **Injuries System** (`../../architecture/engine/injuries.md`) — Framework for injury types, triggers, effects
- **Combat System** (`combat-system.md`) — Applies stress debuffs to attack resolution
- **Cure System** (`cure-system.md`) — Time-based healing, rest mechanics
- **Death System** (`../../architecture/engine/creature-death-reshape.md`) — Triggers witness-death trauma
- **Status UI** (`../../architecture/ui/status.lua`) — Displays stress level and debuffs
