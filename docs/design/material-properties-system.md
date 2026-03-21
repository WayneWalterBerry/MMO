# Material Properties System — Design Document

**Version:** 1.0  
**Date:** 2026-07-19  
**Author:** Frink (Researcher)  
**Audience:** Game designers, content creators, narrative team  
**Status:** Research Complete — Ready for Design Review  

---

## Executive Summary

Material properties are the missing layer between our **object labels** and **emergent behavior**. Today, `material = "wax"` is a string that tells the player "this is wax" but tells the engine nothing. With numeric material properties, the engine can derive behavior from physical reality: wax melts near fire, iron rusts when wet, glass shatters when dropped. Instead of scripting every interaction, designers declare materials and the engine generates emergent consequences.

This is the single biggest upgrade path from "hand-crafted puzzle game" to "simulated world that surprises its designers."

---

## 1. What Material Properties Does Our Game Need?

### 1.1 Core Property Table

| Property | Range | What It Means | What It Enables |
|----------|-------|---------------|-----------------|
| **density** | 100–20000 (kg/m³) | How heavy per unit volume | Weight calculation, sinking/floating, heaviness descriptions |
| **melting_point** | °C or `nil` | Temperature where solid becomes liquid | Wax melts, ice melts, metal softens near extreme heat |
| **ignition_point** | °C or `nil` | Temperature where material catches fire | Wood/fabric burns, wax ignites, stone is fireproof |
| **hardness** | 1–10 (Mohs-inspired) | Resistance to scratching/deformation | Glass breaks, iron dents, wax carves easily |
| **flexibility** | 0.0–1.0 | How much it bends without breaking | Fabric drapes, iron is rigid, rope coils |
| **absorbency** | 0.0–1.0 | How much liquid it soaks up | Cloth absorbs water/blood, glass repels, paper soaks ink |
| **opacity** | 0.0–1.0 | How much light passes through | Glass is transparent, wood is opaque, thin fabric is translucent |
| **flammability** | 0.0–1.0 | How easily it catches/sustains fire | Oil ignites fast, damp wood smolders, stone won't burn |
| **conductivity** | 0.0–1.0 | Heat/electricity transfer rate | Metal conducts heat, wood insulates, wire carries current |
| **fragility** | 0.0–1.0 | Likelihood of breaking on impact | Glass shatters, iron bends, rubber bounces |
| **value** | 1–100 | Economic/trade worth multiplier | Gold is valuable, clay is cheap |

### 1.2 Extended Properties (Phase 2+)

| Property | What It Enables |
|----------|-----------------|
| **rust_susceptibility** | Iron/steel degradation when wet |
| **toxicity** | Poison interactions with food/drink/wounds |
| **magnetism** | Compass behavior, metal attraction puzzles |
| **buoyancy** | (derived from density) Floating/sinking in water |
| **thermal_mass** | How slowly it heats/cools — stone stays cold, metal heats fast |

### 1.3 Material Definitions for Our World

Based on existing objects in `src/meta/objects/`:

| Material | density | melt_pt | ignite_pt | hardness | flexibility | absorbency | flammability | fragility |
|----------|---------|---------|-----------|----------|-------------|------------|-------------|-----------|
| **wax** | 900 | 60 | 230 | 2 | 0.8 | 0.0 | 0.7 | 0.3 |
| **wood** | 600 | nil | 300 | 4 | 0.2 | 0.3 | 0.5 | 0.2 |
| **fabric** | 300 | nil | 250 | 1 | 1.0 | 0.8 | 0.6 | 0.0 |
| **wool** | 350 | nil | 300 | 1 | 0.9 | 0.6 | 0.4 | 0.0 |
| **iron** | 7870 | 1538 | nil | 8 | 0.3 | 0.0 | 0.0 | 0.1 |
| **brass** | 8500 | 930 | nil | 6 | 0.1 | 0.0 | 0.0 | 0.1 |
| **glass** | 2500 | 1400 | nil | 6 | 0.0 | 0.0 | 0.0 | 0.9 |
| **paper** | 700 | nil | 230 | 1 | 0.7 | 0.9 | 0.8 | 0.1 |
| **leather** | 850 | nil | 350 | 3 | 0.6 | 0.4 | 0.3 | 0.0 |
| **ceramic** | 2300 | 1600 | nil | 7 | 0.0 | 0.1 | 0.0 | 0.7 |
| **tallow** | 850 | 45 | 200 | 1 | 0.9 | 0.0 | 0.8 | 0.3 |
| **cotton** | 350 | nil | 250 | 1 | 1.0 | 0.9 | 0.7 | 0.0 |
| **steel** | 7850 | 1370 | nil | 9 | 0.3 | 0.0 | 0.0 | 0.05 |

