-- test/parser/test-error-messages.lua
-- Tier 2: Error message overhaul tests.
-- Validates that error messages are helpful, never echo failed input literally,
-- and always suggest valid actions per the Prime Directive.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../?.lua;"
             .. package.path

local h = require("test.parser.test-helpers")

local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

-------------------------------------------------------------------------------
-- Helper: capture print output from a function call
-------------------------------------------------------------------------------
local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[#parts + 1] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err) end
    return table.concat(lines, "\n")
end

-------------------------------------------------------------------------------
h.suite("Tier 2: Parser fallback error messages")
-------------------------------------------------------------------------------

-- Test the parser/init.lua fallback message
test("parser fallback suggests 'help'", function()
    local parser = require("engine.parser.init")
    -- Create a mock instance without a real matcher
    local instance = {
        matcher = {
            match = function(self, input)
                return nil, nil, 0, nil
            end,
        },
        threshold = 0.40,
        diagnostic = false,
    }
    local output = capture_print(function()
        parser.fallback(instance, "xyzgarbage", { verbs = {} })
    end)
    truthy(output:find("help"), "Parser fallback should suggest 'help'")
    -- Should NOT echo the failed input literally
    truthy(not output:find("xyzgarbage"), "Parser fallback should not echo failed input")
end)

-------------------------------------------------------------------------------
h.suite("Tier 2: Search narrator error messages")
-------------------------------------------------------------------------------

test("search completion with target suggests 'search'", function()
    local narrator = require("engine.search.narrator")
    local ctx = { current_room = { light_level = 1 } }
    local msg = narrator.completion(ctx, {}, "unicorn")
    truthy(msg:find("search"), "Should suggest 'search' when target not found")
    -- Should NOT echo the target name literally (Prime Directive)
    truthy(not msg:find("unicorn"), "Should not echo target name in error")
end)

test("search completion without target and no items suggests 'look'", function()
    local narrator = require("engine.search.narrator")
    local ctx = { current_room = { light_level = 1 } }
    local msg = narrator.completion(ctx, {}, nil)
    truthy(msg:find("look") or msg:find("search"), "Should suggest next action")
end)

test("search completion with found items is neutral", function()
    local narrator = require("engine.search.narrator")
    local ctx = { current_room = { light_level = 1 } }
    local msg = narrator.completion(ctx, { "item1" }, nil)
    truthy(msg:find("finish searching"), "Should indicate search is done")
end)

test("search completion message contains 'finish searching' (test compat)", function()
    local narrator = require("engine.search.narrator")
    local ctx = { current_room = { light_level = 1 } }
    local msg = narrator.completion(ctx, {}, "nonexistent")
    truthy(msg:find("finish searching"), "Must contain 'finish searching' for backward compat")
end)

-------------------------------------------------------------------------------
h.suite("Tier 2: Error messages suggest valid actions")
-------------------------------------------------------------------------------

test("err_not_found suggests 'search around'", function()
    local verbs_mod = require("engine.verbs")
    local registry_mod = require("engine.registry")
    local reg = registry_mod.new()
    local handlers = verbs_mod.create()
    local ctx = {
        player = { hands = {}, worn = {}, state = {} },
        current_room = { id = "room1", name = "Test Room", contents = {}, exits = {}, light_level = 1 },
        registry = reg,
        current_verb = "take",
        known_objects = {},
        verbs = handlers,
    }
    local output = capture_print(function()
        handlers["take"](ctx, "nonexistent")
    end)
    truthy(output:find("search around") or output:find("search"), "err_not_found should suggest searching")
end)

test("examine without noun suggests 'look'", function()
    local verbs_mod = require("engine.verbs")
    local registry_mod = require("engine.registry")
    local reg = registry_mod.new()
    local handlers = verbs_mod.create()
    local ctx = {
        player = { hands = {}, worn = {}, state = {} },
        current_room = { id = "room1", name = "Test Room", contents = {}, exits = {}, light_level = 1 },
        registry = reg,
        current_verb = "examine",
        known_objects = {},
        verbs = handlers,
    }
    local output = capture_print(function()
        handlers["examine"](ctx, "")
    end)
    truthy(output:find("look"), "Examine with no noun should suggest 'look'")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
