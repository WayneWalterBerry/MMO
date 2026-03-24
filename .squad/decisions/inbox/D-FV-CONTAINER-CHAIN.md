# D-FV-CONTAINER-CHAIN: find_visible searches root-level container chains

**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Status:** Implemented  
**Issue:** #149  
**Commit:** 222a4f3

## Context

After search opens containers (drawer, matchbox), `get match` still failed with "You don't notice anything called that nearby." The search system correctly set `accessible = true` on all containers in the chain, but the verb system's `find_visible` → `_fv_surfaces` couldn't see items inside them.

## Problem

`_fv_surfaces` had two search branches:
1. Objects with `.surfaces` → search surface zone contents only
2. Objects WITHOUT `.surfaces` that are containers → search their contents

Nightstand has `.surfaces` (the top), so branch 2 was skipped (`not obj.surfaces` guard). But the drawer lives in `nightstand.contents` (not in any surface zone), because nightstand has no `surfaces.inside` — only `surfaces.top`. Branch 1 never looked at root contents.

## Decision

Added a third search path inside `_fv_surfaces`: after searching surface zones, recursively traverse `obj.contents` for objects with surfaces. The recursive `_search_accessible_chain` function:
- Follows `accessible ~= false` at each level (matches search system's flag)
- Checks both the container itself and its contents for keyword match
- Depth-limited to 3 (matching the containment model: furniture → container → item)

## Impact

- `get match` after search now works for drawer→matchbox→match chain
- `find match, get match` compound command works for nested containers
- Wardrobe→sack path unchanged (items are in `surfaces.inside`, not root contents)
- No regressions (0 new failures in full test suite)
