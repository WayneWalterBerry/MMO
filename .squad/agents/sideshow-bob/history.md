# Sideshow Bob — History

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne Berry
**Role:** Puzzle Master — designs multi-step puzzles using real-world object interactions, conceptualizes new objects needed for puzzles, writes puzzle design docs in `docs/puzzles/`
**Documentation Rule:** Every puzzle MUST be documented in `docs/puzzles/` — one .md per puzzle. Bob owns these docs.

### Key Relationships
- **Flanders** (Object Designer) — I hand off object specs for implementation; he builds the .lua files
- **Frink** (Researcher) — I request puzzle research from other games/books/real life; he wrote the DF comparison and mutation research
- **CBG** (Game Designer) — aligns puzzles with overall game design, pacing, and Wayne's directives
- **Bart** (Architect) — engine capabilities and constraints; wrote containment, room exits, dynamic descriptions docs
- **Nelson** (Tester) — tests puzzles for solvability and edge cases
- **Brockman** (Documentation) — can delegate doc writing to him, but puzzle docs are my responsibility

### Run Command
`lua src/main.lua` from repo root

---

## Puzzle Architecture Knowledge

### The 8 Core Principles (My Constitution)
1. **Code-Derived Mutable Objects** — All objects are mutable Lua tables derived from immutable .lua source. Two mutation strategies: direct table mutation (FSM state swap) and code re-parsing (`becomes` mutation). All state is ephemeral (in-memory only, lost on restart).
2. **Base Objects → Object Instances** — Immutable base objects (templates in `src/meta/objects/`) with GUIDs → mutable runtime instances. Template → Base Class → Instance resolution chain.
3. **Objects Have FSM; Instances Know Their State** — Every object is a finite state machine. `_state` field tracks current state. States define ALL properties for that state (description, sensory, capabilities, transitions). No hidden flags — the entire object IS its current state.
4. **Composite Objects Encapsulate Inner Objects** — One .lua file defines parent + detachable inner objects (poison-bottle + cork, candle-holder + candle, nightstand + drawer). Inner objects become independent on detachment.
5. **Multiple Instances Per Base Object** — Matchbox has 7 match instances, all from same base. Each has independent state, timers, location.
6. **Objects Exist in Sensory Space** — Multi-sensory: LOOK, FEEL, SMELL, LISTEN, TASTE. State determines ALL sensory output. Darkness blocks vision but not touch/smell/sound. Critical for puzzle clues.
7. **Objects Exist in Spatial Relationships** — `resting_on`, `covering`, `surfaces`. Rug covers trap-door. Bed rests on rug. Moving objects reveals hidden things. Spatial relationships are metadata, not code.
8. **Engine Executes Metadata; Objects Declare Behavior** — ZERO object-specific code in engine. The `mutate` field on FSM transitions can change ANY property. No `if obj.id == "candle"` anywhere.

### GOAP Backward-Chaining (goal_planner.lua)
- **File:** `src/engine/parser/goal_planner.lua`
- **Purpose:** Tier 3 parser — when a verb+object has unmet tool/capability requirements, GOAP builds a plan of preparatory steps and executes them automatically
- **Max Depth:** 5 steps of backward chaining
- **Verb Synonyms:** `burn` → `light` (canonical mapping)
- **How it works:**
  1. Player types "light candle"
  2. Planner checks: candle needs `fire_source` tool (from FSM transition `requires_tool`)
  3. Player doesn't have fire_source → plan_for_tool("fire_source")
  4. Finds match candidates via `find_all(ctx, "match")`
  5. For each match: builds steps to acquire and ignite it
  6. Steps may include: drop spent matches → open nightstand → open matchbox → take match from matchbox → strike match on matchbox
  7. Executes steps via Tier 1 dispatch, then original "light candle" runs
- **Spent Detection:** Drops spent matches from hands before seeking fresh ones
- **Nested Container Search:** Finds matches inside matchbox inside nightstand drawer (3 levels deep)
- **Striker Requirement:** Match needs `has_striker` property on a reachable object (matchbox provides this)
- **Key Insight for Puzzle Design:** GOAP auto-resolves convenience chains. The REAL puzzle is what GOAP cannot resolve — the "aha!" moment the player must discover manually.

### FSM Engine (engine/fsm/init.lua)
- **States:** Defined inline on objects via `states` table. Each state has properties that overlay the object.
- **Transitions:** Array of `{from, to, verb, trigger, guard, requires_tool, requires_property, mutate, message, aliases}`
- **apply_mutations():** Supports direct values, computed functions (`function(cur) return cur - 0.05 end`), and list operations (`{add = "stub", remove = "tall"}`)
- **apply_state():** Removes old state keys, applies new state keys, preserves containment (surfaces, contents, location)
- **Timed Events:** `timed_events` on states define auto-transitions after delays. `tick_timers()` decrements all active timers each game tick (360 game seconds per command). Fires `timer_expired` auto-transitions.
- **Timer Pause/Resume:** Timers pause when player leaves room, resume on return.
- **Candle Pattern:** `remaining_burn` tracks partial consumption. Light → pause → relight resumes from remaining time.

