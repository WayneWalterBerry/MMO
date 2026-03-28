-- test/loot/test-loot-integration.lua
-- WAVE-2 TDD: Integration tests for loot tables — full death→loot flow.
-- Tests: kill wolf → drops in room, spider guaranteed silk, backward compat.
-- Bart (engine) and Flanders (objects) are building in parallel — TDD.
--
-- Must be run from repository root: lua test/loot/test-loot-integration.lua

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
-- Load loot engine (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local loot_ok, loot = pcall(require, "engine.creatures.loot")
if not loot_ok then
    print("WARNING: engine.creatures.loot not loadable — " .. tostring(loot))
    loot = nil
end

---------------------------------------------------------------------------
-- Mock factories (match patterns from test-butcher-verb.lua)
-- Note: instantiate_drops uses resolve_template() which reads context.registry:get()
---------------------------------------------------------------------------
local function make_object_def(id, name)
    return {
        guid = "{tpl-" .. id .. "}",
        id = id,
        template = "small-item",
        name = name or id,
        keywords = { id },
        on_feel = "A " .. id .. ".",
        portable = true,
    }
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid or obj.id] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] end
    function reg:add(obj)
        self._objects[obj.guid or obj.id] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    function reg:register(id, obj)
        self._objects[id] = obj
        if obj.guid then self._objects[obj.guid] = obj end
    end
    return reg
end

