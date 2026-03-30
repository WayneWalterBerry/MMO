-- test/creatures/test-death-drops.lua
-- WAVE-2 TDD: Validates that creature death drops inventory items to the room
-- floor alongside the reshaped corpse. Also covers byproduct drops (spider silk).
-- Must be run from repository root: lua test/creatures/test-death-drops.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load creature definitions via dofile (pcall-guarded)
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local ok_wolf, wolf_def = pcall(dofile, creature_path("wolf"))
if not ok_wolf then print("WARNING: wolf.lua failed to load — " .. tostring(wolf_def)) end

local ok_spider, spider_def = pcall(dofile, creature_path("spider"))
if not ok_spider then print("WARNING: spider.lua failed to load — " .. tostring(spider_def)) end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

local ok_cat, cat_def = pcall(dofile, creature_path("cat"))
if not ok_cat then print("WARNING: cat.lua failed to load — " .. tostring(cat_def)) end

local ok_bat, bat_def = pcall(dofile, creature_path("bat"))
if not ok_bat then print("WARNING: bat.lua failed to load — " .. tostring(bat_def)) end

---------------------------------------------------------------------------
-- Load loot objects
---------------------------------------------------------------------------
local obj_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP
local ok_bone, bone_def = pcall(dofile, obj_path .. "gnawed-bone.lua")
if not ok_bone then print("WARNING: gnawed-bone.lua failed to load — " .. tostring(bone_def)) end

local ok_silk, silk_def = pcall(dofile, obj_path .. "silk-bundle.lua")
if not ok_silk then print("WARNING: silk-bundle.lua failed to load — " .. tostring(silk_def)) end

---------------------------------------------------------------------------
-- Known GUIDs
---------------------------------------------------------------------------
local GNAWED_BONE_GUID = "{b8db1d83-9c05-401c-ae7b-67c31b98d6fc}"
local SILK_BUNDLE_GUID = "{203f252d-61f6-4533-a379-f5ecb3880de4}"

---------------------------------------------------------------------------
-- Utilities
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

