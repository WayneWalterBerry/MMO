# Consciousness State Machine — Architecture

**Version:** 1.0  
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Design  
**Purpose:** Technical specification for the player consciousness system — the state machine governing conscious, unconscious, and waking states, and its integration with the game loop, injury ticking, sleep, and death.

---

## Overview

Consciousness is a **player-level state machine** that controls whether the player can act. When unconscious, the game loop skips command input and instead ticks time forward, processing injuries each tick. The player can die while unconscious if injuries reduce derived health to zero.

**Core invariant:** Consciousness state lives in `player.lua` alongside existing state. The game loop in `src/engine/loop/init.lua` checks consciousness before requesting input.

**Key insight:** Unconsciousness and voluntary sleep share the same "player can't act, time passes, injuries tick" mechanic. The architecture unifies them under one forced-inactivity handler.

---

## State Machine

### States

```
┌──────────┐    injury/knockout    ┌──────────────┐    timer expires    ┌─────────┐
│ CONSCIOUS │ ──────────────────► │ UNCONSCIOUS  │ ──────────────────► │ WAKING  │
│           │                      │              │                      │         │
│ normal    │                      │ no input     │                      │ narrate │
│ gameplay  │                      │ injuries tick│                      │ resume  │
└──────────┘ ◄──────────────────── └──────────────┘                      └────┬────┘
      ▲                                    │                                  │
      │            health ≤ 0              ▼                                  │
      │                              ┌──────────┐                             │
      │                              │   DEAD   │                             │
      │                              └──────────┘                             │
      │                                                                       │
      └───────────────────────────────────────────────────────────────────────┘
                                 transition complete
```

| State | Player Can Act? | Injuries Tick? | Time Advances? | Description |
|-------|:---------------:|:--------------:|:--------------:|-------------|
| `conscious` | ✅ Yes | ✅ Yes (per-turn) | ✅ Per command | Normal gameplay. Default state. |
| `unconscious` | ❌ No | ✅ Yes (per-tick) | ✅ Auto-advance | Forced inactivity. Timer counts down. |
| `waking` | ❌ No (transitional) | ❌ No | ❌ No | Brief narration state. Immediately transitions to `conscious`. |
| `dead` | ❌ No | ❌ N/A | ❌ N/A | Terminal. Game over. |

### Transitions

| From | To | Trigger | Conditions |
|------|------|---------|------------|
| `conscious` | `unconscious` | Injury with `causes_unconsciousness = true` inflicted | Player not already unconscious |
| `unconscious` | `waking` | `wake_timer` reaches 0 | Player still alive (`health > 0`) |
| `unconscious` | `dead` | `compute_health(player) <= 0` during tick | Injuries accumulated enough damage |
| `waking` | `conscious` | Wake-up narration dispatched | Always (immediate transition) |

### No Intermediate "Dazed" State

Per Wayne's design decision (2026-03-22 §4): binary conscious/unconscious only. No dazed, groggy, or semi-conscious state. Clean transitions. This may be revisited for multiplayer but is firm for single-player.

---

## Player State Extension

### New Fields in `player.lua`

The consciousness system adds to the existing player state structure (`src/main.lua:278-290`):

```lua
player = {
    -- ... existing fields (hands, worn, injuries, max_health, skills, state) ...

    consciousness = {
        state = "conscious",        -- "conscious" | "unconscious" | "waking"
        wake_timer = 0,             -- turns remaining until wake-up (0 = conscious)
        cause = nil,                -- what caused unconsciousness (e.g., "blow-to-head")
        unconscious_since = nil,    -- game time when player went unconscious
    },
}
```

### Field Semantics

| Field | Type | Description |
|-------|------|-------------|
| `state` | `string` | Current consciousness state. Always one of: `"conscious"`, `"unconscious"`, `"waking"`. |
| `wake_timer` | `number` | Turns remaining until the player wakes. Decremented each forced tick while unconscious. `0` when conscious. |
| `cause` | `string\|nil` | The injury type or event that caused unconsciousness. Used for wake-up narration ("You groan... your head throbs"). `nil` when conscious. |
| `unconscious_since` | `number\|nil` | Game timestamp when unconsciousness began. Used to compute "how long were you out?" for narration. `nil` when conscious. |