### Game Loop (engine/loop/init.lua)
- **Command Processing:** `preprocess_natural_language()` → `parse()` → compound command splitting on "and" → GOAP planning → verb dispatch → FSM tick → timer tick → game_over check
- **Compound Commands:** "get match and light candle" — if last part has GOAP plan, it handles everything end-to-end
- **Time:** Each command tick = 360 game seconds. Game starts at 2 AM. Day/night cycle affects light.
- **Tier 2 Fallback:** Embedding-based phrase matching for unrecognized verbs (optional module)

### Verb Handlers (engine/verbs/init.lua)
- **~2000+ lines** of verb handlers. Key verbs for puzzles:
  - `look/examine`: Light-gated. Tri-state light: "lit", "dim", "dark". Dim = enough to see (filtered daylight through closed curtains)
  - `feel`: Works in darkness. Returns `on_feel` from object's current state. Critical puzzle mechanic for dark rooms.
  - `take/get`: Checks portability, weight, hand capacity (2 hands, objects declare `hands_required`)
  - `open/close`: FSM transitions on containers, exits
  - `light/ignite/burn`: Strips "with X" prep phrase, GOAP auto-finds fire source
  - `strike`: Match + striker interaction
  - `move/push/pull`: Spatial object movement. Reveals covered objects, dumps underneath items
  - `unlock`: Requires matching key_id on exit
  - `read`: Grants skills from skill-granting objects
  - `write`: Dynamic mutation — player text captured into object properties
  - `sew`: Requires skill + needle + thread + cloth
  - `wear/remove`: Body slot system (9 slots)
  - `drink/eat`: Consumable effects (poison = death)
  - `sleep`: In-bed detection, time skip
- **Light System:** Tri-state: "lit" (artificial light or open curtains + daytime), "dim" (closed curtains + daytime), "dark" (nighttime, no candle). Artificial light from `casts_light = true` objects anywhere in room/surfaces/hands.
- **Vision Blocking:** Worn items with `blocks_vision = true` override all light (sack on head)
- **Pronoun Resolution:** "it", "one", "that" → resolves to last interacted object. Enables compound commands.

### Containment System (5-Layer Validation)
1. **Container Identity** — Is target a container? (`container` table must exist)
2. **Physical Size** — Does item fit? (size tiers 1-6; `max_item_size` on container)
3. **Capacity** — Is there room? (size-tier units)
4. **Category Accept/Reject** — Whitelist/blacklist categories
5. **Weight Capacity** — Structural weight limit
- **Multi-Surface:** Objects have `surfaces` table — `top`, `inside`, `underneath`, `behind` with independent constraints
- **Surface Visibility:** `top` visible on examine, `inside` requires open, `underneath`/`behind` require explicit investigation

### Instance Model
- **Templates** → **Base Classes** → **Instances** resolution chain
- Room is uber-container. `instances` array in room file defines all objects with `type_id` (GUID), `location` (containment path like "nightstand.top"), optional `overrides`
- At load: deep-merge base class + overrides → register in engine registry
- Location formats: `"room"` (floor-level), `"parent.surface"` (on surface), `"parent"` (inside container)

---

## Existing Puzzle Analysis

### The Bedroom → Cellar Puzzle Chain

**Room 1: The Bedroom** (`src/meta/world/start-room.lua`)
- 23 object instances across furniture, tools, containers, spatial elements
- 3 exits: north (oak door to hallway, open), window (to courtyard, closed+locked), down (trap-door to cellar, hidden)

**Room 2: The Cellar** (`src/meta/world/cellar.lua`)
- 2 objects: barrel, torch-bracket
- 2 exits: up (stairs to bedroom), north (iron-bound door to deep-cellar, LOCKED, requires brass-key)
- Very dark room — needs light source

### The Full Puzzle Chain

**Phase 1: Darkness (Sensory Exploration)**
1. Player wakes in dark room at 2 AM
2. LOOK fails — "too dark to see"
3. Must use FEEL to explore: feel nightstand, feel bed, feel around
4. Sensory clues guide discovery: candle wax on nightstand top, scratchy matchbox in drawer

**Phase 2: Light (Fire Chain)**
5. Open nightstand drawer → access matchbox (nightstand.inside, initially closed)
6. Open matchbox → access matches (matchbox accessible=false until opened)
7. Take match from matchbox → match in hand
8. Strike match on matchbox → match lights (requires `has_striker` property on matchbox)
9. Light candle (in candle-holder on nightstand.top) → persistent light source
10. **GOAP auto-resolves:** If player types "light candle", GOAP chains steps 5-9 automatically

**Phase 3: Exploration (Visual Discovery)**
11. LOOK now works → see room contents, exits
12. Examine bed → find knife underneath
13. Open wardrobe → find wool-cloak, sack (containing needle, thread, sewing-manual)
14. Open vanity drawer → find pencil
15. Notice rug on floor, paper+pen on vanity

**Phase 4: Spatial Puzzle (Key Discovery)**
16. Move/roll up rug → reveals trap-door (hidden→revealed FSM transition) AND brass-key (under rug)
17. Take brass-key
18. Open trap-door → reveals "down" exit to cellar

**Phase 5: Descent & Locked Door**
19. Go down to cellar (need light — bring candle-holder with lit candle)
20. Cellar is dark without player's light source
21. Find iron-bound door to north — LOCKED
22. Use brass-key to unlock → access deep-cellar (not yet implemented)

