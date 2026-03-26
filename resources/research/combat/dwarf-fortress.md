# Dwarf Fortress Combat — Research Report (CRITICAL)

**Author:** Frink (Research Scientist)
**Date:** 2026-03-25
**Scope:** Combat mechanics in Dwarf Fortress — the most physically detailed combat simulation ever created. This is our PRIMARY inspiration. Every mechanic here should be evaluated for inclusion in our engine.

---

## 1. Hit Location System — Bodies as Hierarchical Trees

Dwarf Fortress models every creature's body as a **hierarchical tree of body parts**, each with individual tissues, and each tissue with material properties.

### Body Part Hierarchy
A dwarf's body tree (simplified):

```
body (upper body / lower body)
├── head
│   ├── skull (bone)
│   ├── brain (organ, inside skull)
│   ├── left eye / right eye
│   ├── nose (cartilage)
│   ├── left ear / right ear
│   ├── mouth → teeth, tongue
│   └── throat
├── upper body (torso)
│   ├── ribcage (bone)
│   ├── heart (organ, inside ribcage)
│   ├── lungs (organ, inside ribcage)
│   ├── liver, stomach, guts (organs)
│   ├── spine (bone)
│   ├── left upper arm → left lower arm → left hand → fingers
│   └── right upper arm → right lower arm → right hand → fingers
└── lower body
    ├── left upper leg → left lower leg → left foot → toes
    └── right upper leg → right lower leg → right foot → toes
```

### How Attacks Target Body Parts
1. Attack targets the creature. A random body part is selected, weighted by **relative size** (torso is a bigger target than a finger).
2. **Armor on that body part** is checked — if the part is covered by equipment, the attack must penetrate the armor first.
3. The attack contacts the **outermost tissue layer** of the body part and works inward: skin → fat → muscle → bone → organ.
4. Each tissue layer has independent material properties (hardness, density, fracture resistance). The attack must overcome each layer to reach the next.

### What This Means
A sword strike to the arm might: slash through skin (leather-like), cut through fat (soft), damage muscle (reduces arm function), but stop at bone (dense calcium). A mace strike might: bruise skin, compress fat and muscle, and FRACTURE the bone (blunt force transfers differently than edged). The SAME body part responds differently to different damage types based on material physics.

### Translation to Our Engine
- We don't need DF's full 200+ body part trees. For Phase 1, creatures need 4-6 body zones: **head, torso, arms, legs, tail** (for creatures that have one). Each zone can have 2-3 tissue layers: **skin/hide, flesh, bone/organ**.
- Body parts as **nested objects within the creature object** aligns with our containment hierarchy. A rat IS a container of body parts, each with material properties.
- Hit location selection weighted by zone size: torso is hit most often, head rarely. This matches physical intuition.

---

## 2. Material-Based Damage — The Physics Engine

DF's combat is fundamentally a **material interaction simulation**. There are no abstract "damage points" — damage emerges from the physical interaction of weapon material, armor material, and tissue material.

### Material Properties
Every material in DF has these combat-relevant properties:
- **SHEAR_YIELD / SHEAR_FRACTURE**: resistance to cutting. Low = easily cut (flesh ~20,000). High = hard to cut (steel ~597,000).
- **IMPACT_YIELD / IMPACT_FRACTURE**: resistance to blunt force. Bone fractures at a specific threshold.
- **DENSITY**: affects momentum and force. Lead (11,340 kg/m³) delivers more blunt force than wood (500 kg/m³).
- **MAX_EDGE**: how sharp a material can be. Steel has high max edge; wood has low. Determines cutting effectiveness.
- **SOLID_DENSITY**: weight calculation for momentum. Heavier weapons hit harder.

### Damage Calculation (Simplified)
1. **Weapon momentum** = velocity × mass × material density. A steel war hammer has enormous momentum; a copper dagger has little.
2. **Contact area**: edged weapons concentrate force on a small area (high pressure); blunt weapons spread it (lower pressure, but momentum transfers through armor).
3. **Material comparison**: weapon material's SHEAR values vs. tissue/armor material's SHEAR values. If weapon exceeds tissue threshold → tissue is cut. If not → tissue bends/bruises.
4. **Layer penetration**: damage propagates through tissue layers until the force is exhausted or encounters a material it cannot overcome.

