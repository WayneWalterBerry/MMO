# Poison Bottle Object Design

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-25  
**Status:** DESIGN  
**Depends On:** Consumption hook system, injury system, composite objects, FSM engine  
**Audience:** Designers, Flanders (object implementation), Bart (engine), Smithers (poison system)

---

## Executive Summary

The poison bottle is a **composite, consumable injury object** that demonstrates the **consumption → injury pipeline**. Unlike a simple prop, the poison bottle has nested parts (bottle, liquid, cork, label), multiple FSM states (sealed → open → consumed), and a consumption hook that bridges the object system to the injury system. The bottle teaches three design patterns: *consumables*, *poison injuries*, and *nested component interaction*.

**Key design principle:** The poison bottle exists to be discovered, examined carefully (with warnings), and either avoided or drunk with consequence. The injury it causes is not punitive—it's *informational*. The player learns: "Unknown liquids are dangerous. TASTE before you DRINK. Sensory investigation saves lives."

---

## 1. Nested Parts Architecture

### 1.1 The Composite Model

The poison bottle is NOT a single monolithic object. It has logically distinct components:

| Part | Role | Detachable | Consumable | Interactive |
|------|------|-----------|-----------|-------------|
| **Bottle** | Container, sealed/open states | No | No | Yes (examine, hold) |
| **Liquid (Poison)** | The actual toxin, consumable substance | No | Yes | Yes (drink, consume) |
| **Cork/Stopper** | Removable seal component | Yes | No | Yes (pull out) |
| **Label** | Readable metadata, giveaway clue | No | No | Yes (examine, read) |

### 1.2 Part Interactions & State Transitions

**Sealed State:** `poison_bottle_sealed`
- Cork is in place, liquid is enclosed and unaccessed
- Player can: examine bottle, read label, hold, throw
- Player cannot: drink, smell the liquid directly
- Label text: "Sealed" OR "Unknown contents" OR poison warning
- Cork description: "A tightly-fitted cork stopper"

**Open State:** `poison_bottle_open`
- Cork has been removed (detached as separate object)
- Liquid is now exposed and can be consumed
- Player can: examine bottle, drink from it, smell the liquid directly, pour out
- Player cannot: re-seal without finding another cork
- Transitions from sealed → open on PULL/REMOVE CORK verb
- Bottle description updates: "The cork is missing. The liquid inside smells... wrong."

**Consumed/Empty State:** `poison_bottle_empty`
- Liquid has been consumed by player or poured out
- Bottle is now a useless container (no longer dangerous)
- Player can: examine it, hold it, pour more liquid in (future mechanics)
- Transitions from open → empty on DRINK or POUR OUT
- Category changes: no longer listed as "dangerous"

### 1.3 Cork Detachment Mechanics

**Detachable Part: Cork**

```
Cork Properties:
- id: poison_bottle_cork
- name: a cork stopper
- keywords: cork, stopper, seal, plug, wooden cork
- size: 0.5 (tiny)
- weight: 0.05 (nearly nothing)
- detachable: true
- portable: true
- description (while attached): "A tightly-fitted cork stopper keeping the contents sealed."
- description (detached): "A small wooden cork, stained at one end from sealing a dark liquid."

Factory Function (when detached):
- Instantiates cork as an independent object in the room
- Cork loses "attached" flag and becomes takeable
- Parent (bottle) transitions: sealed → open
- Bottle description updates to show exposed liquid
```

**Why this matters:** The cork is a **discovery moment**. The player realizes: "The bottle can be opened. The liquid is accessible. This changes the risk level." The cork also demonstrates **reversible detachment** — unlike a broken piece, a cork can theoretically be put back (future mechanic).

### 1.4 Label Examination Without Opening

**Non-Detachable Part: Label**

```
Label Properties:
- id: poison_bottle_label
- name: a label
- keywords: label, writing, text, warning, warning text
- detachable: false (cannot be removed)
- readable: true
- readable_text: "⚠️ POISON — Belladonna extract. Lethal if ingested. 
                 (Two tiny paragraphs of warning text, possibly in archaic script)"

Interaction Flow:
- examine label → displays readable_text
- read label → same as examine (alias)
- read poison bottle → can read the label without removing cork
- read the warning → hints at the danger
```

**Design principle:** The player can and *should* read the label before drinking. This is a **fair warning design**. The poison bottle doesn't hide its danger—it broadcasts it through readable text. A cautious player can avoid the injury entirely.

