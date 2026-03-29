# Options — Implementation Plan

**Status:** ✅ GATE-1 READY — all blockers resolved, architecture approved  
**Version:** 1.0  
**Last Updated:** 2026-08-02

---

## Executive Summary

The **Options feature** is a hint system for stuck players. When players type `"options"`, `"hint"`, `"what can I do"`, or `"give me options"`, the game responds with a numbered list (1-4) of actions that help them progress. Selecting a number executes that command.

This plan uses **Approach C (Goal-Driven Hybrid)** architecture, approved by Wayne. The system combines static room goals with dynamic sensory/spatial suggestions, escalating specificity across 7 anti-spoiler rules. All 12 team review blockers have been resolved.

---

## Phase Overview

| Phase | Owner | Blocked On | Est. Time | Description |
|-------|-------|-----------|-----------|-------------|
| **Architecture** | Bart | — | ✅ COMPLETE | Approach C (goal-driven hybrid) selected. Wayne approved. |
| **Phase 1** | Bart | — | 1 day | Implement engine-side options API (hybrid model with goal + sensory suggestions). |
| **Phase 2** | Smithers | Phase 1 | 1-2 days | Parser aliases ("options", "hint", etc.). Wire to options API. UI output formatting. |
| **Phase 3** | Bart | Phase 1 | 1-2 days | Options generator (hybrid: goal + dynamic sensory/spatial suggestions). |
| **Phase 4** | Smithers | Phase 2 | 1 day | Number selection handler: player types "1" → execute mapped command. |
| **Phase 5** | Moe | Phase 1 | 1-2 days | Define room goal metadata schema. Populate Level 1 rooms with `goal` field (7 rooms). |
| **Phase 6** | Nelson + Bart | Phases 1-4 | 2-3 days | TDD test suite (parser aliases, selection, E2E). 12 LLM walkthroughs. |
| **Phase 7** | Sideshow Bob + Bart | Phase 4 | 1.5 days | Hint text quality review using 7-rule anti-spoiler framework. Rewrite if spoiler risk detected. |
| **Phase 8** | Gil | Phase 6 passing | 1 day | Deploy to web. Beta playtest. |

---

## Key Questions — ALL RESOLVED

### 1. Options Generation Model
✅ **Approach C (Goal-Driven Hybrid)** — Wayne approved  
Room declares `goal` field (verb + noun + label). Engine supplements with dynamic sensory/spatial suggestions. Hybrid approach balances authorial control with contextual relevance.

### 2. Text Quality & Spoiler Risk
✅ **7-rule anti-spoiler framework with escalating specificity**  
Bob rewrote spoiler rules: avoid puzzle answers, use sensory language, escalate from vague → specific. Puzzle exemption system for intentionally direct hints (e.g., tutorial rooms).

### 3. Rate Limiting
✅ **Free / unlimited for MVP**  
No cost or cooldown. Re-evaluate after beta playtest if abuse detected.

### 4. Number Selection
✅ **Smithers parser — numeric input intercepted in main loop**  
When `pending_options` is active, numbers 1-4 bypass standard verb dispatch. Invalid numbers (0, 5, -1) rejected with error message.

### 5. Parser Aliases
✅ **Single verb "options" with aliases** (minus "help me" — collision with help verb)  
Aliases: "options", "hint", "what can I do", "give me options". Embedding matcher handles variations.

---

## Team Assignments (Provisional)

| Phase | Owner | Dependencies | Files (Provisional) | Notes |
|-------|-------|-------------|-------------------|-------|
| Architecture | **Bart** | — | `.squad/decisions/inbox/bart-options-architecture.md` | Proposal document; answers all 5 key questions above. |
| Phase 1 | **Bart** | Architecture | `src/engine/options/init.lua` (TBD path) | Engine API: `options.get_options(room_context, player_state)` or similar. |
| Phase 2 | **Smithers** | Architecture | `src/engine/parser/init.lua` (verb aliases) + `src/engine/ui/init.lua` (output formatting) | Hook verb "options" to Bart's API. Format 1-4 items in numbered list. |
| Phase 3 | **Bart** | Phase 1 | `src/engine/options/*.lua` (depends on model) | Generator logic (dynamic analysis, OR static loader, OR hybrid orchestrator). |
| Phase 4 | **Smithers** | Phase 2 | `src/engine/verbs/init.lua` (selection verb) | Add verb handler: player types "1" → `options.execute_selection(1)`. |
| Phase 5 | **Moe** | Architecture | `src/meta/rooms/*.lua` | Add `goal` field to each room def (verb + noun + label). Level 1 only for MVP. |
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

### Phase 5: Room Metadata (Moe)

**Goal:** Define room goal schema and populate Level 1 rooms (hybrid approach requires `goal` field).

**Tasks:**
- Add `goal` field to room template in `src/meta/templates/room.lua`
- Edit each Level 1 room: `src/meta/rooms/level-01/*.lua` → add field:
  ```lua
  goal = {
      verb = "examine",
      noun = "mirror",
      label = "Look at the mirror"
  }
  ```
- Linter validation: ensure goal verb/noun are valid game commands (lint.py rule)
- 7 Level 1 rooms × ~30 min per room = ~3.5 hours

**Tests (TDD):**
- `test/options/test-phase5-metadata.lua`
- Verify room.goal structure matches schema (verb, noun, label fields required)
- Verify all goals are valid, executable commands
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
| **GATE-2** | Phase 2 parser aliases working, all trigger words → "options" verb | Smithers + Nelson | Wayne |
| **GATE-3** | Phase 3 generator produces 1-4 valid, non-duplicate suggestions | Bart + Nelson | Wayne |
| **GATE-4** | Phase 4 number selection works (player types "1" → executes) | Smithers + Nelson | Wayne |
| **GATE-5** | (1) 12/12 LLM walkthrough scenarios pass, (2) 5/5 parser alias tests pass, (3) all number selection tests pass (1-4 valid, 0/5/-1 rejected), (4) <50ms per options call, (5) zero regressions in existing test suite | Nelson + Marge | Wayne |
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

## Pending Questions

✅ **All key questions resolved** — see Key Questions section above.

- ✅ Architecture: Approach C (goal-driven hybrid) — Wayne approved
- ✅ Parser aliases: Single verb "options" with 4 aliases (minus "help me")
- ✅ Rate limiting: Free / unlimited for MVP
- ✅ Room metadata: `goal` field (verb, noun, label) required per room
- ✅ Performance budget: <50ms per options call
- ✅ Context window: Option C (hybrid — goal steps stable, sensory suggestions rotate)
- ✅ Goal completion: State-based detection (not action-based)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1 | 2026-03-29 | Initial plan structure (pre-architecture); all phases conditional on Bart's proposal |
| 0.2 | 2026-08-02 | **Team review ceremony complete.** 5 reviewers (Bart, Smithers, Moe, Nelson, Bob). 12 blockers identified, all addressable. Architecture (Approach C) unanimously approved. Anti-spoiler rules expanded to 7. Puzzle exemption system proposed. LLM test matrix expanded to 12 scenarios. Phase 7 re-estimated to 1.5 days. Moe mapped all 7 Level 1 room goals. |
| 1.0 | 2026-08-02 | All 12 blockers resolved. Wayne approved: Approach C (goal-driven hybrid), Option C context window (hybrid), free hints, state-based goal detection. Architecture v2 finalized. Plan promoted to v1.0 — GATE-1 READY. |

---

## Archive

(Completed phases, decision logs, and learnings will be added here as the project progresses.)
