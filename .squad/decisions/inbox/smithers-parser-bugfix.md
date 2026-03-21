# Decision: Parser Bug Fixes (BUG-036, 037, 038, 039)

**Author:** Smithers (UI Engineer)
**Date:** 2026-03-22
**Status:** Implemented
**Affects:** `src/engine/parser/preprocess.lua`

---

## D-BUG036: Single-letter "i" shortcut requires exact match

The `i` inventory shortcut (registered in `verbs/init.lua` line 2618) now only fires when `i` is the **entire** input. When "I" starts a sentence (e.g., "I want to look around"), preprocess.lua strips the pronoun and re-parses the rest.

**Implementation:**
- `natural_language()` strips known preambles ("I want to", "I need to", "I'd like to", "I'll") and recursively processes the remainder.
- `parse()` has a safety net: if verb is "i" and noun is non-empty, it re-parses without the leading "I".
- Bare "i" (typed alone) still triggers inventory as before.

**Why in preprocess, not verbs:** The shortcut registration (`handlers["i"]`) is Bart's verb layer. The fix belongs in preprocessing because it's about *input interpretation*, not verb behavior. This keeps the separation clean.

---

## D-BUG037: "what's around me" maps to look

Added `^what'?s%s+around` pattern to the look section. Covers both "what's around me" and "whats around me".

---

## D-BUG038: "what am I holding" maps to inventory

Added `^what%s+am%s+i%s+hold` pattern to the inventory section. Matches "what am I holding", "what am I holding?", etc.

---

## D-BUG039: "use X on Y" expanded for fire tools

The existing "use X on Y" handler only covered needle/thread → sew and key → unlock. Now also handles:
- **Fire tools** (match, lighter, flint, torch, fire, flame) → `light Y with X`
- **Generic fallback** for unrecognized tools → `put X on Y`

The generic fallback uses `put` rather than inventing a new verb, since "put X on Y" already exists and lets the verb handler decide if it makes sense.

---

## Testing

26/26 unit tests passed covering all four bugs plus regression on existing shortcuts (bare `i`, `look`, `examine`, `what do i see`, `what am i carrying`, `look around`, `what can i do`, `use needle on shirt`, `feel around`).
