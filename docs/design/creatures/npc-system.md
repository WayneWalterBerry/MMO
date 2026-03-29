# NPC System Design Reference

**Last updated:** 2026-03-28  
**Audience:** Game Designers, Level Designers, Puzzle Designers  
**Purpose:** Player-facing reference for creatures, their behavior, and how they interact with the player.

---

## What Are Creatures?

**Creatures** are living beings in the world — rats, cats, dogs, and (eventually) humanoids like guards and merchants. Unlike furniture or tools, creatures are **alive**. They have:

- **Agency** — they make decisions each turn (where to move, whether to flee, etc.)
- **Needs** — they get hungry, scared, curious; these needs drive their actions
- **Mortality** — they can be killed and stay dead
- **Autonomy** — they move around rooms, react to the player, and interact with their environment

The player cannot pick up a living creature. But if a creature dies, it becomes a corpse — inanimate, moveable, and part of the world state.

Creature definitions live in `src/meta/creatures/` (for example, `src/meta/creatures/rat.lua`).

---

## How Creatures Behave

### The Tick System

Every turn (after the player issues a command), the world advances:

1. The game processes the player's action
2. Automatic transitions happen (candles burn down, fires spread)
3. **Creatures act** ← this is where they make decisions and move
4. Injuries resolve, game-over checks happen
5. Player sees the results

During the "creatures act" phase, each creature in the game world:

1. **Updates its drives** — gets hungrier, calms down if scared, etc.
2. **Checks for stimuli** — did the player just enter the room? Was there a loud noise?
3. **Makes a decision** — "Should I flee? Hide? Search for food?"
4. **Takes an action** — moves to another room, sits quietly, etc.
5. **Sends narration** — the player sees what the creature is doing

### Drives (Needs)

Creatures have three basic needs:

| Drive | Range | What It Means | How It Grows | How It Shrinks |
|-------|-------|--------------|-------------|----------------|
| **Hunger** | 0-100 | How badly the creature needs food | +2 per turn (slowly) | Eating food (resets to 0) |
| **Fear** | 0-100 | How scared the creature is | Sudden spike when threatened | Naturally decays -5 per turn (slowly) |
| **Curiosity** | 0-100 | How interested in exploring | Variable per creature | Investigating/exploring |

**Example:** A rat starts with hunger=50. After 10 turns, hunger=70. After 20 turns, hunger=90. At hunger=100, it will take big risks to find food.

### Action Selection

Each turn, the creature evaluates: "What action gives me the best chance of surviving and meeting my needs?"

The engine scores each action:

```
score = base_action_utility
      + (hunger_weight × hunger_value)
      + (fear_weight × fear_value)
      + random_variation
```

The creature picks the action with the highest score. **This means creatures can be unpredictable** — even a cowardly rat might take a risk if hungry enough.

### Possible Actions

| Action | What It Looks Like | When It Happens |
|--------|------------------|-----------------|
| **Idle** | Creature sits or stands quietly | When calm and fed |
| **Wander** | Creature moves to another room | When curious or restless |
| **Flee** | Creature runs away as fast as possible | When very scared |
| **Hide** | Creature crouches and tries to become invisible | When scared but can't flee |
| **Approach** | Creature slowly moves toward something (food, player) | When curious or hungry |

---

## Reactions to the Player

Creatures have **reactions** — automatic responses to what the player does.

### Standard Reactions

| Event | What Happens | Example |
|-------|--|---------|
| **Player enters the room** | Creature notices the player; fear spikes | Rat's eyes lock on you; it freezes |
| **Player attacks the creature** | Creature is injured and flees in panic | Rat shrieks and bolts for the nearest exit |
| **Player makes a loud noise** (breaks object, slams door) | Creature startles and becomes cautious | Rat darts away from the disturbance |
| **Player leaves the room** | Creature relaxes; fear decays | Rat cautiously returns to grooming |
| **Player offers food** | Creature is distracted; fear decreases slightly | Rat sniffs the air, whiskers working; hunger decreases |

