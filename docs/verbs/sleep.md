# Sleep

> Sleep to pass time and restore health.

## Synonyms
- `sleep` — Sleep for 1 hour (or specify duration)
- `rest` — Rest/sleep (synonym)
- `nap` — Nap/quick rest

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `sleep` — Sleep for 1 hour (default)
- `sleep for [number] hours` — Sleep for specified duration
- `sleep for [number] hour` — Sleep for specified duration
- `rest` — Same as sleep
- `nap` — Shorter rest

## Behavior
- **Time passage:** Advances game time by specified hours
- **Duration parsing:** Extracts number from "sleep for X hours"
- **Default:** 1 hour if no duration specified
- **Health restoration:** May restore health based on injuries
- **State change:** Updates `ctx.game_seconds` for time progression
- **Message:** "You sleep for X hours."

## Design Notes
- **Time mechanics:** Sleep is primary method for time progression in early game
- **Duration expressions:** Parser handles "for 2 hours", "for 8 hours", etc.
- **Health recovery:** Sleep may reduce injury severity (depends on injury mechanics)
- **No location checking:** Can sleep anywhere (initially)

## Related Verbs
- `rest` — Alias for sleep
- `nap` — Shorter rest
- `time` — Check current time

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["sleep"]`, `handlers["rest"]`, `handlers["nap"]`
- **Time constants:** Uses GAME_SECONDS_PER_REAL_SECOND, GAME_START_HOUR, DAYTIME_START/END
- **Ownership:** Smithers (UI) — output messages; Bart (Architect) — time progression
