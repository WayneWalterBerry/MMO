# Gil — Web Engineer

## Core Context

- **Project:** MMO — text adventure game in pure Lua, deployed to browser via Fengari (Lua 5.3 in JavaScript)
- **Owner:** Wayne "Effe" Berry
- **My role:** Own the web build pipeline, deploys to GitHub Pages, and all web-specific code (HTML/CSS/JS/adapter)
- **Key skill:** `.squad/skills/web-publish/SKILL.md` — the deploy process bible
- **Live site:** https://waynewalterberry.github.io/play/ (unlisted, direct URL only)
- **Pages repo:** `../WayneWalterBerry.github.io` (separate repo, `play/` directory)

## Learnings

### 2026-03-22: Onboarding
- Joined the team. Previous deploys were handled by Smithers — taking over that responsibility.
- The web build has two steps: `web/build-engine.ps1` (engine bundle) and `web/build-meta.ps1` (meta files by GUID).
- Deploy copies index.html, bootstrapper.js, game-adapter.lua, and dist/* to the Pages repo.
- ⚠️ CRITICAL: Always copy index.html — it contains ALL CSS. Missing it causes stale styles.
- Headless mode (`--headless` flag) was just added by Bart — disables TUI for automated testing. May affect the web adapter — need to verify.
- Current deploy: commit 302a335 on Pages repo, 96 files, engine bundle 124.7 KB compressed.

### 2026-07-27: Fixed Issues #12 and #13
- **#12 — Copy button:** Added a clipboard SVG icon button (absolutely positioned top-right of `#terminal`). Uses `navigator.clipboard.writeText()` with a 1.5s checkmark feedback animation. Styled with `--dim`/`--border` vars to match the terminal theme. The `.copied` class flashes green (`#5f9`).
- **#13 — Bug report transcript truncation:** The engine's `report_bug` handler sends all 50 transcript entries in the GitHub issue URL body. GitHub truncates long URLs, so users saw welcome text instead of recent commands. Fixed in the web layer (not engine code): `window._openUrl` in `bootstrapper.js` now parses the URL, splits the transcript on `> ` command prefixes, and keeps only the last 3 blocks before opening.
- ⚠️ Key decision: Fixed #13 in the JS bridge layer (`_openUrl`) rather than modifying `src/engine/verbs/init.lua`, staying within my web-layer charter. The engine still sends all 50 entries — the web bridge trims to 3. Terminal users are unaffected.
- These changes need a deploy (index.html + bootstrapper.js) to go live. Wayne will request separately.

### 2026-07-27: Fixed Issue #18 — Safari/iPhone aggressive caching
- **Problem:** Safari on iPhone serves stale cached JS/Lua files even after a new deploy. Mobile Safari has no hard-refresh gesture, so users get stuck on old versions.
- **Root cause:** GitHub Pages serves static files with permissive cache headers, and Safari honors them aggressively. No cache-busting was in place.
- **Fix — three layers of cache-busting:**
  1. **Meta tags** in `index.html`: `Cache-Control: no-cache, no-store, must-revalidate` + `Pragma: no-cache` + `Expires: 0` — tells browsers not to cache the HTML page itself.
  2. **Query string cache-busting** on all fetched files: `bootstrapper.js?v=TIMESTAMP`, `engine.lua.gz?v=TIMESTAMP`, `game-adapter.lua?v=TIMESTAMP` — browsers see a "new" URL each deploy.
  3. **Automatic stamping** in `build-engine.ps1`: the build script writes the compact timestamp (`yyyyMMddHHmmss`) into both `bootstrapper.js` (`CACHE_BUST` constant) and `index.html` (script tag query string).
- ⚠️ The `CACHEBUST` placeholder in source files is replaced by the build. Don't commit a real timestamp manually — let the build do it.
- Updated `.squad/skills/web-publish/SKILL.md` with a new "Cache-Busting" section documenting the approach.
- Left Issue #18 open for Marge to verify and close.