Reactions are **not guaranteed**. A creature's reaction depends on its personality (is it naturally aggressive? timid? curious?). Two identical-looking rats might react differently to the same situation.

---

## Sensory Interaction

Players interact with creatures through the **five senses**.

### LOOK / EXAMINE

Shows the creature's current visual appearance based on its state:

```
> look rat
A brown rat sits hunched in the corner, grooming itself with tiny pink paws.
```

In darkness (no light), LOOK fails. But you can use other senses.

### FEEL / TOUCH

The **primary sense in darkness**. Always works, even with no light.

```
> feel rat
Coarse, greasy fur over a warm, squirming body. A thick tail whips against your fingers. It bites!
```

Creatures might bite or struggle when touched — this is part of the tactile description.

### SMELL / SNIFF

Always works, always safe. Tells you about the creature's material and state.

```
> smell rat
Musty rodent — damp fur, old nesting material, and the faint ammonia of urine.
```

A dead creature smells different — blood, decay, absence of warmth.

### LISTEN / HEAR

Always works, always safe. Reveals the creature's current activity and FSM state.

```
> listen rat
Skittering claws on stone. An occasional high-pitched squeak.
```

A dead creature is silent.

### TASTE / LICK

Optional, usually unpleasant, and sometimes dangerous. (Future system: poison, disease transmission.)

```
> taste rat
You'd have to catch it first. And then you'd regret it.
```

Don't lick creatures.

---

## Creature States

Each creature cycles through FSM states based on its drives, stimuli, and random chance.

### For a Rat

| State | Description | Behavior | Senses |
|-------|-------------|----------|--------|
| **alive-idle** | Sitting or standing alert | Calm, observing; might transition to wander or flee | "Quiet breathing", "crouches near wall" |
| **alive-wander** | Moving around the room | Exploring, restless; looking for food or interesting things | "Skittering claws", "scurries along baseboard" |
| **alive-flee** | Running away in panic | Maximum fear; executing escape plan | "Frantic squeaking", "panicked darting" |
| **dead** | Lying on the floor | No movement; corpse state | "Silent", "cooling fur", "blood and musk" |

**Transitions:** A rat might go `idle → wander` (restlessness), then `wander → idle` (settled). If the player attacks, it jumps to `alive-flee` instantly.

---

## Mortality & Death

### How Creatures Die

Currently (Phase 1), creatures die when their **health reaches zero**. Planned mechanics (Phase 2+):
- Weapons deal damage based on hit location
- Poison causes gradual health loss
- Injuries degrade creature capabilities

### Permanent Death

Once dead, **a creature stays dead**. It cannot be resurrected. The corpse persists as an inanimate object in the world.

### Corpse Mechanics

A dead creature becomes a **portable object** (if small enough) with:
- Updated sensory descriptions (cold, smelly, silent)
- State = `dead` (inanimate, no autonomy)
- Accessible to pickup, dropping, and puzzle interaction

Example use: Player kills a rat, carries its corpse to trap a larger predator.

---

## Territorial Behavior (Future)

Some creatures might be **territorial** — they defend a "home room" and attack intruders. A guard dog in its master's house, for example.

Territorial creatures:
- Resist leaving their home room
- Become aggressive if the player enters their territory
- May call for help (summon allies)
- Are harder to flee from

This is a Phase 2+ mechanic. Phase 1 creatures are not territorial.

---

## Nocturnal Behavior

The game starts at **2 AM** — deep night. The day/night cycle affects creature behavior.

**Nocturnal creatures** (e.g., rats, owls):
- More active at night (2 AM - 6 AM)
- Higher wander chance and movement speed
- More aggressive or bolder in darkness

**Diurnal creatures** (future):
- More active during day (6 AM - 6 PM)
- Quieter, more cautious at night

---

## Range & Awareness

Creatures don't instantly perceive the player everywhere. They have **sensory ranges**.

### Spatial Tiers

| Creature Location | Perception Fidelity | What It Knows |
|---|---|---|
| **Same room as player** | Full | Sees/hears/smells player immediately; reacts fully |
| **Adjacent room (1 exit away)** | High | Can hear/smell if those ranges extend; reduced movement |
| **Distant (2+ exits away)** | Low | Still gets hungry/afraid, but no active narration |

