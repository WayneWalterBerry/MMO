# PWA + Wasmoon Prototype Research

**Researcher:** Frink  
**Date:** 2025-07-24  
**Status:** Complete  
**Requested by:** Wayne "Effe" Berry

---

## Executive Summary

**Verdict: Highly viable.** Wasmoon can run this project's Lua engine in the browser with modest adaptation. The engine is pure Lua 5.4, has only 6 `require` calls (all pure Lua modules), no C extensions, and no external dependencies — this is close to the ideal Wasmoon use case. The main work is replacing filesystem I/O (`io.popen`, `io.open`, `io.read`) with browser-native equivalents via Wasmoon's JS↔Lua bridge. Total download: ~130KB gzipped WASM + bundled Lua sources (~50KB estimated). A working prototype could be built in a single session.

---

## 1. Wasmoon Viability

### What is Wasmoon?

Wasmoon compiles the **official Lua 5.4 C source** to WebAssembly via Emscripten. It is *not* a reimplementation — it's the real Lua VM running as WASM. This means full Lua 5.4 semantics including coroutines, metatables, string patterns, and all standard library functions.

### Compatibility with Our Engine

| Feature | Our Engine Uses | Wasmoon Supports | Notes |
|---------|----------------|-----------------|-------|
| Lua 5.4 | ✅ Yes | ✅ Yes | Official Lua 5.4 compiled to WASM |
| `require()` | 6 modules | ✅ Yes | Via Emscripten virtual FS or `package.preload` |
| `pcall()` | Yes (loader) | ✅ Yes | Full error handling |
| Metatables | Yes (objects) | ✅ Yes | Full metatable support |
| Coroutines | Not currently | ✅ Yes | Available if needed |
| String patterns | Yes (`match`, `gsub`, `find`) | ✅ Yes | Identical behavior |
| `table.*` | Extensively | ✅ Yes | All table functions |
| `math.*` | Minimally | ✅ Yes | All math functions |
| `io.open()` | Yes | ⚠️ Via VFS | Emscripten MEMFS — files must be pre-mounted |
| `io.popen()` | Yes | ❌ No | Shell commands don't exist in browser |
| `io.read()` | Yes (REPL) | ⚠️ Override | Must replace with JS bridge |
| `print()` | Yes | ⚠️ Override | Must redirect to DOM |
| `os.exit()` | Yes (fatal errors) | ❌ No | Replace with error display |
| `os.time()` | Yes | ✅ Yes | Works via Emscripten |
| `arg[0]` | Yes (path setup) | ❌ No | Not applicable — replace path setup |
| C extensions | None | N/A | Not an issue |

**Bottom line:** 90% of our code runs unmodified. The 10% that needs changes is concentrated in `main.lua`'s startup sequence (filesystem scanning, path setup, REPL loop).

### Lua Version

Wasmoon supports **Lua 5.4** — exactly what our engine targets. No version compatibility issues.

### Limitations

