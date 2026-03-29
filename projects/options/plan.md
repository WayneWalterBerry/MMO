# Options — Implementation Plan (Preliminary)

**Status:** ⏳ Pending architecture decision (Bart)  
**Version:** 0.1 (pre-architecture, provisional phase list)  
**Last Updated:** 2026-03-29

---

## Executive Summary

The **Options feature** is a hint system for stuck players. When players type `"options"`, `"hint"`, `"help me"`, `"what can I do"`, or `"give me options"`, the game responds with a numbered list (1-4) of actions that help them progress. Selecting a number executes that command.

This plan establishes **phase structure and team roles**. The detailed implementation design depends on **Bart's architecture decision** (dynamic vs static vs hybrid options generation). Until Bart completes the architecture proposal, exact file paths, code contracts, and testing specs remain provisional.

---

## Phase Overview

| Phase | Owner | Blocked On | Est. Time | Description |
|-------|-------|-----------|-----------|-------------|
| **Architecture** | Bart | — | 1-2 days | Decide: dynamic vs static vs hybrid options generation. Write proposal. |
| **Phase 1** | Bart | Architecture | 1 day | Implement engine-side options API (whatever model Bart recommends). |
| **Phase 2** | Smithers | Architecture | 1-2 days | Parser aliases ("options", "hint", etc.). Wire to options API. UI output formatting. |
| **Phase 3** | Bart | Phase 1 | 1-2 days | Options generator (dynamic state analysis OR static room data OR hybrid). |
| **Phase 4** | Smithers | Phase 2 | 1 day | Number selection handler: player types "1" → execute mapped command. |
| **Phase 5** | Moe | Architecture | 1-2 days | **Conditional:** If hybrid/static approach, define room metadata schema. Populate Level 1 rooms with goal/hints. |
| **Phase 6** | Nelson + Bart | Phases 1-4 | 2-3 days | TDD test suite (parser aliases, selection, E2E). LLM walkthroughs. |
| **Phase 7** | Sideshow Bob + Bart | Phase 4 | 1 day | Hint text quality review. Rewrite if spoiler risk detected. |
| **Phase 8** | Gil | Phase 6 passing | 1 day | Deploy to web. Beta playtest. |

---

## Key Questions (For Bart's Architecture Proposal)

Before implementation starts, Bart must decide:

### 1. Options Generation Model

**Option A: Dynamic** — Engine analyzes room state at runtime and suggests contextual actions.
- Pros: Always relevant to current state; no metadata authoring needed
- Cons: Complex engine logic; may suggest irrelevant actions if heuristics are wrong
- Examples: ["examine bookshelf", "look for clues", "try to climb"]

**Option B: Static** — Each room declares 1-4 pre-written hints in its `.lua` file.
- Pros: Controlled, authoritative, no spoiler risk from engine heuristics
- Cons: Metadata burden on Moe; must write for every room
- Examples: Hard-coded in `start-room.lua`: `hints = {"look at mirror", "examine dresser", ...}`

**Option C: Hybrid** — Static base hints + dynamic filtering/reordering based on player state.
- Pros: Balance of control and relevance; author-approved text, adaptive ordering
- Cons: Most complex; requires both engine logic and metadata schema
- Examples: Room declares `hints = [...]`, engine reorders by player inventory, location, progress

**Recommended:** Option A (dynamic) for initial MVP — easier to ship fast, avoids metadata cost. Fallback to Option B (static) if engine logic is fragile. Upgrade to Option C (hybrid) post-beta if needed.

### 2. Text Quality & Spoiler Risk

- How detailed should hints be? (vague vs specific vs step-by-step)
- **Gate:** Sideshow Bob reviews all hint text before Phase 7 ship. If spoiler risk → rewrite.

### 3. Rate Limiting

- Unlimited calls to "options", or cost/cooldown?
- **Recommendation:** Unlimited for MVP. Revisit after playtest.

### 4. Number Selection

- Player types "1" to execute option 1. Who owns this verb dispatch?
- Option A: Smithers adds "1" as a verb alias (simplest)
- Option B: Bart adds special handling in engine verb dispatcher
- **Recommendation:** Smithers alias (reuse existing parser infrastructure).

### 5. Parser Aliases

