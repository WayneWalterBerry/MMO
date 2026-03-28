# Smithers-B — Wave 2 Bugfix (Verb Aliases, Parser Tier 2, Part Contents)

**Status:** ✅ Complete  
**Date:** 2026-03-28T14:30Z  
**Duration:** 1707 seconds (~28.4 minutes)  
**Model:** claude-opus-4.6  
**Mode:** background

## Manifest Assignment

- **Issue #381:** Verb aliases not recognized in parser (take/get, wear/put-on, etc.)
- **Issue #383:** (Pre-fixed; verified)
- **Issue #374:** Parser tier 2 (embedding-based semantic matching) returning stale results
- **Issue #373:** `part_contents` field in objects not exposed to parser context

## Work Completed

### Issue #381 (Verb Aliases)
- Root cause: Parser dispatch layer missing alias resolution before handler lookup
- Fix: Added alias registry to `src/engine/verbs/init.lua`; aliased verbs map to canonical handlers
- Result: 3 test assertions fixed

### Issue #383
- Pre-fixed in prior session. Verified passing. No additional work needed.

### Issue #374 (Parser Tier 2)
- Root cause: Embedding index stale; not updated after object additions
- Fix: Regenerated `src/assets/parser/embedding-index.json` from latest object definitions
- Result: 3 test assertions fixed

### Issue #373 (Part Contents)
- Scope: `part_contents` metadata field exposed to parser context for component discovery
- Fix: Updated context builder to extract `part_contents`; added to noun resolution fallback
- Result: 1 test assertion fixed

## Key Artifacts

- **Commit:** 2b2b832 (Wave 2 — Smithers-B)
- **Alias registry:** 12 canonical verb aliases registered
- **Embedding index:** Regenerated from 74 objects
- **Total test assertions fixed:** 7

## Test Results

- `test/parser/test-verb-aliases.lua`: All pass
- `test/parser/test-tier2-embedding.lua`: All pass
- `test/search/test-part-contents.lua`: All pass

## Notes

Verb alias pattern aligns with D-14 (metadata-driven dispatch). Embedding index regeneration ensures parser Tier 2 remains synchronized with object definitions.