---------------------------------------------------------------------------
-- Mock registry that tracks room object registrations
---------------------------------------------------------------------------
local function make_mock_registry(objects)
    local reg = {
        _objects = {},
        _room_objects = {},
        _room_object_list = {},
    }
    for _, obj in ipairs(objects or {}) do
        if obj.guid then reg._objects[obj.guid] = obj end
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] or nil end
    function reg:register_as_room_object(instance, room)
        local key = instance.guid or instance.id
        self._room_objects[key] = { instance = instance, room = room }
        self._room_object_list[#self._room_object_list + 1] = instance
    end
    function reg:was_registered_as_room_object(guid)
        return self._room_objects[guid] ~= nil
    end
    function reg:get_room_object(guid)
        local entry = self._room_objects[guid]
        return entry and entry.instance or nil
    end
    function reg:count_room_objects()
        return #self._room_object_list
    end
    return reg
end

local deregistered_guids = {}
local function mock_deregister_creature(guid)
    deregistered_guids[guid] = true
end
local function reset_deregister_tracking()
    deregistered_guids = {}
end

---------------------------------------------------------------------------
-- Build a live creature instance
---------------------------------------------------------------------------
local function make_live_creature(def, guid_override)
    local inst = deep_copy(def)
    inst.guid = guid_override or inst.guid or ("{test-" .. (inst.id or "creature") .. "}")
    inst.template = inst.template or "creature"
    inst.animate = true
    inst.alive = true
    inst.health = inst.health or inst.max_health or 10
    inst.max_health = inst.max_health or 10
    inst.behavior = inst.behavior or { default = "idle" }
    inst.drives = inst.drives or { hunger = { value = 50 } }
    inst.reactions = inst.reactions or {}
    inst.combat = inst.combat or { attack = 1 }
    return inst
end

---------------------------------------------------------------------------
-- reshape_instance with inventory drop support (WAVE-2 contract)
-- Extends WAVE-1 reshape to also drop inventory items to room floor.
---------------------------------------------------------------------------
local function reshape_instance(instance, death_state, registry, room)
    -- WAVE-1 reshape: template switch + identity overwrite
    instance.template = death_state.template
    instance.name = death_state.name
    instance.description = death_state.description
    instance.keywords = death_state.keywords
    instance.room_presence = death_state.room_presence

    instance.on_feel = death_state.on_feel
    instance.on_smell = death_state.on_smell
    instance.on_listen = death_state.on_listen
    instance.on_taste = death_state.on_taste

    instance.portable = death_state.portable
    instance.size = death_state.size or instance.size
    instance.weight = death_state.weight or instance.weight
    instance.animate = false
    instance.alive = false

    if death_state.food then instance.food = death_state.food end
    if death_state.crafting then instance.crafting = death_state.crafting end
    if death_state.container then instance.container = death_state.container end

    if death_state.states then
        instance.states = death_state.states
        instance.initial_state = death_state.initial_state or "fresh"
        instance._state = instance.initial_state
        instance.transitions = death_state.transitions
    end

    -- WAVE-2: loot_table drops — guaranteed items scatter to room floor
    local instance_had_loot_table = instance.loot_table ~= nil
    if instance.loot_table then
        if instance.loot_table.always then
            for _, entry in ipairs(instance.loot_table.always) do
                local item = registry:get(entry.template)
                if item then registry:register_as_room_object(item, room) end
            end
        end
        instance.loot_table = nil
    end

    -- WAVE-1: byproducts (spider silk) — skipped if loot_table handled drops
    if death_state.byproducts and not instance_had_loot_table then
        for _, bp_id in ipairs(death_state.byproducts) do
            local bp = registry:get(bp_id)
            if bp then registry:register_as_room_object(bp, room) end
        end
    end

    -- Legacy: inventory drops (for backward-compat test fixtures)
    if instance.inventory then
        local inv = instance.inventory
        if inv.hands then
            for _, guid in ipairs(inv.hands) do
                local item = registry:get(guid)
                if item then registry:register_as_room_object(item, room) end
            end
        end
        if inv.worn then
            for _, guid in pairs(inv.worn) do
                local item = registry:get(guid)
                if item then registry:register_as_room_object(item, room) end
            end
        end
        if inv.carried then
            for _, guid in ipairs(inv.carried) do
                local item = registry:get(guid)
                if item then registry:register_as_room_object(item, room) end
            end
        end
        instance.inventory = nil
    end

    mock_deregister_creature(instance.guid)
    registry:register_as_room_object(instance, room)

    -- Clear creature-only metadata
    instance.behavior = nil
    instance.drives = nil
    instance.reactions = nil
    instance.movement = nil
    instance.awareness = nil
    instance.health = nil
    instance.max_health = nil
    instance.body_tree = nil
    instance.combat = nil
end

---------------------------------------------------------------------------
-- Death state blocks (matching creature .lua definitions)
---------------------------------------------------------------------------
local death_states = {
    wolf = {
        template = "furniture",
        name = "a dead wolf",
        description = "A massive wolf carcass sprawled across the floor.",
        keywords = {"dead wolf", "wolf corpse", "wolf carcass", "wolf"},
        room_presence = "A massive dead wolf sprawls across the floor.",
        portable = false, size = "large", weight = 45.0,
        on_feel = "Coarse fur over thick, cooling muscle. Too heavy to lift.",
        on_smell = "Wet dog and blood.",
        on_listen = "Nothing.",
        on_taste = "Fur and grit.",
        food = { category = "meat", raw = true, edible = false, cookable = false },
        container = { capacity = 5, categories = { "tiny", "small", "medium" } },
    },
    spider = {
        template = "small-item",
        name = "a dead spider",
        description = "A crumpled spider husk, legs curled inward.",
        keywords = {"dead spider", "spider husk", "spider"},
        room_presence = "A crumpled spider husk lies on the floor.",
        portable = true, size = "tiny", weight = 0.1,
        material = "chitin",
        on_feel = "Brittle chitin plates. The legs snap if you press.",
        on_smell = "An acrid chemical tang.",
        on_listen = "Dry crackling if you shift it.",
        on_taste = "Bitter and crunchy. Inedible.",
        reshape_narration = "The spider's abdomen splits, spilling a tangle of silk.",
    },
    rat = {
        template = "small-item",
        name = "a dead rat",
        description = "A dead rat lies on its side, legs splayed stiffly.",
        keywords = {"dead rat", "rat corpse", "rat"},
        room_presence = "A dead rat lies crumpled on the floor.",
        portable = true, size = "tiny", weight = 0.3,
        on_feel = "Cooling fur over a limp body.",
        on_smell = "Blood and musk.",
        on_listen = "Nothing.",
        on_taste = "Fur and blood.",
    },
    cat = {
        template = "small-item",
        name = "a dead cat",
        description = "A dead cat, fur matted.",
        keywords = {"dead cat", "cat corpse", "cat"},
        room_presence = "A dead cat lies curled on the floor.",
        portable = true, size = "small", weight = 3.0,
        on_feel = "Soft fur over cooling muscle.",
        on_smell = "Blood and warm fur.",
        on_listen = "Silent.",
        on_taste = "Fur. Not recommended.",
    },
    bat = {
        template = "small-item",
        name = "a dead bat",
        description = "A dead bat, wings folded against its tiny body.",
        keywords = {"dead bat", "bat corpse", "bat"},
        room_presence = "A dead bat lies crumpled on the floor.",
        portable = true, size = "tiny", weight = 0.05,
        on_feel = "Paper-thin wing membranes over fragile bones.",
        on_smell = "Musty guano and blood.",
        on_listen = "Silent.",
        on_taste = "Leathery and bitter.",
    },
}

---------------------------------------------------------------------------
-- TESTS: Death drops (WAVE-2)
---------------------------------------------------------------------------
suite("DEATH DROPS: creature items scatter to room floor (WAVE-2)")

-- 1. Kill wolf → gnawed-bone appears as room floor object
test("1. kill wolf — gnawed-bone appears as room floor object", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_wolf and wolf_def or {
        id = "wolf", guid = "{wolf-drop-01}",
        loot_table = { always = { { template = "gnawed-bone" } } },
    }, "{wolf-drop-01}")
    local bone = bone_def and deep_copy(bone_def) or { guid = GNAWED_BONE_GUID, id = "gnawed-bone", portable = true }
    local registry = make_mock_registry({ bone })
    local room = make_room()

    reshape_instance(inst, death_states.wolf, registry, room)

    h.assert_truthy(registry:was_registered_as_room_object(GNAWED_BONE_GUID),
        "gnawed-bone must appear as room floor object after wolf death")
end)

