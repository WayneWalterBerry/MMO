# Project Priorities

**Set by:** Wayne Berry  
**Date:** 2026-03-29  
**Philosophy:** Stability first, then least-disruptive features, NPC Combat last

## Priority Order

| Rank | Project | Status | P0 | Owner |
|------|---------|--------|-----|-------|
| 0a | Testing | ✅ Steady State | Keep 257 tests green | Marge + Nelson |
| 0b | Linter | ✅ Maintenance | Maintenance mode | Wiggum |
| 1 | Worlds | 📋 Ready to Execute | Execute designed world topology | Bart + Moe |
| 2 | Sound | 📋 Design Complete | Full team review (impl-plan P5) | Bart + Gil |
| 3 | Food | 📋 90% Done | Add 4 raw-meat objects, ship | Flanders |
| 4 | NPC Combat | 📋 Pre-Wave | Phase 5 plan reviewed, PRE-WAVE pending | Bart (arch lead) |

## Always Nice / Background

- **Parser Improvements** — Smithers works on this when available, no urgency (D1-D4 resolved by Frink, 91.2% accuracy)

## Completed

- **Linter** — ✅ Complete (6/6 waves), maintenance mode
- **Mutation Graph** — ✅ Phase 1 complete, Phase 2 deferred

---

## Open Issues Burndown Plan (2026-03-29)

**Scan Date:** 2026-03-29 00:00 UTC  
**Total Open Issues:** 18  
**Kirk Issue Scan:** All issues categorized below

### Summary by Category

