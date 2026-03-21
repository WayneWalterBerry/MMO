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
