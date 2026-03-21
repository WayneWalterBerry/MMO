# Injury Catalog — Gameplay Design

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Status:** DESIGN  
**Depends On:** Health System (health-system.md), FSM Engine  
**Audience:** Designers, Bart (engine), Flanders (objects), Nelson (testing)

---

## 1. Injury Architecture

### 1.1 What Is an Injury?

An injury is a **stateful condition attached to the player** — like a status effect with its own lifecycle. Each injury:
- Has an **FSM** (finite state machine) with defined states and transitions
- Produces **narrative symptoms** (text the player sees)
- May have **mechanical effects** (blocks actions, drains HP)
- Requires **specific treatment** (a particular object or action to progress the FSM)
- Can **worsen** if untreated (degenerative injuries)

### 1.2 Injury Categories

| Category | HP Effect | Duration | Worsens? | Example |
|----------|-----------|----------|----------|---------|
| **One-Time** | Flat damage on infliction | Heals over time or with treatment | No | Cut, bruise, burn |
| **Over-Time** | Drains HP each turn | Until treated or fatal | Some | Bleeding, mild poison |
| **Degenerative** | Escalating drain | Until treated; worsens in stages | Yes | Infection, deep poison |

### 1.3 Injury FSM Pattern

Every injury follows a standard FSM structure. Some injuries skip states (a bruise has no "treated" state — it just heals).

```
            [inflicted]
                │
                ▼
          ┌──────────┐
          │  ACTIVE   │◄──── injury starts here
          │           │      symptoms visible
          │  (ticking)│      mechanical effects active
          └─────┬─────┘
                │ treatment applied
                ▼
          ┌──────────┐
          │ TREATED   │      symptoms reduced
          │           │      HP drain stops (if over-time)
          │           │      healing countdown begins
          └─────┬─────┘
                │ countdown expires
                ▼
          ┌──────────┐
          │  HEALED   │      injury removed from player
          │           │      no further effects
          └──────────┘
```

**Degenerative injuries** add a worsening path:

```
          ┌──────────┐
          │  ACTIVE   │──── untreated for N turns ────┐
          └─────┬─────┘                                │
                │ treatment                            ▼
                ▼                               ┌──────────┐
          ┌──────────┐                          │ WORSENED  │
          │ TREATED   │                          │ (stage 2) │
          └─────┬─────┘                          └─────┬─────┘
                │                                      │ untreated
                ▼                                      ▼
          ┌──────────┐                          ┌──────────┐
          │  HEALED   │                          │ CRITICAL  │
          └──────────┘                          │ (stage 3) │
                                                └─────┬─────┘
                                                      │ untreated
                                                      ▼
                                                   DEATH
```

### 1.4 Injury Data Model

```lua
-- Example injury attached to player
{
  id = "cut-hand-001",
  type = "cut",
  location = "hand",          -- body part affected
  cause = "glass-shard",      -- what caused it
  state = "active",           -- FSM state
  tick_counter = 0,           -- turns since infliction
  hp_drain_per_tick = 0,      -- 0 for one-time, >0 for over-time
  treatment_required = "bandage",  -- what cures it
  mechanical_effects = {},    -- action blocks, stat modifiers
  messages = {
    active = "Your hand stings where the glass cut you.",
    treated = "The bandage on your hand is holding. The pain is fading.",
    reminder = "Your cut hand throbs as you reach out."
  }
}
```

---

## 2. Level 1 Injury Catalog

These injuries are relevant to Level 1 objects and puzzles. They should be implemented first.

---

### 2.1 MINOR CUT

| Field | Value |
|-------|-------|
| **ID** | `minor-cut` |
| **Category** | One-Time |
| **Causes** | Glass shard (handle), pin prick, minor trap |
| **Initial Damage** | 5 HP |
| **Over-Time Drain** | None |
| **Body Location** | Hand (usually) |
| **Mechanical Effect** | None |
| **Status** | 🔴 Planned (extends existing `bleed_ticks`) |

**FSM:**
```
active ──(5 turns)──► healed
active ──(bandage)──► treated ──(2 turns)──► healed
```

**Player Sees:**
| State | Symptom Text |
|-------|-------------|
| Active | *"A small cut on your [hand] stings sharply."* |
| Active (reminder) | *"The cut on your [hand] is still tender."* |
| Treated | *"The bandage on your [hand] is snug. The sting is fading."* |
| Healed | *"The cut on your hand has closed. Barely a mark remains."* |

