-- test/verbs/test-verb-aliases-354.lua
-- TDD regression tests for issues #354, #336, #350.
-- #354: kill/slay/murder should alias to attack
-- #336: same aliases (kill/slay/murder → attack)
-- #350: dissect/gut should alias to butcher
--
-- Usage: lua test/verbs/test-verb-aliases-354.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")

local test = h.test
local suite = h.suite

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

---------------------------------------------------------------------------
-- Issue #354 / #336: kill, slay, murder → attack
---------------------------------------------------------------------------
suite("Issue #354/#336: kill/slay/murder → attack aliases")

test("handlers['kill'] exists", function()
    h.assert_truthy(handlers["kill"], "kill handler should be registered")
end)

test("handlers['slay'] exists", function()
    h.assert_truthy(handlers["slay"], "slay handler should be registered")
end)

test("handlers['murder'] exists", function()
    h.assert_truthy(handlers["murder"], "murder handler should be registered")
end)

test("kill is same function as attack", function()
    h.assert_eq(handlers["kill"], handlers["attack"],
        "kill should be the same handler function as attack")
end)

test("slay is same function as attack", function()
    h.assert_eq(handlers["slay"], handlers["attack"],
        "slay should be the same handler function as attack")
end)

test("murder is same function as attack", function()
    h.assert_eq(handlers["murder"], handlers["attack"],
        "murder should be the same handler function as attack")
end)

test("fight is same function as attack (pre-existing)", function()
    h.assert_eq(handlers["fight"], handlers["attack"],
        "fight should be the same handler function as attack")
end)

test("kill with no noun prints prompt", function()
    local out = capture_output(function()
        handlers["kill"]({}, "")
    end)
    h.assert_eq(out, "Attack what?",
        "kill with no noun should print 'Attack what?'")
end)

---------------------------------------------------------------------------
-- Issue #350: dissect, gut → butcher
---------------------------------------------------------------------------
suite("Issue #350: dissect/gut → butcher aliases")

test("handlers['dissect'] exists", function()
    h.assert_truthy(handlers["dissect"], "dissect handler should be registered")
end)

test("handlers['gut'] exists", function()
    h.assert_truthy(handlers["gut"], "gut handler should be registered")
end)

test("dissect is same function as butcher", function()
    h.assert_eq(handlers["dissect"], handlers["butcher"],
        "dissect should be the same handler function as butcher")
end)

test("gut is same function as butcher", function()
    h.assert_eq(handlers["gut"], handlers["butcher"],
        "gut should be the same handler function as butcher")
end)

-- Pre-existing aliases still work
test("carve is same function as butcher (pre-existing)", function()
    h.assert_eq(handlers["carve"], handlers["butcher"],
        "carve should be the same handler function as butcher")
end)

test("skin is same function as butcher (pre-existing)", function()
    h.assert_eq(handlers["skin"], handlers["butcher"],
        "skin should be the same handler function as butcher")
end)

test("fillet is same function as butcher (pre-existing)", function()
    h.assert_eq(handlers["fillet"], handlers["butcher"],
        "fillet should be the same handler function as butcher")
end)

---------------------------------------------------------------------------
h.summary()
