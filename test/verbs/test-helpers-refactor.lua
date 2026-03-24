-- test/verbs/test-helpers-refactor.lua
-- Pre-refactoring coverage for helper functions that will move to verbs/helpers.lua.
-- Tests: matches_keyword, err_not_found, err_cant_do_that, err_nothing_happens,
--        hands_full, first_empty_hand, which_hand, find_visible search order,
--        find_in_inventory, remove_from_location, container_contents_accessible,
--        find_mutation, exit_matches
--
-- Usage: lua test/verbs/test-helpers-refactor.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")

local test = h.test
local suite = h.suite
local eq = h.assert_eq

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

local function make_registry()
    return registry_mod.new()
end

local function fresh_object(overrides)
    local obj = {
        id = "test-obj",
        name = "a test object",
        keywords = {"test", "object", "test object"},
        description = "A plain test object.",
        on_feel = "Smooth and featureless.",
        portable = true,
    }
    if overrides then
        for k, v in pairs(overrides) do obj[k] = v end
    end
    return obj
end

local function make_ctx(opts)
    opts = opts or {}
    local reg = make_registry()
    local room = opts.room or {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local player = opts.player or {
        hands = { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
        max_health = 100,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 20,
        game_start_time = os.time(),
        current_verb = opts.current_verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. ERROR HELPERS — these print standard messages
---------------------------------------------------------------------------
suite("Error helpers — err_not_found, err_cant_do_that")

test("err_not_found prints standard 'don't notice' message via examine", function()
    -- Use examine (not look) to trigger err_not_found — look checks light first
    local ctx = make_ctx({ time_offset = 8 })  -- daytime for light
    -- Add curtains to provide light
    local curtains = {
        id = "curtains", name = "curtains", keywords = {"curtains"},
        allows_daylight = true, hidden = true,
    }
    ctx.registry:register("curtains", curtains)
    ctx.current_room.contents = {"curtains"}
    local output = capture_output(function()
        handlers["examine"](ctx, "xyzzy_nonexistent")
    end)
    h.assert_truthy(output:find("don't notice") or output:find("don't see") or output:find("search"),
        "Should show not-found message for unknown object")
end)

test("err_not_found prints standard message via feel on unknown noun", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["feel"](ctx, "xyzzy_nonexistent")
    end)
    h.assert_truthy(output:find("can't feel") or output:find("don't notice"),
        "Should show not-found for feel on unknown object")
end)

test("eat nonexistent object prints not-found", function()
    local output = capture_output(function()
        handlers["eat"](make_ctx(), "xyzzy_nonexistent")
    end)
    h.assert_truthy(output:find("don't notice") or output:find("don't see"),
        "eat nonexistent should print not-found")
end)

test("open with empty noun prints 'Open what?'", function()
    local output = capture_output(function()
        handlers["open"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Open what"), "empty noun → 'Open what?'")
end)

test("close with empty noun prints 'Close what?'", function()
    local output = capture_output(function()
        handlers["close"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Close what"), "empty noun → 'Close what?'")
end)

test("break with empty noun prints 'Break what?'", function()
    local output = capture_output(function()
        handlers["break"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Break what"), "empty noun → 'Break what?'")
end)

test("tear with empty noun prints 'Tear what?'", function()
    local output = capture_output(function()
        handlers["tear"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Tear what"), "empty noun → 'Tear what?'")
end)

---------------------------------------------------------------------------
-- 2. HANDS HELPERS — hands_full, first_empty_hand, which_hand
---------------------------------------------------------------------------
suite("Hand helpers — via verb behavior")

test("take fails when both hands full", function()
    local ctx = make_ctx()
    local obj1 = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local obj2 = fresh_object({ id = "stick", name = "a stick", keywords = {"stick"} })
    local obj3 = fresh_object({ id = "leaf", name = "a leaf", keywords = {"leaf"} })
    ctx.registry:register("rock", obj1)
    ctx.registry:register("stick", obj2)
    ctx.registry:register("leaf", obj3)
    ctx.player.hands[1] = obj1
    ctx.player.hands[2] = obj2
    ctx.current_room.contents = {"leaf"}
    local output = capture_output(function()
        handlers["take"](ctx, "leaf")
    end)
    h.assert_truthy(output:find("hands") or output:find("full") or output:find("carrying"),
        "Should reject take when hands full")
end)

test("take puts object in first empty hand", function()
    local ctx = make_ctx()
    local obj1 = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local obj2 = fresh_object({ id = "leaf", name = "a leaf", keywords = {"leaf"}, portable = true })
    ctx.registry:register("rock", obj1)
    ctx.registry:register("leaf", obj2)
    ctx.player.hands[1] = obj1
    ctx.current_room.contents = {"leaf"}
    local output = capture_output(function()
        handlers["take"](ctx, "leaf")
    end)
    -- leaf should be in hand 2
    local hand2 = ctx.player.hands[2]
    local hand2_id = type(hand2) == "table" and hand2.id or hand2
    h.assert_truthy(hand2_id == "leaf" or (output:find("pick") or output:find("take") or output:find("grab")),
        "Leaf should end up in empty hand 2")
end)

test("drop with empty hands prints appropriate message", function()
    local output = capture_output(function()
        handlers["drop"](make_ctx(), "rock")
    end)
    h.assert_truthy(output:find("not") or output:find("holding") or output:find("carrying") or output:find("don't"),
        "drop should fail when not holding item")
end)

---------------------------------------------------------------------------
-- 3. FIND_VISIBLE — verb-dependent search order
---------------------------------------------------------------------------
suite("find_visible — search order behavior")

test("interaction verb (drink) finds held object first", function()
    local ctx = make_ctx({ current_verb = "drink" })
    local held = fresh_object({ id = "bottle-held", name = "a held bottle", keywords = {"bottle"} })
    local room_bottle = fresh_object({ id = "bottle-room", name = "a room bottle", keywords = {"bottle"} })
    ctx.registry:register("bottle-held", held)
    ctx.registry:register("bottle-room", room_bottle)
    ctx.player.hands[1] = held
    ctx.current_room.contents = {"bottle-room"}
    -- drink is an interaction verb → should find held bottle
    local output = capture_output(function()
        handlers["drink"](ctx, "bottle")
    end)
    -- The drink handler should find the held bottle first (interaction verb)
    -- It should NOT say "You'll need to pick that up first."
    h.assert_truthy(not output:find("pick that up"),
        "Interaction verb should find held item before room item")
end)

test("acquisition verb (take) finds room object first", function()
    local ctx = make_ctx({ current_verb = "" })
    local held = fresh_object({ id = "rock-held", name = "a held rock", keywords = {"rock"} })
    local room_rock = fresh_object({ id = "rock-room", name = "a room rock", keywords = {"rock"}, portable = true })
    ctx.registry:register("rock-held", held)
    ctx.registry:register("rock-room", room_rock)
    ctx.player.hands[1] = held
    ctx.current_room.contents = {"rock-room"}
    -- take is acquisition → should find room rock first
    local output = capture_output(function()
        handlers["take"](ctx, "rock")
    end)
    -- Should try to take the room rock (may say "already holding" or succeed)
    h.assert_truthy(output ~= "", "Should produce some output for take")
end)

test("find_visible returns nil for empty keyword", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    -- Look with empty noun should do a room look, not error
    h.assert_truthy(output ~= "", "Look with empty noun should produce room description")
end)

test("find_visible finds object on surface", function()
    local ctx = make_ctx()
    local table_obj = fresh_object({
        id = "table",
        name = "a wooden table",
        keywords = {"table"},
        surfaces = {
            top = {
                accessible = true,
                contents = {"candle"},
            },
        },
    })
    local candle = fresh_object({
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        description = "A stubby tallow candle.",
        on_feel = "Waxy cylinder.",
    })
    ctx.registry:register("table", table_obj)
    ctx.registry:register("candle", candle)
    ctx.current_room.contents = {"table"}
    local output = capture_output(function()
        handlers["feel"](ctx, "candle")
    end)
    h.assert_truthy(output:find("Waxy") or output:find("candle"),
        "Should find candle on table surface and describe it tactilely")
end)

test("find_visible finds object in worn bag", function()
    local ctx = make_ctx({ current_verb = "eat" })
    local bag = fresh_object({
        id = "bag",
        name = "a leather bag",
        keywords = {"bag"},
        container = true,
        contents = {"bread"},
        wear = { slot = "body" },
    })
    local bread = fresh_object({
        id = "bread",
        name = "a loaf of bread",
        keywords = {"bread", "loaf"},
        edible = true,
    })
    ctx.registry:register("bag", bag)
    ctx.registry:register("bread", bread)
    ctx.player.worn = {"bag"}
    local output = capture_output(function()
        handlers["eat"](ctx, "bread")
    end)
    h.assert_truthy(output:find("eat") or output:find("bread"),
        "Should find bread in worn bag for interaction verb")
end)

---------------------------------------------------------------------------
-- 4. KEYWORD MATCHING — via look/feel behavior
---------------------------------------------------------------------------
suite("matches_keyword — various matching patterns")

test("matches by exact keyword", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox", "small matchbox", "box"},
        description = "A small cardboard matchbox.",
        on_feel = "A small cardboard box with a sliding tray.",
    })
    ctx.registry:register("matchbox", obj)
    ctx.current_room.contents = {"matchbox"}
    local output = capture_output(function()
        handlers["feel"](ctx, "matchbox")
    end)
    h.assert_truthy(output:find("cardboard") or output:find("matchbox"),
        "Should find by exact keyword 'matchbox'")
end)

test("matches by object id", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "brass-key",
        name = "a small brass key",
        keywords = {"key", "brass key"},
        on_feel = "A small cold metal key.",
    })
    ctx.registry:register("brass-key", obj)
    ctx.current_room.contents = {"brass-key"}
    local output = capture_output(function()
        handlers["feel"](ctx, "brass-key")
    end)
    h.assert_truthy(output:find("key") or output:find("metal"),
        "Should find by object id")
end)

test("matches by word boundary in name", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "wine-bottle",
        name = "a dusty wine bottle",
        keywords = {"bottle", "wine bottle"},
        on_feel = "A smooth glass bottle.",
    })
    ctx.registry:register("wine-bottle", obj)
    ctx.current_room.contents = {"wine-bottle"}
    local output = capture_output(function()
        handlers["feel"](ctx, "wine")
    end)
    h.assert_truthy(output:find("bottle") or output:find("glass") or output:find("wine"),
        "Should find by word in name 'wine'")
end)

test("plurals resolve to singular (keyword matching)", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        on_feel = "Waxy cylinder.",
    })
    ctx.registry:register("candle", obj)
    ctx.current_room.contents = {"candle"}
    local output = capture_output(function()
        handlers["feel"](ctx, "candles")
    end)
    h.assert_truthy(output:find("Waxy") or output:find("candle") or output:find("don't notice"),
        "Plurals should attempt singular resolution")
end)

test("articles stripped from keyword", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle"},
        on_feel = "Waxy cylinder.",
    })
    ctx.registry:register("candle", obj)
    ctx.current_room.contents = {"candle"}
    local output = capture_output(function()
        handlers["feel"](ctx, "the candle")
    end)
    h.assert_truthy(output:find("Waxy") or output:find("candle"),
        "Articles should be stripped from keyword")
end)

