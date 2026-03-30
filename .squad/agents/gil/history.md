# Gil — Web Engineer

## Core Context

- **Project:** MMO — text adventure game in pure Lua, deployed to browser via Fengari (Lua 5.3 in JavaScript)
- **Owner:** Wayne "Effe" Berry
- **My role:** Own the web build pipeline, deploys to GitHub Pages, and all web-specific code (HTML/CSS/JS/adapter)
- **Key skill:** `.squad/skills/web-publish/SKILL.md` — the deploy process bible
- **Live site:** https://waynewalterberry.github.io/play/ (unlisted, direct URL only)
- **Pages repo:** `../WayneWalterBery.github.io` (separate repo, `play/` directory)

## Learnings

- **2026-03-28:** Full deploy completed. Build: 72 engine files + 204 meta files (141 objects, 7 rooms). 211 files copied to Pages repo. Commit `2f5f7af`. All four critical files (index.html, bootstrapper.js, game-adapter.lua, engine.lua.gz) verified on GitHub via API. Pages status: built. Cache-bust timestamp: `20260328041230`. New files this deploy: `stress.lua` (injury), `silk.lua` (material), 18 new object files.

- **WAVE-2 CI Integration (2026-08-23):** 
  - **Deliverable 1:** `.github/workflows/squad-ci.yml` — GitHub Actions workflow
    - Job: `mutation-lint` (runs on push to main + PR)
    - Triggers: `mutation-edge-check` + tests via pre-deploy gate
    - Exit code: 0 (all targets pass lint), non-zero (failures)
  - **Deliverable 2:** `test/run-before-deploy.ps1` — PowerShell pre-deployment gate
    - Runs `scripts/mutation-lint.ps1` (mutation-edge-check + lint.py)
    - Runs `lua test/run-tests.lua` (full test suite)
    - Sequential execution — must pass both to deploy
  - **Deliverable 3:** `.gitattributes` — normalize line endings (CRLF/LF consistency)
    - Prevents CI line-ending failures across platforms
  - **Deliverable 4:** Updated `.squad/agents/gil/history.md` — session append
  - **Session commit:** 8cb7181 (ci: WAVE-2 mutation edge check in CI + pre-deploy gate)
  - **Key decisions:** Pre-deploy gate MUST run before push (prevents CI failures). `.gitattributes` normalized all shell scripts (*.sh) to LF, PowerShell (*.ps1) to CRLF.

