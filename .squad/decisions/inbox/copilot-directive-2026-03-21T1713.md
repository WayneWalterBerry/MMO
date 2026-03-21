### 2026-03-21T17:13: User directive — Version numbers for cache management
**By:** Wayne Berry (via Copilot)
**What:** The bootstrapper and engine must emit version numbers during loading. This enables browser cache management — if the version hasn't changed, the browser can use cached files. The bootstrapper should show its version in the loading messages. The engine should also have a version. Document this in docs/architecture/web/. Consider whether this is web-specific or a general architecture concern (engine version applies to CLI too).
**Why:** GitHub Pages caching means players may get stale files. Version numbers let us detect and handle this.
