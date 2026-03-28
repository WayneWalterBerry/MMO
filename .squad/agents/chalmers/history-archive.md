### 2026-03-20: Tier 2 Embedding Parser Implementation Plan Delivered

**Task:** Create comprehensive implementation plan for embedding-based parser (Tier 2).

**Deliverables:**
- ✅ Created `plan/` directory at repo root
- ✅ Created `plan/llm-slm-parser-plan.md` (445 lines, 17.6KB)
- ✅ Committed to main branch

**Plan Structure (Requested by Wayne):**
1. **Goal:** Build deterministic GPU-free embedding fallback (handles 12% of Tier 1 misses)
2. **What We Have:** Tier 1 rule-based parser at 85% coverage (complete, unchanged)
3. **What We Need:** GTE-tiny ONNX INT8 model (5.5MB) + ~2,000 canonical phrases encoded into 384-dim vectors (~3MB raw, ~400KB compressed)
4. **6 Implementation Phases:**
   - Phase 1: LLM generates training data (~2,000 phrases from verbs/objects)
   - Phase 2: Build embedding index using GTE-tiny
   - Phase 3: Runtime integration (ONNX Runtime Web + WASM)
   - Phase 4: Game loop fallback chain (Tier 1 → Tier 2 on miss)
   - Phase 5: CI/CD automation (rebuild index on verb/object changes)
   - Phase 6: Testing & tuning (90%+ accuracy target)
5. **Dependencies:** Phase 1→2→3→4 serial, Phase 5 parallel, Phase 6 blocks release
6. **Risks:** ONNX/Wasmoon conflict, stale index, accuracy below 90%
7. **Open Questions:** Accuracy threshold (0.75?), disambiguation UX, Tier 3 room in architecture

**Timeline:** ~10 working days, mostly parallelizable after Phase 2

**Key Insights:**
- Pre-computed vectors eliminate runtime LLM cost (critical for PWA deployment)
- 2,000-phrase index rebuildable in <2 min on code change (vs. SLM retraining)
- Deterministic cosine similarity → no model drift risk
- Fallback chain preserves Tier 1 reliability (no regressions possible)

**Aligned With:**
- Decision D-19 (Parser approach: embedding recommended over SLM)
- Decision D-17 (Build-time LLM cost model)

**Open Items for Wayne:**
- Confirm accuracy threshold (score 0.75 → execute, 0.50–0.75 → disambiguate, <0.50 → fail)
- Decide on Tier 3 (Qwen2.5 generative, optional, ~350MB)
- Approve training data volume (2,000 vs. 5,000–10,000 phrases)

**Confidence:** HIGH (85%) — Architecture proven (GTE-tiny used in production), dependencies clear, no blockers from active work.

---

### 2026-03-20: Architecture Decision Planning Assessment

**Key Planning Insights:**
1. **Build-time LLM (Decision 4) eliminates per-player token cost** — Major financial win (~$5K-10K/month savings). Changes economics of content generation significantly. Impacts infrastructure planning and content pipeline design.

2. **No Merge (Decision 8) is massive scope reduction** — Removes CRDT/OT complexity; simplifies networking. Trade-off: caps social play early. Opt-in merge UX must be compelling to drive multiplayer adoption.

3. **Meta-code format (Decision 2) is still soft** — "Likely Lua tables" is not firm. Blocks template authoring pipeline. Must be locked down in week 1 of engineering phase. Three viable options: (a) Lua source, (b) JSON + interpreter, (c) hybrid. Each has different serialization, LLM, and hot-reload implications.

4. **True code rewrite adds complexity but not risk** — Mutation model is more involved than flags but well-understood. Early prototype (week 1) mitigates risk. Immutable baseline + mutable overlay pattern is key.

**Dependency Map Discovered:**
- Engine core (Lua) unblocks: universe templates, parser research, networking
- Cloud infrastructure is parallel but critical path for player testing
- Parser approach (NLP vs. synonyms) is high-variance; recommend 1-week prototype race
- Critical path to alpha: ~3 weeks (weeks 1-2: foundation + prototypes; weeks 3-4: integration)

**Risks Identified (NEW):**
1. **High:** Code rewrite complexity + cloud infra dependency → Mitigate with early prototyping
2. **Medium:** Parser approach uncertain, meta-code format soft, no-merge limits social play, procedural variation feels repetitive → Each has clear mitigation
3. **Low:** Fog of war isolation, build-time mutation inflexibility → Accept as design trade-offs; plan compensations

**Team Impact:**
- Designer needs Lua literacy (~2 days learning)
- Backend engineer may need CRDT study (lower priority; post-MVP concern)
- Networking engineer needs fog-of-war + room-scoped patterns
- QA needs cloud save/load testing skills

