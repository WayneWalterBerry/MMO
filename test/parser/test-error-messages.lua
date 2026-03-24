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
-- Tier 2 Enhancement: Structured Error Context System (Prime Directive #106)
-- TDD RED PHASE: Tests the NEW engine.errors module.
-- All tests below FAIL until errors.lua is implemented by Smithers.
-------------------------------------------------------------------------------

-- Protected require: errors.lua does not exist yet
local ok_errors, errors = pcall(require, "engine.errors")
if not ok_errors then
    print("NOTE: engine.errors not yet implemented — new Tier 2 tests will fail")
    errors = nil
end

h.suite("Tier 2: Error Context System — Category constants")

test("errors.CATEGORY table exists with expected fields", function()
    truthy(errors, "engine.errors module not yet implemented")
    truthy(errors.CATEGORY, "errors.CATEGORY table missing")
    eq("not_found",    errors.CATEGORY.NOT_FOUND)
    eq("wrong_target", errors.CATEGORY.WRONG_TARGET)
    eq("missing_tool", errors.CATEGORY.MISSING_TOOL)
    eq("impossible",   errors.CATEGORY.IMPOSSIBLE)
    eq("dark",         errors.CATEGORY.DARK)
    eq("no_verb",      errors.CATEGORY.NO_VERB)
    eq("ambiguous",    errors.CATEGORY.AMBIGUOUS)
end)

h.suite("Tier 2: Error Context System — NOT_FOUND errors")

test("NOT_FOUND error includes the noun the player typed", function()
    truthy(errors, "engine.errors module not yet implemented")
    local ctx = errors.context(errors.CATEGORY.NOT_FOUND, { noun = "unicorn" })
    local msg = errors.format(ctx)
    truthy(msg:find("unicorn"), "error should reference the noun")
end)

test("NOT_FOUND with close_match suggests 'did you mean'", function()
    truthy(errors, "engine.errors module not yet implemented")
    local ctx = errors.context(errors.CATEGORY.NOT_FOUND, {
        noun = "candel", close_match = "candle"
    })
    local msg = errors.format(ctx)
    truthy(msg:find("candle"), "error should suggest the close match")
end)

h.suite("Tier 2: Error Context System — WRONG_TARGET errors")

test("WRONG_TARGET error explains why in-world, not generic", function()
    truthy(errors, "engine.errors module not yet implemented")
    local obj = { id = "nightstand", name = "oak nightstand" }
    local ctx = errors.context(errors.CATEGORY.WRONG_TARGET, {
        verb = "eat", noun = "nightstand", object = obj
    })
    local msg = errors.format(ctx)
    truthy(msg:find("nightstand"), "error should mention the object")
    truthy(not msg:find("You can't do that"),
           "error must NOT use generic 'You can't do that'")
end)

h.suite("Tier 2: Error Context System — MISSING_TOOL errors")

test("MISSING_TOOL error hints at what's needed", function()
    truthy(errors, "engine.errors module not yet implemented")
    local obj = { id = "candle", name = "tallow candle" }
    local ctx = errors.context(errors.CATEGORY.MISSING_TOOL, {
        verb = "light", noun = "candle", object = obj,
        reason = "a fire source"
    })
    local msg = errors.format(ctx)
    truthy(msg:find("fire source") or msg:find("light"),
           "error should hint at the missing tool")
end)

h.suite("Tier 2: Error Context System — IMPOSSIBLE errors")

test("IMPOSSIBLE error is narrator-voiced, references material", function()
    truthy(errors, "engine.errors module not yet implemented")
    local obj = { id = "nightstand", name = "oak nightstand" }
    local ctx = errors.context(errors.CATEGORY.IMPOSSIBLE, {
        verb = "eat", noun = "nightstand", object = obj,
        reason = "is not something you could eat."
    })
    local msg = errors.format(ctx)
    truthy(msg:find("nightstand"), "error should name the object")
    truthy(#msg < 200, "error should be brief (under 200 chars)")
end)

h.suite("Tier 2: Error Context System — DARK errors")

test("DARK error suggests 'feel' or light source", function()
    truthy(errors, "engine.errors module not yet implemented")
    local ctx = errors.context(errors.CATEGORY.DARK, {
        verb = "look", noun = "around"
    })
    local msg = errors.format(ctx)
    truthy(msg:find("dark"), "error should mention darkness")
    truthy(msg:find("feel") or msg:find("light"),
           "error should suggest feel or light source")
end)

h.suite("Tier 2: Error Context System — NO_VERB errors")

test("NO_VERB with close match suggests correction", function()
    truthy(errors, "engine.errors module not yet implemented")
    local ctx = errors.context(errors.CATEGORY.NO_VERB, {
        verb = "loook", close_match = "look"
    })
    local msg = errors.format(ctx)
    truthy(msg:find("look"), "error should suggest the closest verb")
end)

h.suite("Tier 2: Error Context System — AMBIGUOUS errors")

test("AMBIGUOUS error lists options with 'Which do you mean'", function()
    truthy(errors, "engine.errors module not yet implemented")
    local ctx = errors.context(errors.CATEGORY.AMBIGUOUS, {
        noun = "bottle",
        suggestions = {"glass bottle", "wine bottle"}
    })
    local msg = errors.format(ctx)
    truthy(msg:find("Which do you mean"), "should ask for disambiguation")
    truthy(msg:find("glass bottle"), "should list first option")
    truthy(msg:find("wine bottle"), "should list second option")
end)

h.suite("Tier 2: Error Context System — Quality checks")

test("no error message contains bare 'You can't do that'", function()
    truthy(errors, "engine.errors module not yet implemented")
    local categories = {
        errors.CATEGORY.NOT_FOUND,
        errors.CATEGORY.WRONG_TARGET,
        errors.CATEGORY.MISSING_TOOL,
        errors.CATEGORY.IMPOSSIBLE,
        errors.CATEGORY.DARK,
        errors.CATEGORY.NO_VERB,
    }
    for _, cat in ipairs(categories) do
        local ctx = errors.context(cat, { verb = "test", noun = "test" })
        local msg = errors.format(ctx)
        truthy(not msg:find("You can't do that"),
               cat .. " error must not contain generic 'You can't do that'")
    end
end)

test("no error message contains 'I don't understand that'", function()
    truthy(errors, "engine.errors module not yet implemented")
    local ctx = errors.context(errors.CATEGORY.NO_VERB, { verb = "frobulate" })
    local msg = errors.format(ctx)
    truthy(not msg:find("I don't understand that"),
           "error must not use generic 'I don't understand that'")
end)

test("error messages are brief — under 200 characters", function()
    truthy(errors, "engine.errors module not yet implemented")
    local categories = {
        errors.CATEGORY.NOT_FOUND,
        errors.CATEGORY.WRONG_TARGET,
        errors.CATEGORY.MISSING_TOOL,
        errors.CATEGORY.IMPOSSIBLE,
    }
    for _, cat in ipairs(categories) do
        local ctx = errors.context(cat, {
            verb = "examine", noun = "candle",
            object = { name = "tallow candle" }
        })
        local msg = errors.format(ctx)
        truthy(#msg <= 200,
               cat .. " error too long: " .. #msg .. " chars")
    end
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
