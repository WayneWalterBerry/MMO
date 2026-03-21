# Decision: HTTP Cache-Aware JIT Loader

**Author:** Smithers (UI Engineer)
**Date:** 2026-07-23
**Status:** Implemented
**Affects:** web/bootstrapper.js, web/game-adapter.lua

## Context

The JIT loader fetches meta files (rooms, objects, templates, levels) on demand via synchronous XHR. On room revisits within a session, files were re-downloaded in full even though they hadn't changed. GitHub Pages serves ETag and Last-Modified headers on all static files.

## Decision

Implement HTTP conditional fetching (ETag/Last-Modified) in the JIT loader:

1. **JS bridge** (`window._cachedFetch`): Synchronous XHR that sends `If-None-Match` and `If-Modified-Since` headers when provided. Returns status, content, ETag, and Last-Modified from the response.

2. **Lua cache** (`http_cache` table in game-adapter.lua): Stores `{ content, etag, last_modified }` per URL. On 304 responses, serves cached content. On 200, updates cache.

3. **Cache API** (`web_loader_api`): Exposes `fetch(type, id)`, `invalidate(type, id)`, `clear()` for engine-level cache management.

4. **Status messages**: Show "(cached)" suffix when a 304 is returned.

## Constraints Honored

- **CLI unaffected** — cache layer is web-only (game-adapter.lua only runs in Fengari)
- **In-memory V1** — cache clears on page refresh; persistent storage deferred to V2 (Service Worker)
- **Synchronous XHR** — matches existing coroutine/yield pattern in Fengari

## Alternatives Considered

- Async `fetch()` API: Would require rearchitecting the Lua coroutine bridge. Deferred.
- Service Worker cache: V2 path per architecture spec. In-memory is sufficient for V1.

## Impact

- Room revisits within a session use conditional fetches → 304 Not Modified → zero bandwidth
- First visits unchanged (full 200 response)
- Typical Level 1 session saves ~50-200KB per room transition on revisits
