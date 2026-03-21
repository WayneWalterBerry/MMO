# Decision: D-JIT001 — JIT Loader Architecture for Web

**Author:** Bart (Architect)  
**Date:** 2026-07-21  
**Status:** Design  
**Scope:** Web loading, build pipeline, engine/loader  
**Document:** `docs/architecture/web/jit-loader.md`

---

## Summary

Replace the monolithic `game-bundle.js` (all 110+ `.lua` files in one ~16MB download) with a JIT (Just-In-Time) loading architecture for the web version.

## Key Decisions

### 1. Engine Bundle + Individual Meta Files

- **Engine code** (`src/engine/**`, `src/assets/**`) remains bundled → `engine-bundle.js` (~2-3MB)
- **Meta files** (`src/meta/**`) served as individual static `.lua` files, fetched on demand
- Clean split: engine = code (bundled), meta = data (JIT loaded)

### 2. Web Loader Module: `src/engine/loader/web.lua`

- New module wraps the existing `loader/init.lua` — does NOT replace it
- API: `fetch_room_bundle(room_id, callback)` is the primary call site
- Fetches room → discovers object GUIDs from instances → fetches missing objects in parallel
- Write-once cache: fetched data stays in memory, never re-fetched

### 3. Static File URL Scheme

```
/play/meta/objects/{guid}.lua      — objects by GUID (matches type_id references)
/play/meta/world/{room-id}.lua     — rooms by ID (matches exit targets)
/play/meta/levels/level-{NN}.lua   — levels by filename convention
/play/meta/templates/{name}.lua    — templates by name
```

Objects use GUID-based URLs because room instances reference them by GUID (`type_id`). Rooms use ID-based URLs because exits reference them by ID (`target`).

### 4. GUID Status — No Expansion Needed

All meta types already carry UUID-format GUIDs:
- Objects: ✅ (e.g., `41eb8a2f-972f-4245-a1fb-bbfdcaad4868`)
- Rooms: ✅ (e.g., `44ea2c40-e898-47a6-bb9d-77e5f49b3ba0`)
- Levels: ✅ (e.g., `c4a71e20-8f3d-4b61-a9c5-2d7e1f03b8a6`)
- Templates: ✅ (e.g., `c2960f69-67a2-42e4-bcdc-dbc0254de113`)

No new GUIDs need to be added. The UUID format is the convention.

### 5. Loading Flow

1. Page load → engine bundle + Fengari → adapter initializes
2. Game init → fetch templates (all 5, parallel) → fetch starting level → fetch starting room + objects
3. Gameplay → room transitions trigger `fetch_room_bundle()` for new rooms
4. Loading indicator on first boot only; room transitions are fast enough (<500ms) to skip indicators

### 6. CLI Mode Unchanged

The JIT loader is web-only. `main.lua` + `io.open()` path for CLI mode is untouched. The engine core has zero changes — registry, FSM, verbs, parser, mutation, containment don't know or care how data was loaded.

### 7. Error Handling

- Retry once on network timeout (2s delay)
- 404 = log + skip (no retry — file genuinely missing)
- Single object failure doesn't block room load — graceful degradation
- Template failure at init = fatal (game can't start without templates)

## Build Pipeline

Two new scripts replace `build-bundle.ps1`:
- `web/build-engine-bundle.ps1` — bundles engine + assets only
- `web/build-meta-files.ps1` — copies meta files to `web/dist/meta/` tree, renames objects by GUID

## Rationale

- Players only download what they need — initial load drops from ~16MB to ~2-3MB
- Scales with game size — adding Level 2 doesn't slow Level 1's load
- Meta file format unchanged — .lua files return tables exactly as today
- Build is simpler — copying files is simpler than JSON-encoding a monolithic bundle
- Future-ready — per-player universe instances can swap individual meta files without regenerating a bundle
