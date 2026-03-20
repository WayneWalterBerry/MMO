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

### Playtest 002 Findings (2026-03-20)
- **Matchbox container inventory works correctly.** Count tracks when taking/returning matches. "Inside: N wooden matches" shown with light. Non-match items rejected as "too heavy."
- **Poison bottle FSM is excellent.** 4 visual states (sealed, open+full, empty), 3 smell states, all distinct. Opening/drinking transitions clean.
- **Container nesting works.** Matchbox inside sack, sack in inventory — all renders correctly.
- **Wear system works.** Cloak equips and shows in "Worn:" section of inventory. ✅ **Coordinated with Bart's wearable engine implementation** (WEAR/REMOVE verbs, slot conflicts, vision blocking).
- **Sack had hidden items.** Sewing needle and thread inside burlap sack in wardrobe — not mentioned in sack description.
- **BUG-008 (MAJOR): Drinking poison doesn't kill or harm the player.** "World goes dark" then continue playing 4 hours later, completely fine.
- **BUG-009 (MED): Parser debug output leaks to player** on unrecognized commands. `[Parser] No match found...` shown directly.
- **BUG-010 (MINOR): Internal object IDs shown** in nightstand surface listing ("candle", "poison-bottle" instead of display names).
- **BUG-011 (MINOR): "help" keyword intercepts write sub-prompt.** Writing "help..." on paper triggers help command instead.
- **BUG-012 (MINOR): "take match" prefers spent match on floor** over fresh match in matchbox in hand.
- **BUG-013 (COSMETIC): Tactile matchbox examine doesn't vary by count** — same text whether 6 or 1 matches remain.
- **BUG-014 (COSMETIC): "poison bottle" not recognized** — only "bottle" works as noun.
- **Note:** BUG-003 from pass 001 is still present — "help" intercepts in write sub-prompt too.
- **Note:** BUG-009 replaces the "no feedback on failed parses" observation from pass 001 — there IS now output, but it's the raw parser debug, not player-facing text.

## Cross-Agent Updates (2026-03-20)
- **From Bart:** Wearable engine implementation complete (WEAR/REMOVE verbs, slot conflicts, vision blocking). All wear operations validated in pass-002 — system is solid and ready for content expansion.
- **From Frink:** MUD verb research identifies that multiplayer verbs should be first-class primitives. Strategic recommendations include 50-100 predefined socials for MVP (retention drivers). Competitive analysis shows tap-to-suggest UI is critical for mobile parsing UX.