### Default State

New players and existing save files start with:

```lua
consciousness = { state = "conscious", wake_timer = 0, cause = nil, unconscious_since = nil }
```

If `player.consciousness` is `nil` (old save file), the engine treats this as `conscious` — backward compatible.

---

## Game Loop Integration

### Current Loop (`src/engine/loop/init.lua`)

The current game loop (approximately 520 lines) follows this flow:

```
1. Read input (headless/TUI/stdin)
2. Parse + dispatch command
3. Tick object FSMs
4. Tick injuries (injury_mod.tick)
5. Check death (health ≤ 0 → game over)
6. Render output
```

### Modified Loop (With Consciousness)

The consciousness check wraps the input phase. If the player is unconscious, the loop skips input and runs a forced tick instead:

```lua
-- Main game loop (modified)
while not context.game_over do

    -- ═══ CONSCIOUSNESS GATE ═══
    if player.consciousness and player.consciousness.state == "unconscious" then
        -- FORCED TICK: no input, time passes, injuries tick
        local result = unconscious_tick(context)
        if result == "died" then
            -- Death during unconsciousness
            handle_unconscious_death(context)
            break
        elseif result == "waking" then
            -- Timer expired, player wakes up
            handle_wake_up(context)
            -- Fall through to normal input on next iteration
        end
        -- Skip command input this iteration; loop again
    else
        -- ═══ NORMAL GAMEPLAY ═══
        -- Read input, parse, dispatch, tick (existing code)
        local input = read_input()
        process_command(context, input)
        tick_objects(context)
        tick_injuries(context)
        check_death(context)
    end

end
```

### Does `loop/init.lua` Need a State Machine?

**Yes, but a lightweight one.** The loop doesn't need a formal FSM framework — it needs a single consciousness check at the top of each iteration. The existing loop structure supports this with a conditional branch:

- **If conscious:** Execute the existing input → parse → dispatch → tick flow unchanged.
- **If unconscious:** Execute the forced-tick subroutine (tick injuries, decrement timer, check death/wake).

This is implemented as an `if/else` at the top of the loop, not a separate state machine module. The consciousness state machine lives in `player.consciousness.state` — the loop just reads it.

---

## Forced Tick (Unconscious Turn Processing)

When the player is unconscious, each loop iteration runs a forced tick instead of waiting for input:

```lua
--- Process one unconscious tick. Returns "died", "waking", or "continue".
--- @param ctx table — game context (player, rooms, time)
--- @return string   — result code
function unconscious_tick(ctx)
    local player = ctx.player

    -- 1. Advance time (same as one game turn)
    ctx.time_offset = (ctx.time_offset or 0) + TIME_PER_TICK

    -- 2. Tick all injuries (same as post-command tick in normal gameplay)
    --    Uses existing injury_mod.tick() from src/engine/injuries.lua
    local injury_mod = require("engine.injuries")
    local msgs, died = injury_mod.tick(player)

    -- 3. Print injury messages (player experiences them even while unconscious)
    --    Narrated as sensory fragments: "Pain flares in your arm..."
    for _, msg in ipairs(msgs) do
        print(msg)
    end

    -- 4. Check death
    if died then
        return "died"
    end

    -- 5. Decrement wake timer
    player.consciousness.wake_timer = player.consciousness.wake_timer - 1

    -- 6. Check wake-up
    if player.consciousness.wake_timer <= 0 then
        player.consciousness.state = "waking"
        return "waking"
    end

    return "continue"
end
```

### Tick Rate During Unconsciousness

Each unconscious tick equals one game turn. If the player has a 5-turn wake timer, the loop iterates 5 times (or fewer if they die). Each iteration:
- Advances game time by one turn increment
- Ticks all injuries (damage accumulates)
- Decrements the wake timer

