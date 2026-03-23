# Tier 2 Embedding-Based Parser Implementation Plan

**Author:** Chalmers (Project Manager)  
**Date:** 2026-03-20  
**Status:** Ready for Approval  
**Related Decisions:** D-19 (Parser approach), D-17 (Build-time LLM)

---

## Goal

Build a deterministic, GPU-free embedding-based fallback parser that handles 12% of command variations the rule-based Tier 1 system misses. This adds semantic understanding without the size/speed/cost penalty of generative models. By encoding ~2,000 canonical command phrases into 384-dimensional vectors at build time, we can match player input against known patterns in 10–30ms, enabling natural language flexibility while keeping the system lightweight and updatable.

---

## What We Have

**Tier 1: Rule-Based Parser (COMPLETE)**
- Location: `src/engine/loop/init.lua` (tokenizer) + `src/engine/verbs/init.lua` (verb dispatch)
- Coverage: ~85% of standard commands
- Method: First word = verb, rest = noun, lowercase both, search visible scope
- Latency: <1ms
- Status: ✅ Working and deployed

This system will remain unchanged. Tier 2 is a **fallback only** — if Tier 1 finds no match, we hand off to embedding search.

---

## What We Need to Build

### Core Strategy: Pre-Computed Embedding Index

Instead of running GTE-tiny inference on every variation, we:
1. **Pre-compute** vectors for ~2,000 canonical phrases at build time (5 seconds)
2. **Store** them as a JSON lookup table (~400KB compressed, ~3MB raw)
3. **Load** into browser memory at game start (negligible)
4. **Match** incoming player input by encoding it (10ms) and computing cosine similarity (1ms)

### Model & Dimensions

| Property | Value |
|----------|-------|
| **Model** | GTE-tiny (ONNX INT8 quantized) |
| **Source** | thenlper/gte-tiny on HuggingFace |
| **Dimensions** | 384-dimensional embeddings |
| **Size** | ~5.5MB ONNX model (loaded once at startup) |
| **Runtime** | ONNX Runtime Web (WASM, no GPU needed) |
| **Inference Latency** | 10–30ms per phrase |

### Canonical Phrase Index

- **Count:** ~2,000 phrases covering all verb + object combinations
- **Format:** JSON lookup table (phrase ID → 384-dim float array)
- **Storage:** `src/assets/parser/embedding-index.json.gz` (compressed)
- **Uncompressed Size:** ~3MB (2,000 phrases × 384 floats × 4 bytes)
- **Compressed Size:** ~400KB
- **Update Cadence:** Regenerated when verb/object definitions change (part of build pipeline)

### Parity with Current System

The embedding index must cover:
- All defined verbs (look, take, drop, open, close, examine, talk, etc.)
- All relevant objects in game (items, NPCs, furniture, surfaces, containers)
- Contextual variations (e.g., "take the sword", "pick up sword", "grab it", "get the thing")
- Common abbreviations and synonyms aligned with design intent

---

## Implementation Phases

### Phase 1: Training Data Generation (Week 1)
**Owner:** LLM Pipeline Lead  
**Dependencies:** None  
**Deliverable:** CSV of ~2,000 canonical phrases

1. Parse verb definitions from `src/verbs/` and object definitions from game data
2. Invoke OpenAI GPT-4 to generate command variations (5–10 per verb + object combo)
3. De-duplicate and filter to canonical set (~2,000 phrases)
4. Output CSV: `phrase_id`, `phrase_text`, `verb`, `object_class`, `context`
5. **Script Location:** `scripts/generate_parser_data.py`
6. **Cost:** ~$0.05, ~30 seconds execution time
7. **QA:** Manual review of 50–100 random samples for quality

**Acceptance Criteria:**
- ✅ CSV generated with 2,000+ phrases
- ✅ All defined verbs represented
- ✅ No duplicates or near-duplicates
- ✅ Phrases are natural-sounding (QA spot check)

---

### Phase 2: Embedding Index Build (Week 1)
**Owner:** ML/Pipeline Engineer  
**Dependencies:** Phase 1 (training data CSV)  
**Deliverable:** `src/assets/parser/embedding-index.json.gz`

1. Download GTE-tiny ONNX model (5.5MB, cached in `models/`)
2. Load training CSV from Phase 1
3. Encode all 2,000 phrases using GTE-tiny (5 seconds, CPU-only)
4. Build lookup table: `{ "phrase_id": [float, float, ...], ... }`
5. Gzip compress to ~400KB
6. Output to `src/assets/parser/embedding-index.json.gz`
7. **Script Location:** `scripts/build_embedding_index.py`
8. **Runtime:** ~10 seconds, CPU-only, no dependencies beyond GTE-tiny

