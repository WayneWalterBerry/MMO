# Nelson — Tier 2 Benchmark Expansion

**Date:** 2025-07-25
**Author:** Nelson (QA)
**Scope:** Smithers (parser), Bart (engine), all devs

## Decision

Created `test/parser/test-tier2-benchmark.lua` with 147 test cases. Score: **123/147 (83.7%)**. This replaces the implicit "100% assumed" baseline with a real measurement.

## Key Finding: Typo Correction Corrupts Nouns

The `correct_typos()` function in `embedding_matcher.lua` applies Levenshtein correction to ALL tokens, not just verbs. When a noun happens to be within edit distance 2 of a known verb, the noun gets silently replaced:

| Input Noun | Corrected To | Edit Distance | Impact |
|-----------|-------------|---------------|--------|
| knife | sniff | 2 | "get knife" → wrong match |
| cloth | close | 2 | "cut cloth" → wrong match |
| cloak | close | 2 | "get cloak" → wrong match |
| gimme | time | 2 | "gimme blanket" → time verb |
| heavy | hear | 2 | "examine heavy" → hear verb |

**This single bug accounts for ~10 of 24 failures.** Fix suggestion for Smithers: only apply typo correction to the FIRST token (likely the verb), or maintain a noun whitelist.

## Other Weaknesses Found

1. **Generic phrase ties:** "look at" (noun="") ties with "look at heavy velvet curtains" at Jaccard 0.500. No tiebreaker handles generic-vs-specific.
2. **Verbose input dilution:** Jaccard denominator grows with extra words. Long player sentences score below 0.40 threshold.
3. **Short-word typo block:** Words ≤4 chars skip correction. "brek" (4 chars) can't correct to "break".
4. **Missing synonyms:** "snag", "show", "what is" have no index coverage.

## Impact on #174

Smithers should run this benchmark before and after stripping vectors. Any score drop below 83.7% indicates regression.

## CI Note

The benchmark does NOT call `os.exit(1)` — it measures accuracy but doesn't fail the test suite. This is intentional: a benchmark that gates CI would need constant maintenance as the parser evolves.
