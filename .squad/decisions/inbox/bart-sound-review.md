# Sound Implementation Plan — Bart's Architecture Review

**Reviewer:** Bart (Architecture Lead)
**Date:** 2026-07-31
**Plan Version:** 1.0
**Verdict:** ⚠️ Concerns — Architecturally sound, 7 spec gaps to close before WAVE-0

---

## Overall Assessment

The plan is well-structured. The driver injection pattern is textbook Principle 8 — objects declare sound metadata, the engine executes it through a platform-agnostic manager with swappable drivers. Hook points into FSM, effects, mutation, and movement are realistic and minimally invasive (confirmed against current codebase: 12 hook points, each ≤6 lines). Wave dependencies are correct. File ownership is clean — no two agents touch the same file in any wave.

**This plan can ship.** The concerns below are spec gaps, not architectural flaws. Fix them in a v1.1 pass and we're clear for WAVE-0.

---

## Findings

### ⚠️ C1: Terminal driver `os.execute()` blocks the game loop

**Location:** Track 0A, terminal-driver.lua
**Issue:** `os.execute()` is synchronous in Lua. The plan says "fire-and-forget one-shots only, max 2 seconds" — but that's a 2-second freeze, not fire-and-forget. On Windows, `os.execute("start /B ...")` is non-blocking but platform-specific. On macOS/Linux, appending `&` works but `os.execute` still waits for the shell to fork.
**Risk:** Medium — terminal is the secondary platform, but freezes during `lua src/main.lua` sessions are a bad dev experience.
**Recommendation:** Use `io.popen()` with immediate close instead of `os.execute()`. Or: document terminal sound as "known-blocking, dev-only, not production." Either way, spec it explicitly.

---

### ⚠️ C2: Dual integration path — effects pipeline vs. direct trigger

**Location:** Track 2A (engine hooks) + effects.lua integration
**Issue:** The plan defines TWO paths for sound dispatch:
1. **Effects pipeline:** `effects.register("play_sound", ...)` — sounds declared as effects in transitions
2. **Direct trigger:** `M:trigger(obj, event_key)` — called from FSM/verb/mutation hooks

If a transition declares a `play_sound` effect AND the FSM hook also calls `trigger()`, the sound fires twice.
**Risk:** Medium — double-firing produces audible glitches and confusing test output.
**Recommendation:** Pick ONE canonical path. My recommendation: **effects pipeline is primary.** Object metadata declares sounds as effects. FSM/verb/mutation hooks emit effects (not direct trigger calls). The `trigger()` method becomes an internal helper called by the effect handler, not by hooks directly. Document this in the plan.

---

### ⚠️ C3: Crossfade spec is underspecified

