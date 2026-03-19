# Decision: FSM Object Lifecycle System Design

**Date:** 2026-03-23  
**Author:** Comic Book Guy (Game Designer)  
**Status:** Ready for Implementation  
**Related:** Wayne's directive to unify match-lit.lua and match.lua; FSM adoption for object state management

---

## Problem Statement

Objects have multiple states (match: unlit → lit → spent; nightstand: closed ↔ open), currently managed as separate files. This creates:
1. Duplication (each state file has its own full definition)
2. Coordination overhead (verb handlers must know all state variants)
3. Ambiguity on finality (is spent state terminal? reversible?)

Wayne directed: "Match-lit.lua and match.lua should be ONE object with state transitions, not two separate objects."

---

## Solution Overview

**Unified FSM with Hybrid File Organization**

- One logical object per FSM (match, candle, nightstand, etc.)
- Unified state machine definition (initial state, transitions, auto-conditions)
- File-per-state preserved for properties (sensory descriptions, capabilities)
- Engine maps: ID → FSM → current state → load state properties

**FSM Definition Format:**
```lua
fsm = {
    initial_state = "unlit",
    states = {
        unlit = { on_feel = "...", casts_light = false },
        lit = { on_feel = "HOT!", casts_light = true, burn_remaining = 30 },
        spent = { terminal = true },
    },
    transitions = {
        { from = "unlit", to = "lit", verb = "light", requires_tool = "fire_source" },
        { from = "lit", to = "spent", trigger = "auto", condition = "burn_remaining <= 0" },
    },
}
```

---

## Scope

### FSM Objects (7 total)
**Consumables (2):** match, candle  
**Containers (5):** nightstand, vanity, wardrobe, window, curtains

### Static Objects (32 total)
No state transitions needed. Continue current object definitions.

---

## Consumable Pattern: Finite Duration, Terminal States

### Match Lifecycle
```
unlit → (STRIKE on matchbox) → lit (30 ticks) → spent [TERMINAL]
```

- **Duration:** 3 game turns (~30 ticks in code; tunable)
- **Terminal:** Once spent, cannot be re-lit or used as fire_source
- **Gameplay:** Teaches urgency. Players plan matches usage strategically.
- **Warning:** At 5 ticks remaining, "The flame creeps dangerously close to your fingers."

**Rationale:** Matches are the primary resource pressure valve. One-time use creates puzzle coherence: "I have 3 turns to light the candle or I fail."

### Candle Lifecycle
```
unlit → (LIGHT with fire_source) → lit (100 ticks) → stub (20 ticks) → spent [TERMINAL]
```

- **Lit duration:** 100 ticks (~20 game turns; tunable)
- **Stub:** Auto-transition when burned to ~20% of original duration
- **Stub capability:** Still provides fire_source but dimly (light_radius reduced)
- **Terminal:** Spent candle has no light; cannot be re-lit
- **Gameplay:** Rewards match management by providing abundant light. Stub teaches incremental scarcity.
- **Warning:** At 10 ticks remaining, "The wick seems shorter. Hurry!"

**Rationale:** Candles create relief after match urgency. Intermediate stub state allows puzzle variance: some puzzles need full 100 turns, others need 40. Stub is the transition zone.

---

## Container Pattern: Reversible Access Gates

### Examples
- **Nightstand:** closed (drawer inaccessible) ↔ open (drawer accessible)
- **Wardrobe:** closed (contents inaccessible) ↔ open (contents accessible)
- **Window:** closed (blocks sound/wind) ↔ open (allows sound/breeze)
- **Curtains:** closed (blocks light) ↔ open (allows light)

**Key Difference from Consumables:**
- No consumption, no terminal states
- Bidirectional: OPEN → open, CLOSE → closed
- Persistence: A closed drawer stays closed if not opened
- No duration/tick impact

**Rationale:** Containers are information gates, not resources. They teach: "Closed means I can't reach it" (essential for darkness gameplay).

---

## Tick System (Duration Mechanics)

### Events-Driven, Not Wall-Clock
- **1 tick = 1 player command** (EXAMINE, TAKE, LIGHT, etc.)
- **Not real-time.** AFK for 5 minutes = no ticks. Strategic pause is free.
- **Each command triggers tick check** across all consumables in the room/player inventory

### Order of Operations
```
1. Player: "light candle"
2. Engine: Tick all consumables (decrement burn_remaining)
3. Engine: Check auto-transitions (if burn_remaining <= 0, fire transition)
4. Engine: Execute verb handler (candle.light)
5. Engine: Output result
```

**Critical:** Tick happens **before** verb execution. This ensures:
- A player's last action feels fair: "I lit the candle with my final match tick"
- No ambiguity: resource consumed before action resolves

### Warning System
- **Threshold:** When `burn_remaining == warning_threshold` (e.g., 5 for match)
- **Fire once:** Engine tracks `has_warned` flag per object instance
- **Message:** "The match flame creeps dangerously close to your fingers."

---

## Terminal vs. Reversible States

### Terminal States (no transitions out)
- **Match spent:** Cannot be re-lit, cannot be used
- **Candle spent:** Cannot be re-lit, cannot be used
- **Marked:** `terminal = true` in FSM definition

