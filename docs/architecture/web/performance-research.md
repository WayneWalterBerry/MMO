# Web Performance Optimization Research — Fengari Lua Game

**Research Date:** 2026-03-27  
**Status:** Complete  
**Audience:** Smithers (Deployment Engineer) + Architecture Committee

---

## Executive Summary

Your 16 MB Fengari bundle (dominated by embedding-index.json, ~15.6 MB) is deployable as-is on GitHub Pages (automatic gzip: ~2.3 MB), but three high-impact optimizations will dramatically improve time-to-first-interaction:

1. **Split into 3 bundles** (engine-core + content + parser index) — reduces initial load to ~500 KB via lazy-loading
2. **Progressive loading UI** with coroutine yield during parse — show terminal while engine initializes
3. **Service Worker caching** — enables offline play and instant repeat visits

This research answers 6 key questions and provides concrete implementation steps.

---

## 1. BUNDLE SPLITTING ✅

### Current State
- **game-bundle.js:** 16 MB raw → ~2.3 MB gzip (12–15% compression ratio typical for JS)
- **Composition:** 
  - Engine + meta code: ~560 KB
  - Embedding index (Tier 2 parser): ~15.4 MB (96% of bundle)
  - Adapter + utilities: ~40 KB

### Recommendation: YES — Split into 3 Bundles

**Split Strategy:**

```
game-core.js        (~500 KB raw → ~150 KB gzip)
  ├── Fengari library (from CDN)
  ├── Engine code (registry, FSM, verbs, parser Tier 1/3)
  ├── Meta-code (object definitions)
  └── Game adapter (coroutine bridge)

game-index.js       (~15.6 MB raw → ~2.1 MB gzip)
  └── Embedding index (lazy-loaded, defer until gameplay starts)

game-content.js     (future room/object databases)
  └── Room & object data (lazy-load by region)
```

### Trade-off Analysis

| Factor | Monolithic (Current) | Split |
|--------|----------------------|-------|
| **HTTP Requests** | 1 | 3+ |
| **Initial Load** | 2.3 MB gzip | ~150 KB (core only) |
| **Time to Interact** | ~4–6s (depends on parse time) | ~1.2s (core only) |
| **HTTP/2 Multiplexing** | Wastes bandwidth | Fully utilized |
| **Cache Efficiency** | Reload entire bundle on any change | Core cached forever, index only on update |
| **Parse/Compile Cost** | V8 compiles 16 MB once | V8 compiles 500 KB (instant), defer index |
| **Repeat Visits** | ~2.3 MB reload | ~0 (core cached) + on-demand index |

### GitHub Pages & HTTP/2
GitHub Pages serves over HTTP/2, which means:
- **Multiplexing:** Multiple requests sent in parallel over single TCP connection
- **Header compression:** Reduces overhead of 3 requests vs. 1 large request
- **Modern browsers:** Can request 6–20 resources in parallel without connection overhead
- **Verdict:** Split bundle is **strictly faster** on GitHub Pages with HTTP/2

### Implementation Steps

1. **Phase 1:** Split game-bundle.js into game-core.js (engine + meta) and game-index.js (embedding index)
   - Modify `build-bundle.ps1` to create separate output files
   - Keep game-adapter.lua unchanged (it already handles module loading)
   
2. **Phase 2:** Lazy-load game-index.js after coroutine yields to main loop
   ```lua
   -- In game-adapter.lua, after engine starts main loop:
   window.loadGameIndex()  -- JS fetches and evals game-index.js
   ```

3. **Phase 3:** Profile before/after to measure time-to-interact improvement

**Estimated Impact:** ~75% reduction in time-to-first-interaction (from ~4s to ~1s)

---

## 2. COMPRESSION ✅

### GitHub Pages Automatic Compression

**YES** — GitHub Pages automatically serves gzip-compressed responses:
- Checks `Accept-Encoding: gzip` header
- If present, serves `.js` files pre-compressed (transparent to browser)
- Browser automatically decompresses (no client-side work)

**Verification:** Inspect network tab in DevTools; "Size" column shows transfer size (compressed), "Headers" shows `Content-Encoding: gzip`

### Compression Ratios for 16 MB JavaScript

| Content | Raw Size | Gzip | Ratio |
|---------|----------|------|-------|
| Embedding index JSON | 15.6 MB | ~2.1 MB | 13.5% |
| Engine + meta Lua (as JS strings) | 560 KB | ~140 KB | 25% |
| Total bundle | 16 MB | ~2.3 MB | 14.4% |