---

## 2. Real-World Emergent Behaviors

### 2.1 Wax Candle Melts Near Fire

**Properties involved:** `melting_point = 60`, `flammability = 0.7`

**Scenario:** Player places an unlit candle on a surface near a lit torch.

```
> PUT CANDLE ON SHELF NEAR TORCH
You place the candle on the shelf beside the iron torch bracket.

[3 turns later...]
The candle droops. Warm air from the torch softens the wax.

[5 turns later...]
The candle has melted into a waxy puddle on the shelf. The wick 
lies coiled in a pool of liquid tallow.
```

**What happened:** The room's `ambient_temperature` near the torch exceeds the wax `melting_point`. The engine fires the threshold auto-transition from `solid` → `melted`, applying mutate fields that change description, weight, keywords, and remove the candle's ability to be lit.

**Emergent consequence:** The player can no longer light that candle. They needed it for the cellar. This creates an unscripted resource pressure.

### 2.2 Iron Key Rusts When Wet

**Properties involved:** `rust_susceptibility = 0.9`, room `wetness > 0.5`

**Scenario:** Player drops the brass key in a flooded cellar.

```
> DROP KEY
You let the brass key fall. It splashes into the ankle-deep water.

[Several turns later...]
The brass key's surface has developed a greenish patina. The teeth 
feel rougher under your fingers.

[Many turns later...]
The key is crusted with verdigris. It may not turn smoothly in a lock.
```

**What happened:** The room's `wetness` property exceeds the threshold. The material's `rust_susceptibility` triggers a degradation auto-transition. The `mutate` field progressively changes description, feel, and eventually the key's `tool_quality` — making it unreliable for locks.

**Emergent consequence:** The player learns that leaving metal objects in water degrades them. This teaches material awareness without a tutorial.

### 2.3 Cloth Absorbs Water

**Properties involved:** `absorbency = 0.8`

**Scenario:** Player uses a rag in the flooded cellar.

```
> DIP RAG IN WATER
You dip the rag into the murky water. It soaks up the liquid 
greedily, growing heavy in your hand.

> FEEL RAG
The rag is sodden and cold. Water drips from it when you lift it.

> WRING RAG
You twist the rag. A stream of water splashes to the floor. 
The rag is damp but lighter now.
```

**What happened:** The fabric's `absorbency = 0.8` allows the DIP/SOAK verb to transfer `wetness` to the object. The `mutate` field increases weight (wet fabric weighs more) and changes tactile descriptions. WRING reverses the process partially.

**Emergent consequence:** Wet cloth can be used to clean blood, dampen fire, cool a hot object, or mark a trail. None of these need explicit scripting if material properties are consistent.

### 2.4 Glass Breaks When Dropped

**Properties involved:** `fragility = 0.9`, `hardness = 6`

**Scenario:** Player drops a glass shard from height.

```
> DROP GLASS SHARD
The glass shard slips from your fingers and strikes the stone floor.
It shatters into glittering fragments too small to pick up.

[Glass shard is destroyed - transitions to terminal "shattered" state]
```

**What happened:** The glass's `fragility = 0.9` exceeds the threshold for surviving an impact with a `hardness = 8` surface (stone floor). The engine fires the "break" auto-transition. If the player had dropped it on the bed (soft surface, `hardness = 1`), it would have survived.

**Emergent consequence:** Players learn to be careful with fragile objects. Dropping them on soft surfaces is safe. This rewards spatial awareness.

### 2.5 Paper Burns Instantly Near Fire

**Properties involved:** `flammability = 0.8`, `ignition_point = 230`

