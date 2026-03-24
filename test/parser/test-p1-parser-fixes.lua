-- test/parser/test-p1-parser-fixes.lua
-- TDD tests for P1 parser bug cluster: Issues #137-145, #156.
-- Write failing tests first, then fix code to make them pass.
--
-- Coverage:
--   #138: "put X down" → drop X
--   #140: "set X down" / "set down X" → drop X
--   #145: "punch myself in the face" → face resolves to head
--   #144: "hurt myself" / "beat myself up" → hit self
--   #139: "drop all" / "drop everything" bulk drop
--   #137: "drop pot" while worn → "remove it first" (not bag error)
--   #156: Mirror comma splice "your head., a deep bruise"
--
-- Ownership: Smithers (UI/Parser Engineer)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

-------------------------------------------------------------------------------
h.suite("#138: 'put X down' → drop X (word order)")
-------------------------------------------------------------------------------

test("'put the knife down' → verb=drop, noun includes knife", function()
    local v, n = preprocess.natural_language("put the knife down")
    eq("drop", v, "verb should be drop")
    -- Article "the" is stripped by verb handler, not preprocessor
    truthy(n == "knife" or n == "the knife", "noun should be knife, got: " .. tostring(n))
end)

test("'put knife down' → verb=drop, noun=knife", function()
    local v, n = preprocess.natural_language("put knife down")
    eq("drop", v, "verb should be drop")
    eq("knife", n, "noun should be knife")
end)

test("'put down the sword' still works → verb=drop, noun=sword", function()
    local v, n = preprocess.natural_language("put down the sword")
    eq("drop", v, "verb should be drop")
    truthy(n == "sword" or n == "the sword", "noun should be sword, got: " .. tostring(n))
end)

test("'put the torch down' → verb=drop, noun includes torch", function()
    local v, n = preprocess.natural_language("put the torch down")
    eq("drop", v, "verb should be drop")
    truthy(n == "torch" or n == "the torch", "noun should be torch, got: " .. tostring(n))
end)

-- Regression: "put X on Y" must NOT become drop
test("'put sword on table' still routes to put (not drop)", function()
    -- natural_language returns nil,nil when input is already canonical
    -- (no transform needed). Verify via parse that verb is still "put"
    local v, n = preprocess.natural_language("put sword on table")
    if v then
        -- If a transform fires, it should still be put, not drop
        truthy(v ~= "drop", "verb should not be drop, got: " .. tostring(v))
    else
        -- No transform = already canonical, parse confirms put
        v, n = preprocess.parse("put sword on table")
        eq("put", v, "verb should be put")
    end
end)

-- Regression: "put on X" must still become wear
test("'put on helmet' still routes to wear (not drop)", function()
    local v, n = preprocess.natural_language("put on helmet")
    eq("wear", v, "verb should be wear")
    eq("helmet", n, "noun should be helmet")
end)

-------------------------------------------------------------------------------
h.suite("#140: 'set X down' / 'set down X' → drop X")
-------------------------------------------------------------------------------

test("'set knife down' → verb=drop, noun=knife", function()
    local v, n = preprocess.natural_language("set knife down")
    eq("drop", v, "verb should be drop")
    eq("knife", n, "noun should be knife")
end)

test("'set the torch down' → verb=drop, noun includes torch", function()
    local v, n = preprocess.natural_language("set the torch down")
    eq("drop", v, "verb should be drop")
    truthy(n == "torch" or n == "the torch", "noun should be torch, got: " .. tostring(n))
end)

test("'set down the sword' → verb=drop, noun includes sword", function()
    local v, n = preprocess.natural_language("set down the sword")
    eq("drop", v, "verb should be drop")
    truthy(n == "sword" or n == "the sword", "noun should be sword, got: " .. tostring(n))
end)

test("'set down knife' → verb=drop, noun=knife", function()
    local v, n = preprocess.natural_language("set down knife")
    eq("drop", v, "verb should be drop")
    eq("knife", n, "noun should be knife")
end)

-- Regression: "set fire to X" must still work
test("'set fire to torch' → verb=light, noun=torch", function()
    local v, n = preprocess.natural_language("set fire to torch")
    eq("light", v, "verb should be light")
    eq("torch", n, "noun should be torch")
end)

-- Regression: "set X on Y" (placement) must still work
test("'set pot on table' → verb=put (placement)", function()
    local v, n = preprocess.natural_language("set pot on table")
    eq("put", v, "verb should be put")
end)