**UI consideration:** The loop should include a brief delay between unconscious ticks (e.g., 500ms) so the player can read injury messages scrolling by. Without delay, 5 ticks would flash past instantly.

---

## Injury Ticking Integration

### Current Injury Tick (`src/engine/injuries.lua:130-202`)

The existing `injury_mod.tick(player)` function:
1. Iterates `player.injuries[]`
2. Increments `turns_active` on each injury
3. Accumulates `damage += damage_per_tick` for over-time injuries
4. Handles degenerative scaling (increment `damage_per_tick` toward cap)
5. Checks auto-heal timers for state transitions
6. Removes terminal injuries
7. Returns `(messages[], died_bool)` — messages are per-injury narration, died is true if `health ≤ 0`

### No Changes Needed to Injury System

The existing `injury_mod.tick()` is already a pure function of player state. It doesn't know or care whether the player is conscious, unconscious, or sleeping. The consciousness system simply **calls it more aggressively** — once per forced tick during unconsciousness, instead of once per player command.

This is the key architectural insight: **the injury system and consciousness system are orthogonal.** Injuries tick. Consciousness controls when ticks happen. Neither knows about the other.

---

## Sleep + Injury Interaction (Voluntary Sleep Now Dangerous)

### Current Sleep Implementation (`src/engine/verbs/init.lua:4827+`)

The current `sleep` verb:
1. Parses duration ("sleep for 3 hours", "sleep until dawn")
2. Computes tick count (≈10 ticks/hour)
3. Loops through ticks, advancing FSM timers for room objects
4. Handles bleeding countdown, candle burnout, etc.
5. Prints wake-up narration

### Current Gap: Sleep Doesn't Tick Injuries

The current sleep implementation ticks **object FSMs** and **blood countdown** but does NOT call `injury_mod.tick()`. This means a player with active bleeding can sleep safely — the bleeding doesn't accumulate during sleep. Per Wayne's design (2026-03-23 plan §4): **this must change.**

### Required Change

The sleep verb's tick loop must call `injury_mod.tick(player)` each iteration:

```lua
-- In do_sleep() tick loop (verbs/init.lua, ~line 4964):
for tick = 1, total_ticks do
    -- Existing: tick object FSMs, burnables, etc.
    tick_room_fsms(ctx)
    tick_burnables(ctx)

    -- NEW: tick injuries during sleep (same as forced unconscious tick)
    local injury_mod = require("engine.injuries")
    local msgs, died = injury_mod.tick(ctx.player)
    for _, msg in ipairs(msgs) do
        sleep_messages[#sleep_messages + 1] = msg
    end

    -- NEW: check death during sleep
    if died then
        -- Player bled out during sleep
        handle_sleep_death(ctx)
        return
    end
end
```

### Sleep Death Narration

If the player dies during voluntary sleep, the narration differs from unconscious death:

```lua
function handle_sleep_death(ctx)
    print("")
    print("You drift deeper into sleep. The pain fades. Everything fades.")
    print("You never wake up.")
    print("")
    print("YOU HAVE DIED.")
    ctx.game_over = true
end
```

### Unified Inactivity Model

Both unconsciousness and sleep share the same mechanical loop:

```
while inactive:
    tick injuries
    if health ≤ 0: die
    decrement timer (or check duration)
    if timer done: wake up
```

The only differences are:
- **Trigger:** Unconsciousness is forced (injury); sleep is voluntary (verb).
- **Duration:** Unconsciousness is turn-based (5-10 turns); sleep is time-based (hours).
- **Narration:** Different wake-up and death messages.
- **Interruption:** Sleep could be interrupted by events (future); unconsciousness always waits for timer.

---

## Death During Unconsciousness

### Handler Architecture

Death during unconsciousness is detected by the `unconscious_tick` function when `injury_mod.tick()` returns `died = true`:

