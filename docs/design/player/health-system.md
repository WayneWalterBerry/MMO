# Player Health System — Gameplay Design

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Status:** DESIGN  
**Depends On:** FSM Engine, Verb Handlers, Game Loop tick system  
**Audience:** Designers, Bart (engine), Flanders (objects)

---

## 1. The Health Scale

### 1.1 Numeric Model

| Property | Value | Notes |
|----------|-------|-------|
| **max_hp** | 100 | Matches `game-design-foundations.md` §4 player model |
| **starting_hp** | 100 | Player begins at full health |
| **death_threshold** | 0 | HP ≤ 0 = death |
| **minimum_damage** | 1 | No damage source deals less than 1 HP |

**Why 100?** It's human-readable, divisible, and matches the existing player model in `game-design-foundations.md`. A 100-point scale lets us have fine-grained damage (pin prick = 5 HP, knife slash = 15 HP, poison = instant death) without needing decimals.

### 1.2 Health Tiers

Health tiers are **narrative zones** — they determine what text the player sees and what mechanics activate. The player never sees a number unless they explicitly check status.

| Tier | HP Range | Name | Narrative Effect | Mechanical Effect |
|------|----------|------|-----------------|-------------------|
| **5** | 100 | Full Health | No messages. Body is invisible. | None. |
| **4** | 75–99 | Scratched | Occasional pain reminders. | None mechanical. Narrative only. |
| **3** | 40–74 | Wounded | Persistent pain messages. Actions feel labored. | Some physical checks become harder (future). |
| **2** | 15–39 | Critical | Desperate prose. Vision blurs. Movement described as staggering. | Cannot perform strenuous actions (climb, lift heavy objects). |
| **1** | 1–14 | Near-Death | Every action is agony. Descriptions are fragmentary. | Cannot run, fight, or perform any physical exertion. |
| **0** | 0 | Dead | Game over sequence. | `ctx.game_over = true` |

### 1.3 Tier Boundaries — Design Rationale

- **75 → Scratched:** Most one-time injuries (5–25 HP) drop the player into this zone. It's a warning: "You've been hurt." No gameplay impact — just narrative stakes.
- **40 → Wounded:** Multiple untreated injuries, or a single serious one (knife wound + bleeding), push the player here. This is the "you should seek treatment" zone.
- **15 → Critical:** Entering this zone is the "alarm bell." The player is in real danger. Over-time injuries (bleeding, poison) will kill them here within a few turns.
- **1 → Near-Death:** The player is one bad decision from death. Every turn feels desperate. This zone should be rare and terrifying.

---

## 2. Narrative Voice by Health Tier

The health system's primary output is **text**. Below are example messages that fire contextually — on room entry, on action, on idle tick. These are *guidelines for writers*; actual text lives in engine metadata.

### Tier 5: Full Health (100 HP)
No health messages. The body is invisible. The player focuses entirely on the world.

### Tier 4: Scratched (75–99 HP)
Intermittent reminders, not every turn. The injury nags but doesn't dominate.

> *"Your [injury] throbs dully."*  
> *"You wince as you reach for the door handle."*  
> *"A twinge of pain reminds you of the cut on your hand."*

**Frequency:** Every 3–5 commands. Tied to the specific injury, not generic.

### Tier 3: Wounded (40–74 HP)
Pain is persistent. Every physical action includes a pain note. Room descriptions gain a pain filter.

> *"Your wounded arm protests as you lift the crate."*  
> *"Blood seeps through the makeshift bandage. You need proper treatment."*  
> *"Each step sends a jolt through your injured leg."*  
> *"You lean against the wall, breathing hard. The world tilts momentarily."*

**Frequency:** Every 1–2 commands. Physical actions always mention pain.

### Tier 3 → Room Description Modifier
When wounded, room descriptions gain a somatic overlay:

> **Normal:** *"A cold cellar stretches before you. Barrels line the walls."*  
> **Wounded:** *"A cold cellar stretches before you. Barrels line the walls. You steady yourself against the door frame, your wounded side aching in the chill."*

### Tier 2: Critical (15–39 HP)
The player's body dominates every interaction. Sensory descriptions are filtered through pain and disorientation.

