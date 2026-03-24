-- test/verbs/test-burn-material.lua
-- Tests for #120: Burnability derived from material flammability.
-- Covers: high-flammability materials burn, low-flammability materials don't,
--         FSM burn transitions, mutation burn paths, generic destruction,
--         no-flame rejection, no-material fallback.
--
-- Usage: lua test/verbs/test-burn-material.lua
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
        worn = {},
        injuries = {},
        bags = {},
        state = opts.state or {},
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "burn",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. High-flammability materials burn
---------------------------------------------------------------------------
suite("burn — high-flammability materials")

test("burn paper (flammability 0.8) destroys the object", function()
    local paper = {
        id = "paper",
        name = "a sheet of paper",
        keywords = {"paper"},
        material = "paper",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("paper", paper)
    ctx.player.hands[1] = paper
    local output = capture_output(function()
        handlers["burn"](ctx, "paper")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns"),
        "Paper should catch fire; got: " .. output)
    eq(ctx.registry:get("paper"), nil, "Paper should be removed from registry")
    eq(ctx.player.hands[1], nil, "Paper should be removed from hand")
end)

test("burn fabric (flammability 0.6) destroys the object", function()
    local rag = {
        id = "rag",
        name = "a dirty rag",
        keywords = {"rag"},
        material = "fabric",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("rag", rag)
    ctx.player.hands[1] = rag
    local output = capture_output(function()
        handlers["burn"](ctx, "rag")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns"),
        "Fabric should burn; got: " .. output)
    eq(ctx.registry:get("rag"), nil, "Rag should be removed from registry")
end)

test("burn wood (flammability 0.5) destroys the object", function()
    local stick = {
        id = "stick",
        name = "a wooden stick",
        keywords = {"stick"},
        material = "wood",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("stick", stick)
    ctx.player.hands[1] = stick
    local output = capture_output(function()
        handlers["burn"](ctx, "stick")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns"),
        "Wood should burn; got: " .. output)
    eq(ctx.registry:get("stick"), nil, "Stick should be removed from registry")
end)

test("burn cotton (flammability 0.7) destroys the object", function()
    local thread = {
        id = "thread",
        name = "a cotton thread",
        keywords = {"thread"},
        material = "cotton",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("thread", thread)
    ctx.player.hands[1] = thread
    local output = capture_output(function()
        handlers["burn"](ctx, "thread")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns"),
        "Cotton should burn; got: " .. output)
end)

---------------------------------------------------------------------------
-- 2. Low-flammability materials refuse to burn
---------------------------------------------------------------------------
suite("burn — low-flammability materials")

test("burn stone (flammability 0.0) says can't burn", function()
    local stone = {
        id = "stone",
        name = "a grey stone",
        keywords = {"stone"},
        material = "stone",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("stone", stone)
    ctx.player.hands[1] = stone
    local output = capture_output(function()
        handlers["burn"](ctx, "stone")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Stone should be unburnable; got: " .. output)
    h.assert_truthy(ctx.registry:get("stone") ~= nil, "Stone should remain in registry")
end)

test("burn iron (flammability 0.0) says can't burn", function()
    local key = {
        id = "iron-key",
        name = "an iron key",
        keywords = {"key", "iron key"},
        material = "iron",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("iron-key", key)
    ctx.player.hands[1] = key
    local output = capture_output(function()
        handlers["burn"](ctx, "key")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Iron should be unburnable; got: " .. output)
    h.assert_truthy(ctx.registry:get("iron-key") ~= nil, "Key should remain in registry")
end)

test("burn glass (flammability 0.0) says can't burn", function()
    local bottle = {
        id = "bottle",
        name = "a glass bottle",
        keywords = {"bottle"},
        material = "glass",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("bottle", bottle)
    ctx.player.hands[1] = bottle
    local output = capture_output(function()
        handlers["burn"](ctx, "bottle")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Glass should be unburnable; got: " .. output)
end)

test("burn ceramic (flammability 0.0) says can't burn", function()
    local pot = {
        id = "pot",
        name = "a ceramic pot",
        keywords = {"pot"},
        material = "ceramic",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("pot", pot)
    ctx.player.hands[1] = pot
    local output = capture_output(function()
        handlers["burn"](ctx, "pot")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Ceramic should be unburnable; got: " .. output)
end)

---------------------------------------------------------------------------
-- 3. Threshold boundary: leather at exactly 0.3
---------------------------------------------------------------------------
suite("burn — threshold boundary")

test("burn leather (flammability 0.3, at threshold) burns", function()
    local tome = {
        id = "tome",
        name = "a leather-bound tome",
        keywords = {"tome"},
        material = "leather",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("tome", tome)
    ctx.player.hands[1] = tome
    local output = capture_output(function()
        handlers["burn"](ctx, "tome")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns"),
        "Leather at threshold should burn; got: " .. output)
end)

test("burn bone (flammability 0.1, below threshold) says can't burn", function()
    local skull = {
        id = "skull",
        name = "a skull",
        keywords = {"skull"},
        material = "bone",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("skull", skull)
    ctx.player.hands[1] = skull
    local output = capture_output(function()
        handlers["burn"](ctx, "skull")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Bone below threshold should be unburnable; got: " .. output)
end)

---------------------------------------------------------------------------
-- 4. FSM burn transitions
---------------------------------------------------------------------------
suite("burn — FSM transitions")

test("burn object with burn FSM transition uses it", function()
    local rope = {
        id = "rope",
        name = "a hemp rope",
        keywords = {"rope"},
        material = "hemp",
        initial_state = "intact",
        _state = "intact",
        states = {
            intact = { description = "A sturdy hemp rope." },
            burning = { description = "The rope is burning." },
        },
        transitions = {
            { from = "intact", to = "burning", verb = "burn",
              message = "The hemp rope catches fire and begins to smolder." },
        },
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("rope", rope)
    ctx.player.hands[1] = rope
    local output = capture_output(function()
        handlers["burn"](ctx, "rope")
    end)
    h.assert_truthy(output:find("smolder") or output:find("catches fire"),
        "FSM burn transition should fire; got: " .. output)
    local updated = ctx.registry:get("rope")
    eq(updated._state, "burning", "Rope should transition to burning state")
end)

---------------------------------------------------------------------------
-- 5. No flame available
---------------------------------------------------------------------------
suite("burn — no flame")

test("burn without flame says no flame", function()
    local paper = {
        id = "paper",
        name = "a sheet of paper",
        keywords = {"paper"},
        material = "paper",
    }
    local ctx = make_ctx({ state = {} })
    ctx.registry:register("paper", paper)
    ctx.player.hands[1] = paper
    local output = capture_output(function()
        handlers["burn"](ctx, "paper")
    end)
    h.assert_truthy(output:find("no flame"),
        "Should say no flame available; got: " .. output)
    h.assert_truthy(ctx.registry:get("paper") ~= nil, "Paper should not be burned without flame")
end)

---------------------------------------------------------------------------
-- 6. Edge cases
---------------------------------------------------------------------------
suite("burn — edge cases")

test("burn with empty noun prints prompt", function()
    local ctx = make_ctx({ state = { has_flame = 3 } })
    local output = capture_output(function()
        handlers["burn"](ctx, "")
    end)
    h.assert_truthy(output:find("Burn what"),
        "Empty noun should prompt; got: " .. output)
end)

test("burn nonexistent object prints not found", function()
    local ctx = make_ctx({ state = { has_flame = 3 } })
    local output = capture_output(function()
        handlers["burn"](ctx, "unicorn")
    end)
    h.assert_truthy(output:find("see") or output:find("find") or output:find("don't"),
        "Missing object should print not-found; got: " .. output)
end)

test("burn object with no material says can't burn", function()
    local widget = {
        id = "widget",
        name = "a mysterious widget",
        keywords = {"widget"},
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("widget", widget)
    ctx.player.hands[1] = widget
    local output = capture_output(function()
        handlers["burn"](ctx, "widget")
    end)
    h.assert_truthy(output:find("can't burn"),
        "No-material object should be unburnable; got: " .. output)
end)

test("burn object in room (not in hand) works", function()
    local scroll = {
        id = "scroll",
        name = "a tattered scroll",
        keywords = {"scroll"},
        material = "paper",
    }
    local ctx = make_ctx({
        state = { has_flame = 3 },
        room_contents = { "scroll" },
    })
    ctx.registry:register("scroll", scroll)
    local output = capture_output(function()
        handlers["burn"](ctx, "scroll")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns"),
        "Room object should burn; got: " .. output)
    eq(ctx.registry:get("scroll"), nil, "Scroll should be removed from registry")
end)

test("burn mutation path takes precedence over generic destruction", function()
    local letter = {
        id = "letter",
        name = "a sealed letter",
        keywords = {"letter"},
        material = "paper",
        mutations = {
            burn = {
                becomes = "letter-ash",
                message = "The letter curls and blackens, its secrets lost forever.",
            },
        },
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("letter", letter)
    ctx.player.hands[1] = letter

    -- Provide minimal mutation context so perform_mutation can resolve
    ctx.object_sources = { ["letter-ash"] = "return { id='letter-ash', name='a pile of ash', keywords={'ash'} }" }
    ctx.templates = {}
    ctx.loader = { load_string = function(self, src) return load(src)() end }
    ctx.mutation = {
        mutate = function(reg, loader, old_id, source, templates)
            local new_obj = load(source)()
            new_obj.id = old_id
            reg:register(old_id, new_obj)
            return new_obj
        end,
    }

    local output = capture_output(function()
        handlers["burn"](ctx, "letter")
    end)
    h.assert_truthy(output:find("secrets lost") or output:find("catches fire") or output:find("burn"),
        "Mutation burn should use custom message; got: " .. output)
    local mutated = ctx.registry:get("letter")
    h.assert_truthy(mutated ~= nil, "Letter should still exist (mutated, not destroyed)")
end)

h.summary()