**Acceptance Criteria:**
- ✅ Index contains exactly 2,000 vectors
- ✅ All vectors are 384-dimensional
- ✅ File compresses to <500KB
- ✅ Loadable in <100ms in browser

**Validation:**
- Spot-check: decode 5 random vectors, verify cosine similarity to semantically similar phrases is high (>0.8)

---

### Phase 3: Runtime Integration — Browser & WASM (Week 2)
**Owner:** Runtime Engineer  
**Dependencies:** Phase 2 (embedding index), existing Wasmoon setup  
**Deliverable:** TypeScript module `src/runtime/parser/embedding-matcher.ts`

1. **Module Structure:**
   ```
   src/runtime/parser/
   ├── embedding-matcher.ts     (main class)
   ├── onnx-wrapper.ts          (ONNX Runtime Web loader)
   └── cosine-similarity.ts     (similarity compute)
   ```

2. **embedding-matcher.ts responsibilities:**
   - Load GTE-tiny ONNX model on startup (5.5MB, via ONNX Runtime Web)
   - Load embedding index JSON from assets (400KB)
   - Expose API: `matchCommand(playerInput: string) -> SimilarityResult[]`
   - Compute cosine similarity against all 2,000 vectors
   - Return top 5 matches with scores
   - Cache encoded input for disambiguation flow

3. **ONNX Runtime Web Integration:**
   - Use existing `node_modules` or CDN for `onnxruntime-web`
   - Initialize on game startup (one-time cost)
   - Verify no conflicts with Wasmoon (both use WASM, should coexist)

4. **API Contract:**
   ```typescript
   interface SimilarityResult {
     phraseId: string;
     phraseText: string;
     score: number;           // 0.0–1.0 cosine similarity
     verb: string;
     objectClass: string;
   }
   
   class EmbeddingMatcher {
     async init(): Promise<void>;                    // Load model + index
     async matchCommand(input: string): Promise<SimilarityResult[]>;
   }
   ```

5. **Error Handling:**
   - If ONNX model fails to load → log warning, disable Tier 2 (Tier 1 only)
   - If index load fails → same graceful degradation
   - If inference times out > 100ms → return empty, fall through to "I don't understand"

**Acceptance Criteria:**
- ✅ Module initializes in <500ms
- ✅ Encoding + similarity for one phrase: <30ms
- ✅ Top 5 results returned ordered by score
- ✅ No conflicts with Wasmoon/PWA deployment

---

### Phase 4: Game Loop Integration (Week 2)
**Owner:** Game Engine Lead  
**Dependencies:** Phase 1 (data), Phase 3 (runtime module)  
**Deliverable:** Modified fallback chain in `src/engine/loop/init.lua`

1. **Fallback Chain (current):**
   ```lua
   Input → Tier 1 Rule-Based Parse
        ↓ (no match)
        ↓ → "I don't understand"
   ```

2. **New Fallback Chain:**
   ```lua
   Input → Tier 1 Rule-Based Parse
        ↓ (no match)
        ↓ → Tier 2 Embedding Match (via TypeScript bridge)
        ↓ (score > 0.75)
        ↓ → Execute best match
        ↓ (score 0.50–0.75)
        ↓ → Disambiguate ("Did you mean...?")
        ↓ (score < 0.50)
        ↓ → "I don't understand"
   ```

3. **Implementation Details:**
   - Add Lua-to-TypeScript bridge in `src/engine/loop/init.lua`
   - On Tier 1 miss, invoke `EmbeddingMatcher.matchCommand()`
   - Extract verb and object from top match
   - Execute via existing verb dispatch (unchanged)
   - On ambiguity (0.50–0.75): display top 3 options, prompt player

4. **Edge Cases:**
   - Empty input → skip Tier 2
   - Very long input (>100 chars) → truncate or skip
   - Special characters → preprocess same as Tier 1
   - Already-matched Tier 1 commands → skip Tier 2 (cheap early exit)

5. **Logging:**
   - Log all Tier 2 invocations with input, top score, execution path
   - Telemetry: track % of commands hitting each tier (goal: 85% Tier 1, 12% Tier 2, <3% fallthrough)

**Acceptance Criteria:**
- ✅ Fallback chain integrated, no Tier 1 regressions
- ✅ Tier 2 only invoked after Tier 1 miss
- ✅ Scores > 0.75 execute reliably
- ✅ Disambiguation UI shows top 3 matches
- ✅ Telemetry logs captured

---

### Phase 5: CI/CD Automation (Week 3)
**Owner:** DevOps / Build System Lead  
**Dependencies:** Phase 1 & 2 scripts  
**Deliverable:** GitHub Actions workflow

