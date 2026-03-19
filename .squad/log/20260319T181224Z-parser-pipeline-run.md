# Session Log — Parser Pipeline Completion (2026-03-19T18:12:24Z)

**Agent:** Bart  
**Task:** End-to-end parser pipeline (Phase 1 & 2)

## Summary
Parser pipeline completed successfully. 29,582 training pairs generated covering 54 verbs and 39 objects. Embedding index built with GTE-tiny (384-d). Model reference fixed (TaylorAI/gte-tiny). Index size: 104.1MB raw, 32.5MB gzipped.

## Key Results
- Training CSV: 1.6MB (29,582 pairs)
- Embedding index: 104.1MB raw, 32.5MB gzipped
- All 54 verbs covered (31 canonical + 23 aliases)
- Model: GTE-tiny (384 dimensions)

## Directives Applied
1. **No fallback past Tier 2** — misses fail visibly
2. **Trim & test empirically** — size acceptable for browser, ready for play testing
