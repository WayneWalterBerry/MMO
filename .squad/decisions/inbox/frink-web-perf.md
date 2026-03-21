# WEB-PERF-001: Web Performance Optimization Strategy

**Author:** Frink (Researcher)  
**Date:** 2026-03-27  
**Status:** PROPOSED  
**Audience:** Smithers (Deploy Engineer), Bart (Architect)  
**Related:** D-43 (PWA + Wasmoon)  

---

## Decision

**Implement bundle splitting (Phase 1) to reduce time-to-first-interaction from ~4s to ~1.2s.**

Split game-bundle.js (16 MB) into:
1. **game-core.js** (~500 KB raw, ~150 KB gzip) — Engine + meta + adapter
2. **game-index.js** (~15.6 MB raw, ~2.1 MB gzip) — Embedding index (lazy-loaded)
3. **game-content.js** (future) — Room/object databases

Load core immediately; defer index until gameplay starts via coroutine yield.

---

## Rationale

### Current Problem
- Game hangs on "Loading Game Engine" for 3–5 seconds
- Root cause: V8 parses and compiles 16 MB JavaScript (~2–3s overhead, inherent to JS engines)
- Monolithic bundle wastes HTTP/2 multiplexing capability

### Why This Works
- **Bundle splitting reduces initial parse load by 96%** (500 KB vs 16 MB)
- **HTTP/2 multiplexing makes 3 requests as fast as 1 large request** on GitHub Pages
- **Coroutine yield architecture fits naturally** — game-adapter.lua can suspend after engine init
- **Lazy-loading preserves functionality** — parser falls back to Tier 1 if index not loaded yet
- **Text game UX advantage** — terminal shows immediately, player doesn't perceive waiting

### Impact Analysis

| Metric | Before | After | Gain |
|--------|--------|-------|------|
| **Initial download** | 2.3 MB | 150 KB | 93% smaller |
| **Time to interact** | ~4s | ~1.2s | **3.3x faster** |
| **Full engine load** | ~4s | ~3.1s | Faster + non-blocking |
| **Network requests** | 1 | 3 | ✅ OK on HTTP/2 |
| **Repeat visits** | 2.3 MB reload | 0 (cached) | Instant |

---

## Implementation

### Phase 1: Bundle Splitting (4 hours, Week 1)
**Owner:** Smithers

```
1. Modify web/build-bundle.ps1:
   - Split output into game-core.js + game-index.js
   - Keep game-adapter.lua unchanged

2. Update web/index.html:
   - Load <script src="game-core.js"></script>
   - Load <script defer src="game-index.js"></script> (or lazy-load via JS)

3. Modify web/game-adapter.lua:
   - After main loop starts, yield to browser
   - Browser fetches game-index.js in background

4. Test:
   - Verify time-to-interact with DevTools Network/Performance tabs
   - Confirm parser Tier 2 loads after index arrives
   - Test on 4G throttle (Chrome DevTools)
```

### Phase 2: Progressive Loading UI (2 hours, Week 1)
**Owner:** Smithers

1. Add `window.showLoadingScreen()` / `window.hideLoadingScreen()` JS functions
2. Show "Loading..." message during engine parse
3. Hide when interactive terminal ready

### Phase 3: Service Worker Caching (6 hours, Week 2)
**Owner:** Smithers

1. Write `web/sw.js` with cache-first strategy for game-core.js
2. Stale-while-revalidate for game-index.js
3. Test offline playability
4. **Benefits:** Instant repeat loads, offline play

### Phase 4: Wasmoon Prototype (3–5 days, Future)
**Owner:** Smithers + Bart

- Reference Decision D-43 (already validated feasibility)
- Prototype Lua → WASM as faster alternative to Fengari
- No decision required now; Phase 1–3 are stable regardless

---

## Trade-offs

