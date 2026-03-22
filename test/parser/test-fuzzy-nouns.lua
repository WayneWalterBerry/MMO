-- test/parser/test-fuzzy-nouns.lua
-- Tier 5: Fuzzy Noun Resolution unit tests
-- Tests: material matching, property matching, partial name match,
--        typo tolerance, disambiguation prompt, Levenshtein distance

package.path = "src/?.lua;src/?/init.lua;test/parser/?.lua;" .. package.path

local helpers = require("test-helpers")
local test = helpers.test
local assert_eq = helpers.assert_eq
local assert_truthy = helpers.assert_truthy
local assert_nil = helpers.assert_nil

local fuzzy = require("engine.parser.fuzzy")

helpers.suite("Levenshtein Distance")

test("identical strings have distance 0", function()
    assert_eq(0, fuzzy.levenshtein("nightstand", "nightstand"))
end)

test("single insertion: nighstand → nightstand", function()
    assert_eq(1, fuzzy.levenshtein("nighstand", "nightstand"))
end)

test("single deletion: nighttstand → nightstand", function()
    assert_eq(1, fuzzy.levenshtein("nighttstand", "nightstand"))
end)

test("single substitution: nightsland → nightstand", function()
    assert_eq(1, fuzzy.levenshtein("nightsland", "nightstand"))
end)

test("two edits: nightsand → nightstand", function()
    -- "nightsand" → "nightstand" is actually 1 edit (insert 't')
    assert_eq(1, fuzzy.levenshtein("nightsand", "nightstand"))
end)

test("completely different strings", function()
    local d = fuzzy.levenshtein("abc", "xyz")
    assert_eq(3, d)
end)

test("empty vs non-empty", function()
    assert_eq(5, fuzzy.levenshtein("", "hello"))
    assert_eq(5, fuzzy.levenshtein("hello", ""))
end)

test("both empty", function()
    assert_eq(0, fuzzy.levenshtein("", ""))
end)

helpers.suite("Typo Tolerance Thresholds")

test("short words (≤4 chars) → distance 0 (exact only)", function()
    assert_eq(0, fuzzy.max_typo_distance(1))
    assert_eq(0, fuzzy.max_typo_distance(3))
    assert_eq(0, fuzzy.max_typo_distance(4))
end)

test("medium words (5-7 chars) → distance 2", function()
    assert_eq(2, fuzzy.max_typo_distance(5))
    assert_eq(2, fuzzy.max_typo_distance(6))
    assert_eq(2, fuzzy.max_typo_distance(7))
end)

test("long words (8+ chars) → distance 2", function()
    assert_eq(2, fuzzy.max_typo_distance(8))
    assert_eq(2, fuzzy.max_typo_distance(10))
    assert_eq(2, fuzzy.max_typo_distance(15))
end)

helpers.suite("Parse Noun Phrase")

test("material adjective: 'wooden thing'", function()
    local p = fuzzy.parse_noun_phrase("the wooden thing")
    assert_eq("wooden", p.material_adj)
    assert_eq("wood", p.material_value)
    assert_eq("thing", p.base_noun)
end)

test("material adjective: 'brass key'", function()
    local p = fuzzy.parse_noun_phrase("brass key")
    assert_eq("brass", p.material_adj)
    assert_eq("brass", p.material_value)
    assert_eq("key", p.base_noun)
end)

test("property adjective: 'heavy one'", function()
    local p = fuzzy.parse_noun_phrase("the heavy one")
    assert_eq("heavy", p.property_adj)
    assert_truthy(p.property_spec)
    assert_eq("weight", p.property_spec.field)
    assert_eq("high", p.property_spec.compare)
    assert_eq("one", p.base_noun)
end)

test("property adjective: 'small box'", function()
    local p = fuzzy.parse_noun_phrase("small box")
    assert_eq("small", p.property_adj)
    assert_eq("size", p.property_spec.field)
    assert_eq("low", p.property_spec.compare)
    assert_eq("box", p.base_noun)
end)

test("plain noun: 'bottle'", function()
    local p = fuzzy.parse_noun_phrase("bottle")
    assert_nil(p.material_adj)
    assert_nil(p.property_adj)
    assert_eq("bottle", p.base_noun)
end)

test("strips articles: 'the bottle'", function()
    local p = fuzzy.parse_noun_phrase("the bottle")
    assert_eq("bottle", p.base_noun)
end)

test("strips demonstratives: 'that bottle'", function()
    local p = fuzzy.parse_noun_phrase("that bottle")
    assert_eq("bottle", p.base_noun)
end)

