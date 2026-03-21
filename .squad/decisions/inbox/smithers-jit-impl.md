# Smithers — Three-Layer Web Architecture Implementation Decisions

**Author:** Smithers (UI Engineer)
**Date:** 2026-07-22
**Task:** Implement D-JIT001 / D-WEBARCH001 three-layer web delivery

---

## D-SYNC-XHR: Synchronous XHR for JIT Meta Fetches

**Decision:** Use synchronous XMLHttpRequest from Lua (via fengari-interop) to fetch meta files on demand.

**Rationale:** Avoids the complexity of async coroutine yield/resume for HTTP fetches. Files are small (<15KB each), so main-thread blocking is imperceptible (<50ms). Synchronous XHR is deprecated but universally supported for same-origin requests. The alternative (coroutine yield + JS Promise + resume) would require modifying the command handler and adding a new yield type — much more invasive for V1.

**Limitation:** Status messages don't render mid-fetch (DOM blocked). Acceptable for V1.

---

## D-ROOMS-METATABLE: Transparent JIT Loading via Metatable

**Decision:** Set a metatable on the `rooms` table with `__index` that triggers automatic room+object loading when the engine accesses an unloaded room.

**Rationale:** The engine code (verbs, loop, movement) accesses rooms via `context.rooms[target_id]`. By using a metatable, the JIT loader is completely transparent to the engine — no engine code changes needed. The metatable handler fetches the room file, discovers and fetches all object GUIDs from instances, resolves templates, registers instances, and wires containment.

**Tradeoff:** Each new room causes a burst of synchronous fetches. For Level 1 (~7 rooms, ~80 objects), this is <500ms per room on broadband.

---

## D-TEMPLATE-HARDCODE: Hardcoded Template File List

**Decision:** The 5 template filenames are hardcoded in game-adapter.lua rather than discovered via directory listing or manifest.

**Rationale:** With the three-layer architecture, `io.popen` directory listing is no longer available. Templates are stable (5 files, rarely changed). A manifest file would be more robust but adds build complexity for V1.

**Action for V2:** Have build-meta.ps1 generate a `meta/manifest.json` listing all files. The adapter can fetch this once at boot.

---

## D-VFS-ENGINE-ASSETS: Engine Assets via _G.__VFS

**Decision:** Asset files (stripped embedding-index.json) are embedded in the engine bundle as Lua long strings in `_G.__VFS["path"]`. The io.open override checks `__VFS` for file access.

**Rationale:** The parser needs the embedding index via `io.open("src/assets/parser/embedding-index.json")`. With the monolithic bundle gone, assets must come from somewhere. Embedding in the engine bundle (with vector stripping, 343KB) keeps them co-located with engine code and avoids a separate fetch.

---

## D-GUID-FILENAME: Objects Named by GUID in Static File Tree

**Decision:** Object .lua files are renamed from human-readable names to their GUID in web/dist/meta/objects/. Rooms and templates keep their original filenames.

**Rationale:** Room instance tables reference objects by `type_id` (which is the GUID). The JIT loader constructs URLs directly: `/meta/objects/{guid}.lua`. No manifest or index lookup needed.

**Note:** 33 of 78 objects have non-standard GUIDs (letters beyond a-f) and are skipped by build-meta. These are placeholder objects for future rooms. When proper GUIDs are assigned, they'll be included automatically.
