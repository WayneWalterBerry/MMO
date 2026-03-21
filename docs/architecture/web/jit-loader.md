# Web Delivery System — Three-Layer Architecture

**Author:** Bart (Architect)  
**Date:** 2026-07-21 (revised 2026-07-22)  
**Status:** Design  
**Decisions:** D-JIT001, D-WEBARCH001  
**Related Docs:** [bootstrapper.md](bootstrapper.md) · [build-pipeline.md](build-pipeline.md) · [performance-research.md](performance-research.md)

---

## Problem

The current web build (`web/build-bundle.ps1`) bundles ALL 110+ `.lua` files into a single `game-bundle.js` (~16MB). This is unsustainable:

- **Slow initial load** — the player downloads every object, room, and template before seeing anything.
- **Scales linearly** — every new level, room, or object makes the bundle bigger.
- **Wastes bandwidth** — the player may never visit most rooms or interact with most objects.
- **No compression control** — relies entirely on GitHub Pages' automatic gzip; no explicit compressed delivery.

## Solution: Three-Layer Delivery

The web version is delivered through three distinct layers, each with a clear responsibility:

| Layer | Technology | What It Does | Size |
|-------|-----------|--------------|------|
| **Layer 1: Bootstrapper** | JavaScript | Fetches, decompresses, and loads the engine into Fengari | ~5-10KB |
| **Layer 2: Engine Bundle** | Compressed Lua | All engine code, bundled and gzip-compressed | ~500KB compressed |
| **Layer 3: JIT Loader** | Lua (inside Fengari) | Fetches individual meta files on demand | Part of engine |

The HTML page loads **one** JavaScript file: `bootstrapper.js`. Everything else flows from there.

---

## Layer 1: Bootstrapper (JavaScript)

**File:** `/play/bootstrapper.js` (~5-10KB)  
**Full design:** [bootstrapper.md](bootstrapper.md)

The bootstrapper is the only JavaScript the HTML page loads directly. It:

1. Initializes Fengari (Lua runtime for the browser)
2. Fetches the compressed engine bundle (`engine.lua.gz`) via `fetch()`
3. Decompresses it using the browser `DecompressionStream` API (or a small JS decompression fallback)
4. Feeds the decompressed Lua source code to Fengari for execution
5. Fetches `game-adapter.lua` (the coroutine bridge between JS and Lua)
6. Hands control to the engine

Throughout this process, the bootstrapper shows **light gray status messages** on screen:

```
Loading Bootstrapper...
Loading Game Engine...
Decompressing Engine...
Initializing Game Engine...
```

The bootstrapper does NOT contain game logic. It is purely a delivery mechanism.

### Why a Bootstrapper?

- **Compression control** — we publish pre-compressed `.gz` files and decompress client-side, giving us explicit control over compression rather than depending on GitHub Pages' automatic gzip behavior.
- **Single entry point** — the HTML loads one `<script>` tag. Clean, auditable, cacheable.
- **Status feedback** — players see progress immediately instead of a blank screen.
- **Separation of concerns** — JavaScript handles browser plumbing; Lua handles the game.

---

## Layer 2: Engine Bundle (Compressed Lua)

**File:** `/play/engine.lua.gz` (~500KB compressed, ~990KB raw)

All engine source from `src/engine/` bundled into a single Lua file, then gzip-compressed. The bootstrapper downloads and decompresses this before Fengari ever runs game code.

### What's In the Bundle

| Component | Source Path | Notes |
|-----------|------------|-------|
| Engine core | `src/engine/**` | loader, registry, FSM, parser, verbs, mutation, containment, display, loop |
| Assets | `src/assets/**` | Vocabulary, parser data |

### What's NOT In the Bundle

| Component | Delivery | Why Separate |
|-----------|----------|-------------|
| Meta files | Layer 3 (JIT) | On-demand loading — player only downloads what they visit |
| SLM embeddings | `/play/slm-data.json` | Large (~15MB raw); only loaded if AI features are needed |
| Game adapter | `/play/game-adapter.lua` | Fetched separately by bootstrapper — it's the bridge between JS and Lua |

