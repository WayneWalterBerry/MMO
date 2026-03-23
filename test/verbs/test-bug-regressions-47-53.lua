-- test/verbs/test-bug-regressions-47-53.lua
-- Regression tests for bugs #47, #49, #52, #53
-- #47: Dark room search uses "find/see" instead of "feel" narration
-- #49: "stab yourself" should infer weapon from hand contents
-- #52: Mirror shows only held items, not full appearance
-- #53: "get pot" outputs take message twice — duplicate response
--
-- Usage: lua test/verbs/test-bug-regressions-47-53.lua

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
local truthy = h.assert_truthy

local narrator = require("engine.search.narrator")
local appearance = require("engine.player.appearance")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")
local injury_mod = require("engine.injuries")

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
    }
end

---------------------------------------------------------------------------
-- BUG #47: Dark room search uses "find/see" instead of "feel" narration
---------------------------------------------------------------------------
suite("Bug #47 — dark room search narration")

test("container_contents_no_target uses 'you feel' in dark room", function()
    local ctx = {
        current_room = { id = "dark-room", light_level = 0 }
    }
    local container = { name = "a wooden chest", id = "chest" }
    local result = narrator.container_contents_no_target(ctx, container, {"a gold coin", "a key"}, nil)
    truthy(result:find("you feel"), "Dark room should use 'you feel', got: " .. result)
    truthy(not result:find("you see"), "Dark room should NOT use 'you see', got: " .. result)
end)

test("container_contents_no_target uses 'you see' in lit room", function()
    local ctx = {
        current_room = { id = "lit-room", light_level = 1 }
    }
    local container = { name = "a wooden chest", id = "chest" }
    local result = narrator.container_contents_no_target(ctx, container, {"a gold coin"}, nil)
    truthy(result:find("you see"), "Lit room should use 'you see', got: " .. result)
end)

test("container_contents_no_target with target uses 'you feel' in dark", function()
    local ctx = {
        current_room = { id = "dark-room", light_level = 0 }
    }
    local container = { name = "a drawer", id = "drawer" }
    local result = narrator.container_contents_no_target(ctx, container, {"a pen"}, "key")
    truthy(result:find("you feel"), "Dark room search for target should use 'you feel', got: " .. result)
    truthy(not result:find("you see"), "Dark room should NOT use 'you see', got: " .. result)
end)

test("container_peek uses 'feel around' in dark room", function()
    local ctx = {
        current_room = { id = "dark-room", light_level = 0 }
    }
    local container = { name = "a nightstand", id = "nightstand" }
    local result = narrator.container_peek(ctx, container)
    truthy(result:find("feel around"), "Dark room peek should use 'feel around', got: " .. result)
end)

test("container_peek uses 'check inside' in lit room", function()
    local ctx = {
        current_room = { id = "lit-room", light_level = 1 }
    }
    local container = { name = "a nightstand", id = "nightstand" }
    local result = narrator.container_peek(ctx, container)
    truthy(result:find("check inside"), "Lit room peek should use 'check inside', got: " .. result)
end)

test("step_narrative uses touch language in dark", function()
    local ctx = {
        current_room = { id = "dark-room", light_level = 0 }
    }
    local obj = { name = "a chair", id = "chair" }
    local result = narrator.step_narrative(ctx, obj, false)
    truthy(result:find("feel") or result:find("fingers") or result:find("reach"),
        "Dark room step should use touch language, got: " .. result)
end)

test("found_target uses touch template in dark", function()
    local ctx = {
        current_room = { id = "dark-room", light_level = 0 }
    }
    local item = { name = "a matchbox", id = "matchbox" }
    local result = narrator.found_target(ctx, item, nil)
    truthy(result:find("feel") or result:find("fingers"),
        "Dark room found target should use touch language, got: " .. result)
end)

---------------------------------------------------------------------------
-- BUG #49: "stab yourself" should infer weapon from hand contents
---------------------------------------------------------------------------
suite("Bug #49 — stab yourself weapon inference")

local function fresh_knife()
    return {
        id = "knife",
        name = "a small knife",
        keywords = {"knife", "blade", "small knife"},
        categories = {"weapon", "sharp"},
        portable = true,
        on_stab = {
            damage = 5,
            injury_type = "bleeding",
            description = "You stab the knife into your %s.",
        },
        mutations = {},
    }
end

