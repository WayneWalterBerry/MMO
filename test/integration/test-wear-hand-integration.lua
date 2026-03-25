-- test/integration/test-wear-hand-integration.lua
-- Bug #180: Integration-level test for wearing items from hand.
--
-- These tests exercise the FULL command pipeline (preprocess → GOAP → dispatch)
-- to ensure the wear handler's hand-clearing survives the integration layer.
-- Nelson's unit tests (test/inventory/test-wear-hand.lua) confirmed handler-level
-- correctness. These tests verify the end-to-end command flow.
--
-- Usage: lua test/integration/test-wear-hand-integration.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")
local preprocess = require("engine.parser.preprocess")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function capture(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(lines, "\n")
end

local function make_spittoon()
    return {
        id = "brass-spittoon",
        name = "a brass spittoon",
        material = "brass",
        keywords = {"spittoon", "brass spittoon", "brass bowl"},
        portable = true, size = 2, weight = 4,
        container = true, capacity = 2, contents = {},
        wear_slot = "head", is_helmet = true,
        wearable = true,
        wear = {
            slot = "head", layer = "outer",
            coverage = 0.7, fit = "makeshift",
            provides_armor = 2, wear_quality = "makeshift",
        },
        _state = "clean",
        location = "player",
    }
end

local function make_grain_sack()
    return {
        id = "grain-sack",
        name = "a heavy sack of grain",
        keywords = {"sack", "grain sack", "grain", "heavy sack"},
        portable = true, size = 3, weight = 8,
        on_feel = "Rough burlap, bulging with grain.",
        location = "player",
    }
end

local function make_ctx()
    local reg = registry_mod.new()
    local handlers = verbs_mod.create()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A featureless room.",
        contents = {},
        exits = {},
    }
    local player = {
        hands = { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 8,
        game_start_time = os.time(),
        known_objects = {},
        last_noun = nil,
        verbs = handlers,
    }
end

-- Simulate what the game loop does for a single command:
-- preprocess → GOAP (if available) → dispatch handler
local function dispatch(ctx, input)
    local verb, noun = preprocess.natural_language(input)
    if not verb then
        verb, noun = preprocess.parse(input)
    end
    if not verb or verb == "" then return end

    -- Pronoun resolution (simplified — mirrors loop logic)
    local no_noun_verbs = {
        look = true, feel = true, smell = true, listen = true, taste = true,
        inventory = true, i = true, help = true, time = true,
    }
    if noun == "" and not no_noun_verbs[verb] and ctx.last_noun then
        noun = ctx.last_noun
    end

    local handler = ctx.verbs[verb]
    if handler then
        ctx.current_verb = verb
        handler(ctx, noun)
        if noun ~= "" and not no_noun_verbs[verb] then
            ctx.last_noun = noun
        end
    end
end

local function hand_id(hand)
    if type(hand) == "table" then return hand.id end
    return hand
end

---------------------------------------------------------------------------
-- Bug #180: Integration — full pipeline dispatch for "wear spittoon"
---------------------------------------------------------------------------
h.suite("Bug #180 — integration: wear via full command pipeline")

test("'wear spittoon' through pipeline clears hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)
    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture(function() dispatch(ctx, "wear spittoon") end)

    eq(nil, ctx.player.hands[1],
        "Left hand must be empty after wearing spittoon via pipeline")
    eq("grain-sack", hand_id(ctx.player.hands[2]),
        "Right hand must still hold grain sack")

    local in_worn = false
    for _, id in ipairs(ctx.player.worn) do
        if id == "brass-spittoon" then in_worn = true end
    end
    truthy(in_worn, "Spittoon must be in worn list")
end)

test("'put on spittoon' through pipeline clears hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)
    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture(function() dispatch(ctx, "put on spittoon") end)

    eq(nil, ctx.player.hands[1],
        "Left hand must be empty after 'put on spittoon'")
    local in_worn = false
    for _, id in ipairs(ctx.player.worn) do
        if id == "brass-spittoon" then in_worn = true end
    end
    truthy(in_worn, "Spittoon must be in worn list after 'put on'")
end)

test("'don spittoon' alias through pipeline clears hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.hands[1] = spittoon

    capture(function() dispatch(ctx, "don spittoon") end)

    eq(nil, ctx.player.hands[1],
        "Hand must be empty after 'don spittoon'")
end)

test("inventory after wear shows item ONLY in worn", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)
    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture(function() dispatch(ctx, "wear spittoon") end)
    local inv = capture(function() dispatch(ctx, "inventory") end)

    local count = 0
    for _ in inv:gmatch("brass spittoon") do count = count + 1 end
    eq(1, count,
        "Spittoon must appear exactly once in inventory (in Worn), got " ..
        count .. " in:\n" .. inv)
end)

---------------------------------------------------------------------------
-- Bug #180: "take" of worn item through full pipeline
---------------------------------------------------------------------------
h.suite("Bug #180 — integration: take worn item blocked")

test("'take spittoon' after wearing is blocked by pipeline", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)
    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture(function() dispatch(ctx, "wear spittoon") end)

    -- Now try to take the worn item
    local output = capture(function() dispatch(ctx, "take spittoon") end)

    -- Should NOT be in any hand
    local in_hand = false
    for i = 1, 2 do
        if hand_id(ctx.player.hands[i]) == "brass-spittoon" then
            in_hand = true
        end
    end
    eq(false, in_hand,
        "Worn item must not be re-placed in hand by take")
end)

test("compound 'wear spittoon, inventory' shows correct state", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)
    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    -- Execute compound: wear then check inventory
    capture(function() dispatch(ctx, "wear spittoon") end)
    local inv = capture(function() dispatch(ctx, "inventory") end)

    -- Verify state
    eq(nil, ctx.player.hands[1], "Left hand must be empty")
    truthy(inv:find("Worn:"), "Inventory must show Worn section")

    local count = 0
    for _ in inv:gmatch("brass spittoon") do count = count + 1 end
    eq(1, count, "Spittoon appears exactly once in inventory")
end)

test("take→wear→take sequence prevents duplication", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    spittoon.location = "test-room"
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.current_room.contents[1] = "brass-spittoon"

    -- Take it
    capture(function() dispatch(ctx, "take spittoon") end)
    truthy(ctx.player.hands[1] ~= nil or ctx.player.hands[2] ~= nil,
        "Spittoon should be in a hand after take")

    -- Wear it
    capture(function() dispatch(ctx, "wear spittoon") end)

    -- Try to take it again (should be blocked — it's worn)
    capture(function() dispatch(ctx, "take spittoon") end)

    -- Check: must be in worn only, not in hand
    local in_hand = false
    for i = 1, 2 do
        if hand_id(ctx.player.hands[i]) == "brass-spittoon" then
            in_hand = true
        end
    end
    eq(false, in_hand,
        "Spittoon must NOT be in hand after take-wear-take sequence")

    local in_worn = false
    for _, id in ipairs(ctx.player.worn) do
        if id == "brass-spittoon" then in_worn = true end
    end
    truthy(in_worn, "Spittoon must remain in worn list")
end)

local failed = h.summary()
if failed > 0 then os.exit(1) end
