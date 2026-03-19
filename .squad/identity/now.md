---
updated_at: 2026-03-19T12:37:39.165Z
focus_area: V1 REPL playable — iterating toward play test
active_issues: []
---

# What We're Focused On

V1 REPL is playable (`lua src/main.lua`). Next: integrate tool system (requires_tool/provides_tool) into verb handlers, resolve new object designs (paper, pen, knife, pin, needle), implement player skills system (lockpicking, sewing), and debate state model confirmed as file-per-state.

## Pending Follow-Ups
- Bart: wire Comic Book Guy's tool convention into LIGHT verb (matchbox check)
- Comic Book Guy: design paper/pen/knife/pin/needle objects + sewing/crafting
- Bart + CBG: new objects need verb handler support (WRITE, CUT, SEW, PICK LOCK)
- Frink: PWA + Wasmoon prototype (platform research done, implementation next)
- Brockman: docs sweep after integration pass
- Brockman: March 19 newspaper (in progress)

## Recent Directives Not Yet Implemented
- Paper mutates with written words (dynamic mutation)
- Knife/pin as injury tools → blood for writing
- Player skills (lockpicking, sewing) unlock tool+verb combos
- Sewing: cloth → clothing with needle
- Puzzles are first-class design goal
- File-per-state confirmed