> *"Your vision blurs. You stumble. You need help soon."*  
> *"The room swims before your eyes. Each breath is a conscious effort."*  
> *"Your hands shake. Picking up the key takes three attempts."*  
> *"A wave of nausea forces you to pause. The darkness at the edge of your sight is not just the unlit room."*

**Frequency:** Every command. Physical actions may fail or require extra description.

### Tier 2 → Sensory Degradation
At critical health, sensory verbs return degraded output:

> **LOOK (normal):** *"An ornate brass key lies on the stone shelf."*  
> **LOOK (critical):** *"Something metallic glints on the shelf. Your vision is too blurred to make out details."*  
>
> **FEEL (normal):** *"The stone wall is cool and smooth."*  
> **FEEL (critical):** *"The wall is cold. Your fingers feel numb and clumsy."*

### Tier 1: Near-Death (1–14 HP)
Fragmentary, desperate prose. The player is dying. Every message reinforces urgency.

> *"The edges of your vision darken. Each step is agony."*  
> *"You collapse against the wall. Getting up takes everything you have."*  
> *"Your heartbeat pounds in your ears, drowning out everything else."*  
> *"The cold stone floor presses against your cheek. When did you fall?"*  
> *"...you can barely... the room is... so cold..."*

**Frequency:** Every command. Descriptions are shorter, more fragmented. Ellipses and incomplete sentences.

### Tier 0: Death
A dramatic, final passage. Then game over.

> *"Your legs give way. The cold stone rushes up to meet you."*  
> *"The last thing you hear is the drip of water somewhere in the darkness."*  
> *"Silence. Stillness. The adventure ends here."*

---

## 3. Damage Model

### 3.1 Damage Sources

Damage comes from **objects and environmental effects**, never from abstract mechanics. Every point of HP lost has a *cause* the player can understand and (usually) avoid.

| Category | Source | Damage | Example |
|----------|--------|--------|---------|
| **Self-Injury** | Prick self (pin/needle) | 5 HP | Blood writing mechanic (existing) |
| **Self-Injury** | Cut self (knife/glass shard) | 10 HP | Blood writing mechanic (existing) |
| **Weapon** | Knife slash (combat or trap) | 15–25 HP | NPC attack, trapped chest |
| **Environmental** | Fall (short) | 10–20 HP | Jumping from window (Puzzle 013) |
| **Environmental** | Fall (long) | Instant death | Falling into pit without rope |
| **Poison** | Poison ingestion | Instant death | Poison bottle (existing, Puzzle 002) |
| **Poison** | Mild poison / tainted food | 5 HP/turn | Spoiled food, weak venom |
| **Trap** | Dart trap | 10 HP + poison | Trapped chest or passage |
| **Over-Time** | Bleeding (untreated cut) | 3 HP/turn | Unbound knife wound |
| **Over-Time** | Infection (untreated wound) | 2 HP/turn (escalating) | Cut that wasn't cleaned |
| **Over-Time** | Mild poison | 5 HP/turn | Ingested toxin with antidote available |
| **Environmental** | Extreme cold | 2 HP/turn | Outdoors in winter without cloak |
| **Environmental** | Extreme heat | 3 HP/turn | Fire-adjacent room |

### 3.2 Damage Application

Damage is applied through the existing verb handler system. Objects declare their damage in metadata:

```lua
-- Example: Knife used as weapon (trap or NPC)
damage_on_hit = {
  amount = 20,
  injury_type = "slash",
  message = "The blade bites deep into your arm.",
  causes_bleeding = true,
  bleed_rate = 3  -- HP per turn
}

-- Example: Environmental fall
on_jump_effect = {
  type = "fall_damage",
  amount = 15,
  injury_type = "bruise",
  message = "You hit the ground hard. Pain explodes through your legs."
}
```

### 3.3 Instant Death vs. Damage

Some hazards bypass HP entirely. This is a *design choice*, not a cop-out:

