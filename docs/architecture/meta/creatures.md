# Creature Architecture — Complete Reference

**Last updated:** 2026-08-17  
**Audience:** Engine developers modifying `src/engine/creatures/` or `src/meta/creatures/`  
**Owner:** Bart (Architecture Lead)

---

## Overview

Creatures are objects with autonomous behavior. Architecturally, a creature is a standard Lua object table that declares `animate = true` — this single flag enrolls it in the **creature tick pipeline**, where the engine evaluates drives, reactions, and actions every turn without any creature-specific engine code.

This document covers the full engine lifecycle: how creature `.lua` files are structured, loaded, ticked, and eventually transformed on death.

### Key Source Files

| Path | Role |
|------|------|
| `src/meta/templates/creature.lua` | Base template — defaults for all creatures |
| `src/meta/creatures/*.lua` | Creature definitions (rat, wolf, spider, cat, bat) |
| `src/engine/creatures/init.lua` | Master tick, public API, module wiring |
| `src/engine/creatures/actions.lua` | Utility scoring + action execution |
| `src/engine/creatures/stimulus.lua` | Stimulus queue: emit, process, clear |
| `src/engine/creatures/navigation.lua` | BFS distance, exit validation, movement |
| `src/engine/creatures/death.lua` | Death reshape (D-14 metamorphosis) |
| `src/engine/creatures/respawn.lua` | Timer-based respawn after death |
| `src/engine/creatures/territorial.lua` | Territory markers, BFS radius, marker response |
| `src/engine/creatures/pack-tactics.lua` | Alpha selection, attack stagger, retreat |
| `src/engine/creatures/predator-prey.lua` | Prey detection in room |
| `src/engine/creatures/morale.lua` | Health-based morale/flee checks |
| `src/engine/creatures/inventory.lua` | Drop inventory on death |
| `src/engine/creatures/loot.lua` | Probabilistic loot table processing |

---

## 1. Creature Template Structure

The creature template (`src/meta/templates/creature.lua`) defines the base shape that every creature inherits. A creature `.lua` file returns a Lua table with `template = "creature"` — the engine deep-merges the template defaults underneath.

### Required Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `animate` | boolean | `true` | Gate for creature tick enrollment |
| `on_feel` | string | `"Warm, alive."` | Primary sense in darkness (Principle 6) |
| `initial_state` | string | `"alive-idle"` | FSM starting state |
| `_state` | string | `"alive-idle"` | Current FSM state (mutable at runtime) |
| `states` | table | 4 base states | FSM state definitions |
| `behavior` | table | `{default="idle", ...}` | Behavior metadata for action scoring |
| `health` / `max_health` | number | `10` | Mortality tracking |
| `size` | string | `"small"` | Containment constraint / exit filtering |
| `weight` | number | `1.0` | Containment weight |
| `material` | string | `"flesh"` | Physical material type |

### Optional Fields (engine handles nil safely)

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `drives` | table | `{}` | Internal motivations (hunger, fear, curiosity) |
| `reactions` | table | `{}` | Stimulus → response mapping |
| `movement` | table | `{speed=1, ...}` | Locomotion rules |
| `awareness` | table | `{sight_range=1, ...}` | Perception ranges |
| `combat` | table | nil | Natural weapons, armor, combat behavior |
| `body_tree` | table | nil | Anatomical zone targeting |
| `death_state` | table | nil | In-place reshape on death (D-14) |
| `loot_table` | table | nil | Probabilistic drops on death |
| `respawn` | table | nil | Timer-based respawn after death |
| `sounds` | table | nil | Sound events keyed by state/event |

### Creature-Specific Fields vs. Object Fields

The template inherits standard object properties (`guid`, `id`, `name`, `keywords`, `description`, `portable`, `container`, `categories`, `mutations`). On top of these, the creature template adds:

```lua
animate = true,              -- THE creature flag
behavior = { ... },          -- autonomous decision metadata
drives = { ... },            -- internal motivations
reactions = { ... },         -- stimulus -> response
movement = { ... },          -- locomotion rules
awareness = { ... },         -- perception ranges
health = 10,                 -- mortality
max_health = 10,
alive = true,
```

---

