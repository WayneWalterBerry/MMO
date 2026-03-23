# Bear Trap Object Design

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-25  
**Status:** DESIGN  
**Depends On:** Contact/touch hook system, injury system, trap mechanics, FSM engine  
**Audience:** Designers, Flanders (object implementation), Bart (engine), Smithers (trap system)

---

## Executive Summary

The bear trap is a **proximity-triggered injury object** that demonstrates the **contact/touch → injury pipeline**. Unlike the poison bottle (consumed → injury), the bear trap causes injury through *interaction with the object itself*—touching it, taking it, or stepping on it. The bear trap teaches three design patterns: *environmental hazards*, *contact injuries*, and *trap discovery as puzzle*.

**Key design principle:** The bear trap exists to catch players who act without observation. Unlike poison (which can be investigated safely), a trap punishes recklessness in the moment. The injury teaches: "Not everything in this world is safe to touch. Examine carefully. Feel for dangers. Listen for warnings."

---

## 1. Touch-Triggered Injury Architecture

### 1.1 The Problem Space

A bear trap creates injury on **contact**, not on consumption. This introduces a different puzzle paradigm than poison:

| Object | Trigger | Effect | Interaction |
|--------|---------|--------|---|
| **Poison Bottle** | DRINK (player action) | Injury on consumption | Can be examined safely first |
| **Bear Trap** | TOUCH / TAKE / STEP (player action) | Injury on contact | Must be discovered before touching |

**Design question:** When does the trap fire?

- **Option A (Generous):** Only when player directly TAKEs it (player must actively pick it up)
- **Option B (Moderate):** When player TAKEs it or examines it closely
- **Option C (Harsh):** When entering the room (trap fires on step)

The design uses **Option A + B hybrid**: The trap is dangerous to touch or take, but safe to observe from a distance (LOOK, SMELL). The injury fires on:
1. `take bear-trap` (player attempts to pick it up)
2. `touch bear-trap` (player attempts to handle it)
3. `step on bear-trap` (if trap is on floor and player walks over it unknowingly)

### 1.2 Visibility States

The bear trap can exist in different visibility contexts:

**Visible Trap (Obvious Hazard):**
- Trap sits openly on table or floor
- Appears in initial room description: "An old bear trap lies on the floor."
- Player can LOOK and see: "The trap's jaws are open and waiting."
- No hidden discovery; the puzzle is "should I touch it?"
- Example: Trap placed as a test in a secured room

**Hidden Trap (Discovery Puzzle):**
- Trap is buried under leaves, hidden under a rug, or obscured
- Does NOT appear in initial room description
- Trigger: Player steps on rug / searches the area / LOOKS UNDER
- Discovery: "You pull back the rug. A bear trap snaps forward, and pain erupts in your foot."
- Example: Trap placed in an outdoor area, covered by fallen leaves

**Partially Hidden Trap (Hint Phase):**
- Trap is slightly visible but not obvious
- Appears in room description: "Something metal glints under the leaves."
- Examining carefully (SEARCH, LOOK UNDER) reveals: "A bear trap is partially buried."
- Player can choose to touch it or avoid it
- Example: Trap in a dungeon passage, dirt partially covering the mechanism

### 1.3 Room-Level vs. Object-Level Triggers

**Object-level trigger (this design):**
- The trap is an object in the inventory/world
- Injury fires when player directly interacts with the object
- Verbs: TAKE, TOUCH, PICK UP, GRAB
- Handler: `on_take` or `on_touch` hook
- Example: Trap sits on a table; player reaches for it

**Room-level trigger (future variant):**
- The trap is "in the room" conceptually (not in inventory)
- Injury fires when player enters room or traverses a specific area
- Verb: IMPLIED (no verb needed)
- Handler: `on_traverse` or `on_enter` hook
- Example: Trap is buried in the floor; entering the room triggers it

**This design uses object-level**, as it creates clearer player agency: "I chose to touch it, and it hurt me."

---

## 2. FSM States & Trap Lifecycle

### 2.1 State Diagram

