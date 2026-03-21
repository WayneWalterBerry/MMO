# Decision: D-WEBARCH001 — Three-Layer Web Delivery Architecture

**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Design  
**Supersedes:** D-JIT001 (expanded, not contradicted)  
**Requested by:** Wayne Berry

---

## Decision

The web version uses a three-layer delivery architecture:

1. **Layer 1: Bootstrapper** (`bootstrapper.js`, ~5-10KB) — a small JavaScript file that fetches the compressed engine bundle via `fetch()`, decompresses it using `DecompressionStream` (or JS fallback), and feeds the decompressed Lua to Fengari. This is the ONLY JavaScript file loaded by the HTML page.

2. **Layer 2: Engine Bundle** (`engine.lua.gz`, ~500KB compressed) — all engine code from `src/engine/` bundled into one Lua file, published pre-compressed. The SLM embeddings (`slm-data.json`) are a separate file, loaded lazily only if needed.

3. **Layer 3: JIT Loader** (`src/engine/loader/web.lua`) — a Lua module inside the engine that fetches individual meta files (objects, rooms, levels, templates) on demand as the player explores. Objects served at GUID-based URLs; rooms at ID-based URLs.

## Rationale

- Explicit compression control (not dependent on GitHub Pages automatic gzip)
- Single JS entry point — clean, auditable, cacheable
- Status messages visible throughout load (JS phase + Lua phase)
- SLM data separated from engine bundle — critical path is ~500KB, not ~16MB
- JIT loading for meta files eliminates the scaling problem (new content doesn't increase load time)

## Static File Layout

```
/play/
  index.html, bootstrapper.js, engine.lua.gz,
  slm-data.json, game-adapter.lua,
  meta/rooms/*.lua, meta/objects/{guid}.lua,
  meta/levels/*.lua, meta/templates/*.lua
```

## Build Pipeline

- `web/build-engine.ps1` — bundles + compresses engine code
- `web/build-meta.ps1` — copies meta files (objects renamed by GUID)

## Documentation

- `docs/architecture/web/jit-loader.md` — full three-layer architecture (updated)
- `docs/architecture/web/bootstrapper.md` — Layer 1 design
- `docs/architecture/web/build-pipeline.md` — build script specs
