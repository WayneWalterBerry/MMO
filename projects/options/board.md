# Options — Board

**Owner:** 🏗️ Bart (Architecture Lead)  
**Last Updated:** 2026-03-29  
**Overall Status:** 🟡 Architecture phase — Bart writing proposal

---

## Next Steps

| # | Task | Owner | Est. Impact | Status | Notes |
|---|------|-------|-------------|--------|-------|
| 1 | **Architecture decision:** Dynamic vs static vs hybrid options generation | Bart | 🟢 Blocking | 🔴 IN PROGRESS | Decision determines parser aliases, room metadata requirements, and engine API surface. Proposal due before Phase 2. |
| 2 | Parser aliases ("options", "hint", "help me", "what can I do", "give me options") | Smithers | Core | ⏳ Pending architecture | Exact text output format depends on Bart's choice. |
| 3 | Options generator (dynamic, static, or hybrid per architecture) | Bart | Core | ⏳ Pending architecture | Engine implementation + metadata structure TBD. |
| 4 | Number selection handler (player types "1" → execute mapped command) | Smithers | Core | ⏳ Pending architecture | Parser verb integration, UI formatting. |
| 5 | Room metadata (if hybrid/static approach chosen) | Moe | Optional | ⏳ Conditional | Only if architecture requires per-room goal/hint definitions. |
| 6 | Hint quality & puzzle spoiler review | Sideshow Bob | Quality gate | ⏳ Pending Phase 4 | Design review: do hints reveal puzzle solutions? Rewrite if necessary. |
| 7 | Testing (parser, E2E, regression) | Nelson | Quality gate | ⏳ Pending Phase 3 | TDD test suite; LLM playthroughs. |
| 8 | Deployment & beta playtest | Gil | Release | ⏳ Pending Phase 6 | Build + web deployment. |

---

## Phases

| Phase | Task | Owner | Status | Depends On |
|-------|------|-------|--------|-----------|
| **Architecture** | Write proposal: dynamic vs static vs hybrid | Bart | 🔴 IN PROGRESS | — |
| **Phase 1** | Architecture decision resolved | Bart | ⏳ Blocked | Proposal complete |
| **Phase 2** | Parser aliases + UI output formatting | Smithers | ⏳ Blocked | Phase 1 decision |
| **Phase 3** | Options generator implementation | Bart | ⏳ Blocked | Phase 1 decision |
| **Phase 4** | Number selection handler (player input "1" → cmd) | Smithers | ⏳ Blocked | Phase 2 complete |
| **Phase 5** | Room metadata (if needed) | Moe | ⏳ Conditional | Phase 1 decision |
| **Phase 6** | Testing (TDD + LLM walkthroughs) | Nelson | ⏳ Blocked | Phase 4 complete |
| **Phase 7** | Deploy + playtest | Gil | ⏳ Blocked | Phase 6 passing |

---

## Open Questions

**Pending Bart's Architecture Proposal:**

1. **Options generation model:** Should options be:
   - **Dynamic** — Game engine analyzes room state, available verbs, inventory, and suggests 1-4 contextual actions in real time?
   - **Static** — Each room declares 1-4 pre-written hints/goals in its `.lua` definition, loaded at room entry?
   - **Hybrid** — Static base hints, dynamically reordered or filtered based on player state?

2. **Text quality vs spoiler risk:** How detailed should hints be?
   - Too vague → player still stuck
   - Too specific → puzzle spoiled
   - Sideshow Bob to review final text

3. **Invocation frequency:** Rate-limited or unlimited?
   - First call free, subsequent calls cost something?
   - Or always available?

4. **Number selection:** After player sees list, typing "1" should execute mapped command. Who owns verb dispatch?
   - Smithers (parser) or Bart (engine)?

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

- ⏳ **Waiting on:** Bart's architecture proposal (due before implementation starts)

---

## Archive

(Completed phases, decisions, & learnings will be logged here as the project progresses.)
