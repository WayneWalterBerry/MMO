# Self-Hit (`hit` Verb) — Design for Self-Infliction Testing

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-23  
**Status:** DESIGN  
**Depends On:** [Stab](../verbs/stab.md), Injury system, Unconsciousness system  
**Audience:** Designers, Flanders (object implementation), Bart (engine), Nelson (testing)

---

## 1. Core Concept

The `hit` verb allows the player to punch, strike, or bash themselves — or objects in the environment. For single-player, it's primarily a **testing mechanism** for the unconsciousness injury system. It parallels the existing `stab self` pattern that lets players test bleeding injuries.

**Why self-hitting?** It creates a safe, controlled way to explore injury mechanics without requiring enemy combat (which doesn't exist in V1). The player can trigger head injuries, understand consequences, and learn the game's danger model at their own pace.

---

## 2. Syntax & Behavior

### 2.1 Full Syntax

```
hit [body area] [with [object]]
hit head
hit head with rock
hit arm with club
hit self                          (bare fists, random area)
punch head                        (synonym)
strike myself on the arm          (natural language variant)
bash head against wall            (object-based variant)
```

### 2.2 Body Area Targeting

The `hit` verb reuses the body area system from `stab`:

| Body Area | Effect | Severity | Armor Protection |
|-----------|--------|----------|------------------|
| **head** | Unconsciousness | 5-15 turns | Helmet reduces/negates |
| **arm** | Bruise (pain category) | —— | Gloves reduce |
| **leg** | Bruise (pain category) | —— | Leg armor reduces |
| **torso** | Bruise (pain category) | —— | Chest armor reduces |

**Default (no area specified):** Randomly selects an area. `hit self` picks a random area and uses bare fists.

### 2.3 Weapon Options

`hit` accepts blunt objects as modifiers:

```
hit head with rock              (increases unconsciousness duration)
hit head with club
hit head with hammer
hit arm with stick              (increases bruise severity)
hit leg with plank
```

**Bare fists:** Default if no weapon specified. Deals base damage.

**Blunt weapons:** Increase severity. A rock increases duration by +3-4 turns. A hammer increases by +5-7 turns.

**Invalid weapons:** Sharp objects (knife, sword) can't be used with `hit`:
> *"You can't punch yourself with a knife — that's stabbing. (Try `stab self with knife`.)"*

---

## 3. Injury Results by Body Area

### 3.1 Head Hit → Unconsciousness

```
> hit head
"You slam your fist hard against the side of your head. Stars explode across your vision. 
The world tilts and fades..."

[Unconsciousness injury applied — 5-turn duration]
[Player enters unconscious state]
```

**Mechanics:**
- Base severity: 5 turns (with bare fist)
- With light weapon (rock, club): +3-4 turns
- With heavy weapon (hammer, sledge): +5-7 turns
- Helmet reduces by 30-50% (or negates light hits)
- After timer expires, player wakes naturally

**Multiple hits:** If the player gets hit on the head again while unconscious, the timer **restarts** at the new duration (doesn't stack).

### 3.2 Arm/Leg Hit → Bruise

```
> hit arm
"You punch yourself in the arm. Sharp pain blooms across the muscle."

[Bruise injury applied — pain category]
```

**Mechanics:**
- Creates a "bruise" injury (pain type, not unconsciousness)
- Pain injuries affect actions (slower movement, weaker grip)
- Base severity: 1-2 turns of pain
- With weapon: +1-2 turns
- Armor (gloves, sleeves) reduces or prevents
- No unconsciousness effect

**Stacking:** Multiple arm bruises can accumulate (left arm + right arm = both hurt).

### 3.3 Torso Hit → Bruise + Possible Winded

```
> hit torso
"You drive your fist into your ribs. Air explodes from your lungs."

[Bruise injury applied to torso]
[Optional: "winded" effect — reduced movement speed for 1-2 turns]
```

**Design note:** Torso hits can optionally cause "winded" status (mechanic for future, not V1).

---

## 4. Armor Interaction

### 4.1 Head Armor (Helmets)

Helmets protect against head hits by reducing unconsciousness duration:

| Armor Type | Reduction | Effect |
|-----------|-----------|--------|
| Bare head | 0% | Full duration (5-15 turns) |
| Leather helmet | 30% | Reduced duration (3-10 turns) |
| Iron helmet | 50% | Severe reduction (2-7 turns) |
| Full plate + gorget | 75% | Can negate all but strongest hits |

**Mechanics:** When applying unconsciousness injury, engine checks for worn head armor and applies `reduces_unconsciousness` modifier.

**Example:**
- Player wearing iron helmet hits head with rock
- Base duration: 8 turns (head hit + rock)
- With iron helmet (50% reduction): 4 turns
- Player wakes after 4 turns

### 4.2 Other Armor (Arms, Legs, Torso)

Gloves, sleeves, and armor reduce bruise severity or prevent injury entirely:

```
> hit arm (no armor)
"You punch your arm. It hurts."
[Bruise applied — moderate pain]

> wear gloves
> hit arm
"You punch your gloved arm. It stings, but the gloves absorb most of the impact."
[Reduced bruise, or no injury]
```

---

## 5. Narration & Flavor

### 5.1 Hit Head Narration Variants

**Bare fist:**
> *"You slam your fist hard against the side of your head. Stars explode across your vision. The world tilts..."*

**With rock:**
> *"You smash your head with a rock. Blinding white light, then darkness..."*

**With helmet, light hit:**
> *"You punch your helmeted head. It clangs metallically. Your ears ring, but the helmet took most of the impact."*

**With helmet, hard hit:**
> *"You drive a heavy rock at your helmeted head. The impact is tremendous — even through the iron, you see stars and stumble..."*

### 5.2 Hit Arm/Leg Narration

**Arm bruise:**
> *"You punch yourself in the arm. Sharp pain blooms across the muscle. That's going to ache."*

**Leg bruise:**
> *"You drive your fist down against your leg. Intense pain shoots through the limb — you're going to be limping for a bit."*

**With armor reduction:**
> *"You punch your gloved arm. It stings, but the padding absorbed most of the blow."*

---

## 6. Prime Directive Compliance

The `hit` verb works with natural language variants as per the Prime Directive:

| Player Input | Resolution |
|--------------|-----------|
| `hit` | "Hit what?" (Prime Directive friendly) |
| `hit self` | Random body area, bare fists |
| `hit head` | Head targeting |
| `hit myself in the head` | Head targeting (pronoun resolution) |
| `punch head` | Synonym for `hit` |
| `strike arm` | Synonym for `hit` |
| `bash my leg` | Pronoun resolution + area targeting |
| `smash head with rock` | `hit head with rock` |
| `thump myself` | Random area, bare fists |

**No explicit weapon required for bare fist:** `hit head` works without saying "with nothing" — bare fists are the default.

---

## 7. Parser Integration

### 7.1 Verb Handling

```lua
handlers["hit"] = function(command_obj)
  -- Handle variants: hit, punch, strike, bash, bonk, smash, thump
  -- Parse body area from direct object
  -- Parse weapon/modifier from "with" clause
  -- Route to injury system with appropriate parameters
end
```

### 7.2 Body Area Resolution

Body areas from `command_obj.directobject`:
- "head" → head
- "arm" / "arms" → random arm (left/right) or specified "left arm", "right arm"
- "leg" / "legs" → random leg
- "torso" / "chest" / "ribs" → torso
- "self" → random area

### 7.3 Weapon Resolution

Weapon from `command_obj.indirect_object` (after "with"):
- Rock, club, stick, hammer, sledge, plank, etc. (blunt objects only)
- Check weapon's `is_blunt` property or `blunt_damage` modifier
- Sharp weapons: reject with appropriate message

---

## 8. Self-Infliction Pattern

`hit` follows the same testing pattern as `stab`:

```
Testing bleeding (existing):
  > stab self with knife
  [Bleeding wound applied]
  > injuries
  [Check condition]
  > apply bandage
  [Treat wound]

Testing unconsciousness (new):
  > hit head
  [Unconscious for 5 turns]
  > [wait or do nothing]
  [After 5 turns: wake up naturally]
  > injuries
  [Check condition after waking]
```

**Educational flow:** Player learns injury mechanics through experimentation. Safe self-testing beats discovering it through traps.

---

## 9. Interaction with Puzzles

### 9.1 Blocking Actions While Bruised

Bruise injuries can block certain actions (design detail for Smithers/Bart):

```
> climb rope
"Your arm is too bruised. You can't pull yourself up."

[After bruise heals]
> climb rope
"You climb..."
```

**Design rationale:** Injuries create time-pressure puzzles. Solve the puzzle before your arm hurts too much to act.

### 9.2 Discovery Hook

`hit` can be the player's first discovery of the injury system:

```
> hit head
"You slam your fist against your head. Stars explode..."
[Enter unconscious state]
[After waking]
> injuries
"You examine yourself: A dull ache in your head from the impact..."
```

This teaches the player that injuries exist and that the `injuries` verb lists them.

---

## 10. Damage Values & Balance

### 10.1 Head Hit Severity Scale

| Scenario | Duration |
|----------|----------|
| Bare fist hit (light) | 3-5 turns |
| Bare fist hit (hard) | 5-8 turns |
| Rock/club hit | 8-12 turns |
| Hammer/heavy hit | 12-18 turns |
| Sledgehammer hit | 18-25 turns |

**Design principle:** More severe = longer unconsciousness. This lets players tune their testing (light hit = quick check, heavy hit = dangerous).

### 10.2 Bruise Severity Scale

| Scenario | Pain Duration | Action Penalty |
|----------|-----------|---------|
| Light punch | 1-2 turns | -5% action speed |
| Medium punch | 2-4 turns | -10% action speed |
| Heavy punch | 4-6 turns | -15% action speed |

---

## 11. Edge Cases

### 11.1 Can't Hit While Unconscious
```
> [unconscious]
> hit head
"You can't — you're unconscious."
```

### 11.2 Multiple Hits Don't Stack Unconsciousness
```
> hit head
[5-turn unconsciousness applied]
> [on turn 2 of unconsciousness]
> [auto-attack or trap triggers another head hit]
[Timer restarts to 5 turns, doesn't become 10 turns]
```

**Rationale:** Once you're out, you're out. A new blow can keep you down longer, but doesn't make you "more unconscious."

### 11.3 Hitting While Already Injured
```
> hit head (with existing bleeding wound from earlier stab)
[Unconsciousness applied]
[Bleeding continues to tick during unconsciousness]
[Both injuries active simultaneously]
```

### 11.4 Wrong Weapon Type
```
> hit head with knife
"You can't punch yourself with a knife — that's stabbing. (Try `stab self with knife`.)"
```

---

## 12. Testing Criteria (Nelson)

- [x] `hit head` triggers unconsciousness
- [x] `hit arm` / `hit leg` trigger bruise injury (pain type)
- [x] Bare fists produce appropriate severity
- [x] Rock/club increase duration by expected amount
- [x] Helmet reduces unconsciousness duration
- [x] Body area targeting works (head, arm, leg, torso)
- [x] Pronouns resolve correctly (`hit my head`, `punch myself in the arm`)
- [x] Multiple injuries stack (bleeding + unconscious)
- [x] Natural language variants work (punch, strike, bash)
- [x] Invalid weapon types rejected gracefully
- [x] Can't act while unconscious from self-hit
- [x] Wake-up narration after self-hit unconsciousness
- [x] `injuries` verb shows bruises correctly

---

## 13. Implementation Notes for Smithers

1. **Verb handler:** Create `handlers["hit"]` in `src/engine/verbs/init.lua`
2. **Body area resolution:** Parse from direct object, handle variants (head, arm, leg, torso)
3. **Weapon modifier:** Check indirect object after "with", apply damage multiplier
4. **Armor interaction:** When applying unconsciousness or bruise, check for worn armor and apply reduction
5. **Injury routing:** Route to injury system with `injury_type = "unconsciousness"` or `"bruise"` and appropriate severity
6. **Narration:** Use injury-specific wake-up template for unconsciousness caused by `hit head`
7. **Self-only:** For V1, `hit` is self-only. Combat hits are future (Phase 2+)

---

## 14. See Also

- `docs/verbs/hit.md` — Verb reference for `hit`
- `docs/verbs/stab.md` — Parallel self-infliction pattern for bleeding
- `docs/design/injuries/unconsciousness.md` — Full unconsciousness system design
- `docs/design/player/health-system.md` — Injury mechanics overview
- `docs/design/injuries/treatment-targeting.md` — Treatment/application patterns
