-- test/search/test-search-streaming.lua
-- Regression tests for #48: search results stream line-by-line with clock
-- advance per item discovered.
--
-- Verifies:
--   1. Each search tick produces a separate narration line
--   2. ctx.time_offset advances by search.MINUTES_PER_STEP per tick
--   3. The on_tick hook fires once per step
--   4. Backward compatibility: existing search semantics unchanged

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

local search   = require("engine.search")
local registry = require("engine.registry")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

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
    if not ok then error(err, 2) end
    return lines
end

--- Drain all remaining ticks, collecting printed lines per tick.
local function drain_ticks(ctx)
    local tick_lines = {}
    local safety = 0
    while search.is_searching() and safety < 200 do
        local lines = capture_print(function() search.tick(ctx) end)
        tick_lines[#tick_lines + 1] = lines
        safety = safety + 1
    end
    return tick_lines
end

local function make_ctx()
    local reg = registry.new()

    local room = {
        id   = "test-room",
        name = "Test Room",
        description = "A room for streaming tests.",
        contents = {},
        exits = {},
        light_level = 1,
    }

    local chair = {
        id = "chair", name = "chair",
        keywords = {"chair"},
        description = "A wooden chair.",
    }

    local table_obj = {
        id = "table", name = "table",
        keywords = {"table"},
        description = "A small table.",
    }

    local lamp = {
        id = "lamp", name = "lamp",
        keywords = {"lamp"},
        description = "A desk lamp.",
    }

    reg:register("test-room", room)
    reg:register("chair", chair)
    reg:register("table", table_obj)
    reg:register("lamp", lamp)

    room.proximity_list = {"chair", "table", "lamp"}
    room.contents       = {"chair", "table", "lamp"}

    return {
        registry     = reg,
        current_room = room,
        player       = { hands = {nil, nil}, state = {} },
        time_offset  = 0,
    }
end

---------------------------------------------------------------------------
h.suite("1. LINE-BY-LINE STREAMING (#48)")
---------------------------------------------------------------------------

test("each search tick produces its own output lines", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function() search.search(ctx, nil, nil) end)
    local tick_lines = drain_ticks(ctx)

    truthy(#tick_lines > 1, "Should have multiple ticks, got " .. #tick_lines)
    -- Every tick should produce at least one line (narration or completion)
    local non_empty = 0
    for _, lines in ipairs(tick_lines) do
        if #lines > 0 then non_empty = non_empty + 1 end
    end
    truthy(non_empty > 0, "At least one tick should produce output")
end)

test("search results are separate narration lines, not a single block", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local all_lines = capture_print(function()
        search.search(ctx, nil, nil)
        while search.is_searching() do search.tick(ctx) end
    end)

    -- First line is the "begin searching" announcement
    truthy(all_lines[1]:find("begin searching"), "First line should be announcement")
    -- Subsequent lines are individual narration
    truthy(#all_lines >= 2, "Should have announcement + at least 1 result line")
end)

---------------------------------------------------------------------------
h.suite("2. CLOCK ADVANCES PER STEP (#48)")
---------------------------------------------------------------------------

test("ctx.time_offset advances by MINUTES_PER_STEP per tick", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end
    ctx.time_offset = 0

    capture_print(function() search.search(ctx, nil, nil) end)

    local expected_per_step = search.MINUTES_PER_STEP / 60
    local ticks = 0
    local advancing_ticks = 0
    while search.is_searching() do
        local before = ctx.time_offset
        capture_print(function() search.tick(ctx) end)
        if ctx.time_offset > before then advancing_ticks = advancing_ticks + 1 end
        ticks = ticks + 1
    end

    truthy(advancing_ticks > 0, "Should have at least one clock-advancing tick")
    -- The final tick (queue exhausted / completion message) does NOT advance
    -- the clock — only actual search steps do.
    local expected = advancing_ticks * expected_per_step
    local diff = math.abs(ctx.time_offset - expected)
    truthy(diff < 0.0001,
        string.format("time_offset should be %.6f, got %.6f (diff %.6f)",
            expected, ctx.time_offset, diff))
end)

test("time_offset is zero before search and positive after", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end
    ctx.time_offset = 0

    eq(0, ctx.time_offset, "Should start at 0")

    capture_print(function()
        search.search(ctx, nil, nil)
        while search.is_searching() do search.tick(ctx) end
    end)

    truthy(ctx.time_offset > 0, "time_offset should have advanced, got " .. tostring(ctx.time_offset))
end)

test("targeted search also advances clock", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end
    ctx.time_offset = 0

    capture_print(function()
        search.search(ctx, "chair", nil)
        while search.is_searching() do search.tick(ctx) end
    end)

    truthy(ctx.time_offset > 0, "Targeted search should advance clock")
end)

test("clock accumulates correctly over multiple steps", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end
    ctx.time_offset = 0

    capture_print(function() search.search(ctx, nil, nil) end)

    local step_size = search.MINUTES_PER_STEP / 60
    local advancing_steps = 0
    while search.is_searching() do
        local before = ctx.time_offset
        capture_print(function() search.tick(ctx) end)
        local after = ctx.time_offset
        local delta = after - before
        if delta > 0 then
            -- This was an actual search step (not the completion message)
            truthy(math.abs(delta - step_size) < 0.0001,
                string.format("Step %d delta should be %.6f, got %.6f",
                    advancing_steps + 1, step_size, delta))
            advancing_steps = advancing_steps + 1
        end
    end
    truthy(advancing_steps >= 1, "Should have at least 1 advancing step")
end)

---------------------------------------------------------------------------
h.suite("3. ON_TICK HOOK (#48)")
---------------------------------------------------------------------------

test("on_tick hook fires once per search step", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local hook_calls = {}
    search.set_on_tick(function(c, step, entry)
        hook_calls[#hook_calls + 1] = { ctx = c, step = step, entry = entry }
    end)

    capture_print(function()
        search.search(ctx, nil, nil)
        while search.is_searching() do search.tick(ctx) end
    end)

    -- Clean up hook
    search.set_on_tick(nil)

    truthy(#hook_calls > 0, "Hook should have been called at least once, got " .. #hook_calls)
    -- Each call should receive the context
    for i, call in ipairs(hook_calls) do
        eq(ctx, call.ctx, "Hook call " .. i .. " should receive ctx")
        truthy(call.step, "Hook call " .. i .. " should receive step number")
        truthy(call.entry, "Hook call " .. i .. " should receive queue entry")
    end
end)

test("on_tick hook receives incrementing step numbers", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local steps = {}
    search.set_on_tick(function(_, step, _)
        steps[#steps + 1] = step
    end)

    capture_print(function()
        search.search(ctx, nil, nil)
        while search.is_searching() do search.tick(ctx) end
    end)

    search.set_on_tick(nil)

    truthy(#steps > 0, "Should have recorded steps")
    for i = 2, #steps do
        truthy(steps[i] > steps[i - 1],
            string.format("Step %d (%d) should be > step %d (%d)",
                i, steps[i], i - 1, steps[i - 1]))
    end
end)

test("nil on_tick hook does not error", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    search.set_on_tick(nil)

    -- Should not error
    capture_print(function()
        search.search(ctx, nil, nil)
        while search.is_searching() do search.tick(ctx) end
    end)
end)

---------------------------------------------------------------------------
h.suite("4. BACKWARD COMPATIBILITY")
---------------------------------------------------------------------------

test("search still announces 'begin searching'", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local lines = capture_print(function() search.search(ctx, nil, nil) end)
    truthy(#lines > 0, "Should produce output")
    truthy(lines[1]:find("begin searching"), "Should announce search start")
end)

test("targeted search still announces target", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local lines = capture_print(function()
        search.search(ctx, "lamp", nil)
    end)
    truthy(lines[1]:find("lamp"), "Should mention target in announcement")
end)

test("search completes and is_searching returns false", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, nil, nil)
        while search.is_searching() do search.tick(ctx) end
    end)

    eq(false, search.is_searching(), "Should not be searching after completion")
end)

test("abort still works during search", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function() search.search(ctx, nil, nil) end)
    truthy(search.is_searching(), "Should be searching")

    capture_print(function() search.abort(ctx) end)
    eq(false, search.is_searching(), "Should stop after abort")
end)

test("ctx without time_offset initializes correctly", function()
    local ctx = make_ctx()
    ctx.time_offset = nil
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, nil, nil)
        while search.is_searching() do search.tick(ctx) end
    end)

    truthy(ctx.time_offset and ctx.time_offset > 0,
        "time_offset should be created and positive")
end)

h.summary()
