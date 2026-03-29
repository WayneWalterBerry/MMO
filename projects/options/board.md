# Options — Board

**Owner:** 🏗️ Bart (Architecture Lead)  
**Last Updated:** 2026-08-02  
**Overall Status:** 🟢 GATE-1 READY — all 12 blockers resolved, architecture v2 approved

---

## Next Steps

| # | Task | Owner | Est. Impact | Status | Notes |
|---|------|-------|-------------|--------|-------|
| 0 | **Team review ceremony** — 5 reviewers assessed architecture + plan | All | Gate | ✅ COMPLETE | 12 blockers found, all addressable. See `decisions/inbox/squad-options-review-ceremony.md` |
| 1 | **Fix API contracts** — Add Option Table + Context Contract to architecture | Bart | 🟢 Blocking | ✅ COMPLETE | Blocker B1 resolved: Bart added section 4.0 with full contracts |
| 2 | **Wayne decision** — Context window: stable (A) vs rotating (B) vs hybrid (C, recommended) | Wayne | 🟢 Blocking | ✅ COMPLETE | Blocker B2 resolved: Wayne chose Option C (hybrid context window) |
| 3 | **Revise anti-spoiler rules** — Replace diminishing returns with escalating specificity + add puzzle exemptions | Bob + Bart | 🟢 Blocking | ✅ COMPLETE | Blockers B3, B4 resolved: Bob rewrote 7-rule system + exemptions |
| 4 | **Fix parser aliases** — Remove "help me" collision, document numeric precedence | Smithers | 🟢 Blocking | ✅ COMPLETE | Blockers B5, B6, B7 resolved: Smithers removed "help me" collision |
| 5 | **Fix test plan** — Change hints→goals, quantify GATE-5, add test scenario matrix | Kirk | 🟢 Blocking | ✅ COMPLETE | Blockers B8, B10 resolved: Kirk fixed hints→goals, quantified GATE-5 |
| 6 | **Add performance test** — test/options/test-performance.lua + baseline measurement | Bart + Nelson | 🟢 Blocking | ✅ COMPLETE | Blockers B9, B11 resolved: Bart added <50ms budget to architecture |
| 7 | **Clarify goal completion** — State-based vs action-based detection | Bart | 🟢 Blocking | ✅ COMPLETE | Blocker B12 resolved: Bart added state-based detection to architecture |
| 8 | Parser aliases ("options", "hint", etc.) | Smithers | Core | ⏳ Pending GATE-1 | Ready after blockers cleared |
| 9 | Options generator (GOAP hybrid) | Bart | Core | ⏳ Pending GATE-1 | Architecture approved |
| 10 | Number selection handler | Smithers | Core | ⏳ Pending GATE-1 | Parser verb integration |
| 11 | Room goal metadata (7 Level 1 rooms) | Moe | Core | ⏳ Pending Phase 1 | Moe mapped all goals in review |
| 12 | Hint quality & puzzle spoiler review | Sideshow Bob | Quality gate | ⏳ Pending Phase 4 | Bob estimated 1.5 days (not 1) |
| 13 | Testing (parser, E2E, regression) | Nelson | Quality gate | ⏳ Pending Phase 3 | 12-scenario LLM test matrix proposed |
| 14 | Deployment & beta playtest | Gil | Release | ⏳ Pending Phase 6 | Build + web deployment |

---

## Phases

| Phase | Task | Owner | Status | Depends On |
|-------|------|-------|--------|-----------|
| **Review** | Team review ceremony (5 reviewers) | All | ✅ COMPLETE | Architecture proposal |
| **Fixes** | Resolve 12 blockers from review | Bart, Smithers, Bob, Kirk, Nelson | ✅ COMPLETE | Review complete |
| **GATE-1** | Architecture + plan approved by Wayne | Wayne | 🟡 Ready for Wayne's final approval | All blockers resolved |
| **Phase 1** | Core verb + sensory/dynamic suggestions (no GOAP) | Bart | ⏳ Blocked | GATE-1 |
| **Phase 2** | Parser aliases + UI output formatting | Smithers | ⏳ Blocked | GATE-1 + Phase 1 API contract |
| **Phase 3** | GOAP goal integration | Bart | ⏳ Blocked | Phase 1 complete |
| **Phase 4** | Number selection handler (player input "1" → cmd) | Smithers | ⏳ Blocked | Phase 2 complete |
| **Phase 5** | Room goal metadata (7 Level 1 rooms) | Moe | ⏳ Blocked | Goal schema finalized + linter rules |
| **Phase 6** | Testing (TDD + 12 LLM walkthroughs) | Nelson | ⏳ Blocked | Phase 4 complete |
| **Phase 7** | Spoiler review + display text rewrite (1.5 days) | Sideshow Bob | ⏳ Blocked | Phase 4 + Phase 5 complete |
| **Phase 8** | Deploy + playtest | Gil | ⏳ Blocked | Phase 6 passing |

