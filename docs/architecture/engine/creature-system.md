# Creature System — NPC Behavior Engine

**Location:** `src/engine/creatures/init.lua`  
**Owner:** Bart (Architecture Lead)  
**Stage:** Phase 1 (NPC autonomy, no combat integration yet)  
**First Implementation:** Rat (brown rat, 5 HP)

---

## Overview

The creature system implements autonomous behavior for animate objects. It is a **generic, metadata-driven engine** that evaluates creature behavior without object-specific logic in the engine itself (Principle 8).

Each creature cycle:
1. **Update drives** — hunger, fear, curiosity decay by configured rates
2. **Process stimuli** — react to room-local events (player enters, loud noise, etc.)
3. **Score actions** — utility-score idle/wander/flee/vocalize based on drives and behavior
4. **Execute action** — move, state transition, emit narration

---

## Module API

### `M.emit_stimulus(room_id, stimulus_type, data)`

Queues a stimulus for creatures to process on the next tick. Called by verbs, effects, and FSM transitions to notify creatures of events.

**Parameters:**
- `room_id` — Room ID where stimulus occurred (creatures evaluate distance from this)
- `stimulus_type` — Event type: `"player_enters"`, `"player_attacks"`, `"loud_noise"`, `"light_change"`, etc.
- `data` — Optional table with event details (source location, intensity, etc.)

**Queue:** Stimuli accumulate in a global `stimulus_queue` and are consumed once per tick.

**Example:**
```lua
creatures.emit_stimulus("bedroom", "player_enters", { source = "player" })
```

### `M.clear_stimuli()`

Drains the stimulus queue after all creatures process their reactions. Called by `M.tick()` at the end of each creature cycle.

### `M.get_creatures_in_room(registry, room_id) -> creature[]`

Returns all animate creatures located in the given room.

**Lookup:** Iterates `registry:list()` (or mock equivalent), filters by `obj.animate == true`, checks `location == room_id`.

**Usage:** Finding creatures for room-local combat, narration targeting, etc.

### `M.creature_tick(context, creature) -> messages[]`

Evaluates one creature's behavior cycle. **Not called directly in production** — use `M.tick()` instead to evaluate all creatures.

**Parameters:**
- `context` — Game context table with `registry`, `current_room`, `rooms` table
- `creature` — Creature object (animate, has drives/reactions)

**Returns:** Array of narration strings (movement, vocalization, reaction text).

**Lifecycle:**
1. Skip if creature is inanimate or dead (`creature.animate == false` or `_state == "dead"`)
2. Update drives
3. Process stimuli and collect reaction messages
4. Score actions and select highest-scoring action
5. Execute action and return messages

**Safety:** Wrapped in `pcall()` during `M.tick()`. Errors don't crash the game loop.

### `M.tick(context) -> messages[]`

Master tick function. Evaluates all animate creatures in the registry, collecting their messages, then drains the stimulus queue.

**Call site:** `loop/init.lua`, after fire propagation, before injury tick (~line 633):
```lua
local creature_ok, creature_mod = pcall(require, "engine.creatures")
if creature_ok and creature_mod then
    local creature_msgs = creature_mod.tick(context)
    for _, msg in ipairs(creature_msgs or {}) do
        print(msg)
    end
end
```

**Performance target:** <50ms for 5 creatures per tick (headless).

---

## Drive System

Drives model simplified Dwarf Fortress-inspired needs. Each drive has:

```lua
drive = {
    value = 0..100,          -- Current state (number)
    decay_rate = ±n,         -- Per-tick change (hunger +2, fear -10)
    max = 100,               -- Upper clamp
    min = 0,                 -- Lower clamp
}
```

### Update Cycle

**`update_drives(creature)`** — Each tick, advances each drive by its `decay_rate`:

```lua
drive.value = drive.value + drive.decay_rate
if drive.value > drive.max then drive.value = drive.max end
if drive.value < drive.min then drive.value = drive.min end
```

### Rat Drives (Example)

| Drive | Value | Decay | Min | Max | Meaning |
|-------|-------|-------|-----|-----|---------|
| `hunger` | 50 | +2 | 0 | 100 | Increases (creature gets hungry). Satisfies on eat. |
| `fear` | 0 | -10 | 0 | 100 | Decreases naturally (fear fades). Spiked by player attacks. |
| `curiosity` | 30 | +1 | 0 | 60 | Slowly increases (drives wander/explore). Caps at 60. |

