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

- `history-archive.md` — Entries before 2026-07-14 (2026-03-19 to 2026-03-28)

## Recent Updates

### Session Update: Combat System Design Plan (2026-07-28)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `plans/combat-system-plan.md` — ~86 KB, 1291 lines, 13 sections.

**What was done:**
- Wrote the authoritative combat system design plan per Wayne's 5 combat directives (D-COMBAT-1 through D-COMBAT-5)
- Synthesized research from 5 combat systems (Dwarf Fortress, MTG, MUD tradition, competitive games, board games)
- Defined body zone system: 4–6 zones, unified with armor slots, `body_tree` metadata format
- Designed MTG-inspired 6-phase combat exchange FSM (engine-driven, not player-operated)
- Specified material-based damage resolution: weapon material × force vs. armor + tissue layers
- Integrated with existing injury system (7 injury types + new stress type)
- Defined creature combat metadata format with complete rat, wolf, spider examples
- Designed player combat interface: verbs, 2-hand constraint, darkness rules, flee mechanics
- Specified NPC-vs-NPC combat: unified combatant interface, predator-prey triggers
- Designed disease delivery: rabies, lycanthropy, spider venom via `on_hit` mechanism
- Created 4-phase implementation roadmap with agent assignments
- Identified 8 open questions for Wayne's decision

**Key Design Decisions:**
- Steel cuts flesh. Always. Material physics, not abstract stats (Principle 9 applied to combat)
- One `resolve_exchange()` function for ALL combat — player, NPC, creature-vs-creature (Principle 8)
- Deterministic core with bounded variance (zone selection random, damage deterministic)
- Combat narration generated from structured results, never scripted per-creature
- `body_tree` required on ALL creatures from Phase 1 (overrides NPC plan's Phase 4 deferral)
- Stress injury type (shaken → panicked → shell-shocked) for psychological combat consequences
- Disease delivery via generic `on_hit` field on natural weapons

**Decision filed:** `.squad/decisions/inbox/cbg-combat-plan.md`

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

## Learnings

### 2026-07-27: Door/Portal/Exit Architecture — Game Design Analysis
**Status:** ✅ ANALYSIS COMPLETE

**Deliverable:** `plans/door-design-analysis.md` — ~40 KB comprehensive game design analysis

**What was done:**
- Analyzed 40+ years of IF genre precedent (Zork/ZIL, Inform 6/7, TADS 3, Hugo, Adventuron)
- Evaluated 10 door/portal scenarios under both exit-construct and door-object approaches
- Compared player experience, designer ergonomics, and creative constraints
- Recommended doors-as-first-class-objects with thin exit references in room files
- Identified migration path: 4 phases from current hybrid to clean door-object architecture

**Key Findings:**
- Genre precedent overwhelmingly favors doors-as-objects (Zork, Inform 6/7, Hugo all use this model)
- TADS 3 is the cautionary tale — treating doors as exit-constructs is its most criticized design decision
- Door-objects won all 10 scenario comparisons; exit-constructs couldn't implement 3 scenarios at all (talking doors, remote levers, timed drawbridges)
- Sensory system requires doors to be objects — the game starts at 2 AM in darkness, players FEEL doors
- Exit-constructs violate Principles 1, 3, 4, 6, 7, 8, 9, and D-14 (Prime Directive)
- Current codebase already has both systems coexisting awkwardly (bedroom-door.lua + inline exit definitions)
- Template inheritance for door-objects produces LESS boilerplate than current 150+ line inline exit definitions

**Affects:**
- Bart (Architect): Engine movement handler, exit table schema, door-object source-of-truth pattern
- Flanders (Object Designer): Door template creation, door object definitions
- Moe (World Builder): Room file simplification — thin exit references instead of inline door logic
- Smithers (Parser/UI): Verb dispatch to door objects instead of exit mutation tables
- Nelson (QA): Door interaction regression tests during migration

**Decision filed:** `.squad/decisions/inbox/cbg-door-design.md`

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

### Session Update: Unconsciousness Trigger Objects Design (2026-07-26)
**Status:** ✅ DESIGN COMPLETE
**Issue:** #162

**Deliverable:** `docs/design/injuries/unconsciousness-triggers.md` — comprehensive design spec for 4 unconsciousness trigger objects.

**What was done:**
- Designed 4 trigger objects that cause unconsciousness through environmental gameplay:
  1. **Falling Rock Trap** (`falling-rock-trap`) — tripwire + boulder, severe severity, 10–15 turn KO, one-shot permanent, can be disarmed by cutting wire
  2. **Ceiling Collapse** (`unstable-ceiling`) — area hazard triggered by noise/vibration, severe severity, 12–18 turn KO, inflicts BOTH concussion + crushing-wound (most dangerous trigger, 25 HP initial + 2/turn bleed during KO), permanent room mutation
  3. **Poison Gas Vent** (`poison-gas-vent`) — chemical sedation, minor severity, 3–5 turn KO, RESETS after wake-up (can KO repeatedly), creates room-escape puzzle, can be plugged with cloth
  4. **Enemy Blow** (`falling-club-trap`) — spring-loaded club (V1 has no NPCs per Principle 0, so mechanical trap simulates combat strike), moderate severity, 6–10 turn KO, one-shot, can be disarmed
- All 4 triggers use the existing `concussion` injury type — no new injury definitions needed
- Full identity, sensory descriptions (on_feel, on_smell, on_listen, on_taste), FSM states with transitions, trigger conditions, self-infliction command tables, narration (trigger text, unconscious text, wake-up text), room/level placement suggestions, mutations
- Injury stacking rules with worked numerical examples (bleeding + rock KO, crushing + concussion from ceiling, nightshade + gas KO)
- Command rejection during unconsciousness: source-specific narration pools (not a single static message), varies by KO cause (impact vs sedation vs combat)
- Critical edge case documented: self-inflicted KO + external bleeding = player CAN die (self-infliction ceiling doesn't protect against external injuries ticking)
- Future multiplayer hooks noted: drag/carry/rob/wake unconscious players (design only, not implemented)
- Per-team-member task breakdown for Flanders (object .lua files), Bart (engine verification), Nelson (TDD), Smithers (parser routing + rejection UI), Sideshow Bob (puzzle integration)

**Key Design Decisions:**
- All 4 triggers inflict the existing `concussion` injury — unified, no proliferation of injury types
- Poison gas is the ONLY resettable trigger (creates distinct puzzle dynamic vs one-shot traps)
- Ceiling collapse is intentionally lethal-tier (25 HP initial + bleed during long KO) — players who ignore warning signs face real consequences
- Enemy blow implemented as mechanical trap for V1 (Principle 0 compliance); real NPC strikes use same concussion injury when NPCs arrive
- Self-infliction commands defined per trigger (e.g., "breathe gas", "pull wire", "step on plate") — parser must route these correctly
- `smell gas` is a WARNING (sensory verb), `breathe gas` is a TRIGGER (self-infliction) — important distinction for Smithers
- Meta-commands (`save`, `quit`) must bypass consciousness gate

**Decision filed:** `.squad/decisions/inbox/comic-book-guy-unconsciousness.md`
