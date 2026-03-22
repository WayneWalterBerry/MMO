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

### 2026-07-27: Full Deploy — Issues #12, #13, #14, #15, #16, #17, #18
- Deployed to GitHub Pages commit `392e549` (96 files in `play/`).
- Engine bundle: 126 KB compressed, 91 meta files (78 objects, 7 rooms, 5 templates, 1 level).
- Cache-bust timestamp `20260322131103` stamped into `bootstrapper.js` and `index.html`.
- **What shipped:**
  - Gil: Copy button (#12), bug report transcript fix (#13), Safari cache-busting (#18)
  - Smithers: Whole room parser (#14), lit candle (#15), compound errors (#16), GOAP narration (#17)
  - CBG: 5 design docs, Bart: 2 architecture docs (no runtime impact, bundled in engine)
- All 5 deploy-checklist files copied: `index.html`, `bootstrapper.js`, `game-adapter.lua`, `engine.lua.gz`, `meta/*`
- ⚠️ First copy of `bootstrapper.js` and `index.html` silently didn't overwrite (identical LastWriteTime?). Had to re-copy individually to get the cache-bust stamps to land. Watch for this in future deploys.

### 2026-03-22 (Afternoon): Phase 7 Completion — First Assignment
- **Timestamp:** 2026-03-22T20:05Z
- **Status:** ✅ COMPLETE — All web bugs fixed, live deployment complete
- **Assignment Summary:** Fixed 3 web issues in first assignment as new Web Engineer
  1. **Issue #12:** Copy button rendering in terminal (SVG icon, clipboard API, feedback animation)
  2. **Issue #13:** Bug report truncation (web bridge transcript trim to last 3 entries)
  3. **Issue #18:** Safari cache-busting (meta tags + query strings + build auto-stamp)
- **Deploy Status:** ✅ Live site deployed with all fixes
- **Testing:** Nelson Pass 035: 50/50 PASS, zero hangs with --headless mode
- **Next Phase:** Ready for ongoing web layer support and maintenance

### 2026-03-22: Deploy Phase 3 — hit verb, unconsciousness, mirror
- **Timestamp:** 2026-03-22T14:46Z
- **Status:** ✅ COMPLETE — Phase 3 deployed to GitHub Pages
- **Pages commit:** `087cee6` (main branch, 6 files changed, +564 lines)
- **Engine bundle:** 130.7 KB compressed (+4.8 KB from previous 126 KB), 91 meta files (78 objects, 7 rooms, 5 templates, 1 level)
- **Cache-bust stamp:** `20260322144632` stamped into `bootstrapper.js` and `index.html`
- **Files deployed:** `index.html`, `bootstrapper.js`, `game-adapter.lua`, `engine.lua(.gz)`, 1 new meta object (`eda1257d-...`)
- ⚠️ **Recurring issue:** `Copy-Item -Force` silently failed to overwrite `index.html` and `bootstrapper.js` again (same as 2026-07-27 deploy). Workaround: `Remove-Item` first, then `Copy-Item`. This should be scripted into the deploy process.
- **What shipped (Smithers Phase 3):** hit verb, unconsciousness system, mirror object
- **Verification:** Live site at `https://waynewalterberry.github.io/play/` returns HTTP 200. CDN propagation may delay new stamp by 1–3 minutes.

### 2026-07-27: Fixed Issues #25 and #20
- **#25 (P0) — Deploy Copy-Item silent failure:** `Copy-Item -Force` silently fails to overwrite files on Windows. Fixed `web/deploy.ps1` to `Remove-Item` before `Copy-Item` for static assets (index.html, bootstrapper.js, game-adapter.lua). Updated `.squad/skills/web-publish/SKILL.md` deploy steps with the same pattern. The recurring workaround from two previous deploys is now permanent.
- **#20 (P1) — Bug report transcript only captures 1 line:** Follow-up to #13. The Lua-side transcript recorded full output but the JS bridge had no independent buffer. Added a JS-side session transcript buffer to `web/bootstrapper.js` that groups all `appendOutput` calls between `>` prompts as one response block. `_openUrl` now uses this buffer (with accurate multi-line responses) instead of parsing the Lua-generated transcript text. Falls back to original #13 regex logic if JS buffer is empty.
- Both issues left open for Marge to verify and close.
