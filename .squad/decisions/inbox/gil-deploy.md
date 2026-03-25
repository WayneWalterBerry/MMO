# Decision: Full Web Rebuild Deployed (2026-03-24)

**Author:** Gil
**Date:** 2026-03-24T17:08Z
**Affects:** All (live site updated)

## Decision

Rebuilt and deployed the full web bundle from main branch to GitHub Pages. This brings the live site current with all merged work including Parser Tiers 1-5 (#106), slim SLM index with tiebreaker (#174), 23 material definitions, and 4 new objects.

## Details

- Engine bundle grew from 152.3 KB → 169.7 KB compressed (+17.4 KB) due to parser tier code. Acceptable size increase.
- Embedding index is the slim version (361.4 KB vectors stripped). The full 15MB index is NOT deployed — browser uses phrase-only matching.
- 136 total files deployed, 44 changed in Pages commit `55fafd6`.
- Cache-bust stamp `20260324170852` applied to bootstrapper.js and index.html.

## Impact

- **Players:** Live site now has full parser intelligence (5 tiers), better noun resolution, material system in browser.
- **Nelson/Marge:** Can test web-specific behavior against current engine state.
- **Smithers:** Parser changes are now live — any browser-specific parser bugs will surface.
