# Puzzle Design Research

**Version:** 1.0  
**Date:** 2026-07-22  
**Author:** Frink (Researcher)  
**Audience:** Sideshow Bob (Puzzle Master), game designers, content creators  
**Status:** Research Complete — Ready for Design Review  

---

## Executive Summary

This document synthesizes puzzle design wisdom from five decades of interactive fiction, modern puzzle games, professional escape rooms, real-world problem-solving psychology, and academic research — all mapped to our engine's unique capabilities. The core finding: **our engine is uniquely positioned to create puzzles that no other text game can**, thanks to the combination of material properties, sensory-space perception, GOAP auto-resolution, and code-derived mutable objects.

The research identifies three puzzle design paradigms particularly suited to our architecture:
1. **Material-physics puzzles** — exploiting our numeric material properties (flammability, melting point, conductivity) for emergent, discoverable interactions
2. **Sensory-gated puzzles** — leveraging our 5-sense system where darkness, silence, or smell become puzzle mechanics, not just atmosphere
3. **Knowledge-gated puzzles** — where GOAP handles mundane prerequisites so puzzles can focus on genuine "aha!" moments of understanding

---

## Table of Contents

1. [Classic Interactive Fiction Puzzles](#1-classic-interactive-fiction-puzzles)
2. [Modern Puzzle Games](#2-modern-puzzle-games)
3. [Escape Room Design](#3-escape-room-design)
4. [Real-Life Problem Solving as Inspiration](#4-real-life-problem-solving-as-inspiration)
5. [Academic Research](#5-academic-research)
6. [Principles for Our Engine](#6-principles-for-our-engine)
7. [Puzzle Ideas Inspired by Research](#7-puzzle-ideas-inspired-by-research)
8. [Sources](#8-sources)

---

## 1. Classic Interactive Fiction Puzzles

### 1.1 The Infocom Golden Age (1980–1989)

Infocom's era produced the most influential text-based puzzles in gaming history. Three titles stand as pillars:

**Zork (1977–1982):**
- Mixed scavenger hunts with environmental and inventory puzzles
- Puzzles were interconnected — items from distant game regions needed elsewhere
- The Royal Puzzle (Zork III) was a sliding block puzzle, demanding spatial reasoning in a text-only medium
- The Grue — an invisible monster in dark rooms — made *darkness itself* a puzzle mechanic [1]

**Enchanter Trilogy (1983–1985):**
- Introduced a magic spell system where puzzles required memorizing and creatively applying spells
- "Frotz" (create light) could be cast on unexpected objects for surprising effects
- Multiple solutions existed for some puzzles, rewarding experimentation over rote memorization
- Spell-based design wove puzzles tightly into the fiction — solutions felt wondrous, not arbitrary [2][3]

**The Hitchhiker's Guide to the Galaxy (1984):**
- Co-written by Douglas Adams and Steve Meretzky
- The Babel Fish puzzle: a legendary multi-step challenge where each failed attempt makes future attempts harder
- Solutions required understanding the *author's sense of humor* — not just game logic
- "No tea" status puzzle: meta-humor and genre subversion as puzzle mechanics [4]

**Why These Puzzles Endure (40+ Years Later):**

| Principle | Why It Works | Example |
|-----------|-------------|---------|
| **Narrative integration** | Solutions fit the story, not arbitrary logic | Enchanter spells tied to magical world |
| **Creative problem-solving** | Experimentation rewarded over brute force | Frotz on unexpected objects |
| **Memorability through frustration→eureka** | The harder the struggle, the sweeter the triumph | Babel Fish remembered 40 years later |
| **Economy of means** | Constrained tools force creative combination | Limited spell slots in Enchanter |
| **Darkness as mechanic** | Absence creates more tension than presence | Grue deaths in Zork |

### 1.2 Andrew Plotkin's Zarfian Cruelty Scale

Andrew Plotkin ("Zarf"), one of IF's most respected theorists, created the definitive framework for classifying puzzle fairness — not difficulty, but *how much the game punishes player mistakes* [5][6]:

| Level | Name | Description | Our Engine Guidance |
|-------|------|-------------|---------------------|
| 1 | **Merciful** | Cannot get stuck. No irreversible mistakes. | ✅ Our GOAP target for most puzzles |
| 2 | **Polite** | Can die/get stuck, but it's immediately obvious | ✅ Good for environmental hazards |
| 3 | **Tough** | Irreversible actions, but signposted in advance | ⚠️ Use sparingly, with clear warning |
| 4 | **Nasty** | Unwinnable, only clear after the fact | ❌ Avoid — frustrates mobile players |
| 5 | **Cruel** | Unwinnable with no warning, realized hours later | ❌ Never — antithetical to our design |

**Key Insight for Our Engine:** Our GOAP system (Tier 3 parser) naturally pushes us toward Merciful/Polite design. When the engine auto-resolves prerequisites ("You'll need to prepare first..."), it eliminates most "Tough" scenarios. This is a *feature*, not a limitation — it lets us design puzzles around *understanding* rather than *gotchas*.

**Plotkin's Revisited Scale (2019):** Modern undo/save-anywhere reduces the impact of Cruel design, but the core principle remains — how and when players learn they've made a mistake is the key design variable [6].

### 1.3 Emily Short on Puzzle Design

Emily Short, creator of *Counterfeit Monkey*, *Bronze*, and *Savoir-Faire*, is IF's most articulate design voice [7][8][9]:

**Core Principles:**

1. **Build a through-line first** — Implement the complete solvable path before adding complexity. Our parallel: build the critical path puzzle chain before branching
2. **Complicate with purpose** — Each puzzle should deepen theme, not just add obstacles
3. **Four qualities of a good puzzle:**
   - **Extent** — Substantial gameplay without busywork (no Towers of Hanoi)
   - **Explorability** — Fun to tinker with even before solving (reward experimentation)
   - **Surprise** — Requires a shift in perspective or connecting partial information
   - **Ingenuity** — Complex puzzles should be teachable through progressive hints
4. **Puzzles as narrative rewards** — Solutions should unlock story, world-building, or character development, not just the next room
5. **Storylet architecture** — Dynamic narrative modules triggered by player state, enabling highly responsive, replayable experiences [10]

**Our Engine Alignment:** Short's "explorability" maps directly to our sensory system — a player can FEEL, SMELL, LISTEN to a puzzle object and get feedback even before understanding the solution. Her "storylet" model maps to our FSM state-driven object descriptions.

---

## 2. Modern Puzzle Games

### 2.1 The Witness (Jonathan Blow, 2016)

**Core Innovation:** Teaches complex systems without a single word of instruction [11][12].

**Design Principles:**
1. **Non-verbal communication** — Rules conveyed purely through puzzle sequence and arrangement
2. **Progressive complexity ("scaffolding")** — Each puzzle is one step beyond the previous
3. **Isolation of mechanics** — New rules introduced in isolation before combination
4. **Environmental teaching** — The island itself contains solutions (tree branches echo maze patterns)
5. **Respect for player intelligence** — No hand-holding; "aha!" moments only through genuine engagement

**Lesson for Us:** Our text medium can achieve similar wordless teaching through *sensory feedback progression*. A candle's heat (FEEL) teaches that fire is hot → a wax seal melts when near fire (material property threshold) → the player combines these understandings to melt a wax-sealed letter. Each step teaches one concept.

### 2.2 Baba Is You (Arvi Teikari, 2019)

**Core Innovation:** The rules of the game are physical objects that can be pushed and rearranged [13][14].

**Key Design Insights:**
- Rules as physical entities: "BABA IS YOU" can be broken by pushing "IS" away
- Live parsing: changing rule configuration instantly updates gameplay
- Combinatorial explosion: enormous state space from simple components
- Metapuzzle quality: players "debug" the logic, not just solve the puzzle
- The use/mention distinction: the word "BABA" vs. the concept of Baba

**Our Engine Parallel:** Our code-derived mutable objects (Principle 1) enable a text-game equivalent. Objects whose FSM states change the rules of interaction — a cursed mirror that reverses verb meanings, a magic scroll that redefines what "OPEN" means in its room. Baba's power comes from making rules tangible; our power comes from making object *behavior* tangible through mutation.

### 2.3 Return of the Obra Dinn (Lucas Pope, 2018)

**Core Innovation:** Pure deduction from observation — no inventory, no action puzzles [15][16].

**Key Design Insights:**
- Strip detective work to observation and logic: uniforms, body language, accents, proximity
- **Lateral information**: clues gathered in one scene applied in another
- Interconnected mysteries: solving one identity reveals clues for others
- "Fair play" rules: all information needed exists in the game world
- Minimalist presentation (1-bit art) forces focus on what matters

**Lesson for Us:** Our multi-sensory system enables "lateral information" through different senses. You HEAR a conversation in one room, SMELL a chemical in another, and FEEL a texture in a third — combining three sensory observations from different rooms into one deduction.

### 2.4 Outer Wilds (Mobius Digital, 2019)

**Core Innovation:** Knowledge is the only key — no inventory gates whatsoever [17].

**Key Design Insights:**
- Every area accessible from the start; only ignorance blocks you
- The Ship Log tracks discoveries as a visual rumor map
- **Knowledge gates**: progression requires *understanding*, not items
- No one-use items; everything resets each loop
- Multiple pathways to every piece of knowledge

**Critical Lesson for Our Engine:** This is the most important model for our GOAP system. When Tier 3 auto-resolves inventory prerequisites, the *remaining* puzzles become knowledge-gated by default. "How do I light the candle?" becomes trivial (GOAP handles it). "Why should I light the candle?" becomes the real puzzle. This elevates our puzzle design above traditional IF.

### 2.5 Portal (Valve, 2007)

**Core Innovation:** Environmental physics puzzles with a single, deeply explored mechanic [18].

**Key Design Insights:**
- The "cabal process": cross-disciplinary teams of 6-8 iterating rapidly
- **Playtesting as secret weapon**: GLaDOS was created because testers needed motivation
- Environmental clarity: white test chambers emerged from playtest confusion
- Single mechanic, infinite depth: one tool (portal gun) explored exhaustively
- Humor as pacing: comedy breaks between intense puzzle sections

**Our Engine Parallel:** Our material properties system is our "portal gun" — a single system (numeric thresholds on materials) that creates infinite puzzle variety. Flammability, melting point, conductivity, density — each property is a "rule" that combines with others.

### 2.6 Myst/Riven (Cyan Worlds, 1993/1997)

**Core Innovation:** Environmental observation as the primary puzzle mechanic [19][20].

**Key Design Insights (Riven especially):**
- Puzzles emerge organically from culture, history, and decaying technology
- Minimal handholding: players learn by observing cause and effect
- Multi-layered puzzles requiring connections between disparate island locations
- Sound and visual cues as feedback systems
- Environmental storytelling IS the puzzle — understanding the culture IS the solution

**The Fire Marble Dome Puzzle:** Requires observations about colors, symbols, and locations gathered hours apart. The solution is comprehension of the Rivenese number system — pure knowledge gate.

**Our Engine Parallel:** Our room descriptions and object descriptions can embed layered clues that only make sense in combination. A tapestry describes a historical event → a hidden journal mentions a date → the player must enter the date using an ancient number system found carved on a wall.

---

## 3. Escape Room Design

### 3.1 Professional Design Principles

The $14B escape room industry has codified puzzle design principles through millions of player sessions [21][22][23]:

**The Five Pillars of Escape Room Design:**
1. **Immersion** — Every puzzle element belongs in the narrative world
2. **Flow** — Pacing from easy to hard, with no dead stops
3. **Collaboration** — Multiple puzzle tracks for parallel solving
4. **Clarity** — Solutions always fair and findable from available information
5. **Surprise** — At least one "wow" moment per experience

### 3.2 Flow Structures

| Structure | Description | Pros | Cons | Our Use |
|-----------|-------------|------|------|---------|
| **Linear** | A → B → C strict sequence | Easy to pace, strong narrative | Bottleneck risk, idle players | Tutorial sequences |
| **Parallel** | Multiple independent tracks | All players engaged | Hard to converge meaningfully | Multi-room exploration |
| **Pyramid** | Parallel → converge at key points | Best of both worlds | Complex to design | Boss puzzles requiring multiple solved sub-puzzles |
| **Bottleneck** | Intentional convergence point | Creates dramatic climax | Must be solvable by all skill levels | Chapter-ending puzzles |

**Our Recommendation:** Pyramid flow with linear tutorials. GOAP auto-resolution means "stuck" state is rarer, so bottleneck puzzles can be harder than traditional IF allows.

### 3.3 Physical Objects as Puzzle Elements

Escape rooms prove that *manipulating physical objects* creates deeper engagement than abstract logic alone [24]:

- **Embodied cognition**: physical manipulation enhances learning and memory
- **Sensory feedback**: "click" when correct, visual change, tactile confirmation
- **Chaining**: solution to puzzle A becomes a tool for puzzle B
- **Multi-step with tangible artifacts**: unlock drawer → find riddle → riddle answer opens safe

**Our Engine Mapping:**

| Escape Room Element | Our Engine Equivalent |
|---------------------|----------------------|
| Hidden compartment | Object with `covering` property hiding another object |
| Combination lock | Object requiring specific knowledge (number, word) to transition FSM |
| Key-and-lock | `requires_tool` on FSM transition |
| UV-light reveal | Sensory verb revealing hidden information (FEEL reveals braille, SMELL reveals invisible ink) |
| Weight-activated platform | Material property threshold (density/weight check) |
| Temperature-sensitive ink | Material property threshold (message appears when heated) |

### 3.4 Red Herrings: When They Work vs. Frustrate

**Works:**
- Thematically appropriate (a red herring *fish* in a fisherman's cottage)
- Immediately identifiable as decorative vs. interactive
- Creates flavor/atmosphere without misleading puzzle logic

**Frustrates:**
- Object has interaction verbs but no puzzle purpose
- Multiple plausible-looking dead ends with no feedback
- Player wastes significant time before realizing irrelevance

**Our Engine Rule (aligns with D-BUG022: No false affordances):** Every described interactive object should either serve a puzzle purpose OR clearly signal its decorative nature through sensory feedback ("The painting is purely decorative — pleasant to look at, nothing more").

### 3.5 The "Aha!" Moment Psychology

Neuroscience research confirms what designers intuit [25]:

- **Dopamine release**: solving puzzles triggers the same reward pathways as food and social bonding
- **Gamma wave burst**: the "aha!" moment produces measurable high-frequency brain activity
- **Insight memory**: solutions discovered through insight are retained far better than those worked out incrementally
- **Impasse is necessary**: the brain requires a period of "stuckness" before insight can occur
- **Reframing triggers insight**: the solution comes from seeing the problem differently, not from more data

**Design Implication:** Good puzzles must create a brief impasse followed by a reframing opportunity. Our GOAP system should NOT auto-resolve knowledge gates — only mechanical prerequisites.

---

## 4. Real-Life Problem Solving as Inspiration

### 4.1 Real-World Tasks as Puzzle Sources

The most satisfying puzzles mirror real-world problem-solving because they activate the same cognitive systems [26][27]:

**Lock Picking:**
- Hidden mechanism + tactile feedback + hypothesis testing
- Clear binary outcome (open/not open)
- Skill develops through practice, not knowledge alone
- **Our adaptation**: A chest with a complex latch mechanism where FEEL reveals pin positions, and the player must manipulate in correct sequence

**Fire Starting:**
- Requires understanding material properties (tinder, kindling, fuel)
- Environmental conditions matter (wind, dampness)
- Multi-step: gather materials → arrange → ignite → maintain
- **Already in our engine**: Candle → match → matchbox chain; extend to campfire building with material property checks

**Cooking:**
- Combines ingredients with specific processes (heat, mix, cut)
- Timing matters (overcook → ruin)
- Material transformation is visible and satisfying
- **Our adaptation**: Potion/recipe puzzles where ingredients must be combined in correct order with correct heat

**Navigation:**
- Pattern recognition in environment
- Landmark memory and spatial reasoning
- Dead reckoning from imperfect information
- **Our adaptation**: Navigate by sound/smell in darkness, using sensory landmarks

### 4.2 Why Real-World Constraints Beat Arbitrary Game Logic

Players have lifetime experience with real physics. When a puzzle obeys real-world rules:
- Solutions feel fair ("of course wax melts near fire!")
- No need to teach puzzle rules — players already know them
- "Material Consistency" principle (R-MAT-3) validates this: if wax melts, ALL wax melts

When puzzles use arbitrary logic:
- Solutions feel cheap ("use the rubber chicken with the pulley")
- Players must read the designer's mind
- Replay value drops — the "trick" only works once

**Our Engine Advantage:** Our material properties system (10-11 numeric properties: density, melting_point, ignition_point, hardness, flexibility, absorbency, opacity, flammability, conductivity, fragility, value) creates a consistent physics that players can learn and then *predict*. This is the gold standard identified by both Blow (The Witness) and Plotkin (Zarfian Merciful design).

### 4.3 Material Properties as Puzzle Elements

Our material system enables puzzle types impossible in traditional IF:

| Material Property | Puzzle Application | Example |
|-------------------|-------------------|---------|
| `flammability` | Fire propagation chains | Light rope to burn through binding |
| `melting_point` | Heat-based reveal/transform | Melt wax seal, forge metal key |
| `conductivity` | Electricity/heat transfer puzzles | Metal rod conducts heat to distant object |
| `density` | Float/sink mechanics | Cork floats to retrieve sunken key |
| `hardness` | Breaking/cutting constraints | Only steel can scratch glass |
| `absorbency` | Liquid transfer | Cloth soaks up water to reveal hidden message |
| `opacity` | Light/shadow puzzles | Transparent object needed to read projected text |
| `flexibility` | Shape/fit puzzles | Bend wire to create tool |
| `fragility` | Handle-with-care puzzles | Glass key shatters if dropped |
| `ignition_point` | Temperature thresholds | Paper ignites before iron; use selective burning |

---

## 5. Academic Research

### 5.1 Gate Taxonomies in Puzzle Design

Academic research identifies three fundamental gate types [28][29]:

**Knowledge Gates:**
- Player must know something (a code, a pattern, a rule)
- Outer Wilds model: knowledge IS the key
- Most satisfying when knowledge is earned through exploration
- **Our engine strength**: GOAP handles everything else, so knowledge gates become primary

**Skill Gates:**
- Player must demonstrate mechanical ability (timing, dexterity)
- Less applicable to text IF (we have no twitch mechanics)
- Can be adapted as *parser skill* — knowing the right verb/phrasing
- **Our consideration**: Tier 1+2 parser makes skill gates mostly irrelevant (good)

**Inventory Gates:**
- Player must possess specific items
- Traditional IF's bread and butter ("use key on door")
- **Our GOAP disruption**: Tier 3 auto-resolves simple inventory gates
- Remaining inventory puzzles must be *interesting*, not just "find the key"

### 5.2 Player Frustration Thresholds and Hint Systems

Research from IEEE, DiVA, and Aalto University [29][30][31]:

**Key Findings:**
- Moderate impasse is beneficial (triggers insight); prolonged impasse causes disengagement
- Adaptive hint systems show mixed results — some players prefer them, others find them patronizing
- **Tiered hints** (increasingly explicit, player-requested) are the consensus best practice
- "Multimodal" hints (responding to time, failed attempts, behavioral cues) show promise

**Hint System Design for Our Engine:**

| Tier | Trigger | Content | Implementation |
|------|---------|---------|----------------|
| 0 | Always available | Sensory feedback (LOOK, FEEL, SMELL) | Built into object descriptions |
| 1 | Player asks (THINK or HINT) | Contextual nudge ("Something about this room smells odd...") | Object-level `on_hint` callback |
| 2 | Extended stuckness | More explicit direction ("The wax seal looks like it would melt easily...") | Tick-based counter per puzzle |
| 3 | Player asks again | Near-solution ("Try holding the candle near the sealed letter") | Escalating specificity |

### 5.3 Cognitive Science of Insight

Research from Tufts University on puzzle video games and human insight [32]:

- Insight (the "aha!" moment) involves a restructuring of the problem representation
- Players must reach an *impasse* before restructuring can occur
- Incubation (stepping away from a puzzle) facilitates restructuring
- Working memory limitations mean puzzles should have 3-5 key elements, not 10+
- Visual/spatial reasoning is easier than verbal/abstract reasoning for most people

**Design Rule:** Each puzzle should have no more than 3-5 key elements to track. Our multi-room, multi-object world makes this challenging — Bob must ensure each puzzle's *relevant* elements are clearly distinguished from *ambient* elements.

### 5.4 Key GDC Talks and Industry References

**Jonathan Blow — "Designing to Reveal the Nature of the Universe" (multiple GDC talks):**
- Puzzles should teach the player something new about the system, not test rote memory
- Satisfaction comes from internal realization, not external reward
- Scaffold learning: simple concepts first, combined in novel ways later
- Discourage obfuscation; prefer clarity and elegance [11]

**Valve — "The Cabal Process" (Ken Birdwell, Gamasutra/GDC):**
- Cross-disciplinary teams of 6-8 iterate on puzzles
- Playtesting is the "secret weapon" — observe, don't ask
- Environmental clarity > visual complexity
- Comedy/story as pacing between puzzle intensity [18][33]

**Arvi Teikari — "Reading the Rules of Baba Is You" (GDC 2020):**
- Rule parsing: syntax + semantics validation prevents nonsensical states
- Temporal + spatial aspects of rule formation add design layers
- Always ensure a "YOU" object exists (player can never lose agency) [14]

---

## 6. Principles for Our Engine

### 6.1 How Our 8 Architecture Principles Enable/Constrain Puzzle Design

| Principle | Puzzle Enablement | Puzzle Constraint |
|-----------|-------------------|-------------------|
| **P1: Code-Derived Mutable Objects** | Objects can transform mid-puzzle (candle→candle-spent) | Transformations must be FSM-legal transitions |
| **P2: Base → Instances** | Same puzzle type, different instances (3 different locked doors) | Instances share base behavior; unique puzzles need unique bases |
| **P3: FSM States** | Puzzles = state transitions; solution = finding the right transition | Must pre-author all possible states (no truly emergent states yet) |
| **P4: Composite Objects** | Multi-part puzzles (disassemble machine, combine parts) | Parts must be pre-defined; can't create arbitrary combinations |
| **P5: GUID Instances** | Multiple puzzle copies for different players/rooms | Each instance tracks state independently |
| **P6: Sensory Space** | Multi-sense puzzles (find by smell, solve by feel, verify by sound) | Each sense must be authored per object per state |
| **P7: Spatial Relationships** | Covering, blocking, weight-on puzzles (rug→trap door) | Spatial props limited to current set (movable, resting_on, covering) |
| **P8: Engine Executes Metadata** | Puzzles defined entirely in object data, not engine code | New puzzle *types* may need engine extensions (new verb, new property) |

### 6.2 How GOAP Auto-Resolution Changes Puzzle Design

**The GOAP Paradigm Shift:**

Traditional IF puzzle: "To light the candle, you need a match. To get the match, open the matchbox. To open the matchbox, find it on the shelf."

This is an *inventory chain* — find A to get B to do C. GOAP auto-resolves this: player types "light candle" → planner builds [open matchbox → take match → strike match → light candle] → executes automatically.

**What This Means for Bob:**

1. **Simple inventory chains are NOT puzzles anymore.** GOAP trivializes them. Don't design "find the key" puzzles.

2. **Knowledge gates become primary.** "Why light the candle?" is the puzzle. The player must *understand* that the candle reveals a hidden message, or that the flame triggers a wax-seal melt.

3. **Environmental understanding replaces item-hunting.** The puzzle is knowing THAT you need fire near the wax seal, not HAVING a fire source.

4. **Multi-domain puzzles thrive.** Combining knowledge from sensory exploration + material understanding + environmental observation. GOAP can resolve any single domain, but cross-domain synthesis requires human insight.

5. **GOAP depth limit (MAX_DEPTH=5) creates natural puzzle complexity ceiling.** Chains longer than 5 steps won't auto-resolve, creating space for intentionally complex puzzles.

### 6.3 How Material Properties Create New Puzzle Types

Our material properties system (from R-MAT research) enables puzzles impossible in traditional IF:

**Threshold-Based Puzzles:**
- Heat wax past melting_point → seal breaks
- Heat metal past ignition_point of nearby cloth → cloth burns → reveals hidden passage
- Submerge object → density determines float/sink → different puzzle paths

**Chain Reaction Puzzles:**
- Light rope (high flammability) → fire spreads to wooden door (moderate flammability) → door burns through → new room accessible
- But metal lock on door survives fire (high melting_point) → must solve lock separately

**Material Substitution Puzzles:**
- Need to block water: cloth (high absorbency) works, metal (zero absorbency) doesn't
- Need to conduct heat: metal rod (high conductivity) works, wooden stick (low conductivity) doesn't
- Player must *understand material properties* to choose the right tool

**The "Material Consistency" Advantage:**
Every material behaves identically everywhere (R-MAT-3). Once a player learns "wax melts near fire," they can predict ALL wax behavior. This creates a learnable, predictable physics that enables Witness-style progressive complexity.

### 6.4 How Our Sensory System Enables Unique Puzzles

Our 5-sense system (D-37 to D-41) creates puzzle types unique to our engine:

**Darkness Puzzles (senses work without light):**
- FEEL reveals shapes, textures, temperatures
- LISTEN reveals ambient sounds, creature movements, mechanical operations
- SMELL reveals chemicals, food, decay, fire
- TASTE reveals substances (bitter = poison, sweet = sugar, metallic = blood)

**Cross-Sensory Deduction:**
- SMELL smoke in room A → fire is somewhere connected
- LISTEN to water dripping in room B → underground stream
- FEEL warm air from the north exit → fire is north
- Combining: fire + water + direction = the solution

**Sensory-Only Puzzles (unprecedented in IF):**
A room in total darkness where the puzzle is solved entirely through non-visual senses. Player must FEEL their way around, LISTEN for clues, SMELL for danger. This leverages our engine's unique capability that sensory verbs work without light.

### 6.5 What Puzzle Types We're Uniquely Positioned to Do Well

| Puzzle Type | Why We Excel | Competition Gap |
|-------------|-------------|-----------------|
| **Material-physics puzzles** | Numeric material properties + threshold transitions | No other text IF has material physics |
| **Multi-sensory puzzles** | 5 independent sense channels | Most IF only has LOOK and EXAMINE |
| **Knowledge-gated puzzles** | GOAP eliminates busywork, elevates understanding | Traditional IF relies on inventory chains |
| **Progressive-complexity chains** | Material consistency teaches rules; FSM enables layered combination | Witness-style design in text medium is unprecedented |
| **Environmental deduction** | Room descriptions + object states + sensory data | Obra Dinn-style deduction in text is our sweet spot |
| **Dark room puzzles** | Non-visual senses as primary interaction | Zero competitors in this space |

---

## 7. Puzzle Ideas Inspired by Research

### 7.1 Classic IF Inspired

**Idea 1: The Enchanter's Library**
🔴 Theorized | ⭐⭐⭐ Difficulty  
A library with books that, when READ, change the behavior of objects in adjacent rooms. Reading "A Treatise on Levitation" makes a specific heavy stone movable. Reading "The Nature of Flame" changes fire behavior. Player must discover which books affect which objects — a text-game Baba Is You.
- **Objects needed:** Library room, 3-4 magical books (new), enchanted objects in adjacent rooms (variants of existing)
- **Gate type:** Knowledge gate — must understand book→effect mapping
- **Principle alignment:** P1 (mutable objects), P3 (FSM transitions via external trigger), P8 (metadata-driven)

**Idea 2: The Darkness Maze**
🔴 Theorized | ⭐⭐ Difficulty  
A series of rooms in total darkness, navigable only through non-visual senses. LISTEN for water (guides toward underground river), SMELL for smoke (guides away from fire), FEEL walls for temperature changes (warm = approaching heat source, cold = approaching exit). Inspired by Zork's Grue + our sensory system.
- **Objects needed:** 4-5 dark rooms (new), ambient sensory objects (water_drip, smoke_vent, warm_wall variants)
- **Gate type:** Knowledge gate — must learn sensory navigation
- **Principle alignment:** P6 (sensory space), D-37 (senses work in darkness)

**Idea 3: The Babel Scroll**
🔴 Theorized | ⭐⭐⭐⭐ Difficulty  
A multi-step puzzle inspired by Hitchhiker's Babel Fish. A scroll with instructions in an ancient language. Each attempt to decipher it reveals ONE word but scrambles another. Player must WRITE down discovered words before they disappear. Requires managing partial knowledge across multiple attempts.
- **Objects needed:** Ancient scroll (new), writing surface (existing?), ink/quill (new)
- **Gate type:** Knowledge gate — accumulate partial information across attempts
- **Principle alignment:** P1 (object mutates each attempt), P3 (FSM tracks decryption progress)

### 7.2 Modern Puzzle Game Inspired

**Idea 4: The Witness Candle Chain**
🔴 Theorized | ⭐⭐ Difficulty  
A progressive-complexity material puzzle. Room 1: light candle with match (trivial, GOAP handles). Room 2: light candle, but match is wet — must dry it first (material property: absorbency). Room 3: light candle, but it's in a sealed glass container — must break glass first (hardness check), but breaking glass alerts guards. Each room adds ONE new concept.
- **Objects needed:** Variants of candle/match with material property differences (new material definitions), glass container (new), guard NPC (new)
- **Gate type:** Progressive knowledge gate
- **Principle alignment:** P8 (metadata-driven behavior), material properties system, Witness-style scaffolding

**Idea 5: The Obra Dinn Murder**
🔴 Theorized | ⭐⭐⭐⭐ Difficulty  
A multi-room deduction puzzle. Someone has been killed, and the player must determine who, how, and why by examining objects across 3-4 rooms. Each room contains sensory clues: SMELL reveals the killer's perfume, FEEL reveals the murder weapon's temperature (recently used), LISTEN reveals a ticking clock that establishes timeline. Solution requires cross-referencing observations.
- **Objects needed:** Crime scene room (new), 3-4 suspect-related rooms (new), evidence objects (blood stains, weapon, letter), NPC suspects (new)
- **Gate type:** Pure knowledge gate — deduction from observation
- **Principle alignment:** P6 (multi-sensory), P7 (spatial relationships as clues)

**Idea 6: The Outer Wilds Loop**
🔴 Theorized | ⭐⭐⭐ Difficulty  
A time-loop puzzle where the player wakes in the same room each cycle. Actions in early cycles reveal information needed in later cycles. Knowledge persists; world state resets. Example: Cycle 1 — read a letter before it burns. Cycle 2 — use the letter's information to open a safe before the room floods. Cycle 3 — use safe contents + letter knowledge to escape.
- **Objects needed:** Time-loop room (new), burning letter (new, FSM with timer), flooding mechanism (new), safe with combination (new)
- **Gate type:** Knowledge gate across time loops
- **Principle alignment:** P1 (reset via fresh load), P3 (FSM timer-based transitions)

### 7.3 Escape Room Inspired

**Idea 7: The Three-Lock Door**
🔴 Theorized | ⭐⭐⭐ Difficulty  
A pyramid-flow puzzle. Three parallel puzzle tracks, each yielding one piece of a three-part code. Track A: material puzzle (melt ice to reveal number). Track B: sensory puzzle (count bell chimes in the dark). Track C: spatial puzzle (move objects to reveal inscription). All three pieces combine to open the final door.
- **Objects needed:** Multi-lock door (new), ice block with frozen number (new, material properties), bell mechanism (new, timer-based), inscription-hiding object arrangement (existing spatial system)
- **Gate type:** Mixed — material + knowledge + spatial
- **Principle alignment:** Escape room pyramid flow, all 8 principles exercised

**Idea 8: The Escape Room Kitchen**
🔴 Theorized | ⭐⭐ Difficulty  
A room designed as a medieval kitchen where every puzzle uses real-world cooking knowledge. Must start a fire (flint + tinder, material properties). Must boil water (fire + pot + water, temperature threshold). Must create a specific mixture (recipe found elsewhere). The mixture dissolves a wax seal on the exit door.
- **Objects needed:** Kitchen room (new), fireplace (new), cooking pot (new), ingredients (herbs, water, oil — new), recipe scroll (new), wax-sealed door (new, material properties)
- **Gate type:** Real-world knowledge + material properties
- **Principle alignment:** Material Consistency principle, P8, real-world grounding

**Idea 9: The Chained Lockbox**
🔴 Theorized | ⭐⭐⭐ Difficulty  
Escape room chaining: Open box A (key under rug — spatial) → contains a lens → use lens to READ tiny inscription on wall → inscription is a riddle → riddle answer is a number → number opens combination lock on box B → box B contains a tool → tool needed to repair a broken mechanism → mechanism opens the exit.
- **Objects needed:** Two lockboxes (new), lens (new), wall inscription (new), combination lock (new), broken mechanism (new)
- **Gate type:** Progressive — spatial → inventory → knowledge → inventory → skill
- **Principle alignment:** Full puzzle chain, P4 (composite), P7 (spatial), P8 (metadata)

### 7.4 Real-World Problem Solving Inspired

**Idea 10: The Flooded Cellar**
🔴 Theorized | ⭐⭐ Difficulty  
The cellar is flooding. Player must find a way to block the water source or bail it out. Uses material properties: cloth (high absorbency) can plug the crack temporarily, but wood (low absorbency, high density) is needed for a permanent fix. Tools available: cloth rag, wooden plank, nails, hammer. Real-world logic: plug leak, then reinforce.
- **Objects needed:** Flooding cellar variant (modified existing), crack in wall (new), cloth rag (existing?), wooden plank (new), nails (new), hammer (new)
- **Gate type:** Material knowledge + real-world construction logic
- **Principle alignment:** Material properties, P6 (FEEL water rising, LISTEN to flow), P8

**Idea 11: The Frozen Lock**
🔴 Theorized | ⭐⭐ Difficulty  
A lock frozen shut in winter. Player must heat the lock to unfreeze it. Direct flame (candle) works but is too weak. Must find a metal object to conduct heat from fire to lock (conductivity property). A metal poker heated in the fireplace, then applied to the lock.
- **Objects needed:** Frozen lock (new, material properties with melting threshold), metal poker (new), fireplace (existing/new)
- **Gate type:** Material knowledge — understanding conductivity
- **Principle alignment:** Material properties (conductivity, melting_point), P6 (FEEL cold lock)

**Idea 12: The Compass Rose**
🔴 Theorized | ⭐⭐⭐ Difficulty  
Navigation puzzle in a dark underground area. No map, no light. Player must navigate by LISTENING to echoes (large room = long echo, small room = short echo), FEELING air currents (draft = exit nearby), SMELLING water (underground stream marks specific corridor). Must build a mental map and navigate to a specific location described only in a found journal.
- **Objects needed:** 5-6 dark interconnected rooms (new), ambient sensory objects per room, journal with navigation clues (new)
- **Gate type:** Knowledge gate — spatial reasoning from sensory data
- **Principle alignment:** P6 (sensory space), P7 (spatial), D-37 (senses in darkness)

### 7.5 Material-Physics Inspired

**Idea 13: The Rube Goldberg Fire Chain**
🔴 Theorized | ⭐⭐⭐⭐ Difficulty  
A fire propagation puzzle: player must create a chain reaction. Light oil-soaked rope (high flammability) → fire travels along rope to wooden beam (moderate flammability) → beam collapses onto wax seal (low melting point) → seal melts → releases counterweight → counterweight opens iron gate (fire-resistant). Player must arrange materials in the correct configuration.
- **Objects needed:** Oil-soaked rope (new), wooden beam (new), wax seal mechanism (new), counterweight system (new), iron gate (new)
- **Gate type:** Material knowledge + spatial arrangement
- **Principle alignment:** R-MAT-4 (fire propagation as first implementation), Material Consistency, P7 (spatial)

**Idea 14: The Alchemist's Scale**
🔴 Theorized | ⭐⭐⭐ Difficulty  
A density/weight puzzle: balance a scale to unlock a door. Player must find objects of specific combined weight. Material density determines weight. A gold coin (high density) weighs more than expected. A hollow wooden ball (low density) weighs less. Player must experiment with different object combinations until the scale balances.
- **Objects needed:** Balance scale mechanism (new), various objects with different densities (gold coin, wooden ball, stone, cork — new), locked mechanism (new)
- **Gate type:** Material knowledge — understanding density relationships
- **Principle alignment:** Material properties (density), P8, real-world physics

### 7.6 Sensory-System Inspired

**Idea 15: The Poisoned Feast**
🔴 Theorized | ⭐⭐⭐ Difficulty  
A table with 5 goblets. One is safe to drink, others are poisoned. Player must use senses: SMELL each (one smells of bitter almonds = cyanide), LOOK at each (one has slight discoloration), FEEL each (one is warmer = recently handled), TASTE tiny amount of one (metallic = arsenic). Cross-reference to identify the safe goblet.
- **Objects needed:** Feast room (new), 5 goblets with different sensory signatures (new), table surface (existing pattern)
- **Gate type:** Sensory knowledge gate — cross-sensory deduction
- **Principle alignment:** P6 (all 5 senses), D-37 (sensory verbs), Obra Dinn-style deduction

**Idea 16: The Singing Door**
🔴 Theorized | ⭐⭐ Difficulty  
A door that opens only when the correct sequence of sounds is produced. Player must LISTEN to environmental sounds (wind through windows, water dripping, bell chiming) and reproduce the pattern by interacting with sound-producing objects in the correct order (ring bell, open window, pour water).
- **Objects needed:** Musical door mechanism (new), bell (existing?), window with wind (new), water source (new)
- **Gate type:** Knowledge gate — pattern recognition through LISTEN
- **Principle alignment:** P6 (auditory sense), P8 (metadata-driven transitions)

---

## 8. Sources

[1] Lebling, Blank, Anderson. "Zork: A Computerized Fantasy Simulation Game." *IEEE Computer*, 1979. History via Gold Machine: https://golmac.org/

[2] Enchanter walkthrough and analysis. Eristic.net: http://www.eristic.net/games/infocom/enchanter.html

[3] Enchanter guide. GameFAQs: https://gamefaqs.gamespot.com/appleii/949403-enchanter/faqs/73871

[4] Infocom InvisiClues archive. https://dfabulich.github.io/infocom-hints-html/index.html; The Complete Infocom Archive: https://invisiclues.org/

[5] Plotkin, Andrew. "The Zarfian Cruelty (or Forgiveness) Scale." https://www.eblong.com/zarf/essays/cruelty.html

[6] Plotkin, Andrew. "The Zarfian Cruelty Scale, Revisited" (2019). https://eblong.com/zarf/essays/cruelty-revisited.html; Blog: https://blog.zarfhome.com/2019/09/the-zarfian-cruelty-scale-revisited.html

[7] Short, Emily. Blog: https://emshort.blog/

[8] "Inside Interactive Fiction: An Interview with Emily Short." Game Developer: https://www.gamedeveloper.com/design/inside-interactive-fiction-an-interview-with-emily-short

[9] "Emily Short on Best Individual Puzzle." The XYZZY Awards: https://xyzzyawards.org/?p=386

[10] "Notes from the Boundaries of Interactive Storytelling" (Short's storylet architecture). Polaris Game Design: https://polarisgamedesign.com/2024/notes-from-the-boundaries-of-interactive-storytelling/

[11] "The Witness, 10 Years Later, Still Refuses To Explain Itself." GameSpot: https://www.gamespot.com/articles/the-witness-10-years-later-still-refuses-to-explain-itself/1100-6537705/

[12] "The Witness' Wordless Tutorials." Rock Paper Shotgun: https://www.rockpapershotgun.com/the-witness-tutorial; "A Deconstructive Analysis of The Witness." The Gemsbok: https://thegemsbok.com/art-reviews-and-articles/the-witness-thekla-jonathan-blow-analysis-deconstruction/

[13] Teikari, Arvi. "Reading the Rules of Baba Is You." GDC 2020: https://media.gdcvault.com/gdc2020/presentations/Reading%20the%20rules_Teikari_Arvi.pdf

[14] "Designing Baba Is You's delightfully innovative rule-writing system." Game Developer: https://www.gamedeveloper.com/design/designing-i-baba-is-you-i-s-delightfully-innovative-rule-writing-system

[15] "Return of the Obra Dinn Design Analysis." Kokutech: https://www.kokutech.com/blog/gamedev/design-patterns/unique-mechanics/return-of-the-obra-dinn

[16] "Return of the Obra Dinn & Lateral Information." Atomic Bob-Omb: https://atomicbobomb.home.blog/2020/03/21/return-of-the-obra-dinn-lateral-information/

[17] "Outer Wilds: Questions about puzzle design." Steam Community: https://steamcommunity.com/app/753640/discussions/0/3805028908499412584/

[18] "Valve's Secret Weapon" (playtesting). Mark Brown / GMTK: https://gmtk.substack.com/p/valves-secret-weapon

[19] "The Art of Environmental Storytelling in Riven." Ellipsus: https://ellipsus.com/blog/riven-world-building

[20] "Riven — Immersion through Integrated Puzzle Design." Experienced Machine: https://experiencedmachine.wordpress.com/2023/03/04/riven-immersion-through-puzzles/; Plotkin on Riven: https://blog.zarfhome.com/2024/07/one-riven-puzzle-considered

[21] "Advanced Flow Modeling - Architecting the Professional Escape Room." Oboe: https://oboe.com/learn/architecting-the-professional-escape-room-8jcjr0/advanced-flow-modeling-1xob4c7

[22] "Linear vs. Non-Linear Game Flow in Escape Rooms." Mystery Soup Games: https://mysterysoupgames.com/linear-vs-non-linear-game-flow-in-escape-rooms/

[23] "The Five Pillars: How Great Designers Turn Locks Into Legends." Escape Room Sverige: https://escaperoomsverige.se/article/5-fundamental-principles-escape-room-design

[24] "The Art of Puzzle Design in Escape Rooms." Big Escape Rooms: https://www.bigescaperooms.com/the-art-of-puzzle-design-in-escape-rooms/

[25] "The Art of the 'Aha!' Moment: What Neuroscience Reveals." Trapped Escape Game: https://trappedescapegame.com/the-art-of-the-aha-moment-what-neuroscience-reveals-about-the-satisfaction-of-solving-an-escape-room-puzzle/; "Anatomy of a Puzzle Experience." Puzzle Drifter: https://puzzledrifter.com/anatomy-of-a-puzzle-experience-measuring-the-aha-moment/

[26] "What the Art of Lockpicking Reveals About Human Problem Solving." Brain Health University: https://brainhealthuniversity.com/brain-health-insights/what-the-art-of-lockpicking-reveals-about-human-problem-solving/

[27] Csikszentmihalyi, Mihaly. "Flow: The Psychology of Optimal Experience." Wikipedia overview: https://en.wikipedia.org/wiki/Flow_(psychology); Psychology Today on puzzle enjoyment: https://www.psychologytoday.com/us/blog/the-pathways-experience/202203/why-we-enjoy-puzzles-the-view-play-studies

[28] "Designing a Knowledge Based Puzzle Game." Aalto University thesis: https://aaltodoc.aalto.fi/bitstreams/2eb22671-565f-46ad-a4e9-385947a344fe/download

[29] "Beyond User Control: Exploring Hint System Design and Player Experience." IEEE: https://ieeexplore.ieee.org/document/11034626

[30] "Adaptive Hint System Enhancing User Experience in Puzzle Platformers." DiVA: https://www.diva-portal.org/smash/get/diva2:1875098/FULLTEXT01.pdf

[31] Hao et al. "Multimodal adaptive hint systems." UW Faculty: https://faculty.washington.edu/weicaics/paper/papers/HaoHZC2022.pdf

[32] Sarathy et al. "Using Puzzle Video Games to Study Cognitive Processes in Human Insight." Tufts University / CogSci 2024: https://hrilab.tufts.edu/publications/sarathyetal2024cogsci.pdf

[33] Birdwell, Ken. "The Cabal: Valve's Design Process For Creating Half-Life." Game Developer: https://www.gamedeveloper.com/design/the-cabal-valve-s-design-process-for-creating-i-half-life-i-

---

*End of Puzzle Design Research — Frink, 2026-07-22*