local function fresh_dagger()
    return {
        id = "silver-dagger",
        name = "a silver dagger",
        keywords = {"dagger", "silver dagger"},
        categories = {"weapon", "sharp"},
        portable = true,
        on_stab = {
            damage = 8,
            injury_type = "bleeding",
            description = "You drive the silver dagger into your %s.",
        },
        mutations = {},
    }
end

local function setup_injuries()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("bleeding", {
        id = "bleeding", name = "Bleeding Wound",
        category = "physical", damage_type = "over_time",
        initial_state = "active",
        on_inflict = { initial_damage = 5, damage_per_tick = 5, message = "Blood wells." },
        states = {
            active = { name = "bleeding", damage_per_tick = 5 },
            treated = { name = "bandaged", damage_per_tick = 0 },
            healed = { name = "healed", terminal = true },
        },
        healing_interactions = {},
    })
end

local function make_stab_ctx(opts)
    opts = opts or {}
    local objs = {}
    local player = {
        max_health = 100,
        injuries = {},
        hands = { nil, nil },
        worn = {},
        state = {},
    }
    if opts.knife_in_hand then
        local knife = opts.knife or fresh_knife()
        objs[knife.id] = knife
        player.hands[1] = knife
    end
    if opts.both_hands then
        objs[opts.both_hands[1].id] = opts.both_hands[1]
        objs[opts.both_hands[2].id] = opts.both_hands[2]
        player.hands[1] = opts.both_hands[1]
        player.hands[2] = opts.both_hands[2]
    end
    local reg = make_mock_registry(objs)
    local room = {
        id = "test-room", name = "Test Room",
        contents = {}, exits = {}, light_level = 0,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "stab",
        injuries = player.injuries,
    }
end

test("'stab yourself' with knife in hand auto-infers weapon", function()
    setup_injuries()
    local ctx = make_stab_ctx({ knife_in_hand = true })
    local output = capture_output(function()
        handlers["stab"](ctx, "yourself")
    end)
    -- Should stab with the knife, not ask for weapon
    truthy(not output:find("Try: stab self"),
        "'stab yourself' should not show help message, got: " .. output)
    truthy(output:find("stab") or output:find("knife"),
        "Should describe the stab action, got: " .. output)
end)

test("'stab yourself' with two weapons disambiguates", function()
    setup_injuries()
    local knife = fresh_knife()
    local dagger = fresh_dagger()
    local ctx = make_stab_ctx({ both_hands = { knife, dagger } })
    local output = capture_output(function()
        handlers["stab"](ctx, "yourself")
    end)
    truthy(output:find("with what") or output:find("holding"),
        "Two weapons should disambiguate, got: " .. output)
end)

test("'stab yourself' with no weapons gives helpful error", function()
    setup_injuries()
    local ctx = make_stab_ctx({})
    local output = capture_output(function()
        handlers["stab"](ctx, "yourself")
    end)
    truthy(output:find("nothing sharp") or output:find("nothing to"),
        "No weapons should give helpful error, got: " .. output)
end)

test("'stab me' with knife in hand works (synonym for yourself)", function()
    setup_injuries()
    local ctx = make_stab_ctx({ knife_in_hand = true })
    local output = capture_output(function()
        handlers["stab"](ctx, "me")
    end)
    truthy(not output:find("Try: stab self"),
        "'stab me' should not show help message, got: " .. output)
end)

test("'stab self' with knife in hand works", function()
    setup_injuries()
    local ctx = make_stab_ctx({ knife_in_hand = true })
    local output = capture_output(function()
        handlers["stab"](ctx, "self")
    end)
    truthy(not output:find("Try: stab self"),
        "'stab self' should not show help message, got: " .. output)
end)

---------------------------------------------------------------------------
-- BUG #52: Mirror shows only held items, not full appearance
---------------------------------------------------------------------------
suite("Bug #52 — mirror shows full appearance")

test("healthy player with held item shows overall health AND item", function()
    local player = {
        hands = { { id = "knife", name = "a small knife" }, nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    local reg = make_mock_registry({ knife = player.hands[1] })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("knife"), "Should show held knife, got: " .. desc)
    truthy(desc:find("healthy") or desc:find("alert"),
        "Should show overall health status, got: " .. desc)
end)

test("player with worn item shows worn item in mirror", function()
    local cloak = {
        id = "wool-cloak",
        name = "a wool cloak",
        wear_slot = "torso",
        appearance = { worn_description = "A heavy wool cloak drapes over your shoulders." },
    }
    local player = {
        hands = { nil, nil },
        worn = { "wool-cloak" },
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    local reg = make_mock_registry({ ["wool-cloak"] = cloak })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("cloak") or desc:find("drapes"),
        "Should show worn cloak, got: " .. desc)
end)

test("player with injury shows injury in mirror", function()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                type = "bleeding",
                severity = "moderate",
                location = "left arm",
                _state = "active",
            }
        },
        consciousness = { state = "conscious" },
        state = {},
    }
    local desc = appearance.describe(player, nil)
    truthy(desc:find("arm") or desc:find("gash") or desc:find("wound"),
        "Should show arm injury, got: " .. desc)
