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
