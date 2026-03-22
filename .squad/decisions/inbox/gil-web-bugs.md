# Decision: Fix bug report transcript in web bridge layer, not engine

**Date:** 2026-07-27
**Author:** Gil (Web Engineer)
**Context:** Issue #13 — bug report URL includes beginning of output instead of last 3 commands

## Problem
The engine's `report_bug` handler (`src/engine/verbs/init.lua`) sends all 50 transcript entries in the GitHub issue URL body. GitHub truncates long URLs (~8KB limit), so the pre-filled issue body shows early welcome text instead of the player's recent commands.

## Decision
Fixed in the **web JS bridge** (`bootstrapper.js` → `window._openUrl`) rather than modifying engine code. The bridge parses the URL, identifies the transcript section, and trims it to the last 3 command/response pairs before opening.

## Rationale
- Stays within Gil's web-layer charter (no `src/engine/` modifications)
- The engine's 50-entry transcript is still useful for TUI users who `report bug` from terminal (URL gets printed, can be shortened manually)
- Web-specific URL length concerns are a web-layer problem
- If the engine handler is later updated to also trim, the JS bridge is harmless (trimming 3 entries to 3 is a no-op)

## Trade-offs
- The fix is in URL post-processing, which depends on the transcript markdown format staying consistent. If the format changes in engine code, the regex may need updating.
- Terminal users still get the full 50-entry URL (which may also be too long). A future engine-side fix could complement this.
