-- test/parser/test-regression-comprehensive.lua
-- Issue #107: Comprehensive parser regression tests covering the FULL pipeline.
-- Covers: preprocessing, compound commands, verb synonyms, noun disambiguation,
--         edge cases, and critical-path Level 1 commands.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../../?.lua;"
             .. script_dir .. "/../../?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")
local fuzzy = require("engine.parser.fuzzy")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy
local is_nil = h.assert_nil

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function nl(input)
    return preprocess.natural_language(input)
end

local function parse(input)
    return preprocess.parse(input)
end

local function make_ctx(objects, room_contents, hands)
    local obj_map = {}
    for _, obj in ipairs(objects) do obj_map[obj.id] = obj end
    local reg = {
        _objects = obj_map,
        get = function(self, id) return self._objects[id] end,
    }
    return {
        current_room = { contents = room_contents or {} },
        player = { hands = hands or {nil, nil}, worn = {} },
        registry = reg,
        current_verb = "examine",
    }
end

-------------------------------------------------------------------------------
h.suite("REGRESSION: Normalization pipeline integrity")
-------------------------------------------------------------------------------

test("lowercase + trim preserved after refactor", function()
    local v, n = parse("  LOOK  AROUND  ")
    eq("look", v)
    eq("around", n)
end)

test("trailing question marks stripped", function()
    local v, n = nl("where am I???")
    eq("look", v)
end)

test("tabs and mixed whitespace collapsed", function()
    local v, n = parse("\t  look \t around  ")
    eq("look", v)
    eq("around", n)
end)

test("politeness stripped: please", function()
    local v, n = nl("please look around")
    eq("look", v)
    eq("", n)
end)

test("politeness stripped: could you", function()
    local v, n = nl("could you look around")
    eq("look", v)
    eq("", n)
end)

test("politeness stripped: would you mind", function()
    local v, n = nl("would you mind searching around?")
    eq("search", v)
end)

test("preamble stripped: I want to", function()
    local v, n = nl("I want to look around")
    eq("look", v)
    eq("", n)
end)

test("preamble stripped: I'd like to", function()
    local v, n = nl("I'd like to open the crate")
    eq("open", v)
    truthy(n and n:find("crate"), "Should target crate")
end)

test("preamble stripped: I need to", function()
    local v, n = nl("I need to take the key")
    eq("take", v)
    truthy(n and n:find("key"), "Should target key")
end)

test("preamble stripped: try to", function()
    local v, n = nl("try to open the door")
    eq("open", v)
    truthy(n and n:find("door"), "Should target door")
end)