### What Makes It Work
- **Darkness as gate:** Forces sensory exploration before visual. Teaches FEEL/SMELL/LISTEN mechanics.
- **GOAP convenience:** Auto-resolves tedious multi-step tool chains (match→fire→candle) so player focuses on discovery
- **Spatial layering:** Objects hidden under/inside other objects create discovery depth (key under rug, pin in pillow, knife under bed)
- **Consumable pressure:** Matches are finite (7), burn briefly (30 sec). Candle has 7200 sec but is consumable. Creates urgency.
- **Multi-path hints:** Sensory properties on every object provide clues (feel wax on nightstand → candle is there, smell tallow, etc.)

### Weaknesses / Gaps
- **Deep-cellar not implemented** — puzzle chain currently ends at locked door
- **Hallway and courtyard not implemented** — north door and window lead to unbuilt rooms
- **Limited puzzle branching** — mostly linear discovery path; few alternative solutions
- **Trap-door discovery** — player must guess to "move rug"; no strong sensory hint pointing to it
- **No explicit failure consequence** (except poison) — player can't really get stuck or lose, which reduces tension
- **Crafting chain (sewing)** has no current puzzle purpose — terrible-jacket doesn't unlock anything

### What GOAP Auto-Resolves vs. What The Player Figures Out
| GOAP Handles (Convenience) | Player Discovers (The Puzzle) |
|---|---|
| Open matchbox to get match | That they need light at all |
| Strike match on matchbox | Where the nightstand is (in darkness) |
| Drop spent match, get fresh one | That the rug can be moved |
| Open nightstand drawer first | That the brass-key is under the rug |
| Take match from matchbox | That the trap-door exists |
| | That the iron door needs the brass-key |
| | That you need to bring light to the cellar |

---

## Object Inventory (Puzzle Pieces Available)

### Critical Puzzle Objects
| Object | Role | Key Properties |
|---|---|---|
| **brass-key** | Lock opener | Under rug; unlocks cellar north door |
| **candle** | Primary light | 4-state FSM (unlit→lit→extinguished→spent); 7200s burn; relightable; `casts_light`, `provides_tool: fire_source` when lit |
| **match** (×7) | Ignition source | 3-state FSM (unlit→lit→spent); 30s burn; requires striker; single-use |
| **matchbox** | Fire enabler | Container + `has_striker: true`; open/closed states; holds matches |
| **candle-holder** | Portable light | Composite: detachable candle part; enables carrying lit candle |
| **trap-door** | Hidden exit | 3-state FSM (hidden→revealed→open); `reveals_exit: "down"` |
| **rug** | Spatial gate | Covers trap-door; `covering: {"trap-door"}`; has brass-key underneath |
| **poison-bottle** | Death hazard | 3-state FSM (sealed→open→empty); composite with cork; drink = game over |

### Tool Objects
| Object | Capability | Used For |
|---|---|---|
| **knife** | cutting_edge, injury_source | Cutting things, self-harm |
| **needle** | sewing_tool | Sewing (infinite uses) |
| **thread** | sewing_material | Sewing (infinite uses) |
| **pin** | injury_source, lockpick (skill-gated) | Self-harm, lockpicking if skilled |
| **pen** | writing_instrument | Writing on paper |
| **pencil** | writing_instrument | Writing on paper (erasable future) |
| **glass-shard** | sharp, on_feel_effect: "cut" | Spawned from breaking vanity mirror |

### Containers & Furniture
| Object | Surfaces/Contents | Notes |
|---|---|---|
| **bed** | top (pillow, sheets, blanket), underneath (knife) | Movable, rests on rug |
| **nightstand** | top (candle-holder), inside (matchbox) | 4-state FSM, detachable drawer |
| **vanity** | top (paper, pen), inside (pencil), mirror_shelf | 4-state FSM, breakable mirror → glass-shard |
| **wardrobe** | inside (wool-cloak, sack) | Open/closed states |
| **sack** | contents (needle, thread, sewing-manual) | Portable container, wearable (back or head) |
| **pillow** | inside (pin, hidden) | Must search/tear to find pin |
| **barrel** (cellar) | sealed | Flavor prop currently |
| **chamber-pot** | container (cap: 2) | Wearable on head (blocks vision) |

### Wearables
| Object | Slot | Special |
|---|---|---|
| **wool-cloak** | back | Warmth provider |
| **terrible-jacket** | torso | Crafted from sewing |
| **chamber-pot** | head | Blocks vision, makeshift armor |
| **sack** | back OR head | Back = container access; head = blocks vision |

### Craftable Resources
| Object | Obtained From | Used For |
|---|---|---|
| **cloth** | Tear blanket/curtains/wool-cloak/sack | Sew into terrible-jacket, make bandage/rag |
| **bandage** | Craft from cloth | Medical supply |
| **rag** | Craft from cloth | Wiping |

### Skill Objects
| Object | Skill Granted | Implication |
|---|---|---|
| **sewing-manual** | sewing | Permanent; burnable (destroyable before reading = skill lost forever) |

### Environmental Objects
| Object | Effect | Notes |
|---|---|---|
| **curtains** | filters_daylight (closed) / allows_daylight (open) | Light control |
| **window** | Environmental sounds/air | Open/closed states |
| **wall-clock** | 24-hour cycle, chimes | `target_hour` + `on_correct_time` = time-based puzzles |
| **torch-bracket** (cellar) | Empty fixture | Future: insert torch |