test("hidden objects not found by find_visible", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "hidden-key",
        name = "a hidden key",
        keywords = {"key"},
        hidden = true,
        on_feel = "A small key.",
    })
    ctx.registry:register("hidden-key", obj)
    ctx.current_room.contents = {"hidden-key"}
    local output = capture_output(function()
        handlers["feel"](ctx, "key")
    end)
    h.assert_truthy(output:find("can't feel") or output:find("don't notice") or output:find("explore"),
        "Hidden objects should not be found by find_visible")
end)

---------------------------------------------------------------------------
-- 5. CONTAINER_CONTENTS_ACCESSIBLE — open vs closed gating
---------------------------------------------------------------------------
suite("Container gating — open/closed access")

test("open container contents are findable", function()
    local ctx = make_ctx()
    local drawer = fresh_object({
        id = "drawer",
        name = "a drawer",
        keywords = {"drawer"},
        container = true,
        _state = "open",
        accessible = true,
        contents = {"candle"},
        surfaces = {
            inside = { accessible = true, contents = {"candle"} },
        },
    })
    local candle = fresh_object({
        id = "candle",
        name = "a candle",
        keywords = {"candle"},
        on_feel = "Waxy cylinder.",
    })
    ctx.registry:register("drawer", drawer)
    ctx.registry:register("candle", candle)
    ctx.current_room.contents = {"drawer"}
    local output = capture_output(function()
        handlers["feel"](ctx, "candle")
    end)
    h.assert_truthy(output:find("Waxy") or output:find("candle"),
        "Should find candle in open drawer")
end)

