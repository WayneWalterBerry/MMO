# D-AUTO-IGNITE-TIMER: auto_ignite() must use FSM timer system

**Author:** Smithers (UI/Parser Engineer)
**Date:** 2026-07-17
**Bug:** #178 — lit match never burns out
**Status:** Implemented

## Decision

Any code that directly sets `obj._state` on a registry object MUST also call `fsm_mod.stop_timer(obj.id)` before the state change and `fsm_mod.start_timer(registry, obj.id)` after. The FSM `transition()` function does this automatically — direct `_state` writes bypass it.

## What Changed

1. **`src/engine/verbs/fire.lua` — `auto_ignite()`**: Added `fsm_mod.stop_timer()` / `fsm_mod.start_timer()` around the direct state application. This was the root cause of bug #178 — matches auto-ignited as fire sources never registered burn-out timers.

2. **`src/engine/search/containers.lua`**: The fallback path at line 107 that sets `_state = "open"` when `fsm.transition()` fails now also calls stop/start_timer. Defensive fix for any future container states with `timed_events`.

## Not Changed (by design)

3. **`src/engine/injuries.lua`**: Multiple `_state` assignments on injury and treatment objects. Injuries live on `player.injuries` (not in the registry) and use their own `turns_active` tick counter. Treatment objects (`_state = "applied"` / `"soiled"`) don't currently have `timed_events` and the `apply_treatment` / `remove_treatment` functions don't receive a registry parameter. If treatment objects ever need timers, those functions must be refactored to accept `registry`. Tracked as future work.

## Affects

- **Bart** (FSM owner): Aware that direct `_state` writes are a timer-bypass risk. Consider adding a `fsm.force_state()` helper that wraps the stop/apply/start pattern.
- **Nelson** (QA): All 10 `test-match-burnout.lua` tests now pass. Full suite: 0 regressions (1 pre-existing failure in unconsciousness-triggers — missing verbs).
- **Flanders** (objects): Match object metadata is correct — `timed_events` and `timer_expired` auto-transition already present. No object changes needed.