```
                    +----------+
                    | SET      | (Armed, dangerous)
                    +----------+
                         |
                  [on_touch / on_take]
                         |
                         v
                    +----------+
                    | TRIGGERED| (Snapped, injured player)
                    +----------+
                         |
                  [on_reset / manual intervention]
                         |
                         v
                    +----------+
                    | DISARMED | (Safe, no longer dangerous)
                    +----------+
```

### 2.2 State Descriptions & Transitions

**State 1: SET (Armed)**

```
Set Properties:
- name: "a bear trap"
- keywords: trap, bear-trap, jaws, metal trap, rusted trap, danger
- description: "A rusted bear trap with powerful spring-loaded jaws. 
               The mechanism is tense and ready. This thing could 
               maim something big."
- is_dangerous = true
- is_armed = true
- categories: { "trap", "dangerous", "hazard" }

Sensory descriptions:
- LOOK: Detailed description of the trap (coiled springs, sharp teeth, etc.)
- FEEL: "The metal is cold and unyielding. You sense the tension in 
         the mechanism. This thing is waiting to snap."
- SMELL: "Rust and old blood. This trap has a history."
- LISTEN: "A faint metallic creak as you examine it. The springs are 
          straining to open."

On-interact behavior:
- Player attempts TAKE → trap fires immediately
- Player attempts TOUCH → trap fires immediately
- On fire: Injury inflicted, trap transitions to TRIGGERED state
```

**State 2: TRIGGERED (Snapped)**

```
Triggered Properties:
- name: "a sprung bear trap"
- keywords: trap, bear-trap, jaws, snapped, broken, sprung trap
- description: "The bear trap has been violently sprung. The jaws 
               are clamped shut, and blood stains the metal. The 
               spring is now slack—the trap is exhausted."
- is_dangerous = false (already fired; immediate risk is over)
- is_armed = false
- is_sprung = true
- categories: { "trap", "evidence", "hazard" }

Sensory descriptions:
- LOOK: "The trap is in a state of violent discharge. The jaws are 
        locked together. You can see hair and blood caught between 
        the teeth."
- FEEL: "The mechanism is now slack. The spring has released its 
        energy. It won't snap again without being reset."
- SMELL: "Strong smell of blood and rust. This trap has done its job."

On-interact behavior:
- Player can TAKE sprung trap (still heavy, but no longer dangerous)
- Player can EXAMINE without injury
- Trap is "evidence" now—it can be used as proof of hazard, or reset
```

**State 3: DISARMED (Safe)**

```
Disarmed Properties:
- name: "a disarmed bear trap"
- keywords: trap, bear-trap, broken, jaws, disarmed, safe
- description: "The bear trap has been carefully disarmed. The 
               springs are neutralized, and the jaws are locked open. 
               It's now a harmless piece of metal."
- is_dangerous = false
- is_armed = false
- is_disarmed = true
- categories: { "trap", "trophy" }

Sensory descriptions:
- LOOK: "The trap is rendered safe. The springs are removed or 
        neutralized. You could carry this without fear."
- FEEL: "Completely inert. No tension. No danger."
- LISTEN: "Silent. The mechanism is dead."

On-interact behavior:
- Player can TAKE, CARRY, USE as tool or trophy
- Trap is no longer a hazard
```

### 2.3 State Transitions & Triggers

| From | To | Trigger | Preconditions | Effect |
|------|----|----|---|---|
| SET | TRIGGERED | Player TAKE / TOUCH | None | Injury inflicted, trap snaps |
| TRIGGERED | DISARMED | Player uses DISARM skill + tool | Player has lockpicking skill | Trap springs neutralized, safe |
| TRIGGERED | DISARMED | NPC/mechanism resets trap | (Future: NPC patrol) | Trap is manually reset |
| TRIGGERED | SET | Trap auto-resets | (Future: magical trap) | Trap re-arms (rare) |

### 2.4 Mutability During Transitions

**SET → TRIGGERED mutation:**