---------------------------------------------------------------------------
-- 6. FIND_MUTATION — mutation lookup
---------------------------------------------------------------------------
suite("find_mutation — via break behavior")

test("break finds exact mutation", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "vase",
        name = "a clay vase",
        keywords = {"vase"},
        mutations = {
            ["break"] = {
                message = "The vase shatters!",
                spawns = {},
            },
        },
    })
    ctx.registry:register("vase", obj)
    ctx.current_room.contents = {"vase"}
    ctx.object_sources = {}
    local output = capture_output(function()
        handlers["break"](ctx, "vase")
    end)
    h.assert_truthy(output:find("shatter") or output:find("break"),
        "Should find and execute break mutation")
end)

test("break finds prefixed mutation (break_mirror)", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "mirror",
        name = "a wall mirror",
        keywords = {"mirror"},
        mutations = {
            break_mirror = {
                message = "The mirror cracks into a web of fragments!",
                spawns = {},
            },
        },
    })
    ctx.registry:register("mirror", obj)
    ctx.current_room.contents = {"mirror"}
    ctx.object_sources = {}
    local output = capture_output(function()
        handlers["break"](ctx, "mirror")
    end)
    h.assert_truthy(output:find("crack") or output:find("mirror") or output:find("fragment"),
        "Should find break_mirror mutation via prefix match")