**Location:** Track 2A, ambient management
**Issue:** "1.5s fade out → 1.5s fade in (web driver only)" implies timing/scheduling logic in the web driver. But the driver interface contract (`driver:play(handle, opts)`) doesn't include fade parameters. Either:
- The crossfade logic lives in `init.lua` (wrong — it's platform-specific behavior)
- The driver:play() opts need `fade_in_ms` / `fade_out_ms` fields (not in the contract)
- The JS bridge handles it autonomously (not specified)
**Risk:** Low — web-only, but will cause confusion during WAVE-0 implementation.
**Recommendation:** Add `fade_in_ms` and `fade_out_ms` to the driver:play() opts contract. Terminal driver ignores them. Web driver implements via `GainNode.linearRampToValueAtTime()`. Document in the driver interface section.

---

### ⚠️ C4: Board vs. plan parallelism contradiction

**Location:** board.md timeline section vs. plan dependency graph
**Issue:** The board says "Run WAVE-1 and WAVE-2 in parallel after GATE-0." The plan's dependency graph says WAVE-2 depends on GATE-1 (WAVE-1 must complete first). These contradict.
**Analysis:** WAVE-2 Track 2A (engine hooks) can start after GATE-0 — the hooks are structural, they don't need actual sound files. But Track 2C (integration tests) needs objects with `sounds` tables from WAVE-1. So it's a **partial overlap**, not full parallel.
**Risk:** Low — sequencing confusion during execution.
**Recommendation:** Clarify in both documents: "WAVE-2 Track 2A (Bart: hooks) can start after GATE-0. WAVE-2 Tracks 2B + 2C wait for GATE-1." Update the dependency graph to show this split.

---

### ⚠️ C5: File extension mismatch (.ogg vs .opus)

**Location:** CBG design notes vs. implementation plan vs. Gil's pipeline notes
**Issue:** CBG's design notes use `.ogg` extensions throughout (e.g., `rat-squeak.ogg`, `amb-cellar-drip.ogg`). Gil's pipeline specifies `.opus` format. The implementation plan uses `.opus`. Room definitions in the plan show `.ogg`.
**Risk:** Low but irritating — Flanders and Moe will ask which extension to use in WAVE-1.
**Recommendation:** Standardize on `.opus` everywhere (it's the actual codec). Update CBG's sound audit table and room ambient assignments before WAVE-1. Add to pre-flight checklist.

---

### ⚠️ C6: Sound key resolution chain not specified

**Location:** Track 0A, `M:trigger(obj, event_key)` description
**Issue:** The plan says trigger "resolves sound key → play (with fallback to defaults)" but doesn't specify the resolution order. Questions:
- Does `trigger("candle", "on_state_lit")` check `obj.sounds.on_state_lit` → `defaults.on_state_lit` → nil?
- What about state-qualified ambient keys? (`ambient_lit` vs `ambient`)
- What if `defaults.lua` has `on_verb_break = "generic-break.opus"` but the object also has it?
**Risk:** Medium — ambiguity causes inconsistent behavior across verb handlers.
**Recommendation:** Document the resolution chain explicitly: `obj.sounds[key] → defaults[verb] → nil (silent)`. Object-specific always wins. Defaults are last resort. Add this to the Track 0A spec as a code comment or decision.

---

### ⚠️ C7: scan_object lifecycle timing unclear

**Location:** Track 0A + loader integration (Track 2A)
**Issue:** `M:scan_object(obj)` extracts sounds tables and queues files. But when is it called?
- During `loader.load_source()`? Too early — template not resolved yet.
- During `registry:register()`? Possible but couples registry to sound.
- After `loader.resolve_template()` in the room loading flow? Right timing but needs explicit call site.
**Risk:** Medium — wrong timing means sounds tables are incomplete (pre-template) or never scanned.
**Recommendation:** Specify: scan happens AFTER `loader.resolve_template()` and `registry:register()`, as a post-registration hook. The loader calls `ctx.sound_manager:scan_object(obj)` if sound_manager is non-nil. Add the exact insertion point (loader line reference) to Track 2A.

---

## Non-Issues (Explicitly Approved)

| Aspect | Assessment |
|--------|-----------|
| **Driver injection pattern** | ✅ Clean. Matches ctx.ui injection pattern. Principle 8 compliant. |
| **effects.register("play_sound")** | ✅ Correct integration point. Uses existing effect infrastructure. |
| **ctx.sound_manager = nil in headless** | ✅ Zero overhead. Same pattern as ctx.ui. |
| **Concurrency limits (4 one-shots, 3 ambients)** | ✅ Reasonable for 24 MVP sounds. |
| **Lazy loading piggybacking on room load** | ✅ No new loading mechanism needed. |
| **pcall() everywhere on bridge** | ✅ Sound failure must never crash the game. |
| **File ownership boundaries** | ✅ No conflicts in any wave. |
| **Wave dependency chain** | ✅ Correct (with C4 clarification). |
| **500 LOC module guard** | ✅ 150 LOC estimate is realistic for init.lua. |
| **No new GUIDs needed** | ✅ Sound adds fields to existing objects, no new entities. |

---

## Summary

| # | Finding | Severity | Blocks WAVE |
|---|---------|----------|-------------|
| C1 | Terminal driver os.execute() blocks | ⚠️ Spec gap | 0 |
| C2 | Dual integration path (effects vs direct) | ⚠️ Design ambiguity | 2 |
| C3 | Crossfade not in driver contract | ⚠️ Spec gap | 0 (web driver) |
| C4 | Board/plan parallelism contradiction | ⚠️ Doc inconsistency | 1-2 sequencing |
| C5 | .ogg vs .opus extension mismatch | ⚠️ Naming | 1 |
| C6 | Sound key resolution chain unspecified | ⚠️ Spec gap | 0 |
| C7 | scan_object lifecycle timing unclear | ⚠️ Spec gap | 2 |

**None of these are ❌ blockers.** All are fixable in a single v1.1 pass by the architect (me). The architecture is sound — these are specification gaps, not structural problems.

---

*Bart — Systems thinker. Every boundary matters.*