1. **Trigger:** On commit to `src/verbs/` or game object definitions
2. **Workflow Steps:**
   - Checkout code
   - Run `scripts/generate_parser_data.py` (Phase 1)
   - Run `scripts/build_embedding_index.py` (Phase 2)
   - Upload artifact: `src/assets/parser/embedding-index.json.gz`
   - Commit updated index to `main` (or create PR for review)

3. **Workflow File:** `.github/workflows/rebuild-parser-embeddings.yml`
4. **Manual Trigger:** Developers can manually trigger rebuild via GitHub UI
5. **Cost Control:**
   - OpenAI LLM called only when verb/object definitions change
   - Cache model + dependencies to avoid re-download
   - Estimate cost/run: ~$0.05

4. **Notifications:**
   - Slack notification on success/failure
   - Link to updated index in commit message

**Acceptance Criteria:**
- ✅ Workflow triggers automatically on verb/object changes
- ✅ Embedding index rebuilt in <2 minutes
- ✅ New index uploaded and committed
- ✅ No manual steps required after push

---

### Phase 6: Testing & Tuning (Week 3)
**Owner:** QA Lead  
**Dependencies:** All prior phases  
**Deliverable:** Test suite + tuning report

1. **Test Suite Location:** `tests/parser/embedding-matcher.test.ts`

2. **Test Cases:**
   - ✅ **Exact Match:** "take sword" matches phrase "take the sword" (score > 0.9)
   - ✅ **Synonym:** "grab weapon" matches "take sword" (score > 0.75)
   - ✅ **Abbreviation:** "get it" matches "take the sword" in context (score > 0.75)
   - ✅ **Misspelling Resistance:** "tke swod" should fail or disambiguate (score < 0.75)
   - ✅ **Edge Cases:**
     - Empty input → no crash
     - Very long input → handled gracefully
     - Special characters → no crash
   - ✅ **Accuracy Threshold:** 90%+ of test cases score correctly
   - ✅ **Latency:** All queries <100ms, median <30ms
   - ✅ **Memory:** Model + index load in <500ms, <10MB total

3. **Manual QA (50–100 commands):**
   - Test 2–3 commands per verb category (look, take, drop, open, examine, talk, go, etc.)
   - Verify natural language variations work
   - Check disambiguation flow (0.5–0.75 scores)
   - Confirm "I don't understand" triggers for nonsense input

4. **Tuning:**
   - If accuracy < 90%, iterate on training data (Phase 1)
   - If latency > 100ms, profile ONNX inference vs. similarity compute
   - If memory > 10MB, consider pruning index or model quantization
   - Document any score threshold adjustments (currently: 0.75 → execute, 0.50–0.75 → disambiguate, <0.50 → fail)

5. **Performance Targets:**
   - Latency: p50 <30ms, p99 <100ms
   - Accuracy: 90%+ on canonical commands
   - Memory: <10MB (model + index in memory)
   - Startup: <500ms to load + initialize

**Acceptance Criteria:**
- ✅ Test suite passes (90%+ accuracy)
- ✅ Latency meets targets
- ✅ Manual QA sign-off
- ✅ Disambiguation flow works intuitively

---

## Dependencies & Critical Path

### Dependency Graph

```
Phase 1 (Training Data)
  ↓
Phase 2 (Embedding Index) → CI/CD (Phase 5)
  ↓
Phase 3 (Runtime Module) ← Phase 2
  ↓
Phase 4 (Game Loop) ← Phase 3
  ↓
Phase 6 (Testing) ← All phases
```

### Critical Path
1. **Phase 1 → Phase 2** (must complete sequentially, ~5 min total)
2. **Phase 3** (parallel to Phase 1/2, can start immediately, depends only on Phase 2 for integration testing)
3. **Phase 4** (depends on Phase 3)
4. **Phase 5** (automation, can start after Phase 2 scripts are written)
5. **Phase 6** (final validation, depends on all)

### Blockers & Assumptions
- ✅ No blockers from active development (Tier 1 is complete)
- ✅ ONNX Runtime Web must run alongside Wasmoon (no known conflicts; both WASM-based)
- ✅ Verb/object definitions must be stable (or Phase 1 data becomes stale)
- ✅ OpenAI API access required for Phase 1 (cost: ~$0.05 per rebuild)

---

## Risks

### High Priority

1. **ONNX Runtime Web + Wasmoon Conflict**
   - **Risk:** Both run WASM; potential thread/context issues in browser
   - **Mitigation:** Early integration test (Phase 3 includes this); investigate compatibility before full rollout
   - **Contingency:** If conflict found, consider ONNX Runtime Node.js for build-time encoding + ship pre-encoded lookup table only (no runtime inference)