test("nil input returns nil", function()
    assert_nil(fuzzy.parse_noun_phrase(nil))
    assert_nil(fuzzy.parse_noun_phrase(""))
end)

helpers.suite("Score Object — Material Matching")

test("'wooden thing' matches object with material=wood", function()
    local obj = { id = "crate", name = "large crate", material = "wood", keywords = {"crate"} }
    local parsed = fuzzy.parse_noun_phrase("the wooden thing")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should match")
    assert_eq("material", reason)
end)

test("'wooden thing' does NOT match object with material=brass", function()
    local obj = { id = "key", name = "brass key", material = "brass", keywords = {"key"} }
    local parsed = fuzzy.parse_noun_phrase("the wooden thing")
    local score = fuzzy.score_object(obj, parsed)
    assert_eq(0, score)
end)

test("'wooden crate' matches with material+name bonus", function()
    local obj = { id = "crate", name = "large crate", material = "wood", keywords = {"crate"} }
    local parsed = fuzzy.parse_noun_phrase("wooden crate")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 3, "material+name should score higher")
    assert_eq("material+name", reason)
end)

test("material match via categories", function()
    local obj = { id = "crate", name = "large crate", categories = {"wooden", "furniture"}, keywords = {"crate"} }
    local parsed = fuzzy.parse_noun_phrase("the wooden thing")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should match via categories")
end)

helpers.suite("Score Object — Property Matching")

test("'heavy one' matches object with weight", function()
    local obj = { id = "anvil", name = "iron anvil", weight = 50, keywords = {"anvil"} }
    local parsed = fuzzy.parse_noun_phrase("the heavy one")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should match by weight property")
    assert_eq("property", reason)
end)

test("'heavy one' does NOT match object without weight", function()
    local obj = { id = "dust", name = "dust", keywords = {"dust"} }
    local parsed = fuzzy.parse_noun_phrase("the heavy one")
    local score = fuzzy.score_object(obj, parsed)
    assert_eq(0, score)
end)

test("'small box' matches object with size + name", function()
    local obj = { id = "box", name = "small wooden box", size = 2, keywords = {"box", "wooden box"} }
    local parsed = fuzzy.parse_noun_phrase("small box")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should match by size + name")
    assert_eq("property+name", reason)
end)

helpers.suite("Score Object — Partial Name Match")

test("'bottle' matches 'small glass bottle'", function()
    local obj = { id = "glass-bottle", name = "small glass bottle", keywords = {"bottle", "glass bottle"} }
    local parsed = fuzzy.parse_noun_phrase("bottle")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should partial-match")
end)

test("'crate' matches 'large shipping crate'", function()
    local obj = { id = "crate", name = "large shipping crate", keywords = {"crate", "shipping crate"} }
    local parsed = fuzzy.parse_noun_phrase("that crate")
    local score = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should partial-match on name/keyword")
end)

test("'lamp' does NOT match 'candle'", function()
    local obj = { id = "candle", name = "tallow candle", keywords = {"candle"} }
    local parsed = fuzzy.parse_noun_phrase("lamp")
    local score = fuzzy.score_object(obj, parsed)
    assert_eq(0, score)
end)

helpers.suite("Score Object — Typo Tolerance")

test("'nighstand' matches 'nightstand' (1 char missing)", function()
    local obj = { id = "nightstand", name = "oak nightstand", keywords = {"nightstand"} }
    local parsed = fuzzy.parse_noun_phrase("nighstand")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should typo-match")
    assert_eq("typo", reason)
end)

test("'candel' matches 'candle' (transposition)", function()
    local obj = { id = "candle", name = "tallow candle", keywords = {"candle"} }
    local parsed = fuzzy.parse_noun_phrase("candel")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should typo-match")
    assert_eq("typo", reason)
end)

test("'botle' matches 'bottle' (1 char missing)", function()
    local obj = { id = "bottle", name = "glass bottle", keywords = {"bottle"} }
    local parsed = fuzzy.parse_noun_phrase("botle")
    local score, reason = fuzzy.score_object(obj, parsed)
    assert_truthy(score > 0, "should typo-match")
    assert_eq("typo", reason)
end)

test("short word typo 'ke' does NOT fuzzy match 'key'", function()
    local obj = { id = "key", name = "brass key", keywords = {"key"} }
    local parsed = fuzzy.parse_noun_phrase("ke")
    local score = fuzzy.score_object(obj, parsed)
    assert_eq(0, score, "short words should be exact only")
end)

