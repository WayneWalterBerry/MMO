# Decision: Injury-Causing Object Hook Categories & Taxonomy

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-25  
**Status:** FINALIZED  
**Scope:** Engine architecture, object design, injury system integration  
**Audience:** Bart (engine lead), Flanders (object implementation), Smithers (injury system)

---

## Executive Summary

Two detailed design documents (Poison Bottle, Bear Trap) reveal a clear **taxonomy of engine hooks for injury-causing objects**. Different interaction patterns require different hook categories. This decision establishes the canonical hook categories that the engine must implement to support all injury-causing objects across the game.

**The four hook categories:**
1. **Consumption Hooks** — For ingestion-based injuries (poison, spoiled food)
2. **Contact Hooks** — For touch-based injuries (traps, hot objects)
3. **Proximity Hooks** — For room-level hazards (gas, pits, floor traps)
4. **Duration Hooks** — For ongoing injury ticks (bleeding, poison DoT)

---

## Problem Statement

**Before this decision:** It was unclear how different injury-causing objects should communicate with the engine. Should a poison bottle call the same hook as a bear trap? Do they both use `on_interact`? How does the engine distinguish between "injuries that happen when you swallow" vs. "injuries that happen when you touch"?

**Example confusion:**
- Bear trap fires on TAKE → should this call `on_take` or a generic `on_interact`?
- Poison bottle fires on DRINK → should this call `on_drink` or `on_consume` or both?
- Future: Gas room fires on ENTER → should this call a different hook entirely?

Without clarity, object implementations will be inconsistent. Different objects will invent different hook names, making the engine harder to extend.

---

## Proposed Solution: Hook Taxonomy

### Category 1: Consumption Hooks

**What:** Injuries triggered by ingestion (drinking, eating, tasting)

**Hook names:**
- `on_consume(verb, severity)` — Universal consumption handler
- `on_drink()` — Specific to liquid consumption (alias: DRINK, SIP, GULP)
- `on_eat()` — Specific to solid consumption (alias: EAT, BITE, CHEW)
- `on_taste(severity)` — Lower-severity investigation (TASTE, LICK)

**Verbs that trigger:**
- DRINK, SIP, GULP, TASTE (for liquids)
- EAT, BITE, CHEW, CONSUME (for solids)

**Safety model:**
- Player can investigate via SMELL, TASTE without lethal consequence
- Full consumption (DRINK full bottle) causes injury
- Design: Fair warning allows safe investigation before consequence

**Objects using this category:**
- Poison bottles (all types)
- Spoiled food
- Contaminated water
- Potions (healing or harmful)
- Magical draughts
- Herbs, mushrooms, berries

**Implementation example:**
```lua
poison_bottle = {
  on_consume = function(self, verb, severity)
    -- verb: "drink", "sip", "gulp", "taste"
    -- severity: "low", "medium", "high"
    if verb == "taste" then
      -- Small amount, no lethal injury, just warning
      return self:inflict_warning_symptom()
    else
      -- Full consumption
      return self:inflict_poisoning_injury(severity)
    end
  end
}
```

---

### Category 2: Contact Hooks

**What:** Injuries triggered by touching/grasping an object

**Hook names:**
- `on_take(verb)` — Triggered when player attempts to take the object
- `on_touch(verb)` — Triggered when player attempts to touch/examine closely
- `on_interact(verb)` — Fallback for general interaction (if more specific hook not defined)

**Verbs that trigger:**
- TAKE, GRAB, PICK UP, SEIZE (primary trigger)
- TOUCH, HANDLE, GRASP, FEEL (secondary trigger)
- EXAMINE (may or may not trigger, depending on design)

**Safety model:**
- Player can observe object from distance via LOOK, SMELL
- Observation is safe, interaction is risky
- Design: Sensory investigation educates but doesn't injure

**Objects using this category:**
- Bear traps (armed state)
- Hot objects (stove, fire, heated metal)
- Sharp edges (broken glass, blades)
- Venomous creatures (snakes, spiders — future)
- Electrical hazards (future)
- Thorny plants (future)

**Implementation example:**
```lua
bear_trap_armed = {
  on_take = function(self, verb)
    if self.is_armed then
      return self:inflict_crushing_injury()
    else
      -- Trap is disarmed, safe to take
      return true
    end
  end,
  
  on_touch = function(self, verb)
    -- Touch is same risk as take for this object
    return self:on_take(verb)
  end
}
```

---

### Category 3: Proximity Hooks (FUTURE)

**What:** Injuries triggered by entering a room or traversing an area

