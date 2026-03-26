-- test/parser/test-issue-174-embedding-overhaul.lua
-- TDD tests for Issue #174: SLM Embedding Index Overhaul (Sections 1-4)
--
-- Section 1: Slim index loads (text/verb/noun only, no vectors)
-- Section 2: Missing objects audited and added
-- Section 3: New phrase variants resolve correctly
-- Section 4: Tiebreaker prefers base-state noun variant

package.path = "src/?.lua;" .. package.path

local t = require("test.parser.test-helpers")
local embedding_matcher = require("engine.parser.embedding_matcher")

local SEP = package.config:sub(1, 1)
local index_path = "src" .. SEP .. "assets" .. SEP .. "parser" .. SEP .. "embedding-index.json"

-- =========================================================================
-- SECTION 1: Slim Index & Graceful Degradation
-- =========================================================================
t.suite("Section 1: Slim index loads correctly")

t.test("engine boots without embedding index (graceful degradation)", function()
    local m = embedding_matcher.new("nonexistent/path/fake.json")
    t.assert_truthy(m, "matcher object should be created")
    t.assert_eq(false, m.loaded, "loaded should be false for missing index")
    local verb, noun, score = m:match("look candle")
    t.assert_nil(verb, "verb should be nil when index not loaded")
    t.assert_eq(0, score, "score should be 0 when index not loaded")
end)