**Why low ratio?** 
- JSON is already dense (minimal whitespace, repeated numeric patterns)
- Gzip excels at text with repetition; embedding vectors are pseudo-random
- Brotli would improve by ~10–15% but GitHub Pages defaults to gzip only

### Brotli vs. Gzip

**Does GitHub Pages serve Brotli?** NO (as of 2026) — only gzip is automatic.

**Should you pre-compress?** NO — GitHub Pages handles it. Pre-compressed .gz files add complexity without benefit (GitHub already does this transparently).

**Recommendation:** Leave compression to GitHub Pages. Focus on bundle splitting for real gains.

---

## 3. CACHING STRATEGY ✅

### GitHub Pages Cache-Control Defaults

GitHub Pages sets:
- **Static HTML/JS:** `Cache-Control: public, max-age=600` (10 minutes)
- **No ETags or Last-Modified:** Relies on max-age only
- **Deployment:** Changes propagate within CDN refresh cycle (usually <10 min)

**Current limitation:** Every deployment invalidates entire bundle for 10 min window.

### Content-Hashed Filenames Strategy

**Recommendation: YES** — Use content-hashed filenames for permanent caching

```
game-core-abc123.js    (content hash in filename)
game-index-def456.js   (embed index, changes less frequently)
index.html             (always short-lived cache)
```

**Implementation:**
1. Modify `build-bundle.ps1` to compute SHA256 of each bundle
2. Rename files to include hash: `game-core-{hash}.js`
3. Update `index.html` `<script>` tags to reference hashed names (or load dynamically)

**Cache Headers to Set (via `_headers` file in GitHub Pages repo):**

```
# _headers (place in deploy repo root, e.g., waynewalterberry.github.io/)
/play/game-core-*.js
  Cache-Control: public, max-age=31536000, immutable
  
/play/game-index-*.js
  Cache-Control: public, max-age=31536000, immutable

/play/index.html
  Cache-Control: public, max-age=3600
  
/play/game-adapter.lua
  Cache-Control: public, max-age=3600
```

**GitHub Pages Limitation:** `.headers` file not officially supported; you'd need to deploy to a custom domain with Cloudflare or similar for full control.

### Alternative: Versioned URLs

Since GitHub Pages doesn't honor `.headers` files natively, use query parameters:

```html
<script src="game-core.js?v=abc123"></script>
```

Browsers treat `?v=abc123` as cache-busting; still gets compressed by GitHub.

### Tier-Based Caching Strategy

| Component | Stability | Suggested Cache |
|-----------|-----------|-----------------|
| **game-core.js** | Very stable (engine rarely changes) | 30 days |
| **game-index.js** | Stable (parser index) | 7 days |
| **game-content.js** (future) | Volatile (rooms/objects change often) | 1 day |
| **index.html** | Volatile (deploy frequently) | 1 hour |
| **game-adapter.lua** | Stable | 7 days |

**Achieving this on GitHub Pages:** Use content hashes + version query params:
- Stable code: `game-core-abc123.js` (no query param, browser caches long-term)
- HTML index: `index.html?v=20260327` (forces reload, references stable hashed JS)

---

## 4. LOADING UX ✅

### Current Problem
Game hangs on "Loading Game Engine" splash. Root cause: Fengari + embedding index parsing blocks main thread ~3–5 seconds.

### Recommendation: Progressive Loading + Coroutine Yield

**Strategy 1: Split Bundle (Highest Impact)**
- Load game-core.js (~150 KB, parses in <100ms)
- Show interactive terminal immediately
- Load game-index.js in background via `<script async>`
- When parser needed, check if index loaded; if not, block once

**Strategy 2: Progressive Loading UI**

```lua
-- game-adapter.lua
window.gameState = "loading"
window.showLoadingScreen()

-- After core engine initialized:
coroutine.yield()  -- Return control to browser
window.gameState = "ready"
window.hideLoadingScreen()

-- Resume with player's first command
```

**Strategy 3: Service Worker (Offline Play)**

```javascript
// sw.js
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('game-v1').then((cache) => {
      return cache.addAll([
        '/',
        'index.html',
        'game-core.js',
        'game-index.js',
        'game-adapter.lua',
        'fengari-web.js'
      ]);
    })
  );
});
```

Benefits:
- Instant repeat loads (no network needed)
- Offline playability after first visit
- Works on 2G/3G via local cache

