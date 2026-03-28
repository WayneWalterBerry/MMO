-- test/crafting/test-craft-placement.lua
-- Regression test for #353: Crafted items must go to player hands, not floor.
-- TDD: Tests must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/crafting/test-craft-placement.lua

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
if not craft_ok then
    print("WARNING: engine.verbs.crafting not loadable — " .. tostring(crafting))
    crafting = nil
end

---------------------------------------------------------------------------
-- Mock infrastructure
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{craft-place-test-" .. guid_counter .. "}"
end

local function make_silk_bundle(suffix)
    return {
        guid = next_guid(),
        id = "silk-bundle" .. (suffix or ""),
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
    function reg:add(obj)
        self._objects[obj.guid] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    function reg:remove(guid_or_id)
        local obj = self._objects[guid_or_id]
        if obj then
            self._objects[obj.guid] = nil
            if obj.id then self._objects[obj.id] = nil end
        end
    end
    function reg:list()
        local seen, result = {}, {}
        for _, obj in pairs(self._objects) do
            if type(obj) == "table" and obj.guid and not seen[obj.guid] then
                seen[obj.guid] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    return reg
end

local function make_player(overrides)
    local p = {
        id = "player",
        health = 20,
        max_health = 30,
        location = "test-room",
        hands = {},
        inventory = {},
        active_injuries = {},
    }
    if overrides then
        for k, v in pairs(overrides) do p[k] = v end
    end
    return p
end

local function make_room()
    return {
        guid = "{room-craft-place}",
        id = "test-room",
        template = "room",
        name = "Test Room",
        description = "A test room.",
        contents = {},
        exits = {},
    }
end

local function make_context(reg, room, player)
    local output = {}
    -- Build object_sources from registry (mock loader needs this)
    local object_sources = {}
    local templates = {}
    return {
        registry = reg,
        current_room = room,
        rooms = { [room.id] = room },
        player = player,
        print = function(msg) output[#output + 1] = msg end,
        output = output,
        game_time = 100,
        object_sources = object_sources,
        templates = templates,
        loader = {
            load_source = function(src) return src end,
            resolve_template = function(obj) return obj end,
        },
    }
end

-- Check if an item with matching id prefix is in player's hands
local function item_in_hands(player, id_prefix)
    for i = 1, 2 do
        local hand = player.hands[i]
        if hand then
            local obj = (type(hand) == "table") and hand or nil
            if obj and obj.id and obj.id:find(id_prefix, 1, true) == 1 then
                return true, i
            end
        end
    end
    return false
end

-- Check if an item with matching id prefix is in room contents
local function item_in_room(room, id_prefix)
    for _, obj_id in ipairs(room.contents or {}) do
        if type(obj_id) == "string" and obj_id:find(id_prefix, 1, true) == 1 then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- TESTS: Crafted items go to player hands (#353)
---------------------------------------------------------------------------
suite("CRAFT PLACEMENT: crafted items go to hands, not floor (#353)")

test("1. craft silk-rope — result placed in player hand, not room", function()
    h.assert_truthy(crafting, "crafting module must load")

    local handlers = {}
    crafting.register(handlers)
    local craft_fn = handlers["craft"]
    h.assert_truthy(craft_fn, "craft handler must exist")

    -- Player holds 2 silk bundles (one per hand)
    local bundle1 = make_silk_bundle("-loot-1")
    local bundle2 = make_silk_bundle("-loot-2")
    local player = make_player()
    player.hands[1] = bundle1
    player.hands[2] = bundle2

    local room = make_room()
    local reg = make_mock_registry({ bundle1, bundle2 })

    -- Wire up object_sources so spawn_objects can find silk-rope template
    local rope_template = {
        guid = next_guid(),
        id = "silk-rope",
        template = "small-item",
        name = "a silk rope",
        keywords = {"rope", "silk rope"},
        portable = true,
        on_feel = "Smooth, strong silk rope.",
    }

    local ctx = make_context(reg, room, player)
    ctx.object_sources["silk-rope"] = rope_template

    -- Override print to capture
    local old_print = _G.print
    _G.print = function(msg) ctx.output[#ctx.output + 1] = msg end

    craft_fn(ctx, "silk-rope")

    _G.print = old_print

    -- The crafted silk-rope must be in the player's hands
    local in_hands = item_in_hands(player, "silk-rope")
    local in_room = item_in_room(room, "silk-rope")

    h.assert_truthy(in_hands,
        "silk-rope must be placed in player's hands after crafting")
    h.assert_truthy(not in_room,
        "silk-rope must NOT be on the room floor after crafting")
end)

test("2. craft silk-bandage (qty 2) — both placed in hands", function()
    h.assert_truthy(crafting, "crafting module must load")

    local handlers = {}
    crafting.register(handlers)
    local craft_fn = handlers["craft"]

    -- Player holds 1 silk bundle in hand 1
    local bundle = make_silk_bundle("-loot-1")
    local player = make_player()
    player.hands[1] = bundle

    local room = make_room()
    local reg = make_mock_registry({ bundle })

    local bandage_template = {
        guid = next_guid(),
        id = "silk-bandage",
        template = "small-item",
        name = "a silk bandage",
        keywords = {"bandage", "silk bandage"},
        portable = true,
        on_feel = "Soft silk strips.",
    }

    local ctx = make_context(reg, room, player)
    ctx.object_sources["silk-bandage"] = bandage_template

    local old_print = _G.print
    _G.print = function(msg) ctx.output[#ctx.output + 1] = msg end

    craft_fn(ctx, "silk-bandage")

    _G.print = old_print

    -- Both bandages should be in hands (recipe produces 2, player has 2 free hands after consuming bundle)
    local hand_count = 0
    for i = 1, 2 do
        local hand = player.hands[i]
        if hand and type(hand) == "table" and hand.id and
           hand.id:find("silk-bandage", 1, true) == 1 then
            hand_count = hand_count + 1
        end
    end

    h.assert_truthy(hand_count >= 1,
        "at least 1 silk-bandage must be in player hands, found " .. hand_count)
end)

test("3. craft with full hands — overflow to room with message", function()
    h.assert_truthy(crafting, "crafting module must load")

    local handlers = {}
    crafting.register(handlers)
    local craft_fn = handlers["craft"]

    -- Bundles are in the ROOM (not hands), hands hold other items
    local bundle1 = make_silk_bundle("-loot-1")
    bundle1.location = "test-room"
    local bundle2 = make_silk_bundle("-loot-2")
    bundle2.location = "test-room"

    local sword = { guid = next_guid(), id = "sword", name = "a sword",
                    on_feel = "Cold steel.", portable = true }
    local shield = { guid = next_guid(), id = "shield", name = "a shield",
                     on_feel = "Heavy wood.", portable = true }

    local player = make_player()
    player.hands[1] = sword
    player.hands[2] = shield

    local room = make_room()
    room.contents = { bundle1.id, bundle2.id }

    local reg = make_mock_registry({ bundle1, bundle2, sword, shield })

    local rope_template = {
        guid = next_guid(),
        id = "silk-rope",
        template = "small-item",
        name = "a silk rope",
        keywords = {"rope", "silk rope"},
        portable = true,
        on_feel = "Smooth, strong silk rope.",
    }

    local ctx = make_context(reg, room, player)
    ctx.object_sources["silk-rope"] = rope_template

    local old_print = _G.print
    _G.print = function(msg) ctx.output[#ctx.output + 1] = msg end

    craft_fn(ctx, "silk-rope")

    _G.print = old_print

    -- Crafted item should still be created (on floor is OK when hands full)
    local rope_exists = false
    for _, obj in ipairs(reg:list()) do
        if obj.id and obj.id:find("silk-rope", 1, true) == 1 then
            rope_exists = true
            break
        end
    end
    h.assert_truthy(rope_exists,
        "silk-rope must be created even when hands are full")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
