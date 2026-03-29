# Creature Behavior Engine — Engine Architecture

**Last updated:** 2026-08-16  
**Audience:** Engine developers modifying `src/engine/creatures/`  
**Owner:** Bart (Architecture Lead)  
**Prerequisite reading:** `docs/architecture/meta/creature-loading.md`, `docs/architecture/engine/creature-system.md`

---

## Overview

The creature behavior engine is a **generic, metadata-driven system** that evaluates autonomous behavior for all `animate == true` objects. It reads `drives`, `reactions`, `behavior`, `movement`, and `senses` metadata from creature definitions and executes them without any creature-specific engine code (Principle 8).

The engine lives in `src/engine/creatures/` and is split across these modules:

| Module | Responsibility |
|--------|----------------|
| `init.lua` | Master tick, public API, module wiring |
| `actions.lua` | Utility scoring + action execution |
| `stimulus.lua` | Stimulus queue: emit, process, clear |
| `navigation.lua` | BFS distance, exit validation, movement |
| `territorial.lua` | Territory markers, BFS radius, marker response |
| `pack-tactics.lua` | Alpha selection, attack stagger, retreat |
| `predator-prey.lua` | Prey detection in room |
| `morale.lua` | Health-based morale checks |
| `death.lua` | Death reshape (D-14) |
| `inventory.lua` | Creature inventory drop on death |
| `loot.lua` | Probabilistic loot table processing |
| `respawn.lua` | Timer-based respawn |

---

## 1. Master Tick — `M.tick(context)`

The master tick is called once per game turn from `src/engine/loop/init.lua`, **after fire propagation and before the injury tick**:

```lua
local creature_ok, creature_mod = pcall(require, "engine.creatures")
if creature_ok and creature_mod then
    local creature_msgs = creature_mod.tick(context)
    for _, msg in ipairs(creature_msgs or {}) do
        print(msg)
    end
end
```

### Tick Sequence

```
M.tick(context)
  │
  ├─ 1. Collect all animate objects from registry
  │     for _, obj in ipairs(registry:list()) do
  │         if obj.animate then creatures[] = obj end
  │     end
  │
  ├─ 2. For each creature: pcall(creature_tick, context, creature)
  │     └─ errors caught; game loop never crashes from creature bugs
  │
  ├─ 3. Advance respawn timers (spawn new creatures when ready)
  │
  └─ 4. Clear stimulus queue
```

**Safety:** Each `creature_tick()` is wrapped in `pcall()`. A bug in one creature's metadata never crashes the game loop.

---

## 2. Single Creature Tick — `M.creature_tick(context, creature)`

This function evaluates one creature's full behavior cycle. It runs in a fixed order:

```
creature_tick(context, creature)
  │
  ├─ 0.  Early exit: skip if animate == false or _state == "dead"
  │
  ├─ 0a. Territorial evaluation: reduce fear if in home territory
  ├─ 0b. Territory marking: place marker on room entry
  ├─ 0c. Territorial marker response: evaluate foreign markers
  ├─ 0d. Pack retreat: defensive flee if health < 20%
  │
  ├─ 1.  Update drives (hunger grows, fear decays, etc.)
  │
  ├─ 2.  Process stimuli (match queued events to reactions)
  ├─ 2a. Bait check (food-as-bait lure behavior)
  ├─ 2b. Ambush check (hide until trigger condition)
  │
  ├─ 3.  Score actions (utility scoring with random jitter)
  │      └─ Pack stagger: only alpha attacks this turn
  │
  └─ 4.  Execute highest-scoring action
```

---

## 3. Drive System

Drives are internal motivations (0-100) that bias behavior selection. The engine reads drive metadata generically — it has no knowledge of what "hunger" or "fear" mean.

### Drive Update — `update_drives(creature)`

Each tick, every drive value is advanced by its `decay_rate`:

```lua
drive.value = drive.value + drive.decay_rate
-- Clamped to [drive.min, drive.max]
```

| Drive pattern | decay_rate | Effect |
|---------------|------------|--------|
| Growing need (hunger) | `+2` | Value increases toward max → creature becomes hungry |
| Decaying emotion (fear) | `-10` | Value decreases toward min → creature calms down |
| Slow growth (curiosity) | `+1` | Value increases slowly → drives exploration |

### Drive Metadata Shape

```lua
drives = {
    hunger = {
        value = 50,        -- current value (mutated each tick)
        decay_rate = 2,    -- per-tick delta
        max = 100,         -- upper clamp
        min = 0,           -- lower clamp (default 0)
        satisfy_action = "eat",
        satisfy_threshold = 80,
    },
}
```

The engine reads `value`, `decay_rate`, `max`, `min`. All other fields (like `satisfy_action`, `satisfy_threshold`) are consumed by specific action handlers. If `drives` is nil or empty, the update is a no-op.

---

## 4. Stimulus System — `stimulus.lua`

Stimuli are events emitted by the engine that creatures react to. They flow through a global queue.

### Emission

Any engine module can emit stimuli via:

```lua
creatures.emit_stimulus(room_id, stimulus_type, data)
```

