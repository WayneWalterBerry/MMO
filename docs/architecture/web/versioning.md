# Web & Engine Versioning Architecture

**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Active  
**Related Docs:** [bootstrapper.md](bootstrapper.md) · [jit-loader.md](jit-loader.md) · [build-pipeline.md](build-pipeline.md)  

---

## Problem Solved

Cache management challenge:

1. **GitHub Pages Caching** — Static files cached by browsers and CDNs for days. Players may load stale bootstrapper, engine, or meta files.
2. **Version Visibility** — Players should see version/timestamp in loading messages for troubleshooting and feedback.
3. **Cache-Busting** — Need a strategy to force fresh downloads when critical files change.
4. **Zero Maintenance** — No manual version number tracking. Just build, deploy, and the timestamp is the version.

---

## Solution: Timestamp-Based Versioning

### Overview

- **Version Source:** Build script generates timestamp at build time
- **Version Format:** ISO 8601 timestamp (`YYYY-MM-DD HH:MM`)
- **URL Timestamps:** Compact format for cache-busting (`YYYYMMDDHHmmss`)
- **Bootstrap Messages:** Display human-readable timestamp in loading messages
- **No `src/version.lua`** — Timestamps are embedded directly into output files

**Key Benefit:** Build happens → timestamp is captured → that timestamp IS the version. No manual maintenance.

---

## Version Generation

### Build-Time Timestamp

When you run the build script (`web/build-engine.ps1`, `web/build-meta.ps1`), it captures the current timestamp:

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"       # "2026-03-21 16:45" (human-readable)
$timestampCompact = Get-Date -Format "yyyyMMddHHmmss"  # "20260321164500" (URL-safe)
```

### Single Source of Truth

The build script is the source of truth. Each build automatically gets a unique timestamp. No file to edit manually.

**Process:**
1. Developer runs build script
2. Script captures timestamp
3. Timestamp embedded in:
   - Bootstrapper loading messages
   - Engine initialization code
   - Generated version file (if needed)
   - URL query params for cache-busting

---

## Cache-Busting: Timestamp Query Params

Build scripts embed a compact timestamp as a query param to force fresh downloads when files change.

### URLs

| File | URL Without Cache-Bust | URL With Cache-Bust |
|------|------------------------|---------------------|
| Bootstrapper | `/play/bootstrapper.js` | `/play/bootstrapper.js?t=20260321164500` |
| Engine | `/play/engine.lua.gz` | `/play/engine.lua.gz?t=20260321164500` |
| Adapter | `/play/game-adapter.lua` | `/play/game-adapter.lua?t=20260321164500` |
| Room | `/play/meta/rooms/cellar.lua` | `/play/meta/rooms/cellar.lua?t=20260321164500` |
| Object | `/play/meta/objects/{guid}.lua` | `/play/meta/objects/{guid}.lua?t=20260321164500` |

### How Cache-Busting Works

1. **Build Time:** Build script captures current timestamp in compact format (YYYYMMDDHHmmss)
2. **URL Rewrite:** URLs in index.html and bootstrapper.js are rewritten with `?t=TIMESTAMP`
3. **Browser Behavior:** Query params don't exist → cache key is the full URL (URL + query string)
4. **Result:** New build → different timestamp → new URL → browser fetches fresh copy

**Example:**
```javascript
// Old build (cached from previous day)
fetch('/play/engine.lua.gz?t=20260320150000')

// New build (timestamp changed)
fetch('/play/engine.lua.gz?t=20260321164500')

// Browser treats these as completely different resources
// Even if cache hasn't expired
```

### Timestamp Formats

| Use Case | Format | Example |
|----------|--------|---------|
| **Loading Messages** | Human-readable | `2026-03-21 16:45` |
| **URL Query Params** | Compact | `20260321164500` |
| **Cache Comparison** | Compact | `20260321164500` |

**Conversion:**
```powershell
$humanReadable = Get-Date -Format "yyyy-MM-dd HH:mm"       # "2026-03-21 16:45"
$compact = Get-Date -Format "yyyyMMddHHmmss"               # "20260321164500"
```

---

## Version Display: Bootstrap Messages

### Bootstrapper (JavaScript) Messages

The bootstrapper shows the build timestamp in loading messages:

```
Loading Bootstrapper (2026-03-21 16:45)...
Loading Game Engine (2026-03-21 16:45)...
Decompressing Engine...
Initializing Game Engine (2026-03-21 16:45)...
```

**Implementation:**
```javascript
const buildTimestamp = "2026-03-21 16:45";  // Embedded at build time