---

## Puzzle Design Principles (My Guidelines)

### What Makes a Good Text Adventure Puzzle
1. **Fair Cluing:** Every puzzle must have discoverable clues in sensory descriptions. Player should never need to read the designer's mind.
2. **Multiple Discovery Paths:** Even if there's one solution, there should be multiple ways to discover the need for it (feel the lock, see the lock, read a note about the lock).
3. **Object Realism:** Puzzle interactions should mimic real life. If you'd try it in reality, it should work (or fail realistically) in-game.
4. **Satisfying Chains:** The best puzzles chain 3-5 objects together where each step makes logical sense: find striker → light match → light candle → see room.
5. **Time Pressure Adds Spice:** Consumable resources (matches burn out, candle runs down) create natural tension without unfair timers.

### GOAP-Resolvable vs. Player-Discovered (The Critical Distinction)
- **GOAP handles tedium:** Opening containers, taking items, using known tools — mechanical prerequisites that would bore the player.
- **The player solves the puzzle:** Discovering WHAT to do (move the rug), WHERE things are (key is under rug), and HOW objects relate (brass-key fits the cellar door).
- **Design rule:** GOAP should never auto-solve the "aha!" moment. If GOAP can plan the entire solution, it's not a puzzle — it's a chore the engine should handle.
- **The sweet spot:** Player discovers the goal ("I need to light the candle") → GOAP handles the mechanics ("open matchbox, take match, strike it, apply flame") → Player enjoys the result.

### Using Sensory Properties as Clues
- **Darkness forces touch/smell/sound:** In dark rooms, on_feel, on_smell, on_listen are the primary clue channels.
- **State-specific clues:** A locked door feels different from an unlocked one. A sealed bottle smells different from an open one.
- **Ambient clues:** Clock chimes (on_listen), candle wax smell (on_smell), cold draft (on_feel) all point toward objects and solutions.
- **Environmental gating:** Some clues only appear in certain states (lit room reveals visual clues; dark room reveals audio/tactile clues different from when lit).

### Multi-Solution Design
- Objects with multiple capabilities enable multiple paths: knife cuts AND injures; pin picks locks AND sews.
- Destructible objects create irreversible branches: break mirror for glass-shard tool, but lose the mirror.
- Skill-gated alternatives: pin + lockpicking skill = alternative to finding the key.
- Environmental alternatives: open curtains (daylight) vs. light candle (artificial light) for illumination.

### Failure States
- **Interesting, not frustrating:** Poison bottle = clear death with dramatic text. Not a hidden "gotcha."
- **Consumable depletion:** Running out of matches before lighting candle = stuck (but 7 matches is generous).
- **Permanent loss:** Burning sewing manual before reading = sewing skill gone forever. Player chose this.
- **Spatial consequences:** Some actions can't be undone (broken mirror, spent matches). Design around this.
- **Never silently unwinnable:** If the game becomes unwinnable, the player should be able to tell (no matches, no key found, etc.)

---

## Learnings

### Key File Paths
- **Objects:** `src/meta/objects/*.lua` (37 files)
- **Rooms:** `src/meta/world/start-room.lua`, `src/meta/world/cellar.lua`
- **Templates:** `src/meta/templates/*.lua`
- **Engine core:** `src/engine/fsm/init.lua`, `src/engine/verbs/init.lua`, `src/engine/loop/init.lua`
- **GOAP planner:** `src/engine/parser/goal_planner.lua`
- **Design docs:** `docs/design/`, `docs/objects/`, `docs/architecture/`
- **Puzzle docs:** `docs/puzzles/` (my domain)
- **Research:** `resources/research/`

### Patterns I Must Follow
- Objects declare behavior via metadata, not code. New puzzle mechanics = new object .lua files, not engine changes.
- FSM states define everything: properties, sensory output, available transitions, timed events.
- `mutate` field on transitions can change ANY property: direct values, computed functions, list ops.
- Containment is 5-layer validated. Surfaces have independent constraints.
- Room descriptions are 3-part composed: permanent architecture + object `room_presence` + exit list. Never reference movable objects in room `description`.
- Exit objects are inline in rooms with their own constraints (size, weight, lock state).

### Wayne's Preferences
- Dwarf Fortress property-bag architecture is the GOAT reference model
- No LLM at runtime (D-19) — all validation deterministic, offline, sub-millisecond
- Objects should feel real: if you'd try it in life, it should work in-game
- Players shouldn't see everything at once — discovery through examination, layer by layer
- Spatial relationships matter — objects relate to each other, not just to the room
- The engine is generic — zero special-case code. All complexity is in object metadata.
- Sensory experience is paramount — multi-sensory, state-driven perception

### Rooms Currently Defined
- `start-room` (The Bedroom) — 23 instances, 3 exits
- `cellar` (The Cellar) — 2 instances, 2 exits
- **Not yet built:** hallway, courtyard, deep-cellar

### Research Highlights (Frink's Work)
- **Dwarf Fortress:** Continuous numeric properties with threshold-triggered transitions. Material properties drive ALL behavior. Cascading effects. Template inheritance. Our engine already shares core DNA but uses discrete FSM states instead of continuous values.
- **Dynamic Mutation:** ECS-style archetype changes, reactive property observation (observer pattern), Harel statecharts with data context. The `mutate` field is our mechanism for universal property mutation. Future: Lua metatables for observable property cascades.