test("adverb stripped: carefully", function()
    local v, n = nl("carefully search the nightstand")
    eq("search", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("adverb stripped: slowly", function()
    local v, n = nl("slowly open the crate")
    eq("open", v)
    truthy(n and n:find("crate"), "Should target crate")
end)

test("adverb stripped: firmly", function()
    local v, n = nl("firmly push the door")
    eq("push", v)
    truthy(n and n:find("door"), "Should target door")
end)

test("gerund conversion: examining → examine", function()
    local v, n = nl("examining the nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("gerund conversion: searching → search", function()
    local v, n = nl("searching the room")
    eq("search", v)
    truthy(n and n:find("room"), "Should target room")
end)

test("gerund conversion: pouring → pour", function()
    local v, n = nl("pouring the water")
    eq("pour", v)
    truthy(n and n:find("water"), "Should target water")
end)

test("noun modifier stripped: all of the", function()
    local v, n = nl("I want to take all of the items")
    eq("take", v)
    truthy(n and n:find("items"), "Should target items")
end)

test("possessive stripped: your/my", function()
    local v, n = nl("hit your head")
    eq("hit", v)
    truthy(n and n:find("head"), "Should target head")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Compound commands — 'X with Y' tool pattern")
-------------------------------------------------------------------------------

test("'open door with key' → open, noun has door + with key", function()
    local v, n = nl("open door with key")
    if not v then v, n = parse("open door with key") end
    eq("open", v)
    truthy(n and n:find("door"), "Should target door")
    truthy(n and n:find("with key"), "Should preserve 'with key'")
end)

test("'unlock chest with key' → unlock, noun has chest + with key", function()
    local v, n = parse("unlock chest with key")
    eq("unlock", v)
    truthy(n and n:find("chest"), "Should target chest")
    truthy(n and n:find("with key"), "Should preserve 'with key'")
end)

test("'pry crate with crowbar' → open, noun has crate", function()
    local v, n = nl("pry crate with crowbar")
    eq("open", v)
    truthy(n and n:find("crate"), "Should target crate")
end)

test("'pry open the chest with a bar' → open, noun has chest", function()
    local v, n = nl("pry open the chest with a bar")
    eq("open", v)
    truthy(n and n:find("chest"), "Should target chest")
end)

test("'force open the crate' → open, noun has crate", function()
    local v, n = nl("force open the crate")
    eq("open", v)
    truthy(n and n:find("crate"), "Should target crate")
end)

test("'use crowbar on crate' → open crate", function()
    local v, n = nl("use crowbar on crate")
    eq("open", v)
    truthy(n and n:find("crate"), "Should target crate")
end)

test("'use bar on door' → open door", function()
    local v, n = nl("use bar on door")
    eq("open", v)
    truthy(n and n:find("door"), "Should target door")
end)

test("'use prybar on chest' → not recognized as open tool (falls to parse)", function()
    -- Only crowbar/bar are recognized pry tools in compound transforms
    local v, n = parse("use prybar on chest")
    eq("use", v)
    truthy(n and n:find("prybar"), "prybar stays in noun")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Compound commands — 'pour X into Y'")
-------------------------------------------------------------------------------

test("'pour water into glass' → pour, noun has water + into glass", function()
    local v, n = nl("pour water into glass")
    if not v then v, n = parse("pour water into glass") end
    eq("pour", v)
    truthy(n and n:find("water"), "Should have water")
    truthy(n and n:find("into glass"), "Should preserve 'into glass'")
end)

test("'pour oil in lantern' → pour, noun has oil + into lantern", function()
    local v, n = nl("pour oil in lantern")
    eq("pour", v)
    truthy(n and n:find("oil"), "Should have oil")
    truthy(n and n:find("into lantern"), "Should normalize 'in' to 'into'")
end)

test("'fill lantern with oil' → pour, reversed to oil + into lantern", function()
    local v, n = nl("fill lantern with oil")
    eq("pour", v)
    truthy(n and n:find("oil"), "Should have oil (reversed)")
    truthy(n and n:find("into lantern"), "Should have lantern as target")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Compound commands — 'apply X to Y'")
-------------------------------------------------------------------------------

test("'apply salve to wound' → apply, noun has salve + to wound", function()
    local v, n = nl("apply salve to wound")
    if not v then v, n = parse("apply salve to wound") end
    eq("apply", v)
    truthy(n and n:find("salve"), "Should have salve")
    truthy(n and n:find("to wound"), "Should preserve 'to wound'")
end)

test("'rub salve on wound' → apply salve to wound", function()
    local v, n = nl("rub salve on wound")
    eq("apply", v)
    truthy(n and n:find("salve"), "Should have salve")
    truthy(n and n:find("to wound"), "Should convert 'on' to 'to'")
end)

test("'rub ointment into cut' → apply ointment to cut", function()
    local v, n = nl("rub ointment into cut")
    eq("apply", v)
    truthy(n and n:find("ointment"), "Should have ointment")
    truthy(n and n:find("to cut"), "Should convert 'into' to 'to'")
end)

test("'use salve on wound' → apply (default fallback)", function()
    local v, n = nl("use salve on wound")
    eq("apply", v)
    truthy(n and n:find("salve"), "Should have salve")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Compound commands — tool dispatch from 'use X on Y'")
-------------------------------------------------------------------------------

test("'use needle on fabric' → sew", function()
    local v, n = nl("use needle on fabric")
    eq("sew", v)
    truthy(n and n:find("fabric"), "Should target fabric")
end)

test("'use key on door' → unlock", function()
    local v, n = nl("use key on door")
    eq("unlock", v)
    truthy(n and n:find("door"), "Should target door")
end)

test("'use match on candle' → light", function()
    local v, n = nl("use match on candle")
    eq("light", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("'use lighter on torch' → light", function()
    local v, n = nl("use lighter on torch")
    eq("light", v)
    truthy(n and n:find("torch"), "Should target torch")
end)

test("'use flint on campfire' → light", function()
    local v, n = nl("use flint on campfire")
    eq("light", v)
    truthy(n and n:find("campfire"), "Should target campfire")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Verb synonym resolution — combat")
-------------------------------------------------------------------------------

test("smack → hit (preprocess transform)", function()
    local v, n = nl("smack the wall")
    eq("hit", v)
    truthy(n and n:find("wall"), "Should target wall")
end)

test("bang → hit", function()
    local v, n = nl("bang the wall")
    eq("hit", v)
end)

test("slap → hit", function()
    local v, n = nl("slap the wall")
    eq("hit", v)
end)

test("whack → hit", function()
    local v, n = nl("whack the wall")
    eq("hit", v)
end)

test("hurt → hit", function()
    local v, n = nl("hurt the wall")
    eq("hit", v)
end)

test("beat up → hit", function()
    local v, n = nl("beat the goblin up")
    eq("hit", v)
end)

test("headbutt → hit head", function()
    local v, n = nl("headbutt")
    eq("hit", v)
    truthy(n and n:find("head"), "Headbutt targets head")
end)

test("bonk (bare) → hit head", function()
    local v, n = nl("bonk")
    eq("hit", v)
    truthy(n and n:find("head"), "Bare bonk targets head")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Verb synonym resolution — verb handler aliases")
-------------------------------------------------------------------------------

-- These test parse() since the handler alias is at the verb-handler level,
-- not preprocess. The verb table maps the alias to the same handler function.
test("punch registered as handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["punch"], "punch should be registered")
end)

test("bash registered as handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["bash"], "bash should be registered")
end)

test("jab registered as stab handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["jab"], "jab should be registered")
    truthy(handlers["stab"], "stab should be registered")
end)

test("grab registered as take handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["grab"], "grab should be registered")
    truthy(handlers["take"], "take should be registered")
end)

test("yank registered as pull handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["yank"], "yank should be registered")
    truthy(handlers["pull"], "pull should be registered")
end)

test("shove registered as push handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["shove"], "shove should be registered")
end)

test("shut registered as close handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["shut"], "shut should be registered")
    truthy(handlers["close"], "close should be registered")
end)

test("smash/shatter registered as break handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["smash"], "smash should be registered")
    truthy(handlers["shatter"], "shatter should be registered")
    truthy(handlers["break"], "break should be registered")
end)

test("don registered as wear handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["don"], "don should be registered")
    truthy(handlers["wear"], "wear should be registered")
end)

test("doff registered as remove handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["doff"], "doff should be registered")
end)

test("snuff registered as extinguish handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["snuff"], "snuff should be registered")
    truthy(handlers["extinguish"], "extinguish should be registered")
end)

test("ignite/relight registered as light handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["ignite"], "ignite should be registered")
    truthy(handlers["relight"], "relight should be registered")
    truthy(handlers["light"], "light should be registered")
end)

test("consume/devour registered as eat handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["consume"], "consume should be registered")
    truthy(handlers["devour"], "devour should be registered")
end)

test("quaff/sip registered as drink handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["quaff"], "quaff should be registered")
    truthy(handlers["sip"], "sip should be registered")
end)

test("spill/dump/fill registered as pour handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["spill"], "spill should be registered")
    truthy(handlers["dump"], "dump should be registered")
    truthy(handlers["fill"], "fill should be registered")
end)

test("rest/nap registered as sleep handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["rest"], "rest should be registered")
    truthy(handlers["nap"], "nap should be registered")
end)

test("treat registered as apply handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["treat"], "treat should be registered")
    truthy(handlers["apply"], "apply should be registered")
end)

test("inscribe registered as write handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["inscribe"], "inscribe should be registered")
end)

test("stitch/mend registered as sew handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["stitch"], "stitch should be registered")
    truthy(handlers["mend"], "mend should be registered")
end)

test("place registered as put handler", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["place"], "place should be registered")
end)

test("direction aliases: n/s/e/w/u/d registered", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["n"], "n should be registered")
    truthy(handlers["s"], "s should be registered")
    truthy(handlers["e"], "e should be registered")
    truthy(handlers["w"], "w should be registered")
    truthy(handlers["u"], "u should be registered")
    truthy(handlers["d"], "d should be registered")
end)

test("movement aliases: walk/run/head/travel registered", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["walk"], "walk should be registered")
    truthy(handlers["run"], "run should be registered")
    truthy(handlers["head"], "head should be registered")
    truthy(handlers["travel"], "travel should be registered")
end)

test("'i' registered as inventory alias", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["i"], "i should be registered")
    truthy(handlers["inventory"], "inventory should be registered")
end)

test("sensory aliases: x/check/inspect registered for examine", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["x"], "x should be registered")
    truthy(handlers["check"], "check should be registered")
    truthy(handlers["inspect"], "inspect should be registered")
end)

test("sensory aliases: touch/grope → feel, sniff → smell", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["touch"], "touch should be registered")
    truthy(handlers["grope"], "grope should be registered")
    truthy(handlers["sniff"], "sniff should be registered")
end)

test("taste aliases: lick → taste", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["lick"], "lick should be registered")
end)

test("listen alias: hear → listen", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["hear"], "hear should be registered")
end)

test("uncork aliases: unstop/unseal registered", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["unstop"], "unstop should be registered")
    truthy(handlers["unseal"], "unseal should be registered")
end)

test("combat aliases: slice/nick → cut; carve → butcher", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["slice"], "slice should be registered")
    truthy(handlers["nick"], "nick should be registered")
    truthy(handlers["carve"], "carve should be registered")
end)

test("tear alias: rip → tear", function()
    local handlers = require("engine.verbs").create()
    truthy(handlers["rip"], "rip should be registered")
end)

test("all 11 verb modules produce complete handler table", function()
    local handlers = require("engine.verbs").create()
    local count = 0
    for _ in pairs(handlers) do count = count + 1 end
    truthy(count >= 90, "Should have 90+ handler keys, got " .. count)
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Preprocess verb aliases (transform layer)")
-------------------------------------------------------------------------------

test("'put out candle' → extinguish candle", function()
    local v, n = nl("put out candle")
    eq("extinguish", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("'blow out candle' → extinguish candle", function()
    local v, n = nl("blow out candle")
    eq("extinguish", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("'take off gloves' → remove gloves", function()
    local v, n = nl("take off gloves")
    eq("remove", v)
    truthy(n and n:find("gloves"), "Should target gloves")
end)

test("'put on hat' → wear hat", function()
    local v, n = nl("put on hat")
    eq("wear", v)
    truthy(n and n:find("hat"), "Should target hat")
end)

test("'dress in cloak' → wear cloak", function()
    local v, n = nl("dress in cloak")
    eq("wear", v)
    truthy(n and n:find("cloak"), "Should target cloak")
end)

test("'set fire to X' → light X", function()
    local v, n = nl("set fire to the candle")
    eq("light", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("'put down sword' → drop sword", function()
    local v, n = nl("put down sword")
    eq("drop", v)
    truthy(n and n:find("sword"), "Should target sword")
end)

test("'set down book' → drop book", function()
    local v, n = nl("set down book")
    eq("drop", v)
    truthy(n and n:find("book"), "Should target book")
end)

test("'get rid of key' → drop key", function()
    local v, n = nl("get rid of key")
    eq("drop", v)
    truthy(n and n:find("key"), "Should target key")
end)

test("'toss candle' (bare) → drop candle", function()
    local v, n = nl("toss candle")
    eq("drop", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("'throw rock' (bare) → drop rock", function()
    local v, n = nl("throw rock")
    eq("drop", v)
    truthy(n and n:find("rock"), "Should target rock")
end)

test("'toss candle on table' → put candle on table", function()
    local v, n = nl("toss candle on table")
    eq("put", v)
    truthy(n and n:find("candle"), "Should have candle")
    truthy(n and n:find("on table"), "Should preserve placement target")
end)

test("'stuff key in pocket' → put key in pocket", function()
    local v, n = nl("stuff key in pocket")
    eq("put", v)
    truthy(n and n:find("key"), "Should have key")
    truthy(n and n:find("in pocket"), "Should preserve 'in pocket'")
end)

test("'hide ring under rug' → put ring under rug", function()
    local v, n = nl("hide ring under rug")
    eq("put", v)
    truthy(n and n:find("ring"), "Should have ring")
    truthy(n and n:find("under rug"), "Should preserve 'under rug'")
end)

test("'slide book into shelf' → put book in shelf", function()
    local v, n = nl("slide book into shelf")
    eq("put", v)
    truthy(n and n:find("book"), "Should have book")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Question transforms")
-------------------------------------------------------------------------------

test("'what am I holding' → inventory", function()
    local v, n = nl("what am I holding")
    eq("inventory", v)
end)

test("'what am I carrying' → inventory", function()
    local v, n = nl("what am I carrying")
    eq("inventory", v)
end)

test("'what am I wearing' → inventory", function()
    local v, n = nl("what am I wearing")
    eq("inventory", v)
end)

test("'what's in my hands' → inventory", function()
    local v, n = nl("what's in my hands")
    eq("inventory", v)
end)

test("'where am I' → look", function()
    local v, n = nl("where am I")
    eq("look", v)
end)

test("'what do I see' → look", function()
    local v, n = nl("what do I see")
    eq("look", v)
end)

test("'what can I see' → look", function()
    local v, n = nl("what can I see")
    eq("look", v)
end)

test("'what time is it' → time", function()
    local v, n = nl("what time is it")
    eq("time", v)
end)

test("'where is the key' → find key", function()
    local v, n = nl("where is the key")
    eq("find", v)
    truthy(n and n:find("key"), "Should target key")
end)

test("'what's in the nightstand' → examine nightstand", function()
    local v, n = nl("what's in the nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("'is there a candle in the room' → search candle", function()
    local v, n = nl("is there a candle in the room")
    eq("search", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("'what now' → help", function()
    local v, n = nl("what now")
    eq("help", v)
end)

test("'what do I do' → help", function()
    local v, n = nl("what do I do")
    eq("help", v)
end)

test("'what's this' → look", function()
    local v, n = nl("what's this")
    eq("look", v)
end)

test("'am I hurt' → health", function()
    local v, n = nl("am I hurt")
    eq("health", v)
end)

test("'am I injured' → health", function()
    local v, n = nl("am I injured")
    eq("health", v)
end)

test("'check my wounds' → health", function()
    local v, n = nl("check my wounds")
    eq("health", v)
end)

test("'where am I bleeding' → injuries", function()
    local v, n = nl("where am I bleeding")
    eq("injuries", v)
end)

test("'how bad is it' → injuries", function()
    local v, n = nl("how bad is it")
    eq("injuries", v)
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Look pattern transforms")
-------------------------------------------------------------------------------

test("'look around' → look", function()
    local v, n = nl("look around")
    eq("look", v)
    eq("", n)
end)

test("'look at nightstand' → examine nightstand", function()
    local v, n = nl("look at nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("'look at myself' → appearance", function()
    local v, n = nl("look at myself")
    eq("appearance", v)
end)

test("'look at my hands' → inventory", function()
    local v, n = nl("look at my hands")
    eq("inventory", v)
end)

test("'check candle' → examine candle", function()
    local v, n = nl("check candle")
    eq("examine", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("'peek under bed' → examine bed", function()
    local v, n = nl("peek under bed")
    eq("examine", v)
    truthy(n and n:find("bed"), "Should target bed")
end)

test("'look for key' → find key", function()
    local v, n = nl("look for key")
    eq("find", v)
    truthy(n and n:find("key"), "Should target key")
end)

test("'look under nightstand' → examine nightstand", function()
    local v, n = nl("look under nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Search phrase transforms")
-------------------------------------------------------------------------------

test("'search for matches' → search match (singularized)", function()
    local v, n = nl("search for matches")
    eq("search", v)
    eq("match", n)
end)

test("'hunt for key' → search key", function()
    local v, n = nl("hunt for key")
    eq("search", v)
    truthy(n and n:find("key"), "Should target key")
end)

test("'rummage around' → search around", function()
    local v, n = nl("rummage around")
    eq("search", v)
end)

test("'find everything' → search (sweep)", function()
    local v, n = nl("find everything")
    eq("search", v)
end)

test("'grope around' → grope via parse (direct verb)", function()
    -- "grope around" is a direct verb+noun, not a natural_language transform
    local v, n = parse("grope around")
    eq("grope", v)
    eq("around", n)
end)

test("'feel around' → feel via parse (direct verb)", function()
    local v, n = parse("feel around")
    eq("feel", v)
    eq("around", n)
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Idiom expansion")
-------------------------------------------------------------------------------

test("'have a look' → look", function()
    local v, n = nl("have a look")
    eq("look", v)
end)

test("'take a look at the door' → examine door", function()
    local v, n = nl("take a look at the door")
    eq("examine", v)
    truthy(n and n:find("door"), "Should target door")
end)

test("'take a peek at the door' → examine door", function()
    local v, n = nl("take a peek at the door")
    eq("examine", v)
    truthy(n and n:find("door"), "Should target door")
end)

test("'make use of key' → use key", function()
    local v, n = nl("make use of key")
    eq("use", v)
    truthy(n and n:find("key"), "Should target key")
end)

test("'go to sleep' → sleep", function()
    local v, n = nl("go to sleep")
    eq("sleep", v)
end)

test("'lay down' → sleep", function()
    local v, n = nl("lay down")
    eq("sleep", v)
end)

test("'lie down' → sleep", function()
    local v, n = nl("lie down")
    eq("sleep", v)
end)

test("'sleep til dawn' → sleep until dawn", function()
    local v, n = nl("sleep til dawn")
    eq("sleep", v)
    truthy(n and n:find("until dawn"), "Should have 'until dawn'")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Movement transforms")
-------------------------------------------------------------------------------

test("'go down the stairs' → down", function()
    local v, n = nl("go down the stairs")
    eq("down", v)
end)

test("'climb up the stairs' → up", function()
    local v, n = nl("climb up the stairs")
    eq("up", v)
end)

test("'go back' → go back", function()
    local v, n = nl("go back")
    -- Accept either "go" with noun "back" or "back" alone
    truthy(v == "go" or v == "back", "Should map to go back, got: " .. tostring(v))
end)

test("'take a nap' → sleep", function()
    local v, n = nl("take a nap")
    eq("sleep", v)
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Multi-command splitting")
-------------------------------------------------------------------------------

test("comma-separated splits correctly", function()
    local cmds = preprocess.split_commands("look, take key, go north")
    eq(3, #cmds)
    eq("look", cmds[1])
    eq("take key", cmds[2])
    eq("go north", cmds[3])
end)

test("semicolons split correctly", function()
    local cmds = preprocess.split_commands("open chest; take sword; go east")
    eq(3, #cmds)
    eq("open chest", cmds[1])
    eq("take sword", cmds[2])
    eq("go east", cmds[3])
end)

test("'then' splits correctly", function()
    local cmds = preprocess.split_commands("take key then unlock door then open door")
    eq(3, #cmds)
    eq("take key", cmds[1])
    eq("unlock door", cmds[2])
    eq("open door", cmds[3])
end)

test("mixed separators all work", function()
    local cmds = preprocess.split_commands("look, take key; open door then go north")
    eq(4, #cmds)
end)

test("double separators skipped", function()
    local cmds = preprocess.split_commands("look,, take key")
    eq(2, #cmds)
end)

test("quoted text not split on internal comma", function()
    local cmds = preprocess.split_commands('say "hello, friend", look')
    eq(2, #cmds)
end)

test("'then' inside word not split", function()
    local cmds = preprocess.split_commands("examine thenardier")
    eq(1, #cmds)
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Noun disambiguation — fuzzy resolve")
-------------------------------------------------------------------------------

test("exact keyword match resolves unambiguously", function()
    local ctx = make_ctx(
        {{ id = "candle", name = "tallow candle", keywords = {"candle", "tallow candle"} },
         { id = "key", name = "brass key", keywords = {"key", "brass key"} }},
        {"candle", "key"}
    )
    local obj = fuzzy.resolve(ctx, "candle")
    truthy(obj, "should resolve")
    eq("candle", obj.id)
end)

test("material disambiguates: 'wooden thing' picks wood object", function()
    local ctx = make_ctx(
        {{ id = "crate", name = "large crate", material = "wood", keywords = {"crate"} },
         { id = "key", name = "brass key", material = "brass", keywords = {"key"} }},
        {"crate", "key"}
    )
    local obj = fuzzy.resolve(ctx, "the wooden thing")
    truthy(obj, "should resolve")
    eq("crate", obj.id)
end)

test("property disambiguates: 'heavy one' picks heaviest", function()
    local ctx = make_ctx(
        {{ id = "anvil", name = "iron anvil", weight = 50, keywords = {"anvil"} },
         { id = "feather", name = "feather", weight = 1, keywords = {"feather"} }},
        {"anvil", "feather"}
    )
    local obj = fuzzy.resolve(ctx, "the heavy one")
    truthy(obj, "should resolve")
    eq("anvil", obj.id)
end)

test("two items with same keyword → disambiguation prompt", function()
    local ctx = make_ctx(
        {{ id = "glass-bottle", name = "glass bottle", keywords = {"bottle", "glass bottle"} },
         { id = "wine-bottle", name = "wine bottle", keywords = {"bottle", "wine bottle"} }},
        {"glass-bottle", "wine-bottle"}
    )
    local obj, _, _, _, prompt = fuzzy.resolve(ctx, "bottle")
    is_nil(obj, "should not auto-resolve")
    truthy(prompt, "should return disambiguation prompt")
    truthy(prompt:find("glass bottle"), "prompt mentions glass bottle")
    truthy(prompt:find("wine bottle"), "prompt mentions wine bottle")
end)

test("typo resolves: 'nighstand' → nightstand", function()
    local ctx = make_ctx(
        {{ id = "nightstand", name = "oak nightstand", keywords = {"nightstand"} }},
        {"nightstand"}
    )
    local obj = fuzzy.resolve(ctx, "nighstand")
    truthy(obj, "should resolve via typo tolerance")
    eq("nightstand", obj.id)
end)

test("short typo rejected: 'ke' does NOT match 'key'", function()
    local ctx = make_ctx(
        {{ id = "key", name = "brass key", keywords = {"key"} }},
        {"key"}
    )
    local obj = fuzzy.resolve(ctx, "ke")
    is_nil(obj, "short-word typo should not match")
end)

test("no match returns nil without prompt", function()
    local ctx = make_ctx(
        {{ id = "chair", name = "wooden chair", keywords = {"chair"} }},
        {"chair"}
    )
    local obj, _, _, _, prompt = fuzzy.resolve(ctx, "elephant")
    is_nil(obj)
    is_nil(prompt)
end)

test("empty room returns nil", function()
    local ctx = make_ctx({}, {})
    is_nil(fuzzy.resolve(ctx, "anything"))
end)

test("material+name beats material alone", function()
    local ctx = make_ctx(
        {{ id = "crate", name = "large crate", material = "wood", keywords = {"crate"} },
         { id = "chair", name = "wooden chair", material = "wood", keywords = {"chair"} }},
        {"crate", "chair"}
    )
    local obj = fuzzy.resolve(ctx, "wooden crate")
    truthy(obj, "should resolve")
    eq("crate", obj.id, "material+name wins over material alone")
end)

test("hand-held items visible to fuzzy resolve", function()
    local ctx = make_ctx(
        {{ id = "sword", name = "iron sword", keywords = {"sword"} }},
        {}, {"sword", nil}
    )
    local obj = fuzzy.resolve(ctx, "sword")
    truthy(obj, "should find item in hand")
    eq("sword", obj.id)
end)

test("hidden objects not visible to fuzzy resolve", function()
    local ctx = make_ctx(
        {{ id = "secret", name = "secret door", hidden = true, keywords = {"door"} }},
        {"secret"}
    )
    is_nil(fuzzy.resolve(ctx, "door"), "hidden object should not resolve")
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Edge cases — malformed input")
-------------------------------------------------------------------------------

test("empty string → nil from natural_language", function()
    is_nil(nl(""))
end)

test("nil input → nil from natural_language", function()
    is_nil(nl(nil))
end)

test("whitespace-only → nil", function()
    is_nil(nl("   "))
end)

test("single character input parses safely", function()
    local v, n = parse("x")
    eq("x", v)
    eq("", n)
end)

test("single character 'i' → inventory shortcut", function()
    local v, n = parse("i")
    eq("i", v)
    eq("", n)
end)

test("gibberish input → nil from natural_language", function()
    is_nil(nl("xyzzy plugh kazam"))
end)

test("very long input does not crash", function()
    local long_input = string.rep("look ", 200)
    h.assert_no_error(function()
        nl(long_input)
    end, "Should not crash on very long input")
end)

test("special characters do not crash", function()
    h.assert_no_error(function()
        nl("look @#$%^&*()")
    end, "Should not crash on special characters")
end)

test("unicode-like characters do not crash", function()
    h.assert_no_error(function()
        nl("look around — carefully")
    end, "Should not crash on em-dash")
end)

test("numbers in input handled safely", function()
    local v, n = parse("take 3 coins")
    eq("take", v)
    eq("3 coins", n)
end)

test("all-punctuation input does not crash", function()
    h.assert_no_error(function()
        nl("!@#$%^&*()")
    end, "Should not crash on all-punctuation")
end)

test("repeated spaces collapsed", function()
    local v, n = parse("look     around")
    eq("look", v)
    eq("around", n)
end)

test("only verb, no noun → empty noun", function()
    local v, n = parse("look")
    eq("look", v)
    eq("", n)
end)

test("split_commands handles nil gracefully", function()
    local cmds = preprocess.split_commands(nil)
    eq(0, #cmds)
end)

test("split_commands handles empty string", function()
    local cmds = preprocess.split_commands("")
    eq(0, #cmds)
end)

test("split_commands handles whitespace only", function()
    local cmds = preprocess.split_commands("   ")
    eq(0, #cmds)
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Critical path — Level 1 command sequence")
-------------------------------------------------------------------------------

-- These verify the commands a player would type to progress through Level 1.

test("'look' parses cleanly (room entry)", function()
    local v, n = parse("look")
    eq("look", v)
    eq("", n)
end)

test("'feel around' → feel via parse (darkness start)", function()
    -- Direct verb+noun, not a natural_language transform
    local v, n = parse("feel around")
    eq("feel", v)
    eq("around", n)
end)

test("'search nightstand' parses cleanly", function()
    local v, n = parse("search nightstand")
    eq("search", v)
    eq("nightstand", n)
end)

test("'take matchbox' parses cleanly", function()
    local v, n = parse("take matchbox")
    eq("take", v)
    eq("matchbox", n)
end)

test("'open matchbox' parses cleanly", function()
    local v, n = parse("open matchbox")
    eq("open", v)
    eq("matchbox", n)
end)

test("'take match' parses cleanly", function()
    local v, n = parse("take match")
    eq("take", v)
    eq("match", n)
end)

test("'strike match' parses cleanly", function()
    local v, n = parse("strike match")
    eq("strike", v)
    eq("match", n)
end)

test("'light candle' parses cleanly", function()
    local v, n = parse("light candle")
    eq("light", v)
    eq("candle", n)
end)

test("'light candle with match' — verb=light, noun preserved", function()
    local v, n = parse("light candle with match")
    eq("light", v)
    eq("candle with match", n)
end)

test("'examine nightstand' parses cleanly", function()
    local v, n = parse("examine nightstand")
    eq("examine", v)
    eq("nightstand", n)
end)

test("'take key' parses cleanly", function()
    local v, n = parse("take key")
    eq("take", v)
    eq("key", n)
end)

test("'unlock door with key' — noun preserved", function()
    local v, n = parse("unlock door with key")
    eq("unlock", v)
    eq("door with key", n)
end)

test("'open door' parses cleanly", function()
    local v, n = parse("open door")
    eq("open", v)
    eq("door", n)
end)

test("'go north' parses cleanly", function()
    local v, n = parse("go north")
    eq("go", v)
    eq("north", n)
end)

test("'north' as bare direction", function()
    local v, n = parse("north")
    eq("north", v)
    eq("", n)
end)

test("'n' as direction shortcut", function()
    local v, n = parse("n")
    eq("n", v)
    eq("", n)
end)

test("'inventory' parses cleanly", function()
    local v, n = parse("inventory")
    eq("inventory", v)
    eq("", n)
end)

test("'drop matchbox' parses cleanly", function()
    local v, n = parse("drop matchbox")
    eq("drop", v)
    eq("matchbox", n)
end)

test("'wear cloak' parses cleanly", function()
    local v, n = parse("wear cloak")
    eq("wear", v)
    eq("cloak", n)
end)

test("'remove cloak' parses cleanly", function()
    local v, n = parse("remove cloak")
    eq("remove", v)
    eq("cloak", n)
end)

test("'read note' parses cleanly", function()
    local v, n = parse("read note")
    eq("read", v)
    eq("note", n)
end)

test("'smell candle' parses cleanly", function()
    local v, n = parse("smell candle")
    eq("smell", v)
    eq("candle", n)
end)

test("'taste wine' parses cleanly", function()
    local v, n = parse("taste wine")
    eq("taste", v)
    eq("wine", n)
end)

test("'listen' parses cleanly (ambient sounds)", function()
    local v, n = parse("listen")
    eq("listen", v)
    eq("", n)
end)

test("'eat bread' parses cleanly", function()
    local v, n = parse("eat bread")
    eq("eat", v)
    eq("bread", n)
end)

test("'drink water' parses cleanly", function()
    local v, n = parse("drink water")
    eq("drink", v)
    eq("water", n)
end)

test("'break mirror' parses cleanly", function()
    local v, n = parse("break mirror")
    eq("break", v)
    eq("mirror", n)
end)

test("'time' parses cleanly", function()
    local v, n = parse("time")
    eq("time", v)
    eq("", n)
end)

test("'help' parses cleanly", function()
    local v, n = parse("help")
    eq("help", v)
    eq("", n)
end)

test("'wait' parses cleanly", function()
    local v, n = parse("wait")
    eq("wait", v)
    eq("", n)
end)

test("'sleep' parses cleanly", function()
    local v, n = parse("sleep")
    eq("sleep", v)
    eq("", n)
end)

-------------------------------------------------------------------------------
h.suite("REGRESSION: Multi-stage pipeline interactions")
-------------------------------------------------------------------------------

test("preamble + adverb + compound: 'I want to carefully pry open the crate'", function()
    local v, n = nl("I want to carefully pry open the crate")
    eq("open", v)
    truthy(n and n:find("crate"), "Should target crate")
end)

test("uppercase + politeness + question: 'COULD YOU PLEASE SEARCH AROUND?'", function()
    local v, n = nl("COULD YOU PLEASE SEARCH AROUND?")
    eq("search", v)
end)

test("gerund + politeness: 'please stop searching'", function()
    local v, n = nl("searching the room")
    eq("search", v)
    truthy(n and n:find("room"), "Should target room")
end)

test("'what\\'s in the nightstand' → examine nightstand (question pattern)", function()
    -- Note: "chest" is a body-part keyword so "in the chest" gets stripped by stage 4.
    -- Use "nightstand" which is not a body-part.
    local v, n = nl("what's in the nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("multi-layer: 'I want to nervously search for the matches'", function()
    local v, n = nl("I want to nervously search for the matches")
    eq("search", v)
    eq("match", n, "Should singularize 'matches' to 'match'")
end)

test("full pipeline: 'Try to gently blow out the candle'", function()
    local v, n = nl("Try to gently blow out the candle")
    eq("extinguish", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("full pipeline: 'I'd like to have a look at the nightstand'", function()
    local v, n = nl("I'd like to have a look at the nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("full pipeline: 'PLEASE CAREFULLY SET FIRE TO THE CANDLE'", function()
    local v, n = nl("PLEASE CAREFULLY SET FIRE TO THE CANDLE")
    eq("light", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
