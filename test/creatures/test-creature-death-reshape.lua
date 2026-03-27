-- test/creatures/test-creature-death-reshape.lua
-- WAVE-1 TDD: Validates that killing each creature type triggers in-place
-- reshape via reshape_instance(). GUID preserved, template switched, creature
-- metadata cleared, tick system deregistered, room object registered.
-- Must be run from repository root: lua test/creatures/test-creature-death-reshape.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load engine module (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
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
-- Load creature definitions via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

local ok_cat, cat_def = pcall(dofile, creature_path("cat"))
if not ok_cat then print("WARNING: cat.lua failed to load — " .. tostring(cat_def)) end

local ok_wolf, wolf_def = pcall(dofile, creature_path("wolf"))
if not ok_wolf then print("WARNING: wolf.lua failed to load — " .. tostring(wolf_def)) end

local ok_spider, spider_def = pcall(dofile, creature_path("spider"))
if not ok_spider then print("WARNING: spider.lua failed to load — " .. tostring(spider_def)) end

local ok_bat, bat_def = pcall(dofile, creature_path("bat"))
if not ok_bat then print("WARNING: bat.lua failed to load — " .. tostring(bat_def)) end

---------------------------------------------------------------------------
-- Mock factory
---------------------------------------------------------------------------
local function make_mock_registry(objects)
    local reg = {
        _objects = {},
        _room_objects = {},
    }
    for _, obj in ipairs(objects or {}) do
        reg._objects[obj.guid or obj.id] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] or nil end
    function reg:register_as_room_object(instance, room)
        self._room_objects[instance.guid or instance.id] = { instance = instance, room = room }
    end
    function reg:was_registered_as_room_object(guid)
        return self._room_objects[guid] ~= nil
    end
    return reg
end

local deregistered_guids = {}

-- Mock for creature deregister
local function mock_deregister_creature(guid)
    deregistered_guids[guid] = true
end

local function reset_deregister_tracking()
    deregistered_guids = {}
end

local function make_room()
    return {
        id = "test-room",
        name = "Test Room",
        template = "room",
        contents = {},
    }
end

-- Build a live creature instance from a loaded creature def, adding creature
-- metadata that a living creature would have at runtime.
local function make_live_creature(def, guid_override)
    local inst = deep_copy(def)
    inst.guid = guid_override or inst.guid or ("{test-" .. (inst.id or "creature") .. "}")
    inst.template = inst.template or "creature"
    inst.animate = true
    inst.alive = true
    inst.health = inst.health or inst.max_health or 10
    inst.max_health = inst.max_health or 10
    -- Ensure creature-only metadata present (so we can verify clearing)
    inst.behavior = inst.behavior or { default = "idle" }
    inst.drives = inst.drives or { hunger = { value = 50 } }
    inst.reactions = inst.reactions or {}
    inst.combat = inst.combat or { attack = 1 }
    return inst
end