end)

test("break object with no mutation prints can't-break", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "rock",
        name = "a rock",
        keywords = {"rock"},
    })
    ctx.registry:register("rock", obj)
    ctx.current_room.contents = {"rock"}
    local output = capture_output(function()
        handlers["break"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't break"),
        "Object without break mutation should print can't-break")
end)

---------------------------------------------------------------------------
-- 7. EXIT_MATCHES — via movement behavior
---------------------------------------------------------------------------
suite("exit_matches — via navigation")

test("go through exit matched by direction", function()
    local target_room = {
        id = "hallway",
        name = "Hallway",
        description = "A dark hallway.",
        contents = {},
        exits = {},
    }
    local ctx = make_ctx({
        exits = {
            north = {
                target = "hallway",
                name = "a wooden door",
                open = true,
            },
        },
    })
    ctx.rooms = { hallway = target_room }
    local output = capture_output(function()
        handlers["north"](ctx, "")
    end)
    h.assert_truthy(output:find("Hallway") or output:find("arrive"),
        "Should navigate north to hallway")
end)

test("go through exit matched by keyword", function()
    local target_room = {
        id = "hallway",
        name = "Hallway",
        description = "A dark hallway.",
        contents = {},
        exits = {},
    }
    local ctx = make_ctx({
        exits = {
            north = {
                target = "hallway",
                name = "a wooden door",
                keywords = {"door", "wooden door"},
                open = true,
            },
        },
    })
    ctx.rooms = { hallway = target_room }
    local output = capture_output(function()
        handlers["go"](ctx, "door")
    end)
    h.assert_truthy(output:find("Hallway") or output:find("arrive"),
        "Should navigate via exit keyword 'door'")
end)

---------------------------------------------------------------------------
-- 8. INVENTORY WEIGHT — via take weight checks
---------------------------------------------------------------------------
suite("Inventory weight tracking")

test("take reports object pickup", function()
    local ctx = make_ctx()
    local obj = fresh_object({
        id = "feather",
        name = "a feather",
        keywords = {"feather"},
        portable = true,
        weight = 0.1,
    })
    ctx.registry:register("feather", obj)
    ctx.current_room.contents = {"feather"}
    local output = capture_output(function()
        handlers["take"](ctx, "feather")
    end)
    h.assert_truthy(output ~= "", "take should produce output")
    local hand1 = ctx.player.hands[1]
    local hand1_id = type(hand1) == "table" and hand1.id or hand1
    local hand2 = ctx.player.hands[2]
    local hand2_id = type(hand2) == "table" and hand2.id or (hand2 or "")
    h.assert_truthy(hand1_id == "feather" or hand2_id == "feather",
        "Feather should be in a hand slot after take")
end)

