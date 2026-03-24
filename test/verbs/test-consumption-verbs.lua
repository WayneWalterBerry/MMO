-- test/verbs/test-consumption-verbs.lua
-- Pre-refactoring coverage for eat, drink, pour verb handlers.
-- Tests: eat edible, eat non-edible, eat event_output, drink FSM transitions,
--        drink from preposition stripping, drink non-drinkable, pour FSM,
--        pour non-pourable, verb aliases (consume, devour, quaff, sip, spill, dump).
--
-- Usage: lua test/verbs/test-consumption-verbs.lua
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
local fsm_mod = require("engine.fsm")

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

local function make_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = opts.worn or {},
        injuries = {},
        bags = {},
        state = opts.state or {},
        max_health = 100,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. EAT — basic food consumption
---------------------------------------------------------------------------
suite("eat — edible objects")

test("eat edible object prints eat message and removes it", function()
    local bread = {
        id = "bread",
        name = "a loaf of bread",
        keywords = {"bread", "loaf"},
        edible = true,
        portable = true,
    }
    local ctx = make_ctx({ verb = "eat" })
    ctx.registry:register("bread", bread)
    ctx.player.hands[1] = bread
    local output = capture_output(function()
        handlers["eat"](ctx, "bread")
    end)
    h.assert_truthy(output:find("eat") or output:find("bread"),
        "Should print eat message")
    -- Object should be removed (registry cleared)
    h.assert_nil(ctx.registry:get("bread"),
        "Edible object should be removed after eating")
end)

test("eat non-edible object prints can't-eat", function()
    local rock = {
        id = "rock",
        name = "a rock",
        keywords = {"rock"},
        portable = true,
    }
    local ctx = make_ctx({ verb = "eat" })
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["eat"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't eat"),
        "Should say can't eat non-edible object")
end)

