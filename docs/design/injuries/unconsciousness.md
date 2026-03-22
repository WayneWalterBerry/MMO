# Unconsciousness Injury System — Gameplay Design

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-23  
**Status:** DESIGN  
**Depends On:** FSM Engine, Verb Handlers, Game Loop tick system, Injury system, Sleep mechanics  
**Audience:** Designers, Bart (engine), Smithers (implementation), Nelson (testing)

---

## 1. Core Concept

Unconsciousness is a **forced sleep state** that results from injury — a blow to the head, poison, gas, or magic. Unlike voluntary sleep (which the player can exit from), unconsciousness imprisons the player for a duration determined by the severity of the injury that caused it.

**Key distinction:** Unconsciousness is not a minor stun. It is a genuine incapacity where:
- The player cannot take any action
- Injuries continue to tick (bleeding does not pause)
- The player can die while unconscious
- Wake-up is automatic after the timer expires

This creates a unique puzzle: the player must avoid certain triggers before managing their health, or risk bleeding out during forced sleep.

---

## 2. Design Principles

### 2.1 Unconsciousness = Forced Sleep, Not Damage

Unconsciousness does not deal direct damage on its own. It is a **state change** — the player goes from "conscious and acting" to "unconscious and helpless." The danger comes from other injuries ticking while the player is incapacitated.

**Example:** A blow to the head causes unconsciousness (5-10 turn duration). If the player also has a bleeding wound, that wound continues to drain health per turn while the player sleeps. The player can bleed out and die during the forced sleep.

### 2.2 Unconsciousness Is Binary

There is no "dazed" state, no "stunned" state, no intermediate conditions. The transition is clean:
- Conscious → takes injury that causes unconsciousness → Unconscious
- Unconscious → timer expires → Conscious

When the player goes unconscious, they are *gone*. The world continues, injuries tick, and time passes.

### 2.3 Severity-Based Duration

The severity of the blow determines how long the player is unconscious. Each injury source has a base severity that maps to turn count:

| Severity | Unconscious Duration | Example Source |
|----------|---------------------|-----------------|
| Minor | 3-4 turns | Weak punch to the head |
| Moderate | 5-8 turns | Hard punch, baseball bat |
| Serious | 10-15 turns | Sledgehammer blow, falling rock |
| Critical | 20+ turns | Concussion-level trauma |

**Design rationale:** This lets puzzles tune threat level. A major trap that knocks you out for 20 turns is more dangerous than a weak hit that stuns you for 3 turns — and the player learns this through consequences.

### 2.4 Armor Provides Protection

Helmets and head armor reduce the severity of head-targeting blows. This is the primary mechanism for armor interaction with unconsciousness:

- **Bare head:** Full severity (3-20 turns depending on blow strength)
- **Leather helmet:** Reduces severity by 30% (easier to wake up)
- **Iron helmet:** Reduces severity by 50% or negates minor blows entirely
- **Full plate with gorget:** Can negate even serious blows

**Mechanics:** The armor has a `reduces_unconsciousness` property (e.g., `reduces_unconsciousness = 0.5` for 50% reduction). When an unconsciousness injury is applied, the engine checks for worn head armor and applies the reduction modifier.

### 2.5 Injuries Tick During Unconsciousness

This is critical: **the game loop does not pause**. Every turn the player is unconscious:
1. Injuries tick normally (bleeding drains health, poison damages, etc.)
2. The unconsciousness timer decrements
3. The engine checks if health ≤ 0
4. If dead, the player dies while unconscious (special death narrative)

**Example scenario:**
- Turn 1: Player is hit on head (unconscious for 8 turns) and simultaneously stabbed (bleeding, drains 2 HP/turn)
- Turn 2-9: Bleeding ticks while player is unconscious. If health reaches 0 before the timer expires, player dies.
- Turn 10+: If player survived, they wake up automatically

### 2.6 Death During Unconsciousness

If the player's health reaches 0 while unconscious, they die **permanently**. There is no option to wake up and fight back. The narrative reflects this:

> *"You never wake up. The bleeding was too much."*
>
> *"Hours pass. The poison in your veins finishes what the blow started."*

**Design rationale:** This creates genuine stakes. An unconscious player is vulnerable. Going into a dangerous situation already injured means risking death during forced sleep. Players learn to treat injuries *before* they risk unconsciousness.

---

## 3. FSM States

Unconsciousness is a player state (not an injury type itself, but a state triggered by injuries):

```
         conscious
             |
             | (injury causes unconsciousness)
             v
        unconscious
             |
        (timer ticks)
             |
             v
          waking
             |
        (narration)
             |
             v
         conscious
```

### 3.1 State Definitions

