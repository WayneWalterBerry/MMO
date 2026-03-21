# Room & Environment Design Research

**Version:** 1.0  
**Date:** 2026-07-21  
**Author:** Frink (Researcher)  
**Audience:** Moe (World Builder), game designers, content creators  
**Status:** Research Complete — Ready for Design Review  

---

## Executive Summary

Rooms are the fundamental unit of world-building in interactive fiction. Every player experience happens *inside a room*. This research synthesizes lessons from classic text adventures, immersive sims, real-world architecture, environmental storytelling theory, and multi-sensory design to give Moe a research foundation for building rooms that feel real, tell stories, and create emergent gameplay through our engine's material property system.

The core insight across all sources: **a great room is not a container with a description — it is a character with a personality, a history, and secrets waiting to be discovered.**

---

## Table of Contents

1. [Classic Text Adventure Room Design](#1-classic-text-adventure-room-design)
2. [Immersive Sim Environment Design](#2-immersive-sim-environment-design)
3. [Real Architecture for Game Rooms](#3-real-architecture-for-game-rooms)
4. [Environmental Storytelling](#4-environmental-storytelling)
5. [Multi-Sensory Room Design](#5-multi-sensory-room-design)
6. [Material Properties and Environments](#6-material-properties-and-environments)
7. [Room Design Principles for Our Engine](#7-room-design-principles-for-our-engine)
8. [Sources](#8-sources)

---

## 1. Classic Text Adventure Room Design

### 1.1 Zork and Colossal Cave Adventure

The two foundational text adventures established room design patterns that persist to this day. Both games proved that **words alone can create unforgettable spaces** — no graphics required.

**Colossal Cave Adventure (Crowther & Woods, 1976):**
- Rooms were modeled on the real Mammoth Cave system in Kentucky. Will Crowther was a caver who mapped the real passages, then added fantastical elements (trolls, magic words, treasures) on top of authentic geography [1].
- This grounding in real-world topology gave rooms a **spatial coherence** that players could intuit. The cave "felt right" because it *was* right — winding passages, tight squeezes, underground rivers, and cathedral-sized chambers all followed real speleological patterns.
- The famous "twisty little passages, all alike" sequence demonstrated that **rooms need distinctiveness** — identical rooms are a navigation nightmare, and the phrase has become shorthand for bad room design [2].

**Zork (Infocom, 1977–1980):**
- Zork's rooms mixed domestic spaces (the white house, the living room) with underground fantasia (the Flood Control Dam #3, the crystal grotto). The contrast between mundane and magical made both more memorable [3].
- The Grue — invisible, deadly, lurking in dark rooms — demonstrated that **what a room *doesn't* show can be more powerful than what it does**. Atmosphere through absence is a design principle, not a limitation [3].
- Room descriptions were deliberately concise due to memory constraints, but this brevity became a strength: each word carried weight. "West of House" is three words, yet millions of players can picture it [2].

**Key Principles from Classic IF:**

| Principle | Description | Example |
|-----------|-------------|---------|
| **Economy of words** | Each word in a room description must earn its place | "West of House" — 3 words, instantly iconic |
| **Sensory specificity** | Name concrete sensations, not abstract qualities | "The smell of damp limestone" not "it smells bad" |
| **Distinctiveness** | Every room must be distinguishable from every other | The anti-pattern: "twisty little passages, all alike" |
| **Atmosphere through absence** | What you *don't* describe creates fear and mystery | Dark rooms + Grues = maximum dread from minimum text |
| **Real-world grounding** | Base fantastical spaces on real geography or architecture | Colossal Cave → Mammoth Cave; Zork house → New England homes |
| **Interactive potential** | Every described feature should invite interaction | If you mention a mailbox, the player WILL try to open it |

### 1.2 Inform 7 Community — Modern IF Room Design

The Inform 7 community, building on 50 years of IF tradition, has codified room design into teachable principles. Key sources include Aaron Reed's *Creating Interactive Fiction with Inform 7* and Jim Aikin's *The Inform 7 Handbook* [4][5].

**The Three-Layer Room Description:**
1. **Orientation layer** — Where am I? What kind of space is this? (First sentence)
2. **Atmosphere layer** — How does it feel? What's the mood? (Sensory details)
3. **Interaction layer** — What can I do here? What draws my attention? (Objects, exits)

**Best Practices from the Community:**

- **Two to three strong sensory details** are enough. More overwhelms; fewer leaves the room empty [5].
- **Variable descriptions** that change based on game state keep rooms alive across revisits. A room should acknowledge what has changed since the player last visited [5].
- **Scenery vs. interactive objects** must be clearly distinguished. Mark background details as scenery so the parser doesn't confuse players by listing them separately [4].
- **Room names matter.** "The Kitchen" tells you function. "Mrs. Haversham's Kitchen" tells you character. "The Kitchen That Time Forgot" tells you story [4].
- **Exits should be narratively motivated.** Don't just say "exits are north and south." Say "A narrow passage leads north into darkness. To the south, lamplight spills from an open doorway" [5].

### 1.3 Emily Short — "Room as Character"

Emily Short, one of interactive fiction's most influential designers and critics, has articulated the principle that **rooms should be designed with the same care as characters** — because they serve the same narrative function [6].

**Key Ideas:**

- **Rooms have personality.** A cluttered workshop and a pristine laboratory both tell you about their occupants without a word of dialogue. The room IS the character introduction [6].
- **Rooms have mood.** The description sets emotional expectations. A room described with warm language (golden light, worn leather, crackling fire) creates comfort. Cold language (grey stone, iron bars, dripping water) creates dread [6].
- **Rooms have history.** The most compelling rooms show evidence of what happened before the player arrived — a half-eaten meal, an overturned chair, a bloodstain on the floor. These are not decorations; they are narrative [6].
- **Rooms change.** A room that never changes is furniture, not character. The best rooms respond to player actions — not just through object state, but through shifts in atmosphere, description, and available interactions [6].
- **Selective detail creates focus.** Describe only what matters. If you mention a crack in the wall, the player will try to examine it. Every detail is an implicit promise of interactivity [6].

**Applicability to Our Engine:**
Our dynamic room description system (see `docs/architecture/rooms/dynamic-room-descriptions.md`) already implements the core technical pattern Short advocates: rooms describe permanent features, objects contribute their own presence, and the composition updates automatically when objects change state. What Moe needs to internalize is the *authorial* principle: write rooms as characters, not containers.

---

## 2. Immersive Sim Environment Design

### 2.1 Looking Glass Studios — Thief & System Shock

Looking Glass Studios (1990–2000) created the immersive sim genre with games whose environments were designed as **simulated worlds, not themed corridors** [7][8].

**System Shock (1994):**
- Citadel Station was a multi-level space station where every room had a logical function — medical bays, engineering decks, crew quarters, maintenance shafts. The station felt real because it was designed as a *place people would actually live and work* [8].
- Non-linear traversal: players could revisit any area, discovering new paths as they gained abilities. Rooms were interconnected, not isolated [8].

**Thief: The Dark Project (1998):**
- Environments told stories through architecture, lighting, and scattered objects — a guard's half-eaten dinner, a love letter tucked behind a painting, contraband hidden in a secret compartment [7].
- Audio was environment design: different floor surfaces (stone, wood, metal, carpet) produced different footstep sounds, turning room materials into gameplay mechanics [7].
- The "every room tells a story" philosophy: even a simple storage closet had personality — what's stored there, how organized (or messy) it is, what's hidden behind the obvious [7].

### 2.2 Arkane Studios — Dishonored & Prey

Arkane Studios carried the Looking Glass torch into the modern era, refining environmental storytelling into a science [9].

**Dishonored (2012):**
- Dunwall's rooms are "interconnected sandboxes" — every room offers multiple entry/exit points (door, window, vent, rooftop, rat tunnel), supporting different playstyles [9].
- Social hierarchy is visible in room design: the aristocrats' apartments have rich furnishings and tall windows, while the plague-ridden poor live in collapsing tenements with boarded windows and rat-gnawed furniture [9].
- **The "lived-in" principle:** Arkane's rooms contain personal items that have no gameplay function but enormous narrative function — family photographs, children's drawings on a desk, a bottle of whiskey and two glasses suggesting a private meeting [9].

**Prey (2017):**
- Talos I is a single contiguous environment where every room is connected. Players can revisit any area at any time, discovering new details as their understanding (and abilities) grow [9].
- Offices contain emails, personal items, and environmental clues that build a picture of the station's inhabitants. A coffee mug, a sticky note, a personal photo — these are the environmental storytelling equivalent of character development [9].

**Key Principles from Immersive Sims:**

| Principle | Description |
|-----------|-------------|
| **Functional realism** | Every room should have a plausible real-world purpose |
| **Multiple approaches** | Rooms should support different ways to enter, explore, and exit |
| **Lived-in clutter** | Personal items, mess, and wear make rooms feel inhabited |
| **Material as gameplay** | Floor surfaces, wall materials, and objects have mechanical consequences |
| **Interconnected spaces** | Rooms should connect to form a coherent, navigable whole |
| **Asymmetric information** | Different approaches reveal different details about the same room |

### 2.3 The "Every Room Tells a Story" Principle

The common thread across all immersive sims is that **no room is "just a room."** Even a maintenance closet tells the story of who maintains this building, what tools they use, and what they've been neglecting. Harvey Smith (Dishonored creative director) has described this as "narrative archaeology" — the player excavates meaning from the environment the way an archaeologist reads a dig site [9].

**For Our Engine:**
This maps directly to our `room_presence` system. Every object in a room contributes a sentence describing how it appears. The world builder's job is to choose objects whose combined presences tell a coherent story. A bedroom with a neatly made bed, a pressed uniform on a hanger, and polished boots tells one story. The same bedroom with tangled sheets, empty bottles, and a letter torn in half tells a very different one.

---

## 3. Real Architecture for Game Rooms

### 3.1 Medieval Manor House Layout

Understanding how real medieval buildings were organized gives room design spatial logic and architectural authenticity [10][11][12].

**The Core Flow:**
```
Main Entrance → Screens Passage → Great Hall
                                    ├── (Dais end) → Stairs → Solar → Lord's Bedchamber / Bower
                                    └── (Service end) → Pantry / Buttery → Kitchen (often detached)
                                                         └── Below: Cellars / Undercroft
```

**Key Rooms of a Medieval Manor:**

| Room | Function | Character | Materials |
|------|----------|-----------|-----------|
| **Great Hall** | Dining, entertaining, sleeping (servants), court | Grand, smoky, noisy, central to all life | Stone walls, oak beams, rush-covered floor, massive hearth |
| **Solar** | Lord's private family room, withdrawing room | Quiet, warm, bright (south-facing windows) | Wood-paneled walls, tapestries, cushioned seats |
| **Buttery** | Ale and drink storage/dispensing | Cool, damp, smells of yeast and hops | Stone or wood, barrels, flagstone floor |
| **Pantry** | Bread and dry goods storage | Dry, dusty, smells of flour and dried herbs | Wood shelves, stone floor, cloth-covered goods |
| **Kitchen** | Cooking (often detached for fire safety) | Hot, smoky, chaotic, loud | Stone hearth, iron pots, wood tables, soot-stained walls |
| **Cellar/Undercroft** | Wine, beer, perishable storage | Cold, dark, damp, low ceilings | Stone vaults, earth floor, iron-banded doors |
| **Bower** | Lady's private rooms | Feminine, bright, textile-rich | Embroidered hangings, spinning wheel, cushioned window seat |
| **Chapel** | Worship | Hushed, incense-scented, candlelit | Stone, wood pews, painted or carved altar |
| **Guardroom** | Security, weapons storage | Martial, utilitarian, smells of leather and oil | Stone, weapon racks, wooden benches, iron brazier |

### 3.2 Castles — Fortified Spaces

Castles add defensive architecture to the manor pattern [11][13]:

- **Keep/Donjon:** The innermost fortification, containing the lord's quarters, treasury, and last-resort defenses. Rooms are stacked vertically — cellar/dungeon at bottom, hall in the middle, private chambers at top.
- **Curtain walls and towers:** Defensive walkways connecting corner towers. Guard rooms, arrow slits, murder holes.
- **Gatehouse:** The controlled entry point with portcullis, drawbridge mechanism, and guard chambers.
- **Spiral staircases:** Clockwise ascending (to disadvantage right-handed attackers climbing upward).
- **Hidden passages:** Secret doors behind tapestries, priest holes, escape tunnels. More common in castles than manors but present in grander homes.
- **Corridors within walls:** Servants' passages allowing movement without disturbing the lord's family. Castles often had these running behind the main rooms [13].

### 3.3 Dungeons and Underground Spaces

The game-design "dungeon" draws from multiple real sources [13]:

- **Castle dungeons (oubliettes):** Tiny, dark, underground cells with a single opening above. No furnishing except perhaps manacles and straw.
- **Natural caves:** Irregular spaces with stalactites, underground streams, and passages that narrow or widen unpredictably (cf. Colossal Cave Adventure).
- **Mines:** Regular tunnels with timber supports, cart tracks, tool storage alcoves.
- **Sewers/Catacombs:** Arched stone tunnels, often partially flooded, with niches, junctions, and occasional larger chambers.

### 3.4 Cottages and Humble Dwellings

The other end of the social spectrum [14][15]:

- **Structure:** Timber frame, wattle-and-daub walls, thatched roof. Often a single room or two rooms (hall and chamber).
- **Floors:** Packed earth covered with rushes or straw.
- **Furnishings:** Extremely simple — a table, stools (not chairs), a straw mattress, a chest, a cooking pot over the central hearth.
- **Textiles:** Homespun wool and linen. No tapestries; perhaps a rough blanket hung for warmth.
- **Lighting:** Rushlights (rush dipped in tallow) or a single candle. Windows were small openings with wooden shutters, not glass.

### 3.5 How Rooms Connect

Real buildings have **purposeful connections** [10][11]:

- **Screens passage:** A cross-passage separating the great hall from service areas. Hides kitchen smells and noise from the dining hall.
- **Newel stairs:** Tight spiral staircases connecting floors, often within wall thickness.
- **Corridors:** Late medieval innovation; earlier buildings used rooms-opening-into-rooms (enfilade).
- **Service passages:** Hidden routes for servants to move food, chamber pots, and supplies without crossing public spaces.
- **Hidden doors:** Behind tapestries, within wood paneling, under flagstones. Used for security, escape, or illicit meetings.

**Relevance to Our Exit System:**
Our exit architecture (see `docs/architecture/rooms/room-exits.md`) supports all of these connection types. Each exit is a first-class object with type, constraints, visibility, and mutation potential. A screens passage is a `doorway` type; a hidden door behind a tapestry is a `secret passage` with `hidden = true` that becomes visible when the tapestry is moved.

---

## 4. Environmental Storytelling

### 4.1 Academic Definition

Henry Jenkins, in his seminal 2004 paper "Game Design as Narrative Architecture," defined environmental storytelling as the process where game spaces:

1. **Evoke** pre-existing narrative associations (a ruined castle triggers Gothic expectations)
2. **Enact** narrative events (the player witnesses or participates in story moments)
3. **Embed** narrative information within their mise-en-scène (objects, notes, environmental details)
4. **Enable** emergent narratives (player actions create unique stories) [16]

Don Carson, a former Walt Disney Imagineer, further described it as "staging the player's experience through the world" — placing story elements where the player will naturally look, creating a **guided discovery** that feels like personal exploration [17].

### 4.2 Game Examples

**BioShock (2007) — Rapture as Narrative:**
- The underwater city of Rapture tells its story through Art Deco architecture crumbling into ruin. A dining table still set for a meal next to a corpse. A child's teddy bear abandoned in a corner. Propaganda posters peeling from water-damaged walls [18].
- The environment communicates "sudden catastrophe" without a single line of expository dialogue. Players reconstruct the timeline from spatial evidence.
- Audio logs supplement but don't replace the environmental narrative — the room itself is the primary text.

**Gone Home (2013) — Domestic Archaeology:**
- The entire game is exploring an empty family house. Every room tells part of the family's story through arrangement and placement of everyday objects [19].
- A hidden locker contains personal letters. Family photos are displayed or tucked away depending on relationships. A parent's record collection tells you their era and taste.
- The game demonstrates that **mundane objects in deliberate arrangements are as narratively powerful as dramatic set-pieces** [19].

**What Remains of Edith Finch (2017) — Rooms as Shrines:**
- Each family member's bedroom is preserved exactly as it was at the time of their death. The arrangement of items — books, toys, hobby materials — combined with unique room layouts, colors, and lighting, evokes each character's personality [20].
- Rooms are *characters*. Gregory's bathroom is playful and colorful. Lewis's bedroom is cluttered with escapist fantasy. Calvin's room is full of daring adventure paraphernalia [20].
- The game proves that **room design IS character design** in environmental storytelling.

### 4.3 The "Show Don't Tell" Principle

Environmental storytelling is the spatial application of the oldest writing rule: **show, don't tell** [17][18].

| "Tell" (Bad) | "Show" (Good) |
|---------------|---------------|
| "A battle was fought here" | Broken weapons, scarred walls, dark stains on the floor |
| "The owner was wealthy" | Gilt-framed paintings, imported rugs, silver candlesticks |
| "Someone left in a hurry" | An overturned chair, a half-packed trunk, a meal going cold |
| "This room is dangerous" | Claw marks on the door, scratching sounds from within, a foul smell |
| "The previous occupant was scholarly" | Overflowing bookshelves, ink-stained desk, astronomical charts on the wall |

### 4.4 Object Placement as Narrative

The key technique in environmental storytelling is **deliberate object placement** — what objects are in the room, where they are, and what condition they're in [17][18][19]:

- **Juxtaposition:** A child's toy next to a weapon tells a story of lost innocence.
- **Absence:** An empty picture frame, a missing book from a shelf, a bare hook on the wall.
- **Condition:** A freshly made bed vs. tangled sheets. A polished sword vs. a rusted one. A full wine glass vs. an empty bottle.
- **Arrangement:** Objects in neat rows suggest order and control. Scattered objects suggest chaos or haste.
- **Accumulation:** Multiple empty bottles suggest a habit. A stack of unsent letters suggests isolation.

**For Our Engine:**
Every object in our system has a `room_presence` field that describes how it appears at a glance. The world builder's job is to select and describe objects so that their combined presences create a narrative. The engine handles composition; the human handles meaning.

---

## 5. Multi-Sensory Room Design

### 5.1 How Rooms Sound

Sound is deeply affected by room materials, size, and contents. In a text game, we describe these sounds rather than playing them — but the principles of real acoustics should inform our descriptions [21][22].

| Room Type | Acoustic Character | Description Keywords |
|-----------|-------------------|---------------------|
| **Stone cellar** | Hard reflections, pronounced echo, cold reverb | Echoing, hollow, booming, dripping, resonant |
| **Wood-paneled study** | Warm, muffled, soft creaks | Creaking, muted, warm, settling, hushed |
| **Carpeted bedroom** | Sound-absorbing, intimate, quiet | Muffled, soft, still, intimate, whispered |
| **Grand stone hall** | Cathedral-like reverb, footsteps carry | Cavernous, reverberant, thundering, vast |
| **Outdoor courtyard** | Open, sound dissipates, wind carries | Breezy, open, birdsong, distant, scattered |
| **Narrow tunnel** | Compressed sound, amplified breathing | Tight, compressed, amplified, close, pressing |

**Design Rule:** A room's acoustic character should match its materials. Stone echoes. Wood creaks. Fabric muffles. Glass rings. If a room has stone walls and a wooden floor, the sound should split — footsteps thud on wood while voices echo off stone [21][22].

### 5.2 How Rooms Smell

Smell is the most evocative sense and the least used in game design. For a text game, smell is pure text — and text is our medium [23].

| Room Type | Primary Smells | Secondary/Seasonal |
|-----------|---------------|-------------------|
| **Kitchen** | Smoke, roasting meat, baking bread, grease | Herbs drying, spilled ale, rendered fat |
| **Cellar** | Must, damp earth, old wood, mildew | Vinegar, stored root vegetables, mouse droppings |
| **Bedroom** | Lavender, tallow, wool, body warmth | Dried flowers, dust, stale air (if closed) |
| **Library/Study** | Old paper, leather, ink, dust | Pipe smoke, beeswax polish, wood oil |
| **Chapel** | Incense, cold stone, candle wax | Flowers, old wood, damp cloth |
| **Dungeon** | Damp stone, rot, rust, unwashed bodies | Blood (iron), mold, straw, fear-sweat |
| **Garden/Courtyard** | Soil, flowers, cut grass, rain | Compost, herb beds, pond water |
| **Forge/Workshop** | Hot metal, coal, oil, leather | Quenching steam, sweat, wood shavings |

**Design Rule:** Every room should have a **primary scent** noted in its permanent description. Secondary scents come from objects (a lit candle adds tallow smell; flowers add fragrance). Our sensory system (Principle 6: Objects Exist in Sensory Space) already supports this — rooms need to use it [23].

### 5.3 How Rooms Feel in Darkness

When light sources are absent or extinguished, the player loses sight but gains other senses [3][21]:

- **Temperature becomes dominant:** Cold stone under bare feet. Warm wood paneling against a searching hand. Damp earth between fingers.
- **Touch reveals material:** Rough-hewn stone vs. smooth marble. Splintery wood vs. polished oak. Gritty sand vs. slippery moss.
- **Sound intensifies:** Every creak, drip, and breath becomes significant. The player "hears" the room's size — a tight space muffles sound; a vast space creates echo.
- **Proprioception:** The player's sense of their body in space — stooping in a low tunnel, reaching arms wide in an open chamber, bumping into unseen furniture.

**Design Rule:** Every room should have a **darkness description** that emphasizes non-visual senses. When the light goes out, the room doesn't disappear — it transforms. The stone walls are still cold. The wooden floor still creaks. The cellar still smells of damp earth. These sensory anchors tell the player "you are still HERE" even when sight fails.

### 5.4 Our Multi-Sensory Advantage

Our engine's Principle 6 (Objects Exist in Sensory Space; State Determines Perception) is a **competitive advantage** that most games — even text games — underuse. We have 5 sensory channels for every object and every room:

| Sense | Room Application | Object Application |
|-------|-----------------|-------------------|
| **Sight** | Room description, room_presence | Object description, visual state |
| **Sound** | Ambient sounds (dripping, creaking, wind) | Object sounds (ticking clock, crackling fire) |
| **Smell** | Room scent (must, smoke, lavender) | Object scent (tallow candle, leather book) |
| **Touch** | Temperature, humidity, floor texture | Object texture (rough stone, smooth glass) |
| **Taste** | Rare — air quality (salt spray, dusty) | Object taste (food, drink, poison) |

**Moe's Opportunity:** Design rooms where **multiple senses reinforce a single mood**. A cellar isn't just dark — it's cold (touch), damp (touch), musty (smell), dripping (sound), and dim (sight). Each sense adds a layer of immersion that no single description could achieve.

---

## 6. Material Properties and Environments

### 6.1 How Our Material Property System Enables Environmental Consistency

Our material property system (see `docs/design/material-properties-system.md`) gives every material numeric properties — density, melting point, ignition point, hardness, conductivity, flammability, and more. These properties don't just affect individual objects; they define **how entire rooms behave** [24].

**The Key Insight:** When rooms are built from specific materials, the material properties cascade into the room's environmental character:

| Room Material | Temperature | Humidity | Fire Risk | Sound | Feel |
|---------------|-------------|----------|-----------|-------|------|
| **Stone** | Cold (high conductivity) | Can be damp | Very low | Echoing | Hard, unyielding |
| **Wood** | Warm (low conductivity) | Dry | High (flammability 0.5) | Creaking, warm | Organic, yielding |
| **Earth** | Cool, stable | Damp | None | Muffled | Soft, gritty |
| **Metal** | Very cold (highest conductivity) | Condensation | None | Ringing, clanging | Hard, smooth |

### 6.2 Environmental Scenarios

**A Stone Cellar:**
- **Temperature:** Cold. Stone conducts heat away from the body (`conductivity = high`). Iron fittings are freezing to touch.
- **Humidity:** Damp. Stone doesn't absorb moisture (`absorbency = 0.0`), so water beads on walls and puddles on floors.
- **Material interactions:** Iron rusts faster in this damp environment (`rust_susceptibility` in Phase 2). Wax candles burn slowly (cool air). Paper deteriorates (damp + low temperature).
- **Gameplay consequence:** A player who brings a wax candle into a cold cellar finds it lasts longer (lower ambient temperature = slower melting). But any iron tools left here will eventually rust.

**A Wooden Bedroom:**
- **Temperature:** Warm. Wood insulates (`conductivity = low`). With a fireplace, the room holds heat.
- **Humidity:** Dry. Wood absorbs some moisture (`absorbency = 0.3`), keeping air comfortable.
- **Material interactions:** High fire risk if an open flame is left unattended (`flammability = 0.5`). Fabric furnishings (curtains, bedding) are even more flammable (`flammability = 0.6-0.7`).
- **Gameplay consequence:** A lit candle left on a wooden nightstand near fabric curtains creates real danger. The material system enables this — no special-case fire scripting needed.

**A Forge/Workshop:**
- **Temperature:** Hot. Metal and fire dominate. Stone floor and walls resist heat but radiate it.
- **Material interactions:** Iron can be heated and shaped. Wax melts near the forge. Wood handles must be kept away from the heat source.
- **Gameplay consequence:** The forge environment enables emergent crafting interactions. Bringing raw materials into a hot environment triggers threshold-based state changes automatically.

### 6.3 The Material Consistency Principle

Our proposed design principle (R-MAT-3) states: **all objects of the same material behave identically under the same conditions**. This extends to rooms [24]:

- If wax melts near fire, ALL wax in the room melts — candles, sealing wax, wax figurines.
- If iron rusts in damp conditions, ALL iron in the room rusts — keys, hinges, sword blades, candelabras.
- If wood burns, ALL wood in the room is at risk — furniture, doors, wooden beams, bookshelves.

**Why This Matters for Room Design:** Moe must think about **what materials are in the room** when designing it, because the material system will enforce consistency. A room full of wooden furniture near an open hearth is a fire hazard. A cellar full of iron fittings will slowly rust. This isn't a bug — it's emergence.

---

## 7. Room Design Principles for Our Engine

### 7.1 Concrete Principles for Moe

Based on all research above, here are actionable room design principles:

#### Principle R1: Every Room Is a Character
A room has personality, mood, and history. Before writing a single line of description, answer: **Who lived here? What happened here? What do they want the visitor to feel?** These answers drive every subsequent design decision.

*Source: Emily Short's "room as character" philosophy [6]; What Remains of Edith Finch's rooms-as-shrines approach [20].*

#### Principle R2: Description = Permanent Features Only
Room `description` contains ONLY immovable, permanent architecture: walls, floor, ceiling, alcoves, ambient atmosphere. NEVER reference any object in `contents`. Objects contribute their own `room_presence` sentences.

*Source: Our dynamic room description architecture. Already codified in `docs/architecture/rooms/dynamic-room-descriptions.md`.*

#### Principle R3: Three Sensory Details, Minimum
Every room description must engage at least three senses. Sight is default; add sound and smell at minimum. Touch and taste are bonus channels for distinctive rooms.

*Source: Classic IF sensory design [1][2][3]; multi-sensory design research [21][22][23].*

#### Principle R4: Material Drives Environment
Choose the room's primary material FIRST (stone, wood, earth, metal). This determines temperature, humidity, acoustic character, fire risk, and sensory palette. Then fill in details that are consistent with that material.

*Source: Material properties system research [24]; immersive sim material-as-gameplay principle [7].*

#### Principle R5: Objects Tell the Story
The room description sets the stage. The objects IN the room tell the story. Choose objects whose combined `room_presence` sentences create a narrative. A neatly made bed + polished boots = discipline. Tangled sheets + empty bottles = despair.

*Source: Environmental storytelling research [16][17][18][19][20]; "show don't tell" principle.*

#### Principle R6: Exits Are Architecture
Exits should reflect the building's real structure. A medieval manor connects through screens passages, spiral stairs, and service corridors — not arbitrary compass directions. Every exit should have a physical description that tells the player what kind of passage it is.

*Source: Real architecture research [10][11][12][13]; our exit architecture in `docs/architecture/rooms/room-exits.md`.*

#### Principle R7: Design for Darkness
Every room should have an implicit "dark version" — what would the player experience here with no light? Cold stone underfoot, the sound of dripping water, the smell of damp earth. If you can't imagine your room in darkness, it lacks sensory depth.

*Source: Zork's Grue darkness [3]; multi-sensory design [21].*

#### Principle R8: Rooms Create Puzzle Opportunities
Every room should contain at least one latent interaction that a puzzle designer (Bob) can exploit. A fireplace suggests fire puzzles. A locked door suggests key puzzles. A window suggests escape/entry puzzles. A material contrast (iron in a damp room) suggests environmental puzzles.

*Source: Classic IF interactive potential [1][2]; material properties emergence [24].*

#### Principle R9: Interconnected, Not Isolated
Rooms exist in a topology. Design rooms knowing what's adjacent. A kitchen should be near the great hall (service flow). A cellar should be below the buttery (gravity). A guard room should be near the gate (defense). Spatial logic makes the world navigable without a map.

*Source: Real architecture [10][11]; immersive sim interconnection principles [7][8][9].*

#### Principle R10: Economy of Words
Every word in a room description must earn its place. Three vivid sentences beat three bland paragraphs. If a player must read your room description on every visit, make it worth reading — and make it fast.

*Source: Classic IF economy [1][2][3]; Inform 7 community best practices [4][5].*

### 7.2 Mapping to Our 8 Architecture Principles

| Engine Principle | Room Design Application |
|-----------------|------------------------|
| **P1: Code-Derived Mutable Objects** | Rooms are Lua tables. Room state can change (damage, flooding, fire) through mutation |
| **P2: Base Objects → Instances** | Room templates provide structural defaults; instances add unique character |
| **P3: FSM on Objects** | Room objects have state machines (door open/closed, fire lit/unlit) that change the room's character |
| **P4: Composite Objects** | Rooms contain objects which contain sub-objects (desk → drawer → letter). Layered discovery |
| **P5: Multiple Instances** | The same room template could be instantiated multiple times (identical guard rooms in a castle) |
| **P6: Sensory Space** | Rooms ARE sensory spaces. Every sense channel should be used. State changes alter perception |
| **P7: Spatial Relationships** | Rooms define the spatial graph of the world. Exits are spatial relationships with constraints |
| **P8: Engine Executes Metadata** | Room properties (material, temperature, humidity) are metadata the engine can process for emergent behavior |

### 7.3 Room Layout Patterns

Different spatial patterns create different player experiences [25][26]:

**Linear:**
```
[A] → [B] → [C] → [D]
```
- Best for: Tutorials, horror sequences, story-critical moments
- Player feels: Guided, focused, sometimes trapped
- Our use: Opening sequence, escape sequences, narrow passages

**Hub-and-Spoke:**
```
        [B]
         |
[A] ← [HUB] → [C]
         |
        [D]
```
- Best for: Base camps, central halls, exploration anchors
- Player feels: Free to choose, oriented, safe at the hub
- Our use: Great Hall as hub with rooms branching off. The player can explore in any order but always returns to the familiar center
- Classic IF precedent: Zork's underground hub, Mario 64's Peach's Castle

**Branching:**
```
[A] → [B] → [C]
       ↓
      [D] → [E]
```
- Best for: Choices with consequences, multiple paths to objectives
- Player feels: Empowered, anxious about missed content
- Our use: Castle with multiple wings, each with its own theme and challenge

**Loop/Circuit:**
```
[A] → [B] → [C]
 ↑              ↓
[F] ← [E] ← [D]
```
- Best for: Revisiting areas with new context, Metroidvania-style progression
- Player feels: Oriented (landmarks), rewarded for remembering
- Our use: Cellar/tunnel networks that loop back, castle walls that circle

**Layered/Vertical:**
```
[Attic]
   ↕
[Upper Floor]
   ↕
[Ground Floor]
   ↕
[Cellar]
   ↕
[Dungeon]
```
- Best for: Social hierarchy (lord at top, prisoners at bottom), temperature gradients
- Player feels: Ascending = progress/escape; descending = danger/discovery
- Our use: Castle keep, tower, mine shaft

### 7.4 How Rooms Create Puzzle Opportunities

Based on the puzzle research patterns, here are room-puzzle connections for Bob:

| Room Feature | Puzzle Opportunity | Material System Interaction |
|-------------|-------------------|---------------------------|
| Fireplace/hearth | Fire puzzles (light/extinguish/fuel) | Flammability, ignition_point thresholds |
| Locked door | Key puzzles, breaking (hardness check) | Material hardness determines breakability |
| Window | Escape/entry, size constraints on exits | Max_carry_size on exit object |
| Water feature | Flooding, rust, extinguishing fire | Absorbency, rust_susceptibility |
| Wooden furniture | Fuel for fire, barricade materials | Flammability, density (weight) |
| Metal fixtures | Conduct heat/cold, resist fire, rust | Conductivity, rust_susceptibility |
| Fabric/textiles | Absorb liquids, fuel fire, muffle sound | Absorbency, flammability |
| Secret passage | Discovery puzzles, hidden exits | `hidden = true` on exit, revealed by interaction |
| Material contrasts | Environmental puzzles (damp + iron = rust) | Threshold auto-transitions |
| Vertical connections | Access puzzles (ladder, rope, climbing) | Exit type constraints, requires_hands_free |

---

## 8. Sources

1. Crowther, W. & Woods, D. "Colossal Cave Adventure" (1976). MUD Wiki: https://mud.fandom.com/wiki/Colossal_Cave_Adventure
2. Montfort, N. *Twisty Little Passages: An Approach to Interactive Fiction*. MIT Press, 2003. Academic analysis: https://www.academia.edu/4367077/
3. Blank, M. & Lebling, D. "Zork" (1977–1980). Infocom. Maps and analysis: https://eblong.com/infocom/maps/
4. Reed, A. *Creating Interactive Fiction with Inform 7*. Cengage, 2010. Companion site: http://inform7.textories.com/
5. Aikin, J. *The Inform 7 Handbook*. https://inform-7-handbook.readthedocs.io/
6. Short, E. Blog posts on room design and interactive fiction craft. https://emshort.blog/
7. Looking Glass Studios. *Thief: The Dark Project* (1998). Retrospective: https://www.pcgamesn.com/thief-the-dark-project/retrospective
8. Looking Glass Studios. *System Shock* (1994). Wikipedia: https://en.wikipedia.org/wiki/System_Shock
9. Arkane Studios. *Dishonored* (2012), *Prey* (2017). Legacy analysis: https://finalweapon.net/2023/05/22/the-legacy-of-immersive-sims/
10. Castles and Manor Houses. "Castle Life — Rooms in a Medieval Castle." https://www.castlesandmanorhouses.com/life_01_rooms.htm
11. Britain Express. "Medieval Manors in England." https://www.britainexpress.com/architecture/medieval-manors.htm
12. Wikipedia. "Solar (room)." https://en.wikipedia.org/wiki/Solar_(room)
13. Historic European Castles. "Rooms in a Medieval Castle." https://historiceuropeancastles.com/rooms-in-a-medieval-castle/
14. Britannica. "Interior Design — Late Medieval Europe." https://www.britannica.com/art/interior-design/Late-medieval-Europe
15. Lady of Legend. "Manor Components." https://ladyoflegend.com/manor-components/
16. Jenkins, H. "Game Design as Narrative Architecture." *First Person: New Media as Story, Performance, and Game*, MIT Press, 2004. https://scalar.usc.edu/works/interactive-storytelling-narrative-techniques-and-methods-in-video-games/environmental-storytelling
17. Carson, D. "Environmental Storytelling: Creating Immersive 3D Worlds Using Lessons Learned from the Theme Park Industry." Gamasutra, 2000. Overview: https://gamedesignskills.com/game-design/environmental-storytelling/
18. 2K Games. *BioShock* (2007). Academic analysis: https://dl.digra.org/index.php/dl/article/download/799/799
19. The Fullbright Company. *Gone Home* (2013). Design analysis: https://pixune.com/blog/environmental-storytelling-in-games/
20. Giant Sparrow. *What Remains of Edith Finch* (2017). Narrative analysis: https://www.rpgfan.com/feature/narrative-design-analysis-what-remains-of-edith-finch/
21. The Vero Stone. "Sound and Stone: How Natural Materials Impact Acoustics." https://www.theverostone.com/post/sound-and-stone-how-natural-materials-impact-acoustics-in-interior-spaces
22. Cannon System Design. "The Science of Sound: Why Some Spaces Just Sound Better." https://www.cannonsystem.design/post/the-science-of-sound
23. IntechOpen. "Environmental Storytelling in Video Games: Crafting Narratives beyond Dialogue." https://www.intechopen.com/chapters/1225186
24. Frink. "Material Properties System — Design Document." Internal: `docs/design/material-properties-system.md`
25. The Level Design Book. "Typology." https://book.leveldesignbook.com/process/layout/typology
26. Blueprint Bard. "Dungeon Layout Strategies — Designing Maps That Enhance Gameplay." https://www.blueprintbard.com/resources/dungeon-layout-strategies-designing-maps-enhance-gameplay

---

*Frink — Researcher*  
*"A room is not a container with a description. It is a character with a personality, a history, and secrets."*
