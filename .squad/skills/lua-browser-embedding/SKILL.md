---
name: "lua-browser-embedding"
description: "How to embed and run Lua in web browsers via WebAssembly or JavaScript"
domain: "architecture"
confidence: "high"
source: "earned — researched for MMO project hosting platform decision + PWA/Wasmoon deep-dive (2025-07-24)"
---

## Context
When a project uses Lua as its engine/scripting language and needs to run in a web browser (for PWA, web app, or as a step toward mobile via Capacitor/WebView wrapping).

## Patterns

### Option 1: Wasmoon (Recommended)
- npm: `wasmoon` — compiles official Lua 5.4 C source to WASM via Emscripten
- 25x faster than Fengari for compute-heavy tasks
- Full Lua 5.4 semantics including coroutines
- Clean JS↔Lua interop: expose JS functions as Lua globals, extract Lua globals into JS
- Bundle: ~393KB raw / ~130KB gzipped WASM binary (cached after first load)
- Pattern: `const lua = await new LuaFactory().createEngine()` → `lua.global.set(name, fn)` → `lua.doString(code)`

### Wasmoon File System (Emscripten VFS)
- `factory.mountFile(path, content)` writes files into in-memory VFS before engine creation
- Standard `io.open()` and `require()` work against mounted files
- Set `package.path = "/?.lua;/?/init.lua"` to find mounted modules
- `io.popen()` does NOT work (no shell in browser) — provide file lists from JS
- Bundle strategy: build-time script reads all .lua → embeds as JS string constants → mountFile at startup

### Wasmoon JS↔Lua Bridge
- `lua.global.set('print', (...args) => { ... })` — override Lua globals with JS functions
- `lua.global.get('fnName')` — extract Lua functions callable from JS
- `await lua.doString(code)` — execute Lua code (returns promise)
- Promises: call `:await()` on a JS promise from Lua
- Limitation: cannot `await` inside a JS→Lua callback (use coroutine workaround if needed)

### Blocking REPL → Event-Driven Browser Pattern
- Don't run `while true do io.read() end` in browser
- Instead: expose `process_command(input)` as Lua global, call from JS on form submit
- Override `print`/`io.write` to append to DOM element
- Create a browser-specific entry point (`main_browser.lua`) — don't modify the terminal version

### Option 2: Fengari (Fallback)
- npm: `fengari` — Lua 5.3 reimplemented in pure JavaScript
- Slower (10-20x vs native) but smaller bundle (~214KB raw / ~69KB gzipped)
- Best JS interop (shared runtime) — can manipulate DOM directly from Lua
- Use when WASM is unavailable or bundle size is critical

### PWA Wrapping for Mobile
- Add `manifest.json` + service worker → installable on phone home screens
- Capacitor (`@capacitor/core`) wraps any web app as native iOS/Android for app stores
- Same codebase serves web, PWA, and native app
- Service worker caches all assets for offline play — no server needed after first load

## Examples
```javascript
// Wasmoon: Mount Lua files and create engine
import { LuaFactory } from "wasmoon";
const factory = new LuaFactory();
await factory.mountFile('engine/registry/init.lua', registrySource);
await factory.mountFile('engine/loader/init.lua', loaderSource);
const lua = await factory.createEngine();
await lua.doString('package.path = "/?.lua;/?/init.lua"');

// Override print for DOM output
lua.global.set("print", (...args) => {
  document.getElementById("output").textContent += args.join('\t') + '\n';
});

// Run game, expose command handler
await lua.doString(mainBrowserLuaSource);
document.getElementById('form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const input = document.getElementById('input').value;
  await lua.doString(`process_command("${input.replace(/"/g, '\\"')}")`);
});
```

## Anti-Patterns
- **Don't use LÖVE/Love2D for text-heavy games** — it's graphics-oriented, poor text layout
- **Don't build native Swift/Kotlin + Lua C bindings** for a text adventure — HTML/CSS is a superior text renderer
- **Don't use Fengari if you need Lua 5.4 features** — it only supports 5.3
- **Don't poll for input in a game loop** — use event-driven browser patterns (addEventListener)
- **Don't modify the terminal entry point** — create a browser-specific `main_browser.lua` instead
- **Don't try to use `io.popen` in browser** — generate file manifests at build time
