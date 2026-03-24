-- test/verbs/test-verify-f1-bugs.lua
-- F1 Verification Tests (post-Smithers commit 5738359)
-- Confirms fixes for: #47, #49, #52, #53, BUG-116
--
-- Written by Nelson (QA) — verification pass, not discovery.
-- Usage: lua test/verbs/test-verify-f1-bugs.lua

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

local function fresh_player(overrides)
    local p = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    if overrides then
        for k, v in pairs(overrides) do p[k] = v end
    end
    return p
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

---------------------------------------------------------------------------
-- VERIFY #47: Dark search narration uses sensory-appropriate verbs
---------------------------------------------------------------------------
suite("VERIFY #47 — dark search uses feel/grope, not find/see")

test("V47-1: dark room container peek says 'feel around', not 'check inside'", function()
    local ctx = { current_room = { id = "dark-room", light_level = 0 } }
    local container = { name = "a nightstand", id = "nightstand" }
    local result = narrator.container_peek(ctx, container)
    truthy(result:find("feel around"),
        "Dark peek should say 'feel around', got: " .. result)
    truthy(not result:find("check inside"),
        "Dark peek should NOT say 'check inside', got: " .. result)
end)

test("V47-2: dark room contents uses 'you feel', never 'you see'", function()
    local ctx = { current_room = { id = "dark-room", light_level = 0 } }
    local container = { name = "a chest", id = "chest" }
    local result = narrator.container_contents_no_target(ctx, container, {"a gold coin"}, nil)
    truthy(result:find("you feel"),
        "Dark contents should use 'you feel', got: " .. result)
    truthy(not result:find("you see"),
        "Dark contents should NOT use 'you see', got: " .. result)
end)

test("V47-3: lit room container peek says 'check inside'", function()
    local ctx = { current_room = { id = "lit-room", light_level = 1 } }
    local container = { name = "a nightstand", id = "nightstand" }
    local result = narrator.container_peek(ctx, container)
    truthy(result:find("check inside"),
        "Lit peek should say 'check inside', got: " .. result)
end)

test("V47-4: dark room found_target uses touch language", function()
    local ctx = { current_room = { id = "dark-room", light_level = 0 } }
    local item = { name = "a matchbox", id = "matchbox" }
    local result = narrator.found_target(ctx, item, nil)
    truthy(result:find("feel") or result:find("fingers"),
        "Dark found_target should use touch language, got: " .. result)
    truthy(not result:find("see") and not result:find("spot"),
        "Dark found_target should NOT use sight words, got: " .. result)
end)

test("V47-5: dark part_contents uses 'feel', never 'find'", function()
    local ctx = { current_room = { id = "dark-room", light_level = 0 } }
    local parent = { name = "a nightstand", id = "nightstand",
        parts = { drawer = { id = "drawer", name = "drawer" } } }
    local result = narrator.part_contents(ctx, "inside", parent, {"a matchbox"})
    truthy(result:find("feel"),
        "Dark part_contents should use 'feel', got: " .. result)
    truthy(not result:find("and find"),
        "Dark part_contents should NOT use 'find', got: " .. result)
end)

---------------------------------------------------------------------------
-- VERIFY #49: "stab yourself" infers weapon from hand contents
---------------------------------------------------------------------------
suite("VERIFY #49 — stab yourself weapon inference")

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
    if opts.knife then
        objs[opts.knife.id] = opts.knife
        player.hands[1] = opts.knife
    end
    return {
        registry = make_mock_registry(objs),
        current_room = { id = "test-room", name = "Test Room",
            contents = {}, exits = {}, light_level = 0 },
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "stab",
        injuries = player.injuries,
    }
end

local function fresh_knife()
    return {
        id = "knife", name = "a small knife",
        keywords = {"knife", "blade", "small knife"},
        categories = {"weapon", "sharp"},
        portable = true,
        on_stab = { damage = 5, injury_type = "bleeding",
            description = "You stab the knife into your %s." },
        mutations = {},
    }
end