-- 2. Kill spider → silk-bundle appears (byproduct from WAVE-1, not inventory)
test("2. kill spider — silk-bundle appears via byproduct", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_spider and spider_def or {
        id = "spider", guid = "{spider-drop-01}",
    }, "{spider-drop-01}")
    local silk = silk_def and deep_copy(silk_def) or { guid = SILK_BUNDLE_GUID, id = "silk-bundle", portable = true }
    local registry = make_mock_registry({ silk })
    local room = make_room()

    reshape_instance(inst, death_states.spider, registry, room)

    h.assert_truthy(registry:was_registered_as_room_object(SILK_BUNDLE_GUID),
        "silk-bundle must appear as room object via byproduct")
end)

-- 3. Kill rat (no inventory) → no items drop, no crash
test("3. kill rat — no inventory, no items drop, no crash", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-drop-01}" }, "{rat-drop-01}")
    local registry = make_mock_registry({})
    local room = make_room()

    h.assert_no_error(function()
        reshape_instance(inst, death_states.rat, registry, room)
    end, "killing rat with no inventory must not crash")
    -- Only the corpse itself should be registered
    h.assert_eq(1, registry:count_room_objects(), "only corpse registered, no extra drops")
end)

-- 4. Kill cat (no inventory) → no items drop
test("4. kill cat — no inventory, no items drop", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_cat and cat_def or { id = "cat", guid = "{cat-drop-01}" }, "{cat-drop-01}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.cat, registry, room)

    h.assert_eq(1, registry:count_room_objects(), "only corpse, no drops from cat")
end)

