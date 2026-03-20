# Puzzle 01: The Bedroom Escape

## Overview

The bedroom is not a single puzzle — it's a **complete introductory environment** that teaches core game systems through spatial exploration, object interaction, and resource management. The player wakes at 2 AM in total darkness on a bed in an unfamiliar room and must escape by finding a hidden trap door beneath the rug. Along the way, they discover light sources, identify hazards, manage inventory, perform crafting, and encounter optional content ranging from comedic interactions to real mechanical depth.

**Core Pillars:**
- **Darkness as a system:** Navigation without sight using FEEL, SMELL, LISTEN
- **Tools enabling verbs:** Matches enable STRIKE; fire enables LIGHT; needle enables SEW
- **Spatial discovery:** Moving objects reveals what's underneath (trap door under rug)
- **Resource scarcity:** Limited matches, temporary light, inventory constraints
- **Optional depth:** Multiple paths to escape, comedic side content, crafting mechanics

## Room: The Bedroom

### Spatial Layout

The bedroom is a single, enclosed space. The player wakes on a bed. Major objects and their relationships:

- **Bed** — player's starting location. Sits ON the rug.
- **Rug** — covers the floor. The trap door is hidden UNDER it. Pulling/moving the rug reveals the trap door.
- **Trap door** — beneath the rug, sealed when discovered. Requires a brass key to open. Exit point to Room 2.
- **Nightstand** — beside the bed (or against wall). Contains drawer with matchbox, candle, poison bottle. Top surface holds more objects.
- **Wardrobe** — tall storage furniture. Contains cloak, sack (with needle and thread), sewing manual.
- **Window with curtains** — provides natural daylight after 6 AM (in-game time).
- **Desk** — writing surface with pen, paper, ink bottle.
- **Chair** — seating, may be movable.
- **Mirror** — reflective surface, breakable.
- **Walls, floor, door (locked)** — non-interactive scaffolding.
- **Books, painting, lamp** — flavor and optional interaction.
- **Chamber pot** — toilet equivalent, comedic interactivity.

### Object Inventory (Comprehensive)

**Light Sources:**
- Matchbox (container with 7 matches + has_striker property)
- Individual match (consumable, becomes match-lit when struck)
- Match-lit (temporary fire source, burns ~30 game seconds, consumed when used to light something)
- Candle (on nightstand, lights with fire source, casts light for ~100 game turns)
- Window/natural light (after 6 AM, no tools required)

**Containers & Furniture:**
- Nightstand (has drawer, may be movable)
- Nightstand drawer (detachable, holds contents)
- Wardrobe (has contents: cloak, sack with needle/thread, sewing manual)
- Sack (holds needle, thread; wearable as silly helmet or blindfold)
- Desk (may have drawer, holds pen/paper/ink)

**Hazards:**
- Poison bottle (cork stopper, deadly if TASTE, warning via SMELL/LOOK)
- Cork (removed from poison bottle, detachable, becomes fishing float)

**Craft Materials:**
- Needle (from sack, enables sewing with thread)
- Thread (from sack, enables sewing with needle)
- Cloth (obtainable via sewing, can be crafted into garment)
- Pen (for writing)
- Paper (for writing)
- Ink bottle (for writing; may be replaceable with blood)

**Wearables/Silly Items:**
- Cloak (from wardrobe, wearable as garment)
- Sack (from wardrobe, wearable as blindfold or helmet, contains needle/thread)
- Chamber pot (wearable as helmet for comedy)

**Documentation:**
- Sewing manual (teaches sewing skill if read)
- Books on shelf (flavor, optional reading)

**Mechanical:**
- Brass key (obtained from beneath rug with trap door, unlocks trap door)
- Trap door (sealed, requires brass key, exit)
- Drawer (in nightstand and desk, detachable)
- Rug (movable, reveals trap door)
- Curtains (openable, reveal window and daylight after 6 AM)
- Mirror (possibly breakable for sharp object or flavor)
- Lamp (non-functional or simple light source)

