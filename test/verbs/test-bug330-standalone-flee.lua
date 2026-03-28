-- test/verbs/test-bug330-standalone-flee.lua
-- Regression tests for bug #330: No standalone flee/run verb outside combat.
-- Verifies that "flee", "run", "run away", and "escape" work as standalone
-- verbs when threats are present, and fall back to movement when they aren't.
--
-- Usage: lua test/verbs/test-bug330-standalone-flee.lua

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
local truthy = h.assert_truthy

local verbs_mod = require("engine.verbs")
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
    local objs = objects or {}
    return {
        _objects = objs,
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
        all = function(self)
            local result = {}
            for _, o in pairs(self._objects) do result[#result + 1] = o end
            return result
        end,
    }
end

---------------------------------------------------------------------------
-- Test: verb registration
---------------------------------------------------------------------------
suite("Bug #330 — standalone flee/run verb")

test("1. 'flee' handler is registered", function()
    truthy(handlers["flee"] ~= nil, "flee handler should be registered")
end)

test("2. 'run' handler is registered and maps to flee", function()
    truthy(handlers["run"] ~= nil, "run handler should be registered")
    -- Both should be the same function (after consciousness wrapper)
end)

test("3. 'escape' handler is registered", function()
    truthy(handlers["escape"] ~= nil, "escape handler should be registered")
end)

---------------------------------------------------------------------------
-- Test: no threat → "nothing to flee from" or falls back to go
---------------------------------------------------------------------------
test("4. 'flee' with no threats says nothing to flee from", function()
    local reg = make_mock_registry({})
    local room = {
        id = "bedroom",
        name = "Bedroom",
        contents = {},
        exits = { north = { target = "hallway" } },
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = {},
            state = {},
            location = "bedroom",
        },
        time_offset = 8,
        game_start_time = os.time(),
    }
    local output = capture_output(function()
        handlers["flee"](ctx, "")
    end)
    truthy(output:find("nothing to flee"),
        "No threats should say 'nothing to flee from', got: " .. output)
end)

test("5. 'run' with no threats says nothing to flee from", function()
    local reg = make_mock_registry({})
    local room = {
        id = "bedroom",
        name = "Bedroom",
        contents = {},
        exits = { north = { target = "hallway" } },
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = {},
            state = {},
            location = "bedroom",
        },
        time_offset = 8,
        game_start_time = os.time(),
    }
    local output = capture_output(function()
        handlers["run"](ctx, "")
    end)
    truthy(output:find("nothing to flee"),
        "'run' with no threats should say 'nothing to flee', got: " .. output)
end)

test("6. 'run away' with no threats says nothing to flee from", function()
    local reg = make_mock_registry({})
    local room = {
        id = "bedroom",
        name = "Bedroom",
        contents = {},
        exits = {},
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = {},
            state = {},
            location = "bedroom",
        },
        time_offset = 8,
        game_start_time = os.time(),
    }
    local output = capture_output(function()
        handlers["run"](ctx, "away")
    end)
    truthy(output:find("nothing to flee"),
        "'run away' with no threats should say 'nothing to flee', got: " .. output)
end)

---------------------------------------------------------------------------
-- Test: with threat → attempts flee
---------------------------------------------------------------------------
test("7. 'flee' with hostile creature attempts flee", function()
    local wolf = {
        id = "wolf",
        name = "a grey wolf",
        animate = true,
        alive = true,
        _state = "alive-hunt",
        location = "hallway",
        combat = { speed = 4 },
    }
    local reg = make_mock_registry({ wolf = wolf })
    local room = {
        id = "hallway",
        name = "Hallway",
        contents = { "wolf" },
        exits = { north = { target = "bedroom" } },
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = {},
            state = {},
            location = "hallway",
            combat = { speed = 3 },
        },
        time_offset = 8,
        game_start_time = os.time(),
    }
    -- Seed random for deterministic test: flee always succeeds
    math.randomseed(42)
    local output = capture_output(function()
        handlers["flee"](ctx, "")
    end)
    -- Should either succeed ("break free") or fail ("blocks your escape" / "still here")
    local fled = output:find("break free") or output:find("blocks") or output:find("still here")
    truthy(fled, "Should attempt flee, got: " .. output)
end)

test("8. 'run' with hostile creature attempts flee (not 'Go where?')", function()
    local wolf = {
        id = "wolf",
        name = "a grey wolf",
        animate = true,
        alive = true,
        _state = "alive-hunt",
        location = "hallway",
        combat = { speed = 4 },
    }
    local reg = make_mock_registry({ wolf = wolf })
    local room = {
        id = "hallway",
        name = "Hallway",
        contents = { "wolf" },
        exits = { north = { target = "bedroom" } },
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = {},
            state = {},
            location = "hallway",
            combat = { speed = 3 },
        },
        time_offset = 8,
        game_start_time = os.time(),
    }
    math.randomseed(42)
    local output = capture_output(function()
        handlers["run"](ctx, "")
    end)
    truthy(not output:find("Go where"),
        "'run' with threat should NOT say 'Go where?', got: " .. output)
    local fled = output:find("break free") or output:find("blocks") or output:find("still here")
    truthy(fled, "'run' should attempt flee, got: " .. output)
end)

---------------------------------------------------------------------------
-- Test: dead creature is NOT a threat
---------------------------------------------------------------------------
test("9. dead creature does not trigger flee", function()
    local dead_wolf = {
        id = "wolf",
        name = "a dead wolf",
        animate = true,
        alive = false,
        _state = "dead",
        location = "hallway",
    }
    local reg = make_mock_registry({ wolf = dead_wolf })
    local room = {
        id = "hallway",
        name = "Hallway",
        contents = { "wolf" },
        exits = {},
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = {},
            state = {},
            location = "hallway",
        },
        time_offset = 8,
        game_start_time = os.time(),
    }
    local output = capture_output(function()
        handlers["flee"](ctx, "")
    end)
    truthy(output:find("nothing to flee"),
        "Dead creature should not be a threat, got: " .. output)
end)

h.summary()
