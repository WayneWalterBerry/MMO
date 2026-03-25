-- test/parser/test-disambiguation.lua
-- TDD FAILING tests for bug #182 — sack disambiguation cluster.
--
-- Bug A: "get burlap sack" picks up the wrong sack (adjective ignored)
-- Bug B: "dump grain" should work as empty/pour action on containers
-- Bug C: No disambiguation prompt when multiple "sack" objects exist
--
-- These tests MUST FAIL against the current engine — TDD red phase.

package.path = "src/?.lua;src/?/init.lua;test/parser/?.lua;" .. package.path

local h = require("test-helpers")
local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy
local assert_nil = h.assert_nil

local registry_mod = require("engine.registry")
local fuzzy = require("engine.parser.fuzzy")
local verbs_mod = require("engine.verbs")
local helpers = require("engine.verbs.helpers")

---------------------------------------------------------------------------
-- Test fixtures: faithful to actual sack.lua and grain-sack.lua
---------------------------------------------------------------------------
local function make_burlap_sack()
    return {
        id = "sack",
        name = "a burlap sack",
        keywords = {"sack", "bag", "burlap sack", "burlap", "pouch"},
        material = "fabric",
        size = 1,
        weight = 0.3,
        portable = true,
        container = true,
        container_preposition = "in",
        capacity = 8,
        contents = {"needle", "thread"},
        categories = {"fabric", "container", "wearable"},
    }
end

local function make_grain_sack()
    return {
        id = "grain-sack",
        name = "a heavy sack of grain",
        keywords = {"sack", "grain sack", "grain", "burlap sack", "bag", "feed sack", "heavy sack"},
        material = "burlap",
        size = 3,
        weight = 15,
        portable = true,
        container = true,
        _state = "tied",
        categories = {"container", "fabric"},
        surfaces = {
            inside = {
                capacity = 2, max_item_size = 1,
                contents = {"iron-key-1"},
                accessible = false,
            },
        },
    }
end

-- Build a test context with both sacks in the room.
-- grain-sack listed FIRST in room.contents to reproduce the bug
-- (find_visible returns first keyword match in iteration order).
local function make_ctx()
    local sack = make_burlap_sack()
    local grain = make_grain_sack()
    local reg = registry_mod.new()
    reg:register("sack", sack)
    reg:register("grain-sack", grain)

    local room = {
        id = "test-room",
        name = "Storage Room",
        description = "A dusty storage room.",
        contents = {"grain-sack", "sack"},
        exits = {},
    }

    return {
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        registry = reg,
        current_verb = "take",
        known_objects = {},
        last_noun = nil,
        last_object = nil,
    }
end

-- Capture printed output from verb handlers
local function capture_print(fn)
    local lines = {}
    local old = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    fn()
    _G.print = old
    return table.concat(lines, "\n")
end