**Puzzle Use:** Glass shard hurts to pick up barehanded. Wrapping it in cloth first prevents the injury — teaches "prepare your tools."

**Notes:** This formalizes the existing `bleed_ticks = 8` from the prick/cut self mechanic. The current implementation is the prototype for this injury.

---

### 2.2 DEEP CUT (Slash)

| Field | Value |
|-------|-------|
| **ID** | `deep-cut` |
| **Category** | Over-Time (bleeding) |
| **Causes** | Knife attack, blade trap, falling onto sharp object |
| **Initial Damage** | 15 HP |
| **Over-Time Drain** | 3 HP/turn (bleeding) |
| **Body Location** | Arm, torso, leg |
| **Mechanical Effect** | Affected limb actions impaired at Tier 2+ |
| **Status** | 🔴 Planned |

**FSM:**
```
active ──(bleeding each turn)──► [death if HP=0]
active ──(bandage)──► bandaged ──(no drain)──► [still injured]
bandaged ──(medicine/rest 10 turns)──► healed
active ──(untreated 15 turns)──► infected (see: INFECTION)
```

**Player Sees:**
| State | Symptom Text |
|-------|-------------|
| Active | *"Blood flows freely from the deep gash in your [arm]. It won't stop on its own."* |
| Active (turn) | *"Blood drips steadily from your wound, pooling at your feet. (-3 HP)"* |
| Bandaged | *"The bandage around your [arm] is holding, but the wound beneath is serious. You need proper rest."* |
| Bandaged (reminder) | *"Your bandaged [arm] aches deeply. Movement is difficult."* |
| Healed | *"The wound on your [arm] has closed, leaving an angry red scar."* |

**Puzzle Use:**
- **Time pressure:** Player takes a knife wound → must find bandage before bleeding out (~33 turns from 100 HP)
- **Action gate:** Deep cut on arm → cannot climb, lift heavy objects until bandaged
- **Resource tension:** Using the blanket for a bandage means it can't be used for a rope later

---

### 2.3 BRUISE

| Field | Value |
|-------|-------|
| **ID** | `bruise` |
| **Category** | One-Time |
| **Causes** | Fall, blunt impact, heavy object dropped on player |
| **Initial Damage** | 10–20 HP (scaled by fall height / impact force) |
| **Over-Time Drain** | None |
| **Body Location** | Legs (falls), torso (impacts), head (blows) |
| **Mechanical Effect** | Legs bruised → climbing/running impaired. Head bruised → examine descriptions degraded. |
| **Status** | 🔴 Planned |

**FSM:**
```
active ──(8 turns)──► healed
active ──(rest/sleep)──► recovering ──(4 turns)──► healed
```

**Player Sees:**
| State | Symptom Text |
|-------|-------------|
| Active | *"Your bruised [legs] ache with every step. The fall left its mark."* |
| Active (action blocked) | *"You try to climb, but your bruised legs buckle. Not yet."* |
| Recovering | *"The bruising is fading. Your [legs] still protest sharp movements, but you can manage."* |
| Healed | *"The soreness in your [legs] has finally passed."* |

**Puzzle Use:** 
- Puzzle 013 (Courtyard Entry): Window jump causes bruised legs → can't climb ivy until recovered → must find ground-level route or wait
- Falling in the cellar (missed step) → bruised legs → next physical challenge is harder

---

### 2.4 BLEEDING

| Field | Value |
|-------|-------|
| **ID** | `bleeding` |
| **Category** | Over-Time |
| **Causes** | Accompanies deep cuts, glass shard wounds, weapon injuries |
| **Initial Damage** | 0 (damage comes from the causing injury) |
| **Over-Time Drain** | 2–5 HP/turn depending on wound severity |
| **Body Location** | Same as causing wound |
| **Mechanical Effect** | Leaves blood trail (future: trackable by NPCs). Hands slippery (drop chance on handled objects). |
| **Status** | 🟡 Prototype exists (`bleed_ticks` in engine) |

**FSM:**
```
active ──(HP drain each turn)──► [death if HP=0]
active ──(bandage/cloth/pressure)──► stopped
stopped ──(wound heals)──► [removed]
```

**Player Sees:**
| State | Symptom Text |
|-------|-------------|
| Active (minor, 2/turn) | *"Blood seeps from your wound, a slow but steady trickle."* |
| Active (major, 5/turn) | *"Blood pours from the gash. Your sleeve is soaked crimson. This is bad."* |
| Active (hands) | *"Blood makes your grip slippery. Objects feel uncertain in your hands."* |
| Stopped | *"The bleeding has stopped. The bandage holds."* |

