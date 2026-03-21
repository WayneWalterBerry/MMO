# Decision: Bug Report Verb — Richer Metadata

**Author:** Flanders (Object Systems Engineer)
**Date:** 2026-07-22
**Status:** Implemented

## Context
The `report bug` verb opened a GitHub issue with only room name and a basic transcript. Wayne requested richer metadata to help triage bugs faster.

## Decision
Enhanced the bug report issue body to include:
1. **Level name** — read from `ctx.current_room.level` (e.g., "Level 1: The Awakening")
2. **Room name** — already existed, kept as-is
3. **Build timestamp** — reads `src/.build-timestamp` file, falls back to "dev" until the build pipeline creates it
4. **Last 50 lines of output** — expanded transcript buffer from 20→50 exchanges in `src/engine/loop/init.lua`
5. **User description section** — `### What happened?` with placeholder text

## Files Changed
- `src/engine/verbs/init.lua` — rewrote `report_bug` handler body format
- `src/engine/loop/init.lua` — expanded transcript buffer cap from 20 to 50

## Team Notes
- **Bart/Smithers:** When the build pipeline is set up, it should write `src/.build-timestamp` per `docs/architecture/engine/versioning.md`. The bug report verb will automatically pick it up.
- **All room authors:** Rooms should include a `level = { number = N, name = "..." }` field for the bug report to display level info. Rooms without it will show "Unknown".