local function make_room(objects)
    local contents = {}
    for _, obj in ipairs(objects or {}) do
        contents[#contents + 1] = obj.guid or obj.id
    end
    return {
        id = "test-room",
        name = "Test Room",
        template = "room",
        description = "A plain test room.",
        contents = contents,
        exits = {},
    }
end

local function make_context(reg, room)
    return {
        registry = reg,
        current_room = room,
    }
end

---------------------------------------------------------------------------
-- Template objects that loot_table can resolve
---------------------------------------------------------------------------
local LOOT_TEMPLATES = {
    make_object_def("gnawed-bone", "a gnawed bone"),
    make_object_def("silver-coin", "a silver coin"),
    make_object_def("torn-cloth", "a torn cloth"),
    make_object_def("copper-coin", "a copper coin"),
    make_object_def("charred-hide", "a charred hide"),
    make_object_def("tainted-meat", "tainted meat"),
    make_object_def("silk-bundle", "a silk bundle"),
    make_object_def("spider-fang", "a spider fang"),
}

---------------------------------------------------------------------------
-- Creature loot_table specs (from docs/architecture/engine/loot-tables.md)
---------------------------------------------------------------------------
local function make_wolf_with_loot()
    return {
        guid = "{test-wolf-loot-001}",
        id = "wolf",
        template = "creature",
        name = "a gray wolf",
        keywords = { "wolf", "gray wolf" },
        on_feel = "Coarse gray fur.",
        alive = true,
        loot_table = {
            always = {
                { template = "gnawed-bone" },
            },
            on_death = {
                { item = { template = "silver-coin" }, weight = 20 },
                { item = { template = "torn-cloth" },  weight = 30 },
                { item = nil,                          weight = 50 },
            },
            variable = {
                { template = "copper-coin", min = 0, max = 3 },
            },
            conditional = {
                fire_kill = { { template = "charred-hide" } },
                poison_kill = { { template = "tainted-meat" } },
            },
        },
    }
end

local function make_spider_with_loot()
    return {
        guid = "{test-spider-loot-001}",
        id = "spider",
        template = "creature",
        name = "a large spider",
        keywords = { "spider" },
        on_feel = "Bristly legs.",
        alive = true,
        loot_table = {
            always = {
                { template = "silk-bundle" },
            },
            on_death = {
                { item = { template = "spider-fang" }, weight = 10 },
                { item = nil,                          weight = 90 },
            },
        },
    }
end

local function make_rat_no_loot()
    return {
        guid = "{test-rat-001}",
        id = "rat",
        template = "creature",
        name = "a large rat",
        keywords = { "rat" },
        on_feel = "Greasy fur.",
        alive = true,
    }
end

---------------------------------------------------------------------------
-- Helper: simulate full death→loot flow using actual loot engine
---------------------------------------------------------------------------
local function simulate_death_loot(creature, death_context, reg, room)
    if not loot then return {} end

    -- Reset counter for deterministic IDs
    if loot._reset_counter then loot._reset_counter() end

    local drops = loot.roll_loot_table(creature, death_context or {})

    local instances
    if loot.instantiate_drops then
        -- Real signature: instantiate_drops(drops, room, context)
        local ctx = make_context(reg, room)
        instances = loot.instantiate_drops(drops, room, ctx)
    else
        -- Fallback if instantiate_drops not yet implemented
        instances = {}
        for _, drop in ipairs(drops) do
            for _ = 1, (drop.quantity or 1) do
                local inst = reg:get(drop.template)
                if inst then
                    local copy = {}
                    for k, v in pairs(inst) do copy[k] = v end
                    copy.id = drop.template .. "-loot-" .. (#instances + 1)
                    instances[#instances + 1] = copy
                    room.contents[#room.contents + 1] = copy.id
                end
            end
        end
    end

    return instances or {}
end

-- Check if any instance has an id starting with a given prefix
local function has_drop_with_prefix(instances, prefix)
    for _, inst in ipairs(instances) do
        if inst.id and inst.id:find(prefix, 1, true) then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("LOOT INTEGRATION: kill wolf → drops appear in room (WAVE-2 TDD)")

test("1. kill wolf with loot_table → gnawed-bone always drops, items in room", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    math.randomseed(42)
    local wolf = make_wolf_with_loot()
    local all_objects = { wolf }
    for _, t in ipairs(LOOT_TEMPLATES) do all_objects[#all_objects + 1] = t end
    local reg = make_mock_registry(all_objects)
    local room = make_room({ wolf })

    local initial_count = #room.contents
    local instances = simulate_death_loot(wolf, {}, reg, room)

    -- gnawed-bone guaranteed (always block) — IDs are renamed to gnawed-bone-loot-N
    h.assert_truthy(has_drop_with_prefix(instances, "gnawed-bone"),
        "gnawed-bone must always drop from wolf")

    -- Room should have more items than before
    h.assert_truthy(#room.contents > initial_count,
        "Room must contain new loot items after death")
end)

test("2. kill spider → silk-bundle always drops", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    math.randomseed(42)
    local spider = make_spider_with_loot()
    local all_objects = { spider }
    for _, t in ipairs(LOOT_TEMPLATES) do all_objects[#all_objects + 1] = t end
    local reg = make_mock_registry(all_objects)
    local room = make_room({ spider })

    local instances = simulate_death_loot(spider, {}, reg, room)

    h.assert_truthy(has_drop_with_prefix(instances, "silk-bundle"),
        "silk-bundle must always drop from spider (always block)")
end)

test("3. creature without loot_table → no crash, no drops (backward compatible)", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    local rat = make_rat_no_loot()
    local reg = make_mock_registry({ rat })
    local room = make_room({ rat })

    local initial_count = #room.contents
    local instances = simulate_death_loot(rat, {}, reg, room)

    h.assert_eq(0, #instances,
        "Creature without loot_table must produce 0 drops")
    h.assert_eq(initial_count, #room.contents,
        "Room contents must not change for creature without loot_table")
end)

test("4. kill wolf with fire_kill → charred-hide conditional drop appears", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    math.randomseed(42)
    local wolf = make_wolf_with_loot()
    local all_objects = { wolf }
    for _, t in ipairs(LOOT_TEMPLATES) do all_objects[#all_objects + 1] = t end
    local reg = make_mock_registry(all_objects)
    local room = make_room({ wolf })

    local instances = simulate_death_loot(wolf, { kill_method = "fire_kill" }, reg, room)

    h.assert_truthy(has_drop_with_prefix(instances, "charred-hide"),
        "fire_kill must produce charred-hide conditional drop")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