### Concrete Examples
- **Steel sword vs. unarmored dwarf**: blade's SHEAR exceeds skin, fat, and muscle thresholds → deep cut → may reach bone → if bone's IMPACT threshold exceeded → fracture.
- **Wooden club vs. armored dwarf**: wood cannot shear through iron armor → blunt force transfers through armor → bruising underneath, possible bone fracture from impact.
- **Obsidian knife vs. bronze armor**: obsidian has VERY high max edge (sharper than steel) but low fracture resistance. Cuts beautifully through soft targets; shatters against hard armor.
- **Bite (tooth material) vs. leather armor**: tooth enamel has moderate shear capability. Against thick leather, bites fail to penetrate. Against bare skin, teeth slice through easily.

### Translation to Our Engine
- Our existing **17+ material system** is the foundation. Each material needs: shear resistance, impact resistance, density. Weapons and armor declare their material; the combat engine compares.
- **Damage types emerge from physics**, not from arbitrary categories. An axe doesn't deal "slashing damage" — it deals damage proportional to its edge sharpness × momentum, resisted by the target's shear resistance. The result might be a slash (if cutting succeeds) or a bruise (if it doesn't).
- This is **Principle 9 (material consistency)** applied to combat. Steel behaves like steel everywhere in the game — crafting, combat, environmental interaction.

---

## 3. Wrestling and Grappling — Non-Weapon Combat

DF has a complete unarmed combat system based on **wrestling maneuvers** that interact with the body part system.

### Wrestling Actions
- **Grab**: seize a specific body part. "Dwarf grabs goblin by the right hand." A grabbed part can be twisted, bent, or used as leverage.
- **Lock joint**: with a grabbed limb, lock the joint to prevent use. A locked arm can't hold a weapon; a locked leg prevents standing.
- **Break**: apply force to a grabbed and locked joint → fracture the bone. "Dwarf bends the goblin's right arm — the elbow shatters!"
- **Throw**: use grabbed body part for leverage to throw the target. Thrown creatures take falling damage and end up prone. Size differential matters — a dwarf can't throw an elephant.
- **Choke**: grab throat → reduce breathing → unconsciousness → death. Requires sustained hold over multiple rounds. Armored throats (gorgets) prevent this.
- **Gouge**: attack with fingers at a specific body part — primarily used against eyes. "Dwarf gouges the goblin's left eye!" → blindness in that eye.
- **Bite**: any creature with a mouth can bite. Damage = tooth material vs. target tissue. Wolves bite hard (carnivore teeth); humans bite weakly.
- **Scratch**: clawed creatures rake targets. Cat claws vs. skin = lacerations.

### Wrestling Progression
A typical wrestling sequence:
1. Grab enemy's weapon arm
2. Lock the elbow joint (enemy drops weapon)
3. Throw enemy to ground (enemy is prone)
4. Grab throat
5. Choke until unconscious or dead

This creates a **multi-step tactical chain** where each move sets up the next. Interrupting any step (the enemy breaks free, an ally intervenes) resets the chain.

### Translation to Our Engine
- Unarmed combat as a **sequence of state transitions** maps to FSM. Each wrestling move transitions the fight's state: standing → grabbed → locked → prone.
- For Phase 1 (rats), wrestling manifests as: rat bites hand → player shakes it off, rat claws at legs → player kicks it. Simple exchanges, but using the same underlying system.
- Later creatures (wolves, NPCs) use the full chain: wolf grabs arm → drags player down → goes for throat.

---

## 4. Creature-vs-Creature — NPC Combat

This is where DF shines and is most relevant to our NPC-vs-NPC requirement. DF's combat system makes **no distinction between player-controlled and AI-controlled combatants**.

### How It Works
- Every creature has the same combat interface: attack, defend, dodge, grapple, flee.
- **AI personalities** determine behavior: aggressive creatures attack immediately; timid creatures flee when injured; territorial creatures defend their zone.
- **Predator-prey** is resolved through combat: a cat encountering a rat initiates combat automatically. The cat's size, speed, and natural weapons (claws, teeth) vs. the rat's size and speed determine the outcome. The cat almost always wins — because physically, a cat always beats a rat.
- **Pack behavior**: wolves hunt in packs. Multiple wolves coordinate: one chases, others flank. In combat, multiple wolves attack simultaneously, overwhelming the target's ability to block/dodge.
- **Flee threshold**: creatures have morale. When injured or outmatched, they attempt to flee. Flee success depends on speed, injuries (damaged legs reduce speed), and terrain (cornered creatures can't flee).

### Concrete DF Combat Scenarios
- **Cat vs. rat**: Cat pounces → grabs rat with front paws → bites rat's head → rat's skull fractures → rat dies. Total: 1-2 rounds. The cat is never in real danger.
- **Wolf pack vs. deer**: Wolf 1 chases deer → deer flees → Wolf 2 cuts off escape → Wolf 1 latches onto hindquarters → deer falls → pack finishes it. Multiple rounds, positional.
- **Two dwarves brawling**: Dwarf A throws punch → Dwarf B dodges → Dwarf B grapples → locks arm → throws Dwarf A to ground → Dwarf A yields. Extensive wrestling.
- **Giant vs. dwarf**: Giant kicks → dwarf flies across room → wall impact → broken bones → stunned → giant follows up → death. Size asymmetry is devastating.

### Translation to Our Engine
- **Unified combatant interface** is non-negotiable. The same `resolve_combat(attacker, defender)` function handles player-vs-rat, cat-vs-rat, guard-vs-thief.
- **Predator-prey as metadata**: each creature declares its prey list and aggression triggers. `{ predator_of = {"rat", "mouse"}, aggression = "on_sight" }`. The engine checks these declarations.
- **Morale/flee** as FSM state: creatures transition from `aggressive` → `wary` → `fleeing` based on damage sustained.

---

## 5. Mood and Stress During Combat

DF's stress system interacts with combat in both directions — stress affects combat performance, and combat causes stress.

### Combat → Stress
- **Witnessing death**: dwarves who see a companion die gain stress. Magnitude depends on relationship (close friend > acquaintance > stranger).
- **Being injured**: pain causes stress. Severe injuries (lost limbs) cause trauma that persists after healing.
- **Killing**: dwarves who kill sentient beings gain stress (unless they have "doesn't care about anything" personality trait). Killing animals has no stress cost.
- **Gore exposure**: seeing blood, severed limbs, or rotting corpses causes stress proportional to gore severity.

### Stress → Combat
- **High stress reduces combat effectiveness**: stressed dwarves are slower to react, less accurate, more likely to freeze.
- **Berserk state**: at extreme stress, a dwarf may "go berserk" — attacking everything nearby indiscriminately, friend and foe. This is a tantrum spiral trigger.
- **Martial training reduces combat stress**: trained soldiers are less affected by witnessing violence. Militia training serves double duty as stress inoculation.

### Translation to Our Engine
- Our injury system (7 injury types) should include **psychological injury**: fear, nausea, shock. These impair player performance temporarily.
- **Combat narration intensity** can scale with exposure: first kill gets vivid description; tenth kill gets matter-of-fact description. This simulates desensitization without stat changes.
- Player stress could affect available verbs: a panicked player might only be able to `flee`, `cower`, or `scream`, not `attack` or `examine`.

---

## 6. Size and Strength Asymmetry

DF models creature size explicitly, and **size difference dramatically affects combat**.

### Size Effects
- **Bigger creatures deal more damage**: momentum = mass × velocity. An elephant kicks with 100x the force of a cat's swipe.
- **Bigger creatures are harder to hurt**: more tissue to penetrate, thicker bones, more blood volume (can sustain more bleeding).
- **Bigger creatures are easier to hit**: larger target area. A dragon is easier to hit than a fly — but hits might not matter.
- **Small creatures have advantages**: harder to grab (grapple check scales with size differential), can fit in tight spaces (escape routes), faster reaction times.
- **Size threshold for damage**: a kitten literally cannot damage an elephant through biting — its teeth can't penetrate elephant hide, and its jaw muscles can't generate enough force.

### Real DF Examples
- **War elephant vs. goblin**: elephant kicks goblin → goblin flies 15 tiles → impacts wall → goblin is paste. One hit kill.
- **Cat vs. giant spider**: cat bites spider's leg → leg tissue is soft → leg severs → spider still has 7 legs → cat bites another → eventually spider is immobilized. Cat wins through persistence.
- **Dwarf vs. dragon**: dragon breathes fire → dwarf catches fire → dwarf's fat layer ignites → dwarf dies. Or: dwarf with dragonslaying weapon stabs dragon → weapon penetrates scales → punctures lung → dragon suffocates. Equipment overcomes size asymmetry.

### Translation to Our Engine
- Creature objects should declare a **size category** (tiny/small/medium/large/huge). Size affects: hit probability (larger = easier target), damage scaling (larger = more force), grapple checks (larger can't grapple much smaller).
- **Size threshold for damage**: a rat biting a player in plate armor literally cannot penetrate. The system should handle this gracefully: "The rat gnaws at your steel greave. Its teeth scrape uselessly."
- **Equipment as equalizer**: the player's advantage over wildlife isn't inherent strength — it's TOOLS. A naked human vs. a wolf is a losing fight. A human with a spear and shield vs. a wolf is an even fight. This reinforces the 2-hand inventory system's strategic importance.

---

## 7. Combat Log Narration — How DF Generates Text

The combat log is where DF's simulation becomes visible, and it's directly instructive for our text IF output.

### DF Combat Log Examples (Real)

```
The crossbow goblin shoots a copper bolt at the dwarf!
The copper bolt strikes the dwarf in the upper right arm, tearing the muscle and fracturing the bone!
The dwarf drops the iron short sword!

The dwarf punches the goblin in the head with her left hand, bruising the skin!
The goblin bites the dwarf in the right lower leg, tearing the skin!

The cat leaps at the rat!
The cat bites the rat in the head, tearing the brain!
The rat has been struck down!
```

### Narration Pattern
Every combat log entry follows a consistent template:
```
[Actor] [action verb] [target] in/at the [body part], [result]!
```

Components:
- **Actor**: the attacking creature
- **Action verb**: strikes, punches, kicks, bites, slashes, shoots
- **Target**: the defending creature
- **Body part**: specific location hit
- **Result**: tissue-level damage description (bruising skin, tearing muscle, fracturing bone, severing, mangling)

### Result Descriptions Scale with Severity
- Minor: "bruising the skin"
- Moderate: "tearing the muscle"
- Serious: "fracturing the bone"
- Severe: "shattering the bone and tearing the nervous tissue!"
- Fatal: "tearing the brain! The rat has been struck down!"

### Translation to Our Engine
- **Template-based combat narration** is exactly what we need. Each combat resolution generates a structured result (actor, action, target, body part, severity), which the text engine formats into prose.
- **Severity-scaled descriptions** prevent repetitive text. A light hit and a devastating hit read differently, generated from the same template with different severity parameters.
- This aligns with **Principle 6 (sensory space)**: the combat narration IS the sensory output of the combat state. The player perceives combat through text descriptions that reflect the physical reality of what's happening.
- Our materials system provides the vocabulary: "tearing leather," "fracturing bone," "denting iron," "shattering glass." Material names become combat narration words.

---

## 8. Why DF Combat Is Our Primary Model

### Alignment with Our Engine
| DF Feature | Our Equivalent | Alignment |
|------------|---------------|-----------|
| Body part tree | Object containment hierarchy | Principle 4 (composite encapsulation) |
| Material physics | 17+ material registry | Principle 9 (material consistency) |
| Tissue layers | Object nesting / mutation | Principle 1 (code-derived objects) |
| Combat log templates | Text output pipeline | Principle 6 (sensory space) |
| Unified combatant interface | Engine-executed metadata | Principle 8 (engine executes metadata) |
| State changes (severed limb) | Mutation system | D-14 (code mutation IS state change) |
| Creature AI as personality data | FSM + metadata | Principle 3 (FSM + state tracking) |

### What DF Gets Right That We Must Emulate
1. **No abstract damage points.** Damage emerges from material interaction. This is physically intuitive and creates consistent, learnable rules.
2. **Every creature uses the same system.** The combat engine doesn't know if it's processing a dragon or a kitten. Creature data drives the outcome.
3. **Combat narration is generated, not scripted.** The template + physical result produces unique descriptions for every attack, every body part, every material interaction.
4. **Size and equipment matter more than abstract stats.** A farmer with a steel war hammer is dangerous. A soldier with a wooden training sword is not.

### What DF Gets Wrong (For Our Purposes)
1. **Overwhelming detail.** DF tracks individual teeth, toenails, eyelids. We need 4-6 body zones, not 200 parts.
2. **No player agency in combat.** DF combat is mostly automated — the player watches. We need per-turn player decisions.
3. **Simulation over fun.** A DF combat log is fascinating to READ but the player doesn't PLAY it. We must add interactive decision points to the DF physical model.