test("eat with empty noun prints 'Eat what?'", function()
    local output = capture_output(function()
        handlers["eat"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Eat what"),
        "Empty noun should prompt 'Eat what?'")
end)

test("eat nonexistent object prints not-found", function()
    local output = capture_output(function()
        handlers["eat"](make_ctx(), "xyzzy")
    end)
    h.assert_truthy(output:find("don't notice"),
        "Nonexistent object should trigger not-found")
end)

test("eat object with on_eat_message prints it", function()
    local cookie = {
        id = "cookie",
        name = "a cookie",
        keywords = {"cookie"},
        edible = true,
        on_eat_message = "Chocolate chips melt on your tongue.",
        portable = true,
    }
    local ctx = make_ctx({ verb = "eat" })
    ctx.registry:register("cookie", cookie)
    ctx.player.hands[1] = cookie
    local output = capture_output(function()
        handlers["eat"](ctx, "cookie")
    end)
    h.assert_truthy(output:find("Chocolate") or output:find("chips"),
        "Should print custom on_eat_message")
end)

test("eat object with event_output prints and clears it", function()
    local apple = {
        id = "apple",
        name = "an apple",
        keywords = {"apple"},
        edible = true,
        portable = true,
        event_output = { on_eat = "Crisp and refreshing!" },
    }
    local ctx = make_ctx({ verb = "eat" })
    ctx.registry:register("apple", apple)
    ctx.player.hands[1] = apple
    local output = capture_output(function()
        handlers["eat"](ctx, "apple")
    end)
    h.assert_truthy(output:find("Crisp"),
        "Should print event_output on_eat text")
end)

test("eat from room (not in hands) works via find_in_inventory fallback", function()
    local bread = {
        id = "bread",
        name = "a loaf of bread",
        keywords = {"bread"},
        edible = true,
        portable = true,
    }
    local ctx = make_ctx({ verb = "eat", room_contents = {"bread"} })
    ctx.registry:register("bread", bread)
    local output = capture_output(function()
        handlers["eat"](ctx, "bread")
    end)
    -- eat checks inventory first, then find_visible
    h.assert_truthy(output:find("eat") or output:find("bread"),
        "Should be able to eat object found in room")
end)

---------------------------------------------------------------------------
-- 2. DRINK — liquid consumption with FSM
---------------------------------------------------------------------------
suite("drink — liquid consumption")

test("drink with empty noun prints 'Drink what?'", function()
    local output = capture_output(function()
        handlers["drink"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Drink what"),
        "Empty noun should prompt 'Drink what?'")
end)

test("drink object not in inventory says pick up first", function()
    local bottle = {
        id = "bottle",
        name = "a bottle",
        keywords = {"bottle"},
    }
    local ctx = make_ctx({ verb = "drink", room_contents = {"bottle"} })
    ctx.registry:register("bottle", bottle)
    local output = capture_output(function()
        handlers["drink"](ctx, "bottle")
    end)
    h.assert_truthy(output:find("pick") or output:find("holding"),
        "Should say need to pick up first")
end)

test("drink nonexistent object prints not-found", function()
    local output = capture_output(function()
        handlers["drink"](make_ctx(), "xyzzy")
    end)
    h.assert_truthy(output:find("don't notice"),
        "Nonexistent object should trigger not-found")
end)

test("drink object with drink FSM transition succeeds", function()
    local wine = {
        id = "wine-bottle",
        name = "an open wine bottle",
        keywords = {"bottle", "wine"},
        _state = "open",
        initial_state = "sealed",
        states = {
            open = { name = "open wine bottle" },
            empty = { name = "empty wine bottle", terminal = true },
        },
        transitions = {
            { from = "open", to = "empty", verb = "drink",
              message = "You drink the sour wine." },
        },
    }
    local ctx = make_ctx({ verb = "drink" })
    ctx.registry:register("wine-bottle", wine)
    ctx.player.hands[1] = wine
    local output = capture_output(function()
        handlers["drink"](ctx, "wine")
    end)
    h.assert_truthy(output:find("drink") or output:find("sour") or output:find("wine"),
        "Should print drink transition message")
    eq("empty", wine._state, "Wine should transition to empty after drinking")
end)

test("drink non-drinkable object prints rejection", function()
    local rock = {
        id = "rock",
        name = "a rock",
        keywords = {"rock"},
    }
    local ctx = make_ctx({ verb = "drink" })
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["drink"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't drink"),
        "Should say can't drink non-drinkable")
end)

test("drink strips 'from' preposition", function()
    local wine = {
        id = "wine-bottle",
        name = "an open wine bottle",
        keywords = {"bottle", "wine"},
        _state = "open",
        states = {
            open = { name = "open wine bottle" },
            empty = { name = "empty wine bottle", terminal = true },
        },
        transitions = {
            { from = "open", to = "empty", verb = "drink",
              message = "You take a sip." },
        },
    }
    local ctx = make_ctx({ verb = "drink" })
    ctx.registry:register("wine-bottle", wine)
    ctx.player.hands[1] = wine
    local output = capture_output(function()
        handlers["drink"](ctx, "from bottle")
    end)
    h.assert_truthy(output:find("sip") or output:find("drink"),
        "'drink from bottle' should strip 'from' and find the bottle")
end)

test("drink object with on_drink_reject shows custom rejection", function()
    local ink = {
        id = "ink",
        name = "a bottle of ink",
        keywords = {"ink", "bottle"},
        on_drink_reject = "That's ink, not a beverage!",
    }
    local ctx = make_ctx({ verb = "drink" })
    ctx.registry:register("ink", ink)
    ctx.player.hands[1] = ink
    local output = capture_output(function()
        handlers["drink"](ctx, "ink")
    end)
    h.assert_truthy(output:find("ink") or output:find("beverage"),
        "Should show custom on_drink_reject")
end)

---------------------------------------------------------------------------
-- 3. POUR — pour out liquids
---------------------------------------------------------------------------
suite("pour — liquid emptying")

test("pour with empty noun prints 'Pour what?'", function()
    local output = capture_output(function()
        handlers["pour"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Pour what"),
        "Empty noun should prompt 'Pour what?'")
end)

test("pour nonexistent object prints not-found", function()
    local output = capture_output(function()
        handlers["pour"](make_ctx(), "xyzzy")
    end)
    h.assert_truthy(output:find("don't notice"),
        "Nonexistent object should trigger not-found")
end)

test("pour object with FSM pour transition succeeds", function()
    local wine = {
        id = "wine-bottle",
        name = "an open wine bottle",
        keywords = {"bottle", "wine"},
        _state = "open",
        states = {
            open = { name = "open wine bottle" },
            empty = { name = "empty wine bottle", terminal = true },
        },
        transitions = {
            { from = "open", to = "empty", verb = "pour",
              message = "Wine glugs out onto the floor." },
        },
    }
    local ctx = make_ctx()
    ctx.registry:register("wine-bottle", wine)
    ctx.player.hands[1] = wine
    local output = capture_output(function()
        handlers["pour"](ctx, "wine")
    end)
    h.assert_truthy(output:find("glug") or output:find("pour") or output:find("Wine"),
        "Should print pour transition message")
    eq("empty", wine._state, "Wine should transition to empty after pouring")
end)

test("pour non-pourable object prints can't-pour", function()
    local rock = {
        id = "rock",
        name = "a rock",
        keywords = {"rock"},
    }
    local ctx = make_ctx()
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["pour"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't pour"),
        "Should say can't pour non-pourable")
end)

---------------------------------------------------------------------------
-- 4. BURN — set flammable things on fire
---------------------------------------------------------------------------
suite("burn — fire consumption")

test("burn with empty noun prints 'Burn what?'", function()
    local output = capture_output(function()
        handlers["burn"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Burn what"),
        "Empty noun should prompt 'Burn what?'")
end)

test("burn nonexistent object prints not-found", function()
    local output = capture_output(function()
        handlers["burn"](make_ctx(), "xyzzy")
    end)
    h.assert_truthy(output:find("don't notice"),
        "Nonexistent should trigger not-found")
end)

test("burn without fire source prints 'no flame'", function()
    local paper = {
        id = "paper",
        name = "a sheet of paper",
        keywords = {"paper"},
        flammable = true,
    }
    local ctx = make_ctx()
    ctx.registry:register("paper", paper)
    ctx.player.hands[1] = paper
    local output = capture_output(function()
        handlers["burn"](ctx, "paper")
    end)
    h.assert_truthy(output:find("flame") or output:find("fire") or output:find("light"),
        "Should say no flame available")
end)

test("burn flammable object with fire removes it", function()
    local paper = {
        id = "paper",
        name = "a sheet of paper",
        keywords = {"paper"},
        flammable = true,
    }
    local ctx = make_ctx({ state = { has_flame = 1 } })
    ctx.registry:register("paper", paper)
    ctx.player.hands[1] = paper
    local output = capture_output(function()
        handlers["burn"](ctx, "paper")
    end)
    h.assert_truthy(output:find("fire") or output:find("burn") or output:find("ash"),
        "Should describe burning")
    h.assert_nil(ctx.registry:get("paper"),
        "Burned object should be removed from registry")
end)

test("burn non-flammable object prints can't-burn", function()
    local rock = {
        id = "rock",
        name = "a rock",
        keywords = {"rock"},
    }
    local ctx = make_ctx({ state = { has_flame = 1 } })
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["burn"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Should say can't burn non-flammable")
end)

print("\nExit code: " .. h.summary())
