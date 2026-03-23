# Comic Book Guy — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Role:** Game Designer responsible for object definitions, sensory descriptions, and content creation

## Core Context

**Agent Role:** Game Designer specializing in multi-sensory object systems and interactive content that works in complete darkness.

**Design Philosophy:** Darkness is not a wall — it's a different mode of play. Every sense gives different information about the same object. TASTE is the "learn by dying" sense that teaches caution and consequence.

## Archives

- `history-archive-2026-03-22.md` — Early sessions
- `history-archive-2026-03-20T22-40Z-comic-book-guy.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): 37+ objects, multi-sensory convention, skills system, FSM lifecycle, command variation matrix, composite objects, spatial system

## Recent Updates

### Session Update: Injury ↔ Puzzle Integration Analysis (2026-07-25)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/injuries/puzzle-integration.md` — ~35 KB strategic design analysis.

**Core Analysis:**
1. **Five Roles of Injury:** Injuries AS puzzles (ticking clocks, triage), Puzzles CAUSING injuries (failure consequences), Injuries BLOCKING puzzles (capability gates), Treatment AS puzzles (crafting chains), Engine hooks (on_traverse, on_pickup, on_timer)
2. **Level 1 Integration Map:** Each of 7 rooms mapped to specific injury sources, treatment resources, and teachable moments
3. **Engine Proposals:** `injury_effect` handler (parallels `wind_effect`), prevention conditions, capability gate system
4. **Anti-Patterns:** Never injure for observation, never create unwinnable stacks, critical path completable injury-free
5. **Medical Scroll:** Proposed tattered scroll content for deep cellar that pre-loads treatment knowledge

**Key Design Decisions:**
- Bedroom is safest room (5 avoidable injuries, all educational); Crypt is danger room (full complexity)
- Courtyard is treatment hub (water for burns, rest for bruises) — ironic because it's hardest to reach safely
- Minor cut calibrates expectations; nightshade is the "final exam"
- Injury severity must match recklessness of player approach
- "Fair Warning" principle: every injury must be traceable to a warning the player could have heeded

**Decision filed:** `.squad/decisions/inbox/cbg-injury-puzzles.md`

### Session Update: Spatial Relationships & Stacking System Design (2026-03-26)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/spatial-system.md` — comprehensive 13,500-word game design document (46 KB).

**Core Design:**
1. **Five Relationships:** ON, UNDER, BEHIND, COVERING, INSIDE with distinct mechanics
2. **Stacking Rules:** weight_capacity, size_capacity, weight categories (Light/Medium/Heavy)
3. **Hidden Objects:** hidden → hinted → revealed states, declarative discovery triggers
4. **Movable Furniture:** PUSH/PULL/MOVE with preconditions, movement difficulty tiers
5. **Spatial Verbs:** PUT ON, TAKE FROM, LIFT, LOOK UNDER, LOOK BEHIND, PUSH/PULL/MOVE
6. **Room Layout Model:** Position anchors, bi-directional relationships, atomic updates
7. **Integration:** Containers + FSM + Composite parts + Dark/Light + Sensory system
8. **Implementation:** 4 phases (core model → discovery → advanced verbs → integration)

**Key Design Decisions:**
- Trap door doesn't exist to player until rug moves (visibility gate)
- Surfaces have weight+size capacity
- Movement in darkness uses FEEL as primary sense
- Composite object parts stay coherent when parent moves

### Session Update: Composite & Detachable Object System Design (2026-03-25)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/composite-objects.md` — 39.5 KB, 8 decision sections

**Key Designs:**
- Single-file architecture (parent + parts in one .lua file)
- Part factory pattern with detachable/non-detachable parts
- FSM state naming: {base_state}_with_PART / {base_state}_without_PART
- Two-handed carry system (0/1/2 hands per object)
- Reversibility as design choice (drawer: yes, cork: no)

### Session Update: FSM Object Lifecycle System Design (2026-03-23)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/fsm-object-lifecycle.md` — 25,000-word design document
- Analyzed 39 objects for FSM candidates
- Consumable durations: matches (3 turns), candles (100+20 turns)
- Container reversibility pattern, tick/turn system
- Implementation roadmap: 4 phases

### Session Update: Command Variation Matrix (2026-03-22)
**Status:** ✅ COMPLETE

