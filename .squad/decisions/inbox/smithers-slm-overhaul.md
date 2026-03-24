# Decision: SLM Embedding Index Overhaul

**Author:** Smithers (UI Engineer)
**Date:** 2025-07-19
**Issue:** #174
**Branch:** `squad/174-slm-overhaul`

## Decision

Stripped all 384-dim GTE-tiny embedding vectors from the runtime index. The Lua engine uses Jaccard token matching (Tier 2), not cosine similarity — vectors were dead weight. This aligns with Frink's D-KEEP-JACCARD research (#176).

## What Changed

1. **Runtime index is now slim (362 KB, down from 15.3 MB)**. Contains only id/text/verb/noun fields.
2. **Full index archived** at `resources/archive/embedding-index-full.json` for future ONNX browser use.
3. **242 new phrase variants** added for research-identified gaps (gimme, hold, lift, peer at, inspect, check out, use).
4. **State-variant tiebreaker** added — when Jaccard scores tie, base-state nouns win over `-lit`/`-open`/`-broken` suffixed variants.
5. **Build script** (`build_embedding_index.py`) defaults to `--slim` output. Use `--no-slim` to restore full vectors.

## Who This Affects

- **Gil**: Web build should target the slim index. Compression/lazy-load (#174 items 5-6) still pending.
- **Bart**: Async loading architecture not yet implemented — engine still loads index synchronously.
- **Nelson**: No new tests added for tiebreaker specifically; existing 129 test files all pass. Consider adding targeted tiebreaker tests.
- **Flanders**: 57 objects have no index entries (Level 2+ content). As new objects ship, run `generate_parser_data.py` to regenerate training pairs.

## Staleness Audit Summary

- **57/87 objects** not in index — mostly Level 2+ content (barrel, chest, torch, crowbar, etc.)
- **2 orphan nouns** — vanity-mirror-broken, vanity-open-mirror-broken (mutation targets, no standalone .lua)
- **90/129 engine verbs** not in index — all handled by Tier 1 exact dispatch (aliases, directions)