**Sensory Investigation:**
- **LOOK:** See the bottle is sealed, notice the label
- **READ:** Learn the contents are dangerous (Belladonna, "lethal if ingested")
- **SMELL:** If sealed, no smell. If open, smell the liquid directly (faint floral sweetness, almost pleasant but *off*)
- **TASTE:** If open and drunk, immediate poison onset

**Safety hierarchy:** READ (safe) → SMELL (safe if sealed) → DRINK (lethal).

---

## 2. Consumption → Injury Pipeline

### 2.1 Consumable Mechanics

The poison bottle is marked with metadata:

```lua
{
  id = "poison-bottle",
  name = "poison bottle",
  is_consumable = true,           -- KEY FLAG
  consumable_type = "liquid",      -- Affects drinking verb
  poison_type = "nightshade",      -- Specific to this bottle
  poison_severity = "lethal",      -- Severity scale
  ...
}
```

**Consumable Types:**
- `liquid` — Consumed by DRINK, SIP, GULP verbs
- `solid` — Consumed by EAT, BITE verbs
- `potion` — Consumed by DRINK or CONSUME (magical context)

### 2.2 The DRINK Verb → Injury Hook

When a player drinks from an open poison bottle:

```
> drink poison bottle
[Engine: target is poison-bottle]
[Engine: is_consumable == true]
[Engine: calls on_consume hook with verb="drink"]
[Hook: passes to injury system]
[Injury System: inflicts "poisoned-nightshade" injury]
```

**Hook Signature:** `on_consume(verb, severity)`
- `verb`: "drink", "sip", "gulp", "consume", "taste"
- `severity`: quantifies how much was consumed
  - "sip" = small amount = lower severity poison onset
  - "gulp" = normal amount = standard severity
  - "drink whole bottle" = full amount = highest severity

**Severity Levels (Internal Mapping):**

| Amount | Verb | Initial Damage | Duration | DoT/Turn |
|--------|------|---|---|---|
| Trace | sip | -5 | 12 turns | -1/turn |
| Normal | gulp | -10 | 18 turns | -2/turn |
| Full | drink all | -20 | 24 turns | -3/turn |

Example: `on_consume("sip", "nightshade")` → injury applied with "low" severity; `on_consume("drink all", "nightshade")` → injury applied with "lethal" severity.

### 2.3 Specific Poison Types & Injury Classes

**Design pattern:** Different poison bottles can cause different injuries, each with its own onset time, severity scale, and treatment.

**Nightshade Poisoning** (from poison bottle in cellar)
- Injury ID: `poisoned-nightshade`
- Onset: Immediate (within 1 turn)
- Symptoms: Burning sensation, nausea, hallucinations
- Pattern: Ticks -2 health/turn (over 18+ turns if untreated)
- Cure: Nightshade antidote (specific) OR purge mechanism (vomit via salt water)
- Narrative: "Your throat burns. The world spins. You've been poisoned."

**Mild Food Poisoning** (from spoiled food — future mechanic)
- Injury ID: `poisoned-mild`
- Onset: Delayed 2-3 turns
- Symptoms: Stomach cramps, nausea, weakness
- Pattern: Ticks -1 health/turn (over 12 turns)
- Cure: Generic antidote OR rest (self-heals slowly)
- Narrative: "Your stomach churns. Something you ate didn't agree with you."

**Viper Venom** (from dart trap — future mechanic)
- Injury ID: `poisoned-viper`
- Onset: Immediate (within 1 turn)
- Symptoms: Rapid heartbeat, numbness, vision fading
- Pattern: Ticks -3 health/turn (over 8 turns — URGENT)
- Cure: Viper antidote (specific) OR immediate medical intervention
- Narrative: "Your heart races. Everything is going numb. The venom spreads fast."

**Design principle:** Specificity matters. Players learn through consequence that "nightshade antidote" ≠ "generic antidote" ≠ "viper antidote". Treatment matching becomes a puzzle.

### 2.4 Onset Delay & Symptom Progression

**Immediate onset (Nightshade):**
- Turn 0 (consumption): "You drink the poison. Your throat burns immediately."
- Turn 1: First damage tick, hallucinations begin
- Turns 2-10: Ongoing damage, worsening symptoms
- Turn 15+: Critical symptoms, player is in danger

