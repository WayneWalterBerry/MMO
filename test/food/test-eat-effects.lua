-- test/food/test-eat-effects.lua
-- WAVE-3 TDD: Eat verb effects tests — health restoration from cooked food.
-- Tests cooked meat nutrition, health healing, effect narration, item removal.
-- Must be run from repository root: lua test/food/test-eat-effects.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load engine modules (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local consumption_ok, consumption = pcall(require, "engine.verbs.consumption")
if not consumption_ok then
    print("WARNING: engine.verbs.consumption not loadable — " .. tostring(consumption))
    consumption = nil
end

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------
local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[deep_copy(k)] = deep_copy(v) end
    return copy
end

---------------------------------------------------------------------------
-- Mock factory
---------------------------------------------------------------------------
local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid or obj.id] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:list()
        local result, seen = {}, {}
        for _, obj in pairs(self._objects) do
            local key = obj.guid or obj.id
            if not seen[key] then
                seen[key] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    reg.all = reg.list
    function reg:get(id)
        return self._objects[id] or nil
    end
    function reg:remove(id)
        local obj = self._objects[id]
        self._objects[id] = nil
        return obj
    end
    return reg
end

-- Cooked food factories (these objects don't exist yet — TDD stubs)
local function make_cooked_rat_meat()
    return {
        guid = "{cooked-rat-meat-001}",
        id = "cooked-rat-meat",
        template = "small-item",
        name = "cooked rat meat",
        keywords = {"cooked rat meat", "rat meat", "cooked meat", "meat"},
        description = "A charred hunk of rat meat. It smells surprisingly appetizing.",
        on_feel = "Warm and greasy.",
        on_smell = "Smoky, roasted meat.",
        on_taste = "Gamey but satisfying. The char adds a smoky depth.",
        on_listen = "Silent.",
        portable = true,
        size = "tiny",
        weight = 0.2,
        edible = true,
        food = {
            category = "meat",
            edible = true,
            nutrition = 15,
            effects = {
                { type = "narrate", message = "The rat meat is gamey but filling." },
                { type = "heal", amount = 3 },
            },
        },
    }
end

local function make_cooked_cat_meat()
    return {
        guid = "{cooked-cat-meat-001}",
        id = "cooked-cat-meat",
        template = "small-item",
        name = "cooked cat meat",
        keywords = {"cooked cat meat", "cat meat", "cooked meat", "meat"},
        description = "A dark slab of cat meat, charred at the edges.",
        on_feel = "Warm and slightly tough.",
        on_smell = "Rich roasted meat.",
        on_taste = "Dark and rich, with a slightly wild flavor.",
        on_listen = "Silent.",
        portable = true,
        size = "small",
        weight = 0.8,
        edible = true,
        food = {
            category = "meat",
            edible = true,
            nutrition = 20,
            effects = {
                { type = "narrate", message = "The cat meat is dark and rich." },
                { type = "heal", amount = 4 },
            },
        },
    }
end

local function make_cooked_bat_meat()
    return {
        guid = "{cooked-bat-meat-001}",
        id = "cooked-bat-meat",
        template = "small-item",
        name = "cooked bat meat",
        keywords = {"cooked bat meat", "bat meat", "cooked meat", "meat"},
        description = "Thin strips of bat meat, singed and crispy.",
        on_feel = "Crispy and light.",
        on_smell = "Slightly acrid, smoky.",
        on_taste = "Thin and stringy with a musky aftertaste.",
        on_listen = "Silent.",
        portable = true,
        size = "tiny",
        weight = 0.1,
        edible = true,
        food = {
            category = "meat",
            edible = true,
            nutrition = 10,
            effects = {
                { type = "narrate", message = "The bat meat is thin but edible." },
                { type = "heal", amount = 2 },
                { type = "inflict_injury", injury = "food-poisoning", chance = 0.10 },
            },
        },
    }
end

local function make_flatbread()
    return {
        guid = "{flatbread-001}",
        id = "flatbread",
        template = "small-item",
        name = "a flatbread",
        keywords = {"flatbread", "bread", "flat bread"},
        description = "A rough disc of flatbread, browned and firm.",
        on_feel = "Warm and firm, slightly crumbly at the edges.",
        on_smell = "Toasted grain.",
        on_taste = "Bland but filling. The charred edges add a slight bitterness.",
        on_listen = "Silent.",
        portable = true,
        size = "tiny",
        weight = 0.15,
        edible = true,
        food = {
            category = "grain",
            edible = true,
            nutrition = 10,
            effects = {
                { type = "narrate", message = "The flatbread is dry but filling." },
                { type = "heal", amount = 1 },
            },
        },
    }
end

local function make_non_food()
    return {
        guid = "{test-rock-eat}",
        id = "test-rock",
        template = "small-item",
        name = "a rock",
        keywords = {"rock", "stone"},
        description = "A plain rock.",
        on_feel = "Cold and rough.",
        edible = false,
        size = 1,
        weight = 1.0,
        portable = true,
    }
end

local function make_context(opts)
    opts = opts or {}
    local room_id = opts.room_id or "test-room"
    local room = {
        id = room_id,
        name = "Test Room",
        template = "room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = {},
    }
    local all_objects = {}
    for _, obj in ipairs(opts.objects or {}) do
        all_objects[#all_objects + 1] = obj
    end
    local registry = make_mock_registry(all_objects)
    return {
        registry = registry,
        rooms = { [room_id] = room },
        current_room = room,
        player = opts.player or {
            id = "player",
            name = "the player",
            location = room_id,
            hands = opts.hands or { nil, nil },
            health = opts.health or 80,
            max_health = 100,
            injuries = opts.injuries or {},
            _state = "alive",
            nutrition = opts.nutrition or 0,
        },
        game_start_time = opts.game_start_time or os.time(),
        headless = true,
        shown_hints = opts.shown_hints or {},
    }
end

---------------------------------------------------------------------------
-- Register verb handlers
---------------------------------------------------------------------------
local handlers = {}
if consumption and consumption.register then
    local reg_ok, reg_err = pcall(consumption.register, handlers)
    if not reg_ok then
        print("WARNING: consumption.register failed — " .. tostring(reg_err))
    end
end

---------------------------------------------------------------------------
-- SUITE 1: Cooked food health effects
---------------------------------------------------------------------------
suite("EAT EFFECTS: cooked food healing (WAVE-3)")

test("1. cooked-rat-meat food.effects declares heal +3", function()
    local meat = make_cooked_rat_meat()
    h.assert_truthy(meat.food, "cooked-rat-meat must have food table")
    h.assert_truthy(meat.food.effects, "cooked-rat-meat must have food.effects")
    local heal_found = false
    for _, eff in ipairs(meat.food.effects) do
        if eff.type == "heal" and eff.amount == 3 then
            heal_found = true; break
        end
    end
    h.assert_truthy(heal_found, "cooked-rat-meat must have heal effect with amount=3")
end)

test("2. cooked-cat-meat food.effects declares heal +4", function()
    local meat = make_cooked_cat_meat()
    h.assert_truthy(meat.food.effects, "cooked-cat-meat must have food.effects")
    local heal_found = false
    for _, eff in ipairs(meat.food.effects) do
        if eff.type == "heal" and eff.amount == 4 then
            heal_found = true; break
        end
    end
    h.assert_truthy(heal_found, "cooked-cat-meat must have heal effect with amount=4")
end)

test("3. cooked-bat-meat food.effects declares heal +2 and food-poisoning risk", function()
    local meat = make_cooked_bat_meat()
    h.assert_truthy(meat.food.effects, "cooked-bat-meat must have food.effects")
    local heal_found = false
    local poison_found = false
    for _, eff in ipairs(meat.food.effects) do
        if eff.type == "heal" and eff.amount == 2 then
            heal_found = true
        end
        if eff.type == "inflict_injury" and eff.injury == "food-poisoning" then
            poison_found = true
            h.assert_eq(0.10, eff.chance,
                "bat meat food-poisoning chance must be 10%")
        end
    end
    h.assert_truthy(heal_found, "cooked-bat-meat must have heal effect with amount=2")
    h.assert_truthy(poison_found, "cooked-bat-meat must have food-poisoning risk")
end)

test("4. flatbread food.effects declares heal +1", function()
    local bread = make_flatbread()
    h.assert_truthy(bread.food.effects, "flatbread must have food.effects")
    local heal_found = false
    for _, eff in ipairs(bread.food.effects) do
        if eff.type == "heal" and eff.amount == 1 then
            heal_found = true; break
        end
    end
    h.assert_truthy(heal_found, "flatbread must have heal effect with amount=1")
end)

---------------------------------------------------------------------------
-- SUITE 2: Food effects narration
---------------------------------------------------------------------------
suite("EAT EFFECTS: narration (WAVE-3)")

test("5. cooked-rat-meat effects include narrate message", function()
    local meat = make_cooked_rat_meat()
    local narrate_found = false
    for _, eff in ipairs(meat.food.effects) do
        if eff.type == "narrate" and eff.message then
            narrate_found = true; break
        end
    end
    h.assert_truthy(narrate_found, "cooked-rat-meat must have narrate effect")
end)

test("6. flatbread effects include narrate message", function()
    local bread = make_flatbread()
    local narrate_found = false
    for _, eff in ipairs(bread.food.effects) do
        if eff.type == "narrate" and eff.message then
            narrate_found = true; break
        end
    end
    h.assert_truthy(narrate_found, "flatbread must have narrate effect")
end)

---------------------------------------------------------------------------
-- SUITE 3: Eat removes item from inventory
---------------------------------------------------------------------------
suite("EAT EFFECTS: item removal (WAVE-3)")

test("7. eat handler registered", function()
    h.assert_truthy(handlers["eat"], "eat handler must be registered")
end)

test("8. eating cooked food removes from registry", function()
    if not handlers["eat"] then
        error("eat handler not registered (TDD)")
    end

    local meat = make_cooked_rat_meat()
    local ctx = make_context({
        objects = { meat },
        hands = { meat, nil },
    })

    h.assert_truthy(ctx.registry:get("cooked-rat-meat"),
        "cooked-rat-meat must be in registry before eating")

    local _print = print
    print = function() end
    handlers["eat"](ctx, "cooked rat meat")
    print = _print

    h.assert_nil(ctx.registry:get("cooked-rat-meat"),
        "cooked-rat-meat must be removed from registry after eating")
end)

test("9. eating flatbread removes from registry", function()
    if not handlers["eat"] then
        error("eat handler not registered (TDD)")
    end

    local bread = make_flatbread()
    local ctx = make_context({
        objects = { bread },
        hands = { bread, nil },
    })

    local _print = print
    print = function() end
    handlers["eat"](ctx, "flatbread")
    print = _print

    h.assert_nil(ctx.registry:get("flatbread"),
        "flatbread must be removed from registry after eating")
end)

test("10. eating applies nutrition to player", function()
    if not handlers["eat"] then
        error("eat handler not registered (TDD)")
    end

    local meat = make_cooked_rat_meat()
    local ctx = make_context({
        objects = { meat },
        hands = { meat, nil },
        nutrition = 0,
    })

    local _print = print
    print = function() end
    handlers["eat"](ctx, "cooked rat meat")
    print = _print

    h.assert_eq(15, ctx.player.nutrition,
        "eating cooked-rat-meat must add 15 nutrition")
end)

---------------------------------------------------------------------------
-- SUITE 4: Eat non-food rejection
---------------------------------------------------------------------------
suite("EAT EFFECTS: non-food rejection (WAVE-3)")

test("11. eat non-food item rejected", function()
    if not handlers["eat"] then
        error("eat handler not registered (TDD)")
    end

    local rock = make_non_food()
    local ctx = make_context({
        objects = { rock },
        hands = { rock, nil },
    })

    local output = {}
    local _print = print
    print = function(s) output[#output + 1] = s end
    handlers["eat"](ctx, "rock")
    print = _print

    local found_reject = false
    for _, line in ipairs(output) do
        if line:lower():find("can't eat") or line:lower():find("cannot eat") then
            found_reject = true; break
        end
    end
    h.assert_truthy(found_reject,
        "eat non-food item must print rejection message")
end)

test("12. eat on_taste text emitted for cooked food", function()
    if not handlers["eat"] then
        error("eat handler not registered (TDD)")
    end

    local meat = make_cooked_rat_meat()
    local ctx = make_context({
        objects = { meat },
        hands = { meat, nil },
    })

    local output = {}
    local _print = print
    print = function(s) output[#output + 1] = s end
    handlers["eat"](ctx, "cooked rat meat")
    print = _print

    local found_taste = false
    for _, line in ipairs(output) do
        if line:find("Gamey") or line:find("smoky") then
            found_taste = true; break
        end
    end
    h.assert_truthy(found_taste,
        "on_taste text must be printed when eating cooked food")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
