-- test/creatures/test-reshaped-corpse-properties.lua
-- WAVE-1 TDD: Validates properties of reshaped corpses — portability, sensory,
-- food, container, size, keywords, name. Each creature's death form is tested.
-- Must be run from repository root: lua test/creatures/test-reshaped-corpse-properties.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

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
-- Mock factory (minimal — just enough for reshape)
---------------------------------------------------------------------------
local function make_mock_registry(objects)
    local reg = { _objects = {}, _room_objects = {} }
    for _, obj in ipairs(objects or {}) do
        reg._objects[obj.guid or obj.id] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] end
    function reg:register_as_room_object(instance, room)
        self._room_objects[instance.guid or instance.id] = true
    end
    return reg
end

local function make_room()
    return { id = "test-room", name = "Test Room", template = "room", contents = {} }
end

---------------------------------------------------------------------------
-- Death state definitions (spec from creature-death-reshape.md)
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
            bloated = { description = "The rat's body has swollen.", duration = 40 },
            rotten  = { description = "The rat is a putrid mess.", duration = 60 },
            bones   = { description = "A tiny scatter of cleaned rat bones." },
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
        byproducts = { "silk-bundle" },
        reshape_narration = "The spider's abdomen splits, spilling a tangle of silk.",
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

-- Apply reshape to a mock creature, return the reshaped instance
local function reshape_and_return(creature_id, ds)
    local inst = {
        guid = "{" .. creature_id .. "-prop}",
        id = creature_id,
        template = "creature",
        animate = true,
        alive = true,
        health = 10,
        max_health = 10,
        behavior = { default = "idle" },
        drives = {},
        reactions = {},
        combat = {},
    }
    local registry = make_mock_registry({})
    local room = make_room()

    -- Apply reshape in-place
    inst.template = ds.template
    inst.name = ds.name
    inst.description = ds.description
    inst.keywords = ds.keywords
    inst.room_presence = ds.room_presence
    inst.on_feel = ds.on_feel
    inst.on_smell = ds.on_smell
    inst.on_listen = ds.on_listen
    inst.on_taste = ds.on_taste
    inst.portable = ds.portable
    inst.size = ds.size or inst.size
    inst.weight = ds.weight or inst.weight
    inst.animate = false
    inst.alive = false
    if ds.food then inst.food = ds.food end
    if ds.crafting then inst.crafting = ds.crafting end
    if ds.container then inst.container = ds.container end
    if ds.states then
        inst.states = ds.states
        inst.initial_state = ds.initial_state or "fresh"
        inst._state = inst.initial_state
        inst.transitions = ds.transitions
    end
    inst.behavior = nil
    inst.drives = nil
    inst.reactions = nil
    inst.combat = nil
    inst.health = nil
    inst.max_health = nil

    return inst
end

---------------------------------------------------------------------------
-- TESTS: Dead rat properties
---------------------------------------------------------------------------
suite("RESHAPED CORPSE PROPERTIES: dead rat")

test("1. dead rat is portable", function()
    local r = reshape_and_return("rat", death_states.rat)
    h.assert_eq(true, r.portable, "dead rat must be portable")
end)

test("2. dead rat has on_feel", function()
    local r = reshape_and_return("rat", death_states.rat)
    h.assert_truthy(r.on_feel, "dead rat must have on_feel (dark sense)")
end)

test("3. dead rat has on_smell", function()
    local r = reshape_and_return("rat", death_states.rat)
    h.assert_truthy(r.on_smell, "dead rat must have on_smell")
end)

test("4. dead rat food.cookable=true", function()
    local r = reshape_and_return("rat", death_states.rat)
    h.assert_truthy(r.food, "dead rat must have food properties")
    h.assert_eq(true, r.food.cookable, "dead rat food.cookable must be true")
end)

---------------------------------------------------------------------------
suite("RESHAPED CORPSE PROPERTIES: dead cat")

test("5. dead cat is portable", function()
    local r = reshape_and_return("cat", death_states.cat)
    h.assert_eq(true, r.portable, "dead cat must be portable")
end)

