-- test/integration/test-kid-friendly-numbers.lua
-- Integration test for Issue #436: number input handling in E-rated worlds

-- Set up package path
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local t = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

print("\n=== TEST: Issue #436 - Number input in E-rated worlds ===")

t.test("plain number 42 returns nil verb", function()
    local verb, noun = preprocess.natural_language("42")
    -- Should return nil (no verb found) — loop.lua handles this
    t.assert_nil(verb, "plain number should not parse to a verb")
end)

t.test("plain number 210 returns nil verb", function()
    local verb, noun = preprocess.natural_language("210")
    t.assert_nil(verb, "plain number should not parse to a verb")
end)

t.test("type 210 parses to type verb", function()
    -- Use parse() directly since natural_language() may not handle type yet
    local verb, noun = preprocess.parse("type 210")
    t.assert_eq("type", verb, "type 210 should parse to type verb")
    t.assert_eq("210", noun, "type 210 should have 210 as noun")
end)

t.test("input 42 parses to input verb", function()
    local verb, noun = preprocess.parse("input 42")
    t.assert_eq("input", verb, "input 42 should parse to input verb")
    t.assert_eq("42", noun, "input 42 should have 42 as noun")
end)

t.summary()
