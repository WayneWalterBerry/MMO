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
