-- test/verbs/test-parser-verb-bugs-307-309-313-320-321-335.lua
-- TDD tests for 6 parser/verb gameplay bugs discovered in playtesting.
--
-- #335: Parser fuzzy-matches 'meat' to 'rug' for eat/cook commands
-- #313: 'light candle with match' still targets holder (with-tool variant)
-- #309: Door disambiguation shows identical names for two different doors
-- #320: 'insert key into lock' produces nonsensical 'You can't close a small brass key'
-- #321: 'use key on padlock' not recognized
-- #307: 'craft' with no noun gives misleading error message
--
-- Usage: lua test/verbs/test-parser-verb-bugs-307-309-313-320-321-335.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local fuzzy_mod = require("engine.parser.fuzzy")
local compound_mod = require("engine.parser.preprocess.compound_actions")

local test = h.test
local suite = h.suite
local eq = h.assert_eq
local truthy = h.assert_truthy

local handlers = verbs_mod.create()

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

local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
        find_by_keyword = function(self, kw)
            local results = {}
            for _, obj in pairs(self._objects) do
                if obj.keywords then
                    for _, k in ipairs(obj.keywords) do
                        if k:lower() == kw:lower() then
                            results[#results + 1] = obj
                            break
                        end
                    end
                end
            end
            return results
        end,
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
        description = "A plain test room.",
        contents = {}, exits = {}, light_level = 1,
    }
end

local function make_ctx(reg, room, player, overrides)
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "look",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
        headless = true,
    }
    if overrides then
        for k, v in pairs(overrides) do ctx[k] = v end
    end
    return ctx
end

---------------------------------------------------------------------------
-- #335: Parser fuzzy-matches 'meat' to 'rug' for eat/cook commands
---------------------------------------------------------------------------
suite("#335: fuzzy resolver rejects low-confidence typo matches")

test("fuzzy.score_object rejects 'meat' matching 'mat' via length ratio", function()
    local rug = {
        id = "rug",
        name = "a threadbare rug",
        keywords = {"rug", "mat", "carpet"},
        material = "cloth",
    }
    local parsed = fuzzy_mod.parse_noun_phrase("meat")
    local score, reason = fuzzy_mod.score_object(rug, parsed)
    -- 'meat'(4) vs 'mat'(3): ratio 3/4=0.75 < 0.80 threshold → no typo match
    eq(0, score,
        "#335: 'meat' should not score against 'mat' (length ratio too low)")
end)

test("fuzzy.resolve rejects 'meat' when only rug is visible", function()
    local rug = {
        id = "rug",
        name = "a threadbare rug",
        keywords = {"rug", "mat", "carpet"},
    }
    local reg = make_mock_registry({ rug = rug })
    local room = base_room()
    room.contents = {"rug"}
    local player = base_player()
    local ctx = make_ctx(reg, room, player, { current_verb = "eat" })
    local obj = fuzzy_mod.resolve(ctx, "meat")
    eq(nil, obj,
        "#335: fuzzy should not resolve 'meat' to rug — should return nil")
end)

test("fuzzy.resolve still accepts valid typo corrections", function()
    local nightstand = {
        id = "nightstand",
        name = "a wooden nightstand",
        keywords = {"nightstand"},
    }
    local reg = make_mock_registry({ nightstand = nightstand })
    local room = base_room()
    room.contents = {"nightstand"}
    local player = base_player()
    local ctx = make_ctx(reg, room, player, { current_verb = "look" })
    local obj = fuzzy_mod.resolve(ctx, "nighstand")
    truthy(obj ~= nil,
        "#335: fuzzy should still correct 'nighstand' to 'nightstand'")
end)

---------------------------------------------------------------------------
-- #313: 'light candle with match' still targets holder
---------------------------------------------------------------------------
suite("#313: light candle with tool modifier resolves nested candle")

test("'light candle with match' targets nested candle, not holder", function()
    local candle = {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        initial_state = "unlit", _state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The candle wick catches and burns steadily." },
        },
    }
    local holder = {
        id = "candle-holder",
        name = "a brass candle holder",
        keywords = {"candle holder", "holder", "candlestick"},
        _state = "with_candle",
        parts = {
            candle = {
                id = "candle", detachable = true,
                keywords = {"candle", "tallow candle"},
                name = "a tallow candle",
            },
        },
    }
    local match_obj = {
        id = "match", name = "a match",
        keywords = {"match"},
        provides_tool = "fire_source",
        _state = "lit",
        states = { lit = { casts_light = true, provides_tool = "fire_source" } },
    }
    local reg = make_mock_registry({
        candle = candle, ["candle-holder"] = holder, match = match_obj,
    })
    local player = base_player()
    player.hands[1] = holder
    player.hands[2] = match_obj
    local room = base_room()
    local ctx = make_ctx(reg, room, player, { current_verb = "light" })

    local output = capture_output(function()
        handlers["light"](ctx, "candle with match")
    end)
    -- Should NOT say "can't light" — should light the candle
    truthy(not output:lower():match("can't light"),
        "#313: 'light candle with match' should not say can't light. Output: " .. output)
end)

test("'light candle' with candle in holder contents resolves correctly", function()
    local candle = {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        initial_state = "unlit", _state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The candle wick catches and burns steadily." },
        },
    }
    local holder = {
        id = "candle-holder",
        name = "a brass candle holder",
        keywords = {"candle holder", "holder", "candlestick"},
        _state = "with_candle",
        contents = {"candle"},
    }
    local match_obj = {
        id = "match", name = "a match",
        keywords = {"match"},
        provides_tool = "fire_source",
        _state = "lit",
        states = { lit = { casts_light = true, provides_tool = "fire_source" } },
    }
    local reg = make_mock_registry({
        candle = candle, ["candle-holder"] = holder, match = match_obj,
    })
    local player = base_player()
    player.hands[1] = holder
    player.hands[2] = match_obj
    local room = base_room()
    local ctx = make_ctx(reg, room, player, { current_verb = "light" })

    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    truthy(not output:lower():match("can't light"),
        "#313: 'light candle' with candle in holder contents should work. Output: " .. output)