| Hazard | Effect | Rationale |
|--------|--------|-----------|
| **Poison bottle** | Instant death | Teaches "investigate before consuming." No amount of HP should save you from drinking pure poison. |
| **Long fall** | Instant death | Jumping off a tower isn't survivable. Realism serves the fiction. |
| **Trapped chest** (dart) | Damage + injury | Survivable but costly. Teaches "check for traps." |
| **NPC attack** | Damage | Combat is a sustained exchange, not instant death. |
| **Bleeding out** | Death over time | Treatable if the player acts. Creates puzzle urgency. |

**Design Rule:** Instant death should always be *player-initiated* (they chose to drink, jump, etc.) or *clearly telegraphed* (the skull-and-crossbones on the bottle, the bottomless pit). Surprise instant death is cruel and unfun.

---

## 4. Death & Game Over Design

### 4.1 Current State

The game currently has one death: poison. It sets `ctx.game_over = true` and the loop exits. There is no restart — just "Game over. Thanks for playing." (per D-BUG022: no false affordances).

### 4.2 Proposed Death Design

Death should be **dramatic, instructive, and recoverable** (eventually — restart is V2).

#### The Death Sequence

```
1. HP reaches 0
2. Death narrative plays (cause-specific text)
3. Brief pause (dramatic beat)
4. "YOU HAVE DIED."
5. Cause of death summary: "Cause: Blood loss from an untreated knife wound."
6. Optional hint: "Perhaps a bandage could have helped."
7. Game over. (Future: checkpoint restart)
```

#### Cause-Specific Death Text

Each death cause has unique flavor text. Examples:

**Bleeding Out:**
> *"The blood won't stop. You press your hand against the wound, but your fingers are too cold, too weak. The cellar floor is warm where you lie — or maybe that's just the last of your warmth leaving. The darkness that creeps in from the edges isn't the room. It's deeper than that."*

**Poison:**
> *"Your body crumples to the cold stone floor. The poison works swiftly — a fire in your veins, then ice, then nothing. Your last thought is of the skull etched on the bottle's label."*  
*(This text already exists in the engine.)*

**Fall:**
> *"The ground rushes up. There is a terrible, brief moment of understanding — and then silence."*

**Cold/Exposure:**
> *"The shivering stopped some time ago. That should worry you, but you can't quite remember why. The snow is so soft. Just rest for a moment..."*

**Infection:**
> *"The fever took you in the night. Your wound, untreated for too long, brought a sickness that no amount of willpower could fight. The last thing you see is the torchlight dancing on the ceiling, growing dim."*

### 4.3 Recovery Mechanics (Future — Phase 2+)

For V1, death is final (restart the game). For V2, two recovery options are on the table:

#### Option A: Checkpoint Respawn
- Game auto-saves at room transitions (entering a new room = checkpoint)
- On death, player restarts from last checkpoint with full HP but injuries cleared
- Items in inventory are preserved; world state is preserved
- **Pro:** Forgiving, encourages exploration. **Con:** Reduces stakes.

#### Option B: Near-Death Rescue
- At 0 HP, player enters "unconscious" state instead of dying
- If a healing item is in the room or on the player, there's a chance of recovery
- Recovery costs: wake up with 1 HP, all injuries worsen by one stage
- **Pro:** Rewards preparation (carry a potion!). **Con:** Complex to implement.

#### Option C: Permadeath with New Game+
- Death is permanent. Full restart.
- But: player retains *knowledge* (discovered shortcuts, puzzle solutions)
- Items/progress lost, but the player is smarter
- **Pro:** Maximum stakes, matches existing `game_over`. **Con:** Frustrating for casual players.

**Recommendation:** Start with **Option C** (permadeath) — it matches the current engine and creates maximum tension. Implement **Option A** (checkpoints) in V2 when save/load exists. Option B is a design treat for V3.

---

## 5. Damage Scenarios from Level 1

These scenarios demonstrate how health and injury interact with existing Level 1 content.

### Scenario 1: The Blood Writing Chain (Existing Mechanic, Formalized)

**Current behavior:** `prick self with pin` → `bleed_ticks = 8` → blood available for writing  
**With health system:**

