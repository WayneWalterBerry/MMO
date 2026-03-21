# Versioning Architecture Decisions

**Filed by:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Design  
**Related Docs:** [docs/architecture/web/versioning.md](../../docs/architecture/web/versioning.md) · [docs/architecture/engine/versioning.md](../../docs/architecture/engine/versioning.md)

---

## D-VERSION001: Single Version Source

**Rationale:**  
All MMO components — CLI, engine, web — derive versions from a single file `src/version.lua`. This prevents inconsistency where the web shows one version and CLI shows another.

**Implementation:**
```lua
-- src/version.lua
return {
    bootstrapper = "1.0.0",
    engine = "0.3.1",
    meta = "0.1.0",
    game = "0.1.0",
}
```

---

## D-VERSION002: Semantic Versioning Per Component

**Rationale:**  
Each component (bootstrapper, engine, meta) changes at different rates. Independent versioning using semver (MAJOR.MINOR.PATCH) allows precise communication of change scope.

**Bumping Rules:**
- **Bootstrapper:** MAJOR on loader flow break; MINOR on features; PATCH on bugs
- **Engine:** MAJOR on verb/FSM overhaul; MINOR on system additions; PATCH on fixes
- **Meta:** MAJOR on schema break; MINOR on new content; PATCH on tweaks
- **Game:** Coordination point, typically aligns with engine or meta MAJOR bumps

---

## D-VERSION003: Content-Hash Query Params for Cache-Busting

**Rationale:**  
GitHub Pages caches static files for days. Query params (`?v=HASH`) force fresh downloads without changing version numbers. Hash is computed at build time; file changed → hash changed → new URL → fresh cache.

**Implementation:**
- Build scripts compute SHA256 hash (first 12 chars) of each file
- URLs rewritten to include hash: `/play/engine.lua.gz?v=9f8e7d6c5b4a`
- Different hash = different cache key = browser fetches fresh copy

**Benefit:** Aggressive caching (7 days) is now safe.

---

## D-VERSION004: Version Display in Bootstrap Messages

**Rationale:**  
Players should see version numbers in loading messages for troubleshooting and feedback. Transparentizes the loading process and helps diagnose stale cache issues.

**Implementation (Web):**
```
Loading Bootstrapper v1.0.0...
Loading Game Engine v0.3.1...
Decompressing Engine...
Initializing Game Engine v0.3.1...
```

**Implementation (CLI):**
```bash
$ lua src/main.lua --version
MMO 0.1.0 (engine: 0.3.1)
```

---

## D-VERSION005: Engine Version Applies to Both CLI and Web

**Rationale:**  
CLI and web run identical code from `src/engine/`. Both must use the same version number. No separate web-only engine version.

**Result:** Developers can test locally (CLI), deploy to web, and confidently state "both are running engine v0.3.1".

---

## D-VERSION006: Manifest File Optional (V2 Feature)

**Rationale:**  
A `versions.json` manifest allows client-side version checks without running Lua (e.g., "Update available" notifications). Not required for V1. Can be added later if needed.

**For V1:** Skip it. Content hashes + HTML refresh sufficient for cache-busting.

---

## Implementation Order

1. Create `src/version.lua` with initial versions
2. Add `--version` flag to CLI
3. Wire version into bootstrapper.js (embed at build time)
4. Update build scripts to compute content hashes
5. Rewrite URLs in index.html with hashes
6. Test both CLI and web

---

## Notes for Smithers

- Initial versions: `bootstrapper = "1.0.0"`, `engine = "0.1.0"`, `meta = "0.1.0"`, `game = "0.1.0"`
- Never reuse version numbers (always bump before release)
- Test CLI: `lua src/main.lua --version`
- Test web: Verify bootstrap messages show correct versions and hashes