**Deliverable:** `docs/design/command-variation-matrix.md`
- ~400 natural language variations for 31 canonical verbs + 23 aliases
- Covers darkness verbs, tool verbs, movement, container interactions
- Pronoun resolution: last-examined object
- Ground-truth validation set for embedding parser QA

### Session Update: Player Skills System Design (2026-03-21)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/player-skills.md` — 6,500-word design document
- Binary skill model, four acquisition methods (Find & Read, Practice, NPC Teaching, Puzzle Solve)
- MVP: Lockpicking, Sewing. Failure modes (bent pin, tangled thread)
- Blood writing system, no puzzle lock-out principle

### Session Update: Matchbox Rework + Match Objects + Thread (2026-03-20)
**Status:** ✅ COMPLETE
- Rewrote matchbox.lua as container with 7 individual match objects
- Created match.lua, match-lit.lua, thread.lua
- Patterns: container-with-contents, compound tool actions, consumable fire source

### Session Update: Multi-Sensory Convention Implementation (2026-03-19)
**Status:** ✅ COMPLETE
- 37 objects with multi-sensory descriptions (FEEL 100%, SMELL ~65%, LISTEN ~16%, TASTE ~8%)
- Decision D-28: Multi-Sensory Object Convention
- Poison bottle implementation (SMELL warns, TASTE kills)

## User Directives Captured
5. Newspaper editions in separate files (2026-03-20T03:40Z)
6. Room layout and movable furniture (2026-03-20T03:43Z)

## Learnings

### 2026-07-25: Injury-Causing Objects — Hook Taxonomy & Design Patterns
**Status:** ✅ 2 DESIGN DOCS WRITTEN

**Deliverables:** 
1. `docs/design/objects/poison-bottle.md` — 26.6 KB, comprehensive consumption-based injury design
2. `docs/design/objects/bear-trap.md` — 32.3 KB, comprehensive contact-based injury design

**Core Analysis: Engine Hook Categories**

The two designs establish a clear taxonomy of **injury-causing hook categories** that structure how different objects cause different injuries through different interaction patterns:

1. **Consumption Hooks** (`on_consume`, `on_drink`, `on_eat`, `on_taste`)
   - Triggered when player ingests/consumes an object
   - Example: Poison bottle → poisoned injury
   - Safety model: Can investigate (read label, smell) before consuming
   
2. **Contact Hooks** (`on_take`, `on_touch`, `on_interact`)
   - Triggered when player physically touches/grasps an object
   - Example: Bear trap → crushing injury
   - Safety model: Observation is safe, interaction is risky
   
3. **Proximity Hooks** (`on_traverse`, `on_enter`, `on_step`) — FUTURE
   - Triggered when player enters room or traverses area
   - Example: Floor trap, gas room → injury on entry
   - Safety model: Can't avoid without prior knowledge
   
4. **Duration Hooks** (`on_tick`, `on_worsening`, `on_healing`)
   - Triggered each turn while injury active
   - Example: Poison/bleeding → ongoing damage per turn
   - Safety model: Injury progresses unless treated

**Poison Bottle Design Insights:**

- **Nested parts architecture:** Bottle ≠ liquid ≠ cork ≠ label. Cork is detachable; label is readable without opening. Creates agency before consequence.
- **Consumption pipeline:** DRINK → `on_consume` hook → passes to injury system → "poisoned-nightshade" injury → ticks -2 health/turn
- **Fair warning design:** Label readable before drinking. SMELL warns after opening. TASTE warns with pain but not death. Only DRINK causes lethal injury.
- **Severity levels:** Sip (low) vs. gulp (medium) vs. drink-all (high) map to different damage scales and durations.
- **Specificity matters:** Nightshade ≠ mild poison ≠ viper venom. Different onset times, different durations, different required cures. Treatment matching is the puzzle.

**Bear Trap Design Insights:**

- **State machine:** SET (armed) → TRIGGERED (snapped) → DISARMED (safe). Each state has distinct description, danger level, and affordances.
- **Contact vs. proximity:** This design uses object-level `on_take` / `on_touch` (player chooses to interact). Room-level `on_traverse` (automatic trigger) is future work.
- **Crushing injury:** Distinct from cutting/bleeding. Combines initial blunt damage (-15) with bleeding component (-2/turn). Teaches mechanical authenticity.
- **Skill integration:** Disarming requires lockpicking skill + correct tool. Gives the skill narrative use beyond lockpicking.
- **Discovery hierarchy:** Visible trap teaches "observe before touching." Hidden trap (future) teaches "some dangers are concealed."