## 2. Loading and Discovery

Creature files live in `src/meta/creatures/` (e.g., `rat.lua`, `wolf.lua`). The engine loads them through the **same sandboxed loader** used for all objects — there is no creature-specific loader code.

### Loading Pipeline

```
creature.lua source → loadstring() with sandbox env → pcall(chunk) → returned table
                                                          │
                                              deep_merge(creature_template, instance)
                                                          │
                                                   resolved object
                                                          │
                                              registry:register(id, object)
```

1. **Sandbox execution:** `loader.load_source()` compiles and executes the `.lua` file in a restricted environment. Only `math`, `string`, `table`, `ipairs`, `pairs`, `type`, `tonumber`, `tostring`, `pcall`, `error` are available. No `os`, `io`, `require`, or `debug`.

2. **Template resolution:** The engine finds `template = "creature"` and loads `src/meta/templates/creature.lua`. `deep_merge(template, instance)` copies all template defaults, then overlays the creature's fields. Instance always wins for any key it defines. For nested tables, the merge is recursive.

3. **Instance placement:** Room `.lua` files reference creatures by `type_id` (GUID) in their `instances` array. `loader.resolve_instance()` looks up the base class, deep-merges any room-level overrides, assigns the instance-specific `id`, and clears the base `guid`.

4. **GUID registration:** Each creature instance is registered in the global registry via `registry:register()`. The registry indexes by `id` (primary) and `guid` (secondary). `find_by_keyword()` matches against `keywords` and `name`. `find_by_category("creature")` returns all creatures.

### Multiple Instances

A single `rat.lua` can produce multiple rat instances (e.g., `cellar-rat-1`, `cellar-rat-2`). Each gets a unique `id` from the room's instance specification. The base file is the prototype; room placement creates concrete instances.

---

## 3. Creature Engine — Tick Pipeline

The creature engine (`src/engine/creatures/init.lua`) runs once per game turn, called from the main loop **after fire propagation and before the injury tick**.

### Master Tick — `M.tick(context)`

```
M.tick(context)
  │
  ├─ 1. Collect: scan registry for all objects with animate == true
  │
  ├─ 2. For each creature: pcall(M.creature_tick, context, creature)
  │     └─ pcall catches errors — one creature's bug never crashes the loop
  │
  ├─ 3. Advance respawn timers (spawn new creatures when ready)
  │
  └─ 4. Clear stimulus queue
```

**Safety:** Every `creature_tick()` is wrapped in `pcall()`. A malformed creature definition produces no output instead of a crash.

### Single Creature Tick — `M.creature_tick(context, creature)`

This evaluates one creature's full behavior cycle in a fixed order:

```
creature_tick(context, creature)
  │
  ├─ 0.  EARLY EXIT: skip if animate == false or _state == "dead"
  │
  ├─ 0a. Territorial: reduce fear if creature is in home territory
  ├─ 0b. Territory marking: place marker on room entry (avoid duplicates)
  ├─ 0c. Foreign marker response: "avoid" (flee) or "challenge" (go aggressive)
  ├─ 0d. Pack retreat: flee immediately if health < 20% of max
  │
  ├─ 1.  UPDATE DRIVES: advance each drive.value by its decay_rate, clamp
  │
  ├─ 2.  PROCESS STIMULI: match queued events to creature.reactions
  ├─ 2a. Bait check: hungry creature drawn to food objects
  ├─ 2b. Ambush check: stay hidden until trigger condition fires
  │
  ├─ 3.  SCORE ACTIONS: utility scoring with random jitter
  │      └─ Pack stagger: only alpha attacks this turn
  │
  └─ 4.  EXECUTE highest-scoring action
```

### Action Scoring — Utility Model

Each possible action gets a numeric score. The highest score wins. Random jitter (`math.random() * 2`) prevents deterministic behavior.

| Action | Score Formula | Condition |
|--------|---------------|-----------|
| `idle` | 10 (constant) | Always available |
| `wander` | `(curiosity × 0.3) + (wander_chance × 0.2)` | Suppressed during active combat |
| `flee` | `fear × 1.5` | Only if `fear >= flee_threshold` |
| `vocalize` | `(fear × 0.3) + (curiosity × 0.1)` | When partially frightened |
| `attack` | `(aggression × 0.5) + (hunger × 0.5)` | Only if prey present in room |
| `create_object` | `creates_object.priority` (default 15) | Only if `behavior.creates_object` declared |

