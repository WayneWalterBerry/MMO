# Design Requirements & Directives

**Version:** 1.0  
**Last Updated:** 2026-03-21  
**Author:** Brockman (Documentation)  
**Purpose:** Consolidated reference of all design directives from Wayne and team decisions.

---

## System: Object & Lifecycle

### REQ-001: Objects Own Their Metadata
- **Directive:** Objects declare their own properties (name, description, size, weight, capabilities)
- **Source:** D-22 (Object Inheritance / Template System)
- **Status:** ✅ Implemented
- **Details:** Objects use `template` inheritance; instance properties override base class. No external metadata registry.
- **Related Docs:** `fsm-object-lifecycle.md`, `composite-objects.md`

### REQ-002: Finite State Machine (FSM) Inline
- **Directive:** Each object manages its own state transitions via built-in FSM (match: unlit → lit → spent; nightstand: closed ↔ open)
- **Source:** D-7, D-14 (FSM Object Lifecycle System Design)
- **Status:** ✅ Designed, ⏳ partially implemented
- **Details:** One logical object per FSM. State transitions are event-driven (1 tick = 1 player command). Terminal states prevent impossible actions.
- **Related Docs:** `fsm-object-lifecycle.md`

### REQ-003: Composite Objects with Detachable Parts
- **Directive:** Objects can have sub-objects (parts) that sometimes detach, becoming independent objects
- **Source:** D-2 (Composite & Detachable Object System)
- **Status:** ✅ Designed, ⏳ partially implemented
- **Details:** Single-file architecture; parts detach via factory functions. Parent transitions to `{base_state}_without_PART`. Reversibility is design-time choice.
- **Related Docs:** `composite-objects.md`, `fsm-object-lifecycle.md`

### REQ-004: Code Mutation Model (True Rewrite)
- **Directive:** When object state changes, the object's code is literally rewritten. Old definition replaced by new one. Code IS state.
- **Source:** D-14 (Mutation Model: True Code Rewrite), D-8.2 (Code Mutation Over State Flags)
- **Status:** ✅ Designed, ⏳ partially implemented
- **Details:** Mutation variants stored as dormant strings; verb triggers full code swap. No separate state flags. Uses immutable baseline + mutable overlay pattern.
- **Related Docs:** `fsm-object-lifecycle.md`, `architecture-decisions.md`

### REQ-005: Type System with IS-A Inheritance
- **Directive:** Objects inherit from base types via `type_id` (chamber-pot IS-A pot). Base class behavior flows down unless overridden.
- **Source:** D-22 (Object Inheritance / Template System)
- **Status:** ✅ Implemented
- **Details:** Templates are single-level (sheet, furniture, container, small-item). Deep inheritance avoided to prevent debugging nightmares.
- **Related Docs:** `composite-objects.md`

---

## System: Wearable & Clothing

### REQ-006: Wearable Slot System
- **Directive:** Objects can be worn on specific body parts (head, hands, torso, feet, etc.). Each worn item occupies one slot.
- **Source:** D-33 (Player Skills System), general design
- **Status:** ✅ Designed
- **Details:** Player has finite worn slots. Conflicts detected when trying to wear items to occupied slots. Wearables affect vision/sensory state.
- **Related Docs:** `wearable-system.md`, `player-skills.md`

