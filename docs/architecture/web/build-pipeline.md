# Web Build Pipeline

**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Design  
**Parent Doc:** [jit-loader.md](jit-loader.md) (Three-Layer Architecture)

---

## Overview

Two PowerShell build scripts replace the current monolithic `web/build-bundle.ps1`:

| Script | Input | Output | Purpose |
|--------|-------|--------|---------|
| `web/build-engine.ps1` | `src/engine/**`, `src/assets/**` | `engine.lua`, `engine.lua.gz` | Bundle + compress all engine code |
| `web/build-meta.ps1` | `src/meta/**` | `meta/` directory tree | Copy individual meta files for JIT loading |

Both scripts output to `web/dist/`, which is the root of the static site deployed to GitHub Pages at `/play/`.

---

## Output Directory Structure

After both scripts run:

```
web/dist/
├── index.html                ← copied from web/index.html
├── bootstrapper.js           ← copied from web/bootstrapper.js
├── engine.lua.gz             ← build-engine.ps1 output (compressed)
├── engine.lua                ← build-engine.ps1 output (raw, for debugging)
├── slm-data.json             ← copied from src/assets/ (if present)
├── game-adapter.lua          ← copied from web/game-adapter.lua
└── meta/
    ├── rooms/
    │   ├── start-room.lua
    │   ├── cellar.lua
    │   ├── storage-cellar.lua
    │   ├── deep-cellar.lua
    │   ├── hallway.lua
    │   ├── courtyard.lua
    │   ├── crypt.lua
    │   └── ...
    ├── objects/
    │   ├── 41eb8a2f-972f-4245-a1fb-bbfdcaad4868.lua   (matchbox)
    │   ├── 009b0347-2ba3-45d1-a733-7a587ad1f5c9.lua   (match)
    │   ├── c3e8f1a2-b4d7-4596-8e23-f9a1b6c5d402.lua   (barrel)
    │   └── ...  (~80 files, each named by GUID)
    ├── levels/
    │   ├── level-01.lua
    │   └── ...
    └── templates/
        ├── small-item.lua
        ├── room.lua
        ├── container.lua
        ├── furniture.lua
        └── sheet.lua
```

---

## Script 1: `web/build-engine.ps1`

### Purpose

Bundles all engine source code into a single Lua file, then compresses it with gzip.

### Input

| Source | Contents |
|--------|----------|
| `src/engine/**/*.lua` | Engine core: loader, registry, FSM, parser, verbs, mutation, containment, display, loop |
| `src/assets/**` | Vocabulary files, parser data (NOT embedding-index.json) |

### Output

| File | Description |
|------|-------------|
| `web/dist/engine.lua` | Concatenated engine source (raw, ~990KB) — kept for debugging |
| `web/dist/engine.lua.gz` | Gzip-compressed engine bundle (~500KB) — served to browsers |

### Algorithm

```
1. Collect all .lua files from src/engine/ (recursive)
2. Collect all asset files from src/assets/ (excluding embedding-index.json)
3. Concatenate Lua files into a single engine.lua
   - Each file wrapped in a module registration block
   - Module name derived from file path (e.g., src/engine/fsm/init.lua → "engine.fsm")
4. Embed asset file contents as string literals (same VFS pattern as current build-bundle.ps1)
5. Write engine.lua to web/dist/
6. Gzip-compress engine.lua → engine.lua.gz
7. Report sizes (raw vs. compressed)
```

### Module Registration Pattern

Each Lua source file is wrapped so it registers itself as a loadable module:

```lua
-- Module: engine.fsm
package.preload["engine.fsm"] = function()
    -- [contents of src/engine/fsm/init.lua]
end
```

This mirrors the existing `build-bundle.ps1` pattern but outputs pure Lua instead of JavaScript string assignments.

### Compression

```powershell
# PowerShell gzip compression
$content = [System.IO.File]::ReadAllBytes("web/dist/engine.lua")
$ms = New-Object System.IO.MemoryStream
$gz = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionLevel]::Optimal)
$gz.Write($content, 0, $content.Length)
$gz.Close()
[System.IO.File]::WriteAllBytes("web/dist/engine.lua.gz", $ms.ToArray())
```

### What's Excluded

| Excluded | Reason |
|----------|--------|
| `src/meta/**` | Served individually by build-meta.ps1 |
| `src/assets/embedding-index.json` | SLM data — separate file, lazy-loaded |
| `src/main.lua` | CLI entry point — not used in web |

---

## Script 2: `web/build-meta.ps1`

### Purpose

Copies individual meta `.lua` files into the static file tree for JIT loading. Objects are renamed by their GUID.

### Input

| Source | Contents |
|--------|----------|
| `src/meta/objects/*.lua` | Object definitions (~80 files) |
| `src/meta/world/*.lua` | Room definitions (~7 files) |
| `src/meta/levels/*.lua` | Level definitions (~1 file) |
| `src/meta/templates/*.lua` | Template definitions (~5 files) |

### Output

| Destination | Naming |
|-------------|--------|
| `web/dist/meta/objects/{guid}.lua` | Renamed from human name to GUID |
| `web/dist/meta/rooms/{room-id}.lua` | Kept as-is (room ID = filename) |
| `web/dist/meta/levels/{filename}.lua` | Kept as-is |
| `web/dist/meta/templates/{name}.lua` | Kept as-is |

### Algorithm

```
1. Clean web/dist/meta/ directory (remove stale files)

2. For each file in src/meta/objects/:
   a. Read file, extract guid field (regex: guid\s*=\s*"([^"]+)")
   b. Copy to web/dist/meta/objects/{guid}.lua
   c. If no guid found, WARN and skip

3. For each file in src/meta/world/:
   a. Copy to web/dist/meta/rooms/{filename}
   (Note: source is "world/", destination is "rooms/" — cleaner URL semantics)

4. For each file in src/meta/levels/:
   a. Copy to web/dist/meta/levels/{filename}

5. For each file in src/meta/templates/:
   a. Copy to web/dist/meta/templates/{filename}

6. Report: file counts per category, total size
```

