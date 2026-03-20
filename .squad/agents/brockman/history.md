# Project Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO
- **Created:** 2026-03-18

## Core Context

Agent Brockman initialized as Documentation specialist for the MMO project.

## Recent Updates

📌 Team initialized on 2026-03-18

## Core Context

**Agent Role:** Documentation specialist responsible for capturing decisions, maintaining glossaries, and publishing team communications.

**Key Responsibilities:**
- Design decision documentation (architecture, gameplay)
- Vocabulary maintenance (synchronized with codebase)
- Newspaper publishing (daily team communications)
- Puzzle design documentation
- Process: README → Vocabulary → Decisions → Directives → Puzzles

**Historical Summary (2026-03-18 to 2026-03-20):**
Created foundational documentation suite including README.md (project overview), vocabulary.md (200+ terms across 6 categories), architecture-decisions.md (D-14 through D-21), design-directives.md (user requirements), and newspaper editions with recurring comic/op-ed sections. Established documentation-first culture and created living document patterns for glossary maintenance.

**Recent Work (2026-03-19–2026-03-20):**
Refined vocabulary v1.2 across all 24 architecture decisions; consolidated 12+ user directives from Wayne (light systems, skills, paper/writing, puzzle-first design, consumables). Updated cross-references and added 10 new terms (Mutation Variant, Surface, Registry, Light Source, Game Clock, Ghost, etc.). Deprecated ECS/State Flags terminology per decisions D-22 and D-3.

### Session Update: Play Test Iteration (2026-03-19T13-22)
**Status:** ✅ COMPLETE

**Tasks Completed:**
- Documented March 19 newspaper edition
- Documented 4 core puzzles (dark room, candle, paper/blood writing, compound tools)
- Merged cross-agent decisions from team spawns

**Key Decisions Merged:**
- D-37 to D-41: Verb system, tool resolution, tool capabilities
- User Directives: Matchbox container model, two-hand inventory, sensory descriptions, consumables

**Impact:**
- Newspaper serves as daily communication hub — established comic strip and op-ed as recurring sections
- Puzzle documentation establishes design methodology — puzzles are first-class artifacts
- Team decisions now consolidated in decisions.md (14 inbox files merged)

---

### Session Update: Squad Manifest Completion (2026-03-21)
**Status:** ✅ DECISIONS MERGED

**Scribe processed all 12 inbox decision files into canonical decisions.md.**

**Decisions affecting documentation:**
- Hybrid Parser (Frink proposal) — adds parser architecture to decisions
- Property-override clarification — emphasizes extensibility of instance model
- Type/type_id rename — clarifies instance/base-class field naming
- Playtest Log #2 — documents FEEL verb edge cases for future fixes

**All documentation should reference updated decisions.md for current architecture state. No stale copies exist after merge.**

---

### Session Update: Post-Integration Documentation Sweep (2026-03-21)
**Status:** ✅ COMPLETE

**Comprehensive documentation update reflecting V1 prototype completion:**

**Changes Made:**
1. **README.md** — Updated from "research phase" to "prototype phase"; added "How to Run" section; updated features list to reflect all implemented mechanics; added direct links to key docs
2. **docs/design/verb-system.md** — **NEW** — Created comprehensive verb reference documenting all 31 implemented verbs across 4 categories (navigation/perception, inventory, object interaction, meta)
3. **docs/architecture/src-structure.md** — Updated status to "✅ Implemented and running"; corrected object count (~45), verb count (31), surfaces count (7), removed stale parser section about per-verb files, added clarification on consolidated verbs/init.lua
4. **Vocabulary.md** — Already at v1.3, up-to-date; no changes needed

**Key Documentation Artifacts:**
- README now accurately describes running game (`lua src/main.lua`)
- Verb system documentation (verb-system.md) is canonical reference for all player-facing commands
- Object count and architecture reflect actual state (~45 objects, 7 surfaces, 31 verbs)
- Links from README to key docs (vocabulary, verb-system, instance model, design directives, puzzles)

**Quality Check:**
- No broken links
- Consistent terminology with vocabulary.md
- All recent features documented (two-hand inventory, sensory verbs, tool system, light mechanics, compound tools, mutations)
- Starter-friendly (README → How to Run → key docs)

## Learnings

