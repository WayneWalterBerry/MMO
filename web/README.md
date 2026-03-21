# Web Wrapper — Fengari Browser Build

Play THE BEDROOM in a web browser using [Fengari](https://fengari.io/) (Lua 5.3 VM in JavaScript).

## Quick Start

```bash
# 1. Build the game bundle (from repo root)
powershell web/build-bundle.ps1

# 2. Serve locally
cd web && python -m http.server 8080

# 3. Open http://localhost:8080 in your browser
```

## Architecture

```
Browser
  ├── index.html ........... Terminal UI (dark theme, monospace, command history)
  ├── game-bundle.js ....... All src/ files bundled as JS strings (auto-generated)
  ├── game-adapter.lua ..... Bridges game engine → browser (Fengari Lua)
  └── (CDN) fengari-web.js . Lua 5.3 VM that runs in JavaScript
```

### How It Works

1. **Virtual File System** — `build-bundle.ps1` reads all `.lua` and `.json` files
   under `src/` and generates `game-bundle.js`, a JS object mapping file paths to
   source strings. The Lua adapter reads from this instead of the filesystem.

2. **Module Loading** — A custom `package.searcher` resolves `require()` calls
   against the VFS. Engine modules like `engine.registry` map to
   `src/engine/registry/init.lua` in the bundle.

3. **I/O Overrides** — `io.open()`, `io.popen()`, `io.read()`, `io.write()`,
   `io.stderr`, and `os.exit()` are all overridden for browser compatibility.

4. **Coroutine Game Loop** — The existing game loop (`engine.loop`) runs inside a
   Lua coroutine. When it calls `io.read()`, the coroutine yields. When the player
   types a command, JavaScript resumes the coroutine with their input. This reuses
   the **existing loop code unchanged**.

5. **Print → DOM** — `print()` is overridden to append `<div>` elements to the
   scrollable output area. Word-wrapping is handled by `engine.display`.

### File Inventory

| File | Generated? | Description |
|------|-----------|-------------|
| `index.html` | No | Terminal UI, CSS, JS event handling |
| `game-adapter.lua` | No | Lua adapter (VFS, I/O overrides, game init, coroutine) |
| `build-bundle.ps1` | No | Build script that generates the bundle |
| `game-bundle.js` | **Yes** | All source files as JS strings (~16 MB raw, ~3 MB gzipped) |

## Bundle Size

The bundle is ~16 MB uncompressed, dominated by `embedding-index.json` (15.6 MB
phrase dictionary for the Tier 2 parser). GitHub Pages serves gzip-compressed
responses, bringing transfer size down to ~2-3 MB.

**To reduce size further:**
- Strip the embedding index (loses Tier 2 natural language parsing; Tier 1 exact
  verb dispatch still covers ~70% of commands)
- Build a slimmed-down phrase dictionary for web

## Deployment to GitHub Pages

```bash
# Build the bundle
powershell web/build-bundle.ps1

# Copy to the GitHub Pages repo
cp web/index.html       ../WayneWalterBerry.github.io/play/
cp web/game-adapter.lua ../WayneWalterBerry.github.io/play/
cp web/game-bundle.js   ../WayneWalterBerry.github.io/play/

# Commit and push
cd ../WayneWalterBerry.github.io
git add play/
git commit -m "Update web playtest build"
git push
```

The game will be available at: `https://waynewalterberry.github.io/play/`

**Hidden link pattern:** The page has `<meta name="robots" content="noindex">` and
no navigation links from the blog. Only people given the direct URL can find it.

## Known Issues & Future Work

### Fengari Calling Conventions
When JavaScript calls a Lua function stored on `window`, Fengari may pass an
implicit `self` parameter. The adapter handles both `(text)` and `(self, text)`
calling conventions. If commands appear as `[object Window]`, the calling
convention detection may need adjustment.

### Bundle Rebuild Required
After any changes to `src/`, run `build-bundle.ps1` again. The bundle is not
auto-generated — this is deliberate (no build toolchain dependency).

### Parser Tier 2 Compatibility
The embedding matcher reads `embedding-index.json` via `io.open`. The VFS
override handles this, but if the JSON parsing fails in Fengari (edge cases
with the custom `engine.parser.json` module), Tier 2 will gracefully degrade
and the game falls back to Tier 1 exact verb matching.

### Terminal UI Module
The `engine.ui` module (ANSI split-screen terminal) is stubbed out for the web
build. The browser's HTML/CSS terminal replaces it entirely.

### No Save/Load
Game state is in-memory only. Refreshing the page restarts. Future work:
serialize game state to `localStorage`.
