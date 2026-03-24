-- test/parser/test-hit-synonyms.lua
-- TDD tests for hit synonym cluster: #142, #157, #143, #141, #146
-- Covers: smack, bang, slap, whack, headbutt, bonk→head default,
--         toss/throw as drop synonyms.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test = h.test
local eq   = h.assert_eq

-------------------------------------------------------------------------------
h.suite("Hit synonyms — smack (#142)")
-------------------------------------------------------------------------------

test("'smack my head' → hit head", function()
    local v, n = preprocess.natural_language("smack my head")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

test("'smack myself' → hit self", function()
    local v, n = preprocess.natural_language("smack myself")
    eq("hit", v, "verb")
    eq("myself", n, "noun")
end)

-------------------------------------------------------------------------------
h.suite("Hit synonyms — bang (#142)")
-------------------------------------------------------------------------------

test("'bang my head' → hit head", function()
    local v, n = preprocess.natural_language("bang my head")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

-------------------------------------------------------------------------------
h.suite("Hit synonyms — slap (#142, #157)")
-------------------------------------------------------------------------------

test("'slap myself' → hit myself", function()
    local v, n = preprocess.natural_language("slap myself")
    eq("hit", v, "verb")
    eq("myself", n, "noun")
end)

test("'slap my head' → hit head", function()
    local v, n = preprocess.natural_language("slap my head")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

-------------------------------------------------------------------------------
h.suite("Hit synonyms — whack (#157)")
-------------------------------------------------------------------------------

test("'whack my head' → hit head", function()
    local v, n = preprocess.natural_language("whack my head")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

test("'whack myself' → hit myself", function()
    local v, n = preprocess.natural_language("whack myself")
    eq("hit", v, "verb")
    eq("myself", n, "noun")
end)

-------------------------------------------------------------------------------
h.suite("Hit synonyms — headbutt (#143)")
-------------------------------------------------------------------------------

test("'headbutt the wall' → hit head", function()
    local v, n = preprocess.natural_language("headbutt the wall")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

test("'headbutt myself' → hit head", function()
    local v, n = preprocess.natural_language("headbutt myself")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

test("bare 'headbutt' → hit head", function()
    local v, n = preprocess.natural_language("headbutt")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

-------------------------------------------------------------------------------
h.suite("Bonk defaults to head (#146)")
-------------------------------------------------------------------------------

test("'bonk myself' → hit head (not random)", function()
    local v, n = preprocess.natural_language("bonk myself")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

test("'bonk self' → hit head", function()
    local v, n = preprocess.natural_language("bonk self")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

test("'bonk my head' → hit head (explicit head preserved)", function()
    local v, n = preprocess.natural_language("bonk my head")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

test("'bonk my arm' → hit arm (explicit body part preserved)", function()
    local v, n = preprocess.natural_language("bonk my arm")
    eq("hit", v, "verb")
    eq("arm", n, "noun")
end)

test("bare 'bonk' → hit head", function()
    local v, n = preprocess.natural_language("bonk")
    eq("hit", v, "verb")
    eq("head", n, "noun")
end)

-------------------------------------------------------------------------------
h.suite("Drop synonyms — toss/throw (#141)")
-------------------------------------------------------------------------------

test("'toss hat' → drop hat", function()
    local v, n = preprocess.natural_language("toss hat")
    eq("drop", v, "verb")
    eq("hat", n, "noun")
end)

test("'throw hat' → drop hat", function()
    local v, n = preprocess.natural_language("throw hat")
    eq("drop", v, "verb")
    eq("hat", n, "noun")
end)

test("'throw hat on ground' → drop hat", function()
    local v, n = preprocess.natural_language("throw hat on ground")
    eq("drop", v, "verb")
    eq("hat", n, "noun")
end)

test("'throw hat on the ground' → drop hat", function()
    local v, n = preprocess.natural_language("throw hat on the ground")
    eq("drop", v, "verb")
    eq("hat", n, "noun")
end)

test("'toss hat on the floor' → drop hat", function()
    local v, n = preprocess.natural_language("toss hat on the floor")
    eq("drop", v, "verb")
    eq("hat", n, "noun")
end)

-- Placement variants should still route to put (not drop)
test("'toss hat on table' → put hat on table (placement preserved)", function()
    local v, n = preprocess.natural_language("toss hat on table")
    eq("put", v, "verb")
    eq("hat on table", n, "noun")
end)

test("'throw hat in box' → put hat in box (placement preserved)", function()
    local v, n = preprocess.natural_language("throw hat in box")
    eq("put", v, "verb")
    eq("hat in box", n, "noun")
end)

-------------------------------------------------------------------------------
h.suite("Regression — existing hit aliases still work")
-------------------------------------------------------------------------------

test("'hit head' still works", function()
    local v, n = preprocess.parse("hit head")
    eq("hit", v)
    eq("head", n)
end)

test("'punch myself' still works", function()
    local v, n = preprocess.parse("punch myself")
    eq("punch", v)
    eq("myself", n)
end)

test("'bash my head' via natural_language still works", function()
    local v, n = preprocess.natural_language("bash my head")
    -- bash goes through strip_possessives → "bash head"
    eq("bash", v)
    eq("head", n)
end)

-------------------------------------------------------------------------------
h.suite("Regression — drop still works")
-------------------------------------------------------------------------------

test("'drop hat' stays as drop", function()
    local v, n = preprocess.parse("drop hat")
    eq("drop", v)
    eq("hat", n)
end)

test("'put down hat' → drop hat (idiom)", function()
    local v, n = preprocess.natural_language("put down hat")
    eq("drop", v)
    eq("hat", n)
end)

local exit_code = h.summary()
os.exit(exit_code)