2. **Embedding Index Becomes Stale**
   - **Risk:** If verbs/objects change but CI/CD doesn't trigger, index mismatch
   - **Mitigation:** Phase 5 automation ensures rebuild on changes; document verb/object file paths to watch
   - **Contingency:** Ship versioned indices; fallback to Tier 1 if index version mismatch detected

3. **Accuracy Below 90%**
   - **Risk:** Poor training data or model mismatch; Tier 2 hurts UX instead of helping
   - **Mitigation:** Phase 1 includes QA spot-check; Phase 6 includes full test suite
   - **Contingency:** Lower accuracy threshold to 85%, increase manual disambiguations (0.6–0.75 → ask), or skip Tier 2 altogether and remain on Tier 1 only

### Medium Priority

4. **Model Size or Load Time Unexpected**
   - **Risk:** ONNX model or index larger/slower than estimated
   - **Mitigation:** Prototype Phase 3 early to validate size/latency assumptions
   - **Contingency:** Prune index to 1,000 phrases or use lighter model variant

5. **Player Input Encoding Latency Exceeds Budget**
   - **Risk:** 10–30ms estimate is optimistic; actual inference slower in low-end browsers
   - **Mitigation:** Profile on target devices (modern browsers + PWA conditions); optimize ONNX settings
   - **Contingency:** Cache recent encodings, batch requests, or accept longer latency with user tolerance research

### Low Priority

6. **Tier 1 Regression**
   - **Risk:** Integration with Tier 2 accidentally breaks Tier 1
   - **Mitigation:** Phase 4 includes regression tests; Tier 1 unchanged structurally
   - **Contingency:** Roll back fallback chain logic (1-line fix)

---

## Open Questions for Wayne

1. **Accuracy Threshold:**
   - Currently planned: >0.75 → execute, 0.50–0.75 → disambiguate, <0.50 → fail
   - Should we be more lenient (>0.65) or stricter (>0.85) to start?
   - Acceptable error rate? (e.g., 1 in 20 commands misinterpreted?)

2. **Disambiguation UX:**
   - When score is 0.50–0.75, show "Did you mean...?" with top 3 options?
   - Or use context (recent commands, current room, inventory) to pick best single match?

3. **Training Data Volume:**
   - 2,000 phrases estimated; does this cover all verb + object combos you anticipate?
   - Or should we generate 5,000–10,000 (more comprehensive, larger index)?

4. **Update Cadence:**
   - Rebuild index every time verbs/objects change (automated)?
   - Or batch changes and rebuild weekly/monthly?

5. **Tier 3 (Generative SLM):**
   - Should we leave room in architecture for optional Tier 3 (Qwen2.5, ~350MB)?
   - Or commit to Tier 1 + Tier 2 as final?

6. **Fallback on Error:**
   - If ONNX model fails to load → silently degrade to Tier 1 only (recommended)?
   - Or fail game startup entirely?

---

## Success Metrics

- ✅ **Coverage:** Tier 2 handles 12%+ of commands Tier 1 misses (telemetry post-launch)
- ✅ **Latency:** Embedding lookup <100ms p99 (median ~30ms)
- ✅ **Accuracy:** 90%+ correct interpretation on canonical test set
- ✅ **Size:** Index <500KB, model <10MB in memory
- ✅ **Maintenance:** Index rebuildable in <2 minutes on code change
- ✅ **UX:** Players perceive parser as "smarter" (qualitative feedback)
- ✅ **No Regressions:** Tier 1 remains at 85% coverage, no false positives

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
| **Total** | **~10 working days** | **6 people (parallel tracks)** | **Week 1** | **Week 4 Mon** |

**Critical Path:** Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 6 (~6 days serial, rest parallelizable)

---

## Next Steps (After Approval)

1. **Wayne Review:** Approve plan, answer open questions
2. **Chalmers:** Create JIRA/GitHub issues for each phase (6 total)
3. **Team Assignment:** Allocate owners to phases (above timeline assigns tentatively)
4. **Week 1 Kickoff:** LLM Pipeline Lead starts Phase 1 on Monday

---

## References

- **Research:** `resources/research/architecture/parser-distillation.md` (main recommendation)
- **Tier 3 (Optional):** `resources/research/architecture/local-slm-parser.md`
- **Architecture Context:** `resources/research/architecture/parser-pipeline-and-sandbox-security.md`
- **Current Tier 1:** `src/engine/loop/init.lua`, `src/engine/verbs/init.lua`
- **Decision D-19:** Parser approach (embedding vs. SLM, pending Wayne approval)
- **Decision D-17:** Build-time LLM (no per-player cost)
