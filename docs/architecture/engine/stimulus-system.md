# Stimulus System — Event Queue for Creature Reactions

**Location:** `src/engine/creatures/init.lua` (stimulus_queue and emit_stimulus)  
**Owner:** Bart (Architecture Lead)  
**Stage:** Phase 1 (Creature reactions to environmental events)  
**Related:** Creature behavior engine (creature-system.md)

---

## Overview

The stimulus system is a **simple event queue** that decouples event sources (verbs, effects, FSM) from creature reactions. Instead of hard-coding creature behavior into verb handlers, events are emitted to a global queue and creatures consume them during their tick.

This implements **Principle 8** (Engine Executes Metadata): creatures declare reactions in their `.lua` files; the engine processes them generically.

---

## Architecture: Four Emission Points

Stimuli are emitted from four locations in the game loop and verb system:

### 1. Movement Verbs

When the player enters a room, emit `player_enters` stimulus.

**Pseudo-code (Smithers implements in verb handlers):**
```lua
-- Example: go verb (move to adjacent room)
if player_room ~= new_room then
    creatures.emit_stimulus(old_room_id, "player_leaves")
    creatures.emit_stimulus(new_room_id, "player_enters", { source = "player" })
end
```

**Phase 1 triggers:**
- `player_enters` — Player moves to a room with creatures
- `player_leaves` — Player exits a room

### 2. Effect System (Sound, Light, Fire)

When an effect propagates (fire spreads, loud noise emitted, light changes), emit corresponding stimulus.

**Pseudo-code (effects.lua or effects handlers):**
```lua
-- Loud sound effect
creatures.emit_stimulus(room_id, "loud_noise", {
    intensity = effect.volume,
    source = "explosion",
})

-- Light change (fire ignites)
creatures.emit_stimulus(room_id, "light_change", {
    transition = "dark_to_lit",
    source = "fire",
})
```

**Phase 1 triggers:**
- `loud_noise` — Weapon swing, machinery, explosion
- `light_change` — Darkness→light or light→darkness

### 3. FSM Transitions

When a creature's FSM transitions (e.g., rat enters "alive-flee" state), emit a stimulus to inform other creatures.

**Pseudo-code (fsm engine, future phase):**
```lua
-- When creature transitions to flee state
if old_state ~= "alive-flee" and new_state == "alive-flee" then
    creatures.emit_stimulus(creature_room_id, "creature_fled", {
        creature_id = creature.id,
        from_room = creature_room_id,
    })
end
```

**Phase 2+ triggers:**
- `creature_fled` — Creature enters flee state
- `creature_attacked` — Creature initiates attack (Phase 2+)
- `creature_injured` — Creature takes damage (Phase 2+)
- `creature_died` — Creature dies (Phase 2+)

### 4. Combat System (Phase 2+)

When combat resolves (Phase 2 integration), emit combat-specific stimuli.

**Pseudo-code (combat/init.lua, Phase 2):**
```lua
if defender_is_creature then
    creatures.emit_stimulus(combat_room_id, "creature_attacked", {
        attacker_id = attacker.id,
        defender_id = defender.id,
        damage = resolved_damage,
    })
end
```

**Phase 2+ triggers:**
- `creature_attacked` — Creature is the target of an attack
- `creature_injured` — Creature sustains injury
- `creature_died` — Creature health → 0

---

## Stimulus Format

Each stimulus in the queue is a table:

```lua
stimulus = {
    room_id = "bedroom",             -- Room where event occurred
    stimulus_type = "player_enters", -- Event classification
    data = {                         -- Optional details
        source = "player",
        intensity = 80,
    },
}
```

### Fields

| Field | Type | Meaning | Required |
|-------|------|---------|----------|
| `room_id` | string | Room ID where stimulus occurred | ✓ |
| `stimulus_type` | string | Event name (player_enters, loud_noise, etc.) | ✓ |
| `data` | table | Event-specific metadata | Optional |

### Well-Known Stimulus Types

| Type | Phase | Source | Creatures Usually React |
|------|-------|--------|------------------------|
| `player_enters` | 1 | Movement verb | Fear spike (evaluate) |
| `player_leaves` | 1 | Movement verb | Fear decline (calm) |
| `loud_noise` | 1 | Effect system (weapons, machinery) | Fear spike (flee) |
| `light_change` | 1 | Effect system (fire, light) | Fear spike (evaluate) |
| `creature_fled` | 2 | FSM (creature state change) | (Herd behavior, Phase 3+) |
| `creature_attacked` | 2 | Combat system | Fear spike (defensive) |
| `creature_injured` | 2 | Combat system | Aggression increase |
| `creature_died` | 2 | Combat system | Fear spike (alarm) |

