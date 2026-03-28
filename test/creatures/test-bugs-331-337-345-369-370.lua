-- test/creatures/test-bugs-331-337-345-369-370.lua
-- TDD tests for 5 creature/combat bugs found in playtesting.
--
-- #369: Combat targets 'knee' on spider despite body_tree not having knee
-- #337: Spider body zones reference human anatomy in combat
-- #370: Death message should use 'the rat' not 'a brown rat' after first mention
-- #345: Death messages use lowercase article: 'a brown rat is dead!'
-- #331: attack dead creature says 'don't see' instead of 'already dead'
--
-- Usage: lua test/creatures/test-bugs-331-337-345-369-370.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite
local eq = h.assert_eq

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
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

local function load_creature(name)
    local path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. name .. ".lua"
    local ok, def = pcall(dofile, path)
    if not ok then error("Failed to load " .. name .. ".lua: " .. tostring(def)) end
    return def
end

local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
    }
end

local function base_player()
    return {
        max_health = 100, health = 100,
        injuries = {}, hands = { nil, nil },
        worn_items = {}, bags = {}, worn = {},
        state = {}, location = "test-room",
    }
end

local function base_room()
    return {
        id = "test-room", name = "Test Room",
        description = "A test room.",
        contents = {}, exits = {}, light_level = 1,
    }
end

local function make_ctx(reg, room, player)
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "attack",
        injuries = player.injuries,
        known_objects = {},
        headless = true,
    }
end

---------------------------------------------------------------------------
-- #369/#337: Spider body_tree should use spider-specific zone names
---------------------------------------------------------------------------
suite("#369/#337: Spider body zones must not reference human anatomy")

test("spider body_tree has no human-only zones", function()
    local spider = load_creature("spider")
    local human_zones = { knee = true, thigh = true, shin = true, haunch = true,
                          arm = true, forearm = true, shoulder = true,
                          hand = true, foot = true, ankle = true }
    for zone, _ in pairs(spider.body_tree) do
        h.assert_truthy(not human_zones[zone],
            "#369: spider body_tree should not have human zone '" .. zone .. "'")
    end
end)

test("spider body_tree zones have narration names", function()
    local spider = load_creature("spider")
    for zone, info in pairs(spider.body_tree) do
        h.assert_truthy(info.names and #info.names > 0,
            "#337: spider body_tree zone '" .. zone .. "' must have names for narration")
    end
end)

test("spider zone names don't include human anatomy words", function()
    local spider = load_creature("spider")
    local human_words = { knee = true, thigh = true, shin = true, haunch = true,
                          forearm = true, shoulder = true, ankle = true, foot = true }
    for zone, info in pairs(spider.body_tree) do
        if info.names then
            for _, name in ipairs(info.names) do
                h.assert_truthy(not human_words[name:lower()],
                    "#337: spider zone '" .. zone .. "' name '" .. name .. "' is human anatomy")
            end
        end
    end
end)

test("narration uses spider body_tree names instead of defaults", function()
    local narration_ok, narration = pcall(require, "engine.combat.narration")
    if not narration_ok then
        h.assert_truthy(false, "#369: could not load narration module")
        return
    end

    local spider = load_creature("spider")
    local result = {
        severity = narration.SEVERITY.HIT,
        attacker = { id = "player", is_player = true },
        defender = spider,
        zone = "legs",
        tissue_hit = "chitin",
        material_name = "iron",
        action_verb = "hacks into",
    }

    local human_words = { thigh = true, shin = true, knee = true, haunch = true }
    local found_human = false
    for _ = 1, 100 do
        local text = narration.generate(result, true)
        for word in text:lower():gmatch("%w+") do
            if human_words[word] then
                found_human = true
                h.assert_truthy(false,
                    "#369: narration for spider 'legs' zone produced human word '" .. word .. "': " .. text)
                break
            end
        end
        if found_human then break end
    end
    if not found_human then
        h.assert_truthy(true, "#369: no human anatomy in 100 spider combat narrations")
    end
end)

test("rat body_tree zones have narration names", function()
    local rat = load_creature("rat")
    for zone, info in pairs(rat.body_tree) do
        h.assert_truthy(info.names and #info.names > 0,
            "#337: rat body_tree zone '" .. zone .. "' must have names for narration")
    end
end)

---------------------------------------------------------------------------
-- #345/#370: Death message formatting
---------------------------------------------------------------------------
suite("#345/#370: Death message capitalization and article")

