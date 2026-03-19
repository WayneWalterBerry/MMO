---
name: "lua-browser-embedding"
description: "How to embed and run Lua in web browsers via WebAssembly or JavaScript"
domain: "architecture"
confidence: "high"
source: "earned — researched for MMO project hosting platform decision"
---

## Context
When a project uses Lua as its engine/scripting language and needs to run in a web browser (for PWA, web app, or as a step toward mobile via Capacitor/WebView wrapping).

## Patterns

### Option 1: Wasmoon (Recommended)
- npm: `wasmoon` — compiles official Lua 5.4 C source to WASM via Emscripten
- 25x faster than Fengari for compute-heavy tasks
- Full Lua 5.4 semantics including coroutines
- Clean JS↔Lua interop: expose JS functions as Lua globals, extract Lua globals into JS
- Bundle: ~1-2.5MB WASM binary (cached after first load)
- Pattern: `const lua = await new LuaFactory().createEngine()` → `lua.global.set(name, fn)` → `lua.doString(code)`

### Option 2: Fengari (Fallback)
- npm: `fengari` — Lua 5.3 reimplemented in pure JavaScript
- Slower (10-20x vs native) but smaller bundle (~200KB)
- Best JS interop (shared runtime) — can manipulate DOM directly from Lua
- Use when WASM is unavailable or bundle size is critical

### PWA Wrapping for Mobile
- Add `manifest.json` + service worker → installable on phone home screens
- Capacitor (`@capacitor/core`) wraps any web app as native iOS/Android for app stores
- Same codebase serves web, PWA, and native app

## Examples
```javascript
// Wasmoon: Load Lua engine in browser
import { LuaFactory } from "wasmoon";
const lua = await new LuaFactory().createEngine();
lua.global.set("host_print", (text) => document.getElementById("output").innerHTML += text);
await lua.doString(luaEngineCode);
await lua.doString('process_command("look")');
```

## Anti-Patterns
- **Don't use LÖVE/Love2D for text-heavy games** — it's graphics-oriented, poor text layout
- **Don't build native Swift/Kotlin + Lua C bindings** for a text adventure — HTML/CSS is a superior text renderer
- **Don't use Fengari if you need Lua 5.4 features** — it only supports 5.3
- **Don't poll for input in a game loop** — use event-driven browser patterns (addEventListener)