### SLM Data (Separate, Optional)

The SLM embedding index (`slm-data.json`) is **not** part of the engine bundle. It is:
- Served as a separate static file at `/play/slm-data.json`
- Only fetched if the Tier 2 parser needs it (lazy-loaded after game starts)
- ~15MB raw, ~2.1MB with GitHub Pages automatic gzip
- The engine works without it — Tier 1 and Tier 3 parsing don't need embeddings

### Size Budget

| Component | Raw | Compressed (gzip) |
|-----------|-----|-------------------|
| Engine Lua code | ~990KB | ~500KB |
| SLM data (separate) | ~15.4MB | ~2.1MB |
| Game adapter | ~15KB | ~5KB |

The **critical path** is ~500KB — that's what the player waits for before seeing anything. The SLM data loads in the background after the game is interactive.

---

## Layer 3: JIT Loader (Lua, Inside Fengari)

**Module:** `src/engine/loader/web.lua`

A Lua module that runs inside Fengari after the engine is loaded. It fetches individual meta files (objects, rooms, levels, templates) on demand as the player explores.

### Why JIT?

The game world has ~80+ objects across 7+ rooms. Loading them all at startup wastes bandwidth and time. The JIT loader fetches only what the current room needs, when the player enters it.

### Module Structure

```
src/engine/loader/
├── init.lua       -- existing: load_source(), resolve_template(), resolve_instance()
└── web.lua        -- NEW: fetch_room(), fetch_level(), fetch_object(), fetch_template()
```

The web loader wraps the existing loader — it does NOT replace it. CLI mode continues to use `require()` / `io.open` unchanged.

### API

```lua
local web_loader = require("engine.loader.web")

-- Initialize with base URL and reference to core loader
web_loader.init({
    base_url = "/play/meta",
    loader = require("engine.loader"),
})

-- Fetch individual meta files (async, yields coroutine)
web_loader.fetch_object(guid, callback)     -- e.g., guid = "41eb8a2f-..."
web_loader.fetch_room(room_id, callback)    -- e.g., room_id = "cellar"
web_loader.fetch_level(level_num, callback) -- e.g., level_num = 1
web_loader.fetch_template(name, callback)   -- e.g., name = "small-item"

-- Synchronous cache check (returns nil if not yet fetched)
web_loader.get_cached_object(guid)
web_loader.get_cached_room(room_id)

-- Bulk fetch (for room entry — fetches room + all its objects)
web_loader.fetch_room_bundle(room_id, callback)
```

### Status Messages (from Lua)

Once the JIT loader takes over, it shows its own status messages (light gray, same style as the bootstrapper):

```
Loading Level 1...
Loading Room: Bedroom...
Loading Object: Matchbox...
Loading Object: Candle...
Ready.
```

These messages come from Lua code running inside Fengari, using the same display output mechanism as the game itself.

### Callback Pattern

Browser HTTP is inherently async. The web loader uses a callback pattern that integrates with the existing coroutine architecture:

```lua
web_loader.fetch_room("cellar", function(room_data, err)
    if err then
        -- handle error (see Error Handling below)
        return
    end
    -- room_data is the parsed Lua table, ready for use
end)
```

`fetch_room_bundle()` is the primary call site. It:
1. Fetches the room `.lua` file
2. Reads the `instances` table to discover which object GUIDs are needed
3. Checks the cache — skips objects already loaded
4. Fetches missing objects in parallel
5. Calls back when everything is ready

### Caching

Once fetched, meta files stay in memory for the session. No re-fetch.

```lua
local cache = {
    objects   = {},  -- keyed by GUID
    rooms     = {},  -- keyed by room id
    levels    = {},  -- keyed by level number
    templates = {},  -- keyed by template name
}
```

**Cache policy:** Write-once, read-many. Objects are never evicted during a session. For Level 1 (~7 rooms, ~80 objects), peak memory is well under 1MB of parsed Lua tables.