## Critical Path: Minimum Steps to Escape

This is the fastest route from wake-up to trap door exit. Assumes player knows what they're doing.

### Act 1: Light the Room (5–10 minutes real time)

1. **WAKE in darkness** — Player begins on bed at 2 AM. Total darkness. Can see nothing.
2. **FEEL around** — Use sensory verb (FEEL) to explore the room by touch. Discover the nightstand beside the bed.
3. **FEEL nightstand** — Discover nightstand has a drawer. Discover candle sitting on top.
4. **OPEN nightstand drawer** — Drawer opens, revealing matchbox inside.
5. **TAKE matchbox** — Matchbox enters player's inventory.
6. **OPEN matchbox** — Reveals 7 individual matches inside. Each is an object.
7. **TAKE match** — Take one match from matchbox into inventory.
8. **STRIKE match ON matchbox** — Compound action: match head meets matchbox striker. Match ignites, becomes match-lit. Small flame provides light in immediate area for ~30 game seconds.
9. **LIGHT candle WITH match** — Apply lit match to candle. Candle ignites, becomes candle-lit. Provides brighter light, lasts ~100 game turns. Room is now illuminated.

### Act 2: Find the Brass Key (5–15 minutes real time)

10. **LOOK around** — Now that it's light, visually inspect the room. See all objects, walls, furniture clearly.
11. **PUSH bed** or **MOVE bed** — Bed is sitting on the rug. Push it off the rug to clear the rug area.
12. **PULL rug** or **MOVE rug** — Rug was covering something. As it's moved, **trap door is revealed**. Also visible: brass key sitting on or near trap door.
13. **TAKE brass key** — Pick up the key. It's now in inventory.

### Act 3: Escape (1–2 minutes real time)

14. **OPEN trap door WITH brass key** — Insert key, turn, trap door unseals.
15. **CLIMB DOWN** or **DESCEND** into trap door — Exit Room 1, enter Room 2 (or next level).

**Total time for critical path:** ~15–30 minutes real time (including reasonable exploration and experimentation).

## Puzzle Mechanics: The Systems at Work

### 1. Darkness Mechanic
- **In darkness (before light source):** Player can use FEEL, SMELL, LISTEN, TASTE. LOOK returns "You can't see anything."
- **In light:** All verbs work. LOOK returns visual descriptions. Objects are fully visible.
- **Purpose:** Teaches sensory-first interaction. Darkness is not a barrier; it's a different mode of play.

### 2. Spatial/Layering Mechanic
- **Objects have positions:** Candle is ON nightstand (not in drawer). Bed is ON rug. Trap door is UNDER rug.
- **Moving top objects reveals underneath:** Push bed → rug is now accessible. Move rug → trap door appears.
- **Purpose:** Teaches spatial reasoning. Physical location matters. Discovery through active manipulation.

### 3. Container Mechanic
- **Containers hold contents:** Nightstand drawer contains matchbox. Matchbox contains 7 matches. Sack contains needle and thread.
- **Opening/closing changes access:** Closed drawer = contents hidden (must open). Open drawer = contents visible.
- **Taking from containers:** Taking a match removes it from matchbox. Matchbox now has 6 matches left.
- **Purpose:** Teaches inventory as physical reality. Items are not in an abstract menu; they are in physical containers.

### 4. Compound Tool Mechanic
- **Single objects + single verbs = limited capability:**
  - A match alone cannot ignite (needs striker surface).
  - A matchbox alone cannot ignite (needs something to strike).
  - Fire source alone cannot apply to candle without intent (needs LIGHT verb).
- **Compound actions require two objects:** STRIKE match ON matchbox (two objects, one verb, one result).
- **Capability matching:** Any fire source can light any candle (not specific item matching).
- **Purpose:** Teaches tool chains and interdependency.

