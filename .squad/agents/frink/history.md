# Frink — History (Summarized)

## Project Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO — Self-modifying universe code in Lua
- **Role:** Technical researcher and architect

## Core Context

**Agent Role:** Research and analysis specialist providing architectural guidance and technical feasibility studies.

**Research Delivered (2026-03-18 to 2026-03-20):**
1. **Text Adventure Architecture** — Parent-child containment tree, rooms as graph nodes, standard verb-noun pipeline
2. **Lua as Primary Language** — Homoiconicity, prototype inheritance, production pedigree (200+ games), small runtime
3. **Multiverse Architecture** — Per-universe Lua VMs, event sourcing, copy-on-write, procedural generation
4. **Self-Modifying Code & Sandbox Security** — 6 sandbox layers, 8 threat classes mitigated
5. **Parser Pipeline** — Classic IF pipeline, three-tier hybrid (rule-based + embedding + optional SLM)

**Key Reports:** 5 architecture reports, local SLM parser, parser distillation, PWA/Wasmoon, CYOA analysis (14 files), competitive analysis (16 competitors), MUD verb research

## Archives

- `history-archive-2026-03-20T22-40Z-frink.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): all research deliverables, architecture reports, parser studies, PWA feasibility, CYOA analysis, competitive landscape, MUD verbs

## Recent Updates

### 2026-03-29: Parser D1-D4 Decision Research

**Task:** Research and decide 4 blocking parser technical decisions for Wayne.

**Decisions delivered:**
- D1: 70/30 BM25-heavy, two-stage pipeline (BM25 retrieves top-50, MaxSim re-ranks)
- D2: 2-3 synonyms per noun (conservative) — Lu et al. research, drift risk above 3
- D3: MaxSim first, soft cosine as documented fallback — simpler, debuggable, equivalent at 2-4 token scale
- D4: 93% target (~137/147), then beta + reassess with real player data

**Files updated:** `projects/parser-improvements/board.md`, `.squad/decisions/inbox/frink-parser-scoring.md`

## Learnings

- BM25 is remarkably robust for short queries (2-4 tokens). At this query length, lexical matching dominates and semantic re-ranking provides marginal gains only on ties.
- MaxSim and soft cosine produce near-identical rankings for 2-4 token queries against 3-4 token phrases. The O(n²) vs O(n×m) complexity debate is irrelevant at this scale — implementation simplicity and debuggability are the real differentiators.
- Conservative synonym expansion (2-3 per term) is backed by Lu et al. (2015) and validated by the project's own verb synonym system. Aggressive expansion introduces semantic drift that hurts precision more than it helps recall.
- The 13 remaining benchmark failures (91.2%) are predominantly disambiguation and false-positive issues, not missing-synonym issues. This means re-ranking improvements will yield more gains than vocabulary expansion.
- Real player data from beta playtesting will be 10x more valuable than synthetic benchmarks for guiding the 93% → 95% push.
