# Decision: Prime Directive Architecture — Parser Tiers 1-5

**Author:** Smithers (UI Engineer)  
**Date:** 2026-07-19  
**Issue:** #106  
**Affects:** Nelson (test strategy), Comic Book Guy (design companion doc), Bart (pipeline architecture)

## Decision

Wrote the technical architecture spec for all 5 Prime Directive parser tiers at `docs/architecture/engine/prime-directive-architecture.md`.

## Key Architectural Choices

1. **No pipeline rewrite.** Tiers 1 and 3 enhance existing pipeline stages (slots 5 and 6) by extracting data tables to backing modules (`questions.lua`, `idioms.lua`). The 11-stage table-driven pipeline stays as-is.

2. **New `errors.lua` module for Tier 2.** Centralizes error categories and message templates. Verb handlers call `errors.context()` + `errors.format()` instead of bare print strings. ~50 error sites across verbs/*.lua need updating.

3. **Context window is additive (Tier 4).** Existing `context.lua` already tracks objects, discoveries, and previous room. New features: "again" command replay, verb history stack, `recency_score()` for fuzzy disambiguation.

4. **Fuzzy enhancements are conservative (Tier 5).** Confidence normalization (0.0-1.0), context integration, 4-char typo threshold change. Existing safeguards (length ratio ≥ 0.75, ≤3-char exactness) retained.

5. **Implementation order: 3 → 1 → 2 → 4 → 5.** Additive-only tiers first (zero risk), stateful tiers last.

## Who Should Read This

- **Nelson:** Architecture doc defines test strategy per tier and function signatures to test against.
- **Comic Book Guy:** This is the HOW companion to the WHAT design spec. Cross-reference for consistency.
- **Bart:** Pipeline integration points documented — no structural changes to loop/init.lua dispatch flow.
