# D-SLM-LAZY-LOAD

**Author:** Gil (Web Engineer)
**Date:** 2026-03-25
**Issue:** #210
**Branch:** `squad/210-slm-lazy-load`

## Decision

Embedding vectors are now extracted at build time into a separate `embedding-vectors.json.gz` file (~4.8 MB) and lazy-loaded after game boot via IndexedDB caching. The game starts immediately with BM25 scoring; vectors become available asynchronously if/when needed.

## Architecture

1. Build produces `dist/embedding-vectors.json.gz` from `resources/archive/embedding-index-full.json`
2. `VECTORS_VERSION` (SHA256 hash) stamped into `bootstrapper.js` for cache invalidation
3. After boot, JS fetches vectors → caches in IndexedDB (`mmo-slm-cache`) → injects into Lua VFS
4. Vectors accessible at `_G.__VFS["src/assets/parser/embedding-vectors.json"]`

## Who Should Know

- **Bart/Smithers:** Vectors are now available in VFS after lazy-load. If you implement soft-cosine scoring in `embedding_matcher.lua`, check `_G.__VFS["src/assets/parser/embedding-vectors.json"]` — it will be `nil` initially and populated async. Format: `{"version":"...","count":N,"vectors":[[float...],...]}` where index i = phrase id i+1.
- **Nelson:** No test changes needed. The lazy-load is web-only (JS/IndexedDB). Engine tests are unaffected.
- **Gil (self):** `web/extract-vectors.py` is a new build dependency — requires Python. If Python unavailable, build continues without vectors. The `embedding-vectors.json.gz` file needs to be deployed alongside `engine.lua.gz`.

## Key Constraint

Python is now a build-time dependency for vector extraction. If this is problematic, the extraction could be rewritten in pure PowerShell (slower, ~30-60s vs ~9s).