---

## HTTP Cache Strategy

The JIT loader leverages standard HTTP cache mechanisms (ETag and Last-Modified headers) to eliminate redundant bandwidth on revisits to rooms. This works seamlessly with static hosting on GitHub Pages.

### How It Works

1. **First fetch:** JIT loader calls `fetch("/play/meta/objects/{guid}.lua")` — receives file content plus response headers
2. **Store locally:** Cache the file content AND extract the `ETag` and `Last-Modified` headers from the response
3. **Subsequent fetches:** On room revisit, send `If-None-Match: {etag}` and `If-Modified-Since: {date}` headers with the fetch request
4. **304 Not Modified:** Server returns no body (zero bandwidth) — load the cached version immediately
5. **200 OK:** Server returns new content — update both the cached content and headers

### GitHub Pages HTTP Headers

GitHub Pages automatically serves proper HTTP cache headers on all static files:
- **ETag** — fingerprint of file content (changes if file changes)
- **Last-Modified** — timestamp of last modification
- **Cache-Control** — typically `public, max-age=0` (revalidate always, but browsers cache aggressively)

This means the loader gets cache headers "for free" — no server-side changes needed.

### Cache Storage Structure

The loader maintains an in-memory cache with headers:

```lua
local cache = {
    objects = {
        ["41eb8a2f-972f-4245-a1fb-bbfdcaad4868"] = {
            content = { ... },           -- parsed Lua table
            etag = "abc123def456",       -- from ETag header
            lastModified = "Mon, 21 Jul 2026 10:30:00 GMT",  -- from Last-Modified header
        },
    },
    rooms = { ... },     -- same structure
    levels = { ... },    -- same structure
    templates = { ... }, -- same structure
}
```

### Fetch Flow with Conditional Headers

```lua
-- First visit to a room
web_loader.fetch_room_bundle("cellar", function(data, err)
    -- fetch("/play/meta/rooms/cellar.lua")
    -- Response: 200 OK + full body + ETag + Last-Modified
    -- Store: content + headers
end)

-- Later: player revisits the room
web_loader.fetch_room_bundle("cellar", function(data, err)
    -- fetch("/play/meta/rooms/cellar.lua", {
    --     headers: {
    --         "If-None-Match": "previous-etag",
    --         "If-Modified-Since": "previous-date"
    --     }
    -- })
    -- Response: 304 Not Modified (no body, zero bytes transferred)
    -- Use: cached content from memory
end)
```

### Performance Impact

- **First visit to a room:** Full fetch (unavoidable, all data downloaded)
- **Revisit to a room:** Conditional fetch + 304 response (headers only, ~1KB of data, instant load from cache)
- **Objects that haven't changed:** Zero bandwidth on revisit, fast cached lookup in memory
- **Objects that DID change:** 200 response with new content, cache updated

For a typical play session of Level 1 (7 rooms), after the initial full load, revisits save ~50-200KB of bandwidth per room transition.

### Cache API

The loader exposes this interface for managing the cache:

```lua
web_loader.fetch(type, id)        -- fetch with conditional headers, returns content
                                  -- checks memory cache first
                                  -- sends If-None-Match/If-Modified-Since on HTTP request
                                  -- uses cached version on 304

web_loader.invalidate(type, id)   -- force re-fetch on next access
                                  -- clears stored headers, triggers full fetch
                                  -- use if metadata schema changes mid-session

web_loader.clear()                -- clear entire cache
                                  -- used when engine version changes (see Versioning)
```

### Versioning Integration

The loader integrates with the engine version system (`versions.json`):

**Same version:** Trust HTTP cache headers
- Store and check ETags/Last-Modified across browser sessions (if persistent storage is added later)
- Revisits rely on conditional fetches
- Changes between deploys are detected automatically by the server (ETag changes)

