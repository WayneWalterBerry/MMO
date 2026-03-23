-- test/parser/test-pass038-phrase-routing.lua
-- Regression tests for Pass-038 phrase routing bugs (#35-39).
-- Tests natural language phrases for health, injuries, inventory, appearance,
-- and wait routing through the parser preprocessing pipeline.
--
-- Bug IDs tested: BUG-127, BUG-128, BUG-129, BUG-130, BUG-131

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test = h.test
local eq   = h.assert_eq

-------------------------------------------------------------------------------
h.suite("1. HEALTH STATUS QUERIES — #35 (BUG-127)")
-------------------------------------------------------------------------------

test("BUG-127: 'status' → health", function()
    local v, n = preprocess.natural_language("status")
    eq("health", v, "Should route 'status' to health verb")
    eq("", n, "Should have no noun")
end)

test("BUG-127: 'how am I' → health", function()
    local v, n = preprocess.natural_language("how am I")
    eq("health", v, "Should route 'how am I' to health verb")
end)

test("BUG-127: 'how am I doing' → health", function()
    local v, n = preprocess.natural_language("how am I doing")
    eq("health", v, "Should route 'how am I doing' to health verb")
end)

test("BUG-127: 'am I hurt?' → health", function()
    local v, n = preprocess.natural_language("am I hurt?")
    eq("health", v, "Should route 'am I hurt?' to health verb")
end)

test("BUG-127: 'am I injured?' → health", function()
    local v, n = preprocess.natural_language("am I injured?")
    eq("health", v, "Should route 'am I injured?' to health verb")
end)

test("BUG-127: 'what's wrong with me?' → health", function()
    local v, n = preprocess.natural_language("what's wrong with me?")
    eq("health", v, "Should route 'what's wrong with me?' to health verb")
end)

test("BUG-127: 'what is wrong with me' → health", function()
    local v, n = preprocess.natural_language("what is wrong with me")
    eq("health", v, "Should route 'what is wrong with me' to health verb")
end)

test("BUG-127: 'check my wounds' → health", function()
    local v, n = preprocess.natural_language("check my wounds")
    eq("health", v, "Should route 'check my wounds' to health verb")
end)

test("BUG-127: 'check my injuries' → health", function()
    local v, n = preprocess.natural_language("check my injuries")
    eq("health", v, "Should route 'check my injuries' to health verb")
end)

test("BUG-127: 'check my health' → health", function()
    local v, n = preprocess.natural_language("check my health")
    eq("health", v, "Should route 'check my health' to health verb")
end)

test("BUG-127: 'am I ok?' → health", function()
    local v, n = preprocess.natural_language("am I ok?")
    eq("health", v, "Should route 'am I ok?' to health verb")
end)

test("BUG-127: 'am I alright?' → health", function()
    local v, n = preprocess.natural_language("am I alright?")
    eq("health", v, "Should route 'am I alright?' to health verb")
end)

-------------------------------------------------------------------------------
h.suite("2. BLEEDING/SEVERITY QUERIES — #36 (BUG-128)")
-------------------------------------------------------------------------------

test("BUG-128: 'Where am I bleeding from?' → injuries", function()
    local v, n = preprocess.natural_language("Where am I bleeding from?")
    eq("injuries", v, "Should route bleeding location query to injuries")
end)

test("BUG-128: 'where am I bleeding' → injuries", function()
    local v, n = preprocess.natural_language("where am I bleeding")
    eq("injuries", v, "Should route bleeding query to injuries")
end)

test("BUG-128: 'How bad is it?' → injuries", function()
    local v, n = preprocess.natural_language("How bad is it?")
    eq("injuries", v, "Should route severity query to injuries")
end)

test("BUG-128: 'why don't I feel well?' → injuries", function()
    local v, n = preprocess.natural_language("why don't I feel well?")
    eq("injuries", v, "Should route feeling query to injuries")
end)

test("BUG-128: 'why dont I feel well' → injuries", function()
    local v, n = preprocess.natural_language("why dont I feel well")
    eq("injuries", v, "Should handle missing apostrophe")
end)

test("BUG-128: 'how bad are my injuries' → injuries", function()
    local v, n = preprocess.natural_language("how bad are my injuries")
    eq("injuries", v, "Should route 'how bad are' query to injuries")
end)

test("BUG-128 regression: 'where am I' still routes to look", function()
    local v, n = preprocess.natural_language("where am I")
    eq("look", v, "Generic 'where am I' must still route to look")
end)

test("BUG-128 regression: 'where am I?' still routes to look", function()
    local v, n = preprocess.natural_language("where am I?")
    eq("look", v, "Generic 'where am I?' must still route to look")
end)

-------------------------------------------------------------------------------
h.suite("3. SELF-REFERENTIAL EXAMINE → APPEARANCE — #37 (BUG-129)")
-------------------------------------------------------------------------------

test("BUG-129: 'look at myself' → appearance", function()
    local v, n = preprocess.natural_language("look at myself")
    eq("appearance", v, "Should route self-examine to appearance")
end)

test("BUG-129: 'look at self' → appearance", function()
    local v, n = preprocess.natural_language("look at self")
    eq("appearance", v, "Should route self-examine to appearance")
end)

test("BUG-129: 'look at me' → appearance", function()
    local v, n = preprocess.natural_language("look at me")
    eq("appearance", v, "Should route self-examine to appearance")
end)

test("BUG-129: 'examine myself' → appearance", function()
    local v, n = preprocess.natural_language("examine myself")
    eq("appearance", v, "Should route self-examine to appearance")
end)

test("BUG-129: 'examine self' → appearance", function()
    local v, n = preprocess.natural_language("examine self")
    eq("appearance", v, "Should route self-examine to appearance")
end)

test("BUG-129: 'examine me' → appearance", function()
    local v, n = preprocess.natural_language("examine me")
    eq("appearance", v, "Should route self-examine to appearance")
end)

test("BUG-129: 'check myself' → appearance", function()
    local v, n = preprocess.natural_language("check myself")
    eq("appearance", v, "Should route self-check to appearance")
end)

test("BUG-129: 'check self' → appearance", function()
    local v, n = preprocess.natural_language("check self")
    eq("appearance", v, "Should route self-check to appearance")
end)

test("BUG-129 regression: 'look at nightstand' still works", function()
    local v, n = preprocess.natural_language("look at nightstand")
    eq("examine", v, "Generic look-at must still route to examine")
    eq("nightstand", n, "Should keep target noun")
end)

test("BUG-129 regression: 'examine nightstand' still works", function()
    local v, n = preprocess.parse("examine nightstand")
    eq("examine", v, "Generic examine must still parse as examine verb")
    eq("nightstand", n, "Should keep target noun")
end)

-------------------------------------------------------------------------------
h.suite("4. HAND/HOLDING INVENTORY QUERIES — #38 (BUG-130)")
-------------------------------------------------------------------------------

test("BUG-130: 'what's in my hands?' → inventory", function()
    local v, n = preprocess.natural_language("what's in my hands?")
    eq("inventory", v, "Should route hand query to inventory")
end)

test("BUG-130: 'what is in my hands' → inventory", function()
    local v, n = preprocess.natural_language("what is in my hands")
    eq("inventory", v, "Should route hand query to inventory")
end)

test("BUG-130: 'am I holding anything?' → inventory", function()
    local v, n = preprocess.natural_language("am I holding anything?")
    eq("inventory", v, "Should route holding query to inventory")
end)

test("BUG-130: 'am I holding something?' → inventory", function()
    local v, n = preprocess.natural_language("am I holding something?")
    eq("inventory", v, "Should route holding query to inventory")
end)

test("BUG-130: 'look at my hands' → inventory", function()
    local v, n = preprocess.natural_language("look at my hands")
    eq("inventory", v, "Should route hand look to inventory")
end)

test("BUG-130 regression: 'what am I carrying?' still works", function()
    local v, n = preprocess.natural_language("what am I carrying?")
    eq("inventory", v, "Existing inventory phrases must still work")
end)

test("BUG-130 regression: 'what am I holding?' still works", function()
    local v, n = preprocess.natural_language("what am I holding?")
    eq("inventory", v, "Existing inventory phrases must still work")
end)

test("BUG-130 regression: 'what do I have?' still works", function()
    local v, n = preprocess.natural_language("what do I have?")
    eq("inventory", v, "Existing inventory phrases must still work")
end)

-------------------------------------------------------------------------------
h.suite("5. WAIT AND APPEARANCE STANDALONE — #39 (BUG-131)")
-------------------------------------------------------------------------------

test("BUG-131: 'wait' parses as verb=wait", function()
    local v, n = preprocess.parse("wait")
    eq("wait", v, "Should parse 'wait' as wait verb")
    eq("", n, "Should have no noun")
end)

test("BUG-131: 'appearance' parses as verb=appearance", function()
    local v, n = preprocess.parse("appearance")
    eq("appearance", v, "Should parse 'appearance' as appearance verb")
    eq("", n, "Should have no noun")
end)

-------------------------------------------------------------------------------
h.suite("6. EXISTING BEHAVIOUR REGRESSIONS")
-------------------------------------------------------------------------------

test("Regression: 'health' still works", function()
    local v, n = preprocess.parse("health")
    eq("health", v, "Direct 'health' verb must still parse")
end)

test("Regression: 'injuries' still works", function()
    local v, n = preprocess.parse("injuries")
    eq("injuries", v, "Direct 'injuries' verb must still parse")
end)

test("Regression: 'inventory' still works", function()
    local v, n = preprocess.parse("inventory")
    eq("inventory", v, "Direct 'inventory' verb must still parse")
end)

test("Regression: 'what's in the wardrobe' still routes to examine", function()
    local v, n = preprocess.natural_language("what's in the wardrobe")
    eq("examine", v, "Container queries must still work")
end)

test("Regression: 'check the nightstand' → examine nightstand", function()
    local v, n = preprocess.natural_language("check the nightstand")
    eq("examine", v, "check X must still route to examine")
end)

local fail_count = h.summary()
os.exit(fail_count > 0 and 1 or 0)
