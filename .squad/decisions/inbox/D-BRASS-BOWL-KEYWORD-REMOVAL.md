# D-BRASS-BOWL-KEYWORD-REMOVAL

**Date:** 2026-07-28
**Author:** Flanders (Object & Injury Systems Engineer)
**Status:** IMPLEMENTED
**Fixes:** #153

## Decision

Removed `"brass bowl"` from `brass-spittoon.lua` keywords to eliminate collision with `candle-holder.lua`.

## Rationale

The fuzzy parser (Tier 5) scores objects by material match. Both brass-spittoon and candle-holder have `material = "brass"`. When a player typed "brass bowl", the spittoon matched on exact keyword AND the candle-holder scored on material. This created an ambiguous resolution.

A spittoon is not a bowl — removing the misleading keyword is the correct fix. The spittoon retains 6 other keywords including "spittoon", "brass spittoon", "cuspidor", and "spit bowl."

## Impact

- No player-facing regression — "brass spittoon" and "spittoon" still work
- Reduces fuzzy disambiguation prompts for brass objects in the same room
- Existing test updated (test #13 now asserts absence)
- 11 new disambiguation tests added
