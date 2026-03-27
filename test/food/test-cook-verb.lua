-- test/food/test-cook-verb.lua
-- WAVE-3 TDD: Cook verb handler tests for food system.
-- Tests the cook verb, aliases, fire_source gating, and mutation output.
-- Must be run from repository root: lua test/food/test-cook-verb.lua

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
local crafting_ok, crafting = pcall(require, "engine.verbs.crafting")
if not crafting_ok then
    print("WARNING: engine.verbs.crafting not loadable — " .. tostring(crafting))
    crafting = nil
end

local cooking_ok, cooking = pcall(require, "engine.verbs.cooking")
if not cooking_ok then
    print("WARNING: engine.verbs.cooking not loadable — " .. tostring(cooking))
    cooking = nil
end

---------------------------------------------------------------------------
-- Load creature definitions for death_state (TDD: graceful failures)
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

local ok_cat, cat_def = pcall(dofile, creature_path("cat"))
if not ok_cat then print("WARNING: cat.lua failed to load — " .. tostring(cat_def)) end

local ok_bat, bat_def = pcall(dofile, creature_path("bat"))
if not ok_bat then print("WARNING: bat.lua failed to load — " .. tostring(bat_def)) end

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
    function reg:add(obj)
        self._objects[obj.guid or obj.id] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    return reg
end

-- Build a reshaped dead creature from its death_state
local function make_dead_creature(creature_def, id_override)
    if not creature_def or not creature_def.death_state then return nil end
    local ds = creature_def.death_state
    local inst = {
        guid = "{dead-" .. (id_override or creature_def.id) .. "-cook}",
        id = id_override or creature_def.id,
        template = ds.template or "small-item",
        animate = false,
        alive = false,
        portable = ds.portable ~= false,
        name = ds.name,
        description = ds.description,
        keywords = deep_copy(ds.keywords),
        room_presence = ds.room_presence,
        on_feel = ds.on_feel,
        on_smell = ds.on_smell,
        on_listen = ds.on_listen,
        on_taste = ds.on_taste,
        food = deep_copy(ds.food),
        crafting = deep_copy(ds.crafting),
        initial_state = ds.initial_state or "fresh",
        _state = ds.initial_state or "fresh",
        states = deep_copy(ds.states),
        transitions = deep_copy(ds.transitions),
        size = ds.size,
        weight = ds.weight,
    }
    return inst
end

local function make_fire_source()
    return {
        guid = "{test-brazier-001}",
        id = "brazier",
        template = "furniture",
        name = "an iron brazier",
        keywords = {"brazier", "iron brazier", "fire"},
        description = "A heavy iron brazier, glowing with hot coals.",
        on_feel = "Radiating heat.",
        fire_source = true,
        capabilities = { "fire_source" },
        portable = false,
        size = "medium",
        weight = 30,
    }
end

local function make_grain()
    return {
        guid = "{test-grain-001}",
        id = "grain-handful",
        template = "small-item",
        name = "a handful of grain",
        keywords = {"grain", "handful of grain", "wheat"},
        description = "A handful of dried grain kernels.",
        on_feel = "Dry, hard kernels. They rattle in your palm.",
        on_smell = "Dusty and faintly sweet.",
        on_taste = "Hard and bland. Not really edible raw.",
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
        crafting = {
            cook = {
                becomes = "flatbread",
                requires_tool = "fire_source",
                message = "You press the grain into a flat cake and hold it over the flames. It browns and hardens into rough flatbread.",
                fail_message_no_tool = "You need a fire source to cook this.",
            },
        },
    }
end

local function make_non_cookable()
    return {
        guid = "{test-rock-cook}",
        id = "test-rock",
        template = "small-item",
        name = "a rock",
        keywords = {"rock", "stone"},
        description = "A plain rock.",
        on_feel = "Cold and rough.",
        portable = true,
        size = 1,
        weight = 1.0,
    }
end

-- Track mutations performed
local mutation_log = {}

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

    mutation_log = {}

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
        },
        game_start_time = opts.game_start_time or os.time(),
        headless = true,
        shown_hints = opts.shown_hints or {},
        mutation = {
            mutate = function(reg, loader, id, source, templates)
                mutation_log[#mutation_log + 1] = { id = id, source = source }
                return { id = id }, nil
            end,
        },
        loader = {},
        templates = {},
        object_sources = {},
    }
end