---

## Perception: Distance-Based Filtering

Not all creatures perceive all stimuli equally. Perception is **distance-weighted**.

### Distance Calculation

**`get_room_distance(from_room_id, to_room_id)` → distance**

Uses **BFS (breadth-first search)** to compute minimum room hops:

- Distance 0 = same room
- Distance 1 = adjacent room (one exit traversal)
- Distance > 1 = two or more exits away
- Distance 999 = unreachable (or > max_depth = 10)

```lua
local function get_room_distance(context, from_id, to_id)
    if from_id == to_id then return 0 end
    local visited = { [from_id] = true }
    local frontier = { from_id }
    local depth = 0
    while #frontier > 0 and depth < 10 do
        depth = depth + 1
        local next_frontier = {}
        for _, rid in ipairs(frontier) do
            local room = get_room(context, rid)
            if room and room.exits then
                for _, exit in pairs(room.exits) do
                    local target_id = get_exit_target(context, exit)
                    if target_id and not visited[target_id] then
                        if target_id == to_id then return depth end
                        visited[target_id] = true
                        next_frontier[#next_frontier + 1] = target_id
                    end
                end
            end
        end
        frontier = next_frontier
    end
    return 999
end
```

### Perception Thresholds

| Distance | Perception | Scale | Example |
|----------|------------|-------|---------|
| 0 (same room) | Full | 1.0 | Rat sees player enter. Fear delta × 1.0. Message emitted. |
| 1 (adjacent) | Attenuated | 0.5 | Rat hears loud noise through wall. Fear delta × 0.5. No message. |
| >1 (distant) | None | 0 | Rat in hallway doesn't react to whisper in distant bedroom. |

**Application in `process_stimuli()`:**

```lua
for _, stimulus in ipairs(stimulus_queue) do
    local dist = 999
    if creature_loc == stimulus.room_id then
        dist = 0
    else
        dist = get_room_distance(context, creature_loc, stimulus.room_id)
    end

    -- Only same-room and adjacent creatures react
    if dist <= 1 then
        local reaction = creature.reactions[stimulus.stimulus_type]
        if reaction then
            if reaction.fear_delta and creature.drives and creature.drives.fear then
                local scale = dist == 0 and 1.0 or 0.5  -- Full at distance 0, half at distance 1
                local delta = reaction.fear_delta * scale
                -- Apply delta...
            end
        end
    end
end
```

---

## Queue Lifecycle

### Emission (`emit_stimulus`)

```lua
function M.emit_stimulus(room_id, stimulus_type, data)
    stimulus_queue[#stimulus_queue + 1] = {
        room_id = room_id,
        stimulus_type = stimulus_type,
        data = data or {},
    }
end
```

Stimuli accumulate during a single game tick (one player command). Multiple verbs, effects, and FSM transitions may emit stimuli in sequence.

### Processing (`process_stimuli`)

During `creature_tick()`, each creature scans the entire `stimulus_queue`:

```lua
local function process_stimuli(context, creature)
    local messages = {}
    if type(creature.reactions) ~= "table" then return messages end
    local creature_loc = get_location(context.registry, creature)

    for _, stimulus in ipairs(stimulus_queue) do
        -- Compute distance
        local dist = (creature_loc == stimulus.room_id) and 0 or 
                     get_room_distance(context, creature_loc, stimulus.room_id)

        -- Threshold check
        if dist <= 1 then
            local reaction = creature.reactions[stimulus.stimulus_type]
            if reaction then
                -- Apply drive delta (scaled by distance)
                if reaction.fear_delta then
                    local scale = (dist == 0) and 1.0 or 0.5
                    apply_delta_to_drive(creature, "fear", reaction.fear_delta * scale)
                end
                -- Emit message if same room
                if dist == 0 and reaction.message then
                    messages[#messages + 1] = reaction.message
                end
            end
        end
    end

    return messages
end
```

**Order:** Each creature processes ALL stimuli in the queue in the order they were emitted. If Creature A and B both react to the same stimulus, both reactions fire.

### Draining (`clear_stimuli`)

After all creatures have ticked, the stimulus queue is cleared:

```lua
function M.clear_stimuli()
    stimulus_queue = {}
end
```

Called at the end of `M.tick()`. Ensures no stimuli persist into the next game tick.

---

## PCaLL Guard Pattern

Stimulus processing is wrapped in error handling to prevent crashes.

**In `M.tick()`:**

