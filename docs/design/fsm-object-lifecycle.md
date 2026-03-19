# FSM Object Lifecycle System Design

**Date:** 2026-03-23  
**Designer:** Comic Book Guy (Game Design)  
**Status:** Design Complete (Ready for Implementation)

---

## Executive Summary

Objects in MMO can have multiple states: a candle can be unlit, lit, or burned to a stub. A nightstand can be open or closed. A match can be fresh, burning, or spent. Currently, we handle these as **separate object files** (match.lua, match-lit.lua). Wayne's directive simplifies this: **one logical object, multiple states, managed by an FSM**.

This document defines:
1. How consumable objects burn/deplete over time
2. How container objects open/close
3. The unified FSM definition format that works for both patterns
4. Which of our 39 existing objects need FSM treatment
5. The duration/tick system that triggers state transitions
6. Implementation strategy: preserve existing file-per-state **properties**, add FSM **transitions** on top

---

## 1. The Consumable Duration Pattern

### 1.1 What Burns and Why

**Consumables are resources that disappear.** They are the primary mechanism for creating puzzle urgency. A player who lights a match knows: "I have ~3 turns, then darkness." A lit candle is more generous (~100 turns) but still finite. This creates narrative tension and forces decisions.

#### The Match Lifecycle

```
unlit → (STRIKE on matchbox) → lit → (burn expires OR LIGHT consumes) → spent
```

**States:**
- **unlit:** Default state. A match is inert, takeable, strikeable on a strikestrip.
- **lit:** Active fire source. Burns, casts light, consumable. Can be extinguished or burned to termination.
- **spent:** Terminal. A burnt match stub. Cannot be re-lit, cannot be used for fire. Marks failure to use the resource in time.

**Duration:** 3 game turns (30 game ticks in current code, ~5 ticks per turn; TBD by tuning)

**Gameplay Feel:** 
- Player strikes match: "I have 3 commands to use this light."
- At 2 remaining: room description might hint "the flame flickers" (optional warning)
- At 1 remaining: "The match sputters dangerously low."
- At 0: "The match flame dies. Darkness swallows you."

**Critical Decision:** A match is a **consumable** regardless of path—whether it burns down naturally or the player uses it to light a candle. Either way, it's gone after one use. This teaches: "Resources are not infinite."

#### The Candle Lifecycle

```
unlit → (LIGHT with fire_source) → lit → (burn for ~100 turns) → stub → (burn for ~20 turns) → spent
```

**States:**
- **unlit:** Default. A candle sits waiting in its brass dish.
- **lit:** Active light source. Burns brightly. Provides `fire_source` tool for other candles. Casts `light_radius=2`.
- **stub:** Auto-transition when `burn_remaining` reaches ~20. Light dims (`light_radius=1`). Still burns but weaker. Player can relight if they extinguish; stub can provide fire but dimly.
- **spent:** Terminal. Exhausted tallow, wick burnt to nub. No more light.

**Duration:** 
- lit → stub: ~100 turns (adjustable based on puzzle pacing)
- stub → spent: ~20 turns (reduced to encourage puzzle completion)

**Gameplay Feel:** 
- Lighting a candle feels generous: "I have a lot of time now."
- At 50% lit duration: "The candlelight steadies, warm and reliable."
- At 10 remaining: "The flame gutters. The wick is nearly gone."
- Transitions to stub: "The candle sputters and collapses to a nub. Light dims to a flicker."
- Stub still works but feels fragile, urgent.

**Why This Pattern?** Candles are more forgiving than matches, teaching incremental resource depletion. A player who managed the lit phase can still salvage a stub. But eventually, all light dies—forcing forward progress or a return to darkness.

### 1.2 Duration Mechanics

#### Ticks vs. Turns

- **Tick:** A game action (command) issued by a player. Each EXAMINE, TAKE, LIGHT, etc. is 1 tick.
- **Turn:** Not explicitly modeled yet; we count ticks. For design purposes: assume 1 player command = 1 turn.

#### When Does Tick Happen?