**Current emission points:**
- Player movement verb → `"player_enters"`
- FSM light change (`casts_light` flip) → `"light_change"` (emitted from `fsm/init.lua`)
- Effects pipeline (`effect.loud == true`) → `"loud_noise"` (emitted from `effects.lua`)
- Combat resolution → `"creature_attacked"`, `"creature_died"` (emitted from `actions.lua`)

### Queue Structure

```lua
stimulus_queue = {
    { room_id = "cellar", stimulus_type = "player_enters", data = { source = "player" } },
    { room_id = "cellar", stimulus_type = "loud_noise", data = { source = "sword" } },
}
```

### Processing — `stimulus.process(context, creature, helpers)`

For each queued stimulus:

1. **Compute distance** from creature's room to stimulus room via BFS (max depth 10).
2. **Distance filter:** Only creatures within distance ≤ 1 react.
   - Distance 0 (same room): full intensity (scale = 1.0)
   - Distance 1 (adjacent room): half intensity (scale = 0.5)
   - Distance > 1: ignored
3. **Match reaction:** Look up `creature.reactions[stimulus_type]`.
4. **Apply drive deltas:** `fear.value += reaction.fear_delta * scale` (clamped to min/max).
5. **Emit message:** If distance == 0 and reaction has `.message`, add to output.

### Queue Lifecycle

The queue accumulates stimuli during the entire game turn. After all creatures process, `M.clear_stimuli()` drains it. Stimuli are consumed exactly once per tick.

---

## 5. Action Scoring — `actions.score_actions(creature, context, helpers)`

The engine uses **utility scoring** to select creature behavior. Each possible action gets a numeric score; the highest score wins.

### Available Actions and Scoring

| Action | Base Score | Drive Influence | Condition |
|--------|-----------|-----------------|-----------|
| `idle` | 10 | — | Always available |
| `wander` | `(curiosity × 0.3) + (wander_chance × 0.2)` | Curiosity drive, `behavior.wander_chance` | Suppressed during active combat |
| `flee` | `fear × 1.5` | Fear drive | Only if `fear >= flee_threshold` |
| `vocalize` | `(fear × 0.3) + (curiosity × 0.1)` | Fear (10 < x < threshold) + curiosity | When partially frightened |
| `attack` | `(aggression × 0.5) + (hunger × 0.5)` | Aggression, hunger | Only if prey present in room |
| `create_object` | `creates_object.priority` (default 15) | — | Only if `behavior.creates_object` declared |

### Territorial Aggression Boost

When a creature is in its declared `behavior.territory` room, the attack score receives an additional `aggression × 0.3` bonus.

### Random Jitter

Every score receives `+ math.random() * 2` to prevent deterministic behavior. Two creatures with identical metadata will act differently.

### Selection

Scores are sorted descending. The top entry is executed.

---

## 6. Action Execution — `actions.execute_action(context, creature, action, helpers)`

### `idle`

Sets `creature._state = "alive-idle"`. No movement, no narration.

### `wander`

1. Calls `navigation.get_valid_exits()` to find passable exits.
2. **Territory leash:** If `behavior.territory` is set, filters exits to only `behavior.patrol_rooms` (or the territory room itself).
3. Picks a random valid exit.
4. Calls `move_creature()` — removes creature from old room's `contents`, adds to new room's `contents`, updates `creature.location`.
5. Sets `_state = "alive-wander"`.
6. Emits directional narration if player is in the departure or arrival room.

### `flee`

Same movement logic as wander, but sets `_state = "alive-flee"` and uses different narration ("bolts" instead of "scurries").

### `vocalize`

If creature is in the player's room, emits the current state's `on_listen` text. No state change.

### `attack`

1. Selects prey via `predator_prey.select_prey_target()` (based on `behavior.prey` array).
2. Delegates to `combat.run_combat()` for damage resolution.
3. On defender death: registers for respawn, calls `handle_creature_death()` (reshape), emits `creature_died` stimulus.
4. Runs morale checks on both attacker and defender.
5. Narrates combat result if player is present.

### `create_object`

Used by creatures that produce objects (e.g., spider spins webs). The engine reads `behavior.creates_object` metadata:

```lua
creates_object = {
    template = "spider-web",
    cooldown = 30,           -- seconds between creations
    max_per_room = 2,        -- cap per room
    narration = "The spider spins a web in the corner.",
}
```

The engine enforces `cooldown` via `os.time()` tracking and `max_per_room` by counting matching objects in room contents. A custom `condition` function (if declared) is also checked. All checks are metadata-driven.

---

## 7. Territory System — `territorial.lua`

Territorial behavior is entirely metadata-driven. The engine reads `behavior.territorial`, `behavior.territory`, `behavior.marks_territory`, and `behavior.mark_radius` from creature definitions.

### Territory Marking

When a territorial creature enters a new room, the engine:

1. Checks if the creature already has a marker in this room (avoid duplicates).
2. Creates a `territory-marker` object with `owner = creature.guid`, `radius`, and `timestamp`.
3. Registers the marker in the registry and adds it to `room.contents`.

Markers are invisible (`hidden = true`, `searchable = false`) — players detect them via smell only.

### Territory Evaluation