**Puzzle Use:**
- **The classic time puzzle:** Player is bleeding. A bandage exists 2 rooms away. They have ~20 turns. Every command matters.
- **Resource discovery:** The blanket on the bed can be torn for cloth → cloth becomes bandage → bleeding stops. The player must figure this out under pressure.
- **Slippery hands:** Bleeding hands make it harder to manipulate objects. Drops become possible. Creates urgency to treat.

**Implementation Note:** The existing `bleed_ticks` system is the prototype. It already decrements per tick and clears `player.state.bloody`. The injury system formalizes this into a proper FSM with HP drain.

---

### 2.5 POISONING (Mild)

| Field | Value |
|-------|-------|
| **ID** | `poisoning-mild` |
| **Category** | Over-Time |
| **Causes** | Tainted food, weak venom (spider bite, dart trap), spoiled drink |
| **Initial Damage** | 5 HP (nausea hit) |
| **Over-Time Drain** | 5 HP/turn |
| **Body Location** | Systemic (whole body) |
| **Mechanical Effect** | Nausea → intermittent action interruption. Smell/taste senses degraded. |
| **Status** | 🔴 Planned |

**FSM:**
```
active ──(HP drain each turn)──► [death if HP=0]
active ──(antidote)──► neutralized ──(3 turns)──► healed
active ──(vomit/purge)──► weakened ──(5 turns)──► healed
                          (but costs 10 HP)
```

**Player Sees:**
| State | Symptom Text |
|-------|-------------|
| Active | *"Your stomach churns violently. Something you consumed is poisoning you."* |
| Active (turn) | *"A wave of nausea hits. The poison burns through your veins. (-5 HP)"* |
| Active (sensory) | *"Everything tastes like copper. Your sense of smell is shot."* |
| Neutralized | *"The antidote works quickly. The burning fades. You feel weak but alive."* |
| Weakened | *"You retch violently. The poison leaves your system the hard way. You feel hollowed out."* |
| Healed | *"The last of the poison has left your body. You won't forget that taste."* |

**Puzzle Use:**
- **Antidote fetch puzzle:** Player is poisoned by dart trap → must find antidote herb/potion within 20 turns
- **Purge alternative:** No antidote? Induce vomiting (drink salt water, stick finger down throat) — saves life but costs more HP
- **Poison identification:** SMELL or TASTE (carefully!) can identify poison type → hints at correct antidote
- **Contrast with instant poison:** The poison bottle (Puzzle 002) is instant death. Mild poison is survivable-with-treatment. The player learns: "not all poisons are equal — but all are dangerous."

**Design Note:** This is NOT the same as the existing poison bottle death. That remains instant and fatal. Mild poisoning is a new mechanic for traps, food, and NPC encounters where death would be unfair.

---

### 2.6 BURN

| Field | Value |
|-------|-------|
| **ID** | `burn` |
| **Category** | One-Time |
| **Causes** | Touching lit candle, hot surface, fire trap |
| **Initial Damage** | 5–15 HP (scaled by heat source) |
| **Over-Time Drain** | None (unless severe → blistering) |
| **Body Location** | Hand (touching hot object), face/body (fire trap) |
| **Mechanical Effect** | Burned hand → reduced grip. Burned face → vision impaired. |
| **Status** | 🔴 Planned |

**FSM:**
```
active ──(cold water/salve)──► treated ──(5 turns)──► healed
active ──(10 turns)──► healed (slow natural healing)
active (severe) ──(untreated 8 turns)──► blistered ──(medicine)──► treated ──► healed
```

**Player Sees:**
| State | Symptom Text |
|-------|-------------|
| Active (minor) | *"Your fingertips are red and tender where you touched the flame."* |
| Active (severe) | *"The burn on your [hand] is angry and raw. Even the air hurts."* |
| Treated | *"The cool salve soothes the burn. The throbbing eases."* |
| Blistered | *"The burn has blistered. Fluid-filled welts cover your [hand]. Don't touch anything."* |
| Healed | *"The burn has faded to a patch of shiny pink skin."* |

**Puzzle Use:** 
- Lit candle is essential for light but dangerous to touch directly (teaches: use the candle-holder, not the candle)
- Fire trap in future level: player must reach through flame to get an object. Protective glove/wet cloth reduces burn damage.