Territorial creatures in their home territory get an additional `aggression × 0.3` boost to attack score.

### Action Execution

| Action | What happens |
|--------|-------------|
| `idle` | Sets `_state = "alive-idle"`. No movement. |
| `wander` | Picks a random valid exit (respecting door/size constraints). Moves creature. Sets `_state = "alive-wander"`. Emits narration if player present. |
| `flee` | Same as wander movement, but `_state = "alive-flee"` and different narration. |
| `vocalize` | Emits the current state's `on_listen` text if player is in same room. No state change. |
| `attack` | Selects prey via `predator_prey.select_prey_target()`. Delegates to `combat.run_combat()`. On kill: death reshape + respawn registration + stimulus emission. Morale checks on both combatants. |
| `create_object` | Reads `behavior.creates_object` metadata. Enforces `cooldown` and `max_per_room`. Creates object in room. |

---

## 4. FSM States for Creatures

Creatures use the **same FSM engine** as inanimate objects (`src/engine/fsm/init.lua`). The difference is in what triggers transitions and what states mean.

### Standard Creature States

The base template defines four states. Creature definitions extend these:

| State | Template default | Meaning |
|-------|-----------------|---------|
| `alive-idle` | ✓ | Resting, alert. Default behavior. |
| `alive-wander` | ✓ | Moving around aimlessly. |
| `alive-flee` | ✓ | Escaping a perceived threat. |
| `dead` | ✓ | Health = 0. `animate = false`, `portable = true`. |

Creatures extend this with custom states:

| Creature | Additional states |
|----------|------------------|
| Wolf | `alive-patrol`, `alive-aggressive` |
| Spider | `alive-web-building` |
| Cat | `alive-hunt`, `alive-groom` |
| Bat | `alive-roosting`, `alive-flying` |

### Transition Triggers

Creature transitions declare a `verb` field that determines what triggers them:

| Verb | Trigger source | Example |
|------|---------------|---------|
| `"_tick"` | Autonomous — evaluated by creature engine each turn | `alive-idle → alive-wander` on `wander_roll` |
| `"_damage"` | Health-based — evaluated on damage receipt | `* → dead` on `health_zero` |
| `"<verb>"` | Player-initiated — standard verb dispatch | Same as object FSM transitions |

The `"*"` wildcard in `from` matches any state, enabling death transitions from any alive state:

```lua
{ from = "*", to = "dead", verb = "_damage", condition = "health_zero" }
```

### State Property Overrides

Each state can override top-level creature properties. The engine uses the state-level value when present, falling back to the creature-level value:

```lua
states = {
    dead = {
        description = "A dead rat lies on its side.",
        animate = false,    -- removes from creature tick
        portable = true,    -- player can pick up
        on_feel = "Cooling fur over a limp body.",
        on_smell = "Blood and musk.",
    },
}
```

### How Creature FSM Differs from Object FSM

| Aspect | Object FSM | Creature FSM |
|--------|-----------|--------------|
| Transition trigger | Player verbs, timers, effects | `_tick` (autonomous), `_damage`, player verbs |
| State naming | Arbitrary (e.g., `lit`, `unlit`) | Convention: `alive-*` prefix for living, `dead` for death |
| `animate` flag | Not used | State can set `animate = false` to exit tick |
| `room_presence` | Static per state | Changes each tick based on behavior |
| Transition frequency | On player action or timer | Every tick (behavior engine continuously re-evaluates) |

---

## 5. Drive System

Drives are internal motivations (numeric values, typically 0–100) that bias action scoring. The engine reads drive metadata generically — it has no knowledge of what "hunger" or "fear" mean.

### Drive Update — Each Tick

```lua
-- From creatures/init.lua: update_drives()
drive.value = drive.value + drive.decay_rate
-- Clamped to [drive.min or 0, drive.max or 100]
```