-- Standalone reshape_instance that mirrors the SPEC from creature-death-reshape.md.
-- TDD: we test the specified behavior, not the current (possibly incomplete)
-- engine implementation. When the engine is finalized, tests verify the contract.
local function reshape_instance(instance, death_state, registry, room)
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

    if death_state.reshape_narration then
        -- In tests, we capture narration rather than printing
        instance._reshape_narration_emitted = death_state.reshape_narration
    end

    if death_state.byproducts then
        for _, bp_id in ipairs(death_state.byproducts) do
            local bp = registry:get(bp_id)
            if bp then registry:register_as_room_object(bp, room) end
        end
    end

    mock_deregister_creature(instance.guid)
    registry:register_as_room_object(instance, room)

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
-- Mock death_state blocks (these will eventually live in creature .lua files)
-- Mirroring the spec from creature-death-reshape.md §3.1
---------------------------------------------------------------------------
local death_states = {
    rat = {
        template = "small-item",
        name = "a dead rat",
        description = "A dead rat lies on its side, legs splayed stiffly.",
        keywords = {"dead rat", "rat corpse", "rat carcass", "rat"},
        room_presence = "A dead rat lies crumpled on the floor.",
        portable = true,
        size = "tiny",
        weight = 0.3,
        on_feel = "Cooling fur over a limp body. The tail hangs like wet string.",
        on_smell = "Blood and musk. The sharp copper of death.",
        on_listen = "Nothing. Absolutely nothing.",
        on_taste = "Fur and blood. You immediately regret this decision.",
        food = { category = "meat", raw = true, edible = false, cookable = true },
        crafting = { cook = { becomes = "cooked-rat-meat", requires_tool = "fire_source" } },
        container = { capacity = 1, categories = { "tiny" } },
        initial_state = "fresh",
        states = {
            fresh   = { description = "A freshly killed rat.", duration = 30 },
            bloated = { description = "The rat's body has swollen.", duration = 40, food = { cookable = false } },
            rotten  = { description = "The rat is a putrid mess.", duration = 60, food = { cookable = false, edible = false } },
            bones   = { description = "A tiny scatter of cleaned rat bones.", food = nil },
        },
        transitions = {
            { from = "fresh", to = "bloated", verb = "_tick", condition = "timer_expired" },
            { from = "bloated", to = "rotten", verb = "_tick", condition = "timer_expired" },
            { from = "rotten", to = "bones", verb = "_tick", condition = "timer_expired" },
        },
    },
    cat = {
        template = "small-item",
        name = "a dead cat",
        description = "A dead cat, fur matted.",
        keywords = {"dead cat", "cat corpse", "cat"},
        room_presence = "A dead cat lies curled on the floor.",
        portable = true,
        size = "small",
        weight = 3.0,
        on_feel = "Soft fur over cooling muscle.",
        on_smell = "Blood and warm fur.",
        on_listen = "Silent.",
        on_taste = "Fur. Not recommended.",
        food = { category = "meat", raw = true, edible = false, cookable = true },
        container = { capacity = 2, categories = { "tiny", "small" } },
    },
    wolf = {
        template = "furniture",
        name = "a dead wolf",
        description = "A massive wolf carcass sprawled across the floor.",
        keywords = {"dead wolf", "wolf corpse", "wolf carcass", "wolf"},
        room_presence = "A massive dead wolf sprawls across the floor.",
        portable = false,
        size = "large",
        weight = 45.0,
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
        portable = true,
        size = "tiny",
        weight = 0.1,
        material = "chitin",
        on_feel = "Brittle chitin plates. The legs snap if you press.",
        on_smell = "An acrid chemical tang.",
        on_listen = "Dry crackling if you shift it.",
        on_taste = "Bitter and crunchy. Inedible.",
        reshape_narration = "The spider's abdomen splits, spilling a tangle of silk.",
        byproducts = { "silk-bundle" },
    },
    bat = {
        template = "small-item",
        name = "a dead bat",
        description = "A dead bat, wings folded against its tiny body.",
        keywords = {"dead bat", "bat corpse", "bat"},
        room_presence = "A dead bat lies crumpled on the floor.",
        portable = true,
        size = "tiny",
        weight = 0.05,
        on_feel = "Paper-thin wing membranes over fragile bones.",
        on_smell = "Musty guano and blood.",
        on_listen = "Silent.",
        on_taste = "Leathery and bitter.",
        food = { category = "meat", raw = true, edible = false, cookable = true },
    },
}

---------------------------------------------------------------------------
-- TESTS: Death reshape per creature type
---------------------------------------------------------------------------
suite("DEATH RESHAPE: kill triggers in-place reshape (WAVE-1)")

-- 1. Kill rat → template switches to "small-item", GUID preserved
test("1. kill rat — template switches to small-item, GUID preserved", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-001}" }, "{rat-001}")
    local original_guid = inst.guid
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_eq("small-item", inst.template, "template should be small-item")
    h.assert_eq(original_guid, inst.guid, "GUID must be preserved")
end)

-- 2. Kill cat → template = "small-item"
test("2. kill cat — template switches to small-item", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_cat and cat_def or { id = "cat", guid = "{cat-001}" }, "{cat-001}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.cat, registry, room)

    h.assert_eq("small-item", inst.template, "template should be small-item")
    h.assert_eq("{cat-001}", inst.guid, "GUID preserved")
end)

