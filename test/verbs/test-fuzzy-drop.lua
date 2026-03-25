-- test/verbs/test-fuzzy-drop.lua
-- Bug #181: "drop spitton" fails — fuzzy not applied to drop targets.
--
-- Two sub-bugs:
--   A. "spitton" (typo, edit-distance 1) not fuzzy-matched to "spittoon"
--      The drop handler uses matches_keyword() which is exact-only.
--      Fuzzy (Tier 5) is never consulted for drop targets.
--   B. Dropping a worn item — verify remove→drop flow works and that
--      dropping a worn item gives a helpful message.
--
-- TDD RED PHASE — bug-exposing tests MUST FAIL until the fix lands.
--
-- Usage: lua test/verbs/test-fuzzy-drop.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local fuzzy = require("engine.parser.fuzzy")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy
local nilval = h.assert_nil

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
        keywords = {"spittoon", "brass spittoon", "cuspidor", "spit bowl",
                    "helmet", "improvised helmet"},
        portable = true, size = 2, weight = 4,
        container = true, capacity = 2, contents = {},
        wear_slot = "head", is_helmet = true,
        wearable = true,
        wear = {
            slot = "head", layer = "outer",
            coverage = 0.7, fit = "makeshift",
            provides_armor = 2, wear_quality = "makeshift",
        },
        on_feel = "Cool, curved brass with a wide rim.",
        _state = "clean",
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
        location = "player",
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
        state = { hints_shown = {} },
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

local function array_contains(arr, val)
    for _, v in ipairs(arr or {}) do
        if v == val then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- 0. SANITY — Levenshtein distance for spittoon typos
---------------------------------------------------------------------------
h.suite("Bug #181 — Levenshtein distance: spittoon typos")

test("'spitton' → 'spittoon' is edit distance 1 (missing 'o')", function()
    eq(1, fuzzy.levenshtein("spitton", "spittoon"))
end)

test("'spitoon' → 'spittoon' is edit distance 1 (missing 't')", function()
    eq(1, fuzzy.levenshtein("spitoon", "spittoon"))
end)

test("'spittoon' → 'spittoon' is edit distance 0 (exact)", function()
    eq(0, fuzzy.levenshtein("spittoon", "spittoon"))
end)

test("'spittn' → 'spittoon' is edit distance 2 (missing 'oo')", function()
    eq(2, fuzzy.levenshtein("spittn", "spittoon"))
end)

---------------------------------------------------------------------------
-- 1. SANITY — "spittoon" is in the keyword vocabulary
---------------------------------------------------------------------------
h.suite("Bug #181 — spittoon keyword vocabulary")

test("spittoon object has 'spittoon' in keywords", function()
    local obj = make_spittoon()
    local found = false
    for _, kw in ipairs(obj.keywords) do
        if kw == "spittoon" then found = true break end
    end
    truthy(found, "'spittoon' must be in keywords array")
end)

test("max_typo_distance for 'spitton' (7 chars) allows distance 2", function()
    eq(2, fuzzy.max_typo_distance(7))
end)

test("max_typo_distance for 'spittoon' (8 chars) allows distance 2", function()
    eq(2, fuzzy.max_typo_distance(8))
end)

---------------------------------------------------------------------------
-- 2. SANITY — fuzzy.score_object handles spittoon typos
---------------------------------------------------------------------------
h.suite("Bug #181 — fuzzy.score_object: spittoon typos")

test("'spitton' scores > 0 against spittoon (typo match)", function()
    local obj = make_spittoon()
    local parsed = fuzzy.parse_noun_phrase("spitton")
    local score, reason = fuzzy.score_object(obj, parsed)
    truthy(score > 0, "'spitton' should typo-match 'spittoon'")
    eq("typo", reason)
end)

test("'spitoon' scores > 0 against spittoon (typo match)", function()
    local obj = make_spittoon()
    local parsed = fuzzy.parse_noun_phrase("spitoon")
    local score, reason = fuzzy.score_object(obj, parsed)
    truthy(score > 0, "'spitoon' should typo-match 'spittoon'")
    eq("typo", reason)
end)

---------------------------------------------------------------------------
-- 3. SANITY — fuzzy.resolve finds spittoon via typo in room
---------------------------------------------------------------------------
h.suite("Bug #181 — fuzzy.resolve: spittoon typos in room")

