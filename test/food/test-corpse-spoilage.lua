-- test/food/test-corpse-spoilage.lua
-- WAVE-1 TDD: Validates spoilage FSM on reshaped corpses.
-- fresh → bloated → rotten → bones, timer-driven transitions.
-- Must be run from repository root: lua test/food/test-corpse-spoilage.lua

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
-- Spoilage FSM definition (from creature-death-reshape.md §3.4)
-- This is the death_state for rat with full spoilage — used as the
-- canonical spoilage test subject.
---------------------------------------------------------------------------
local rat_death_state = {
    template = "small-item",
    name = "a dead rat",
    description = "A dead rat lies on its side, legs splayed stiffly.",
    keywords = {"dead rat", "rat corpse", "rat carcass", "rat"},
    room_presence = "A dead rat lies crumpled on the floor.",
    portable = true,
    size = "tiny",
    weight = 0.3,
    on_feel = "Cooling fur over a limp body.",
    on_smell = "Blood and musk.",
    on_listen = "Nothing.",
    on_taste = "Fur and blood.",
    food = { category = "meat", raw = true, edible = false, cookable = true },
    initial_state = "fresh",
    states = {
        fresh = {
            description = "A freshly killed rat.",
            room_presence = "A dead rat lies crumpled on the floor.",
            on_smell = "Blood and musk. The sharp copper of death.",
            duration = 30,
        },
        bloated = {
            description = "The rat's body has swollen grotesquely.",
            room_presence = "A bloated rat carcass lies on the floor, reeking.",
            on_smell = "The sweet, cloying stench of decay.",
            food = { cookable = false },
            duration = 40,
        },
        rotten = {
            description = "The rat is a putrid mess of matted fur and liquefying flesh.",
            room_presence = "A rotting rat carcass festers on the floor.",
            on_smell = "Overwhelming rot. Your eyes water.",
            food = { cookable = false, edible = false },
            duration = 60,
        },
        bones = {
            description = "A tiny scatter of cleaned rat bones.",
            room_presence = "A small pile of rat bones sits on the floor.",
            on_smell = "Nothing — just dry bone.",
            on_feel = "Tiny, fragile bones. They click together.",
            clear_food = true, -- signals food removal (Lua tables can't store nil)
        },
    },
    transitions = {
        { from = "fresh", to = "bloated", verb = "_tick", condition = "timer_expired" },
        { from = "bloated", to = "rotten", verb = "_tick", condition = "timer_expired" },
        { from = "rotten", to = "bones", verb = "_tick", condition = "timer_expired" },
    },
}

-- Create a reshaped dead rat corpse with spoilage FSM applied
local function make_dead_rat()
    local inst = {
        guid = "{dead-rat-spoil}",
        id = "rat",
        template = "small-item",
        animate = false,
        alive = false,
        portable = true,
        name = rat_death_state.name,
        description = rat_death_state.description,
        on_feel = rat_death_state.on_feel,
        on_smell = rat_death_state.on_smell,
        on_listen = rat_death_state.on_listen,
        on_taste = rat_death_state.on_taste,
        room_presence = rat_death_state.room_presence,
        food = deep_copy(rat_death_state.food),
        states = deep_copy(rat_death_state.states),
        initial_state = "fresh",
        _state = "fresh",
        transitions = deep_copy(rat_death_state.transitions),
        _tick_counter = 0,
    }
    return inst
end

-- Simulate spoilage tick: advance tick counter, check for transition.
-- In the real engine, FSM processes _tick transitions when duration expires.
-- This mock simulates that: if current state has a duration and counter
-- reaches it, transition to the next state per the transitions table.
local function advance_ticks(inst, n)
    for _ = 1, n do
        inst._tick_counter = (inst._tick_counter or 0) + 1
        local current = inst._state
        local state_def = inst.states and inst.states[current]
        if state_def and state_def.duration and inst._tick_counter >= state_def.duration then
            -- Find matching transition
            for _, tr in ipairs(inst.transitions or {}) do
                if tr.from == current and tr.verb == "_tick" then
                    inst._state = tr.to
                    -- Apply state-level property overrides
                    local new_state = inst.states[tr.to]
                    if new_state then
                        if new_state.description then inst.description = new_state.description end
                        if new_state.room_presence then inst.room_presence = new_state.room_presence end
                        if new_state.on_smell then inst.on_smell = new_state.on_smell end
                        if new_state.on_feel then inst.on_feel = new_state.on_feel end
                        if new_state.clear_food then
                            inst.food = nil
                        elseif new_state.food ~= nil then
                            inst.food = new_state.food
                        end
                    end
                    inst._tick_counter = 0
                    break
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- TESTS: Corpse spoilage FSM
---------------------------------------------------------------------------
suite("CORPSE SPOILAGE: FSM lifecycle (WAVE-1)")

-- 1. Dead rat starts in "fresh" state
test("1. dead rat starts in fresh state", function()
    local rat = make_dead_rat()
    h.assert_eq("fresh", rat._state, "dead rat must start in fresh state")
end)

-- 2. After 30 ticks → transitions to "bloated"
test("2. after 30 ticks transitions to bloated", function()
    local rat = make_dead_rat()
    advance_ticks(rat, 30)
    h.assert_eq("bloated", rat._state, "rat must transition to bloated after 30 ticks")
end)

-- 3. After 40 more ticks → transitions to "rotten"
test("3. after 40 more ticks transitions to rotten", function()
    local rat = make_dead_rat()
    advance_ticks(rat, 30) -- → bloated
    advance_ticks(rat, 40) -- → rotten
    h.assert_eq("rotten", rat._state, "rat must transition to rotten after 40 more ticks")
end)

-- 4. After 60 more ticks → transitions to "bones"
test("4. after 60 more ticks transitions to bones", function()
    local rat = make_dead_rat()
    advance_ticks(rat, 30) -- → bloated
    advance_ticks(rat, 40) -- → rotten
    advance_ticks(rat, 60) -- → bones
    h.assert_eq("bones", rat._state, "rat must transition to bones after 60 more ticks")
end)

-- 5. Spoilage changes description
test("5. spoilage changes description at each state", function()
    local rat = make_dead_rat()
    local fresh_desc = rat.description

    advance_ticks(rat, 30) -- → bloated
    h.assert_truthy(rat.description ~= fresh_desc,
        "description must change when transitioning to bloated")

    local bloated_desc = rat.description
    advance_ticks(rat, 40) -- → rotten
    h.assert_truthy(rat.description ~= bloated_desc,
        "description must change when transitioning to rotten")
end)

-- 6. Spoilage changes room_presence
test("6. spoilage changes room_presence", function()
    local rat = make_dead_rat()
    local fresh_rp = rat.room_presence

    advance_ticks(rat, 30) -- → bloated
    h.assert_truthy(rat.room_presence ~= fresh_rp,
        "room_presence must change when transitioning to bloated")
end)

-- 7. Spoilage changes on_smell
test("7. spoilage changes on_smell", function()
    local rat = make_dead_rat()
    local fresh_smell = rat.on_smell

    advance_ticks(rat, 30) -- → bloated
    h.assert_truthy(rat.on_smell ~= fresh_smell,
        "on_smell must change when transitioning to bloated")
end)

-- 8. Bloated rat is not cookable
test("8. bloated rat is not cookable", function()
    local rat = make_dead_rat()
    h.assert_eq(true, rat.food.cookable, "fresh rat must be cookable")

    advance_ticks(rat, 30) -- → bloated
    h.assert_truthy(rat.food, "bloated rat must have food table")
    h.assert_eq(false, rat.food.cookable, "bloated rat must NOT be cookable")
end)

-- 9. Rotten rat is not edible
test("9. rotten rat is not edible", function()
    local rat = make_dead_rat()
    advance_ticks(rat, 30) -- → bloated
    advance_ticks(rat, 40) -- → rotten

    h.assert_truthy(rat.food, "rotten rat must have food table")
    h.assert_eq(false, rat.food.edible, "rotten rat must NOT be edible")
end)

-- 10. Bones state has no food properties
test("10. bones state removes food properties", function()
    local rat = make_dead_rat()
    advance_ticks(rat, 30) -- → bloated
    advance_ticks(rat, 40) -- → rotten
    advance_ticks(rat, 60) -- → bones

    h.assert_nil(rat.food, "bones state must have no food properties")
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
