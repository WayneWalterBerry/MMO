# Squad Decisions — MERGED

**Last Updated:** 2026-03-20T21:15Z  
**Merger:** Scribe  
**Source:** 23 inbox files + existing decisions.md (deduplicated, reorganized by category)

---

## ARCHITECTURE & ENGINE DECISIONS

### D-14: True Code Mutation (Objects Rewritten, Not Flagged)
**Author:** Bart (Architect)  
**Date:** 2026-03-18  
**Status:** Foundational  
Objects are mutated by rewriting their Lua code (via `loadstring` and registry update), not by state flags. This enables arbitrary object transformation while keeping metadata accurate.

---

### D-16: Lua for Both Engine and Meta-Code
**Author:** Bart (Architect)  
**Date:** 2026-03-18  
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