showStatus(`Loading Bootstrapper (${buildTimestamp})...`);
showStatus(`Loading Game Engine (${buildTimestamp})...`);
showStatus(`Initializing Game Engine (${buildTimestamp})...`);
```

The timestamp is embedded in bootstrapper.js when the build script runs. No manual version tracking needed.

### JIT Loader (Lua) Messages

After engine loads, the JIT loader shows its own messages:

```
Loading Level 1 (2026-03-21 16:45)...
Loading Room: Cellar...
Loading Object: Barrel...
Loading Object: Match...
Ready (2026-03-21 16:45).
```

**Implementation:**
```lua
local buildTimestamp = "2026-03-21 16:45"  -- Embedded at build time

jit_loader.init({
    base_url = "/play/meta",
    timestamp = buildTimestamp
})

-- Later, in jit_loader.fetch_room_bundle():
print(string.format("Loading Level %d (%s)...", level, buildTimestamp))
print("Loading Room: " .. room_name .. "...")
print("Loading Object: " .. object_name .. "...")
print(string.format("Ready (%s).", buildTimestamp))
```

---

## Cache Validation

When a player's cached version differs from the server version, re-fetch:

```javascript
const cachedTimestamp = localStorage.getItem("gameTimestamp");    // "20260320150000"
const serverTimestamp = "20260321164500";                          // From URL or manifest

if (cachedTimestamp !== serverTimestamp) {
    // Clear cache and re-fetch with new timestamp
    localStorage.setItem("gameTimestamp", serverTimestamp);
    fetch(`/play/engine.lua.gz?t=${serverTimestamp}`);
}
```

Simple comparison: if timestamps differ, the server version is fresher. No complex version logic needed.

---

## Build Pipeline Integration

### `web/build-engine.ps1` Changes

1. Capture current timestamp at build start
2. Embed human-readable timestamp in bootstrapper.js loading messages
3. Embed compact timestamp in URL query params
4. Report: "Engine built (2026-03-21 16:45) → engine.lua.gz?t=20260321164500"

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"        # "2026-03-21 16:45"
$timestampCompact = Get-Date -Format "yyyyMMddHHmmss"   # "20260321164500"

Write-Host "Engine built ($timestamp) → engine.lua.gz?t=$timestampCompact"

# Embed into bootstrapper.js
$bootstrapperContent = Get-Content "web/bootstrapper.js" -Raw
$bootstrapperContent = $bootstrapperContent -replace 'const buildTimestamp = ".*?"', "const buildTimestamp = `"$timestamp`""
Set-Content "web/bootstrapper.js" $bootstrapperContent
```

### `web/build-meta.ps1` Changes

1. Capture timestamp (same as engine build)
2. Embed timestamp in generated version constant
3. Rewrite meta file URLs with compact timestamp
4. Report: "Meta built (2026-03-21 16:45) → 7 rooms, 80+ objects"

### `web/bootstrapper.js` Changes

1. Define `buildTimestamp` constant (will be embedded at build time)
2. Use timestamp in all loading messages (human-readable format)
3. Append compact timestamp to URL query params

```javascript
const buildTimestamp = "2026-03-21 16:45";  // Embedded at build time
const timestampCompact = buildTimestamp.replace(/[- :]/g, "");  // "20260321164500"

showStatus(`Loading Bootstrapper (${buildTimestamp})...`);
showStatus(`Loading Game Engine (${buildTimestamp})...`);
fetch(`/play/engine.lua.gz?t=${timestampCompact}`);
```

---

## Version Lifecycle

### Initial Release

```
Build script runs (2026-03-21 16:45)
Timestamp embedded: "2026-03-21 16:45" (human-readable), "20260321164500" (compact)