```lua
{
  name = "a sprung bear trap",
  keywords_add = "sprung, blood, clamped",
  keywords_remove = "ready",
  is_armed = false,
  is_sprung = true,
  categories = { "trap", "evidence", "hazard" },
  weight = weight,  -- Still heavy, not lighter
  on_feel = "The mechanism is now slack. The spring has released..."
}
```

**TRIGGERED → DISARMED mutation:**

```lua
{
  name = "a disarmed bear trap",
  keywords_add = "disarmed, safe, trophy",
  keywords_remove = "sprung, blood, dangerous",
  is_armed = false,
  is_disarmed = true,
  categories = { "trap", "trophy" },
  on_feel = "Completely inert. No tension. No danger."
}
```

---

## 3. Engine Hook Points & Interaction Model

### 3.1 Required Engine Events

For the bear trap to function, the engine must support these hooks:

**Contact Hooks (object-level):**
- `on_take(verb)` — Called when player attempts TAKE, GRAB, PICK UP
- `on_touch(verb)` — Called when player attempts TOUCH, HANDLE, EXAMINE CLOSELY
- `on_interact(verb)` — Fallback for general interaction

**Proximity Hooks (room-level, future):**
- `on_traverse(direction)` — Called when player enters room/area
- `on_enter(room_id)` — Called on room entry
- `on_step()` — Called when player steps on specific location

**Skill Hooks (disarmament):**
- `can_disarm(player, tool)` — Checks if player has skill + correct tool
- `on_disarm(player, tool)` — Called when player successfully disarms trap

**Trap Reset Hooks (future):**
- `on_auto_reset()` — Trap rearms itself (magical)
- `on_manual_reset(tool)` — Trap is manually re-tensioned

### 3.2 Metadata Requirements

The bear trap .lua file must declare:

```lua
{
  id = "bear-trap",
  name = "a bear trap",
  keywords = { "trap", "bear-trap", "jaws", "metal trap", "danger" },
  
  -- Trap flags
  is_trap = true,              -- Identifies as hazard
  is_armed = true,             -- Currently armed
  is_dangerous = true,         -- Can cause injury on touch
  trap_type = "spring-jaw",    -- Type of trap mechanism
  
  -- Injury properties
  trap_injury_type = "crushing",      -- Type of injury caused
  trap_damage_amount = 15,             -- Initial damage on trigger
  trap_damage_type = "bruising",       -- Accompanying injury status
  
  -- Contact hook handlers
  on_take = function(self, player)
    -- Called when player tries TAKE
    -- Checks is_armed
    -- If armed: inflict injury, transition to TRIGGERED
    -- If triggered/disarmed: allow take
    return result
  end,
  
  on_touch = function(self, player)
    -- Called when player tries TOUCH
    -- Same logic as on_take
    return result
  end,
  
  -- Disarm mechanics
  can_disarm = function(self, player, tool)
    -- Check: player has lockpicking skill?
    -- Check: tool is appropriate (thin tool, key)?
    return boolean
  end,
  
  on_disarm = function(self, player, tool)
    -- Trigger disarm animation
    -- Transition to DISARMED state
    -- Narrate success
    return true
  end,
  
  -- FSM & state tracking
  fsm = {
    initial_state = "set",
    states = { "set", "triggered", "disarmed" },
    transitions = { /* ... */ }
  },
  
  -- Sensory descriptions
  on_feel = { 
    set = "The metal is cold and unyielding. You sense tension...",
    triggered = "The mechanism is now slack...",
    disarmed = "Completely inert. No danger."
  },
  on_look = { /* ... */ },
  on_smell = { /* ... */ },
  
  -- Categories
  categories = { "trap", "dangerous", "hazard", "spring-mechanism" }
}
```

### 3.3 on_take vs. on_touch vs. on_traverse

**Key distinction:** Different trigger contexts require different hooks.

**Scenario 1: Player reaches for trap on table**
```
> take bear-trap
[Engine: on_take hook]
[Hook checks: is_armed == true]
[Yes → inflict injury]
[Trap transitions: set → triggered]
```

**Scenario 2: Player carefully examines trap**
```
> touch bear-trap
[Engine: on_touch hook]
[Hook checks: is_armed == true]
[Yes → inflict injury]
[Trap transitions: set → triggered]
```

