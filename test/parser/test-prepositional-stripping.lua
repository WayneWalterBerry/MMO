-- test/parser/test-prepositional-stripping.lua
-- TDD tests for Issue #154: Prepositional suffixes corrupt item resolution.
--
-- Bug: trailing prepositional phrases ("on my head", "in the mirror",
-- "from head", "as a hat", "on the floor") corrupt the noun before it
-- reaches item resolution, causing look/wear/remove/drop to fail.
--
-- Fix target: src/engine/parser/preprocess.lua pipeline stage.

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
h.suite("1. BODY-PART SUFFIXES — 'on my head' / 'on head' (#154)")
-------------------------------------------------------------------------------

test("'wear blanket on my head' → verb=wear, noun=blanket", function()
    local v, n = preprocess.natural_language("wear blanket on my head")
    eq("wear", v, "verb should be wear")
    eq("blanket", n, "noun should be blanket (strip 'on my head')")
end)

test("'wear pot on head' → verb=wear, noun=pot", function()
    local v, n = preprocess.natural_language("wear pot on head")
    eq("wear", v, "verb should be wear")
    eq("pot", n, "noun should be pot (strip 'on head')")
end)

test("'wear pot as a hat' → verb=wear, noun=pot", function()
    local v, n = preprocess.natural_language("wear pot as a hat")
    eq("wear", v, "verb should be wear")
    eq("pot", n, "noun should be pot (strip 'as a hat')")
end)

test("'wear scarf as an accessory' → verb=wear, noun=scarf", function()
    local v, n = preprocess.natural_language("wear scarf as an accessory")
    eq("wear", v, "verb should be wear")
    eq("scarf", n, "noun should be scarf (strip 'as an accessory')")
end)

-------------------------------------------------------------------------------
h.suite("2. REMOVE + 'from' SUFFIX (#154)")
-------------------------------------------------------------------------------

test("'remove pot from head' → verb=remove, noun=pot", function()
    local v, n = preprocess.natural_language("remove pot from head")
    eq("remove", v, "verb should be remove")
    eq("pot", n, "noun should be pot (strip 'from head')")
end)

test("'remove pot from my head' → verb=remove, noun=pot", function()
    local v, n = preprocess.natural_language("remove pot from my head")
    eq("remove", v, "verb should be remove")
    eq("pot", n, "noun should be pot (strip 'from my head')")
end)

test("'remove helmet from my shoulders' → verb=remove, noun=helmet", function()
    local v, n = preprocess.natural_language("remove helmet from my shoulders")
    eq("remove", v, "verb should be remove")
    eq("helmet", n, "noun should be helmet (strip 'from my shoulders')")
end)

-------------------------------------------------------------------------------
h.suite("3. LOOK AT SELF 'in the mirror' (#154)")
-------------------------------------------------------------------------------

test("'look at myself in the mirror' → appearance", function()
    local v, n = preprocess.natural_language("look at myself in the mirror")
    eq("appearance", v, "verb should be appearance (self-referential)")
    eq("", n, "noun should be empty")
end)

test("'look at myself in mirror' → appearance", function()
    local v, n = preprocess.natural_language("look at myself in mirror")
    eq("appearance", v, "verb should be appearance")
    eq("", n, "noun should be empty")
end)

test("'look at myself in the reflection' → appearance", function()
    local v, n = preprocess.natural_language("look at myself in the reflection")
    eq("appearance", v, "verb should be appearance")
    eq("", n, "noun should be empty")
end)

-------------------------------------------------------------------------------
h.suite("4. DROP + 'on the floor/ground' (#154)")
-------------------------------------------------------------------------------

test("'drop knife on the floor' → verb=drop, noun=knife", function()
    local v, n = preprocess.natural_language("drop knife on the floor")
    eq("drop", v, "verb should be drop")
    eq("knife", n, "noun should be knife (strip 'on the floor')")
end)

test("'drop knife on floor' → verb=drop, noun=knife", function()
    local v, n = preprocess.natural_language("drop knife on floor")
    eq("drop", v, "verb should be drop")
    eq("knife", n, "noun should be knife (strip 'on floor')")
end)

test("'drop knife on the ground' → verb=drop, noun=knife", function()
    local v, n = preprocess.natural_language("drop knife on the ground")
    eq("drop", v, "verb should be drop")
    eq("knife", n, "noun should be knife (strip 'on the ground')")
end)