web/dist/
  bootstrapper.js?t=20260321164500
    (shows: "Loading Bootstrapper (2026-03-21 16:45)...")
  engine.lua.gz?t=20260321164500
    (shows: "Loading Engine (2026-03-21 16:45)...")
  meta/rooms/*.lua?t=20260321164500
  meta/objects/*.lua?t=20260321164500
```

### After Engine Bug Fix

```
Fix applied to src/engine/parser/init.lua

Build script runs (2026-03-21 17:00)
New timestamp embedded: "2026-03-21 17:00", "20260321170000"

Players see:
  Old cached engine: "Loading Engine (2026-03-21 16:45)..." from ?t=20260321164500
  New server engine: "Loading Engine (2026-03-21 17:00)..." from ?t=20260321170000
  
Browser fetches fresh copy (URL changed)
```

### After Meta Content Expansion

```
New rooms/objects added to src/meta/

Build script runs (2026-03-22 10:00)
New timestamp: "2026-03-22 10:00", "20260322100000"

Result:
  Old cached meta: from previous timestamp
  New server meta: from new timestamp
  Different timestamps = fresh download
```

---

## Cache Control Headers (Future)

For production, GitHub Pages allows setting cache headers:

```
# .github/workflows/deploy.yml (pseudocode)

engine.lua.gz:        Cache-Control: public, max-age=604800  (7 days)
bootstrapper.js:      Cache-Control: public, max-age=3600    (1 hour)
index.html:           Cache-Control: public, no-cache, must-revalidate
meta/rooms/*.lua:     Cache-Control: public, max-age=604800  (7 days)
```

With timestamp query params, aggressive caching is safe — every build gets a new timestamp → new URL → fresh download.

---

## Recommendations for Smithers

### V1 Implementation (MVP)

1. **Update `web/build-engine.ps1`** — Capture timestamp, embed in bootstrapper.js, append to URLs
2. **Update `web/build-meta.ps1`** — Same timestamp, apply to meta file URLs
3. **Update `bootstrapper.js`** — Use `buildTimestamp` constant in messages, convert to compact format for URLs
4. **Update `src/main.lua`** — Add `--version` flag to show build timestamp (CLI)
5. **DELETE `src/version.lua`** — No longer needed. Timestamps replace it entirely.
6. **Update `web/index.html`** — Rewrite URLs with `?t=TIMESTAMP` query params (or wire into build scripts)

### Ongoing

- Just run the build script. Timestamp is automatic.
- No version file to maintain.
- Each build automatically gets a unique version.

---

## FAQ

**Q: Why timestamps instead of semantic versioning?**  
A: Timestamps require zero maintenance. Build happens → timestamp is captured → version is done. No manual bumping, no forgetting to update a version file.

**Q: Won't query params break static caching?**  
A: Exactly the point. Different timestamp = different query string = different cache key = fresh download. This is a feature, not a bug.

**Q: What if I build twice in the same minute?**  
A: The compact timestamp format includes seconds (YYYYMMDDHHmmss). Two builds in the same minute get different timestamps (differ in seconds).

**Q: Can I revert to an old timestamp?**  
A: Yes, but not recommended. If you revert code, run the build script — it captures the new timestamp. Deploying old code with a new timestamp is cleaner than trying to reuse old timestamps.

**Q: How do I compare versions?**  
A: Timestamp comparison is trivial: "20260321170000" > "20260321164500" = second is newer. No complex semver logic needed.

**Q: Does this work with GitHub Pages' automatic gzip?**  
A: Yes. GitHub Pages gzips on-the-fly regardless of query params. The query params are for browser cache-busting, not server gzip.

---

## Summary

| Aspect | Solution |
|--------|----------|
| **Single source** | Build script (no files to edit) |
| **Versioning** | Timestamps (YYYY-MM-DD HH:MM in UI, YYYYMMDDHHmmss in URLs) |
| **Cache-busting** | Timestamp query params (e.g., `?t=20260321164500`) |
| **Messages** | "Loading Bootstrapper (2026-03-21 16:45)..." |
| **CLI** | `lua src/main.lua --version` shows timestamp |
| **Maintenance** | Zero — build is the version |
| **Cache headers** | Aggressive (timestamps ensure fresh downloads on new builds) |

This eliminates GitHub Pages cache issues while eliminating version maintenance entirely. Simpler, more reliable, less to think about.
