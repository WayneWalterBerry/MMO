# Decision: Deploy Web Game to GitHub Pages /play/

**Author:** Smithers (UI Engineer)
**Date:** 2026-03-24
**Status:** Implemented

## Context

The web bundle was built successfully (110 files, 16.7 MB) and verified locally with `npx serve`. Wayne requested deployment to the public GitHub Pages site as a hidden beta URL.

## Decision

Deploy to `https://waynewalterberry.github.io/play/` with search engine exclusion via `<meta name="robots" content="noindex, nofollow">`. No links from the blog homepage or any published posts.

## Files Deployed

| File | Size | Purpose |
|------|------|---------|
| `play/index.html` | 6,230 bytes | Terminal UI (Fengari-based Lua runtime) |
| `play/game-bundle.js` | 16.7 MB | All game source files as JS virtual filesystem |
| `play/game-adapter.lua` | 19,212 bytes | Lua↔browser bridge adapter |

## Rationale

- GitHub Pages is free, fast, and already configured for the blog
- The `/play/` path is clean and memorable for beta testers
- `noindex, nofollow` is standard practice for unlisted pages — prevents both indexing and link crawling
- The 16.7 MB bundle is large but acceptable for beta; can strip embedding-index.json later for lighter builds

## Risks

- **Bundle size:** 16.7 MB is heavy for mobile users. Consider lazy-loading or stripping the embedding index.
- **CDN dependency:** Fengari loads from CDN. If CDN goes down, game won't load.
- **No versioning:** Currently overwrites in place. Consider adding version tags if multiple builds need to coexist.

## Commit

`a5e12f0` on `WayneWalterBerry.github.io` main branch — "Deploy web game to /play/ (hidden beta)"