```lua
function handle_unconscious_death(ctx)
    local cause = ctx.player.consciousness.cause or "your injuries"

    -- Contextual death message based on what knocked the player out
    local messages = {
        ["blow-to-head"] = "You never wake up. The bleeding was too much.",
        ["poison-gas"]   = "The gas fills your lungs. You stop breathing.",
        ["knockout"]     = "Darkness takes you, and this time it doesn't let go.",
    }

    local msg = messages[cause] or "You never wake up. Your injuries were too much."

    print("")
    print(msg)
    print("")
    print("YOU HAVE DIED.")
    ctx.game_over = true
end
```

### Death Priority

If the player is unconscious AND has ticking injuries, death can occur at any tick. The `unconscious_tick` function checks death BEFORE decrementing the wake timer — you can't wake up from death:

```
tick injuries → check death (exit if dead) → decrement timer → check wake
```

---

## Wake-Up Event and Narration

### Wake-Up Flow

```
1. wake_timer reaches 0
2. consciousness.state = "waking"
3. handle_wake_up() runs:
   a. Compute time elapsed since unconscious_since
   b. Select narration based on cause
   c. Print wake-up text
   d. Print time-passage text
   e. Set consciousness.state = "conscious"
   f. Clear consciousness fields (cause, timer, unconscious_since)
4. Next loop iteration: normal gameplay resumes
```

### Wake-Up Narration

```lua
function handle_wake_up(ctx)
    local player = ctx.player
    local cause = player.consciousness.cause or "unknown"
    local elapsed = compute_elapsed_time(
        player.consciousness.unconscious_since, ctx.time_offset
    )

    -- Cause-specific narration
    local narrations = {
        ["blow-to-head"] = "You groan and open your eyes. Your head throbs with a dull, heavy ache.",
        ["poison-gas"]   = "You cough violently, gasping for air. The world swims back into focus.",
        ["knockout"]     = "Pain drags you back to consciousness. Every muscle aches.",
    }
    local wake_text = narrations[cause] or "You slowly regain consciousness."

    print("")
    print(wake_text)

    -- Time passage
    if elapsed then
        print(string.format("About %s has passed.", format_duration(elapsed)))
    end

    -- Current injury status (player should know what happened while they were out)
    local health = compute_health(player)
    if health < player.max_health * 0.5 then
        print("You feel weak. Something is very wrong.")
    elseif health < player.max_health * 0.75 then
        print("You feel battered but alive.")
    end

    print("")

    -- Reset consciousness state
    player.consciousness.state = "conscious"
    player.consciousness.wake_timer = 0
    player.consciousness.cause = nil
    player.consciousness.unconscious_since = nil
end
```

### Narration Quality

Wake-up text must be **cause-aware** and **state-aware**:
- If the player has active bleeding: mention blood
- If health is low: mention weakness
- If it's now a different time of day: mention light changes
- If the room changed (future — dragged by NPC): describe new surroundings

---

## Triggering Unconsciousness

### Injury-Driven

A new injury category (`causes_unconsciousness = true`) triggers the state change:

```lua
-- src/meta/injuries/concussion.lua (example)
return {
    id = "concussion",
    name = "Concussion",
    category = "unconsciousness",
    causes_unconsciousness = true,

    -- Duration: severity-based (harder hit = longer KO)
    unconscious_duration = {
        minor    = 3,       -- 3 turns
        moderate = 5,       -- 5 turns
        severe   = 10,      -- 10 turns
    },

    initial_state = "active",
    damage_type = "one_time",
    on_inflict = {
        initial_damage = 5,
        damage_per_tick = 0,
    },

    states = {
        active = {
            name = "concussed",
            description = "Your head is swimming. Stars dance at the edges of your vision.",
            auto_heal_turns = 15,
            transitions = {
                { to = "healed", condition = "timer" },
            },
        },
        healed = {
            name = "recovered",
            terminal = true,
        },
    },
}
```

### Engine Processing (Infliction)

When `injury_system.inflict()` creates an injury with `causes_unconsciousness = true`:

