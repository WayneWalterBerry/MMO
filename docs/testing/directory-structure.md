# Test Directory Structure

The test suite is organized into 16 directories, each focused on a specific system or subsystem. This page documents the structure and what each directory tests.

## Directory Layout

```
test/
├── run-tests.lua                    # Main test runner (discovered via discovery)
├── run-before-deploy.ps1            # Pre-deploy gate (tests + web build)
├── parser/
│   ├── test-helpers.lua             # ← Framework (not a test file)
│   ├── test-*.lua                   # 30+ parser tests
│   └── pipeline/
│       └── test-*.lua               # 7 preprocessing stage tests
├── inventory/                       # 11 test files — inventory, containers, search order
├── injuries/                        # 6 test files — injury system, weapon pipeline
├── verbs/                           # 80+ test files — verb handlers (largest suite)
├── search/                          # 23 test files — object discovery, traversal, spatial
├── integration/                     # 7 test files — multi-command scenarios
├── ui/                              # 2 test files — status bar, display
├── rooms/                           # 8 test files — room navigation, exits, portals
├── objects/                         # 12 test files — object definitions, templates, materials
├── armor/                           # 2 test files — armor FSM, degradation
├── wearables/                       # 1 test file — wearable logic
├── sensory/                         # 1 test file — sensory system (feel, smell, etc.)
├── fsm/                             # 1 test file — finite state machine engine
├── creatures/                       # 7 test files — NPC behavior, AI, creature template
├── combat/                          # 7 test files — combat system, material damage, exchange FSM
├── nightstand/                      # 3 test files — nightstand-specific container logic
└── food/                            # (Reserved for future use — currently empty)
```

## Test Directories at a Glance

### `test/parser/` — Parser Pipeline (30+ tests)
Tests the input processing pipeline:
- Verb/noun splitting and normalization
- Pronoun/preamble stripping
- Idiom expansion
- Question pattern detection
- Compound command splitting

**Subdirectory:** `test/parser/pipeline/` (7 preprocessing stage tests)

---

### `test/inventory/` — Inventory System (11 tests)
Tests player inventory management:
- Take/drop mechanics
- Hand slot management (2 hands)
- Put into containers
- Search order (hands, worn, room)
- Containment constraints (size, weight, capacity)

---

### `test/injuries/` — Injury System (6 tests)
Tests damage and healing:
- Weapon injury pipeline
- Unconsciousness triggers
- Self-infliction edge cases
- Injury state and recovery

---

### `test/verbs/` — Verb Handlers (80+ tests)
The largest suite. Tests individual verb implementations:
- **Spatial verbs:** north, south, open, close, look, examine
- **Interaction verbs:** take, drop, put, wear, remove
- **Fire/light verbs:** light, burn, ignite, extinguish
- **Combat verbs:** hit, stab, poison
- **Utility verbs:** inventory, status, help
- **Container verbs:** open/close containers, examine contents

Includes regression tests for specific bug fixes.

---

### `test/search/` — Object Discovery (23 tests)
Tests object lookup and traversal:
- Keyword matching in room/inventory
- Nested container search (drawers, shelves, etc.)
- Spatial relationships (on_top, contents, nested, underneath)
- Search scoping (hands only vs. room only vs. global)
- Streaming search with pagination
- Fuzzy noun resolution

---

### `test/integration/` — Multi-Command Scenarios (7 tests)
Tests sequences of commands:
- Wear/remove sequences
- Stab self pipeline (preparation + execution)
- Room override behavior
- Playtest bug regressions
- No-hang guarantees

---

### `test/ui/` — UI/Display (2 tests)
Tests rendering and presentation:
- Status bar display
- Time display (underground mode)
- Text formatting and word wrapping

---

### `test/rooms/` — Room Navigation (8 tests)
Tests room structure and exit system:
- Exit definitions and linking
- Two-way portal system
- Room loading and initialization
- Level intro sequencing
- Navigation edge cases

---

### `test/objects/` — Object Definitions (12 tests)
Tests object templates and instantiation:
- Template inheritance
- Material properties and consistency
- Object instantiation and GUIDing
- Keyword disambiguation
- Capacity calculations (sack, container)
- Material-specific behavior (tears, burns, etc.)

---

### `test/armor/` — Armor System (2 tests)
Tests wearable armor:
- Armor FSM (intact → damaged → destroyed)
- Ceramic degradation over hits
- Armor interceptor (reduces damage before injury calc)

---

### `test/wearables/` — Wearables (1 test)
Tests wearable logic:
- Helmet swap (one helmet at a time)
- Zone-based wear restrictions

---