```
> prick self with pin
"You press the pin into your fingertip. A bead of dark blood wells up.
 You lose 5 HP." (100 → 95 HP, Tier 4: Scratched)

> [3 turns later]
"The pinprick on your finger throbs dully." (Tier 4 reminder)

> [8 turns later]
"The bleeding has stopped. The tiny wound is already closing."
(Bleed_ticks exhausted. No further HP loss — prick is a one-time injury.)
```

**Puzzle implication:** Blood writing now has real cost. Pricking yourself 10+ times would push you into Wounded territory. The player must weigh "do I need to write this?" against HP.

### Scenario 2: The Knife as Hazard

**Setup:** Player finds knife under bed (existing). Knife has `injury_source` capability.

```
> cut self with knife
"You draw the blade across your palm. Blood flows freely.
 You lose 10 HP." (100 → 90 HP, Tier 4: Scratched)
"The cut is deep. Blood drips steadily from your hand."
(Injury: BLEEDING, 3 HP/turn until treated)

> [Turn 1 of bleeding]
"Blood drips from your hand, spattering the stone floor. (-3 HP)"
(90 → 87 HP)

> [Turn 2]
"The bleeding hasn't slowed. Your hand feels cold. (-3 HP)"
(87 → 84 HP)

> tear cloth from blanket
"You rip a strip of cloth from the wool blanket."

> bandage hand with cloth
"You wrap the cloth tightly around your palm. The bleeding slows
 and stops. The makeshift bandage holds." 
(Bleeding stopped. Injury: CUT → BANDAGED. No more HP drain.)
```

**Puzzle implication:** The knife is both a tool and a hazard. Cutting yourself for blood now requires treatment. The blanket — previously a flavor object — becomes a medical resource.

### Scenario 3: Poison Bottle — Preserved Instant Death

**Current behavior:** `taste poison bottle` → instant death → game over  
**With health system:** *Unchanged.* Poison bypasses HP. This is a design choice.

```
> taste poison bottle
"BITTER! The liquid burns your tongue, your throat, your stomach.
 Your body crumples to the cold stone floor. The poison works swiftly —
 a fire in your veins, then ice, then nothing."
 
YOU HAVE DIED.
Cause: Poison ingestion.
Perhaps the skull on the label was a warning.
```

### Scenario 4: Window Jump (Puzzle 013 — Courtyard Entry)

**With health system:**

```
> jump from window
"You haul yourself onto the ledge and leap. The ground is further
 than it looked. You hit the cobblestones hard, pain exploding
 through your ankles and knees."
 You lose 15 HP. (100 → 85 HP, Tier 4: Scratched)
 Injury: BRUISED LEGS

> [In courtyard, trying to climb ivy]
"You reach for the ivy, but your bruised legs buckle under you.
 You can't climb — not like this."

> rest
"You sit against the wall, letting the pain subside.
 After a while, the throbbing eases." 
(BRUISED LEGS: active → recovering. Climbing re-enabled after 5 turns.)
```

**Puzzle implication:** The window jump is no longer free. It creates a temporary physical limitation that affects what the player can do in the courtyard. The "safe" path (finding the key, using the door) avoids this cost.

### Scenario 5: Glass Shard Trap

**Setup:** Player breaks vanity mirror (existing). Glass shards appear.

```
> take glass shard
"You pick up a jagged piece of mirror. It bites into your palm.
 You lose 5 HP." (100 → 95 HP)
 Injury: MINOR CUT (hand)
"Your hand stings where the glass cut you."

> feel glass shard
"A wicked shard of mirror, razor-sharp on all edges.
 Your fingers come away slick with blood."
```

**Puzzle implication:** Glass shard becomes a risk/reward object. It's useful (cutting_edge capability) but hurts to handle. A piece of cloth wrapped around it (future: `wrap shard with cloth`) would prevent the injury — a mini-puzzle teaching "tools need preparation."

---

## 6. The `status` Command

### 6.1 Design

A new command lets the player check their condition. It does NOT show a number — it returns *narrative assessment*.

