-- test/parser/test-pass027-bugs.lua
-- Regression tests for the 6 remaining bugs from Pass 027 (2026-03-22).
-- These inputs previously caused hangs due to compound/prepositional phrases
-- that didn't cleanly reduce to verb+target in the preprocessing pipeline.
--
-- Bug IDs tested: BUG-082, BUG-083, BUG-084, BUG-091, BUG-093, BUG-094

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
-- Helper: simulate loop's compound split (commas/semicolons/then, then "and")
-------------------------------------------------------------------------------
local function split_compound(input)
    local trimmed = input:match("^%s*(.-)%s*$")
    trimmed = trimmed:gsub("%?+$", ""):match("^%s*(.-)%s*$")
    local parts = preprocess.split_commands(trimmed)
    local sub_commands = {}
    for _, part in ipairs(parts) do
        local remaining = part
        local safety = 0
        while true do
            safety = safety + 1
            if safety > 100 then break end
            local before, after = remaining:match("^(.-)%s+and%s+(.+)$")
            if before and after then
                local b = before:match("^%s*(.-)%s*$")
                if b ~= "" then sub_commands[#sub_commands+1] = b end
                remaining = after
            else
                local r = remaining:match("^%s*(.-)%s*$")
                if r ~= "" then sub_commands[#sub_commands+1] = r end
                break
            end
        end
    end
    return sub_commands
end

--- Preprocess a single sub-command: NL first, then parse fallback
local function preprocess_cmd(input)
    local v, n = preprocess.natural_language(input)
    if not v then v, n = preprocess.parse(input) end
    return v, n
end

-------------------------------------------------------------------------------
h.suite("1. BUG-082: 'search the drawer for a match' — scoped X-for-Y")
-------------------------------------------------------------------------------

test("BUG-082: preprocess 'search the drawer for a match' → search, drawer for match", function()
    local v, n = preprocess.natural_language("search the drawer for a match")
    eq("search", v, "Should return search verb")
    truthy(n:find("drawer"), "Should contain 'drawer' in noun: " .. tostring(n))
    truthy(n:find("match"), "Should contain 'match' in noun: " .. tostring(n))
end)

test("BUG-082: articles stripped from both scope and target", function()
    local v, n = preprocess.natural_language("search the drawer for a match")
    eq("search", v)
    -- After article stripping, should be "drawer for match" (no "the"/"a")
    truthy(not n:match("^the%s"), "Leading 'the' should be stripped")
    truthy(not n:find(" a "), "'a' article should be stripped from target")
end)

test("BUG-082: 'search nightstand for candle' → search, nightstand for candle", function()
    local v, n = preprocess.natural_language("search nightstand for candle")
    eq("search", v)
    truthy(n:find("nightstand"), "Should contain scope 'nightstand'")
    truthy(n:find("candle"), "Should contain target 'candle'")
end)

test("BUG-082: 'search the bed for a knife' → search, bed for knife", function()
    local v, n = preprocess.natural_language("search the bed for a knife")
    eq("search", v)
    truthy(n:find("bed"), "Should contain scope 'bed'")
    truthy(n:find("knife"), "Should contain target 'knife'")
end)

test("BUG-082: does NOT hang (completes in bounded time)", function()
    -- The key regression: this input must complete, not enter infinite recursion
    local completed = false
    local v, n = preprocess.natural_language("search the drawer for a match")
    completed = (v ~= nil)
    truthy(completed, "Preprocessing should complete without hanging")
end)

-------------------------------------------------------------------------------
h.suite("2. BUG-083: 'could you search for matches' — politeness + compound")
-------------------------------------------------------------------------------

test("BUG-083: 'could you search for matches' → search, match (BUG-111: singularized)", function()
    local v, n = preprocess.natural_language("could you search for matches")
    eq("search", v, "Should strip 'could you' and parse 'search for matches'")
    eq("match", n, "Should singularize 'matches' to 'match' (BUG-111)")
end)

test("BUG-083: 'please search for the matchbox' → search, matchbox", function()
    local v, n = preprocess.natural_language("please search for the matchbox")
    eq("search", v)
    eq("matchbox", n, "Article 'the' should be stripped")
end)

test("BUG-083: 'would you search for a candle' → search, candle", function()
    local v, n = preprocess.natural_language("would you search for a candle")
    eq("search", v, "Should strip 'would you'")
    eq("candle", n, "Article 'a' should be stripped")
end)

test("BUG-083: 'can you find the key' → find, key", function()
    local v, n = preprocess.natural_language("can you find the key")
    eq("find", v, "Should strip 'can you'")
    eq("key", n, "Article 'the' should be stripped")
end)

test("BUG-083: 'could you look for matches' → find, match (BUG-111: singularized)", function()
    local v, n = preprocess.natural_language("could you look for matches")
    eq("find", v, "Should strip 'could you' and convert 'look for' to 'find'")
    eq("match", n)
end)

test("BUG-083: does NOT hang", function()
    local v, n = preprocess.natural_language("could you search for matches")
    truthy(v ~= nil, "Should return a verb without hanging")
end)

-------------------------------------------------------------------------------
h.suite("3. BUG-084: 'find a match and light it' — compound X and Y")
-------------------------------------------------------------------------------

test("BUG-084: compound splits into two sub-commands", function()
    local subs = split_compound("find a match and light it")
    eq(2, #subs, "Should split into exactly 2 sub-commands")
    eq("find a match", subs[1], "First sub-command")
    eq("light it", subs[2], "Second sub-command")
end)

test("BUG-084: 'find a match' preprocesses with article stripped", function()
    local v, n = preprocess_cmd("find a match")
    eq("find", v, "Should be find verb")
    eq("match", n, "Article 'a' should be stripped")
end)

test("BUG-084: 'light it' preprocesses to light, it", function()
    local v, n = preprocess_cmd("light it")
    eq("light", v, "Should be light verb")
    eq("it", n, "Should preserve pronoun 'it'")
end)

test("BUG-084: 'take a match and strike it' splits correctly", function()
    local subs = split_compound("take a match and strike it")
    eq(2, #subs)
    eq("take a match", subs[1])
    eq("strike it", subs[2])
end)

test("BUG-084: 'find a match and light it' does NOT hang", function()
    local subs = split_compound("find a match and light it")
    local all_ok = true
    for _, sc in ipairs(subs) do
        local v, n = preprocess_cmd(sc)
        if not v then all_ok = false end
    end
    truthy(all_ok, "All sub-commands should preprocess without hanging")
end)

test("BUG-084: article stripping works on each compound fragment", function()
    local subs = split_compound("find a candle and light it")
    local v1, n1 = preprocess_cmd(subs[1])
    eq("find", v1)
    eq("candle", n1, "Article 'a' should be stripped from 'find a candle' fragment")
end)

test("BUG-084: 'open the matchbox and take a match' splits and strips", function()
    local subs = split_compound("open the matchbox and take a match")
    eq(2, #subs)
    eq("open the matchbox", subs[1])
    eq("take a match", subs[2])
end)

-------------------------------------------------------------------------------
h.suite("4. BUG-091: 'take match' — spent vs fresh match priority")
-------------------------------------------------------------------------------

test("BUG-091: match object has terminal state 'spent'", function()
    -- Verify the match definition has the right FSM structure
    local match_def = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/match.lua")
    truthy(match_def.states, "Match should have states table")
    truthy(match_def.states.spent, "Match should have 'spent' state")
    truthy(match_def.states.spent.terminal, "'spent' state should be terminal")
end)

test("BUG-091: match 'spent' state is consumable", function()
    local match_def = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/match.lua")
    truthy(match_def.states.spent.consumable, "'spent' state should be consumable")
end)

test("BUG-091: match 'unlit' state is NOT terminal", function()
    local match_def = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/match.lua")
    truthy(not match_def.states.unlit.terminal,
           "'unlit' state should not be terminal")
end)

test("BUG-091: match 'lit' state is NOT terminal", function()
    local match_def = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/match.lua")
    truthy(not match_def.states.lit.terminal,
           "'lit' state should not be terminal")
end)

test("BUG-091: matchbox has accessible flag (open vs closed)", function()
    local mb_closed = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/matchbox.lua")
    local mb_open = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/matchbox-open.lua")
    eq(false, mb_closed.accessible, "Closed matchbox should not be accessible")
    eq(true, mb_open.accessible, "Open matchbox should be accessible")
end)

-------------------------------------------------------------------------------
h.suite("5. BUG-093: 'rummage around' — verb synonym recognition")
-------------------------------------------------------------------------------

test("BUG-093: 'rummage around' → search, around", function()
    local v, n = preprocess.natural_language("rummage around")
    eq("search", v, "'rummage' should be synonym for 'search'")
    eq("around", n, "'around' should be preserved for sweep")
end)

test("BUG-093: 'rummage for matches' → search, match (BUG-111: singularized)", function()
    local v, n = preprocess.natural_language("rummage for matches")
    eq("search", v, "'rummage for' should map to 'search'")
    eq("match", n)
end)

test("BUG-093: 'rummage through the wardrobe' → search, wardrobe", function()
    local v, n = preprocess.natural_language("rummage through the wardrobe")
    eq("search", v, "'rummage through' should map to 'search'")
    -- "the wardrobe" may or may not have article stripped by this path
    truthy(n and n:find("wardrobe"), "Should contain 'wardrobe'")
end)

test("BUG-093: bare 'rummage' → search, around (sweep)", function()
    local v, n = preprocess.natural_language("rummage")
    eq("search", v, "Bare 'rummage' should map to 'search'")
    eq("around", n, "Should trigger sweep")
end)

test("BUG-093: 'rummage nightstand' → search, nightstand", function()
    local v, n = preprocess.natural_language("rummage nightstand")
    eq("search", v, "'rummage [scope]' should map to 'search'")
    eq("nightstand", n)
end)

test("BUG-093: does NOT hang", function()
    local v, n = preprocess.natural_language("rummage around")
    truthy(v ~= nil, "Should return a verb without hanging")
end)

-------------------------------------------------------------------------------
h.suite("6. BUG-094: 'look for a candle' — look-for + article")
-------------------------------------------------------------------------------

test("BUG-094: 'look for a candle' → find, candle", function()
    local v, n = preprocess.natural_language("look for a candle")
    eq("find", v, "'look for' should convert to 'find'")
    eq("candle", n, "Article 'a' should be stripped from target")
end)

test("BUG-094: 'look for the matchbox' → find, matchbox", function()
    local v, n = preprocess.natural_language("look for the matchbox")
    eq("find", v, "'look for' should convert to 'find'")
    eq("matchbox", n, "Article 'the' should be stripped")
end)

test("BUG-094: 'look for an apple' → find, apple", function()
    local v, n = preprocess.natural_language("look for an apple")
    eq("find", v)
    eq("apple", n, "Article 'an' should be stripped")
end)

test("BUG-094: 'look for matches' → find, match (BUG-111: singularized)", function()
    local v, n = preprocess.natural_language("look for matches")
    eq("find", v)
    eq("match", n, "Should singularize 'matches' to 'match' (BUG-111)")
end)

test("BUG-094: does NOT hang", function()
    local v, n = preprocess.natural_language("look for a candle")
    truthy(v ~= nil, "Should return a verb without hanging")
end)

-------------------------------------------------------------------------------
h.suite("7. Cross-bug edge cases")
-------------------------------------------------------------------------------

test("Politeness + rummage: 'could you rummage around' → search, around", function()
    local v, n = preprocess.natural_language("could you rummage around")
    eq("search", v)
    eq("around", n)
end)

test("Adverb + search scope: 'carefully search the drawer for a match'", function()
    local v, n = preprocess.natural_language("carefully search the drawer for a match")
    eq("search", v)
    truthy(n:find("drawer"), "Should have 'drawer' in noun")
    truthy(n:find("match"), "Should have 'match' in noun")
end)

test("Politeness + look for: 'please look for a candle' → find, candle", function()
    local v, n = preprocess.natural_language("please look for a candle")
    eq("find", v)
    eq("candle", n)
end)

test("Compound + politeness: 'could you find a match' → find, match", function()
    local v, n = preprocess.natural_language("could you find a match")
    eq("find", v)
    eq("match", n, "Article 'a' should be stripped")
end)

test("Triple compound: 'open drawer, take match and light it' splits to 3", function()
    local subs = split_compound("open drawer, take match and light it")
    eq(3, #subs, "Should split into 3 sub-commands")
    eq("open drawer", subs[1])
    eq("take match", subs[2])
    eq("light it", subs[3])
end)

test("Adverb + rummage: 'frantically rummage around' → search, around", function()
    local v, n = preprocess.natural_language("frantically rummage around")
    eq("search", v)
    eq("around", n)
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
