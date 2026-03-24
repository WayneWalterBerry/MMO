-- test/verbs/test-meta-verbs.lua
-- Pre-refactoring coverage for meta/utility verb handlers.
-- Tests: help, wait, time, inventory, appearance, injuries, set/adjust.
--
-- Usage: lua test/verbs/test-meta-verbs.lua
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
local presentation = require("engine.ui.presentation")

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
        injuries = opts.injuries or {},
        bags = {},
        state = opts.state or {},
        max_health = 100,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 20,
        game_start_time = os.time(),
        current_verb = "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. HELP — should print comprehensive help
---------------------------------------------------------------------------
suite("help — help output")

test("help prints movement section", function()
    local output = capture_output(function()
        handlers["help"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Movement"),
        "Help should include Movement section")
end)

test("help prints observation section", function()
    local output = capture_output(function()
        handlers["help"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Observation"),
        "Help should include Observation section")
end)

test("help prints item interaction section", function()
    local output = capture_output(function()
        handlers["help"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Item Interaction"),
        "Help should include Item Interaction section")
end)

test("help prints equipment section", function()
    local output = capture_output(function()
        handlers["help"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Equipment"),
        "Help should include Equipment section")
end)

test("help prints combat section", function()
    local output = capture_output(function()
        handlers["help"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Combat"),
        "Help should include Combat section")
end)

test("help prints survival section", function()
    local output = capture_output(function()
        handlers["help"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Health") or output:find("Survival"),
        "Help should include Health/Survival section")
end)

test("help mentions quit command", function()
    local output = capture_output(function()
        handlers["help"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("quit"),
        "Help should mention quit command")
end)

---------------------------------------------------------------------------
-- 2. WAIT — pass time
---------------------------------------------------------------------------
suite("wait — time passing")

test("wait prints 'Time passes'", function()
    local output = capture_output(function()
        handlers["wait"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Time passes"),
        "Wait should print 'Time passes'")
end)

test("pass alias prints 'Time passes'", function()
    local output = capture_output(function()
        handlers["pass"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Time passes"),
        "Pass should also print 'Time passes'")
end)

---------------------------------------------------------------------------
-- 3. INVENTORY — display carried items
---------------------------------------------------------------------------
suite("inventory — display")

test("inventory with empty hands shows (empty)", function()
    local output = capture_output(function()
        handlers["inventory"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("empty"),
        "Empty inventory should show (empty)")
end)

test("inventory shows held item names", function()
    local knife = {
        id = "knife",
        name = "a small knife",
        keywords = {"knife"},
    }
    local ctx = make_ctx()
    ctx.registry:register("knife", knife)
    ctx.player.hands[1] = knife
    local output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)
    h.assert_truthy(output:find("knife") or output:find("Left hand"),
        "Inventory should show held knife")
end)

test("inventory shows worn items", function()
    local cloak = {
        id = "cloak",
        name = "a wool cloak",
        keywords = {"cloak"},
        wear = { slot = "body" },
    }
    local ctx = make_ctx({ worn = {"cloak"} })
    ctx.registry:register("cloak", cloak)
    local output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)
    h.assert_truthy(output:find("Worn") or output:find("cloak"),
        "Inventory should show worn items")
end)

test("inventory shows bag contents", function()
    local bag = {
        id = "bag",
        name = "a leather bag",
        keywords = {"bag"},
        container = true,
        contents = {"coin"},
    }
    local coin = {
        id = "coin",
        name = "a gold coin",
        keywords = {"coin"},
    }
    local ctx = make_ctx()
    ctx.registry:register("bag", bag)
    ctx.registry:register("coin", coin)
    ctx.player.hands[1] = bag
    local output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)
    h.assert_truthy(output:find("contains") or output:find("coin"),
        "Inventory should show bag contents")
end)

test("inventory shows flame status", function()
    local ctx = make_ctx({ state = { has_flame = 1 } })
    local output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)
    h.assert_truthy(output:find("flame") or output:find("match"),
        "Inventory should show active flame")
end)

test("i alias works like inventory", function()
    local output = capture_output(function()
        handlers["i"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("empty"),
        "'i' should work same as 'inventory'")
end)

---------------------------------------------------------------------------
-- 4. TIME — display game time
---------------------------------------------------------------------------
suite("time — game time display")

test("time handler produces output", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["time"](ctx, "")
    end)
    h.assert_truthy(output ~= "", "time should produce some output")
    h.assert_truthy(output:find("AM") or output:find("PM") or output:find("o'clock") or output:find(":"),
        "Time output should include time of day")
end)

---------------------------------------------------------------------------
-- 5. INJURIES — health display
---------------------------------------------------------------------------
suite("injuries — health display")

test("injuries with no injuries shows 'feel fine'", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["injuries"](ctx, "")
    end)
    h.assert_truthy(output:find("fine") or output:find("no injuries") or output:find("No active"),
        "No injuries should show positive message")
end)

test("injury alias works", function()
    h.assert_truthy(handlers["injury"] == handlers["injuries"],
        "injury should be alias for injuries")
end)

test("wounds alias works", function()
    h.assert_truthy(handlers["wounds"] == handlers["injuries"],
        "wounds should be alias for injuries")
end)

test("health alias works", function()
    h.assert_truthy(handlers["health"] == handlers["injuries"],
        "health should be alias for injuries")
end)

---------------------------------------------------------------------------
-- 6. APPEARANCE — player appearance
---------------------------------------------------------------------------
suite("appearance — player description")

test("appearance handler produces output", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["appearance"](ctx, "")
    end)
    h.assert_truthy(output ~= "", "appearance should produce some output")
end)

---------------------------------------------------------------------------
-- 7. SET/ADJUST — clock puzzle mechanic
---------------------------------------------------------------------------
suite("set/adjust — clock puzzle")

test("set with empty noun prints 'Set what?'", function()
    local output = capture_output(function()
        handlers["set"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Set what"),
        "Empty noun should prompt 'Set what?'")
end)

test("set non-adjustable object prints 'can't set'", function()
    local rock = {
        id = "rock",
        name = "a rock",
        keywords = {"rock"},
    }
    local ctx = make_ctx({ room_contents = {"rock"} })
    ctx.registry:register("rock", rock)
    local output = capture_output(function()
        handlers["set"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't set"),
        "Non-adjustable should say can't set")
end)

test("set adjustable clock advances the hour", function()
    local clock = {
        id = "wall-clock",
        name = "a wall clock",
        keywords = {"clock", "wall clock"},
        adjustable = true,
        _state = "hour_3",
        states = {
            hour_3 = { name = "3 o'clock" },
            hour_4 = { name = "4 o'clock" },
        },
        transitions = {},
    }
    -- Need light for set
    local curtains = {
        id = "curtains",
        name = "curtains",
        keywords = {"curtains"},
        allows_daylight = true,
        hidden = true,
    }
    local ctx = make_ctx({ room_contents = {"wall-clock", "curtains"}, time_offset = 8 })
    ctx.registry:register("wall-clock", clock)
    ctx.registry:register("curtains", curtains)
    local output = capture_output(function()
        handlers["set"](ctx, "clock")
    end)
    h.assert_truthy(output:find("four o'clock") or output:find("clock"),
        "Set should advance hour and report new time")
    eq("hour_4", clock._state, "Clock should advance from hour_3 to hour_4")
end)

test("set clock wraps from hour_24 to hour_1", function()
    local clock = {
        id = "wall-clock",
        name = "a wall clock",
        keywords = {"clock"},
        adjustable = true,
        _state = "hour_24",
        states = {
            hour_24 = { name = "midnight" },
            hour_1 = { name = "1 AM" },
        },
        transitions = {},
    }
    local curtains = {
        id = "curtains",
        name = "curtains",
        keywords = {"curtains"},
        allows_daylight = true,
        hidden = true,
    }
    local ctx = make_ctx({ room_contents = {"wall-clock", "curtains"}, time_offset = 8 })
    ctx.registry:register("wall-clock", clock)
    ctx.registry:register("curtains", curtains)
    local output = capture_output(function()
        handlers["set"](ctx, "clock")
    end)
    eq("hour_1", clock._state, "Clock should wrap from 24 to 1")
end)

test("set clock fires on_correct_time callback at target hour", function()
    local triggered = false
    local clock = {
        id = "wall-clock",
        name = "a wall clock",
        keywords = {"clock"},
        adjustable = true,
        _state = "hour_5",
        target_hour = 6,
        states = {
            hour_5 = { name = "5 o'clock" },
            hour_6 = { name = "6 o'clock" },
        },
        transitions = {},
        on_correct_time = function(self, ctx)
            triggered = true
        end,
    }
    local curtains = {
        id = "curtains",
        name = "curtains",
        keywords = {"curtains"},
        allows_daylight = true,
        hidden = true,
    }
    local ctx = make_ctx({ room_contents = {"wall-clock", "curtains"}, time_offset = 8 })
    ctx.registry:register("wall-clock", clock)
    ctx.registry:register("curtains", curtains)
    capture_output(function()
        handlers["set"](ctx, "clock")
    end)
    h.assert_truthy(triggered, "on_correct_time should fire when target hour reached")
end)

---------------------------------------------------------------------------
-- 8. REPORT_BUG — URL generation
---------------------------------------------------------------------------
suite("report_bug — URL generation")

test("report_bug handler exists", function()
    h.assert_truthy(handlers["report_bug"], "report_bug handler should exist")
end)

test("report_bug prints a URL", function()
    local ctx = make_ctx()
    ctx.transcript = {
        { input = "look", output = "You see nothing special." },
    }
    local output = capture_output(function()
        handlers["report_bug"](ctx, "")
    end)
    h.assert_truthy(output:find("github") or output:find("bug") or output:find("URL") or output:find("http"),
        "report_bug should output a GitHub URL")
end)

test("report_bug includes room name in output", function()
    local ctx = make_ctx()
    ctx.transcript = {}
    local output = capture_output(function()
        handlers["report_bug"](ctx, "")
    end)
    h.assert_truthy(output:find("Test Room") or output:find("github"),
        "report_bug should include room context")
end)

---------------------------------------------------------------------------
-- 9. APPLY — healing items (basic)
---------------------------------------------------------------------------
suite("apply — healing basics")

test("apply with empty noun prints prompt", function()
    local output = capture_output(function()
        handlers["apply"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Apply what") or output:find("examine"),
        "Empty noun should prompt for item")
end)

test("apply with no injuries prints 'no injuries'", function()
    local bandage = {
        id = "bandage",
        name = "a linen bandage",
        keywords = {"bandage"},
    }
    local ctx = make_ctx()
    ctx.registry:register("bandage", bandage)
    ctx.player.hands[1] = bandage
    local output = capture_output(function()
        handlers["apply"](ctx, "bandage")
    end)
    h.assert_truthy(output:find("don't have any injuries") or output:find("no injuries"),
        "Should say no injuries to treat")
end)

print("\nExit code: " .. h.summary())