local function make_fuzzy_ctx(objects, room_contents, hands, worn)
    local obj_map = {}
    for _, obj in ipairs(objects) do
        obj_map[obj.id] = obj
    end
    local reg = {
        _objects = obj_map,
        get = function(self, id) return self._objects[id] end,
    }
    return {
        current_room = { contents = room_contents or {} },
        player = { hands = hands or {nil, nil}, worn = worn or {} },
        registry = reg,
        current_verb = "examine",
    }
end

test("fuzzy.resolve: 'spitton' finds spittoon in room", function()
    local spittoon = make_spittoon()
    local ctx = make_fuzzy_ctx({spittoon}, {"brass-spittoon"})
    local obj = fuzzy.resolve(ctx, "spitton")
    truthy(obj, "'spitton' should fuzzy-resolve to spittoon in room")
    eq("brass-spittoon", obj.id)
end)

test("fuzzy.resolve: 'spitoon' finds spittoon in room", function()
    local spittoon = make_spittoon()
    local ctx = make_fuzzy_ctx({spittoon}, {"brass-spittoon"})
    local obj = fuzzy.resolve(ctx, "spitoon")
    truthy(obj, "'spitoon' should fuzzy-resolve to spittoon in room")
    eq("brass-spittoon", obj.id)
end)

test("fuzzy.resolve: 'spitton' finds spittoon in hand", function()
    local spittoon = make_spittoon()
    local ctx = make_fuzzy_ctx({spittoon}, {}, {spittoon, nil})
    local obj = fuzzy.resolve(ctx, "spitton")
    truthy(obj, "'spitton' should fuzzy-resolve to spittoon in hand")
    eq("brass-spittoon", obj.id)
end)

---------------------------------------------------------------------------
-- 4. BUG A — drop handler must resolve typos (MUST FAIL until fixed)
---------------------------------------------------------------------------
h.suite("Bug #181A — drop + fuzzy typo resolution [RED]")

test("[RED] 'drop spitton' drops spittoon from hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.hands[1] = spittoon

    local output = capture_output(function()
        handlers["drop"](ctx, "spitton")
    end)

    -- After drop, hand should be empty
    eq(nil, ctx.player.hands[1],
        "Spittoon should be dropped from hand via fuzzy 'spitton'")
    -- Spittoon should be in room contents
    truthy(array_contains(ctx.current_room.contents, "brass-spittoon"),
        "Spittoon should land in room after drop")
end)

test("[RED] 'drop spitoon' drops spittoon from hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.hands[1] = spittoon

    local output = capture_output(function()
        handlers["drop"](ctx, "spitoon")
    end)

    eq(nil, ctx.player.hands[1],
        "Spittoon should be dropped from hand via fuzzy 'spitoon'")
    truthy(array_contains(ctx.current_room.contents, "brass-spittoon"),
        "Spittoon should land in room after drop")
end)

test("[RED] 'drop spitton' does not say 'You aren't holding that'", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.hands[1] = spittoon

    local output = capture_output(function()
        handlers["drop"](ctx, "spitton")
    end)

    -- Should NOT get the "not holding" error — fuzzy should find it
    local has_error = output:lower():find("aren't holding")
    eq(nil, has_error,
        "Should not say 'aren't holding' when spittoon IS in hand (typo)")
end)

test("[RED] 'drop spitton' with spittoon in right hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    local apple = make_apple()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.registry:register("apple", apple)
    ctx.player.hands[1] = apple
    ctx.player.hands[2] = spittoon

    local output = capture_output(function()
        handlers["drop"](ctx, "spitton")
    end)

    -- Right hand should be cleared
    eq(nil, ctx.player.hands[2],
        "Spittoon should be dropped from right hand via fuzzy 'spitton'")
    -- Left hand untouched
    eq("apple", hand_id(ctx.player.hands[1]),
        "Apple in left hand should be untouched")
end)

---------------------------------------------------------------------------
-- 5. BUG A — fuzzy typo should work for other verbs too
---------------------------------------------------------------------------
h.suite("Bug #181A — fuzzy typo for other verbs (get/examine) [RED]")

test("[RED] 'get spitton' resolves spittoon from room", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    spittoon.location = "test-room"
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.current_room.contents = {"brass-spittoon"}

    local output = capture_output(function()
        handlers["get"](ctx, "spitton")
    end)

    -- Player should now hold the spittoon
    local in_hand = hand_id(ctx.player.hands[1]) == "brass-spittoon"
                 or hand_id(ctx.player.hands[2]) == "brass-spittoon"
    truthy(in_hand,
        "'get spitton' should fuzzy-resolve and pick up the spittoon")
end)