end)

test("healthy player with no items still shows overall description", function()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    local desc = appearance.describe(player, nil)
    truthy(desc:find("healthy") or desc:find("alert") or desc:find("unremarkable"),
        "Should show some overall description, got: " .. desc)
end)

test("mirror output starts with 'In the mirror' prefix", function()
    local player = {
        hands = { { id = "knife", name = "a small knife" }, nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    local reg = make_mock_registry({ knife = player.hands[1] })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("^In the mirror"),
        "Should start with 'In the mirror', got: " .. desc)
end)

---------------------------------------------------------------------------
-- BUG #53: "get pot" outputs take message twice — duplicate response
---------------------------------------------------------------------------
suite("Bug #53 — get pot duplicate response")

local function make_take_ctx(room_objects)
    local objs = {}
    local room_contents = {}
    for _, obj in ipairs(room_objects) do
        objs[obj.id] = obj
        room_contents[#room_contents + 1] = obj.id
    end
    local reg = make_mock_registry(objs)
    local room = {
        id = "test-room", name = "Test Room",
        contents = room_contents, exits = {},
        light_level = 1,
    }
    return {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = {},
            state = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
end

test("'get pot' prints exactly one 'You take' message", function()
    local pot = {
        id = "chamber-pot",
        name = "a ceramic chamber pot",
        keywords = {"chamber pot", "pot", "ceramic pot"},
        portable = true,
        container = true,
        contents = {},
        categories = {"ceramic", "container"},
        mutations = {},
    }
    local ctx = make_take_ctx({ pot })
    local output = capture_output(function()
        handlers["get"](ctx, "pot")
    end)
    -- Count occurrences of "You take"
    local count = 0
    for _ in output:gmatch("You take") do count = count + 1 end
    eq(1, count, "Should print 'You take' exactly once, got " .. count .. " in: " .. output)
end)

test("'take pot' prints exactly one 'You take' message", function()
    local pot = {
        id = "chamber-pot",
        name = "a ceramic chamber pot",
        keywords = {"chamber pot", "pot", "ceramic pot"},
        portable = true,
        container = true,
        contents = {},
        categories = {"ceramic", "container"},
        mutations = {},
    }
    local ctx = make_take_ctx({ pot })
    local output = capture_output(function()
        handlers["take"](ctx, "pot")
    end)
    local count = 0
    for _ in output:gmatch("You take") do count = count + 1 end
    eq(1, count, "Should print 'You take' exactly once, got " .. count .. " in: " .. output)
end)

test("taking already-held object says 'already have'", function()
    local pot = {
        id = "chamber-pot",
        name = "a ceramic chamber pot",
        keywords = {"chamber pot", "pot", "ceramic pot"},
        portable = true,
        container = true,
        contents = {},
        location = "player",
        categories = {"ceramic", "container"},
        mutations = {},
    }
    local reg = make_mock_registry({ ["chamber-pot"] = pot })
    local room = {
        id = "test-room", name = "Test Room",
        contents = { "chamber-pot" }, exits = {},
        light_level = 1,
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = { pot, nil },
            worn = {},
            state = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
    local output = capture_output(function()
        handlers["get"](ctx, "pot")
    end)
    truthy(output:find("already have"),
        "Already-held item should say 'already have', got: " .. output)
end)

test("'grab pot' prints exactly one 'You take' message", function()
    local pot = {
        id = "chamber-pot",
        name = "a ceramic chamber pot",
        keywords = {"chamber pot", "pot", "ceramic pot"},
        portable = true,
        container = true,
        contents = {},
        categories = {"ceramic", "container"},
        mutations = {},
    }
    local ctx = make_take_ctx({ pot })
    local output = capture_output(function()
        handlers["grab"](ctx, "pot")
    end)
    local count = 0
    for _ in output:gmatch("You take") do count = count + 1 end
    eq(1, count, "Should print 'You take' exactly once, got " .. count .. " in: " .. output)
end)