**Scope Summary:**
- **Simplifications:** No per-player LLM, no merge conflict resolution, single language stack, fog of war networking → 4+ weeks of work saved
- **Additions:** Cloud infrastructure, universe template pipeline, parser prototyping → ~1 week added (net positive)

**Recommended Next Steps:**
1. Lock Decision 2 (meta-code format) by end of week — gates template authoring
2. Start Phase 1 (week 1-2): Engine core prototype + parser race + cloud schema
3. Phase 2 (weeks 3-4): Template pipeline + parser integration + cloud sync
4. Phase 3 (weeks 5-6): Networking + game content + raid scenarios

**Confidence:** MEDIUM-HIGH (70%) — Architecture is sound, main uncertainty is designer learning curve + multiplayer networking patterns unfamiliar to team.

**Firmness Assessment:**
- Decisions 1, 3, 4, 5, 7, 8: FIRM (7/8 locked)
- Decisions 2, 6: SOFT (require week 1 work to finalize)

---

## Cross-Agent Update: Wasmoon Feasibility Confirmed (2026-03-19T16-28-39Z)

**From:** Frink (Technical Researcher)  
**Impact:** Tier 2 Parser Plan risk mitigation  

Frink completed PWA + Wasmoon prototype research. Key impact on parser plan:

1. **ONNX+Wasmoon Compatibility:** Tier 2 parser plan identified ONNX Runtime Web as critical dependency. Frink confirms ONNX Runtime Web + Wasmoon coexist cleanly — no conflicts.

2. **Engine Pure Lua:** Your assumption that engine is ~90% unmodified for browser deployment is validated. Tier 2 embedding parser (pure ONNX inference + cosine similarity) needs no special handling.

3. **Runtime Integration Path:** Phase 3 of your plan (ONNX Runtime Web + WASM integration) is now proven viable. No technical debt or hidden complexity.

4. **5–7hr PWA Prototype:** Frink's estimate means parser plan can proceed in parallel. If Phase 1 (LLM data generation) completes on schedule, Frink can handle browser integration while your team builds Phases 2–4.

**Recommendation:** No changes to parser plan. Risk #1 (ONNX/Wasmoon conflict) is now MITIGATED ✅. Proceed with Phase 1 approval from Wayne.

**Decision:** D-43 filed: PWA + Wasmoon Prototype Feasibility (also confirms D-42 Tier 2 parser viability)

**Key Planning Insights:**
1. **Build-time LLM (Decision 4) eliminates per-player token cost** — Major financial win (~$5K-10K/month savings). Changes economics of content generation significantly. Impacts infrastructure planning and content pipeline design.

2. **No Merge (Decision 8) is massive scope reduction** — Removes CRDT/OT complexity; simplifies networking. Trade-off: caps social play early. Opt-in merge UX must be compelling to drive multiplayer adoption.

3. **Meta-code format (Decision 2) is still soft** — "Likely Lua tables" is not firm. Blocks template authoring pipeline. Must be locked down in week 1 of engineering phase. Three viable options: (a) Lua source, (b) JSON + interpreter, (c) hybrid. Each has different serialization, LLM, and hot-reload implications.

4. **True code rewrite adds complexity but not risk** — Mutation model is more involved than flags but well-understood. Early prototype (week 1) mitigates risk. Immutable baseline + mutable overlay pattern is key.

**Dependency Map Discovered:**
- Engine core (Lua) unblocks: universe templates, parser research, networking
- Cloud infrastructure is parallel but critical path for player testing
- Parser approach (NLP vs. synonyms) is high-variance; recommend 1-week prototype race
- Critical path to alpha: ~3 weeks (weeks 1-2: foundation + prototypes; weeks 3-4: integration)

**Risks Identified (NEW):**
1. **High:** Code rewrite complexity + cloud infra dependency → Mitigate with early prototyping
2. **Medium:** Parser approach uncertain, meta-code format soft, no-merge limits social play, procedural variation feels repetitive → Each has clear mitigation
3. **Low:** Fog of war isolation, build-time mutation inflexibility → Accept as design trade-offs; plan compensations

**Team Impact:**
- Designer needs Lua literacy (~2 days learning)
- Backend engineer may need CRDT study (lower priority; post-MVP concern)
- Networking engineer needs fog-of-war + room-scoped patterns
- QA needs cloud save/load testing skills

**Scope Summary:**
- **Simplifications:** No per-player LLM, no merge conflict resolution, single language stack, fog of war networking → 4+ weeks of work saved
- **Additions:** Cloud infrastructure, universe template pipeline, parser prototyping → ~1 week added (net positive)