**Design Decisions Locked In:**

1. **Hook categories map to player interaction patterns:** Consumption (swallow), contact (touch), proximity (traverse), duration (wait). Each has different safety model.
2. **Nested parts create agency:** Poison bottle's cork + label enable investigation before consequence. This is pedagogically superior to flat consumables.
3. **Specificity creates puzzle difficulty:** Generic antidote ≠ nightshade antidote. Teaches treatment matching, not just "find cure."
4. **Visible hazards teach first:** Bear trap is visible (not hidden). Player learns through observation before discovering hidden traps (Level 2).
5. **Fair warning principle:** Every injury must be avoidable through investigation. No gotchas, no trap randomization. Consequence comes from *ignoring* warnings.
6. **FSM mutations update categories:** When trap transitions SET → TRIGGERED, categories change ("dangerous" → "evidence"). Engine queries can filter by category.

**Pattern Library Established:**

- Consumables: poison, potion, food (on_consume + severity mapping)
- Contact hazards: trap, hot object, sharp edge (on_take / on_touch)
- Room hazards: gas, pit, pressure-plate (on_traverse + on_enter — future)
- Ongoing effects: bleeding, poison DoT, burning (on_tick)
- Reversible detachment: cork, drawer, blade (can be reattached with new mechanic)
- Skill-triggered actions: disarm trap requires lockpicking (on_disarm requires skill check)

**Key Design Principle Affirmed:**

*Interaction pattern determines injury type determines solution.* Poison is solved by antidotes (treatment matching). Bear trap is solved by disarming (skill + tool matching). Burning is solved by cooling (environmental resource matching). The game teaches through this pattern repetition: "Understand what hurt you. Find what solves it."

**Decision filed:** `.squad/decisions/inbox/cbg-injury-hooks-taxonomy.md`

### 2026-03-23: Unconsciousness, Mirrors, and Player Appearance Subsystem
**Status:** ✅ 5 DESIGN DOCS WRITTEN

**Design decisions locked in:**
1. **Unconsciousness is binary, not graduated.** No dazed state. Either you're conscious or knocked out. Clean transition creates clarity for players.
2. **Severity-based duration scales threat.** 3-turn light hit vs. 18-turn sledgehammer creates tunable puzzle pressure. Players learn consequences through duration feedback.
3. **Injuries tick during unconsciousness.** This is the KEY PUZZLE. A player can bleed out while sleeping/KO'd. Sleep becomes strategically dangerous, not a rest button.
4. **Armor interacts with unconsciousness via reduction modifier.** Helmets reduce duration — not a binary negate, but a percentage reduction (30-75%). Allows progression: leather helmet > iron helmet > plate + gorget.
5. **Self-infliction via `hit` parallels `stab self`.** Same testing pattern for different injury types. Player can safely explore mechanics without traps. Builds intuition.
6. **Appearance subsystem is the "eyes" of the game.** Layer-by-layer rendering (head→feet) avoids robotic lists. Natural connectives make prose flow. Same subsystem later powers multiplayer. Must be beautiful first, functional second.
7. **Mirrors are metadata-only.** The `is_mirror` flag on objects routes examine to appearance subsystem. No special mechanics. Appearance is where complexity lives.
8. **Health is never displayed as a number.** Derived from injuries aggregate. Narrative voice shifts with severity (healthy→worn→critical→dying). Player experiences their condition through prose, not HUD.

**Design principles affirmed:**
- State-driven composition beats hardcoded content (appearance from flags, not templates)
- Puzzle-first design (unconsciousness creates time-pressure and resource-matching puzzles)
- Sensory richness in narrative text compensates for text-only interface
- Layered systems enable reuse (same appearance subsystem: mirrors today, multiplayer tomorrow)

### Earlier Sessions (Previous Learnings)

