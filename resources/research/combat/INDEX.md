# Combat Research — Master Synthesis (INDEX)

**Author:** Frink (Research Scientist)
**Date:** 2026-03-25
**Scope:** Cross-reference all 5 combat research streams. Synthesize patterns, identify what's unique to text IF, and make concrete recommendations for the MMO engine.

---

## Research Sources

| File | Domain | Key Contribution |
|------|--------|-----------------|
| [mud-combat.md](mud-combat.md) | MUD Combat Systems | Verb-based interface, unified combatant model, flee mechanics |
| [competitive-games.md](competitive-games.md) | Competitive Game Combat | Systemic interaction, transparent rules, perceived fairness |
| [board-games.md](board-games.md) | Board Game Combat | Elegant resolution without computers, resource depletion, hit locations |
| [mtg-combat.md](mtg-combat.md) | Magic: The Gathering | Keyword-based emergent complexity, structured decision points, multiplayer targeting |
| [dwarf-fortress.md](dwarf-fortress.md) | Dwarf Fortress (CRITICAL) | Material-physics combat, body part hierarchy, generated narration, NPC-vs-NPC |

---

## 1. Universal Patterns Across ALL Combat Systems

### Pattern 1: Attack-Defense Interaction (All 5 Sources)
Every system models defense as an active property, not passive HP deduction. MUDs have armor reducing damage. XCOM has cover. Board games have defense dice and armor thresholds. MTG has toughness and blocking. DF has layered tissue resistance. **Implication:** Our combat must have meaningful armor/defense that changes outcomes, not just HP padding.

### Pattern 2: Meaningful Per-Turn Decisions (All 5 Sources)
No successful system automates combat entirely. Even DF (which automates dwarf combat) is criticized for lacking player agency. Every good combat system asks the player "what do you do?" each turn with no obviously correct answer. **Implication:** Every combat turn must present a genuine choice — attack, defend, use item, reposition, flee — with tradeoffs.

### Pattern 3: Bounded Randomness or Determinism (4 of 5 Sources)
Gloomhaven's modifier deck, Arkham's chaos bag, DCSS's careful probability tuning, Into the Breach's zero randomness, DF's material-deterministic outcomes. Pure unbounded dice rolling appears in NONE of the best systems. **Implication:** If we use randomness, it must be constrained and explicable. Material-deterministic outcomes (steel cuts flesh) may be the best fit.

### Pattern 4: Resource Depletion as Timer (4 of 5 Sources)
Gloomhaven's card exhaustion, Mage Knight's hand management, MUD spell slots, our existing consumable light sources. Combat must not last forever. **Implication:** Weapon durability, stamina, or consumable supplies should create natural time pressure.

### Pattern 5: Combat Generates Narrative (3 of 5 Sources)
DF's combat log, Kingdom Death's hit location cards, MTG's keyword interactions — the best systems produce stories, not just outcomes. **Implication:** Our combat resolution should generate unique, readable text for every exchange, not repetitive "you hit the rat for 2 damage."

### Pattern 6: Unified Combatant Interface (2 of 5 Sources, Both Critical)
MUDs and DF both use the exact same combat system for player-vs-NPC and NPC-vs-NPC. The engine doesn't distinguish. **Implication:** This is non-negotiable for our game. One combat resolution function for all combatants.

---

## 2. What's Unique to Text-Based Games

### Advantages of Text IF Combat
1. **Unlimited description bandwidth.** A graphical game shows a sprite swinging a sword. Text can describe the sound of metal on bone, the spray of blood, the rat's squeal, the vibration in your grip. Text combat can be MORE visceral than graphical combat.
2. **Environmental interaction is cheap.** "Push the barrel at the rat" costs the same to implement as "attack rat" — both are verb-noun commands resolved through the same parser. In graphical games, environmental interactions require expensive animation work.
3. **Implicit pacing.** Reading takes time. A 3-sentence combat round naturally takes 5-10 seconds to read, creating dramatic pacing without explicit timers.
4. **Physical reasoning.** Players can attempt ANYTHING: "wrap my cloak around the rat," "throw sand in its eyes," "slam the door on it." The text parser can evaluate creative solutions that graphical games can't represent.

### Challenges of Text IF Combat
1. **No spatial visualization.** Players can't see positioning. Combat descriptions must convey spatial relationships through prose: "the rat circles behind you," "you're backed against the wall."
2. **Input latency.** Typing is slower than clicking. Combat can't require rapid-fire decisions. Turn-based with deliberate pacing is mandatory.
3. **State tracking is invisible.** Players can't glance at HP bars. Combat state must be communicated through narrative cues: "blood streams from your forearm" (injured arm), "the rat limps on three legs" (damaged limb).
4. **Repetition is death.** In graphical games, repeating the same attack looks different each time (animation variance). In text, "You swing. You hit the rat." repeated 5 times is unbearable. Narration must vary.

---

## 3. Recommendations for Our MMO Engine