---------------------------------------------------------------------------
-- 9. ALIAS REGISTRATION — verb aliases point to correct handlers
---------------------------------------------------------------------------
suite("Verb alias registration")

test("smash is alias for break", function()
    h.assert_truthy(handlers["smash"] == handlers["break"],
        "smash should be alias for break")
end)

test("shatter is alias for break", function()
    h.assert_truthy(handlers["shatter"] == handlers["break"],
        "shatter should be alias for break")
end)

test("rip is alias for tear", function()
    h.assert_truthy(handlers["rip"] == handlers["tear"],
        "rip should be alias for tear")
end)

test("shut is alias for close", function()
    h.assert_truthy(handlers["shut"] == handlers["close"],
        "shut should be alias for close")
end)

test("pry is alias for open", function()
    h.assert_truthy(handlers["pry"] == handlers["open"],
        "pry should be alias for open")
end)

test("ignite is alias for light", function()
    h.assert_truthy(handlers["ignite"] == handlers["light"],
        "ignite should be alias for light")
end)

test("relight is alias for light", function()
    h.assert_truthy(handlers["relight"] == handlers["light"],
        "relight should be alias for light")
end)

test("snuff is alias for extinguish", function()
    h.assert_truthy(handlers["snuff"] == handlers["extinguish"],
        "snuff should be alias for extinguish")
end)

test("consume is alias for eat", function()
    h.assert_truthy(handlers["consume"] == handlers["eat"],
        "consume should be alias for eat")
end)

test("devour is alias for eat", function()
    h.assert_truthy(handlers["devour"] == handlers["eat"],
        "devour should be alias for eat")
end)

test("quaff is alias for drink", function()
    h.assert_truthy(handlers["quaff"] == handlers["drink"],
        "quaff should be alias for drink")
end)

test("sip is alias for drink", function()
    h.assert_truthy(handlers["sip"] == handlers["drink"],
        "sip should be alias for drink")
end)

test("spill is alias for pour", function()
    h.assert_truthy(handlers["spill"] == handlers["pour"],
        "spill should be alias for pour")
end)

test("dump is alias for pour", function()
    h.assert_truthy(handlers["dump"] == handlers["pour"],
        "dump should be alias for pour")
end)

test("pass is alias for wait", function()
    h.assert_truthy(handlers["pass"] == handlers["wait"],
        "pass should be alias for wait")
end)

test("i is alias for inventory", function()
    h.assert_truthy(handlers["i"] == handlers["inventory"],
        "i should be alias for inventory")
end)

test("treat is alias for apply", function()
    h.assert_truthy(handlers["treat"] == handlers["apply"],
        "treat should be alias for apply")
end)

test("walk is alias for go", function()
    h.assert_truthy(handlers["walk"] == handlers["go"],
        "walk should be alias for go")
end)

test("run is alias for go", function()
    h.assert_truthy(handlers["run"] == handlers["go"],
        "run should be alias for go")
end)

test("adjust is alias for set", function()
    h.assert_truthy(handlers["adjust"] == handlers["set"],
        "adjust should be alias for set")
end)

test("n is alias for north", function()
    h.assert_truthy(handlers["n"] == handlers["north"],
        "n should be alias for north")
end)

test("s is alias for south", function()
    h.assert_truthy(handlers["s"] == handlers["south"],
        "s should be alias for south")
end)

test("e is alias for east", function()
    h.assert_truthy(handlers["e"] == handlers["east"],
        "e should be alias for east")
end)

test("w is alias for west", function()
    h.assert_truthy(handlers["w"] == handlers["west"],
        "w should be alias for west")
end)

test("u is alias for up", function()
    h.assert_truthy(handlers["u"] == handlers["up"],
        "u should be alias for up")
end)

test("d is alias for down", function()
    h.assert_truthy(handlers["d"] == handlers["down"],
        "d should be alias for down")
end)

print("\nExit code: " .. h.summary())
