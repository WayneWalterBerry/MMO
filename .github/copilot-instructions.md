# Copilot Instructions — MMO Text Adventure Engine

## Project Overview

MMO is a **Lua text adventure game** inspired by Zork, built for mobile. It features a mutation-based object system, containment hierarchies, multi-sensory interactions, and a 5-tier verb-dispatch parser. The engine is playable — Level 1 has 74+ objects, 7 rooms, and 31+ verbs.

- **Language:** Lua (pure — zero external runtime dependencies)
- **Entry point:** `lua src/main.lua`
- **Owner:** Wayne "Effe" Berry
- **Stage:** Prototype (V1 playable, heading toward beta playtesting)

## Squad — AI Team Framework

This project uses **Squad**, an AI team framework with 14 specialist agents coordinated by a Coordinator. Before doing any work:

1. Read `.squad/team.md` for the roster and department structure.
2. Read `.squad/routing.md` to understand who owns what.
3. Read `.squad/decisions.md` for active team decisions that affect your work.
4. If an issue has a `squad:{member}` label, read that agent's charter at `.squad/agents/{member}/charter.md` and work in their voice.

### Code Ownership Boundaries

| Owner | Domain | Files |
|-------|--------|-------|
| **Bart** | Engine architecture, module design | `src/engine/**` |
| **Flanders** | Object definitions, injury types | `src/meta/objects/**`, `src/meta/injuries/**` |
| **Moe** | Room definitions, world layout | `src/meta/world/**` |
| **Smithers** | Parser pipeline, UI/text presentation | `src/engine/parser/**`, `src/engine/ui/**`, `src/engine/verbs/init.lua` (text output) |
| **Gil** | Web build pipeline, browser wrapper | `web/**` |
| **Sideshow Bob** | Puzzle design | `docs/design/puzzles/**`, `docs/levels/*/puzzles/**` |
| **Comic Book Guy** | Game design, mechanics | `docs/design/**` |
| **Nelson** | QA, test automation | `test/**` |
| **Brockman** | Documentation | `docs/**` |

### Decision Protocol

After making a decision that affects other team members, write it to:
```
.squad/decisions/inbox/{your-name}-{brief-slug}.md
```
The Scribe merges decisions into `.squad/decisions.md`.

## Architecture — Core Principles

Read `docs/architecture/objects/core-principles.md` before modifying objects. The 9 inviolable principles:

| # | Principle | Summary |
|---|-----------|---------|
| 0 | Objects are inanimate | No NPC system (yet) |
| 0.5 | Deep nesting syntax | Room `.lua` files encode topology via `on_top`, `contents`, `nested`, `underneath` |
| 1 | Code-derived mutable objects | The `.lua` file IS the object definition |
| 2 | Base → instance | Templates define shape; rooms instantiate |
| 3 | FSM + state tracking | Objects declare `states` and `transitions` inline |
| 4 | Composite encapsulation | Objects can contain inner objects |
| 5 | Multiple instances per base | Each instance gets a unique GUID |
| 6 | Sensory space | State determines what the player perceives |
| 7 | Spatial relationships | Objects exist in physical relation to other objects |
| 8 | Engine executes metadata | Objects declare behavior; engine runs it — no object-specific engine code |
| 9 | Material consistency | Objects obey real-world material properties |

### The Prime Directive (D-14)

**Code Mutation IS State Change.** When a player breaks a mirror, the engine rewrites `mirror.lua` → `mirror-broken.lua` at runtime. The code literally transforms. There are no separate state flags — the code IS the state.

## Source Structure

