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
