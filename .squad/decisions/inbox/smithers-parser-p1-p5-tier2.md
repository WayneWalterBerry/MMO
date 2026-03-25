# Decision: P1-P5 Tier 2 Parser Improvements

**Author:** Smithers (UI/Parser Pipeline Owner)
**Date:** 2026-03-26
**Branch:** `squad/parser-p1-noun-gate`
**Benchmark:** 134/147 (91.2%) → 144/147 (98.0%)

## What Changed

Five improvements to `src/engine/parser/embedding_matcher.lua`:

1. **P1 — Noun validation gate:** Input tokens classified as verb-like vs noun-like. Phrases where no input noun matches any phrase token are skipped. Prevents "eat the dragon" → "eat a portrait".

2. **P2 — Verbose input truncation:** Inputs >5 tokens (after stop-word removal) truncated to top 5 by known-noun priority then IDF weight.

3. **P3 — Question transform:** "what is X" → "examine X" in Tier 2 match(), preprocess.lua, and questions.lua.

4. **P4 — Noun exactness tiebreaker:** Exact noun match wins BM25 ties. +0.5 noun match bonus in scoring.

5. **P5 — Adjective-only guard:** Inputs with only generic adjectives (small, big, colors) return nil.

## Affects Other Members

- **Nelson (QA):** 3 remaining failures — C-97 ("match match"), C-98 (verbless multi-noun), E-136 ("fly north"). These need P6+ or are unfixable by Tier 2 alone.
- **Flanders (Objects):** New objects should ensure `on_feel` and keywords include the primary noun. The noun gate relies on token overlap.
- **Bart (Engine):** New `verb_tokens`, `known_noun_tokens` sets built in constructor. No engine API changes.

## New Stop Words

Added: `something`, `anything`, `everything`, `slowly`, `sitting`, `lying`, `standing`.