test("V49-1: 'stab yourself' with knife auto-infers weapon", function()
    setup_injuries()
    local ctx = make_stab_ctx({ knife = fresh_knife() })
    local output = capture_output(function()
        handlers["stab"](ctx, "yourself")
    end)
    truthy(not output:find("Try: stab self"),
        "Should not show help, got: " .. output)
    truthy(output:find("stab") or output:find("knife") or output:find("gash"),
        "Should describe stab action, got: " .. output)
end)

test("V49-2: 'stab self' also works", function()
    setup_injuries()
    local ctx = make_stab_ctx({ knife = fresh_knife() })
    local output = capture_output(function()
        handlers["stab"](ctx, "self")
    end)
    truthy(not output:find("Try: stab self"),
        "'stab self' should not show help, got: " .. output)
end)

test("V49-3: 'stab me' also works", function()
    setup_injuries()
    local ctx = make_stab_ctx({ knife = fresh_knife() })
    local output = capture_output(function()
        handlers["stab"](ctx, "me")
    end)
    truthy(not output:find("Try: stab self"),
        "'stab me' should not show help, got: " .. output)
end)

test("V49-4: empty hands gives helpful error, not crash", function()
    setup_injuries()
    local ctx = make_stab_ctx({})
    local output = capture_output(function()
        handlers["stab"](ctx, "yourself")
    end)
    truthy(output:find("nothing sharp") or output:find("nothing to"),
        "Empty hands should give helpful error, got: " .. output)
end)

---------------------------------------------------------------------------
-- VERIFY #52: Mirror shows full appearance (worn, held, injuries, health)
---------------------------------------------------------------------------
suite("VERIFY #52 — mirror shows full appearance")

test("V52-1: held item + overall health both shown", function()
    local knife = { id = "knife", name = "a small knife" }
    local player = fresh_player({ hands = { knife, nil } })
    local reg = make_mock_registry({ knife = knife })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("knife"), "Should show knife, got: " .. desc)
    truthy(desc:find("healthy") or desc:find("alert"),
        "Should show health, got: " .. desc)
end)

test("V52-2: worn item visible in mirror", function()
    local cloak = {
        id = "wool-cloak", name = "a wool cloak",
        wear_slot = "torso",
        appearance = { worn_description = "A heavy wool cloak drapes over your shoulders." },
    }
    local player = fresh_player({ worn = { "wool-cloak" } })
    local reg = make_mock_registry({ ["wool-cloak"] = cloak })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("cloak") or desc:find("drapes"),
        "Should show worn cloak, got: " .. desc)
end)

test("V52-3: injury visible in mirror", function()
    local player = fresh_player({
        injuries = {{ type = "bleeding", severity = "moderate",
            location = "left arm", _state = "active" }},
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("arm") or desc:find("gash"),
        "Should show arm injury, got: " .. desc)
end)

test("V52-4: combined state — worn + held + injured + health", function()
    local knife = { id = "knife", name = "a small knife" }
    local helm = {
        id = "iron-helm", name = "an iron helm",
        wear_slot = "head", is_helmet = true,
    }
    local player = fresh_player({
        hands = { knife, nil },
        worn = { "iron-helm" },
        injuries = {{ type = "bleeding", severity = "moderate",
            location = "left arm", _state = "active" }},
    })
    local reg = make_mock_registry({ knife = knife, ["iron-helm"] = helm })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("knife"), "Should show knife, got: " .. desc)
    truthy(desc:find("helm") or desc:find("head"),
        "Should show helmet, got: " .. desc)
    truthy(desc:find("arm") or desc:find("gash"),
        "Should show injury, got: " .. desc)
    truthy(desc:find("healthy") or desc:find("alert"),
        "Should show health, got: " .. desc)
end)

test("V52-5: output starts with 'In the mirror' prefix", function()
    local player = fresh_player()
    local desc = appearance.describe(player, nil)
    truthy(desc:find("^In the mirror") or desc:find("^Your reflection"),
        "Should start with mirror prefix, got: " .. desc)
end)

---------------------------------------------------------------------------
-- VERIFY #53: "get pot" single take message (no duplicate output)
---------------------------------------------------------------------------
suite("VERIFY #53 — get pot no duplicate output")