**Delayed onset (Mild poison):**
- Turn 0 (consumption): "You eat the tainted food. It tastes fine."
- Turns 1-2: No visible symptoms; player feels fine
- Turn 3: "Your stomach cramps. Something is wrong."
- Turns 4-10: Damage ticks begin

**Design principle:** Delayed onset teaches a harder lesson: "I felt fine an hour ago, and now I'm dying." This demonstrates the importance of investigation BEFORE consumption, not hindsight after.

### 2.5 Cure & Antidote Mechanics

**Antidote Matching:**

| Injury | Specific Cure | Generic Cure | Cure-All | Self-Healing |
|--------|---|---|---|---|
| Nightshade | Nightshade antidote | — | — | No (fatal if untreated) |
| Mild poison | Generic antidote | Yes | — | Slow (24+ turns) |
| Viper venom | Viper antidote | — | — | No (fatal if untreated) |

**Application Mechanics:**

The player cures poison via:
1. **Drink antidote** (verb: DRINK, target: antidote-bottle)
   - Requires inventory space, knowledge of which antidote
   - Immediate effect (within 1 turn)
   
2. **Purge mechanism** (verb: VOMIT, triggered by salt water or special action)
   - Requires finding salt water or emetic substance
   - Violent but effective for mild poison
   - Leaves player weakened but clears the poison
   
3. **Time & rest** (only for mild poison)
   - Character passively heals over 20+ turns
   - Risky because player is vulnerable while healing
   - Works in safe locations (bedroom, not on active puzzles)

**Engine Hook:** `on_apply_treatment(injury_type, treatment_item)` → checks if treatment matches injury → applies cure effect.

---

## 3. Engine Hook Points & FSM Architecture

### 3.1 Required Engine Events

For the poison bottle to function, the engine must support these hooks:

**Consumption Hooks:**
- `on_consume(verb, severity)` — Called when player drinks/eats consumable
- `on_drink()` — Specific to liquid consumption
- `on_eat()` — Specific to solid consumption
- `on_taste(severity)` — Called when player tastes/samples (lower severity than drink)

**State Transition Hooks:**
- `on_state_change(from_state, to_state)` — Called when FSM transitions (sealed → open)
- `on_part_detach(part_id)` — Called when cork is removed
- `on_part_attach(part_id)` — Called if cork is re-inserted (future mechanic)

**Property Mutation Hooks:**
- `on_mutate(property, new_value)` — Update object properties during state transitions
  - Example: keywords change from "sealed bottle" to "open bottle"
  - Example: category changes from "dangerous" to "less dangerous"

### 3.2 FSM State Diagram

```
                    +----------+
                    | SEALED   |
                    +----------+
                         |
                  [on_pull_cork]
                         |
                         v
                    +----------+
                    | OPEN     |
                    +----------+
                    /          \
        [on_drink]  /            \  [on_pour_out]
                   /              \
                  v                v
            +----------+      +----------+
            | CONSUMED | or  | EMPTY    |
            +----------+      +----------+
```

**State Transitions & Mutations:**

| From | To | Trigger | Mutation | New Description |
|------|-------|---------|----------|---|
| SEALED | OPEN | PULL/REMOVE cork | Add "open_bottle" category, remove cork from parts | "The bottle is now open, and the liquid inside smells strange." |
| OPEN | CONSUMED | DRINK (full bottle) | Remove "consumable" flag, set weight to 0.1 (empty) | "An empty bottle, smelling of bitter almonds." |
| OPEN | EMPTY | POUR OUT all liquid | Same as CONSUMED | "The liquid has been poured out." |

### 3.3 Metadata Requirements

The poison bottle .lua file must declare:

```lua
{
  id = "poison-bottle",
  name = "poison bottle",
  keywords = { "poison", "bottle", "liquid", "vial", "dark liquid" },
  
  -- Consumable flag
  is_consumable = true,
  consumable_type = "liquid",
  poison_type = "nightshade",      -- Specific poison class
  poison_severity = "lethal",      -- Severity scale
  
  -- Consumption hook handler
  on_consume = function(self, verb, severity)
    -- Called when player drinks
    -- Passes to injury system
    -- Returns success/failure
  end,
  
  -- FSM & state tracking
  fsm = {
    initial_state = "sealed",
    states = { "sealed", "open", "consumed", "empty" },
    transitions = { /* ... */ }
  },
  
  -- Sensory descriptions
  on_feel = { sealed = "...", open = "..." },
  on_smell = { sealed = "Nothing escapes.", open = "Faint floral sweetness, almost pleasant but wrong." },
  on_taste = { open = "The liquid burns your tongue." },
  on_look = { /* describes state */ },
  
  -- Parts: cork + label
  parts = {
    cork = { detachable = true, ... },
    label = { detachable = false, readable = true, ... }
  },
  
  -- Categories (system-level queries)
  categories = { "dangerous", "consumable", "liquid", "poison" }
}
```