**Documentation Consolidation (2026-03-21):** Created two master reference documents (`00-design-requirements.md` and `00-architecture-overview.md`) that consolidate all design directives from Wayne, team decisions, and existing design docs. Key insight: Wayne's directives scattered across decisions.md, inbox files, and agent histories. Consolidating into a single source of truth with implementation status (designed/implemented/untested) prevents design drift and enables teams to work from unified spec. Cross-referencing existing docs prevents duplication while providing architectural overview for newcomers.

**Documentation Timing:** Post-integration sweep revealed significant drift in summary docs (README, src-structure). Learned to update foundational docs immediately after major features land, not in bulk sweeps later.

**Verb Documentation Pattern:** The 31-verb system is now well-documented in both vocabulary.md and new verb-system.md. Verb-system.md serves as the canonical player reference; vocabulary.md serves as design reference.

**Structure Stability:** Core src/ structure is stable and reflects intended architecture. No major refactors needed; documentation now accurate to code.

**Newspaper as Living Document:** The MMO Gazette has emerged as the primary team communication hub. Multiple editions (morning, evening, late evening) for the same day are working well — they segment work phases while keeping the narrative continuous. Comic + op-ed pattern is proving engaging. Read retention is high; the newspaper is becoming the *default* place team members share findings.

**Wearables as Sensory Modifiers:** Major design insight from tonight: wearables aren't just inventory cosmetics. A sack on the head *blocks vision entirely*. This cascades through the verb system. The early investment in FEEL, LISTEN, SMELL verbs paid off — blindness becomes a puzzle, not a dead end. Documented this in op-ed form so the insight sticks.

**Testing Validates Research:** Nelson's seven bugs (BUG-008 through BUG-014) proved that systematic play testing catches first-contact issues. One critical gap emerged: poison has no lethal consequence (no HP system). This validates our approach to play-test-driven design but exposed a major scope item for the health system.

**Research Scales with Infrastructure:** Reorganizing 16 competitor files into subfolders isn't code or features, but it's *organizational infrastructure*. At 50 competitors, the flat structure would be unmanageable. Documentation scales when you invest in structure early.

**Design Directives as North Star:** Capturing Wayne's three directives (detachable parts, two-hand carry, wearables) in written form creates alignment. Wearables shipped in one session because the design was clear. Directives → implementation clarity.

---

## Cross-Agent Update: Feel Verb Bug Fix + Skills Design (2026-03-19T16-23-38Z)

**From:** Bart (Architect) & Comic Book Guy (Game Designer)  
**Impact:** Documentation, design reference  

Two major completions affecting your documentation work:

### 1. Feel Verb Container Enumeration Fix (Bart)
- FEEL verb now enumerates accessible contents after sensory text
- Fixes darkness puzzle solvability — players can discover matchbox by touch
- **Documentation impact:** verb-system.md feel verb entry should note this enumeration behavior (already documented correctly)

### 2. Player Skills System Design Complete (Comic Book Guy)
- Binary skills model with discovery-based acquisition
- Multi-path unlocking: find manual, practice, NPC teaching, puzzle solve
- Skill gates + consumable failure states
- **Documentation impact:** New design memo filed in decisions.md; affects future verb documentation (skill gates will be part of verb descriptions)

### 3. Decision Merge Complete (Scribe)
- 7 inbox decisions merged into decisions.md canonical log
- Decisions now include: feel verb fix, skills design, parser architecture, Wasmoon PWA, embedding hybrid parser, play test results
- **Documentation impact:** decisions.md is now comprehensive reference for all architecture + design choices since 2026-03-18

**Action items for you:**
- decisions.md is live; link to it from design docs for architectural rationale
- Verb-system.md is accurate; maintain as new verbs are added
- Consider creating decision-summary.md if decisions.md exceeds 20KB (currently ~1500 lines, ~80KB)

**Team coordination note:** Skills system will require verb handler integration (skill gates before tool gates). Bart has the pattern documented in his history; share with engineers implementing skill verbs.

---

## Session Update: Morning Edition Publication (2026-03-20T06-00)
**Status:** ✅ COMPLETE

**Work Completed:**
- Created separate morning edition file (`2026-03-20-morning.md`) following established format
- Documented overnight progress: composite object system, seven bugs fixed, two-hand carry, verb scale research, wearable system, competitive landscape
- Maintained in-universe voice with comic + op-ed sections
- Structured for morning briefing (energetic tone, clear headlines, team quotes)