- Trigger words: "options", "hint", "help me", "what can I do", "give me options" — all map to same verb?
- Or separate verbs per alias?
- **Recommendation:** Single verb "options" with 5 aliases (consolidate in parser).

---

## Team Assignments (Provisional)

| Phase | Owner | Dependencies | Files (Provisional) | Notes |
|-------|-------|-------------|-------------------|-------|
| Architecture | **Bart** | — | `.squad/decisions/inbox/bart-options-architecture.md` | Proposal document; answers all 5 key questions above. |
| Phase 1 | **Bart** | Architecture | `src/engine/options/init.lua` (TBD path) | Engine API: `options.get_options(room_context, player_state)` or similar. |
| Phase 2 | **Smithers** | Architecture | `src/engine/parser/init.lua` (verb aliases) + `src/engine/ui/init.lua` (output formatting) | Hook verb "options" to Bart's API. Format 1-4 items in numbered list. |
| Phase 3 | **Bart** | Phase 1 | `src/engine/options/*.lua` (depends on model) | Generator logic (dynamic analysis, OR static loader, OR hybrid orchestrator). |
| Phase 4 | **Smithers** | Phase 2 | `src/engine/verbs/init.lua` (selection verb) | Add verb handler: player types "1" → `options.execute_selection(1)`. |
| Phase 5 | **Moe** | Architecture | `src/meta/rooms/*.lua` (if static/hybrid) | Add `goals` or `hints` field to each room def. Level 1 only for MVP. |
| Phase 6 | **Nelson** | Phases 1-4 | `test/options/test-*.lua` | TDD suite: alias matching, selection dispatch, E2E walkthroughs. Deterministic seeds. |
| Phase 7 | **Sideshow Bob** | Phase 4 | Audit hint text + `notes/options-spoiler-review.md` | Read all generated/authored hints. Flag spoilers. Rewrite if necessary. |
| Phase 8 | **Gil** | Phase 6 passing | Web build pipeline | Deploy to GitHub Pages. Coordinate playtest setup. |

---

## Phase Details (Provisional — Updates After Architecture Decided)

### Phase 1: Engine API (Bart)

**Goal:** Implement core options API per chosen architecture.

**Possible outcomes** (one of these per option chosen):

**If Option A (Dynamic):**
- Write `src/engine/options/dynamic.lua`
- Function: `generate_options_dynamic(room_context, player_state)` → list of 1-4 strings
- Heuristics: examine verbs available in room + inventory checks + light/darkness + door exploration + object state analysis
- ~150-200 LOC

**If Option B (Static):**
- Write `src/engine/options/static.lua`
- Function: `load_room_hints(room_id)` → list from room metadata
- Validation: ensure hints are valid verbs in-game
- ~50-100 LOC

**If Option C (Hybrid):**
- Write `src/engine/options/hybrid.lua`
- Function: `generate_options_hybrid(room_context, player_state, base_hints)` → reordered/filtered list
- Combine static + dynamic logic
- ~200-300 LOC

**Tests (TDD):**
- `test/options/test-phase1-api.lua`
- Unit tests for chosen generator function
- Mock room contexts, test 5+ scenarios per model type

---

### Phase 2: Parser Aliases & UI (Smithers)

**Goal:** Hook verb "options" to engine API. Format output.

**Files:**
- Edit: `src/engine/parser/init.lua` → add aliases ["options", "hint", "help me", "what can I do", "give me options"]
- Edit: `src/engine/verbs/init.lua` → add verb handler:
  ```lua
  verbs.options = function(context, noun)
      local opts = options_api.get_options(context.room, context.player)
      if not opts or #opts == 0 then
          print("No options available right now.")
          return
      end
      print("Your options:")
      for i, opt in ipairs(opts) do
          print(string.format("  %d. %s", i, opt))
      end
  end
  ```
- Edit: `src/engine/ui/presentation.lua` → formatters for numbered lists (if custom styling needed)

**Tests (TDD):**
- `test/options/test-phase2-parser.lua`
- Verify all 5 aliases resolve to "options" verb
- Test output formatting (1-4 items, numbered correctly, no truncation)
- Edge case: room with 0 options → error message
- Edge case: room with >4 options → trim to top 4