**Version mismatch:** Clear all cached meta
- If the engine version from `versions.json` changes, call `web_loader.clear()`
- Forces a full re-fetch of all meta files (assume everything may have changed)
- New ETag/Last-Modified headers stored for the new version

### Browser Session vs. Persistent Storage

**Current (V1): In-memory cache only**
- Cache persists only during the current browser tab session
- Page reload clears the cache
- Conditional fetches save bandwidth within a session

**Future (V2): Service Worker + persistent IndexedDB**
- Service Worker caches fetched files across page reloads
- `If-None-Match` headers catch changes pushed by new deploys
- Provides offline capability and near-instant revisits
- No work needed now — layer 3 design supports this upgrade path

### Example: Room Transition with Conditional Fetch

```
Player in bedroom, types "go down"
  ↓
engine resolves exit: target = "cellar"
  ↓
web_loader.fetch_room_bundle("cellar", callback)
  ↓
fetch("/play/meta/rooms/cellar.lua")
  headers: { "If-None-Match": "etagFromPreviousVisit" }
  ↓
Server: "304 Not Modified" (no body)
  ↓
cache[rooms]["cellar"] exists and is used
  ↓
(Discover object GUIDs from cached room data)
  ↓
Fetch missing objects:
  fetch("/play/meta/objects/41eb8a2f-...lua")
  headers: { "If-None-Match": "etagFromPreviousVisit" }
  ↓
Server: "304 Not Modified" (most objects unchanged)
  ↓
All data loaded from cache, room transition instant
```

### Detection: CLI vs. Web

```lua
local is_web = (type(js) == "table" or _G.__WEB_MODE == true)
```

The game initialization path uses `web_loader` instead of the "load everything from VFS" approach. The engine core does NOT need to know about the loader — rooms and objects look identical once loaded.

---

## Static File Layout (GitHub Pages)

The build pipeline generates this directory tree, served as static files:

```
/play/
  index.html              ← loads Fengari CDN + bootstrapper.js
  bootstrapper.js         ← Layer 1: fetches + decompresses engine
  engine.lua.gz           ← Layer 2: compressed engine bundle
  slm-data.json           ← SLM embeddings (separate, optional, lazy-loaded)
  game-adapter.lua        ← coroutine bridge (fetched by bootstrapper)
  meta/
    rooms/
      bedroom.lua         ← individual room files (by room id)
      cellar.lua
      storage-cellar.lua
      deep-cellar.lua
      hallway.lua
      courtyard.lua
      crypt.lua
      ...
    objects/
      {guid}.lua          ← individual object files, named by GUID
      ...                    e.g., 41eb8a2f-972f-4245-a1fb-bbfdcaad4868.lua
    levels/
      level-01.lua        ← level definitions (by filename)
      ...
    templates/
      small-item.lua      ← template files (by name)
      room.lua
      container.lua
      furniture.lua
      sheet.lua
```

### URL Scheme

| Meta Type | URL Pattern | Key Type | Example |
|-----------|-------------|----------|---------|
| Objects | `/play/meta/objects/{guid}.lua` | Windows GUID | `/play/meta/objects/41eb8a2f-972f-4245-a1fb-bbfdcaad4868.lua` |
| Rooms | `/play/meta/rooms/{room-id}.lua` | String ID | `/play/meta/rooms/cellar.lua` |
| Levels | `/play/meta/levels/{filename}.lua` | Filename | `/play/meta/levels/level-01.lua` |
| Templates | `/play/meta/templates/{name}.lua` | Template name | `/play/meta/templates/small-item.lua` |

### Why GUIDs for Objects, IDs for Rooms?

**Objects** are referenced by GUID in room instance tables (`type_id = "41eb8a2f-..."`). The loader needs to fetch by GUID because that's the key it has when resolving instances. GUID-based URLs make this a single lookup with no index needed.

**Rooms** are referenced by string ID in exits (`target = "cellar"`), level files, and player location. The loader fetches by room ID.