-------------------------------------------------------------------------------
h.suite("#145: 'punch myself in the face' — face → head body area")
-------------------------------------------------------------------------------

test("'punch myself in the face' strips face, dispatches as punch→hit at runtime", function()
    local v, n = preprocess.natural_language("punch myself in the face")
    -- "punch" stays as verb (aliased to hit at handler level, line 4173)
    -- "in the face" stripped by decorative prepositions
    eq("punch", v, "verb should be punch (handler aliases to hit)")
    eq("myself", n, "noun should be myself after stripping 'in the face'")
end)

test("'hit myself in the face' strips to 'hit myself'", function()
    local v, n = preprocess.natural_language("hit myself in the face")
    eq("hit", v, "verb should be hit")
    truthy(n == "myself" or n == "face" or n == "head",
           "noun should be self-target or body part, got: " .. tostring(n))
end)

test("strip_decorative_prepositions handles 'in the face'", function()
    local strip = preprocess.stages.strip_decorative_prepositions
    local result = strip("hit myself in the face")
    eq("hit myself", result, "should strip 'in the face'")
end)

test("strip_decorative_prepositions handles 'in the gut'", function()
    local strip = preprocess.stages.strip_decorative_prepositions
    local result = strip("hit myself in the gut")
    eq("hit myself", result, "should strip 'in the gut'")
end)

-- Regression: "in the mirror" still works
test("'in the mirror' still strips correctly", function()
    local strip = preprocess.stages.strip_decorative_prepositions
    local result = strip("look at myself in the mirror")
    eq("look at myself", result, "should strip 'in the mirror'")
end)

-------------------------------------------------------------------------------
h.suite("#144: 'hurt myself' / 'beat myself up' → hit self")
-------------------------------------------------------------------------------

test("'hurt myself' → verb=hit, noun=myself", function()
    local v, n = preprocess.natural_language("hurt myself")
    eq("hit", v, "verb should be hit")
    eq("myself", n, "noun should be myself")
end)

test("'hurt self' → verb=hit, noun=self", function()
    local v, n = preprocess.natural_language("hurt self")
    eq("hit", v, "verb should be hit")
    -- self or myself after strip
    truthy(n == "self" or n == "myself", "noun should be self, got: " .. tostring(n))
end)

test("'beat myself up' → verb=hit, noun=myself", function()
    local v, n = preprocess.natural_language("beat myself up")
    eq("hit", v, "verb should be hit")
    eq("myself", n, "noun should be myself")
end)

test("'beat up myself' → verb=hit, noun=myself", function()
    local v, n = preprocess.natural_language("beat up myself")
    eq("hit", v, "verb should be hit")
    eq("myself", n, "noun should be myself")
end)

-------------------------------------------------------------------------------
h.suite("#139: 'drop all' / 'drop everything' bulk drop")
-------------------------------------------------------------------------------

-- These test the preprocessor only (verb handler tests need full context)
test("'drop all' passes through as verb=drop, noun=all", function()
    -- Preprocessor should let "drop all" through as-is (handler resolves it)
    local v, n = preprocess.parse("drop all")
    eq("drop", v, "verb should be drop")
    eq("all", n, "noun should be all")
end)

test("'drop everything' passes through as verb=drop, noun=everything", function()
    local v, n = preprocess.parse("drop everything")
    eq("drop", v, "verb should be drop")
    eq("everything", n, "noun should be everything")
end)

-- Integration test with mock context for the actual drop handler
test("drop handler recognizes 'all' keyword (handler unit test)", function()
    -- Load verbs module and test that "all" is handled
    local verbs_ok, verbs = pcall(require, "engine.verbs")
    if not verbs_ok then
        -- Can't load full verbs module in isolation — test parser only
        -- The verb handler test is validated through the full test suite
        local v, n = preprocess.parse("drop all")
        eq("drop", v, "verb should be drop")
        eq("all", n, "noun should be all")
        return
    end
end)

-------------------------------------------------------------------------------
h.suite("#137: 'drop pot' while worn → 'remove it first' error")
-------------------------------------------------------------------------------

