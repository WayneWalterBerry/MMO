-- test/integration/test-bugs-066-067-069-070-071.lua
-- Regression + integration tests for parser/resolver bug fixes:
--   #66: "stab yourself" — effects pipeline not called, no injury created
--   #67: "hit your head" — possessive pronoun "your" not stripped
--   #69/#70: "wear it" — pronoun "it"/"that" not resolved, no auto-pickup
--   #71: "pick up cloak" — fuzzy match "cloak"→"oak" false positive

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../../test/parser/?.lua;"
             .. package.path

local passed = 0
local failed = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("  PASS " .. name)
        passed = passed + 1
    else
        print("  FAIL " .. name .. ": " .. tostring(err))
        failed = failed + 1
    end
end

local function assert_eq(a, b, msg)
    if a ~= b then
        error((msg or "assert_eq") .. " — expected: " .. tostring(b) .. " got: " .. tostring(a))
    end
end

local function assert_true(v, msg)
    if not v then error(msg or "expected true") end
end

local function assert_contains(haystack, needle, msg)
    if not haystack:find(needle, 1, true) then
        error((msg or "substring not found") .. "\n  expected: " .. needle .. "\n  in: " .. haystack)
    end
end

-- Capture print output during a function call
local function capture(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local args = {}
        for i = 1, select("#", ...) do args[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(args, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err) end
    return table.concat(captured, "\n")
end

-- Reset require cache for clean test isolation
local function reset_modules()
    for k, _ in pairs(package.loaded) do
        if k:match("^engine%.") or k:match("^meta%.") then
            package.loaded[k] = nil
        end
    end
end

---------------------------------------------------------------------------
-- Shared setup: create a test context with objects
---------------------------------------------------------------------------
local function make_ctx(opts)
    opts = opts or {}
    reset_modules()

    local registry_mod = require("engine.registry")
    local reg = registry_mod.new()

    -- Register a knife with effects_pipeline
    local knife = {
        id = "knife",
        name = "a small knife",
        keywords = {"knife", "blade", "small knife"},
        material = "steel",
        portable = true,
        effects_pipeline = true,
        on_stab = {
            damage = 5,
            injury_type = "bleeding",
            description = "You stab the knife into your %s. It hurts.",
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "bleeding",
                  source = "knife", damage = 5,
                  message = "You stab the knife into your %s. It hurts." },
            },
        },
    }
    reg:register("knife", knife)

    -- Register a wool cloak (wearable)
    local cloak = {
        id = "wool-cloak",
        name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak", "cape"},
        portable = true,
        material = "wool",
        wear = { slot = "back", layer = "outer", provides_warmth = true },
    }
    reg:register("wool-cloak", cloak)

    -- Register an oak vanity (to test #71 fuzzy priority)
    local vanity = {
        id = "vanity",
        name = "oak vanity",
        keywords = {"vanity", "mirror", "oak vanity", "dressing table"},
        material = "oak",
    }
    reg:register("vanity", vanity)

    local room_contents = opts.room_contents or {"vanity"}
    if opts.cloak_in_room then
        room_contents[#room_contents + 1] = "wool-cloak"
    end

    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A test room.",
        contents = room_contents,
        exits = {},
    }

    local hands = {nil, nil}
    if opts.knife_in_hand then
        hands[1] = knife
    end

    local ctx = {
        registry = reg,
        current_room = room,
        time_offset = 8,
        game_start_time = os.time() - 28800, -- 8 hours ago for daytime
        player = {
            hands = hands,
            worn = {},
            state = {},
            injuries = {},
            max_health = 100,
        },
        verbs = {},
    }

    local verbs_mod = require("engine.verbs")
    ctx.verbs = verbs_mod.create()

    return ctx, reg, knife, cloak, vanity
end

---------------------------------------------------------------------------
print("=== #66: Stab yourself — effects pipeline integration ===")
---------------------------------------------------------------------------

test("#66: stab self with knife creates injury via pipeline", function()
    local ctx = make_ctx({ knife_in_hand = true })
    local output = capture(function()
        ctx.verbs.stab(ctx, "self")
    end)
    assert_true(#ctx.player.injuries > 0, "should have at least 1 injury")
    local inj = ctx.player.injuries[1]
    assert_eq(inj.type, "bleeding", "injury type should be bleeding")
    assert_true(inj.damage > 0, "injury should have damage")
    assert_true(inj.source:find("knife"), "source should mention knife")
end)

test("#66: stab self sets bloody state", function()
    local ctx = make_ctx({ knife_in_hand = true })
    capture(function() ctx.verbs.stab(ctx, "self") end)
    assert_true(ctx.player.state.bloody, "player should be bloody after stab")
end)

test("#66: stab arm with knife — body area preserved in injury", function()
    local ctx = make_ctx({ knife_in_hand = true })
    capture(function() ctx.verbs.stab(ctx, "arm") end)
    assert_true(#ctx.player.injuries > 0, "should have injury")
    assert_eq(ctx.player.injuries[1].location, "left arm", "arm should resolve to left arm")
end)

test("#66: stab self prints weapon description", function()
    local ctx = make_ctx({ knife_in_hand = true })
    local output = capture(function() ctx.verbs.stab(ctx, "self") end)
    assert_contains(output, "stab the knife", "should print knife stab description")
end)

test("#66: effects.process is called (pipeline_effects used)", function()
    local ctx = make_ctx({ knife_in_hand = true })
    -- Track if effects module is invoked
    local effects = require("engine.effects")
    local original_process = effects.process
    local process_called = false
    effects.process = function(raw, fx_ctx)
        process_called = true
        return original_process(raw, fx_ctx)
    end
    capture(function() ctx.verbs.stab(ctx, "self") end)
    effects.process = original_process
    assert_true(process_called, "effects.process should be called for pipeline weapons")
end)

---------------------------------------------------------------------------
print("=== #67: Possessive pronoun stripping ===")
---------------------------------------------------------------------------

test("#67: 'hit your head' recognized as self-infliction", function()
    local ctx = make_ctx({})
    local output = capture(function() ctx.verbs.hit(ctx, "your head") end)
    -- Should trigger concussion, not "You can only hit yourself"
    assert_true(not output:find("only hit yourself", 1, true),
        "should NOT say 'only hit yourself' — 'your head' should resolve")
    assert_true(#ctx.player.injuries > 0, "should create concussion injury")
end)

test("#67: 'stab your arm' recognized (possessive in verb handler)", function()
    local ctx = make_ctx({ knife_in_hand = true })
    local output = capture(function() ctx.verbs.stab(ctx, "your arm") end)
    assert_true(#ctx.player.injuries > 0, "should create bleeding injury on arm")
    assert_eq(ctx.player.injuries[1].location, "left arm")
end)

test("#67: preprocess strips possessives from verb+noun", function()
    local preprocess = require("engine.parser.preprocess")
    local verb, noun = preprocess.natural_language("hit your head")
    assert_eq(verb, "hit", "verb should be hit")
    assert_eq(noun, "head", "noun should be head (your stripped)")
end)

test("#67: preprocess strips 'my' possessive too", function()
    local preprocess = require("engine.parser.preprocess")
    local verb, noun = preprocess.natural_language("stab my leg")
    assert_eq(verb, "stab", "verb should be stab")
    assert_eq(noun, "leg", "noun should be leg (my stripped)")
end)

test("#67: possessive strip doesn't break 'check my wounds'", function()
    local preprocess = require("engine.parser.preprocess")
    local verb, noun = preprocess.natural_language("check my wounds")
    assert_eq(verb, "health", "'check my wounds' should still route to health")
end)

test("#67: possessive strip doesn't break 'what's in my hands'", function()
    local preprocess = require("engine.parser.preprocess")
    local verb, noun = preprocess.natural_language("what's in my hands?")
    assert_eq(verb, "inventory", "'what's in my hands' should still route to inventory")
end)

test("#67: 'pick up your cloak' strips possessive for two-word verb", function()
    local preprocess = require("engine.parser.preprocess")
    local verb, noun = preprocess.natural_language("pick up your cloak")
    -- After strip: "pick up cloak" → parse → verb="pick", noun="up cloak"
    -- The verb handler for "take" handles "up cloak" → "cloak"
    assert_true(noun ~= nil and not noun:find("your"), "possessive should be stripped")
end)

---------------------------------------------------------------------------
print("=== #69/#70: Pronoun resolution + wear auto-pickup ===")
---------------------------------------------------------------------------

test("#69: context_window resolves 'it' to last examined object", function()
    local ctx = make_ctx({ cloak_in_room = true })
    -- Examine cloak to push to context window
    capture(function() ctx.verbs.examine(ctx, "cloak") end)
    -- Now resolve 'it'
    local context_window = require("engine.parser.context")
    local resolved = context_window.resolve("it")
    assert_true(resolved ~= nil, "should resolve 'it' to something")
    assert_eq(resolved.id, "wool-cloak", "'it' should resolve to wool-cloak")
end)

test("#69: context_window resolves 'that' to last object", function()
    local ctx = make_ctx({ cloak_in_room = true })
    capture(function() ctx.verbs.examine(ctx, "cloak") end)
    local context_window = require("engine.parser.context")
    local resolved = context_window.resolve("that")
    assert_true(resolved ~= nil, "'that' should resolve")
    assert_eq(resolved.id, "wool-cloak")
end)

test("#70: wear auto-picks up wearable from room", function()
    local ctx = make_ctx({ cloak_in_room = true })
    -- Cloak is in room, not in hands
    assert_true(ctx.player.hands[1] == nil or ctx.player.hands[1].id ~= "wool-cloak",
        "cloak should not be in hand initially")
    local output = capture(function() ctx.verbs.wear(ctx, "cloak") end)
    -- Should auto-pickup and wear
    assert_contains(output, "pick up", "should narrate auto-pickup")
    assert_true(#ctx.player.worn > 0, "cloak should now be worn")
    local found_worn = false
    for _, id in ipairs(ctx.player.worn) do
        if id == "wool-cloak" then found_worn = true; break end
    end
    assert_true(found_worn, "wool-cloak should be in worn list")
end)

test("#70: wear 'it' after examining cloak auto-picks up", function()
    local ctx = make_ctx({ cloak_in_room = true })
    -- Examine cloak (pushes to context window)
    capture(function() ctx.verbs.examine(ctx, "cloak") end)
    -- Now "wear it" — should resolve 'it' to cloak, auto-pickup, and wear
    local output = capture(function() ctx.verbs.wear(ctx, "it") end)
    assert_true(#ctx.player.worn > 0, "cloak should be worn after 'wear it'")
end)

test("#70: wear auto-pickup fails gracefully when hands full", function()
    local ctx = make_ctx({ cloak_in_room = true, knife_in_hand = true })
    -- Fill both hands
    local stone = { id = "stone", name = "a stone", keywords = {"stone"} }
    ctx.registry:register("stone", stone)
    ctx.player.hands[2] = stone
    local output = capture(function() ctx.verbs.wear(ctx, "cloak") end)
    assert_contains(output, "hands are full", "should say hands are full")
end)

test("#70: non-wearable item does NOT auto-pickup on wear", function()
    local ctx = make_ctx({})
    -- Vanity is in room but not wearable
    local output = capture(function() ctx.verbs.wear(ctx, "vanity") end)
    assert_contains(output, "holding", "should say not holding (no auto-pickup for non-wearable)")
end)

---------------------------------------------------------------------------
print("=== #71: Fuzzy match priority — cloak vs oak ===")
---------------------------------------------------------------------------

test("#71: fuzzy.levenshtein('cloak', 'oak') = 2", function()
    local fuzzy = require("engine.parser.fuzzy")
    local dist = fuzzy.levenshtein("cloak", "oak")
    assert_eq(dist, 2, "Levenshtein distance cloak→oak should be 2")
end)

test("#71: fuzzy scoring rejects 'cloak'→'oak' typo (length ratio)", function()
    local fuzzy = require("engine.parser.fuzzy")
    local vanity = {
        id = "vanity", name = "oak vanity",
        keywords = {"vanity", "oak vanity"},
    }
    local parsed = fuzzy.parse_noun_phrase("cloak")
    local score, reason = fuzzy.score_object(vanity, parsed)
    assert_eq(score, 0, "vanity should NOT match 'cloak' via typo — score should be 0")
end)

test("#71: fuzzy scoring accepts exact keyword match for cloak", function()
    local fuzzy = require("engine.parser.fuzzy")
    local cloak = {
        id = "wool-cloak", name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak", "cape"},
    }
    local parsed = fuzzy.parse_noun_phrase("cloak")
    local score, reason = fuzzy.score_object(cloak, parsed)
    assert_eq(score, 10, "wool-cloak should match 'cloak' as exact keyword")
    assert_eq(reason, "exact")
end)

test("#71: legitimate typo 'nighstand' still matches 'nightstand'", function()
    local fuzzy = require("engine.parser.fuzzy")
    local nightstand = {
        id = "nightstand", name = "nightstand",
        keywords = {"nightstand", "table"},
    }
    local parsed = fuzzy.parse_noun_phrase("nighstand")
    local score, reason = fuzzy.score_object(nightstand, parsed)
    assert_true(score > 0, "legitimate typo 'nighstand' should still match")
    assert_eq(reason, "typo")
end)

test("#71: length ratio 3/5=0.60 below 0.75 threshold", function()
    -- "oak" is 3 chars, "cloak" is 5 chars. 3/5 = 0.60 < 0.75 → rejected.
    local ratio = 3 / 5
    assert_true(ratio < 0.75, "3/5 ratio should be below 0.75 threshold")
end)

---------------------------------------------------------------------------
print("=== INTEGRATION: Full parser pipeline → verb dispatch → injury ===")
---------------------------------------------------------------------------

test("INTEGRATION: raw 'stab yourself' creates injury", function()
    local ctx = make_ctx({ knife_in_hand = true })
    local preprocess = require("engine.parser.preprocess")
    local verb, noun = preprocess.parse("stab yourself")
    local output = capture(function()
        if ctx.verbs[verb] then
            ctx.verbs[verb](ctx, noun)
        else
            error("verb '" .. verb .. "' not found in handlers")
        end
    end)
    assert_true(#ctx.player.injuries > 0,
        "INTEGRATION: 'stab yourself' should create injury through full pipeline")
end)

test("INTEGRATION: raw 'hit your head' creates concussion", function()
    local ctx = make_ctx({})
    local preprocess = require("engine.parser.preprocess")
    -- Process through NL pipeline first
    local verb, noun = preprocess.natural_language("hit your head")
    if not verb then verb, noun = preprocess.parse("hit your head") end
    local output = capture(function()
        ctx.verbs[verb](ctx, noun)
    end)
    assert_true(#ctx.player.injuries > 0,
        "INTEGRATION: 'hit your head' should create concussion injury")
    assert_eq(ctx.player.injuries[1].type, "concussion")
end)

test("INTEGRATION: raw 'stab your arm' creates bleeding injury", function()
    local ctx = make_ctx({ knife_in_hand = true })
    local preprocess = require("engine.parser.preprocess")
    local verb, noun = preprocess.natural_language("stab your arm")
    if not verb then verb, noun = preprocess.parse("stab your arm") end
    local output = capture(function()
        ctx.verbs[verb](ctx, noun)
    end)
    assert_true(#ctx.player.injuries > 0,
        "INTEGRATION: 'stab your arm' should create bleeding injury")
    assert_eq(ctx.player.injuries[1].type, "bleeding")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------

print("--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)

if failed > 0 then
    print("Failures:")
    os.exit(1)
end

return { run = function() return failed == 0 end }