**Hunger decay_rate is positive:** creature becomes hungrier each tick. Decays toward max (100 = starving).  
**Fear decay_rate is negative:** creature becomes braver naturally. Decays toward min (0 = calm).

---

## Reaction System

Reactions are stimulus-response mappings. When a stimulus fires, creatures matching the reaction type apply drive deltas and emit messages.

### Stimulus Perception

**Distance rules:**
- **Same room** (distance = 0): Receive stimulus at 100% intensity
- **Adjacent room** (distance = 1): Receive stimulus at 50% intensity  
- **Distant** (distance > 1): No reaction

**BFS distance:** Computed via `get_room_distance()` — flood-fill from creature's room to stimulus room, max depth = 10.

### Rat Reactions (Example)

```lua
reactions = {
    player_enters = {
        action = "evaluate",
        fear_delta = 35,
        message = "A rat freezes, beady eyes fixed on you. Its whiskers quiver.",
    },
    player_attacks = {
        action = "flee",
        fear_delta = 80,
        message = "The rat squeals — a piercing, desperate sound — and bolts!",
    },
    loud_noise = {
        action = "flee",
        fear_delta = 25,
        message = "The rat startles at the noise and scurries into the shadows.",
    },
}
```

**Processing:**
1. Each stimulus in the queue is evaluated
2. For creatures within range (distance ≤ 1):
   - If reaction exists for this stimulus type:
     - Apply `fear_delta * scale` to creature's `drives.fear.value`
     - If same room (scale = 1.0) and reaction has `.message`, emit it
3. Messages bubble up to `creature_tick()` and thence to game loop for printing

---

## Behavior Selection (Utility Scoring)

Actions are ranked by utility score. The highest-scoring action executes.

### Scoring Function

**`score_actions(creature)`** evaluates:

| Action | Base | Drive Influence | Condition |
|--------|------|---|----------|
| `idle` | 10 | — | Always available |
| `wander` | (curiosity × 0.3) + (wander_chance × 0.2) | Curiosity, behavior.wander_chance | Always available |
| `flee` | fear × 1.5 | Fear >= flee_threshold | Only if fear is high |
| `vocalize` | (fear × 0.3) + (curiosity × 0.1) | Fear (10 < x < threshold) + curiosity | When partially frightened or curious |

All scores receive a random jitter (`+ math.random() * 2`) to prevent deterministic behavior.

**Result:** Sorted descending, highest score is selected and executed.

### Rat Behavior Example

**Typical flow:**
- **Low fear + moderate curiosity** → wander
- **Fear > 30** (flee_threshold) → flee  
- **Stuck (no valid exits)** → idle

---

## Action Execution

### State Transitions

Actions set creature `_state`:

- **`idle`** → `"alive-idle"`
- **`wander`** → `"alive-wander"`
- **`flee`** → `"alive-flee"`
- **`vocalize`** → uses `states[_state].on_listen`
- **Dead** → no-op (state remains `"dead"`)

### Movement

**`move_creature(context, creature, target_room_id)`** — Repositions creature:

1. Remove creature from old room's `contents` array
2. Add creature to new room's `contents` array  
3. Update creature's location (both in-object and via `registry:set_location()`)

**Exit validation** (before move):
- `is_exit_passable(context, exit, creature)` checks:
  - Is exit open? If closed, can creature open doors (`movement.can_open_doors`)?
  - For portal-based exits, is portal traversable?
  - Returns `(passable: bool, target_room_id: string)`

**Exit discovery** (for wander/flee):
- `get_valid_exits(context, room_id, creature)` returns all passable exits
- Creature picks random valid exit (wander) or farthest from threat (flee, Phase 2+)

### Narration

Messages are emitted conditionally:

**Wander/Flee (movement):**
- If creature leaves player's room: `"{Name} scurries/bolts {direction}."`
- If creature enters player's room: `"{Name} arrives."` (or state-based `room_presence` text)