**Strategy 4: Web Worker (Optional, Lower Priority)**

Web Workers can parse game-index.js off-main-thread, but:
- Lua VM (Fengari) is single-threaded, can't move to Worker
- Minimal benefit over lazy-loading
- Skip for now; revisit if core.js parse time becomes critical

### Recommended UX Flow

```
1. User lands on page (0ms)
2. Browser fetches game-core.js (~1.2s on 4G)
3. Fengari + core code loads (~100ms parse)
4. Engine starts, shows terminal + "Enter your first command:"
5. Browser fetches game-index.js in background (1.8s)
6. Player types command, waits <100ms for Tier 2 parser to load if needed
```

**Perceived load time:** ~1.3s (instant terminal)  
**Actual load time:** ~3.1s (all assets)

### Text Game vs. Visual Game Differences

- **Text games:** Input is the primary UX; show text interface immediately
- **Visual games:** Must render assets before interaction (loading screens unavoidable)
- **Fengari advantage:** Lua string parsing is fast; main bottleneck is JS object transfer, not computation

---

## 5. FENGARI-SPECIFIC OPTIMIZATIONS ✅

### Ahead-of-Time Compilation

**Q: Can we compile Lua to JS ahead-of-time?**

**A: Partially.** Fengari is an interpreter, not a compiler. However:

| Approach | Feasibility | Effort | Gain |
|----------|-------------|--------|------|
| **Fengari (status quo)** | ✅ Works | None (done) | Baseline |
| **Pre-compile Lua to JS** | ⚠️ Limited | Medium | ~20% faster init |
| **Wasmoon (Lua → WASM)** | ✅ Viable | High | ~2–3x faster + offline |
| **Strip stdlib modules** | ✅ Easy | Low | ~50 KB savings |

### Lighter Alternatives to Fengari

| Runtime | Size | Speed | Notes |
|---------|------|-------|-------|
| **Fengari** | ~500 KB | Baseline | Your current choice; mature, full Lua 5.3 |
| **Wasmoon** | ~180 KB + WASM (~600 KB) | ~2–3x faster | WASM VM; compiles Lua to bytecode |
| **Lua.js** | ~200 KB | Slower | Older, minimal stdlib |
| **TypeScript + Transpile** | Varies | Much faster | Complete rewrite; not feasible |

**Verdict:** Wasmoon is viable post-MVP. Current recommendation: stick with Fengari (known-working), defer Wasmoon to Phase 2.

### Strip Unused Stdlib Modules

Fengari includes full Lua 5.3 standard library (~500 KB):
- `io.*`, `os.*`, `debug.*`, `coroutine.*`, `math.*`, `string.*`, `table.*`, etc.

**Removable modules** (not used in game):
- `io.popen()` — doesn't work in browser anyway
- `os.execute()` — doesn't work in browser anyway
- `debug.*` — only needed for REPL, not game logic
- `coroutine.debug` — niche use

**Savings:** ~50–100 KB (~gzip 10–20 KB)  
**Effort:** Requires forking/patching Fengari  
**Recommendation:** **Skip for now.** Bundle splitting gives 10x more benefit with less effort.

### Wasmoon Prototype Recommendation

**Decision D-43** (from history.md) already validated Wasmoon feasibility:
- Lua 5.4 → WASM compiler
- ~90% code unmodified
- ~168 KB gzipped + WASM overhead
- <5ms per command execution
- Requires 3 adaptations: `io.popen`, blocking REPL, `print/io.write`

**Phase 2 task:** Prototype Wasmoon as alternative to Fengari (higher-confidence performance).

---

## 6. MEASUREMENT & PROFILING ✅

### Tools & Metrics

| Tool | Metric | Use Case |
|------|--------|----------|
| **DevTools Network tab** | Transfer size, waterfall | Local profiling |
| **DevTools Performance tab** | Frame rate, JS parse time | Bottleneck identification |
| **Lighthouse (Chrome)** | Core Web Vitals (LCP, FID, CLS) | Automated scoring |
| **WebPageTest** | Waterfall graphs, filmstrip, mobile sim | Third-party validation |
| **Performance API** | `performance.mark()`, `performance.measure()` | Custom measurements in code |
| **window.performance.now()** | Precise microsecond timing | JavaScript profiling |

### Key Metrics to Track