---

## 3. Future Injury Types (Level 2+)

These injuries are designed but not needed for Level 1. Documented here for forward planning.

---

### 3.1 INFECTION

| Field | Value |
|-------|-------|
| **ID** | `infection` |
| **Category** | Degenerative |
| **Causes** | Untreated cut/slash wound after 15+ turns |
| **Over-Time Drain** | Stage 1: 1/turn. Stage 2: 2/turn. Stage 3: 3/turn. |
| **Treatment** | Stage 1: Clean wound (water + cloth). Stage 2: Medicine/herb poultice. Stage 3: Requires skilled NPC healer. |
| **Mechanical Effect** | Fever → intermittent confusion (random action failure). Stage 3 → bedridden. |
| **Status** | 🔴 Planned (Level 2) |

**FSM:**
```
stage_1 ──(clean wound)──► treated ──(8 turns)──► healed
stage_1 ──(untreated 10 turns)──► stage_2
stage_2 ──(medicine)──► treated ──(12 turns)──► healed
stage_2 ──(untreated 10 turns)──► stage_3
stage_3 ──(NPC healer)──► treated ──(20 turns)──► healed
stage_3 ──(untreated 15 turns)──► DEATH
```

**Player Sees:**
| Stage | Symptom Text |
|-------|-------------|
| Stage 1 | *"The wound is warm to the touch and slightly swollen. That's not a good sign."* |
| Stage 2 | *"Fever grips you. The wound has gone bad — red streaks crawl up your arm. You need medicine."* |
| Stage 3 | *"You can barely stand. The infection has spread. Your skin burns, your thoughts scatter. Without a healer, this will kill you."* |

**Puzzle Use:** Infection creates a *multi-stage time puzzle*. The player has ~35 turns from infection to death, but each stage requires a *different* treatment. Finding clean water (stage 1) is easy. Finding medicine (stage 2) is a fetch puzzle. Finding a healer (stage 3) is a relationship/navigation challenge.

---

### 3.2 BROKEN BONE

| Field | Value |
|-------|-------|
| **ID** | `broken-bone` |
| **Category** | One-Time (with long recovery) |
| **Causes** | Severe fall, heavy object, combat |
| **Initial Damage** | 25 HP |
| **Over-Time Drain** | None (pain, not bleeding) |
| **Treatment** | Splint (wood + cloth) → slow heal. NPC healer → faster heal. |
| **Mechanical Effect** | Broken arm → cannot carry objects in that hand, cannot climb. Broken leg → movement slowed (extra turn per room transition). |
| **Status** | 🔴 Planned (Level 2+) |

**Puzzle Use:** A broken arm gates physical puzzles. The player must find a workaround (one-handed solutions) or get healed first. Creates a "damaged state" puzzle where the challenge is solving problems with reduced capabilities.

---

### 3.3 HYPOTHERMIA

| Field | Value |
|-------|-------|
| **ID** | `hypothermia` |
| **Category** | Over-Time (environmental) |
| **Causes** | Extended exposure to cold without cloak/fire |
| **Over-Time Drain** | 2 HP/turn |
| **Treatment** | Warmth source (fire, cloak, shelter) |
| **Mechanical Effect** | Shivering → reduced dexterity (fumble chance). Stage 2 → confusion. |
| **Status** | 🔴 Planned (Level 2+ outdoor areas) |

**Puzzle Use:** Outdoor winter sections require the wool-cloak (Level 1 optional item). Players who collected it are rewarded; those who didn't must find alternate warmth. The cloak — a seemingly useless flavor item in Level 1 — retroactively proves its value.

---

### 3.4 EXHAUSTION

| Field | Value |
|-------|-------|
| **ID** | `exhaustion` |
| **Category** | Degenerative (slow build) |
| **Causes** | Extended activity without rest, multiple injuries |
| **Over-Time Drain** | 1 HP/5 turns |
| **Treatment** | Sleep (full rest), food + drink |
| **Mechanical Effect** | Stage 1: occasional yawning messages. Stage 2: physical actions slower. Stage 3: collapse (forced rest). |
| **Status** | 🔴 Planned (Level 3+) |

**Puzzle Use:** Creates long-term resource pressure. The player needs to balance exploration with rest. Safe rest locations become valuable. Food becomes a strategic resource, not just flavor.

---

## 4. Injury Interaction Rules