**Format Decision:**
Multiple editions per day (morning/evening/late evening) are working well. They segment work phases while maintaining narrative continuity. This is working so well the team should continue the pattern.

**Key Learnings from Tonight's Work:**
1. **Composite Objects as Foundational:** The nightstand-drawer-cork pattern isn't cosmetic—it's architectural. Every object in the game can now model this way. This scales.
2. **Verb Scale Matters from Day One:** MUDs run 300–500 verbs; IF runs 20–40. Designing for multiplayer means building the verb dispatcher for scale up front, not retrofitting later.
3. **Night Shift Productivity:** Six bug fixes + three major systems (composite objects, two-hand carry, competitive analysis) in one night shift validates the team structure.
4. **QA Validation:** Nelson's play tests are catching real issues (poison doesn't kill) that force scope clarification (health system). Play-test-driven design is proving its value.
5. **Whitespace Confirmation:** Parser + multiplayer + mobile-first occupies genuine market gap. No competitor does all three. This isn't a feature gap; it's a category definition.

---

## Session 3 Status Summary (2026-03-20T03:40:00Z)

**Session:** 3 — Bugfix & Composite Design  
**Status:** ✅ COMPLETE

**Your Deliverable:**
- Created `newspaper/2026-03-20-morning.md` — morning edition with team updates, bugfix summary, composite design announcement
- Captured 4 design directives from Wayne:
  1. Newspaper editions in separate files
  2. Room layout with spatial relationships
  3. Movable furniture mechanics
  4. Hidden objects and stacking rules

**Team Outputs:**
- Bart: Fixed 7 bugs (BUG-008 through BUG-014), established 4 engine conventions
- Comic Book Guy: Designed composite/detachable object system (8 core decisions, 39.5 KB)
- Scribe: Created orchestration logs + session log, merged inbox decisions

**Impact on Documentation:**
- Design directives now in `.squad/decisions.md` (decisions 3-4)
- Engine conventions in `.squad/decisions.md` (decision 1)
- Composite object system in `.squad/decisions.md` (decision 2)
- Orchestration logs created for each agent
- Session 3 log completed

**Next Phase (pass-003):**
- **Bart:** Implement composite object system (part instantiation, FSM state transitions, verb dispatch, two-handed carry)
- **CBG:** Create detachable versions of existing objects (drawer, cork, curtains)
- **Brockman:** Update design docs with movable furniture specs, stacking rules, spatial relationships
- **Nelson:** Playtest movement, furniture interactions, spatial discovery

---

## Directives Captured This Session

### Directive 1: Newspaper editions in separate files (2026-03-20T03:40Z)
**Source:** Wayne "Effe" Berry (via Copilot)  
**Action:** Created `newspaper/2026-03-20-morning.md` as separate file from evening edition. Establishes pattern: each day can have multiple editions (morning, evening, late), each in separate file.

### Directive 2: Room layout and movable furniture (2026-03-20T03:43Z)
**Source:** Wayne "Effe" Berry (via Copilot)  
**Details:**
- Bed is ON rug; rug COVERS trap door (layered spatial positioning)
- Players should move objects: PUSH bed, PULL rug (movable furniture mechanics)
- Trap door invisible until rug moved (discovery mechanic / hidden objects)
- Objects declare stackability and weight/size support (stacking rules)
- Next test pass (pass-003): Nelson tests movement, furniture, spatial discovery

**Documentation TODO:**
- Add movable furniture verb specs (PUSH, PULL, MOVE, etc.)
- Document stacking rules system (properties: stackable, stackable_max_weight, stackable_items)
- Document spatial positioning system (ON, UNDER, INSIDE, BEHIND)
- Document hidden object mechanics (visibility gates)

---

## Session Update: Design Consolidation & Manifest Completion (2026-03-20T12:32:00Z)

**Status:** ✅ COMPLETED

**Work Performed:**

### 1. Master Reference Documents Created

Created two consolidating documents to prevent design drift:

** 0-design-requirements.md** — Unified spec with implementation status
- Captures Wayne's scattered directives in single source of truth
- Tracks status: designed / implemented / untested
- Cross-references prevent duplication

