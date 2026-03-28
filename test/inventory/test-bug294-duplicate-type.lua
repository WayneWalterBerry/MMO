-- test/inventory/test-bug294-duplicate-type.lua
-- Regression tests for bug #294: Can't hold two items of same type.
-- The take system compared obj.id (base type) instead of object identity,
-- blocking players from holding two different instances of the same template
-- (e.g., two silk-bundles needed for silk-rope crafting).
--
-- Usage: lua test/inventory/test-bug294-duplicate-type.lua

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
local registry_mod = require("engine.registry")

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
    }
end

---------------------------------------------------------------------------
-- BUG #294: Take two different instances of same type
---------------------------------------------------------------------------
suite("Bug #294 — take two items of same type")

test("1. second silk-bundle on floor can be taken when first is in hand", function()
    local bundle1 = {
        id = "silk-bundle-loot-1",
        guid = "{aaa-111}",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        portable = true,
        size = "small",
        weight = 0.2,
        location = "player",
        on_feel = "Sticky strands.",
    }
    local bundle2 = {
        id = "silk-bundle-loot-2",
        guid = "{bbb-222}",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        portable = true,
        size = "small",
        weight = 0.2,
        location = "cellar",
        on_feel = "Sticky strands.",
    }
    local reg = make_mock_registry({
        ["silk-bundle-loot-1"] = bundle1,
        ["silk-bundle-loot-2"] = bundle2,
    })
    local room = {
        id = "cellar",
        name = "Cellar",
        contents = { "silk-bundle-loot-2" },
        exits = {},
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { bundle1, nil },
            worn = {},
            state = {},
            location = "cellar",
        },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
    local output = capture_output(function()
        handlers["take"](ctx, "silk bundle")
    end)
    truthy(output:find("You take"),
        "Should take second silk-bundle, got: " .. output)
    truthy(not output:find("already have"),
        "Should NOT say 'already have', got: " .. output)
    truthy(ctx.player.hands[2] ~= nil,
        "Second hand should now hold the bundle")
end)

test("2. exact same object in hand IS correctly blocked", function()
    local bundle = {
        id = "silk-bundle-loot-1",
        guid = "{aaa-111}",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        portable = true,
        size = "small",
        weight = 0.2,
        location = "player",
        on_feel = "Sticky strands.",
    }
    local reg = make_mock_registry({
        ["silk-bundle-loot-1"] = bundle,
    })
    local room = {
        id = "cellar",
        name = "Cellar",
        contents = { "silk-bundle-loot-1" },
        exits = {},
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { bundle, nil },
            worn = {},
            state = {},
            location = "cellar",
        },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
    local output = capture_output(function()
        handlers["take"](ctx, "silk bundle")
    end)
    truthy(output:find("already have"),
        "Should say 'already have' for the SAME object, got: " .. output)
end)

test("3. two items with same base id (no loot suffix) can both be taken", function()
    local bandage1 = {
        id = "silk-bandage",
        guid = "{ccc-333}",
        name = "a silk bandage",
        keywords = {"silk bandage", "bandage"},
        portable = true,
        size = "small",
        weight = 0.1,
        location = "player",
        on_feel = "Soft silk strips.",
    }
    local bandage2 = {
        id = "silk-bandage-2",
        guid = "{ddd-444}",
        name = "a silk bandage",
        keywords = {"silk bandage", "bandage"},
        portable = true,
        size = "small",
        weight = 0.1,
        location = "cellar",
        on_feel = "Soft silk strips.",
    }
    local reg = make_mock_registry({
        ["silk-bandage"] = bandage1,
        ["silk-bandage-2"] = bandage2,
    })
    local room = {
        id = "cellar",
        name = "Cellar",
        contents = { "silk-bandage-2" },
        exits = {},
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { bandage1, nil },
            worn = {},
            state = {},
            location = "cellar",
        },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
    local output = capture_output(function()
        handlers["take"](ctx, "bandage")
    end)
    truthy(output:find("You take"),
        "Should take second bandage, got: " .. output)
    truthy(not output:find("already have"),
        "Should NOT say 'already have' for a different instance, got: " .. output)
end)

test("4. worn item of same type does not block floor take", function()
    local cloak1 = {
        id = "wool-cloak",
        guid = "{eee-555}",
        name = "a wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true,
        size = "medium",
        weight = 1.0,
        location = "player",
        wearable = true,
        on_feel = "Scratchy wool.",
    }
    local cloak2 = {
        id = "wool-cloak-2",
        guid = "{fff-666}",
        name = "a wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true,
        size = "medium",
        weight = 1.0,
        location = "cellar",
        wearable = true,
        on_feel = "Scratchy wool.",
    }
    local reg = make_mock_registry({
        ["wool-cloak"] = cloak1,
        ["wool-cloak-2"] = cloak2,
    })
    local room = {
        id = "cellar",
        name = "Cellar",
        contents = { "wool-cloak-2" },
        exits = {},
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = { "wool-cloak" },
            state = {},
            location = "cellar",
        },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
    local output = capture_output(function()
        handlers["take"](ctx, "cloak")
    end)
    truthy(output:find("You take"),
        "Should take second cloak from floor, got: " .. output)
    truthy(not output:find("wearing"),
        "Should NOT say 'wearing' for a different cloak, got: " .. output)
end)

test("5. registry collision: same-id item in hand blocks re-take (identity check)", function()
    -- Simulate registry collision: both items share id "silk-bundle"
    -- but the registry can only store one. After taking it, the room still
    -- lists the id. The take handler should recognize the same TABLE and block.
    local bundle = {
        id = "silk-bundle",
        guid = "{aaa-111}",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        portable = true,
        size = "small",
        weight = 0.2,
        location = "player",
        on_feel = "Sticky strands.",
    }
    local reg = make_mock_registry({
        ["silk-bundle"] = bundle,
    })
    local room = {
        id = "cellar",
        name = "Cellar",
        contents = { "silk-bundle" },
        exits = {},
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { bundle, nil },
            worn = {},
            state = {},
            location = "cellar",
        },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
    local output = capture_output(function()
        handlers["take"](ctx, "silk bundle")
    end)
    truthy(output:find("already have"),
        "Same object (table identity) should say 'already have', got: " .. output)
end)

h.summary()
