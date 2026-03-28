# Orchestration Log: bart-object-lua-batch
**Timestamp:** 2026-03-20T22:00Z  
**Agent:** Bart (Architect)  
**Status:** ✅ COMPLETE

## Deliverables
- **4 Object Lua Files Shipped:**
  1. `src/meta/objects/candle-holder.lua` — composite object with detachable candle (parts pattern)
  2. `src/meta/objects/wall-clock.lua` — 24-state cyclic FSM (hour_1 → hour_24 → hour_1)
  3. `src/meta/objects/candle.lua` — enhanced (extinguish/partial burn/timed_events)
  4. `src/meta/objects/match.lua` — enhanced (no-relight, timed_events)

## Design Decisions Filed (6 total)
1. **D-OBJ001:** `timed_events` replaces `on_tick` for timer-driven objects
2. **D-OBJ002:** Candle uses `remaining_burn` for pause/resume timer
3. **D-OBJ003:** Match extinguish → spent (terminal), NOT unlit
4. **D-OBJ004:** Wall clock = 24-state cyclic FSM (no engine special-case code)
5. **D-OBJ005:** Candle holder uses parts pattern for detachable candle
6. **D-OBJ006:** Terminal spent states carry `consumable = true` flag

## Architectural Decisions
- **timed_events metadata pattern:** All timer behavior declarative in state definitions, not imperative callbacks
- **Pause/resume without engine support:** Candle's `remaining_burn` field makes pause/resume a metadata concern
- **Match is terminal:** No relight path (conservation of matches) vs candle (reusable)
- **Wall clock is pure FSM:** 24 states generated via Lua loop, one 3600s transition per state, cyclic wrap
- **Composite candle-holder:** Minimal reference to existing candle.lua, follows nightstand/poison-bottle parts pattern
- **Consumable flag:** Signal to engine that object is fully consumed (spent state = terminal + consumable)

## No Engine Changes Required
All objects use standard FSM patterns, timed_events, and composite reference — engine remains generic and untouched.

## Testing
Ready for Nelson's playtest validation. Objects now in `src/meta/objects/` awaiting integration tests.