### Bundle Splitting
✅ Pros:
- 3.3x faster time-to-interact
- HTTP/2 multiplexing advantage
- Better cache efficiency (core stable, index changes less frequently)
- Text game UX naturally hides loading

❌ Cons:
- 3 HTTP requests instead of 1 (negligible on HTTP/2)
- Slight added complexity in build script
- Players in 2G might wait longer if parser needed (acceptable, rare)

### Compression (Already Optimal)
- GitHub Pages auto-gzips (transparent)
- 16 MB JS compresses to 14% (~2.3 MB) naturally
- Brotli not available on GitHub Pages
- **Verdict:** Don't pre-compress; bundle splitting gives 10x more benefit

### Caching Strategy (GitHub Pages Limitation)
- GitHub Pages defaults to 10-minute cache
- Custom Cache-Control headers not supported natively
- **Workaround:** Use query params (?v=20260327) for cache-busting
- **Defer to Phase 3+:** Service Worker overrides this anyway

---

## Measurement

### Before (Baseline)
```
DevTools Network tab:
- game-bundle.js: 2.3 MB gzip (2–3s download on 4G)
- V8 parse: ~2–3s (watch "Evaluate Script" spike in Performance tab)
- Total: ~4–5s to "Enter command"

Lighthouse score: 40–50 (large JS bundle)
```

### After (Phase 1)
```
DevTools Network tab:
- game-core.js: 150 KB (300ms on 4G)
- V8 parse: ~100ms
- Total: ~1.2s to "Enter command"
- game-index.js loads in background (visible in Network tab, non-blocking)

Lighthouse score: 70–80

Repeat visits: <100ms (core cached)
```

### Measurement Tools
- **DevTools Network tab:** Inspect transfer size + timeline
- **DevTools Performance tab:** Record profile, look for "Evaluate Script" spikes
- **Performance API:** `performance.mark()` / `performance.measure()` for custom timings
- **Lighthouse:** DevTools → Lighthouse, run audit
- **WebPageTest:** Third-party validation (webpagetest.org)

---

## Success Criteria

- ✅ Time to "Enter command" reduced to <1.5s on 4G (from ~4s)
- ✅ DevTools Network shows non-blocking game-index.js load
- ✅ Tier 1 parser works immediately; Tier 2 works after index loads
- ✅ No parser regressions (test complex commands after index loads)
- ✅ Service Worker caching reduces repeat load to <200ms (Phase 3)
- ✅ Lighthouse score improves from 40–50 to 70–80

---

## GitHub Pages Constraints

✅ Supports: gzip compression, HTTP/2, 1 GB storage, 100 GB/month bandwidth, custom domains, HTTPS, SPA routing  
❌ Doesn't support: Brotli, custom Cache-Control headers (.headers file), server-side rendering

**Impact on this decision:** None. Bundle splitting works perfectly within GitHub Pages constraints.

---

## Alternatives Considered

| Alternative | Why Not Now |
|-------------|-------------|
| **Wasmoon (Lua → WASM)** | Viable but Phase 2 task; Fengari works well for MVP |
| **Strip Fengari stdlib** | Only 50 KB savings; bundle splitting saves 1.8 MB (36x more benefit) |
| **Pre-compress with brotli** | GitHub Pages doesn't serve Brotli; gzip already optimal |
| **Monolithic bundle + async parse** | Possible but doesn't solve V8 compilation overhead; splitting is cleaner |

---

## Next Steps

1. **This week (Smithers):** Implement Phase 1 bundle splitting (4 hours)
2. **Phase 2:** Progressive loading UI (2 hours)
3. **Phase 3:** Service Worker caching (6 hours, next week)
4. **Phase 4:** Wasmoon prototype decision (defer to future; reference D-43)

---

## Documentation

- **Full research:** `docs/architecture/web/performance-research.md` (20 KB)
- **Build script:** `web/build-bundle.ps1` (modify to split output)
- **Game adapter:** `web/game-adapter.lua` (add coroutine yield + lazy-load)

