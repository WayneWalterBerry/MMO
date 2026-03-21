# SKILL: Web Publish

**Owner:** Smithers (UI Engineer)
**Trigger:** After `src/` changes pass all tests

## What This Does

Builds and deploys the browser-playable version of the game to GitHub Pages.
The web version uses Fengari (Lua 5.3 in JavaScript) to run the game engine
in-browser, with a terminal-style UI.

## When to Run

- After any changes to files under `src/` (engine, meta, assets)
- After test-pass confirms all tests pass
- Before announcing a new playtest build

## Build Steps

```bash
# 1. Rebuild the engine bundle (compresses to .gz)
powershell -File web/build-engine.ps1

# 2. Rebuild meta files (copies individual .lua files by GUID)
powershell -File web/build-meta.ps1
```

## Deploy Steps

```bash
# 3. Copy ALL web files to the GitHub Pages site
$pagesRepo = "../WayneWalterBerry.github.io"
$playDir   = "$pagesRepo/play"

# Create play/ directory if it doesn't exist
New-Item -ItemType Directory -Path $playDir -Force

# ⚠️ CRITICAL: Copy index.html EVERY TIME — it contains all CSS.
# This file was missed in a prior deploy and caused CSS fixes to not appear.
Copy-Item web/index.html       $playDir/
Copy-Item web/bootstrapper.js  $playDir/
Copy-Item web/game-adapter.lua $playDir/

# Copy all built/dist files (engine bundle, meta files, etc.)
Copy-Item web/dist/*           $playDir/ -Recurse -Force

# 4. Commit and push
cd $pagesRepo
git add play/
git commit -m "Update web playtest build"
git push
```

## ⚠️ Deploy Checklist

Every deploy MUST copy these files (miss one and the site breaks or shows stale content):

| File | Contains | Changes when |
|------|----------|-------------|
| `web/index.html` | **ALL CSS**, DOM structure, boot script | CSS fixes, layout changes, new UI elements |
| `web/bootstrapper.js` | JS engine, bold rendering, debug flag, echo styling | JS behavior changes, formatting fixes |
| `web/game-adapter.lua` | Lua↔browser bridge, coroutine loop, JIT loader | Engine integration changes |
| `web/dist/*` | Engine bundle (.gz), meta .lua files | Any `src/` changes |

## Hidden Link Pattern

The web build is intentionally unlisted:

- **`<meta name="robots" content="noindex">`** — Search engines won't index it
- **No navigation links** — The blog has no links to `/play/`
- **Direct URL only** — Share `https://waynewalterberry.github.io/play/` with
  beta testers directly

## File Inventory

| File | Role | Regenerate? |
|------|------|-------------|
| `web/index.html` | Terminal UI page | Manual edits only |
| `web/game-adapter.lua` | Lua↔browser bridge | Manual edits only |
| `web/build-bundle.ps1` | Bundle generator | N/A (it's the tool) |
| `web/game-bundle.js` | All game source files | **Yes — run build-bundle.ps1** |

## Verification

After deploying, open the URL and verify:
1. The terminal UI loads (dark background, blinking "Loading..." text)
2. The welcome message appears ("You wake with a start...")
3. Basic commands work: `feel`, `help`, `look`

## Troubleshooting

- **"Failed to load game engine"** — Check browser console for errors. Usually
  a Lua module that failed to load from the VFS.
- **Blank page** — Fengari CDN might be down. Check network tab.
- **Bundle too large** — The embedding-index.json (15 MB) dominates. Can be
  stripped for a lighter build (loses Tier 2 natural language parsing).

## Architecture Reference

See `web/README.md` for detailed technical architecture of the Fengari adapter,
coroutine-based game loop, and virtual file system.