local function make_take_ctx(room_objects)
    local objs = {}
    local room_contents = {}
    for _, obj in ipairs(room_objects) do
        objs[obj.id] = obj
        room_contents[#room_contents + 1] = obj.id
    end
    return {
        registry = make_mock_registry(objs),
        current_room = { id = "test-room", name = "Test Room",
            contents = room_contents, exits = {}, light_level = 1 },
        player = { hands = { nil, nil }, worn = {}, state = {} },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
end

local function make_pot()
    return {
        id = "chamber-pot", name = "a ceramic chamber pot",
        keywords = {"chamber pot", "pot", "ceramic pot"},
        portable = true, container = true, contents = {},
        categories = {"ceramic", "container"}, mutations = {},
    }
end

test("V53-1: 'get pot' prints 'You take' exactly once", function()
    local ctx = make_take_ctx({ make_pot() })
    local output = capture_output(function()
        handlers["get"](ctx, "pot")
    end)
    local count = 0
    for _ in output:gmatch("You take") do count = count + 1 end
    eq(1, count, "'get pot' should print 'You take' exactly once, got " .. count .. " in: " .. output)
end)

test("V53-2: 'take pot' prints 'You take' exactly once", function()
    local ctx = make_take_ctx({ make_pot() })
    local output = capture_output(function()
        handlers["take"](ctx, "pot")
    end)
    local count = 0
    for _ in output:gmatch("You take") do count = count + 1 end
    eq(1, count, "'take pot' should print 'You take' exactly once, got " .. count .. " in: " .. output)
end)

test("V53-3: 'grab pot' prints 'You take' exactly once", function()
    local ctx = make_take_ctx({ make_pot() })
    local output = capture_output(function()
        handlers["grab"](ctx, "pot")
    end)
    local count = 0
    for _ in output:gmatch("You take") do count = count + 1 end
    eq(1, count, "'grab pot' should print 'You take' exactly once, got " .. count .. " in: " .. output)
end)

---------------------------------------------------------------------------
-- VERIFY BUG-116: "get X from Y" blocked on closed container
---------------------------------------------------------------------------
suite("VERIFY BUG-116 — get from closed container blocked")

local function make_drawer_ctx(drawer_open)
    local matchbox = {
        id = "matchbox", name = "a small matchbox",
        keywords = {"matchbox", "match box", "box of matches"},
        portable = true, container = true, is_open = true,
        contents = {}, categories = {"small", "container"},
    }
    local drawer = {
        id = "drawer", name = "a small drawer",
        keywords = {"drawer", "small drawer"},
        container = true,
        is_open = drawer_open,
        accessible = drawer_open and true or false,
        contents = {"matchbox"},
        categories = {"furniture", "wooden", "container"},
    }
    return {
        registry = make_mock_registry({ matchbox = matchbox, drawer = drawer }),
        current_room = { id = "test-room", name = "Test Room",
            contents = { "drawer" }, exits = {}, light_level = 1 },
        player = { hands = { nil, nil }, worn = {}, state = {} },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
end

test("V116-1: 'get matchbox from drawer' fails when drawer closed", function()
    local ctx = make_drawer_ctx(false)
    local output = capture_output(function()
        handlers["get"](ctx, "matchbox from drawer")
    end)
    local lower = output:lower()
    truthy(not lower:find("you take"),
        "Should NOT take from closed drawer, got: " .. output)
    truthy(lower:find("closed") or lower:find("not accessible"),
        "Should mention closed, got: " .. output)
end)

test("V116-2: 'get matchbox from drawer' works when drawer open", function()
    local ctx = make_drawer_ctx(true)
    local output = capture_output(function()
        handlers["get"](ctx, "matchbox from drawer")
    end)
    local lower = output:lower()
    truthy(lower:find("you take") or lower:find("matchbox"),
        "Should take from open drawer, got: " .. output)
end)

test("V116-3: item stays in drawer when closed", function()
    local ctx = make_drawer_ctx(false)
    capture_output(function()
        handlers["get"](ctx, "matchbox from drawer")
    end)
    local drawer = ctx.registry:get("drawer")
    local still_there = false
    for _, id in ipairs(drawer.contents) do
        if id == "matchbox" then still_there = true; break end
    end
    truthy(still_there, "Matchbox should remain in closed drawer")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