> **Note:** All meta types carry Windows-style GUIDs (e.g., `44ea2c40-e898-47a6-bb9d-77e5f49b3ba0`). Objects, rooms, and levels all have `guid` fields. The GUID is the base class identity. Instance identity uses the `id` field (e.g., `"match-1"`, `"match-2"`). The `type_id` on instances points to the base class GUID.

---

## Complete Loading Sequence

The full flow from page load to gameplay, with the status messages the player sees:

### Phase 1: Bootstrapper (JavaScript)

```
1. Browser loads index.html
2. Fengari loaded from CDN
3. bootstrapper.js runs
   → shows "Loading Bootstrapper..."       [light gray]
4. fetch("/play/engine.lua.gz")
   → shows "Loading Game Engine..."         [light gray]
5. DecompressionStream decompresses engine
   → shows "Decompressing Engine..."        [light gray]
6. Decompressed Lua fed to Fengari
7. fetch("/play/game-adapter.lua")
8. Adapter + engine initialized
   → shows "Initializing Game Engine..."    [light gray]
```

### Phase 2: Engine Init (Lua takes over)

```
9. Engine starts, JIT loader activates
10. Fetch all templates (5 files, parallel, ~2KB total)
11. Fetch level-01.lua
    → shows "Loading Level 1..."            [light gray]
12. Fetch start-room.lua
    → shows "Loading Room: Bedroom..."      [light gray]
13. Read room instances → discover object GUIDs
14. Fetch all starting room objects (parallel)
    → shows "Loading Object: Matchbox..."   [light gray]
    → shows "Loading Object: Candle..."     [light gray]
    → ...etc for each object
15. Resolve templates, build registry, wire containment
```

### Phase 3: Game Ready

```
16. → shows "Ready."                        [light gray]
17. Game prompt appears — player can type commands
```

**Target:** <2 seconds from page load to "Ready." on broadband.

### Phase 4: Gameplay (room transitions)

```
Player types "go down" (move to cellar)
  → engine resolves exit → target = "cellar"
  → web_loader.fetch_room_bundle("cellar", ...)
    → shows "Loading Room: Cellar..."       [light gray]
    → fetch cellar.lua (if not cached)
    → discover object GUIDs from instances
    → skip objects already in cache (carried items)
    → fetch missing objects (parallel)
    → shows "Loading Object: Barrel..."     [light gray]
    → resolve, register, wire containment
  → transition player to new room
```

Cached rooms load instantly. First visits: ~200-500ms with loading messages.

---

## Error Handling

### Fetch Failures

| Scenario | Behavior |
|----------|----------|
| Network timeout | Retry once after 2 seconds. If second attempt fails, show error in game output. |
| 404 (file not found) | Log to console. Show "Something went wrong" in game output. Do NOT retry. |
| Parse error (bad Lua) | Log full error to console. Show "Something went wrong loading [room/object]" in game output. |
| Template not found | Fatal — templates load at init. If missing, game cannot start. Show error on loading screen. |
| Engine bundle fetch fails | Fatal — bootstrapper shows error. Game cannot start without the engine. |
| Decompression fails | Fatal — bootstrapper falls back to uncompressed fetch if available, else shows error. |

### Graceful Degradation

If a single object fails to load, the room still loads — that object is simply absent. The player can continue playing.

```lua
for _, guid in ipairs(needed_guids) do
    web_loader.fetch_object(guid, function(obj, err)
        if err then
            console_warn("Failed to load object " .. guid .. ": " .. err)
        else
            cache.objects[guid] = obj
        end
        check_all_done()
    end)
end
```

---

## GUID Convention

All meta types carry Windows-style GUIDs (UUID v4 format):

| Type | Example GUID | Example File |
|------|-------------|--------------|
| Object | `41eb8a2f-972f-4245-a1fb-bbfdcaad4868` | `matchbox.lua` |
| Room | `44ea2c40-e898-47a6-bb9d-77e5f49b3ba0` | `start-room.lua` |
| Level | `c4a71e20-8f3d-4b61-a9c5-2d7e1f03b8a6` | `level-01.lua` |
| Template | `c2960f69-67a2-42e4-bcdc-dbc0254de113` | `small-item.lua` |