| State | Description | Player Input | Injury Ticking | Wake Condition |
|-------|-------------|--------------|-----------------|----------------|
| **conscious** | Normal state. Player can act normally. | Full input accepted. | N/A (state change, not an injury) | Apply unconsciousness-causing injury. |
| **unconscious** | Incapacitated. Player cannot act. | Input rejected ("You can't—you're unconscious"). | Yes — all injuries tick normally. | Timer reaches 0 OR player dies. |
| **waking** | Brief transitional state. Narration plays. Player will be conscious in next turn. | Input rejected. | Injuries continue ticking (transition is instant). | Auto-transition to conscious. |

### 3.2 State Transitions

| From | To | Trigger | Guard | Message |
|-----|----|---------|---------|----|
| **conscious** | **unconscious** | Injury applied with `causes_unconsciousness` flag | Injury severity > 0 after armor reduction | *(Varies by injury source)* |
| **unconscious** | **waking** | Unconsciousness timer reaches 0 | Player still alive (health > 0) | *(Wake-up narration template)* |
| **unconscious** | **dead** | Health reaches 0 | Player was unconscious when it happened | *(Death-during-unconsciousness narration)* |
| **waking** | **conscious** | Auto-transition | None | *(Automatic next turn)* |

---

## 4. Wake-Up Mechanics

### 4.1 Wake-Up Narration Templates

When the unconsciousness timer expires, the player wakes up with narration that varies by injury source. These templates create a sense of different causes:

**Blow to head:**
> *"Your eyes flutter open. Your head throbs with a dull, persistent ache. Stars still dance at the edges of your vision. [Time advancement message]."*

**Poison (recovered):**
> *"You gasp and cough. Your throat is raw. Your body aches from the convulsions, but your mind clears. The poison has run its course. [Time advancement message]."*

**Gas exposure:**
> *"You wake with a start, gasping for air. Your lungs burn. The acrid smell is fading. You must have crawled away from the source. [Time advancement message]."*

**Magic (varies by spell type):**
> *"The world snaps back into focus. Your head is clear, though your body feels heavy, as if you've been dragged across stone. [Time advancement message]."*

### 4.2 Time Advancement

When the player wakes up, the engine must handle **time advancement**. If the player was unconscious for 8 turns, the day/night cycle advances by 8 turns. This affects:
- Time-based room effects (wind gusts, water dripping, etc.)
- Decay of objects (matches burning down, food spoiling)
- Passage of in-game time visible to the player

**Narrative integration:** The wake-up message includes a time phrase:
> *"You come to. Several minutes have passed. The world is darker now — dusk is falling."*
>
> *"You wake in the dead of night. A few hours have passed while you were out."*

---

## 5. Interaction with Voluntary Sleep

**Sleep does not protect from injuries.** If the player goes to sleep with active bleeding wounds, they can bleed out and die during sleep, just like unconsciousness.

**Design principle:** Sleep and unconsciousness create the same puzzle — they are both dangerous states where injuries continue to tick. A player who goes to sleep with health near critical is making a gamble.

**Key difference:** With sleep, the player *chose* to enter that state. With unconsciousness, they were *forced* into it. But mechanically, they produce the same risk.

**Example scenario:**
- Player has a bleeding wound (draining 3 HP/turn) and 15 total HP
- Player decides to sleep (hoping to heal naturally)
- Every turn asleep, they lose 3 HP
- After 5 turns of sleep: health is 0, player dies in their sleep
- Wake-up narrative: *"You never wake up. The infection took you while you slept."*

---

## 6. What Triggers Unconsciousness?

Injuries that can cause unconsciousness:

### 6.1 Head Impact (blow-to-head injury)
- Severity-based duration (3-20 turns)
- Caused by: blunt force to the head (punch, club, falling object, trap)
- **Testing verb:** `hit head` with bare fist (self-infliction)
- **Armor protection:** Helmets reduce or negate

### 6.2 Poison (certain types)
- Not all poisons cause unconsciousness (some just damage health)
- Nightshade poison in high doses could cause unconsciousness (hallucinations → collapse)
- Other poisons: viper venom (low dose = pain, high dose = unconsciousness)
- **Duration:** 5-10 turns (poison-dependent)
- **Testing verb:** `drink poison` (self-infliction, dangerous)

### 6.3 Gas Exposure (future)
- Toxic gas in certain rooms (cellar, ancient tomb)
- Duration depends on gas type and player endurance
- **Not in Level 1** but design for it

### 6.4 Magic (future)
- Sleep spells, stunning spells
- **Not in Level 1** but design for it

---

## 7. Self-Infliction: The `hit` Verb

The primary way to **test** unconsciousness in single-player is self-infliction via the `hit` verb:

```
> hit head
"You slam your fist hard against the side of your head. Stars explode across your vision. The world tilts..."
[Player enters unconscious state, 5-turn timer]

> look
"You can't look around — everything is black. Consciousness slips away..."

[After 5 turns]
"Your eyes flutter open. Your head throbs. [time has passed]."
```

**Mechanics:**
- `hit head` → applies unconsciousness injury (base severity 5 turns)
- `hit arm` or `hit leg` → applies bruise injury (pain category, not unconsciousness)
- `hit` with no target → "Hit what?"
- Works in darkness (touch-based)
- Armor protection applies (helmet reduces duration)

