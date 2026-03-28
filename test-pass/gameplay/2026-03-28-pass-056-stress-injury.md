# Pass-056: Stress Injury System

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scope:** Stress injury accumulation, threshold debuffs, rest-based cure

## Executive Summary

**Tests run:** 12 | **Pass:** 5 | **Fail:** 4 | **Blocked:** 3
**Bugs filed:** 4 (1 CRITICAL, 1 HIGH, 2 MEDIUM)

The stress trigger mechanism works correctly — killing creatures fires `witness_creature_death` and prints narration ("The sight of death shakes you."). Stress accumulates at +1 per kill as designed. However, the **cure path is completely broken**: the `rest` verb never calls `injuries.cure_stress()`, so stress can never be cured through gameplay. Higher threshold testing (shaken/distressed/overwhelmed) was blocked because bare-fist combat lethality kills the player before accumulating 3+ kills.

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-188 | CRITICAL | Rest verb does not call cure_stress — stress can never be cured |
| BUG-189 | HIGH | cure_stress ignores "2 hours" duration requirement from stress.lua |
| BUG-190 | MEDIUM | cure_stress and is_safe_room use different safety check methods |
| BUG-191 | MEDIUM | No player feedback for sub-threshold stress accumulation |

## Test Results

### T-001: Stress trigger on first creature kill
**Command:** `attack rat` (in cellar)
**Response:** Combat resolves, then: `The sight of death shakes you. a brown rat is dead!`
**Verdict:** ✅ PASS
**Notes:** Trigger narration `witness_creature_death` fires correctly after rat death. Stress +1.

### T-002: Stress trigger on second creature kill
**Command:** `attack spider` (in cellar, same session as T-001)
**Response:** Combat resolves, then: `The sight of death shakes you. a large brown spider is dead!`
**Verdict:** ✅ PASS
**Notes:** Second trigger narration fires correctly. Stress now at 2. Consistent across 4 test runs.

### T-003: Injuries list at stress=2 (below shaken threshold=3)
**Command:** `injuries` (after 2 kills, stress=2)
**Response:** Lists physical injuries only. No stress-related output. "You feel fine." when no physical injuries present.
**Verdict:** ⚠️ WARN
**Bug:** BUG-191
**Notes:** Code review confirms: `injuries.list()` checks `has_stress = (player.stress or 0) > 0 and injuries.get_stress_level(player) ~= nil`. At stress=2, `get_stress_level` returns nil (below threshold 3), so stress is invisible. Player has zero feedback that stress is accumulating. Expected: some indication like "You feel uneasy" even below threshold.

### T-004: Stress threshold — shaken at 3 kills
**Command:** N/A — could not reach 3 kills
**Response:** N/A
**Verdict:** 🔴 BLOCKED
**Notes:** Bare-fist combat against rat (5HP) + spider (3HP) causes ~50-80HP of combined bleeding/venom damage. Player dies before reaching 3rd creature. Rooms beyond cellar require surviving 2 fights + unlocking storage door. Need weapon or healing to test.

### T-005: Stress threshold — distressed at 6 kills
**Command:** N/A
**Response:** N/A
**Verdict:** 🔴 BLOCKED
**Notes:** Blocked by T-004. Only 6 initial creatures across all rooms; need to survive multiple fights.

### T-006: Stress threshold — overwhelmed at 10 kills
**Command:** N/A
**Response:** N/A
**Verdict:** 🔴 BLOCKED
**Notes:** Blocked by T-004. Would require creature respawn cycles.

### T-007: Rest in unsafe room (cellar with live spider)
**Command:** `rest` (in cellar after killing rat, spider still alive)
**Response:** `You drift deeper into sleep. The pain fades. Everything fades. You never wake up. YOU HAVE DIED.`
**Verdict:** ❌ FAIL
**Bug:** BUG-188
**Notes:** Player died from bleeding during sleep. No stress-related output at all. Rest handler (`rest.lua`) does not call `injuries.cure_stress()` — it was never wired up. Even if the player survived, stress would persist. Additionally, the rest verb does not check room safety for stress purposes; it simply never addresses stress at all.

### T-008: Rest in safe room (bedroom, no creatures)
**Command:** `rest for 2 hours` (in bedroom after killing 1 rat)
**Response:** `You close your eyes and rest for 2 hours. It is now 4:04 AM.`
**Verdict:** ❌ FAIL
**Bug:** BUG-188
**Notes:** No stress cure message appeared. Expected: "With rest and safety, the panic slowly fades." (from `cure_stress`). The rest verb completed successfully but did not call `injuries.cure_stress()`. Confirmed by code review: `rest.lua` ticks injuries and advances FSM timers during sleep, but has zero references to stress or cure_stress.

### T-009: Rest in safe room — bleeding kills during sleep
**Command:** `rest` (in bedroom after 1 rat kill, player bleeding)
**Response:** `You drift deeper into sleep... You never wake up. YOU HAVE DIED.`
**Verdict:** ✅ PASS
**Notes:** Bleeding correctly ticks during sleep and can kill the player. This is working as designed — bleeding is lethal if untreated. However, this makes stress testing via rest impossible without healing first.

### T-010: Headless combat auto-stance with stress flee_bias
**Command:** Code review of `verbs/init.lua` lines 248-259
**Response:** N/A (code review)
**Verdict:** ✅ PASS
**Notes:** In headless mode, `prompt_stance()` correctly reads `get_stress_effects()` and auto-selects "flee" with probability = flee_bias when stressed. Falls back to "balanced". Cannot verify in gameplay (need stress >= 6 for flee_bias).