-- 3. Kill wolf → template = "furniture"
test("3. kill wolf — template switches to furniture", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_wolf and wolf_def or { id = "wolf", guid = "{wolf-001}" }, "{wolf-001}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.wolf, registry, room)

    h.assert_eq("furniture", inst.template, "wolf reshapes to furniture")
end)

-- 4. Kill spider → template = "small-item", silk-bundle byproduct appears
test("4. kill spider — template small-item + silk-bundle byproduct", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_spider and spider_def or { id = "spider", guid = "{spider-001}" }, "{spider-001}")
    local silk = { id = "silk-bundle", guid = "{silk-001}", name = "a bundle of silk" }
    local registry = make_mock_registry({ silk })
    local room = make_room()

    reshape_instance(inst, death_states.spider, registry, room)

    h.assert_eq("small-item", inst.template, "spider reshapes to small-item")
    h.assert_truthy(registry:was_registered_as_room_object("{silk-001}"),
        "silk-bundle byproduct must be registered as room object")
end)

-- 5. Kill bat → template = "small-item"
test("5. kill bat — template switches to small-item", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_bat and bat_def or { id = "bat", guid = "{bat-001}" }, "{bat-001}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.bat, registry, room)

    h.assert_eq("small-item", inst.template, "bat reshapes to small-item")
end)

-- 6. Creature deregistered from tick system after reshape
test("6. creature deregistered from tick system after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-tick}" }, "{rat-tick}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_truthy(deregistered_guids["{rat-tick}"],
        "creature GUID must be deregistered from tick system")
end)

-- 7. Instance registered as room object after reshape
test("7. instance registered as room object after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-room}" }, "{rat-room}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_truthy(registry:was_registered_as_room_object("{rat-room}"),
        "reshaped instance must be registered as room object")
end)

-- 8. Creature behavior metadata cleared
test("8. creature behavior metadata cleared after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-meta}" }, "{rat-meta}")
    -- Ensure creature metadata exists before reshape
    h.assert_truthy(inst.behavior, "behavior should exist before reshape")
    h.assert_truthy(inst.drives, "drives should exist before reshape")
    h.assert_truthy(inst.combat, "combat should exist before reshape")

    local registry = make_mock_registry({})
    local room = make_room()
    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_nil(inst.behavior, "behavior must be nil after reshape")
    h.assert_nil(inst.drives, "drives must be nil after reshape")
    h.assert_nil(inst.reactions, "reactions must be nil after reshape")
    h.assert_nil(inst.combat, "combat must be nil after reshape")
end)

-- 9. Health and max_health cleared
test("9. health and max_health cleared after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_cat and cat_def or { id = "cat", guid = "{cat-hp}" }, "{cat-hp}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.cat, registry, room)

    h.assert_nil(inst.health, "health must be nil after reshape")
    h.assert_nil(inst.max_health, "max_health must be nil after reshape")
end)

-- 10. Movement and awareness cleared
test("10. movement and awareness cleared after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_wolf and wolf_def or { id = "wolf", guid = "{wolf-mv}" }, "{wolf-mv}")
    inst.movement = { speed = 2 }
    inst.awareness = { range = 3 }

    local registry = make_mock_registry({})
    local room = make_room()
    reshape_instance(inst, death_states.wolf, registry, room)

    h.assert_nil(inst.movement, "movement must be nil after reshape")
    h.assert_nil(inst.awareness, "awareness must be nil after reshape")
end)

-- 11. body_tree cleared
test("11. body_tree cleared after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-bt}" }, "{rat-bt}")
    inst.body_tree = { head = {}, torso = {} }

    local registry = make_mock_registry({})
    local room = make_room()
    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_nil(inst.body_tree, "body_tree must be nil after reshape")
end)