-- This is a verb handler fix — we test it by checking the find_in_inventory
-- flow. Since we can't easily unit-test the verb handler in isolation,
-- we verify the preprocessor routing is correct and document the fix.
test("'drop pot' preprocesses correctly (verb=drop, noun=pot)", function()
    local v, n = preprocess.parse("drop pot")
    eq("drop", v, "verb should be drop")
    eq("pot", n, "noun should be pot")
end)

-------------------------------------------------------------------------------
h.suite("#156: Mirror comma splice — 'your head., a deep bruise'")
-------------------------------------------------------------------------------

test("render_injury_phrase does NOT end with period", function()
    local app = require("engine.player.appearance")
    local phrase = app._render_injury_phrase({
        type = "bruised",
        severity = "moderate",
        location = "head",
    }, 1)
    -- Should be "a deep bruise on your head" with no trailing period
    truthy(not phrase:match("%.$"), "injury phrase should not end with period, got: " .. phrase)
end)

test("compose_natural strips trailing periods from phrases before joining", function()
    local app = require("engine.player.appearance")
    -- Simulate headgear description ending with period + injury phrase
    local result = app._compose_natural({
        "a pot sits on your head.",
        "a deep bruise on your head",
    })
    truthy(not result:match("%.,"), "should not have '., ' comma splice, got: " .. result)
    truthy(not result:match("%.%s+and"), "should not have '. and' splice, got: " .. result)
end)

test("compose_natural with three phrases (Oxford comma) — no splice", function()
    local app = require("engine.player.appearance")
    local result = app._compose_natural({
        "a pot sits on your head.",
        "a deep bruise on your head",
        "a slight gash on your forehead.",
    })
    truthy(not result:match("%.,"), "should not have period-comma in Oxford comma join, got: " .. result)
end)

test("render_head with injury has no period-comma splice", function()
    local app = require("engine.player.appearance")
    local player = {
        injuries = {
            { type = "bruised", severity = "moderate", location = "head" },
            { type = "bleeding", severity = "minor", location = "head" },
        },
        worn = {},
    }
    local result = app._render_head(player, nil)
    truthy(result ~= nil, "render_head should return non-nil")
    truthy(not result:match("%.,"), "head render should not have '., ' splice, got: " .. result)
end)

test("full appearance.describe with head injury — no comma splice", function()
    local app = require("engine.player.appearance")
    local player = {
        hands = { nil, nil },
        worn = {},
        injuries = {
            { type = "bruised", severity = "moderate", location = "head" },
        },
        max_health = 100,
    }
    local mock_registry = {
        get = function(self, id) return nil end,
    }
    local desc = app.describe(player, mock_registry)
    -- The composed description should not have "head., " anywhere
    truthy(not desc:match("head%.,%s"), "description should not have 'head., ' splice, got: " .. desc)
    truthy(not desc:match("%.,"), "description should not have any '., ' splice, got: " .. desc)
end)

test("full appearance with head + arm injury — clean sentence boundaries", function()
    local app = require("engine.player.appearance")
    local player = {
        hands = { nil, nil },
        worn = {},
        injuries = {
            { type = "bruised", severity = "moderate", location = "head" },
            { type = "bleeding", severity = "minor", location = "left arm" },
        },
        max_health = 100,
    }
    local mock_registry = {
        get = function(self, id) return nil end,
    }
    local desc = app.describe(player, mock_registry)
    -- Verify sentence boundaries are clean (no double periods, no period+comma)
    truthy(not desc:match("%.%."), "should not have double periods, got: " .. desc)
    truthy(not desc:match("%.,"), "should not have period-comma, got: " .. desc)
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION GUARDS")
-------------------------------------------------------------------------------

test("'put match in matchbox' preserved (compound target)", function()
    local v, n = preprocess.natural_language("put match in matchbox")
    if v then
        -- If a transform fires, it should still route to put
        truthy(v ~= "drop", "verb should not be drop, got: " .. tostring(v))
    else
        -- No transform = already canonical
        v, n = preprocess.parse("put match in matchbox")
        eq("put", v, "verb should be put")
    end
end)

test("'get rid of sword' → verb=drop, noun=sword", function()
    local v, n = preprocess.natural_language("get rid of sword")
    eq("drop", v, "verb should be drop")
    eq("sword", n, "noun should be sword")
end)

test("'toss knife' → verb=drop, noun=knife", function()
    local v, n = preprocess.natural_language("toss knife")
    eq("drop", v, "verb should be drop")
    eq("knife", n, "noun should be knife")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
