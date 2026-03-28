-- test/creatures/test-spider-death-single-drop.lua
-- Regression test for Issue #356: Spider must drop exactly 1 silk-bundle on
-- death, not 2. The old byproducts system and the new loot_table.always were
-- both firing independently, causing disambiguation deadlocks.
--
-- Uses the real engine death.lua to validate end-to-end behavior.
-- Must be run from repository root: lua test/creatures/test-spider-death-single-drop.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load modules
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)

local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end
local function object_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP .. name .. ".lua"
end

local ok_spider, spider_def = pcall(dofile, creature_path("spider"))
if not ok_spider then print("WARNING: spider.lua failed to load — " .. tostring(spider_def)) end

local ok_silk, silk_def = pcall(dofile, object_path("silk-bundle"))
if not ok_silk then print("WARNING: silk-bundle.lua failed to load — " .. tostring(silk_def)) end

local ok_wolf, wolf_def = pcall(dofile, creature_path("wolf"))
if not ok_wolf then print("WARNING: wolf.lua failed to load — " .. tostring(wolf_def)) end

local ok_bone, bone_def = pcall(dofile, object_path("gnawed-bone.lua"))
if not ok_bone then bone_def = nil end

-- Load real engine modules
local ok_death, death_mod = pcall(require, "engine.creatures.death")
if not ok_death then print("WARNING: engine.creatures.death failed to load — " .. tostring(death_mod)) end

local ok_loot, loot_mod = pcall(require, "engine.creatures.loot")
if not ok_loot then print("WARNING: engine.creatures.loot failed to load — " .. tostring(loot_mod)) end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[deep_copy(k)] = deep_copy(v) end
    return copy
end

local function make_room()
    return { id = "test-room", name = "Test Room", template = "room", contents = {} }
end

local function make_mock_registry(objects)
    local reg = { _store = {} }
    for _, obj in ipairs(objects or {}) do
        if obj.id then reg._store[obj.id] = obj end
        if obj.guid then reg._store[obj.guid] = obj end
    end
    function reg:get(id) return self._store[id] or nil end
    function reg:register(id, obj)
        self._store[id] = obj
        if obj.guid then self._store[obj.guid] = obj end
    end
    return reg
end

local function count_silk_in_room(room)
    local count = 0
    for _, entry in ipairs(room.contents or {}) do
        if type(entry) == "string" and entry:find("silk%-bundle") then
            count = count + 1
        end
    end
    return count
end

local function count_item_in_room(room, pattern)
    local count = 0
    for _, entry in ipairs(room.contents or {}) do
        if type(entry) == "string" and entry:find(pattern) then
            count = count + 1
        end
    end
    return count
end

local function make_live_creature(def, guid_override)
    local inst = deep_copy(def)
    inst.guid = guid_override or inst.guid
    inst.animate = true
    inst.alive = true
    inst.health = inst.health or inst.max_health or 10
    return inst
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("ISSUE #356: Spider must drop exactly 1 silk-bundle (not 2)")

test("1. spider.lua has loot_table.always with silk-bundle", function()
    h.assert_truthy(ok_spider, "spider.lua must load")
    h.assert_truthy(spider_def.loot_table, "spider must have loot_table")
    h.assert_truthy(spider_def.loot_table.always, "spider must have loot_table.always")
    local found = false
    for _, entry in ipairs(spider_def.loot_table.always) do
        if entry.template == "silk-bundle" then found = true end
    end
    h.assert_truthy(found, "loot_table.always must contain silk-bundle")
end)

test("2. spider.lua death_state does NOT have byproducts with silk-bundle", function()
    h.assert_truthy(ok_spider, "spider.lua must load")
    h.assert_truthy(spider_def.death_state, "spider must have death_state")
    local ds = spider_def.death_state
    if ds.byproducts then
        for _, bp in ipairs(ds.byproducts) do
            h.assert_truthy(bp ~= "silk-bundle",
                "death_state.byproducts must NOT contain silk-bundle (legacy duplicate — Issue #356)")
        end
    end
end)

test("3. kill spider via engine death.lua — exactly 1 silk-bundle in room", function()
    h.assert_truthy(ok_death, "engine.creatures.death must load")
    h.assert_truthy(ok_spider, "spider.lua must load")
    h.assert_truthy(ok_silk, "silk-bundle.lua must load")

    if loot_mod and loot_mod._reset_counter then loot_mod._reset_counter() end

    local silk = deep_copy(silk_def)
    local inst = make_live_creature(spider_def, "{test-spider-356}")
    local room = make_room()
    local reg = make_mock_registry({ silk })

    local context = {
        registry = reg,
        base_classes = { ["silk-bundle"] = deep_copy(silk_def) },
        object_sources = {},
    }

    death_mod.handle_creature_death(inst, context, room)

    local silk_count = count_silk_in_room(room)
    h.assert_eq(1, silk_count,
        "exactly 1 silk-bundle must be in room after spider death (got " .. silk_count .. ")")
end)

test("4. wolf has loot_table.always but NO byproducts (no duplicate risk)", function()
    h.assert_truthy(ok_wolf, "wolf.lua must load")
    h.assert_truthy(wolf_def.loot_table, "wolf must have loot_table")
    h.assert_truthy(wolf_def.loot_table.always, "wolf must have loot_table.always")
    local ds = wolf_def.death_state
    h.assert_truthy(ds, "wolf must have death_state")
    h.assert_truthy(ds.byproducts == nil,
        "wolf death_state must NOT have byproducts (WAVE-2 uses loot_table)")
end)

test("5. loot_table.always drops exactly 1 entry per template", function()
    h.assert_truthy(ok_loot, "engine.creatures.loot must load")
    if loot_mod and loot_mod._reset_counter then loot_mod._reset_counter() end

    local creature = deep_copy(spider_def)
    local drops = loot_mod.roll_loot_table(creature, {})

    local silk_count = 0
    for _, drop in ipairs(drops) do
        if drop.template == "silk-bundle" then
            silk_count = silk_count + drop.quantity
        end
    end
    h.assert_eq(1, silk_count,
        "loot_table.always must produce exactly 1 silk-bundle drop descriptor")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
