# Decision: Strip Embedding Vectors from Web Bundle

**Author:** Smithers (UI Engineer)
**Date:** 2025-07-24
**Status:** Implemented

## Context

The web playtest build at waynewalterberry.github.io/play/ hung at "Loading Game Engine" and never finished. Root cause: the 16 MB embedding-index.json (4337 phrases × 384-dim float vectors) was bundled raw. Fengari's pure-Lua JSON decoder couldn't parse it in reasonable time.

## Decision

`build-bundle.ps1` now strips the `embedding` field from each phrase during bundling. Only `id`, `text`, `verb`, and `noun` are kept. The vectors are documented as unused at runtime — the Lua matcher uses Jaccard token-overlap, not vector similarity.

**Impact:** Bundle shrinks from 16.7 MB → 990 KB. Page should load in seconds, not hang forever.

## Related

- BUG-049: Added "pry" as verb synonym for "open" (verbs/init.lua + preprocess.lua). Also added "pry open X" and "use crowbar on X" compound phrases.

## Risk

Tier 2 parser works identically — it never read the embedding vectors. If vector similarity is added later (e.g., ONNX Runtime Web), the full index would need a separate loading path.
