-- test/verbs/test-parser-synonyms.lua
-- Unit tests for verb synonyms and parser flexibility
-- Tests: Issue #2 (move as synonym for go), Issue #4 (sleep without "for")

-- Set up package path to find engine modules from repo root
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local verbs_mod = require("engine.verbs")
local registry = require("engine.registry")

local test = h.test
local eq   = h.assert_eq

-- Create verb handlers
local handlers = verbs_mod.create()

-------------------------------------------------------------------------------
h.suite("Issue #4 — sleep without 'for' keyword")
-------------------------------------------------------------------------------

test("'sleep 6 hours' works without 'for'", function()
    local ctx = { registry = registry, time_offset = 0, injuries = {}, game_start_time = os.time() }
    local handler = handlers["sleep"]
    
    if not handler then
        error("Sleep handler not found!")
    end
    
    -- Mock print to capture output
    local captured = {}
    local old_print = print
    _G.print = function(msg) captured[#captured + 1] = msg end
    
    -- Call handler (this might fail if missing dependencies)
    local ok, err = pcall(function()
        handler(ctx, "6 hours")
    end)
    
    _G.print = old_print
    
    if not ok then
        error("Handler call failed: " .. tostring(err))
    end
    
    -- Verify time advanced 6 hours
    eq(6, ctx.time_offset, "Time should advance 6 hours")
    
    -- Verify no error message about format
    for _, msg in ipairs(captured) do
        if msg:match("Sleep how long") then
            error("Got error message for 'sleep 6 hours' without 'for'")
        end
    end
end)

test("'sleep 3 hours' works", function()
    local ctx = { registry = registry, time_offset = 0, injuries = {}, game_start_time = os.time() }
    local handler = handlers["sleep"]
    
    local captured = {}
    local old_print = print
    _G.print = function(msg) captured[#captured + 1] = msg end
    
    handler(ctx, "3 hours")
    
    _G.print = old_print
    
    eq(3, ctx.time_offset, "Time should advance 3 hours")
end)

test("'sleep 1 hour' works", function()
    local ctx = { registry = registry, time_offset = 0, injuries = {}, game_start_time = os.time() }
    local handler = handlers["sleep"]
    
    local captured = {}
    local old_print = print
    _G.print = function(msg) captured[#captured + 1] = msg end
    
    handler(ctx, "1 hour")
    
    _G.print = old_print
    
    eq(1, ctx.time_offset, "Time should advance 1 hour")
end)

test("'sleep for 2 hours' still works (backward compat)", function()
    local ctx = { registry = registry, time_offset = 0, injuries = {}, game_start_time = os.time() }
    local handler = handlers["sleep"]
    
    local captured = {}
    local old_print = print
    _G.print = function(msg) captured[#captured + 1] = msg end
    
    handler(ctx, "for 2 hours")
    
    _G.print = old_print
    
    eq(2, ctx.time_offset, "Time should advance 2 hours")
end)

test("'sleep 30 minutes' works", function()
    local ctx = { registry = registry, time_offset = 0, injuries = {}, game_start_time = os.time() }
    local handler = handlers["sleep"]
    
    local captured = {}
    local old_print = print
    _G.print = function(msg) captured[#captured + 1] = msg end
    
    handler(ctx, "30 minutes")
    
    _G.print = old_print
    
    eq(0.5, ctx.time_offset, "Time should advance 0.5 hours (30 minutes)")
end)

test("'sleep until dawn' still works", function()
    local ctx = { registry = registry, time_offset = 0, injuries = {}, game_start_time = os.time() }
    local handler = handlers["sleep"]
    
    local captured = {}
    local old_print = print
    _G.print = function(msg) captured[#captured + 1] = msg end
    
    handler(ctx, "until dawn")
    
    _G.print = old_print
    
    -- Should advance to 6 AM from 2 AM (game start)
    -- Time advanced should be positive (at least moving forward)
    if ctx.time_offset <= 0 then
        error("Time should advance forward")
    end
end)

test("'sleep until morning' works", function()
    local ctx = { registry = registry, time_offset = 0, injuries = {}, game_start_time = os.time() }
    local handler = handlers["sleep"]
    
    local captured = {}
    local old_print = print
    _G.print = function(msg) captured[#captured + 1] = msg end
    
    handler(ctx, "until morning")
    
    _G.print = old_print
    
    -- Should advance to 6 AM (same as dawn)
    -- Time advanced should be positive
    if ctx.time_offset <= 0 then
        error("Time should advance forward")
    end
end)

-------------------------------------------------------------------------------
h.suite("Issue #2 — 'move' as synonym for 'go'")
-------------------------------------------------------------------------------

test("'move' verb handler exists", function()
    local handler = handlers["move"]
    if not handler then
        error("'move' verb handler not found")
    end
end)

test("'move' maps to same handler as 'go'", function()
    local move_handler = handlers["move"]
    local go_handler = handlers["go"]
    
    eq(go_handler, move_handler, "'move' should be same handler as 'go'")
end)

test("'walk', 'run', 'head', 'travel' are also synonyms", function()
    local go_handler = handlers["go"]
    
    eq(go_handler, handlers["walk"], "'walk' should be synonym")
    eq(go_handler, handlers["run"], "'run' should be synonym")
    eq(go_handler, handlers["head"], "'head' should be synonym")
    eq(go_handler, handlers["travel"], "'travel' should be synonym")
    eq(go_handler, handlers["move"], "'move' should be synonym")
end)

-- Note: Full integration testing of movement requires a room context,
-- which is better handled by integration tests. These unit tests just
-- verify the verb handler mapping exists.

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
