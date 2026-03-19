# Project Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO
- **Created:** 2026-03-18

## Core Context

Agent Chalmers initialized as Project Manager for the MMO project.

## Recent Updates

📌 Team initialized on 2026-03-18

## Learnings

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
