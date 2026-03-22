-- test/parser/pipeline/test-strip-filler.lua
-- Unit tests for Stage 2: strip_filler (iterative: preambles + politeness + adverbs)
-- Tests the composite strip_filler and its sub-stages in isolation.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../../src/?.lua;"
             .. script_dir .. "/../../../src/?/init.lua;"
             .. script_dir .. "/../../../?.lua;"
             .. script_dir .. "/../../../?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test   = h.test
local eq     = h.assert_eq

local strip_filler     = preprocess.stages.strip_filler
local strip_politeness = preprocess.stages.strip_politeness
local strip_adverbs    = preprocess.stages.strip_adverbs
local strip_preambles  = preprocess.stages.strip_preambles

-------------------------------------------------------------------------------
h.suite("Stage 2a: strip_politeness — basic prefixes")
-------------------------------------------------------------------------------

test("'please look' → 'look'", function()
    eq("look", strip_politeness("please look"))
end)

test("'could you search for matches' → 'search for matches'", function()
    eq("search for matches", strip_politeness("could you search for matches"))
end)

test("'can you open the door' → 'open the door'", function()
    eq("open the door", strip_politeness("can you open the door"))
end)

test("'would you look around' → 'look around'", function()
    eq("look around", strip_politeness("would you look around"))
end)

test("'will you take the key' → 'take the key'", function()
    eq("take the key", strip_politeness("will you take the key"))
end)

test("'let me search' → 'search'", function()
    eq("search", strip_politeness("let me search"))
end)

test("'try to open the crate' → 'open the crate'", function()
    eq("open the crate", strip_politeness("try to open the crate"))
end)

test("'kindly help me' → 'help me'", function()
    eq("help me", strip_politeness("kindly help me"))
end)

test("'attempt to light the match' → 'light the match'", function()
    eq("light the match", strip_politeness("attempt to light the match"))
end)

test("word 'please' inside a noun not stripped", function()
    eq("find the please and thank you sign", strip_politeness("find the please and thank you sign"))
end)