### 3.4 How on_consume Connects to the Injury System

**Call Chain:**

```
1. Parser: "drink poison bottle"
   ↓
2. Verb Handler: on_drink(object=poison_bottle)
   ↓
3. Consumption Check: is_consumable == true?
   ↓
4. Call Hook: poison_bottle.on_consume(verb="drink", amount="full")
   ↓
5. Hook Implementation: Communicates with injury system
   ↓
6. Injury System: Creates "poisoned-nightshade" injury instance
   ↓
7. Injury added to player.injuries array
   ↓
8. Game Loop: Each turn, injury ticks, health drains, symptoms print
```

**Hook Implementation (pseudo-code):**

```lua
function poison_bottle:on_consume(verb, amount)
  local injury_type = self.poison_type        -- "nightshade"
  local severity = self.poison_severity      -- "lethal"
  
  -- Map amount to damage scale
  local damage_multiplier = {
    sip = 0.5,
    gulp = 1.0,
    ["drink all"] = 2.0
  }
  
  -- Create injury instance
  local injury = create_injury(
    type = injury_type,
    severity = severity,
    damage_multiplier = damage_multiplier[amount],
    origin = self.id
  )
  
  -- Apply to player
  player.add_injury(injury)
  
  -- Narrate
  narrate("You drink the poison. Your throat burns immediately.")
  
  -- Transition bottle FSM
  self.transition_to("consumed")
  
  return true
end
```

---

## 4. Player Experience & Narration

### 4.1 Discovery & Investigation Phase

**Player encounters sealed bottle:**

```
> examine poison bottle
"A small glass bottle with a dark, murky liquid inside. A cork stopper 
seals the contents. There's a label on the side, partially faded."

> read label
"⚠️ POISON — Belladonna extract. LETHAL if ingested. 
Keep away from children and animals. Do not under any circumstances drink."

> look at it (sensory: LOOK)
"The liquid inside is dark red-brown, almost black in shadow. It doesn't 
swirl like water—it's thicker, more viscous. The label's warning is clear 
and urgent."

> smell (from across the room, sealed)
"From a distance, the bottle smells faintly of earth and stone—sealed tight."
```

**Safe investigation** (from sealed bottle):
- READ label → direct warning, no ambiguity
- LOOK → observe color, viscosity, opacity
- SMELL (at distance) → minimal scent due to seal

**Risky investigation** (after opening):

```
> pull cork
"You pull the cork free. It comes out with a soft pop. The moment the 
bottle is open, a faint smell escapes—floral, sweet, almost beautiful... 
but there's something *wrong* about it. The sweetness has an acrid edge, 
like flowers in a crypt."

> smell (now open)
"The open bottle releases a peculiar fragrance—sweet blooms mixed with 
something chemical and sharp. Your instincts scream *danger*."

> taste (sip without drinking)
"Your tongue touches the liquid. It burns immediately. The sensation is 
fire, and you pull back. You spit. Your mouth is numb."
```

**Fair warning design:** The player has multiple chances to realize danger:
1. **Read label** (safest) → explicit warning
2. **Smell** (after opening) → warning through sensory intuition
3. **Taste** (sip) → warning through pain, but not death
4. **Drink** (full gulp) → consequence (death incoming)

### 4.2 Consumption Narration

**Moment of drinking:**

```
> drink poison bottle
"You raise the bottle to your lips. The liquid burns your throat as you 
swallow—a sensation like swallowing fire. Your mouth goes numb. Your 
stomach writhes.

Oh god. You drank *poison*.

Your heart races. The room tilts. The walls... are they breathing?"
```

**Symptom Progression (turns 1-5):**

Turn 1:
```
"Burning spreads through your veins. Your vision blurs at the edges. 
Is the room getting darker?"
```