### 5. Consumable Mechanic
- **Limited resources:** 7 matches total. Each use consumes one.
- **Temporary effects:** Match burns for ~30 game seconds. Candle burns for ~100 turns. Both can be exhausted.
- **Scarcity teaches planning:** Wasting matches means fewer light opportunities.
- **Purpose:** Creates urgency and teaches resource management.

### 6. State Mutation Mechanic
- **Objects change fundamentally when affected:**
  - Match → match-lit (different object, not a flag)
  - Candle → candle-lit (different object with light property)
  - Poison bottle → poison-bottle-uncorked (if cork is removed)
- **Mutations are persistent until reversed:** A lit match stays lit until it burns out. A candle stays lit until it burns down or is extinguished.
- **Purpose:** Changes in the world are **real**. Not flag flips; genuine transformations.

### 7. Inventory/Hands Mechanic
- **Player has 2 hands.** Each carried object requires hands.
- **Object carry requirements:**
  - Matchbox = 1 hand (small)
  - Match = 0 hands (negligible)
  - Candle = 1 hand (must hold to carry)
  - Brass key = 0 hands (negligible)
- **Inventory as physical constraint:** Cannot carry too many large objects simultaneously. Forces strategic choices.
- **Purpose:** Inventory is not infinite. Carrying capacity is real.

### 8. Detection/Hazard Mechanic
- **Poison bottle teaches sensory hierarchy:**
  - FEEL → "Glass bottle, sealed cork, heavy." No danger info.
  - SMELL → "Acrid chemical smell. Warning bells." Danger identified.
  - LOOK (with light) → Skull-and-crossbones label. Danger confirmed.
  - TASTE (without warning) → Death. **Consequence system engaged.**
- **Purpose:** Teaches that different senses reveal different information. Consequences are real and permanent (death = game over).

### 9. Time Mechanic
- **In-game time advances:** 1 real hour = 1 full in-game day.
- **Daytime window:** 6 AM to 6 PM are daylight hours.
- **Alternative to tools:** At 6 AM, the window provides natural light. Player can skip the match puzzle by waiting.
- **Purpose:** Time creates opportunity windows. Alternatives exist for those willing to wait.

### 10. Spatial Discovery Mechanic (Trap Door)
- **Rug covers trap door:** Initially invisible.
- **Active exploration reveals:** Pushing bed, pulling rug → trap door becomes visible.
- **Key to proceed:** Brass key is under/near trap door. Player must find it to progress.
- **Purpose:** Teaches that **active manipulation of space reveals secrets**. Not all solutions are obvious; exploration is rewarded.

## Optional Discovery Paths

### A. The Wardrobe Branch — Crafting & Clothing

**Path:** OPEN wardrobe → discover cloak, sack, sewing manual.

#### Option A1: Read the Sewing Manual
1. Open wardrobe, take sewing manual.
2. READ sewing manual.
3. Player learns sewing skill (or gains "sewing" knowledge state).
4. **Learning outcome:** Teaches reading as mechanic. Manuals teach skills.

#### Option A2: Sewing Craft
1. Open wardrobe, take sack and needle.
2. From inside sack, take needle and thread.
3. Find cloth in the room (or craft cloth from string/thread).
4. SEW cloth WITH needle AND thread.
5. Cloth becomes garment (simple shirt or basic clothing).
6. **Learning outcome:** First crafting action. Multiple objects combine to make something new.
7. **Strategic use:** Garment might be useful in future rooms.

#### Option A3: Sack as Wearable
1. Take sack from wardrobe.
2. WEAR sack ON head.
3. **Result:** Player blindfolds themselves with sack. Flavor description: "You pull the sack over your head, plunging back into darkness. That was a silly decision."
4. **Purpose:** Comedy. Teaches that wearables can be equipped.

#### Option A4: Cloak as Wearable
1. Take cloak from wardrobe.
2. WEAR cloak.
3. **Result:** Player dons a dark cloak. Flavor description: "You wrap the cloak around yourself. You look mysterious and slightly dramatic."
4. **Strategic use:** Cloak might affect NPC reactions or light refraction in future encounters.

