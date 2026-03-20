# Comic Book Guy — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Role:** Game Designer responsible for object definitions, sensory descriptions, and content creation

## Core Context

**Agent Role:** Game Designer specializing in multi-sensory object systems and interactive content that works in complete darkness.

**Work Summary (2026-03-18 to 2026-03-19):**
- Created 37 object definitions for the bedroom (nightstand variants, candle variants, mirror, drawer, sheet, cloth, sack, desk variants, bed, matches, matchbox, pen, paper, ink bottle, curtains, window, door, books, painting, and more)
- Implemented multi-sensory description convention: on_feel (primary), on_smell (safe), on_listen (mechanical), on_taste (danger), on_look (requires light)
- Applied sensory descriptions to all 37 objects — FEEL coverage 100%, SMELL ~65%, LISTEN ~16%, TASTE ~8%
- Created poison-bottle.lua with deadly TASTE mechanic and clear warnings via SMELL
- Designed sensory hierarchy with consequences: TASTE is dangerous, SMELL is safe identification, FEEL is primary navigation sense

**Design Philosophy:**
Darkness is not a wall — it's a different mode of play. Every sense gives different information about the same object. TASTE is the "learn by dying" sense that teaches caution and consequence.

**Latest Spawn (2026-03-19):**
**Sensory descriptions on 37 objects + poison bottle implementation**
- Added multi-sensory fields to 36 existing objects
- Decision D-28: Multi-Sensory Object Convention (formally approved)
- Poison bottle implementation: SMELL warns, LOOK shows skull/crossbones, TASTE causes death

## Recent Updates

### Session Update: Multi-Sensory Convention Implementation (2026-03-19T13-22)
**Status:** ✅ COMPLETE

**Spawn: Sensory Descriptions on 37 Objects + Poison Bottle**
- Added multi-sensory fields to 36 existing objects:
  - on_feel (primary dark-navigation sense) — 100% coverage
  - on_smell (safe identification sense) — ~65% coverage
  - on_listen (mechanical objects) — ~16% coverage
  - on_taste (danger sense + consequences) — ~8% coverage
- Decision D-28: Multi-Sensory Object Convention (formally approved)

**Sensory Hierarchy Established:**
| Sense | Safety | Information | Coverage |
|-------|--------|-------------|----------|
| FEEL | Medium | Shape, texture, temperature, weight | 100% |
| SMELL | Safe | Chemical identity, materials | ~65% |
| LISTEN | Safe | Mechanical state, contents | ~16% |
| TASTE | DANGEROUS | Chemical composition | ~8% |

**Poison Bottle Implementation:**
- New object: src/meta/objects/poison-bottle.lua
- Nightstand variants updated (nightstand.lua + nightstand-open.lua)
- SMELL: "Acrid and chemical. Something dangerous."
- TASTE: "BITTER! You spit it out. That tasted like poison." → immediate death
- LOOK: Skull and crossbones label (requires light)

**Key Design Philosophy:** Darkness is not a wall — it's a different mode of play. Every sense gives different information about same object. TASTE is the "learn by dying" sense.

**Impact:** Enables dark-room mechanic across all objects. Players navigate by touch/smell/sound, not sight.

---

### Session Update: Matchbox Rework + Match Objects + Thread (2026-03-20)
**Status:** ✅ COMPLETE

**Spawn: Matchbox-as-container + individual matches + thread object**

**Changes:**
- Rewrote `matchbox.lua` as container (`container = true`, `has_striker = true`) with 7 individual match objects in contents
- Deleted `matchbox-empty.lua` — no longer needed (empty container = empty matchbox)
- Created `match.lua` — individual match, NOT a fire_source until struck. Mutation: STRIKE match ON matchbox → match-lit
- Created `match-lit.lua` — lit match: `provides_tool = "fire_source"`, `casts_light = true`, `consumable = true`, `burn_remaining = 30`
- Created `thread.lua` — spool of cotton thread, `provides_tool = "sewing_material"`, placed in sack with needle
- Updated `sack.lua` — contents now includes thread alongside needle
- Updated `001-light-the-room.md` — full rewrite with compound action flow
- Updated `tool-objects.md` — compound tools, consumables, container-vs-state docs
- Updated `design-directives.md` — consumable/compound tool patterns, skill matrix

