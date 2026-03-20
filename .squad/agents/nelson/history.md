# Nelson — Tester History

## Project Context
- **Owner:** Wayne "Effe" Berry
- **Project:** MMO — Lua text adventure engine
- **Stack:** Pure Lua, REPL-based, run via `lua src/main.lua`
- **Game starts in darkness** — player must feel around, find matchbox, light match to see
- **Key systems:** FSM engine for object state, Tier 2 embedding parser, container model, sensory verbs

## Critical Path
1. feel around → discover nightstand
2. open drawer → access matchbox
3. get matchbox → open matchbox → get match
4. light match (or strike match on matchbox) → room is lit
5. look around → see the room for the first time

## Learnings

### Playtest 001 Findings
- **Critical path works perfectly.** feel → open drawer → get matchbox → open matchbox → get match → light match → look → light candle all succeed cleanly.
- **BUG-001 (HIGH): Text wrapping duplicates characters.** Every long description has broken words at line boundaries (e.g., "worl\nld", "puppets\ns"). Off-by-one in wrap function.
- **BUG-002 (MED): Window examine doesn't reflect broken state.** FSM updates exits but `look at window` still shows intact description.
- **BUG-003 (MED): "yell for help" falsely matches `help` command.** Tier 2 gives score 1.00 because "help" appears literally in input.
- **BUG-004 (MED): No movement commands.** "go north", "north" fail. Room shows exits but player can't use them. No helpful error message.
- **BUG-005 (LOW): Typo recovery drops object.** "loko at bed" → recovers "look at" but loses "bed", does room look instead.
- **BUG-006 (LOW): Dawn light doesn't work through broken window.** Room goes pitch dark at 5:17 AM with shattered window.
- **BUG-007 (LOW): feel drawer inherits nightstand description.** Also reports opening an already-open drawer.
- **Parser diagnostic output has encoding issue.** Unicode arrow → displays as `ΓåÆ` in terminal.
- **Parser strengths:** "grab the knife" → take, "examine" → look at, compound commands, pronoun "it" — all work.
- **No feedback on failed parses.** Player sees nothing when input doesn't match. Needs "I don't understand" message.
- **Time passes too fast.** ~7-8 minutes per action; 3 hours pass in 25 commands.
