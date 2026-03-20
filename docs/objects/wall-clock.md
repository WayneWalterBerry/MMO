# Wall Clock — Object Design

## Description
A wall clock in the bedroom. Chimes at the top of every in-game hour. The first ambient timed event object.

## Location
Bedroom (mounted on wall — not a takeable object)

## FSM States

The wall clock uses a **24-state cyclic FSM** (hour_1 through hour_24), where each state represents an in-game hour. States transition automatically every 3600 seconds (1 game hour).

```
hour_1 → hour_2 → hour_3 → ... → hour_23 → hour_24 → hour_1 (cycles continuously)
```

**Why 24 states instead of 1 recurring timer?**
- Standard FSM pattern: Each state is just like any other FSM object
- Engine ticks transitions uniformly — no special-case handling in the engine
- Each state can have unique metadata (room presence text, chime counts, etc.)
- Follows the same timer mechanism as other timed objects (candle burn, match burn)

## State Transitions

Each state transitions to the next via a timed event:

```lua
timed_events = {
  {
    event = "transition",
    delay = 3600,           -- 3600 seconds = 1 game hour
    to_state = "hour_2"     -- transitions from hour_1 to hour_2, etc.
  }
}
```

This pattern is identical to how candle burn and match burn work — timed events that fire after a delay and move to a new state. The engine simply processes the transition; there is nothing clock-specific about the mechanism.

## State-Specific Behavior

Each state has:

| State | Room Presence | Chime Transition | Chime Count |
|-------|---------------|------------------|-------------|
| hour_1 | "The clock reads 1 o'clock." | Chimes as it enters hour_1 | 1 |
| hour_2 | "The clock reads 2 o'clock." | Chimes as it enters hour_2 | 2 |
| hour_3 | "The clock reads 3 o'clock." | Chimes as it enters hour_3 | 3 |
| ... | ... | ... | ... |
| hour_12 | "The clock reads 12 o'clock." | Chimes as it enters hour_12 | 12 |
| hour_13 | "The clock reads 1 o'clock (PM)." | Chimes as it enters hour_13 | 1 |
| ... | ... | ... | ... |
| hour_24 | "The clock reads 12 o'clock (midnight)." | Chimes as it enters hour_24 | 12 |

**Chime Output:**
- "The clock chimes once." (hour_1, hour_13)
- "The clock chimed X times." (all other hours, X ≤ 12)
- During SLEEP: "You heard the clock chime several times during your sleep." (batched)

## Sensory Descriptions

| Sense | Description |
|-------|------------|
| Look | A wooden wall clock with Roman numerals. The pendulum swings steadily. |
| Feel | Smooth wooden case, you can feel the vibration of the mechanism |
| Listen | Steady tick-tock. The clock is reliable, if nothing else. |
| Examine | The clock reads [current game time]. The face is dusty but the mechanism works. |

## Interaction

- **look at clock** — shows current game time
- **listen to clock** — "Tick... tock... tick... tock..."
- **examine clock** — detailed description + current time
- Not takeable (mounted on wall)
- Not breakable (for now — future: smash for parts?)

## Connection to Timed Events System

The wall clock is a **standard FSM object using the timed-transition pattern**:
- One-shot timers (time bomb): single state → transition after delay
- **Recurring timers (clock, candle, match): state → next state after delay, cycles or continues**
- Timer metadata in the .lua file (timed_events table)
- Engine reads and registers timed events when room loads
- Engine ticks transitions uniformly for all FSM objects

There is **no special-case code for the clock** in the engine. It follows the exact same rules as any other timed FSM object.

## Design Philosophy

**From Wayne:** "Try not to have special case objects that can be interpreted from the .lua code, we don't want to have special case in the engine."

The 24-state FSM design upholds this principle:
- **Before:** Recurring timer → clock needed special logic in engine (`type = "recurring"`, `action = "chime"`, custom output function)
- **After:** 24 FSM states → clock uses standard FSM pattern, engine just ticks transitions

This approach scales:
- Add a clock hand that moves? Another FSM state group or property in the state
- Make the clock stop when broken? Just disable timed_events or add a "stopped" state
- Add different chime sounds? Metadata in the state, not special logic in the engine

Standard FSM pattern = extensible, maintainable, no engine bloat.