### 4.1 Stacking

Multiple injuries can be active simultaneously. Each has independent FSM, timers, and effects.

**Example compound state:**
```
Player HP: 52/100 (Wounded)
Active injuries:
  - Deep cut (arm): BANDAGED, no HP drain, 6 turns to healed
  - Bruised ribs: ACTIVE, 3 turns to natural heal
  - Mild poison: ACTIVE, -5 HP/turn, needs antidote
```

**Combined narrative:** *"Your bandaged arm aches. Your ribs protest every breath. And underneath it all, the poison churns in your gut, burning, burning."*

### 4.2 Injury Cascading

Some injuries can trigger other injuries:

| If This... | And This... | Then... |
|------------|-------------|---------|
| Deep cut is untreated | 15+ turns pass | → INFECTION begins |
| Burn is untreated (severe) | 8+ turns pass | → BLISTERED (worse burn state) |
| Player at Tier 2 (Critical) | Falls | → Damage increased 50% (weakened body) |
| Multiple bleeding wounds | Simultaneous | → Drain stacks (2 wounds × 3/turn = 6/turn) |

### 4.3 Body Location Conflicts

Injuries on the same body part compound their effects:
- **Two hand injuries:** Both affect grip. Total effect is worse than either alone.
- **Leg injury + bruised ribs:** Movement and climbing both impaired.
- **Head injury + poisoning:** Confusion effects stack — increased fumble chance.

### 4.4 Treatment Priority

When the player has multiple injuries, the *most dangerous* should be treated first. The game doesn't enforce this — the player chooses — but narrative hints guide them:

> *"Your arm is bleeding and your ribs ache, but it's the poison in your blood that will kill you first."*

---

## 5. Injury × Puzzle Design Patterns

### Pattern 1: The Ticking Clock
**Setup:** Player receives an over-time injury (bleeding, poison).  
**Puzzle:** Find the treatment before HP runs out.  
**Tension:** Every command spent exploring costs HP.  
**Example:** Dart trap poisons player → antidote is 3 rooms away → 20 turns of poison left.

### Pattern 2: The Capability Gate
**Setup:** Injury blocks a specific action.  
**Puzzle:** Find alternate solution or heal first.  
**Tension:** The obvious path is blocked; lateral thinking required.  
**Example:** Broken arm → can't climb wall → must find stairs or get healed.

### Pattern 3: The Risky Shortcut
**Setup:** An action causes injury but provides a benefit.  
**Puzzle:** Is the shortcut worth the health cost?  
**Tension:** Risk/reward calculation.  
**Example:** Jump from window (bruised legs, saves time) vs. find the key (safe but slower).

### Pattern 4: The Prepared Adventurer
**Setup:** A hazard ahead is telegraphed.  
**Puzzle:** Find protective equipment before encountering the hazard.  
**Tension:** Forewarning vs. preparation.  
**Example:** "A cold draft from the stairway" → find cloak before descending.

### Pattern 5: The Medical Puzzle
**Setup:** An injured NPC or player needs treatment.  
**Puzzle:** Identify the injury → find the correct treatment → apply it.  
**Tension:** Correct diagnosis required; wrong treatment wastes resources.  
**Example:** NPC is sick → symptoms suggest poison → antidote herb + water = cure.

---

## 6. Implementation Priority

| Priority | Injury | Why First |
|----------|--------|-----------|
| **P1** | Minor Cut, Bleeding | Extends existing `bleed_ticks`. Minimal new engine work. |
| **P1** | Bruise | Window jump (Puzzle 013) needs this. |
| **P2** | Deep Cut | Weapon traps need a survivable wound type. |
| **P2** | Mild Poison | Dart traps, tainted food — Level 1 content. |
| **P3** | Burn | Candle interaction. Existing objects cause this. |
| **P4** | Infection | Requires multi-stage FSM. Level 2 content. |
| **P4** | Broken Bone | Requires body-part action gating. Level 2 content. |
| **P5** | Hypothermia, Exhaustion | Environmental systems. Level 3+ content. |

---

## See Also

- [health-system.md](./health-system.md) — Health scale and damage model
- [healing-items.md](./healing-items.md) — Treatment objects and mechanics
- [README.md](./README.md) — System overview
- `docs/design/fsm-object-lifecycle.md` — FSM patterns (injuries follow same architecture)
- `docs/design/player-skills.md` §8 — Blood writing (existing prick → bleed chain)