**Scenario:** Player holds paper near a candle flame.

```
> HOLD PAPER OVER CANDLE
The paper catches fire immediately! Flames race across the 
page, curling the edges black.

[If player holds sewing manual near candle...]
> HOLD MANUAL NEAR CANDLE
The cover of the sewing manual darkens and smokes. You pull it 
away before it catches. (Higher thermal_mass = slower ignition)
```

**What happened:** Paper's high `flammability` and low `ignition_point` mean instant combustion. A thicker book with more thermal mass takes longer. The engine treats all of them the same — checking material properties against heat exposure.

### 2.6 Wool Cloak Smothers Fire

**Properties involved:** wool `flammability = 0.4`, `absorbency = 0.6`, thickness

**Scenario:** Player uses the wool cloak to smother a small fire.

```
> PUT CLOAK ON FIRE
You throw the heavy wool cloak over the flames. It smothers 
the fire with a hiss. Acrid smoke rises from the scorched wool.

> FEEL CLOAK
The cloak is warm and slightly singed at one corner, but intact.
```

**What happened:** Wool's relatively low `flammability` and thick mass allow it to smother small fires rather than catch fire itself. The engine checks: is the material's `flammability` low enough to suppress rather than propagate? If the player used paper (`flammability = 0.8`), it would catch fire instead.

---

## 3. How Players Experience Material Properties

### 3.1 Sensory Integration

Material properties enrich all five senses our engine supports:

| Sense | What Material Properties Add |
|-------|------------------------------|
| **LOOK** | "The brass key has a greenish tint" (rust state) / "The candle droops, soft" (near melting) |
| **FEEL** | "Cold and rigid" (iron, high density + low flexibility) / "Soft and yielding" (wax, low hardness) |
| **SMELL** | "Acrid, like burning wool" (flammability + ignition) / "Waxy, faintly sweet" (tallow properties) |
| **LISTEN** | "Clinks against stone" (hardness > 5, rigid) / "Thuds softly" (hardness < 3, flexible) |
| **TASTE** | "Metallic tang" (iron conductivity) / "Bland, slightly waxy" (tallow properties) |

**Implementation:** Sensory callbacks (`on_feel`, `on_smell`, etc.) can reference material properties to generate contextual descriptions:

```lua
on_feel = function(obj)
    local mat = materials[obj.material]
    local temp_desc = mat.conductivity > 0.5 and "cold" or "room-temperature"
    local flex_desc = mat.flexibility > 0.5 and "yields slightly" or "rigid and unyielding"
    return string.format("The %s is %s to the touch, %s under your fingers.",
        obj.name, temp_desc, flex_desc)
end
```

### 3.2 Progressive State Changes

Material properties enable **gradual degradation** instead of binary state flips:

```
Pristine → Slightly worn → Weathered → Damaged → Destroyed
```

Each stage changes descriptions, capabilities, and effectiveness. A rusting key goes from "bright brass" to "patina-stained" to "crusted with verdigris" to "crumbles in the lock." The player sees the world aging around them.

### 3.3 Player Learning Through Consistent Rules

The key design principle: **if it's true for one object, it's true for all objects of the same material.**

- All wooden objects burn near fire (shelf, nightstand, wardrobe, matchbox)
- All fabric objects absorb water (rag, cloak, curtains, bed-sheets)
- All glass objects shatter on hard surfaces (glass-shard, window, mirror)
- All iron objects rust when wet (brass-key, knife, needle, pin)

Players internalize these rules through experience. Once they learn "wood burns," they can predict that the wooden wardrobe near the fireplace is a fire risk. This is **emergent puzzle design** — the designer sets up conditions, and players discover consequences.

> **Source:** This pattern is directly inspired by Zelda: Breath of the Wild's "chemistry engine," where three simple rules about element-material interactions create an enormous emergent space. — https://gamesbeat.com/the-legend-of-zelda-breath-of-the-wild-makes-chemistry-just-as-important-as-physics/

---

## 4. Proposed Design Core Principle

### 4.1 Draft Wording