This parallels the existing `stab self` pattern for testing bleeding injuries.

---

## 8. Related Verbs & Systems

### 8.1 The `injuries` Verb
The player can check their condition with the `injuries` verb. If unconscious, this returns a special message:

> *"You can't examine yourself — you're unconscious."*

### 8.2 The `sleep` Verb
Sleep now has the same injury-ticking risk as unconsciousness:

```
> sleep
"You close your eyes and drift off..."
[Injuries tick normally. If health reaches 0, player dies in sleep.]
[After target duration, player wakes naturally OR dies.]
```

### 8.3 Wake-Up Conditions
- **Normal:** Timer expires, player wakes automatically
- **Woken by NPC:** In multiplayer or future combat, an ally could wake the player early (not in V1)
- **Interrupted by critical damage:** If an attack deals massive damage during unconsciousness, does that apply as additional injury? (Design decision: treat as stacking injury, not interrupt)

---

## 9. Edge Cases & Design Decisions

### 9.1 Multiple Unconsciousness Injuries
**Question:** Can the player be hit multiple times while unconscious and gain multiple unconsciousness injuries?

**Answer:** No. Unconsciousness is a player state, not an injury type. If the player is already unconscious and gets hit again, the new blow **restarts the timer** at its own severity, or takes the longest duration if the new blow is weaker. This prevents the timer from being extended arbitrarily through damage.

**Rationale:** Once you're out, you're out. You don't "go more unconscious." But a bigger hit can keep you down longer.

### 9.2 Consciousness During Narration
**Question:** During the wake-up narration, is the player conscious?

**Answer:** The player is in the **waking** state during narration (not yet in conscious state). Once the narration completes, they transition to conscious and can act normally next turn.

### 9.3 Inventory During Unconsciousness
**Question:** Can items be taken from the unconscious player?

**Answer:** Design question for Bart/Smithers. In V1, ignore this. Future multiplayer would allow theft from unconscious players — another reason to avoid it.

### 9.4 Damage Dealt While Unconscious
**Question:** If an NPC attacks an unconscious player, does the damage apply immediately or as an additional injury?

**Answer:** Treat as a new stacking injury. Damages stack — each wound drains independently.

---

## 10. Testing Criteria (Nelson)

All of these must pass before unconsciousness is considered complete:

- [x] Player hits head → goes unconscious for appropriate duration
- [x] Player wakes up naturally after timer expires
- [x] Player can bleed to death during unconsciousness
- [x] Sleep with injuries can also result in death
- [x] Helmet reduces unconsciousness duration appropriately
- [x] Multiple injuries (bleeding + unconscious) drain concurrently
- [x] Wake-up narration varies by injury source
- [x] Time advancement is reflected in room state
- [x] Player cannot act while unconscious
- [x] `injuries` verb returns appropriate message when unconscious
- [x] Self-hit with `hit head` produces unconsciousness
- [x] Self-hit with helmet equipped produces reduced-duration unconsciousness
- [x] Restarting timer on additional head hits (doesn't stack to infinite)

---

## 11. Narrative Polish

The key to making unconsciousness feel real is the **narration**. Every transition should create presence:

**Going under:**
> *"You see the blow coming but can't dodge. Your vision explodes into white light, then nothing..."*

**The darkness:**
> *"You are aware of nothing. Time has no meaning here."*
> *(Occasionally, injury pain breaks through: "A distant, muffled throbbing...")*

**Waking:**
> *"Consciousness returns slowly. Your eyelids are impossibly heavy. You fight to open them. The world comes into focus, sharp with pain."*

**Disorientation:**
> *"Your head spins when you try to move. Where are you? How long were you out?"*

---

## 12. Implementation Notes for Bart & Smithers

1. **Player state:** Add `player.consciousness` (conscious/unconscious/waking) and `player.unconsciousness_timer` (turns remaining)
2. **Game loop:** Each tick, if unconscious:
   - Decrement timer
   - Process all injury ticks
   - Check death (health ≤ 0)
   - If timer expires and health > 0, transition to waking
   - Next turn, transition to conscious
3. **Input handling:** If unconscious, reject all commands with "You can't—you're unconscious."
4. **Narration dispatch:** Wake-up message varies by injury type (`injury.unconscious_cause` field)
5. **Armor interaction:** When applying unconsciousness injury, check for worn head armor and apply reduction modifier
6. **`hit` verb:** Route to injury system with `causes_unconsciousness = true` and `target_area = "head"`

---

## 13. See Also

- `docs/design/injuries/self-hit.md` — Design for the `hit` verb (self-infliction)
- `docs/verbs/hit.md` — Verb reference for the `hit` command
- `docs/design/player/health-system.md` — Overall health and injury model
- `docs/design/injuries/puzzle-integration.md` — How unconsciousness fits into Level 1 puzzles
- `docs/verbs/sleep.md` — Sleep verb (now carries injury risk)
