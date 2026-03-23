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

### 2026-03-23: Wave2 — CI Safety Guardrail & Decision Documentation

**Wave2 Spawn:** Scribe fixed CI workflow to prevent accidental deployments

**Changes Made:**
- **`.github/workflows/squad-main-guard.yml`** — Removed `main` from push trigger events. CI now only runs on pull_request and scheduled jobs. This prevents automated deployments from main branch pushes, requiring explicit PRs for deployment validation.

**Commit:** 5e366ee — CI workflow fix

**Cross-Agent Context:**
- Marge verified CI changes don't impact QA workflows
- Phase 3 deployments unaffected — deploy is still manual via web/deploy.ps1
- Next deploys will use safe PR workflow

**Impact Summary:**
- Deployment pipeline now requires explicit PR review before CI runs
- Reduced risk of accidental main-branch deployments
- Ready for sustained release/merge cycle

### 2026-03-23: Deploy — Effects Pipeline + New Objects + Parser Transforms
- **Timestamp:** 2026-03-23T11:21Z
- **Status:** ✅ COMPLETE — Deployed to GitHub Pages
- **Pages commit:** `f780c28` (main branch, 7 files changed, +991 lines)
- **Engine bundle:** 134.4 KB compressed (+3.7 KB from previous 130.7 KB), 28 engine files + 1 asset file
- **Meta files:** 92 total (79 objects (+1 new), 7 rooms, 5 templates, 1 level)
- **Cache-bust stamp:** `20260323112127` stamped into `bootstrapper.js` and `index.html`
- **Files deployed:** `index.html`, `bootstrapper.js`, `game-adapter.lua`, `engine.lua(.gz)`, 92 meta files
- **What shipped:**
  - Effects Pipeline (`effects.lua`) — EP1 through EP10 milestone
  - Poison bottle + bear trap objects refactored to use Effects Pipeline
  - 30+ parser phrase transforms (health, injury, inventory, appearance, wait)
  - All bug fixes from the 2026-03-23 session
- **Deploy method:** Used `web/deploy.ps1` — clean run, no Copy-Item issues this time
- **Verification:** Live site at `https://waynewalterberry.github.io/play/` returns HTTP 200 with correct cache-bust stamp

### 2026-03-23: Deploy — Play-test Bug Fixes (#40 #42 #43 #44)
- **Timestamp:** 2026-03-23T11:45Z
- **Status:** ✅ COMPLETE — Deployed to GitHub Pages
- **Pages commit:** `e1d5be4` (main branch, 5 files changed, +35 −6 lines)
- **Source commit:** `491f9a8` — Smithers' 4 bug fixes from Wayne's iPhone play-test session
- **Engine bundle:** 134.7 KB compressed, 92 meta files (79 objects, 7 rooms, 5 templates, 1 level)
- **Cache-bust stamp:** `20260323114535` stamped into `bootstrapper.js` and `index.html`
- **Files deployed:** `index.html`, `bootstrapper.js`, `engine.lua.gz`, 1 updated meta object (`d40b15e6-...`)
- ⚠️ **Copy-Item silent failure recurred:** `Remove-Item` + `Copy-Item` still didn't overwrite `index.html` and `bootstrapper.js` with new cache-bust stamps. Had to use `[System.IO.File]::Copy()` as workaround. The deploy script should be updated to use .NET file copy instead of PowerShell cmdlets.
- **What shipped (Smithers fixes):** Issues #40, #42, #43, #44 — play-test bug fixes from Wayne's iPhone session
- **Verification:** Live site at `https://waynewalterberry.github.io/play/` — pushed to GitHub Pages, CDN propagation 1–3 minutes

