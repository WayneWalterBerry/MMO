### 2026-03-25T13:25:00Z: D-PARSER-PHASE1-DEFAULTS
**By:** Squad Coordinator (defaults — Wayne to review)
**Scope:** Parser improvement plan decision points D1-D5

**Decisions (using plan recommendations as defaults):**
- D1: Hybrid scoring 70% BM25 / 30% soft cosine (start lexical-heavy, tune empirically)
- D2: Top 2-3 synonyms per term (conservative, expand if gains warrant)
- D3: Both soft cosine AND MaxSim — A/B test, keep winner
- D4: Conditional — if Phase 2 exceeds 82%, continue to Phase 3; else stop
- D5: Inverted index in Phase 2 (wait for soft cosine profile data)

**Why:** Wayne is away, implementation needs to proceed. All defaults match Frink's recommendations.
**Affects:** Smithers (parser implementation), Nelson (test verification)