t.test("slim index loads (text/verb/noun only, no vectors)", function()
    local m = embedding_matcher.new(index_path)
    t.assert_truthy(m.loaded, "matcher should load slim index")
    t.assert_truthy(#m.phrases > 0, "phrases should be populated")
    -- Verify phrase structure: text, verb, noun present; no embedding/vector field
    local first = m.phrases[1]
    t.assert_truthy(first.text, "phrase should have text")
    t.assert_truthy(first.verb, "phrase should have verb")
    t.assert_truthy(first.tokens, "phrase should have tokenized tokens")
    -- No embedding field should be present
    t.assert_nil(first.embedding, "phrase should NOT have embedding vector")
    t.assert_nil(first.vector, "phrase should NOT have vector field")
end)

t.test("slim index resolves basic queries", function()
    local m = embedding_matcher.new(index_path)
    local verb, noun, score = m:match("look candle")
    t.assert_eq("look", verb)
    t.assert_eq("candle", noun)
    t.assert_truthy(score > 0, "score should be positive")
end)

-- =========================================================================
-- SECTION 2: Missing Objects Covered
-- Objects added to the game since the original index was built must have
-- embedding entries so Tier 2 can resolve them.
-- =========================================================================
t.suite("Section 2: Key missing objects in index")

local m = embedding_matcher.new(index_path)

local function assert_resolves(input, expect_verb, expect_noun, desc)
    t.test(desc or (input .. " resolves"), function()
        local verb, noun, score = m:match(input)
        t.assert_truthy(score > 0, "score should be positive for: " .. input)
        if expect_verb then
            t.assert_eq(expect_verb, verb, "verb mismatch for: " .. input)
        end
        if expect_noun then
            t.assert_eq(expect_noun, noun, "noun mismatch for: " .. input)
        end
    end)
end

-- Level 1 objects that should be in the index
assert_resolves("examine mirror",       "examine", "mirror",        "mirror resolves")
assert_resolves("open drawer",          "open",    "drawer",        "drawer resolves")
assert_resolves("get candle holder",    "get",     "candle-holder", "candle-holder resolves")
assert_resolves("examine candle stub",  "examine", "candle-stub",   "candle-stub resolves")
assert_resolves("open chest",           "open",    "chest",         "chest resolves")
assert_resolves("get silver dagger",    "get",     "silver-dagger", "silver-dagger resolves")
assert_resolves("examine portrait",     "examine", "portrait",      "portrait resolves")
assert_resolves("get crowbar",          "get",     "crowbar",       "crowbar resolves")
assert_resolves("get torch",            "get",     "torch",         "torch resolves")
assert_resolves("examine barrel",       "examine", "barrel",        "barrel resolves")
assert_resolves("examine oak door",      "examine", "bedroom-hallway-door-north",  "bedroom-hallway-door-north resolves")
assert_resolves("get rope",             "get",     "rope-coil",     "rope-coil resolves")
assert_resolves("examine cloth scraps", "examine", "cloth-scraps",  "cloth-scraps resolves")
assert_resolves("wear trousers",        "don",     "trousers",      "trousers resolves")
assert_resolves("get iron key",         "get",     "iron-key",      "iron-key resolves")

-- Level 2+ objects with basic coverage
assert_resolves("examine skull",        "examine", "skull",         "skull resolves")
assert_resolves("get oil flask",        "get",     "oil-flask",     "oil-flask resolves")
assert_resolves("examine wine bottle",  "examine", "wine-bottle",   "wine-bottle resolves")
assert_resolves("examine bear trap",    "examine", "bear-trap",     "bear-trap resolves")
assert_resolves("read scroll",          "read",    "tattered-scroll", "tattered-scroll resolves")
assert_resolves("examine sarcophagus",  "examine", "sarcophagus",   "sarcophagus resolves")
assert_resolves("get bronze ring",      "get",     "bronze-ring",   "bronze-ring resolves")

-- =========================================================================
-- SECTION 3: New Phrase Variants
-- gimme X → get, hold X → get, lift X → get
-- peer at X → examine, inspect X → examine
-- ignite X → light, use candle → ignite, check out X → examine
-- =========================================================================
t.suite("Section 3: New phrase variants")

assert_resolves("gimme the knife",      "get",     "knife",    "gimme X → get")
assert_resolves("gimme blanket",        "get",     "blanket",  "gimme blanket → get")
assert_resolves("hold the candle",      "get",     "candle",   "hold X → get")
assert_resolves("hold matchbox",        "get",     "matchbox", "hold matchbox → get")
assert_resolves("lift the pillow",      "get",     "pillow",   "lift X → get")
assert_resolves("lift rug",             "get",     "rug",      "lift rug → get")

assert_resolves("peer at nightstand",   "examine", "nightstand", "peer at X → examine")
assert_resolves("peer at the candle",   "examine", "candle",     "peer at candle → examine")
assert_resolves("inspect the rug",      "examine", "rug",        "inspect X → examine")
assert_resolves("inspect knife",        "examine", "knife",      "inspect knife → examine")

assert_resolves("ignite the match",     "ignite",  "match",    "ignite X → light/ignite")
assert_resolves("ignite candle",        "ignite",  "candle",   "ignite candle → light/ignite")
assert_resolves("use candle",           "ignite",  "candle",   "use candle → ignite")
assert_resolves("use match",            "ignite",  "match",    "use match → ignite")
assert_resolves("check out the wardrobe", "examine", "wardrobe", "check out X → examine")
assert_resolves("check out rug",        "examine",    "rug",      "check out rug → examine")

-- =========================================================================
-- SECTION 4: State-Variant Tiebreaker
-- When scores tie, prefer base-state (non-suffixed) noun variant.
-- "examine match" → "match" not "match-lit"
-- =========================================================================
t.suite("Section 4: Base-state tiebreaker")

t.test("examine match prefers base-state noun", function()
    local verb, noun, score = m:match("examine match")
    t.assert_eq("examine", verb)
    t.assert_eq("match", noun, "should prefer 'match' over 'match-lit'")
end)

t.test("look at candle prefers base-state noun", function()
    local verb, noun, score = m:match("look at candle")
    t.assert_eq("look", verb)
    t.assert_eq("candle", noun, "should prefer 'candle' over 'candle-lit'")
end)

t.test("get candle prefers base-state noun", function()
    local verb, noun, score = m:match("get candle")
    t.assert_eq("get", verb)
    t.assert_eq("candle", noun, "should prefer 'candle' over 'candle-lit'")
end)

t.test("open nightstand prefers base-state noun", function()
    local verb, noun, score = m:match("open nightstand")
    t.assert_eq("open", verb)
    t.assert_eq("nightstand", noun, "should prefer 'nightstand' over 'nightstand-open'")
end)

t.test("search wardrobe prefers base-state noun", function()
    local verb, noun, score = m:match("search wardrobe")
    t.assert_eq("search", verb)
    t.assert_eq("wardrobe", noun, "should prefer 'wardrobe' over 'wardrobe-open'")
end)

t.test("examine vanity prefers base-state noun", function()
    local verb, noun, score = m:match("examine vanity")
    t.assert_eq("examine", verb)
    t.assert_eq("vanity", noun, "should prefer 'vanity' over vanity-open/mirror-broken")
end)

t.test("feel curtains prefers base-state noun", function()
    local verb, noun, score = m:match("feel curtains")
    t.assert_eq("feel", verb)
    t.assert_eq("curtains", noun, "should prefer 'curtains' over 'curtains-open'")
end)

t.test("look at window prefers base-state noun", function()
    local verb, noun, score = m:match("look at window")
    t.assert_eq("look", verb)
    t.assert_eq("window", noun, "should prefer 'window' over 'window-open'")
end)

-- Explicit state mentions SHOULD resolve to the stated variant
t.test("examine lit match resolves to match-lit", function()
    local verb, noun, score = m:match("examine a lit match")
    t.assert_eq("examine", verb)
    t.assert_eq("match-lit", noun, "explicit 'lit' should resolve to match-lit")
end)

t.test("look at open wardrobe resolves to wardrobe-open", function()
    local verb, noun, score = m:match("look at open wardrobe")
    t.assert_eq("look", verb)
    t.assert_eq("wardrobe-open", noun, "explicit 'open' should resolve to wardrobe-open")
end)

-- =========================================================================
-- Summary
-- =========================================================================
local fail_count = t.summary()
if fail_count > 0 then
    os.exit(1)
end
