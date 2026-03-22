# Smithers: Hang Pattern Root Cause Analysis — Pass 027

**Date:** 2026-03-22  
**Author:** Smithers (UI Engineer)  
**Context:** BUG-082, BUG-083, BUG-084, BUG-091, BUG-093, BUG-094

---

## Summary

All 5 hang bugs from Pass 027 share a common root cause: **compound/prepositional phrases that bypass the Tier 1 preprocessing pipeline and fall through to the Tier 2 embedding matcher**, where the Jaccard similarity tokenizer strips stop words (including "for", "around", "a", "the") producing degenerate single-token matches that bounce between verb handlers.

## Root Cause: The Preprocessing Gap

The `natural_language()` function in `preprocess.lua` handles specific patterns:
- `"search for X"`, `"search X for Y"`, `"look for X"`, `"hunt for X"`, `"rummage around"`

If an input doesn't match ANY pattern AND was not modified by politeness/adverb stripping, `natural_language()` returns `nil, nil`. The caller falls back to `preprocess.parse()`, which does a simple first-word split. This produces verbs like "search" or "find" that DO have handlers, so the Tier 2 fallback is not invoked.

**However**, the historical hang path was:
1. Preprocessing returned an unexpected verb/noun (e.g., "rummage" as a verb with no handler)
2. Tier 2 embedding matcher was invoked
3. Matcher tokenized input, stripping stop words ("for", "a", "around")
4. Degenerate match returned a verb+noun that re-entered the parser
5. Some verb handlers recursively called the parser on unrecognized sub-phrases
6. Infinite recursion between parser fallback and verb handlers

## What Fixed the Hangs

The fixes applied before this pass work by **catching compound phrases in preprocessing before they reach Tier 2**:
- `"rummage around/for/through"` → `"search"` synonym mapping (preprocess.lua)
- `"look for X"` → `"find X"` conversion with article stripping
- `"search X for Y"` → scoped search with article stripping on both scope and target
- Politeness stripping (`"could you"`, `"please"`, etc.) runs FIRST, before pattern matching
- Adverb stripping (`"thoroughly"`, `"carefully"`, etc.) runs FIRST

## Remaining Risk for Phase 4

The underlying architectural risk remains: **any new verb synonym or phrase pattern not covered by `natural_language()` will fall through to the embedding matcher.** The matcher itself is safe (bounded O(n) scan), but if it returns a verb+noun that triggers a handler which re-invokes parsing (e.g., via the `preamble_rest` recursive call at line 119), we could get a new hang.

**Recommendations for Phase 4:**
1. Add a global recursion counter to `natural_language()` — if called more than 3 times in a single input processing, return a safe fallback
2. Add a catch-all at the END of `natural_language()` that recognizes common verb stems (rummage, hunt, scour, probe, etc.) and maps them to known verbs, rather than requiring explicit patterns for every form
3. Consider adding a "verb synonym table" at the top of preprocess.lua that maps unknown verbs to known ones, checked before the pattern matching section
4. The Tier 2 embedding matcher should set a flag preventing re-entry to the parser from verb handlers

## Compound Command Fix (BUG-084)

Added search draining between compound sub-commands in `loop/init.lua`. When "find X and verb Y" splits into two sub-commands, the search started by "find X" now completes before "verb Y" processes. Also added pronoun resolution in the GOAP optimization block so "light it" resolves "it" from earlier fragments.

---
**Status:** All 6 bugs verified fixed. 438 tests passing, 0 failures.