Turn 2:
```
"The poison is in your blood. Every breath is agony. The shadows in 
the corners are *moving*. You feel cold despite sweating."
```

Turn 3 (Hallucination begins):
```
"You can't tell what's real anymore. The shadows have teeth. The room 
tilts sideways. Your hands shake uncontrollably. 

*You're dying.*

And you have maybe fifteen more turns before it kills you. You need 
an antidote. NOW."
```

### 4.3 Progressive Symptom Text

The injury system generates symptom text that changes with progress:

| Turn | Damage | Symptom Narrative |
|------|--------|---|
| 0 | 10 (immediate) | "Your throat burns. You drank poison." |
| 1 | -2 | "Fire in your veins. The world tilts." |
| 3 | -2 | "Hallucinations flicker at the edges of your vision." |
| 6 | -2 | "Reality fractures. You see *things* that aren't there." |
| 10 | -2 | "You're fading. The poison is overwhelming." |
| 15+ | -2 | "Your last thought: You should have read the label." |

### 4.4 Death & Untreated Poison

If the player does not get an antidote and poison reaches lethal levels:

```
[After 18 turns of untreated nightshade poisoning]

"The fire in your blood reaches a crescendo. Your vision goes white, 
then black. Your heart convulses. 

The last thing you remember is the taste of bitter almonds.

Then... nothing."

[DEAD — Cause of Death: "Nightshade Poisoning (Untreated)"]
```

### 4.5 Successful Treatment Narration

If player finds and drinks nightshade antidote in time:

```
[Turn 8 of poisoning, player drinks antidote]

"The antidote burns going down—sharp and metallic. For a moment, the 
burning in your veins seems to worsen, and you panic. 

Then... the fire recedes. Your vision clears. The hallucinations 
dissolve like mist. Your heart slows.

You're alive. The antidote worked. The poison is neutralizing."

[Injury Status: Nightshade poisoning (stabilized, healing)]
```

---

## 5. Design Patterns & Reusability

### 5.1 Consumption Patterns

This poison bottle design establishes three reusable patterns:

**Pattern 1: Consumable with immediate effect**
- Use for: Poison bottles, healing potions, spoiled food
- Hook: `on_consume()` → immediate injury or healing
- Example: Poison bottle (this design)

**Pattern 2: Consumable with delayed effect**
- Use for: Slow poison, contaminated water, bad mushrooms
- Hook: `on_consume()` → delayed injury (onset in 3-5 turns)
- Future: A tainted meal in the kitchen

**Pattern 3: Consumable with accumulation**
- Use for: Magical toxins that stack, alcohol, addictive substances
- Hook: `on_consume()` → repeated effect if consumed multiple times
- Future: A magical wine that causes stacking hallucinations

### 5.2 Object Nesting Patterns

The poison bottle's nested architecture (bottle + liquid + cork + label) parallels:

- **Matchbox:** Container + individual match objects + striker surface
- **Nightstand:** Furniture + drawer (detachable) + mirror (non-detachable)
- **Weapon:** Hilt + blade (detachable) + crossguard (non-detachable)

All follow the same principle: **one parent file, multiple parts, selective detachability**.

### 5.3 State Machine Reuse

The poison bottle's FSM (`sealed → open → consumed`) mirrors:

- **Candle:** unlit → lit → burnt-out
- **Window:** closed → open → broken
- **Matches:** box full → box partially used → box empty

The mutation pattern (keywords update, categories shift, descriptions change) is consistent across all FSM objects.

---

## 6. Testing & Validation Checklist

### Safe Path Testing
- [ ] Sealed bottle: player reads label (safe)
- [ ] Player smells sealed bottle (safe, minimal scent)
- [ ] Player can hold bottle without injury
- [ ] Examine shows correct state description

### Investigation Testing
- [ ] Player pulls cork (bottle transitions to OPEN)
- [ ] Cork appears in inventory as separate object
- [ ] Bottle description updates ("now open")
- [ ] Smell of open bottle is different from sealed
- [ ] Player tastes (sips) open bottle without lethal effect

### Consumption Testing
- [ ] Player drinks (full gulp) open bottle
- [ ] Poison bottle transitions to CONSUMED
- [ ] Player receives "poisoned-nightshade" injury
- [ ] Injury begins ticking immediately
- [ ] Symptom text appears each turn
- [ ] Player can use "injuries" verb to diagnose

