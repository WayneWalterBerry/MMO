# D-TEST-BACKDOOR: Tester Room-Start Backdoor

**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  

## Decision

Added `--room <id>` (alias `--start-room <id>`) and `--list-rooms` CLI flags to `src/main.lua` for tester use.

## Rationale

With Level 1 expanding to 7+ rooms, testers (Nelson, Lisa) need direct room access without replaying the full game. This is a debug feature — prints a visible `=== DEBUG ===` banner when active.

## Usage

```
lua src/main.lua --list-rooms              # Show all available rooms
lua src/main.lua --room cellar             # Start in the cellar
lua src/main.lua --start-room deep-cellar  # Alternate flag name
lua src/main.lua                           # Normal start (unchanged)
```

## Impact

- **No effect on normal gameplay** — default behavior is identical when no flag is given
- **Graceful errors** — invalid room ID prints available rooms and exits
- **Minimal change** — ~40 lines in main.lua, no new files or modules
- **Team note:** All room IDs in `src/meta/world/` are automatically discovered; no hardcoded list to maintain