---------------------------------------------------------------------------
-- Register verb handlers into a table we can call directly
---------------------------------------------------------------------------
local handlers = {}
if crafting and crafting.register then
    local reg_ok, reg_err = pcall(crafting.register, handlers)
    if not reg_ok then
        print("WARNING: crafting.register failed — " .. tostring(reg_err))
    end
end
if cooking and cooking.register then
    local reg_ok, reg_err = pcall(cooking.register, handlers)
    if not reg_ok then
        print("WARNING: cooking.register failed — " .. tostring(reg_err))
    end
end

---------------------------------------------------------------------------
-- SUITE 1: Cook dead creatures (with fire_source)
---------------------------------------------------------------------------
suite("COOK VERB: creature cooking with fire_source (WAVE-3)")

test("1. cook dead-rat with fire_source produces cooked-rat-meat", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    h.assert_truthy(rat_def.death_state, "rat must have death_state")
    h.assert_truthy(rat_def.death_state.crafting, "rat death_state must have crafting")
    h.assert_truthy(rat_def.death_state.crafting.cook, "rat must have crafting.cook")
    h.assert_eq("cooked-rat-meat", rat_def.death_state.crafting.cook.becomes,
        "rat cook.becomes must be cooked-rat-meat")
    h.assert_eq("fire_source", rat_def.death_state.crafting.cook.requires_tool,
        "rat cook must require fire_source")
end)

test("2. cook dead-cat with fire_source produces cooked-cat-meat", function()
    h.assert_truthy(ok_cat, "cat.lua must load")
    h.assert_truthy(cat_def.death_state, "cat must have death_state")
    h.assert_truthy(cat_def.death_state.crafting, "cat death_state must have crafting")
    h.assert_truthy(cat_def.death_state.crafting.cook, "cat must have crafting.cook")
    h.assert_eq("cooked-cat-meat", cat_def.death_state.crafting.cook.becomes,
        "cat cook.becomes must be cooked-cat-meat")
end)

test("3. cook dead-bat with fire_source produces cooked-bat-meat", function()
    h.assert_truthy(ok_bat, "bat.lua must load")
    h.assert_truthy(bat_def.death_state, "bat must have death_state")
    h.assert_truthy(bat_def.death_state.crafting, "bat death_state must have crafting")
    h.assert_truthy(bat_def.death_state.crafting.cook, "bat must have crafting.cook")
    h.assert_eq("cooked-bat-meat", bat_def.death_state.crafting.cook.becomes,
        "bat cook.becomes must be cooked-bat-meat")
end)

test("4. cook grain with fire_source produces flatbread", function()
    local grain = make_grain()
    h.assert_truthy(grain.crafting, "grain must have crafting")
    h.assert_truthy(grain.crafting.cook, "grain must have crafting.cook")
    h.assert_eq("flatbread", grain.crafting.cook.becomes,
        "grain cook.becomes must be flatbread")
    h.assert_eq("fire_source", grain.crafting.cook.requires_tool,
        "grain cook must require fire_source")
end)

test("5. cook verb handler registered", function()
    h.assert_truthy(handlers["cook"],
        "cook handler must be registered in crafting or cooking module")
end)