-- ===========================================================================
-- BUG A: "get burlap sack" resolves to wrong sack (#182)
-- The adjective "burlap" should disambiguate to the burlap sack (id="sack"),
-- not the grain sack — even though both have "burlap sack" as a keyword.
-- ===========================================================================
h.suite("BUG A: Adjective-qualified sack resolution (#182)")

test("'burlap sack' via find_visible resolves to the burlap sack, not grain sack", function()
    local ctx = make_ctx()
    -- grain-sack is first in room.contents AND has "burlap sack" keyword.
    -- find_visible currently returns first keyword match → grain-sack (WRONG).
    local obj = helpers.find_visible(ctx, "burlap sack")
    truthy(obj, "'burlap sack' should resolve to an object")
    eq("sack", obj.id,
        "'burlap sack' should resolve to the burlap sack (id='sack'), not grain-sack")
end)

test("'sack of grain' resolves to the grain sack", function()
    local ctx = make_ctx()
    local obj = helpers.find_visible(ctx, "sack of grain")
    truthy(obj, "'sack of grain' should resolve to an object")
    eq("grain-sack", obj.id,
        "'sack of grain' should resolve to grain-sack")
end)

test("'grain sack' resolves to the grain sack", function()
    local ctx = make_ctx()
    local obj = helpers.find_visible(ctx, "grain sack")
    truthy(obj, "'grain sack' should resolve to an object")
    eq("grain-sack", obj.id,
        "'grain sack' should resolve to grain-sack")
end)

test("adjective-qualified noun always prefers the object whose name contains the adjective", function()
    -- "burlap sack": name "a burlap sack" vs name "a heavy sack of grain"
    -- The burlap sack's NAME contains "burlap" — it should win.
    local ctx = make_ctx()
    local obj = helpers.find_visible(ctx, "burlap sack")
    truthy(obj, "should resolve")
    truthy(obj.id ~= "grain-sack",
        "adjective 'burlap' must not resolve to grain-sack whose name is 'a heavy sack of grain'")
    eq("sack", obj.id, "should resolve to the burlap sack")
end)

test("'heavy sack' resolves to grain sack via property or keyword", function()
    local ctx = make_ctx()
    -- "heavy sack" is an exact keyword in grain-sack but NOT in burlap sack.
    -- This should resolve unambiguously to the grain sack.
    local obj = helpers.find_visible(ctx, "heavy sack")
    truthy(obj, "'heavy sack' should resolve to an object")
    eq("grain-sack", obj.id, "'heavy sack' should resolve to grain-sack")
end)

-- ===========================================================================
-- BUG C: No disambiguation prompt when multiple "sack" objects exist (#182)
-- When both sacks share the keyword "sack", the parser should ask the player
-- which sack they mean instead of silently picking the first match.
-- ===========================================================================
h.suite("BUG C: Disambiguation when multiple sacks share a keyword (#182)")

test("'sack' with two sacks triggers disambiguation, not silent pick", function()
    local ctx = make_ctx()
    local obj = helpers.find_visible(ctx, "sack")
    -- Currently: find_visible returns the first match silently (grain-sack).
    -- Expected: should NOT silently resolve. Should either return nil with
    -- a disambiguation prompt on ctx, or trigger a "Which sack?" question.
    if obj then
        -- Bug: silently picked one without asking
        local prompt = ctx.disambiguation_prompt
        if not prompt then
            error("'sack' matched two objects but resolved silently to '"
                .. (obj.id or "?") .. "' without disambiguation prompt")
        end
    end
    -- If obj is nil, check for disambiguation prompt
    local prompt = ctx.disambiguation_prompt
    truthy(prompt, "'sack' should produce a disambiguation prompt")
    truthy(prompt:find("Which") or prompt:find("which"),
        "prompt should ask 'Which do you mean'")
end)

test("'bag' with two sacks triggers disambiguation", function()
    -- Both sack.lua and grain-sack.lua have "bag" as a keyword.
    local ctx = make_ctx()
    local obj = helpers.find_visible(ctx, "bag")
    if obj then
        local prompt = ctx.disambiguation_prompt
        if not prompt then
            error("'bag' matched two objects but resolved silently to '"
                .. (obj.id or "?") .. "' without disambiguation prompt")
        end
    end
    local prompt = ctx.disambiguation_prompt
    truthy(prompt, "'bag' should produce disambiguation prompt")
end)

test("disambiguation prompt mentions both sack names", function()
    local ctx = make_ctx()
    helpers.find_visible(ctx, "sack")
    local prompt = ctx.disambiguation_prompt
    truthy(prompt, "should have disambiguation prompt for 'sack'")
    truthy(prompt:find("burlap"), "prompt should mention burlap sack")
    truthy(prompt:find("grain"), "prompt should mention grain sack")
end)

test("fuzzy.resolve also disambiguates 'sack' between two sack objects", function()
    local ctx = make_ctx()
    local obj, _, _, _, prompt = fuzzy.resolve(ctx, "sack")
    -- Both objects have "sack" as exact keyword → same score → disambiguation
    assert_nil(obj, "'sack' should not auto-resolve when two sacks score equally")
    truthy(prompt, "fuzzy.resolve should return disambiguation prompt")
    truthy(type(prompt) == "string" and (prompt:find("Which") ~= nil),
        "prompt should ask 'Which do you mean'")
end)

-- ===========================================================================
-- BUG B: "dump"/"empty" should work on dry containers (#182)
-- Currently "dump" aliases to "pour" which only handles liquid FSM transitions.
-- Containers with item contents need a proper dump/empty action.
-- ===========================================================================
h.suite("BUG B: dump/empty verb for containers (#182)")

test("'dump sack' empties container contents, not 'can't pour' error", function()
    local ctx = make_ctx()
    local handlers = verbs_mod.create()
    ctx.verbs = handlers
    ctx.current_verb = "dump"

    -- Put burlap sack in player's hand (contains needle + thread)
    local sack = ctx.registry:get("sack")
    sack.location = "player"
    ctx.player.hands[1] = sack

    local output = capture_print(function()
        handlers["dump"](ctx, "sack")
    end)

    -- Should NOT say "You can't pour that" — sack is a dry container
    truthy(output:find("can't pour") == nil,
        "dump on a dry container should not fail with 'can't pour': got '" .. output .. "'")
    -- The sack should be emptied
    eq(0, #sack.contents,
        "sack should be empty after dumping (had needle + thread)")
end)

test("'empty' is a registered verb", function()
    local handlers = verbs_mod.create()
    truthy(handlers["empty"],
        "'empty' should be a registered verb handler")
end)

test("'empty sack' works as synonym for dump on containers", function()
    local ctx = make_ctx()
    local handlers = verbs_mod.create()
    ctx.verbs = handlers
    ctx.current_verb = "empty"

    local sack = ctx.registry:get("sack")
    sack.location = "player"
    ctx.player.hands[1] = sack

    truthy(handlers["empty"], "'empty' must be a registered verb")

    local output = capture_print(function()
        handlers["empty"](ctx, "sack")
    end)

    truthy(output:find("can't") == nil,
        "'empty sack' should succeed, not produce error: got '" .. output .. "'")
    eq(0, #sack.contents, "sack should be empty after 'empty sack'")
end)

test("'dump grain' empties the grain sack contents", function()
    local ctx = make_ctx()
    local handlers = verbs_mod.create()
    ctx.verbs = handlers
    ctx.current_verb = "dump"

    local grain = ctx.registry:get("grain-sack")
    grain.location = "player"
    grain._state = "untied"
    ctx.player.hands[1] = grain

    local output = capture_print(function()
        handlers["dump"](ctx, "grain")
    end)

    -- "dump grain" should empty the grain sack, not fail with pour error
    truthy(output:find("can't pour") == nil,
        "'dump grain' should not fail with liquid-specific error: got '" .. output .. "'")
end)

-- ===========================================================================
print("")
local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