### B. The Writing Branch — Documentation & Blood

**Path:** Discover pen, paper, ink bottle on desk.

#### Option B1: Write a Note
1. Take pen, paper, ink.
2. WRITE message ON paper WITH pen.
3. Player writes a note (any message they choose).
4. **Learning outcome:** Writing as mechanic. Players can leave messages.
5. **Flavor:** Creates a personal narrative thread.

#### Option B2: Draw on Paper (Humor)
1. Take pen and paper.
2. DRAW ON paper WITH pen.
3. Player creates a crude drawing.
4. **Learning outcome:** DRAW verb exists. Creative output is possible.

#### Option B3: Write in Blood
1. Get bleeding by injuring self or finding wound (alternate mechanic, see Puzzle 003).
2. WRITE message ON paper WITH blood (blood becomes writing material).
3. Message is written in blood (visual/thematic change).
4. **Learning outcome:** Resources can be harvested from player. Consequences and desperation create drama.

### C. The Poison Bottle Branch — Hazard Investigation

**Path:** Nightstand drawer contains poison bottle.

#### Option C1: Safe Investigation (Recommended)
1. SMELL poison-bottle → "Acrid chemical smell. Something dangerous."
2. With light, LOOK poison-bottle → "Skull-and-crossbones label. POISON."
3. AVOID it. Escape successfully.
4. **Learning outcome:** Sensory investigation prevents death.

#### Option C2: Uncork the Poison
1. UNCORK poison-bottle.
2. Cork pops out, becomes detachable object (cork).
3. Poison bottle is now open (state changes to poison-bottle-uncorked).
4. Cork can be picked up and carried.
5. **Future use:** Cork becomes fishing float or crafting material in later rooms.
6. **Warning:** If player TASTES the open poison, death occurs.

#### Option C3: Lethal Path (Death Condition)
1. TASTE poison-bottle (in darkness or after seeing label).
2. **Result:** Immediate death. Game over. "You taste something vile and metallic. Your vision swims. The world fades."
3. **Learning outcome:** TASTE is dangerous. Choices have lethal consequences.

### D. The Mirror Branch — Cosmetics & Self-Awareness

**Path:** Mirror on wall or stand.

#### Option D1: Look in Mirror (with Light)
1. LOOK at mirror or LOOK in mirror (requires light).
2. **Result:** Player sees reflection. Flavor description reveals player appearance (maybe: "You see a disheveled figure in worn clothes. Your hair is a mess.").
3. **Learning outcome:** LOOK verb can interact with reflective surfaces.

#### Option D2: Break Mirror (Optional)
1. BREAK mirror or SMASH mirror.
2. Mirror shatters into shards (visual state change).
3. Shards can be collected as sharp objects.
4. **Future use:** Shards are cutting tools or weapons in later rooms.
5. **Consequence:** Room loses reflective surface.

### E. The Chamber Pot Branch — Comedy & Physicality

**Path:** Chamber pot sits in corner or under bed.

#### Option E1: Examine It
1. FEEL chamber pot → "Ceramic bowl, empty."
2. LOOK chamber pot (with light) → "An ornate ceramic chamber pot. Definitely a toilet equivalent."
3. **Learning outcome:** Bathroom fixtures exist. Hygiene is world-building.

#### Option E2: Use It (Flavor)
1. RELIEVE yourself WITH chamber pot (or PISS IN pot).
2. **Result:** Flavor text. "You feel better. The chamber pot is now... full. Definitely want to avoid that later."
3. **Purpose:** Physical comedy. Reminds player that body functions exist in this world.

#### Option E3: Wear It
1. TAKE chamber pot.
2. WEAR chamber pot ON head.
3. **Result:** Comedy. "You place the chamber pot on your head. You are now wearing a very uncomfortable helmet. It smells like a mistake."
4. **Purpose:** Absurdist humor. Wearables don't need to be sensible.

### F. The Time Loop Branch — Sleeping

