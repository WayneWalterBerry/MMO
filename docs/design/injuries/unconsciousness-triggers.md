# Unconsciousness Trigger Objects — Design Specification

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-26  
**Status:** DESIGN  
**Issue:** #162  
**Depends On:** Unconsciousness system (`unconsciousness.md`), Injury engine (`src/engine/injuries.lua`), Concussion injury (`src/meta/injuries/concussion.lua`), Self-hit design (`self-hit.md`), D-CONSC* decisions, D-SELF-INFLICT-CEILING  
**Audience:** Flanders (object `.lua` files), Bart (engine verification), Nelson (TDD + play-test), Smithers (verb routing), Sideshow Bob (puzzle placement)

---

## 0. Preamble

The unconsciousness injury system exists in the engine. The `concussion` injury type exists. The `hit head` self-infliction verb works. What we do NOT have are **environmental objects** that cause unconsciousness through gameplay — traps, hazards, and threats that the player encounters (or deliberately triggers) while exploring the world.

This document specifies four trigger objects. Each one is a full game object with FSM states, material properties, sensory descriptions, trigger conditions, self-infliction commands, narration, and suggested room placement. Flanders builds the `.lua` files from these specs. Bart verifies the engine handles all stacking/timing edge cases. Nelson writes failing tests first (D-TESTFIRST).

**Wayne confirmed all design decisions:**
- 4 triggers: falling rock trap, ceiling collapse, poison gas, enemy blow
- Game-wide first-class injury (not level-scoped)
- Self-infliction is a puzzle mechanic (D-13 pattern, parallels `stab self` and `hit head`)
- Wake up in same room, injuries continue ticking during unconsciousness
- Duration varies by trigger (rock/collapse = long, gas = short, blow = medium)

---

## 1. Design Principles (All Triggers)

### 1.1 Objects Declare Behavior, Engine Executes (Principle 8)

Every trigger object declares its unconsciousness effect in metadata — `causes_unconsciousness = true`, `unconscious_duration`, `injury_type`. The engine reads these fields and applies the concussion injury. **No object-specific code in the engine.**

### 1.2 Self-Infliction Is a Puzzle Mechanic

Per D-SELF-INFLICT-CEILING, self-inflicted damage can never kill. Players can deliberately trigger any of these four objects to enter unconsciousness. This serves two purposes:

1. **Testing:** Players explore injury mechanics safely (parallels `stab self`, `hit head`)
2. **Puzzle solving:** Some puzzles may require the player to be unconscious (e.g., time-skip past a guard patrol, trigger a trap to open a hidden passage). Sideshow Bob will design these.

### 1.3 Duration Varies by Trigger Severity

| Trigger | Severity | Duration (turns) | Design Rationale |
|---------|----------|-----------------|-------------------|
| Falling Rock Trap | Serious | 10–15 | Heavy blunt impact — long KO |
| Ceiling Collapse | Serious | 12–18 | Area-effect trauma — longest KO |
| Poison Gas | Minor | 3–5 | Chemical sedation — short KO |
| Enemy Blow | Moderate | 6–10 | Combat strike — medium KO |

Duration is set per-object in the `unconscious_duration` field. The concussion injury definition already supports severity-based duration mapping (minor=3, moderate=5, severe=10, critical=20). These triggers use the same scale.

### 1.4 All Triggers Inflict the `concussion` Injury

We do NOT create new injury types. All four triggers inflict the existing `concussion` injury with varying severity. The concussion injury already has `causes_unconsciousness = true` and the correct FSM (active → healed). This keeps the injury system unified and avoids duplicating unconsciousness logic.

**Exception:** Poison Gas inflicts `concussion` for the unconsciousness effect but MAY also stack a separate `poisoned-gas` injury for ongoing damage (see §2.3 below).

### 1.5 Material Consistency (Principle 9)

Each trigger object has real-world material properties. A falling rock is granite. A collapsing ceiling is timber and plaster. Poison gas is an airborne chemical. These materials affect sensory descriptions and interaction possibilities.

---

## 2. Per-Trigger Design

---

### 2.1 Falling Rock Trap

#### Identity

| Field | Value |
|-------|-------|
| **id** | `falling-rock-trap` |
| **name** | "a crude rock trap" |
| **template** | `furniture` (wall-mounted mechanism) |
| **keywords** | `rock trap`, `trap`, `falling rock`, `rock`, `tripwire`, `wire` |
| **material** | granite (rock), hemp (tripwire) |
| **weight** | immovable (trap mechanism is fixed) |
| **description** | "A heavy granite boulder sits in a crude wooden cradle bolted to the ceiling, held in place by a fraying hemp rope threaded through an iron ring. A thin tripwire stretches across the floor at ankle height." |

#### Sensory Descriptions