```
src/
├── main.lua                          # Entry point, CLI flags: --debug, --trace, --headless, --no-ui
├── engine/
│   ├── loader/init.lua               # Sandboxed Lua loader, template resolution
│   ├── registry/init.lua             # Universe object store (GUID-indexed)
│   ├── mutation/init.lua             # Hot-swap object rewrite engine
│   ├── containment/init.lua          # Placement validation (size, weight, capacity)
│   ├── fsm/init.lua                  # Finite state machine engine
│   ├── loop/init.lua                 # Main game loop
│   ├── verbs/init.lua                # 31+ verb handlers
│   ├── parser/
│   │   ├── init.lua                  # Tier 2 embedding matcher wrapper
│   │   ├── preprocess.lua            # Input normalization pipeline
│   │   ├── fuzzy.lua                 # Tier 5 fuzzy noun resolution
│   │   ├── context.lua               # Tier 4 context window
│   │   ├── goal_planner.lua          # Tier 3 GOAP planner
│   │   └── embedding_matcher.lua     # Semantic matching
│   ├── ui/
│   │   ├── init.lua                  # Terminal UI (optional)
│   │   ├── status.lua                # Status bar
│   │   └── presentation.lua          # Text formatting, time constants
│   ├── effects.lua                   # Unified effect processing pipeline
│   ├── injuries.lua                  # Injury subsystem
│   ├── traverse_effects.lua          # Exit passage effects
│   ├── materials/init.lua            # Material registry (17+ materials)
│   └── display.lua                   # Word-wrapping output
├── meta/
│   ├── templates/                    # 5 base templates (room, furniture, container, small-item, sheet)
│   ├── objects/                      # 74+ object .lua definitions
│   ├── world/                        # 7 room .lua definitions
│   ├── levels/                       # Level definitions (level-01.lua)
│   └── injuries/                     # 7 injury type definitions
└── assets/
    └── parser/embedding-index.json   # Pre-computed embeddings for Tier 2
```

## Lua Coding Conventions

### Naming

- **Files/folders:** lowercase with dashes (`wool-cloak.lua`, `goal_planner.lua`)
- **Functions:** `snake_case` (`deep_merge()`, `normalize_guid()`)
- **Local variables:** `snake_case`
- **Module pattern:** single table export (`local M = {} ... return M`)

### Module Pattern

```lua
local M = {}

-- Dependencies at top
local registry = require("src.engine.registry")

function M.do_thing(context, noun)
    -- implementation
end

return M
```

### Comments

- Use `--` for inline comments; add comments only when clarification is needed
- Don't over-comment obvious code

## Object Definition Pattern

Every object `.lua` file returns a table:

```lua
return {
    guid = "{windows-guid}",
    template = "small-item",              -- inherits from template
    id = "candle",
    name = "a tallow candle",
    keywords = {"candle", "tallow candle"},
    description = "A stubby tallow candle...",

    -- EVERY object MUST have on_feel (primary dark sense)
    on_feel = "Waxy cylinder, cool to the touch.",
    on_smell = "Faint tallow smell.",
    on_listen = "Silent.",
    on_taste = "Bitter wax.",

    -- Optional: FSM states
    initial_state = "unlit",
    _state = "unlit",
    states = {
        unlit = { description = "...", casts_light = false },
        lit   = { description = "...", casts_light = true },
    },
    transitions = {
        { from = "unlit", to = "lit", verb = "light", requires_tool = "fire_source" }
    },

    -- Optional: mutations
    mutations = {
        break = { becomes = "candle-broken", message = "The candle snaps in two." }
    }
}
```

**Required sensory property:** Every object MUST have `on_feel` — it's the primary sense in darkness.

## Room Definition Pattern

Rooms use deep nesting to encode spatial topology:

```lua
return {
    guid = "{windows-guid}",
    template = "room",
    id = "start-room",
    name = "Bedroom",
    description = "Permanent features only: walls, floor, atmosphere.",

    instances = {
        { id = "nightstand", type_id = "{guid}",
            on_top = { { id = "candle", type_id = "{guid}" } },
            contents = { { id = "matches", type_id = "{guid}" } },
            nested = { { id = "drawer", type_id = "{guid}" } },
            underneath = { { id = "dust-bunny", type_id = "{guid}" } }
        }
    },

    exits = {
        north = {
            target = "hallway",
            type = "door",
            name = "a wooden door",
            open = false, locked = true
        }
    }
}
```

**Key rules:**
- `description` contains ONLY permanent features (walls, floor, light, atmosphere)
- Movable objects use `room_presence` fields composed at runtime
- Four nesting relationships: `on_top`, `contents`, `nested`, `underneath`

## Verb Handler Pattern

All verbs live in `src/engine/verbs/init.lua`:

```lua
verbs.look = function(context, noun)
    local obj = context.registry:find_by_keyword(noun)
    if not obj then
        err_not_found(context)
        return
    end
    print(obj.description or obj.name)
end
```

- Signature: `function(context, noun)`
- Resolve objects via `context.registry`
- Check tool capabilities before mutations
- Principle 8: no object-specific logic in handlers — objects declare behavior

## Testing

### Running Tests

```bash
lua test/run-tests.lua                    # Run all tests
lua test/parser/test-preprocess.lua       # Run a specific test file
```