**Scenario 3: Player enters room with hidden trap (future)**
```
> go north
[Engine: on_traverse hook for room]
[Hook checks: trap exists in room AND is hidden]
[Player doesn't see it: inflict injury]
[Narration: "SNAP! Your foot catches something..."]
[Trap transitions: set → triggered]
```

**This design uses on_take / on_touch only.** Room-level on_traverse triggers are future work (for hidden floor traps).

---

## 4. Player Experience & Discovery Narrative

### 4.1 Visible Trap (No Discovery Puzzle)

**Player enters room with visible trap:**

```
> look
"The room is sparse. An old bear trap lies on the floor, its jaws 
open and waiting. Rust flakes from the metal."

> examine trap
"A rusted bear trap, built for something large. The spring mechanism 
is tense and coiled. You can see the trap is armed and ready. This 
thing would break bones."

> feel trap
"You touch the trap carefully. The metal is cold. You sense the 
pressure in the springs—they're straining to snap shut. This trap 
could maim something big. Touching it further seems... unwise."
```

**Player chooses to interact:**

```
> take bear-trap
"You reach for the trap. The moment your fingers touch the mechanism, 
the jaws snap SHUT with a violent CRACK! Pain shoots through your 
hand as the trap crushes it.

You scream. The trap is clamped tight, and you can't open it. Blood 
drips from between the jaws."
```

**The injury:**

```
[Injury applied: "crushed hand" (bruising + bleeding)]

Damage: -15 health (immediate)
Ticking: -2 health/turn (from bleeding component)
Duration: 12 turns (until bleeding stops)

Sensory: "Your hand is trapped inside the jaws of the bear trap. 
The pain is blinding. You need to get it out, and you need to 
bandage the bleeding."
```

### 4.2 Hidden Trap (Discovery Puzzle)

**Player enters room with hidden trap (not yet visible):**

```
> look
"You're in a forest clearing. Leaves cover the ground. In the center 
of the clearing, something metal glints beneath fallen leaves."

> examine leaves
"Dead leaves, scattered and brown. Beneath them, you catch a glimpse 
of something metal—a mechanism? A trap?"

> look under leaves
"You pull back the leaves and freeze. Half-buried in the dirt is an 
old bear trap. The jaws are open and ready. Someone left this here 
as a barrier—or a warning."

> touch bear-trap
"You reach toward the trap cautiously. The moment your fingers 
brush the metal, the springs release. The jaws SNAP shut with a 
sickening CRACK!"

[Injury applied]
```

**Why this matters:** The hidden trap is a **discovery moment**. The player realizes: "Not everything obvious is safe. Some dangers are hidden. I need to be careful."

### 4.3 Near-Miss Detection

A player with good sensory awareness could detect the trap before triggering it:

```
> smell trap
"A strong smell of rust and old blood. This trap has a history. 
Something died here."

> listen
"A faint metallic creak as the wind catches the trap. The springs 
are under pressure. This thing is ready to snap."

> feel (without taking)
"The mechanism is tense. You can almost feel the energy coiled in 
the springs. This trap is a predator waiting for prey."
```

**Design principle:** Observation is safe. Interaction is risky. A careful player can avoid the trap by investigating first.

### 4.4 After the Trap Fires

**Player is injured and trapped:**

```
[After trap fires]

"Your hand is caught in the jaws of the bear trap. The pain is 
intense, and the trap isn't opening. You need to either:
1. Get your hand out somehow
2. Disarm the trap
3. Take the injury and hope it doesn't cripple you"

> examine trap (now triggered)
"The trap has snapped. The jaws are clamped tight, and your hand is 
caught between them. You can see blood dripping. The spring is now 
slack—the trap is exhausted and won't snap again. But your hand... 
your hand is in trouble."

> pull hand out (with strength check)
"You yank your hand free. The jaws scrape across your skin. More 
blood. You get free, but the damage is done."

[Follow-up: bleeding wound that needs bandaging]
```

### 4.5 Disarming the Trap

If the player has the lockpicking skill and correct tool:

