# Squad Decisions — MERGED

**Last Updated:** 2026-03-24T19:55:00Z  
**Merger:** Scribe  
**Source:** Inbox merged (deduplicated, reorganized by category)  
**Latest Merge (2026-03-24T19:55:00Z):** D-FIRE-PROPAGATION-ARCHITECTURE, D-WASH-VERB-FSM, D-MATCH-TERMINAL-STATE, D-PUSH-LIFT-SLIDE-VERBS, D-ENGINE-HOOKS-USE-EAT-DRINK, D-SALVE-ANTIDOTE-OBJECTS  
**Previous Decisions:** D-PLAYER-CANONICAL-STATE, D-OBJECT-INSTANCING-FACTORY, D-ENGINE-REFACTORING-REVIEW, D-META-CHECK-V1-APPROVAL, D-WAYNE-CODE-REVIEW-DIRECTIVE, D-WAYNE-METACOMPILER-COMPILER-LINTER, D-WAYNE-TDD-REFACTORING-DIRECTIVE, D-TESTFIRST, D-HIRING-DEPT, D-WAYNE-BATCH-2026-03-24, D-CHEST-DESIGN, D-SEARCH-OPENS, D-ARMOR-INTERCEPTOR, D-META-VALIDATION, D-BRASS-BOWL-KEYWORD-REMOVAL, D-EMBEDDED-PRESENCES, D-OPEN-CLOSE-HOOKS, D-P1-PARSER-CLUSTER, D-CONTAINER-SENSORY-GATING

---

## OBJECT INSTANTIATION & PLAYER STATE (Burndown Wave 6 — 2026-03-24T19:30:00Z)

