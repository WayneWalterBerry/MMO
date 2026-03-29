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

### 2025-07-18: Mr. Beast Research for Wyatt's World

**Task:** Research Mr. Beast (Jimmy Donaldson) content, characters, challenges, aesthetic, and educational angles for a themed text adventure world for Wyatt (age 10).

**Deliverable:** `projects/wyatt-world/research-mrbeast.md` — comprehensive research brief covering 7 topics: biography, famous challenges, visual aesthetic, crew/characters, catchphrases/language, games/products, and educational angles. Includes vocabulary list, character reference sheet, 10 room concept seeds, and design recommendations.

**Key findings:**
- MrBeast's content maps cleanly to text adventure mechanics: inventory puzzles (spending sprees), endurance/patience rooms (last to leave), multi-step scavenger hunts, risk-vs-reward decision points, and rule-following challenges (Squid Game recreations).
- The "Beast Gang" (Chandler, Karl, Nolan, Tareq) each have distinct personalities that translate well to NPC archetypes: Chandler = comedic helper, Karl = enthusiastic guide, Nolan = rival/challenger, Tareq = tool/hint provider.
- Educational angles are strong: money math (counting big prizes, budgets), reading comprehension (clue-reading, following instructions), strategy/decision-making (risk vs reward), and teamwork/values (philanthropy themes).
- 3rd-grade reading level vocabulary aligns with MrBeast's own language style — simple, direct, action-oriented sentences with high energy.
- The bright, color-coded warehouse aesthetic translates well to room descriptions even in text form — color = function is a consistent design language.