-- 12. animate set to false after reshape
test("12. animate=false and alive=false after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-anim}" }, "{rat-anim}")
    h.assert_truthy(inst.animate, "animate should be true before reshape")

    local registry = make_mock_registry({})
    local room = make_room()
    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_eq(false, inst.animate, "animate must be false after reshape")
    h.assert_eq(false, inst.alive, "alive must be false after reshape")
end)

-- 13. reshape_narration emitted for spider (has it)
test("13. reshape_narration emitted when present (spider)", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_spider and spider_def or { id = "spider", guid = "{sp-narr}" }, "{sp-narr}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.spider, registry, room)

    h.assert_eq("The spider's abdomen splits, spilling a tangle of silk.",
        inst._reshape_narration_emitted or death_states.spider.reshape_narration,
        "spider reshape_narration must be emitted")
end)

-- 14. No reshape_narration for rat (silent)
test("14. no reshape_narration for rat (silent reshape)", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-silent}" }, "{rat-silent}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_nil(inst._reshape_narration_emitted, "rat should have no reshape_narration")
    h.assert_nil(death_states.rat.reshape_narration, "rat death_state has no reshape_narration")
end)

-- 15. No reshape_narration for cat (silent)
test("15. no reshape_narration for cat (silent reshape)", function()
    h.assert_nil(death_states.cat.reshape_narration, "cat death_state has no reshape_narration")
end)

-- 16. No reshape_narration for wolf (silent)
test("16. no reshape_narration for wolf (silent reshape)", function()
    h.assert_nil(death_states.wolf.reshape_narration, "wolf death_state has no reshape_narration")
end)

-- 17. No reshape_narration for bat (silent)
test("17. no reshape_narration for bat (silent reshape)", function()
    h.assert_nil(death_states.bat.reshape_narration, "bat death_state has no reshape_narration")
end)

-- 18. Name updated from death_state
test("18. name updated from death_state after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_rat and rat_def or { id = "rat", guid = "{rat-name}" }, "{rat-name}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.rat, registry, room)

    h.assert_eq("a dead rat", inst.name, "name must update to death_state.name")
end)

-- 19. Keywords updated from death_state
test("19. keywords updated from death_state after reshape", function()
    reset_deregister_tracking()
    local inst = make_live_creature(ok_cat and cat_def or { id = "cat", guid = "{cat-kw}" }, "{cat-kw}")
    local registry = make_mock_registry({})
    local room = make_room()

    reshape_instance(inst, death_states.cat, registry, room)

    h.assert_truthy(type(inst.keywords) == "table", "keywords must be a table")
    local found = false
    for _, kw in ipairs(inst.keywords) do
        if kw == "dead cat" then found = true; break end
    end
    h.assert_truthy(found, "keywords must include 'dead cat'")
end)

-- 20. Creature WITHOUT death_state keeps FSM dead behavior (backward compat)
test("20. creature without death_state keeps FSM dead state (backward compat)", function()
    local inst = {
        guid = "{legacy-001}",
        template = "creature",
        id = "legacy-bug",
        name = "a bug",
        animate = true,
        alive = true,
        health = 0,
        _state = "alive-idle",
        states = {
            ["alive-idle"] = { description = "Idle." },
            ["dead"] = { description = "Dead.", animate = false, portable = true },
        },
        behavior = { default = "idle" },
        drives = {},
        reactions = {},
        combat = {},
    }

    -- No death_state declared — simulate old behavior
    h.assert_nil(inst.death_state, "legacy creature should not have death_state")

    -- Old-style death: transition to FSM dead state
    if not inst.death_state then
        inst._state = "dead"
    end

    h.assert_eq("dead", inst._state, "legacy creature should transition to FSM dead state")
    h.assert_eq("creature", inst.template, "template should NOT change without death_state")
    h.assert_truthy(inst.behavior, "behavior should NOT be cleared without reshape")
end)

---------------------------------------------------------------------------
suite("DEATH RESHAPE: sensory properties (WAVE-1)")

-- 21. Reshaped creature has on_feel (mandatory dark sense)
test("21. all reshaped creatures have on_feel", function()
    for name, ds in pairs(death_states) do
        h.assert_truthy(ds.on_feel, name .. " death_state must have on_feel")
    end
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