test("6. dead cat container.capacity=2", function()
    local r = reshape_and_return("cat", death_states.cat)
    h.assert_truthy(r.container, "dead cat must have container properties")
    h.assert_eq(2, r.container.capacity, "dead cat container capacity must be 2")
end)

test("7. dead cat food.cookable=true", function()
    local r = reshape_and_return("cat", death_states.cat)
    h.assert_truthy(r.food, "dead cat must have food properties")
    h.assert_eq(true, r.food.cookable, "dead cat food.cookable must be true")
end)

---------------------------------------------------------------------------
suite("RESHAPED CORPSE PROPERTIES: dead wolf")

test("8. dead wolf is NOT portable (furniture)", function()
    local r = reshape_and_return("wolf", death_states.wolf)
    h.assert_eq(false, r.portable, "dead wolf must NOT be portable")
end)

test("9. dead wolf template is furniture", function()
    local r = reshape_and_return("wolf", death_states.wolf)
    h.assert_eq("furniture", r.template, "dead wolf template must be furniture")
end)

test("10. dead wolf container.capacity=5", function()
    local r = reshape_and_return("wolf", death_states.wolf)
    h.assert_truthy(r.container, "dead wolf must have container properties")
    h.assert_eq(5, r.container.capacity, "dead wolf container capacity must be 5")
end)

test("11. dead wolf food.cookable=false (too big)", function()
    local r = reshape_and_return("wolf", death_states.wolf)
    h.assert_truthy(r.food, "dead wolf must have food properties")
    h.assert_eq(false, r.food.cookable, "dead wolf food.cookable must be false (too big to cook whole)")
end)

---------------------------------------------------------------------------
suite("RESHAPED CORPSE PROPERTIES: dead spider")

test("12. dead spider is portable", function()
    local r = reshape_and_return("spider", death_states.spider)
    h.assert_eq(true, r.portable, "dead spider must be portable")
end)

test("13. dead spider is NOT edible (chitin)", function()
    local r = reshape_and_return("spider", death_states.spider)
    h.assert_nil(r.food, "dead spider must have no food properties (chitin, inedible)")
end)

test("14. dead spider is NOT a container", function()
    local r = reshape_and_return("spider", death_states.spider)
    h.assert_nil(r.container, "dead spider must not be a container")
end)

test("15. dead spider material is chitin", function()
    h.assert_eq("chitin", death_states.spider.material, "spider death_state material must be chitin")
end)

---------------------------------------------------------------------------
suite("RESHAPED CORPSE PROPERTIES: dead bat")

test("16. dead bat is portable", function()
    local r = reshape_and_return("bat", death_states.bat)
    h.assert_eq(true, r.portable, "dead bat must be portable")
end)

test("17. dead bat food.cookable=true", function()
    local r = reshape_and_return("bat", death_states.bat)
    h.assert_truthy(r.food, "dead bat must have food properties")
    h.assert_eq(true, r.food.cookable, "dead bat food.cookable must be true")
end)

test("18. dead bat size is tiny", function()
    local r = reshape_and_return("bat", death_states.bat)
    h.assert_eq("tiny", r.size, "dead bat size must be tiny")
end)

---------------------------------------------------------------------------
suite("RESHAPED CORPSE PROPERTIES: universal invariants")

test("19. all reshaped corpses have on_feel (dark sense requirement)", function()
    for name, ds in pairs(death_states) do
        h.assert_truthy(ds.on_feel, name .. " death_state must have on_feel")
    end
end)

test("20. all reshaped corpses have name", function()
    for name, ds in pairs(death_states) do
        h.assert_truthy(ds.name, name .. " death_state must have name")
    end
end)

test("21. all reshaped corpses have keywords", function()
    for name, ds in pairs(death_states) do
        h.assert_truthy(ds.keywords, name .. " death_state must have keywords")
        h.assert_truthy(#ds.keywords > 0, name .. " keywords must be non-empty")
    end
end)

test("22. all reshaped corpses have room_presence", function()
    for name, ds in pairs(death_states) do
        h.assert_truthy(ds.room_presence, name .. " death_state must have room_presence")
    end
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
