-- test/options/test-number-selection.lua
-- TDD tests for the numbered option selection system.
-- Written from architecture spec §4.3 (numbered selection).
-- Tests the input interception logic that routes "1", "2" etc.
-- to the corresponding pending_options command.

local t = require("test.parser.test-helpers")
local test = t.test
local eq = t.assert_eq
local truthy = t.assert_truthy

-- ============================================================
-- Mock infrastructure
-- ============================================================

-- Simulate the number selection logic from arch §4.3:
--   local num = tonumber(input)
--   if num and ctx.player.pending_options and ctx.player.pending_options[num] then
--       input = ctx.player.pending_options[num].command
--       ctx.player.pending_options = nil
--   end
-- Plus: non-numeric input clears pending_options (§4.9)

local function resolve_number_input(input, ctx)
    local num = tonumber(input)

    -- Precedence rule (§4.3): only active when pending_options exists
    if num and ctx.player.pending_options and ctx.player.pending_options[num] then
        local command = ctx.player.pending_options[num].command
        ctx.player.pending_options = nil  -- clear after use
        return command, nil  -- resolved command, no error
    end

    -- Out-of-range number with active pending_options
    if num and ctx.player.pending_options then
        if num < 1 or num > #ctx.player.pending_options then
            return nil, "invalid_number"  -- error: out of range
        end
    end

    -- Non-numeric input clears pending_options (§4.9)
    if not num and ctx.player.pending_options then
        ctx.player.pending_options = nil
    end

    -- No pending_options: numbers pass through as-is
    return input, nil
end

-- Build mock context with pending_options
local function make_ctx_with_options()
    return {
        player = {
            pending_options = {
                { command = "feel",           display = "Feel around for objects" },
                { command = "open door north", display = "Try the door to the north" },
                { command = "listen",          display = "Listen carefully for sounds" },
                { command = "smell",           display = "Sniff the air for clues" },
            },
            hands = { nil, nil },
            inventory = {},
            state = {},
        },
        current_room = { id = "test-room", contents = {}, exits = {} },
    }
end

local function make_ctx_without_options()
    return {
        player = {
            pending_options = nil,
            hands = { nil, nil },
            inventory = {},
            state = {},
        },
        current_room = { id = "test-room", contents = {}, exits = {} },
    }
end

-- ============================================================
-- Tests
-- ============================================================

t.suite("number selection — valid option execution")

test("typing '1' after options executes first option's command", function()
    local ctx = make_ctx_with_options()
    local result, err = resolve_number_input("1", ctx)
    eq("feel", result, "should resolve to first option command")
    truthy(not err, "should not return error")
end)

test("typing '2' after options executes second option's command", function()
    local ctx = make_ctx_with_options()
    local result, err = resolve_number_input("2", ctx)
    eq("open door north", result, "should resolve to second option command")
end)

test("typing '3' after options executes third option's command", function()
    local ctx = make_ctx_with_options()
    local result, err = resolve_number_input("3", ctx)
    eq("listen", result, "should resolve to third option command")
end)

test("typing '4' after options executes fourth option's command", function()
    local ctx = make_ctx_with_options()
    local result, err = resolve_number_input("4", ctx)
    eq("smell", result, "should resolve to fourth option command")
end)

t.suite("number selection — out-of-range errors")

test("typing '5' when only 4 options exist returns error", function()
    local ctx = make_ctx_with_options()
    local result, err = resolve_number_input("5", ctx)
    eq("invalid_number", err, "should return invalid_number error")
end)

test("typing '0' returns error", function()
    local ctx = make_ctx_with_options()
    local result, err = resolve_number_input("0", ctx)
    eq("invalid_number", err, "0 is out of range")
end)

test("typing '-1' returns error", function()
    local ctx = make_ctx_with_options()
    local result, err = resolve_number_input("-1", ctx)
    eq("invalid_number", err, "-1 is out of range")
end)

t.suite("number selection — clearing pending_options")

test("after executing a number, pending_options is cleared", function()
    local ctx = make_ctx_with_options()
    resolve_number_input("1", ctx)
    truthy(ctx.player.pending_options == nil,
        "pending_options should be nil after number execution")
end)

test("typing a non-number clears pending_options", function()
    local ctx = make_ctx_with_options()
    resolve_number_input("look around", ctx)
    truthy(ctx.player.pending_options == nil,
        "non-numeric input should clear pending_options")
end)

test("after clearing, original text passes through", function()
    local ctx = make_ctx_with_options()
    local result, err = resolve_number_input("look around", ctx)
    eq("look around", result, "non-numeric input should pass through unchanged")
end)

t.suite("number selection — no pending_options (passthrough)")

test("when no pending_options, numbers pass through to normal parser", function()
    local ctx = make_ctx_without_options()
    local result, err = resolve_number_input("1", ctx)
    eq("1", result, "number should pass through when no pending_options")
    truthy(not err, "should not error")
end)

test("when no pending_options, '42' passes through unchanged", function()
    local ctx = make_ctx_without_options()
    local result, err = resolve_number_input("42", ctx)
    eq("42", result, "arbitrary number passes through without pending_options")
end)

test("when no pending_options, text input passes through", function()
    local ctx = make_ctx_without_options()
    local result, err = resolve_number_input("open door", ctx)
    eq("open door", result, "text should pass through when no pending_options")
end)

t.suite("number selection — precedence rule")

test("number selection only active after calling options verb", function()
    -- Simulate: player has NOT called options → pending_options is nil
    local ctx = make_ctx_without_options()
    local result, _ = resolve_number_input("2", ctx)
    eq("2", result, "without options call, '2' is not intercepted")

    -- Simulate: player calls options → pending_options is set
    ctx = make_ctx_with_options()
    local result2, _ = resolve_number_input("2", ctx)
    eq("open door north", result2, "with options call, '2' resolves to command")
end)

test("typing options again refreshes the list (clears old pending)", function()
    local ctx = make_ctx_with_options()
    -- Player types "options" instead of a number
    resolve_number_input("options", ctx)
    -- pending_options should be cleared (non-numeric input)
    truthy(ctx.player.pending_options == nil,
        "typing 'options' (text) should clear old pending_options")
end)

-- ============================================================
local exit_code = t.summary()
t.reset()
os.exit(exit_code)
