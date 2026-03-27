# Test Framework API Reference

The MMO test framework is defined in `test/parser/test-helpers.lua` and provides minimal, pure-Lua testing primitives.

## Core Functions

### `test(name, fn)`

Register and run a single test. Automatically catches errors via `pcall()`.

**Usage:**
```lua
local h = require("test.parser.test-helpers")

h.test("my test name", function()
    -- Test code here
    h.assert_eq(5, 2 + 3)
end)
```

**Behavior:**
- Calls `fn()` wrapped in `pcall()` to catch exceptions
- On success: prints `"  PASS my test name"`
- On failure: prints `"  FAIL my test name: <error>"` and stores error
- Increments internal pass/fail counters

**Exit Handling:**
Errors in `fn()` are caught — they don't crash the test runner. The test is simply marked as failed, and execution continues.

---

### `assert_eq(expected, actual, [msg])`

Assert two values are equal (using Lua's `~=` operator).

**Usage:**
```lua
h.assert_eq(5, 2 + 3)                              -- Pass
h.assert_eq("opened", state, "door should be open") -- Fail with custom message
```

**Behavior:**
- Raises an error if `expected ~= actual`
- Error message includes both values: `"expected: X got: Y"`
- Optional `msg` is prepended: `"door should be open — expected: X got: Y"`

---

### `assert_truthy(val, [msg])`

Assert a value is truthy (not `nil` and not `false`).

**Usage:**
```lua
h.assert_truthy(result)
h.assert_truthy(obj.is_open, "chest should be open")
```

**Behavior:**
- Raises an error if `val` is `nil` or `false`
- Error message: `"expected truthy value — got: nil"` (or shows actual value)

---

### `assert_nil(val, [msg])`

Assert a value is `nil`.

**Usage:**
```lua
h.assert_nil(registry:get("nonexistent"))
h.assert_nil(error_obj, "should have no error")
```

**Behavior:**
- Raises an error if `val ~= nil`
- Error message: `"expected nil — got: X"`

---

### `assert_no_error(fn, [msg])`

Assert that a function executes without raising an error.

**Usage:**
```lua
h.assert_no_error(function()
    loader:load_object("test-object")
end)

h.assert_no_error(function()
    registry:register("obj", obj_def)
end, "registration should not error")
```

**Behavior:**
- Calls `fn()` wrapped in `pcall()`
- If error occurs, raises an error with message `"expected no error — got: X"`

---

### `suite(name)`

Print a section header. Useful for organizing tests into logical groups.

**Usage:**
```lua
h.suite("Player Inventory")
h.test("take item", function() ... end)
h.test("drop item", function() ... end)

h.suite("Container Operations")
h.test("open chest", function() ... end)
```

**Output:**
```
=== Player Inventory ===
  PASS take item
  PASS drop item

=== Container Operations ===
  PASS open chest
```

---

### `summary()`

Print test results and return failure count. Must be called at end of each test file.

**Usage:**
```lua
h.summary()
```

**Output:**
```
--- Results ---
  Passed: 42
  Failed: 0
```

**Return Value:**
- Returns the number of failed tests (0 if all passed)
- Used to set exit code: `os.exit(h.summary() == 0 and 0 or 1)`

**Behavior:**
- Prints pass/fail counts
- If there are failures, prints a "Failures:" section with error details
- Resets internal counters for next test file

---

### `reset()`

Manually reset pass/fail counters (rarely needed).

**Usage:**
```lua
h.reset()  -- Clears all internal state
```

This is useful if a single test file runs multiple independent suites that need separate result tracking.

---

## How Error Handling Works

### pcall Wrapping

The `test()` function uses `pcall()` to safely execute test code:

```lua
function helpers.test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("  PASS " .. name)
        passed = passed + 1
    else
        print("  FAIL " .. name .. ": " .. tostring(err))
        failed = failed + 1
        errors[#errors + 1] = { name = name, err = tostring(err) }
    end
end
```

**Key point:** If an assertion fails (raises an error), the error is caught by `pcall()` and the test is marked as failed. The test runner continues with the next test.

### Assertion Pattern

All `assert_*` functions follow the same pattern:

```lua
if condition_not_met then
    error((msg and (msg .. " — ") or "") ..
          "description of what was expected vs what was found")
end
```

This ensures:
1. Errors are descriptive and include both custom messages and actual values
2. When caught by `test()`, they populate the error log for `summary()`

---

## Exit Code Contract

Every test file must exit with proper code:

```lua
os.exit(h.summary() == 0 and 0 or 1)
```

This converts:
- `h.summary() == 0` (no failures) → exit code 0 (success)
- `h.summary() ~= 0` (failures exist) → exit code 1 (failure)

The test runner (`test/run-tests.lua`) checks these codes to aggregate results.

---

## State Management

The test helpers module maintains internal state:

```lua
local passed = 0
local failed = 0
local errors = {}
```

**Important:** Each test file runs in its own subprocess, so state is isolated. Calling `h.reset()` is rarely necessary unless a single file needs multiple independent test runs.

---

## Complete Example

```lua
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;" .. package.path

local h = require("test.parser.test-helpers")
local module = require("engine.mymodule")

local test = h.test
local eq = h.assert_eq

h.suite("Module Basics")

test("thing works", function()
    eq("expected", module.do_thing())
end)

test("other thing works", function()
    h.assert_truthy(module.other_thing())
end)

h.suite("Error Cases")

test("invalid input errors", function()
    h.assert_no_error(function()
        module.validate(nil)
    end)
end)

os.exit(h.summary() == 0 and 0 or 1)
```

---

For patterns and real-world examples, see [patterns.md](./patterns.md).