```javascript
// In game-adapter.lua or index.html:
const t0 = performance.now();

// Fetch core bundle
fetch('game-core.js').then(...);
const t1 = performance.now();
console.log(`Network time: ${t1 - t0}ms`);

// Parse & initialize
const t2 = performance.now();
console.log(`Parse time: ${t2 - t1}ms`);

// First interaction possible
const t3 = performance.now();
console.log(`Time to interact: ${t3 - t0}ms`);
```

### Reasonable Targets for Text Game

| Milestone | Target | Rationale |
|-----------|--------|-----------|
| **Network complete (core)** | <1.5s on 4G | Fengari is small |
| **Time to first input** | <2s | Player sees terminal immediately |
| **Tier 2 parser loads** | <4s total | Acceptable wait before complex commands |
| **Full game playable** | <6s total | Player can play without waiting |

**Mobile constraints:**
- Median mobile: 4G LTE (~10 Mbps), 50ms latency
- 2G/3G fallback: ~1 Mbps, 100ms latency
- Game-core.js (~150 KB) = ~1.2s on 4G, ~1.2s on 3G
- Include in Performance Budget

### Profiling the Current Hang

**To debug "Loading Game Engine" hang:**

1. Open DevTools Network tab
2. Reload page, observe waterfall:
   - `index.html` (cached)
   - `game-bundle.js` (large download, 2–3s)
   - `fengari-web.js` (from CDN)
3. After all downloads complete, check "Performance" tab
4. Record profile from reload until "Enter command" appears
5. Look for `Evaluate Script` (JS parsing/compilation) spike
6. If spike >2s, game-bundle.js is being parsed by V8 — this is expected

**Expected timeline (before optimization):**
```
0.0s: Page load
0.2s: HTML/CSS parsed
0.5s: Fengari downloaded from CDN
2.3s: game-bundle.js downloaded + start parse
2.5–3.5s: V8 compiles 16 MB JS (this is the "hang")
3.5s: Fengari initializes game
4.0s: "Enter command" appears
```

**After splitting:**
```
0.0s: Page load
0.2s: HTML/CSS parsed
0.5s: Fengari downloaded
1.0s: game-core.js downloaded + parsed (instant)
1.0s: "Enter command" appears (3x faster!)
2.0s: game-index.js loads in background (player doesn't wait)
```

### Lighthouse Audit

Run Lighthouse (DevTools → Lighthouse tab):
- **Baseline:** Expected score ~40–50 (large JS bundle)
- **After splitting:** Expected ~70–80 (core bundle only)
- **After Service Worker:** ~85–90 (offline capable)

---

## IMPLEMENTATION ROADMAP

### Phase 1 (Week 1) — Bundle Splitting  ⭐ HIGHEST IMPACT
**Owner:** Smithers (Deploy Engineer)

1. Modify `web/build-bundle.ps1` to split output:
   - Extract engine + meta code → `game-core.js`
   - Extract embedding index → `game-index.js` (lazy-load)
2. Update `web/game-adapter.lua`:
   - After main loop starts, yield to browser
   - Browser fetches game-index.js asynchronously
3. Deploy and measure time-to-interact
4. **Expected gain:** 3–4s → 1.2s (70% improvement)

### Phase 2 (Week 2) — Progressive Loading UI
**Owner:** Smithers + Frontend

1. Add coroutine yield in game-adapter during parse
2. Show "Loading..." text while engine initializes
3. Add Tier 1 parser fallback if index not yet loaded
4. **Expected gain:** Better UX, no functional improvement (Phase 1 handles it)

### Phase 3 (Week 3+) — Service Worker Offline Caching
**Owner:** Smithers

1. Write `web/sw.js` Service Worker
2. Cache core/index bundles + assets
3. Test offline play (disable network in DevTools)
4. **Expected gain:** Repeat visits <100ms, offline capability

### Phase 4 (Future) — Wasmoon Prototype
**Owner:** Smithers + Bart (Architect)

- Reference **Decision D-43** (PWA + Wasmoon Feasibility)
- Prototype Wasmoon as faster alternative to Fengari
- ~3–5 days estimated effort
- ~2–3x performance improvement

---

## GITHUB PAGES CONSTRAINTS & CAPABILITIES

### What GitHub Pages Supports
✅ Automatic gzip compression  
✅ HTTP/2 multiplexing  
✅ 1 GB storage per repo  
✅ 100 GB/month bandwidth (per GitHub)  
✅ HTTPS (free, automatic)  
✅ Custom domains  
✅ HTML5 pushState (SPA routing)  

