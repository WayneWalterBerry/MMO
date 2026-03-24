# D-HIT-SYNONYM-CLUSTER — Hit/Drop Synonym Expansion

**Date:** 2026-03-26
**Author:** Smithers (Parser Engineer)
**Status:** Implemented
**Commit:** f48b0a3
**Issues:** #141, #142, #143, #146, #157

## Decision

Expanded the hit and drop verb synonym clusters in the preprocessing pipeline rather than only in the verb handler alias table. This ensures `natural_language()` normalizes synonyms before parse, so Tier 1 dispatch always sees canonical verbs.

## Key Design Choices

1. **headbutt always → hit head**: The word "headbutt" inherently implies head targeting. No other body area makes sense, so preprocess collapses everything after "headbutt" and routes to "hit head".

2. **bonk defaults to head (not random)**: Unlike generic hit, bonk carries a connotation of a head tap. When used without explicit body part ("bonk myself", "bonk self", bare "bonk"), defaults to head. Explicit body parts like "bonk arm" are preserved.

3. **toss/throw consolidated**: Previously only `toss X on/in Y` was handled. Now both toss and throw share a single loop that checks for placement prepositions (→ put) and falls through to drop for bare usage. This replaces the old toss-only block.

4. **Dual-layer aliases**: Synonyms are aliased in BOTH preprocess (verb normalization) AND verb handlers (runtime dispatch). This ensures both `natural_language()` and `parse()` paths work correctly.

## Impact

- 27 new tests, zero regressions
- 5 Nelson playtest issues resolved in a single commit