test("death message uses capitalized definite article", function()
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    -- Create a live creature that will die in one hit
    local rat = {
        id = "rat", name = "a brown rat",
        keywords = {"rat", "brown rat"},
        animate = true, alive = true,
        _state = "alive-idle",
        health = 1, max_health = 5,
        location = "test-room",
        body_tree = {
            body = { size = 2, vital = true, tissue = { "hide", "flesh" },
                names = { "body", "flank" } },
        },
        combat = {
            size = "tiny", speed = 3,
            natural_weapons = {
                { id = "bite", type = "pierce", material = "tooth-enamel",
                  zone = "head", force = 1, message = "bites" },
            },
            behavior = { defense = "dodge", flee_threshold = 0.0 },
        },
        behavior = { flee_threshold = 0 },
        states = {
            dead = { description = "A dead rat.", room_presence = "A dead rat lies here." },
        },
        death_state = {
            template = "small-item",
            name = "a dead rat",
            description = "A dead rat.",
            keywords = {"dead rat", "rat"},
            room_presence = "A dead rat lies here.",
            on_feel = "Cold fur.",
            portable = true,
        },
    }
    local knife = {
        id = "knife", name = "a knife",
        keywords = {"knife"},
        combat = { type = "edged", force = 100, message = "slashes" },
        material = "iron",
    }
    local reg = make_mock_registry({ rat = rat, knife = knife })
    local room = base_room()
    room.contents = { "rat" }
    room.light_level = 5
    local player = base_player()
    player.hands[1] = knife
    local ctx = make_ctx(reg, room, player)
    -- Ensure light is available for combat
    ctx.time_offset = 40

    local output = capture_output(function() handlers["attack"](ctx, "rat") end)
    -- Death message should contain "The rat is dead!" (capitalized, definite article)
    h.assert_truthy(output:find("The rat is dead!"),
        "#345/#370: death message should be 'The rat is dead!', got: " .. output)
    -- Should NOT contain lowercase "a brown rat is dead"
    h.assert_truthy(not output:lower():find("a brown rat is dead"),
        "#345: should not contain 'a brown rat is dead', got: " .. output)
end)

---------------------------------------------------------------------------
-- #331: Attack dead creature via verb aliases
---------------------------------------------------------------------------
suite("#331: combat verb aliases on dead creatures")

test("'stab rat' on dead creature says 'already dead'", function()
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local dead_rat = {
        id = "rat", name = "a dead rat",
        keywords = {"rat", "dead rat", "brown rat"},
        animate = false, alive = false,
        _state = "dead",
        health = 0, max_health = 5,
        location = "test-room",
    }
    local reg = make_mock_registry({ rat = dead_rat })
    local room = base_room()
    room.contents = { "rat" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function() handlers["stab"](ctx, "rat") end)
    h.assert_truthy(output:lower():find("already dead"),
        "#331: 'stab' dead creature should say 'already dead', got: " .. output)
end)

test("'hit rat' on dead creature says 'already dead'", function()
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local dead_rat = {
        id = "rat", name = "a dead rat",
        keywords = {"rat", "dead rat"},
        animate = false, alive = false,
        _state = "dead",
        health = 0, max_health = 5,
        location = "test-room",
    }
    local reg = make_mock_registry({ rat = dead_rat })
    local room = base_room()
    room.contents = { "rat" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function() handlers["hit"](ctx, "rat") end)
    h.assert_truthy(output:lower():find("already dead"),
        "#331: 'hit' dead creature should say 'already dead', got: " .. output)
end)

test("'kick spider' on dead creature says 'already dead'", function()
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local dead_spider = {
        id = "spider", name = "a dead spider",
        keywords = {"spider", "dead spider"},
        animate = false, alive = false,
        _state = "dead",
        health = 0, max_health = 3,
        location = "test-room",
    }
    local reg = make_mock_registry({ spider = dead_spider })
    local room = base_room()
    room.contents = { "spider" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function() handlers["kick"](ctx, "spider") end)
    h.assert_truthy(output:lower():find("already dead"),
        "#331: 'kick' dead creature should say 'already dead', got: " .. output)
end)

test("'punch rat' on dead creature says 'already dead'", function()
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local dead_rat = {
        id = "rat", name = "a dead rat",
        keywords = {"rat", "dead rat"},
        animate = false, alive = false,
        _state = "dead",
        health = 0, max_health = 5,
        location = "test-room",
    }
    local reg = make_mock_registry({ rat = dead_rat })
    local room = base_room()
    room.contents = { "rat" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function() handlers["punch"](ctx, "rat") end)
    h.assert_truthy(output:lower():find("already dead"),
        "#331: 'punch' dead creature should say 'already dead', got: " .. output)
end)

test("'strike spider' on dead creature says 'already dead'", function()
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local dead_spider = {
        id = "spider", name = "a dead spider",
        keywords = {"spider", "dead spider"},
        animate = false, alive = false,
        _state = "dead",
        health = 0, max_health = 3,
        location = "test-room",
    }
    local reg = make_mock_registry({ spider = dead_spider })
    local room = base_room()
    room.contents = { "spider" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function() handlers["strike"](ctx, "spider") end)
    h.assert_truthy(output:lower():find("already dead"),
        "#331: 'strike' dead creature should say 'already dead', got: " .. output)
end)

test("'swing at rat' on dead creature says 'already dead'", function()
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local dead_rat = {
        id = "rat", name = "a dead rat",
        keywords = {"rat", "dead rat"},
        animate = false, alive = false,
        _state = "dead",
        health = 0, max_health = 5,
        location = "test-room",
    }
    local reg = make_mock_registry({ rat = dead_rat })
    local room = base_room()
    room.contents = { "rat" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function() handlers["swing"](ctx, "rat") end)
    h.assert_truthy(output:lower():find("already dead"),
        "#331: 'swing' dead creature should say 'already dead', got: " .. output)
end)

test("'attack rat' on dead creature still says 'already dead'", function()
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local dead_rat = {
        id = "rat", name = "a dead rat",
        keywords = {"rat", "dead rat"},
        animate = false, alive = false,
        _state = "dead",
        health = 0, max_health = 5,
        location = "test-room",
    }
    local reg = make_mock_registry({ rat = dead_rat })
    local room = base_room()
    room.contents = { "rat" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function() handlers["attack"](ctx, "rat") end)
    h.assert_truthy(output:lower():find("already dead"),
        "#331: 'attack' dead creature should say 'already dead', got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