**Recommended Next Steps:**
1. Lock Decision 2 (meta-code format) by end of week — gates template authoring
2. Start Phase 1 (week 1-2): Engine core prototype + parser race + cloud schema
3. Phase 2 (weeks 3-4): Template pipeline + parser integration + cloud sync
4. Phase 3 (weeks 5-6): Networking + game content + raid scenarios

**Confidence:** MEDIUM-HIGH (70%) — Architecture is sound, main uncertainty is designer learning curve + multiplayer networking patterns unfamiliar to team.

**Firmness Assessment:**
- Decisions 1, 3, 4, 5, 7, 8: FIRM (7/8 locked)
- Decisions 2, 6: SOFT (require week 1 work to finalize)

### Session Update: Architecture Decisions Session (2026-03-18)
- **Task:** Assess planning implications of 8 architecture decisions from Wayne's session (D-14 through D-21)
- **Status:** ✅ COMPLETE
- **Key Analysis Delivered:**
  - Scope Impact: Identified ~4 weeks of savings from build-time LLM and no-merge simplifications
  - Risk Assessment: High/Medium/Low risks mapped with mitigations
  - Critical Path: ~3 weeks to alpha (foundation + prototypes + integration)
  - Team Impact: Designer Lua literacy, networking engineer fog-of-war patterns, QA cloud testing skills
- **Decisions Assessed:**
  - D-14: Mutation Model (True Code Rewrite)
  - D-15: Meta-Code Format (Deferred — Lua tables/closures)
  - D-16: Engine Language (Lua)
  - D-17: Universe Templates (Build-time LLM + procedural variation)
  - D-18: Persistence (Cloud Storage)
  - D-19: Parser (NLP or Rich Synonyms)
  - D-20: Ghost Visibility (Fog of War)
  - D-21: Universe Merge (No Merge)
- **Orchestration Log:** `.squad/orchestration-log/2026-03-18T23-22-00Z-chalmers.md`
- **Decision Firmness:** 7/8 FIRM, 2 SOFT (meta-code format and language choice need week 1 confirmation)

### 2026-03-23: Wave 3 — Daily Plan Update
**Status:** ✅ COMPLETE  
**Task:** Update daily plan with session work, propagate Wave 3 completion

**Actions:**
- Updated `plans/2026-03-23-daily-plan.md` with Marge (issue closure), Nelson (Pass 039), Smithers (Phase 3) outcomes
- Committed: 26bbc6b — "Chalmers updates daily plan with session work"  
- Propagated Wave 3 context to team history

**Wave 3 Outcomes Documented:**
- **Marge:** #35-39 closed, deploy gate unblocked, 1,088 tests pass
- **Nelson:** Pass 039 solid — 171/171 tests, parser validated, new objects work
- **Smithers:** Phase 3 features shipped, 3 design decisions documented (D-HIT001/002/003)

**Next Wave Targets Identified:**
- Phase 3+ expansion: NPC systems, dialogue routing, extended map
- Foundation assessment: ✅ Engine SOLID, Parser EXCELLENT, Objects VALIDATED

### 2026-03-24: End-of-Day Plan Audit
**Status:** ✅ COMPLETE  
**Task:** Audit daily plans (Mar 22–24), identify incomplete items, file missing issues, compile open questions for Mar 25

**Method:**
- Read all `[ ]` items across 3 daily plans (~65 unchecked boxes)
- Cross-referenced against: 128 closed issues, 29 open issues, 130+ git commits, filesystem deliverables

**Findings:**
- ~59 unchecked items were **done but checkboxes stale** (code committed, issues closed, files exist)
- **6 genuinely incomplete items** had no tracking — all now have GitHub Issues
- 5 items explicitly deferred by Wayne (puzzles, verb expansion, combat, self-infliction questions)

**Issues Filed:**
- #158: Deploy — March 24 work not on live site
- #159: Newspaper — March 24 evening edition missing
- #160: Docs — event-hooks.md needs on_drop + equipment category
- #161: Docs — effects-pipeline.md needs armor interceptor (v3.0)
- #162: Design — Injury-causing objects for unconsciousness triggers
- #163: Test — Material audit CI test (every object needs valid material)

**Open Questions for Mar 25 (13 total):**
- P0-A sequencing: refactor verbs/init.lua before or after meta-compiler?
- P0-B decisions: Python+Lark confirmed? Tool naming? Where does compiler live?
- Deploy timing: ship Mar 24 before starting refactoring?
- Backlog prioritization: 29 open issues, which carry into tomorrow?
- Full list in `temp/plan-audit-2026-03-24.md`

**Assessment:** March 24 was highly productive — armor system, on_drop, brass spittoon, event_output, 25+ bug fixes all shipped. The gaps are docs, deploy, newspaper, and a CI test. No critical feature work left on the floor.

---