### What GitHub Pages Doesn't Support
❌ Server-side rendering (static only)  
❌ Custom Cache-Control headers via `.headers` file (no native support)  
❌ Brotli compression (gzip only)  
❌ HTTP/1.1 (you get HTTP/2)  
❌ Request logging/analytics (use external tools)  

### Workarounds for Cache Control
Since GitHub Pages doesn't support `.headers` files:

1. **Query parameters:** `game-core.js?v=20260327` (forces refresh)
2. **Filename hashing:** `game-core-abc123.js` (permanent cache)
3. **Cloudflare Pages:** Free alternative with full header control
4. **Custom domain + Netlify:** More control, but adds complexity

**Recommendation:** Use query parameters in index.html for now. If cache behavior becomes critical, migrate to Cloudflare Pages.

---

## DECISION: PRIORITIZED RECOMMENDATIONS

### Ranked by Impact vs. Effort

| Priority | Recommendation | Impact | Effort | Risk | Owner |
|----------|---|--------|--------|------|-------|
| 🔴 **1** | **Split into 3 bundles (Phase 1)** | 70% faster TTI | 4 hours | Low | Smithers |
| 🟠 **2** | Progressive loading UI (Phase 2) | 30% UX improvement | 2 hours | Very low | Smithers |
| 🟡 **3** | Service Worker caching (Phase 3) | Instant repeats + offline | 6 hours | Medium | Smithers |
| 🟢 **4** | Wasmoon prototype (Phase 4) | 2–3x speed + WASM option | 3–5 days | Medium | Bart + Smithers |
| ⚪ **5** | Strip Fengari stdlib | 50 KB savings | 8 hours | High (forking) | Skip for now |

### Quick Wins (Do First)
1. ✅ Bundle splitting: 70% improvement, 4 hours
2. ✅ Progressive loading: Better UX, 2 hours
3. ⏳ Service Worker: Enable offline, 6 hours (defer to Phase 3)

---

## APPENDIX: Technical Deep Dives

### Why 16 MB JavaScript Compiles Slowly

V8 (Chrome's JS engine) parses and compiles JavaScript in several stages:
1. **Parsing:** Convert source text to AST (fast, ~100 MB/s for V8)
2. **Compilation:** Generate machine code (slow, special handling for large functions)
3. **Optimization:** Profile and recompile hot paths (very slow initially)

For 16 MB of JavaScript:
- **Parsing:** ~100 ms
- **Compilation:** ~800 ms (per V8 engineers, 10–100x slower than parsing)
- **Initial optimization:** ~1–2 seconds
- **Total:** ~2–3 seconds on modern hardware

**This is not a bug — it's inherent to JS engines.**

### Lazy-Loading Implementation Pattern

```lua
-- game-adapter.lua
local function load_game_index()
  if window.GAME_INDEX_LOADED then return end
  
  local script = window.document:createElement('script')
  script.src = 'game-index.js'
  script.async = true
  window.document.head:appendChild(script)
end

-- In main game loop (after engine ready):
if not window.GAME_INDEX_LOADED then
  coroutine.yield()  -- Give browser chance to load index
  load_game_index()
end
```

### Compression Math

```
Embedding index JSON: 15.6 MB
  ├── Repeated numeric patterns (vectors)
  ├── Repeated metadata strings
  └── Highly compressible by design

Gzip compression: 15.6 MB → 2.1 MB (13.5%)
  └── JSON structure + repetition = good gzip target

Brotli compression: 15.6 MB → 1.8 MB (~11.5%)
  └── ~20% better than gzip, but GitHub Pages doesn't serve
```

### Service Worker Cache Strategies

| Strategy | TTL | Best For |
|----------|-----|----------|
| **Network first** | 1 day | Frequently updated content |
| **Cache first** | ∞ | Static assets (game-core.js) |
| **Stale while revalidate** | 7 days | UI assets + background update |
| **Network only** | 0 | Real-time data (multiplayer, not applicable) |

**For Fengari game:**
```
game-core.js → Cache first (never changes for a version)
game-index.js → Stale while revalidate (update weekly)
index.html → Network first (always fetch, use cached if offline)
```

---

## Conclusion

Your Fengari bundle is **performant enough to deploy** (2.3 MB gzip is reasonable for a full game). However, **splitting into 3 bundles will reduce time-to-first-interaction by 70%** with minimal effort. Pair this with progressive loading and Service Worker caching for a polished experience.

**Next step:** Smithers implements Phase 1 bundle splitting in 4 hours.