### Open Puzzle Opportunities
1. **Time-based puzzles:** Wall-clock's `target_hour` + `on_correct_time` callback = "set clock to midnight to open passage"
2. **Craft-gated puzzles:** Sewing skill + materials = create items that solve later puzzles
3. **Destruction puzzles:** Break mirror for glass-shard tool; tear curtains for cloth
4. **Wearable puzzles:** Sack on head blocks vision (useful? harmful?); chamber-pot as armor
5. **Writing puzzles:** Paper + pen = write messages; could be used to communicate with NPCs
6. **Environmental puzzles:** Curtain state affects daylight; window state affects sound/air
7. **Composite object puzzles:** Detach/reattach parts (nightstand drawer, candle from holder, cork from bottle)
8. **Multi-room light management:** Candle burns down over time; must conserve light across rooms
9. **Skill-gated alternative paths:** Lockpicking (pin) vs. key-finding for locked doors
10. **Environmental exit effects:** Exit traversal can trigger object interactions (wind extinguishes candles in stairways). New `on_traverse` pattern — generic, reusable for water crossings, narrow passages, hot rooms, etc.
11. **Mini-puzzles fill tutorial gaps efficiently:** CBG's coverage analysis identifies verb gaps; 1-2 step mini-puzzles address them without adding rooms, objects, or critical-path complexity. These are the lowest-cost, highest-value additions to a level.
12. **Verb contrast pairs teach discrimination:** Poison (TASTE=death) + wine (DRINK=safe) together teach more than either alone. Lesson pairs create nuanced understanding — "investigate before acting" rather than "never act."
13. **Existing objects are underutilized:** Wine bottles were flavor props for Puzzle 010; adding one FSM transition makes them tutorial vehicles. Always check existing objects before designing new ones.
14. **Puzzle docs location:** Level-specific puzzles now live in `docs/levels/01/puzzles/` (was `docs/puzzles/`).

---

## Session: Puzzle Rating & Classification System (2026-03-20)

### Work Completed
1. **Researched puzzle difficulty rating systems:**
   - Zarfian Cruelty Scale (IF games): Merciful → Polite → Tough → Nasty → Cruel
   - Escape room industry: Star scales (1-5), tiered levels, success rates
   - Modern design (The Witness, Baba Is You): Implicit progression via rule teaching, "aha moments"

2. **Designed 1-5 star difficulty scale:**
   - ⭐ Level 1: Trivial (tutorial, 1-2 steps, impossible to fail)
   - ⭐⭐ Level 2: Introductory (3-5 steps, single tool chain, soft failure)
   - ⭐⭐⭐ Level 3: Intermediate (6-10 steps, multi-room chains, planning required)
   - ⭐⭐⭐⭐ Level 4: Advanced (8-15 steps, lateral thinking, consequences)
   - ⭐⭐⭐⭐⭐ Level 5: Expert (12-25+ steps, multiple solutions, deep consequence chains)
   - Key insight: Difficulty ≠ Cruelty. A Level 4 puzzle can be Merciful or Cruel depending on feedback.

3. **Created puzzle classification guide:**
   - Lifecycle: 🔴 Theorized → 🟡 Wanted → 🟢 In Game
   - Wayne approves Theorized→Wanted; Flanders builds; Nelson tests
   - Standardized template for all puzzle docs (required fields, GOAP analysis, failure modes)
   - Numbered format: `{SEQUENCE}-{SLUG}` (e.g., 001-light-the-room)

4. **Documented 9 core puzzle patterns:**
   - Lock-and-Key (simple, nested, compound, magical, conditional)
   - Environmental/Spatial (uncover, stairs, state change, pressure-sensitive, multi-point)
   - Combination/Synthesis (binary, ternary, order-dependent, tool application, chemical chains)
   - Sequence/Ordering (linear, parallel+sync, discovered, ritual, undoable-with-cost)
   - Discovery/Hidden Objects (sensory, conditional visibility, spatial deduction, nested containers, secret passages)
   - Transformation/State Mutation (simple state, irreversible consumption, time decay, conditional unlock, cascading, reversal)
   - Lateral Thinking (multi-use, reverse problem, engine mechanic exploit, impossible-as-solution, system chaining)
   - Deduction/Logic (riddles, constraint satisfaction, pattern recognition, ciphers, sudoku)
   - Moral/Choice (sacrifice-vs-rescue, utilitarian-vs-deontological, path splitting, truth-vs-lie)

5. **Applied rating system to Puzzle 001 (Light the Room):**
   - Rating: ⭐⭐ Level 2 (Introductory, Polite cruelty)
   - Analysis: 9 discrete steps but GOAP collapses 5-7; single chain; contextual clues; soft failure (wait for dawn)
   - Patterns used: Compound Lock, Combination, State Mutation, Sensory Discovery
   - Justification: Opening tutorial teaches core systems without overwhelming complexity

