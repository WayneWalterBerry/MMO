# Testing Overview

The MMO test framework is a **pure-Lua testing system** with zero external dependencies. This makes it ideal for browser deployment (Fengari) and keeps the codebase minimal.

## Quick Start

### Run All Tests
```bash
lua test/run-tests.lua
```

This discovers and runs all `test-*.lua` files across 17 test directories (16 active + 1 reserved), reporting pass/fail status for each. Exit code 0 = all pass, 1 = at least one failure.

### Run a Single Test File
```bash
lua test/verbs/test-open-close-hooks.lua
```

### Run Pre-Deploy Gate (Tests + Web Build)
```powershell
.\test\run-before-deploy.ps1
```

This runs the test suite, then (if all tests pass) triggers `web\build-engine.ps1` to bundle the engine for the browser.

## How It Works

The test system has three core components:

### 1. Test Runner (`test/run-tests.lua`)
The orchestrator that:
- Discovers all test files in 16 hardcoded directories
- Runs each test file as an isolated subprocess (using `io.popen`)
- Captures stdout/stderr from each subprocess
- Checks exit codes to determine pass/fail
- Reports aggregate results

**Key principle:** Each test file is **isolated** — one failure doesn't contaminate others.

### 2. Test Helpers (`test/parser/test-helpers.lua`)
Provides assertion primitives and test grouping:

```lua
local h = require("test.parser.test-helpers")

h.test("my test name", function()
    h.assert_eq(expected, actual, "optional message")
end)

h.suite("My Suite Title")   -- Prints section header
h.summary()                 -- Prints results and returns failed count
```

### 3. Test Files
Located in `test/{category}/` directories and follow a standard pattern (see [patterns.md](./patterns.md)).

## Headless Mode for CI

For automated/CI testing, use headless mode to disable the TUI:

```bash
echo "look" | lua src/main.lua --headless
```

Headless mode:
- Disables terminal UI
- Suppresses interactive prompts
- Emits `---END---` delimiter after each command's output
- Returns clean exit codes (0 = game loaded successfully)

This prevents false-positive hangs and makes output parseable by CI systems.

## Test Framework API

See [framework.md](./framework.md) for the complete API reference:

- `test(name, fn)` — Register a test with automatic error catching
- `assert_eq(expected, actual, msg)` — Check equality
- `assert_truthy(val, msg)` — Check truthiness
- `assert_nil(val, msg)` — Check nil
- `assert_no_error(fn, msg)` — Verify no exception
- `suite(name)` — Print section header
- `summary()` — Print results and return failed count

## Test Patterns

For real-world examples and patterns, see [patterns.md](./patterns.md):

- Context factory (`make_ctx()`) for creating isolated game state
- Output capture (`capture_print()`) for testing narration
- Test isolation with `deep_copy()`
- Module state resets with `setup()`

## Test Directory Structure

See [directory-structure.md](./directory-structure.md) for the full breakdown:

- `test/parser/` — Parser pipeline (preprocess, context, GOAP, fuzzy)
- `test/parser/pipeline/` — Preprocessing stages (7 files, 224+ tests)
- `test/verbs/` — Verb handlers (80+ test files)
- `test/search/` — Object discovery and traversal
- `test/inventory/` — Inventory management and containment
- `test/injuries/` — Injury system and weapon pipeline
- `test/integration/` — Multi-command scenarios
- Plus 10 other specialized directories (ui, rooms, objects, armor, wearables, sensory, fsm, creatures, combat, nightstand)

## Exit Code Contract

Every test file must exit with:
- **0** = All tests passed
- **1** = At least one test failed

This is implemented at the bottom of each test file:
```lua
os.exit(h.summary() == 0 and 0 or 1)
```

The runner checks these codes via `io.popen()` to determine overall pass/fail.

---

**Next:** Learn to write tests by reading [patterns.md](./patterns.md).