test("'rug' does NOT fuzzy match 'mug' (short word, exact only)", function()
    local obj = { id = "mug", name = "ceramic mug", keywords = {"mug"} }
    local parsed = fuzzy.parse_noun_phrase("rug")
    local score = fuzzy.score_object(obj, parsed)
    assert_eq(0, score, "3-char words should be exact only per D-BUG018")
end)

helpers.suite("Gather Visible Objects")

test("gathers room contents", function()
    local reg = {
        _objects = {
            chair = { id = "chair", name = "wooden chair", keywords = {"chair"} },
        },
        get = function(self, id) return self._objects[id] end,
    }
    local ctx = {
        current_room = { contents = {"chair"} },
        player = { hands = {nil, nil}, worn = {} },
        registry = reg,
    }
    local visible = fuzzy.gather_visible(ctx)
    assert_eq(1, #visible)
    assert_eq("chair", visible[1].obj.id)
    assert_eq("room", visible[1].loc)
end)

test("gathers surface contents", function()
    local reg = {
        _objects = {
            table = { id = "table", name = "table",
                surfaces = { top = { contents = {"cup"}, accessible = true } },
                keywords = {"table"} },
            cup = { id = "cup", name = "ceramic cup", keywords = {"cup"} },
        },
        get = function(self, id) return self._objects[id] end,
    }
    local ctx = {
        current_room = { contents = {"table"} },
        player = { hands = {nil, nil}, worn = {} },
        registry = reg,
    }
    local visible = fuzzy.gather_visible(ctx)
    assert_truthy(#visible >= 2)
end)

test("gathers hand contents", function()
    local reg = {
        _objects = {
            sword = { id = "sword", name = "iron sword", keywords = {"sword"} },
        },
        get = function(self, id) return self._objects[id] end,
    }
    local ctx = {
        current_room = { contents = {} },
        player = { hands = {"sword", nil}, worn = {} },
        registry = reg,
    }
    local visible = fuzzy.gather_visible(ctx)
    assert_eq(1, #visible)
    assert_eq("sword", visible[1].obj.id)
    assert_eq("hand", visible[1].loc)
end)

test("skips hidden objects", function()
    local reg = {
        _objects = {
            secret = { id = "secret", name = "secret door", hidden = true, keywords = {"door"} },
        },
        get = function(self, id) return self._objects[id] end,
    }
    local ctx = {
        current_room = { contents = {"secret"} },
        player = { hands = {nil, nil}, worn = {} },
        registry = reg,
    }
    local visible = fuzzy.gather_visible(ctx)
    assert_eq(0, #visible)
end)

helpers.suite("Fuzzy Resolve — Integration")

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

test("partial match: 'bottle' resolves to only bottle in room", function()
    local ctx = make_ctx(
        {{ id = "glass-bottle", name = "small glass bottle", keywords = {"bottle", "glass bottle"} },
         { id = "chair", name = "wooden chair", keywords = {"chair"} }},
        {"glass-bottle", "chair"}
    )
    local obj = fuzzy.resolve(ctx, "bottle")
    assert_truthy(obj, "should resolve")
    assert_eq("glass-bottle", obj.id)
end)

test("material match: 'wooden thing' finds wooden object", function()
    local ctx = make_ctx(
        {{ id = "crate", name = "large crate", material = "wood", keywords = {"crate"} },
         { id = "key", name = "brass key", material = "brass", keywords = {"key"} }},
        {"crate", "key"}
    )
    local obj = fuzzy.resolve(ctx, "the wooden thing")
    assert_truthy(obj, "should resolve to wooden object")
    assert_eq("crate", obj.id)
end)

test("property match: 'heavy one' picks heaviest object", function()
    local ctx = make_ctx(
        {{ id = "anvil", name = "iron anvil", weight = 50, keywords = {"anvil"} },
         { id = "feather", name = "feather", weight = 1, keywords = {"feather"} }},
        {"anvil", "feather"}
    )
    local obj = fuzzy.resolve(ctx, "the heavy one")
    assert_truthy(obj, "should resolve to heaviest")
    assert_eq("anvil", obj.id)
end)

test("property match: 'light one' picks lightest object", function()
    local ctx = make_ctx(
        {{ id = "anvil", name = "iron anvil", weight = 50, keywords = {"anvil"} },
         { id = "feather", name = "feather", weight = 1, keywords = {"feather"} }},
        {"anvil", "feather"}
    )
    local obj = fuzzy.resolve(ctx, "the light one")
    assert_truthy(obj, "should resolve to lightest")
    assert_eq("feather", obj.id)
end)

test("typo: 'nighstand' resolves to 'nightstand'", function()
    local ctx = make_ctx(
        {{ id = "nightstand", name = "oak nightstand", keywords = {"nightstand"} },
         { id = "chair", name = "wooden chair", keywords = {"chair"} }},
        {"nightstand", "chair"}
    )
    local obj = fuzzy.resolve(ctx, "nighstand")
    assert_truthy(obj, "should resolve via typo tolerance")
    assert_eq("nightstand", obj.id)
end)

test("typo: 'candel' resolves to 'candle'", function()
    local ctx = make_ctx(
        {{ id = "candle", name = "tallow candle", keywords = {"candle"} }},
        {"candle"}
    )
    local obj = fuzzy.resolve(ctx, "candel")
    assert_truthy(obj, "should resolve via typo tolerance")
    assert_eq("candle", obj.id)
end)

test("disambiguation: two bottles → prompt, no crash", function()
    local ctx = make_ctx(
        {{ id = "glass-bottle", name = "glass bottle", keywords = {"bottle", "glass bottle"} },
         { id = "wine-bottle", name = "wine bottle", keywords = {"bottle", "wine bottle"} }},
        {"glass-bottle", "wine-bottle"}
    )
    local obj, _, _, _, prompt = fuzzy.resolve(ctx, "bottle")
    assert_nil(obj, "should not auto-resolve ambiguous match")
    assert_truthy(prompt, "should return disambiguation prompt")
    assert_truthy(prompt:find("glass bottle"), "prompt should mention glass bottle")
    assert_truthy(prompt:find("wine bottle"), "prompt should mention wine bottle")
    assert_truthy(prompt:find("Which do you mean"), "prompt should ask politely")
end)

test("disambiguation: three items → comma-separated prompt", function()
    local ctx = make_ctx(
        {{ id = "red-gem", name = "red gem", keywords = {"gem", "red gem"} },
         { id = "blue-gem", name = "blue gem", keywords = {"gem", "blue gem"} },
         { id = "green-gem", name = "green gem", keywords = {"gem", "green gem"} }},
        {"red-gem", "blue-gem", "green-gem"}
    )
    local obj, _, _, _, prompt = fuzzy.resolve(ctx, "gem")
    assert_nil(obj, "should not auto-resolve three-way ambiguity")
    assert_truthy(prompt, "should have disambiguation prompt")
    assert_truthy(prompt:find("or"), "prompt should include 'or'")
end)

test("no match returns nil without prompt", function()
    local ctx = make_ctx(
        {{ id = "chair", name = "wooden chair", keywords = {"chair"} }},
        {"chair"}
    )
    local obj, _, _, _, prompt = fuzzy.resolve(ctx, "elephant")
    assert_nil(obj, "should not match")
    assert_nil(prompt, "should have no prompt")
end)

test("empty room returns nil", function()
    local ctx = make_ctx({}, {})
    local obj = fuzzy.resolve(ctx, "anything")
    assert_nil(obj)
end)

test("material + partial name beats material alone", function()
    local ctx = make_ctx(
        {{ id = "crate", name = "large crate", material = "wood", keywords = {"crate"} },
         { id = "chair", name = "wooden chair", material = "wood", keywords = {"chair"} }},
        {"crate", "chair"}
    )
    local obj = fuzzy.resolve(ctx, "wooden crate")
    assert_truthy(obj, "should resolve")
    assert_eq("crate", obj.id, "material+name should win over material alone")
end)

helpers.suite("Correct Typo — Standalone")

test("correct_typo suggests nightstand for nighstand", function()
    local visible = {
        { obj = { id = "nightstand", name = "oak nightstand", keywords = {"nightstand"} } },
        { obj = { id = "chair", name = "wooden chair", keywords = {"chair"} } },
    }
    local corrected = fuzzy.correct_typo("nighstand", visible)
    assert_eq("nightstand", corrected)
end)

test("correct_typo returns nil for exact match", function()
    local visible = {
        { obj = { id = "chair", name = "wooden chair", keywords = {"chair"} } },
    }
    local corrected = fuzzy.correct_typo("chair", visible)
    assert_nil(corrected, "exact match should return nil")
end)

test("correct_typo returns nil for short words", function()
    local visible = {
        { obj = { id = "key", name = "brass key", keywords = {"key"} } },
    }
    local corrected = fuzzy.correct_typo("kye", visible)
    assert_nil(corrected, "3-char words should not fuzzy correct")
end)

-- Report
local failed = helpers.summary()
os.exit(failed > 0 and 1 or 0)