**Path:** Player can SLEEP to advance time.

#### Option F1: Sleep Until Dawn
1. SLEEP or SLEEP IN bed.
2. Time advances to 6 AM (automatically).
3. **Result:** Natural light floods through window. Room is illuminated without using candle/matches.
4. **Trade-off:** Slow but resource-efficient.

#### Option F2: Sleep Multiple Times
1. SLEEP → advance to dawn (6 AM).
2. Later (in future rooms), SLEEP → advance to next day.
3. **Learning outcome:** Sleep is a time-advance mechanic. Used strategically to access different game states.

### G. The Curtain Branch — Window & Light

**Path:** Window with curtains.

#### Option G1: Open Curtains
1. OPEN curtains or DRAW curtains.
2. If it's after 6 AM (in-game time), natural light floods in.
3. If it's before 6 AM, opening curtains shows darkness outside.
4. **Learning outcome:** Windows provide light during daytime hours.

#### Option G2: Close Curtains (Flavor)
1. CLOSE curtains.
2. Room darkens again (if daytime was providing light).
3. **Purpose:** Strategic light management.

### H. The Desk Branch — Writing & Storage

**Path:** Desk with drawer, pen, paper, ink bottle.

#### Option H1: Open Desk Drawer
1. OPEN desk drawer (if desk has one).
2. Drawer contains office supplies or other flavor items.
3. Drawer might be detachable (like nightstand drawer).
4. **Learning outcome:** Desks are furniture with storage.

#### Option H2: Pull Drawer Out
1. PULL desk drawer or PULL OUT drawer.
2. Drawer detaches from desk, becomes portable container.
3. Player can carry drawer to another location.
4. **Learning outcome:** Containers are movable. Furniture pieces are separable.

## Hints System (Progressive Hints for Stuck Players)

### Hint Levels (if implemented with `HINT` command)

**Hint 1 — General Direction:**
- "You're in a dark room. Try using your senses to explore. FEEL might help in the darkness."

**Hint 2 — First Steps:**
- "Feel around for furniture near you. A nightstand might be close by."

**Hint 3 — Specific Object:**
- "The nightstand has a drawer. Open it to find what might help with light."

**Hint 4 — Tool Chain:**
- "You found a matchbox. Open it to see what's inside. Matches need a striking surface."

**Hint 5 — Compound Action:**
- "Strike a match ON the matchbox (use the surface to light it). Then use the lit match to light the candle."

**Hint 6 — Light Success:**
- "The candle is lit! Now you can see the room. Look around for clues about escape."

**Hint 7 — Spatial Discovery:**
- "The bed is sitting on a rug. What if you moved the bed or rug? Something might be hidden underneath."

**Hint 8 — Trap Door:**
- "There's a trap door hidden under the rug! And a brass key nearby. The key might unlock the trap door."

**Hint 9 — Exit:**
- "Use the brass key to open the trap door and descend."

## Difficulty Analysis

### Difficulty Tuning

**Current difficulty: EASY (by design for first room)**

**Why easy?**
1. **7 matches** — Generous margin. Players can afford trial-and-error.
2. **Clear object placement** — Matchbox in drawer, candle on nightstand. Logical hiding spots, not obscure.
3. **Intuitive verb usage** — FEEL, OPEN, TAKE, STRIKE, LIGHT are common-sense verbs.
4. **No time pressure in Act 1** — Matches burn down, but slowly (30 sec). Plenty of time to experiment.
5. **Daytime alternative** — If stuck, wait for 6 AM and use natural light. Removes all tool dependency.
6. **Clear exit condition** — "Escape via trap door" is obvious once room is illuminated.

**What makes it interesting (not boring)?**
1. **Darkness forces sensory learning** — Darkness is not just a difficulty setting; it's a tutorial mechanism.
2. **Compound actions** — Striking match on matchbox teaches tool interdependency early.
3. **Optional depth** — Sewing, crafting, writing, comedic interactions reward exploration.
4. **Early death trap** — Poison bottle teaches consequences without being required to escape.
5. **Spatial discovery** — Moving rug to reveal trap door teaches active exploration.