| Drive pattern | `decay_rate` | Behavior |
|--------------|-------------|----------|
| Growing need (hunger) | `+2` | Value rises each tick. Creature becomes hungrier. |
| Decaying emotion (fear) | `-10` | Value drops each tick. Creature calms down naturally. |
| Slow growth (curiosity) | `+1` | Value rises slowly. Drives exploration over time. |

### Drive Definition Shape

```lua
drives = {
    hunger = {
        value = 50,             -- current value (mutated each tick)
        decay_rate = 2,         -- per-tick delta
        max = 100,              -- upper clamp
        min = 0,                -- lower clamp (default 0)
        satisfy_action = "eat", -- action that resets this drive
        satisfy_threshold = 80, -- value at which creature seeks satisfaction
    },
}
```

The engine reads `value`, `decay_rate`, `max`, `min` for the tick update. Fields like `satisfy_action` and `satisfy_threshold` are consumed by specific action handlers during scoring.

If `drives` is nil or empty, the update is a no-op — creature behavior still works, it just won't be influenced by internal motivations.

### How Drives Feed Into Actions

Drives don't directly cause actions. They **bias action scores**:

- High `fear.value` → higher `flee` score → creature more likely to flee
- High `hunger.value` → higher `attack` score (via hunger component) → creature more likely to hunt
- High `curiosity.value` → higher `wander` score → creature explores more

---

## 6. Reaction System

Reactions map external stimuli to drive deltas and narration. They are declared as metadata tables in the creature definition. The engine processes them through a global stimulus queue.

### Stimulus Flow

```
Game event (player enters, noise, light change)
  │
  └─ creatures.emit_stimulus(room_id, stimulus_type, data)
       │
       └─ Queued in stimulus_queue[]
            │
            └─ stimulus.process() matches against each creature's reactions table
                 │
                 ├─ Distance filter: ≤ 1 room (same room = full, adjacent = half)
                 ├─ Apply drive deltas (e.g., fear += 40)
                 └─ Emit message if creature is in same room as player
```

### Current Emission Points

| Event | Stimulus type | Emitted from |
|-------|--------------|-------------|
| Player moves into room | `"player_enters"` | Movement verbs |
| FSM light change | `"light_change"` | `fsm/init.lua` |
| Loud effect | `"loud_noise"` | `effects.lua` |
| Creature attacked | `"creature_attacked"` | `actions.lua` |
| Creature killed | `"creature_died"` | `actions.lua` |

### Reaction Definition Shape

```lua
reactions = {
    player_enters = {
        action = "evaluate",    -- re-evaluate behavior
        fear_delta = 35,        -- add 35 to fear (scaled by distance)
        message = "A rat freezes, beady eyes fixed on you. Its whiskers quiver.",
    },
    player_attacks = {
        action = "flee",        -- force flee action
        fear_delta = 80,        -- spike fear
        message = "The rat squeals and bolts!",
    },
},
```

### Distance Scaling

Stimuli are processed with distance attenuation:

| Distance | Scale | Effect |
|----------|-------|--------|
| 0 (same room) | 1.0 | Full `fear_delta` applied. Message emitted. |
| 1 (adjacent) | 0.5 | Half `fear_delta` applied. No message. |
| 2+ | — | Stimulus ignored entirely. |

### Queue Lifecycle

The queue accumulates stimuli during the entire game turn. After all creatures process stimuli, `M.clear_stimuli()` drains it. Stimuli are consumed exactly once per tick.

---

## 7. Creature Death

When a creature's health reaches zero, the engine orchestrates a multi-step death sequence.

### Death Sequence