**Before the action completes.** This ensures:
1. Player issues LIGHT command
2. Tick counter decrements
3. Action resolves (candle now lit)
4. If tick counter = 0 after action, object auto-transitions (becomes "spent", message fires)

**Benefit:** Action resolution feels coherent. "I light the candle (1 turn spent)" → "The flame gutters after 99 more turns" feels fair.

#### What Messages Should Fire?

**On transition (automatic):**
- Match: lit → spent: "The match flame dies. Your fingers are cold and dark."
- Candle: lit → stub: "The candlelight sputters and collapses to a nub. Light dims to a flicker."
- Candle: stub → spent: "The last of the wick gutters out. Darkness."

**On warning (at 2-3 remaining ticks):**
- Match: "The flame creeps dangerously close to your fingers. It won't last long."
- Candle (lit): "The wick seems shorter. The flame flickers."
- Candle (stub): "The nub trembles with each breath. Darkness is coming."

**Implementation:** Include `warning_message` and `warning_threshold` in the FSM definition. Engine fires it once per transition warning.

### 1.3 What Happens When Duration Expires Mid-Action?

Example: Player has 1 tick left on a lit match. They issue LIGHT candle.

**Solution: Strict linear order.**
1. Verify match still has ticks (it does: 1)
2. Execute LIGHT action (candle ignites)
3. Decrement match ticks (now: 0)
4. Check auto-transitions (match tick = 0, trigger spent transition)
5. Fire message: "The match dies in your hand."

Result: Candle is lit, match is spent. Player succeeded because they acted fast. No refund.

**Alternative (rejected):** Allow the action to fail if not enough "fuel". Violates principle: if a player manages the puzzle correctly, they succeed.

---

## 2. The Container State Pattern

### 2.1 What Opens and Why

