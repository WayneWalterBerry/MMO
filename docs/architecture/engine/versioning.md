# Engine & Game Versioning

**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Active  
**Related Docs:** [../web/versioning.md](../web/versioning.md)

---

## Overview

All MMO components — CLI, engine, web — use **timestamp-based versioning**. The build timestamp IS the version. No manual version tracking, no `src/version.lua` to maintain. Just build and deploy.

---

## Version Source: Build Timestamp

### Single Source of Truth

The build script captures the current timestamp when it runs. That timestamp is embedded everywhere:

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"        # "2026-03-21 16:45" (human-readable)
$timestampCompact = Get-Date -Format "yyyyMMddHHmmss"   # "20260321164500" (compact for URLs)
```

**No `src/version.lua` file needed.** The build process generates the version automatically.

### Timestamp Formats

| Use | Format | Example |
|-----|--------|---------|
| **User-facing UI** | ISO 8601, human-readable | `2026-03-21 16:45` |
| **Cache-busting URLs** | Compact | `20260321164500` |
| **Storage/Comparison** | Compact | `20260321164500` |

---

## CLI Usage

### Command

```bash
lua src/main.lua --version
```

### Output

```
MMO built 2026-03-21 16:45
```

### Implementation

The build script embeds the timestamp into a generated constant or file that `src/main.lua` reads:

```lua
-- src/main.lua (early, before game loop)

if arg[1] == "--version" then
    local buildTimestamp = "2026-03-21 16:45"  -- Embedded at build time
    print("MMO built " .. buildTimestamp)
    os.exit(0)
end
```

**Alternatively, generate a file at build time:**

```lua
-- src/main.lua
if arg[1] == "--version" then
    -- Read from generated file or constant
    local file = io.open("src/.build-timestamp", "r")
    local timestamp = file:read("*a"):match("^%s*(.-)%s*$")  -- trim
    file:close()
    print("MMO built " .. timestamp)
    os.exit(0)
end
```

**Build script generates `src/.build-timestamp`:**

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
Set-Content -Path "src/.build-timestamp" -Value $timestamp
```

---

## Web Integration

### Bootstrapper Messages

The web bootstrapper shows the build timestamp in loading messages:

```
Loading Bootstrapper (2026-03-21 16:45)...
Loading Game Engine (2026-03-21 16:45)...
Initializing Game Engine (2026-03-21 16:45)...
```

### JIT Loader Messages

After engine loads, meta version appears in subsequent messages:

```
Loading Level 1 (2026-03-21 16:45)...
Ready (2026-03-21 16:45).
```

### Cache-Busting

Web uses timestamp query params for cache-busting:

```
/play/engine.lua.gz?t=20260321164500
/play/bootstrapper.js?t=20260321164500
```

See [../web/versioning.md](../web/versioning.md) for details.

---

## Release Lifecycle

### Scenario 1: Engine Bug Fix

1. Fix bug in `src/engine/parser/init.lua`
2. Run build script
3. Build captures new timestamp: `2026-03-21 17:00`
4. CLI: `lua src/main.lua --version` now shows `MMO built 2026-03-21 17:00`
5. Web: New bootstrap messages show `(2026-03-21 17:00)`

### Scenario 2: New Object Added

1. Add new object to `src/meta/objects/`
2. Run build script
3. Build captures timestamp: `2026-03-22 09:30`
4. Both CLI and web see updated timestamp

### Scenario 3: Major Release (New Level)

1. Implement Level 2 content in `src/meta/`
2. Implement new parser in `src/engine/`
3. Run build script
4. Single timestamp captures entire release
5. CLI and web both show new timestamp

---

## Timestamp Comparison

**To check if versions differ:**

```lua
local cachedTimestamp = "20260321164500"   -- From localStorage or cache
local serverTimestamp = "20260321170000"   -- From URL or manifest

if cachedTimestamp ~= serverTimestamp then
    -- Server has newer version, re-fetch
end
```

**To determine which is newer:**

```lua
if tonumber(serverTimestamp) > tonumber(cachedTimestamp) then
    print("Server version is newer")
else
    print("Cached version is newer")
end
```

Timestamps are naturally sortable. No complex version comparison logic needed.

---

## Testing Versions

### CLI

```bash
# Verify version command
lua src/main.lua --version

# Should output something like:
# MMO built 2026-03-21 16:45

# Verify local CLI test
lua src/main.lua --room start-room --no-ui
# Should work without version errors
```

### Web

```bash
# Check version messages in browser console
# 1. Load index.html
# 2. Open DevTools (F12)
# 3. Look for "Loading Bootstrapper (2026-03-21 16:45)..." messages
# 4. Verify timestamp matches build time
```

### Integration

```bash
# Verify CLI shows timestamp
lua -c "
local buildTimestamp = '2026-03-21 16:45'  -- Read from generated file in real implementation
print('Engine built: ' .. buildTimestamp)
"

# Should match the timestamp in web bootstrap messages
```

---

## Recommendations for Smithers

### V1 Implementation

1. Create `src/.build-timestamp` file (will be generated at build time)
2. Update build scripts to generate timestamp
3. Add `--version` flag to `src/main.lua` to read `src/.build-timestamp`
4. Test CLI: `lua src/main.lua --version`
5. Wire timestamp into web bootstrapper
6. DELETE `src/version.lua` (no longer needed)

### Ongoing

- Just run the build script
- Each build automatically captures the timestamp
- No manual version maintenance
- CLI and web both show the same build timestamp

---

## FAQ

**Q: What version should I use for initial release?**  
A: Just run the build script. It captures the current timestamp. That IS the version.

**Q: Can I have different versions for web vs. CLI?**  
A: No — both run the same code. They share the same build timestamp. When you build, that's the version for everything.

**Q: Should I bump the version for every commit?**  
A: No — you only bump the version (by building) when you deploy. Development builds on your machine can have any timestamp; only deployed builds matter.

**Q: Where do I store the version number?**  
A: Generated at build time. No manual storage needed. Web: embedded in bootstrapper.js and URLs. CLI: read from `src/.build-timestamp` at startup.

**Q: What if I accidentally build twice?**  
A: Both builds get different timestamps (differ in seconds). Both are valid versions. Pick which one to deploy.

**Q: How do I revert a deployment?**  
A: Check out the previous code, rebuild, and re-deploy. New build = new timestamp = clean deployment.

---

## Summary

| Aspect | Solution |
|--------|----------|
| **Version source** | Build script (automatic) |
| **Version format** | Timestamp (human-readable: `2026-03-21 16:45`, compact: `20260321164500`) |
| **Where stored** | Embedded in web files and URL params; read from generated file in CLI |
| **Maintenance** | Zero — build is the version |
| **CLI** | `lua src/main.lua --version` shows `MMO built 2026-03-21 16:45` |
| **Web** | Bootstrap shows `(2026-03-21 16:45)` in messages |
| **Cache-busting** | Timestamp query params (e.g., `?t=20260321164500`) |

This eliminates version tracking overhead. Build once, timestamp is captured everywhere, done.
