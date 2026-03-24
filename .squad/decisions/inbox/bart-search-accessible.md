### D-SEARCH-ACCESSIBLE: Search container open must set accessible flag

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** Implemented  
**Issues:** #135, #132

When the search traversal system opens a closed container (e.g., matchbox) via `containers.open()`, it must set `object.accessible = true` in addition to `is_open` and `open`. The `find_visible` function in `engine/verbs/init.lua` checks `obj.accessible ~= false` before searching container contents. Without this, items discovered by search inside closed containers remain invisible to all subsequent verb handlers (`get`, `take`, `examine`, etc.).

**Scope:** `src/engine/search/containers.lua` — the `containers.open()` function is the single authoritative place where search opens containers. One-line fix ensures all callers benefit.

**Invariant:** After `containers.open(ctx, obj)` succeeds, `obj.accessible` must be `true`. This matches the real game's mutation pattern where the closed matchbox (`accessible = false`) mutates to matchbox-open (`accessible = true`) via the verb system.
