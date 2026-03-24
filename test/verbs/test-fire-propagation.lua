-- test/verbs/test-fire-propagation.lua
-- Tests for #121: Fire propagation system.
-- Covers: proximity-based spread, material resistance, max ignitions per tick,
--         deterministic RNG for test control, generic destruction countdown,
--         FSM burn transitions, no-spread when no burning sources.
--
-- Usage: lua test/verbs/test-fire-propagation.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local registry_mod = require("engine.registry")
local fire_prop = require("engine.fire_propagation")

local test = h.test
local suite = h.suite
local eq = h.assert_eq

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
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
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
    }
    -- Deterministic RNG for tests: always returns opts.roll_value (default 0.0 = always spread)
    ctx.fire_rng = function()
        return opts.roll_value or 0.0
    end
    return ctx
end

local function capture_messages(ctx)
    return fire_prop.tick(ctx)
end

---------------------------------------------------------------------------
-- 1. is_burning detection
---------------------------------------------------------------------------
suite("fire propagation — is_burning detection")

test("object with is_burning=true is detected as burning", function()
    local obj = { id = "rag", is_burning = true }
    eq(fire_prop.is_burning(obj), true)
end)

test("FSM object in 'burning' state is detected as burning", function()
    local obj = {
        id = "paper",
        _state = "burning",
        states = { burning = { description = "On fire!" } },
    }
    eq(fire_prop.is_burning(obj), true)
end)

test("FSM object in 'lit' state is NOT burning (lit ≠ burning)", function()
    local obj = {
        id = "candle",
        _state = "lit",
        states = { lit = { casts_light = true } },
    }
    eq(fire_prop.is_burning(obj), false)
end)

test("FSM object with state.is_burning=true is detected", function()
    local obj = {
        id = "curtain",
        _state = "aflame",
        states = { aflame = { is_burning = true } },
    }
    eq(fire_prop.is_burning(obj), true)
end)

test("nil object returns false", function()
    eq(fire_prop.is_burning(nil), false)
end)

---------------------------------------------------------------------------
-- 2. Same-surface propagation (highest chance)
---------------------------------------------------------------------------
suite("fire propagation — same surface spread")

test("burning paper on table surface spreads to cotton on same surface", function()
    local paper = {
        id = "paper", name = "a sheet of paper",
        material = "paper",
        _state = "burning",
        states = { burning = { is_burning = true } },
    }
    local thread = {
        id = "thread", name = "a cotton thread",
        material = "cotton",
        keywords = {"thread"},
    }
    local table_obj = {
        id = "table", name = "a wooden table",
        surfaces = {
            top = { contents = { "paper", "thread" } },
        },
    }
    local ctx = make_ctx({ room_contents = { "table" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("thread", thread)
    ctx.registry:register("table", table_obj)

    local msgs = capture_messages(ctx)
    h.assert_truthy(#msgs > 0, "Fire should spread; got 0 messages")
    h.assert_truthy(
        thread.is_burning or thread._state == "burning",
        "Thread should be ignited"
    )
end)

test("same-surface spread uses SAME_SURFACE proximity factor", function()
    -- With roll_value just below SAME_SURFACE threshold, fire spreads
    -- paper flammability=0.8, cotton flammability=0.7
    -- chance = 0.8 (prox) × 0.7 (target) × 0.8 (source) = 0.448
    local paper = {
        id = "paper", material = "paper",
        _state = "burning",
        states = { burning = { is_burning = true } },
    }
    local thread = {
        id = "thread", material = "cotton",
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "paper", "thread" } } },
    }
    -- Roll 0.44 < 0.448 → spreads
    local ctx = make_ctx({ room_contents = { "shelf" }, roll_value = 0.44 })
    ctx.registry:register("paper", paper)
    ctx.registry:register("thread", thread)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    h.assert_truthy(#msgs > 0, "Fire should spread at roll 0.44")
end)

test("same-surface spread fails when roll exceeds chance", function()
    local paper = {
        id = "paper", material = "paper",
        _state = "burning",
        states = { burning = { is_burning = true } },
    }
    local thread = {
        id = "thread", material = "cotton",
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "paper", "thread" } } },
    }
    -- chance = 0.8 × 0.7 × 0.8 = 0.448; roll 0.5 > 0.448 → no spread
    local ctx = make_ctx({ room_contents = { "shelf" }, roll_value = 0.5 })
    ctx.registry:register("paper", paper)
    ctx.registry:register("thread", thread)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Fire should NOT spread at roll 0.5")
    eq(thread.is_burning, nil, "Thread should not ignite")
end)