---

### Phase 3: Generator Logic (Bart)

**Goal:** Implement chosen model's generator (dynamic/static/hybrid).

**Details depend on Phase 1 architecture choice — see Phase 1 breakdown above.**

**Tests (TDD):**
- `test/options/test-phase3-generator.lua`
- 10+ unit scenarios per model type
- Verify suggestions are valid commands
- Verify no duplicates in list
- Verify list length is 1-4

---

### Phase 4: Number Selection Handler (Smithers)

**Goal:** Player types "1" → execute mapped command.

**Files:**
- Edit: `src/engine/parser/init.lua` → add number alias resolution (link "1" to last options list)
- Edit: `src/engine/verbs/init.lua` → add verb handler for number selection:
  ```lua
  verbs.number = function(context, noun)
      -- noun is the selected number (1, 2, 3, or 4)
      local opts = context.last_options_list  -- Need to track this in context
      if not opts or not opts[tonumber(noun)] then
          print("Invalid selection.")
          return
      end
      local cmd = opts[tonumber(noun)]
      -- Parse + execute the command string
      context:execute_command(cmd)
  end
  ```

**Challenge:** How to track "last options shown" across turns? Options:
- Option A: Store in `context.last_options_list` (session-scoped)
- Option B: Store in registry under player ID (persistent)
- Option C: Re-generate on each number selection attempt
- **Recommendation:** Option A for MVP.

**Tests (TDD):**
- `test/options/test-phase4-selection.lua`
- Player shows options, selects 1-4 → correct command executed
- Player selects invalid number (5, 0, -1) → error
- Player selects after exiting room → error (list cleared)
- Number command executed with same results as typing original verb

---

### Phase 5: Room Metadata (Moe) — CONDITIONAL

**Goal:** If Phase 1 chose static or hybrid, define room schema and populate Level 1.

**Only needed if architecture decision is Option B or Option C.**

**If proceeding:**
- Add `goals` or `hints` field to room template in `src/meta/templates/room.lua`
- Edit each Level 1 room: `src/meta/rooms/level-01/*.lua` → add field:
  ```lua
  hints = {
      "examine the mirror",
      "look for light source",
      "try to open the dresser",
  }
  ```
- Linter validation: ensure hints are valid game verbs (lint.py rule)
- 7 Level 1 rooms × ~30 min per room = ~3.5 hours

**If Option A (dynamic) chosen:** This phase is skipped; move to Phase 6.

**Tests (TDD):**
- `test/options/test-phase5-metadata.lua`
- Verify room.hints structure matches schema
- Verify all hints are valid, executable commands
- Verify no spoiler language (Sideshow Bob review replaces any found)

---

### Phase 6: Testing Suite (Nelson)

**Goal:** Full TDD coverage + LLM walkthroughs + regression gate.

**Files:**
- `test/options/test-suite.lua` (comprehensive integration)
- `test/options/scenarios/` (LLM test walkthroughs)

**Scenarios (5+):**
1. Start game → type "options" → see 1-4 suggestions ✅
2. Type "1" → first suggestion executes correctly ✅
3. Room with 0 options → error message ✅
4. Type "options" twice → same list OR re-evaluated? (depends on design)
5. Multiple players on same level (if multi-player ever happens)

**LLM walkthrough command:**
```bash
echo -e "look\noptions\n1\noptions" | lua src/main.lua --headless
```

**Gate criteria:**
- 100% of test scenarios pass
- No parser regressions (pre-existing test suite still passes)
- No performance regression (<50ms per options call)
- Nelson approves walkthrough UX

---

### Phase 7: Spoiler Review (Sideshow Bob)

**Goal:** Audit all hints/options for puzzle spoilers.

**Files:**
- Read: all hint text (from Phase 3 dynamic output samples OR Phase 5 metadata)
- Write: `notes/options-spoiler-review.md` — assessment + rewrite suggestions

**Gate criteria:**
- All hints pass "helpful but not spoiling" threshold
- Rewritten hints are re-tested by Nelson

---

### Phase 8: Deploy & Playtest (Gil)

**Goal:** Ship to GitHub Pages. Coordinate beta playtest.