1. **No native C modules** — not an issue, we use none
2. **No real filesystem** — addressed via virtual FS (Section 3)
3. **No shell commands** (`io.popen`) — addressed via build-time manifest (Section 3)
4. **Async JS↔Lua boundary** — cannot `await` inside a Lua callback from JS (workaround: coroutine-based async pattern, but we don't need it for a text adventure)

---

## 2. Module Loading Strategy

### How Our Engine Loads Modules

The engine uses exactly **6 `require()` calls**, all in `main.lua`:

```lua
require("engine.registry")      -- engine/registry/init.lua
require("engine.loader")        -- engine/loader/init.lua
require("engine.mutation")      -- engine/mutation/init.lua
require("engine.containment")   -- engine/containment/init.lua
require("engine.loop")          -- engine/loop/init.lua
require("engine.verbs")         -- engine/verbs/init.lua
```

**No other files use `require`.** Each engine module is self-contained — no internal cross-requires. This is extremely favorable for bundling.

### Wasmoon Module Loading Options

**Option A: `mountFile` (Recommended)**

Wasmoon's `LuaFactory.mountFile()` writes files into Emscripten's in-memory filesystem (MEMFS) before the Lua VM starts:

```javascript
const factory = new LuaFactory();

// Mount engine modules
await factory.mountFile('engine/registry/init.lua', registrySource);
await factory.mountFile('engine/loader/init.lua', loaderSource);
await factory.mountFile('engine/mutation/init.lua', mutationSource);
await factory.mountFile('engine/containment/init.lua', containmentSource);
await factory.mountFile('engine/loop/init.lua', loopSource);
await factory.mountFile('engine/verbs/init.lua', verbsSource);

const lua = await factory.createEngine();

// Set package.path to find mounted files
await lua.doString('package.path = "/?.lua;/?/init.lua"');
```

**Option B: `package.preload` (Alternative)**

Register modules directly as JS-provided Lua functions:

```javascript
// Get the package.preload table and set loaders
await lua.doString(`
  package.preload["engine.registry"] = function()
    -- inline source or load from mounted file
  end
`);
```

**Option C: Inline all sources (Simplest for prototype)**

Concatenate all Lua source into one big string and `doString()` it. Since there are no circular dependencies and only 6 modules, this works:

```javascript
const allLua = registrySource + "\n" + loaderSource + "\n" + /* ... */ + mainSource;
await lua.doString(allLua);
```

### Recommended Bundling Strategy

**Use Option A (`mountFile`) for production, Option C (inline) for rapid prototype.**

Build-time step: A simple Node.js script reads all `.lua` files, embeds them as JS string constants in a `lua-bundle.js` file, and mounts them at startup. This preserves the module structure and makes debugging easier.

```javascript
// build-step output: lua-bundle.js
export const LUA_FILES = {
  "engine/registry/init.lua": `-- registry source here...`,
  "engine/loader/init.lua": `-- loader source here...`,
  "engine/verbs/init.lua": `-- verbs source here...`,
  // ... all files
};
```

At runtime:
```javascript
for (const [path, source] of Object.entries(LUA_FILES)) {
  await factory.mountFile(path, source);
}
```

---

## 3. File System

### The Problem

Our engine reads files from disk at startup:
1. **`read_file(path)`** — uses `io.open(path, "r")` to read `.lua` source files
2. **`list_lua_files(dir)`** — uses `io.popen("dir ...")` or `io.popen("ls ...")` to enumerate `.lua` files in a directory
3. **`package.path` setup** — uses `arg[0]` to find the script's directory

None of these work in a browser. There's no filesystem, no shell, and no `arg[0]`.

### Solution: Build-Time Manifest + Virtual FS

**Step 1: Build-time manifest generation**

A build script scans `src/meta/` and generates a JSON manifest:

```javascript
// build-manifest.js (runs at build time, not in browser)
const manifest = {
  templates: {
    "small-item.lua": "-- source...",
    "container.lua": "-- source...",
    "furniture.lua": "-- source...",
    "sheet.lua": "-- source...",
    "room.lua": "-- source..."
  },
  objects: {
    "matchbox.lua": "-- source...",
    "bed.lua": "-- source...",
    // ... all 37+ objects
  },
  world: {
    "start-room.lua": "-- source..."
  }
};
export default manifest;
```

**Step 2: Mount into Emscripten VFS at startup**

```javascript
for (const [dir, files] of Object.entries(manifest)) {
  for (const [filename, source] of Object.entries(files)) {
    await factory.mountFile(`meta/${dir}/${filename}`, source);
  }
}
```

**Step 3: Replace `list_lua_files` and `read_file` in main.lua**

Instead of modifying `main.lua` heavily, we can **override these functions from JS before running main.lua**:

```javascript
// Provide a file listing function that reads from the VFS
lua.global.set('_browser_list_files', (dir) => {
  return Object.keys(manifest[dir] || {});
});

lua.global.set('_browser_read_file', (path) => {
  // Already mounted in VFS, so io.open will work!
  return null; // Let Lua use io.open on VFS
});
```

Actually, since `mountFile` puts files in the Emscripten VFS, **`io.open` will work as-is** for reading. The only function that truly breaks is `io.popen` (directory listing) and `arg[0]` (path detection).

### Minimal Changes to main.lua

Create a **browser-specific entry point** (`main_browser.lua`) that:
1. Hardcodes the path setup (no `arg[0]` needed)
2. Receives file lists from JS instead of `io.popen`
3. Otherwise delegates to the same engine modules

```lua
-- main_browser.lua (browser entry point)
-- Path setup: files are mounted at root
package.path = "/?.lua;/?/init.lua;" .. package.path

-- File listing: provided by JS bridge
-- _browser_file_list is set from JS before this runs
local file_lists = _browser_file_list or {}

local function list_lua_files(dir)
  return file_lists[dir] or {}
end

-- read_file works as-is because files are in Emscripten VFS
local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

-- ... rest of main.lua logic unchanged ...
```

### `io.popen` Replacement

The engine uses `io.popen` only for listing `.lua` files in directories. **Two strategies:**

1. **Build-time file list** (recommended): Generate the file list at build time, pass as a JS global
2. **Emscripten FS directory listing**: Wasmoon exposes `lua.cmodule.module.FS.readdir()` which can list the VFS — but it's easier to just provide the list from JS

---

## 4. I/O Model (REPL Bridging)

### The Problem

The REPL in `engine/loop/init.lua` uses a blocking synchronous loop:

```lua
while true do
  io.write("> ")
  io.flush()
  local input = io.read()  -- blocks waiting for user
  -- process input...
  -- print output via print()
end
```

Browsers are event-driven. You cannot block the main thread waiting for input.

### Solution: Invert the Control Flow

Instead of a blocking loop, expose a **command handler function** that JS calls when the user submits input:

```javascript
// Override print to write to DOM
lua.global.set('print', (...args) => {
  const text = args.join('\t') + '\n';
  outputElement.textContent += text;
});

// Override io.write similarly
lua.global.set('io', {
  write: (text) => { outputElement.textContent += text; },
  read: () => { /* never called in browser mode */ },
  stderr: { write: (text) => console.error(text) },
  flush: () => {},
  open: null  // Let VFS handle this
});

// Don't run the REPL loop — instead, expose a process_command function
```

### Browser REPL Architecture

```
┌─────────────────────────────────┐
│         Browser UI              │
│  ┌───────────────────────────┐  │
│  │    Output Display         │  │
│  │    (scrollable <pre>)     │  │
│  └───────────────────────────┘  │
│  ┌────────────────────┐ ┌────┐  │
│  │  Text Input         │ │Go │  │
│  └────────────────────┘ └────┘  │
└─────────────────┬───────────────┘
                  │ user types "look at bed"
                  ▼
┌─────────────────────────────────┐
│   JavaScript Bridge             │
│   onSubmit(input) {             │
│     lua.doString(               │
│       `process_command("${input}")` │
│     );                          │
│   }                             │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│   Lua VM (Wasmoon/WASM)        │
│   process_command(input) →      │
│     parse → verb dispatch →     │
│     state update → print output │
└─────────────────────────────────┘
```

### Implementation Approach

**Option A: Modify `engine/loop/init.lua` to support both modes**

Add a browser mode that exposes a function instead of running a loop:

```lua
-- In engine/loop/init.lua
function loop.run_browser(context)
  -- Do initial "look" command
  -- Return a function that processes one command
  return function(input)
    -- same logic as the loop body, minus io.read/io.write
  end
end
```

**Option B: Create a thin browser adapter (Recommended)**

Don't modify the engine at all. Create `main_browser.lua` that:
1. Runs the same initialization as `main.lua`
2. Exposes `process_command(input)` as a global function
3. JS calls this function on each user input

```lua
-- main_browser.lua
-- (initialization same as main.lua lines 1-300)
-- Instead of loop.run(context), expose:

function process_command(raw_input)
  local input = raw_input:match("^%s*(.-)%s*$")
  if not input or input == "" then return end

  local verb, args = input:lower():match("^(%S+)%s*(.*)")
  if not verb then return end

  -- Same verb dispatch as loop.run
  local handler = context.verb_handlers[verb]
  if handler then
    handler(args, context)
  else
    print("I don't understand that.")
  end

  -- Run tick callbacks
  if context.on_tick then context.on_tick() end
end
```

Then from JS:
```javascript
document.getElementById('input-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const input = inputField.value;
  inputField.value = '';
  outputElement.textContent += '> ' + input + '\n';
  await lua.doString(`process_command("${input.replace(/"/g, '\\"')}")`);
});
```

### `io.stderr:write()` Handling

The engine writes warnings to stderr during startup. Replace with a JS logging function:
```javascript
lua.global.set('_warn', (msg) => console.warn('[Lua]', msg));
```

And in `main_browser.lua`: `io.stderr = { write = function(self, msg) _warn(msg) end }`

---

## 5. PWA Architecture

### Recommendation: Vanilla HTML/JS, No Framework

A text adventure has trivially simple UI needs. No framework is warranted. The entire PWA is:

```
pwa/
├── index.html          # UI: output area + input field
├── app.js              # Wasmoon init, I/O bridge, event handlers
├── lua-bundle.js       # All .lua files as JS string constants
├── sw.js               # Service worker for offline caching
├── manifest.json       # PWA manifest for installability
├── style.css           # Terminal-style CSS
└── icons/
    ├── icon-192.png
    └── icon-512.png