test("no-op on clean input", function()
    eq("open door", strip_politeness("open door"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 2b: strip_adverbs — leading adverbs")
-------------------------------------------------------------------------------

test("'carefully search the nightstand' → 'search the nightstand'", function()
    eq("search the nightstand", strip_adverbs("carefully search the nightstand"))
end)

test("'thoroughly search the room' → 'search the room'", function()
    eq("search the room", strip_adverbs("thoroughly search the room"))
end)

test("'quickly look around' → 'look around'", function()
    eq("look around", strip_adverbs("quickly look around"))
end)

test("'slowly open the drawer' → 'open the drawer'", function()
    eq("open the drawer", strip_adverbs("slowly open the drawer"))
end)

test("'gently push the door' → 'push the door'", function()
    eq("push the door", strip_adverbs("gently push the door"))
end)

test("'quietly search around' → 'search around'", function()
    eq("search around", strip_adverbs("quietly search around"))
end)

test("'frantically search for matches' → 'search for matches'", function()
    eq("search for matches", strip_adverbs("frantically search for matches"))
end)

test("'desperately look for the key' → 'look for the key'", function()
    eq("look for the key", strip_adverbs("desperately look for the key"))
end)

test("'closely examine the painting' → 'examine the painting'", function()
    eq("examine the painting", strip_adverbs("closely examine the painting"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 2b: strip_adverbs — trailing adverbs")
-------------------------------------------------------------------------------

test("'search the room carefully' → 'search the room'", function()
    eq("search the room", strip_adverbs("search the room carefully"))
end)

test("'look around quickly' → 'look around'", function()
    eq("look around", strip_adverbs("look around quickly"))
end)

test("'open the crate again' → 'open the crate'", function()
    eq("open the crate", strip_adverbs("open the crate again"))
end)

test("'look now' → 'look'", function()
    eq("look", strip_adverbs("look now"))
end)

test("'search here' → 'search'", function()
    eq("search", strip_adverbs("search here"))
end)

test("no-op on clean input", function()
    eq("open door", strip_adverbs("open door"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 2c: strip_preambles — 'I want to' family")
-------------------------------------------------------------------------------

test("'i want to look around' → 'look around'", function()
    eq("look around", strip_preambles("i want to look around"))
end)

test("'i need to take the key' → 'take the key'", function()
    eq("take the key", strip_preambles("i need to take the key"))
end)

test("'i'd like to open the crate' → 'open the crate'", function()
    eq("open the crate", strip_preambles("i'd like to open the crate"))
end)

test("'i would like to search the room' → 'search the room'", function()
    eq("search the room", strip_preambles("i would like to search the room"))
end)

test("'i'll take the matchbox' → 'take the matchbox'", function()
    eq("take the matchbox", strip_preambles("i'll take the matchbox"))
end)

test("'i need search' → 'search'", function()
    eq("search", strip_preambles("i need search"))
end)

test("'i want search' → 'search'", function()
    eq("search", strip_preambles("i want search"))
end)

test("no-op on clean input", function()
    eq("open door", strip_preambles("open door"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 2: strip_filler — composite iterative stripping")
-------------------------------------------------------------------------------

test("'please carefully search the room' → strips politeness + adverb", function()
    eq("search the room", strip_filler("please carefully search the room"))
end)

test("'could you thoroughly look around' → strips both layers", function()
    eq("look around", strip_filler("could you thoroughly look around"))
end)

test("'i want to please carefully open the crate' → multi-layer strip", function()
    eq("open the crate", strip_filler("i want to please carefully open the crate"))
end)

test("'please try to quickly search' → nested politeness + adverb", function()
    eq("search", strip_filler("please try to quickly search"))
end)

test("'i'd like to carefully search again' → preamble + adverb + trailing", function()
    eq("search", strip_filler("i'd like to carefully search again"))
end)

test("'maybe i should slowly look around' → politeness + adverb", function()
    eq("look around", strip_filler("maybe i should slowly look around"))
end)

test("clean input passes through unchanged", function()
    eq("look", strip_filler("look"))
end)

test("single verb passes through unchanged", function()
    eq("search", strip_filler("search"))
end)

test("verb + noun passes through unchanged", function()
    eq("open crate", strip_filler("open crate"))
end)

test("iterative stripping handles deeply nested politeness", function()
    local result = strip_filler("please kindly try to carefully search")
    eq("search", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 2a: strip_politeness — new patterns (Tier 0)")
-------------------------------------------------------------------------------

test("'would you mind opening the door' → 'opening the door'", function()
    eq("opening the door", strip_politeness("would you mind opening the door"))
end)

test("'would you mind searching around' → 'searching around'", function()
    eq("searching around", strip_politeness("would you mind searching around"))
end)

test("'i think i'll take the key' → 'take the key'", function()
    eq("take the key", strip_politeness("i think i'll take the key"))
end)

test("'i think ill take the key' (no apostrophe) → 'take the key'", function()
    eq("take the key", strip_politeness("i think ill take the key"))
end)

test("'maybe look around' → 'look around'", function()
    eq("look around", strip_politeness("maybe look around"))
end)

test("'perhaps search the room' → 'search the room'", function()
    eq("search the room", strip_politeness("perhaps search the room"))
end)

test("'perhaps look at the nightstand' → 'look at the nightstand'", function()
    eq("look at the nightstand", strip_politeness("perhaps look at the nightstand"))
end)

test("'maybe i should' still works → 'look'", function()
    eq("look", strip_politeness("maybe i should look"))
end)

test("'would you mind' before 'would you' (order matters)", function()
    eq("looking", strip_politeness("would you mind looking"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 2b: strip_adverbs — new adverbs (Tier 0)")
-------------------------------------------------------------------------------

test("'firmly push the door' → 'push the door'", function()
    eq("push the door", strip_adverbs("firmly push the door"))
end)

test("'softly knock on the door' → 'knock on the door'", function()
    eq("knock on the door", strip_adverbs("softly knock on the door"))
end)

test("'briskly walk north' → 'walk north'", function()
    eq("walk north", strip_adverbs("briskly walk north"))
end)

test("'hastily grab the key' → 'grab the key'", function()
    eq("grab the key", strip_adverbs("hastily grab the key"))
end)

test("'nervously open the door' → 'open the door'", function()
    eq("open the door", strip_adverbs("nervously open the door"))
end)

test("trailing: 'push the door firmly' → 'push the door'", function()
    eq("push the door", strip_adverbs("push the door firmly"))
end)

test("trailing: 'close the door softly' → 'close the door'", function()
    eq("close the door", strip_adverbs("close the door softly"))
end)

test("trailing: 'walk north briskly' → 'walk north'", function()
    eq("walk north", strip_adverbs("walk north briskly"))
end)

test("trailing: 'grab the key hastily' → 'grab the key'", function()
    eq("grab the key", strip_adverbs("grab the key hastily"))
end)

test("trailing: 'open the box nervously' → 'open the box'", function()
    eq("open the box", strip_adverbs("open the box nervously"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 2: strip_filler — Tier 0 composite interactions")
-------------------------------------------------------------------------------

test("BUG-083: 'could you search for matches' → 'search for matches'", function()
    eq("search for matches", strip_filler("could you search for matches"))
end)

test("politeness + new adverb: 'please firmly push the door' → 'push the door'", function()
    eq("push the door", strip_filler("please firmly push the door"))
end)

test("new politeness + adverb: 'perhaps carefully search' → 'search'", function()
    eq("search", strip_filler("perhaps carefully search"))
end)

test("'would you mind hastily searching around' → 'search around' (BUG-107: gerund stripped)", function()
    eq("search around", strip_filler("would you mind hastily searching around"))
end)

test("'i think i'll nervously open the crate' → 'open the crate'", function()
    eq("open the crate", strip_filler("i think i'll nervously open the crate"))
end)

test("strip order: preamble then politeness then adverb", function()
    eq("search", strip_filler("i want to please softly search"))
end)

test("multiple new politeness layers strip iteratively", function()
    eq("look around", strip_filler("perhaps maybe look around"))
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