- Containers are simpler and more immersive than charges (real matches > abstract counter)
- Compound actions create better puzzles (STRIKE match ON matchbox)
- Skills as discovery gates, not progression gates
- Binary skills scale better than XP bars for V1
- Failure costs teach design language (bent pins, tangled threads)
- Single-file architecture cleaner than file-per-part scattering
- Spatial relationships need to be first-class (ON/UNDER/BEHIND/COVERING are distinct)
- Hidden objects are the mystery teacher (discovery drives exploration)
- Decomposable objects create emergent puzzles
- Darkness is solvable without light when sensory descriptions are complete
- `mutate` on FSM transitions is for BASE-LEVEL properties (weight, size, keywords, categories) — don't duplicate what states already handle (name, description, sensory text)
- Weight mutations are the highest-immersion payoff — players FEEL physics through inventory weight
- Functions for proportional changes (`weight * 0.7`), absolutes for terminal states (`weight = 0.05`)
- Keywords must reflect current object reality for parser resolution ("open window", "spent match", "empty bottle")
- Categories as system queries ("dangerous", "ventilation", "useless") enable cross-system behavior
- 10 of 37 objects have FSM transitions where `mutate` adds value; 27 are static or use old mutations system
- Tier 1 mutate candidates: candle (weight↓ per burn cycle), match (keywords→spent), poison-bottle (weight+categories), window (keywords+categories)
- Level 1 covers 31 of 35 engine verbs through puzzle necessity alone — no exposition needed
- Tutorial gaps are small: EXTINGUISH, DRINK, EAT, BURN never required. EXTINGUISH and DRINK are the only two worth fixing before Level 2.
- Scaffolding works: same pattern at different scales (drawer→matchbox→match THEN crate→sack→key) is textbook Witness-model progressive complexity
- The candle extinguish→relight FSM cycle is fully implemented but no puzzle exercises it — a draft in the stairway or altar ritual variant would fix this cheaply
- TASTE teaches "danger" but DRINK (consumption) is never safely demonstrated — players may fear all liquids after the poison bottle

### 2026-03-27: Object Spatial Relationships — Hiding vs On-Top-Of
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/objects/spatial-relationships.md` — 13 KB focused design document

**Core Insight from Play-Test (Wayne):**
The game doesn't distinguish between objects that sit ON something visible (candle on nightstand) and objects that HIDE something beneath them (rug over trap door). This difference is fundamental to creating mystery and discovery.

**Four Spatial Relationships Defined:**
1. **Resting On** — Both objects visible, no interaction needed to see both (candle on nightstand)
2. **Covering/Hiding** — Top object visible, bottom INVISIBLE until interaction (rug over trap door)
3. **Behind** — Front visible, back HIDDEN until opening/moving (curtains hiding window)
4. **Inside** — Container mechanics (handled separately in containers.md)

**Key Design Decisions:**
- Hidden objects do NOT appear in SEARCH results (discovery phase)
- EXAMINE of covering object includes ONE hint sentence (hint phase)
- Move/lift/pull of covering object triggers dramatic discovery message (reveal phase)
- Discovery messages are 2-3 sentences, sensory, explain WHY it was hidden
- Hint→Verb progression must feel natural, not forced or arbitrary
- Different cover types suggest different verbs (rug: MOVE; curtains: PULL ASIDE; painting: MOVE)
- Hidden objects reward exploration, never gate critical paths

**Player Experience Design:**
- Hidden objects = mystery = discovery = engagement
- Search gives hints, not spoilers
- Reveal narration creates narrative moment, not just mechanical update
- Players learn play pattern: "look UNDER things, MOVE furniture, EXAMINE carefully"
- This is how the game hides puzzle elements (switch behind portrait, key under floorboard, etc.)

**Real-World Connection:**
- A rug HIDES what's under it (functional concealment)
- A book SITS ON a table (both visible)
- A painting HIDES a safe behind it (deliberate design)
The game must distinguish these three cases for meaningful space and real discovery.

**Anti-Patterns Identified:**
- Don't hide objects without hints
- Don't make hidden objects feel arbitrary
- Don't put mandatory puzzle elements in hidden objects
- Don't make "find the hidden thing" a puzzle by guessing randomly

**Implementation Guidance:**
- Object designers: declare covering relationships, write hints (1 sentence), write discovery (2-3 sentences)
- Room designers: place hints deliberately, consider player expectations, test hint→verb progression
- Testing: verify visibility gates, search exclusion, hint clarity, discovery satisfaction