### 2026-03-25: Daily Plan Update & Carry-Over Integration
**Status:** ✅ COMPLETE  
**Task:** Flesh out March 25 daily plan with carry-over from March 24, process rules, P0 review, P1/P2 prioritization

**Approach:**
1. Catalogued shipped work from March 24: 12 major features, 14+ bug fixes → 63 closed issues
2. Identified carry-over gaps: 6 items deferred (deploy, newspaper, 2 docs, 1 design, 1 CI test)
3. Structured plan with three priority tiers:
   - **P0:** Two urgent items (engine code review + meta-compiler) — must ship today
   - **P1:** Four carry-over fixes (deploy, docs, newspaper hold status)
   - **P2:** Design work + backlog triage (21 open issues, low-urgency)
4. Embedded Wayne's TDD-First directives + refactoring safety sequence (D-REFACTOR)
5. Built dependencies graph showing blockers and sequencing
6. Listed 4 open questions for Wayne (sequencing, tool decisions, deploy timing, newspaper hold)

**Key Planning Insights Documented:**
- **P0-A complexity:** verbs/init.lua is 5,817 lines; refactoring sequence matters (before or after meta-compiler?)
- **P0-B research-first:** 5 research questions must be answered before design docs (bug catalog, Lark grammar test, Lisa's wishlist, cross-ref inventory, existing validation audit)
- **TDD safety sequence:** Refactoring WITHOUT test coverage violates Wayne's directive D-REFACTOR; test baseline must come first
- **Deploy blocker:** March 24 code isn't live; #158 needs approval + manual gate (Gil responsible)
- **Meta-check as quality gate:** Once shipped, can become CI blocker for all new objects/rooms (enforces schema compliance)

**Carry-Over Summary:**
- Shipped 12 major features + 1,088 tests pass
- 6 incomplete items now tracked with GitHub issues
- 3 docs updates queued for P1 (event-hooks, effects-pipeline, newspaper hold clarification)
- Backlog triage: 21 open issues waiting for P0 completion before prioritization

**Risks Identified:**
1. **High:** Refactoring without test baseline (new code could break) → Mitigated by D-REFACTOR sequencing
2. **Medium:** P0-B design doc delays → Mitigated by pre-research questions (research 30 min, docs 1 hr, build 2–3 hr)
3. **Medium:** Deploy gate manual vs. automated → Affects rollback ease if issues surface

**Next Steps for Team:**
1. Wayne confirms 4 open questions (sequencing, tool details, deploy timing, newspaper hold)
2. Bart begins P0-A code review immediately
3. Frink begins P0-B research (bug catalog, Lark prototype) in parallel
4. Nelson prepares test coverage audit for functions Bart will recommend splitting
5. Brockman blocks on P0-B design doc approval before writing docs

### 2026-03-25: End-of-Session Integration — March 25 Plan Merged Into March 24 Daily Plan

**Status:** ✅ COMPLETE  
**Task:** Merge nearly all March 25 planned work (which shipped early during March 24 session) into daily plan records

**Context:**
Wayne ran a highly productive evening session (extended March 24) and executed ~95% of the March 25 daily plan before the next day. This created a planning situation: maintain two parallel plans, or merge the completed work into March 24 and leave March 25 with only the 3 items that remain unfinished.

**Decision Made:** Merge early completion into daily plan structure
- March 24 plan: Added new section "🚀 BONUS: March 25 Work Shipped Early" documenting all completed P0 items, tests, documentation, and bug fixes
- March 25 plan: Replaced detailed P0-A/B/C deliverables (all complete) with concise status section + clean session statistics
- Maintained "3 remaining items" (unfinished tasks) front-and-center for March 26 planning

**Outcomes Documented:**
- P0-A: Engine code review complete (172 pre-refactor tests, 2,670 post-refactor assertions, 0 regressions)
- P0-B: Meta-check V1 shipped (19/144 rules, 0 false positives)
- P0-C: Meta-check V2 shipped (159/160 rules, full meta-type coverage)
- P1 documentation: event-hooks.md + effects-pipeline.md v3.0 complete
- Deployment: March 24 features live on web server
- Playtest bugs: 7 issues filed and fixed same evening (#167–173)
- **Total:** 40+ issues closed, 3,342 tests passing

**Key Insight:**
When a team executes work significantly ahead of schedule, the daily plan documents should reflect *what actually shipped* rather than *what was planned*. This keeps the archive accurate and helps future sessions understand velocity and decision history.

**Files Updated:**
- `plans/2026-03-24-daily-plan.md` — Added "🚀 BONUS: March 25 Work Shipped Early" section (full detail of P0-A/B/C, documentation, deployment, bug fixes)
- `plans/2026-03-25-daily-plan.md` — Replaced old detailed P0 sections with concise status + statistics; left 3 unfinished items for March 26

---