---------------------------------------------------------------------------
-- 3. Same-parent propagation (medium chance)
---------------------------------------------------------------------------
suite("fire propagation — same parent, different surface")

test("burning item on top spreads to item underneath same furniture", function()
    local paper = {
        id = "paper", material = "paper",
        _state = "burning",
        states = { burning = { is_burning = true } },
    }
    local rag = {
        id = "rag", material = "fabric",
    }
    local dresser = {
        id = "dresser",
        surfaces = {
            top = { contents = { "paper" } },
            underneath = { contents = { "rag" } },
        },
    }
    local ctx = make_ctx({ room_contents = { "dresser" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("rag", rag)
    ctx.registry:register("dresser", dresser)

    local msgs = capture_messages(ctx)
    h.assert_truthy(#msgs > 0, "Fire should spread to item on different surface of same parent")
end)

---------------------------------------------------------------------------
-- 4. Same-room propagation (low chance)
---------------------------------------------------------------------------
suite("fire propagation — room-level spread")

test("burning item loose in room can spread to another loose item", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    local rag = {
        id = "rag", material = "fabric",
    }
    -- chance = 0.2 (room prox) × 0.6 (fabric flam) × 0.8 (paper intensity) = 0.096
    -- roll 0.09 < 0.096 → spreads
    local ctx = make_ctx({ room_contents = { "paper", "rag" }, roll_value = 0.09 })
    ctx.registry:register("paper", paper)
    ctx.registry:register("rag", rag)

    local msgs = capture_messages(ctx)
    h.assert_truthy(#msgs > 0, "Fire should spread across room at low roll")
end)

test("room-level spread fails at higher roll", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    local rag = {
        id = "rag", material = "fabric",
    }
    -- chance = 0.096; roll 0.1 > 0.096 → no spread
    local ctx = make_ctx({ room_contents = { "paper", "rag" }, roll_value = 0.1 })
    ctx.registry:register("paper", paper)
    ctx.registry:register("rag", rag)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Fire should NOT spread at roll 0.1")
end)

---------------------------------------------------------------------------
-- 5. Material resistance
---------------------------------------------------------------------------
suite("fire propagation — material resistance")

test("stone objects never catch fire (flammability 0.0)", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    local stone = {
        id = "stone", material = "stone",
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "paper", "stone" } } },
    }
    local ctx = make_ctx({ room_contents = { "shelf" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("stone", stone)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Stone should never ignite")
    eq(stone.is_burning, nil, "Stone should not be burning")
end)

test("iron objects never catch fire (flammability 0.0)", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    local key = {
        id = "key", material = "iron",
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "paper", "key" } } },
    }
    local ctx = make_ctx({ room_contents = { "shelf" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("key", key)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Iron should never ignite")
end)

test("bone objects below threshold don't catch fire (flammability 0.1)", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    local bone = {
        id = "bone", material = "bone",
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "paper", "bone" } } },
    }
    local ctx = make_ctx({ room_contents = { "shelf" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("bone", bone)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Bone should not ignite (below threshold)")
end)

---------------------------------------------------------------------------
-- 6. Max ignitions per tick
---------------------------------------------------------------------------
suite("fire propagation — max ignitions per tick")

test("only MAX_IGNITIONS_PER_TICK objects ignite per tick", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    -- Three flammable targets, but max is 2
    local rag1 = { id = "rag1", material = "fabric" }
    local rag2 = { id = "rag2", material = "fabric" }
    local rag3 = { id = "rag3", material = "fabric" }
    local shelf = {
        id = "shelf",
        surfaces = {
            top = { contents = { "paper", "rag1", "rag2", "rag3" } },
        },
    }
    local ctx = make_ctx({ room_contents = { "shelf" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("rag1", rag1)
    ctx.registry:register("rag2", rag2)
    ctx.registry:register("rag3", rag3)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    -- At most 2 ignitions
    local ignited = 0
    if rag1.is_burning then ignited = ignited + 1 end
    if rag2.is_burning then ignited = ignited + 1 end
    if rag3.is_burning then ignited = ignited + 1 end
    h.assert_truthy(ignited <= fire_prop.MAX_IGNITIONS_PER_TICK,
        "At most " .. fire_prop.MAX_IGNITIONS_PER_TICK .. " should ignite; got " .. ignited)
    h.assert_truthy(ignited > 0, "At least one should ignite")
end)

---------------------------------------------------------------------------
-- 7. No burning sources → no propagation
---------------------------------------------------------------------------
suite("fire propagation — no burning sources")

test("tick with no burning objects produces no messages", function()
    local rag = { id = "rag", material = "fabric" }
    local ctx = make_ctx({ room_contents = { "rag" } })
    ctx.registry:register("rag", rag)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "No burning objects means no propagation")
end)

test("tick with empty room produces no messages", function()
    local ctx = make_ctx()
    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Empty room means no propagation")
end)

---------------------------------------------------------------------------
-- 8. Already-burning objects don't re-ignite
---------------------------------------------------------------------------
suite("fire propagation — already burning")

test("already-burning target is not ignited again", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    local rag = {
        id = "rag", material = "fabric",
        is_burning = true,
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "paper", "rag" } } },
    }
    local ctx = make_ctx({ room_contents = { "shelf" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("rag", rag)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Already-burning rag should not generate ignition message")
end)

---------------------------------------------------------------------------
-- 9. Terminal-state objects don't catch fire
---------------------------------------------------------------------------
suite("fire propagation — terminal state immunity")

test("burnt-out object in terminal state cannot re-ignite", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    local ash = {
        id = "ash", material = "wood",
        _state = "ash",
        states = { ash = { terminal = true } },
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "paper", "ash" } } },
    }
    local ctx = make_ctx({ room_contents = { "shelf" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("ash", ash)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Terminal-state objects should not re-ignite")
end)

---------------------------------------------------------------------------
-- 10. Generic burn countdown
---------------------------------------------------------------------------
suite("fire propagation — generic burn countdown")

test("generic burning object is removed after countdown ticks", function()
    local rag = {
        id = "rag", name = "a dirty rag", material = "fabric",
        is_burning = true,
        _burn_ticks_remaining = 1,
    }
    local ctx = make_ctx({ room_contents = { "rag" } })
    ctx.registry:register("rag", rag)

    local msgs = fire_prop.tick(ctx)
    h.assert_truthy(ctx.registry:get("rag") == nil,
        "Rag should be removed from registry after burn countdown")
    h.assert_truthy(#msgs > 0, "Should produce ash message")
    h.assert_truthy(msgs[1]:find("ash") or msgs[1]:find("crumbles"),
        "Should mention ash; got: " .. msgs[1])
end)

---------------------------------------------------------------------------
-- 11. FSM burn transition path
---------------------------------------------------------------------------
suite("fire propagation — FSM burn transitions")

test("flammable FSM object transitions to burning state via propagation", function()
    local source = {
        id = "torch", material = "wood",
        _state = "burning",
        states = { burning = { is_burning = true } },
    }
    local curtain = {
        id = "curtain", material = "fabric",
        _state = "intact",
        states = {
            intact = {},
            burning = { is_burning = true },
        },
        transitions = {
            { from = "intact", to = "burning", verb = "burn",
              message = "The curtain catches fire!" },
        },
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "torch", "curtain" } } },
    }
    local ctx = make_ctx({ room_contents = { "shelf" } })
    ctx.registry:register("torch", source)
    ctx.registry:register("curtain", curtain)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    h.assert_truthy(#msgs > 0, "Curtain should catch fire")
    eq(curtain._state, "burning", "Curtain should transition to burning state")
end)

---------------------------------------------------------------------------
-- 12. Player hand propagation
---------------------------------------------------------------------------
suite("fire propagation — player hand items")

test("burning item in one hand can spread to item in other hand", function()
    local torch = {
        id = "torch", material = "wood",
        is_burning = true,
    }
    local scroll = {
        id = "scroll", material = "paper",
    }
    local ctx = make_ctx({ hands = { "torch", "scroll" } })
    ctx.registry:register("torch", torch)
    ctx.registry:register("scroll", scroll)

    local msgs = capture_messages(ctx)
    h.assert_truthy(#msgs > 0, "Fire should spread between hands")
    h.assert_truthy(scroll.is_burning, "Scroll should catch fire from torch")
end)

---------------------------------------------------------------------------
-- 13. No-material objects are immune
---------------------------------------------------------------------------
suite("fire propagation — objects without material")

test("object with no material property doesn't catch fire", function()
    local paper = {
        id = "paper", material = "paper",
        is_burning = true,
    }
    local mystery = {
        id = "mystery", name = "a mysterious orb",
    }
    local shelf = {
        id = "shelf",
        surfaces = { top = { contents = { "paper", "mystery" } } },
    }
    local ctx = make_ctx({ room_contents = { "shelf" } })
    ctx.registry:register("paper", paper)
    ctx.registry:register("mystery", mystery)
    ctx.registry:register("shelf", shelf)

    local msgs = capture_messages(ctx)
    eq(#msgs, 0, "Object without material should not catch fire")
end)

---------------------------------------------------------------------------
-- Done
---------------------------------------------------------------------------
print("\nExit code: " .. h.summary())