### What We Already Have

| Existing System | Combat Application |
|-----------------|-------------------|
| **2-hand inventory** | Weapon/shield choice is strategic; limits available combat tricks |
| **17+ materials** | Foundation for material-physics damage (steel vs. leather vs. bone) |
| **FSM states/transitions** | Combat states (aggressive, defensive, fleeing, prone, grappled) |
| **Mutation system** | Damage AS code change — a broken shield becomes a different object |
| **Injury system (7 types)** | Wound outcomes for body zone hits |
| **Object containment hierarchy** | Body parts as nested objects within creatures |
| **Darkness/light system** | Combat in darkness = can't see target, rely on sound/feel |
| **Sensory system** | Combat narration through multiple senses (sight, sound, feel, smell) |

### What We Need to Build

#### 3.1 Unified Combatant Interface
**Priority: P0 (foundational)**

Every creature (including the player) must expose the same combat interface:
```
- attack(target, weapon) → attack result
- defend(attack) → defense result
- take_damage(result) → injury/mutation
- flee(direction) → success/failure
- get_morale() → current willingness to fight
```

This is metadata on the creature object (Principle 8). The engine resolves combat by calling these interfaces on both participants. The player's `defend()` presents choices to the human; an NPC's `defend()` uses its AI personality.

#### 3.2 Material-Based Damage Resolution
**Priority: P0 (core mechanic)**

Extend our material registry with combat properties:
- `shear_resistance` — resistance to cutting/slashing
- `impact_resistance` — resistance to blunt force
- `density` — mass for momentum calculation
- `max_edge` — sharpness potential for edged weapons

Damage calculation: `weapon material properties × weapon type × force` vs. `armor material properties + tissue properties`. Result is a severity level (miss / deflect / graze / hit / critical) that maps to an injury type.

#### 3.3 Body Zone System (Simplified DF)
**Priority: P1 (Phase 1 can use simple version)**

Phase 1 creatures need 3-5 body zones:
- **Rat**: head, body, tail, legs
- **Player**: head, torso, arms, legs

Each zone has: size weight (for hit probability), armor coverage, and injury consequence. A hit to the rat's head with sufficient force = kill. A hit to the rat's tail = it escapes but is wounded. A rat bite to the player's hand = possible weapon drop.

#### 3.4 Combat Turn Structure (MTG-Inspired)
**Priority: P0 (interaction model)**

Adapt MTG's structured decision points for text IF:

```
1. INITIATIVE: determine turn order (speed-based, size-based)
2. ATTACKER'S ACTION: creature declares intent (attack, grapple, flee, use ability)
3. DEFENDER'S RESPONSE: defender reacts (block, dodge, counterattack, flee, use item)
4. RESOLUTION: material comparison → severity → body zone → injury/mutation
5. NARRATION: generate text from structured result
6. STATE UPDATE: apply injuries, check morale, check death, trigger mutations
```

The player always gets a response choice (Step 3), even on the enemy's turn. This ensures agency in every exchange.

#### 3.5 Creature Combat Metadata
**Priority: P0 (Principle 8)**

Creatures declare their combat profile as metadata:
```lua
combat = {
    size = "tiny",                    -- affects hit probability, damage scaling
    speed = 8,                        -- initiative modifier
    natural_weapons = {
        { type = "bite", material = "tooth_enamel", zone = "head",
          damage_type = "pierce", force = 2 },
        { type = "claw", material = "keratin", zone = "legs",
          damage_type = "slash", force = 1 },
    },
    armor = {},                       -- natural armor (scales, shell, thick hide)
    body_zones = {
        { id = "head", size = 1, vital = true },
        { id = "body", size = 3, vital = true },
        { id = "tail", size = 1, vital = false },
        { id = "legs", size = 2, vital = false },
    },
    behavior = {
        aggression = "on_provoke",    -- attacks when player attacks first
        flee_threshold = 0.3,         -- flees at 30% health
        prey = {},                    -- doesn't hunt
        predator_of = {},             -- nothing preys on it (player is predator)
    },
}
```

The engine resolves combat using ONLY this metadata. No rat-specific code in the engine (Principle 8).

#### 3.6 NPC-vs-NPC and Predator-Prey
**Priority: P1 (Phase 2)**

With unified combatant interface + creature combat metadata:
- **Predator-prey triggers**: when a cat object and rat object are in the same room, check `cat.combat.behavior.predator_of` — if it includes "rat", initiate combat automatically.
- **Resolution**: same combat function. Cat's claws (keratin) vs. rat's hide (skin). Cat wins because it's bigger, faster, and has sharper natural weapons.
- **Player witnesses**: if the player is in the room, they see/hear the combat through the narration system. In darkness, they hear it. With light, they see it.

#### 3.7 Defensive Reactions
**Priority: P0 (player agency)**