```lua
-- In injury_system.inflict() (src/engine/injuries.lua):
function injury_system.inflict(player, injury_type, opts)
    local def = load_injury_definition(injury_type)
    local instance = create_instance(def, opts)

    -- Add to player injuries
    player.injuries[#player.injuries + 1] = instance

    -- Check for unconsciousness trigger
    if def.causes_unconsciousness then
        local severity = opts.severity or "moderate"
        local duration = def.unconscious_duration[severity]
            or def.unconscious_duration.moderate
            or 5

        -- Trigger unconsciousness
        player.consciousness = {
            state = "unconscious",
            wake_timer = duration,
            cause = injury_type,
            unconscious_since = current_game_time(),
        }
    end

    return instance
end
```

### Armor Mitigation

Per Wayne's design decision (2026-03-22 §4): helmets and armor can reduce or prevent unconsciousness:

```lua
-- Before setting unconsciousness:
if def.causes_unconsciousness then
    local severity = opts.severity or "moderate"
    local duration = def.unconscious_duration[severity] or 5

    -- Armor mitigation
    local helmet = player.worn and player.worn.head
    if helmet then
        local helmet_def = load_object(helmet)
        local reduction = helmet_def.reduces_unconsciousness or 0
        duration = math.max(0, duration - reduction)
    end

    if duration > 0 then
        -- Go unconscious
        player.consciousness = { ... }
    else
        -- Helmet absorbed the blow
        print("Your helmet absorbs the impact. You stagger but stay conscious.")
    end
end
```

Object metadata for armor:

```lua
-- src/meta/objects/iron-helmet.lua
return {
    id = "iron-helmet",
    name = "a dented iron helmet",
    type = "wearable",
    wear_slot = "head",
    reduces_unconsciousness = 3,    -- reduces KO duration by 3 turns
}
```

---

## Interaction Matrix

How consciousness interacts with other player systems:

| System | Conscious | Unconscious | Waking |
|--------|-----------|-------------|--------|
| **Command input** | ✅ Normal | ❌ Skipped | ❌ Skipped (transitional) |
| **Injury ticking** | ✅ Per command | ✅ Per forced tick | ❌ (one-frame state) |
| **Death check** | ✅ After tick | ✅ After each forced tick | ❌ N/A |
| **Object FSM ticking** | ✅ Normal | ✅ Per forced tick | ❌ N/A |
| **Appearance subsystem** | ✅ Available | ❌ Can't look in mirror | ❌ N/A |
| **Movement** | ✅ Normal | ❌ Can't move | ❌ N/A |
| **Sleep verb** | ✅ Available | ❌ Already unconscious | ❌ N/A |

---

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-CONSC001 | Consciousness is a player-level state, not engine-level | Player state lives in `player.lua`. Adding a field to the player table follows the existing "player.lua is single source of truth" pattern. |
| D-CONSC002 | No dazed/intermediate state | Wayne directive (2026-03-22). Binary conscious/unconscious. Clean transitions. Revisit for multiplayer. |
| D-CONSC003 | Game loop uses `if/else`, not a formal FSM module | The loop needs one conditional check. A full FSM framework would be over-engineering for two branches. |
| D-CONSC004 | Injury system is unchanged | `injury_mod.tick()` is already a pure function of player state. Consciousness calls it — no coupling needed. |
| D-CONSC005 | Sleep and unconsciousness share the same "inactive ticking" model | Both skip input and tick injuries. Only the trigger, duration source, and narration differ. DRY. |
| D-CONSC006 | Death check runs before wake timer check | You can't wake up from death. Priority: tick → die check → wake check. |
| D-CONSC007 | Backward compatible — missing `consciousness` field = conscious | Old save files without the field work without migration. |
| D-CONSC008 | Wake timer is turn-based, not time-based | Unconsciousness duration is measured in game turns, not real-time or game-time hours. Each forced tick = one turn toward waking. |

---

## Related

- [README.md](README.md) — Player system overview, canonical player.lua structure
- [health.md](health.md) — Derived health computation (death check depends on this)
- [injuries.md](injuries.md) — Injury FSM system, `injury_mod.tick()` function
- [appearance-subsystem.md](appearance-subsystem.md) — Appearance can't be used while unconscious
- [player-model.md](player-model.md) — Player state structure (consciousness extends this)