```lua
function M.tick(context)
    local messages = {}
    if not context or not context.registry then return messages end

    local creatures = {}
    for _, obj in ipairs(list_objects(context.registry)) do
        if obj.animate then
            creatures[#creatures + 1] = obj
        end
    end

    for _, creature in ipairs(creatures) do
        local ok, result = pcall(M.creature_tick, context, creature)
        if ok and type(result) == "table" then
            for _, msg in ipairs(result) do
                messages[#messages + 1] = msg
            end
        end
        -- If pcall fails, error is caught; game loop continues
    end

    M.clear_stimuli()
    return messages
end
```

**Rationale:** Malformed creatures, missing reactions, or broken FSM transitions should not crash the game. Errors are silently suppressed; creature ticks are skipped. This allows developers to add creatures progressively without risking game stability.

---

## Stimulus Consumption Model

Creatures **consume** stimuli by processing them, but stimuli are **not removed** from the queue. All creatures see all stimuli in a single tick.

```lua
-- Tick 1: "player_enters" emitted
stimulus_queue = { { room_id = "bedroom", type = "player_enters" } }

-- Creature A processes: sees "player_enters", reacts
-- Creature B processes: sees "player_enters", reacts
-- Creature C processes: sees "player_enters", reacts

-- After all creatures tick:
M.clear_stimuli()  -- Drain the queue

-- Tick 2: Queue is empty (fresh)
```

**Consequence:** Multiple creatures in the same room will all react to the same stimulus. This is intentional (e.g., rat colony reacts as a group).

---

## Design Decisions

### Why a Queue?

**Coupling problem:** Without a queue, verbs would need to know about creature reactions:
```lua
-- BAD: Verb hardcodes creature logic
creatures:notify_of_player_entry(old_room, new_room)
-- Creatures are hardcoded into the verb system
```

**Queue solution:** Verbs emit events; creatures subscribe to events:
```lua
-- GOOD: Decoupled
creatures.emit_stimulus(new_room_id, "player_enters")
-- Verbs don't know creatures exist; creatures declare reactions
```

### Why Draining After Ticks?

If the stimulus queue were to persist:
- Stimuli could be processed multiple times (re-entering a room → creature reacts twice)
- Old stimuli would interfere with new behavior (rat never forgets past events)

By draining after `M.tick()`, each game tick has a **clean slate**. Stimuli are one-shot events, not persistent state.

### Why Distance Weighting?

**Realism:** Loud noise heard faintly in an adjacent room shouldn't panic a rat as much as a sword swing in the same room.

**Gameplay:** Creatures in distant rooms shouldn't be aware of every player action (no omniscience). Sound carries through walls but diminishes.

**Performance:** Distant creatures don't react (distance > 1 → no reaction). Fewer behavior updates = better performance.

---

## Integration with Creature System

**Flow (per game tick):**

1. **Player command** → verb executes
   - Verb may emit stimuli (e.g., `player_enters`)
   
2. **Effects propagate** → effects.lua executes
   - Effects may emit stimuli (e.g., `loud_noise`)

3. **Creature tick** → `creatures.M.tick()` executes
   - For each creature:
     - Process stimuli (scan queue, apply reactions, collect messages)
     - Score actions (wander, flee, idle, vocalize)
     - Execute best action
   - Drain queue

4. **Injury tick** → injuries.lua executes

5. **Output** → Messages printed to UI

**Stimulus queue lifetime:** Single tick (created from scratch per tick).

---

## Testing

**Test location:** `test/creatures/test-stimulus-system.lua` (Nelson, TDD)

**Must cover:**
1. Emit and consume: stimulus added to queue, creature reacts, queue cleared
2. Distance 0 (same room): Full perception, message emitted
3. Distance 1 (adjacent): Attenuated perception (50%), no message
4. Distance >1 (distant): No reaction
5. Multiple creatures: All react to same stimulus
6. BFS: Distance calculation via room.exits traversal
7. Unknown stimulus type: Creature skips (no reaction defined)
8. Missing reactions table: No crash, creature skips processing
9. PCaLL guard: Malformed creature doesn't crash tick
10. Queue draining: Second tick starts clean

---

## Glossary

| Term | Meaning |
|------|---------|
| **Stimulus** | Event queued for creatures to process (table with room_id, type, data) |
| **Emission** | Calling `creatures.emit_stimulus()` to add a stimulus to the queue |
| **Reaction** | Creature's response to a stimulus type (fear delta, message, action) |
| **Queue** | Global array `stimulus_queue` holding all emitted stimuli for current tick |
| **Distance** | BFS room hop count between two rooms (0 = same, 1 = adjacent, >1 = distant) |
| **Perception** | Creature's awareness of a stimulus based on distance (0 dist = full, 1 dist = 50%, >1 dist = none) |
| **Draining** | Clearing the stimulus queue after all creatures have processed it |
| **PCaLL guard** | Error handling wrapper preventing malformed creatures from crashing the game loop |