### Reversible States
- **Nightstand open/closed:** Can toggle indefinitely
- **Wardrobe open/closed:** Can toggle indefinitely
- **No terminal states:** Containers can be opened/closed forever

### Mixed (Vanity Case)
The vanity is a container (closeable) + object (mirror intact/broken):
```
vanity (closed, intact) → vanity-open (open, intact)
                       ↘ vanity-mirror-broken (closed, broken)
                          ↘ vanity-open-mirror-broken (open, broken)
```

FSM flattens this to: `open` and `mirror_broken` as orthogonal properties. Simplifies verb dispatch.

---

## File Organization (Hybrid Approach)

**Decision:** Keep file-per-state for properties; add unified FSM definitions.

### Current Structure (Match)
```
src/meta/objects/match.lua        # unlit state properties
src/meta/objects/match-lit.lua    # lit state properties
```

### New Structure (Match with FSM)
```
src/meta/objects/match.lua                         # unified FSM + shared properties
  ├─ fsm.states.unlit = { on_feel, on_smell, ... }
  ├─ fsm.states.lit = { on_feel, on_smell, provides_tool, burn_remaining, ... }
  ├─ fsm.states.spent = { terminal = true }
  ├─ fsm.transitions = { ... }
  └─ fsm.shared_properties = { id, name, keywords, size, weight, ... }
```

**OR:** FSM in separate file (`match-fsm.lua`) that the engine loads alongside object definitions. TBD by architect.

### Benefit
- Designers keep beautiful, detailed sensory descriptions per state
- No massive monolithic definitions
- Engine manages state dispatch; designers focus on content

---

## Puzzle Design Implications

### Match as Urgency Teacher
"I have 3 turns to use this match. If I waste it on EXAMINE, I lose a turn."

Example 8-turn puzzle:
```
turn 1: examine room (2 ticks left on match)
turn 2: feel nightstand (1 tick left)
turn 3: open drawer (match dies; matchbox discovered)
turn 4: take matchbox
turn 5: strike match (new lit match, 3 ticks left)
turn 6: light candle (match dies, candle lit for 100 ticks)
turn 7+: explore safely with candle
```

Emergent: Player must plan strategically because resources are scarce.

### Candle as Relief Reward
"I solved the match phase. Now I have abundant light."

Candle → stub → spent progression creates incremental urgency:
- Lit: "I have time."
- Stub: "I should think ahead."
- Spent: "Find another light or navigate by touch."

### Containers as Information Gates
"I can't reach inside a closed drawer, even by touch."

In darkness, containers enforce puzzle logic without requiring light. Player learns:
- FEEL a nightstand → discover closed drawer
- OPEN drawer → discover matchbox inside
- Information unlocks progressively

---

## Design Rules

1. **One object, many states.** Unify match.lua + match-lit.lua into single FSM object.
2. **Consumables are terminal by default.** Spent match cannot be recycled (teaches consequence).
3. **Containers are reversible.** No destruction on container state change.
4. **Tick happens before action.** Fair resource consumption; no ambiguity.
5. **Warning threshold tunable.** Design team can adjust urgency per puzzle (match at 5 ticks, candle at 10 ticks, etc.).
6. **File-per-state for properties preserved.** Designers keep beautiful descriptions.
7. **Shared properties outside FSM.** id, name, keywords, size, weight go once, referenced by all states.

---

## Implementation Roadmap

### Phase 1: FSM Engine (Architect)
- [ ] Create FSM data structure
- [ ] Implement state machine dispatcher
- [ ] Add tick counter and auto-transition checks
- [ ] Implement warning threshold system

### Phase 2: Consumable Objects (Design)
- [ ] Convert match → FSM (merge match.lua + match-lit.lua)
- [ ] Convert candle → FSM (merge candle.lua + candle-lit.lua)
- [ ] Tune durations in gameplay
- [ ] Validate warning messages

### Phase 3: Container Objects (Design)
- [ ] Convert nightstand → FSM
- [ ] Convert wardrobe, window, curtains → FSM
- [ ] Flatten vanity's 4-state composite
- [ ] Verify all transitions work

### Phase 4: Tuning & Playtest
- [ ] Adjust match burn duration
- [ ] Adjust candle burn duration and stub duration
- [ ] Verify warning thresholds feel right
- [ ] Confirm auto-transitions don't interrupt actions

---

## Open Questions for Architecture

1. **Persistent state:** Do we save current state to database, or regenerate from tick timer on load?
2. **Tick visibility:** Should UI expose "match: 2 ticks left" or keep it implicit in messages?
3. **Cross-room persistence:** Does a lit match keep burning if player goes to another room?
4. **Composite FSMs:** How do vanity's open + mirror_broken states interact? Orthogonal or sequential?

---

## Success Criteria

- [ ] FSM objects (match, candle, containers) transition correctly
- [ ] Auto-transitions fire at the right time (before verb execution)
- [ ] Warning messages appear at threshold without spamming
- [ ] Puzzle pacing feels right (matches create urgency, candles provide relief)
- [ ] Terminal states prevent impossible actions (can't re-light spent match)
- [ ] Reversible states toggle smoothly (can open/close containers indefinitely)

---

**Approved by:** Comic Book Guy  
**Next review:** After Phase 1 (FSM engine implementation)