### REQ-007: Wearable Layers & Conflicts
- **Directive:** Some wearables conflict with each other (can't wear both hat and helmet). System enforces wear_layer and slot constraints.
- **Source:** General design, `wearable-system.md`
- **Status:** ✅ Designed
- **Details:** Each wearable declares its wear_slot and optional wear_layer. Layer conflicts prevent simultaneous wear.
- **Related Docs:** `wearable-system.md`

### REQ-008: Vision Blocking via Wearables
- **Directive:** Wearing certain items (sack, blindfold) blocks vision entirely. Sensory verbs still work but LOOK fails.
- **Source:** Brockman's research (wearables as sensory modifiers)
- **Status:** ✅ Implemented
- **Details:** Vision state checked in LOOK verb. Blindness becomes a puzzle, not a dead end. FEEL/SMELL/LISTEN unaffected.
- **Related Docs:** `wearable-system.md`, `verb-system.md`

### REQ-009: Container as Wearable (e.g., Backpack)
- **Directive:** Some wearables are containers (backpack, sack). Can wear AND store items simultaneously.
- **Source:** General design
- **Status:** ✅ Designed
- **Details:** Backpack is both worn and has `contents`. Worn containers contribute to inventory weight calculation.
- **Related Docs:** `wearable-system.md`, `containment-constraints.md`

---

## System: Spatial & Room Design

### REQ-010: Spatial Relationships (ON/UNDER/BEHIND/COVERING)
- **Directive:** Objects exist in spatial layers: ON top of something, UNDER something, BEHIND something, COVERING something.
- **Source:** D-4 (Room layout and movable furniture)
- **Status:** ✅ Designed, ⏳ partially implemented
- **Details:** Bed ON rug; rug COVERS trap door. Multi-surface containment model in engine. Each zone has own capacity and accessibility.
- **Related Docs:** `containment-constraints.md`, `dynamic-room-descriptions.md`

### REQ-011: Movable Furniture
- **Directive:** Players can move furniture (PUSH bed, PULL rug). Movement reveals hidden objects beneath.
- **Source:** D-4 (Room layout and movable furniture)
- **Status:** ✅ Designed
- **Details:** Movable furniture has `stackable = true`. Players move via verb handlers (PUSH/PULL/MOVE). Removal chain: move rug → reveal trap door.
- **Related Docs:** `dynamic-room-descriptions.md`, `room-exits.md`

### REQ-012: Hidden Objects & Discovery Mechanic
- **Directive:** Objects can be hidden under/behind other objects. Moving top object reveals hidden item (discovery puzzle).
- **Source:** D-4 (Room layout and movable furniture)
- **Status:** ✅ Designed
- **Details:** Trap door hidden under rug. `on_look` function hints without revealing. Separate verbs (LOOK UNDER) expose.
- **Related Docs:** `dynamic-room-descriptions.md`, `composite-objects.md`

### REQ-013: Stacking Rules & Weight Capacity
- **Directive:** Some objects stackable, some not. Weight limits enforced per surface. Objects declare `stackable` and `weight_capacity`.
- **Source:** D-4 (Room layout and movable furniture)
- **Status:** ✅ Implemented (engine layer)
- **Details:** Containers have `weight_capacity`. Items have `weight`. Verb handlers check limits before placing items.
- **Related Docs:** `containment-constraints.md`, `composite-objects.md`

---

## System: Container & Inventory

### REQ-014: Containment Hierarchy (Parent-Child Tree)
- **Directive:** All objects modeled as parent-child tree. Rooms contain furniture; furniture contains items.
- **Source:** D-3 (Text Adventure Containment Architecture)
- **Status:** ✅ Implemented
- **Details:** Each object has `.location` (parent) and `.contents` (children list). Prevents circular containment, enforces weight/size limits.
- **Related Docs:** `containment-constraints.md`, `architecture-decisions.md`

### REQ-015: Surfaces with Multiple Zones
- **Directive:** Objects can define multiple containment zones (bed: top + underneath; nightstand: top + inside; vanity: top + inside + mirror_shelf).
- **Source:** D-22 (Object Inheritance / Template System), D-24 (Bedroom Design Patterns)
- **Status:** ✅ Implemented
- **Details:** `surfaces = { top = {...}, inside = {...} }` structure. Each zone has own capacity, max_item_size, weight_capacity, accessibility.
- **Related Docs:** `composite-objects.md`, `containment-constraints.md`

### REQ-016: Container Accessibility
- **Directive:** Some containers are accessible (open drawer), others not (closed drawer). Accessibility gates whether items can be retrieved.
- **Source:** General design
- **Status:** ✅ Implemented
- **Details:** Containers use `accessible` flag. Locked/closed containers still have contents (not destroyed), just unretrievable.
- **Related Docs:** `containment-constraints.md`

### REQ-017: Player Two-Handed Carry
- **Directive:** Player has 2 hand slots. Objects declare `hands_required` (0/1/2). Can't carry more objects than hands allow.
- **Source:** D-2 (Composite & Detachable Object System)
- **Status:** ✅ Implemented
- **Details:** Heavy items require 2 hands. Worn items don't count toward hand slots. Inventory shows hands + worn + bags.
- **Related Docs:** `player-skills.md`, `composite-objects.md`

---

## System: Consumable & Temporal

### REQ-018: Match Consumable (3 Turns / 30 Ticks)
- **Directive:** Match lights (3 turns, 30 ticks). After that, it's spent (terminal state).
- **Source:** D-7 (FSM Object Lifecycle System Design)
- **Status:** ✅ Designed
- **Details:** Event-driven duration. Warning at 5 ticks. Ticks happen BEFORE verb execution (fair resource consumption).
- **Related Docs:** `fsm-object-lifecycle.md`, `game-design-foundations.md`

### REQ-019: Candle Consumable (100 Ticks, Then Stub 20, Then Spent)
- **Directive:** Candle burns (100 ticks) → stub state (20 ticks) → spent. Multi-phase terminal progression.
- **Source:** D-7 (FSM Object Lifecycle System Design)
- **Status:** ✅ Designed
- **Details:** Warning thresholds tunable. Stub state still provides light but urgently. Spent state terminal (no recycling).
- **Related Docs:** `fsm-object-lifecycle.md`

### REQ-020: Poison Kills (Immediate Death)
- **Directive:** Poison has lethal consequence. `on_taste_effect = "poison"` → immediate game over.
- **Source:** D-26 (Light and Time Systems), game design
- **Status:** ✅ Implemented
- **Details:** Triggers `ctx.game_over = true` in loop. Game over state with "Play again?" prompt.
- **Related Docs:** `fsm-object-lifecycle.md`, `architecture-decisions.md`

### REQ-021: Game Clock (24x Real Time)
- **Directive:** Game has internal clock. 1 real-time hour = 1 full in-game day (24x speed).
- **Source:** D-26 (Light and Time Systems)
- **Status:** ✅ Implemented
- **Details:** Uses `os.time()` delta × 24. Always accurate, even between commands. No tick-based advancement.
- **Related Docs:** `fsm-object-lifecycle.md`

---

## System: Parser & Commands

### REQ-022: Tier 1 Parser (Exact Verb Dispatch)
- **Directive:** Tier 1 is fast exact matching of commands to verbs. If input exactly matches a verb or alias, use it immediately.
- **Source:** D-6 (Tier 2 Parser Wiring)
- **Status:** ✅ Implemented
- **Details:** Dictionary lookup for canonical verbs and aliases. No LLM tokens. Fast path for common commands.
- **Related Docs:** `verb-system.md`, `command-variation-matrix.md`

### REQ-023: Tier 2 Parser (Jaccard Phrase Matching)
- **Directive:** Tier 2 uses phrase-text similarity (Jaccard token overlap). No vector embeddings. Match score ≥ 0.40 for acceptance.
- **Source:** D-6 (Tier 2 Parser Wiring)
- **Status:** ✅ Implemented (Lua REPL; vector version future)
- **Details:** Loads embedding index as phrase dictionary. Scores phrase against index. Threshold tunable via `parser.THRESHOLD`.
- **Related Docs:** `command-variation-matrix.md`

### REQ-024: No Fallback Past Tier 2
- **Directive:** If Tier 2 misses (score ≤ 0.40), the command fails visibly with diagnostic output. No fallback to Tier 3.
- **Source:** D-4 (Cross-Agent Directive: No Fallback Past Tier 2)
- **Status:** ✅ Implemented
- **Details:** Diagnostic mode on by default during playtesting (`--debug` CLI flag). Enables empirical QA.
- **Related Docs:** `verb-system.md`

### REQ-025: Typo Correction (Jaccard Similarity)
- **Directive:** Parser tolerates minor typos via Jaccard token overlap. "lgiht" might match "light" via fuzzy phrase matching.
- **Source:** General design
- **Status:** ✅ Designed (via Tier 2 phrase matching)
- **Details:** Phrase-level tolerance better than character-level. Full embedding similarity available in browser (future).
- **Related Docs:** `command-variation-matrix.md`

### REQ-026: Compound Commands (Tool + Surface Verbs)
- **Directive:** Some verbs chain two tools: STRIKE match ON matchbox, WRITE ON paper WITH pen. Engine dispatches compound tool verbs.
- **Source:** D-25 (Tool Object Convention)
- **Status:** ✅ Implemented
- **Details:** Verb handlers receive target + tool from parser. Compound tool resolution verifies both items present in inventory.
- **Related Docs:** `tool-objects.md`, `verb-system.md`

---

## System: Player & Skills

### REQ-027: Player Skills (Binary, Discovery-Based)
- **Directive:** Player learns skills through gameplay (find manual, practice, NPC teaching, puzzle solve). Binary: have skill or don't.
- **Source:** D-33 (Player Skills System)
- **Status:** ✅ Designed, ⏳ partially implemented
- **Details:** Skills gate verb+tool combinations. Without lockpicking, pin is just a pin. WITH lockpicking, pin → lock pick tool.
- **Related Docs:** `player-skills.md`, `composite-objects.md`

### REQ-028: Skill Gates on Verbs
- **Directive:** Some verbs (PICK_LOCK, SEW, WRITE) require a prerequisite skill. Engine checks skill before allowing mutation.
- **Source:** D-33 (Player Skills System)
- **Status:** ✅ Designed
- **Details:** Verb handler checks `player.skills[required_skill]` before proceeding. Graceful fail message if skill missing.
- **Related Docs:** `player-skills.md`, `verb-system.md`

### REQ-029: Consumable Failure States (Poison, Injury)
- **Directive:** Some verbs can fail in dangerous ways. TASTE poison → death. PRICK with needle → blood source.
- **Source:** D-32 (Blood as Writing Instrument), D-33 (Player Skills System)
- **Status:** ✅ Designed
- **Details:** Objects can declare `on_taste_effect = "poison"` or provide `injury_source` capability.
- **Related Docs:** `player-skills.md`, `tool-objects.md`

### REQ-030: Sewing as Crafting Skill
- **Directive:** Player with sewing skill + needle (tool) can transform cloth into wearable items. Cloth becomes raw material when skill unlocked.
- **Source:** D-36 (Sewing as Crafting Skill)
- **Status:** ✅ Designed
- **Details:** Needle provides `sewing_tool` capability. SEW verb requires skill gate + tool. Mutates cloth → garment.
- **Related Docs:** `player-skills.md`, `composite-objects.md`

---

## System: Light & Darkness

### REQ-031: Game Starts in Darkness
- **Directive:** Player wakes at 2 AM in complete darkness. No light by default. Must find/light a fire source.
- **Source:** D-26 (Light and Time Systems), game start time decision
- **Status:** ✅ Implemented
- **Details:** Darkness at start forces candle puzzle. Sensory verbs (FEEL, SMELL, LISTEN) work in dark. LOOK fails in dark.
- **Related Docs:** `fsm-object-lifecycle.md`, `dynamic-room-descriptions.md`

### REQ-032: Light Sources Emit Light
- **Directive:** Objects with `casts_light = true` (lit candle, torch) illuminate room. LOOK only works in lit room or with EXAMINE/sensory verbs.
- **Source:** D-26 (Light and Time Systems)
- **Status:** ✅ Implemented
- **Details:** Light property checked in verb layer. Easy to extend (add more light sources, color-coded light, etc.).
- **Related Docs:** `fsm-object-lifecycle.md`, `verb-system.md`

### REQ-033: Daylight Through Windows
- **Directive:** Outside areas during daytime (6 AM to 6 PM) have natural light via `allows_daylight = true`. Inside areas need fire source OR window to daylight.
- **Source:** D-26 (Light and Time Systems)
- **Status:** ✅ Designed, ⏳ partially implemented
- **Details:** Curtains can be opened (allows_daylight) or closed (blocks daylight). Window position affects light propagation.
- **Related Docs:** `dynamic-room-descriptions.md`, `composite-objects.md`

---

## System: Death & Game Over

### REQ-034: Game Over on Poison
- **Directive:** Poison drink → immediate death. Sets `ctx.game_over = true`. Game loop breaks, shows "Play again?" prompt.
- **Source:** D-26 (Light and Time Systems)
- **Status:** ✅ Implemented
- **Details:** Extensible for future death causes (fall damage, starvation, etc.). Currently only poison triggers death.
- **Related Docs:** `fsm-object-lifecycle.md`, `architecture-decisions.md`

### REQ-035: Play Again Prompt
- **Directive:** On game over, display "Play again? (y/n)" and exit game if user chooses no. If yes, restart with fresh universe.
- **Source:** General design
- **Status:** ✅ Designed
- **Details:** Implementation detail for game loop. Restart clears universe state, reloads fresh templates.
- **Related Docs:** `architecture-decisions.md`

---

## System: Newspaper & Communication

### REQ-036: Newspaper Editions in Separate Files
- **Directive:** Each newspaper edition (morning, evening, late evening) lives in separate `.md` file, not all in one file.
- **Source:** D-3 (User Directive: Newspaper editions in separate files)
- **Status:** ✅ Implemented
- **Details:** Format: `YYYY-MM-DD-{edition}.md` (e.g., `2026-03-20-morning.md`). Each edition is independent, readable artifact.
- **Related Docs:** (newspaper folder)

### REQ-037: Newspaper Comic & Op-Ed (Recurring Sections)
- **Directive:** Every newspaper edition includes comic strip and op-ed piece. These are recurring sections, not one-offs.
- **Source:** D-28 (Newspaper Format)
- **Status:** ✅ Implemented
- **Details:** Comic strip provides team humor + storytelling. Op-ed captures design insights. High reader retention.
- **Related Docs:** (newspaper folder)

---

## System: Testing & Validation

### REQ-038: Nelson Uses LLM Smarts
- **Directive:** QA testing (Nelson) uses LLM intelligence to explore game state, not scripted test cases. Streams output, finds edge cases empirically.
- **Source:** General design philosophy
- **Status:** ✅ Active
- **Details:** Nelson plays game as human would, reports bugs naturally. Different from traditional UI automation.
- **Related Docs:** (external to docs/)

### REQ-039: No Scripts (LLM-Driven Testing)
- **Directive:** QA doesn't write test scripts. LLM-driven play testing is primary validation method.
- **Source:** General design philosophy
- **Status:** ✅ Active
- **Details:** Enables rapid bug discovery without maintenance overhead. Streaming output provides real-time feedback.
- **Related Docs:** (external to docs/)

---

## System: Paper & Writing

### REQ-040: Sheet of Paper Object
- **Directive:** Game includes paper object. Words can be written on it.
- **Source:** D-30 (Paper and Writing System)
- **Status:** ✅ Designed, ⏳ partially implemented
- **Details:** `paper.lua` object defined. Can be examined and written on.
- **Related Docs:** `composite-objects.md`, `tool-objects.md`

### REQ-041: WRITE Verb (Requires Writing Instrument)
- **Directive:** WRITE ON paper WITH pen/pencil/blood. Writing requires tool (pen, pencil, or blood source).
- **Source:** D-30 (Paper and Writing System)
- **Status:** ✅ Designed
- **Details:** `requires_tool = "writing_instrument"`. Pen, pencil, blood all provide this capability.
- **Related Docs:** `tool-objects.md`, `verb-system.md`

### REQ-042: Paper Mutation on Writing
- **Directive:** When text written on paper, paper object mutates to `paper-with-writing`. Code rewrite includes written text in description.
- **Source:** D-31 (Paper Mutation on Writing)
- **Status:** ✅ Designed
- **Details:** Engine generates variant file `paper-with-{content}` or directly mutates paper object. Text becomes permanent part of paper's definition.
- **Related Docs:** `fsm-object-lifecycle.md`, `composite-objects.md`

### REQ-043: Blood as Writing Instrument
- **Directive:** Player can cut/prick self with knife/pin to draw blood. Blood is writing instrument. Creates tool chain: knife/pin → blood → write.
- **Source:** D-32 (Blood as Writing Instrument)
- **Status:** ✅ Designed
- **Details:** Knife/pin provide `injury_source` capability. Using them triggers blood state. Player must actively choose to injure self. Dark, consequential.
- **Related Docs:** `player-skills.md`, `tool-objects.md`

---

## System: Tools & Capabilities

### REQ-044: Tool Convention (requires_tool / provides_tool)
- **Directive:** Objects declare capabilities via `provides_tool = "capability"`. Verbs declare requirements via `requires_tool = "capability"`.
- **Source:** D-25 (Tool Object Convention)
- **Status:** ✅ Implemented
- **Details:** Capability matching, not item-ID matching. Enables extensibility (multiple tools provide same capability). Used throughout verb system.
- **Related Docs:** `tool-objects.md`, `verb-system.md`

### REQ-045: Fire Source Capability
- **Directive:** Objects that can light fires (match-lit, torch, candle-lit) provide `fire_source` capability. LIGHT verb requires it.
- **Source:** D-29 (Fire Source for Lighting), D-25 (Tool Object Convention)
- **Status:** ✅ Implemented
- **Details:** First implementation: matchbox (3 charges) provides `fire_source`. Depletes to `matchbox-empty`.
- **Related Docs:** `tool-objects.md`, `fsm-object-lifecycle.md`

### REQ-046: Sharp Tool Capability
- **Directive:** Objects that cut (knife, glass shard, needle) provide `sharp_tool` capability. CUT verb requires it.
- **Source:** General design
- **Status:** ✅ Designed
- **Details:** Enables multiple sharp tool implementations. Integrates with craft system.
- **Related Docs:** `tool-objects.md`, `player-skills.md`

### REQ-047: Writing Instrument Capability
- **Directive:** Objects that write (pen, pencil, blood) provide `writing_instrument` capability. WRITE verb requires it.
- **Source:** D-30, D-41 (Paper and Writing System)
- **Status:** ✅ Designed
- **Details:** Enables extensibility (pencil, charcoal, blood all provide same capability). Different sensory qualities.
- **Related Docs:** `tool-objects.md`, `player-skills.md`

### REQ-048: Sewing Tool Capability
- **Directive:** Needle provides `sewing_tool` capability. SEW verb requires it + sewing skill.
- **Source:** D-36 (Sewing as Crafting Skill)
- **Status:** ✅ Designed
- **Details:** Skill gate + tool gate = double-gated verb. Prevents crafting without training.
- **Related Docs:** `tool-objects.md`, `player-skills.md`

---

## Implementation Status Summary

| Category | Designed | Implemented | Tested | Status |
|----------|----------|-------------|--------|--------|
| Object FSM | ✅ | ⏳ | ⏳ | Phase 2 |
| Wearables | ✅ | ⏳ | ⏳ | Phase 2 |
| Spatial | ✅ | ⏳ | ⏳ | Phase 2 |
| Containers | ✅ | ✅ | ✅ | Ready |
| Consumables | ✅ | ✅ | ⏳ | Phase 2 |
| Parser | ✅ | ✅ | ✅ | Ready |
| Skills | ✅ | ⏳ | ⏳ | Phase 2 |
| Light/Dark | ✅ | ✅ | ⏳ | Phase 2 |
| Death/Game Over | ✅ | ✅ | ✅ | Ready |
| Newspaper | ✅ | ✅ | ✅ | Ready |
| Paper/Writing | ✅ | ⏳ | ⏳ | Phase 2 |
| Tools/Capabilities | ✅ | ✅ | ✅ | Ready |

---

## Cross-References

- **Object Lifecycle:** See `fsm-object-lifecycle.md`
- **Wearable Details:** See `wearable-system.md`
- **Container Model:** See `containment-constraints.md`
- **Room Design:** See `dynamic-room-descriptions.md`
- **Verb Reference:** See `verb-system.md`
- **Architectural Decisions:** See `architecture-decisions.md` and `.squad/decisions.md`
- **Command Variations:** See `command-variation-matrix.md`
- **Tool Patterns:** See `tool-objects.md`
- **Skills Design:** See `player-skills.md`