```
health ≤ 0 detected
  │
  ├─ 1. Check creature.death_state
  │     ├─ Present → reshape_instance() (D-14 in-place metamorphosis)
  │     └─ Absent → legacy FSM: creature._state = "dead" (backward compat)
  │
  ├─ 2. Capture loot_table before reshape (defensive copy)
  │
  ├─ 3. reshape_instance(creature, death_state, registry, room)
  │     ├─ Switch template: "creature" → "small-item" or "furniture"
  │     ├─ Overwrite identity: name, description, keywords, room_presence
  │     ├─ Overwrite sensory: on_feel, on_smell, on_listen, on_taste
  │     ├─ Set animate = false, alive = false, portable = death_state.portable
  │     ├─ Apply optional metadata: food, crafting, container
  │     ├─ Install spoilage FSM if death_state.states defined
  │     ├─ Ensure creature in room.contents exactly once
  │     └─ Clear creature metadata: behavior, drives, reactions, movement,
  │        awareness, health, max_health, body_tree, combat = nil
  │
  ├─ 4. Instantiate byproducts to room floor
  ├─ 5. Drop creature inventory to room floor
  ├─ 6. Roll loot table + instantiate drops
  ├─ 7. Clear loot_table from reshaped corpse
  ├─ 8. Print reshape_narration (if declared)
  └─ 9. Trauma hook: add_stress("witness_creature_death") if player in room
```

### D-14 Alignment: In-Place Metamorphosis

`reshape_instance()` modifies the creature table **in-place**. The GUID is preserved — the same object that was a living wolf becomes a dead wolf corpse. This is NOT file-swap mutation (`mutation.mutate()`). The creature's death form lives in the same `.lua` file as its living form, declared in the `death_state` table.

```lua
-- Before reshape
instance.template = "creature"
instance.animate = true
instance.behavior = { aggression = 70, ... }

-- After reshape
instance.template = "furniture"   -- wolf is too large to carry
instance.animate = false
instance.behavior = nil            -- creature metadata cleared
instance.food = { category = "meat", cookable = false }
```

### Tick Exit After Death

The creature tick's first check is the dead guard:

```lua
if not creature.animate or creature._state == "dead" then
    return messages  -- early exit, no behavior evaluation
end
```

After reshape sets `animate = false`, the creature permanently exits the tick pipeline.

### Sound on Death

When `animate = false` is set during reshape, sound hooks (`stop_by_owner`) silence any ambient loops the creature was playing. The dead state's `on_listen` field provides the new (typically silent) sound description.

### Spoilage FSM

Reshaped corpses can declare a spoilage lifecycle that uses the standard FSM timer engine:

```
fresh ──(timer_expired)──> bloated ──(timer_expired)──> rotten ──(timer_expired)──> bones
```

Each state overrides sensory/food properties (e.g., bloated → `cookable = false`, rotten → `on_smell` overridden with decay text).

### Backward Compatibility

If a creature has no `death_state`, the engine falls back to the legacy FSM dead state (`creature._state = "dead"`). No errors, no crashes.

### Respawn After Death

Creatures with `respawn` metadata are registered for timed respawn on death:

```lua
respawn = {
    timer = 60,           -- ticks until respawn
    home_room = "cellar", -- room to spawn in
    max_population = 3,   -- cap on simultaneous living instances
},
```

The respawn module:
1. Records the creature's base data when death is processed.
2. Each tick, `respawn.tick()` decrements timers.
3. When timer reaches zero **and** population cap not exceeded **and** player is not in the home room, a new instance spawns.
4. If the player is watching (`home_room == player_room`), the timer resets — no spawn-in-face.

---

## 8. Creature vs. Object — Architectural Differences

Creatures and objects share the same foundational systems (loader, registry, FSM, containment). The differences are behavioral, gated by `animate = true`.

### What's Shared

| System | Creature behavior | Object behavior |
|--------|------------------|-----------------|
| Loader | Same sandbox, same `load_source()` | Identical |
| Template resolution | `deep_merge(template, instance)` | Identical |
| Registry | Same `register()`, `find_by_keyword()` | Identical |
| FSM engine | Same `fsm/init.lua` for state transitions | Identical |
| Sensory properties | `on_feel` mandatory, per-state overrides | Identical |
| Containment | Same size/weight/capacity constraints | Identical |
| Sound integration | Same `scan_object()`, `trigger()` pipeline | Identical |

### What's Different