-------------------------------------------------------------------------------
h.suite("5. PUT + body part → WEAR routing (#154)")
-------------------------------------------------------------------------------

test("'put pot on my head' → verb=wear, noun=pot", function()
    local v, n = preprocess.natural_language("put pot on my head")
    eq("wear", v, "verb should be wear (put on body part)")
    eq("pot", n, "noun should be pot")
end)

test("'put pot on head' → verb=wear, noun=pot", function()
    local v, n = preprocess.natural_language("put pot on head")
    eq("wear", v, "verb should be wear (put on body part)")
    eq("pot", n, "noun should be pot")
end)

test("'put blanket on my shoulders' → verb=wear, noun=blanket", function()
    local v, n = preprocess.natural_language("put blanket on my shoulders")
    eq("wear", v, "verb should be wear")
    eq("blanket", n, "noun should be blanket")
end)

-------------------------------------------------------------------------------
h.suite("6. COMPOUND TARGETS PRESERVED — no stripping (#154)")
-------------------------------------------------------------------------------

test("'put match in the matchbox' → compound preserved", function()
    local v, n = preprocess.natural_language("put match in the matchbox")
    if not v then
        v, n = preprocess.parse("put match in the matchbox")
    end
    eq("put", v, "verb should be put (compound target kept)")
    truthy(n and n:find("match"), "noun should contain 'match'")
    truthy(n and n:find("matchbox"), "noun should contain 'matchbox'")
end)

test("'put book on table' → compound preserved (table is furniture)", function()
    local v, n = preprocess.natural_language("put book on table")
    if not v then
        v, n = preprocess.parse("put book on table")
    end
    eq("put", v, "verb should be put (table is furniture, not body)")
    truthy(n and n:find("table"), "noun should contain 'table'")
end)

test("'put sword in chest' → compound preserved (chest is furniture)", function()
    local v, n = preprocess.natural_language("put sword in chest")
    if not v then
        v, n = preprocess.parse("put sword in chest")
    end
    eq("put", v, "verb should be put (chest is container, not body)")
    truthy(n and n:find("chest"), "noun should contain 'chest'")
end)

test("'look in drawer' → still works (functional preposition)", function()
    local v, n = preprocess.natural_language("look in drawer")
    if not v then
        v, n = preprocess.parse("look in drawer")
    end
    -- "look in drawer" may transform or pass through; should NOT strip "in drawer"
    truthy(v ~= nil, "verb should not be nil")
end)

-------------------------------------------------------------------------------
h.suite("7. REGRESSION — standard commands unaffected (#154)")
-------------------------------------------------------------------------------

test("'wear gloves' → verb=wear, noun=gloves (no preposition)", function()
    local v, n = preprocess.natural_language("wear gloves")
    if not v then v, n = preprocess.parse("wear gloves") end
    eq("wear", v)
    eq("gloves", n)
end)

test("'remove helmet' → verb=remove, noun=helmet (no preposition)", function()
    local v, n = preprocess.natural_language("remove helmet")
    if not v then v, n = preprocess.parse("remove helmet") end
    eq("remove", v)
    eq("helmet", n)
end)

test("'drop knife' → verb=drop, noun=knife (no preposition)", function()
    local v, n = preprocess.natural_language("drop knife")
    if not v then v, n = preprocess.parse("drop knife") end
    eq("drop", v)
    eq("knife", n)
end)

test("'look at nightstand' → examine nightstand (regression)", function()
    local v, n = preprocess.natural_language("look at nightstand")
    eq("examine", v)
    eq("nightstand", n)
end)

test("'take off gloves' → remove gloves (regression)", function()
    local v, n = preprocess.natural_language("take off gloves")
    eq("remove", v)
    eq("gloves", n)
end)

test("'put on gloves' → wear gloves (regression)", function()
    local v, n = preprocess.natural_language("put on gloves")
    eq("wear", v)
    eq("gloves", n)
end)

test("'examine mirror' → verb=examine, noun=mirror (no stripping)", function()
    local v, n = preprocess.natural_language("examine mirror")
    if not v then v, n = preprocess.parse("examine mirror") end
    eq("examine", v)
    eq("mirror", n)
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