**Hook names:**
- `on_traverse(direction)` — Called when player moves in a direction and enters a room with hazard
- `on_enter(room_id)` — Called when player enters a specific room
- `on_step(location)` — Called when player steps on a specific floor location (granular)

**Verbs that trigger:**
- GO, MOVE (implied — no explicit verb, automatic on traversal)
- N, S, E, W, UP, DOWN (direction verbs that trigger room change)

**Safety model:**
- Player cannot avoid without prior knowledge or detection
- Design: Can detect via careful investigation (SEARCH, LISTEN, SMELL) to get warning
- Once triggered, injury is applied automatically

**Objects using this category (FUTURE):**
- Floor traps (hidden pit trap)
- Gas rooms (poison cloud, noxious atmosphere)
- Collapsing ceilings
- Pressure plates (weight-triggered)
- Cursed areas (status effects)

**Implementation example (pseudo-code for future):**
```lua
floor_trap_hidden = {
  on_traverse = function(self, player, direction)
    if player.awareness_level < self.detect_threshold then
      -- Player didn't notice, trap triggers
      return self:inflict_falling_injury()
    else
      -- Player detected the trap, they can see it now
      self.revealed = true
      return false  -- No injury
    end
  end
}
```

---

### Category 4: Duration Hooks

**What:** Injuries that apply effects each turn while active

**Hook names:**
- `on_tick(turn_count)` — Called once per game turn, applies ongoing damage/effects
- `on_worsening(severity_increase)` — Called when injury severity increases (untreated)
- `on_healing(amount)` — Called when injury receives treatment

**Triggers:**
- `on_tick` fires every turn automatically while injury is active
- `on_worsening` fires when injury worsens (e.g., bleeding untreated for N turns)
- `on_healing` fires when player applies treatment (bandage, antidote)

**Safety model:**
- Player must monitor injury status via `injuries` verb
- Player must identify injury type and find correct treatment
- Design: Injury informs (symptoms text), treatment cures

**Objects using this category:**
- Bleeding wounds (tick until bandaged)
- Poisoning (tick until antidote applied)
- Burning (tick until cooled with water)
- Infections (tick and worsen if untreated)
- Regeneration effects (tick as beneficial)

**Implementation example:**
```lua
poison_nightshade = {
  on_tick = function(self, player, turn_count)
    local damage = -2
    player.health = player.health + damage
    
    if turn_count == 1 then
      narrate("Your throat burns. Fire in your veins.")
    elseif turn_count == 5 then
      narrate("Hallucinations flicker at your vision's edge.")
    end
    
    if player.health <= 0 then
      player.die("Nightshade Poisoning (Untreated)")
    end
  end
}
```

---

## Hook Resolution & Dispatch

The engine resolves which hook to call based on verb + object properties:

```
Verb: DRINK
  → Is object consumable?
    YES → Call on_consume(verb="drink", severity=object.severity)
           Dispatch to on_drink() if defined
    NO → Error: "You can't drink that"

Verb: TAKE
  → Is object a trap and armed?
    YES → Call on_take(verb="take")
           Check object.on_take() for injury logic
    NO → Standard take behavior

Verb: GO NORTH
  → Enter new room
    → Check room for proximity hazards
    → Call on_traverse(direction="north")
    → If hazard, call on_enter(room_id) or on_step(location)

Every Turn:
  → For each active injury in player.injuries:
    → Call injury.on_tick(turn_count)
    → Apply damage, update symptoms, check for worsening
```

---

## Design Constraints & Principles

### Constraint 1: One Hook Per Interaction Pattern

Each interaction pattern (consume, touch, enter, tick) maps to exactly one hook category. Objects don't invent custom hooks.

**Why:** Consistency across the codebase. The engine knows exactly what to call.

### Constraint 2: Hook Names Are Verbs

Hook names use English verbs in imperative form: `on_consume`, `on_take`, `on_tick`. Not `whenConsumed` or `afterTouch`.

**Why:** Consistency with existing codebase. Easy to read: "on_X" = "when X happens."

### Constraint 3: Hooks Pass Context

Each hook receives parameters that let the object know *how* it was interacted with:

- `on_consume(verb, severity)` — How much was consumed (sip vs. gulp)
- `on_take(verb)` — Allows object to vary behavior per verb (GRAB vs. PICK UP)
- `on_traverse(direction)` — Allows room-level logic based on entry direction
- `on_tick(turn_count)` — Allows injury to vary text based on progression

**Why:** Objects can customize behavior without the engine hard-coding variations.

### Constraint 4: Hooks Are Optional