| Aspect | Creature | Object |
|--------|----------|--------|
| `animate` flag | `true` — enrolls in creature tick | Absent or `false` |
| Autonomous behavior | Acts every turn via drives, reactions, scoring | Passive — responds only to player verbs |
| Movement | Can move between rooms autonomously | Stays where placed |
| Death lifecycle | `death_state` reshape + loot + respawn + trauma | Mutation (file-swap via `mutation.mutate()`) |
| FSM transitions | `_tick` (autonomous), `_damage` (health) | Player verbs and timers only |
| Additional metadata | `behavior`, `drives`, `reactions`, `movement`, `awareness`, `combat`, `body_tree`, `loot_table`, `respawn` | None of these fields |
| Categories | Always includes `"creature"` | Typically `"furniture"`, `"container"`, etc. |

### The `animate` Gate

The `animate` flag is the **single boolean** that separates creatures from objects at the engine level:

```lua
-- In M.tick(): only animate objects enter the creature pipeline
for _, obj in ipairs(list_objects(context.registry)) do
    if obj.animate then
        creatures[#creatures + 1] = obj
    end
end
```

Everything else in the engine (loader, registry, FSM, containment, parser) treats creatures identically to objects. The creature engine is an **opt-in behavior layer**, not a parallel system.

### Principle 8 Compliance

The creature behavior engine has **zero creature-specific code**. All behavior differences between a rat and a wolf emerge from their metadata:

| What varies | Where declared | Engine reads generically |
|-------------|---------------|------------------------|
| Fear threshold | `behavior.flee_threshold` | Compared to `drives.fear.value` |
| Wander frequency | `behavior.wander_chance` | Multiplied into wander score |
| Territorial marking | `behavior.territorial` | Boolean gate + `behavior.territory` room ID |
| Pack behavior | Same `id` creatures in same room | `get_pack_in_room()` matches by `obj.id` |
| Web spinning | `behavior.creates_object` | Generic object creation pipeline |
| Prey targets | `behavior.prey` | Array scanned by `predator_prey` module |
| Ambush hiding | `behavior.ambush` | Metadata-driven trigger check |

Adding a new creature type requires **only** a new `.lua` file in `src/meta/creatures/`. No engine code changes.

---

## Appendix A: Creature Engine Module Map

```
src/engine/creatures/
├── init.lua           Master tick, public API, registry abstraction
├── actions.lua        Utility scoring + action execution (idle, wander, flee, attack, etc.)
├── stimulus.lua       Stimulus queue: emit → queue → process → clear
├── navigation.lua     BFS distance, exit passability, NPC obstacle check
├── death.lua          reshape_instance() + handle_creature_death() (D-14)
├── respawn.lua        Timer-based respawn with population cap
├── territorial.lua    Territory markers (create, find, evaluate, expire, BFS radius)
├── pack-tactics.lua   Alpha selection (highest health), attack stagger, retreat check
├── predator-prey.lua  Prey detection via behavior.prey array
├── morale.lua         Health-ratio morale check → flee trigger
├── inventory.lua      Validate creature inventory, drop on death
└── loot.lua           4-pattern loot table: always, weighted, variable, conditional
```

## Appendix B: Creature Definition Checklist

Minimum viable creature (the engine handles nil safely for optional fields):

```lua
return {
    guid = "{new-guid}",
    template = "creature",
    id = "my-creature",
    name = "a creature",
    keywords = {"creature"},
    description = "A creature.",

    animate = true,
    on_feel = "...",               -- MANDATORY (primary dark sense)

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = { description = "...", room_presence = "..." },
        dead = { description = "...", animate = false, portable = true },
    },
    transitions = {
        { from = "*", to = "dead", verb = "_damage", condition = "health_zero" },
    },

    behavior = { default = "idle" },
    health = 10,
    max_health = 10,
}
```

## See Also

- **Creature Template (detailed):** `docs/architecture/meta/creature-template.md`
- **Creature Loading (detailed):** `docs/architecture/meta/creature-loading.md`
- **Creature Behavior Engine (detailed):** `docs/architecture/meta/creature-behavior-engine.md`
- **Creature Combat Integration:** `docs/architecture/meta/creature-combat-integration.md`
- **Core Principles:** `docs/architecture/meta/core-principles.md` — Principles 0, 0a, 8
- **FSM Lifecycle:** `docs/architecture/engine/fsm-object-lifecycle.md`
- **Instance Model:** `docs/architecture/meta/instance-model.md`
- **Effects Pipeline:** `docs/architecture/engine/effects-pipeline.md`
