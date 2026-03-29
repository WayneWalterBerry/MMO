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