-- 5. Kill bat (no inventory) → no items drop
test("5. kill bat — no inventory, no items drop", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_bat and bat_def or { id = "bat", guid = "{bat-drop-01}" }, "{bat-drop-01}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.bat, registry, room)

    h.assert_eq(1, registry:count_room_objects(), "only corpse, no drops from bat")
end)

-- 6. Dropped items are independent room objects (not attached to corpse)
test("6. dropped items are independent room objects", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_wolf and wolf_def or {
        id = "wolf", guid = "{wolf-indep-01}",
        loot_table = { always = { { template = "gnawed-bone" } } },
    }, "{wolf-indep-01}")
    local bone = bone_def and deep_copy(bone_def) or { guid = GNAWED_BONE_GUID, id = "gnawed-bone", portable = true }
    local registry = make_mock_registry({ bone })
    local room = make_room()

    reshape_instance(inst, death_states.wolf, registry, room)

    -- Bone is its own room object, not nested under corpse
    local bone_entry = registry:get_room_object(GNAWED_BONE_GUID)
    local corpse_entry = registry:get_room_object("{wolf-indep-01}")
    h.assert_truthy(bone_entry, "bone must be a room object")
    h.assert_truthy(corpse_entry, "corpse must be a room object")
    -- They are separate objects
    h.assert_truthy(bone_entry ~= corpse_entry, "bone and corpse must be separate objects")
end)

-- 7. Dropped items have correct GUIDs
test("7. dropped items have correct GUIDs", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_wolf and wolf_def or {
        id = "wolf", guid = "{wolf-guid-01}",
        loot_table = { always = { { template = "gnawed-bone" } } },
    }, "{wolf-guid-01}")
    local bone = bone_def and deep_copy(bone_def) or { guid = GNAWED_BONE_GUID, id = "gnawed-bone" }
    local registry = make_mock_registry({ bone })
    local room = make_room()

    reshape_instance(inst, death_states.wolf, registry, room)

    local dropped = registry:get_room_object(GNAWED_BONE_GUID)
    h.assert_truthy(dropped, "dropped bone must exist in room")
    h.assert_eq(GNAWED_BONE_GUID, dropped.guid, "dropped bone GUID must match")
end)

-- 8. Reshaped corpse and dropped items coexist in room
test("8. reshaped corpse and dropped items coexist in room", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_wolf and wolf_def or {
        id = "wolf", guid = "{wolf-coexist-01}",
        loot_table = { always = { { template = "gnawed-bone" } } },
    }, "{wolf-coexist-01}")
    local bone = bone_def and deep_copy(bone_def) or { guid = GNAWED_BONE_GUID, id = "gnawed-bone" }
    local registry = make_mock_registry({ bone })
    local room = make_room()

    reshape_instance(inst, death_states.wolf, registry, room)

    -- 2 objects: corpse + bone
    h.assert_eq(2, registry:count_room_objects(),
        "room must have corpse + dropped bone (2 objects)")
    h.assert_truthy(registry:was_registered_as_room_object("{wolf-coexist-01}"), "corpse in room")
    h.assert_truthy(registry:was_registered_as_room_object(GNAWED_BONE_GUID), "bone in room")
end)

-- 9. Items are take-able after drop (portable = true)
test("9. dropped items are take-able (portable = true)", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_wolf and wolf_def or {
        id = "wolf", guid = "{wolf-take-01}",
        loot_table = { always = { { template = "gnawed-bone" } } },
    }, "{wolf-take-01}")
    local bone = bone_def and deep_copy(bone_def) or {
        guid = GNAWED_BONE_GUID, id = "gnawed-bone", portable = true,
    }
    local registry = make_mock_registry({ bone })
    local room = make_room()

    reshape_instance(inst, death_states.wolf, registry, room)

    local dropped = registry:get_room_object(GNAWED_BONE_GUID)
    h.assert_truthy(dropped, "dropped bone must exist")
    h.assert_eq(true, dropped.portable, "dropped bone must be portable (take-able)")
end)

