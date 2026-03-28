-- test/crafting/test-bug303-floor-ingredients.lua
-- Bug #303: Craft system doesn't find ingredients on room floor.
-- Root cause: the `dominated` check uses c.id == obj.id which prevents
-- finding a second instance of the same ingredient type after the first
-- is already consumed. Fix: only use guid comparison.
-- TDD: Must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/crafting/test-bug303-floor-ingredients.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load crafting module
---------------------------------------------------------------------------
local craft_ok, crafting = pcall(require, "engine.verbs.crafting")
h.assert_truthy(craft_ok, "crafting module must load: " .. tostring(crafting))

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{bug303-" .. guid_counter .. "}"
end

local function make_silk_bundle(guid_suffix)
    return {
        guid = next_guid(),
        id = "silk-bundle",
        template = "small-item",
        name = "a bundle of spider silk",
        keywords = {"silk", "silk bundle", "bundle"},
        material = "silk",
        portable = true,
        on_feel = "Soft, fine threads bundled together.",
    }
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] end
    function reg:register(id, obj)
        self._objects[id] = obj
        if obj.guid then self._objects[obj.guid] = obj end
    end
    function reg:remove(id)
        local obj = self._objects[id]
        if obj then
            self._objects[id] = nil
            if obj.guid then self._objects[obj.guid] = nil end
            if obj.id and obj.id ~= id then self._objects[obj.id] = nil end
        end
    end
    function reg:list()
        local r = {}
        local seen = {}
        for _, obj in pairs(self._objects) do
            if type(obj) == "table" and not seen[obj] then
                seen[obj] = true
                r[#r + 1] = obj
            end
        end
        return r
    end
    return reg
end

local function make_room()
    return {
        id = "test-room",
        name = "Test Room",
        description = "A room.",
        contents = {},
        exits = {},
    }
end

local function make_player()
    return {
        hands = { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
        skills = {},
        max_health = 100,
        consciousness = { state = "conscious" },
        visited_rooms = { ["test-room"] = true },
    }
end

local function make_context(reg, room, player)
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 6,
        game_start_time = os.time(),
        current_verb = "craft",
        known_objects = {},
        last_object = nil,
        headless = true,
        output = {},
        loader = {
            load_source = function(src) return src end,
            resolve_template = function(obj) return obj end,
        },
        object_sources = {},
        templates = {},
    }
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #303: Craft finds ingredients on room floor")

test("1. two same-id silk-bundles on floor — craft succeeds", function()
    local handlers = {}
    crafting.register(handlers)
    local craft_fn = handlers["craft"]
    h.assert_truthy(craft_fn, "craft handler must exist")

    -- Two silk-bundles with SAME id but different guids on the floor
    local bundle1 = make_silk_bundle()
    bundle1.location = "test-room"
    local bundle2 = make_silk_bundle()
    bundle2.location = "test-room"

    h.assert_eq(bundle1.id, bundle2.id, "both bundles must have same id")
    h.assert_truthy(bundle1.guid ~= bundle2.guid, "bundles must have different guids")

    local player = make_player()
    local room = make_room()
    room.contents = { bundle1.guid, bundle2.guid }

    local reg = make_mock_registry({ bundle1, bundle2 })
    local ctx = make_context(reg, room, player)

    local old_print = _G.print
    local output = {}
    _G.print = function(msg) output[#output + 1] = tostring(msg) end

    craft_fn(ctx, "silk-rope")

    _G.print = old_print

    local out_str = table.concat(output, "\n")
    -- Should NOT say "don't have enough"
    h.assert_truthy(not out_str:find("don't have enough"),
        "craft must NOT fail with 'don't have enough' when 2 bundles on floor, got: " ..
        out_str:sub(1, 200))
    -- Should print the narration (success)
    h.assert_truthy(out_str:find("twist") or out_str:find("rope") or out_str:find("silk"),
        "craft must succeed and print narration, got: " .. out_str:sub(1, 200))
end)

test("2. one bundle in hand + one on floor — craft succeeds", function()
    local handlers = {}
    crafting.register(handlers)
    local craft_fn = handlers["craft"]

    local bundle1 = make_silk_bundle()
    bundle1.location = "player"
    local bundle2 = make_silk_bundle()
    bundle2.location = "test-room"

    local player = make_player()
    player.hands[1] = bundle1

    local room = make_room()
    room.contents = { bundle2.guid }

    local reg = make_mock_registry({ bundle1, bundle2 })
    local ctx = make_context(reg, room, player)

    local old_print = _G.print
    local output = {}
    _G.print = function(msg) output[#output + 1] = tostring(msg) end

    craft_fn(ctx, "silk-rope")

    _G.print = old_print

    local out_str = table.concat(output, "\n")
    h.assert_truthy(not out_str:find("don't have enough"),
        "one hand + one floor must succeed, got: " .. out_str:sub(1, 200))
end)

test("3. both bundles in hands — craft succeeds", function()
    local handlers = {}
    crafting.register(handlers)
    local craft_fn = handlers["craft"]

    local bundle1 = make_silk_bundle()
    bundle1.location = "player"
    local bundle2 = make_silk_bundle()
    bundle2.location = "player"

    local player = make_player()
    player.hands[1] = bundle1
    player.hands[2] = bundle2

    local room = make_room()

    local reg = make_mock_registry({ bundle1, bundle2 })
    local ctx = make_context(reg, room, player)

    local old_print = _G.print
    local output = {}
    _G.print = function(msg) output[#output + 1] = tostring(msg) end

    craft_fn(ctx, "silk-rope")

    _G.print = old_print

    local out_str = table.concat(output, "\n")
    h.assert_truthy(not out_str:find("don't have enough"),
        "both in hands must succeed, got: " .. out_str:sub(1, 200))
end)

test("4. only one bundle available — craft fails correctly", function()
    local handlers = {}
    crafting.register(handlers)
    local craft_fn = handlers["craft"]

    local bundle1 = make_silk_bundle()
    bundle1.location = "test-room"

    local player = make_player()
    local room = make_room()
    room.contents = { bundle1.guid }

    local reg = make_mock_registry({ bundle1 })
    local ctx = make_context(reg, room, player)

    local old_print = _G.print
    local output = {}
    _G.print = function(msg) output[#output + 1] = tostring(msg) end

    craft_fn(ctx, "silk-rope")

    _G.print = old_print

    local out_str = table.concat(output, "\n")
    h.assert_truthy(out_str:find("don't have enough"),
        "with only 1 bundle, craft must fail, got: " .. out_str:sub(1, 200))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
