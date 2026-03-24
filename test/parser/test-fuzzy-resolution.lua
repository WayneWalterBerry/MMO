-- test/parser/test-fuzzy-resolution.lua
-- Tier 5: Enhanced Fuzzy Noun Resolution unit tests (Prime Directive #106).
-- Tests new features being added to engine.parser.fuzzy:
--   - Confidence scoring (0.0–1.0 normalization)
--   - Context-integrated scoring (recency bonus)
--   - Enhanced typo thresholds for 4-char words
--   - Rejection below minimum confidence threshold
--
-- TDD RED PHASE: These tests target NEW APIs on the existing fuzzy module.
-- All tests FAIL until the enhancements are implemented by Smithers.
--
-- Usage: lua test/parser/test-fuzzy-resolution.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../?.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local test    = h.test
local eq      = h.assert_eq
local truthy  = h.assert_truthy
local assert_nil = h.assert_nil

local fuzzy = require("engine.parser.fuzzy")

-- Context module needed for context-integrated scoring tests
local context_window = require("engine.parser.context")

-------------------------------------------------------------------------------
-- Test helpers: mock context for fuzzy resolve
-------------------------------------------------------------------------------
local function make_ctx(objects, room_contents, hands)
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
        player = { hands = hands or {nil, nil}, worn = {} },
        registry = reg,
        current_verb = "examine",
    }
end

-------------------------------------------------------------------------------
h.suite("Tier 5: Confidence Scoring — New API")
-------------------------------------------------------------------------------

test("fuzzy.confidence exists as a function", function()
    truthy(type(fuzzy.confidence) == "function",
           "fuzzy.confidence() not yet implemented")
end)

test("fuzzy.confidence(10) → 1.0 (max score)", function()
    truthy(fuzzy.confidence, "fuzzy.confidence not yet implemented")
    local c = fuzzy.confidence(10)
    eq(1.0, c, "max raw score should normalize to 1.0")
end)

test("fuzzy.confidence(5) → 0.5 (mid score)", function()
    truthy(fuzzy.confidence, "fuzzy.confidence not yet implemented")
    local c = fuzzy.confidence(5)
    eq(0.5, c, "mid raw score should normalize to 0.5")
end)

test("fuzzy.confidence(0) → 0.0 (no match)", function()
    truthy(fuzzy.confidence, "fuzzy.confidence not yet implemented")
    local c = fuzzy.confidence(0)
    eq(0.0, c, "zero raw score should normalize to 0.0")
end)

-------------------------------------------------------------------------------
h.suite("Tier 5: Confidence Thresholds")
-------------------------------------------------------------------------------

test("fuzzy.MIN_CONFIDENCE exists and is 0.3", function()
    truthy(fuzzy.MIN_CONFIDENCE ~= nil,
           "fuzzy.MIN_CONFIDENCE not yet defined")
    eq(0.3, fuzzy.MIN_CONFIDENCE,
       "minimum acceptance threshold should be 0.3")
end)

test("fuzzy.AUTO_ACCEPT exists and is 0.7", function()
    truthy(fuzzy.AUTO_ACCEPT ~= nil,
           "fuzzy.AUTO_ACCEPT not yet defined")
    eq(0.7, fuzzy.AUTO_ACCEPT,
       "auto-accept threshold should be 0.7")
end)

-------------------------------------------------------------------------------
h.suite("Tier 5: Enhanced Typo Thresholds — 4-char words")
-------------------------------------------------------------------------------

test("max_typo_distance(4) returns 1 (allow single typo)", function()
    -- Current code returns 0 for 4-char words; new spec says 1
    local d = fuzzy.max_typo_distance(4)
    eq(1, d, "4-char words should allow distance 1 (currently 0)")
end)

test("max_typo_distance(3) still returns 0 (exact only)", function()
    local d = fuzzy.max_typo_distance(3)
    eq(0, d, "3-char words must remain exact only")
end)

test("max_typo_distance(5) still returns 2", function()
    local d = fuzzy.max_typo_distance(5)
    eq(2, d, "5-char words should allow distance 2")
end)

-------------------------------------------------------------------------------
h.suite("Tier 5: Context-Integrated Scoring")
-------------------------------------------------------------------------------

test("fuzzy.score_with_context exists as a function", function()
    truthy(type(fuzzy.score_with_context) == "function",
           "fuzzy.score_with_context() not yet implemented")
end)

test("score_with_context adds recency bonus for recent object", function()
    truthy(fuzzy.score_with_context,
           "fuzzy.score_with_context not yet implemented")
    context_window.reset()
    local candle = { id = "candle", name = "tallow candle",
                     keywords = {"candle"}, material = "wax" }
    context_window.push(candle)
    local parsed = fuzzy.parse_noun_phrase("candle")
    local base_score = fuzzy.score_object(candle, parsed)
    local ctx_score = fuzzy.score_with_context(candle, parsed, context_window)
    truthy(ctx_score > base_score,
           "context score should exceed base score for recently used object")
end)

