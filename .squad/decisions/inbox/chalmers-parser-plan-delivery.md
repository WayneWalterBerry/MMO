# Decision: Tier 2 Embedding Parser Implementation Plan Approved for Review

**Author:** Chalmers (Project Manager)  
**Date:** 2026-03-20  
**Status:** Ready for Wayne Review  
**Related Decisions:** D-19 (Parser approach), D-17 (Build-time LLM)  
**Decision Authority:** Level 2 (Architecture-affecting, requires Wayne sign-off)

---

## Summary

Created comprehensive implementation plan for Tier 2 embedding-based parser fallback system. Plan covers all 6 phases needed to integrate GTE-tiny ONNX embeddings into game loop, with ~10 working days timeline and clear dependency graph.

**Deliverable:** `plan/llm-slm-parser-plan.md` (445 lines, committed to main)

---

## Key Decisions Embedded in Plan

### 1. **Embedding Model Choice: GTE-tiny ONNX INT8**
- 5.5MB model size (vs. 350MB for SLM)
- No GPU required (ONNX Runtime Web + WASM)
- 10–30ms inference latency per phrase
- 384-dimensional vectors

**Rationale:** Balances semantic understanding with PWA constraints (size, latency, no GPU). Pre-computed vectors eliminate runtime LLM cost.

### 2. **Index Strategy: Pre-Computed, Updatable**
- ~2,000 canonical phrases encoded at build time
- JSON lookup table (~400KB compressed)
- Regenerated automatically when verbs/objects change
- No model retraining required

**Rationale:** Decouples content changes from model tuning. Index rebuild takes <2 min; retraining would take hours.

### 3. **Fallback Chain: Tier 1 → Tier 2 → Fail**
- Tier 1 (rule-based) remains at 85% coverage, unchanged
- Tier 2 only invoked after Tier 1 miss
- Threshold: 0.75 score → execute, 0.50–0.75 → disambiguate, <0.50 → "I don't understand"

**Rationale:** Preserves existing reliability, zero Tier 1 regressions possible.

### 4. **Test Coverage Target: 90%+ Accuracy**
- Canonical command set + edge cases
- Manual QA + automated test suite
- Latency targets: p50 <30ms, p99 <100ms

**Rationale:** Threshold protects UX; Tier 2 must improve parser, not break it.

### 5. **CI/CD Automation: GitHub Actions on Verb/Object Change**
- Automatic rebuild of embedding index
- LLM call triggered only on content changes
- Cost ~$0.05 per rebuild

**Rationale:** Keeps index in sync with game content; eliminates manual steps.

---

## Open Questions for Wayne (Requires Input)

1. **Accuracy Threshold:**
   - Plan assumes 0.75 → execute; should this be 0.65 (lenient) or 0.85 (strict)?
   - Acceptable misinterpretation rate? (e.g., 1 in 20 commands?)

2. **Training Data Volume:**
   - Plan estimates 2,000 phrases; sufficient for verb+object coverage?
   - Should we generate 5,000–10,000 for more robustness?

3. **Disambiguation UX:**
   - When score is 0.50–0.75: show "Did you mean...?" with top 3 options?
   - Or use context (recent commands, room, inventory) to pick best match?

4. **Tier 3 (Optional Generative SLM):**
   - Should architecture leave room for future Tier 3 (Qwen2.5, ~350MB)?
   - Or commit to Tier 1 + Tier 2 as final solution?

5. **Fallback on Error:**
   - If ONNX model fails to load at startup: silently degrade to Tier 1 only (recommended)?
   - Or fail game startup entirely?

---

## Risk Mitigation

| Risk | Severity | Mitigation |
|------|----------|-----------|
| ONNX Runtime Web + Wasmoon conflict | HIGH | Early integration test (Phase 3); investigate before full rollout |
| Embedding index becomes stale | HIGH | Phase 5 automation + version checking |
| Accuracy < 90% | HIGH | Phase 1 QA + Phase 6 full test suite; contingency: lower threshold or skip Tier 2 |
| Model/index size larger than estimated | MEDIUM | Profile Phase 3; prune index if needed |
| Inference latency >100ms | MEDIUM | Cache encodings; batch requests; accept longer latency with tolerance research |
| Tier 1 regression | LOW | Regression tests in Phase 4 |

---

## Success Metrics

- ✅ Tier 2 handles 12%+ of Tier 1 misses (telemetry post-launch)
- ✅ Latency <100ms p99, median ~30ms
- ✅ Accuracy 90%+ on canonical test set
- ✅ Index <500KB, model <10MB memory
- ✅ Index rebuildable <2 min on code change
- ✅ Players perceive parser as "smarter"
- ✅ Zero Tier 1 regressions

---

## Timeline

| Phase | Duration | Owner | Start | End |
|-------|----------|-------|-------|-----|
| 1 | 1 day | LLM/Pipeline | Week 1 Mon | Week 1 Tue |
| 2 | 1 day | ML Engineer | Week 1 Tue | Week 1 Wed |
| 3 | 3 days | Runtime Engineer | Week 1 Wed | Week 2 Fri |
| 4 | 2 days | Game Engine Lead | Week 2 Mon | Week 2 Tue |
| 5 | 2 days | DevOps | Week 2 Wed | Week 3 Thu |
| 6 | 3 days | QA Lead | Week 3 Fri | Week 4 Mon |
| **Total** | **~10 working days** | **6 people (parallel)** | **Week 1** | **Week 4 Mon** |

Critical path: Phase 1→2→3→4→6 (~6 days serial)

---

## Next Steps

1. **Wayne Review:** Read plan, answer open questions above
2. **Chalmers:** Once approved, create JIRA/GitHub issues for each phase
3. **Team Assignment:** Allocate owners + schedule
4. **Week 1 Kickoff:** LLM Pipeline Lead starts Phase 1

---

## References

- **Full Plan:** `plan/llm-slm-parser-plan.md`
- **Research:** `resources/research/architecture/parser-distillation.md` (main recommendation, 541 lines)
- **SLM Option:** `resources/research/architecture/local-slm-parser.md` (optional Tier 3, 389 lines)
- **Architecture:** `resources/research/architecture/parser-pipeline-and-sandbox-security.md` (1600 lines)
- **Decision D-19:** Parser approach (embedding vs. SLM, pending Wayne approval)
- **Decision D-17:** Build-time LLM (no per-player cost model)
- **Current Tier 1:** `src/engine/loop/init.lua`, `src/engine/verbs/init.lua`

---

## Recommendation

**APPROVE.** Plan is concrete, actionable, and de-risks the embedding approach through staged integration + comprehensive testing. All blockers identified and mitigated. Parallel tracks maximize efficiency. Ready for Week 1 kickoff pending Wayne's answers to open questions.