test("[RED] 'examine spitton' describes the spittoon", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    spittoon.description = "A battered brass spittoon, dented but serviceable."
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.current_room.contents = {"brass-spittoon"}

    local output = capture_output(function()
        handlers["examine"](ctx, "spitton")
    end)

    -- Output should contain the spittoon description, not an error
    local found_desc = output:find("brass spittoon") or output:find("battered")
    truthy(found_desc,
        "'examine spitton' should describe the spittoon, not error")
end)

test("[RED] 'look at spitton' describes the spittoon", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    spittoon.description = "A battered brass spittoon, dented but serviceable."
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.current_room.contents = {"brass-spittoon"}

    local output = capture_output(function()
        handlers["look"](ctx, "spitton")
    end)

    local found_desc = output:find("brass spittoon") or output:find("battered")
    truthy(found_desc,
        "'look at spitton' should describe the spittoon via fuzzy")
end)

---------------------------------------------------------------------------
-- 6. BUG B — drop on worn item gives helpful message
---------------------------------------------------------------------------
h.suite("Bug #181B — drop worn item messaging")

test("'drop spittoon' on worn item says 'remove it first'", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    spittoon.location = "player"
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.worn = {"brass-spittoon"}

    local output = capture_output(function()
        handlers["drop"](ctx, "spittoon")
    end)

    local has_wearing_msg = output:lower():find("wearing")
                         or output:lower():find("remove")
    truthy(has_wearing_msg,
        "Should tell player to remove worn item before dropping")
end)

test("[RED] 'drop spitton' on worn item says 'remove it first' (fuzzy)", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    spittoon.location = "player"
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.worn = {"brass-spittoon"}

    local output = capture_output(function()
        handlers["drop"](ctx, "spitton")
    end)

    -- Even with typo, should recognize worn item and give helpful message
    local has_wearing_msg = output:lower():find("wearing")
                         or output:lower():find("remove")
    truthy(has_wearing_msg,
        "Should tell player to remove worn item (fuzzy 'spitton'→'spittoon')")
end)

---------------------------------------------------------------------------
-- 7. Drop exact-match sanity (should PASS — proves handler works)
---------------------------------------------------------------------------
h.suite("Bug #181 — drop exact match sanity")

test("'drop spittoon' works when spittoon is in hand", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.hands[1] = spittoon

    local output = capture_output(function()
        handlers["drop"](ctx, "spittoon")
    end)

    eq(nil, ctx.player.hands[1],
        "Hand should be empty after dropping spittoon (exact match)")
    truthy(array_contains(ctx.current_room.contents, "brass-spittoon"),
        "Spittoon should be in room after drop")
end)

test("'drop brass spittoon' works (multi-word keyword)", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.hands[1] = spittoon

    local output = capture_output(function()
        handlers["drop"](ctx, "brass spittoon")
    end)

    eq(nil, ctx.player.hands[1],
        "Hand should be empty after dropping 'brass spittoon'")
end)

test("remove then drop flow works for worn spittoon", function()
    local ctx = make_ctx()
    local spittoon = make_spittoon()
    ctx.registry:register("brass-spittoon", spittoon)
    ctx.player.worn = {"brass-spittoon"}

    -- Step 1: remove the spittoon (should move to hand)
    capture_output(function() handlers["remove"](ctx, "spittoon") end)

    local in_hand = hand_id(ctx.player.hands[1]) == "brass-spittoon"
                 or hand_id(ctx.player.hands[2]) == "brass-spittoon"
    truthy(in_hand, "Spittoon should be in hand after remove")
    eq(false, array_contains(ctx.player.worn, "brass-spittoon"),
        "Spittoon should no longer be in worn list after remove")

    -- Step 2: drop the spittoon
    capture_output(function() handlers["drop"](ctx, "spittoon") end)

    local still_in_hand = hand_id(ctx.player.hands[1]) == "brass-spittoon"
                       or hand_id(ctx.player.hands[2]) == "brass-spittoon"
    eq(false, still_in_hand, "Spittoon should not be in hand after drop")
    truthy(array_contains(ctx.current_room.contents, "brass-spittoon"),
        "Spittoon should be in room after remove→drop")
end)

---------------------------------------------------------------------------
-- Report
---------------------------------------------------------------------------
local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