> **Design Core Principle: Material Consistency**  
> Every object in the world is made of a material. Every material has measurable physical properties. The engine treats all objects of the same material identically — wax melts whether it's a candle, a seal, or a figurine. Players learn the world by learning materials, not by memorizing object-specific rules. When a player discovers that fabric burns, they have learned something true about every fabric object they will ever encounter.

### 4.2 Design Implications

1. **No special-casing:** If wax candles melt near fire, wax seals must melt near fire too. Designers cannot make one wax object fireproof without changing its material.
2. **Teachable world:** Each material interaction taught is knowledge that transfers to all objects of that material. Players build a mental model of the world's physics.
3. **Emergent puzzles:** Designers place objects near environmental conditions and let material interactions create the puzzle. "Put a wooden shelf near a fire source" = fire risk without scripting.
4. **Predictable consequences:** If the player can predict "this will melt" or "this will break," the world feels fair. Surprising material behavior should be rare and signaled.
5. **Sensory depth multiplier:** Material properties enrich all five senses without per-object description work. A designer specifies `material = "iron"` and gets tactile coldness, metallic taste, clanking sound, and visual rust potential for free.

### 4.3 Relationship to Existing Principles

| Existing Principle | How Material Consistency Relates |
|-------------------|---------------------------------|
| P1: Code-Derived Mutable Objects | Material properties are part of the mutable object table |
| P3: Objects Have FSM | Material thresholds trigger FSM transitions |
| P6: Sensory Space | Material properties inform sensory callbacks |
| P8: Engine Executes Metadata | Material registry is metadata; engine resolves generically |
| D-14: True Code Mutation | Material state changes (rusted, melted) are full mutations |

---

## 5. Comparison with Existing Objects

### 5.1 Objects That Would Benefit Most

| Object | Current Material | What Material Properties Would Add |
|--------|-----------------|-----------------------------------|
| **candle** | (implicit wax) | Melts near fire, wax drips, burns at ignition point |
| **match** | (implicit wood+sulfur) | Wood burns, sulfur ignites at low temp, spent match is charcoal |
| **brass-key** | (implicit brass) | Conducts heat, tarnishes when wet, heavy for its size |
| **glass-shard** | `"glass"` | Shatters on impact, cuts soft materials, transparent |
| **bed-sheets** | (implicit fabric) | Absorbs blood/water, burns near fire, tears when cut |
| **wool-cloak** | (implicit wool) | Absorbs water, smothers fire, insulates from cold |
| **knife** | (implicit iron/steel) | Rusts when wet, conducts heat, holds edge based on hardness |
| **curtains** | (implicit fabric) | Burns near fire, absorbs water, light-blocking based on opacity |
| **nightstand** | (template: wood) | Burns if fire spreads, warps when wet, dents on impact |
| **wardrobe** | (template: wood) | Burns, heavy (density × size), insulates contents |
| **blanket** | (implicit wool/fabric) | Absorbs, insulates, smothers fire, wraps objects |
| **paper** | (implicit paper) | Burns instantly, absorbs ink/water, tears easily |
| **needle** | (implicit iron) | Rusts, conducts heat, pricks skin (hardness) |
| **sewing-manual** | (implicit paper+leather) | Cover resists fire briefly, pages burn, absorbs water |
| **pencil** | (implicit wood+graphite) | Wood shaft burns, graphite tip leaves marks |

### 5.2 Template Upgrades Needed

| Template | Current `material` | Needed |
|----------|-------------------|--------|
| `furniture.lua` | `"wood"` | ✅ Already correct — wood properties auto-apply |
| `sheet.lua` | `"fabric"` | ✅ Already correct — fabric properties auto-apply |
| `container.lua` | `"generic"` | ⚠️ Should be overridden per object (wooden chest vs iron chest) |
| `small-item.lua` | `"generic"` | ⚠️ Should be overridden per object |

### 5.3 Emergent Puzzle Opportunities

**Existing puzzle: Lighting the candle in the bedroom**

With material properties:
- If the player strikes a match near the bed-sheets, the sheets could catch fire (fabric `flammability = 0.6`)
- The fire could spread to the wooden nightstand (wood `flammability = 0.5`)
- The player might smother the fire with the wool cloak (wool `flammability = 0.4` + mass)
- Or douse it with water from the chamber pot