**Difficulty curve for sequence:**
- **Act 1 (light):** Tutorial-gentle. Most players succeed first try or after 1-2 experiments.
- **Act 2 (find key):** Moderate. Requires spatial reasoning ("move bed to access rug"). Not instantly obvious.
- **Act 3 (escape):** Simple. Once key is found, using it is straightforward.

**If difficulty needs adjustment:**
- **Make harder:** Reduce matches (5 instead of 7), hide nightstand location, make rug heavier to move.
- **Make easier:** Add more light sources, make nightstand glowing/beacon, auto-unlock trap door.

## Items Collected on Escape

### What Player Can Carry Out

Assuming the player escapes via trap door, what do they bring to Room 2?

**Typical loadout (critical path):**
- Brass key (used to open trap door, but player likely still has it)
- Remaining matches (maybe 5-6 unused)
- Matchbox (reusable container, may have striker still)
- Candle (if not burned down to stub)
- (Optional) Any items taken from side explorations (cloak, sack, sewing manual, pen, paper, etc.)

**Inventory management:**
- Player has 2 hands. Large items (candle, sack, cloak) take 1 hand each.
- Small items (matches, key, pen) take 0 hands.
- Some items can be placed inside containers (matches in matchbox) to reduce inventory burden.

**Strategic carrying:**
- Experienced players will optimize: carry candle + key + matchbox, leave cloak/sack behind.
- Curious players might carry sewing manual or crafted garment for future use.
- Careless players might be overloaded and need to drop items or make multiple trips (if that's allowed).

**Impact on Room 2:**
- Room 2 design should assume player has light source (candle or matches).
- Room 2 might reward certain items brought from Room 1 (sewing manual enables craft, cloak disguises player, key opens locks, etc.).

## Time Pressure & Consumables

### Match Lifecycle
- **Found:** 7 individual matches in matchbox
- **Struck:** Match becomes match-lit, burns for ~30 game seconds (~12 real seconds at 1:1 time scale)
- **Lit candle:** Match is consumed (destroyed) in the act of lighting candle
- **Burned out:** If a match isn't used within 30 sec, it burns down to player's fingers and is consumed
- **Resource impact:** Each failed light attempt costs a match

### Candle Lifecycle
- **Unlit:** Provides no light, just an object
- **Lit:** Candle-lit variant, casts light for ~100 game turns (~25 real seconds at 1:1 time scale, or ~4 minutes of in-game day)
- **Burned down:** After 100 turns, candle is exhausted, becomes unlit candle-stub
- **Reignition:** Candle can be relit if another match is available (if candle-lit object is not yet consumed)

### Sleep/Time Advancement
- **SLEEP verb:** Advances in-game time forward (by default, until next dawn at 6 AM)
- **Time scale:** 1 real hour = 1 in-game day. So 3–4 minutes real time = ~6 AM in-game.
- **Strategic use:** If player wastes all matches before lighting candle, they can sleep until dawn to get natural light

### Pressure on Player
- **Match pressure (30 sec):** Creates urgency. Player must act quickly after striking a match.
- **Candle pressure (100 turns / ~4 minutes):** Creates medium-term pressure. Player has time to explore but not forever.
- **Time pressure (wait vs. act):** Player can wait for dawn (~3-4 real minutes) or act immediately. Teaches trade-off between speed and resource consumption.

## Death Conditions

### Only Death in Room 1: Poison
- **Trigger:** TASTE poison-bottle
- **Result:** Immediate death. Game ends or resets to checkpoint (if checkpoints are implemented).
- **Message:** "You taste something vile, metallic, and wrong. Your tongue burns. The world fades to black."
- **Learning outcome:** Consequences are real. Not all objects are safe to interact with.

### No Other Death Conditions in Room 1
- Staying in darkness is not lethal (just inconvenient).
- Running out of light is not lethal (can wait for dawn).
- Using all matches is not lethal (can wait for dawn).
- Any other interaction is survival-neutral (inconvenient but not deadly).

**Future rooms:** Death conditions may expand (falling, suffocation, combat, etc.).

## Connection to Room 2 (Placeholder)

### What Lies Below the Trap Door?

**Design prompts for future rooms:**
- Room 2 is directly below Room 1 (basement, cellar, dungeon level).
- Player descends via trap door using rope ladder, stone stairs, or other mechanism.
- Room 2 likely builds on Room 1 mechanics:
  - Darkness? Room 2 might start dark too, rewarding players who brought candle/matches.
  - Spatial puzzles? Room 2 might have more complex layering and object manipulation.
  - Crafting? Room 2 might require items from Room 1 (sewing manual, sack, cloak, etc.).
  - Consequences? Room 2 might have more significant failure states or permanent choices.

**Items from Room 1 with future relevance:**
- **Cork:** Becomes fishing float or plug for later.
- **Sack:** Might be needed for carrying items or as disguise.
- **Sewing manual:** Might enable crafts in Room 2.
- **Cloth/garment:** Might affect NPC reactions or environmental interactions.
- **Matches/candle:** Continues as light source.
- **Key:** Might unlock different lock types or remain as currency.

**Narrative handoff:**
- Room 1 teaches: darkness, tools, consequences, spatial discovery, inventory management.
- Room 2 should escalate: complexity, stakes, depth of resource management, story progression.

## Status

**Designed** — Complete game design documentation. Implementation assigned to Bart (Architect) and Nelson (QA). All mechanics, optional paths, and difficulty tuning documented for reference during testing and iteration.

---

## Design Notes & Rationale

### Why Start in Darkness?

1. **Narrative impact:** Waking in darkness creates disorientation and urgency. More dramatic than waking to daylight.
2. **Mechanical teaching:** Darkness forces immediate FEEL usage. Player learns that light is not required for all verbs.
3. **Tool discovery:** Lights are tools. Player must actively find and use them. Establishes tool-first gameplay.
4. **Sensory hierarchy:** Without sight, player learns FEEL → SMELL → LISTEN → TASTE priority. Sight is not the default sense.

### Why These Specific Objects?

- **Matchbox:** Natural place to find matches. Container teaches containment. Striker surface teaches compound actions.
- **7 matches:** Generous margin. Enough for experimentation without severe punishment for mistakes.
- **Nightstand:** Logical furniture piece next to bed. Dark-room play is supported (drawer discoverable by FEEL).
- **Candle:** Intuitive light source. Takes a tool to light (teaches tool chains). Burns for reasonable duration (~100 turns, enough to explore fully).
- **Poison bottle:** Teaches consequences early. Hazard trap rewards sensory caution.
- **Wardrobe:** Classic furniture for clothing/crafting discovery. Multiple optional interactions.
- **Desk:** Writing surface. Supports optional narrative (leaving messages, documenting, etc.).
- **Trap door under rug:** Teaches spatial discovery. Moving objects reveals secrets. Natural gate to next room.
- **Brass key:** Physical unlock mechanism. Not abstract; real object with real purpose.

### Why This Sequence?

1. **Wake → Explore darkness:** Player learns FEEL works without light.
2. **Find nightstand → Discover drawer:** Player learns containment and OPEN mechanic.
3. **Get matchbox → Open and take match:** Player learns container contents are objects.
4. **Strike match on matchbox:** Player learns compound actions and urgency (match burns down).
5. **Light candle:** Player learns state mutation (match → match-lit → consumed; candle → candle-lit).
6. **Explore with light:** Player now discovers room layout, sees all objects.
7. **Push bed, pull rug:** Player learns spatial manipulation reveals secrets.
8. **Find key, open trap door:** Payoff. Escape unlocked. Progression to Room 2.

This sequence scaffolds player knowledge from sensory basics → tool chains → spatial reasoning → resource management → progression.

### Why Optional Content?

Optional content serves multiple purposes:

1. **Player agency:** Not all players want to solve one way. Alternatives reward exploration and creativity.
2. **Replayability:** First playthrough might skip sewing; second playthrough might try crafting.
3. **Depth without mandatory complexity:** Casual players escape via critical path. Hardcore players uncover sewing, writing, poison uncorking.
4. **Comedy and humanity:** Sack-on-head and chamber pot humor makes the game feel alive, not just mechanical.
5. **Future relevance:** Items crafted or taken now might matter in later rooms.

### Combat & Conflict Absence

Room 1 has no combat, no NPCs, no social conflict. This is intentional:

- **Tutorial focus:** Combat would distract from learning core systems.
- **Isolation:** Player wakes alone. No immediate threat (poison is a hazard, not an enemy).
- **Pacing:** Room 1 is about exploration and discovery, not action.
- **Future escalation:** Room 2+ will introduce conflict as player grows confident.

### Difficulty is Tuned to EASY (First Room)

Easy difficulty is intentional because:

1. **Onboarding:** New players need success early to build confidence.
2. **Failure teaches:** Even easy room has one lethal option (poison). Failure feels earned, not arbitrary.
3. **Pacing:** Players should spend ~15-30 min in Room 1, not get stuck for hours.
4. **Escalation:** Rooms 2+ will increase difficulty as player skills improve.

---

## Related Systems & Documentation

- **Light System:** Defined in `../design/design-directives.md` (Light & Time System)
- **Tool Convention:** Defined in `../design/design-directives.md` (Tools System)
- **Compound Tool Actions:** Defined in `../design/tool-objects.md`
- **Consumable Pattern:** Defined in `../design/tool-objects.md` (Consumables)
- **Composite Object System:** Decision D-25 in `.squad/decisions.md`
- **Multi-Sensory Convention:** Decision D-28 in `.squad/decisions.md`
- **Room 1 Objects:** 37+ object definitions in `src/meta/objects/` (nightstand.lua, match.lua, candle.lua, etc.)
- **Game Engine Conventions:** Decision D-24 in `.squad/decisions.md` (Pass-002 Bugfixes)

---

## Testing Checklist for QA (Nelson)

- [ ] **Wake in darkness:** Player spawns in dark room on bed. LOOK returns "can't see" message.
- [ ] **Sensory exploration:** FEEL nightstand works without light. SMELL candle works without light.
- [ ] **Container mechanic:** Open nightstand drawer, take matchbox. Matchbox opens, contains 7 matches.
- [ ] **Compound action:** STRIKE match ON matchbox. Match becomes match-lit, provides light.
- [ ] **Consumable burnout:** Lit match burns for ~30 game seconds, then is consumed.
- [ ] **State mutation:** Candle lights, becomes candle-lit object (not flag flip).
- [ ] **Inventory carry:** Can carry 2 large items (candle, cloak) or many small items (matches, key).
- [ ] **Spatial discovery:** Push bed off rug. Pull rug reveals trap door beneath.
- [ ] **Trap door unlock:** Use brass key to open trap door.
- [ ] **Poison hazard:** SMELL poison warns. TASTE poison kills. LOOK poison shows label (with light).
- [ ] **Time/sleep:** SLEEP until 6 AM. Window provides natural light without candle.
- [ ] **Optional crafting:** Sew needle + thread into cloth. Cloth becomes garment.
- [ ] **Optional comedy:** Wear sack on head, wear chamber pot as helmet. Flavor text displays.
- [ ] **Escape:** Descend trap door successfully.

---

## Author Notes

This design doc is intended for both designers AND QA. Nelson should use this as a testing reference. Any deviations from documented behavior should be reported as bugs. Optional content can be tested in any order; critical path must be tested in sequence.

**Comic Book Guy, Game Designer**
**MMO Project — Room 1 Complete Documentation**
**Date:** 2026-03-25