### Treatment Testing
- [ ] Player can find nightshade antidote
- [ ] Player drinks antidote before death
- [ ] Poison injury stabilizes and heals
- [ ] Death message appears if untreated past threshold
- [ ] Generic antidote does NOT cure nightshade (treatment matching works)

### Edge Cases
- [ ] Player tries to drink sealed bottle (parser should offer PULL CORK first, or refuse)
- [ ] Player tries to pour out empty bottle (no effect, already empty)
- [ ] Player carries multiple poison bottles (inventory stacking)
- [ ] Player throws bottle at NPC (does not poison NPC—physical object, not ingestion)

---

## 7. Future Extensions

### 7.1 Poison Variants

Different poison bottles could be placed in different levels:

- **Level 1:** Nightshade (teaching poison matching)
- **Level 2:** Viper venom (faster onset, more lethal)
- **Level 3:** Paralytic toxin (causes paralysis instead of damage ticking)
- **Level 4:** Hallucination toxin (causes perception distortion, not damage)

### 7.2 Antidote Mechanics

Antidotes could become craftable items:

- **Knowledge gate:** Player must find the Medical Scroll (in deep cellar)
- **Resource matching:** Antidote requires specific herbs + base (honey water?)
- **Brewing time:** Antidote preparation takes 3+ turns (time-pressure puzzle)

### 7.3 NPC Poisoning Mechanics

In multiplayer or future content:

- NPCs can be poisoned (same mechanism as player)
- Player can GIVE poisoned bottle to NPC (ethical puzzle)
- NPC dies from poison → consequences for player (faction standing, story branching)

### 7.4 Environmental Poison Mechanics

Future hazards could use the same injury system:

- **Poison gas room:** Traverse room → "on_enter" hook → immediate poison injury
- **Contaminated water:** Drink from well → "on_consume" hook → mild poison
- **Toxic plant:** Touch or eat → "on_touch" hook → injury

---

## 8. Design Decisions & Rationale

### Decision 1: Why Nested Parts?

**Question:** Why is the poison bottle a composite object instead of a simple consumable?

**Answer:** Nested parts create **agency and exploration**. A simple consumable is just "drink or don't drink." A composite object is:
- Cork: "I can open this. I need to decide if I want to."
- Label: "I can read this first. I can learn the danger."
- Liquid: "I can observe this without drinking."

The nesting teaches decision-making before consequence.

### Decision 2: Why Readable Label?

**Question:** Why not just let players make a blind choice?

**Answer:** **Fair warning design**. The game should never punish players for lack of information. The poison bottle broadcasts its danger loudly. A cautious player can avoid it entirely. The injury only occurs if the player ignores repeated warnings.

This isn't a gotcha. It's a lesson.

### Decision 3: Why Different Poison Types?

**Question:** Why have "mild poison," "nightshade," and "viper venom" instead of just "poison"?

**Answer:** **Treatment matching as puzzle**. Players learn through consequence that specificity matters. A generic antidote works for mild poison but not nightshade. This creates a three-part puzzle:
1. Identify what poisoned you (read injury description)
2. Find the right antidote (connect knowledge: nightshade = belladonna)
3. Apply correctly (drink antidote, not bandage poison)

### Decision 4: Why Immediate Onset?

**Question:** Why does nightshade poison start immediately instead of waiting 3 turns?

**Answer:** **Teaching moment clarity**. The bottle is the Level 1 "introduction to poison." Immediate onset makes the cause-effect crystal clear: "I drank, now I'm dying." Delayed poison comes later (Level 2), teaching the lesson: "I felt fine an hour ago."

---

## Cross-References

- **Injury System Design:** `docs/design/player/health-system.md` — How injuries aggregate
- **Injury Catalog:** `docs/design/player/injury-catalog.md` — Specific poison types (mild, viper, nightshade)
- **Composite Objects:** `docs/design/composite-objects.md` — Nested parts and detachability pattern
- **FSM Lifecycle:** `docs/design/fsm-object-lifecycle.md` — State machine implementation
- **Verb System:** `docs/design/verb-system.md` — How DRINK, TASTE, PULL verbs resolve
- **Healing Items:** `docs/design/player/healing-items.md` — How antidotes are implemented
- **Puzzle Integration:** `docs/design/injuries/puzzle-integration.md` — How poison fits in puzzle design
- **Object Design Patterns:** `docs/design/object-design-patterns.md` — Reusable patterns for complex objects
