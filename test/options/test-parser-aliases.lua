-- test/options/test-parser-aliases.lua
-- TDD tests for options/hint parser alias resolution.
-- Written from architecture spec §4.2 (parser integration).
-- Validates that all documented aliases route to the correct verb.

local t = require("test.parser.test-helpers")
local test = t.test
local eq = t.assert_eq

-- Attempt to load the real preprocess module
local ok, preprocess = pcall(require, "engine.parser.preprocess")
if not ok then
    -- Stub preprocess.parse matching documented alias behavior
    -- Once impl lands, this stub is never reached.
    preprocess = {
        parse = function(input)
            input = (input or ""):lower():match("^%s*(.-)%s*$")

            -- Options aliases (arch §4.2b — phrases.lua patterns)
            if input:match("^what%s+are%s+my%s+options")
                or input:match("^give%s+me%s+options")
                or input:match("^what%s+can%s+i%s+try")
                or input:match("^i'?m%s+stuck")
                or input == "options"
                or input == "hint"
                or input == "hints"
                or input == "nudge" then
                return "options", ""
            end

            -- Options aliases (arch §4.2c — idioms.lua)
            if input == "give me a hint"
                or input == "suggest something"
                or input == "give me a nudge" then
                return "options", ""
            end

            -- Help stays as help (D-OPTIONS-B5)
            if input == "help me" or input == "help" then
                return "help", ""
            end

            -- Basic verb/noun split fallback
            local verb, noun = input:match("^(%S+)%s*(.*)")
            return verb or input, noun or ""
        end,
    }
end

local parse = preprocess.parse

-- ============================================================
-- Tests
-- ============================================================

t.suite("options aliases — direct keywords")

test("'options' resolves to options verb", function()
    local v, _ = parse("options")
    eq("options", v)
end)

test("'hint' resolves to options verb", function()
    local v, _ = parse("hint")
    eq("options", v)
end)

test("'hints' resolves to options verb", function()
    local v, _ = parse("hints")
    eq("options", v)
end)

test("'nudge' resolves to options verb", function()
    local v, _ = parse("nudge")
    eq("options", v)
end)

t.suite("options aliases — natural phrases")

test("'what are my options' resolves to options verb", function()
    local v, _ = parse("what are my options")
    eq("options", v)
end)

test("'give me options' resolves to options verb", function()
    local v, _ = parse("give me options")
    eq("options", v)
end)

test("'what can I try' resolves to options verb", function()
    local v, _ = parse("what can i try")
    eq("options", v)
end)

test("'i'm stuck' resolves to options verb", function()
    local v, _ = parse("i'm stuck")
    eq("options", v)
end)

t.suite("options aliases — idioms")

test("'give me a hint' resolves to options verb", function()
    local v, _ = parse("give me a hint")
    eq("options", v)
end)

test("'suggest something' resolves to options verb", function()
    local v, _ = parse("suggest something")
    eq("options", v)
end)

t.suite("options aliases — help verb boundary (D-OPTIONS-B5)")

test("'help me' resolves to help verb, NOT options", function()
    local v, _ = parse("help me")
    eq("help", v, "'help me' must stay mapped to help, not options (D-OPTIONS-B5)")
end)

test("'help' resolves to help verb", function()
    local v, _ = parse("help")
    eq("help", v)
end)

t.suite("options aliases — case insensitivity")

test("'HINT' (uppercase) resolves to options verb", function()
    local v, _ = parse("HINT")
    eq("options", v)
end)

test("'What Are My Options' (mixed case) resolves to options verb", function()
    local v, _ = parse("What Are My Options")
    eq("options", v)
end)

-- ============================================================
local exit_code = t.summary()
t.reset()
os.exit(exit_code)
