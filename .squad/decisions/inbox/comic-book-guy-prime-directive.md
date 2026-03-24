# Decision: Prime Directive Tiers 1–5 Design Spec

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-25  
**Issue:** #106  
**Status:** Design Complete  
**Deliverable:** `docs/design/prime-directive-tiers.md`

## Summary

Designed the 5-tier parser Prime Directive system from the player's perspective. This is the governing design document for all parser work going forward.

## Key Decisions

### Priority Order
Tier 2 (Error Messages) > Tier 5 (Fuzzy) > Tier 4 (Context) > Tier 1 (Questions) > Tier 3 (Idioms)

Error messages are #1 because they're the safety net when everything else fails. Every player will hit error messages; good ones teach, bad ones frustrate.

### Error Message Categories
Five distinct categories, each with its own response strategy and progressive hints:
1. Unknown verb — narrator bemused but helpful
2. Unknown noun — context-aware, never reveals hidden objects
3. Impossible action — explain why using material properties
4. Missing prerequisite — hint without solving puzzles
5. Ambiguous target — use location and properties to disambiguate

### Fuzzy Confidence Tiers
- Score ≥5: Execute immediately
- Score 3–4: Execute with narration "(Taking the *brass key*...)"
- Score 2: Confirm "Did you mean the *candle*?"
- Score ≤1: Fall through to error

### Idiom Library Cap
Target 80–120 entries. Beyond that, invest in Tier 2 embedding matching. Table-driven in preprocess.lua, expanded from playtesting data.

### "OOPS" Command
Proposed from Level 9's parser. When parser fails on unrecognized noun, store the input. If player types "oops {word}", replace the bad word and re-parse. ~20 lines of Lua, enormous UX value.

### Disambiguation Memory
After asking "Which do you mean?", store the option list for 3 commands. Next input of "first"/"second"/"the glass one" resolves against stored options.

## Who Should Know

- **Smithers:** This is your implementation roadmap. Start with Tier 2 (error messages).
- **Nelson:** Test coverage needed for each tier. Error messages need regression tests.
- **Flanders:** Objects need good `keywords` (including color terms) for Tier 5 fuzzy matching.
- **Moe:** Room descriptions should use consistent object naming for Tier 5 partial matching.
- **Brockman:** Update parser architecture docs to reference this design spec.