GUIDs are stable, unique, and present on **every** meta file in the codebase. The GUID is the base class identity. Instance identity uses the `id` field. The `type_id` on instances points to the base class GUID.

---

## Adapter Changes

`game-adapter.lua` needs surgical changes:

### Current Flow (monolithic)
1. VFS backed by `window.GAME_FILES` (all files pre-loaded)
2. Load all templates, all objects, all rooms at boot
3. Start game loop

### New Flow (three-layer)
1. Bootstrapper loads decompressed engine into Fengari
2. VFS used for engine modules only (from the engine bundle)
3. `web_loader` handles meta files via HTTP fetch
4. Boot: fetch templates → fetch starting level → fetch starting room bundle
5. Game loop starts after starting room is ready
6. Room transitions trigger `web_loader.fetch_room_bundle()`

The `vfs_get()` and `vfs_list()` functions remain for engine `require()` resolution. They no longer contain meta files.

The coroutine architecture is preserved — `fetch_room_bundle` yields the game coroutine while fetches are in flight, then resumes when data is ready. Same pattern `io.read()` already uses.

---

## What Stays the Same

- **Engine core** — zero changes. Registry, FSM, verbs, parser, mutation, containment — untouched.
- **Meta file format** — `.lua` files return tables exactly as they do now. No schema changes.
- **CLI mode** — `main.lua` + `io.open` path unchanged. The three-layer delivery is web-only.
- **Object resolution** — `loader.load_source()`, `resolve_template()`, `resolve_instance()` — all unchanged.
- **Game loop** — `engine/loop` runs identically. It doesn't know or care how data was loaded.

---

## Build Pipeline

Two build scripts generate the static file tree. See [build-pipeline.md](build-pipeline.md) for full details.

| Script | Input | Output |
|--------|-------|--------|
| `web/build-engine.ps1` | `src/engine/**`, `src/assets/**` | `engine.lua.gz` (compressed bundle) |
| `web/build-meta.ps1` | `src/meta/**` | `meta/` directory tree (individual files) |

---

## Implementation Order

For Smithers to implement:

1. **`web/build-engine.ps1`** — bundle `src/engine/` + `src/assets/` into `engine.lua`, compress to `engine.lua.gz`
2. **`web/build-meta.ps1`** — copy meta files to static file tree (objects renamed by GUID)
3. **`bootstrapper.js`** — the JavaScript bootstrapper (fetch, decompress, load into Fengari)
4. **`src/engine/loader/web.lua`** — the JIT loader module (fetch, cache, parallel loading)
5. **Adapter refactor** — modify `game-adapter.lua` boot sequence for three-layer flow
6. **Room transition hook** — wire `fetch_room_bundle()` into the movement verb flow
7. **`index.html` update** — replace `game-bundle.js` script tag with `bootstrapper.js`
8. **Test** — verify a full play-through of Level 1 with three-layer delivery

Steps 1-3 can be done in parallel. Steps 4-6 are sequential. Step 7 is independent. Step 8 validates the whole chain.

---

## Open Questions

1. **Pre-fetching adjacent rooms** — Should the loader speculatively fetch rooms connected by exits? **Recommendation:** Not for V1. Room fetches are fast enough (<500ms).

2. **Service Worker caching** — A service worker could cache fetched `.lua` files across page reloads. **Recommendation:** V2. Browser HTTP cache headers suffice for now.

3. **DecompressionStream fallback** — If the browser doesn't support `DecompressionStream`, should we ship a small JS gzip library (~3KB)? **Recommendation:** Yes — include pako or fflate as fallback. All modern browsers support `DecompressionStream`, but the fallback costs almost nothing.

4. **Content-hashed filenames** — Should `engine.lua.gz` include a content hash for cache-busting? **Recommendation:** V2. Version query params (`?v=abc123`) are simpler for now.