The player's response to an attack should be a genuine choice:
1. **Block** (requires shield/armor in hand): reduce damage by shield material properties
2. **Dodge** (always available): chance based on player agility vs. attacker speed; costs next attack action
3. **Counterattack** (requires weapon in hand): trade taking the hit for a simultaneous attack
4. **Use item** (requires item in hand): throw flask, use potion, deploy tool
5. **Flee** (always available): attempt to leave the room; may fail; costs defensive stance

Each choice has tradeoffs. No always-correct answer.

---

## 4. Minimum Viable Combat — Phase Roadmap

### Phase 1: Rat Combat (Minimum Viable)
**Goal:** Player can fight a single rat using held weapons.

Requirements:
- [ ] Unified combat resolution function
- [ ] Material comparison (weapon material vs. rat tissue)
- [ ] Simple body zones (3-4 per creature)
- [ ] Player response choices (attack/dodge/flee)
- [ ] Template-based combat narration (DF-style)
- [ ] Injury/mutation on damage (rat dies = mutation to "dead-rat")
- [ ] Flee mechanic (both player and rat)
- [ ] Combat in darkness (can hear but not see; reduced accuracy)

**Excluded from Phase 1:** Multiple combatants, NPC-vs-NPC, grappling, morale system, creature AI beyond simple aggression.

### Phase 2: Creature Ecosystem
**Goal:** Multiple creature types with NPC-vs-NPC predator-prey combat.

Requirements:
- [ ] NPC-vs-NPC combat using unified interface
- [ ] Predator-prey trigger system
- [ ] Creature combat AI (aggression types, flee thresholds)
- [ ] Multiple simultaneous combatants
- [ ] Morale system (fear, berserk, flee)
- [ ] Combat witness narration (player sees/hears NPC fights)
- [ ] Pack behavior (multiple rats, wolves)

### Phase 3: Advanced Combat
**Goal:** Full DF-inspired combat with grappling, complex wounds, and environmental interaction.

Requirements:
- [ ] Wrestling/grappling system (grab → lock → throw)
- [ ] Environmental combat verbs (push, throw objects, slam doors)
- [ ] Wound severity progression (scratch → cut → gash → severed)
- [ ] Psychological effects (fear, nausea, shock)
- [ ] Size asymmetry (tiny vs. huge creatures)
- [ ] Weapon degradation through combat use
- [ ] Armor damage and penetration

---

## 5. Key Design Decisions for the Team

### Decision 1: Deterministic or Probabilistic?
**Recommendation: Primarily deterministic with bounded variance.**

Steel cuts flesh. Always. The question is HOW MUCH damage, not WHETHER damage occurs. Variance comes from hit location (random, weighted by zone size) and attack quality (player choice affects effectiveness). This matches DF's approach and avoids the "whiff problem" where repeated misses kill pacing in text.

### Decision 2: How Much DF Detail?
**Recommendation: DF's philosophy, not its granularity.**

We adopt DF's principles (material physics, body zones, generated narration, unified combatants) but at much lower resolution. 4-6 body zones instead of 200 parts. 3 tissue layers instead of 15. 5-8 material combat properties instead of 30. The system should be EXTENSIBLE to more detail later, but Phase 1 should be playable with minimal creature data.

### Decision 3: Turn Structure?
**Recommendation: MTG-inspired exchange rounds.**

Each combat "round" is one exchange: attacker acts → defender responds → resolve → narrate. This creates a natural 3-beat rhythm per round that reads well in text. The player always has a response choice, maintaining agency. Turn order between combatants is speed-based (fast creatures act first).

### Decision 4: How Do Creatures Declare Combat Data?
**Recommendation: Inline metadata in creature object files (Principle 8).**

Creature `.lua` files include a `combat` table with natural weapons, body zones, armor, behavior, and AI personality. The engine reads this metadata and resolves combat generically. No creature-specific combat code in the engine. This is exactly how our existing FSM, mutation, and sensory systems work — combat is just another metadata-driven behavior.

---

## 6. Open Questions for Further Research

1. **Weapon type effectiveness matrix**: should swords be better against unarmored targets and maces better against armored? DF says yes. How granular should our weapon types be?
2. **Combat in water/cramped spaces**: how do environmental constraints modify combat? DF models this through material wetness and space restrictions.
3. **Poison delivery**: our existing poison system (taste-based) — how does it integrate with combat? Poison weapons? Venomous bites?
4. **Sound as combat telegraph**: in darkness, the player hears combat sounds. How specific? "You hear scrabbling claws" vs. "You hear something lunge at you from the left."
5. **Multi-room combat**: can combat span room transitions? Player flees → rat follows → combat continues in new room?

---

*This research package provides the foundation for combat system design. All 5 sources converge on the same core principles: material-physical damage, structured decision points, generated narration, and unified combatant interfaces. Our existing engine architecture (materials, FSM, mutation, containment, Principle 8) is remarkably well-suited to implement DF-inspired combat. The path from "text adventure" to "combat-capable text adventure" is shorter than it appears.*