```
> status
"You feel strong and alert. No injuries trouble you."
(Tier 5: Full Health)

> status
"Your hand aches where the glass cut you. A cloth bandage,
 slightly bloodstained, is wrapped around your palm. Otherwise,
 you feel reasonably well."
(Tier 4: Scratched, one bandaged injury)

> status
"You are in bad shape. Your side throbs where the blade caught you,
 and the makeshift bandage is soaked through. Your head swims
 when you stand too quickly. You need proper treatment — soon."
(Tier 2: Critical, untreated slash wound)

> status
"Everything hurts. Your vision tunnels with each heartbeat.
 Standing takes an act of will. You are dying."
(Tier 1: Near-Death)
```

### 6.2 Optional: Numeric Mode

If Wayne decides players should see numbers, a `--verbose` flag or `health` command could show:

```
> health
HP: 42/100 (Wounded)
Active injuries: Slash wound (bleeding, -3 HP/turn), Bruised ribs
```

**Recommendation:** Keep narrative-only as default. Numbers as a debug/accessibility option.

---

## 7. Interaction with Game Time

### 7.1 Tick-Based Damage

Over-time injuries (bleeding, poison, cold) deal damage per game tick. The engine already has `tick_timers()` in the game loop — injury ticks plug into the same mechanism.

**Current:** Each command = 1 tick = 360 game seconds  
**With injuries:** Each tick also processes `player.active_injuries`, decrementing timers and applying per-tick damage.

### 7.2 Sleep and Health

The existing SLEEP verb advances the game clock. With health:
- **Sleeping while injured:** Over-time injuries continue ticking during sleep. Sleeping while bleeding is dangerous — you might not wake up.
- **Sleeping while healthy:** Could provide minor HP regeneration (5–10 HP per sleep hour). Design choice: rest as healing mechanic.
- **Sleeping while critical:** "You lie down, but the pain won't let you rest. Sleep eludes you." (Sleep blocked at Tier 1–2 unless medicated.)

### 7.3 Time Pressure from Injuries

Over-time injuries create **implicit turn limits**:

| Injury | HP Drain | Turns to Death (from 100 HP) | Turns to Death (from 50 HP) |
|--------|----------|-----------------------------|-----------------------------|
| Bleeding (minor) | 2/turn | 50 turns | 25 turns |
| Bleeding (major) | 5/turn | 20 turns | 10 turns |
| Mild poison | 5/turn | 20 turns | 10 turns |
| Infection (early) | 1/turn | 100 turns | 50 turns |
| Infection (late) | 3/turn (escalating) | ~33 turns | ~17 turns |
| Extreme cold | 2/turn | 50 turns | 25 turns |

**Design note:** These create natural puzzle urgency without artificial timers. The player doesn't see a countdown — they see their character deteriorating and feel the need to act.

---

## 8. Engine Integration Notes (For Bart)

### 8.1 Player State Extension

```lua
ctx.player.hp = 100
ctx.player.max_hp = 100
ctx.player.injuries = {}  -- table of active injury objects, each with its own FSM
ctx.player.health_tier = 5  -- computed from HP, drives narrative
```

### 8.2 Tick Integration

The game loop's existing tick cycle (after verb dispatch, after FSM tick, after timer tick) gets a new phase:

```
command → parse → dispatch verb → FSM tick → timer tick → INJURY TICK → game_over check
```

Injury tick: iterate `player.injuries`, apply per-tick effects (HP drain, status changes), check for auto-transitions (bleeding → infection if untreated for N turns).

### 8.3 Narrative Hook

A new function in the display system checks health tier after each command and optionally appends a health-state message:

```lua
function health_narrative(player)
  local tier = compute_health_tier(player.hp)
  if tier <= 3 then
    return tier_messages[tier][random_index]
  end
  return nil  -- no message at full health
end
```

### 8.4 Verb Guard Integration

Strenuous actions check health tier before executing:

```lua
-- In climb verb handler
if ctx.player.health_tier <= 2 then
  print("You try to climb, but your body won't cooperate. You're too weak.")
  return
end
```

---

## See Also

- [injury-catalog.md](./injury-catalog.md) — Full catalog of injury types and their FSMs
- [healing-items.md](./healing-items.md) — How healing objects work
- [README.md](./README.md) — System overview and design principles
- `docs/design/game-design-foundations.md` §4 — Original player model (hp, max_hp, stats)
- `docs/design/player-skills.md` §8 — Blood writing (existing injury → resource chain)