**Vocalize:**
- If in player's room, emit state's `on_listen` (e.g., rat's "Skittering claws on stone")

**Reaction messages:**
- Emitted only in same room (distance = 0)

---

## Game Loop Integration

The creature tick fires **after fire propagation, before injury tick** in `loop/init.lua`:

```lua
-- Fire propagation (existing effect system)
...

-- Creature tick: evaluate behavior for all animate objects
local creature_ok, creature_mod = pcall(require, "engine.creatures")
if creature_ok and creature_mod then
    local creature_msgs = creature_mod.tick(context)
    for _, msg in ipairs(creature_msgs or {}) do
        print(msg)
    end
end

-- Injury tick (player recovery, poison effects, etc.)
...
```

**Rationale:** Creatures need to react to stimuli from the previous command before injuries are processed. This ordering ensures consistent cause-effect narration.

**PCaLL safety:** Creature errors are caught; game loop continues.

---

## Performance Characteristics

**Budget:** <50ms per tick for 5 creatures (headless, no UI).

**Optimizations implemented:**

1. **Early exit for dead creatures** — Skip ticks for `animate == false` or `_state == "dead"`
2. **BFS depth limit** — Max depth = 10 for distance calculations; unreachable rooms default to 999
3. **Registry abstraction** — Single loop over all objects; cull by `animate` flag
4. **Lazy reactions** — Only creatures within distance ≤ 1 react; distant creatures ignored
5. **Random exit selection** — O(valid_exits) for wander/flee; no global pathfinding

**Profiling:** After GATE-2, measure wall-clock `creature_tick()` on known test fixture. Tune decay rates and wander_chance if >50ms observed.

---

## Stimulus Emission Points

Creatures should emit stimuli at:

1. **Player movement verb** — `player_enters` when creature's room gains player
2. **Player attack** — `player_attacks` when combat initiates (Phase 2+)
3. **Loud effects** — `loud_noise` from weapons, spells, machinery
4. **Lighting changes** — `light_change` when dark→lit or lit→dark

**Example:**
```lua
-- In a verb handler (Smithers or others)
creatures.emit_stimulus(player_room_id, "loud_noise", { source = "sword_clash" })
```

---

## No Combat in Phase 1

**Design decision (D-COMBAT-NPC-PHASE-SEQUENCING):**

Creature tick in Phase 1 does NOT execute an `attack` action. Combat FSM, body_tree, and damage resolution are deferred to Phase 2+.

**Phase 1 scope:** Creatures move, react, and vocalize. They exist autonomously but do not initiate combat.

Rats bite only when grabbed by the player (via simple `injuries.inflict()` in a catch/grab verb, not via creature tick autonomy).

---

## Object Metadata Contract

**Every creature must have:**
- `animate = true`
- `drives` table (may be empty; creature ticks safely even if nil)
- `reactions` table (may be empty; no reactions fired)
- `behavior` table (min: `flee_threshold`, `wander_chance`)
- `movement` table (min: `can_open_doors`, `can_climb`)
- Sensory properties: `on_feel`, `on_smell`, `on_listen`, `on_taste` (mandatory per core principles)

**Optional:**
- Custom `states` and `transitions` (inherits from creature template)
- `awareness` table (sight_range, sound_range, smell_range for future phases)

---

## Testing

**Test location:** `test/creatures/test-creature-tick.lua` (Nelson, TDD)

**Must cover:**
1. Drive decay: hunger increases, fear decreases per tick
2. Stimulus processing: fear spikes on player_enters, clamped to max
3. Action scoring: wander score includes curiosity × 0.3
4. Movement: creature relocates to target room, old room.contents updated
5. Exit validation: closed door blocks walk unless can_open_doors
6. BFS distance: adjacent room reactions at 50% scale
7. Distant room: creatures beyond distance 1 ignore stimuli
8. State transitions: idle → wander → idle cycles smoothly
9. Dead creatures: skip ticks, ignore stimuli

---

## Glossary

| Term | Meaning |
|------|---------|
| **Animate** | `creature.animate == true`; subject to creature tick |
| **Drive** | Dwarf Fortress-inspired need (hunger, fear, curiosity) |
| **Reaction** | Stimulus→response mapping; modifies drives and emits messages |
| **Stimulus** | Event queued for creatures to process (player_enters, loud_noise, etc.) |
| **Utility score** | Numeric ranking for action selection; highest wins |
| **Portal** | Exit linked to a portal object (state-aware, can be locked/open) |
| **Room presence** | State-specific text describing creature in player's room ("A rat crouches...") |