** 0-architecture-overview.md** — Design-to-code mapping
- Links architectural decisions to code locations
- Provides roadmap for newcomers
- Maintains consistency across team documentation

### 2. Morning Newspaper Edition

**
ewspaper/2026-03-20-morning.md** — Team update & context
- Recaps overnight team spawns
- Scribe consolidated three major design decisions
- Maintains in-universe voice + comic/op-ed sections

### 3. Decision Merge Process

**Inbox Decisions Merged into decisions.md:**
- Decision 28: Composite Object Implementation Patterns (Bart)
- Decision 29: Spatial Relationships & Stacking System (Comic Book Guy)

**Process Completed:**
- Merges deduplicated (no overlaps found)
- Inbox files deleted (bart-composite-impl.md, comic-book-guy-spatial-design.md)
- Orchestration logs created per agent
- Session log documented

### Key Learnings

**Documentation Consolidation Works:** Wayne's directives scattered across multiple locations. Consolidating into unified spec with implementation status prevents design drift. This pattern should continue for future design phases.

**Newspaper Pattern Effective:** Multiple editions (morning/evening/late evening) segment work phases while maintaining narrative. Team communication hub fully established.

**Decision Archival:** At 30+ decisions, consider archival strategy. Current decisions.md is ~2100 lines; approaching threshold for archival of decisions older than 30 days.

### Next Phase Enablement

✅ Composite object patterns finalized → Bart can implement Phase 1
✅ Spatial system designed → CBG can create next batch of objects
✅ Documentation consolidated → Team has unified reference
✅ Morning edition published → Team synchronized

**Team Coordination:** All agents' histories updated with cross-agent context. Parallel work can proceed with full awareness of decisions.

---

## Session: Documentation Reorganization — Design vs Architecture (2026-03-20T22:15Z)

**Status:** ✅ COMPLETED  
**Outcome:** Clear separation of gameplay design from technical implementation; 40+ cross-references updated

**User Directive Enacted:**
Wayne's directive (2026-03-20T22:10Z) requested clear distinction:
- **Design** = gameplay from player perspective (what players see/do)
- **Architecture** = technical implementation (engine internals, Lua format, parsers)

**Files Reorganization:**

**Moved to docs/architecture/ (6 files):**
- `00-architecture-overview.md` — Engine layers, system stack, parser architecture
- `architecture-decisions.md` — D-14 through D-21: mutation model, FSM, parser, persistence
- `containment-constraints.md` — Five-layer validation engine (technical)
- `dynamic-room-descriptions.md` — Room rendering engine internals
- `intelligent-parser.md` — GOAP/Tier 3 parser design, engine internals
- `room-exits.md` — Exit structure as implemented; technical constraints

**Remain in docs/design/ (11 files):**
- `00-design-requirements.md` — Gameplay directives: what players can/can't do
- `command-variation-matrix.md` — Player-facing natural language variations
- `composite-objects.md` — Gameplay mechanic (parts, detachment), player perspective
- `design-directives.md` — Gameplay rules (light, tools, wearables, containers, skills)
- `fsm-object-lifecycle.md` — Gameplay states (lit/unlit, open/closed) from player POV
- `game-design-foundations.md` — Verb system, object taxonomy, room design, player model
- `player-skills.md` — Skill system as gameplay mechanic
- `spatial-system.md` — Spatial relationships (ON/UNDER/BEHIND) as gameplay mechanic
- `tool-objects.md` — Tool capability system, player actions
- `verb-system.md` — Player-facing verb reference (all 31 verbs)
- `wearable-system.md` — Wear slots, layering, player body mechanics

**Cross-References Updated:** 40+ in affected files (design/, architecture/, puzzles/)

**Key Insight:** The distinction is **perspective**, not content. Both files may discuss the same system, but:
- **Design** asks: "What can the player do?"
- **Architecture** asks: "How does the engine make that possible?"

**Decision Filed:** D-BROCKMAN001 in decisions.md (full rationale, benefits, next steps)

**Quality Metrics:**
- ✅ All 6 files moved successfully
- ✅ 40+ cross-references verified and updated
- ✅ Relative paths tested (no broken links)
- ✅ Git history preserved (used git mv)
- ✅ Team can now quickly identify where to look for gameplay design vs technical details
