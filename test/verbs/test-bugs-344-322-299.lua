-- test/verbs/test-bugs-344-322-299.lua
-- TDD regression tests for 3 disambiguation/verb bugs.
-- #344: 'attack creature' skips disambiguation when multiple creatures present
-- #322: 'unbar door' says 'You aren't holding that' — unclear unbar mechanic
-- #299: Disambiguation prompt for identical items gives no way to differentiate
--
-- Usage: lua test/verbs/test-bugs-344-322-299.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local test = h.test
local suite = h.suite
local eq = h.assert_eq

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Shared helpers
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
            return results[1]
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
        description = "A test room.",
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
-- #344: attack creature disambiguation — standardized prompt format
---------------------------------------------------------------------------
suite("#344: attack disambiguation uses standard prompt format")

test("'attack rat' with 2 different creatures shows 'Which do you mean' prompt", function()
    local rat1 = {
        id = "brown-rat", name = "a brown rat",
        keywords = {"rat", "brown rat", "creature"},
        animate = true, alive = true, _state = "alive",
        health = 10, max_health = 10,
        location = "test-room",
        combat = {
            size = "tiny", speed = 3,
            natural_weapons = {
                { id = "bite", type = "pierce", material = "tooth-enamel",
                  zone = "head", force = 2, message = "bites" },
            },
            behavior = { defense = "dodge", flee_threshold = 0.3 },
        },
        body_tree = {
            head = { size = 1, vital = true, tissue = { "hide", "flesh" } },
            body = { size = 2, vital = true, tissue = { "hide", "flesh" } },
        },
    }
    local rat2 = {
        id = "grey-rat", name = "a grey rat",
        keywords = {"rat", "grey rat", "creature"},
        animate = true, alive = true, _state = "alive",
        health = 10, max_health = 10,
        location = "test-room",
        combat = {
            size = "tiny", speed = 3,
            natural_weapons = {
                { id = "bite", type = "pierce", material = "tooth-enamel",
                  zone = "head", force = 2, message = "bites" },
            },
            behavior = { defense = "dodge", flee_threshold = 0.3 },
        },
        body_tree = {
            head = { size = 1, vital = true, tissue = { "hide", "flesh" } },
            body = { size = 2, vital = true, tissue = { "hide", "flesh" } },
        },
    }
    local knife = {
        id = "knife", name = "a knife",
        keywords = {"knife"},
        combat = { type = "edged", force = 5, message = "slashes" },
    }
    local reg = make_mock_registry({
        ["brown-rat"] = rat1, ["grey-rat"] = rat2, knife = knife,
    })
    local room = base_room()
    room.contents = { "brown-rat", "grey-rat" }
    local player = base_player()
    player.hands[1] = knife
    local ctx = make_ctx(reg, room, player, { current_verb = "attack" })

    local output = capture_output(function() handlers["attack"](ctx, "rat") end)
    -- Must use the standard "Which do you mean" format, not "Which one?"
    h.assert_truthy(output:find("Which do you mean"),
        "#344: should use standard 'Which do you mean' format, got: " .. output)
end)

test("'attack rat' disambiguation sets ctx.disambiguation_prompt as string", function()
    local rat1 = {
        id = "brown-rat", name = "a brown rat",
        keywords = {"rat", "creature"},
        animate = true, alive = true, _state = "alive",
        health = 10, max_health = 10, location = "test-room",
        combat = { size = "tiny", speed = 3,
            natural_weapons = {{ id = "bite", type = "pierce", material = "tooth-enamel",
                zone = "head", force = 2, message = "bites" }},
            behavior = { defense = "dodge", flee_threshold = 0.3 } },
        body_tree = { head = { size = 1, vital = true, tissue = {"hide","flesh"} } },
    }
    local rat2 = {
        id = "grey-rat", name = "a grey rat",
        keywords = {"rat", "creature"},
        animate = true, alive = true, _state = "alive",
        health = 10, max_health = 10, location = "test-room",
        combat = { size = "tiny", speed = 3,
            natural_weapons = {{ id = "bite", type = "pierce", material = "tooth-enamel",
                zone = "head", force = 2, message = "bites" }},
            behavior = { defense = "dodge", flee_threshold = 0.3 } },
        body_tree = { head = { size = 1, vital = true, tissue = {"hide","flesh"} } },
    }
    local reg = make_mock_registry({
        ["brown-rat"] = rat1, ["grey-rat"] = rat2,
    })
    local room = base_room()
    room.contents = { "brown-rat", "grey-rat" }
    local player = base_player()
    player.hands[1] = { id = "knife", name = "a knife", keywords = {"knife"},
        combat = { type = "edged", force = 5 } }
    local ctx = make_ctx(reg, room, player, { current_verb = "attack" })

    capture_output(function() handlers["attack"](ctx, "rat") end)
    h.assert_truthy(type(ctx.disambiguation_prompt) == "string",
        "#344: disambiguation_prompt should be a string, got: " .. type(ctx.disambiguation_prompt or "nil"))
end)