-- 10. Wolf corpse GUID preserved after inventory drop
test("10. wolf corpse GUID preserved after inventory drop", function()
    reset_deregister_tracking()
    local original_guid = "{wolf-preserve-01}"
    local inst = make_live_creature(ok_wolf and wolf_def or {
        id = "wolf", guid = original_guid,
        loot_table = { always = { { template = "gnawed-bone" } } },
    }, original_guid)
    local bone = bone_def and deep_copy(bone_def) or { guid = GNAWED_BONE_GUID, id = "gnawed-bone" }
    local registry = make_mock_registry({ bone })
    local room = make_room()

    reshape_instance(inst, death_states.wolf, registry, room)

    h.assert_eq(original_guid, inst.guid, "corpse GUID must be preserved")
end)

-- 11. Multiple inventory items all drop
test("11. multiple inventory items all drop", function()
    reset_deregister_tracking()
    local g1, g2 = "{item-a}", "{item-b}"
    local inst = make_live_creature({
        id = "test-beast", guid = "{beast-multi-01}",
        inventory = { hands = { g1 }, worn = {}, carried = { g2 } },
    }, "{beast-multi-01}")
    local item_a = { guid = g1, id = "item-a", portable = true }
    local item_b = { guid = g2, id = "item-b", portable = true }
    local registry = make_mock_registry({ item_a, item_b })
    local room = make_room()

    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_truthy(registry:was_registered_as_room_object(g1), "item-a must drop")
    h.assert_truthy(registry:was_registered_as_room_object(g2), "item-b must drop")
    -- corpse + 2 items = 3
    h.assert_eq(3, registry:count_room_objects(), "corpse + 2 items = 3 room objects")
end)

-- 12. Loot table cleared from corpse after drop
test("12. loot_table cleared from corpse after drop", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_wolf and wolf_def or {
        id = "wolf", guid = "{wolf-clear-01}",
        loot_table = { always = { { template = "gnawed-bone" } } },
    }, "{wolf-clear-01}")
    local bone = bone_def and deep_copy(bone_def) or { guid = GNAWED_BONE_GUID, id = "gnawed-bone" }
    local registry = make_mock_registry({ bone })
    local room = make_room()

    reshape_instance(inst, death_states.wolf, registry, room)

    h.assert_nil(inst.loot_table, "loot_table must be nil on corpse after drops")
end)

-- 13. Gnawed-bone has correct properties after drop
test("13. gnawed-bone has correct properties after drop", function()
    h.assert_truthy(ok_bone, "gnawed-bone.lua must load")
    h.assert_eq("small-item", bone_def.template, "gnawed-bone template")
    h.assert_eq("bone", bone_def.material, "gnawed-bone material")
    h.assert_truthy(bone_def.on_feel, "gnawed-bone must have on_feel")
    h.assert_eq(true, bone_def.portable, "gnawed-bone must be portable")
end)

-- 14. Silk-bundle has correct properties after drop
test("14. silk-bundle has correct properties after drop", function()
    h.assert_truthy(ok_silk, "silk-bundle.lua must load")
    h.assert_eq("small-item", silk_def.template, "silk-bundle template")
    h.assert_truthy(silk_def.on_feel, "silk-bundle must have on_feel")
    h.assert_eq(true, silk_def.portable, "silk-bundle must be portable")
end)

-- 15. Spider corpse and silk-bundle both in room
test("15. spider corpse and silk-bundle both in room", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_spider and spider_def or {
        id = "spider", guid = "{spider-coexist-01}",
    }, "{spider-coexist-01}")
    local silk = silk_def and deep_copy(silk_def) or { guid = SILK_BUNDLE_GUID, id = "silk-bundle", portable = true }
    local registry = make_mock_registry({ silk })
    local room = make_room()

    reshape_instance(inst, death_states.spider, registry, room)

    h.assert_eq(2, registry:count_room_objects(), "spider corpse + silk = 2 room objects")
    h.assert_truthy(registry:was_registered_as_room_object("{spider-coexist-01}"), "spider corpse in room")
    h.assert_truthy(registry:was_registered_as_room_object(SILK_BUNDLE_GUID), "silk-bundle in room")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