---

## Open Questions

**Resolved by architecture (Approach C — Goal-Driven Hybrid):**
- ✅ Options generation model → Approach C selected, Wayne approved
- ✅ Rate limiting → Unlimited for MVP
- ✅ Number selection → Smithers parser (precedence documented)
- ✅ Parser aliases → Single verb "options" with aliases (minus "help me" — collision)

**Resolved by team review:**
- ✅ Room metadata needed → Yes, `goal` field per room (Moe mapped all 7 Level 1 rooms)
- ✅ Phase 7 scope → 1.5 days, not 1 day (Bob's expanded scope)
- ✅ Anti-spoiler approach → 7-rule system with escalating specificity (Bob's rewrite)

**Resolved by Wayne:**
- ✅ **B2: Context window behavior** — Wayne chose Option C (hybrid: goal steps stable, sensory suggestions rotate)

**All 12 blockers resolved:**
- ✅ B1: API contracts added (Bart)
- ✅ B2: Context window decision (Wayne: Option C)
- ✅ B3, B4: Anti-spoiler rules rewritten (Bob)
- ✅ B5, B6, B7: Parser aliases fixed (Smithers)
- ✅ B8, B10: Test plan updated (Kirk)
- ✅ B9, B11: Performance budget added (Bart)
- ✅ B12: Goal completion clarified (Bart)

---

## Feature Summary

**Player-facing experience:**
1. Player types: `"what are my options"` / `"give me options"` / `"hint"` / `"help me"` / `"what can I do"`
2. Game responds with 1-4 numbered suggestions:
   ```
   1. examine the nightstand
   2. light the candle
   3. look around the room
   4. talk to someone (if applicable)
   ```
3. Player types: `"1"` (or `"do 1"` / `"choose 1"`)
4. Game executes the mapped command

**Design goals:**
- Help stuck players get unstuck without spoiling puzzles
- Respect puzzle design (Sideshow Bob review gate)
- Architecture must integrate cleanly with parser pipeline and room/object system

---

## Related Issues

- Issue #291: Implement hint system (feature request)
- Issue #XXX: Parser alias coverage (if created)
- Issue #XXX: Room metadata schema (if applicable)

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Spoiler leak** | Player experience destroyed | Sideshow Bob hint text review (gate before Phase 7) |
| **Vague hints** | Feature useless | Iterate text with beta playtesters; Nelson LLM walkthroughs |
| **Parser ambiguity** ("options" ↔ "option"?) | Verb dispatch failure | Smithers alias coverage + fuzzy noun resolution |
| **Room metadata scope creep** | Phase 5+ delay | Defer all room data to Phase 5; don't block earlier phases |
| **Dynamic analysis too slow** | UI lag | Measure latency; fall back to static if needed |

---

## Blockers

✅ **All 12 blockers from team review resolved.** GATE-1 ready for Wayne's approval.

- ✅ B1: API contracts (Bart added section 4.0)
- ✅ B2: Context window (Wayne chose Option C)
- ✅ B3, B4: Anti-spoiler rules (Bob rewrote 7-rule framework)
- ✅ B5, B6, B7: Parser aliases (Smithers removed "help me" collision)
- ✅ B8, B10: Test plan (Kirk fixed hints→goals, quantified GATE-5)
- ✅ B9, B11: Performance budget (Bart added <50ms requirement)
- ✅ B12: Goal completion (Bart clarified state-based detection)

---

## Archive

(Completed phases, decisions, & learnings will be logged here as the project progresses.)