### 2026-03-23: Fixed Issue #45 — Status bar shows "7 matches" at game start
- **Problem:** Status bar right side displayed "Matches: 7  Candle: o" immediately at game start. Player starts empty-handed — the "7 matches" came from the matchbox object sitting on the start room table, found via a registry fallback search.
- **Root cause:** `src/engine/ui/status.lua` searched player hands → room surfaces → `ctx.registry:get("matchbox")` (fallback). The fallback always found the matchbox wherever it lived in the game world, counting its 7 match-object contents as if they were player inventory.
- **Fix:** Removed the entire 60+ line matchbox/candle search block from `status.create_updater()`. Replaced with health status — right side now shows `Health: X/Y` only when the player has injuries (blank at full health). Left side unchanged: level, room name, time.
- **Regression tests:** Added `test/ui/test-status-bar.lua` (11 tests) — verifies no inventory keywords appear, room/level/time shown, health hidden at full HP, health visible when injured, matchbox in registry doesn't leak into status bar. Added `test/ui/` to `test/run-tests.lua`.
- **Test suite:** 50/50 PASS (all existing + new).
- **Commit:** d73f034 — pushed to main.
- ⚠️ This is an engine-layer fix (Smithers' territory), but it directly impacts the web status bar via `game-adapter.lua` which calls `status.create_updater()`. No web-layer changes needed — the adapter passes through whatever left/right strings the engine provides.

### 2026-07-27: Fixed Issues #3 and #19 (verified #18)
- **#3 (P2) — Screen flicker during progressive object discovery:**
  - **Root cause:** Every `print()` call from Lua → `appendOutput()` in `bootstrapper.js` → individual `appendChild()` + `scrollTop = scrollHeight`, causing layout thrashing. During `feel` verb room scan, each discovered object gets its own `print()` call, triggering N+1 reflows.
  - **Fix:** DOM batching in `bootstrapper.js`. Added `_beginBatch()` / `_endBatch()` around command processing. During a batch, `appendOutput()` collects elements into a `DocumentFragment` instead of appending directly. After command processing completes, `requestAnimationFrame` flushes the fragment to the DOM with a single `appendChild` and one `scrollTop` assignment. Pre-command output (boot messages, welcome text) still appends immediately.
  - **Files changed:** `web/bootstrapper.js` (+30 lines)
- **#18 (P1) — Safari/iPhone aggressive caching:**
  - **Already fixed** in the 2026-07-27 session (see earlier history entry). Verified all three cache-busting layers still in place: (1) meta tags in `index.html`, (2) `CACHE_BUST` query strings on all fetched resources, (3) build auto-stamp in `build-engine.ps1`. No changes needed.
- **#19 (P2) — Move welcome/intro text from main.lua into level data:**
  - **Root cause:** Intro narrative ("You wake with a start...") was hardcoded in both `src/main.lua` (terminal) and `web/game-adapter.lua` (browser). Any text change required editing two files.
  - **Fix:** Added `intro` table to `src/meta/levels/level-01.lua` with fields: `title`, `subtitle`, `narrative` (array of lines), `help`. Updated `main.lua` to load level-01.lua and read intro from it. Updated `game-adapter.lua` to read intro from the already-fetched level data. Both fall back to hardcoded defaults if level data or intro field is missing.
  - **Files changed:** `src/meta/levels/level-01.lua` (+11 lines), `src/main.lua` (+20/-9 lines), `web/game-adapter.lua` (+14/-8 lines)
  - **Tests:** Added `test/rooms/test-level-intro.lua` — 11 tests covering intro structure validation, backward compatibility, and integration (headless mode outputs narrative from level data).
- **Test suite:** 60/60 PASSED (59 existing + 1 new).
- **Commit:** c3b890c — pushed to main.
- ⚠️ Issues #3 and #19 left open for Marge to verify and close. #18 already verified.

### 2026-03-23: Full Clean Rebuild + Deploy — Pipeline Integrity Audit
- **Timestamp:** 2026-03-23T14:17Z
- **Status:** ✅ COMPLETE — Clean rebuild deployed, all fixes verified
- **Pages commit:** `54115fb` (main branch, 5 files changed)
- **Engine bundle:** 139.2 KB compressed (903.2 KB raw), 28 engine files + 1 asset file
- **Meta files:** 93 total (80 objects, 7 rooms, 5 templates, 1 level)
- **Cache-bust stamp:** `20260323141706` stamped into `bootstrapper.js` and `index.html`
- **Total files deployed:** 98
- **Pipeline investigation findings:**
  - ✅ `build-engine.ps1` correctly bundles ALL 28 `src/engine/*.lua` files (recursive) into `engine.lua.gz` via `package.preload` entries
  - ✅ `build-meta.ps1` correctly copies all objects (by GUID), rooms, levels, templates
  - ✅ `deploy.ps1` uses Remove-Item + Copy-Item pattern (fix for #25 silent overwrite bug)
  - ✅ No stale files — dist/ was deleted and rebuilt from scratch
  - ✅ File counts match: dist/ = 98, play/ = 98
  - ✅ No source files modified after the previous build (no gap detected)
  - ⚠️ The previous build (14:03) was actually already in sync with Pages — the "gap" Wayne experienced may have been CDN propagation delay or browser cache
- **Fix spot-checks (all PRESENT in deployed engine.lua.gz):**
  - ✅ #63: `narrator.lua` — "On top of the" surface narration (2 matches)
  - ✅ #66: `verbs/init.lua` — effects.process self-infliction handler (1 match)
  - ✅ #71: `parser/fuzzy.lua` — 0.75 length ratio threshold (2 matches)
- **Conclusion:** No systemic deploy gap found. The pipeline (`build-engine.ps1` → `build-meta.ps1` → `deploy.ps1`) correctly propagates ALL src/ changes to the live site. The perceived gap was likely CDN cache (1-3 min propagation) or mobile Safari aggressive caching (mitigated by cache-bust stamps).

### 2026-03-23: Deploy — #63 search fixes, 6 deep-nesting rooms, #68 #74 parser fixes
- **Timestamp:** 2026-03-23T15:11Z
- **Status:** ✅ COMPLETE — Deployed to GitHub Pages
- **Pages commit:** `0268114` (main branch, 12 files changed, +219 −85 lines)
- **Engine bundle:** 140 KB compressed (907.1 KB raw), 28 engine files + 1 asset file
- **Meta files:** 101 total (81 objects, 7 rooms, 5 templates, 1 level, 7 injuries)
- **Cache-bust stamp:** `20260323151146` stamped into `bootstrapper.js` and `index.html`
- **Total files deployed:** 106
- **What shipped:**
  - Nelson: #63 targeted search surface narration + deterministic ordering (d849d69)
  - Flanders: 6 rooms converted to deep nesting (cellar, courtyard, crypt, deep-cellar, hallway, storage-cellar)
  - Smithers: #68 category synonym matching, #74 composite child preference (6cad8d0)
- **Deploy method:** Used `web/deploy.ps1` — clean run, no issues
- **Verification:** Pushed to GitHub Pages, CDN propagation 1–3 minutes

### 2026-03-23: Fixed Issue #72 — Search text trickle effect
- **Problem:** Search results dumped all output lines at once as a block. Felt instantaneous rather than like real-time discovery.
- **Root cause:** DOM batching (#3) collects all `appendOutput()` calls during command processing into a `DocumentFragment`, then flushes everything in one `requestAnimationFrame`. For search commands, this means 5–15 narrative lines appear simultaneously.
- **Fix:** Added a search-specific trickle system to `web/bootstrapper.js`:
  1. **Detection:** Regex-based command matching — `/^(search|find)\b/i` and `/^look\s+(for|in)\b/i`
  2. **Scheduling:** After command processing, collected nodes are released one at a time via `setTimeout` with 350ms gaps
  3. **Cancellation:** If the user enters a new command while trickle is active, all pending nodes are flushed immediately to avoid visual glitches
  4. Non-search commands still use instant DOM batch flush (#3) — no regression
- **Files changed:** `web/bootstrapper.js` (+68 lines)
- **Regression tests:** Added `test/web/test-search-trickle.js` (22 tests) — validates search/find/look-for detection, negative cases (look, look at, go, take), word boundary enforcement, scheduling delays, cancel behavior
- **Test suite:** 65/65 Lua tests PASS, 22/22 JS tests PASS
- **Commit:** cc10a43 — pushed to main
- ⚠️ This is a presentation-layer-only change. No engine code modified. The engine still outputs all search lines synchronously; the trickle effect is purely in the JS display layer.