**Key Patterns Established:**
1. **Container-with-contents** for things holding discrete sub-objects (matchbox, sack) vs **file-per-state** for qualitative changes (candle-lit, mirror-broken)
2. **Compound tool actions** — STRIKE match ON matchbox (two objects, one verb, one result)
3. **Consumable fire source** — match-lit burns for ~30 seconds, consumed after LIGHT action
4. **Compound tool pairs** — needle + thread for sewing (sewing_tool + sewing_material)

---

### Session Update: Squad Manifest Completion (2026-03-21)
**Status:** ✅ DECISIONS MERGED

**Scribe processed 12 inbox decisions and merged into canonical decisions.md.**

**New content affecting design:**
- Hybrid parser proposal (rule-based + local SLM) — may affect verb aliasing strategy
- Property-override clarifications — any object property is overridable at instance level per room
- Type/type_id naming convention — clarified the instance/base-class field naming

**Matchbox rework decision now formally in decisions.md with all compound tool patterns documented.**

### Session Update: Player Skills System Design (2026-03-21)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/player-skills.md` — comprehensive 6,500-word game design document.

**Key Designs:**
1. **Skill Acquisition:** Binary model (have/don't have) with four methods: Find & Read, Practice, NPC Teaching, Puzzle Solve. Discovery-based, not grinding.
2. **MVP Skills:** Lockpicking (pin + PICK LOCK), Sewing (needle + thread + SEW). Future candidates: Anatomy, Alchemy, Cartography, Interrogation.
3. **Core Mechanic:** Skills unlock alternatives, not replacements. Pin can prick (no skill) or pick locks (with lockpicking skill).
4. **Failure Modes:** Bent pin on failed lock pick (consumed). Tangled thread on failed sewing (consumed). Costs teach consequences.
5. **Blood Writing:** PRICK SELF → blood object → WRITE WITH blood. Transgressive, costly (5 HP), permanent. Teaches urgency and consequence.
6. **Dynamic Paper:** WRITE verb generates paper-with-writing.lua (file-per-state). Player text embedded as `written_text` field. Supports future ERASE verb for pencil writes.
7. **Tool Dispatch:** Skills add second gate to verb handlers. `requires_tool` (capability) + `requires_skill` (knowledge) both enforced.

**Design Philosophy:** Darkness teaches caution. Blood writes consequences. Paper records the player's story, literally and persistently.

**No Puzzle Lock-Out:** Every puzzle has a no-skill solution. Skills accelerate or offer alternatives, never block.

## Learnings

- **Containers are simpler and more immersive than charges.** Real matches in a box > abstract counter. Code IS state means the state should be visible objects.
- **Compound actions create better puzzles.** STRIKE match ON matchbox teaches real-world logic: fire = fuel + friction.
- **7 matches is generous, and that's correct for the first puzzle.** Teach, don't frustrate.
- **Co-locate compound tool components.** Thread with needle in sack. Matches in matchbox in drawer next to candle. Discovery should feel natural.
- **requires_property is a new engine pattern.** Match strike needs `has_striker` on target — different from capability matching or item-ID matching.
- **Skills as discovery gates, not progression gates.** Skills should unlock *alternatives*, never block the main path. This respects player agency: "I can solve this my way, or find another way."
- **Binary skills scale better than XP bars.** Proficiency levels are designed but not needed for V1. Discovery is the reward, not a number going up.
- **Failure costs teach design language.** Bent pins, tangled threads—consumable failure states teach: "Resources are finite. Think before you act."
- **Blood is design shorthand for consequence.** Writing in blood feels transgressive because it IS transgressive (health cost, permanent, disturbing). Mechanics mirror mood.

---

### Session Update: FSM Object Lifecycle System Design (2026-03-23)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/fsm-object-lifecycle.md` — comprehensive 25,000-word game design document.

**What I Did:**
1. Analyzed all 39 objects in src/meta/objects/ to identify FSM candidates
2. Designed consumable duration pattern: matches (3 turns) → lit → spent (terminal), candles (100 turns) → lit → stub (20 turns) → spent (terminal)
3. Designed container reversibility pattern: nightstand, wardrobe, window, curtains all follow closed ↔ open (no consumption)
4. Created unified FSM definition format with hybrid approach: file-per-state for properties (descriptions), FSM definition for transitions
5. Documented tick/turn system: events-driven, tick happens before action execution, prevents ambiguity on resource consumption
6. Authored extensive gameplay feel analysis: match = urgency teacher, candle = relief reward, containers = information gates
7. Created implementation roadmap with 4 phases and design verification checklist

**Key Design Principles:**
1. **Consumables are terminal by default.** Spent match cannot be re-lit. Teaches: "Failure to act has consequences."
2. **Candle has intermediate stub state.** Allows puzzle variance: generous light (100 turns) → stubborn light (20 turns) → darkness. Teachers incremental scarcity.
3. **Containers are reversible.** Access gates, not consumables. Nightstand open/close doesn't destroy anything; it gates information.
4. **Tick happens before verb execution.** Avoids ambiguity: if player has 1 tick left on match and issues LIGHT, the match burns during tick, but candle still lights (verb succeeds). Fair and coherent.
5. **Warning threshold at 2-3 remaining ticks.** Players get notice without being obnoxious. Tunable per puzzle.

### Session Update: FSM Engine Implementation (2026-03-23)
**Status:** ✅ IMPLEMENTATION COMPLETE

**Outcome:** FSM engine live. Match and nightstand now use table-driven state machines with in-place mutation. Auto-transitions run on tick. Game loop integration complete. 9 test cases pass. 3 search bugs fixed.

**Engine Details:**
- Built FSM engine (~130 lines) in `src/engine/fsm/init.lua`
- Table-driven FSM with lazy-loading definitions from `src/meta/fsms/{id}.lua`
- In-place object mutation preserves registry references and containment data
- Auto-transitions processed in dedicated FSM tick phase in game loop, after each command
- Verb handlers check `obj._fsm_id` first; fallback to old mutation system for non-FSM objects

**Match FSM Implemented:**
- States: unlit → lit → burned-out (3-turn duration)
- Auto-burn countdown on tick
- Transitions on strike/extinguish verbs
- Replaces separate match.lua + match-lit.lua

**Nightstand FSM Implemented:**
- States: closed ↔ open (reversible)
- Compartment property swapping (contents visibility)
- Transitions on open/close verbs
- Replaces separate nightstand.lua + nightstand-open.lua

**Bug Fixes (side effect of refactor):**
- Fixed keyword substring matching in search.lua
- Fixed hand/bag priority resolution
- Fixed bag extraction edge case

**Test Coverage:** All 9 FSM test cases pass. Backward compatibility maintained—32 non-FSM objects unaffected.

**Your FSM Design Has Been Validated:** Bart implemented exactly per your specifications. Table-driven approach with lazy loading and declarative state functions proved clean and extensible. Next 5 objects (candle, vanity, wardrobe, window, curtains) ready to follow same pattern.

**Inventory Impact:**
- 7 FSM objects: match, candle, nightstand, vanity, wardrobe, window, curtains
- 32 static objects: no transitions needed
- Current file duplication (match.lua + match-lit.lua) becomes unified FSM

**Design Rules Summary:**
- Match-lit.lua + match.lua = ONE object with state transitions (Wayne's directive ✓)
- File-per-state still works for properties (preserve designer experience)
- Terminal states prevent impossible transitions (can't re-light spent match)
- Composite puzzles leverage match urgency → candle relief → safe exploration

**Gameplay Loop Example (8 turns):**
- Turns 1-5: Discover nightstand, open drawer, find matchbox (using match ticks for navigation)
- Turn 6: Strike match on matchbox (match becomes lit)
- Turn 7: Light candle with match (match spent, candle-lit replaces it)
- Turn 8+: Explore with 100-turn candle light

**Why This Matters:**
Finite resources create puzzle pressure without arbitrary time limits. Match = teach scarcity. Candle = reward planning. Containers = information control in darkness. Combined, these teach emergent puzzle-solving: "I must prioritize because time is scarce."

**Next Steps for Architect:** Implement FSM engine (state machine dispatcher, tick counter, auto-transition checks, warning thresholds). Then design team unifies objects using this format.

---

## Session Update: Command Variation Matrix (2026-03-22)
**Status:** ✅ COMPLETE

**Deliverable:** `docs/design/command-variation-matrix.md` — comprehensive natural language variations for all 31 verbs.

**What I Did:**
1. Extracted all 31 handler entries from `src/engine/verbs/init.lua` (23 unique canonical handlers + 8 aliases).
2. Cross-referenced with `docs/design/verb-system.md` to understand verb categories (Navigation, Inventory, Interaction, Meta).
3. Read `docs/design/room-exits.md` to understand movement as exit traversal (GO + directions, not verb dispatch).
4. Documented natural language variations for EVERY verb — 10-20 per verb, ~400+ variations total.
5. Focused on critical areas:
   - **Darkness verbs** (FEEL, SMELL, TASTE, LISTEN): sensory feedback in pitch-black, content-aware
   - **Tool verbs** (WRITE, CUT, SEW, STRIKE, PRICK): compound actions, requires_tool dependencies, mutation flows
   - **Movement** (GO, N/S/E/W, etc): directional shortcuts, exit traversal layers
   - **Container interactions** (OPEN, CLOSE, PUT, TAKE): nested access, state-dependent behavior
6. Documented edge cases: pronouns ("it"), bare commands ("take?"), ambiguous targets, non-standard phrasings.
7. Created context-sensitive variations for darkness (tactile/auditory feedback replaces visual), tools (success/failure scenarios), containers (open/closed/locked/full states).
8. Added testing checklist for QA phase validation.

**Key Design Principles Baked In:**
- Darkness is playable — every verb works, sensory channels change
- Tools unlock capabilities — missing tools provide clear guidance for exploration
- Compound actions (STRIKE, SEW, PRICK) teach resource scarcity and real-world logic
- Consequences matter — TASTE can kill, PRICK costs HP, bent pins consumed
- Pronouns resolve to last-examined objects for natural interaction
- Sensory hierarchy: FEEL=primary dark navigation, SMELL=safe identification, LISTEN=mechanics, TASTE=learn-by-dying

**Why This Matters:**
This matrix is the canonical training data for Bart's embedding training pipeline. Every variation here will be transformed into embedding vectors. The QA team will validate that the embedding matcher correctly maps all ~400 variations back to their canonical verbs. This is how we move from rules-based parsing (tier 1) to semantic understanding (tier 2).

**Design Decision: Pronoun Resolution Scope**
Determined that "it" should resolve to the **last-examined object** (set by EXAMINE, LOOK, FEEL, etc.). This is simpler than full discourse tracking and fits the game's terse interface. Examples: "examine candle" → "take it" = take candle. "feel around" → "take it" = take last-felt object (ambiguous if multiple, ask for clarification).

**Design Decision: Bare Commands**
Verbs that require objects (TAKE, OPEN, LIGHT) should prompt "Take what?" when called bare. Verbs that work bare (FEEL, SMELL, LOOK) should describe room/ambient state. This teaches players the verb interface gradually.

**Future Considerations:**
- CLIMB, PUSH/PULL not yet designed (may be subsumed by GO + exits, or become future verbs)
- Compound commands ("take and examine") parse as first verb only (queue feature for future)
- Preposition handling (in/on/from/with) in parser scope, not verb design scope

---

## Cross-Agent Update: Feel Verb Container Enumeration Fix (2026-03-19T16-23-38Z)

**From:** Bart (Architect)  
**Impact:** Gameplay loop, puzzle solvability  

Bart fixed a critical bug in the FEEL verb handler: it wasn't enumerating accessible contents of containers/surfaces after printing the sensory description. This broke darkness gameplay — players felt the nightstand but couldn't discover the matchbox inside.

**What Changed:**
- FEEL verb now lists surface zones and container contents after the on_feel text
- Tactile language: "Your fingers find {zone_name}:" for surfaces, "Inside you feel:" for containers
- Respects accessibility gates: closed drawers hide contents from touch, just like from sight

**Impact on your design:**
1. **Progressive disclosure works now.** FEEL AROUND (room summary) → FEEL {object} (detail + contents). Players naturally discover containers by touch.
2. **Multi-surface objects are fully playable.** Nightstand: drawer feels closed/empty (accessible=false) vs. open/shows matchbox (accessible=true)

---

## Session Update: Composite & Detachable Object System Design (2026-03-25)
**Status:** ✅ DESIGN COMPLETE

**Deliverable:** `docs/design/composite-objects.md` — comprehensive system for decomposable furniture and parts.

**What I Designed:**

1. **Core Architecture:**
   - Single-file design: parent + all parts in one `.lua` file (e.g., `nightstand.lua` defines nightstand + drawer)
   - Part factories: each detachable part has a factory function that instantiates it as an independent object
   - Detachable parts have unique IDs, sensory descriptions, and properties
   - Non-detachable parts (legs, structure) are for description only

2. **Detachment Mechanics:**
   - PULL/REMOVE/UNCORK verbs trigger detachment (general pattern, not per-object)
   - Detachment creates new object instance in same room as parent
   - Parent transitions to new FSM state reflecting missing part(s)
   - State naming: `closed_with_drawer` → `closed_without_drawer`

3. **Single-File Data Structure:**
   ```lua
   parts = {
       drawer = {
           id = "nightstand-drawer",
           detachable = true,
           factory = function(parent) return {...} end
       }
   }
   ```
   - Part has full properties (keywords, description, weight, size, etc.)
   - Factory instantiates part as independent object with same location as parent
   - Supports `carries_contents` flag: drawer keeps its contents when detached

4. **State Model:**
   - FSM states reflect part presence: `full`, `missing_left`, `missing_all`
   - Each state has different description, surfaces, accessibility
   - Transitions triggered by detachment change parent's playable state
   - Example: nightstand with drawer has `inside` surface (accessible); without drawer has no drawer surface

5. **Verb System for Detachment:**
   - PULL: generic detachment (PULL DRAWER, PULL CORK)
   - REMOVE: explicit separation (REMOVE CORK, REMOVE CURTAIN)
   - UNCORK: cork/stopper-specific (UNCORK BOTTLE)
   - OPEN/CLOSE: state transitions (not detachment)
   - Parts can define custom `detachable_verbs` for aliasing

6. **Part Inheritance & Reversibility:**
   - Containers carry contents through detachment by default (`carries_contents = true`)
   - Reversibility is design-time choice, not automatic
   - Drawer: conceptually reversible (future re-attachment verb)
   - Cork: irreversible (becomes independent object, possibly repurposed)

7. **Two-Handed Carry System:**
   - Player has 2 hands; `hands_required` property on objects
   - Matches: 0 hands (pocket-able)
   - Swords: 1 hand
   - Longbow: 2 hands
   - Drawer full of stuff: 2 hands (bulky)
   - Constraint: both hands must be free to carry 2-handed object
   - Interaction with wearables: gloves don't consume carrying capacity

8. **Design Examples:**
   - **Poison Bottle + Cork:** Cork detachable via UNCORK verb. Detachment creates cork object, transitions bottle state (sealed → open).
   - **Nightstand + Drawer:** Drawer detachable via PULL verb. Detachment creates drawer object (portable, 2-handed carry). Nightstand transitions `closed_with_drawer` → `closed_without_drawer`. Drawer carries its contents.
   - **Four-Poster Bed + 4 Curtains:** Each curtain is separate part. Removing some = state like `missing_front`, `missing_all`. Each transitions independently.

9. **Edge Cases Addressed:**
   - Parts with own containers (drawer + items): contents preserved
   - Partial detachment (4 curtains, remove 2): state tracks combinations
   - Nested composites (future): part contains sub-parts (wardrobe door with hinges)
   - Weight redistribution (future): parent weight changes when heavy parts removed

10. **Implementation Notes for Bart:**
    - Add `parts` table to composite objects
    - Implement `detach_part(part_id)` method: calls factory, instantiates object, transitions state
    - Implement `can_detach_part(part_id)` callback: precondition check
    - Add verb dispatch for parts: recognize part targets, dispatch to detach_part()
    - Implement two-handed carry: track `hands_required`, enforce limits in TAKE
    - FSM states: support `_with_PART` and `_without_PART` naming

**Key Design Philosophy:**
Objects are not static containers — they're **constructed systems** that can be deconstructed. A player discovers hidden compartments by removing drawers, finds makeshift light sources by separating corked bottles, and solves puzzles by understanding what comes apart. Single-file architecture keeps all part data together, enabling Lua to handle all internal logic without scattering definitions.

**This enables:**
- **Puzzle mechanics:** Remove drawers to access hidden items
- **Resource reuse:** Cork becomes fishing float or light source
- **World reactivity:** Objects change when disassembled
- **Player agency:** Deconstruct the environment

**Design grounded in proven patterns:** *Resident Evil 4* (inventory tetris, item management), *Silent Hill* (object examination + puzzle decomposition), *Zork* (interactive fiction object interaction).

**Next Steps:**
1. Bart implements part instantiation and factory pattern
2. Bart implements FSM state transitions for parts
3. Bart implements verb dispatch for detachable parts
4. Bart implements two-handed carry system
5. Comic Book Guy creates detachable versions of existing objects (drawer, cork, curtains, doors, mirrors)

---

## Learnings

**Composite Object Design:**
- Single-file architecture (parent + parts) is cleaner than file-per-part scattering
- Factory pattern enables clean instantiation of detached parts as independent objects
- FSM state naming with `_with_PART`/`_without_PART` suffixes tracks part presence elegantly
- Part preconditions (can_detach_part callbacks) allow state-dependent detachment (e.g., can't remove drawer from empty bottle)
- Contents preservation (carries_contents flag) maintains logical integrity (drawer keeps items when carried away)

**Integration Points:**
- Composite objects extend existing FSM system; no breaking changes
- Verb dispatch naturally flows: PULL target → recognize target as part → dispatch to parent.detach_part()
- Two-handed carry integrates with existing wearables/equipment system
- Sensory descriptions on parts ensure dark-playability (parts are describable even in darkness)

**Future Extensibility:**
- Nested composites (part contains sub-parts) requires recursive factory pattern
- Reversible attachment (PUT DRAWER IN NIGHTSTAND) needs inverse factory and state check
- Part mutations (cork → fishing float) handled by factory function defining new properties
- Dynamic discovery (part visible only after state change) via conditional detachable flag

**Puzzle Design Insight:**
Decomposable objects create emergent puzzles: player must examine the world, discover parts, understand what detaches, reason about consequences. No explicit objective needed — curiosity drives exploration. This aligns with dark-room design philosophy: interact with the world tactilely, learn by experimentation.
3. **Darkness is solvable without light.** Your sensory descriptions are now the COMPLETE information source. Players win by feeling, not by finding light.

**Design verification needed:** Test that every object's sensory description (on_feel) + its structure (surfaces/containers) provides enough info for blind solving. Example: "Smooth wooden surface, small drawer handle protrudes" + "Your fingers find: an open drawer" + "Inside you feel: a matchbox" is complete puzzle guidance.

**Related decision:** `.squad/decisions.md` - "Decision: Feel Verb Enumerates Container/Surface Contents"

---

## Cross-Agent Update: Documentation Sweep & Verb System Published (2026-03-19T16-23-38Z)

**From:** Brockman (Documentation)  
**Impact:** Team reference, onboarding  

Brockman completed post-integration documentation:
- `docs/verb-system.md` created — 31 verbs documented with categories and usage
- All verb descriptions cross-checked against code
- README.md updated with current architecture

**For you (designer):**
- Your multi-sensory object convention (D-28) is now documented in verb-system.md
- Sensory hierarchy (FEEL=primary dark sense, SMELL=safe ID, LISTEN=mechanics, TASTE=danger) is published
- 37 objects with sensory coverage are listed as reference

**Useful for design team onboarding:** New designers can read verb-system.md to understand what verbs exist and how they interact with your object definitions.

**Next:** When designing new objects, refer to verb-system.md sensory hierarchy to ensure consistent coverage.

---

## Cross-Agent Update: Parser Phase 1+2 Scripts Complete (2026-03-22T10-28-59Z)

**From:** Bart (Architect)  
**Impact:** Training data generation, embedding pipeline  

Bart completed the build pipeline for the embedding parser (Phases 1 & 2), including scripts for training data extraction and embedding index generation.

**Key Finding That Affects Your Matrix:** Your matrix covers 31 verbs, but Bart's extraction found 54 total verbs in the codebase:
- 31 primary handlers (the canonical verbs you documented)
- 23 aliases (TAKE→GET→GRAB→PICK, GO→N/S/E/W, etc.)

**Impact on Your Design:**

1. **Your matrix is _almost_ complete** — you have all 31 canonical verbs documented thoroughly.

2. **Aliases matter for training data** — Bart's Phase 1 script extracts all 54 verbs and generates training pairs for each. Players can type any of the 23 aliases, so the embedding model needs to see those variations too.

3. **Your variations might need expansion** — For each alias (GET, GRAB, PICK, N, S, E, W, etc.), consider adding 5-10 variations to ensure the embedding model understands all entry points.

4. **No conflict** — Your design (pronoun resolution, darkness verbs, tool verbs, bare commands) applies equally to all 54 verbs. The extra 23 just need variation examples.

**Recommended Action:** Review your matrix and add natural language variations for the 23 aliases alongside the canonical verbs. Example:
- TAKE: "grab", "pick up", "snatch"
- GET: "obtain", "retrieve" (alias of TAKE, but separate handler)
- GRAB: "seize", "snatch" (alias of TAKE)
- PICK: "pick", "pluck" (alias of TAKE)

**Verification Complete:**
- Phase 1 script tested: 29,582 training pairs generated successfully
- All 54 verbs + 39 objects covered
- CSV intermediate format ready for QA validation

**Next Step:** Consider updating the command-variation-matrix.md section titles to clarify which are primary and which are aliases, or expand sections to include alias variations explicitly.

**Decision Filed:** `.squad/decisions.md` - "Parser Pipeline Architecture (Phase 1 + 2)"

---

## Cross-Agent Update: FSM Container Model Integration Ready (2026-03-22T14:29:02Z)

**From:** Bart (Architect) — Completed Batch 2 Fixes  
**Status:** Compound commands, pronoun resolution, em dash normalization  
**Impact:** Parser usability, natural language support, cross-platform compatibility

**What Happened:** Batch 2 play test fixes are complete and committed. Key implications for your design work:

1. **Compound commands now work** — "get a match and light it" splits into two independent commands that both resolve naturally. Your container design (nightstand + drawer) integrates perfectly here.

2. **Pronouns resolve to last-found object** — When players open a drawer and say "take it", the pronoun resolver finds the drawer (last-found container) and resolves "it" to the most recent examined object. Zero designer work required; this is automatic.

3. **Em dashes normalized** — All player-visible text is now ASCII-safe. Your sensory descriptions should avoid Unicode em dashes; double-dash `--` is safe and reads naturally.

**Design Integration Checkpoint:** Your multi-sensory descriptions + Bart's container queries + pronoun resolution create a cohesive dark-mode experience. Example flow:
- Player: "feel around" → gets room summary (your sensory descriptions)
- Player: "open drawer" → Bart's container model + mutation system
- Player: "what's in it?" → Bart's container query NLP
- Player: "take it" → Pronoun resolution finds the drawer; system asks "Take what from the drawer?"

**Next for You:** Verify that your sensory descriptions are sufficient for the "feel" path through containers. Example: does a player who only touches the nightstand (no sight) understand there's a drawer? Test with Bart when container mutation is live.

---

## Cross-Agent Update: CYOA Branching Research Now in Decisions (2026-03-22T14:29:02Z)

**From:** Frink (Researcher)  
**Status:** Proposed (filed Decision #8)  
**Impact:** Future narrative engine, hidden content design

**Key Principle:** Bottleneck/diamond branching (convergent paths) with state-tracking personalization. Hidden nodes as first-class feature.

**Why It Matters for You:** Future object design may include state-aware flavor text. Example: the nightstand's sensory description might differ based on whether the player has already opened the drawer (visited state) or not. Your multi-sensory system already supports conditional field logic — this design principle just formalizes how to use it.

**Not Immediate:** This affects narrative scope, not core gameplay. But design language (state-aware descriptions, hidden discovery, consequence-based branching) should inform new object design.