```
> disarm trap (with thin tool)
"You carefully examine the trap's spring mechanism. You find the 
release point—a small pin that holds the tension. You insert the 
tool and gently pry the pin.

The springs give. The jaws go slack. The trap is disarmed.

The trap is now safe to handle."

[Trap transitions: triggered → disarmed]
```

---

## 5. Injury Type: Crushing Damage

### 5.1 Injury Properties

The bear trap inflicts **crushing damage** — a specific injury class:

```
Injury Type: crushing
- Cause: Trap jaws crushing body part
- Initial Damage: -15 health
- Over-time Component: -2 health/turn (bleeding from crushed flesh)
- Severity: Medium (not lethal if treated, but painful)
- Treatment: Bandages + cleaning (similar to minor bleeding)
- Duration: 12 turns (if untreated)
```

### 5.2 Crushing vs. Other Injuries

| Injury | Cause | Initial | DoT | Duration | Treatment |
|--------|-------|---------|-----|----------|---|
| Crushing (trap) | Bear trap jaw | -15 | -2/turn | 12 | Bandages |
| Bleeding (cut) | Sharp blade | -5 | -1/turn | 20+ | Bandages |
| Bruising (blunt) | Punch, fall | -5 | None | Self-heals | Rest |
| Burning (heat) | Fire, hot object | -8 | -1/turn | 8 | Cold water |
| Poisoning (venom) | Dart trap | -10 | -3/turn | 8 | Specific antidote |

**Crushing is distinct because:** It combines immediate blunt damage with bleeding from crushed tissue. It's painful but not as lethal as poison.

### 5.3 Symptom Progression

| Turn | Damage | Narrative |
|------|--------|---|
| 0 | -15 | "Your hand is crushed in the trap. The pain is blinding." |
| 1 | -2 | "Blood soaks through the crushed flesh. You need to bandage this." |
| 3 | -2 | "The wound isn't getting worse, but the pain isn't stopping." |
| 6 | -2 | "Swelling increases. Your fingers are going numb." |
| 10 | -2 | "If you don't bandage this soon, infection might set in." |
| 12+ | Stops | Wound stops bleeding; bruising remains (self-heals) |

---

## 6. Disarmament Mechanics & Skill Integration

### 6.1 Trap Disarming Flow

**Scenario: Player catches their hand in the trap**

```
> disarm trap (player doesn't have skill yet)
"You try to decipher the trap mechanism, but you don't know what 
you're looking for. The springs are too complex. You can't disarm it 
without proper knowledge."

→ Command fails, trap remains triggered, player remains injured
```

**Later: Player learns lockpicking skill (from scroll in cellar)**

```
> disarm trap (with thin tool: lockpick, dagger, needle)
"You examine the trap mechanism carefully. You've learned the 
principles of springs and tension from the medical scroll. You find 
the release pin holding the spring coiled.

With a careful twist of your lockpick, you manipulate the pin. The 
tension releases. The jaws go slack.

The trap is disarmed."

→ Trap transitions to disarmed state, danger is over, player is free
```

### 6.2 Required Tools