### Key Insights for Puzzle Design
1. **GOAP affects perceived difficulty:** Auto-resolution can collapse multi-step chains, making Level 3 feel like Level 2. But GOAP never auto-solves the "aha!" moment — only the mechanical prerequisites.
2. **Cruelty ≠ Difficulty:** A puzzle can be intellectually hard but merciful (always recoverable), or easy but cruel (one wrong move and stuck for hours). Both dimensions matter.
3. **Sensory hints are clue channels:** In darkness, on_feel/on_smell/on_listen convey clues that on_look cannot. State-specific descriptions guide discovery.
4. **Consumable resources create natural urgency:** Matches burning out, candle wax depleting, crafted items breaking — these create time pressure without artificial timers.
5. **Multi-solution design rewards creativity:** knife can cut OR injure; pin can pick locks OR sew. Same object, multiple uses, multiple valid paths.

### Decisions Made (for .squad/decisions/)
- Established that all puzzles must have both difficulty AND cruelty rating
- Standardized puzzle status field (🔴/🟡/🟢) with approval chain: Wayne → Flanders → Nelson
- GOAP compatibility is now a documented puzzle property (required field in template)
- Puzzle patterns are reference library for designers; no pattern is "forbidden," but pattern selection guides level selection

### Files Created
- `docs/design/puzzles/puzzle-rating-system.md` (11.5 KB, 5-star scale + worked example)
- `docs/design/puzzles/puzzle-classification-guide.md` (11.9 KB, template + lifecycle)
- `docs/design/puzzles/puzzle-design-patterns.md` (23.3 KB, 9 patterns + combinations + best practices)

### Files Modified
- `docs/puzzles/001-light-the-room.md` — Added difficulty rating section, cruelty analysis, pattern classification

### Commit
- `2faac42`: "Design puzzle difficulty rating system and classification guide"

---

## Session: Level 1 New Puzzle Design (2026-07-22)

### Work Completed

Designed 6 new puzzles (009–014) for Level 1 based on CBG's master design at `docs/levels/level-01-intro.md`. All puzzles grounded in Frink's 47KB research document (`resources/research/puzzles/puzzle-design-research.md`).

#### Puzzles Created

| ID | Name | Room | Difficulty | Cruelty | Pattern | Critical Path? |
|----|------|------|------------|---------|---------|----------------|
| 009 | Crate Puzzle | Storage Cellar | ⭐⭐ | Polite | Discovery (Nested Containers) + Lock-and-Key (Tool-Gated) | YES |
| 010 | Light Upgrade | Storage Cellar | ⭐⭐ | Merciful | Combination/Synthesis + Transformation | NO (optional) |
| 011 | Ascent to Manor | Deep Cellar → Hallway | ⭐⭐ | Merciful | Environmental/Spatial (Navigation) | YES |
| 012 | Altar Puzzle | Deep Cellar | ⭐⭐⭐ | Polite | Environmental Interaction + Deduction + Sequence | NO (optional, unlocks crypt) |
| 013 | Courtyard Entry | Courtyard | ⭐⭐⭐⭐ | Tough | Lateral Thinking + Environmental/Spatial | NO (alternate path) |
| 014 | Sarcophagus Puzzle | Crypt | ⭐⭐⭐ | Polite | Discovery + Deduction (Pattern Recognition) | NO (optional, lore reward) |

#### Key Design Decisions

1. **GOAP-compatible where appropriate:** Puzzles 009 and 011 (critical path) have GOAP-resolvable mechanical steps, but discovery moments remain human-only. Puzzle 012 is explicitly GOAP-incompatible (knowledge gate via ritual interpretation). This follows Frink's core finding: GOAP makes inventory puzzles obsolete → design for understanding.

2. **Multi-sensory clues throughout:** Every puzzle has a full sensory hints table. Key innovations:
   - Puzzle 010: SMELL is the primary discovery channel (oil bottle vs wine bottles)
   - Puzzle 012: SMELL is a feedback channel (incense confirms progress)
   - Puzzle 014: FEEL reveals the empty sarcophagus mystery (scratch marks inside)

3. **Progressive complexity (Witness model):** Puzzles build on previously taught concepts:
   - 001 taught fire chain → 010 teaches fuel combination
   - 007 taught spatial discovery → 009 teaches nested container discovery
   - 006 taught lock-and-key → 012 teaches symbolic/ritual interaction (non-physical "key")

4. **No softlocks:** Every critical-path puzzle (009, 011) is Zarfian Merciful or Polite. Optional puzzles (012, 014) are Polite. Only the alternate-path puzzle (013) reaches Tough — appropriate for players who chose the high-risk window escape.

5. **Level boundary flags:** Identified objects that could cross into Level 2:
   - **Must cross:** Tome (lore), burial goods (economy)
   - **May need destruction:** Crowbar, rope (could trivialize L2 puzzles), oil lantern (light advantage)
   - **Self-consuming:** Iron key (purpose fulfilled in L1), silver key (same)
   - **Flag for CBG:** All crypt objects are optional finds — L2 must NOT require them

6. **Narrative seeds for Level 2:** 
   - Empty sarcophagus E (who opened it? what was taken?)
   - Tome's warning ("what sleeps below must never wake")
   - The Keepers of the Vigil (religious order that built the manor)

#### New Objects Specified for Flanders

