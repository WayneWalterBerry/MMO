-- test/creatures/test-bug319-retreat-maxhealth.lua
-- Bug #319: Wolf never retreats — max_health lookup bug
-- The combat flee check in verbs/init.lua uses creature.combat.max_health
-- (nil) and creature.combat.flee_threshold (nil). Both are wrong paths.
-- Correct: creature.max_health and creature.combat.behavior.flee_threshold.
-- TDD: Must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/creatures/test-bug319-retreat-maxhealth.lua

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
-- Load verb module
---------------------------------------------------------------------------
local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
h.assert_truthy(verbs_ok, "engine.verbs must load: " .. tostring(verbs_mod))

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{bug319-" .. guid_counter .. "}"
end

local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function make_creature(overrides)
    local c = {
        guid = next_guid(),
        id = "wolf",
        name = "a grey wolf",
        keywords = {"wolf"},
        animate = true,
        health = overrides.health or 22,
        max_health = overrides.max_health or 22,
        _state = overrides._state or "alive-aggressive",
        states = {
            ["alive-aggressive"] = { room_presence = "A snarling wolf." },
            ["alive-flee"] = { room_presence = "A wounded wolf limps." },
            fled = { room_presence = "" },
            dead = { room_presence = "A dead wolf." },
        },
        combat = {
            size = "medium",
            speed = 5,
            natural_weapons = {
                { id = "bite", type = "pierce", material = "tooth-enamel",
                  zone = "head", force = 5, message = "bites" },
            },
            behavior = {
                aggression = "territorial",
                flee_threshold = 0.2,
                attack_pattern = "sustained",
                defense = "counter",
            },
        },
        behavior = { flee_threshold = 20 },
        body_tree = {
            head = { size = 2, vital = true, tissue = {"hide","flesh","bone"} },
            body = { size = 5, vital = true, tissue = {"hide","flesh","bone"} },
        },
    }
    for k, v in pairs(overrides) do c[k] = v end
    return c
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #319: Wolf retreat max_health lookup")

test("1. creature.combat.max_health is nil — verify data shape", function()
    local wolf = make_creature({ health = 4, max_health = 22 })
    h.assert_eq(wolf.max_health, 22, "max_health at creature level must be 22")
    h.assert_eq(wolf.combat.max_health, nil, "combat.max_health must be nil (it lives on creature)")
    h.assert_eq(wolf.combat.flee_threshold, nil, "combat.flee_threshold must be nil (it's in combat.behavior)")
    h.assert_eq(wolf.combat.behavior.flee_threshold, 0.2, "combat.behavior.flee_threshold must be 0.2")
end)

test("2. hp_pct calculation uses correct max_health", function()
    -- Bug: creature.combat.max_health is nil → fallback to creature.health → ratio = 1.0
    -- Fix: use creature.max_health → ratio = 4/22 = 0.18
    local wolf = make_creature({ health = 4, max_health = 22 })
    local max_hp = wolf.max_health or wolf.health or 10
    local hp_pct = wolf.health / max_hp
    h.assert_truthy(hp_pct < 0.20,
        "hp_pct must be < 0.20 (got " .. hp_pct .. "), using creature.max_health")

    -- Verify the BUGGY path yields wrong result
    local buggy_max = wolf.combat.max_health or wolf.health or 10
    local buggy_pct = wolf.health / buggy_max
    h.assert_eq(buggy_pct, 1.0,
        "buggy path (combat.max_health → health) yields 1.0, never retreats")
end)

test("3. flee_threshold lookup uses combat.behavior.flee_threshold", function()
    local wolf = make_creature({ health = 4, max_health = 22 })
    -- Correct path
    local threshold = wolf.combat and wolf.combat.behavior
        and wolf.combat.behavior.flee_threshold
    h.assert_eq(threshold, 0.2, "threshold must be 0.2 from combat.behavior")

    -- Buggy path: creature.combat.flee_threshold is nil
    local buggy_threshold = wolf.combat and wolf.combat.flee_threshold
    h.assert_eq(buggy_threshold, nil, "combat.flee_threshold is nil (wrong path)")
end)

test("4. attack verb flee check triggers at <20% health", function()
    -- This test exercises the ACTUAL verb handler's flee check.
    -- We create a mock combat scenario: wolf at 4/22 hp = 18% < 20%.
    -- The handler should print a flee message.
    local handlers = verbs_mod.create()
    local attack_fn = handlers["attack"]
    h.assert_truthy(attack_fn, "attack handler must exist")

    local wolf = make_creature({ health = 4, max_health = 22 })
    wolf.location = "test-room"

    local reg_objects = {}
    reg_objects[wolf.guid] = wolf
    reg_objects[wolf.id] = wolf

    local reg = {
        _objects = reg_objects,
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
        list = function(self)
            local r = {}
            local seen = {}
            for _, obj in pairs(self._objects) do
                if type(obj) == "table" and not seen[obj] then
                    seen[obj] = true
                    r[#r + 1] = obj
                end
            end
            return r
        end,
    }

    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A test room.",
        contents = { wolf.id },
        exits = { north = { target = "hallway" } },
    }

    local player = {
        hands = { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
        skills = {},
        max_health = 100,
        health = 100,
        consciousness = { state = "conscious" },
        visited_rooms = { ["test-room"] = true },
    }

    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        headless = true,
        time_offset = 6,
        game_start_time = os.time(),
        current_verb = "attack",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }

    local output = capture_output(function()
        attack_fn(ctx, "wolf")
    end)

    -- Wolf at 18% should flee during combat
    local fled = output:find("[Ff]lee") or output:find("[Tt]urns and flees")
        or wolf._state == "fled" or wolf._state == "alive-flee"
    h.assert_truthy(fled,
        "wolf at 18% health must flee (state=" .. tostring(wolf._state) ..
        "), output: " .. output:sub(1, 200))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
