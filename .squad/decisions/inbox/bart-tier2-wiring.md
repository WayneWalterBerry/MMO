# Decision: Tier 2 Parser Wiring (Lua REPL)

**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Implemented  
**Impact:** Parser, game loop, runtime architecture

## Summary

Tier 2 (embedding-based) parser is now wired into the Lua game loop. When Tier 1 (exact verb dispatch) fails, the loop falls back to Tier 2 phrase-text similarity matching. If Tier 2 also misses (score ≤ 0.40), the command fails with diagnostic output showing the input, best match, and score.

## Key Decisions

1. **No ONNX in Lua.** The embedding index is loaded as a phrase dictionary. Matching uses Jaccard token-overlap similarity, not vector cosine similarity. Real embedding similarity comes later in the browser via ONNX Runtime Web.

2. **No fallback past Tier 2.** If the matcher misses, the command fails visibly. Diagnostic mode is on by default during playtesting.

3. **Embedding index serves dual purpose:**
   - Lua REPL: phrase dictionary (text matching, vectors ignored)
   - Browser runtime (future): vector index (ONNX Runtime Web cosine similarity)

4. **Index trimmed via `--max-variations` flag:** Round-robin synonym distribution ensures verb diversity per combo. 29,582 → 4,337 phrases, gzip 34MB → 4.9MB.

5. **Threshold 0.40** for Tier 2 acceptance. Below this, matches tend to be wrong-verb. Tunable via `parser.THRESHOLD` in `src/engine/parser/init.lua`.

## Files

- `src/engine/parser/init.lua` — Tier 2 module entry point
- `src/engine/parser/embedding_matcher.lua` — Jaccard phrase matcher
- `src/engine/parser/json.lua` — Minimal JSON decoder for Lua
- `src/engine/loop/init.lua` — Tier 2 fallback wired after Tier 1
- `src/main.lua` — Parser module loaded at startup
- `scripts/generate_parser_data.py` — `--max-variations` flag added

## Team Impact

- **Comic Book Guy:** The ~400 command variation matrix can now be validated against Tier 2 matching. Run the game and test variations to find coverage gaps.
- **QA:** Diagnostic output shows every Tier 2 invocation — use it to build a test matrix of what matches and what doesn't.
- **Future:** When browser runtime is implemented, the same embedding-index.json gets loaded by ONNX Runtime Web for real vector similarity. The Lua Jaccard matching is a stopgap.