```

### `manifest.json`

```json
{
  "name": "The Bedroom — A Text Adventure",
  "short_name": "Bedroom",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#1a1a1a",
  "theme_color": "#00ff00",
  "description": "A self-modifying text adventure powered by Lua",
  "icons": [
    { "src": "icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

### `sw.js` (Service Worker)

```javascript
const CACHE = 'mmo-v1';
const ASSETS = [
  '/', '/index.html', '/app.js', '/lua-bundle.js',
  '/style.css', '/manifest.json',
  '/icons/icon-192.png', '/icons/icon-512.png'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
});

self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(r => r || fetch(e.request))
  );
});
```

### Why Vanilla?

- **Total JS code needed:** ~100 lines (Wasmoon init + DOM event handlers)
- **No state management:** Lua owns all game state
- **No routing:** Single page, single view
- **No component model:** One `<pre>` for output, one `<input>` for commands
- React/Vue/Svelte would add 30-100KB+ of bundle for zero benefit

### Offline Play

The service worker caches all assets on first load. After that, the game works fully offline — there's no server interaction. This makes it a true offline-first PWA. The Wasmoon WASM binary is also cached.

### Installability

With `manifest.json` + service worker + HTTPS, browsers will offer "Install" / "Add to Home Screen." On mobile, this creates a full-screen app icon. On desktop, it creates a standalone window.

---

## 6. Performance

### Download Size

| Asset | Raw | Gzipped | Notes |
|-------|-----|---------|-------|
| Wasmoon WASM binary | ~393 KB | ~130 KB | Cached after first load |
| Wasmoon JS bridge | ~50 KB | ~15 KB | Estimated |
| Lua sources (all engine + meta) | ~80 KB | ~20 KB | 6 modules + 37 objects + templates |
| HTML/CSS/JS wrapper | ~10 KB | ~3 KB | Trivial |
| **Total first load** | **~533 KB** | **~168 KB** | Excellent for a PWA |

For context: a typical web page is 2-3 MB. This game loads faster than most websites.

### Startup Time

- **WASM compilation:** ~50-100ms (browser streams + compiles WASM in parallel with download)
- **Lua VM initialization:** ~5-10ms
- **Mount files + load modules:** ~10-20ms
- **Object instantiation:** ~5ms (50 objects, 10 rooms — trivial)
- **Total cold start:** ~100-200ms (imperceptible)
- **Warm start (cached):** ~30-50ms

### Memory Usage

- **Wasmoon VM:** ~2-4 MB base
- **Lua state (50 objects, 10 rooms):** ~100-200 KB
- **Total runtime memory:** ~5 MB estimated
- For context: a single browser tab typically uses 50-100 MB. This is nothing.

### Execution Performance

Wasmoon runs Lua at near-native speed via WASM. For a text adventure:
- Command parsing: <1ms
- Verb dispatch + state mutation: <1ms
- Output generation: <1ms
- **Total per-command latency: <5ms** (instantaneous to the user)

### Verdict

Performance is a non-issue. This game will load fast, run fast, and use minimal resources. Even on budget phones.

---

## 7. Prior Art

### Direct Wasmoon Projects

| Project | Description | Relevance |
|---------|-------------|-----------|
| [lua-in-browser](https://github.com/hellpanderrr/lua-in-browser) | Wasmoon demo: runs Lua in browser, JS↔Lua interop, file mounting | Best technical reference for our approach |
| [LiveCodes](https://livecodes.io/docs/languages/lua-wasm/) | Online code playground using Wasmoon | Proves Wasmoon works reliably in-browser |
| [webx-wasmoon](https://github.com/inventionpro/webx-wasmoon) | Wasmoon fork for web extensions | Shows WASM Lua in constrained environments |

### No Shipped Games (Yet)

No publicly documented games have shipped via Wasmoon. This project would be **pioneering** in that space. However:

- The technical foundation is proven (file mounting, JS interop, execution speed)
- The gap is adoption, not capability
- Text adventures are the ideal first case: no graphics, no real-time loops, pure logic

### Alternative Lua-in-Browser Engines

| Engine | Approach | Lua Version | Performance | Size |
|--------|----------|-------------|-------------|------|
| **Wasmoon** | Official Lua → WASM | 5.4 | 25x Fengari | 130 KB gz |
| **Fengari** | Lua reimplemented in JS | 5.3 | Baseline | 69 KB gz |
| **LÖVE.js** | LÖVE2D → Emscripten | 5.1 (LuaJIT) | Good (graphics) | ~5 MB |

Wasmoon is the right choice: correct Lua version (5.4), best performance, reasonable size, active maintenance.

### Lessons from lua-in-browser Demo

Key patterns from the reference project:
1. Use `mountFile` before creating the engine
2. Set `package.path` inside Lua after engine creation
3. Override `print` to redirect output to DOM
4. Use `doString` for running Lua code, not `doFile`
5. Handle errors in JS with try/catch around `doString`

---

## 8. Prototype Plan

### Phase 0: Hello World (30 minutes)

**Goal:** Prove Wasmoon runs Lua in a browser on this machine.

```
pwa-prototype/
├── index.html
├── app.js
└── package.json
```

Steps:
1. `mkdir pwa-prototype && cd pwa-prototype`
2. `npm init -y && npm install wasmoon`
3. Create minimal `index.html` with a `<pre>` and `<script type="module">`
4. In `app.js`: import Wasmoon, create engine, run `print("Hello from Lua!")`
5. Serve with `npx serve .` and verify in browser
6. Override `print` to write to the `<pre>` element

```javascript
// app.js (Phase 0)
import { LuaFactory } from './node_modules/wasmoon/dist/index.js';

const output = document.getElementById('output');
const factory = new LuaFactory();
const lua = await factory.createEngine();

lua.global.set('print', (...args) => {
  output.textContent += args.join('\t') + '\n';
});

await lua.doString('print("Hello from Lua 5.4 via Wasmoon!")');
```

### Phase 1: Load One Module (1 hour)

**Goal:** Load `engine/registry` via `mountFile` and call it from Lua.

Steps:
1. Read `src/engine/registry/init.lua` content
2. Mount it via `factory.mountFile('engine/registry/init.lua', source)`
3. Set `package.path = "/?.lua;/?/init.lua"`
4. `doString('local reg = require("engine.registry"); print(type(reg))')`
5. Verify it returns "table"

### Phase 2: Load All Engine Modules (1-2 hours)

**Goal:** All 6 engine modules loaded and callable.

Steps:
1. Create `build-bundle.js` — reads all `.lua` files, outputs `lua-bundle.js`
2. Mount all engine modules
3. Mount all templates, objects, world files
4. Verify `require` works for all 6 modules

```javascript
// build-bundle.js (Node.js build script)
import { readFileSync, readdirSync } from 'fs';
import { join } from 'path';

function scanDir(dir) {
  const files = {};
  for (const f of readdirSync(dir)) {
    if (f.endsWith('.lua')) {
      files[f] = readFileSync(join(dir, f), 'utf-8');
    }
  }
  return files;
}

const bundle = {
  engine: {
    'registry/init.lua': readFileSync('src/engine/registry/init.lua', 'utf-8'),
    'loader/init.lua': readFileSync('src/engine/loader/init.lua', 'utf-8'),
    'mutation/init.lua': readFileSync('src/engine/mutation/init.lua', 'utf-8'),
    'containment/init.lua': readFileSync('src/engine/containment/init.lua', 'utf-8'),
    'loop/init.lua': readFileSync('src/engine/loop/init.lua', 'utf-8'),
    'verbs/init.lua': readFileSync('src/engine/verbs/init.lua', 'utf-8'),
  },
  meta: {
    templates: scanDir('src/meta/templates'),
    objects: scanDir('src/meta/objects'),
    world: scanDir('src/meta/world'),
  }
};

const output = `export const LUA_BUNDLE = ${JSON.stringify(bundle, null, 2)};`;
writeFileSync('pwa-prototype/lua-bundle.js', output);
```

### Phase 3: Browser REPL (2-3 hours)

**Goal:** Full game running in browser with input/output.

Steps:
1. Create `main_browser.lua` — adapted `main.lua` without `io.popen`, `arg[0]`, or blocking REPL
2. Replace `list_lua_files` with JS-provided file lists
3. Replace REPL loop with `process_command()` global function
4. Wire HTML input form to `process_command()`
5. Override `print` and `io.write` to write to output `<pre>`
6. Test: type "look", "take matchbox", "open matchbox" — verify game works

### Phase 4: PWA Wrapper (1 hour)

**Goal:** Installable offline PWA.

Steps:
1. Add `manifest.json` with icons
2. Add `sw.js` service worker
3. Register service worker in `index.html`
4. Add CSS for terminal-style appearance
5. Test offline: load page, go offline, verify it still works
6. Test install: verify "Add to Home Screen" prompt appears

### Phase 5: Polish (Optional)

- Auto-scroll output to bottom
- Command history (up/down arrow)
- Save/load game state to `localStorage`
- Dark/light theme toggle
- Touch-friendly input on mobile

### Total Estimated Effort

| Phase | Time | Skill Required |
|-------|------|---------------|
| Phase 0: Hello World | 30 min | Junior JS |
| Phase 1: One Module | 1 hr | JS + Lua basics |
| Phase 2: All Modules | 1-2 hr | Build tooling |
| Phase 3: Browser REPL | 2-3 hr | Lua adaptation |
| Phase 4: PWA Wrapper | 1 hr | Web standards |
| **Total** | **5-7 hours** | |

---

## Key Risks and Mitigations

### Risk 1: `io.open` on VFS May Not Work as Expected

**Likelihood:** Low  
**Impact:** Medium  
**Mitigation:** If `io.open` doesn't work on mounted files, switch to `package.preload` and inject all file contents directly via JS globals. This is a straightforward fallback.

### Risk 2: `io.popen` Removal Requires main.lua Changes

**Likelihood:** Certain (this will happen)  
**Impact:** Low  
**Mitigation:** Create `main_browser.lua` as a parallel entry point. Don't modify `main.lua` — keep the terminal version working. The browser version receives file lists from JS.

### Risk 3: Engine Modules Depend on Global State Set by main.lua

**Likelihood:** Medium  
**Impact:** Medium  
**Mitigation:** The explore analysis shows all 6 modules are self-contained and return tables. No globals are expected except what `main.lua` passes as the `context` table. This should be fine.

### Risk 4: Wasmoon Async Limitations

**Likelihood:** Low  
**Impact:** Low  
**Mitigation:** Our game is synchronous — user types, game responds. No async needed. The `doString` call resolves synchronously (or via a single await). No coroutine boundary issues.

### Risk 5: WASM Not Supported on Target Browsers

**Likelihood:** Very low  
**Impact:** High  
**Mitigation:** WASM is supported by 96%+ of browsers globally (all modern Chrome, Firefox, Safari, Edge). The only gap is IE11 (dead) and very old Android WebViews.

---

## Recommendation

**Proceed with the prototype.** This is a high-confidence, low-risk endeavor.

The engine's architecture is almost tailor-made for Wasmoon deployment:
- Pure Lua 5.4, no C extensions
- Only 6 self-contained modules
- No circular dependencies
- Sandboxed object execution (already designed for untrusted code)
- Small codebase (~3000 lines total)

The main adaptation work is:
1. Replace `io.popen` (directory listing) with build-time manifest → **~20 lines of JS**
2. Replace blocking REPL with event-driven command handler → **~50 lines of Lua**
3. Override `print`/`io.write` for DOM output → **~10 lines of JS**

**The prototype should be Phase 0-3 (working browser REPL), then Phase 4 (PWA) once validated.** Total: one solid day of engineering work.

---

## Appendix A: Wasmoon API Quick Reference

```javascript
// Initialize
const factory = new LuaFactory();
await factory.mountFile(path, content);     // Mount file into VFS
const lua = await factory.createEngine();   // Create Lua VM

// JS → Lua
lua.global.set('name', value);              // Set global (string, number, function, table)
await lua.doString(luaCode);                // Execute Lua code
await lua.doFile(path);                     // Execute file from VFS

// Lua → JS
const val = lua.global.get('name');         // Get global value
const fn = lua.global.get('fnName');        // Get function (callable from JS)

// Cleanup
lua.global.close();                         // Free Lua state
```

## Appendix B: Wasmoon Size and Performance

| Metric | Value | Source |
|--------|-------|--------|
| WASM binary (raw) | 393 KB | Wasmoon README |
| WASM binary (gzipped) | 130 KB | Wasmoon README |
| Heap sort 2K items | 15.3 ms | Wasmoon benchmark |
| vs. Fengari same test | 389.9 ms | Wasmoon benchmark |
| Lua version | 5.4 (official) | Compiled from lua/lua repo |
| License | MIT | Open source |
| npm weekly downloads | Active | Maintained as of 2025 |

## Appendix C: Files That Need Browser Adaptation

| File | Change Needed | Complexity |
|------|--------------|------------|
| `src/main.lua` | Create browser variant (`main_browser.lua`) | Medium — mostly copy + remove I/O |
| `src/engine/loop/init.lua` | Either modify or bypass in browser mode | Low — just skip the blocking loop |
| `src/engine/loader/init.lua` | None expected — uses pcall/sandbox, no I/O | None |
| `src/engine/registry/init.lua` | None | None |
| `src/engine/mutation/init.lua` | None | None |
| `src/engine/containment/init.lua` | None | None |
| `src/engine/verbs/init.lua` | Override `print` output target | None (handled by JS bridge) |