### T-011: Stress attack_penalty in combat resolution
**Command:** Code review of `combat/resolution.lua` lines 202-209
**Response:** N/A (code review)
**Verdict:** ✅ PASS
**Notes:** `resolve_damage()` correctly reads `get_stress_effects()` and applies attack_penalty. Each -1 penalty reduces force by 15%, floored at 0.3x. Well-implemented. Cannot verify in gameplay (need stress >= 3 for penalty).

### T-012: cure_stress duration check
**Command:** Code review of `injuries/init.lua` lines 515-536
**Response:** N/A (code review)
**Verdict:** ❌ FAIL
**Bug:** BUG-189
**Notes:** `cure_stress()` resets stress to 0 immediately without checking rest duration. The stress.lua metadata specifies `cure.duration = "2 hours"`, but the function ignores this. A 10-minute nap would cure 10 points of stress — same as 2 hours. Also, `cure_stress()` checks `ctx.room.creatures` for safety, while `is_safe_room()` uses `creatures_mod.get_creatures_in_room(registry, room_id)` — different code paths that may produce different results (BUG-190).

## Detailed Bug Reports

### BUG-188: CRITICAL — Rest verb does not call cure_stress

**Severity:** CRITICAL — Stress cure mechanic is completely non-functional
**Location:** `src/engine/verbs/rest.lua`
**Reproduction:**
1. Kill any creature (stress accumulates via witness_creature_death trigger)
2. Go to a safe room (no hostile creatures)
3. Type `rest for 2 hours`
4. Type `injuries` — stress is NOT cured

**Expected:** After resting in a safe room, stress should be cured and message "With rest and safety, the panic slowly fades." should appear.
**Actual:** Rest completes normally but stress persists. No stress-related processing occurs during rest.
**Root cause:** `rest.lua` function `do_sleep()` ticks injuries, FSM timers, blood state, and candle burnout during sleep — but has zero calls to `injuries.cure_stress()`. The function exists in `injuries/init.lua` but is never invoked by any verb handler.
**Impact:** Players who accumulate stress have no way to recover. Attack penalties, flee bias, and movement penalties are permanent for the session.

### BUG-189: HIGH — cure_stress ignores duration requirement

**Severity:** HIGH — When wired up, cure will be too easy
**Location:** `src/engine/injuries/init.lua` lines 515-536
**Reproduction:** Code review — `cure_stress()` checks `player.stress <= 0` and `ctx.room.creatures` for hostiles, then immediately sets `player.stress = 0`.
**Expected:** Should require minimum 2 hours of rest (per `stress.lua` metadata: `cure.duration = "2 hours"`).
**Actual:** Duration is ignored. A 10-minute nap would cure 10 stress points.
**Root cause:** `cure_stress()` was implemented without reading the `cure.duration` field from the stress definition.

### BUG-190: MEDIUM — Inconsistent room safety checks

**Severity:** MEDIUM — Could cause stress to cure in unsafe rooms (or not cure in safe rooms)
**Location:** `src/engine/injuries/init.lua` lines 515-554
**Reproduction:** Code review comparison:
- `cure_stress()` (line 519-528): checks `ctx.room.creatures` array for `creature.hostile and creature.alive ~= false`
- `is_safe_room()` (line 540-553): uses `creatures_mod.get_creatures_in_room(registry, room_id)` and checks `c.alive ~= false and c._state ~= "dead" and c._state ~= "fled"` plus `c.behavior.aggression > 0`
**Expected:** Both functions should use the same safety criteria.
**Actual:** Different data sources (`ctx.room.creatures` vs registry query), different alive checks, different hostility checks (`hostile` flag vs `aggression > 0`).

### BUG-191: MEDIUM — No feedback for sub-threshold stress

**Severity:** MEDIUM — Player has no warning stress is building
**Location:** `src/engine/injuries/init.lua` function `injuries.list()` lines 312-362
**Reproduction:**
1. Kill 1-2 creatures (stress = 1-2, below shaken threshold of 3)
2. Type `injuries`
3. Output: "You feel fine. No injuries to speak of." (if no physical injuries)
**Expected:** Some indication that stress is building, e.g. "You feel slightly uneasy." or "Stress: 2/3 until shaken".
**Actual:** Zero feedback. Player cannot tell they have any stress until crossing the threshold at 3.
**Notes:** Trigger narration ("The sight of death shakes you.") fires per-kill, but the `injuries` command gives no status.

## Test Environment Notes

- All tests run via `--headless` mode with piped input
- Combat auto-resolves with "balanced" stance in headless mode
- Player starts with 100HP, no weapons, no armor
- Cellar has 1 rat (5HP) and 1 spider (3HP + venom)
- Bare-fist combat causes ~8-54 HP damage to player per fight (high variance)
- Spider venom stacks and can kill within 2-3 ticks after combat

## Recommendations

1. **BUG-188 fix:** Add `injuries.cure_stress(ctx.player, ctx)` call to `rest.lua` after sleep completes, before time display. Check `is_safe_room()` before calling.
2. **BUG-189 fix:** Add duration check to `cure_stress()` — compare `sleep_hours` against `stress_def.cure.duration` (parsed to hours).
3. **BUG-190 fix:** Have `cure_stress()` delegate to `is_safe_room()` instead of inline room safety check.
4. **BUG-191 fix:** In `injuries.list()`, show sub-threshold stress: "You feel a growing unease. (stress: N)" when `player.stress > 0` even if below threshold.
5. **Threshold testing:** Needs weapon or healing items to survive 3+ fights. Consider adding a test-only flag or providing a starting weapon for combat testing.

---
**Signed:** Nelson — Tester
**Pass completed:** 2026-03-28
