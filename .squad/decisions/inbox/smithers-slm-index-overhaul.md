# Decision: SLM Embedding Index Overhaul

**Author:** Smithers (UI Engineer)
**Date:** 2026-07-21
**Issue:** #174 (Sections 1-4)
**Status:** Implemented

## D-SLM-INDEX-OVERHAUL

### What Changed

1. **embedding_matcher.lua upgraded to BM25 scoring** — The matcher now uses BM25 (IDF-weighted) scoring with an inverted index for fast candidate retrieval. Jaccard is kept as automatic fallback when bm25_data.lua is missing. Synonym expansion runs before typo correction.

2. **bm25_data.lua and synonym_table.lua restored to main** — These files existed on feature branches but were never merged. They are now committed on main and are loaded with pcall (graceful degradation if missing).

3. **56 new objects added to embedding index** — All objects in `src/meta/objects/` now have phrase coverage (~117 phrases each). Index grew from 4,579 → 11,131 phrases, 883KB (still slim, no vectors).

4. **New synonym mappings** — gimme→get, hold→get, lift→get, use→ignite, peer→look. Removed check→examine to preserve "check out" → look routing.

5. **prefer_base_state tiebreaker** — Extracted to a clean function. When BM25/Jaccard scores tie, base-state nouns (e.g., "match") are preferred over state variants (e.g., "match-lit").

### Who Should Know

- **Flanders (objects):** When you add new objects to `src/meta/objects/`, they need corresponding entries in the embedding index. Run `python scripts/build_embedding_index.py --slim` to regenerate, or manually add phrases.
- **Moe (rooms):** No room changes needed. Objects are indexed by their display name, not their file path or room location.
- **Nelson (tests):** 51 new tests in `test/parser/test-issue-174-embedding-overhaul.lua`. Existing benchmark tests (if restored from feature branches) should also pass.
- **Gil (web):** Section 5 (web lazy-load) is separate. The slim index is the same format — no web-side changes needed for Sections 1-4.
- **Bart (engine):** No engine API changes. The matcher's public API (`new()`, `match()`) is unchanged. BM25/synonym modules load with pcall — zero coupling.