test("'attack creature' with rat+spider shows disambiguation, not silent combat", function()
    local rat = {
        id = "brown-rat", name = "a brown rat",
        keywords = {"rat", "creature", "brown rat"},
        animate = true, alive = true, _state = "alive",
        health = 10, max_health = 10, location = "test-room",
        combat = { size = "tiny", speed = 3,
            natural_weapons = {{ id = "bite", type = "pierce", material = "tooth-enamel",
                zone = "head", force = 2, message = "bites" }},
            behavior = { defense = "dodge", flee_threshold = 0.3 } },
        body_tree = { head = { size = 1, vital = true, tissue = {"hide","flesh"} } },
    }
    local spider = {
        id = "brown-spider", name = "a large brown spider",
        keywords = {"spider", "creature", "brown spider"},
        animate = true, alive = true, _state = "alive",
        health = 8, max_health = 8, location = "test-room",
        combat = { size = "tiny", speed = 4,
            natural_weapons = {{ id = "bite", type = "pierce", material = "chitin",
                zone = "body", force = 3, message = "bites" }},
            behavior = { defense = "dodge", flee_threshold = 0.2 } },
        body_tree = { body = { size = 2, vital = true, tissue = {"chitin","flesh"} } },
    }
    local reg = make_mock_registry({
        ["brown-rat"] = rat, ["brown-spider"] = spider,
    })
    local room = base_room()
    room.contents = { "brown-rat", "brown-spider" }
    local player = base_player()
    player.hands[1] = { id = "knife", name = "a knife", keywords = {"knife"},
        combat = { type = "edged", force = 5 } }
    local ctx = make_ctx(reg, room, player, { current_verb = "attack" })

    local output = capture_output(function() handlers["attack"](ctx, "creature") end)
    -- Should show disambiguation, not attack or "don't see"
    h.assert_truthy(output:find("Which do you mean"),
        "#344: 'attack creature' with rat+spider should disambiguate, got: " .. output)
    h.assert_truthy(not output:find("don't see"),
        "#344: should not say 'don't see' with multiple creatures, got: " .. output)
end)

---------------------------------------------------------------------------
-- #322: 'unbar door' should work via FSM, not say 'You aren't holding that'
---------------------------------------------------------------------------
suite("#322: unbar verb handler exists and uses FSM transitions")

test("'unbar' is registered as a verb handler", function()
    h.assert_truthy(handlers["unbar"],
        "#322: 'unbar' should be registered as a verb handler")
end)

test("'bar' is registered as a verb handler", function()
    h.assert_truthy(handlers["bar"],
        "#322: 'bar' should be registered as a verb handler")
end)

test("'unbar door' on barred door executes FSM transition", function()
    local door = {
        id = "oak-door", name = "a heavy oak door",
        keywords = {"door", "oak door", "heavy door"},
        initial_state = "barred",
        _state = "barred",
        states = {
            barred = { description = "The door is held shut by a heavy iron bar." },
            unbarred = { description = "The door stands unbarred." },
        },
        transitions = {
            { from = "barred", to = "unbarred", verb = "unbar",
              aliases = {"lift bar", "remove bar"},
              message = "You grip the iron bar and heave it from its brackets." },
        },
    }
    local reg = make_mock_registry({ ["oak-door"] = door })
    local room = base_room()
    room.contents = { "oak-door" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player, { current_verb = "unbar" })

    local output = capture_output(function() handlers["unbar"](ctx, "door") end)
    h.assert_truthy(output:find("grip the iron bar") or output:find("heave"),
        "#322: 'unbar door' should execute FSM transition, got: " .. output)
    h.assert_truthy(not output:find("aren't holding"),
        "#322: 'unbar door' should NOT say 'You aren't holding that', got: " .. output)
end)