Disarming requires:
1. **Lockpicking skill** (binary: have it or don't)
2. **Correct tool** (thin, rigid object):
   - Lockpick ✓
   - Dagger / knife ✓
   - Needle ✓
   - Thick rope ✗
   - Bare hands ✗

**Mechanic:** Hook checks `player.has_skill("lockpicking")` AND `tool in ["lockpick", "dagger", "needle", ...]`

### 6.3 Skill Discovery & Progression

Lockpicking skill is discovered in the Medical Scroll (cellar):

```
[Medical Scroll excerpt]

"Understanding the mechanisms of traps requires the same patience 
as understanding the mechanisms of the body. Both are systems of 
tension and release. A trapped animal is no different from a trapped 
limb—you must understand the spring to set it free.

Basic trap disarming requires a thin tool (pin, needle, dagger) and 
knowledge of the release mechanism. The spring holds tension. Find 
where it connects to the jaws. Gentle pressure on the connection 
point will release the trap safely."

[Player gains: Lockpicking Skill (binary)]
```

---

## 7. Engine Hook Categories: Comprehensive Taxonomy

### 7.1 Consumption Hooks (Poison Bottle Pattern)

Triggered when player **consumes/ingests** an object:

```
Hook Category: Consumption
Verbs: DRINK, SIP, GULP, TASTE, EAT, CONSUME
on_consume(verb, severity) {
  -- For poisons, potions, food
  -- Passes to injury system
  -- Example: Poison bottle → poisoned injury
}

on_drink() {
  -- Specific to liquids
  -- Variant of on_consume
}

on_eat() {
  -- Specific to solids
  -- Variant of on_consume
}

on_taste() {
  -- Lower severity than on_consume
  -- Safe investigation (teaches caution)
  -- Example: Sip poison → warning, not death
}
```

**Use cases:**
- Poison bottles (any poison)
- Spoiled food
- Contaminated water
- Healing potions
- Magical draughts
- Herbal remedies

---

### 7.2 Contact Hooks (Bear Trap Pattern)

Triggered when player **physically touches/takes** an object:

```
Hook Category: Contact
Verbs: TAKE, GRAB, PICK UP, TOUCH, HANDLE, GRASP
on_take(verb) {
  -- For traps, hot objects, sharp edges
  -- Passes to injury system
  -- Example: Bear trap → crushing injury
}

on_touch(verb) {
  -- For careful examination
  -- Can trigger injury or just warning
  -- Example: Hot poker → minor burn warning
}

on_interact(verb) {
  -- Fallback for general interaction
}
```

**Use cases:**
- Bear traps
- Hot objects (stove, fire)
- Sharp edges (broken glass, blades)
- Electrical hazards (future)
- Venomous creatures (future)

---

### 7.3 Proximity Hooks (Room-Level Hazards)

Triggered when player **enters room or traverses area**:

```
Hook Category: Proximity
Verbs: IMPLIED (no verb, automatic on traversal)
on_traverse(direction) {
  -- For floor traps, environmental hazards
  -- Triggered on room entry
  -- Example: Hidden pit → crushing injury on step
}

on_enter(room_id) {
  -- Fired when player enters specific room
  -- Can check room layout, objects, state
  -- Example: Gas room → poison injury
}

on_step(location) {
  -- Fired when player steps on specific location
  -- More granular than on_enter
  -- Example: Pressure plate → trap fires
}
```

**Use cases:**
- Floor traps (hidden bear traps, pits)
- Gas rooms (poison cloud)
- Environmental hazards (collapsing ceiling)
- Pressure plates
- Cursed areas

---

### 7.4 Duration Hooks (Ongoing Effects)

Triggered each turn while injury is **active**:

```
Hook Category: Duration
Verbs: IMPLIED (game loop timer)
on_tick(turn_count) {
  -- Called once per turn for active injuries
  -- Applies damage, updates symptom text
  -- Example: Poison → -1 health per turn, symptoms worsen
}

on_worsening(severity_change) {
  -- Called when injury severity increases
  -- Example: Wound becomes infected, DoT increases
}

on_healing(amount) {
  -- Called when injury healing is applied
  -- Example: Bandage stops bleeding, reduces DoT
}
```

**Use cases:**
- Bleeding (ongoing until bandaged)
- Poisoning (ongoing until antidote)
- Burning (ongoing until cooled)
- Infections (ongoing until treated)
- Regeneration effects

---

### 7.5 Complete Hook Taxonomy

```
INJURY-CAUSING HOOK CATEGORIES
│
├─ CONSUMPTION (Poison Bottle)
│  ├─ on_consume(verb, severity)
│  ├─ on_drink()
│  ├─ on_eat()
│  └─ on_taste()
│
├─ CONTACT (Bear Trap)
│  ├─ on_take(verb)
│  ├─ on_touch(verb)
│  └─ on_interact(verb)
│
├─ PROXIMITY (Future: Room Hazards)
│  ├─ on_traverse(direction)
│  ├─ on_enter(room_id)
│  └─ on_step(location)
│
└─ DURATION (Ongoing)
   ├─ on_tick(turn_count)
   ├─ on_worsening(severity)
   └─ on_healing(amount)
```

### 7.6 Verb-to-Hook Resolution

| Verb | Object Category | Hook Called | Result |
|------|---|---|---|
| TAKE | poison-bottle | on_consume (if open) | Injury if conditions met |
| DRINK | poison-bottle | on_drink / on_consume | Injury inflicted |
| TASTE | poison-bottle | on_taste | Warning, no injury |
| TAKE | bear-trap | on_take | Injury if armed |
| TOUCH | bear-trap | on_touch | Injury if armed |
| STEP (implied) | floor-trap | on_traverse | Injury if hidden |
| GO (move) | gas-room | on_enter | Injury ongoing each turn |

---

## 8. Design Patterns & Reusability

### 8.1 Trap Patterns

This bear trap design establishes three reusable patterns:

**Pattern 1: Spring-loaded trap (immediate trigger)**
- Use for: Bear traps, rat traps, snap traps
- Hook: `on_take` / `on_touch` → immediate injury
- Example: Bear trap (this design)

**Pattern 2: Hidden proximity trap (discovery-first)**
- Use for: Floor traps, pit traps, pressure plates
- Hook: `on_traverse` → injury on room entry
- Future: Hidden pit in cellar floor

**Pattern 3: Environmental hazard trap (passive danger)**
- Use for: Gas rooms, lava, poison cloud
- Hook: `on_tick` while in room → ongoing damage
- Future: Noxious gas cellar

### 8.2 Injury Pattern Reuse

The crushing injury from the bear trap parallels:

- **Bleeding:** Bladed weapon (cutting)
- **Burning:** Heat source (fire)
- **Poisoning:** Toxic substance (ingestion)
- **Bruising:** Blunt force (impact)

All follow the same **injury system architecture**: initial damage + optional over-time + treatment options.

### 8.3 FSM State Reuse

The bear trap's FSM (`set → triggered → disarmed`) mirrors:

- **Light source:** unlit → lit → burnt-out
- **Door:** closed → open → broken
- **Wound:** fresh → infected → healed

The mutation pattern (name update, categories shift, danger level changes) is consistent.

---

## 9. Testing & Validation Checklist

### Safe Path Testing
- [ ] Player can examine armed trap from distance (safe, no injury)
- [ ] Player can read trap description without triggering
- [ ] Player can FEEL trap without injury (if armed but not touched)
- [ ] Player can SMELL trap without injury
- [ ] Examine shows correct state description (armed vs. triggered)

### Trigger Testing
- [ ] Player TAKEs armed trap → injury inflicted
- [ ] Player TOUCHEs armed trap → injury inflicted
- [ ] Trap transitions to TRIGGERED state
- [ ] Player receives "crushing" injury (or appropriate type)
- [ ] Injury begins ticking (if applicable)
- [ ] Player can use "injuries" verb to diagnose

### Triggered State Testing
- [ ] Sprung trap shows updated description ("snapped", "blood")
- [ ] Player can now TAKE sprung trap (dangerous phase over)
- [ ] Trap is no longer marked as armed
- [ ] Trap shows evidence of firing (blood, clamped jaws)

### Disarming Testing
- [ ] Player without lockpicking skill cannot disarm
- [ ] Player with lockpicking skill + correct tool can disarm
- [ ] Disarming requires appropriate tool (thin object)
- [ ] Disarming transitions trap to DISARMED state
- [ ] Disarmed trap is safe to carry and handle
- [ ] Disarmed trap shows updated description ("safe", "inert")

### Injury Testing
- [ ] Crushing injury has correct initial damage (-15)
- [ ] Crushing injury ticks correctly (-2/turn if still bleeding)
- [ ] Injury stops ticking after 12 turns (standard duration)
- [ ] Bandaging stops ticking (treatment works)
- [ ] Symptom text updates each turn
- [ ] Death message appears if untreated long enough

### Edge Cases
- [ ] Multiple traps in room (each fires independently)
- [ ] Trap respawns / resets (if future magic mechanic)
- [ ] NPC triggers trap (if applicable)
- [ ] Player in inventory with armed trap (shouldn't be able to carry)
- [ ] Disarmed trap can be picked up freely
- [ ] Hidden trap detection via SEARCH / LOOK UNDER

---

## 10. Future Extensions

### 10.1 Trap Variants

Different traps could exist in later levels:

- **Level 1:** Bear trap (teaching contact hazards)
- **Level 2:** Pit trap (room-level trigger, falling damage)
- **Level 2:** Caltrops (field hazard, stepping injury)
- **Level 3:** Poison dart trap (contact + poison combination)
- **Level 3:** Pressure plate (automatic trigger, no escape)
- **Level 4:** Magical trap (resets itself, on_auto_reset hook)

### 10.2 Trap Combinations

Traps could work together for puzzle complexity:

- **Chained traps:** One trap leads to another
- **Timed traps:** Trap resets every N turns (must hurry through)
- **Conditional traps:** Trap only triggers if condition met (weight > 20 lbs)
- **Alarmed traps:** Trap triggers NPC patrol or alarm

### 10.3 NPC-Aware Traps

In multiplayer or AI scenarios:

- NPCs can be injured by traps (same system as player)
- NPCs avoid known traps (if they've seen one before)
- NPCs disarm traps (if they have skill)
- NPCs trigger traps as alarm for player

### 10.4 Environmental Trap Rooms

Room-level hazards using the same injury system:

- **Gas chamber:** `on_enter` → poison injury each turn
- **Collapsing ceiling:** `on_traverse` → crushing injury
- **Lava floor:** `on_tick` → burning injury while in room
- **Cursed zone:** `on_enter` → status effect (cursed, reduces healing)

---

## 11. Design Decisions & Rationale

### Decision 1: Why Contact Trigger Instead of Room-Level?

**Question:** Why does the trap fire on TAKE/TOUCH instead of room entry?

**Answer:** **Player agency and fairness**. A contact trigger means the player made a choice to touch the object. A room-level trigger punishes exploration without warning. For Level 1, contact is better pedagogically: "I touched it, I got hurt, I learned."

Room-level triggers come later, when the player understands traps conceptually.

### Decision 2: Why Disarmable?

**Question:** Why let the player disarm the trap instead of being stuck with the injury?

**Answer:** **Skill integration**. Lockpicking skill has no puzzle in Level 1 (matchbox is already solved). Trap disarming gives the skill a narrative use. It teaches: "Skills aren't just for locks; they solve physical problems too."

### Decision 3: Why Crushing, Not Slashing?

**Question:** Why does a bear trap cause "crushing" instead of "laceration/bleeding"?

**Answer:** **Mechanical authenticity**. A bear trap's jaws crush bones and muscle—not cut. Crushing damage is distinct from blade wounds. This teaches: "Different tools cause different injuries. Treatment matters."

### Decision 4: Why Is It Visible?

**Question:** Why not hide the trap completely as a discovery puzzle?

**Answer:** **Pedagogical layering**. The visible trap teaches: "Some hazards are announced. Observation prevents injury." Hidden traps come later (Level 2), teaching: "Some dangers are concealed. Extra caution required."

---

## Cross-References

- **Injury System Design:** `docs/design/player/health-system.md` — How injuries aggregate
- **Injury Catalog:** `docs/design/player/injury-catalog.md` — Injury types (crushing, bleeding, etc.)
- **FSM Lifecycle:** `docs/design/fsm-object-lifecycle.md` — State machine implementation
- **Verb System:** `docs/design/verb-system.md` — How TAKE, TOUCH, DISARM verbs resolve
- **Skills System:** `docs/design/player-skills.md` — Lockpicking skill mechanics
- **Puzzle Integration:** `docs/design/injuries/puzzle-integration.md` — How traps fit in puzzles
- **Contact Objects:** (future) Objects that harm on touch (hot stove, sharp edges)
- **Object Design Patterns:** `docs/design/object-design-patterns.md` — Reusable patterns
- **Poison Bottle Design:** `docs/design/objects/poison-bottle.md` — Parallel consumption-trigger design