**Example:** A rat with `sight_range=1, sound_range=2`:
- If the rat is in the same room, it sees you immediately
- If the rat is 1 room away, it doesn't see you, but might hear you
- If the rat is 2 rooms away, it doesn't interact; it just slowly gets hungrier

When you enter a distant creature's room, it "snaps to" full fidelity and reacts in real-time.

---

## Design Patterns

### Pattern: Distraction via Food

**Puzzle:** A territorial dog guards a doorway. You can't get past.

**Solution:** Leave food outside the dog's awareness range, then:
1. Dog's hunger grows (game tick)
2. Dog enters `alive-wander` state
3. Dog's nose leads it toward food (via `approach` action)
4. Dog is now occupied; you slip past

### Pattern: Permanent Corpses

**Puzzle:** You need a heavy weight to trigger a pressure plate.

**Solution:**
1. Kill a creature (rat, cat, etc.)
2. Drag its corpse to the pressure plate
3. Corpse is inanimate and stays put; pressure plate activates

### Pattern: Sound Distraction

**Puzzle:** Creature is in a room you need to enter, but it's hostile.

**Solution:**
1. Break a glass or slam a door in an adjacent room (loud noise → stimuli)
2. Creature's fear spikes and it flees
3. Room is empty; you proceed

### Pattern: Nocturnal Advantage

**Puzzle:** Creature is aggressive during the day.

**Solution:**
1. Wait for nightfall (time advancement)
2. Nocturnal creature becomes bolder, less cautious
3. Behavior changes; maybe it wanders away
4. Or: You use the creature's confidence against it

---

## Design Guidelines for Level Designers

### Balancing Creatures in Puzzles

- **Weak creature (low health, high fear_threshold):** Easy to scare away; good for pacing
- **Strong creature (high health, low flee_threshold):** Difficult to avoid; puzzle requires outsmarting or distraction
- **Hungry creature (high hunger decay rate):** Can be baited with food
- **Timid creature (low aggression):** Unlikely to attack; good for flavor/atmosphere
- **Aggressive creature (high aggression):** Attacks on sight; requires tactical avoidance

### Creature Placement

Place creatures in rooms via the `instances` array:

```lua
instances = {
    { id = "rat-1", type = "Rat", type_id = "{rat-guid}",
      location = "room",
      home_room = "kitchen"  -- (optional) creature prefers to stay here
    },
}
```

### Narration Quality

Each creature's sensory descriptions, state descriptions, and reactions should be **vivid and specific**. A well-written creature feels like an NPC even without dialogue:

- **on_feel:** Physical texture, temperature, resistance
- **on_smell:** Specific scents (musk, blood, earth)
- **on_listen:** Activity-specific sounds (scurrying, breathing, silence)
- **room_presence:** Visual snapshot of current action
- **Reactions:** Personality-driven flavor text

---

## Phase Roadmap

### Phase 1 (Current)
- ✅ Creature template
- ✅ Rat (first NPC)
- ✅ Autonomous behavior loop (drives, reactions, actions)
- ✅ Movement (wander, flee, approach)
- ✅ Sensory descriptions
- ✅ Permanent death & corpses

### Phase 2 (Combat Integration)
- Combat FSM integration
- Creatures can attack (melee, ranged)
- Weapon handling (creature picks up tools)
- Body-part targeting

### Phase 3 (Humanoids)
- NPC dialogue (bartering, hints)
- Complex behavior trees
- Social hierarchies (guards protect merchants)
- Named NPCs (guards, shopkeepers)

### Phase 4+ (Advanced)
- Creature spawning / despawning
- Population management
- Ecosystem (predator/prey relationships)
- Faction reputation system

---

## See Also

- **Creature Template Architecture:** `docs/architecture/objects/creature-template.md`
- **Design Directives:** `docs/design/design-directives.md`
- **NPC System Plan (Technical):** `plans/npc-system-plan.md`
- **Dwarf Fortress Design Philosophy:** External ref (for inspiration)
