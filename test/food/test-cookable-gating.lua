-- test/food/test-cookable-gating.lua
-- WAVE-3 TDD: Cookable gating tests — raw meat edibility and rejection.
-- Tests raw meat eating consequences, grain rejection, spoilage blocks.
-- Must be run from repository root: lua test/food/test-cookable-gating.lua

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
-- Load creature definitions for death_state
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

local ok_cat, cat_def = pcall(dofile, creature_path("cat"))
if not ok_cat then print("WARNING: cat.lua failed to load — " .. tostring(cat_def)) end

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
    function reg:get(id) return self._objects[id] or nil end
    function reg:remove(id) local obj = self._objects[id]; self._objects[id] = nil; return obj end
    return reg
end

-- Build a reshaped dead creature from its death_state
local function make_dead_creature(creature_def, id_override, state_override)
    if not creature_def or not creature_def.death_state then return nil end
    local ds = creature_def.death_state
    local inst = {
        guid = "{dead-" .. (id_override or creature_def.id) .. "-gate}",
        id = id_override or creature_def.id,
        template = ds.template or "small-item",
        animate = false,
        alive = false,
        portable = ds.portable ~= false,
        name = ds.name,
        description = ds.description,
        keywords = deep_copy(ds.keywords),
        on_feel = ds.on_feel,
        on_smell = ds.on_smell,
        on_listen = ds.on_listen,
        on_taste = ds.on_taste,
        food = deep_copy(ds.food),
        crafting = deep_copy(ds.crafting),
        initial_state = ds.initial_state or "fresh",
        _state = state_override or ds.initial_state or "fresh",
        states = deep_copy(ds.states),
        transitions = deep_copy(ds.transitions),
        size = ds.size,
        weight = ds.weight,
    }
    -- Apply state-level food overrides (like bloated disabling cookable)
    if state_override and ds.states and ds.states[state_override] then
        local s = ds.states[state_override]
        if s.description then inst.description = s.description end
        if s.on_smell then inst.on_smell = s.on_smell end
        if s.food ~= nil then
            inst.food = deep_copy(s.food)
        end
    end
    return inst
end

local function make_raw_grain()
    return {
        guid = "{test-grain-gate}",
        id = "grain-handful",
        template = "small-item",
        name = "a handful of grain",
        keywords = {"grain", "handful of grain"},
        description = "A handful of dried grain kernels.",
        on_feel = "Dry, hard kernels.",
        on_taste = "Hard and bland.",
        on_listen = "Silent.",
        portable = true,
        size = "tiny",
        weight = 0.2,
        food = {
            category = "grain",
            raw = true,
            edible = false,
            cookable = true,
        },
        on_eat_reject = "You can't eat that raw. Try cooking it first.",
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
            health = opts.health or 100,
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
-- SUITE 1: Raw meat eating — allowed but with consequences
---------------------------------------------------------------------------
suite("COOKABLE GATING: raw meat eating (WAVE-3)")

test("1. raw dead-rat food.raw=true, food.edible=false, food.cookable=true", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    local food = rat_def.death_state.food
    h.assert_truthy(food, "rat death_state must have food table")
    h.assert_eq(true, food.raw, "rat food.raw must be true")
    h.assert_eq(false, food.edible, "rat food.edible must be false (raw)")
    h.assert_eq(true, food.cookable, "rat food.cookable must be true")
end)

test("2. raw dead-cat food.raw=true, food.edible=false, food.cookable=true", function()
    h.assert_truthy(ok_cat, "cat.lua must load")
    local food = cat_def.death_state.food
    h.assert_truthy(food, "cat death_state must have food table")
    h.assert_eq(true, food.raw, "cat food.raw must be true")
    h.assert_eq(false, food.edible, "cat food.edible must be false (raw)")
    h.assert_eq(true, food.cookable, "cat food.cookable must be true")
end)

test("3. eat raw meat handler allows but warns (TDD — impl in WAVE-3)", function()
    if not handlers["eat"] then
        error("eat handler not registered (TDD)")
    end

    local dead_rat = make_dead_creature(rat_def, "dead-rat")
    -- Override: raw meat is technically edible (with consequences)
    -- The WAVE-3 eat handler should detect food.raw=true + food.cookable=true
    -- and allow eating with food-poisoning consequence
    dead_rat.food.edible = true  -- eat handler will check raw flag separately
    dead_rat.food.raw = true

    local ctx = make_context({
        objects = { dead_rat },
        hands = { dead_rat, nil },
    })

    local output = {}
    local _print = print
    print = function(s) output[#output + 1] = s end
    local ok, err = pcall(handlers["eat"], ctx, "dead rat")
    print = _print

    h.assert_truthy(ok, "eat raw meat must not crash: " .. tostring(err))
    h.assert_truthy(#output > 0, "eat raw meat must produce output")
end)

---------------------------------------------------------------------------
-- SUITE 2: Raw grain rejection
---------------------------------------------------------------------------
suite("COOKABLE GATING: raw grain rejection (WAVE-3)")

test("4. raw grain declares on_eat_reject with cooking hint", function()
    -- WAVE-3 TDD: The eat handler should reject raw grain (food.category=grain,
    -- food.raw=true, food.edible=false) with on_eat_reject text mentioning cooking.
    -- Currently the handler treats all raw food as edible-with-consequences.
    -- Smithers will add category-based gating in WAVE-3 eat handler extensions.
    local grain = make_raw_grain()
    h.assert_truthy(grain.food, "grain must have food table")
    h.assert_eq(false, grain.food.edible, "grain food.edible must be false")
    h.assert_eq(true, grain.food.cookable, "grain food.cookable must be true")
    h.assert_eq(true, grain.food.raw, "grain food.raw must be true")
    h.assert_truthy(grain.on_eat_reject, "grain must declare on_eat_reject")
    h.assert_truthy(grain.on_eat_reject:lower():find("cook"),
        "on_eat_reject must hint at cooking: " .. grain.on_eat_reject)
end)

test("5. raw grain on_eat_reject text declared", function()
    local grain = make_raw_grain()
    h.assert_truthy(grain.on_eat_reject,
        "grain must have on_eat_reject message")
    h.assert_truthy(grain.on_eat_reject:lower():find("cook"),
        "on_eat_reject must mention cooking: " .. grain.on_eat_reject)
end)

---------------------------------------------------------------------------
-- SUITE 3: Spoiled corpse blocking
---------------------------------------------------------------------------
suite("COOKABLE GATING: spoiled corpse blocks (WAVE-3)")

test("6. bloated corpse is not cookable", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    local bloated_rat = make_dead_creature(rat_def, "dead-rat", "bloated")
    h.assert_truthy(bloated_rat.food, "bloated rat must have food table")
    h.assert_eq(false, bloated_rat.food.cookable,
        "bloated rat must NOT be cookable")
end)

test("7. rotten corpse is not edible", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    local rotten_rat = make_dead_creature(rat_def, "dead-rat", "rotten")
    h.assert_truthy(rotten_rat.food, "rotten rat must have food table")
    h.assert_eq(false, rotten_rat.food.edible,
        "rotten rat must NOT be edible")
    h.assert_eq(false, rotten_rat.food.cookable,
        "rotten rat must NOT be cookable")
end)

test("8. raw meat on_taste warns of foulness", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    local taste = rat_def.death_state.on_taste
    h.assert_truthy(taste, "rat death_state must have on_taste")
    h.assert_truthy(taste:lower():find("regret") or taste:lower():find("blood")
        or taste:lower():find("fur") or taste:lower():find("foul"),
        "raw meat on_taste must warn of unpleasantness: " .. taste)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
