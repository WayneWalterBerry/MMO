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

### Playtest 003 Findings (2026-03-20)
- **Pass-002 bug fixes: 5/5 tested FIXED.** BUG-008 (poison death), BUG-009 (parser debug), BUG-010 (nightstand IDs), BUG-012 (spent match priority), BUG-014 ("poison bottle" noun). All solid.
- **Wearable system is polished.** Cloak wear/remove, sack-on-head vision blocking, chamber pot helmet with flavor text, slot conflicts ("Already wearing X. Remove it first."), inventory shows Worn section with slots. All work.
- **Composite objects mostly work.** Drawer detaches, becomes independent 2-handed object, can be put back. Cork uncorks and becomes pickable. BUT:
- **BUG-017 (CRITICAL): Replacing drawer destroys surface objects.** Putting drawer back into nightstand deletes the candle and bottle from the surface. Room goes dark. Unrecoverable. FSM state transition wipes children.
- **BUG-015: Wardrobe shows internal IDs** ("wool-cloak", "sack" instead of display names). Same class as BUG-010, just not fixed in wardrobe container.
- **BUG-018: "kick" → "lick" parser confusion.** 1-char edit distance triggers false Tier 2 match.
- **BUG-019: FSM state labels leak** into player text — "(drawer open)" shown in move/put messages.
- **Furniture movement works well.** Push bed, pull rug, discover trap door + brass key. Wardrobe too heavy. "look under bed" reveals hidden knife.
- **Trap door discovery sequence is excellent game design.** push bed → pull rug → find key + trap door → open trap door. Multi-step environmental puzzle.
- **Movement verbs still not implemented.** "go down", "down" don't work for trap door stairs. "unlock" not recognized. Expected for current build.
- **BUG-021: Parser startup debug line** `[Parser] Tier 2 loaded...` leaks without --debug flag.
- **BUG-022: "Play again?" prompt** says yes but exits instead of restarting.

### Playtest 004 Findings (2026-03-20)
- **Massive regression pass — 10 previous bugs verified FIXED.** BUG-009, BUG-010, BUG-012, BUG-015, BUG-016, BUG-017, BUG-019, BUG-021 all confirmed resolved.
- **Sleep verb works great.** Default duration, specific hours, "take a nap" alias, too-long/too-short rejection, clock advancement, time-of-day descriptions. All solid.
- **Player skills system works.** Sewing manual in sack in wardrobe. Skill gate before reading: "don't know how to sew." After reading: "don't see cloth to sew." Different error confirms unlock. No sewable cloth found in room.
- **Spatial puzzle is polished.** push bed → pull rug → brass key + trap door. Descriptions update dynamically. "down" exit appears after trap door opens. Immovable wardrobe/nightstand handled correctly.
- **Curtains + daylight work.** Open/close curtains toggles room light descriptions. Morning light floods in at 7:53 AM.
- **Terminal UI renders** but has Unicode encoding issue (candle icon shows as `Γùï`). Status bar shows room name + time. Scrollback commands shown.
- **BUG-017 (CRITICAL) FIXED.** Drawer replace no longer destroys surface objects. Candle + bottle survive.
- **Composite objects work.** Drawer detaches, requires 2 hands, reattaches. Cork uncorks, becomes independent pickable object with description.
- **BUG-023 (COSMETIC): UI Unicode encoding** — candle icon garbled in Windows terminal.
- **BUG-024 (MINOR): Sack-on-head regression** — `put sack on head` now equips to shoulder as "backpack", not head. No vision blocking. Worked in pass-003.
- **BUG-025 (MINOR): Single-slot wearable system** — wearing cloak blocks wearing sack (different body parts should coexist). May be intentional simplification.
- **Not tested:** Blood/writing, sleep-until-dawn, candle burn-out during sleep, poison death.

### Playtest 005 Findings (2026-03-20)
- **Pass-004 fixes verified: BUG-024 (sack vision blocking) and BUG-025 (multi-slot wearables) both FIXED.** Sack on head → "Everything goes dark" + blocks look. Cloak (back) + sack (head) coexist in inventory. Multi-slot system is solid.
- **BUG-026 (CRITICAL): Movement verbs completely unimplemented.** `go down`, `down`, `descend`, `climb down`, `enter trap door`, `go north`, `north`, `walk down`, `go through trap door`, `use trap door`, `go west` — ALL fail. Parser has zero movement verb recognition. Exits are displayed but unusable. This is the #1 blocker for game progression.
- **BUG-027: FSM state labels leak on trap door.** `close trap door` → "You can't close a trap door (open)." Same class as BUG-019, not fixed for trap door object.
- **BUG-028: "key" doesn't resolve to "brass key".** Parser requires full adjective for noun resolution. Same class as BUG-014.
- **Room escape puzzle works beautifully.** push bed → pull rug → brass key + trap door → open trap door. All descriptions update dynamically. Trap door has rich multi-sensory descriptions (visual, smell). The content design is ahead of the engine.
- **Help text is comprehensive** — 40+ verbs listed, accurately reflects parser capabilities. No movement verbs listed because none exist.
- **Multi-room testing blocked.** Sections 4-7 of the test plan (room transitions, object persistence, candle carry, Room 2 exploration) could not be tested. Entire test plan needs re-run once movement is implemented.

### Playtest 006 Findings (2026-03-20)
- **BUG-026 (CRITICAL) FIXED.** Movement verbs fully implemented. 8+ verb forms work: `down`, `d`, `go down`, `descend`, `climb down`, `enter trap door`, `up`, `u`, `go up`, `ascend`, `climb up`. This was THE critical blocker from pass-005.
- **The Cellar is a fully realized second room.** Rich atmospheric descriptions: rough-hewn granite, dripping water, cobwebs, cold damp air. Objects: barrel (sealed), iron torch bracket (empty). Exits: up (stairway), north (locked iron door).
- **Object persistence across rooms works perfectly.** Drop brass key in cellar → go up → go back down → key still there. Bedroom state (moved bed, open trap door, dropped matchbox) all preserved across transitions.
- **Light carries between rooms.** Lit candle in hand illuminates cellar. Transition text is atmospheric and distinct for each direction.
- **Transition text is excellent.** Down: "each step taking you deeper into cold, damp air." Up: "The floorboards creak beneath your feet, and the shadows seem to lean in closer."
- **Invalid directions handled cleanly.** `go south` in cellar → "You can't go that way." No crashes.
- **Time advances across rooms.** Clock keeps ticking, dawn transition observed at 6:10 AM.
- **BUG-029 (MINOR): Iron door not examinable.** Exit shows "a heavy iron-bound door (locked)" but `look at door` / `look at iron door` → "You don't see that here."
- **BUG-030 (MAJOR): No unlock verb exists.** `unlock door`, `use key on door` all fail. Brass key + locked door = dead end. **Next critical-path blocker for Room 3.**

## Cross-Agent Updates (2026-03-20)
- **From Bart:** Wearable engine implementation complete (WEAR/REMOVE verbs, slot conflicts, vision blocking). All wear operations validated in pass-002 — system is solid and ready for content expansion.
- **From Frink:** MUD verb research identifies that multiplayer verbs should be first-class primitives. Strategic recommendations include 50-100 predefined socials for MVP (retention drivers). Competitive analysis shows tap-to-suggest UI is critical for mobile parsing UX.