### Pre-Deploy Gate

```powershell
.\test\run-before-deploy.ps1             # Tests + web build
```

### Test Framework

Pure Lua — no external dependencies. Located at `test/parser/test-helpers.lua`:

```lua
local t = require("test.parser.test-helpers")
t.test("candle lights with match", function()
    t.assert_eq(result, "lit")
end)
t.summary()
```

### Test Structure

| Directory | Coverage |
|-----------|----------|
| `test/parser/` | Parser pipeline (preprocess, context, GOAP, fuzzy, embedding) |
| `test/parser/pipeline/` | Per-stage preprocessing (7 files, 224+ tests) |
| `test/verbs/` | Verb handlers (wine, wear, combat, poison, etc.) |
| `test/search/` | Object discovery, traversal, spatial, containers |
| `test/inventory/` | Inventory management, put/take, search order |
| `test/injuries/` | Injury system, weapon pipeline, self-infliction |
| `test/integration/` | Multi-command scenarios, regression tests |
| `test/rooms/` | Room-level interaction tests |
| `test/ui/` | UI/status bar tests |

### Headless Mode (D-HEADLESS)

For automated testing, **always** use `--headless`:
```bash
echo "look" | lua src/main.lua --headless
```
This disables TUI, suppresses prompts, and emits `---END---` delimiters.

## Key Design Mechanics

### Two-Hand Inventory
Players have 2 hand slots. Carrying items is a strategic choice. Compound tools (match + matchbox) require BOTH objects in hands.

### Sensory System
- **LOOK/EXAMINE** — requires light
- **FEEL/TOUCH** — always works, primary sense in darkness
- **SMELL/SNIFF** — always works, safe identification
- **LISTEN/HEAR** — always works, reveals mechanical state
- **TASTE/LICK** — always works, but dangerous (poison)

### Light & Time
- Game starts at 2 AM (darkness)
- 1 real hour = 1 game day
- Daytime: 6 AM–6 PM
- Light sources: candles, matches (consumable)

### Parser Pipeline (5 Tiers)
1. **Tier 1:** Exact alias lookup (~70% hit rate)
2. **Tier 2:** Embedding-based semantic matching
3. **Tier 3:** Goal-oriented prerequisite planning (GOAP)
4. **Tier 4:** Context window (recent interactions)
5. **Tier 5:** Fuzzy noun resolution (typos, materials, partials)

## Documentation Reference

| Topic | Location |
|-------|----------|
| Core principles (9 rules) | `docs/architecture/objects/core-principles.md` |
| Deep nesting syntax | `docs/architecture/objects/deep-nesting-syntax.md` |
| Design directives (comprehensive) | `docs/design/design-directives.md` |
| Verb system | `docs/design/verb-system.md` |
| Object design patterns | `docs/design/object-design-patterns.md` |
| Tool/capability system | `docs/design/tools-system.md` |
| FSM lifecycle | `docs/architecture/engine/fsm-object-lifecycle.md` |
| Effects pipeline | `docs/architecture/engine/effects-pipeline.md` |
| Containment constraints | `docs/architecture/engine/containment-constraints.md` |
| Player model | `docs/architecture/player/player-model.md` |
| Material properties | `docs/design/material-properties-system.md` |

## Common Pitfalls

- **Don't add object-specific logic to the engine.** Objects declare behavior via metadata; the engine executes it (Principle 8).
- **Don't forget `on_feel`.** Every object needs a tactile description — it's how players navigate in darkness.
- **Don't put movable objects in `room.description`.** Use `room_presence` for anything the player can interact with.
- **Don't use external Lua dependencies.** The engine must be zero-dependency for Fengari (browser) compatibility.
- **Don't close bug Issues from code.** Only the test team (Marge/Nelson) verifies fixes and closes Issues.
- **Don't skip `--headless` in automated tests.** The TUI causes false-positive hangs in CI and LLM testing.
- **Don't create object-specific state flags.** Use mutation (code rewrite) for state changes (D-14).

## Branch & PR Conventions

### Branch Naming
```
squad/{issue-number}-{kebab-case-slug}
```
Example: `squad/42-fix-parser-disambiguation`

### PR Requirements
- Reference the issue: `Closes #{issue-number}`
- If working as a squad member: `Working as {member} ({role})`
- Run `lua test/run-tests.lua` before opening PRs