Each tick, territorial creatures check for foreign markers in their room:

| Condition | Response |
|-----------|----------|
| Own marker | `"patrol"` — continue normal behavior |
| Foreign marker + aggression > 70% | `"challenge"` → transition to `alive-aggressive` |
| Foreign marker + aggression ≤ 70% | `"avoid"` → flee to random adjacent room |

### Territory Rooms (BFS Radius)

`get_territory_rooms(marker, ctx)` performs BFS from the marker's room up to `marker.radius` hops, returning all rooms within that territory sphere. Used to determine whether a creature is "in its territory."

### Marker Expiration

`expire_markers(ctx, duration_hours)` removes markers whose `timestamp` exceeds the configured duration. Called periodically to prevent marker accumulation.

---

## 8. Pack Coordination — `pack-tactics.lua`

Pack tactics are read from creature metadata. The engine identifies packs by finding same-`id` creatures in the same room that are alive and animate.

### Alpha Selection

```
Alpha = creature with highest current health
Tie-breaker: highest max_health
```

No configuration required — the engine determines alpha dynamically each tick.

### Attack Stagger

When multiple pack members select `attack` as their action:

1. Alpha attacks immediately (delay = 0).
2. Non-alpha members wait one turn (`_pack_waited` flag), then attack the next tick.

This prevents all pack members from attacking simultaneously, creating a staggered assault pattern.

### Defensive Retreat

`should_retreat(creature)` returns `true` when `health / max_health < 0.20`. The creature tick checks this before drive updates — if triggered, the creature flees to a random exit immediately, bypassing normal action scoring.

### Pack Query

`get_pack_in_room(registry, room_id, creature)` finds all alive animate objects with the same `id` as the given creature. This means a room with 3 wolves has a pack of 3, but a wolf and a rat do not form a pack.

---

## 9. Movement and Navigation — `navigation.lua`

### Exit Validation

`is_exit_passable(context, exit, creature)` checks:

1. **Direct exits:** If `exit.open == false`, blocked unless `creature.movement.can_open_doors == true`.
2. **Portal exits:** Resolves portal object from registry, checks `states[_state].traversable`. Blocked portals require `can_open_doors`.

### NPC Obstacle Check

`room_has_npc_obstacle(context, room_id)` scans room contents for objects with `obstacle.blocks_npc_movement == true`. If found, creatures cannot enter that room.

### BFS Room Distance

`get_room_distance(context, from, to)` performs breadth-first search through room exits, max depth 10. Returns 999 if unreachable. Used by stimulus processing for reaction distance scaling.

---

## 10. Ambush Behavior

Creatures with `behavior.ambush` metadata stay hidden until a trigger fires:

```lua
behavior = {
    ambush = {
        trigger_on_proximity = true,  -- spring when player enters room
        narration = "The creature lunges from the shadows!",
    },
}
```

Or with a custom condition function:

```lua
ambush = {
    condition = function(creature, ctx)
        return ctx.current_room.id == creature.location
    end,
}
```

Until the ambush springs (`creature._ambush_sprung = true`), the creature tick returns early with no actions. After springing, normal behavior scoring resumes.

---

## 11. Bait Behavior

Hungry creatures (hunger ≥ `satisfy_threshold`) are drawn to food objects with matching `food.bait_targets`. The engine:

1. Scans current room for bait objects targeting this creature.
2. If found: creature consumes bait (removes from registry), resets hunger.
3. If not in room but adjacent: creature moves toward bait.

This is checked after stimulus processing but before action scoring. If bait is consumed, the creature tick returns early.

---

## 12. Principle 8 Compliance

The creature behavior engine has **zero creature-specific code**. All behavior differences between creatures emerge from their metadata:

| What varies | Where it's declared | Engine reads it generically |
|-------------|--------------------|-----------------------------|
| Fear threshold | `behavior.flee_threshold` | Compared to `drives.fear.value` |
| Wander frequency | `behavior.wander_chance` | Multiplied into wander score |
| Territorial marking | `behavior.territorial` | Boolean gate + `behavior.territory` room ID |
| Pack behavior | Same `id` in same room | `get_pack_in_room()` matches by `obj.id` |
| Web spinning | `behavior.creates_object` | Generic object creation pipeline |
| Prey targets | `behavior.prey` | Array scanned by `predator_prey` module |
| Ambush hiding | `behavior.ambush` | Metadata-driven trigger check |

Adding a new creature type requires **only** a new `.lua` file in `src/meta/creatures/`. No engine code changes.

---

## See Also

- **Creature Loading:** `docs/architecture/meta/creature-loading.md` — how creature files enter the engine
- **Creature Combat:** `docs/architecture/meta/creature-combat-integration.md` — body zones, loot, death
- **Creature System (API):** `docs/architecture/engine/creature-system.md` — module API reference
- **Creature Template:** `docs/architecture/meta/creature-template.md` — field reference
- **FSM Lifecycle:** `docs/architecture/engine/fsm-object-lifecycle.md` — FSM engine shared with objects
- **Effects Pipeline:** `docs/architecture/engine/effects-pipeline.md` — `loud_noise` stimulus emission