- **Deploy Workflow (squad-deploy.yml):**
  - **Deliverable:** `.github/workflows/squad-deploy.yml` — auto-deploy on merge to main
  - **Trigger:** `push` to `main` (fires after PR merge)
  - **Jobs:** `test` (sharded, mirrors squad-ci.yml) → `build-and-deploy` (pwsh build scripts → Pages push)
  - **Deploy target:** `WayneWalterBerry/WayneWalterBerry.github.io` repo, `play/` directory
  - **Secret required:** `PAGES_DEPLOY_TOKEN` — fine-grained PAT with Contents (read+write) on the Pages repo
  - **Deploy checklist files:** index.html, bootstrapper.js, game-adapter.lua, web/dist/* (per SKILL.md)
  - **Cache-busting:** BUILD_TIMESTAMP printed to Actions log for verification
  - **No-op guard:** Skips push if no files changed (idempotent deploys)
  - **Key pattern:** Uses `git clone --depth 1` with x-access-token auth for cross-repo push

- **2026-03-28 Full Deploy (Manual):** 
   - **Trigger:** Wayne "Effe" Berry — "Gil Deploy"
   - **Status:** ✓ SUCCESS
   - **Pipeline execution:**
     1. `lua test/run-tests.lua` — All 257 tests PASSED
     2. `powershell -File test/run-before-deploy.ps1` — Pre-deploy gate PASSED (mutation lint + tests)
     3. `powershell -File web/build-engine.ps1` — Engine bundle built (290.8 KB .gz, 1960.2 KB raw)
     4. `powershell -File web/build-meta.ps1` — Meta files built (208 total: 143 objects, 7 rooms, 5 creatures, 11 injuries, 32 materials, 8 templates, 1 level, 1 world)
   - **Deploy checklist (215 files total):**
     - ✓ index.html (6.3 KB) — CSS + DOM + boot script
     - ✓ bootstrapper.js (22.2 KB) — JS engine
     - ✓ game-adapter.lua (33.1 KB) — Lua↔browser bridge
     - ✓ engine.lua.gz (297.8 KB) — Engine bundle compressed
     - ✓ embedding-vectors.json.gz (4.8 MB) — Lazy-load embeddings for Tier 2 parsing
     - ✓ meta/* (209 files) — Object/room/creature/injury definitions by GUID
   - **GitHub commit:** `e9a023c` (pushed to `WayneWalterBerry/WayneWalterBerry.github.io` main)
   - **BUILD_TIMESTAMP:** `2026-03-28 18:11` (stamped in bootstrapper.js, game-adapter.lua)
   - **CACHE_BUST:** `20260328181100` (query string: `?v=20260328181100`)
   - **Live verification:**
     - Index: https://waynewalterberry.github.io/play/
     - Debug URL: https://waynewalterberry.github.io/play/?debug
     - Commit hash & timestamp visible in debug output on page load

- **WAVE-3c Multi-World Web Deploy (2026-03-29):**
  - **Trigger:** Wayne Berry (autonomous — Wayne at party, wants playable when he returns)
  - **Status:** ✓ BUILD SUCCESS — ready for deploy push
  - **Deliverable 1:** `web/build-meta.ps1` — Refactored for multi-world support
    - Discovers ALL worlds under `src/meta/worlds/` (manor + wyatt-world)
    - Objects/creatures from all worlds → flat `meta/{category}/{guid}.lua` (GUID-renamed, no conflicts)
    - Rooms from all worlds → flat `meta/rooms/{name}.lua` (no name collisions)
    - World definitions → `meta/worlds/{world_id}/world.lua` (per-world)
    - Levels → `meta/worlds/{world_id}/levels/` (per-world) + `meta/levels/` (manor backward compat)
    - Shared content (templates, materials) → unchanged
    - World-specific content (injuries) → merged into flat dirs
    - `_index.lua` manifest includes both worlds' rooms and world list
  - **Deliverable 2:** `web/game-adapter.lua` — World-aware level loading
    - Level loading now tries `meta/{content_root}/levels/level-01.lua` first
    - Falls back to `meta/levels/level-01.lua` for backward compat
    - World definition loading already worked (Bart WAVE-0)
    - `?world=wyatt-world` selects Wyatt's World; no param = manor
  - **Build output:** 283 total files (211 objects, 14 rooms, 2 worlds)
    - manor: 143 objects, 5 creatures, 7 rooms, 11 injuries, 1 level
    - wyatt-world: 68 objects, 7 rooms, 1 level
    - shared: 8 templates, 32 materials
  - **Verification:** `bootstrapper.js` reads `?world=` URL param → `window._selectedWorld` → adapter selects world → loads world-specific level → loads world-specific rooms/objects
  - **Backward compat:** Base URL (no `?world=`) still loads The Manor
  - **Tests:** 7,643 tests pass (277 files). 12 pre-existing failures (not related to this change).
  - **URLs:**
    - Manor: https://waynewalterberry.github.io/play/
    - Wyatt's World: https://waynewalterberry.github.io/play/?world=wyatt-world
    - Debug: https://waynewalterberry.github.io/play/?world=wyatt-world&debug

- **World URL Param Bug Fix (2026-03-29):**
  - **Trigger:** Wayne Berry — `?world=wyatt-world` URL loaded Manor instead of Wyatt's World
  - **Status:** ✓ CODE FIX COMMITTED + PUSHED
  - **Root cause diagnosis:**
    - Code flow in game-adapter.lua was structurally correct (world selection, content_root, level path all wired)
    - The dist (`web/dist/meta/worlds/wyatt-world/`) has all content: world.lua, levels/level-01.lua, 7 rooms, 68 objects
    - Most likely cause: WAVE-3c build was local-only ("ready for deploy push") and was never pushed to Pages repo
    - When world.lua 404s on the deployed site, the adapter silently fell back to Manor — zero console output, zero user error
  - **Fix 1: bootstrapper.js** — Added `console.log('[world] Selected world: ...')` (always fires, not just `?debug`)
  - **Fix 2: game-adapter.lua** — Added 7 `console.log("[world] ...")` messages throughout the world loading path:
    - `[world] Selected world: wyatt-world (from URL)` — which world was requested
    - `[world] Fetching: meta/worlds/wyatt-world/world.lua` — what URL is fetched
    - `[world] Content root: worlds/wyatt-world` — resolved content root
    - `[world] Level file: meta/worlds/wyatt-world/levels/level-01.lua` — level URL
    - `[world] Start room: beast-studio` — which room the game starts in
    - `[world] ...warn/error` messages when world or level not found
  - **Fix 3: User-visible error** — When `?world=X` is specified but world.lua 404s, shows: `"World 'X' not found. Loading The Manor instead."` (was completely silent before)
  - **Fix 4: Loading messages** — `"Loading Wyatt's World..."` instead of generic `"Loading Level 1..."` — uses world display name
  - **Tests:** 7,643 tests pass. 12 pre-existing failures unchanged (not related)
  - **Commit:** `b9b7106` (pushed to `WayneWalterBerry/MMO` main)
  - **NOTE:** A deploy push to Pages repo is still needed for `?world=wyatt-world` to work on the live site. The code is correct; the content must be deployed.

- **Options Module Bundle Fix (2026-03-30):**
  - **Trigger:** Wayne Berry — web build crashing with "module 'src.engine.options' not found"
  - **Status:** ✓ FIXED + PUSHED
  - **Root cause:** Module path inconsistency
    - `src/engine/verbs/options.lua` used `require("src.engine.options")`
    - `src/engine/options/init.lua` used `require("src.engine.parser.*")` and `require("src.engine.ui.presentation")`
    - `build-engine.ps1` strips `src.` prefix when creating `package.preload` entries (lines 55-78)
    - All other engine modules correctly use `require("engine.*")` format
    - This caused doubled path in error: `src/src/engine/options.lua`
  - **Fix:** Changed require statements to use `engine.*` format (not `src.engine.*`)
    - `src/engine/verbs/options.lua`: `require("src.engine.options")` → `require("engine.options")`
    - `src/engine/options/init.lua`: `require("src.engine.parser.goal_planner")` → `require("engine.parser.goal_planner")`
    - `src/engine/options/init.lua`: `require("src.engine.parser.context")` → `require("engine.parser.context")`
    - `src/engine/options/init.lua`: `require("src.engine.ui.presentation")` → `require("engine.ui.presentation")`
  - **Verification:**
    - Rebuilt engine bundle: 101 engine files (up from 100), 310.2 KB .gz
    - Confirmed `package.preload["engine.options"]` present in web/dist/engine.lua (line 8581)
    - No more `require("src.engine.*")` patterns in bundled code
    - All 7,687 tests pass (286 test files)
  - **Commit:** `d56160e` (pushed to main)
  - **Build artifacts:**
    - `web/dist/engine.lua.gz`: 310.2 KB (1960.2 KB raw)
    - `web/dist/embedding-vectors.json.gz`: 4813.6 KB
    - BUILD_TIMESTAMP: `2026-03-30 14:27`
    - CACHE_BUST: `20260330142742`
  - **Resolves:** RC-3 (Engine Bundle Stale — options module missing from web build)
  - **Next:** CI will auto-deploy to Pages repo via squad-deploy.yml workflow