An object doesn't need to define a hook it doesn't use. If a poison bottle doesn't define `on_take`, the engine assumes it's not dangerous to take (only to consume).

**Why:** Simplicity. Not all objects need all hooks.

---

## Mapping: Objects → Hook Categories

| Object | Injury Type | Primary Hook | Secondary Hooks | Verbs |
|--------|---|---|---|---|
| Poison Bottle | Poisoning | on_consume | on_taste | DRINK, TASTE |
| Bear Trap | Crushing | on_take | on_touch | TAKE, TOUCH |
| Hot Stove (future) | Burning | on_touch | on_take | TOUCH, TAKE |
| Dart Trap (future) | Viper venom | on_take | on_traverse | TAKE, GO |
| Gas Room (future) | Poison | on_enter | on_tick | GO, (tick) |
| Floor Pit (future) | Falling | on_traverse | on_tick | GO, (tick) |
| Cursed Zone (future) | Curse | on_enter | on_tick | GO, (tick) |

---

## Implementation Roadmap

### Phase 1: Core Hooks (Level 1 MVP)

**Required for Level 1:**
- ✅ `on_consume()` — Poison bottle
- ✅ `on_take()` — Bear trap
- ✅ `on_tick()` — All injuries (bleeding, poison)

**Not required for Level 1 (Phase 2+):**
- `on_traverse()` — Room-level traps
- `on_enter()` — Gas rooms
- `on_step()` — Pressure plates

### Phase 2: Extended Hooks (Level 2+)

**Proximity hooks:**
- `on_traverse(direction)` — Pit traps, hidden floor hazards
- `on_enter(room_id)` — Gas rooms, cursed zones

### Phase 3: Advanced Hooks (Level 3+)

**Extended duration hooks:**
- `on_worsening(severity_change)` — Infection progression
- `on_healing(amount)` — Treatment response feedback
- `on_recovery(turn_count)` — Post-treatment recovery

---

## Testing Strategy

### Test Category 1: Consumption
- [ ] Sealed poison bottle: player reads label (safe)
- [ ] Open poison bottle: player smells (warning, safe)
- [ ] Open poison bottle: player tastes (pain, no injury)
- [ ] Open poison bottle: player drinks (injury applied)
- [ ] Generic antidote on nightshade poison (should fail)
- [ ] Nightshade antidote on poisoning (should succeed)

### Test Category 2: Contact
- [ ] Armed bear trap: player examines from distance (safe)
- [ ] Armed bear trap: player takes (injury applied)
- [ ] Armed bear trap: player touches (injury applied)
- [ ] Sprung bear trap: player can take (safe, already triggered)
- [ ] Sprung bear trap: player can disarm with skill + tool

### Test Category 3: Proximity (Phase 2+)
- [ ] Hidden pit trap: player enters room unknowingly (injury applied)
- [ ] Hidden pit trap: player searches first (detection avoids injury)
- [ ] Gas room: player enters (on_enter triggers, injury per turn)
- [ ] Gas room: player exits (injury stops ticking)

### Test Category 4: Duration
- [ ] Active poison: tick per turn applies damage
- [ ] Active poison: symptom text changes per turn
- [ ] Active poison: antidote applied stops ticking
- [ ] Active bleeding: tick per turn applies damage
- [ ] Active bleeding: bandage applied stops ticking

---

## Cross-References

- **Poison Bottle Design:** `docs/design/objects/poison-bottle.md` — Full design of consumption hooks
- **Bear Trap Design:** `docs/design/objects/bear-trap.md` — Full design of contact hooks
- **Injury System:** `docs/design/player/health-system.md` — How injuries tick and accumulate
- **Verb System:** `docs/design/verb-system.md` — How verbs dispatch to handlers
- **Engine Architecture:** `docs/architecture/engine/hooks.md` — Engine hook system (TBD)

---

## Approval & Sign-Off

**Decision Ready For:** Bart (engine lead), Flanders (object implementation)

**Implementation Notes for Bart:**
1. Create hook interface: `IHookable` with optional methods for all four categories
2. Verb-to-hook dispatch: CONSUME verb → call `on_consume()` if defined
3. FSM state tracking: Objects can define hooks per state (armed trap ≠ disarmed trap)
4. Hook context: Pass verb, severity, direction parameters to allow object customization

**Implementation Notes for Flanders:**
1. Poison bottle: Implement `on_consume()`, `on_taste()` hooks
2. Bear trap: Implement `on_take()`, `on_touch()` hooks
3. Test each hook with poison and trap separately
4. Follow FSM state changes during hook dispatch (SET state → TRIGGERED state)
