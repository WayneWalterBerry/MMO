# Test Patterns & Conventions

This document shows how to write tests in the MMO project — patterns, conventions, and real-world examples.

## File Structure Pattern

Every test file follows this structure:

```lua
-- test/category/test-myfeature.lua
-- Brief description of what is being tested

-- 1. Set up package path (required for subprocess isolation)
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"  -- if needed
             .. package.path

-- 2. Import test helpers and modules under test
local h = require("test.parser.test-helpers")
local target_module = require("engine.mymodule")
local verbs_mod = require("engine.verbs")

-- 3. Alias helpers for brevity
local test = h.test
local eq = h.assert_eq
local truthy = h.assert_truthy

-- 4. Run test suites
h.suite("Feature Area 1")

test("first test", function()
    eq(5, 2 + 3)
end)

test("second test", function()
    truthy(some_value)
end)

h.suite("Feature Area 2")

test("another test", function()
    h.assert_no_error(function()
        target_module.do_something()
    end)
end)

-- 5. Print results and exit
os.exit(h.summary() == 0 and 0 or 1)
```

**Key points:**
- Always set `package.path` — test files run as subprocesses
- Use `arg[0]:match()` pattern to get current script directory
- Import helpers and target modules
- Alias helpers to `test`, `eq`, `truthy` etc. for brevity
- Always exit with `os.exit(h.summary() == 0 and 0 or 1)`

---

## Context Factory Pattern

Most tests need a minimal game context (registry, room, player, etc.). Use a factory function:

```lua
local function make_ctx()
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A featureless room.",
        contents = {},
        exits = {},
    }
    local player = {
        hands = { nil, nil },
        worn = {},
        state = {},
    }
    local handlers = verbs_mod.create()
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        verbs = handlers,
        last_noun = nil,
        last_object = nil,
    }
    return ctx, reg, room, handlers
end
```

**Usage:**
```lua
h.suite("Inventory Management")

test("take adds item to hand", function()
    local ctx, reg, room, verbs = make_ctx()
    
    -- Register and place an object
    local obj = { id = "sword", name = "a sword" }
    reg:register(obj.id, obj)
    room.contents[#room.contents + 1] = obj.id
    
    -- Invoke verb handler
    verbs.take(ctx, "sword")
    
    -- Verify state
    eq(obj.id, ctx.player.hands[1])
end)
```

**Benefits:**
- Fresh registry for each test (isolation)
- Minimal but complete context
- Easy to customize per test if needed

---

## Output Capture Pattern

To test narration and print output, capture `print()` calls:

```lua
local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Call failed: " .. tostring(err)) end
    return table.concat(lines, "\n")
end
```

**Usage:**
```lua
test("open message displayed", function()
    local ctx, reg, room, verbs = make_ctx()
    
    -- Register chest with FSM
    local chest = {
        id = "chest", name = "a chest",
        _state = "closed",
        states = {
            closed = { description = "Shut." },
            open = { description = "Open." },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open", message = "You open it." },
        },
    }
    reg:register(chest.id, chest)
    room.contents[#room.contents + 1] = chest.id
    
    -- Capture output
    local output = capture_print(function()
        verbs.open(ctx, "chest")
    end)
    
    -- Verify narration
    truthy(output:find("You open it"))
end)
```

**Key points:**
- Save and restore `_G.print` to avoid breaking test output
- Wrap the fn in `pcall()` to surface errors
- Collect lines in a table and join with newlines

---

## Test Isolation with deep_copy

For tests that modify state, use `deep_copy()` to avoid cross-contamination:

```lua
local function deep_copy(obj)
    if type(obj) ~= "table" then return obj end
    local copy = {}
    for k, v in pairs(obj) do
        copy[k] = deep_copy(v)
    end
    return copy
end

test("state change isolated", function()
    local ctx1, reg1, room1 = make_ctx()
    local obj = { id = "item", value = 10 }
    reg1:register(obj.id, obj)
    
    -- Modify in context 1
    local ctx1_obj = reg1:get("item")
    ctx1_obj.value = 20
    
    -- Context 2 should have fresh state
    local ctx2, reg2, room2 = make_ctx()
    local ctx2_obj = reg2:get("item") or { value = 10 }
    
    eq(10, ctx2_obj.value)  -- Should be original value
end)
```

