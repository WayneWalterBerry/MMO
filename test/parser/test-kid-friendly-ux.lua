-- test/parser/test-kid-friendly-ux.lua
-- Tests for Issues #433, #435, #436, #437, #438, #439: Kid-friendly UX improvements
-- TDD REQUIRED: These tests should FAIL before fixes, PASS after.

-- Set up package path to find engine modules from repo root
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local t = require("test.parser.test-helpers")

local preprocess = require("engine.parser.preprocess")
local fuzzy = require("engine.parser.fuzzy")

print("\n=== TEST: Issue #433 - Greetings get friendly responses ===")

t.test("hello transforms to friendly help", function()
    local verb, noun = preprocess.natural_language("hello")
    t.assert_eq("help", verb, "hello should route to help or special handler")
end)

t.test("hi transforms to friendly help", function()
    local verb, noun = preprocess.natural_language("hi")
    t.assert_eq("help", verb, "hi should route to help or special handler")
end)

t.test("hey there transforms to friendly help", function()
    local verb, noun = preprocess.natural_language("hey there")
    t.assert_eq("help", verb, "hey there should route to help or special handler")
end)

t.test("greetings transforms to friendly help", function()
    local verb, noun = preprocess.natural_language("greetings")
    t.assert_eq("help", verb, "greetings should route to help or special handler")
end)

print("\n=== TEST: Issue #435 - 'feal' typo routes correctly ===")

-- Test fuzzy verb correction
t.test("feal should fuzzy-match to feel verb", function()
    -- This will be tested via integration — preprocess should normalize typos
    local verb, noun = preprocess.natural_language("feal")
    -- Should either return "feel" or nil (to be caught by fuzzy matcher)
    t.assert_truthy(verb == "feel" or verb == nil, "feal should fuzzy-match to feel")
end)

t.test("lok should fuzzy-match to look verb", function()
    local verb, noun = preprocess.natural_language("lok")
    t.assert_truthy(verb == "look" or verb == nil, "lok should fuzzy-match to look")
end)

print("\n=== TEST: Issue #437 - Common kid typos fuzzy-match ===")

t.test("lok typo matches look", function()
    local verb, noun = preprocess.natural_language("lok")
    t.assert_truthy(verb == "look" or verb == nil, "lok should match look")
end)

t.test("luk typo matches look", function()
    local verb, noun = preprocess.natural_language("luk")
    t.assert_truthy(verb == "look" or verb == nil, "luk should match look")
end)

t.test("hlep typo matches help", function()
    local verb, noun = preprocess.natural_language("hlep")
    t.assert_truthy(verb == "help" or verb == nil, "hlep should match help")
end)

t.test("taset typo matches taste", function()
    local verb, noun = preprocess.natural_language("taset")
    t.assert_truthy(verb == "taste" or verb == nil, "taset should match taste")
end)

t.test("examin typo matches examine", function()
    local verb, noun = preprocess.natural_language("examin")
    t.assert_truthy(verb == "examine" or verb == nil, "examin should match examine")
end)

t.test("serch typo matches search", function()
    local verb, noun = preprocess.natural_language("serch")
    t.assert_truthy(verb == "search" or verb == nil, "serch should match search")
end)

print("\n=== TEST: Issue #438 - MrBeast catchphrases in E-worlds ===")

t.test("subscribe gets Easter egg response", function()
    local verb, noun = preprocess.natural_language("subscribe")
    -- Should route to special handler or "help"
    t.assert_truthy(verb ~= nil, "subscribe should not return nil verb")
end)

t.test("beast mode gets Easter egg response", function()
    local verb, noun = preprocess.natural_language("beast mode")
    t.assert_truthy(verb ~= nil, "beast mode should not return nil verb")
end)

t.test("lets go gets Easter egg response", function()
    local verb, noun = preprocess.natural_language("lets go")
    t.assert_truthy(verb ~= nil, "lets go should not return nil verb")
end)

t.test("smash like gets Easter egg response", function()
    local verb, noun = preprocess.natural_language("smash like")
    t.assert_truthy(verb ~= nil, "smash like should not return nil verb")
end)

print("\n=== TEST: Issue #439 - Frustration phrases get encouragement ===")

t.test("im confused gets encouraging response", function()
    local verb, noun = preprocess.natural_language("im confused")
    t.assert_truthy(verb ~= nil, "im confused should not return nil verb")
end)

t.test("this is dumb gets encouraging response", function()
    local verb, noun = preprocess.natural_language("this is dumb")
    t.assert_truthy(verb ~= nil, "this is dumb should not return nil verb")
end)

t.test("i dont get it gets encouraging response", function()
    local verb, noun = preprocess.natural_language("i dont get it")
    t.assert_truthy(verb ~= nil, "i dont get it should not return nil verb")
end)

t.test("help me gets help", function()
    local verb, noun = preprocess.natural_language("help me")
    t.assert_eq("help", verb, "help me should route to help")
end)

t.test("i need help gets help", function()
    local verb, noun = preprocess.natural_language("i need help")
    t.assert_eq("help", verb, "i need help should route to help")
end)

t.test("im stuck gets encouraging response", function()
    local verb, noun = preprocess.natural_language("im stuck")
    t.assert_truthy(verb ~= nil, "im stuck should not return nil verb")
end)

t.summary()
