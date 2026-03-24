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

### Session Update: Brass Spittoon Object Design Document (2026-03-24)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/objects/brass-spittoon.md` — Comprehensive object design doc, ~14.5 KB.

**What was done:**
- Wrote Phase D1 brass spittoon design document
- Established brass as durable counterpart to ceramic chamber pot (contrast principle)
- Documented physical properties: tarnished brass, wide rim, tobacco stains, weight 2.5 (dense)
- Detailed wearable mechanics: head/outer slot, is_helmet = true, makeshift fit, coverage 0.9
- Specified FSM states: intact → stained → dented (cosmetic degradation only, never shatters)
- Included all five sensory descriptions (feel, smell, listen, taste) with worn variants
- Created comprehensive gameplay tradeoff table (pot vs spittoon) highlighting durability vs weight vs smell
- Documented protection profile: 1.8–2.0 (vs pot's 1.4–1.6) with brass material properties as foundation
- Container specification: capacity 2, holds small items + liquids (true to purpose)
- Included keywords: spittoon, cuspidor, spit bowl, brass bowl, tobacco bowl
- Provided implementation notes for Phase D2 (Flanders) with complete lua structure
- Emphasized material properties as single source of truth: brass (hardness 6, density 8500, fragility 0.1)

**Key Design Decisions:**
- **Brass ≠ Strong:** Spittoon has lower hardness (6 vs ceramic 7, steel 9) but incredible durability from fragility 0.1
- **Dents Forever:** Fragility 0.1 means accumulative cosmetic damage (dents) but never structural failure (no shattering)
- **Wear Penalty:** Intense tobacco smell narration ("The inside still smells of old tobacco. You catch whiffs of it every time you move.")
- **Weight Matters:** 2.5 density (vs pot 1.0) signals future integration with stamina system
- **Design Contrast:** Ceramic says "use it now before it breaks"; Brass says "you'll be stuck with this forever"
- **Coverage 0.9:** Nearly complete head protection but back of neck exposed (not a helm, an improvised bowl)
- **Makeshift Fit:** ×0.5 protection multiplier; the spittoon wasn't designed for head wear

**Document Structure:**
1. Physical description + material properties
2. FSM lifecycle (intact → stained → dented)
3. Comprehensive sensory matrix (look/feel/smell/listen/taste)
4. Worn state sensory descriptions (smell, appearance, feel, listen)
5. Wearable equip metadata + protection profile
6. Behavior (wear/remove/conflict)
7. Combat degradation (never shatters, dents accumulate)
8. Container specifications
9. Keywords & aliases (spittoon, cuspidor, spit bowl, etc.)
10. Weight & physical impact (2.5, future stamina integration)
11. Design principles: Brass vs Ceramic contrast
12. Gameplay tradeoff table
13. Sensory deep dive (on_feel, on_smell, on_listen, on_taste)
14. Related objects (chamber pot comparison)
15. Implementation notes for Phase D2

**Why This Matters:**
- Brass spittoon is durable alternative to ceramic pot, not superior—different narrative (endurance vs fragility)
- Material properties alone create emergent durability: fragility 0.1 → dents forever, fragility 0.7 → cracks immediately
- Establishes pattern for object design: containers can be wearable, wearables can be containers
- Tobacco smell when worn is gameplay consequence (not bug), not just flavor
- Sets foundation for Phase D2 (implementation) and Phase D3 (testing)
- Demonstrates designer mental model: "What are this object's material properties?" → everything else emerges

### Session Update: Armor System Design Document (2026-03-24)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/armor-system.md` — Designer-facing armor system guide, ~40 KB comprehensive design document.

**What was done:**
- Wrote Phase A2 armor system design doc covering designer responsibilities (NOT engine architecture)
- Documented core philosophy: **protection is derived from material, never hardcoded**
- Created Material → Protection table (22 materials ranked by protection value)
- Built Damage Type × Material Interaction Matrix (slashing vs piercing vs blunt)
- Detailed degradation narratives (ceramic cracks, brass dents, fragility mechanics)
- Provided 5 full worked examples: ceramic pot (fragile), brass spittoon (durable), steel helm (elite), leather cap (flexible), sack on head (comedic)
- Brass spittoon case study: hardness 6, fragility 0.1, durable but heavy (design philosophy: durable ≠ strong)
- Design tips: material reuse, fit as story, coverage for partial protection, layering armor, antipatterns
- Integration guide: how armor hooks into injury system, wearables, appearance/mirror
- Q&A section covering 7 common designer questions
- Future extensions section (not Phase A2): elemental armor, enchantments, repair, weight system, environmental wear

**Key Design Decisions:**
- Designers declare `material = "ceramic"` and `wear = { slot, layer, coverage, fit }` — engine derives everything else
- No hardcoded `provides_armor`, `reduces_unconsciousness`, or `armor_strength` properties on objects
- Material properties (hardness, flexibility, density, fragility) are single source of truth for armor behavior
- Coverage (0.0–1.0) and fit (makeshift/fitted/masterwork) are multiplicative factors on protection
- Fragility determines degradation: ceramic (0.7) breaks after 2–3 hits; brass (0.1) dents forever
- All interactions (damage type, material, location) are emergent from existing systems, not hardcoded

**Document Structure:**
1. Executive summary + Big Picture flow
2. Making an object act as armor (metadata required)
3. Material → Protection table (all 22 materials ranked)
4. Damage Type × Material Matrix (slashing/piercing/blunt vs materials)
5. Degradation narratives (FSM states with flavor text)
6. Five complete worked examples (ceramic pot, brass spittoon, steel helm, leather cap, sack)
7. Brass spittoon case study (durable counterpart to ceramic pot)
8. Core design philosophy (6 principles)
9. Design tips for creators (6 practical guidelines)
10. Anti-patterns (5 common mistakes)
11. Integration with injury/wearable/appearance systems
12. Q&A (7 common questions)
13. Future extensions (not in Phase A2)

**Why This Matters:**
- Establishes designer mental model: materials are properties, not labels
- Prevents future hardcoding of per-object armor values
- Enables emergent gameplay: same system handles pots, spittoons, helms, and sacks without special cases
- Documents the Dwarf Fortress principle: "engine operates on property bags, emergent behavior is free"
- Sets up Phase A4 (implementation) with clear design semantics

**Document Quality:**
- Timeless design guidance (not bug fix history)
- Designer-facing (not engine architecture)
- 13 comprehensive sections covering philosophy, mechanics, examples, integration
- Cross-referenced to architecture docs and material registry
- Includes real worked examples from the game world (ceramic pot, brass spittoon)

### Session Update: Chest Object Design Enhancement (2026-07-25)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/objects/chest.md` — enhanced existing design doc with ~150 lines of new content.

**What was done:**
- Enhanced existing chest.md (which had core design from prior session) with four new sections
- Added **Transitions** table with mutate fields (keywords ±open), matching the 2026-07-20 pattern used in wardrobe.md and nightstand.md
- Added **Edge Cases** section: 9 scenarios (one-hand carry, closed-container verbs, open-while-carrying, nesting, dropping, D-PEEK search behavior, smell-through-wood partial gating)
- Added **Comedy & Flavor Opportunities** section: 6 comedy beats (dramatic lift, empty disappointment, one-hand mockery, unnecessary close, acoustic properties, smell of history)
- Added **Implementation Notes for Flanders** section: property table, state-accessible flag mapping, drawer.lua pattern reference, drawer-vs-chest comparison table, iron hardware guidance, keywords/categories

**Key Design Decisions:**
- Smell is NOT fully gated by closed state — faint mustiness seeps through wood (unlike look/feel which are blocked)
- Iron hardware is decorative metadata, not a separate material entry (primary material = oak)
- Cannot open chest while carrying it (must drop first — two-step sequence)
- Capacity/size checks at insertion time, not close time (no protruding-object physics)
- Chest follows drawer.lua FSM+container pattern exactly, just scaled up

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

### 2026-07-26: EP7 — Bear Trap Design Doc Updated for Effects Pipeline Integration
**Status:** ✅ DESIGN DOC UPDATED

**Deliverable:** Updated `docs/design/objects/bear-trap.md` with 243 new lines detailing Effects Pipeline integration (section 8, ~1500 words).

**Integration Pattern Established:**

The bear trap design now demonstrates the complete **object declaration → pipeline dispatch** pattern:

1. **What:** Objects declare effects in structured tables
   ```lua
   effect = {
       { type = "inflict_injury", injury_type = "crushing-wound", damage = 15, ... },
       { type = "narrate", message = "..." },
       { type = "mutate", mutations = { is_armed = false, ... } }
   }
   ```

2. **When:** Engine hooks trigger the table (FSM transitions, sensory verbs, room entry)
   - `take` verb → finds transition → calls `effects.process()`
   - `feel` verb → finds `on_feel_effect` field → calls `effects.process()`

3. **How:** Pipeline routes to subsystems without verb handler knowledge
   - Normalization: strings or tables → unified array format
   - Before-effect interceptors: armor reduces damage, immunity cancels effect
   - Dispatching: `inflict_injury` → `injuries.inflict()`, `narrate` → `print()`, `mutate` → object update
   - After-effect interceptors: achievements, logging, side effects

**Key Design Decisions Locked In:**

1. **Preconditions prevent side effects:** Disarm skill check happens before FSM transition, so failure prevents all mutations + effects
2. **Interceptors run after transition:** Armor reduction doesn't undo state change (trap is already triggered); it just reduces damage
3. **Structured effects are extensible:** New effect types added to pipeline without touching object code
4. **Migration is opt-in:** Legacy `effect = "poison"` strings still work via `normalize()` backward-compat layer
5. **Pipeline is triple-dispatch:** Object declares WHAT (effect table), engine decides WHEN (hook), pipeline decides HOW (handler registry)

**Why This Matters:**

- **No verb handler edits for new objects:** New trap types just declare effects in metadata
- **Consistent injury path:** All contact injuries flow through same pipeline (glass shard, hot object, thorns, etc.)
- **Armor system works generically:** Before-effect interceptor reduces any `inflict_injury` damage, not trap-specific
- **Skill gating is composable:** Precondition can check skill + location + object state; FSM transition respects all preconditions
- **Mutation system stays coherent:** State changes (SET→TRIGGERED→DISARMED) and property updates (is_armed, is_sprung, categories) all via same mutation handler

**Documentation Notes:**

- Parallel to poison-bottle design (consumable→injury) but different trigger (contact vs. consumption)
- Both demonstrate same pipeline: object metadata → effects table → engine dispatch → subsystem action
- Difference: poison uses FSM transition effect, bear trap uses FSM transition + sensory verb effects
- Future: hidden traps will use `on_traverse` hook, teaching room-level trigger pattern

**Sections Added:**
- 8.1 Overview (pipeline architecture, current vs. future)
- 8.2 Architecture comparison (inline vs. pipeline dispatch)
- 8.3 Effect declaration format (structured tables for FSM and sensory verbs)
- 8.4 Effect types table (inflict_injury, narrate, mutate)
- 8.5 Before-effect interceptors (armor reduction pattern)
- 8.6 Disarm mechanics (precondition pattern)
- 8.7 Hook references (how hooks integrate with pipeline)
- 8.8 Migration notes (4 phases: object declaration → engine integration → interceptors → backward compat)
- 8.9 Why it matters (extensibility benefits)

**Renumbered Sections:**
- 9. Design Patterns & Reusability (was 8)
- 10. Testing & Validation Checklist (was 9)
- 11. Future Extensions (was 10)
- 12. Design Decisions & Rationale (was 11)
---

## MANIFEST COMPLETION — 2026-03-24T00:09:13Z

**Status:** ✅ SPAWN COMPLETE

**Manifest Item:** Chest design — Enhanced docs/objects/chest.md with transitions, edge cases, comedy, implementation notes

**Deliverables:**
- ✅ docs/objects/chest.md enhanced (~150 lines added)
- ✅ Four major sections: Transitions, Edge Cases, Comedy & Flavor, Implementation Notes
- ✅ Design decisions locked: smell partial gating, iron hardware metadata, carry constraints, insertion-time capacity checks
- ✅ Implementation-ready for Flanders (drawer.lua pattern reference)
- ✅ Orchestration log: .squad/orchestration-log/2026-03-24T00-09-13Z-cbg-chest.md

**Design Decisions Filed:** D-CHEST-DESIGN (merged into decisions.md)

**Team Context:**
- **Smithers (#85/#86 fix):** Search traversal (expand root) + wear auto-pickup from containers deployed (commit a4b0c50, 15 tests)
- **Nelson (M4 mirror review):** 8 scenarios tested, 26 tests written, 6 issues filed (#90-95)
- **Wayne Design Batch:** Material Consistency Core Principle approved (instances CAN override), nightshade L1, soiled bandage L2, combat deferred, Bob's puzzles theorized

**Orchestration Complete:** All 3 spawns consolidated into decisions.md. New TDD directive and hiring department policy filed. Ready for git commit.

---

### Session Update: Chest Design Carry-Over Verification (2026-03-24 — Autonomous)
**Status:** ✅ DESIGN COMPLETE & VERIFIED

**Task:** Design Carry-Over from yesterday's plan — "Chest object — Design doc + chest.lua (two-handed carry, open/close FSM, container, based on drawer pattern)"

**Verification Results:**

Both deliverables exist and are complete:

1. **Design Doc:** `docs/objects/chest.md` — 311 lines
   - ✅ Physical description: wooden chest, oak with iron bands
   - ✅ Two-handed carry system: `hands_required = 2`, strategic inventory trade-off documented
   - ✅ Open/close FSM: closed (default) ↔ open with sensory gating (accessible flag)
   - ✅ Container mechanics: 8-slot capacity, max item size 3, 30-unit weight limit
   - ✅ Material system: primary material `oak` with iron hardware as descriptive element
   - ✅ Sensory properties: comprehensive multi-sense matrix (look, feel, smell, listen) + taste edge case
   - ✅ Two-hand inventory integration: explicit interaction sequence example showing hands constraint
   - ✅ Drawer vs Chest comparison: detailed property table (size, weight, capacity, reattach_to)
   - ✅ Keywords: chest, trunk, storage, wooden chest, heavy chest, treasure chest
   - ✅ Level 1 placement: Crypt (puzzle chest), Deep Cellar (supplies chest) documented

2. **Implementation:** `src/meta/objects/chest.lua` — 103 lines, production-ready
   - ✅ Follows drawer.lua FSM+container pattern exactly (open state exposes contents, accessible flag per state)
   - ✅ GUID: `{6cf2ab69-60e5-4c14-9b3a-c559b6037cf4}`
   - ✅ Properties: size 5, weight 20, portable true, hands_required 2
   - ✅ Container config: capacity 8, max_item_size 3, weight_capacity 30
   - ✅ Transitions: closed→open ("click + hinge groan"), open→closed ("thud + latch click")
   - ✅ State-specific sensory: closed state shows exterior, open state lists interior contents via registry
   - ✅ Design doc references: All implementation details match design spec

3. **Design Decisions:** D-CHEST-DESIGN filed in decisions.md
   - ✅ Smell partial gating rationale (wood is porous, unlike sealed vault)
   - ✅ Iron hardware metadata guidance (primary material oak, iron described in text)
   - ✅ Cannot-open-while-carrying constraint documented
   - ✅ Capacity enforcement timing (at insertion, not at close)
   - ✅ Pattern reference for Flanders (drawer.lua = exact pattern to follow)

**Why This Matters:**
- Chest is a **flagship portable container** demonstrating the two-hand system
- Establishes **material-derived properties** pattern (oak hardness/fragility/density from registry)
- Provides **design+implementation parity** template for future objects
- **Gameplay impact:** Two-handed carry creates resource allocation choices (can't hold torch while carrying loot)
- **Sensory richness** without breaking isolation semantics (smell leaks through wood, look/feel fully gated)

**Coordination Complete:**
- ✅ Design doc passed review (Principle 1.4: code-derived, sensory space, spatial relationships)
- ✅ Implementation verified against Drawer pattern (FSM, container mechanics, state accessibility)
- ✅ Ready for player testing (Level 1 crypt/cellar placement verified in design doc)
- ✅ No outstanding design decisions or implementation blockers

**Conclusion:** Chest object design + implementation carries over from yesterday as **COMPLETE & VERIFIED**. Both design doc and .lua file are production-ready. Can proceed to next phase (chest instance placement in Level 1 rooms) without further design work.