Each call to `make_ctx()` creates a fresh registry, so cross-contamination is rare. Use `deep_copy()` only when sharing objects between tests.

---

## Section-Level Setup Pattern

For tests that need shared setup:

```lua
h.suite("Lighting System")

local function setup()
    -- Shared setup for this suite
    local ctx, reg, room = make_ctx()
    
    local candle = { id = "candle", name = "a candle", _state = "unlit" }
    reg:register(candle.id, candle)
    room.contents[#room.contents + 1] = candle.id
    
    return ctx, reg
end

test("light with match", function()
    local ctx, reg = setup()
    -- Test code
end)

test("light without match errors", function()
    local ctx, reg = setup()
    -- Test code
end)
```

**Note:** This is just a helper function; the test framework doesn't have a built-in setup hook. Each test explicitly calls it.

---

## dofile vs require

Use **`dofile()`** to load test target files when you need fresh instances:

```lua
-- Each test gets a fresh copy of the module
local preprocess = dofile("src/engine/parser/preprocess.lua")
```

Use **`require()`** for stateless modules (or when caching is desired):

```lua
-- Shared instance across tests
local helpers = require("test.parser.test-helpers")
```

**Rule of thumb:**
- `dofile()` — when module has internal state you want to reset per test
- `require()` — when module is stateless or caching is fine

---

## Naming Conventions

### Test File Names
```
test-{feature}.lua              -- Most common
test-{issue}-bugs.lua           -- For bug regression tests
test-{pass-number}-bugs.lua     -- For multi-pass regression
```

Examples:
- `test-inventory.lua` — General inventory system
- `test-open-close-hooks.lua` — Specific feature
- `test-bugs-211-212.lua` — Multiple bug regressions
- `test-pass031-bugs.lua` — Bugs from pass 31

### Test Naming
Use present-tense, descriptive names:

```lua
test("take adds item to hand", function() ... end)           -- ✓ Good
test("drop removes item from player", function() ... end)    -- ✓ Good
test("take with no target", function() ... end)              -- ✓ Good
test("test_take", function() ... end)                        -- ✗ Avoid
test("X", function() ... end)                                -- ✗ Avoid
```

---

## Complete Example: Parser Test

```lua
-- test/parser/test-myparser.lua
-- Unit tests for parser normalization and verb resolution

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local parser = require("engine.parser.preprocess")

local test = h.test
local eq = h.assert_eq

h.suite("Verb/Noun Splitting")

test("single word is verb only", function()
    local v, n = parser.parse("look")
    eq("look", v)
    eq("", n)
end)

test("two words split correctly", function()
    local v, n = parser.parse("open door")
    eq("open", v)
    eq("door", n)
end)

h.suite("Normalization")

test("input lowercased", function()
    local v, n = parser.parse("LOOK AROUND")
    eq("look", v)
    eq("around", n)
end)

test("whitespace trimmed", function()
    local v, n = parser.parse("  look   ")
    eq("look", v)
    eq("", n)
end)

os.exit(h.summary() == 0 and 0 or 1)
```

---

## Complete Example: Verb Handler Test

```lua
-- test/verbs/test-myverm.lua
-- Tests for a custom verb handler

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local verbs_mod = require("engine.verbs")

local test = h.test
local eq = h.assert_eq
local truthy = h.assert_truthy

local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    fn()
    _G.print = old_print
    return table.concat(lines, "\n")
end

local function make_ctx()
    local ctx = {
        registry = { get = function() end },
        current_room = { contents = {} },
        player = { hands = { nil, nil } },
    }
    return ctx
end

local handlers = verbs_mod.create()

h.suite("Verb: examine")

test("examine found object", function()
    local ctx = make_ctx()
    local output = capture_print(function()
        handlers.examine(ctx, "object")
    end)
    truthy(output)
end)

os.exit(h.summary() == 0 and 0 or 1)
```

---

For API reference, see [framework.md](./framework.md).  
For directory structure, see [directory-structure.md](./directory-structure.md).