### D-OBJECT-INSTANCING-FACTORY
**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-24 (Implemented in #105)  
**Status:** Implemented  
**Issue:** #105

Created `src/engine/factory/init.lua` — a formal instancing factory implementing Core Principle 5 (Multiple Instances Per Base Object).

**API:**
```lua
local factory = require("src.engine.factory")

-- Create N instances from one base object
local matches = factory.create_instances(match_base, 6, {
    location = "matchbox",
    per_instance_overrides = {
        [3] = { _state = "lit" },
        [4] = { _state = "spent" },
    },
})

-- Create a single instance
local candle = factory.create_one(candle_base, { location = "nightstand.top" })

-- Generate a GUID standalone
local guid = factory.generate_guid()
```

**Key Decisions:**
1. **Self-contained module** — factory has its own `deep_copy`/`deep_merge` rather than importing from loader. Keeps the module dependency-free and testable in isolation.
2. **`instance_guid` field** (not `guid`) — base objects own `guid`; instances get `instance_guid` to avoid confusion. `guid` is cleared on instances.
3. **`type_id` traceability** — every instance records `base.guid` as `type_id`, matching the existing room instance pattern.
4. **Pure Lua GUID generator** — `factory.generate_guid()` produces UUID v4 strings using `math.random`. Sufficient for single-process runtime; not cryptographic.
5. **Sequential id naming** — instances get `{prefix}-1`, `{prefix}-2`, etc. by default, matching the existing `match-1` through `match-7` pattern in room files.

**Impact on Other Agents:**
- **Moe (rooms):** Room files can continue using the existing `instances` array pattern. The factory formalizes the same pattern for programmatic use (e.g., spawning items at runtime).
- **Flanders (objects):** No changes needed to object definitions. The factory works with any base object table.
- **Nelson (tests):** 24 new tests in `test/engine/test-factory.lua`. Factory can be used in test setup for creating test fixtures.

**Verification:** 24 tests passing, zero regressions.

---

### D-PLAYER-CANONICAL-STATE
**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-24 (Implemented in #104)  
**Status:** Implemented  
**Issue:** #104

All player state MUST live on `ctx.player`. No player-related data on `ctx` root level.

**What Changed:**
- `visited_rooms` moved from `ctx.visited_rooms` → `ctx.player.visited_rooms`
- All engine code and tests updated to use `ctx.player.visited_rooms`
- Created canonical `src/engine/player.lua` module

**Rule Going Forward:**
When adding new player state (e.g., quest flags, reputation, discovered secrets), put it on `ctx.player` or a sub-table like `ctx.player.state`. Never on `ctx` directly.

**Who Should Know:**
- **Moe** — room definitions don't change, but movement verb now reads `ctx.player.visited_rooms`
- **Smithers** — parser/verb code should access player state via `ctx.player`
- **Nelson** — test mock contexts must put `visited_rooms` on `ctx.player`, not `ctx`
- **Gil** — web adapter updated; `web/dist/` will need rebuild

**Verification:** 8 tests passing, 113 files green.

---

## SENSORY & CONTAINER INTERACTION (2026-03-24)

### D-CONTAINER-SENSORY-GATING
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-24  
**Status:** Implemented  
**Issue:** #100

Container contents are now gated by FSM open/closed state for sensory verbs:

| Sense | Closed Container | Open Container |
|-------|-----------------|----------------|
| LOOK inside | Blocked — "is closed" | Shows contents |
| FEEL inside | Blocked — "is closed" | Feel contents |
| SEARCH | Blocked — "is closed" | Searches normally |
| SMELL | Passes through | Works |
| LISTEN | Passes through | Works |

**Transparent exception:** Closed transparent containers still allow LOOK (visual), but block FEEL (tactile).

**Key Constraint:** Gating uses ONLY `_state` (FSM state field). Objects with `open = false` but no FSM are NOT gated. This prevents false blocking on containers like the matchbox that use `is_open = false` as a search-system marker without intending sensory blocking.

**Affected Team Members:**
- **Flanders** (Object definitions): New containers that should block sensory access MUST have FSM states with "closed"/"open" in the state names. Objects without `_state` are treated as sensory-accessible.
- **Bart** (Engine): The `container_contents_accessible()` helper in `helpers.lua` is the single source of truth for this check.
- **Nelson** (QA): 18 new tests in `test/verbs/test-container-sensory-gating.lua`.

**Verification:** 18 tests passing, 103 files green.

---

## OBJECT & PARSER DECISIONS (2026-03-24)

### D-BRASS-BOWL-KEYWORD-REMOVAL
**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-03-24  
**Status:** Implemented  
**Fixes:** #153

Removed `"brass bowl"` from `brass-spittoon.lua` keywords to eliminate collision with `candle-holder.lua`. The fuzzy parser (Tier 5) scores objects by material match. Both brass-spittoon and candle-holder have `material = "brass"`. When a player typed "brass bowl", the spittoon matched on exact keyword AND the candle-holder scored on material, creating ambiguous resolution.

A spittoon is not a bowl — removing the misleading keyword is the correct fix. The spittoon retains 6 other keywords including "spittoon", "brass spittoon", "cuspidor", and "spit bowl." No player-facing regression; "brass spittoon" and "spittoon" still work. Reduces fuzzy disambiguation prompts for brass objects in the same room. Existing test updated; 11 new disambiguation tests added.

---

### D-EMBEDDED-PRESENCES
**Author:** Bart (Architect)  
**Date:** 2026-03-24  
**Status:** Implemented  

Rooms can now declare `embedded_presences = { "obj-id-1", "obj-id-2", ... }` — a list of object IDs whose presence is already described in `room.description`. The look handler skips these objects during the presences iteration, preventing duplicate display.

**Rationale:** BUG-050 — Multiple rooms (hallway, crypt, courtyard) had objects described in both `room.description` AND in the room_presence presences section. Torches, portraits, sarcophagi, etc. appeared twice. The previous `seen_presences` text-dedup only prevented identical text from repeating — it didn't prevent objects described in the prose from also rendering room_presence.

**Pattern:** Rooms add `embedded_presences` when their `description` already mentions specific instance objects. Objects in `embedded_presences` are still interactable — they're just not double-rendered in `look`. If an object is picked up and dropped in another room, it renders normally (the flag is per-room, not per-object).

---

### D-OPEN-CLOSE-HOOKS
**Author:** Bart (Architect)  
**Date:** 2026-03-24  
**Status:** Implemented  

Added `on_open` and `on_close` hooks to the open/close verb handlers, following the exact pattern of `on_wear`/`on_remove_worn`. Both support:
1. **Callback hooks:** `obj.on_open = function(obj, ctx) ... end` — fires after successful FSM transition
2. **event_output:** `event_output = { on_open = "text", on_close = "text" }` — one-shot flavor text, consumed after first fire

**Hook Taxonomy (Updated):**

| Hook | Verb | Pattern |
|------|------|---------|
| `on_wear` | wear | callback + event_output |
| `on_remove_worn` | remove | callback + event_output |
| `on_open` | open | callback + event_output |
| `on_close` | close | callback + event_output |
| `on_drop` | drop | fragility + event_output |
| `on_take` | take | event_output only |

**Constraints:** Hooks only fire on the FSM path (objects with `.states`). Mutation-based open/close does not fire hooks. Hooks fire AFTER the transition message prints but BEFORE the verb handler returns. Failed transitions (already open/closed, can't open) do NOT fire hooks.

---

### D-P1-PARSER-CLUSTER
**Author:** Smithers (UI/Parser Engineer)  
**Date:** 2026-03-24  
**Status:** Implemented  
**Issues:** #137, #138, #139, #140, #144, #145, #156

Seven parser/UI bugs fixed via TDD. Key design decisions:

1. **Idiom table ordering matters:** `set X down` → `drop X` idioms placed BEFORE `set fire to` in the table, but `set fire to` pattern is more specific (3 fixed words) so it wins when applicable. No ordering conflict.
2. **BODY_PARTS extended:** Added stomach/belly/gut/chest/side to the preprocessor's `BODY_PARTS` lookup to match `BODY_AREA_ALIASES` in verbs. These were missing, causing "in the gut" to not strip.
3. **Drop handler priority:** Worn items now checked BEFORE bags when generating error messages. Behavior change — previously all non-hand items got the "bag" error message regardless of actual location.
4. **Bulk drop is hands-only:** `drop all` iterates `player.hands[1..2]` only. Does NOT auto-remove worn items or dump bag contents. Drop = "release from hands."
5. **compose_natural period stripping:** Defensive — strips trailing periods from all phrases before joining with Oxford comma. Prevents splices when metadata `worn_description` fields end with periods.

**Commit:** 25f5372 — 34 new tests, zero regressions.

---

## TESTING DECISIONS

### D-HEADLESS: Headless Testing Mode
**Author:** Bart (Architect)  
**Date:** 2026-03-25  
**Status:** Implemented  
Added `--headless` command-line flag to `src/main.lua` that activates clean automated testing mode: disables TUI (no ANSI codes), suppresses prompt, emits `---END---` delimiters for trivial parsing, and preserves all game logic. Usage: `echo "look" | lua src/main.lua --headless`. Eliminates TUI false-positive hang reports from LLM play testing. Nelson MUST use `--headless` for all automated testing going forward.

---

### D-PIPE-TESTS: Per-Stage Pipeline Unit Tests
**Author:** Nelson (Tester)  
**Date:** 2026-03-22  
**Status:** Active  
Created `test/parser/pipeline/` with 7 isolated test files (224 tests total) covering each composable stage of the table-driven parser pipeline. Tests call individual stage functions via `preprocess.stages.*` for isolation; integration test exercises full pipeline. Each file independently runnable: `lua test/parser/pipeline/test-<name>.lua`.

---

## PHASE 3: HIT VERB, CONSCIOUSNESS, APPEARANCE (Smithers)

### D-HIT001: Hit verb is self-only in V1
**Author:** Smithers (Engine Engineer)  
**Date:** 2026-03-22  
**Status:** Implemented  
Hit/punch/bash/bonk/thump only work as self-infliction in V1. "hit <object>" is not supported. Combat hitting is future work (Phase 2+). This mirrors the stab verb pattern.

---

### D-HIT002: Strike disambiguates body areas vs fire-making
**Author:** Smithers (Engine Engineer)  
**Date:** 2026-03-22  
**Status:** Implemented  
`strike` is overloaded: if the noun resolves to a body area (`strike arm`, `strike head`), it routes to the hit handler. Otherwise it falls through to the existing fire-making handler (`strike match on matchbox`). The `parse_self_infliction` function handles disambiguation.

---

### D-HIT003: Smash NOT aliased to hit
**Author:** Smithers (Engine Engineer)  
**Date:** 2026-03-22  
**Status:** Implemented  
`smash` remains aliased to `break` because it's used for the vanity mirror smash transition. Creating a hit alias would break existing furniture destruction gameplay.

---

### D-CONSC-GATE: Consciousness gate before input reading
**Author:** Smithers (Engine Engineer)  
**Date:** 2026-03-22  
**Status:** Implemented  
The consciousness check runs at the top of the game loop, BEFORE the input-reading section. When unconscious, the loop ticks injuries and decrements the timer without consuming player input. Uses `goto continue` to re-enter the loop.

---

### D-APP-STATELESS: Appearance subsystem is stateless
**Author:** Smithers (Engine Engineer)  
**Date:** 2026-03-22  
**Status:** Implemented  
`appearance.describe(player, registry)` is a pure function that reads player state and composes a string. It never modifies state. Takes any player state table — future-proofed for multiplayer `look at <player>`.

---

### D-SLEEP-INJURY: Sleep now ticks injuries (bug fix)
**Author:** Smithers (Engine Engineer)  
**Date:** 2026-03-22  
**Status:** Implemented  
Sleep was missing `injury_mod.tick()` calls during its tick loop. Now each sleep tick calls the injury system, and death during sleep triggers "You never wake up" narration with `ctx.game_over = true`.

---

### D-HEADLESS: Headless Testing Mode
**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Implemented  
Added `--headless` command-line flag to `src/main.lua` that activates clean automated testing mode: disables TUI (no ANSI codes), suppresses prompt, emits `---END---` delimiters for trivial parsing, and preserves all game logic. Usage: `echo "look" | lua src/main.lua --headless`. Eliminates TUI false-positive hang reports from LLM play testing. Nelson MUST use `--headless` for all automated testing going forward.

---

## ARCHITECTURE & ENGINE DECISIONS

### D-14: True Code Mutation (Objects Rewritten, Not Flagged)
**Status:** Foundational  
Both the engine (src/engine/) and object definitions (src/meta/) are pure Lua. The loader executes meta-code in a sandboxed environment. This enables self-modifying behavior via `loadstring`.

---

### D-17: Universe Templates (Build-Time LLM + Procedural Variation)
**Author:** Bart (Architect)  
**Date:** 2026-03-18  
**Status:** Design  
Each player's universe is instantiated from a template. Templates are generated at build-time using LLM + procedural variation. Each player sees a slightly different world based on their seed, but the core gameplay loop is identical.

---

### D-37 to D-41: Sensory Verb Convention & Tool Resolution
**Author:** Bart (Architect)  
**Date:** 2026-03-19  
**Status:** Implemented  

**Key Decisions:**
1. **Sensory verbs work in darkness:** FEEL, SMELL, TASTE, LISTEN don't require light
2. **Tool resolution is verb-layer concern:** When a verb needs a tool (fire_source, needle, etc.), it queries capabilities, not inventory IDs
3. **Blood as virtual tool:** When `player.state.bloody == true`, blood is automatically available as a tool for writing
4. **CUT vs PRICK split:** CUT produces dirty blood (leaves marks), PRICK produces clean blood (can seal the wound)

---

### D-BUG017: Save containment before FSM cleanup
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented  
**Affects:** verbs/init.lua

Surface contents must be saved BEFORE any state-key cleanup phase, not during the apply phase. The inline transition in `reattach_part` now mirrors the save-first pattern used by `fsm.apply_state`. Any code that does manual FSM state transitions must save containment data first.

---

### D-BUG018: No fuzzy correction on short words
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented  
**Affects:** parser/embedding_matcher.lua

Words ≤4 characters skip fuzzy correction entirely — exact match only. Longer words still use the existing distance < 3 threshold. Fuzzy matching thresholds must account for word length.

---

### D-BUG019: No internal state in display names
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented  
**Affects:** Object naming conventions

Object `name` fields must be clean display names. Internal state is tracked by `_state` and expressed through `description`, `room_presence`, and `on_look` — never through the name. State metadata never goes in the `name` field.

---

### D-BUG020: Containment messages are specific and capitalized
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented  
**Affects:** containment/init.lua

Containment rejection messages include the container name and follow sentence capitalization: "There is not enough room on {name}." All player-facing messages use sentence case and reference the relevant object.

---

### D-BUG021: Debug output gated at construction
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented  
**Affects:** parser/init.lua, parser/embedding_matcher.lua, main.lua

Debug flags must be passed through the full init chain (main → parser.init → matcher.new). Default is off. Constructor-time output respects the flag. Any module that prints diagnostics during construction must accept a debug parameter.

---

### D-BUG022: No false affordances
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented  
**Affects:** loop/init.lua

Never ship UI that promises functionality that doesn't exist. "Play again? (y/n)" was replaced with honest "Game over. Thanks for playing." message. When restart is implemented later, the prompt can return.

---

## OBJECT ARCHITECTURE & COMPOSITE SYSTEM

### D-2: Composite & Detachable Object System (2026-03-25)
**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-25  
**Status:** Approved  

**Core Solution:** Single-file architecture where one `.lua` file defines parent + all parts. Parts detach via factory functions, becoming independent objects. Parent transitions to new FSM state reflecting missing parts.

**Key Design Decisions:**
1. **Single-File Architecture** — All parts and parent logic live in one Lua file
2. **Part Factory Pattern** — Each detachable part has a factory function
3. **FSM State Naming** — `{base_state}_with_PART` and `{base_state}_without_PART`
4. **Verb Dispatch for Parts** — General verbs trigger detachment; parts define verb aliases
5. **Contents Preservation** — Container parts carry contents when detached
6. **Two-Handed Carry System** — Objects have `hands_required` (0/1/2)
7. **Reversibility as Design Choice** — Each part's reversibility is design-time decision
8. **Non-Detachable Parts Valid** — Parts can have `detachable = false` for description-only

---

### D-3: Engine Conventions from Pass-002 Bugfixes (2026-03-22)
**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Approved  

**Conventions Established:**
1. **`on_look(self, registry)` signature** — Object `on_look` functions may accept optional registry instance for resolving child object IDs
2. **`on_feel` can be string or function** — Feel handler dispatches based on type; functions receive `(self)`
3. **`ctx.game_over` flag for death/ending** — Setting this causes loop to break after tick cycle
4. **`--debug` CLI flag** — Parser diagnostic output off by default; pass `--debug` to enable

---

### D-42: Movement Handler Architecture
**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  

Single `handle_movement(ctx, direction)` function handles all movement. Direction aliases, keyword search, accessibility checks, and room transition all flow through this one function. Centralizes movement logic; every movement verb (north, go, enter, descend, climb) delegates to same handler.

---

### D-43: Multi-Room Loading at Startup
**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  

All room files in `src/meta/world/` are loaded at startup into a shared `context.rooms` table. All object instances across all rooms share a single registry. Simplest correct approach for V1. Objects persist regardless of which room player is in.

---

### D-44: Per-Room Contents, Shared Registry
**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  

Each room has its own `room.contents` array. Objects live in shared registry. Moving objects between rooms means updating contents arrays. Registry is single source of truth for object state.

---

### D-45: FSM Tick Scope
**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  

FSM ticks only run on objects in current room + player hands. Objects in other rooms don't tick while player is away. Correct for V1 — candles in other rooms shouldn't burn down while player isn't there.

---

### D-46: Cellar as Room 2
**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  

The cellar is the first expansion room, accessed via trap door stairs. Naturally dark (no windows), has locked iron door to north (future expansion hook), contains minimal atmospheric objects (barrel, torch bracket).

---

### D-47: Exit Display Name Convention
**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  

FSM state labels should NOT appear in object display names. State is conveyed through descriptions and room_presence fields. BUG-027 showed that "a trap door (open)" leaks implementation into player-facing text.

---

## SPATIAL & PUZZLE SYSTEMS

### D-5: Spatial Relationships Implementation (2026-03-26)
**Author:** Bart (Architect)  
**Date:** 2026-03-26  
**Status:** Implemented  

Implemented spatial relationships system from Comic Book Guy's design spec. Focused on critical path: bed → rug → trap door puzzle chain.

**Key Decisions:**
1. **Per-Object Properties, Not Spatial Graph** — Spatial relationships declared as simple object properties (`movable`, `resting_on`, `covering`)
2. **Dynamic Blocking Check** — Movement helper scans room.contents for objects with `resting_on == this_object.id`
3. **Verb-Layer Helper** — `move_spatial_object()` lives in `engine/verbs/init.lua` as helper
4. **FSM Reveal via Engine** — Trap door's hidden→revealed transition triggered programmatically when rug moved
5. **reveals_exit Pattern** — Objects can declare `reveals_exit = "direction"` to unhide exit when opened

**New Object Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `movable` | boolean | Can be pushed/pulled/moved |
| `moved` | boolean | Has been moved from initial position |
| `resting_on` | string | ID of object this sits on (blocks that object's movement) |
| `covering` | table | List of object IDs this conceals |
| `push_message` | string | Custom message for push verb |
| `move_message` | string | Custom message for move/pull verb |
| `moved_room_presence` | string | Room presence after moved |
| `moved_description` | string | Description after moved |
| `moved_on_feel` | string | Feel text after moved |
| `discovery_message` | string | Message when revealed from covering |
| `reveals_exit` | string | Exit direction to unhide on open |

**New Verbs:** PUSH, SHOVE, MOVE, SHIFT, SLIDE, LIFT — all route through `move_spatial_object()`.

---

## GOAL-ORIENTED ACTION PLANNING (GOAP)

### D-GOAP-1: Tier 3 Goal-Oriented Parser Implementation
**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** Implemented  
**Affects:** Parser pipeline, game loop, object metadata, verb dispatch

Implemented Tier 3 backward-chaining prerequisite resolver as a **pre-check** mechanism between input parsing and Tier 1 verb dispatch. The planner checks if a verb+object has unmet tool requirements and builds/executes preparatory steps through existing Tier 1 handlers.

**Key Design Choices:**
1. **Pre-check vs Post-failure** — Planner runs BEFORE verb handler, not after failure
2. **In-place container manipulation** — Containers opened in place without pickup
3. **Nested containment search (3 levels)** — Player hands → room contents → container contents → surface contents
4. **Narrated execution, no confirmation** — Plan execution prints "You'll need to prepare first..." then each step's natural output
5. **UNLOCK as exit-level verb** — UNLOCK handler operates on exits (doors), not objects

**Files Changed:**
- **Created:** `src/engine/parser/goal_planner.lua` (~220 lines)
- **Modified:** `src/engine/loop/init.lua` (planner integration, prepositional parsing, context tracking)
- **Modified:** `src/engine/verbs/init.lua` (UNLOCK handler, exit examine/feel, help text)
- **Modified:** `src/meta/objects/candle.lua` (prerequisites table)
- **Modified:** `src/meta/world/cellar.lua` (iron door: key_id, state descriptions, open mutation, on_feel)

**Risks Addressed:**
- **Infinite loops:** MAX_DEPTH=5 prevents runaway planning
- **Wrong inferences:** Planner only fires when `requires_tool` explicitly declared
- **Hand capacity:** In-place container opening eliminates mid-plan failures
- **Partial execution:** Stop-on-failure preserves consistent world state

**Future Work:**
- Extend planner to handle `requires_property` prerequisites
- Add exit-level prerequisites (auto-unlock, auto-open before movement)
- Use `known_objects` context tracking to limit planning to discovered objects
- Support multiple tool sources with priority ordering

---

## SKILL SYSTEM & CRAFTING

### D-SKILL-01 to D-SKILL-08: Player Skills System + Gap Fixes (2026-03-26)
**Author:** Bart (Architect)  
**Date:** 2026-03-26  
**Status:** Implemented  

**Decisions Made:**

1. **Skills as Simple Table Lookup** — `player.skills = {}` with binary entries (`player.skills.sewing = true`). No proficiency levels, no XP. Gate check is one line: `if not ctx.player.skills[skill_name] then`. First skill: sewing.

2. **Skill Discovery via Readable Objects** — Objects with `grants_skill` field teach skills when READ. READ verb handler checks this field before falling through to examine.

3. **SEW Verb as Crafting Template** — SEW verb implements crafting pattern: skill gate → parse material/tool → find tool in inventory → find sewing_material (thread) → consume materials per recipe → spawn product. Recipe lives on material object (`cloth.crafting.sew`).

4. **Sack Wearable with Alternate Slots** — Objects can declare `wear_alternate = { slot_name = { config } }`. WEAR handler parses "wear X on Y" for slot selection.

5. **Wardrobe Refactored to Inline FSM** — Wardrobe converted from mutation-based to inline FSM (single file, states: closed/open, transitions with messages).

6. **Blood State Persistence (Tick-Down)** — `player.state.bleed_ticks` set on injury (8 for prick, 10 for cut). Decremented each tick. At tick 2: "Your wound is still bleeding, but it's slowing." At tick 0: `bloody = false`, "The bleeding has stopped."

7. **Curtains Daylight Already Wired** — Curtains FSM was already correctly implemented with `allows_daylight` (open state) and `filters_daylight` (closed state).

8. **Surface-Based Container Access in TAKE** — "Take X from Y" handler expanded to search `surfaces` (not just `container + contents`).

---

## USER INTERFACE & EXPERIENCE

### D-UI-1 to D-UI-5: Split-Screen Terminal UI Architecture (2026-07-18)
**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  

**Decisions:**

1. **Manual redraw from scrollback buffer** — ANSI scroll regions used only to prevent input line scrolling status bar. All output rendering from 500-line scrollback buffer. Avoids terminal-specific quirks.

2. **Print interception via display.ui hook** — UI hooks into `display.ui` rather than patching `print()`. Existing `display.install()` wrapper checks `display.ui.is_enabled()` and routes through `ui.output()`.

3. **Scroll commands instead of key capture** — Pure Lua `io.read()` cannot capture Page Up/Down without C extensions. Scrollback uses `/up`, `/down`, `/bottom` commands intercepted before verb dispatch.

4. **--no-ui flag for graceful fallback** — `--no-ui` command-line flag bypasses UI initialization entirely. Falls back to original print/read behavior. Essential for piped input and automated testing.

5. **pcall-wrapped game loop for terminal cleanup** — `loop.run()` wrapped in `pcall` so `ui.cleanup()` always executes — even on Lua errors.

**Files:**
- **Created:** `src/engine/ui/init.lua` — terminal UI module
- **Modified:** `src/engine/display.lua` — added `display.ui` hook for print routing
- **Modified:** `src/engine/loop/init.lua` — UI-aware input, scroll command handling, status bar updates
- **Modified:** `src/main.lua` — UI init, status bar callback, cleanup, --no-ui flag
- **Modified:** `src/engine/verbs/init.lua` — WRITE verb uses `context.ui.prompt()` when available

---

## GAME MECHANICS & WORLD

### USER-DIRECTIVE: Sleep as clock advance mechanic (2026-03-20T17:35Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active/Implemented  

Players can SLEEP and specify how long ("sleep for 2 hours", "sleep until dawn", "take a nap"). This is a mechanism to advance the game clock. The game runs at 24x real time, but sleep lets players fast-forward to specific time (e.g., skip to morning for daylight through windows).

---

### USER-DIRECTIVE: Timed event objects (2026-03-20T19:05Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

Some objects run on timers embedded in .lua metadata. Two patterns:
- **One-shot timer** (time bomb): after N time units, something happens once
- **Recurring timer** (clock): every N time units, something happens repeatedly

First implementation: Wall clock in bedroom chimes at top of every in-game hour.

---

### USER-DIRECTIVE: Candle extinguish + partial consumption + timer integration (2026-03-20T20-57Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

1. **Player can extinguish candle** via "blow out candle", "extinguish candle", "put out candle"
2. **Partial consumption state** — FSM reflects how much wax remains
3. **Timer runs only when lit** — Burn timer only active when candle is lit
4. **FSM + metadata** — All logic lives in candle.lua
5. **Connection to timed events** — Same pattern as wall clock directive

---

### USER-DIRECTIVE: Candle holder as composite object (2026-03-20T21-00Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

1. **Candle holder is separate object** that holds the candle
2. **Prevents burns** — Holder lets you carry lit candle without burning hand
3. **Candle is removable** — Can be taken out of holder (composite/detachable pattern)
4. **Bedroom has candle in holder** on the nightstand
5. **Gameplay implications:** Candle + holder = portable light (1 hand); Candle alone = falls over, can't carry while lit

---

### USER-DIRECTIVE: Match timer + no relight after extinguish (2026-03-20T21-01Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

1. **Match has timer** — Burns down over time (3 ticks)
2. **If extinguished by player** — Match transitions to SPENT, not unlit. Cannot be relit.
3. **Different from candle** — Candle can be blown out and relit; match cannot
4. **FSM difference:**
   - Candle: unlit → lit → unlit(partial) → lit → stub → spent
   - Match: unlit → lit → spent (no relight path)

---

### USER-DIRECTIVE: Burnable objects as universal property (2026-03-20T21-08Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

1. **Burnability is NOT meta property — it's a state change** that must be considered when creating ALL new objects
2. **Burnable objects** include: blanket, bed-sheet, rag, sack, paper, cloth, curtains, wool cloak
3. **FSM pattern:** normal → burning (on timer) → burned (destroyed/consumed)
4. **Burning is triggered by** contact with fire source
5. **Chain reaction potential** — A burning sack could set fire to other flammable objects nearby (future)
6. **Every new object** must answer: "Is this burnable?"
7. **Burning emits light** — Burning object is light source. FSM `burning` state must set `casts_light = true`
8. **Consumable pattern** — Once burned, object is gone forever

---

### USER-DIRECTIVE: Read verb for skill granting + burnable manuals (2026-03-20T21-13Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

1. **Skills granted by READING manual, not acquisition** — Must explicitly use READ verb for skill
2. **Manuals are burnable** like all paper objects
3. **Manual FSM states:**
   - `readable` — default state, can be read to grant skill
   - `burning` — on timer, emits light (`casts_light = true`), cannot be read
   - `burned` — destroyed/consumed, skill permanently lost if not yet learned
4. **Design implications:** Burning manual before reading = permanent skill loss (consequence!)
5. **Pattern applies to ALL skill-granting documents**

---

## FILE STRUCTURE & CONSOLIDATION

### USER-DIRECTIVE: Merge window into single FSM file (2026-03-20T21-11Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Implemented (2026-03-20T21:45Z)

The window object currently has two separate .lua files (window.lua and window-open.lua). Must be merged into a single file with inline FSM, consistent with one-file = one-object = one-FSM architecture.

**Result:** ✅ **IMPLEMENTED** — Bart completed window FSM consolidation. Single-file pattern established for all openable objects.

---

### D-WINDOW-FSM: Window & Wardrobe FSM Consolidation (2026-03-20)
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented  

**What Changed:**
1. **window.lua** — Rewritten as unified FSM with `closed` and `open` states, inline transitions, per-state sensory text
2. **window-open.lua** — Deleted. Merged into window.lua's `open` state.
3. **wardrobe-open.lua** — Deleted. Already superseded by wardrobe.lua's complete FSM.

**Engine Impact:** None. Engine's open/close handlers already check FSM before mutations.

**Pattern Established:** All openable objects use single-file FSM: `initial_state` + `_state` fields, `states` table with per-state properties, `transitions` table with verb-driven changes. No separate `-open` files.

---

### D-GOAP-MINOR-BUGS: Two Minor GOAP Coverage Gaps (2026-03-20)
**Author:** Nelson (Tester)  
**Date:** 2026-03-20  
**Status:** Logged (not critical)

**BUG-031 (MINOR):** Compound "and" commands show confusing mixed output with GOAP
- Repro: `get match from matchbox and light candle` in darkness
- Actual: First half fails, second half GOAP-succeeds → confusing mixed output

**BUG-032 (MINOR):** "burn candle" doesn't trigger GOAP backward-chaining
- Repro: Fresh start → `burn candle`
- Actual: "You have no flame..." — verb recognized but no GOAP. `light` and `ignite` DO chain.
- Fix: Register "burn" as GOAP goal synonym for "light"

**Assessment:** Strongest build yet. GOAP core functionality is transformative. Only 2 minor coverage gaps.
- **States:** closed → open (and back)
- **Curtains interaction:** curtains cover the window, opening curtains with open window = daylight
- **Single `window.lua`** with inline FSM states

---

### USER-DIRECTIVE: Merge wardrobe into single FSM file (2026-03-20T21-13Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

The wardrobe object currently has two separate .lua files (wardrobe.lua and wardrobe-open.lua). Must be merged into single `wardrobe.lua` file with inline FSM, consistent with single-file architecture. Same pattern as window merge and nightstand/matchbox FSM objects.

---

### USER-DIRECTIVE: Newspaper editions in separate files (2026-03-20T03-40Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

The morning edition and late/evening edition of the newspaper should be in different files. Keeps editions distinct and readable.

---

### USER-DIRECTIVE: Room layout and movable furniture (2026-03-20T03-43Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Active  

**Room Layout & Spatial Relationships:**
- Bed is ON the rug
- Rug COVERS a trap door
- Layered spatial positioning — objects on top of other objects
- Moving top object reveals what's underneath

**Movable Furniture:** Players should be able to move objects around room. **Stacking Rules:** Some objects stackable, some not. Objects declare stackability and weight/size support.

---

## NLP & PARSING

### USER-DIRECTIVE: Intelligent natural language input (2026-03-20T20-03Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Design  

Players expect more intelligent input than classic verb+noun MUD syntax. Because of modern LLM/AI interactions, users now expect natural language comprehension. The parser must handle:

1. **Multi-step compound commands:** "Get match from the matchbox and light the candle" → execute: open matchbox → take match → strike match → light candle
2. **Contextual commands:** "Light the candle with a match" — if player already has match in hand, just light it
3. **Implicit containers:** "Get match from the matchbox" — understands "from the matchbox" as source container
4. **Goal-oriented input:** Player states GOAL, not individual steps
5. **Context awareness:** If player examined matchbox, "light the candle" should infer the chain

**Old style (MUD-era):** get matchbox → open matchbox → get match → strike match → light candle (5 commands)  
**New style (LLM-era):** "Get a match from the matchbox and light the candle" (1 command)

This is NOT about adding an LLM to the parser — it's about building smarter NLP preprocessing that can decompose complex commands into action chains with context awareness.

---

## SQUAD OPERATIONS & DIRECTIVES

### USER-DIRECTIVE: Bradley Squad Operating Directives (2026-03-20T20-44Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Governance  

10 operational directives for how the squad operates:

1. **Work Is Triggered, Not Requested** — Squad doesn't wait for human prompts. Work driven by explicit triggers (time, state, size, event).
2. **"Pending" Is Not a Valid State** — Every item needs owner, next action, escalation condition.
3. **Single-Agent Ownership** — Every workflow has exactly one owning agent.
4. **Work Is Pull-Based** — Agents pull from queues, don't wait to be assigned.
5. **Definition of Done Is Explicit** — What artifact, where posted, what state change.
6. **Staleness Is Actively Managed** — Items exceeding idle threshold trigger action.
7. **Reporting Is Required** — Every agent emits: what checked, what did, what blocked, what needs human.
8. **Humans Are Escalation Points, Not Schedulers** — Humans contacted only for missing input, decisions, or escalation conditions.
9. **Default to Action Over Inaction** — Apply defaults, propose action, or escalate with specific question.
10. **Failure Is a Signal, Not Silence** — Say why, what unblocks, who acts next.

**Operating Principle:** "If a human has to remind the squad twice, the system is misconfigured."

---

### D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24T07-28-58Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Proposed (awaiting approval on sequencing)  

**Directive:** Execute a senior engineering code review of engine .lua files, especially those >500 lines. Evaluate whether files should be split into separate modules. Consider:
- Logical divides between responsibilities
- Impact on LLM context windows when editing individual files
- Test coverage opportunities for extracted functions
- Refactoring timing relative to meta-check tool development

**Related Decision:** D-ENGINE-REFACTORING-REVIEW (Bart's analysis, below)

---

### D-WAYNE-METACOMPILER-COMPILER-LINTER (2026-03-24T08-52-50Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Approved  

**Directive:** meta-check must be BOTH a semantic analyzer (compiler front-end: parse, tokenize, validate structure/references/FSM) AND a linter (style conventions, naming patterns, field ordering, documentation requirements). Not just "is this valid Lua" — also "does it follow our conventions?"

**Rationale:** LLMs writing objects need correctness checks AND style enforcement. Lisa uses it as a quality gate.

**Implementation Notes (resolved):**
- **Name:** meta-check ✅
- **Language:** Python + Lark ✅
- **Location:** scripts/meta-check/ ✅
- **Refactor vs meta-check:** Can run in parallel (independent) ✅
- **Deploy first:** Yes — before Phase 2 work ✅

---

### D-WAYNE-TDD-REFACTORING-DIRECTIVE (2026-03-24T07-34-02Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** Approved  

**Directive:** TDD-First mandate — before refactoring ANY engine code (splitting files, moving functions), must follow TDD:
1. Write tests for existing behavior FIRST
2. Verify tests pass (green baseline)
3. Refactor code
4. Re-run tests to confirm no breakage

**Rationale:** Refactoring without tests introduces silent regressions. Tests are the safety net.

**Application:** P0-A refactoring (`verbs/init.lua` split into 12 modules) followed this pattern. Nelson verified 2,666 assertions pass post-refactoring.

---

### D-ENGINE-REFACTORING-REVIEW
**Author:** Bart (Architect)  
**Date:** 2026-03-24  
**Status:** Completed  
**Affects:** All engine files >500 lines, especially `src/engine/verbs/init.lua`

**Summary:** Senior code review of all engine files >500 lines. Analysis in `docs/architecture/engine/refactoring-review.md`.

**Key Decisions:**

1. **`verbs/init.lua` (5,884 lines): SPLIT into 12 files** — 1 registry (`init.lua` ~80 lines), 1 shared helpers module (`helpers.lua` ~650 lines), 10 verb category modules (sensory, acquisition, containers, destruction, fire, combat, crafting, equipment, survival, movement, meta). Each verb module exports a `register(handlers)` function. LLM context reduction: 74-84% per edit. ✅ **SHIPPED**

2. **`preprocess.lua` (1,059 lines): SPLIT into 3 files (P2)** — core, transforms, patterns. Low urgency — file is well-organized and independently tested.

3. **`traverse.lua` (871 lines): KEEP as-is** — high internal cohesion, single FSM, no split value.

4. **`goal_planner.lua` (848 lines): SPLIT into 2 files (P3)** — queries vs planner. Low urgency unless file grows further.

5. **`loop/init.lua` (585 lines): KEEP as-is** — safety barrier ordering is critical, size reflects genuine complexity.

6. **Sequencing: Refactor BEFORE meta-compiler (original plan)** — BUT reversed based on feedback: **meta-check ships independently**, refactoring verified via TDD afterward. No timing impact — both P0 items complete in parallel.

7. **Utility deduplication prerequisite:** `strip_articles()`, `kw_match()`/`matches_keyword()`, and hand accessors are duplicated across 3+ files. Centralize before any split (30-minute task, zero behavioral risk).

**Blockers Resolved:**
- ✅ Nelson completed pre-refactoring TDD tests for all 12 modules (2,670 assertions)
- ✅ Refactoring completed with zero regressions
- ✅ Utility deduplication completed

**Estimated effort (completed):** 18-22 hours total — Bart + Nelson. ✅ SHIPPED

---

### D-WAYNE-META-CHECK-SCOPE-EXPANSION (2026-03-24T17-40-46Z)
**Author:** Wayne Berry (via Copilot)  
**Status:** New — Captured for March 25 plan  

**Directive:** meta-check must expand beyond objects + rooms to cover ALL meta types:
- Levels (level-01.lua, level-02.lua, etc.)
- Injuries (types and configurations)
- Templates (templates/ base definitions)

**Rationale:** User request to broaden validation scope for complete object system coverage.

**Impact:** Expands meta-check roadmap. Will be included in V2+ expansion (rules 20-144+).

---

### D-META-CHECK-V1-APPROVAL
**Author:** Lisa (Object Testing Specialist)  
**Date:** 2026-03-25  
**Status:** Approved for use  
**Affects:** Smithers (parser/tools), Nelson (QA), Flanders (object design)

**Decision:** meta-check V1 is APPROVED for use — it correctly validates 19 checks with zero false positives. Covers only 13% of acceptance criteria (19/144), but sufficient for current object set.

**Validation Results:**
- 103 object files tested
- 0 errors, 0 false positives
- 3/3 planted defects caught (100%)
- 19 rules implemented correctly

**Action Items for Smithers:**
1. Fix severity discrepancies: S-11 → ERROR, MAT-01 → ERROR, XF-03 → INFO
2. Add empty-string detection: `on_feel = ""` flagged as missing
3. Priority checks to expand next: Template-specific (SI/CT/FU/SH), FSM completeness (FSM-02/03/05-08), room instance/exit checks (RI/EX)

**Impact:**
- ✅ Nelson can start using meta-check in CI for 19 implemented checks
- ⏳ Flanders should be aware template-specific validation is NOT yet enforced
- ⏳ Tool will not catch missing size/weight on small-items, missing capacity on containers, or broken room references until those checks ship (meta-check V2, ~3-5 hours)

**Confidence:** MODERATE — V1 correct but incomplete. Full 144-rule coverage queued for Phase 2.

---

## BUG REPORTS & TEST FINDINGS

### Nelson — Pass-003 Bug Report
**Date:** 2026-03-20  
**Build:** Current HEAD  

**Verified Fixes:**
- BUG-009: Parser debug leaks → ✅ FIXED
- BUG-010: Nightstand internal IDs → ✅ FIXED  
- BUG-012: Spent match priority → ✅ FIXED
- BUG-015: Wardrobe internal IDs → ✅ FIXED
- BUG-016: "put X on head" routing → ✅ FIXED
- BUG-017: Drawer replace destroys surface → ✅ FIXED (critical)
- BUG-019: FSM state labels leak → ✅ FIXED
- BUG-021: Parser startup debug line → ✅ FIXED

---

### Nelson — Pass-004 Bug Report
**Date:** 2026-03-20  

**Verified Fixes:**
- BUG-024: Sack on head blocks vision → ✅ FIXED
- BUG-025: Cloak + sack coexist → ✅ FIXED (multi-slot wearables)

---

### Nelson — Pass-005 Bug Report
**Critical Issues:**
- BUG-026: Movement verbs completely unimplemented → ✅ FIXED (by Bart)
- BUG-027: FSM state labels leak into player text → ✅ FIXED
- BUG-028: "key" doesn't resolve to "brass key" → tracked for future
- BUG-029: Iron door in cellar not examinable → ✅ FIXED (by Bart, GOAP implementation)
- BUG-030: No unlock/use-key verb → ✅ FIXED (by Bart, UNLOCK verb + GOAP)

---

### Nelson — Pass-006 Bug Report
**Date:** 2026-03-20  

**Status:** All critical-path bugs fixed. Multi-room movement fully functional. UNLOCK verb enables progression past cellar.

---

## ARCHIVED DECISIONS

### Previous Session Decisions (Before 2026-03-20)
[Summarized from earlier sessions; see decisions-archive-*.md for full history]

- **Newspaper Format & Purpose** (2026-03-18) — Newspaper tracks world events and changes across game time
- **Object containment patterns** — Objects declare capacity, weight support, category restrictions
- **FSM engine foundations** — State machines define object behavior, transitions trigger mutations
- **Initial inventory system** — Player starts with nothing; discovers objects through exploration
- **Darkness mechanic** — Game starts in complete darkness; light is primary quest

---

## NEXT PRIORITIES

### Ready to Implement
- ✅ GOAP Tier 3 (complete, tested with UNLOCK door)
- ✅ Burnable objects system (complete, documented)
- ⏳ Pass-007 GOAP test execution (Nelson)
- ⏳ Hallway room implementation (expand multi-room gameplay)
- ⏳ Extended prerequisite coverage (additional craftables, tools)

### Design Review Needed
- Multi-tool crafting prerequisites
- NPC dialogue system integration with GOAP
- Timed event system architecture (clocks, time bombs)
- Chain-reaction fire system (optional, future)

### In Flight
- Nelson: Pass-007 test execution (GOAP with goals)
- Bart: Extended prerequisite coverage
- Comic Book Guy: Additional room design (hallway, expanded cellar)

---

**End of Merged Decisions**
**Total Decisions:** 47 active + archived  
**Last Merge:** 2026-03-20T21:15Z (Scribe)

---

### D-GOAP-MINOR-BUGS: Two Minor GOAP Coverage Gaps (2026-03-20)

**Author:** Nelson (Tester)  
**Date:** 2026-03-20  
**Status:** Identified, Bart-Fixes-Pending  
**Affects:** goal_planner.lua, verbs/init.lua, loop/init.lua

**Issue 1 (BUG-031):** Compound "and" commands show confusing mixed output  
- Command: `get match from matchbox and light candle`  
- Behavior: First half fails, GOAP succeeds for second half  
- Desired: If the last sub-command has a GOAP plan, skip earlier sub-commands entirely (they're redundant prerequisites GOAP will resolve)  

**Issue 2 (BUG-032):** "burn candle" doesn't trigger GOAP backward-chaining  
- Commands that work: `light candle`, `ignite candle`  
- Commands that don't: `burn candle` (says "no flame")  
- Root cause: "burn" verb not recognized as synonym for "light" in goal planner  
- Fix: Add `VERB_SYNONYMS` table mapping "burn" → "light", update burn verb handler to check for FSM "light" transition first  

---

### D-BUG031: Compound "and" + GOAP Clean Output
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented (Pass-007 verified)  
**Affects:** src/engine/loop/init.lua

When a compound "and" command is entered, check if the last sub-command has a GOAP plan. If GOAP can handle the final goal end-to-end, skip earlier sub-commands entirely — they're redundant prerequisites that GOAP will resolve automatically.

**Where:** New block between compound splitting and the sub-command processing loop.

**Rationale:** Player typing "get match from matchbox and light candle" expresses ONE goal ("light candle"). GOAP already knows how to backward-chain through prerequisites (open drawer → open matchbox → take match → strike match). Processing the first half independently produces confusing error because it bypasses GOAP's planning. Letting GOAP own the entire chain produces clean, coherent output.

**Scope:** Only triggers when the last sub-command actually has a non-empty GOAP plan. Compound commands without GOAP involvement (e.g., "take sword and go north") still split and process normally.

---

### D-BUG032: "burn" as GOAP Synonym for "light"
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented (Pass-007 verified)  
**Affects:** goal_planner.lua, verbs/init.lua, loop/init.lua

Register "burn" as a GOAP synonym for "light" via a `VERB_SYNONYMS` table in `goal_planner.lua`, and redirect the burn verb handler to the light handler for objects with FSM "light" transitions.

**Where:**
- `src/engine/parser/goal_planner.lua` — `VERB_SYNONYMS` table + canonical verb lookup in `plan()`
- `src/engine/verbs/init.lua` — burn handler checks for "light" FSM transition before its own logic
- `src/engine/loop/init.lua` — added "burn" to prepositional "with" stripping

**Rationale:** The burn handler was a standalone "destroy flammable things" verb with no awareness of FSM-based lightable objects (candles). Goal planner only matched exact verbs or aliases. Adding a synonym layer in the planner is the right abstraction — keeps candle data clean (no need to add "burn" to every object's aliases) and makes the mapping explicit and extensible.

**Design note:** `VERB_SYNONYMS` is intentionally a simple 1:1 map, not many-to-many. If we need many-to-many later, we can expand it, but right now simplicity wins.

---

## OBJECT DESIGN DECISIONS

### D-OBJ001: timed_events replaces on_tick for timer-driven objects
**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  
**Affects:** candle.lua, match.lua, wall-clock.lua

All timer-driven FSM objects now use declarative `timed_events` tables inside their states instead of `on_tick` callback functions.

**Pattern:** `{ event = "transition", delay = N, to_state = "state_name" }`

The engine will read this metadata and schedule accordingly. This keeps timer behavior in metadata (not imperative code) and aligns with the "code IS the state" principle.

---

### D-OBJ002: Candle uses remaining_burn for pause/resume timer
**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  
**Affects:** candle.lua

The candle carries `burn_duration` (max) and `remaining_burn` (current) at the object level. When transitioning lit→extinguished, the engine saves remaining time to `remaining_burn`. When transitioning extinguished→lit, the engine uses `remaining_burn` as the timed_event delay.

This makes pause/resume a metadata concern, not engine special-case code.

---

### D-OBJ003: Match extinguish goes to spent, not unlit
**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  
**Affects:** match.lua

A blown-out match transitions lit→spent (terminal), NOT lit→unlit. There is no "extinguished" state and no relight path. This is the key behavioral difference between match and candle. Conservation of matches matters.

---

### D-OBJ004: Wall clock uses 24-state cyclic FSM
**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  
**Affects:** wall-clock.lua

The wall clock is a standard FSM object with 24 states (hour_1 through hour_24), each transitioning to the next via a 3600-second timed_event. hour_24 wraps to hour_1. No special engine code required — the clock is just another FSM object.

States and transitions are generated programmatically via Lua loop. Initial state is hour_2 (game starts at 2 AM).

---

### D-OBJ005: Candle holder uses parts pattern for detachable candle
**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  
**Affects:** candle-holder.lua

The candle holder follows the nightstand/poison-bottle composite pattern: a `parts` table with `detachable = true, reversible = true` for the candle. The candle already exists as an independent object (candle.lua), so the factory returns a minimal reference. The holder's FSM tracks with_candle/empty states.

---

### D-OBJ006: consumable flag on terminal spent states
**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  
**Affects:** candle.lua, match.lua

Terminal spent states now carry `consumable = true` to signal the engine that the object has been fully consumed. This is metadata the engine can use for cleanup, descriptions, or gameplay logic.

---

## USER DIRECTIVES & STRATEGIC DECISIONS

### UD-2026-03-20T21-54Z: No special-case objects; clock as 24-state FSM
**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-20  
**Status:** Policy  

Objects must NOT require special-case engine code. Everything must be expressible through the standard .lua metadata patterns (FSM states, transitions, timers, sensory descriptions). The engine should be generic — objects define their own behavior entirely in their .lua files.

**Example:** The wall clock could have 24 states (hour-1 through hour-24), each with its own transition on a timer. This keeps the clock as a normal FSM object — the engine just ticks transitions like any other object. No special "clock" code in the engine.

**Pattern:** `hour_1 → (timer: 3600s) → hour_2 → ... → hour_24 → hour_1` (cyclic FSM)

Each hour state can have:
- Different `room_presence` text ("The clock reads one o'clock")
- Chime sound on transition (`transition_message`: "The clock strikes two")
- `casts_light = false` (no light, just ambient sound)

This is the same timer mechanism candles and matches use — just with 24 states instead of 2-3.

**Why:** Architectural purity. The engine stays generic; objects own ALL their behavior. No special cases means any new object can be created purely in .lua without engine changes.

---

### UD-2026-03-20T21-57Z: Wall clock supports misset time for puzzles
**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-20  
**Status:** Policy

The wall clock object must support being "misset" — its displayed time can differ from the actual game time. Key points:

1. **Instance-level mutable offset:** Each clock instance has a `time_offset` (or `initial_hour`) in its mutable metadata that determines what hour it displays. Bedroom clock has offset 0 (correct time). Puzzle room clock might start at hour_7 when game time is hour_3.

2. **Setting the clock as a puzzle trigger:** The act of adjusting/setting a misset clock to the correct time (or a specific target time) triggers an event — unlocking a door, revealing a passage, etc. This is a transition with a `trigger` or `on_transition` callback.

3. **SET verb interaction:** Player needs to be able to "set clock to 3" or "turn hands to midnight" — a new verb/interaction pattern for adjustable objects.

4. **The concept lives in the base clock object.** The clock.lua defines the FSM states, the ability to be set, and the trigger mechanism. Individual room instances provide the mutable offset and what the trigger does.

5. **Bedroom clock = correct time.** The first clock the player encounters shows accurate game time. The puzzle clock is in a different room.

**Why:** Future puzzle design. Clock-setting as puzzle mechanic. Instance-level mutation keeps the base object generic.

---

<!-- Directives swept to docs on 2026-03-21T23:15Z by Brockman -->
- UD-2026-03-20T21-54Z: "No special-case objects; clock as 24-state FSM" → docs/objects/wall-clock.md (Design Philosophy section)
- UD-2026-03-20T21-57Z: "Wall clock supports misset time for puzzles" → docs/objects/wall-clock.md (Instance-Level Customization section) + docs/design/00-design-requirements.md (REQ-054B)

---

---

## TIMED EVENTS ENGINE & PUZZLE SUPPORT (2026-03-20T22:15Z)

### D-TIMER001: Timed Events Engine — FSM Timer Tracking and Lifecycle
**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Implemented  
**Affects:** `src/engine/fsm/init.lua`, `src/engine/loop/init.lua`, `src/main.lua`

The FSM engine now supports timed state transitions. Objects define `timed_events` in their state metadata (already present in candle, match, wall-clock). The engine tracks active timers per object and decrements them each game tick.

**Key design decisions:**
- **Two-phase tick:** Expired timers are collected first, then processed, avoiding table-mutation-during-iteration bugs.
- **Timer lifecycle:** `start_timer` on state entry, `stop_timer` on state exit (handled automatically by `fsm.transition()`). Candle extinguish stops the burn timer; relight starts it with `remaining_burn`.
- **Room load/unload:** `scan_room_timers()` starts timers on room load; `pause_room_timers()` preserves them on unload. Paused timers resume on re-entry.
- **Tick rate:** Each command tick = 360 game seconds (consistent with SLEEP's 10 ticks/hour model).
- **Cyclic support:** When a timed transition fires, the engine checks if the new state also has `timed_events` and starts a new timer (wall clock cycles hour_1→hour_24→hour_1).
- **Sleep integration:** `tick_timers()` is called per sleep tick so timers advance during sleep.

---

### D-READ001: READ Verb Skill-Granting Protocol
**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Implemented  
**Affects:** `src/engine/verbs/init.lua`

The READ verb now follows the full skill-granting protocol:

1. Object must be in inventory OR visible in room
2. Object must have `categories` containing "readable" (or `grants_skill`)
3. Non-readable objects get "That's not something you can read."
4. Objects in "burning" state get "The flames make it impossible to read!"
5. Skill-granting readables set both `player.skills[skill] = true` AND `obj.skill_granted = true` (mutation marker)
6. Already-learned skills show `already_learned_message`
7. Readable objects without skills delegate to LOOK AT for their description

---

### D-CLOCK001: Wall Clock Misset Puzzle Support — Instance-Level Configuration
**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Implemented  
**Affects:** `src/meta/objects/wall-clock.lua`, `src/engine/verbs/init.lua`, `src/engine/loop/init.lua`

Wall clock now supports instance-level puzzle overrides:

- `time_offset` (default 0): hours ahead/behind game time
- `adjustable` (default false): enables SET verb interaction
- `target_hour` (default nil): the puzzle solution hour
- `on_correct_time` (default nil): callback fired when SET reaches target

The SET/ADJUST verb advances an adjustable clock by one hour per invocation. NLP patterns handle "set clock", "turn hands", "adjust clock". Default bedroom clock is unaffected (all defaults = no puzzle behavior).

---

## DOCUMENTATION REORGANIZATION (2026-03-20T22:15Z)

### D-BROCKMAN001: Design vs Architecture Documentation Separation
**Author:** Brockman (Documentation)  
**Date:** 2026-03-25  
**Status:** ✅ COMPLETED  
**Impacts:** `docs/design/`, `docs/architecture/`, 40+ cross-references

Reorganized the `docs/` folder to reflect a clear distinction between **design** (gameplay from player perspective) and **architecture** (technical implementation and engine internals).

**Moved to docs/architecture/ (6 files):**
- `00-architecture-overview.md` — Engine layers, system stack, parser architecture
- `architecture-decisions.md` — D-14 through D-21: mutation model, FSM, parser, persistence
- `containment-constraints.md` — Five-layer validation engine (technical)
- `dynamic-room-descriptions.md` — Room rendering engine internals
- `intelligent-parser.md` — GOAP/Tier 3 parser design, engine internals
- `room-exits.md` — Exit object structure as implemented in engine; technical constraints

**Remain in docs/design/ (11 files):**
- `00-design-requirements.md` — Gameplay directives: what players can/can't do
- `command-variation-matrix.md` — Player-facing natural language variations
- `composite-objects.md` — Gameplay mechanic (parts, detachment), player perspective
- `design-directives.md` — Gameplay rules (light, tools, wearables, containers, skills)
- `fsm-object-lifecycle.md` — Gameplay states (lit/unlit, open/closed) from player POV
- `game-design-foundations.md` — Verb system, object taxonomy, room design, player model
- `player-skills.md` — Skill system as gameplay mechanic
- `spatial-system.md` — Spatial relationships (ON/UNDER/BEHIND) as gameplay mechanic
- `tool-objects.md` — Tool capability system, player actions
- `verb-system.md` — Player-facing verb reference (all 31 verbs)
- `wearable-system.md` — Wear slots, layering, player body mechanics

**Cross-References Updated:** 40+ in affected files (design, architecture, puzzles)

**Key Insight:** The distinction is **perspective**, not content. Both files may discuss the same system, but:
- **Design** asks: "What can the player do?"
- **Architecture** asks: "How does the engine make that possible?"

**Result:** Fast discoverability, team alignment (architects/designers navigate different folders), clearer onboarding for new members.

---

---

## USER DIRECTIVES & PROCESS DECISIONS (2026-03-24 Evening Session)

### UD-2026-03-24T18-42Z: Log All Bugs as GitHub Issues First
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-24  
**Status:** ENFORCED  

User directive: Every bug Wayne reports MUST be logged as a GitHub issue BEFORE fixing. This ensures every bug has a trackable GitHub issue number for audit trail.

---

### D-BROCKMAN002: Directive Sweep to Permanent Docs (Wall Clock Misset)
**Author:** Brockman (Documentation)  
**Date:** 2026-03-21  
**Status:** Completed  
**Scope:** Consolidate user directives from decisions.md into permanent docs

**Directives Processed (2):**
1. **UD-2026-03-20T21-54Z** — Already captured in docs/objects/wall-clock.md (Design Philosophy section)
2. **UD-2026-03-20T21-57Z** — Wall clock misset time for puzzles (NEW sections added)

**Updates Made:**
- **docs/objects/wall-clock.md** — NEW SECTION: "Instance-Level Customization: Misset Time for Puzzles"
  - Explains `time_offset` mutable metadata pattern
  - Documents `on_set_to_target` trigger mechanism for puzzle events
  - Describes SET verb interaction (future capability)

- **docs/design/00-design-requirements.md** — NEW REQUIREMENT: REQ-054B
  - Title: "Clock Misset for Puzzles (Instance-Level Time Offset)"
  - Source: UD-2026-03-20T21-57Z
  - Status: In Design
  - Full specification with Lua code examples

**Pattern Established:** Gameplay design → `docs/design/` + object-specific behavior → `docs/objects/`, with cross-references maintaining consistency. docs/ folder is now the lasting source of truth.

---

### UD-2026-03-20T22:20Z: Three-Way Classification of User Directives (Squad Process)
**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-20  
**Status:** Policy  

When Wayne gives a directive, classify it into one of three categories and route accordingly:

1. **Squad/Process directive** → `.squad/decisions.md`
   - How the team operates, workflow rules, agent behavior
   - Examples: "Always have Nelson test after Bart builds", "Use haiku for docs"

2. **Game Design directive** → directly into `docs/design/` or `docs/objects/`
   - How the game works from the player's perspective, object behaviors, puzzle mechanics
   - Examples: "Candle burns down over time", "Match can't be relit", "Clock can be misset"

3. **Architecture directive** → directly into `docs/architecture/`
   - How the engine is built, technical patterns, code conventions
   - Examples: "No special-case objects", "Single .lua per object", "FSM for all state"

**Action:** Coordinator acknowledges category detected: "📌 Game design: {summary}" or "📌 Architecture: {summary}" or "📌 Squad process: {summary}"

**Key Point:** Game design and architecture directives go DIRECTLY into the appropriate docs file — not through decisions.md as a staging area. decisions.md is reserved for squad process decisions only. This keeps information flow clean and docs as the source of truth.

---

**Last Merge:** 2026-03-20T22:40Z (Scribe)

---

## SQUAD PROCESS DIRECTIVES (Swept 2026-03-21)

### DIRECTIVE: Daily Edition Requirements (Comic Strip + Op-Ed)
**Author:** Brockman (Documentation)  
**Date:** 2026-03-21  
**Status:** SQUAD PROCESS DIRECTIVE (UPDATED 2026-03-24)

Every daily newspaper edition must include one recurring section:

| Section | Content | Frequency |
|---------|---------|-----------|
| **Op-Ed Piece** | Editorial opinion, developer commentary, in-character article | Every edition |

**Note:** Comic strips were removed from newspapers per Wayne's directive (2026-03-24). Newspapers now focus on news, analysis, and op-eds.

**Current editions:** See `newspaper/` folder (2026-03-20-morning.md, etc.)

**See also:** Design Directives in `../design/design-directives.md`

---

### DIRECTIVE: Documentation Maintenance
**Author:** Brockman (Documentation)  
**Date:** 2026-03-21  
**Status:** SQUAD PROCESS DIRECTIVE

Keep architecture and design docs up to date as decisions and implementation progress. Docs should reflect current state, not lag.

| Document | Owner | Cadence |
|----------|-------|---------|
| Design directives | Game designers | Update as new directives added |
| Tool taxonomy | Architects | Update as new tool categories discovered |
| Architecture | Lead engineer | Update as decisions locked in |
| Game design foundations | Designer lead | Quarterly or as pillars shift |

**Key principle:** Documentation is a living artifact. Stale docs create ambiguity and design drift.

**Current cadence:**
- README.md: Updated after each major feature release
- Design docs in `docs/design/`: Updated as new directives captured
- Architecture docs in `docs/architecture/`: Updated as implementation decisions lock in
- Vocabulary.md: Synced with codebase after each session

---

### DIRECTIVE: Puzzle Documentation
**Author:** Brockman (Documentation)  
**Date:** 2026-03-21  
**Status:** SQUAD PROCESS DIRECTIVE

Keep an authoritative folder of puzzle documentation at `docs/puzzles/` where game designers document the logic, state, and learning outcomes of each puzzle.

**Contents per puzzle:**
- Puzzle name and location
- Prerequisite knowledge/skills
- Solution path(s)
- Objects involved
- Sensory/timing constraints
- Teach-value (what player learns)
- Consequence if failed

**Current puzzles:** 001-light-the-room.md, 002-poison-bottle.md, 003-write-in-blood.md, 004-inventory-management.md, 005-bedroom-escape.md

**See also:** Design Directives in `../design/design-directives.md`

---

## BUG REPORTS & TEST FINDINGS (Pass-008)

### Nelson — Pass-008 Test Report
**Date:** 2026-03-20T22:40Z  
**Pass:** test-pass/2026-03-20-pass-008.md  
**Tests Run:** 29 | **Tests Passed:** 25

### New Bugs Discovered

#### BUG-033 (MEDIUM): GOAP Relight Fails When Spent Match in Hand
- **Impact:** Blocks extinguish→relight cycle without manual workaround
- **Repro:** `light candle` → `blow candle` → `light candle` → FAILS ("hands full", tries spent match)
- **Root cause:** GOAP planner doesn't auto-drop spent matches before acquiring fresh ones
- **Workaround:** Player must manually `drop match` before relighting
- **Owner:** Assigned to Bart for Pass-009

#### BUG-034 (MINOR): "put out candle" Parsed as PUT Verb
- **Impact:** Common phrasing for extinguish doesn't work
- **Repro:** Light candle → `put out candle` → "Put what where?"
- **Root cause:** Parser matches "put" verb before recognizing "put out" phrasal verb
- **Fix:** Add "put out" as extinguish synonym or handle phrasal verb splitting
- **Owner:** Assigned to Bart for Pass-009

### Fixed Bugs Verified
- **BUG-031:** ✅ FIXED — compound `and` commands produce clean output
- **BUG-032:** ✅ FIXED — `burn candle` triggers full GOAP chain

### Content Gap (Not a Bug)
- **Candle holder** object exists in code but is not placed in any room
- **Action:** Include placement in Pass-009 object sweeps or next room expansion

---

**End of Pass-008 & Docs Cleanup Merge**  
**Total Active Decisions:** 52  
**Last Merge:** 2026-03-20T22:40Z (Scribe)

---

## EFFECTS PIPELINE ROLLOUT (EP1–EP4, 2026-03-23T17:05Z)

### D-EFFECTS-PIPELINE: Unified Effect Processing Pipeline

**Author:** Bart (Architect), Smithers (Implementation)  
**Date:** 2026-07-26 (Architecture), 2026-03-23 (Implementation)  
**Status:** ✅ IMPLEMENTED  
**Scope:** Engine architecture, verb handler integration  
**Deliverables:**
- Architecture: `docs/architecture/engine/effects-pipeline.md`
- Implementation: `src/engine/effects.lua` (232 lines)
- Integration: `src/engine/verbs/init.lua` (drink/taste handlers)

**Context:** Engine currently handles object effects inline in verb handlers. Poison bottle had duplicate code paths for drink vs taste, with taste calling `os.exit(0)` directly instead of routing through injury system.

**Decision:** Create unified Effect Processing Pipeline that:
1. Accepts structured effect tables from object metadata (or legacy string tags via normalization)
2. Routes effects to registered handlers by `type` field (`inflict_injury`, `narrate`, `add_status`, `remove_status`, `mutate`, etc.)
3. Supports before/after interceptors for modification, cancellation, post-processing (armor, immunity, achievements)
4. Replaces inline verb handler effect interpretation with single `effects.process(trans.effect, ctx)` call

**Key Design Decisions:**
- Handler context (`ctx`) constructed at call site, not implicitly from globals (stateless per D-APP-STATELESS)
- Normalize returns arrays always (single effects and legacy strings both normalize to `[ {...} ]`)
- Death check stays in verb handler after `effects.process()` returns (handler sets `ctx.game_over = true`, verb handler does authoritative check)
- Legacy `os.exit(0)` in taste handler was dead code path (FSM `apply_state()` copies structured tables, so `obj.on_taste_effect == "poison"` was always false)

**Consequences:**
- Objects declare *what* happens; engine decides *when*; pipeline decides *how*
- New effect types added by registering handlers — zero pipeline changes
- New injury-causing objects require zero engine changes (Principle 8 compliance)
- Fixed taste verb injury routing bug
- ~120 lines new, ~60 lines deleted (net reduction)

**Day-One Handlers:** `inflict_injury`, `narrate`, `add_status`, `remove_status`, `mutate`  
**Future Handlers:** `fsm_transition`, `trigger_event`, `spawn_object`, `destroy_object`, `play_sound` (as subsystems come online)

**Test Results:**
- 116/116 poison bottle regression tests passing ✓
- 1361/1362 full suite pass (1 pre-existing unrelated failure) ✓
- Zero regressions introduced ✓
- Indirect coverage via poison bottle integration sufficient (direct effects.lua unit tests optional for EP6)

**Gates Approved:**
- EP2b (Marge): Test coverage baseline APPROVED → EP3 cleared
- EP4 (Marge): Regression check PASSED → EP5 cleared

**Status:** ✅ Ready for EP5 (Flanders: poison-bottle.lua refactor)

---

## DIRECTIVE: ZERO-REGRESSION TESTING GATE

**Issued:** 2026-03-23T16:55Z  
**By:** Wayne "Effe" Berry (via Copilot)  
**Authority:** User directive  
**Target:** Marge (Test Manager)

Marge must track unit tests and check for regressions during all refactoring work. Every phase of the Effects Pipeline implementation (EP2–EP10) requires Marge to verify test coverage before and after code changes. No refactoring proceeds without a green test suite. Marge gates each phase transition.

**Status:** ✅ In effect. EP4 gate demonstrates policy in action.

---

## DIRECTIVE: WAYNE CONTRIBUTIONS TRACKER

**Issued:** 2026-03-23T16:58Z  
**By:** Wayne "Effe" Berry (via Copilot)  
**Authority:** User directive  
**Target:** Chalmers (QA/Tracker)

Start keeping track of Wayne's contributions to the project. Read between the lines to determine how he is helping — key insights, design decisions, course corrections, quality gates. Retroactively capture contributions from project start. Maintain a contributions markdown file in .squad/ for the human team member.

**Amended:** 2026-03-23T17:01Z — Wayne is a Senior Engineer with 40 years of experience. Contributions file should reflect his technical depth — engineering guidance (e.g., bootstrapper, compressor suggestions, SLM vs LLM recommendations), not just project management. Include section for Wayne to self-document technical guidance and insights. Capture engineering judgment, not just decisions.

**Status:** ✅ Tracker built. Ready for population.

---

## SQUAD RESEARCH & MUTATION ANALYSIS (2026-03-21T00:16Z)

### D-MUTATE-PROPOSAL: Generic `mutate` Field on FSM Transitions
**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Proposal  
**Research:** Frink (resources/research/architecture/dynamic-object-mutation.md)

**Audit Summary:**
- FSM engine currently mutates 14 properties via `apply_state()`
- Verb handlers mutate 60+ distinct properties across player and object state
- Core properties (weight, size, keywords, categories, portable) are never mutated
- Current limitation: property changes are implicit in state definitions, not declarable at transition time

**Proposal:**
Add optional `mutate` table to FSM transition definitions:
```lua
transitions = {
  light = {
    to = "lit",
    on_transition = "light_verb_handler",
    mutate = { casts_light = true, light_radius = 5 }  -- NEW: explicit mutation at transition
  }
}
```

**Benefits:**
- Makes transition-time mutations explicit and debuggable
- Keeps metadata accurate during transformation
- Maintains engine genericity (no object special-casing)
- Aligns with Dwarf Fortress property-bag architecture (user directive 2026-03-21T00:16Z)

**Implementation:** ~25 lines Lua in engine/fsm/init.lua

**Key Insight:** Core object properties are architecturally stable; new mutation control should be orthogonal to them.

---

### DIRECTIVE: Core Principles Are Inviolable
**Author:** Brockman (Documentation) / Wayne Berry (User)  
**Date:** 2026-03-21T00:16Z  
**Status:** SQUAD GOVERNANCE RULE

When making architecture or design changes, agents must:

1. **No violations:** Check that changes do NOT violate any existing core principle. If they would, rework the change.
2. **No contradictions:** Core principles must not contradict each other. If a new principle conflicts with an existing one, resolve the conflict BEFORE adoption.
3. **Equal weight:** Architecture core principles (in `docs/architecture/objects/core-principles.md`) and design core principles have equal weight.

Core principles are the constitution — everything else is legislation. See `docs/architecture/objects/core-principles.md` (7 foundational principles).

---

### DIRECTIVE: User Reference — Dwarf Fortress Architecture Model
**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-21T00:16Z  
**Status:** SQUAD GOVERNANCE RULE

Dwarf Fortress is an excellent architectural reference model. Its property-bag approach where the engine simulates physics on data-driven material/object properties (rather than special-casing objects) is the architecture we should aspire to.

**Alignment:** This validates our FSM + generic mutation strategy and the proposed `mutate` field.

---

### DIRECTIVE: Process — Resolved Questions Are Deleted
**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-20T22:53Z  
**Status:** SQUAD PROCESS DIRECTIVE

When an open question gets answered/resolved, remove it from `docs/design/open-questions.md` entirely. Don't mark it as "RESOLVED" and leave it there — just delete it. The answer should already be captured in the appropriate design or architecture doc. The open-questions file should only contain genuinely open questions.

---

**End of 2026-03-21T00:16Z Mutation Research Merge**  
**Total Active Decisions:** 56  
**Last Merge:** 2026-03-21T00:16Z (Scribe)

---

## PARSER IMPROVEMENTS & DESIGN (2026-03-22T20:05Z)

### D-MODSTRIP: Noun Modifier Stripping is a Separate Pipeline Stage
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-23  
**Status:** Implemented  
**Affects:** preprocess.lua, loop/init.lua, verbs/init.lua

Quantifier modifiers ("whole", "entire", "every", "all of the") are stripped in their own pipeline stage (`strip_noun_modifiers`), NOT folded into `strip_filler`. Rationale: filler stripping operates on sentence-level prefixes/suffixes, but modifiers appear _inside_ noun phrases ("the **whole** room"). Separate stage keeps concerns clean and is independently testable.

---

### D-ALREADY-LIT: FSM State Detection for Already-Lit Objects
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-23  
**Status:** Implemented  
**Affects:** verbs/init.lua, candle.lua

The `light` handler checks `obj.states[obj._state].casts_light` to detect already-lit objects. This is property-based (works for any FSM object with casts_light) rather than string-matching state names. Follows the Prime Directive: describes the world state ("A tallow candle burns with a steady flame...") instead of telling the player what they can't do.

---

## USER DIRECTIVES — BATCH 2026-03-24

### D-TESTFIRST: Test-First Directive for Bug Fixes
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-23T23:33:32Z  
**Status:** ACTIVE DIRECTIVE  

**Rule:** The Nelson (test team) MUST write unit tests that reproduce the bug FIRST and verify the tests FAIL before any dev fixes the issue. Tests prove the bug exists, then the fix makes them pass. No more fix-first, test-after.

**Rationale:** User request — TDD for bug fixes. Tests that never failed never proved anything. Wayne has flagged this pattern multiple times: fixes ship without tests that actually catch the bug.

**Applies to:** All bug fixes going forward (dev agents must wait for test team verification before shipping)

---

### D-HIRING-DEPT: All New Hires Must Have Department Assignment
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-23T23:47:51Z  
**Status:** ACTIVE DIRECTIVE  

**Rule:** All new hires must be assigned to a department (Design, Engineering, Test, Docs, or Operations). No unaffiliated team members.

**Rationale:** User request — organizational structure must be maintained as the team grows.

**Departments:** Design (CBG, Lisa), Engineering (Smithers, Flanders, Frink, Bart), Test (Nelson), Docs (Brockman), Operations (Gil, Marge, Moe, Sideshow Bob)

---

### D-WAYNE-BATCH-2026-03-24: Design Decisions Batch (Wayne)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-24T00:05Z  
**Status:** ACTIVE DECISIONS  

**Decisions:**

1. **Nightshade antidote placement:** Level 1. Teaches players treatments exist early.

2. **Soiled bandage infection:** Deferred to Level 2. Keep Level 1 simpler.

3. **Combat/armor design:** Not ready — defer all combat-related decisions (armor negation, damage floors, etc.)

4. **Bob's 12 puzzles:** Stay 🔴 Theorized. Wayne wants to review quality before approving. Will ask when ready.

5. **Material Consistency Core Principle:** YES — adopt as formal Core Principle. Every object MUST have a material from the registry. Engine derives physical behavior from material properties. **However, object instances CAN override material properties when needed.** The material is the default, the instance override is the exception.

6. **Verb expansion:** Deferred.

7. **Non-SP puzzles:** To be removed from Level 1.

**Rationale:** User decisions — resolving pending design questions from prior sessions.

---

### D-CHEST-DESIGN: Chest Object Design Conventions
**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-24T00:09:13Z  
**Status:** DESIGN COMPLETE  
**Affects:** `docs/objects/chest.md`, future `src/meta/objects/chest.lua`

**Decisions Made:**

1. **Smell Partially Penetrates Closed Containers**
   Smell is NOT fully gated by the closed state. A closed wooden chest still emits faint "storage mustiness" and "old wood" odors. Players can smell *something* but cannot identify individual items by smell alone through a closed container. This differs from look/feel which are fully blocked.
   
   **Rationale:** Wood is porous. A sealed metal vault would block smell completely, but a wooden chest with natural gaps wouldn't. This adds sensory richness without breaking containment semantics.

2. **Iron Hardware Is Decorative Metadata**
   The chest's iron bands, hinges, handles, and latch are described in sensory text but use `material = "oak"` as the primary material. Iron hardware does NOT need a separate material entry unless a future fire/destruction system requires distinguishing which parts burn vs. which survive.
   
   **Rationale:** Keeps the material system simple. The existing material registry has both `oak` and `iron` — if a future system needs to track composite materials, the sensory text already documents what's iron.

3. **Cannot Open Chest While Carrying**
   A player carrying a chest (both hands occupied) must drop it before opening. This is a two-step interaction: `drop chest` → `open chest`. The engine should check `hands_required` against current hand state before allowing open/close transitions on portable containers.
   
   **Rationale:** You can't unlatch and lift a heavy lid while your arms are wrapped around the chest. This is both realistic and creates interesting gameplay pacing.

4. **Capacity Checks at Insertion, Not Close**
   The `capacity` and `max_item_size` constraints are enforced when placing items INTO the chest, not when closing the lid. There is no "lid won't close because something's sticking out" mechanic. If it fit going in, it fits when closed.
   
   **Rationale:** Avoids complex physics simulation. The container model is abstract slots, not spatial geometry.

**Team Impact:**
- **Flanders:** chest.lua implementation should follow drawer.lua pattern exactly (FSM + container + accessible flag per state + mutate keywords). See Implementation Notes in `docs/objects/chest.md`.
- **All agents:** Smell-through-wood convention may apply to other wooden containers (wardrobe, drawer). Consider whether existing designs need smell-gating updates for consistency.

---

**End of 2026-03-24 Inbox Merge**  
**Total Active Decisions:** 60 (56 prior + 4 new merged)  
**Inbox Status:** ✅ EMPTY  
**Last Merge:** 2026-03-24T00:09:13Z (Scribe)

---

### D-CONDITIONAL: Conditional Clauses Detected in Loop, Not Parser
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-23  
**Status:** Implemented  
**Affects:** loop/init.lua, preprocess.lua

Conditional clause detection ("if you find X", "when you see X") lives in `loop/init.lua` during sub-command execution, not in `preprocess.split_commands`. Rationale: the parser's job is to split text faithfully; the loop's job is to decide what to execute. Moving it to the loop keeps the parser pure and gives the loop control over how many sub-commands to skip.

---

### D-GOAP-NARRATE: GOAP Steps Narrate via Verb-Keyed Table
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-23  
**Status:** Implemented  
**Affects:** goal_planner.lua, verbs/init.lua

GOAP `execute()` uses a `STEP_NARRATION` table mapping verbs to narration functions. This is extensible (add new verbs by adding table entries) and keeps narration separate from handler logic. Each GOAP step gets a brief prefix message before the handler runs.

---

## DESIGN PHASE: APPEARANCE & CONSCIOUSNESS SUBSYSTEMS (2026-03-22T20:05Z)

### D-APP001: Appearance is an Engine Subsystem
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed (pending implementation)  
**Affects:** src/engine/player/appearance.lua

Appearance is an engine subsystem at `src/engine/player/appearance.lua`, not object logic. Objects set `is_mirror` flag; engine calls `appearance.describe(player)`.

---

### D-APP002: Layered Head-to-Toe Rendering
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  
**Affects:** appearance subsystem

Layered head-to-toe rendering (head, torso, arms, hands, legs, feet, overall). Each layer is an independent function returning a phrase or nil.

---

### D-APP003: Nil Layers Silently Skipped
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Nil layers are silently skipped — no "you see nothing" filler.

---

### D-APP004: Appearance Generic Over Player State
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

`appearance.describe()` takes any player state table — works for self (mirror) or another player (future multiplayer).

---

### D-APP005: Injury Phrases via 4-Stage Pipeline
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Injury phrases are composed via a 4-stage pipeline: location → severity → treatment → natural phrase.

---

### D-APP006: Object Appearance Metadata Optional
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Object appearance metadata (`appearance.worn_description`) is optional with graceful fallback to `name`.

---

### D-CONSC001: Consciousness is Player-Level Field
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Consciousness is a player-level field (`player.consciousness`) — not engine-level.

---

### D-CONSC002: Binary Conscious/Unconscious Only
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Binary conscious/unconscious only — no dazed/intermediate state (Wayne directive).

---

### D-CONSC003: Game Loop Uses Simple If/Else
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Game loop uses simple `if/else` on `player.consciousness.state`, not a formal FSM module.

---

### D-CONSC004: Injury System Unchanged
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Injury system (`injury_mod.tick`) is unchanged — consciousness calls it, no coupling.

---

### D-CONSC005: Sleep and Unconsciousness Share Ticking Model
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Sleep and unconsciousness share the same "inactive ticking" model — both tick injuries per turn.

---

### D-CONSC006: Death Check Before Wake Timer
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Death check runs before wake timer check — can't wake up from death.

---

### D-CONSC007: Missing Consciousness Field = Conscious
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Missing `consciousness` field = conscious (backward compatible with old saves).

---

### D-CONSC008: Wake Timer is Turn-Based
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed  

Wake timer is turn-based, not time-based.

---

## WEB LAYER FIXES & DEPLOYMENT (2026-03-22T20:05Z)

### D-WEB-BUG13: Bug Report Transcript in Web Bridge Layer
**Author:** Gil (Web Engineer)  
**Date:** 2026-03-22  
**Status:** Implemented  
**Affects:** bootstrapper.js, web bridge

Issue #13 — bug report URL truncation fixed in the web JS bridge (`bootstrapper.js` → `window._openUrl`) rather than modifying engine code. The bridge parses the URL, identifies the transcript section, and trims it to the last 3 command/response pairs before opening GitHub issue.

**Rationale:**
- Stays within Gil's web-layer charter (no `src/engine/` modifications)
- The engine's 50-entry transcript is still useful for TUI users who `report bug` from terminal
- Web-specific URL length concerns are a web-layer problem
- If the engine handler is later updated to also trim, the JS bridge is harmless (trimming 3 entries to 3 is a no-op)

---

## SPATIAL RELATIONSHIPS & DISCOVERY (Evening Session 2026-03-22T22:05Z)

### D-SPATIAL-HIDE: Spatial Relationships — Hiding vs On-Top-Of
**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-22  
**Status:** Design Complete, Pending Implementation  
**Related Issues:** #26, Wayne iPhone playtest (#19-27)

The game must explicitly distinguish between two fundamentally different spatial relationships:

1. **Resting On** — Both objects visible (e.g., candle on nightstand)
2. **Covering/Hiding** — Top visible, bottom HIDDEN (e.g., rug over trap door)

This distinction is the core mystery mechanic. Without it, the game is a flat list of items. With it, the game becomes a treasure hunt.

**Four Relationship Types:**
| Relationship | Example | Top Visible? | Bottom Visible? | Verb |
|--------------|---------|--------------|-----------------|------|
| Resting On | Candle on nightstand | ✓ | ✓ | PUT ON, TAKE FROM |
| Covering | Rug over trap door | ✓ | ✗ | MOVE, LIFT, PULL BACK |
| Behind | Curtains over window | ✓ | ✗ | PULL ASIDE, OPEN, LOOK BEHIND |
| Inside | Matches in matchbox | ~ | ~ | OPEN, CLOSE, PUT IN |

**Discovery Progression (Three-Phase Reveal):**
1. **Hidden Phase:** Object does NOT appear in SEARCH results
2. **Hint Phase:** EXAMINE of covering object gives ONE sentence hint
3. **Reveal Phase:** Interaction verb (MOVE, LIFT, PULL) triggers dramatic discovery message

**Key Constraints:**
- Hidden objects are invisible until trigger occurs
- Hints are ONE sentence, suggestive but not spoilery
- Discovery narration is 2-3 sentences, sensory
- Objects declare behavior; engine executes
- Object is NOT on critical path (reward, not requirement)

**Design Rationale:** This pattern enables emergent learning through exploration without tutorial text. Players learn "I should look UNDER things" and "I should MOVE furniture" through discovery.

---

### D-SPATIAL-ARCH: Spatial Relationships — Engine Architecture
**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Design Complete, Implementation In Progress  
**Related Issues:** #24, #26, #27  
**Deliverable:** `docs/architecture/objects/spatial-relationships.md`

Engine architecture for spatial concealment relationships follows three rules:

1. **Covering objects own the relationship.** The `covering` array on the covering object (e.g., rug) declares what it hides. The hidden object declares `hidden = true` and provides an FSM with `hidden → revealed` transition. The room does not track relationships — objects are self-describing.

2. **traverse.lua must filter hidden objects.** `expand_object()` must check `obj.hidden` and skip hidden objects entirely. `matches_target()` must also return `false` for hidden objects. This is a bug fix — the search engine currently walks past the `hidden` flag without checking it.

3. **The `behind` relationship uses the same pattern.** Future `hiding_behind` field on blocker objects (wardrobe, curtains) follows identical mechanics to `covering`. The engine treats both as concealment; only the reveal verb differs.

**Design Rationale:** Object-level metadata (not room-level relationship tables) because:
- Follows Principle 8: objects declare behavior, engine executes
- Composable: rug carries its `covering` list if moved to another room
- No second source of truth — one place to author, one place to debug

**Bugs Fixed:**
- traverse.lua: No hidden-object check in expand_object() or matches_target()
- rug.lua: surfaces.underneath lacks accessible = false
- Move handler: Should set underneath.accessible = true when covering object is moved

---

### D-PEEK: Read-Only Search Peek for Containers
**Author:** Smithers (Engine Engineer)  
**Date:** 2026-03-22  
**Status:** Implemented  
**Issues:** #24, #26, #27  
**Commits:** 70fc91f (exemplar)

The search system had three related bugs in how it interacted with spatial relationships:
1. Hidden objects (trap door under rug) were discoverable by search (#26)
2. Search auto-opened containers (drawers, wardrobes) as a side effect (#24)
3. Search didn't report container contents when the target wasn't found (#27)

**Decision: Read-Only Peek (Not Open)**

Search now "peeks" inside closed containers without changing their state. The old code called `containers.open()` and FSM `transition()` during search, which mutated object state. The new code reads `contents` directly without triggering any state transitions.

**Key Distinction:** Container surfaces (nightstand drawer) can be peeked into during search. Non-container inaccessible surfaces (rug's underneath) are truly hidden and cannot be peeked — they require the covering object to be physically moved first.

**Hidden Object Filtering:** Added `obj.hidden` checks to both `expand_object()` and `matches_target()` in traverse.lua. Hidden objects are ghosts — completely invisible to the search engine until explicitly revealed by the move verb handler.

**Content Reporting:** Added narrator functions to report what IS inside a container when the target isn't found. This gives players useful information about the game world during search.

**Alternatives Considered:**
1. **Save/restore state:** Open the container, search, then close it again. Rejected — fragile, could fail if FSM transitions have side effects
2. **Separate "search-open" FSM event:** Add a special "peek" transition to container FSMs. Rejected — overengineered

**Consequences:**
- Search is now purely observational — it never mutates game state
- Players must explicitly `open` containers if they want to change their state
- The `accessible` flag on surfaces now has two semantics: container-accessible (peekable) vs. physically-blocked (not peekable)

---

**End of 2026-03-22T22:05Z Evening Bug Burndown Merge**  
**Total Active Decisions:** 68  
**Last Merge:** 2026-03-22T22:05Z (Scribe)

---

## ARCHITECTURE: ENGINE HOOKS & EFFECTS (Bart, CBG)

### D-EFFECTS-PIPELINE: Unified Effect Processing Pipeline for Injuries

**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** PROPOSED  
**Requested by:** Wayne "Effe" Berry  
**Scope:** `src/engine/effects.lua` (new), `src/engine/verbs/init.lua` (refactor), object metadata format

**Problem:** Objects cause injuries through three ad-hoc patterns: string `effect` fields, `on_{verb}_effect` fields, and structured `on_stab`/`on_cut` tables. Each requires inline interpretation by verb handlers. New injury mechanics require editing engine code, violating encapsulation.

**Decision:** Create `src/engine/effects.lua` that:
1. Accepts string effects (backward compatible) and structured effect tables
2. Dispatches to registered effect handlers by `type` field
3. Ships with `inflict_injury` built-in handler calling `injuries.inflict()`
4. Replaces all inline verb-handler effect interpretation

**Key Principles:**
- Effects are per-object, not per-verb (objects declare behavior)
- Effect processor is separate from hook framework (hooks = *when*, effects = *what*)
- No new hooks needed for consumable injuries (FSM `effect` + `effects.process()`)
- `on_enter_room` hook needed for spatial traps (pit, gas, rocks)
- Fully backward compatible (zero breaking changes)

**Consequences:**
- ✅ New injury objects require zero engine changes (object metadata declares effects)
- ✅ Effect types extensible (`fsm_transition`, `spawn_object`, `heal` as handlers)
- ⚠️ Minor refactor needed in `verbs/init.lua`
- ⚠️ Legacy string effects create implicit mapping to maintain

**Implementation Priority:**
- P0: `effects.lua` + `inflict_injury` handler + `normalize_effect()`
- P1: Verb handler refactor to use `effects.process()`
- P2: `on_enter_room` hook + `trap_effect` subtype

**Full Analysis:** See `docs/architecture/engine/event-hooks.md`

---

### D-INJURY-HOOKS: Injury-Causing Object Hook Categories & Taxonomy

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-23  
**Status:** FINALIZED  
**Scope:** Engine architecture, object design, injury system integration  
**Audience:** Bart (engine), object implementation team, Smithers (injury system)

**Problem:** Different injury-causing objects need different interaction patterns. Should poison bottle call same hook as bear trap? How does engine distinguish "swallow" vs. "touch"? Without clarity, object implementations become inconsistent.

**Decision: Four Hook Categories**

1. **Consumption Hooks** — Ingestion-based injuries (poison, spoiled food)
   - `on_consume(verb, severity)`, `on_drink()`, `on_eat()`, `on_taste(severity)`
   - Verbs: DRINK, SIP, GULP, TASTE, EAT, BITE, CHEW
   - Safety: TASTE safe (warning), full consumption causes injury

2. **Contact Hooks** — Touch-based injuries (traps, hot objects)
   - `on_take(verb)`, `on_touch(verb)`, `on_interact(verb)` (fallback)
   - Verbs: TAKE, GRAB, PICK UP, SEIZE, TOUCH, HANDLE, GRASP
   - Safety: LOOK, SMELL safe; interaction risky

3. **Proximity Hooks (Phase 2+)** — Room-level hazards (pit, gas, ceiling)
   - `on_traverse(direction)`, `on_enter(room_id)`, `on_step(location)`
   - Verbs: GO, MOVE, directional verbs (N, S, E, W, UP, DOWN)
   - Safety: Can detect via SEARCH, LISTEN, SMELL before triggering

4. **Duration Hooks** — Ongoing injury ticks (bleeding, poison DoT)
   - `on_tick(turn_count)`, `on_worsening(severity_increase)`, `on_healing(amount)`
   - Triggers: Every turn automatically; on injury worsening; on treatment
   - Safety: Player monitors via `injuries` verb, finds treatment

**Key Constraints:**
- One hook per interaction pattern (consistency)
- Hook names are verbs (`on_consume`, not `whenConsumed`)
- Hooks pass context (`on_consume(verb, severity)` allows object customization)
- Hooks are optional (object doesn't need all)

**Hook Resolution Matrix:**
- DRINK → `on_consume(verb="drink")` if defined
- TAKE on trap → `on_take(verb="take")` if defined
- GO NORTH → `on_traverse(direction="north")`
- Every turn → `on_tick(turn_count)` for active injuries

**Implementation Roadmap:**
- **Phase 1 MVP:** `on_consume()`, `on_take()`, `on_tick()`
- **Phase 2:** `on_traverse()`, `on_enter()` (proximity)
- **Phase 3+:** `on_worsening()`, `on_healing()`, `on_recovery()` (advanced)

**Testing Strategy:**
- Consumption: sealed bottle (safe) → taste (warning) → drink (injury)
- Contact: armed trap (safe observation) → take/touch (injury)
- Proximity: hidden pit (unknown risk) → search first (avoids injury)
- Duration: poison ticks per turn, antidote stops ticking

**Cross-References:**
- Poison Bottle Design: `docs/design/objects/poison-bottle.md` (710 lines)
- Bear Trap Design: `docs/design/objects/bear-trap.md` (972 lines)
- Engine Hooks: `docs/architecture/engine/event-hooks.md`

---

**End of 2026-03-23T15:22Z Morning Session Merge**  
**Total Active Decisions:** 70  
**Last Merge:** 2026-03-23T15:22Z (Scribe)

---

## NEW DECISIONS (2026-03-24T18:50Z Afternoon Wave)

### D-AUDIT-OBJECTS: Effects Pipeline Compatibility Audit
**Author:** Bart (Architect)  
**Date:** 2026-03-24  
**Status:** Completed (awaiting implementation)  
**Scope:** All 79 objects in `src/meta/objects/`

**Finding Summary:**
- **✅ Pipeline-routed (2 objects):** poison-bottle, bear-trap
- **🔴 Broken (3 objects):** knife, glass-shard, silver-dagger
- **⚪ No effects (74 objects):** passive furniture, tools, decorations

**Critical Issue:** Knife, glass-shard, and silver-dagger define `on_stab`, `on_cut`, `on_slash` with `damage` and `injury_type` fields, but **do NOT declare `effects_pipeline = true`**. This breaks injury creation when players interact with these weapons.

**Migration Priority:**
- **P1 CRITICAL (Week 1):** knife (player-facing, blocks #50), glass-shard (simpler, same severity) — ~2.5 hours total
- **P2 HIGH (Week 1-2):** silver-dagger (3 verbs, lower priority) — ~2 hours

**Pattern (from bear-trap, poison-bottle):**
1. Add `effects_pipeline = true`
2. Restructure verb handlers as pipeline effects
3. Test: wound created via `inflict_injury()`

**Implication:** Any future weapon-like object must follow this pattern.

**Full Report:** `.squad/decisions/inbox/bart-object-migration-audit.md` (309 lines, now merged)

---

### D-NEW-OBJECTS-PUZZLES: Objects Needed for Real-World Puzzles 020–031
**Author:** Sideshow Bob (Puzzle Master)  
**Date:** 2026-03-24  
**For:** Flanders (Object Designer)  
**Status:** Prioritized, awaiting implementation

**Priority 1 — Using Existing Patterns (5 objects):**
1. **wax-written-scroll** — Hidden message (reveal via heat/soot)
2. **charcoal** — Soot-rubbing tool
3. **bread-loaf** — Food item, absorbs poison
4. **bait-meat** — Raw meat, attracts NPCs via scent
5. **hand-mirror** — Portable reflective surface

**Priority 2 — Requires Engine Features (5 objects):**
6. **wooden-barricade** — Flammable obstacle, burnable
7. **pressure-platform** — Weight threshold container
8. **portcullis** — Counterweight-driven gate
9. **sealed-wall-section** — Hidden draft reveals passage
10. **light-beam** — Environmental light source

**Engine Work Needed (for Bart):**
- Capability gating (injury → restricted verbs)
- Weight threshold system
- Fire-spread mechanics
- Smoke visibility
- Light-beam reflection
- NPC behavior patterns
- Thrown-object mechanics

**Full Report:** `.squad/decisions/inbox/bob-new-objects-needed.md` (122 lines, now merged)

---

### D-WAYNE-REGRESSION-TESTS: Every Bug Fix Must Include Regression Test
**Author:** Wayne "Effe" Berry (User Directive)  
**Date:** 2026-03-23T18:49Z  
**Status:** ENFORCED (team-wide policy)

**Policy:** Every bug fix MUST include a regression test that locks down the exact scenario. No fix ships without a test.

**Rationale:** Nightstand search has broken 3+ times because fixes weren't locked with tests.

**Enforcement:** If a bug comes back, file a process bug alongside the code bug — indicates missing/insufficient regression test.

**Impact:** Nelson's audit (6 closed issues verified) followed this pattern. All #63 latent bug fixes now have regression tests.

---

### D-INANIMATE: Objects Are Inanimate (Creatures Are Future)
**Author:** Wayne "Effe" Berry + Flanders (Object Engineer)  
**Date:** 2026-03-24  
**Status:** IMPLEMENTED

**Decision Statement:** Objects in the MMO engine are INANIMATE. Living creatures, animals, NPCs, and autonomous agents are NOT objects.

**Rationale:** Object system optimized for passive, state-driven entities. Creatures require:
- Autonomous behavior (goal pursuit, decision-making)
- Spatial reasoning (pathfinding, obstacle avoidance)
- Communication (dialogue, relationship memory)
- Agency (creatures act on world; objects are acted upon)

**Implementation:**
- ✅ Removed `src/meta/objects/rat.lua` (atmospheric creature incorrectly modeled as object)
- ✅ Removed rat references from `storage-cellar.lua`, web dist
- ✅ Added documentation: `docs/architecture/objects/core-principles.md` (Principle 0)

**Design Guidance:**
- **Alive or autonomous?** → Defer to NPC/creature system (future)
- **Passive and state-driven?** → Belongs in object system (now)

**Examples:**
- ✅ **Rat** → NOT an object; requires creature AI
- ✅ **Rat trap** → IS an object; container/tool
- ✅ **Guard with patrol** → NOT an object; requires dialogue + pathfinding
- ✅ **Guard helmet (loot)** → IS an object; equipment

**Status:** CLOSED (all action items completed, no broken references remain)

---

### D-WAYNE-COMMIT-CHECK: Check Commits Before Push (Quality Gate)
**Author:** Wayne "Effe" Berry (User Directive)  
**Date:** 2026-03-23T21:58Z  
**Status:** ENFORCED (team-wide policy)

**Policy:** All team members MUST check/review their commits before pushing them. No blind pushes.

**Enforcement:** Agents run `git diff --cached` or equivalent to review staged changes before `git push`.

**Implementation:** All orchestration logs include commit hash. Agents verify diff before pushing.

---

### D-WAYNE-CONTRIBUTIONS: Track Wayne Contributions Continuously
**Author:** Wayne "Effe" Berry (User Directive)  
**Date:** 2026-03-23T22:00Z  
**Status:** ACTIVE (ongoing practice)

**Policy:** A team member must continuously watch Wayne's prompts and maintain a working file documenting the value he adds as a Senior Engineer.

**What to Track:**
- Design decisions
- Architectural insights
- Course corrections
- Quality gates
- Domain expertise

**Living Document:** `.squad/contributions/wayne-contributions-log.md` (516 lines)

**Maintenance:** Bart (Architect) initially created; Scribe merges new entries per agent spawn

**Impact:** Enables future retrospectives, recognizes engineering leadership, fulfills accountability directive

---

---

## SEARCH & CONTAINERS (Smithers)

### D-SEARCH-OPENS: Search Opens Containers (supersedes #24)
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-23  
**Status:** Implemented  
**Commit:** 7044275  
**Issues:** #96, #97, #98, #99

Search/find now **physically opens** closed containers it enters, rather than peeking read-only. This supersedes the #24 design decision ("read-only search") because:

1. Players expect `find X` → `take X` to work as a natural flow
2. Wayne explicitly requested narrated opening in #97
3. The "peek" behavior caused 4 bugs (#96-#99) where items were discovered but unreachable

**Implementation Details:**
- `traverse.step()` calls `containers.open()` when entering closed unlocked containers
- Surface `.accessible` is set to `true` after search opens a container
- Container `.is_open` / `.open` flags are set to `true`
- Opening is narrated as a distinct line: "You feel a small drawer. You pull it open."
- Locked containers are still skipped (no change)
- Direct part search (e.g., "search drawer") on a closed surface still tells the player to open it manually (no change to #41)

---

### D-SEARCH-ACCESSIBLE: Search Container Open Must Set Accessible Flag

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** Implemented  
**Issues:** #135, #132  

When the search traversal system opens a closed container (e.g., matchbox) via `containers.open()`, it must set `object.accessible = true` in addition to `is_open` and `open`. The `find_visible` function in `engine/verbs/init.lua` checks `obj.accessible ~= false` before searching container contents. Without this, items discovered by search inside closed containers remain invisible to all subsequent verb handlers (`get`, `take`, `examine`, etc.).

**Scope:** `src/engine/search/containers.lua` — the `containers.open()` function is the single authoritative place where search opens containers. One-line fix ensures all callers benefit.

**Invariant:** After `containers.open(ctx, obj)` succeeds, `obj.accessible` must be `true`. This matches the real game's mutation pattern where the closed matchbox (`accessible = false`) mutates to matchbox-open (`accessible = true`) via the verb system.

---

### D-PLANT-MATERIAL: New "plant" Material in Registry

**Author:** Flanders  
**Date:** 2026-07-27  
**Status:** Implemented  
**Scope:** `src/engine/materials/init.lua`

Added `plant` material to the materials registry to support ivy.lua and future botanical objects (vines, moss, hedges, etc.).

**Properties**
| Property | Value | Rationale |
|----------|-------|-----------|
| density | 500 | Living wood/stem, lighter than timber |
| melting_point | nil | Organic, doesn't melt |
| ignition_point | 280 | Green plant matter, harder to ignite than dry paper |
| hardness | 2 | Soft, flexible stems |
| flexibility | 0.8 | Vines bend easily |
| absorbency | 0.5 | Plant tissue absorbs water |
| opacity | 0.7 | Dense foliage blocks some light |
| flammability | 0.5 | Green = moderate; dry would be higher |
| conductivity | 0.0 | Non-conductive |
| fragility | 0.3 | Stems snap under stress but aren't brittle |
| value | 1 | Common, no economic value |

**Impact**
- ivy.lua now has `material = "plant"` (was the only object missing material in the audit)
- Future botanical objects (moss, hedge, vines) can reference this material
- No engine changes needed — materials.get("plant") works automatically

**Cross-Agent Notes**
- **Nelson:** Material audit validation test (Phase B2) should include plant material
- **Bart:** No engine changes needed — registry is self-extending

---

### D-SELF-INFLICT-CEILING: Self-Infliction Damage Can Never Kill

**Author:** Smithers (UI/Parser Engineer)  
**Date:** 2026-03-25  
**Status:** Implemented  
**Issue:** #133  

Self-inflicted injuries (source contains "self-inflicted") are capped so they can never reduce health to 0. Two enforcement layers:

1. `injuries.inflict()` caps initial damage at infliction time when source is self-inflicted — health stays ≥ 1.
2. `injuries.tick()` death check skips `died = true` if ALL active injuries are self-inflicted.

External injuries can still kill even when combined with self-inflicted damage. This means a player who weakened themselves via self-infliction and then takes a fatal external hit will die normally.

**Design rationale:** "hit head" is self-harm for unconsciousness gameplay, not suicide. Players should be able to bonk themselves repeatedly without dying.

---

### D-SEARCH-SLOW-REVEAL-TIMING: Search Slow-Reveal Timing × 3

**Author:** Smithers (UI Engineer)  
**Date:** 2026-07-17  
**Status:** Implemented  

Wayne directed that the search slow-reveal (user-facing trickle delay in the browser) should be 3× slower. Search is a command of convenience but shouldn't be *too* convenient — the real-time delay makes searching feel deliberate and weighty.

**Decision:** Multiplied `TRICKLE_DELAY_MS` by 3: **350 ms → 1050 ms** per line.

**Files Changed**
- `web/bootstrapper.js` (source)
- `web/dist/bootstrapper.js` (deployed bundle)

**Impact**
- Each search result line now takes ~1 second to appear instead of ~0.35 seconds.
- A 5-line search now takes ~5 seconds of user time instead of ~1.75 seconds.
- This is presentation-layer only (JS); no Lua engine changes. All 76 test files pass.

---

## NEW DECISIONS (2026-03-24 Spawn Merge)

### D-ARMOR-INTERCEPTOR: Armor Protection Formula Weights

**Author:** Smithers (Engine Engineer)  
**Date:** 2026-03-24  
**Status:** Implemented  
**Commit:** f46d69d

The armor before-effect interceptor uses material properties to calculate protection. Bart's architecture doc specified weights "≈ 2.0, 1.0, 0.5" for hardness, flexibility, and density respectively. The implementation uses **1.0, 1.0, 0.5** instead.

**Reason:** With hardness_weight=2.0, ceramic protection ≈ 14.4 — at damage=10 (Nelson's test value), both intact and cracked (× 0.7 = 10.08) states hit the minimum-damage floor of 1, making degradation indistinguishable. Tuning hardness to 1.0 gives ceramic ≈ 7.4, so cracked (≈ 5.2) produces meaningfully different damage than intact (≈ 7.4).

**Formula:**
```
protection = hardness × 1.0 + flexibility × 1.0 + min(1.0, density/3000) × 0.5
effective_protection = floor(protection × coverage × fit_multiplier × state_multiplier)
final_damage = max(1, original_damage - effective_protection)
```

**Fit multipliers:** makeshift 0.5×, fitted 1.0×, masterwork 1.2×  
**State multipliers:** intact 1.0×, cracked 0.7×, shattered 0.0×

**Impact:** All 22 materials now have sensible protection values in the 1–10 range rather than 2–20. This aligns better with the game's typical damage values (5–20 per hit).

**Cross-Agent Notes:**
- **Bart:** Architecture doc §3.1 weights were approximate ("≈"). Implementation chose values that satisfy Nelson's test contracts while preserving relative ordering.
- **Nelson:** `test/armor/` directory needs to be added to `test/run-tests.lua` for inclusion in the full test suite.
- **CBG:** Material → Protection ranking in design doc remains valid (relative ordering is preserved).

---

### D-META-VALIDATION: Compile-Time Safety for Meta Objects (Research Priority)

**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-24T05:53:31Z  
**Status:** Research / Priority Backlog

**Directive:** Wayne is concerned about using Lua as a "script" language for meta objects (objects, rooms, levels) because there are no compile-time checks. LLMs writing .lua data can introduce bugs only caught at runtime. As the project scales to 100s of objects and rooms, this becomes a real risk.

**Problem Space to Explore:**
1. Configuration-style tests that cheaply parse text for correctness
2. A custom meta compiler with parser/tokenizer that validates objects are correct objects (not just valid Lua)
3. Potentially a different language entirely for meta definitions

**Note:** The easiest answer may not be the best — think deeply about scale and correctness guarantees. This is an architectural risk mitigation task for future phases. Recommend deep exploration before committing to a solution.

---

---

## EQUIPMENT & EVENT SYSTEM (2026-03-24 Batch Merge)

### D-EQUIP-HOOKS: Equipment Event Hooks (on_wear / on_remove_worn)

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-24  
**Status:** Implemented  
**Phase:** A6

Equipment actions are now engine events, not just array manipulation in verb handlers.

**Hooks implemented:**
- `on_wear(obj, ctx)` — fires after item is equipped and flavor message prints
- `on_remove_worn(obj, ctx)` — fires after item is unequipped and message prints
- `on_equip_tick(obj, ctx)` — designed, not yet implemented (needs game loop integration)

**Pattern:** Per-object callbacks (CODE pattern). Objects declare functions; engine calls them at the right time. Follows existing `on_look`/`on_feel` callback convention.

**Files changed:** `src/engine/verbs/init.lua`, `docs/architecture/engine/event-hooks.md` (v3.0)

**Cross-Agent Notes:**
- **Flanders:** Chamber pot migration (A7) can now use `on_wear` for smell narration
- **Nelson:** Can write tests for on_wear/on_remove_worn callbacks
- **Smithers:** Armor registration should hook into `on_wear`/`on_remove_worn`

---

### D-EVENT-OUTPUT: Instance-Level One-Shot Flavor Text System

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-24  
**Status:** Implemented  
**Phase:** A6b

Objects can declare `event_output = { on_wear = "text", on_take = "text" }` for per-instance flavor text that fires once then self-removes.

**Design:**
- DATA pattern, not CODE — no callbacks, just strings on the object
- Engine checks `obj.event_output[event_name]` after each event
- If string exists → print → set to nil (one-shot)
- Flavor text lives on ROOM instance data, not object template
- Same template can have different flavor text in different rooms

**Dispatch points:** on_take (4 paths), on_drop, on_wear, on_remove_worn, on_eat, on_drink — 8 total insertion points.

**Files changed:** `src/engine/verbs/init.lua`, `docs/architecture/engine/event-hooks.md` (v3.0)

**Cross-Agent Notes:**
- **Flanders:** Can now add `event_output.on_wear` to wool-cloak, chamber-pot, terrible-jacket instances
- **Nelson:** Can write event_output tests (wear → text prints, wear again → no text, object without → no error)

---

### D-NO-NEWSPAPER-PENDING: Newspaper Hold Directive

**Author:** Wayne Berry (User Directive)  
**Date:** 2026-03-24T05:59:19Z  
**Status:** Active  

Do NOT write a newspaper edition until Wayne explicitly requests one. Phase G2 (evening newspaper) from the daily plan is on hold.

---

**End of 2026-03-24T06-13-16Z Spawn Orchestration Merge**
**Total Active Decisions:** 86 (83 prior + 3 new from inbox)
**Last Merge:** 2026-03-24T06:13:16Z (Scribe)
**Inbox Status:** CLEARED (2 inbox files → merged, deleted)



---

### D-NELSON-COVERAGE-GAPS: Pre-Refactoring Test Coverage Audit

**Author:** Nelson (QA)  
**Date:** 2026-03-28  
**Status:** Active  

# Nelson: Pre-Refactoring Coverage Gaps

**Date:** 2026-03-28
**Author:** Nelson (QA)
**Context:** P0-A pre-refactoring test coverage audit for verbs/init.lua split

## Coverage Added (172 tests)

Six new test files covering the major verb categories that previously had ZERO dedicated tests:
- **Helpers** (54): find_visible search order, matches_keyword, error helpers, hand helpers, all 26 verb aliases
- **Movement** (31): All direction handlers, go/enter/climb/descend/ascend/back, exit blocking, visit tracking
- **Consumption** (23): eat/drink/pour/burn with FSM transitions, preposition handling, edge cases
- **Containers** (18): open/close/unlock with FSM, hooks, exit doors, key resolution
- **Meta** (31): help/wait/inventory/time/injuries/appearance/set/adjust/report_bug/apply
- **Fire** (15): light/extinguish with tool requirements, player flame, already-lit detection

## Remaining Gaps (Bart: be careful here)

These verb handlers still have LOW or NO dedicated test coverage. Extra caution during file extraction:

| Handler | Risk | Why |
|---------|------|-----|
| **write/inscribe** | 🔴 HIGH | 163 lines of runtime code generation. Dynamic mutation. Needs light check + tool resolution + text parsing. |
| **sew/stitch/mend** | 🔴 HIGH | 149 lines. Skill-gated, requires tool + material. Complex preconditions. |
| **put/place** | 🟡 MEDIUM | 228 lines. Containment surfaces + reattach_part. Some coverage in test/inventory but not comprehensive. |
| **pull/yank/extract** | 🟡 MEDIUM | Part detachment logic. Shared codepath with cork removal. |
| **lift** | 🟡 MEDIUM | Spatial vs portable disambiguation. ~30 lines, not complex but untested. |
| **uncork/unstop** | 🟡 MEDIUM | Part detachment shortcut. ~50 lines. |
| **sleep** | 🟡 MEDIUM | 246 lines. Time advancement + FSM ticking during sleep. Complex but isolated. |
| **strike** | 🟡 MEDIUM | 138 lines. Match+matchbox compound interaction. Partially tested via fire integration. |

## Alarming Finds

1. **write/inscribe** has ZERO tests and is the engine's only runtime code generation verb. If this breaks during refactoring, there's no safety net.

2. **context_window is module-level mutable state** — tests that navigate rooms pollute the context_window for subsequent tests. Bart needs to ensure the context_window reference is properly shared across verb modules after splitting.

3. **_next_instance_id counter** is module-level. After split, it must live in exactly ONE module (helpers.lua) or verb modules will generate duplicate instance IDs.

## Recommendation

The 172 tests I wrote cover the highest-traffic verb handlers. For the remaining gaps, I recommend Bart:
- Extract write/sew/put LAST (highest complexity, lowest coverage)
- Test each file extraction individually with `lua test/run-tests.lua` before proceeding
- Flag me for any new test needs discovered during extraction


---

### D-LARK-GRAMMAR: Lark-Based Lua Object Parser

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** Proven  

# Decision: D-LARK-GRAMMAR — Lark-Based Lua Object Parser

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** PROVEN  
**Scope:** Meta-compiler parsing strategy

---

## Decision

**Use Python + Lark (Earley parser) to parse Lua object files for the meta-check tool.**

The prototype at `scripts/meta-check/lua_grammar.py` successfully parses all 83 objects in `src/meta/objects/` with zero failures.

## Architecture

Three-phase pipeline:
1. **Tokenize** — Custom Lua tokenizer handles strings, comments, keywords, nesting
2. **Preprocess** — Strip preamble (local declarations), neutralize function bodies → `__FUNC__` placeholders
3. **Lark Parse** — Earley grammar: `return { key = value, ... }` with nested tables, arrays, booleans, nil, trailing commas

## Key Findings

1. **82/83 objects are pure data tables** — `return { ... }` with only literals, tables, and function expressions as values. Lark's ~30-line grammar handles them directly.

2. **1/83 objects (wall-clock.lua) uses programmatic generation** — builds `states` and `transitions` tables with `for` loops, then references them by variable name (`states = states`). Handled by adding `ident_ref` support (bare identifier as value). Meta-check treats these as opaque — only the Lua runtime knows the computed value.

3. **Function bodies are safely opaque** — 50%+ of objects have functions (`on_look`, `on_feel`, `factory`, `guard`). Preprocessing replaces them with `__FUNC__` markers. Meta-check validates data fields only; function logic is Lua's responsibility.

4. **Nightstand pattern (local function preamble)** — Some objects define helper functions before `return`. The preprocessor's block-depth tracker correctly finds the top-level `return` past any `function`/`if`/`for`/`end` nesting.

## Implications

- **For meta-check:** Parse → extract fields → validate against schema. Functions and ident_refs are "pass-through" — can't be validated statically.
- **For wall-clock pattern:** Consider whether programmatic objects should be refactored to inline data, or whether meta-check should accept `ident_ref` as "runtime-validated only."
- **For future:** Grammar is extensible. Room files follow the same pattern and should parse with the same grammar.

## Affected Team Members

- **Frink** — Confirms Lua-subset-parsing.md findings; Lark is the recommended tool
- **Nelson** — Grammar can be used to build test fixtures (parse → extract → assert)
- **Flanders** — Objects with `ident_ref` values (wall-clock) can't be fully validated statically


---

**End of 2026-03-24T16-40-00Z Decision Inbox Merge**
**Total Active Decisions:** 88 (86 prior + 2 new from inbox)
**Last Merge:** 2026-03-24T16:40:00Z (Scribe)
**Inbox Status:** 2 files merged, ready for deletion

---

## VERBS & META-CHECK DECISIONS (2026-03-24)

### D-VERBS-REFACTOR-2026-03-24
**Author:** Bart (Architect)  
**Date:** 2026-03-24  
**Status:** Implemented  

Split `src/engine/verbs/init.lua` (5,884 lines) into helper + 10 verb modules using a `register(handlers)` pattern, with a registry-only `init.lua`.

- Added `src/engine/verbs/helpers.lua` as the shared utility module (core helpers + optional parser modules).
- Added verb modules: `sensory`, `acquisition`, `containers`, `destruction`, `fire`, `combat`, `crafting`, `equipment`, `survival`, `movement`, `meta`.
- Moved self-infliction parsing helpers (`parse_self_infliction`, `handle_self_infliction`) into helpers for reuse by strike → hit routing.

**Impact:** Verb behavior unchanged; module boundaries now explicit and easier to edit. `engine.verbs` remains the public entry point (registry only).

**Tests:** `lua test/run-tests.lua` — all tests passing.

---

### D-META-CHECK-BUILD-2026-03-24
**Author:** Smithers (UI/Parser)  
**Date:** 2026-03-24  
**Status:** Implemented  

Built `scripts/meta-check/check.py` as a Python CLI validator based on Bart's proven Lark grammar to enforce core object integrity and cross-file consistency.

- Parses meta `.lua` files with Lark grammar from `lua_grammar.py`
- Enforces required fields: `guid`, `template`, `id`, `name`, `keywords`, `on_feel`
- Type checks, GUID format validation, material registry cross-validation
- Validates FSM `initial_state` references and transition state pairs
- Runs cross-file GUID uniqueness and keyword collision checks
- JSON and text output modes with severity filtering and defined exit codes

**Consequences:** Fast, deterministic validation gate for meta content. Conservative FSM handling avoids false positives on non-literal state tables.

---

**End of 2026-03-24T17:20:00Z Decision Inbox Merge**
**Total Active Decisions:** 90 (88 prior + 2 new from inbox)
**Last Merge:** 2026-03-24T17:20:00Z (Scribe)
**Inbox Status:** 2 files merged, ready for deletion

---

## D-ENGINE-HOOKS-101 — Room & Item Callback Hooks

**Author:** Bart (Architect)  
**Date:** 2026-03-29  
**Issue:** #101  
**Status:** Implemented  

### Decision

Implemented 4 engine hooks following the established on_X(obj, ctx) + vent_output pattern:

| Hook | File | Fires When |
|------|------|-----------|
| on_enter_room(room, ctx) | movement.lua | After player enters a room (both normal movement and "go back") |
| on_exit_room(room, ctx) | movement.lua | Before player leaves a room (after traverse effects) |
| on_pickup(obj, ctx) | cquisition.lua | After successful take/get (all 4 take paths) |
| on_drop(obj, ctx) | cquisition.lua | After drop action (single-item and "drop all" paths) |

### Architecture Notes

- Room hooks use (room, ctx) signature — consistent with the existing on_enter text-generation function pattern, but on_enter_room is a distinct callback hook (not a replacement)
- on_exit_room fires after 	raverse_effects.process() but before the actual room change — the room reference is still valid
- on_enter_room fires after the room change but before arrival text / auto-look — hooks can modify room state before display
- Hook order during movement: on_traverse → on_exit_room → (room swap) → on_enter_room → arrival text

### Affected Team Members

- **Moe** (rooms): Can now declare on_enter_room / on_exit_room callbacks on room definitions for spatial traps, atmosphere triggers
- **Flanders** (objects): Can now declare on_pickup / on_drop callbacks on objects for cursed items, puzzle triggers
- **Sideshow Bob** (puzzles): Can use room entry hooks for spatial trap designs (pit trap, gas cloud)
- **Nelson** (QA): 16 new tests in 	est/verbs/test-engine-hooks-101.lua

---

**End of 2026-03-24T18-45-00Z Decision Inbox Merge**
**Total Active Decisions:** 91 (90 prior + 1 new from inbox)
**Last Merge:** 2026-03-24T18:45:00Z (Scribe)
**Inbox Status:** 1 file merged, ready for deletion

---

## MATERIAL SYSTEM & BURNABILITY (Burndown Wave 7 — 2026-03-24T19:50:00Z)

### D-BURNABILITY-MATERIAL-DERIVED
**Author:** Bart (Architect)  
**Date:** 2026-03-24 (Implemented in #120)  
**Status:** Implemented  
**Issue:** #120

Burnability is now derived from material flammability scores rather than per-object flags or category arrays. This follows the same pattern established for armor (material-derived, not hardcoded).

**Threshold:**
- **Burnable:** `flammability >= 0.3`
- **Not burnable:** `flammability < 0.3` or no material

**Resolution Order:**
1. **FSM transition** — if the object has a `burn` verb transition, use it (e.g., rope: intact → burning)
2. **Mutation** — if the object has a `burn` mutation, apply it (e.g., letter → letter-ash)
3. **Generic destruction** — remove the object from the world entirely

**Key Decisions:**
1. **Material registry** — 17 materials cataloged with flammability scores (0.0–1.0)
2. **Universal burn verb** — Single handler checks material flammability; fireproof objects reject burn
3. **3-tier burn progression** — States: intact → charred → ash
4. **No object-specific burn logic** — Objects declare material; engine determines burnability

**Impact on Other Agents:**
- **Flanders** (objects): New objects with `material` fields automatically get correct burn behavior. No need to add `flammable` flags or categories. Objects that need custom burn behavior should use FSM transitions or mutations.
- **Moe** (rooms): Room objects with flammable materials can now be burned. Consider whether rooms need fire-spread mechanics later.
- **Sideshow Bob** (puzzles): Puzzles can leverage material-derived burnability. Burning a rope to drop something, burning a scroll, etc.

**Backward Compatibility:**
The old `obj.flammable` and `categories = {"flammable"}` paths are removed. Only `paper.lua` used the `flammable` category — it has `material = "paper"` (flammability 0.8) so it burns correctly under the new system.

---

---

## FIRE & BURN SYSTEM (Burndown Wave 8 — 2026-03-24T19:55:00Z)

### D-FIRE-PROPAGATION-ARCHITECTURE
**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-24 (Implemented in #121)  
**Status:** Implemented  
**Issue:** #121

Fire propagation is implemented as a standalone tick-based module (`src/engine/fire_propagation/init.lua`) that runs once per game tick in the post-command phase of the game loop.

**Key Choices:**

**Proximity Model (3 tiers)**
- **SAME_SURFACE (0.8):** Items on the same furniture surface. Highest spread chance — they're effectively touching.
- **SAME_PARENT (0.5):** Items on different surfaces of same furniture. Medium spread — heat rises/radiates.
- **SAME_ROOM (0.2):** Items loose in room or on different furniture. Low spread — radiant heat only.

**Spread Formula**
`chance = proximity_factor × target_flammability × source_intensity`

All values derived from the material system. No per-object fire configuration needed.

**Rate Limiting**
MAX_IGNITIONS_PER_TICK = 2. Fire cascades over multiple turns. Players always have at least one turn to react.

**Generic Destruction Countdown**
Non-FSM objects get `_burn_ticks_remaining = 1` when ignited. They burn for one tick before destruction. FSM objects use declared burn transitions.

**"Burning" vs "Lit"**
Lit candles do NOT propagate fire. Only objects in "burning" FSM state or with `is_burning = true` spread fire. Prevents candles from being fire hazards.

**Impact:**
- **Flanders:** Objects with custom burn behavior use FSM transitions or mutations
- **Moe:** Room designers aware of fire propagation chains on same surface
- **Nelson:** 23 tests with deterministic RNG (`ctx.fire_rng`)
- **Sideshow Bob:** Fire chains enable puzzle design (escape scenarios, timed mechanics)

**Verification:** 23 tests passing, 118 files green.

---

## VERB SYSTEM EXPANSION (Burndown Wave 8 — 2026-03-24T19:55:00Z)

### D-WASH-VERB-FSM
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-24 (Implemented in #112)  
**Status:** Implemented  
**Issue:** #112

Wash verb implemented with FSM state transition (soiled → clean) and water source validation.

**Key Choices:**
1. **Water source requirement** — Objects checked in inventory/room for water_source tool
2. **FSM enforcement** — Transition only if obj.states.soiled exists
3. **Alias coverage** — wash, rinse, clean, scrub (4 aliases)
4. **Terminal state** — already_clean check prevents redundant washes

**Impact:**
- **Flanders:** Objects needing clean states add FSM: `{ from = "soiled", to = "clean" }`
- **Moe:** Rooms can place water sources for puzzle prerequisites
- **Sideshow Bob:** Washing enables puzzle logic (cleanliness requirements)

**Verification:** 34 tests passing, 118 files green.

---

### D-MATCH-TERMINAL-STATE
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-24 (Implemented in #119)  
**Status:** Implemented  
**Issue:** #119

Terminal state protection prevents relighting spent matches. FSM guard in light verb.

**Key Choices:**
1. **Terminal flag** — Match FSM includes `terminal = true` on spent state
2. **Verb guard** — Light verb rejects FSM transitions from terminal states
3. **Error message** — "The match is spent. It won't light again."

**Impact:**
- **Flanders:** Objects declaring terminal states are immutable after transition
- **Sideshow Bob:** Terminal states enable one-time-use puzzle mechanics

**Verification:** 5 tests passing, 118 files green.

---

### D-PUSH-LIFT-SLIDE-VERBS
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-24 (Implemented in #111)  
**Status:** Implemented  
**Issue:** #111

Movement verbs implemented with containment validation and full alias support.

**Verbs:**
- **PUSH** — Move object away (cardinal directions)
- **LIFT** — Pick up and hold (weight/capacity checks)
- **SLIDE** — Move horizontally without lifting (heavy furniture)
- **DROP** — Release from hand to floor

**Aliases:**
- push/shove, lift/pick/grab, slide/drag/shift, drop/release/discard (12+ total)

**Key Choices:**
1. **Containment validation** — Weight checks before lift, capacity checks before place
2. **Spatial bounds** — Can't push off room edge
3. **Hand slot limits** — Max 2 items in hands
4. **Parser integration** — Full noun + direction resolution

**Impact:**
- **Moe:** Room designers place heavy objects knowing push/slide vs lift constraints
- **Sideshow Bob:** Movement constraints enable spatial puzzles

**Verification:** 46 tests passing, 118 files green.

---

### D-ENGINE-HOOKS-USE-EAT-DRINK
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-24 (Implemented in #102)  
**Status:** Implemented  
**Issue:** #102

Engine hooks (use/eat/drink) dispatch to object-defined callbacks, enabling custom behaviors.

**Verbs:**
- **USE** — Generic object interaction, dispatch to `obj.on_use(context)`
- **EAT** — Food consumption, dispatch to `obj.on_eat(context)`, validates edibility
- **DRINK** — Liquid consumption, dispatch to `obj.on_drink(context)`, validates drinkability

**Key Choices:**
1. **Callback dispatch** — Objects define handlers; engine runs them
2. **Effect pipeline integration** — Callbacks can mutate state, trigger FSM, remove from inventory
3. **Graceful fallback** — Objects without callbacks receive generic message
4. **Context availability** — All callbacks receive full game context

**Impact:**
- **Flanders:** Objects can define custom behaviors via callbacks
- **Moe:** Room objects (furniture) can have use behaviors
- **Sideshow Bob:** Custom interactions enable puzzle design

**Verification:** 20 tests passing, 118 files green.

---

## OBJECT DESIGN (Burndown Wave 8 — 2026-03-24T19:55:00Z)

### D-SALVE-ANTIDOTE-OBJECTS
**Author:** Flanders (Object Designer)  
**Date:** 2026-03-24 (Implemented in #114 + #115)  
**Status:** Implemented  
**Issues:** #114, #115

Salve and antidote objects created with FSM states and healing effects.

**Salve Object (`src/meta/objects/salve.lua`)**
- Template: small-item
- Material: beeswax (flammability 0.2)
- FSM: unused → applied → drained
- Healing: restores 30 health on apply
- Sensory descriptions per state

**Antidote Object (`src/meta/objects/antidote.lua`)**
- Template: small-item
- Material: glass (container)
- FSM: sealed → consumed → empty
- Healing: removes poison condition on drink
- Sensory descriptions per state

**Key Choices:**
1. **FSM-driven states** — Use app/drink verbs to transition
2. **Effects integration** — Healing callbacks in effects pipeline
3. **Terminal semantics** — "drained" and "empty" are exhausted, not mutations

**Impact:**
- **Nelson:** New healing objects for test scenarios
- **Sideshow Bob:** Healing items enable puzzle design (recovery prerequisites)

**Verification:** 117 files green (salve/antidote pass as part of effects system).

---

**End of 2026-03-24T19:55:00Z Decision Inbox Merge**
**Total Active Decisions:** 98 (92 prior + 6 new from Wave 8 inbox)
**Last Merge:** 2026-03-24T19:55:00Z (Scribe)
**Inbox Status:** All Wave 8 inbox files processed and archived