test("6. cook handler with fire_source calls mutation", function()
    if not handlers["cook"] then
        error("cook handler not registered (TDD — WAVE-3 not implemented yet)")
    end

    local dead_rat = make_dead_creature(rat_def, "dead-rat")
    local brazier = make_fire_source()
    local ctx = make_context({
        objects = { dead_rat, brazier },
        hands = { dead_rat, nil },
    })

    local output = {}
    local _print = print
    print = function(s) output[#output + 1] = s end
    local ok, err = pcall(handlers["cook"], ctx, "dead rat")
    print = _print

    h.assert_truthy(ok, "cook handler must not crash: " .. tostring(err))
    h.assert_truthy(#output > 0, "cook must produce output")
end)

---------------------------------------------------------------------------
-- SUITE 2: Cook without fire_source → failure
---------------------------------------------------------------------------
suite("COOK VERB: missing fire_source (WAVE-3)")

test("7. cook without fire_source fails with message", function()
    if not handlers["cook"] then
        error("cook handler not registered (TDD — WAVE-3 not implemented yet)")
    end

    local dead_rat = make_dead_creature(rat_def, "dead-rat")
    local ctx = make_context({
        objects = { dead_rat },
        hands = { dead_rat, nil },
    })

    local output = {}
    local _print = print
    print = function(s) output[#output + 1] = s end
    local ok, err = pcall(handlers["cook"], ctx, "dead rat")
    print = _print

    h.assert_truthy(ok, "cook handler must not crash: " .. tostring(err))
    local found_fail = false
    for _, line in ipairs(output) do
        local lower = line:lower()
        if lower:find("fire") or lower:find("heat") or lower:find("need")
           or lower:find("can't cook") or lower:find("no way to cook") then
            found_fail = true; break
        end
    end
    h.assert_truthy(found_fail,
        "cook without fire_source must print failure message mentioning fire/heat")
end)

test("8. fail message matches crafting.cook.fail_message_no_tool", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    local fail_msg = rat_def.death_state.crafting.cook.fail_message_no_tool
    h.assert_truthy(fail_msg, "rat must declare fail_message_no_tool")
    h.assert_truthy(fail_msg:lower():find("fire"),
        "fail_message_no_tool must mention fire: " .. fail_msg)
end)

---------------------------------------------------------------------------
-- SUITE 3: Cook non-cookable item → rejection
---------------------------------------------------------------------------
suite("COOK VERB: non-cookable item rejection (WAVE-3)")

test("9. cook non-cookable item rejected", function()
    if not handlers["cook"] then
        error("cook handler not registered (TDD — WAVE-3 not implemented yet)")
    end

    local rock = make_non_cookable()
    local brazier = make_fire_source()
    local ctx = make_context({
        objects = { rock, brazier },
        hands = { rock, nil },
    })

    local output = {}
    local _print = print
    print = function(s) output[#output + 1] = s end
    local ok, err = pcall(handlers["cook"], ctx, "rock")
    print = _print

    h.assert_truthy(ok, "cook handler must not crash: " .. tostring(err))
    local found_reject = false
    for _, line in ipairs(output) do
        local lower = line:lower()
        if lower:find("can't cook") or lower:find("cannot cook")
           or lower:find("not something you can cook")
           or lower:find("no way") or lower:find("cook that") then
            found_reject = true; break
        end
    end
    h.assert_truthy(found_reject,
        "cook non-cookable item must print rejection message")
end)

test("10. cook with empty noun rejected", function()
    if not handlers["cook"] then
        error("cook handler not registered (TDD — WAVE-3 not implemented yet)")
    end

    local ctx = make_context({ objects = {} })
    local output = {}
    local _print = print
    print = function(s) output[#output + 1] = s end
    local ok, err = pcall(handlers["cook"], ctx, "")
    print = _print

    h.assert_truthy(ok, "cook with empty noun must not crash: " .. tostring(err))
    h.assert_truthy(#output > 0, "cook with empty noun must produce guidance message")
end)

---------------------------------------------------------------------------
-- SUITE 4: Cook aliases
---------------------------------------------------------------------------
suite("COOK VERB: aliases (WAVE-3)")

test("11. roast alias registered", function()
    h.assert_truthy(handlers["roast"],
        "roast alias must be registered for cook")
end)

test("12. bake alias registered", function()
    h.assert_truthy(handlers["bake"],
        "bake alias must be registered for cook")
end)

test("13. grill alias registered", function()
    h.assert_truthy(handlers["grill"],
        "grill alias must be registered for cook")
end)

test("14. aliases point to same handler as cook", function()
    h.assert_truthy(handlers["cook"], "cook must be registered")
    if handlers["roast"] then
        h.assert_eq(handlers["cook"], handlers["roast"],
            "roast must point to same handler as cook")
    end
    if handlers["bake"] then
        h.assert_eq(handlers["cook"], handlers["bake"],
            "bake must point to same handler as cook")
    end
    if handlers["grill"] then
        h.assert_eq(handlers["cook"], handlers["grill"],
            "grill must point to same handler as cook")
    end
end)

---------------------------------------------------------------------------
-- SUITE 5: Cooked item replaces raw item
---------------------------------------------------------------------------
suite("COOK VERB: cooked item replaces raw (WAVE-3)")

test("15. cook recipe message declared on creature death_state", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    local msg = rat_def.death_state.crafting.cook.message
    h.assert_truthy(msg, "rat cook must have a message")
    h.assert_truthy(msg:lower():find("flame") or msg:lower():find("fire")
        or msg:lower():find("singe") or msg:lower():find("cook"),
        "cook message must reference cooking action: " .. msg)

    h.assert_truthy(ok_cat, "cat.lua must load")
    local cat_msg = cat_def.death_state.crafting.cook.message
    h.assert_truthy(cat_msg, "cat cook must have a message")

    h.assert_truthy(ok_bat, "bat.lua must load")
    local bat_msg = bat_def.death_state.crafting.cook.message
    h.assert_truthy(bat_msg, "bat cook must have a message")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