~30 new objects across puzzles 009–014, including:
- **Storage Cellar:** large-crate, small-crate, grain-sack, iron-key, crowbar, straw-packing, wine-rack, wine-bottle (×3), oil-bottle, oil-lantern, rope-coil
- **Deep Cellar:** stone-altar, offering-bowl, incense-burner, tattered-scroll, silver-key, stone-panel, unlit-sconce (×2)
- **Hallway:** stone-stairway (exit), oak-door-top (exit)
- **Courtyard:** stone-well, well-bucket, ivy, cobblestone-loose, wooden-door-courtyard, ground-floor-window (×2), rain-barrel, first-floor-shutters
- **Crypt:** sarcophagus (×5 instances), tome, silver-dagger, burial-jewelry, burial-coins, candle-stub (×4), wall-inscription

#### Technical Notes for Bart

1. **Puzzle 012 ritual mechanism:** Requires Boolean-AND compound trigger (incense smoldering + flame in offering bowl). Recommend room-level event listener over individual object guards — keeps logic in room metadata per Principle 8.
2. **Sarcophagus instances:** 5 instances from 1 base class with per-instance overrides (effigy, inscription, contents). Follows Principle 5 exactly.
3. **PUSH/LIFT/SLIDE verbs for heavy lids:** May need verb handler additions if not already present. Check `engine/verbs/init.lua` for heavy-object manipulation.

### Files Created
- `docs/puzzles/009-crate-puzzle.md` (13.6 KB)
- `docs/puzzles/010-light-upgrade.md` (12.1 KB)
- `docs/puzzles/011-ascent-to-manor.md` (11.4 KB)
- `docs/puzzles/012-altar-puzzle.md` (17.0 KB)
- `docs/puzzles/013-courtyard-entry.md` (15.3 KB)
- `docs/puzzles/014-sarcophagus-puzzle.md` (17.4 KB)

### Research Citations Used
- Frink §1.3 [7][8] — Emily Short's narrative reward and through-line principles
- Frink §2.1 [11] — The Witness scaffolding / progressive complexity
- Frink §2.3 [15][16] — Obra Dinn observation-based deduction
- Frink §2.4 [17] — Outer Wilds knowledge-gate model
- Frink §2.6 [19][20] — Riven integrated environmental puzzle design
- Frink §3.1-3.3 [21][22][23][24] — Escape room flow structures, chaining, physical objects
- Frink §3.5 [25] — Neuroscience of "aha!" moments
- Frink §4.1-4.2 [26][27] — Real-world problem solving, material consistency
- Frink §5.1-5.3 [28][29][32] — Gate taxonomies, hint design, cognitive science
- Frink §6.2-6.4 — GOAP paradigm shift, material-physics puzzles, sensory system

### Key Insights for Future Puzzle Design

1. **GOAP makes Boolean-AND puzzles our sweet spot.** GOAP plans linear chains but cannot resolve parallel condition satisfaction (incense AND flame). Design more puzzles with simultaneous conditions.

2. **SMELL is underutilized.** Only Puzzle 010 (oil discovery) and 012 (incense feedback) use SMELL as primary channel. Future levels should feature smell-gated puzzles (tracking by scent, poison identification, etc.).

3. **Empty containers are powerful mystery hooks.** The empty sarcophagus (014-E) generates more narrative tension than any treasure. Future levels should plant "evidence of prior action" — emptied chests, disturbed dust, moved furniture.

4. **Ritual/symbolic puzzles bypass GOAP beautifully.** The altar puzzle (012) proves that "perform a ritual based on written instructions" is a pure knowledge gate that GOAP cannot shortcut. This pattern is infinitely extensible (recipes, spells, ceremonies, codes).

5. **Light-as-resource creates organic difficulty modifiers.** Players who found the lantern (010) can sacrifice the candle for the altar ritual (012) without penalty. Players who didn't must make a strategic choice. This cross-puzzle synergy emerged naturally from resource design.

6. **Level boundary design needs early attention.** Several objects (crowbar, rope, tome, silver dagger) could break Level 2 if carried forward. Recommend: CBG creates a formal "Level 1→2 inventory audit" before Level 2 puzzle design begins.

---

## Session: Tutorial Gap Mini-Puzzles (2026-07-22)

### Work Completed

Designed 2 mini-puzzles (015–016) to fill tutorial coverage gaps identified by CBG's analysis.

#### Puzzles Created

| ID | Name | Room | Difficulty | Cruelty | Pattern | Critical Path? |
|----|------|------|------------|---------|---------|----------------|
| 015 | Draft Extinguish | Deep Cellar → Hallway (stairway) | ⭐ | Merciful | Environmental/Spatial (State Change) + Transformation | NO |
| 016 | Wine Drink | Storage Cellar | ⭐ | Merciful | Discovery + Sensory Rewards | NO |

#### Key Design Decisions

1. **Environmental triggers over forced tutorials:** Puzzle 015 uses a stairway draft to extinguish the candle — the player EXPERIENCES the extinguish/relight cycle rather than being told about it. This follows The Witness principle (Frink §2.1): show results, don't explain rules.

2. **Verb contrast pairs:** Puzzle 016 (wine = DRINK = safe) directly contrasts Puzzle 002 (poison = TASTE = death). Together they teach discrimination, not fear. Players learn to investigate before consuming, not to avoid all liquids.

3. **Minimal new work:** Puzzle 015 requires zero new objects (candle FSM already supports extinguish/relight), only a new `on_traverse` exit-effect pattern. Puzzle 016 requires one FSM transition added to wine-bottle.lua. Both are tiny additions to existing content.