### `test/sensory/` — Sensory System (1 test)
Tests multi-sense interactions:
- Feel, smell, listen, taste, look
- Sensory gating (can't smell closed containers)
- Dark mode fallback (feel is primary sense in darkness)

---

### `test/fsm/` — FSM Engine (1 test)
Tests the finite state machine implementation:
- State transitions
- Transition validation (from/to guards)
- Message output on transition
- State lifecycle

---

### `test/creatures/` — NPC/Creature System (7 tests)
Tests creature behavior and AI:
- Creature template instantiation
- Stimulus-response system
- Creature tick (decision loop)
- NPC-specific verbs (talk, ask, give)
- Flesh material behavior
- Integration with combat

---

### `test/combat/` — Combat System (7 tests)
Tests combat mechanics:
- Weapon/armor interaction
- Material-specific damage (wood vs. metal)
- Combat exchange FSM (attack, defend, resolve)
- Narration for combat actions
- Body tree targeting (head, torso, limbs)
- Tissue material properties

---

### `test/nightstand/` — Nightstand Container (3 tests)
Tests nightstand-specific container logic:
- Deep nesting (drawer inside nightstand)
- Container gating (what can be inside)
- Surface vs. contents distinction

---

## How Test Discovery Works

The test runner (`test/run-tests.lua`) has a hardcoded array of 17 directories (including one reserved for future use):

```lua
local test_dirs = {
    repo_root .. SEP .. "test" .. SEP .. "parser",
    repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "pipeline",
    repo_root .. SEP .. "test" .. SEP .. "inventory",
    repo_root .. SEP .. "test" .. SEP .. "injuries",
    repo_root .. SEP .. "test" .. SEP .. "verbs",
    repo_root .. SEP .. "test" .. SEP .. "search",
    repo_root .. SEP .. "test" .. SEP .. "nightstand",
    repo_root .. SEP .. "test" .. SEP .. "integration",
    repo_root .. SEP .. "test" .. SEP .. "ui",
    repo_root .. SEP .. "test" .. SEP .. "rooms",
    repo_root .. SEP .. "test" .. SEP .. "objects",
    repo_root .. SEP .. "test" .. SEP .. "armor",
    repo_root .. SEP .. "test" .. SEP .. "wearables",
    repo_root .. SEP .. "test" .. SEP .. "sensory",
    repo_root .. SEP .. "test" .. SEP .. "fsm",
    repo_root .. SEP .. "test" .. SEP .. "creatures",
    repo_root .. SEP .. "test" .. SEP .. "combat",
    repo_root .. SEP .. "test" .. SEP .. "food",  -- Reserved for future
}
```

```lua
local test_dirs = {
    repo_root .. SEP .. "test" .. SEP .. "parser",
    repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "pipeline",
    repo_root .. SEP .. "test" .. SEP .. "inventory",
    -- ... more directories
}
```

For each directory, it runs a platform-specific command:
- **Windows:** `dir /b "test_dir\test-*.lua" 2>nul`
- **Unix:** `ls "test_dir"/test-*.lua 2>/dev/null`

Files matching `test-*.lua` are collected, sorted, and executed as subprocesses.

---

## Adding a New Test Directory

To add a new test directory:

1. **Create the directory:**
   ```bash
   mkdir test/mynewsystem
   ```

2. **Add to `test_dirs` array in `test/run-tests.lua`:**
   ```lua
   local test_dirs = {
       -- ... existing directories
       repo_root .. SEP .. "test" .. SEP .. "mynewsystem",
   }
   ```

3. **Create test files:**
   ```bash
   # Follow the test file pattern
   touch test/mynewsystem/test-myfeature.lua
   ```

4. **Run tests:**
   ```bash
   lua test/run-tests.lua
   ```

The runner will discover and run all `test-*.lua` files in `mynewsystem/`.

---

## Test Statistics

| Directory | Files | Category |
|-----------|-------|----------|
| parser | 30+ | Input pipeline |
| parser/pipeline | 7 | Preprocessing stages |
| verbs | 80+ | Verb handlers |
| search | 23 | Object discovery |
| inventory | 11 | Inventory/containers |
| injuries | 6 | Damage system |
| creatures | 7 | NPC/creature behavior |
| combat | 7 | Combat mechanics |
| rooms | 8 | Room navigation |
| objects | 12 | Object templates |
| integration | 7 | Multi-command scenarios |
| armor | 2 | Armor FSM |
| ui | 2 | Display/status bar |
| nightstand | 3 | Container nesting |
| wearables | 1 | Wearable logic |
| sensory | 1 | Sensory system |
| fsm | 1 | FSM engine |
| food | — | (Reserved) |
| **TOTAL** | **200+** | **All systems** |

---

## Running Specific Test Categories

Run all tests in a directory:
```bash
# All parser tests
lua test/parser/test-preprocess.lua
lua test/parser/test-context.lua

# All verb handler tests
lua test/verbs/test-combat-verbs.lua

# All inventory tests
lua test/inventory/test-containment-comprehensive.lua
```

Run the full suite:
```bash
lua test/run-tests.lua
```

---

For framework API, see [framework.md](./framework.md).  
For test patterns, see [patterns.md](./patterns.md).