| Category | Count | Assignees | Action |
|----------|-------|-----------|--------|
| **T0 Stability Bugs** | 2 | Moe, Lisa | CRITICAL — Fix immediately |
| **Squad-Assigned (Puzzle 017)** | 5 | Bart, Flanders, Moe | Ready to execute (depends on #126) |
| **Squad-Assigned (Portal TDD)** | 6 | Lisa, Moe | Ready to execute (high value) |
| **Squad-Assigned (Cleanup)** | 1 | Moe | Standard chore (GUID-02 orphans) |
| **Deferred / Design** | 3 | — | Future features (rabies, lycanthropy, clothing storage) |
| **Untriaged** | 1 | — | Needs routing (#126) |

### Issues by Priority

#### 🔴 T0 STABILITY BUGS (Actionable Now)

| # | Title | Assigned To | Owner | Est. Complexity |
|---|-------|-------------|-------|-----------------|
| 406 | BUG: 'Report Bug' command gives 404 — wrong repo URL in meta.lua | Moe | Moe | Quick fix (<5 min) |
| 315 | BUG-200: Pack tactics untestable — only 1 wolf in game | Lisa | Lisa | Standard (15–20 min) |

**Burndown Wave 1:** Parallel execution by Moe + Lisa. Both are blocking nothing else. TDD mandatory: failing test → fix → run full suite.

#### 🟢 SQUAD-ASSIGNED (Ready to Execute)

**Puzzle 017 objects (5 issues) — Dependency: #126 must be resolved first**

| # | Title | Assigned To | Owner | Est. Complexity | Dependencies |
|---|-------|-------------|-------|-----------------|--------------|
| 258 | Update incense-burner for incense-stick compatibility | Bart, Flanders | Flanders | Standard | #255, #256, #257 |
| 257 | Create stone-alcove.lua object | Flanders, Moe | Flanders | Quick fix | #254 |
| 256 | Create altar-candle.lua object | Flanders, Moe | Flanders | Quick fix | — |
| 255 | Create incense-stick.lua object | Flanders, Moe | Flanders | Quick fix | — |
| 254 | Update deep-cellar.lua room with chain mechanism + alcove | Moe | Moe | Standard | #257 |

**Portal TDD Refactors (6 issues) — No dependencies, high confidence**

| # | Title | Assigned To | Owner | Est. Complexity |
|---|-------|-------------|-------|-----------------|
| 208 | TDD + refactor courtyard-kitchen door | Lisa | Lisa | Standard (10–15 min) |
| 207 | TDD + refactor hallway-east door | Lisa | Lisa | Standard (10–15 min) |
| 206 | TDD + refactor hallway-west door | Lisa | Lisa | Standard (10–15 min) |
| 205 | TDD + refactor hallway-level2 staircase | Lisa | Lisa | Standard (10–15 min) |
| 204 | TDD + refactor deep cellar-crypt archway | Lisa | Lisa | Standard (10–15 min) |
| 203 | TDD + refactor deep cellar-hallway stairway | Moe | Moe | Standard (10–15 min) |

**Cleanup (1 issue)**

| # | Title | Assigned To | Owner | Est. Complexity |
|---|-------|-------------|-------|-----------------|
| 250 | meta-lint: GUID-02 — 21 orphan objects not referenced | Moe | Moe | Chore (varies: audit + decision) |

#### 🟡 UNTRIAGED (Needs Routing)

| # | Title | Assigned To | Category | Notes |
|---|-------|-------------|----------|-------|
| 126 | Deep-cellar chain puzzle undefined + incense burner FSM missing | — | Engine/Design | **BLOCKER for Puzzle 017 execution.** Needs Bart routing (engine design) or Sideshow Bob (puzzle design). |

#### ⏱️ DEFERRED / FUTURE (Not Blocking Beta)

| # | Title | Category | Notes |
|---|-------|----------|-------|
| 265 | Bug: Wearing clothes requires empty hands + no pocket storage | Enhancement | Design issue — wardrobe system needs review (CBG/Flanders). Defer to Phase 2. |
| 263 | Feature: Rabies as Injury/Disease type | Enhancement | Future injury system expansion. Defer. |
| 262 | Feature: Werewolf Disease (Lycanthropy) as Injury type | Enhancement | Future injury system expansion. Defer. |

### Proposed Burndown Waves

**Wave 1 (Stability bugs) — Parallel:**
- 🔨 **Lisa** — #315 (pack tactics untestable) — TDD mandatory
- 🏗️ **Moe** — #406 (report bug URL) — TDD mandatory

**Expected duration:** ~20 min  
**Post-Wave:** Re-scan GitHub, commit + push

---

**Wave 2 (Portal TDD refactors) — Parallel (after Wave 1):**
- 📋 **Lisa** — #208, #207, #206, #205, #204 (5× portal doors/stairs)
  - Route to one instance of Lisa, serialized per file
  - TDD mandatory for each: failing test → fix → full test pass
- 🏗️ **Moe** — #203 (deep cellar-hallway stairway)
  - Independent file, parallel with Lisa
  - TDD mandatory

**Expected duration:** ~60–90 min  
**Post-Wave:** Commit + push, re-scan

---

**Wave 3 (Route #126 + Puzzle 017 prep) — Sequential blocker**
1. **Bart or Sideshow Bob** — #126 (deep-cellar FSM + chain puzzle) — Design triage, TDD
   - Determines whether Puzzle 017 can proceed in Wave 4
2. **Flanders + Moe** — #255, #256, #257, #254, #258 (create objects + update room)
   - Parallel execution (different files)
   - Each: TDD mandatory, test against room containment constraints

**Expected duration:** ~45–75 min  
**Post-Wave:** Commit + push, Marge verification

---

**Wave 4 (Cleanup chore) — Optional**
- 🏗️ **Moe** — #250 (orphan GUID audit)
  - Chore: review 21 orphan objects, decide: keep as inventory spawns, move to future puzzles, or delete
  - TDD: write linter to prevent future orphans

**Expected duration:** ~30–60 min  
**Post-Wave:** Commit + push

---

### Test Pass Gate (After All Waves)

Once all waves complete:
1. **Marge verification** — QA checks recent closures, can reopen
2. **Full test pass** (parallel):
   - Linter (`lua src/engine/linter.lua`)
   - Unit tests (`lua test/run-tests.lua`)
   - Parser benchmark
   - Nelson walkthrough
3. **Final deployment** (Gil)

---

### Summary for Wayne

**Actionable Now (14 issues):**
- T0 bugs: 2 (fix immediately)
- Squad-ready: 12 (execute Waves 2–4 after #126 routing)

**Blocked on Routing (1 issue):**
- #126 needs owner assignment (Bart or Sideshow Bob)

**Deferred (3 issues):**
- Clothing storage, rabies, lycanthropy → Phase 2

**Estimated Total Burndown Time:** ~3 hours (4 waves + test pass)

---

### Next Action

**Kirk's next move:** Request Bart + Sideshow Bob to triage #126 (deep-cellar FSM + chain puzzle). Once assigned, Wave 3 can begin. Waves 1–2 can start in parallel.