**None of this is scripted.** The designer placed flammable objects near a fire source. The material properties and threshold system handle the rest.

**New puzzle potential: The flooded cellar**

- Iron objects left in water develop rust (degradation over turns)
- Paper objects dissolve or become unreadable when submerged
- The player learns to protect valuable objects from water
- Glass objects survive water fine (absorbency = 0.0) — the glass shard is safe to submerge

---

## 6. Industry Precedents

### 6.1 Dwarf Fortress (2006–present)

The gold standard for material simulation. Every material has 20+ numeric properties. The engine operates on property bags with zero knowledge of object types. A "steel sword" is just a collection of steel's mechanical properties in a sword-shaped template.

**Lesson for us:** Material properties should be the primary driver of object behavior, not per-object scripting.

> **Source:** DF Wiki — https://dwarffortresswiki.org/index.php/Material_definition_token

### 6.2 Zelda: Breath of the Wild (2017)

Three rules: elements affect materials, elements affect each other, materials don't affect each other directly. Wood burns, metal conducts, ice melts. Simple rules, enormous emergent space.

**Lesson for us:** You don't need 20 properties. A small set of well-chosen properties creates disproportionate emergence.

> **Source:** GamesBeat — https://gamesbeat.com/the-legend-of-zelda-breath-of-the-wild-makes-chemistry-just-as-important-as-physics/  
> **Source:** The Artifice, "Systemic Games: A Design Philosophy" — https://the-artifice.com/systemic-games-philosophy/

### 6.3 Noita (2019)

Every pixel has material properties: density, flammability, conductivity, solidity. Cellular automata rules drive interactions. Oil floats on water, fire spreads to flammable neighbors, lava melts ice.

**Lesson for us:** Simple property rules at the micro level create breathtakingly complex macro interactions. Start simple.

> **Source:** GDC 2020, "Exploring the Tech and Design of Noita" — https://braindump.jethro.dev/posts/gdc_vault_exploring_the_tech_and_design_of_noita/  
> **Source:** Noita Wiki — https://noita.fandom.com/wiki/Materials

### 6.4 Caves of Qud (2015–present)

Materials interact through property matching. Acid corrodes metals. Fire burns organics. Liquids have weight, temperature, and flash points. Every pool, gas cloud, and surface participates in one interaction system.

**Lesson for us:** Material interactions create emergent narratives. A player who discovers acid dissolves their favorite weapon has learned something about the world that generates a story.

> **Source:** GameDeveloper — https://www.gamedeveloper.com/design/tapping-into-the-potential-of-procedural-generation-in-caves-of-qud  
> **Source:** Caves of Qud Wiki — https://wiki.cavesofqud.com/wiki/Mutations

### 6.5 Academic: Emergent Behavior Frameworks

The EB-DEVS formal framework (Journal of Computational Science, 2021) models macro-micro interactions and feedback loops in dynamic complex systems — directly applicable to understanding how simple material rules produce complex emergent behavior.

The Machinations Framework (AIIDE) simulates resource flows and game mechanics, enabling analysis of emergent outcomes from foundational rules before implementation.

> **Source:** EB-DEVS — https://www.sciencedirect.com/science/article/pii/S1877750321000752  
> **Source:** Machinations — https://ojs.aaai.org/index.php/AIIDE/article/download/12477/12336

---

## 7. Implementation Priorities for Designers

### Phase 1: Foundation (Minimum Viable Material System)

1. **Define 8-10 base materials** with core properties (the table in Section 1.3)
2. **Add `material` to all existing objects** (most already have it or inherit from templates)
3. **Implement fire propagation** as the first emergent behavior (highest impact, most visible)
4. **Test with bedroom puzzle** — verify fire spreading from match to paper/fabric is discoverable and fair

### Phase 2: Water & Degradation

1. **Add wetness/absorption interactions** — cloth soaks, paper dissolves, metal rusts
2. **Implement wear/decay numeric property** — objects degrade over time/use
3. **Cellar flooding as test case** — water damage to objects the player leaves behind

### Phase 3: Impact & Fragility

