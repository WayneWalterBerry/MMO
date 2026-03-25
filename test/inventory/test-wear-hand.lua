-- test/inventory/test-wear-hand.lua
-- Bug #180: Wearing item from hand doesn't free the hand slot.
--
-- Wayne's playtest transcript:
--   > inventory
--     Left hand: a brass spittoon
--     Right hand: a heavy sack of grain
--     Worn:
--       a brass spittoon (head)
--
-- The spittoon appears in BOTH left hand AND worn. Wearing should remove
-- the item from the hand slot so the hand is free for something else.
--
-- Tests cover: direct wear from hand, auto-pickup+wear from room, take
-- of already-worn item, and inventory display correctness.
--
-- TDD RED PHASE — these tests document the bug and MUST fail until fixed.
--
-- Usage: lua test/inventory/test-wear-hand.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")

local test   = h.test
local eq     = h.assert_eq
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
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler call failed: " .. tostring(err)) end
    return table.concat(captured, "\n")
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

local function make_apple()
    return {
        id = "apple",
        name = "a red apple",
        keywords = {"apple", "red apple"},
        portable = true, size = 1, weight = 0.3,
        on_feel = "Smooth and cool.",
        location = "test-room",
    }
end

local function make_ctx()
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A featureless room for testing.",
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
        last_object = nil,
        verbs = handlers,
    }
end

local function hand_id(hand)
    if type(hand) == "table" then return hand.id end
    return hand
end

---------------------------------------------------------------------------
-- Bug #180: Basic wear from hand — direct handler tests
---------------------------------------------------------------------------

h.suite("Bug #180 — wear from hand frees hand (both hands full)")

test("wearing spittoon from left hand removes it from left hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)

    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    eq(nil, ctx.player.hands[1],
        "Left hand should be empty after wearing spittoon")
end)

test("after wearing, right hand is unaffected", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)

    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    eq("grain-sack", hand_id(ctx.player.hands[2]),
        "Right hand should still hold the grain sack")
end)

test("spittoon appears ONLY in worn, not in hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)

    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    local found_in_worn = false
    for _, worn_id in ipairs(ctx.player.worn) do
        if worn_id == "brass-spittoon" then found_in_worn = true end
    end
    truthy(found_in_worn, "Spittoon should be in worn list")

    local found_in_hand = false
    for i = 1, 2 do
        if hand_id(ctx.player.hands[i]) == "brass-spittoon" then
            found_in_hand = true
        end
    end
    eq(false, found_in_hand,
        "Spittoon must NOT appear in any hand after wearing")
end)

test("inventory output shows spittoon in worn only, not in hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)

    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    local inv_output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)

    truthy(inv_output:find("Worn:"),
        "Inventory should have a Worn section")

    local count = 0
    for _ in inv_output:gmatch("brass spittoon") do count = count + 1 end

    eq(1, count,
        "Spittoon should appear exactly once in inventory (in Worn only), got " ..
        count .. " in output:\n" .. inv_output)
end)

test("player can pick up new item after wearing frees the hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    local apple = make_apple()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)
    ctx.registry:register("apple", apple)
    ctx.current_room.contents[1] = "apple"

    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack

    capture_output(function() handlers["wear"](ctx, "spittoon") end)
    capture_output(function() handlers["take"](ctx, "apple") end)

    eq("apple", hand_id(ctx.player.hands[1]),
        "Freed hand should now hold the apple")
end)

test("removing worn spittoon puts it back in hand if hand is free", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)

    ctx.player.worn = { "brass-spittoon" }
    spittoon.location = "player"

    capture_output(function() handlers["remove"](ctx, "spittoon") end)

    local in_hand = hand_id(ctx.player.hands[1]) == "brass-spittoon"
                 or hand_id(ctx.player.hands[2]) == "brass-spittoon"
    truthy(in_hand, "Removed spittoon should be placed in a free hand")

    local in_worn = false
    for _, id in ipairs(ctx.player.worn) do
        if id == "brass-spittoon" then in_worn = true end
    end
    eq(false, in_worn, "Spittoon should no longer be in worn list")
end)

---------------------------------------------------------------------------
-- Bug #180: "take" of already-worn item should be blocked
--
-- Possible reproduction path: player wears spittoon (hand freed), then
-- types "take spittoon" which picks up the WORN item back into a hand
-- without removing it from worn list → item in both hand AND worn.
---------------------------------------------------------------------------

h.suite("Bug #180 — take worn item should not duplicate")

test("take of already-worn spittoon should NOT put it in hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local sack = make_grain_sack()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("grain-sack", sack)

    -- Wear the spittoon first
    ctx.player.hands[1] = spittoon
    ctx.player.hands[2] = sack
    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    -- Now try to "take spittoon" — it's already worn, not in room
    capture_output(function() handlers["take"](ctx, "spittoon") end)

    -- Spittoon must NOT appear in hand (it's worn, not takeable)
    local in_hand = false
    for i = 1, 2 do
        if hand_id(ctx.player.hands[i]) == "brass-spittoon" then
            in_hand = true
        end
    end
    eq(false, in_hand,
        "Taking a worn item should not put it back in hand")
end)

test("take of worn item does not create duplicate in inventory", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)

    -- Wear the spittoon
    ctx.player.hands[1] = spittoon
    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    -- Attempt take
    capture_output(function() handlers["take"](ctx, "spittoon") end)

    -- Run inventory, count appearances
    local inv_output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)

    local count = 0
    for _ in inv_output:gmatch("brass spittoon") do count = count + 1 end

    -- Must appear at most once (in worn section)
    truthy(count <= 1,
        "Worn item must appear at most once in inventory after take attempt, " ..
        "got " .. count .. " in:\n" .. inv_output)
end)

---------------------------------------------------------------------------
-- Bug #180: Auto-pickup wear from room with both hands full
--
-- When the item is in the room (not in hand), and the player types
-- "wear spittoon", the handler auto-picks it up then wears it. If both
-- hands are full, this should either fail gracefully or swap correctly.
---------------------------------------------------------------------------

h.suite("Bug #180 — wear from room auto-pickup")

test("wear from room with one free hand: item ends in worn, hand freed", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    spittoon.location = "test-room"
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.current_room.contents[1] = "brass-spittoon"

    -- Only right hand occupied
    local sack = make_grain_sack()
    ctx.registry:register("grain-sack", sack)
    ctx.player.hands[2] = sack

    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    -- Should be worn
    local in_worn = false
    for _, id in ipairs(ctx.player.worn) do
        if id == "brass-spittoon" then in_worn = true end
    end
    truthy(in_worn, "Spittoon should be in worn list after auto-pickup wear")

    -- Should NOT be in hand (it went hand → worn)
    local in_hand = false
    for i = 1, 2 do
        if hand_id(ctx.player.hands[i]) == "brass-spittoon" then
            in_hand = true
        end
    end
    eq(false, in_hand,
        "Auto-picked spittoon must not remain in hand after wearing")
end)

local failed = h.summary()
if failed > 0 then os.exit(1) end