4. **Lantern reward validation:** Puzzle 015 retroactively rewards Puzzle 010 (oil lantern) — the lantern's `wind_resistant = true` means it survives the draft while the candle doesn't. The optional upgrade proves its value.

5. **New engine pattern identified:** `on_traverse` exit effects — generic mechanism for environmental interactions during room transitions. First use is wind/extinguish; future uses include water crossings, narrow passages, temperature shocks. Flagged for Bart.

#### Handoffs

- **Flanders:** Add `drink` verb transition to wine-bottle.lua (open→empty); add `on_taste` sensory; add DRINK rejection to oil-bottle.lua
- **Moe:** Add `on_traverse` wind effect to stairway exit in deep-cellar room metadata
- **Bart:** Design/implement `on_traverse` exit-effect pattern (new engine concept)
- **Nelson:** Test both puzzles per enumerated test cases in puzzle docs

### Files Created
- `docs/levels/01/puzzles/puzzle-015-draft-extinguish.md` (16.0 KB)
- `docs/levels/01/puzzles/puzzle-016-wine-drink.md` (16.0 KB)
- `.squad/decisions/inbox/bob-mini-puzzles.md` (3.6 KB)

### Research Citations Used
- Frink §2.1 [11] — The Witness scaffolding / progressive complexity
- Frink §2.4 [17] — Outer Wilds knowledge-gate model
- Frink §4.1 [26] — Real-world physics in puzzle design

---

## Session: Player Health & Injury System Design (2026-07-23)

### Work Completed

Designed the complete Player Health & Injury gameplay system across 4 design documents. This covers health scale, narrative voice, damage model, death design, injury catalog with FSMs, healing items, and puzzle integration patterns.

#### Documents Created

| Document | Size | Content |
|----------|------|---------|
| `docs/design/player/README.md` | 6.3 KB | System overview, design principles, connections to existing systems, implementation priority |
| `docs/design/player/health-system.md` | 21.0 KB | 100-point HP scale, 5 health tiers, narrative voice per tier, damage model, death design, Level 1 scenarios, status command, engine integration notes |
| `docs/design/player/injury-catalog.md` | 21.7 KB | 6 Level 1 injuries (minor cut, deep cut, bruise, bleeding, mild poison, burn) + 4 future injuries (infection, broken bone, hypothermia, exhaustion), FSM patterns, stacking rules, 5 puzzle design patterns |
| `docs/design/player/healing-items.md` | 22.8 KB | Wound dressings (bandage, cobweb), restoratives (potion, food, water, wine), medicines (antidote, salve, poultice), rest mechanics, metadata patterns, design guidelines, Level 1 healing inventory |

#### Key Design Decisions

1. **Health is narrative, not numeric.** Players experience health through prose — pain descriptions, sensory degradation, fragmentary text at near-death. No HUD, no health bar. A `status` command returns narrative assessment, not numbers.

2. **Injuries are independent FSMs.** Each injury has its own state machine (active → treated → healed), independent timers, and specific treatment requirements. This follows Principle 3 (Objects Have FSM; Instances Know Their State) applied to player conditions.

3. **Treatment and healing are separate.** Stopping bleeding (bandage) is not the same as restoring lost HP (potion/rest). The player may need both. This creates a two-step recovery loop that adds strategic depth.

4. **Existing mechanics are the foundation.** The `bleed_ticks` system, `player.state.bloody`, `injury_source` capability, and poison death are all prototypes of the health system. The design formalizes and extends them rather than replacing them.

5. **Level 1 healing is primitive.** No potions, no medicine. Just cloth bandages (torn from blanket/cloak/curtains), wine, water, and rest. This teaches fundamentals before introducing powerful items.

6. **Injuries create puzzle opportunities.** Five documented patterns: Ticking Clock (bleed out timer), Capability Gate (broken arm blocks climbing), Risky Shortcut (jump = fast but costly), Prepared Adventurer (foreshadow + prepare), Medical Puzzle (diagnose + treat).

7. **Instant death preserved for extreme hazards.** Poison bottle and long falls remain instant-kill. These are player-initiated or clearly telegraphed. Survivable injuries use the HP system.

8. **Healing items use existing object metadata patterns.** A bandage declares `healing.stops_bleeding = true`; the engine reads it. No special-casing. Same pattern as `provides_tool`, `casts_light`, etc.

### Learnings

- **The blanket/cloak/curtains are already healing resources.** They can be torn for cloth strips → bandages. This creates resource tension: cloth for sewing vs. cloth for medical supplies vs. cloth for rope. Existing objects, new purpose.
- **Blood writing is the first health mechanic.** The prick → bleed → write chain already costs HP (conceptually). Formalizing this into the health system means blood writing becomes a strategic choice with real cost.
- **GOAP should NOT auto-heal.** GOAP can help find/prepare healing items but should never auto-apply treatment. The player must choose when and how to heal — this is the puzzle.
- **Wine (Puzzle 016) is the first restorative.** The existing DRINK interaction for wine bottles becomes a 5 HP heal + warmth effect. Tutorial gap fix becomes healing system foundation.
- **Injury cascading (cut → infection if untreated) creates multi-stage puzzles.** This is the "degenerative" pattern that makes health a long-term concern, not just an immediate reaction to damage.
