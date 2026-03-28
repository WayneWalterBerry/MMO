# Squad Decisions

**Last Updated:** 2026-03-28T04:45:00Z  
**Last Deep Clean:** 2026-03-28T05:00:00Z  
**Scribe:** Session Logger & Memory Manager

## How to Use This File

**Agents:** Scan the Decision Index first. Active decisions have full details below. Archived decisions are in `decisions-archive.md`.

**To add a new decision:** Create `inbox/{agent-name}-{slug}.md`, Scribe will merge it here.

---

## Decision Index

Quick-reference table of **active + most recent decisions**.

| ID | Category | Status | One-Line Summary |
|----|----------|--------|------------------|
| D-14 | Architecture | 🟢 Active | Code mutation is state change — objects rewritten at runtime |
| D-INANIMATE | Architecture | 🟢 Active | Objects are inanimate; creatures future phase |
| D-ENGINE-REFACTORING-REVIEW | General | 🟢 Active | Ongoing engine architecture review |
| D-HIRING-DEPT | General | 🟢 Active | All new hires must have department assignment |
| D-WAYNE-CODE-REVIEW-DIRECTIVE | Process | 🟢 Active | Mandatory code review before pull requests |
| D-TESTFIRST | Testing | 🟢 Active | Test-first directive for all bug fixes |
| D-WAVE1-BUTCHERY-CREATURES-SPLIT | Architecture | ✅ Implemented | creatures/init.lua split to actions.lua; -190 LOC headroom |
| D-WAVE1-BURNDOWN | Process | ✅ Complete | Triaged 54 issues, 39 Wave 3 ready, 15 deferred to Phase 5 |
| D-WAVE5-BEHAVIORS | Architecture | ✅ Implemented | Pack tactics, territorial, ambush behavior engine design |
| D-CREATE-OBJECT-ACTION | Architecture | ✅ Implemented | Metadata-driven creature object creation + NPC obstacle detection |
| D-STRESS-HOOKS | Architecture | ✅ Implemented | Stress trauma hooks delegate to central injuries.add_stress() API |

---

## D-14: True Code Mutation (Objects Rewritten, Not Flagged)

**Status:** 🟢 Foundational Principle

When a player breaks a mirror or defeats a creature, the engine does NOT set a flag. Instead, it **rewrites the .lua file itself**. The code IS the state.

**Example:**
- Player: `break mirror`
- Engine: Mutates `mirror.lua` → `mirror-broken.lua` in registry
- Result: All subsequent `look mirror` use broken state; code transformation is permanent for that game instance

---

## D-INANIMATE: Objects Are Inanimate (Creatures Are Future)

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry + Flanders (Object Engineer)

**Scope:** Version 1 (V1) supports **inanimate objects and environmental creatures only**. NPCs (interactive, dialogue-driven creatures) are Phase 5+.

**Why:**
- Creatures currently: Simple AI (wander, attack, flee, drop loot) — no agency or memory
- NPC requirements: Dialogue trees, quest state, multi-turn memory — requires entirely different architecture

**Current scope (V1):**
- ✅ Environmental creatures (wolf, spider, rat) with simple behavior
- ✅ Inanimate objects with state mutations
- ⏳ Phase 5: Interactive NPCs with dialogue and quests

---

## D-WAVE1-BURNDOWN: Triage + Deduplication Report

**Status:** ✅ Complete  
**Author:** Chalmers (Project Manager)  
**Date:** 2026-03-28

**Overview:** 91 reported issues triaged into 63 unique (28 duplicates closed). Phase 4 closed 15 Wave 1–2 integration bugs today.

**Wave 3 Assignment (39 bugs ready):**
- **Tier P0 (Critical):** 6 bugs (stress system, territorial wolves, butchery guards)
- **Tier P1 (High):** 15 bugs (combat loops, creature AI, dark sense)
- **Tier P2 (Medium):** 12 bugs (edge cases, UX clarification)
- **Tier P3 (Low):** 6 bugs (ghost objects, parser edge cases)

**Deferred to Phase 5 (15 issues):**
- Portal refactoring (6 issues, Lisa)
- Puzzle 017 (5 issues, deep-cellar chain mechanism)
- Features/design (4 issues, blocked on Wayne Q1 decisions)

**Team Assignment:**
- **Bart:** 12 bugs (engine/parser/FSM)
- **Smithers:** 16 bugs (parser/verbs/UI)
- **Flanders:** 8 bugs (objects/creatures)
- **Moe:** 1 bug (rooms)

---

## D-STRESS-HOOKS: Stress Trauma Hook Architecture

**Status:** ✅ Implemented  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Phase:** Phase 4 WAVE-3

**Decision:** Stress trauma hooks follow the same pattern as C11/C12 injury and stimulus hooks — minimal integration points that delegate to `injuries.add_stress()`.

**Three hooks, three files:**
1. `witness_creature_death` (death.lua)
2. `near_death_combat` (combat/init.lua)
3. `witness_gore` (butchery.lua)

**Stress debuffs as multipliers:**
- Attack penalty: 15% force reduction per point (floor 0.3×) in `resolution.resolve_damage`
- Movement penalty: Probability of movement failure + reduced flee speed in verbs
- Flee bias: Auto-selects flee in headless mode; hints in interactive mode

---

## D-CREATE-OBJECT-ACTION: Creature Object Creation Engine

**Status:** ✅ Implemented  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**Phase:** Phase 4 WAVE-4

**Decision:** Added `create_object` action to creature action dispatch system. This is **metadata-driven** — any creature can create environmental objects by declaring `behavior.creates_object`.

**Key Design:**
1. **Cooldown uses `os.time()` (real seconds)** — not coupled to presentation layer
2. **Object instantiation via shallow copy + `registry:register()`** — template provided in creature metadata
3. **NPC obstacle check in `navigation.lua`** — `room_has_npc_obstacle()` scans target room for `obstacle.blocks_npc_movement = true`

**Principle 8 Compliance:** No spider-specific logic anywhere. Engine reads `behavior.creates_object` metadata generically.

---

## Standing Directives

### D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24)

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry

All PRs must include **code review summaries** from lead team members before merge. No review = no merge.

### D-TESTFIRST

**Status:** 🟢 Active

Every bug fix must include regression tests verifying the fix. TDD workflow:
1. Write failing test demonstrating the bug
2. Make the fix
3. Verify test passes + no regressions

### D-HEADLESS

**Status:** 🟢 Active

For automated testing, always use `--headless` mode to disable TUI, suppress prompts, emit `---END---` delimiters.

---

**For older decisions, design discussions, and completed Phase 3 work, see `decisions-archive.md`.**