**Containers have accessibility gates.** A closed nightstand drawer is physically present but unreachable (in darkness, you can't fish around blindly for success). An open drawer exposes its contents to FEEL, TAKE, EXAMINE.

This is **not** about consumption or depletion. A nightstand doesn't burn out after 10 openings. It opens and closes reversibly.

#### The Nightstand Lifecycle

```
closed ↔ (OPEN / CLOSE) ↔ open
```

**States:**
- **closed:** Drawer is shut. Surface (`top`) is accessible. Interior (`inside`) is NOT accessible (`accessible=false`). Tactile description: "small drawer handle protrudes."
- **open:** Drawer is pulled out. Both surface and interior are accessible. Tactile description: "drawer slides open under your fingers."

**Reversibility:** Yes. Player can close it again (CLOSE → closed).

**Terminal State:** None. Perpetually reversible.

#### The Vanity Lifecycle (Complex Container + State)

```
closed → open (reversible)
    + 
    can-break-mirror (independent path)
    ↓
    mirror-broken (combines open/closed + broken state)
```

This is **two FSMs converging**:
1. **Drawer state:** closed ↔ open
2. **Mirror state:** intact vs. broken

Result: 4 possible states (closed-intact, open-intact, closed-broken, open-broken). Current implementation uses 3 files (vanity, vanity-open, vanity-open-mirror-broken) because "closed-broken" isn't needed for the bedroom puzzle.

**Key insight:** Composite states require clear naming. Files named `{object}-{state1}-{state2}` grow unwieldy. FSM definition format should flatten this.

#### The Wardrobe and Window Lifecycles

```
wardrobe: closed ↔ open (reversible)
window:   closed ↔ open (reversible)
curtains: closed ↔ open (reversible)
```

All follow the same pattern: binary toggle, reversible, no consumption.

### 2.2 Container vs. Consumable: Key Difference

| Aspect | Consumable | Container |
|--------|-----------|-----------|
| Termination | Yes (spent/exhausted) | No (reversible or permanent) |
| Tick-based? | Yes (time elapses) | No (verb-triggered only) |
| Messages | Auto-transition alerts ("flame dies") | Action confirmations ("drawer opens") |
| Puzzle impact | Resource scarcity (time pressure) | Access control (information gating) |

---

## 3. The FSM Definition Format

### 3.1 Unified Structure

Each FSM object defines:
1. **States** — what can happen to it
2. **Transitions** — verbs and conditions that trigger state changes
3. **Auto-transitions** — duration/condition-based (consumables only)
4. **Terminal states** — states with no outgoing transitions
5. **Shared properties** — fields that don't change across states

#### Example: Match (Consumable)

```lua
fsm = {
    initial_state = "unlit",
    
    states = {
        unlit = {
            description = "A small wooden match with a bulbous red-brown tip...",
            on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
            on_smell = "Faintly sulfurous.",
            provides_tool = nil,
            casts_light = false,
        },
        lit = {
            description = "A small wooden match, burning with a flickering flame...",
            on_feel = "HOT! You burn your fingers.",
            on_smell = "Burning sulfur and wood.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 1,
            consumable = true,
            burn_remaining = 30,
            warning_threshold = 5,
            warning_message = "The flame creeps dangerously close to your fingers.",
        },
        spent = {
            description = "A blackened match stub, cold and inert.",
            on_feel = "A cold, blackened stick. Dead.",
            on_smell = "Charred wood, and nothing else.",
            provides_tool = nil,
            casts_light = false,
            terminal = true,
        },
    },
    
    transitions = {
        {
            from = "unlit",
            to = "lit",
            verb = "strike",
            requires_tool = nil,
            requires_property = "has_striker",  -- target must have this
            message = "You drag the match head across the striker strip. It catches with a sharp hiss.",
        },
        {
            from = "lit",
            to = "unlit",
            verb = "extinguish",
            message = "You pinch the flame out. Darkness.",
        },
        {
            from = "lit",
            to = "spent",
            trigger = "auto",
            condition = "burn_remaining <= 0",
            message = "The match flame dies. Your fingers are cold and dark.",
        },
    },
    
    shared_properties = {
        id = "match",
        name = "a wooden match",
        size = 1,
        weight = 0.01,
        portable = true,
        categories = {"small", "consumable"},
    },
}
```

### 3.2 State Definition

Each state object contains:
- **Sensory descriptions** (on_feel, on_smell, on_listen, on_taste, on_look)
- **Capabilities** (provides_tool, casts_light, light_radius)
- **Duration fields** (consumable, burn_remaining, warning_threshold)
- **Terminal flag** (terminal = true if no outgoing transitions)

### 3.3 Transition Definition

Each transition object contains:
- **from** — origin state
- **to** — destination state
- **verb** — canonical verb (strike, light, open, close)
- **trigger** — "manual" (verb-based) or "auto" (duration/condition-based)
- **condition** — for auto-transitions only (e.g., `burn_remaining <= 0`)
- **requires_tool** — verb check (e.g., "fire_source" for lighting)
- **requires_property** — target property check (e.g., "has_striker" on matchbox)
- **message** — user-facing feedback
- **warning_message** — optional alert before auto-transition
- **warning_threshold** — condition for warning (e.g., "burn_remaining == 5")

### 3.4 Shared Properties

Fields that don't change across states:
- **id, name, keywords** — identity
- **size, weight, portable, categories** — physical attributes
- **guid** — unique identifier

These live outside the FSM definition for clarity and to avoid duplication.

---

## 4. Inventory of All FSM Objects

### 4.1 Current Objects Analysis

**Total objects in src/meta/objects/:** 39

#### FSM Objects (Require State Transitions)

| Object | Type | States | Current Files | FSM Needed? |
|--------|------|--------|----------------|------------|
| match | Consumable | unlit → lit → spent | match.lua, match-lit.lua | YES (consolidate) |
| candle | Consumable | unlit → lit → stub → spent | candle.lua, candle-lit.lua | YES (consolidate) |
| nightstand | Container | closed ↔ open | nightstand.lua, nightstand-open.lua | YES |
| vanity | Container+Property | closed ↔ open; intact ↔ broken | vanity.lua, vanity-open.lua, vanity-open-mirror-broken.lua, vanity-mirror-broken.lua | YES (flatten to FSM) |
| wardrobe | Container | closed ↔ open | wardrobe.lua, wardrobe-open.lua | YES |
| window | Container | closed ↔ open | window.lua, window-open.lua | YES |
| curtains | Container | closed ↔ open | curtains.lua, curtains-open.lua | YES |

#### Static Objects (No FSM Needed)

| Object | Reason |
|--------|--------|
| bed, bed-sheets | Single state, non-interactive |
| pillow, blanket, rug | Single state, non-interactive |
| brass-key, knife, pin, needle | Single state, no state transitions |
| pen, pencil, paper, cloth, rag | Single state (paper-with-writing is spawned dynamically, not state) |
| poison-bottle | Single state (terminal) |
| glass-shard | Spawned debris, no transitions |
| matchbox | Container with contents, no state (closed/open is player perception, not game state) |
| sack, thread | Single state |
| wool-cloak, terrible-jacket | Single state |
| bandage, chamber-pot | Single state |
| vanity-mirror-broken | Terminal state only (only accessed via break_mirror mutation) |

**Summary:** 7 FSM objects require design (2 consumable, 5 container). 32 objects are static.

---

## 5. The Duration/Tick System

### 5.1 How the Game Tracks Turns

**Current Implementation:** Consumables store `burn_remaining` as a tick counter.
- Each game command = 1 tick
- `burn_remaining` decrements per tick
- When `burn_remaining <= 0`, auto-transition fires

**Tick sources:** Any action in a room (EXAMINE, TAKE, FEEL, LIGHT, OPEN, etc.).

**Design Questions:**
1. Should AFK time (player idle for 5 minutes) cause ticks? **NO.** Ticks are tied to actions, not wall-clock time. This respects players who need to think.
2. Should one compound action (STRIKE match ON matchbox) consume 1 or 2 ticks? **1 tick.** One player input = one decision point.
3. Should room messages (ambient descriptions) regenerate after each tick? **Optional.** Can show "The candlelight steadies" passively to reinforce urgency.

### 5.2 When Tick Happens (Order of Operations)

```
1. Player enters command
2. Parse and dispatch verb handler
3. ===== TICK OCCURS HERE (at START of action) =====
4.   - All consumables decrement burn_remaining
5.   - Check auto-transitions (if burn_remaining <= 0, fire)
6.   - If object transitioned (e.g., match spent), output message
7.   - If object survived transition, proceed with verb
8.   - Verb executes (e.g., LIGHT candle)
9.   - Output verb result
10. Return to room state (player sees updated state)
```

**Rationale:** Tick happens before the verb executes. This means:
- "I light the candle" consumes 1 tick
- If player had 1 tick left on a match, match dies before candle is lit
- But candle *is* lit (verb succeeds if candle is accessible)

**Alternative order (rejected):** Tick happens *after* verb. Creates ambiguity: if player's last action is LIGHT, does the match burn out before or after the candle ignites?

### 5.3 Warning Messages

**Threshold:** At `burn_remaining == warning_threshold`, fire warning once.

Example:
- Match lit with 30 ticks: no warning
- At 5 ticks remaining: "The flame creeps dangerously close to your fingers."
- At 1 tick remaining: Optional "Your fingers singe. Hurry!" (or consolidate with final message)

**Implementation:** Engine tracks `has_warned` per object instance. Once fired at threshold, don't repeat.

### 5.4 Auto-Transition Messages

**Format:**
```
{object_name} {state} → {new_state}
Output: "{message}"
```

Examples:
- "Your match spent. The match flame dies. Your fingers are cold and dark."
- "Your candle lit → stub. The candlelight sputters and collapses to a nub."

**Where to output?** After the tick, before the verb result. Player sees:
```
> light candle
The match flame dies. Darkness swallows you.
You feel around for the candle... and find it. Cold, unlit.
> 
```

---

## 6. Design Rules and Implementation Strategy

### 6.1 Wayne's Core Directive

> **Match-lit.lua and match.lua should be ONE object with state transitions, not two separate objects.**

**Interpretation:** Use unified FSM with file-per-state for PROPERTIES.

### 6.2 File Organization (Hybrid Approach)

**Keep:** File-per-state for sensory descriptions and state-specific properties.
- `match.lua` contains: unlit description, on_feel, on_smell
- `match-lit.lua` contains: lit description, fire_source capability, burn_remaining
- New: FSM definition goes in an associated config (TBD: new file or merged into object?)

**Engine maps:** Object ID → FSM definition → current state → load state properties from file.

**Benefit:** Designers can still craft beautiful, detailed descriptions per state without walls of code.

### 6.3 A Spent Match Is Terminal

Once `spent`, a match cannot be:
- Re-lit (no transition back to unlit)
- Used as fire_source (provides_tool = nil)
- Taken and used elsewhere (terminal state prevents mutation)

Teaches: **"Failure to act has consequences."**

**Exception:** Designers can allow `spent → recycled` if puzzle requires it. But default is terminal.

### 6.4 Same Pattern Applies to Candle

- Unlit → Lit → Stub → Spent (terminal)
- Progression is linear; no "relight a spent candle"
- Stub is intermediate, allowing puzzle variance (some puzzles need 120 total turns, some need 40)

### 6.5 Container Reversibility

- Nightstand: closed ↔ open (bidirectional)
- Wardrobe: closed ↔ open (bidirectional)
- Window: closed ↔ open (bidirectional)

No consumption, no terminal states. These are access gates, not resources.

### 6.6 Design Verification Checklist

Before implementing an FSM object, verify:

- [ ] **States are complete.** Can the object reach all necessary states for puzzles?
- [ ] **Transitions are logical.** Does the verb → state mapping match real-world logic or established game convention?
- [ ] **Terminal states are marked.** If a state is unreversible, is `terminal=true` set?
- [ ] **Durations are tested.** For consumables, are turn counts realistic for puzzle completion?
- [ ] **Messages are evocative.** Do they reinforce the game's tone (urgency for matches, relief for candles)?
- [ ] **Warnings work.** Do players get enough notice before auto-transition?

---

## 7. Gameplay Feel and Puzzle Design Implications

### 7.1 Match: Tension and Scarcity

A lit match represents **time pressure**. Players feel it:
- "I have 3 turns." (explicit UI or inference from game messages)
- "If I waste this on EXAMINE, I lose a turn." (strategic thinking)
- "I should light the candle NOW, not later." (forward planning)
- "I ran out of time. I failed." (consequence)

**Puzzle design:** Matches are the first pressure valve. They teach resource management before players encounter harder puzzles.

### 7.2 Candle: Generosity and Relief

A lit candle represents **abundance after scarcity**. Players feel it:
- "I have 100+ turns now. I can explore safely."
- "The stub is still useful, but I should think ahead."
- "This light will die eventually. I need to plan the next puzzle."

**Puzzle design:** Candles enable longer exploration sequences. A bedroom puzzle might be: light match → light candle → explore safely → find key → use key to escape. The candle is the reward for solving the match phase.

### 7.3 Containers: Information Gating

A closed nightstand drawer teaches:
- "Closed means I can't reach it."
- "FEEL tells me it's closed, but doesn't reveal contents."
- "I need to OPEN it, then FEEL its contents."

This is essential for **darkness gameplay**. In pitch-black, closed drawers are a reliable puzzle gate that doesn't require light to enforce.

### 7.4 Composite Puzzles

Example 8-turn sequence:
```
turn 1: examine room
turn 2: feel nightstand (discover closed drawer)
turn 3: open drawer (consume match tick 1/3; match has 2 left)
turn 4: feel inside drawer (discover matchbox)
turn 5: take matchbox (match has 1 left)
turn 6: light candle [action blocked because no fire source yet]
turn 7: strike match on matchbox (match dies, match-lit replaces it, light available)
turn 8: light candle with match (match dies, candle-lit active for 100 turns)
```

Result: Player used all 3 match ticks to navigate, discover, and execute. Candle is now the primary light source. Next puzzle should use the candle as gateway.

**Design principle:** Match scarcity creates puzzle coherence. Without it, players don't strategize; they just randomly TAKE things.

---

## 8. Implementation Roadmap

### Phase 1: FSM Engine (Arch Team)

- [ ] Create FSM definition data structure
- [ ] Implement state machine dispatcher
- [ ] Add tick counter system
- [ ] Implement auto-transition checks
- [ ] Add warning threshold system

### Phase 2: Consumable Objects (Design Team)

- [ ] Convert match.lua + match-lit.lua → unified FSM
- [ ] Convert candle.lua + candle-lit.lua → unified FSM
- [ ] Test duration values in puzzle contexts
- [ ] Validate warning messages

### Phase 3: Container Objects (Design Team)

- [ ] Convert nightstand.lua + nightstand-open.lua → FSM
- [ ] Convert wardrobe, window, curtains → FSM
- [ ] Flatten vanity's 4-state composite into FSM
- [ ] Verify all container transitions work correctly

### Phase 4: Integration & Tuning

- [ ] Playtest match burn duration (currently 30, may need 10-20)
- [ ] Playtest candle burn duration (currently 60, may need 80-120)
- [ ] Verify warning messages appear at correct thresholds
- [ ] Confirm auto-transitions don't interrupt actions

---

## 9. Design Decisions Summary

| Decision | Rationale | Impact |
|----------|-----------|--------|
| Match is terminal when spent | Teaches resource scarcity | Players must plan match usage |
| Candle has intermediate "stub" state | Allows puzzle variance | Some puzzles need generous light, others need urgency |
| Tick happens before verb execution | Avoids ambiguity on resource consumption | Last-turn actions feel fair and coherent |
| Containers are reversible (no terminal) | Access gates, not consumables | Puzzles can gate content without destruction |
| File-per-state for properties preserved | Designers keep beautiful descriptions | Implementation stays modular |
| Warning at 2-3 remaining ticks | Players get notice without being obnoxious | Puzzle difficulty stays tunable |

---

## Appendix A: FSM Definition Template

```lua
fsm = {
    -- Which state does the object start in?
    initial_state = "unlit",
    
    -- Define all reachable states
    states = {
        unlit = {
            -- State-specific descriptions
            on_feel = "...",
            on_smell = "...",
            on_listen = nil,
            on_taste = nil,
            on_look = "...",
            
            -- State-specific capabilities
            provides_tool = nil,
            casts_light = false,
            
            -- For consumables: duration data
            consumable = false,
            burn_remaining = nil,
            warning_threshold = nil,
            
            -- Is this a dead-end state?
            terminal = false,
        },
        -- ... more states
    },
    
    -- Define transitions between states
    transitions = {
        {
            from = "unlit",
            to = "lit",
            verb = "light",
            trigger = "manual",
            requires_tool = "fire_source",
            requires_property = nil,
            message = "The wick catches and curls to life.",
        },
        {
            from = "lit",
            to = "spent",
            verb = nil,
            trigger = "auto",
            condition = "burn_remaining <= 0",
            message = "The light dies. Darkness.",
        },
        -- ... more transitions
    },
    
    -- Properties shared across all states
    shared_properties = {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "light"},
        size = 1,
        weight = 1,
        portable = true,
        categories = {"light source"},
    },
}
```

---

## Appendix B: Open Questions for the Architect

1. **State persistence:** Do we save object state to the database, or regenerate from tick timer each session? (Affects load/save logic)
2. **Tick granularity:** Should we expose tick count to UI? ("Match: 2 ticks remaining") or keep it implicit?
3. **Cross-room persistence:** If a player drops a lit match in one room and goes to another, does it keep burning? (Affects event dispatch)
4. **Puzzle chaining:** Can multiple FSM objects interact (e.g., lighting one candle with another)? Already working via requires_tool, but confirm implementation.

---

**End of Document**