### GUID Extraction for Objects

Objects are renamed from their human-readable filename to their GUID. The build script reads each file and extracts the `guid` field:

```powershell
# Extract GUID from a .lua object file
$content = Get-Content $file -Raw
if ($content -match 'guid\s*=\s*"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"') {
    $guid = $Matches[1]
    Copy-Item $file "web/dist/meta/objects/$guid.lua"
} else {
    Write-Warning "No GUID found in $($file.Name) — skipping"
}
```

### Why Rename Objects by GUID?

Room files reference objects by `type_id` (which is the GUID):

```lua
-- In start-room.lua:
instances = {
    { id = "matchbox-1", type_id = "41eb8a2f-972f-4245-a1fb-bbfdcaad4868", ... },
}
```

When the JIT loader needs to fetch the matchbox definition, it has the GUID `41eb8a2f-...`. If the file is named `41eb8a2f-972f-4245-a1fb-bbfdcaad4868.lua`, the loader can construct the URL directly:

```
/play/meta/objects/41eb8a2f-972f-4245-a1fb-bbfdcaad4868.lua
```

No manifest or index lookup needed. The GUID IS the filename.

### Room Directory Rename: world/ → rooms/

Source files live in `src/meta/world/` but are served from `meta/rooms/` in the static site. This is intentional:
- `world/` is the engine convention (rooms define the game world)
- `rooms/` is the URL convention (clearer, matches what the JIT loader fetches)
- The build script handles the mapping

---

## Running the Build

### Full Build

```powershell
# From repo root
.\web\build-engine.ps1
.\web\build-meta.ps1

# Copy static assets
Copy-Item web\index.html web\dist\
Copy-Item web\bootstrapper.js web\dist\
Copy-Item web\game-adapter.lua web\dist\
```

### Incremental Build

For development, only rebuild what changed:

```powershell
# Engine code changed? Rebuild engine bundle
.\web\build-engine.ps1

# Meta files changed? Rebuild meta tree
.\web\build-meta.ps1

# Only one object changed? Manual copy (for speed)
# But prefer running the full build-meta.ps1 — it's fast
```

### Expected Output

```
=== build-engine.ps1 ===
Bundling 47 engine files + 3 asset files...
  engine.lua:    990 KB (raw)
  engine.lua.gz: 502 KB (compressed, 50.7% ratio)
Done.

=== build-meta.ps1 ===
Copying meta files to web/dist/meta/...
  Objects:   82 files → meta/objects/ (renamed by GUID)
  Rooms:      7 files → meta/rooms/
  Levels:     1 files → meta/levels/
  Templates:  5 files → meta/templates/
  Total:     95 files
Done.
```

---

## GUID Validation

Both scripts should validate GUID format on all meta files:

**Format:** Windows-style GUID (UUID v4): `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`  
**Pattern:** `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`

| Meta Type | GUID Required? | Action on Missing GUID |
|-----------|---------------|----------------------|
| Objects | YES | WARN and skip (object won't be loadable) |
| Rooms | YES | WARN (room still copied by room-id) |
| Levels | YES | WARN (level still copied by filename) |
| Templates | YES | WARN (template still copied by name) |

Every meta entity MUST have a `guid` field. This is already the case for all existing files. The build script validates this as a safety net.

---

## Deployment

The `web/dist/` directory maps directly to the GitHub Pages `/play/` path:

```
web/dist/index.html        → https://waynewalterberry.github.io/play/index.html
web/dist/bootstrapper.js   → https://waynewalterberry.github.io/play/bootstrapper.js
web/dist/engine.lua.gz     → https://waynewalterberry.github.io/play/engine.lua.gz
web/dist/meta/rooms/...    → https://waynewalterberry.github.io/play/meta/rooms/...
web/dist/meta/objects/...  → https://waynewalterberry.github.io/play/meta/objects/...
```

The deploy step (pushing to the GitHub Pages branch) is separate from the build. The build scripts produce the artifact; deployment is handled by the existing GitHub Pages workflow.

---

## Migration from build-bundle.ps1

The existing `web/build-bundle.ps1` is **replaced**, not modified:

| Old | New |
|-----|-----|
| `build-bundle.ps1` → `game-bundle.js` (16MB monolith) | `build-engine.ps1` → `engine.lua.gz` (~500KB) |
| All Lua files embedded as JS strings | Engine Lua bundled as pure Lua, compressed |
| Meta files included in bundle | `build-meta.ps1` → individual static files |
| Single `<script>` loads everything | `bootstrapper.js` orchestrates fetch+decompress |

`build-bundle.ps1` can be kept temporarily for comparison testing but should be removed once the three-layer system is validated.

---

## Implementation Notes for Smithers

1. **Start with build-engine.ps1** — the existing `build-bundle.ps1` has the file-walking and module-wrapping logic. Fork it, strip the meta files, output Lua instead of JS, add gzip compression.

2. **build-meta.ps1 is simple** — it's mostly `Copy-Item` with GUID extraction for objects. The tricky part is the GUID regex — test it against all object files to make sure none are missed.

3. **Test the compressed bundle locally** — decompress `engine.lua.gz` manually and verify it's valid Lua before wiring up the bootstrapper.

4. **The `world/` → `rooms/` rename** is intentional. Make sure the JIT loader uses `/play/meta/rooms/` (not `/play/meta/world/`).

5. **Clean builds** — always clear `web/dist/meta/` before running `build-meta.ps1`. Stale files from deleted objects will break the game.
