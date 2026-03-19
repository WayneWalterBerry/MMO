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