end)

---------------------------------------------------------------------------
-- #309: Door disambiguation shows identical names
---------------------------------------------------------------------------
suite("#309: door disambiguation includes direction")

test("disambiguation prompt includes direction for same-name doors", function()
    local door_south = {
        id = "door-south",
        name = "an open iron-bound door",
        keywords = {"door", "iron-bound door"},
    }
    local door_north = {
        id = "door-north",
        name = "an open iron-bound door",
        keywords = {"door", "iron-bound door"},
    }
    local reg = make_mock_registry({
        ["door-south"] = door_south,
        ["door-north"] = door_north,
    })
    local room = base_room()
    room.contents = {"door-south", "door-north"}
    room.exits = {
        south = { id = "door-south", name = "an open iron-bound door",
                   target = "hallway", type = "door" },
        north = { id = "door-north", name = "an open iron-bound door",
                   target = "cellar", type = "door" },
    }
    local player = base_player()
    local ctx = make_ctx(reg, room, player, { current_verb = "lock" })

    -- Call find_visible directly to get disambiguation prompt
    local search_mod = require("engine.verbs.helpers")
    local obj = search_mod.find_visible(ctx, "door")

    -- find_visible should return nil and set disambiguation_prompt
    eq(nil, obj, "#309: find_visible should return nil for ambiguous doors")
    truthy(ctx.disambiguation_prompt ~= nil,
        "#309: disambiguation_prompt should be set")
    if ctx.disambiguation_prompt then
        local prompt = ctx.disambiguation_prompt
        -- The prompt should NOT have two identical strings
        local has_direction = prompt:lower():match("south") or prompt:lower():match("north")
        truthy(has_direction,
            "#309: disambiguation should include direction for same-name doors. Got: " .. prompt)
    end
end)

---------------------------------------------------------------------------
-- #320: 'insert key into lock' → preprocess routing
---------------------------------------------------------------------------
suite("#320: 'insert X into Y' compound action routing")

test("'insert key into lock' routes to unlock", function()
    local result = compound_mod.transform_compound_actions("insert key into lock")
    truthy(result:match("unlock"),
        "#320: 'insert key into lock' should route to unlock. Got: " .. result)
end)

test("'insert key into keyhole' routes to unlock", function()
    local result = compound_mod.transform_compound_actions("insert key into keyhole")
    truthy(result:match("unlock"),
        "#320: 'insert key into keyhole' should route to unlock. Got: " .. result)
end)

test("'insert coin into slot' routes to put", function()
    local result = compound_mod.transform_compound_actions("insert coin into slot")
    truthy(result:match("put"),
        "#320: 'insert coin into slot' should route to put. Got: " .. result)
end)

---------------------------------------------------------------------------
-- #321: 'use key on padlock' — unlock handler resolves padlock/lock nouns
---------------------------------------------------------------------------
suite("#321: 'use key on padlock' recognized")

test("compound_actions routes 'use brass key on padlock' to unlock", function()
    local result = compound_mod.transform_compound_actions("use brass key on padlock")
    truthy(result:match("unlock"),
        "#321: 'use brass key on padlock' should route to unlock. Got: " .. result)
end)

test("unlock handler resolves 'padlock' to a locked exit door", function()
    local key = {
        id = "brass-key",
        name = "a small brass key",
        keywords = {"key", "brass key"},
    }
    local reg = make_mock_registry({ ["brass-key"] = key })
    local room = base_room()
    room.exits = {
        south = {
            id = "cellar-door",
            name = "a heavy iron-bound door",
            keywords = {"door", "iron-bound door"},
            target = "cellar",
            type = "door",
            locked = true,
            key_id = "brass-key",
        },
    }
    local player = base_player()
    player.hands[1] = key
    local ctx = make_ctx(reg, room, player, { current_verb = "unlock" })

    local output = capture_output(function()
        handlers["unlock"](ctx, "padlock with brass key")
    end)
    -- Should NOT say "don't notice anything" — should find the locked exit
    truthy(not output:match("don't notice") and not output:match("not found"),
        "#321: 'unlock padlock' should find the locked exit door. Output: " .. output)
end)

---------------------------------------------------------------------------
-- #307: 'craft' with no noun gives misleading error message
---------------------------------------------------------------------------
suite("#307: 'craft' with no noun gives helpful message")

test("'craft' with empty noun says 'Craft what?' not 'don't know how'", function()
    local reg = make_mock_registry({})
    local room = base_room()
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function()
        handlers["craft"](ctx, "")
    end)
    truthy(output:lower():match("craft what"),
        "#307: 'craft' with empty noun should say 'Craft what?'. Got: " .. output)
    truthy(not output:lower():match("don't know how"),
        "#307: should NOT say 'don't know how to craft that'. Got: " .. output)
end)

test("'make' with empty noun says helpful message", function()
    local reg = make_mock_registry({})
    local room = base_room()
    local player = base_player()
    local ctx = make_ctx(reg, room, player)

    local output = capture_output(function()
        handlers["make"](ctx, "")
    end)
    truthy(output:lower():match("craft what") or output:lower():match("make what"),
        "#307: 'make' with empty noun should give helpful message. Got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