test("'unbar door' on non-barred door says nothing happens", function()
    local door = {
        id = "oak-door", name = "a heavy oak door",
        keywords = {"door", "oak door"},
        initial_state = "unbarred",
        _state = "unbarred",
        states = {
            barred = { description = "The door is held shut by a heavy iron bar." },
            unbarred = { description = "The door stands unbarred." },
        },
        transitions = {
            { from = "barred", to = "unbarred", verb = "unbar",
              message = "You grip the iron bar and heave it from its brackets." },
        },
    }
    local reg = make_mock_registry({ ["oak-door"] = door })
    local room = base_room()
    room.contents = { "oak-door" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player, { current_verb = "unbar" })

    local output = capture_output(function() handlers["unbar"](ctx, "door") end)
    -- Should NOT say "aren't holding" — should say nothing happens or similar
    h.assert_truthy(not output:find("aren't holding"),
        "#322: wrong-state unbar should NOT say holding error, got: " .. output)
end)

test("'lift bar' alias routes to unbar handler", function()
    h.assert_truthy(handlers["lift bar"],
        "#322: 'lift bar' should be registered as alias for unbar")
end)

---------------------------------------------------------------------------
-- #299: Disambiguation for identical items includes differentiating info
---------------------------------------------------------------------------
suite("#299: identical-name disambiguation uses ordinals")

-- Use find_visible directly via the helpers module
local helpers_mod = require("engine.verbs.helpers")
local fv = helpers_mod.find_visible

test("two objects with same name get ordinal disambiguation", function()
    -- Use non-numeric suffixed IDs so _base_id won't treat them as fungible
    local candle1 = {
        id = "candle-bedroom", name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        on_feel = "Waxy cylinder.",
    }
    local candle2 = {
        id = "candle-cellar", name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        on_feel = "Waxy cylinder.",
    }
    local reg = make_mock_registry({
        ["candle-bedroom"] = candle1, ["candle-cellar"] = candle2,
    })
    local room = base_room()
    room.contents = { "candle-bedroom", "candle-cellar" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player, { current_verb = "take" })

    local result = fv(ctx, "candle")
    -- Should trigger disambiguation with differentiating info
    h.assert_truthy(ctx.disambiguation_prompt,
        "#299: identical candles should trigger disambiguation prompt")
    local prompt = ctx.disambiguation_prompt
    h.assert_truthy(type(prompt) == "string",
        "#299: prompt should be a string, got: " .. type(prompt))
    -- The prompt should NOT have identical options
    -- It should use ordinals like "the first tallow candle" / "the second tallow candle"
    h.assert_truthy(prompt:find("first") or prompt:find("second")
        or prompt:find("1st") or prompt:find("2nd"),
        "#299: identical-name objects should have ordinals in prompt, got: " .. prompt)
end)

test("three identical items get ordinal disambiguation", function()
    -- Use non-numeric suffixed IDs so _base_id won't treat them as fungible
    local mk = function(suffix)
        return {
            id = "torch-" .. suffix, name = "a wooden torch",
            keywords = {"torch", "wooden torch"},
            on_feel = "Rough wood.",
        }
    end
    local reg = make_mock_registry({
        ["torch-alpha"] = mk("alpha"), ["torch-beta"] = mk("beta"), ["torch-gamma"] = mk("gamma"),
    })
    local room = base_room()
    room.contents = { "torch-alpha", "torch-beta", "torch-gamma" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player, { current_verb = "take" })

    fv(ctx, "torch")
    local prompt = ctx.disambiguation_prompt
    h.assert_truthy(prompt, "#299: 3 identical torches should trigger disambiguation")
    h.assert_truthy(prompt:find("first") and prompt:find("second") and prompt:find("third"),
        "#299: should have first/second/third ordinals, got: " .. tostring(prompt))
end)

test("two items with different names still show normal disambiguation (no ordinals)", function()
    local sack1 = {
        id = "burlap-sack", name = "a burlap sack",
        keywords = {"sack", "burlap sack"},
    }
    local sack2 = {
        id = "grain-sack", name = "a grain sack",
        keywords = {"sack", "grain sack"},
    }
    local reg = make_mock_registry({
        ["burlap-sack"] = sack1, ["grain-sack"] = sack2,
    })
    local room = base_room()
    room.contents = { "burlap-sack", "grain-sack" }
    local player = base_player()
    local ctx = make_ctx(reg, room, player, { current_verb = "take" })

    fv(ctx, "sack")
    local prompt = ctx.disambiguation_prompt
    h.assert_truthy(prompt, "different-named sacks should trigger disambiguation")
    -- Should show names without ordinals since they're already different
    h.assert_truthy(prompt:find("burlap") and prompt:find("grain"),
        "should show both sack names, got: " .. tostring(prompt))
    h.assert_truthy(not prompt:find("first"),
        "different names should NOT use ordinals, got: " .. tostring(prompt))
end)

---------------------------------------------------------------------------
h.summary()
