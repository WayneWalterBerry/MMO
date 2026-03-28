-- test/verbs/test-light-spent-match-361.lua
-- Issue #361: Light candle grabs spent match before working one.
-- TDD: Tests written before fix.

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

local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
        find_by_keyword = function(self, kw)
            local results = {}
            for _, obj in pairs(self._objects) do
                if obj.keywords then
                    for _, k in ipairs(obj.keywords) do
                        if k:lower() == kw:lower() then
                            results[#results + 1] = obj
                            break
                        end
                    end
                end
            end
            return results
        end,
    }
end

local function fresh_candle()
    return {
        id = "candle", name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        portable = true,
        on_feel = "Waxy cylinder, cool to the touch.",
        initial_state = "unlit",
        _state = "unlit",
        states = {
            unlit = { description = "An unlit tallow candle.", casts_light = false },
            lit   = { description = "A flickering tallow candle.", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light", requires_tool = "fire_source" },
        },
    }
end

local function fresh_match()
    return {
        id = "match", name = "a wooden match",
        keywords = {"match", "wooden match"},
        portable = true,
        initial_state = "unlit",
        _state = "unlit",
        states = {
            unlit = { description = "An unlit wooden match." },
            lit   = { description = "A lit match, flickering.", provides_tool = "fire_source", casts_light = true },
            spent = { description = "A spent, blackened match.", terminal = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "strike" },
            { from = "lit", to = "spent", verb = "extinguish" },
        },
    }
end

local function spent_match()
    local m = fresh_match()
    m.id = "match-spent"
    m._state = "spent"
    return m
end

---------------------------------------------------------------------------
-- #361: Auto-prep must skip spent matches
---------------------------------------------------------------------------
suite("#361: Light candle skips spent matches")

test("spent match in hand 1, fresh match in hand 2 → uses fresh match", function()
    local candle = fresh_candle()
    local bad_match = spent_match()
    local good_match = fresh_match()
    good_match.id = "match-good"

    local reg = make_mock_registry({
        candle = candle,
        ["match-spent"] = bad_match,
        ["match-good"] = good_match,
    })
    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.", contents = { "candle" },
        exits = {}, light_level = 0,
    }
    -- Candle in hand slot 1 (so find_in_inventory finds it),
    -- matches in hand slots would conflict. Put matches in other hand.
    -- Actually: candle visible on floor, matches in both hands.
    local player = {
        max_health = 100, health = 100,
        injuries = {}, hands = { bad_match, good_match },
        worn_items = {}, bags = {}, worn = {},
        state = {},
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "light",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
    local output = capture_output(function() handlers["light"](ctx, "candle") end)
    -- The good match should be auto-ignited (state changed to "lit")
    h.assert_truthy(good_match._state == "lit",
        "Fresh match should be auto-ignited to 'lit', got state: " .. tostring(good_match._state))
    -- The spent match should remain spent
    h.assert_eq("spent", bad_match._state,
        "Spent match must remain in 'spent' state")
end)

test("only spent match in hand → does not auto-ignite it", function()
    local candle = fresh_candle()
    local bad_match = spent_match()

    local reg = make_mock_registry({
        candle = candle,
        ["match-spent"] = bad_match,
    })
    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.", contents = { "candle" },
        exits = {}, light_level = 0,
    }
    local player = {
        max_health = 100, health = 100,
        injuries = {}, hands = { bad_match, nil },
        worn_items = {}, bags = {}, worn = {},
        state = {},
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "light",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
    local output = capture_output(function() handlers["light"](ctx, "candle") end)
    -- Spent match must NOT be auto-ignited
    h.assert_eq("spent", bad_match._state,
        "Spent match must remain 'spent', got: " .. tostring(bad_match._state))
    -- Should say something about needing a flame
    h.assert_truthy(output:find("flame") or output:find("light") or output:find("lit") or output:find("spent"),
        "Should explain why light failed, got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