**Steps:**
1. Build web version (existing pipeline)
2. Deploy to GitHub Pages
3. Announce playtest (Wayne contacts beta testers)
4. Collect feedback
5. Log issues for Phase 2

**Gate criteria:**
- Web build succeeds
- Playtest runs 1+ session without crashes
- Feedback logged as GitHub issues (if issues found)

---

## Testing Gates (Binary Pass/Fail)

| Gate | Criteria | Owners | Approves |
|------|----------|--------|----------|
| **GATE-1** | Architecture proposal complete, all 5 questions answered, no blockers | Bart | Wayne |
| **GATE-2** | Phase 2 parser aliases working, all 5 trigger words → "options" verb | Smithers + Nelson | Wayne |
| **GATE-3** | Phase 3 generator produces 1-4 valid, non-duplicate suggestions | Bart + Nelson | Wayne |
| **GATE-4** | Phase 4 number selection works (player types "1" → executes) | Smithers + Nelson | Wayne |
| **GATE-5** | Phase 6 test suite passes + no regressions + LLM walkthroughs OK | Nelson + Marge | Wayne |
| **GATE-6** | Phase 7 spoiler review done, no puzzle leaks, rewritten hints re-tested | Sideshow Bob + Nelson | Wayne |
| **GATE-7** | Web build succeeds, deploys to GitHub Pages | Gil | Wayne |

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|-----------|
| **Architecture decision delays Phase 1** | 2-3 day slip | Medium | Bart decides by end of 2026-03-29. If blocked, Wayne clarifies model preference. |
| **Dynamic heuristics suggest wrong actions** | Hints unhelpful | Medium | Phase 6 LLM walkthroughs catch; fall back to static hints if needed. |
| **Parser ambiguity** ("options" ↔ "option" singular?) | Verb dispatch fails | Low | Smithers uses embedding matcher + fuzzy to handle plurals. Test coverage. |
| **Hint text spoils puzzle** | Feature backfires | High | GATE-6 spoiler review (Sideshow Bob) before ship. Rewrite if risk detected. |
| **Metadata scope creep** | Phase 5 delays | Medium | Defer all rooms except Level 1 for MVP. Keep Phase 5 ~3 hours. |
| **Room context not sufficient for dynamic generation** | Vague suggestions | Medium | Phase 1 API design includes `room_context` spec; iterate if needed. |

---

## Autonomous Execution Protocol

After GATE-1 (architecture approved):

1. **Waves cycle:** Phase N agents start simultaneously (no file conflicts)
2. **Inter-phase gates:** Each phase outputs testable artifact. Nelson verifies before next phase starts.
3. **Failure handling:**
   - 1st gate failure → file issue, assign to responsible agent, re-gate (don't escalate immediately)
   - 2nd gate failure on same gate → escalate to Wayne
4. **Checkpoint:** After each gate passes, coordinator updates this plan doc:
   - Mark phase `✅ COMPLETE`
   - Log actual time vs estimate
   - Note any deviations

---

## Commit Strategy

After each gate passes:
```bash
git add projects/options/
git commit -m "docs(options): phase N complete — GATE-N passed

Completed phases: [list]
Gate results: [summary]
Next phase: [owner, phase description]

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Success Criteria (MVP Ship)

✅ Feature is "done" when:
1. All 8 gates pass
2. Player can type "options" in Level 1 and receive 1-4 helpful, spoiler-free suggestions
3. Player can type "1" (or "2"/"3"/"4") and execute mapped command
4. Parser covers all 5 trigger words
5. No regressions in existing test suite
6. Beta playtest starts with no showstoppers

---

## Pending Questions (Awaiting Bart)

- [ ] Architecture proposal written (GATE-1 blocker)
- [ ] Parser alias trigger words finalized
- [ ] Rate limiting policy decided
- [ ] Room metadata schema (if needed)
- [ ] Performance budget set (e.g., <50ms per call)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1 | 2026-03-29 | Initial plan structure (pre-architecture); all phases conditional on Bart's proposal |
| 0.2 | [TBD] | Architecture decision captured; phases 1-3 detailed |
| 1.0 | [TBD] | All phases detailed + GATE-1 approved |

---

## Archive

(Completed phases, decision logs, and learnings will be added here as the project progresses.)
