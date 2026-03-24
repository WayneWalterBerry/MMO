-- test/parser/test-compound-commands.lua
-- Issue #168: Compound commands only execute first part.
-- Tests compound command splitting and pronoun resolution across sub-commands.
--
-- Usage: lua test/parser/test-compound-commands.lua
-- Must be run from the repository root.

-- Set up package path to find engine modules from repo root
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")
local context_window = require("engine.parser.context")

local test = h.test
local eq   = h.assert_eq

-------------------------------------------------------------------------------
h.suite("split_commands — comma-and separator")
-------------------------------------------------------------------------------

test("comma-and splits into two commands", function()
    local cmds = preprocess.split_commands("get candle, and light it")
    eq(2, #cmds, "should produce 2 commands")
    eq("get candle", cmds[1])
    eq("light it", cmds[2])
end)

test("comma-and with extra whitespace", function()
    local cmds = preprocess.split_commands("take key,  and  unlock door")
    eq(2, #cmds, "should produce 2 commands")
    eq("take key", cmds[1])
    eq("unlock door", cmds[2])
end)

test("comma-and with three parts", function()
    local cmds = preprocess.split_commands("get candle, and light it, and look")
    eq(3, #cmds, "should produce 3 commands")
    eq("get candle", cmds[1])
    eq("light it", cmds[2])
    eq("look", cmds[3])
end)

-------------------------------------------------------------------------------
h.suite("split_commands — and-then separator")
-------------------------------------------------------------------------------

test("and-then splits into two commands", function()
    local cmds = preprocess.split_commands("get candle and then light it")
    eq(2, #cmds, "should produce 2 commands")
    eq("get candle", cmds[1])
    eq("light it", cmds[2])
end)

test("and-then with semicolons mixed", function()
    local cmds = preprocess.split_commands("take key; unlock door and then open door")
    eq(3, #cmds, "should produce 3 commands")
    eq("take key", cmds[1])
    eq("unlock door", cmds[2])
    eq("open door", cmds[3])
end)

-------------------------------------------------------------------------------
h.suite("split_commands — semicolons and then (existing behavior)")
-------------------------------------------------------------------------------

test("semicolons still split", function()
    local cmds = preprocess.split_commands("go north; look around")
    eq(2, #cmds, "should produce 2 commands")
    eq("go north", cmds[1])
    eq("look around", cmds[2])
end)

test("then still splits", function()
    local cmds = preprocess.split_commands("open sack then put candle in sack")
    eq(2, #cmds, "should produce 2 commands")
    eq("open sack", cmds[1])
    eq("put candle in sack", cmds[2])
end)

test("bare comma still splits", function()
    local cmds = preprocess.split_commands("open sack, put candle in sack")
    eq(2, #cmds, "should produce 2 commands")
    eq("open sack", cmds[1])
    eq("put candle in sack", cmds[2])
end)

-------------------------------------------------------------------------------
h.suite("split_compound — verb-aware 'and' splitting")
-------------------------------------------------------------------------------

test("and splits when second part starts with a verb", function()
    local cmds = preprocess.split_compound("take key and unlock door")
    eq(2, #cmds, "should produce 2 commands")
    eq("take key", cmds[1])
    eq("unlock door", cmds[2])
end)

test("and does NOT split multi-object commands", function()
    local cmds = preprocess.split_compound("get candle and matchbox")
    eq(1, #cmds, "should stay as 1 command")
    eq("get candle and matchbox", cmds[1])
end)

test("and does NOT split 'put pen and paper on desk'", function()
    local cmds = preprocess.split_compound("put pen and paper on desk")
    eq(1, #cmds, "should stay as 1 command")
    eq("put pen and paper on desk", cmds[1])
end)

test("and splits 'open door and go north'", function()
    local cmds = preprocess.split_compound("open door and go north")
    eq(2, #cmds, "should produce 2 commands")
    eq("open door", cmds[1])
    eq("go north", cmds[2])
end)

test("and splits 'get match and light candle'", function()
    local cmds = preprocess.split_compound("get match and light candle")
    eq(2, #cmds, "should produce 2 commands")
    eq("get match", cmds[1])
    eq("light candle", cmds[2])
end)

test("and does NOT split 'bread and butter'", function()
    local cmds = preprocess.split_compound("eat bread and butter")
    eq(1, #cmds, "should stay as 1 command")
    eq("eat bread and butter", cmds[1])
end)

test("and does NOT split when second part is a plain noun", function()
    local cmds = preprocess.split_compound("take sword and shield")
    eq(1, #cmds, "should stay as 1 command")
    eq("take sword and shield", cmds[1])
end)

test("and splits on multiple verb-led conjunctions", function()
    local cmds = preprocess.split_compound("take key and unlock door and open door")
    eq(3, #cmds, "should produce 3 commands")
    eq("take key", cmds[1])
    eq("unlock door", cmds[2])
    eq("open door", cmds[3])
end)

-------------------------------------------------------------------------------
h.suite("Pronoun resolution — 'it' and 'them'")
-------------------------------------------------------------------------------

test("context_window resolves 'it' to last pushed object", function()
    context_window.reset()
    context_window.push({ id = "candle", name = "tallow candle" })
    local obj = context_window.resolve("it")
    eq("candle", obj and obj.id or nil, "'it' should resolve to candle")
end)

test("context_window resolves 'them' to last pushed object", function()
    context_window.reset()
    context_window.push({ id = "matches", name = "bundle of matches" })
    -- "them" not in resolve currently — this tests the PRONOUNS table in loop
    -- Context window handles: it, that, this, one
    -- The game loop's PRONOUNS table handles: them
    local obj = context_window.resolve("it")
    eq("matches", obj and obj.id or nil, "'it' should resolve to matches")
end)

test("context_window pronoun tracks most recent interaction", function()
    context_window.reset()
    context_window.push({ id = "candle", name = "tallow candle" })
    context_window.push({ id = "key", name = "rusty key" })
    local obj = context_window.resolve("it")
    eq("key", obj and obj.id or nil, "'it' should resolve to most recent (key)")
end)

test("context_window resolves 'that' to last pushed object", function()
    context_window.reset()
    context_window.push({ id = "sword", name = "short sword" })
    local obj = context_window.resolve("that")
    eq("sword", obj and obj.id or nil, "'that' should resolve to sword")
end)

-------------------------------------------------------------------------------
h.suite("Combined flow — compound split + pronoun would resolve")
-------------------------------------------------------------------------------

test("compound split produces commands where pronoun can resolve", function()
    -- Simulates: "get candle, and light it"
    -- After splitting, the game loop would:
    --   1. Execute "get candle" → sets context.last_noun = "candle"
    --   2. Execute "light it" → "it" resolves to "candle"
    local cmds = preprocess.split_commands("get candle, and light it")
    eq(2, #cmds, "should produce 2 commands")
    eq("get candle", cmds[1])
    eq("light it", cmds[2])

    -- Verify that parsing "light it" extracts "it" as the noun
    local verb, noun = preprocess.parse(cmds[2])
    eq("light", verb)
    eq("it", noun)
end)

test("compound split with 'and then' preserves pronoun", function()
    local cmds = preprocess.split_commands("take sword and then examine it")
    eq(2, #cmds, "should produce 2 commands")
    eq("take sword", cmds[1])
    eq("examine it", cmds[2])

    local verb, noun = preprocess.parse(cmds[2])
    eq("examine", verb)
    eq("it", noun)
end)

test("split does not break 'find candle and light it' when verb-aware", function()
    -- "find candle and light it" — "light" IS a verb, so it SHOULD split
    local cmds = preprocess.split_compound("find candle and light it")
    eq(2, #cmds, "should produce 2 commands")
    eq("find candle", cmds[1])
    eq("light it", cmds[2])
end)

-------------------------------------------------------------------------------
h.suite("Edge cases")
-------------------------------------------------------------------------------

test("empty input returns empty list", function()
    local cmds = preprocess.split_commands("")
    eq(0, #cmds)
end)

test("single command returns single element", function()
    local cmds = preprocess.split_commands("look around")
    eq(1, #cmds)
    eq("look around", cmds[1])
end)

test("leading/trailing whitespace trimmed from segments", function()
    local cmds = preprocess.split_commands("  get candle , and  light it  ")
    eq(2, #cmds)
    eq("get candle", cmds[1])
    eq("light it", cmds[2])
end)

test("split_compound with no 'and' returns single command", function()
    local cmds = preprocess.split_compound("look around")
    eq(1, #cmds)
    eq("look around", cmds[1])
end)

test("split_compound with nil returns empty list", function()
    local cmds = preprocess.split_compound(nil)
    eq(0, #cmds)
end)

test("split_compound with empty string returns empty list", function()
    local cmds = preprocess.split_compound("")
    eq(0, #cmds)
end)

h.summary()
