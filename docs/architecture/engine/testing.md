# Parser Unit Test Framework

**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Active

## Overview

Pure-Lua unit test framework for the MMO parser pipeline. No external dependencies — runs anywhere Lua is installed. Tests must pass before deployment.

## Directory Structure

```
test/
├── run-tests.lua          # Test runner — discovers and runs all test files
├── run-before-deploy.ps1  # Pre-deploy gate: tests → build
└── parser/
    ├── test-helpers.lua    # Framework: test(), assert_eq, assert_truthy, etc.
    ├── test-preprocess.lua # Tests for engine/parser/preprocess.lua
    └── test-context.lua    # Tests for context retention + verb dispatch
```

## Running Tests

From the repository root:

```bash
lua test/run-tests.lua
```

Or run a single test file:

```bash
lua test/parser/test-preprocess.lua
```

Pre-deploy (tests + engine build):

```powershell
powershell test/run-before-deploy.ps1
```

## Writing Tests

### Test File Convention

- Files in `test/parser/` matching `test-*.lua` are auto-discovered
- Each file is a standalone Lua script (runs as subprocess for isolation)
- Exit code 0 = all passed, 1 = failures

### Framework API

```lua
local h = require("test.parser.test-helpers")

h.suite("Section Name")           -- prints section header
h.test("description", function()  -- runs fn in pcall, reports pass/fail
    -- test body
end)

h.assert_eq(expected, actual, msg)  -- strict equality
h.assert_truthy(val, msg)           -- val must not be nil/false
h.assert_nil(val, msg)              -- val must be nil
h.assert_no_error(fn, msg)          -- fn must not throw

local failures = h.summary()        -- prints results, returns failure count
os.exit(failures > 0 and 1 or 0)    -- exit with appropriate code
```

### Package Path Setup

Each test file must set up the package path to find engine modules:

```lua
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path
```

### Mock Context for Verb Tests

Context tests that exercise verb handlers need a minimal mock world:

```lua
local ctx = make_context({
    { id = "wardrobe", name = "wardrobe", keywords = {"wardrobe"},
      _state = "closed", states = { ... } }
})
local ok = load_verbs(ctx)  -- loads engine/verbs
ctx.verbs["open"](ctx, "wardrobe")
```

Required context fields: `registry`, `current_room`, `player` (with hands/worn/skills), `game_start_time`, `time_offset`.

## Test Coverage

### test-preprocess.lua (22 tests)
- `preprocess.parse()`: verb/noun splitting, whitespace, casing, pronoun handling
- `preprocess.natural_language()`: question patterns (inventory, look, time), preamble stripping, verb aliases (BUG-049), edge cases

### test-context.lua (4 tests)
- Pronoun resolution: "examine X" then "open it" → resolves to X
- Context retention bug: bare "open" after "search wardrobe" (documents known bug)
- "search everything" crash protection
- BUG-049: "pry" aliased to "open"

## Pre-Deploy Integration

`test/run-before-deploy.ps1` enforces the gate:

1. Runs `lua test/run-tests.lua`
2. If tests fail → exit 1 (deploy blocked)
3. If tests pass → runs `web/build-engine.ps1`

CI/CD should call `run-before-deploy.ps1` instead of `build-engine.ps1` directly.