1. **Dropping objects on surfaces** — glass breaks on stone, survives on bed
2. **Composite material handling** — sewing manual (leather cover + paper pages)
3. **Material-aware tool resolution** — iron knife cuts fabric, glass shard cuts skin

### Phase 4: Advanced Interactions

1. **Conductivity puzzles** — metal conducts heat/electricity, wood insulates
2. **Opacity and light** — glass lets light through, fabric blocks partially
3. **Material crafting** — combining materials with complementary properties

---

## 8. Design Guidelines for Content Creators

### DO:
- ✅ Always specify a `material` for new objects
- ✅ Let material properties drive behavior — if wax melts, don't prevent it for "story reasons"
- ✅ Place objects near environmental conditions to create emergent puzzles
- ✅ Test material interactions in rooms with varied conditions (fire, water, darkness)
- ✅ Trust the system — surprising interactions are features, not bugs

### DON'T:
- ❌ Override material behavior per-object unless there's a strong narrative reason
- ❌ Create "magical" materials that violate physical expectations without clear signals
- ❌ Assume players will avoid testing material limits ("what if I put this in water?")
- ❌ Script interactions that material properties would handle automatically
- ❌ Give objects a `material` that doesn't match their physical reality

### CONSIDER:
- 🤔 Some objects have mixed materials (sewing manual = leather + paper). Use the primary material for the object, and note secondary materials in metadata for advanced interactions.
- 🤔 "Magical" objects should have a `material = "enchanted_X"` variant that inherits from the base material but overrides specific thresholds (e.g., fireproof cloth).
- 🤔 Tarn Adams's advice: "Don't overplan your model." Start with the 10 properties in the table. Add more only when designers need them for specific interactions.

---

## 9. Sources & References

1. **Dwarf Fortress Wiki — Material definition token.** https://dwarffortresswiki.org/index.php/Material_definition_token
2. **Dwarf Fortress Wiki — Raw file format.** https://dwarffortresswiki.org/index.php/Raw_file
3. **GamesBeat — BotW Chemistry Engine.** https://gamesbeat.com/the-legend-of-zelda-breath-of-the-wild-makes-chemistry-just-as-important-as-physics/
4. **The Artifice — Systemic Games Design Philosophy.** https://the-artifice.com/systemic-games-philosophy/
5. **80.lv — Noita Falling Sand Simulation.** https://80.lv/articles/noita-a-game-based-on-falling-sand-simulation
6. **GDC 2020 — Exploring the Tech and Design of Noita.** https://braindump.jethro.dev/posts/gdc_vault_exploring_the_tech_and_design_of_noita/
7. **Noita Wiki — Materials.** https://noita.fandom.com/wiki/Materials
8. **GameDeveloper — Caves of Qud Procedural Generation.** https://www.gamedeveloper.com/design/tapping-into-the-potential-of-procedural-generation-in-caves-of-qud
9. **Caves of Qud Wiki — Mutations.** https://wiki.cavesofqud.com/wiki/Mutations
10. **EB-DEVS — Emergent Behavior Framework (2021).** https://www.sciencedirect.com/science/article/pii/S1877750321000752
11. **AIIDE — Simulating Mechanics to Study Emergence in Games.** https://ojs.aaai.org/index.php/AIIDE/article/download/12477/12336
12. **Springer — Chemical Engine Algorithm (UE4).** https://link.springer.com/chapter/10.1007/978-3-031-50072-5_14
13. **Lucas Lab Studio — Modular Interactions in Emergent Gameplay: Zelda.** https://lucaslabstudio.wordpress.com/2024/08/06/modular-interactions-in-emergent-gameplay-the-legend-of-zelda/
14. **Zelda Dungeon — Tears of the Kingdom Expands on BotW.** https://www.zeldadungeon.net/analysis-tears-of-the-kingdom-expands-on-breath-of-the-wilds-devotion-to-player-freedom/
15. **Internal — DF Architecture Comparison.** `resources/research/competitors/dwarf-fortress/architecture-comparison.md`
16. **Internal — Core Architecture Principles.** `docs/architecture/objects/core-principles.md`

---

*End of Design Document*