test("score_with_context returns base score for unknown object", function()
    truthy(fuzzy.score_with_context,
           "fuzzy.score_with_context not yet implemented")
    context_window.reset()
    local lamp = { id = "lamp", name = "brass lamp",
                   keywords = {"lamp"}, material = "brass" }
    local parsed = fuzzy.parse_noun_phrase("lamp")
    local base_score = fuzzy.score_object(lamp, parsed)
    local ctx_score = fuzzy.score_with_context(lamp, parsed, context_window)
    eq(base_score, ctx_score,
       "object not in context should get no recency bonus")
end)

-------------------------------------------------------------------------------
h.suite("Tier 5: Typo Resolution via Confidence")
-------------------------------------------------------------------------------

test("'candel' resolves to candle with confidence above threshold", function()
    truthy(fuzzy.confidence, "fuzzy.confidence not yet implemented")
    local ctx = make_ctx(
        {{ id = "candle", name = "tallow candle", keywords = {"candle"} }},
        {"candle"})
    local obj = fuzzy.resolve(ctx, "candel")
    truthy(obj, "'candel' should resolve to candle")
    eq("candle", obj.id)
    -- Verify confidence scoring on the match
    local parsed = fuzzy.parse_noun_phrase("candel")
    local score = fuzzy.score_object(obj, parsed)
    local conf = fuzzy.confidence(score)
    truthy(conf >= fuzzy.MIN_CONFIDENCE,
           "typo match confidence should meet minimum threshold")
end)

test("'mirrir' resolves to mirror with confidence above threshold", function()
    truthy(fuzzy.confidence, "fuzzy.confidence not yet implemented")
    local mirror = { id = "mirror", name = "silver mirror",
                     keywords = {"mirror"}, material = "glass" }
    local ctx = make_ctx({ mirror }, {"mirror"})
    local obj = fuzzy.resolve(ctx, "mirrir")
    truthy(obj, "'mirrir' should resolve to mirror")
    eq("mirror", obj.id)
    local parsed = fuzzy.parse_noun_phrase("mirrir")
    local score = fuzzy.score_object(obj, parsed)
    local conf = fuzzy.confidence(score)
    truthy(conf >= fuzzy.MIN_CONFIDENCE,
           "typo match confidence should meet minimum threshold")
end)

-------------------------------------------------------------------------------
h.suite("Tier 5: Material-Based Resolution via Confidence")
-------------------------------------------------------------------------------

test("'the glass thing' → mirror (material-based)", function()
    truthy(fuzzy.confidence, "fuzzy.confidence not yet implemented")
    local mirror = { id = "mirror", name = "silver mirror",
                     keywords = {"mirror"}, material = "glass" }
    local crate = { id = "crate", name = "large crate",
                    keywords = {"crate"}, material = "wood" }
    local ctx = make_ctx({ mirror, crate }, {"mirror", "crate"})
    local obj = fuzzy.resolve(ctx, "the glass thing")
    truthy(obj, "'the glass thing' should resolve")
    eq("mirror", obj.id)
    local parsed = fuzzy.parse_noun_phrase("the glass thing")
    local score = fuzzy.score_object(mirror, parsed)
    local conf = fuzzy.confidence(score)
    truthy(conf >= fuzzy.MIN_CONFIDENCE,
           "material match confidence should meet threshold")
end)

test("'the brass' → brass key (partial name)", function()
    truthy(fuzzy.confidence, "fuzzy.confidence not yet implemented")
    local key = { id = "brass-key", name = "brass key",
                  keywords = {"key", "brass key"}, material = "brass" }
    local ctx = make_ctx({ key }, {"brass-key"})
    local obj = fuzzy.resolve(ctx, "the brass")
    truthy(obj, "'the brass' should resolve to brass key")
    eq("brass-key", obj.id)
end)

-------------------------------------------------------------------------------
h.suite("Tier 5: Rejection Threshold")
-------------------------------------------------------------------------------

test("'xyz' should NOT match anything — below confidence", function()
    local candle = { id = "candle", name = "tallow candle",
                     keywords = {"candle"} }
    local ctx = make_ctx({ candle }, {"candle"})
    local obj = fuzzy.resolve(ctx, "xyz")
    assert_nil(obj, "'xyz' should not match any object")
end)

test("'qqq' should NOT match anything", function()
    local mirror = { id = "mirror", name = "silver mirror",
                     keywords = {"mirror"} }
    local ctx = make_ctx({ mirror }, {"mirror"})
    local obj = fuzzy.resolve(ctx, "qqq")
    assert_nil(obj, "'qqq' should not match any object")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
