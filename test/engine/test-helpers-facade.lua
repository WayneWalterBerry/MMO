-- test/engine/test-helpers-facade.lua
-- Regression tests for #372 and #376: verbs/helpers facade must load
-- correctly and re-export all public functions from submodules.
-- The Phase 3 refactoring split helpers.lua into helpers/ submodules;
-- this test ensures the facade never breaks again.
--
-- Usage: lua test/engine/test-helpers-facade.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite
local eq = h.assert_eq

---------------------------------------------------------------------------
-- #372: require("engine.verbs.helpers") must not crash
---------------------------------------------------------------------------
suite("#372 helpers facade module loading")

test("require('engine.verbs.helpers') loads without error", function()
    local ok, mod = pcall(require, "engine.verbs.helpers")
    h.assert_truthy(ok, "helpers facade must load: " .. tostring(mod))
    h.assert_truthy(type(mod) == "table", "helpers must return a table")
end)

test("helpers facade exports all core functions", function()
    local H = require("engine.verbs.helpers")
    local required_functions = {
        "err_not_found", "err_cant_do_that", "err_nothing_happens",
        "show_hint", "matches_keyword",
        "hands_full", "first_empty_hand", "which_hand", "count_hands_used",
        "find_visible", "find_in_inventory", "find_tool_in_inventory",
        "remove_from_location", "find_mutation", "perform_mutation",
        "spawn_objects", "provides_capability", "consume_tool_charge",
        "container_contents_accessible",
        "random_body_area", "try_fsm_verb",
        "find_portal_by_keyword", "sync_bidirectional_portal",
        "get_game_time", "is_daytime", "has_some_light",
        "get_light_level", "vision_blocked_by_worn",
    }
    for _, name in ipairs(required_functions) do
        h.assert_truthy(H[name] ~= nil, "missing export: H." .. name)
    end
end)

test("helpers facade exports submodule references", function()
    local H = require("engine.verbs.helpers")
    h.assert_truthy(H.fsm_mod ~= nil, "missing H.fsm_mod")
    h.assert_truthy(H.presentation ~= nil, "missing H.presentation")
    h.assert_truthy(H.preprocess ~= nil, "missing H.preprocess")
    h.assert_truthy(H.effects ~= nil, "missing H.effects")
    h.assert_truthy(H.materials ~= nil, "missing H.materials")
end)

---------------------------------------------------------------------------
-- #372: each submodule loads independently via helpers.X path
---------------------------------------------------------------------------
suite("#372 helpers submodule loading")

local submodules = {
    "engine.verbs.helpers.core",
    "engine.verbs.helpers.inventory",
    "engine.verbs.helpers.search",
    "engine.verbs.helpers.tools",
    "engine.verbs.helpers.mutation",
    "engine.verbs.helpers.combat",
    "engine.verbs.helpers.portal",
}

for _, mod_path in ipairs(submodules) do
    test("require('" .. mod_path .. "') loads without error", function()
        local ok, mod = pcall(require, mod_path)
        h.assert_truthy(ok, "submodule must load: " .. tostring(mod))
        h.assert_truthy(type(mod) == "table", mod_path .. " must return a table")
    end)
end

---------------------------------------------------------------------------
-- #376: engine.verbs loads (which loads helpers), enabling CLI boot
---------------------------------------------------------------------------
suite("#376 engine.verbs loads (CLI boot path)")

test("require('engine.verbs') loads without error", function()
    local ok, mod = pcall(require, "engine.verbs")
    h.assert_truthy(ok, "engine.verbs must load: " .. tostring(mod))
end)

test("engine.verbs.create() returns verb handlers table", function()
    local verbs_mod = require("engine.verbs")
    h.assert_truthy(type(verbs_mod.create) == "function", "verbs.create must be a function")
    local handlers = verbs_mod.create()
    h.assert_truthy(type(handlers) == "table", "create() must return a table")
    h.assert_truthy(handlers.look ~= nil, "handlers must include 'look'")
    h.assert_truthy(handlers.take ~= nil, "handlers must include 'take'")
end)

---------------------------------------------------------------------------
h.summary()