| Sense | Description |
|-------|-------------|
| **on_feel** | "Your fingers find a taut cord stretched across the passage at ankle height. Following it, you trace it to a rough iron ring set in the wall. Something heavy hangs above." |
| **on_smell** | "Old rope. Dust. The faint mineral smell of raw stone." |
| **on_listen** | "A faint creaking from above, like rope under tension." |
| **on_taste** | *(not applicable — player shouldn't lick a trap)* "You'd have to put your mouth on a tripwire. Probably not wise." |

#### FSM States

```
    armed
      |
      | (player walks into tripwire / self-triggers)
      v
   triggered ──── (rock falls, unconsciousness applied)
      |
      | (permanent — rock is on the floor now)
      v
    spent
```

| State | Description | `on_feel` | Interactions |
|-------|-------------|-----------|--------------|
| **armed** | Trap is set. Rock overhead, tripwire taut. | "A taut cord at ankle height. Something heavy above." | Player can `examine`, `feel`, `cut tripwire` (disarms), or walk through (triggers) |
| **triggered** | Rock has fallen. Brief transition state. | "A huge boulder blocking the passage. Still warm from the impact." | Unconsciousness applied. Transition to `spent` is immediate. |
| **spent** | Rock is on the floor. Tripwire slack. Trap is permanently disarmed. | "A heavy boulder on the ground. A frayed rope dangles from a ceiling ring." | Rock becomes a movable obstacle. Can be `push`ed or `climb`ed over. |

#### Trigger Conditions

1. **Walk-through:** Player enters the room or moves through the trapped passage → tripwire triggers automatically
2. **Touch tripwire:** `feel wire`, `touch tripwire` → triggers the trap (your hand pulls the wire)
3. **Self-infliction:** `trigger trap`, `pull wire`, `step on wire`, `walk into trap`
4. **Disarm (avoidance):** `cut wire`, `cut tripwire with knife` → rope severs, rock falls harmlessly to the side, trap spent without injury

#### Self-Infliction Commands

| Command | Resolution | Effect |
|---------|-----------|--------|
| `trigger trap` | Direct verb on trap object | Rock falls, concussion (severe), 10–15 turns unconscious |
| `pull wire` | Verb on tripwire sub-object | Same as above |
| `step on wire` | Movement verb, triggers trap | Same as above |
| `walk into trap` | Contextual — parser resolves to trap trigger | Same as above |
| `hit myself with rock` | Self-infliction with object modifier | Concussion (severe), 10–15 turns. Rock must be in `spent` state (on floor) and player must `take rock` first. |

#### Unconsciousness Details

| Field | Value |
|-------|-------|
| **injury_type** | `concussion` |
| **severity** | `severe` |
| **duration** | 10–15 turns (maps to concussion `severe` = 10 base, +random 0–5) |
| **initial_damage** | 8 (heavy rock impact — more than bare fist) |
| **source** | `"falling-rock-trap"` (external) or `"self-inflicted:falling-rock-trap"` |
| **location** | `"head"` |

#### Narration

**Trigger text (walk-through):**
> *Your foot catches on something — a wire, stretched taut across the passage. You hear a snap, then a terrible grinding above. You look up. The last thing you see is a shadow the size of a boulder.*

**Trigger text (self-infliction):**
> *You pull the wire deliberately. The snap echoes in the silence. The grinding starts. You have just enough time to think "this was a mistake" before the world goes dark.*

**Unconscious text (periodic, during KO turns):**
> *Weight. Unbearable weight pressing down. The smell of dust and blood. You can't move. You can't think.*

**Wake-up text:**
> *Consciousness returns like a slow tide. Your head screams. Your body is pinned beneath something immensely heavy — no, the rock has rolled aside. You're free. But the ache in your skull tells you you were out for a long time.*

#### Room/Level Suggestions

- **Cellar passage** (between cellar and deep-cellar) — classic dungeon trap placement
- **Crypt entrance** — ancient trap protecting tomb contents
- **Future Level 2:** Mine shafts, collapsed tunnels

#### Mutations

| Mutation | Becomes | Message |
|----------|---------|---------|
| `break` | N/A — granite doesn't break from player force | "The rock is solid granite. Your efforts accomplish nothing but sore knuckles." |
| `cut wire` (armed state) | `falling-rock-trap-disarmed` | "You slice through the hemp wire. There's a grinding sound, then a heavy thud — the boulder drops harmlessly to one side. The trap is spent." |

---

### 2.2 Ceiling Collapse

#### Identity

| Field | Value |
|-------|-------|
| **id** | `unstable-ceiling` |
| **name** | "a cracked and sagging ceiling" |
| **template** | `room-feature` (environmental hazard, not a discrete object) |
| **keywords** | `ceiling`, `cracks`, `sagging ceiling`, `unstable ceiling`, `cracked ceiling`, `timber`, `plaster` |
| **material** | timber (beams), plite (plaster), stone (aggregate) |
| **weight** | immovable (it's the ceiling) |
| **description** | "The ceiling sags ominously. Deep cracks spider across the plaster between ancient timber beams. Dust sifts down in thin streams. Every footstep sends a tremor through the joists." |

#### Sensory Descriptions

| Sense | Description |
|-------|-------------|
| **on_feel** | "Grit falls on your fingers when you touch the wall. The timber beams overhead groan softly. The plaster between them is warm — dry rot." |
| **on_smell** | "Plaster dust. Dry-rotted wood. The stale air of a space that hasn't breathed in decades." |
| **on_listen** | "A continuous low creaking. The occasional tick of plaster flakes hitting the floor. The ceiling is alive with the sound of slow failure." |
| **on_taste** | "Plaster dust coats your tongue. Chalky, gritty, unpleasant." |

#### FSM States

```
    unstable
       |
       | (loud noise / impact / player pushes beam)
       v
   collapsing ──── (debris falls, unconsciousness + crushing-wound)
       |
       | (permanent — ceiling is down)
       v
    collapsed
```

| State | Description | `on_feel` | Interactions |
|-------|-------------|-----------|--------------|
| **unstable** | Ceiling intact but dangerous. Dust falls. Creaking sounds. | "Grit and dust. Groaning timbers above." | Player can `examine`, `listen`, `push beam` (triggers), `shout` (triggers), `prop ceiling` (prevents collapse with suitable object) |
| **collapsing** | Brief transition. Debris rains down. | "Chunks of plaster and timber falling around you." | Unconsciousness + crushing-wound applied. Immediate transition to `collapsed`. |
| **collapsed** | Rubble everywhere. Passage may be blocked. | "A heap of broken timber, plaster chunks, and stone rubble." | Room description changes. May block an exit. Rubble can be `search`ed for salvage. |

#### Trigger Conditions

1. **Loud noise:** Player `shout`s, `yell`s, or makes a loud noise in the room → vibration triggers collapse
2. **Physical impact:** Player `push`es a beam, `hit`s the wall, or causes structural vibration
3. **Timed:** After N turns in the room, collapse triggers automatically (environmental pressure)
4. **Self-infliction:** `push beam`, `hit ceiling`, `shake timber`, `pull beam`, `make noise`
5. **Prevention (avoidance):** `prop ceiling with plank`, `brace beam` → delays or prevents collapse if player has a suitable bracing object

#### Self-Infliction Commands

| Command | Resolution | Effect |
|---------|-----------|--------|
| `push beam` | Verb on ceiling sub-object | Collapse triggers, concussion (severe) + crushing-wound |
| `hit ceiling` | Verb on room feature | Same as above |
| `shout` / `yell` | Verb in this room triggers collapse | Same as above |
| `shake timber` | Verb on ceiling sub-object | Same as above |
| `pull beam down` | Deliberate structural destruction | Same as above |

#### Unconsciousness Details

| Field | Value |
|-------|-------|
| **injury_type** | `concussion` (unconsciousness) + `crushing-wound` (stacking damage) |
| **severity** | `severe` (concussion) |
| **duration** | 12–18 turns (longest — area-effect, multiple impacts) |
| **initial_damage** | 10 (concussion) + 15 (crushing-wound) = 25 total on impact |
| **source** | `"unstable-ceiling"` (external) or `"self-inflicted:unstable-ceiling"` |
| **location** | `"head"` (concussion), `"torso"` (crushing-wound) |

**CRITICAL STACKING:** Ceiling collapse inflicts TWO injuries simultaneously:
1. `concussion` (causes unconsciousness, 12–18 turns)
2. `crushing-wound` (over-time bleed at 2 HP/turn while unconscious)

This is the most dangerous trigger because the crushing-wound **ticks during unconsciousness**. A player who enters this room already injured may die during the KO.

#### Narration

**Trigger text (noise-triggered):**
> *The sound echoes against the walls — and the ceiling answers. A crack like a gunshot splits the air. Timber groans, plaster erupts, and the world comes apart above you. You throw your arms over your head but it's not enough. Something massive strikes you down.*

**Trigger text (self-infliction — push beam):**
> *You shove the timber beam. It shifts. Then everything shifts. The groan becomes a roar. You have a single, brilliant instant of clarity — you just brought the ceiling down on yourself — before the darkness takes you.*

**Unconscious text:**
> *Dust. Weight. The taste of blood and plaster. Something presses against your chest. Breathing is a labor. Far away, timber settles with a final, tired creak.*

**Wake-up text:**
> *You cough yourself awake. Dust fills your lungs. Your body is a map of pain — your head throbs, your ribs scream, and you can barely see through the grit in your eyes. Chunks of plaster and splintered timber surround you. The ceiling is gone. Rubble fills the space where it used to be.*

#### Room/Level Suggestions

- **Deep cellar** — ancient structure, centuries of neglect
- **Crypt** — disturbing the dead has consequences
- **Storage cellar** — overloaded shelving weakening the joists above
- **Future Level 2:** Abandoned mine, ruined tower

#### Mutations

| Mutation | Becomes | Message |
|----------|---------|---------|
| State `unstable` → `collapsed` | Room description mutates. Exits may be blocked by rubble. | (narration above) |
| `search rubble` (collapsed) | Player may find objects buried in debris | "You dig through the rubble and find..." |

---

### 2.3 Poison Gas

#### Identity

| Field | Value |
|-------|-------|
| **id** | `poison-gas-vent` |
| **name** | "a cracked vent pipe" |
| **template** | `furniture` (wall-mounted hazard) |
| **keywords** | `vent`, `pipe`, `gas`, `poison gas`, `crack`, `cracked pipe`, `gas vent`, `fumes` |
| **material** | iron (pipe), (gas is airborne — no material for the gas itself) |
| **weight** | immovable (fixed to wall) |
| **description** | "A corroded iron pipe protrudes from the wall near the floor, cracked along its length. A faint, sweetish haze seeps from the fracture. The air near it shimmers." |

#### Sensory Descriptions

| Sense | Description |
|-------|-------------|
| **on_feel** | "The pipe is cold iron, rough with corrosion. Your fingers come away with a faint oily residue. The air around it feels heavier than it should." |
| **on_smell** | "Sweet. Cloying. Like overripe fruit left in a closed room. Your head swims after a few breaths." |
| **on_listen** | "A thin, continuous hiss. Gas escaping under pressure." |
| **on_taste** | "The air tastes sweet and thick. Immediately wrong. Your tongue goes numb." |

#### FSM States

```
    leaking
       |
       | (player stays too long / breathes deeply / self-triggers)
       v
    active ──── (gas overwhelms, unconsciousness applied)
       |
       | (resettable — gas continues after player wakes)
       v
    leaking (returns to leaking — trap resets!)
```

| State | Description | `on_feel` | Interactions |
|-------|-------------|-----------|--------------|
| **leaking** | Gas seeps out continuously. Low concentration. Warning signs present. | "Oily residue on the pipe. Heavy air." | Player can `examine`, `smell` (warning), `plug pipe` (blocks gas), `leave room` (avoidance). Extended presence triggers transition. |
| **active** | Gas concentration critical. Player is affected. | "Your limbs are heavy. Vision blurs. The sweet smell is overwhelming." | Unconsciousness applied. Returns to `leaking` after player wakes (gas dissipates while unconscious, then builds again). |
| **plugged** | Player has blocked the vent. | "A wad of cloth stuffed into the cracked pipe. The hissing has stopped." | Safe. Gas no longer accumulates. Can be unplugged. |

**Key design: This trap RESETS.** Unlike the rock trap and ceiling collapse (which are permanent/one-shot), the gas vent continues leaking. A player who wakes up and stays in the room will be knocked out again. This creates a room-escape puzzle: get in, do what you need, get out before the gas takes you. Or plug the vent.

#### Trigger Conditions

1. **Timed exposure:** Player stays in the room for N turns (3–4 turns) → gas concentration builds → unconsciousness
2. **Deep breath:** `breathe`, `breathe deeply`, `inhale`, `sniff gas` → instant trigger (skips the timer)
3. **Self-infliction:** `breathe gas`, `inhale fumes`, `sniff pipe`, `smell gas deeply`
4. **Prevention:** `plug pipe with cloth`, `stuff vent`, `block pipe` → requires cloth/rag item in hand. Transitions to `plugged` state.
5. **Avoidance:** Leave the room before the timer expires. Timer resets on re-entry.

#### Self-Infliction Commands

| Command | Resolution | Effect |
|---------|-----------|--------|
| `breathe gas` | Direct verb on gas | Instant unconsciousness, concussion (minor), 3–5 turns |
| `inhale fumes` | Synonym resolution | Same as above |
| `sniff gas` | Sensory verb override → trigger | Same as above |
| `smell pipe` | Sensory verb on pipe → warning only ("It smells sweet and wrong") | No KO — just a warning. Deliberate `breathe` is required for self-infliction. |

#### Unconsciousness Details

| Field | Value |
|-------|-------|
| **injury_type** | `concussion` (unconsciousness only — gas sedates, doesn't concuss) |
| **severity** | `minor` |
| **duration** | 3–5 turns (short — gas sedation wears off fast) |
| **initial_damage** | 2 (minimal — gas sedates more than harms) |
| **source** | `"poison-gas-vent"` (external) or `"self-inflicted:poison-gas-vent"` |
| **location** | `"head"` (inhalation affects the brain) |

**Design note:** Poison gas causes unconsciousness but deals minimal direct damage. The danger is:
1. Other injuries ticking during the KO (bleeding + gas KO = death risk)
2. Repeated exposure (wake up, still in room, get gassed again)
3. Time loss (puzzle timer, day/night cycle advancement)

**Future consideration:** A stronger gas variant could stack a separate `poisoned-gas` injury type (nausea, ongoing HP drain). For V1, the sedative effect (concussion-based unconsciousness) is sufficient.

#### Narration

**Warning text (entering room with leaking vent):**
> *The air is thick here. A sweetish smell hangs low, almost pleasant — almost. Something about it makes your head feel light.*

**Escalation text (after 2 turns in room):**
> *The sweet smell is stronger. Your thoughts are moving slower. You should leave. You really should leave.*

**Trigger text (timed exposure):**
> *The room sways. Your knees buckle. The sweet smell fills your skull like cotton wool, pushing everything else out — your name, your purpose, the floor rising to meet your face. Then nothing.*

**Trigger text (self-infliction — breathe gas):**
> *You lean toward the cracked pipe and breathe deeply. The sweetness floods your lungs, rich and heavy. Your vision narrows to a pinpoint. A distant voice in your head says this was idiotic. The voice is correct. Darkness.*

**Unconscious text:**
> *Sweet nothing. A chemical dreamlessness, empty as glass. Time passes without you.*

**Wake-up text:**
> *You gasp awake, lungs burning. The sweet taste coats your throat. Your head aches — a chemical headache, sharp and thin. The air is still heavy. You need to move.*

#### Room/Level Suggestions

- **Storage cellar** — corroded plumbing in a neglected underground space
- **Deep cellar** — deeper underground, older infrastructure, more dangerous
- **Future Level 2:** Alchemy lab, sewer system, mine with gas pockets

#### Mutations

| Mutation | Becomes | Message |
|----------|---------|---------|
| `plug pipe` (leaking state) | `poison-gas-vent-plugged` | "You stuff the cloth into the crack. The hissing stops. The air begins to clear." |
| `unplug pipe` (plugged state) | Returns to `leaking` | "You pull the cloth free. The hissing resumes immediately. The sweet smell creeps back." |

---

### 2.4 Enemy Blow

#### Identity

| Field | Value |
|-------|-------|
| **id** | `falling-club-trap` |
| **name** | "a spring-loaded club" |
| **template** | `furniture` (concealed mechanism) |
| **keywords** | `club`, `trap`, `spring trap`, `mechanism`, `lever`, `club trap`, `spring` |
| **material** | oak (club head), iron (spring mechanism), hemp (release cord) |
| **weight** | immovable (mechanism is wall-mounted) |
| **description** | "A heavy oak club is mounted on a spring-loaded iron arm, concealed behind a false wall panel. A pressure plate on the floor serves as the trigger." |

**Design rationale:** Issue #162 specifies "enemy blow" as a trigger, but V1 has no NPCs (Principle 0: Objects are inanimate). The enemy blow is implemented as a **mechanical trap that simulates an enemy strike** — a spring-loaded club, like a medieval booby trap. This preserves the "combat hit" feel while staying within V1's object-only architecture. When NPCs arrive (Phase 2+), real enemy strikes will use the same concussion injury with `severity = moderate`.

#### Sensory Descriptions

| Sense | Description |
|-------|-------------|
| **on_feel** | "Your fingers find a seam in the wall — a panel that shifts slightly. Below your feet, a flagstone rocks under your weight. Something is rigged here." |
| **on_smell** | "Machine oil. The faint metallic tang of a spring under tension." |
| **on_listen** | "A faint metallic creak when you shift your weight. Something is coiled and waiting." |
| **on_taste** | "You taste iron and oil on the air. Industrial. Wrong for a cellar." |

#### FSM States

```
    armed
      |
      | (player steps on plate / self-triggers)
      v
   triggered ──── (club swings, unconsciousness applied)
      |
      | (mechanism can be reset or stays spent)
      v
    spent
```

| State | Description | `on_feel` | Interactions |
|-------|-------------|-----------|--------------|
| **armed** | Trap is set. Pressure plate active. Club cocked. | "A loose flagstone underfoot. A seam in the wall panel." | Player can `examine`, `feel`, `disarm trap` (with tools), or step on plate (triggers). |
| **triggered** | Club has swung. Brief transition. | "A heavy oak club, still swinging on its iron arm." | Unconsciousness applied. Immediate transition to `spent`. |
| **spent** | Club extended, spring relaxed. Trap is done. | "A heavy club on a limp iron arm. A relaxed spring. The mechanism is spent." | Club can potentially be `take`n (detached). Pressure plate is inert. |

#### Trigger Conditions

1. **Pressure plate:** Player steps on the flagstone (movement through the space, or `step on plate`)
2. **Interaction:** `push panel`, `open panel` → reveals the mechanism and triggers it
3. **Self-infliction:** `step on plate`, `trigger trap`, `push lever`, `activate mechanism`
4. **Disarm:** `disarm trap`, `jam mechanism`, `block spring with <object>` → requires a tool (knife, stick, metal rod). Transitions to `spent` without firing.

#### Self-Infliction Commands

| Command | Resolution | Effect |
|---------|-----------|--------|
| `step on plate` | Verb on pressure-plate sub-object | Club swings, concussion (moderate), 6–10 turns |
| `trigger trap` | Direct verb on trap | Same as above |
| `push lever` | Verb on mechanism sub-object | Same as above |
| `activate mechanism` | Contextual resolution | Same as above |

#### Unconsciousness Details

| Field | Value |
|-------|-------|
| **injury_type** | `concussion` |
| **severity** | `moderate` |
| **duration** | 6–10 turns (moderate — a club strike, not a boulder) |
| **initial_damage** | 5 (standard blunt impact — same as bare-fist concussion) |
| **source** | `"falling-club-trap"` (external) or `"self-inflicted:falling-club-trap"` |
| **location** | `"head"` |

#### Narration

**Trigger text (pressure plate):**
> *The flagstone sinks under your foot with a click. You hear a metallic twang — and then something fast and heavy fills your vision. A wooden club, swinging out from the wall on an iron arm. It connects with the side of your head. The world cracks apart.*

**Trigger text (self-infliction):**
> *You step on the loose flagstone deliberately. Click. Twang. The club catches you perfectly across the temple. You had time to brace for it. It didn't help.*

**Unconscious text:**
> *Ringing. A high, sustained tone, like a struck bell. Your head is a bell. Someone struck it. The tone fades to silence.*

**Wake-up text:**
> *Your eyes open to stone floor. Your temple throbs with a hot, rhythmic ache. The oak club hangs limply from its iron arm, spent. The trap got you. You sit up slowly, vision swimming.*

#### Room/Level Suggestions

- **Hallway** — protecting a door or passage
- **Crypt entrance** — ancient security measure
- **Cellar** — hidden trap near valuable storage
- **Future Level 2:** Guard rooms, treasure vaults, NPC territory boundaries

#### Mutations

| Mutation | Becomes | Message |
|----------|---------|---------|
| `disarm` (armed state) | `falling-club-trap-disarmed` | "You wedge the knife into the spring mechanism. There's a click, a soft whir, and the club drops limply. The trap is harmless now." |
| `take club` (spent state) | Club becomes inventory item | "You wrench the oak club free of its iron mount. Heavy. Solid. This would make a decent weapon." |

---

## 3. Injury Stacking Rules

Unconsciousness creates a window of vulnerability. These rules govern how injuries interact when the player is KO'd.

### 3.1 Core Rule: All Injuries Tick During Unconsciousness

Per D-CONSC004 and D-CONSC005, the injury system (`injuries.tick()`) is called every turn regardless of consciousness state. The unconsciousness system does not pause, gate, or modify injury ticking in any way. This is non-negotiable.

**Practical consequence:** A player who goes unconscious with active injuries is on a death clock. The longer the KO, the more damage accumulates.

### 3.2 Stacking Scenarios

#### Bleeding + Unconsciousness

| Turn | State | Bleeding (5/turn) | Concussion | Health (start: 100) |
|------|-------|--------------------|------------|----------------------|
| 0 | Conscious | Active | — | 95 (5 initial) |
| 1 | Hit by rock trap | — | Applied (severity=severe, initial=8) | 82 (95 - 5 bleed - 8 concussion) |
| 2 | Unconscious (turn 1/12) | Ticks | — | 77 |
| 3 | Unconscious (turn 2/12) | Ticks | — | 72 |
| ... | ... | ... | — | ... |
| 13 | Unconscious (turn 12/12) | Ticks | — | 22 |
| 14 | Waking | Ticks | Timer expired | 17 |
| 15 | Conscious | Still ticking | Heals eventually | 12 |

**Verdict:** Survived — barely. If the bleeding had been at 8/turn (worsened state), the player would die on turn 12.

#### Crushing Wound + Concussion (Ceiling Collapse)

The ceiling collapse inflicts BOTH injuries simultaneously:
- Concussion: 10 initial + causes 12–18 turn KO
- Crushing wound: 15 initial + 2/turn bleed

Combined initial damage: 25 HP on impact. During 15 turns of unconsciousness, the crushing wound drains an additional 30 HP. Total: 55 HP from one event. A player below 55 HP will die.

**This is intentional.** The ceiling collapse is the most dangerous trigger. Players who see the warning signs (creaking, dust, cracks) and ignore them face real consequences.

#### Poison + Gas KO

If the player has nightshade poisoning (8/turn) and gets gassed (3–5 turn KO):
- 3 turns unconscious × 8 damage/turn = 24 additional poison damage during KO
- Plus the gas's own initial 2 damage

The short gas KO duration mitigates the risk. This is the "safest" unconsciousness trigger when already injured.

### 3.3 Multiple Unconsciousness Sources

Per the existing design (§9.1 of `unconsciousness.md`): unconsciousness is a **player state**, not a stackable injury. If the player is already unconscious and a new KO source triggers:

- **Longer duration:** New duration replaces old if longer. Timer resets to the longer value.
- **Shorter duration:** Ignored. Current timer continues.
- **Additional injury:** The concussion injury itself stacks normally (additional damage instance).

**Example:** Player is unconscious (gas, 3 turns remaining). Ceiling collapses (15 turns). Timer resets to 15 turns. Player now has two concussion instances (gas + collapse) and a crushing wound — three active injuries.

### 3.4 Self-Infliction Stacking

Per D-SELF-INFLICT-CEILING, self-inflicted damage alone cannot kill. However:

- Self-inflicted unconsciousness CAN allow external injuries to kill during the KO
- **Example:** Player has bleeding wound (external source) + hits own head → goes unconscious → bleeding ticks → can die
- The death check in `injuries.tick()` sees the bleeding wound as external → `has_external = true` → death is possible

**Design implication for puzzles:** If Sideshow Bob designs a puzzle requiring self-inflicted unconsciousness, the player MUST treat any active bleeding/poison injuries first. Getting knocked out while bleeding is a learnable risk.

---

## 4. Command Rejection During Unconsciousness

### 4.1 The Gate

Per D-CONSC-GATE, the consciousness check runs at the **top** of the game loop, before input reading. When unconscious, all player commands are rejected.

### 4.2 Rejection Messages

Rather than a single static message, the rejection text varies to maintain immersion. The engine cycles through these based on the KO source:

#### Generic (any source)

> *"You can't. The darkness holds you down."*

> *"Nothing responds. Not your eyes, not your limbs, not your voice. You are elsewhere."*

> *"Consciousness is a distant shore. You drift."*

#### Rock Trap / Ceiling Collapse (heavy impact)

> *"Weight. Pressure. Your body refuses every signal your brain sends."*

> *"You try to move. Pain answers. You stop trying."*

> *"Somewhere far away, your fingers twitch. That's all."*

#### Poison Gas (chemical sedation)

> *"The sweetness won't let go. Your thoughts dissolve before they form."*

> *"You try to think. The thought has no edges. It melts."*

> *"Breathing. That's all you manage. In. Out. The sweet air fills you."*

#### Enemy Blow / Club Trap (combat strike)

> *"Your ears ring. The world is a tone — one long, sustained note."*

> *"You hear your own heartbeat, slow and thick. Nothing else."*

> *"Movement is a concept you can no longer parse."*

### 4.3 Implementation Notes

The game loop already uses `goto continue` to skip input reading when unconscious. The rejection messages should be printed **only when the player has typed something** — not on auto-tick turns. This means:

1. If the player mashes keys during unconsciousness, they see rejection messages
2. If no input is provided (headless mode, automated testing), no rejection messages appear
3. The message selection uses `player.consciousness.cause` to determine which pool to draw from

Smithers: store the rejection message pool on the concussion injury definition or on the trigger object's `rejection_messages` field. The game loop reads the field from the active injury source.

### 4.4 Special Commands During Unconsciousness

ALL commands are rejected. No exceptions. Including:
- `inventory` — "You can't check your pockets. You can't feel your pockets."
- `injuries` — "You can't examine yourself — you're unconscious."
- `save` / `quit` — These are META commands, not player commands. They MUST still work. Smithers: gate on `is_meta_command`, not consciousness state.
- `look` — "Darkness. Not the darkness of a lightless room — the darkness of a switched-off mind."

---

## 5. Future Multiplayer Hooks

These features are **noted for design** but **not implemented in V1**. They exist so that Bart and Smithers don't build anything that makes them impossible later.

### 5.1 Drag / Carry Unconscious Player

In multiplayer, another player can `drag <player>` or `carry <player>` to move them to a different room. This requires:
- Both hands free (carrying is a two-hand action)
- The unconscious player's weight ≤ carrier's strength
- Movement speed penalty while carrying

**Engine implication:** The `player.location` field must be writable by another player's action. Currently, only the game loop sets location. No changes needed now — just don't hardcode assumptions that only the player moves themselves.

### 5.2 Rob Unconscious Player

Another player can `take <item> from <player>` when the target is unconscious:
- Inventory is accessible (both hands, backpack if implemented)
- The unconscious player is notified on wake-up: *"Something is missing. Your [item] is gone."*

**Engine implication:** Inventory access must not be gated by `player == ctx.player`. A generic `access_inventory(target_player)` function should work for any player object. Don't build this now, but don't block it either.

### 5.3 Wake Up a Player

Another player can `wake <player>`, `shake <player>`, or `slap <player>` to reduce the unconsciousness timer:
- Base effect: reduces timer by 30–50%
- Stacking: can be done once per unconsciousness event
- Some triggers resist early wake-up (ceiling collapse → too much trauma to wake early)

**Engine implication:** The `consciousness.remaining_turns` field must be writable by verb handlers, not just decremented by the game loop tick. It already is (it's just a number on the player table), so no changes needed.

### 5.4 Protect Unconscious Player

In a combat scenario, another player can `guard <player>` to prevent enemies from attacking the unconscious player. This is pure combat-system design and has zero V1 implications.

---

## 6. Summary: What Each Team Member Needs

### Flanders (Object Design)

Create 4 `.lua` object files in `src/meta/objects/`:
1. `falling-rock-trap.lua` — FSM: armed → triggered → spent. Material: granite, hemp.
2. `unstable-ceiling.lua` — FSM: unstable → collapsing → collapsed. Material: timber, plaster, stone. ALSO create `unstable-ceiling-collapsed.lua` mutation target.
3. `poison-gas-vent.lua` — FSM: leaking → active → leaking (resets!). ALSO create `poison-gas-vent-plugged.lua` mutation target. Material: iron.
4. `falling-club-trap.lua` — FSM: armed → triggered → spent. Material: oak, iron, hemp.

Each object needs `causes_unconsciousness = true`, `unconscious_severity`, and `unconscious_duration` fields. Use the concussion injury type. Follow the patterns in existing injury-causing objects.

### Bart (Engine Architect)

Verify that:
- `injuries.tick()` runs every turn during unconsciousness (already confirmed by D-CONSC004)
- Multiple concurrent concussion instances don't cause double-unconsciousness (player state is binary — D-CONSC002)
- Self-infliction ceiling applies to trigger objects when source contains `"self-inflicted"` (D-SELF-INFLICT-CEILING)
- Death check handles the ceiling-collapse scenario (two simultaneous injuries, external source)

### Nelson (QA / TDD)

Write failing tests FIRST (D-TESTFIRST) for:
- [ ] Each trigger object causes unconsciousness with correct severity/duration
- [ ] Self-infliction works for all 4 triggers (all commands in §2.x tables)
- [ ] Gas vent resets after player wakes (can be knocked out again)
- [ ] Gas vent can be plugged (transitions to `plugged`, no more KO)
- [ ] Ceiling collapse inflicts BOTH concussion and crushing-wound
- [ ] Injury stacking: bleeding + rock trap KO → bleeding ticks during KO
- [ ] Injury stacking: nightshade + gas KO → poison ticks during KO
- [ ] Player wakes in same room for all 4 triggers
- [ ] Commands rejected with correct source-specific narration
- [ ] `save`/`quit` still work during unconsciousness
- [ ] Rock trap and club trap can be disarmed (avoidance path)
- [ ] Duration varies correctly per trigger type
- [ ] Self-inflicted KO + external bleeding → player can die (self-infliction ceiling doesn't protect against external injuries ticking during self-inflicted KO)

### Smithers (Parser / UI)

- Route self-infliction commands to trap trigger handlers (see §2.x tables)
- Implement rejection message pools (§4.2) — read from injury source or trigger object
- Gate meta-commands (`save`, `quit`) to bypass consciousness check
- Wire up `smell gas` as warning vs. `breathe gas` as trigger (important distinction)

### Sideshow Bob (Puzzles)

- The gas vent is a natural room-escape puzzle: get in, do the thing, get out
- The rock trap rewards observation (feel the wire in darkness → cut it)
- The ceiling collapse punishes noise in fragile spaces (a "stealth" lesson)
- Self-inflicted unconsciousness as puzzle mechanic: design puzzles where the player MUST knock themselves out (time-skip, dream sequence, bypass a timed lock)

---

## 7. Cross-References

- `docs/design/injuries/unconsciousness.md` — Core unconsciousness system design
- `docs/design/injuries/self-hit.md` — `hit` verb design (self-infliction pattern)
- `docs/design/injuries/puzzle-integration.md` — How injuries function as puzzles
- `src/meta/injuries/concussion.lua` — The injury type all 4 triggers inflict
- `src/meta/injuries/crushing-wound.lua` — Stacking injury for ceiling collapse
- `src/engine/injuries.lua` — Injury engine (infliction, ticking, stacking)
- `.squad/decisions.md` — D-CONSC*, D-SELF-INFLICT-CEILING, D-HIT*
