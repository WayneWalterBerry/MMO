-- test/parser/test-tier2-benchmark.lua
-- Tier 2 Embedding Matcher Benchmark
-- Tests the embedding_matcher's ability to resolve player input to verb+noun.
-- This benchmark is designed to find the parser's REAL limits.
--
-- Categories:
--   F: Core sanity (standard phrasings that MUST work)
--   A: Ambiguous inputs (same words, different intent)
--   B: Creative/unusual phrasings players actually type
--   C: Edge cases and stress tests
--   D: State-dependent disambiguation
--   E: Negative/impossible inputs (valid structure, nonsense target)
--   G: Complex multi-object interactions (prepositional phrases, tool modifiers)
--   H: Ambiguous pronouns/references (bare pronouns, ordinals, deictics)
--   I: Natural language variations (slang, contractions, txtspeak, heavy typos)
--   J: Context-dependent commands (repetition, undo, meta-references)
--   K: Adversarial/tricky inputs (negation, hypotheticals, non-commands)

package.path = "src/?.lua;" .. package.path

local t = require("test.parser.test-helpers")
local embedding_matcher = require("engine.parser.embedding_matcher")

-- Load the matcher once
local SEP = package.config:sub(1, 1)
local index_path = "src" .. SEP .. "assets" .. SEP .. "parser" .. SEP .. "embedding-index.json"
local m = embedding_matcher.new(index_path)

-- Track benchmark stats
local benchmark_pass = 0
local benchmark_fail = 0
local benchmark_total = 0
local failures = {}

-- Helper: test that input resolves to expected verb + noun
-- If expect_noun is nil, we only check the verb.
-- score_floor is the minimum score we expect (default: 0.40 threshold)
local function bench(category, input, expect_verb, expect_noun, score_floor)
    score_floor = score_floor or 0.40
    benchmark_total = benchmark_total + 1
    local test_id = string.format("[%s-%02d]", category, benchmark_total)

    t.test(test_id .. " " .. input, function()
        local verb, noun, score, phrase = m:match(input)

        -- Must clear threshold
        t.assert_truthy(score >= score_floor,
            string.format("score %.3f below floor %.2f (got %s %s via \"%s\")",
                score, score_floor, tostring(verb), tostring(noun), tostring(phrase)))

        -- Verb must match
        t.assert_eq(expect_verb, verb,
            string.format("verb mismatch for \"%s\" (score %.3f via \"%s\")",
                input, score, tostring(phrase)))

        -- Noun must match (if specified)
        if expect_noun then
            t.assert_eq(expect_noun, noun,
                string.format("noun mismatch for \"%s\" (score %.3f via \"%s\")",
                    input, score, tostring(phrase)))
        end
    end)
end

-- Helper: test that input resolves to expected verb (noun can be anything)
local function bench_verb_only(category, input, expect_verb, score_floor)
    bench(category, input, expect_verb, nil, score_floor)
end

-- Helper: test that input FAILS to match above threshold (negative test)
local function bench_no_match(category, input)
    benchmark_total = benchmark_total + 1
    local test_id = string.format("[%s-%02d]", category, benchmark_total)

    t.test(test_id .. " (no match) " .. input, function()
        local verb, noun, score, phrase = m:match(input)
        -- Should either return nil or score below threshold
        local below = (verb == nil) or (score < 0.40)
        t.assert_truthy(below,
            string.format("expected no match but got %s %s (score %.3f via \"%s\")",
                tostring(verb), tostring(noun), score, tostring(phrase)))
    end)
end


-- =========================================================================
-- CATEGORY F: Core Sanity — standard phrasings that MUST work
-- These establish a baseline. If these fail, something is deeply wrong.
-- =========================================================================
t.suite("Category F: Core Sanity")

bench("F", "look candle",           "look",    "candle")
bench("F", "examine match",         "examine", "match")
bench("F", "get knife",             "get",     "knife")
bench("F", "take matchbox",         "take",    "matchbox")
bench("F", "open wardrobe",         "open",    "wardrobe")
bench("F", "close nightstand",      "close",   "nightstand")
bench("F", "feel blanket",          "feel",    "blanket")
bench("F", "smell candle",          "smell",   "candle")
bench("F", "taste rag",             "lick",    "rag")
bench("F", "listen pillow",         "hear",    "pillow")
bench("F", "drop knife",            "drop",    "knife")
bench("F", "light candle",          "ignite",  "candle")
bench("F", "break window",          "break",   "window")
bench("F", "hit bed",               "strike",  "bed")
bench("F", "cut cloth",             "cut",     "cloth")
bench("F", "burn paper",            "burn",    "paper")
bench("F", "eat candle",            "consume", "candle")
bench("F", "read paper",            "read",    "paper")
bench("F", "search nightstand",     "search",  "nightstand")
bench("F", "smell rag",             "smell",   "rag")


-- =========================================================================
-- CATEGORY A: Ambiguous inputs — same/similar words, different intent
-- These test whether the parser picks the RIGHT phrase when multiple
-- objects share keywords or when a word can be verb or noun.
-- =========================================================================
t.suite("Category A: Ambiguous Inputs")

-- "match" is both an object AND part of "matchbox"
bench("A", "examine the match",         "examine", "match")
bench("A", "examine the matchbox",       "examine", "matchbox")
bench("A", "get match",                  "get",     "match")
bench("A", "get matchbox",               "get",     "matchbox")

-- "glass" appears in glass-shard AND window (leaded glass window)
bench("A", "look at glass shard",        "look",    "glass-shard")
bench("A", "look at glass window",       "look",    "window")
bench("A", "examine glass",             "examine",  "glass-shard")
bench("A", "break the glass",           "break",    "glass-shard")

-- "light" as verb (ignite) vs "light" as adjective
bench("A", "light the candle",           "ignite",  "candle")
bench("A", "light match",               "ignite",   "match")

-- "open" — drawer vs nightstand vs wardrobe vs window
bench("A", "open the wardrobe",          "open",    "wardrobe")
bench("A", "open the window",            "open",    "window")
bench("A", "open nightstand",            "open",    "nightstand")

-- "key" — brass key is the only key, but "small" appears in many nouns
bench("A", "get the small key",          "get",     "brass-key")
bench("A", "examine the brass key",      "examine", "brass-key")

-- "bottle" — poison-bottle. The word "small" + "bottle" should still resolve
bench("A", "get the bottle",             "get",     "poison-bottle")
bench("A", "examine small glass bottle", "examine", "poison-bottle")

-- "sewing" — needle AND pin share the word "sewing"
bench("A", "get needle",                "get",      "needle")
bench("A", "get pin",                   "get",      "pin")
bench("A", "examine sewing needle",     "examine",  "needle")
bench("A", "examine sewing pin",        "examine",  "pin")

-- "wool" — blanket (heavy wool blanket) vs cloak (moth-eaten wool cloak)
bench("A", "get wool blanket",           "get",     "blanket")
bench("A", "get wool cloak",             "get",     "wool-cloak")
bench("A", "examine the wool",           "examine", "blanket")

-- "candle" vs "candle-lit" — tiebreaker should prefer base state
bench("A", "look at the candle",         "look",    "candle")

-- "vanity" — multiple states (open, mirror-broken, etc.)
bench("A", "examine the vanity",         "examine", "vanity")

-- "wooden" appears in "wooden match" and nowhere else — but "small" is everywhere
-- Too vague for any parser to handle — player must be more specific
bench_no_match("A", "get something small")

-- "sack" vs "jacket" — both burlap
bench("A", "get the burlap sack",        "get",     "sack")
bench("A", "get the burlap jacket",      "get",     "terrible-jacket")


-- =========================================================================
-- CATEGORY B: Creative/unusual phrasings players actually type
-- Real players don't type "examine candle". They type weird stuff.
-- =========================================================================
t.suite("Category B: Creative Phrasings")

-- Casual/slang pickup attempts
bench("B", "grab the knife",                "grab",    "knife")
bench("B", "snag the matchbox",             "take",    "matchbox")
bench("B", "pick up the candle",            "take",    "candle")
bench("B", "gimme the blanket",             "get",     "blanket")
bench("B", "fetch me the key",              "get",     "brass-key")
bench("B", "obtain the pen",                "get",     "pen")
bench("B", "lift the pillow",               "get",     "pillow")

-- Verbose/descriptive look commands
bench("B", "look at the tallow candle carefully", "look", "candle")
bench("B", "peer at the nightstand",         "examine", "nightstand")
bench("B", "check out the wardrobe",         "examine", "wardrobe")
bench("B", "inspect the rug closely",        "examine", "rug")
bench("B", "study the paper",               "examine",  "paper")

-- Alternative verb phrasings
bench("B", "smash the window",              "break",   "window")
bench("B", "shatter the glass shard",       "break",   "glass-shard")
bench("B", "incinerate the paper",          "burn",    "paper")
bench("B", "set fire to the rag",           "burn",    "rag")
bench("B", "ignite the match",              "ignite",  "match")
bench("B", "set ablaze the curtains",       "ignite",  "curtains")
bench("B", "whack the pillow",              "strike",  "pillow")
bench("B", "slash the cloth",               "cut",     "cloth")
bench("B", "slice the thread",              "cut",     "thread")

-- Touch/feel variants
bench("B", "touch the blanket",             "feel",    "blanket")
bench("B", "run fingers over the curtains", "feel",    "curtains")

-- Sensory verbs in casual form
bench("B", "sniff the candle",              "smell",   "candle")
bench("B", "lick the brass key",            "lick",    "brass-key")

-- Question forms that players actually type
bench_verb_only("B", "what is the candle",          "examine")
bench_verb_only("B", "check the matchbox",          "examine")

-- Verbose/wordy input — parser must not choke on extra words
bench("B", "i want to look at the old dusty rug on the floor", "look", "rug")
bench("B", "please carefully examine the small wooden match",   "examine", "match")
bench("B", "could you show me the nightstand",                  "look",  "nightstand")

-- "use" as a verb — mapped to ignite for candle/match
bench("B", "use the match",                 "ignite",  "match")
bench("B", "use the candle",                "ignite",  "candle")


-- =========================================================================
-- CATEGORY C: Edge Cases and Stress Tests
-- Minimal input, maximum input, typos, repeated words, weird structures.
-- =========================================================================
t.suite("Category C: Edge Cases")

-- Very short inputs — single keyword
bench_verb_only("C", "help",                "help")
-- "inventory" phrase maps to verb "i" in the index
bench_verb_only("C", "inventory",           "i")
-- "i" is a stop word — Tier 1 handles this, Tier 2 can't
bench_no_match("C", "i")
bench_verb_only("C", "x",                   "x")
bench_verb_only("C", "time",                "time")

-- Input is ONLY stop words (should fail to match)
bench_no_match("C", "the a an")
bench_no_match("C", "it is to at on in")

-- Single non-verb word with no context
bench_no_match("C", "banana")
bench_no_match("C", "dragon")
bench_no_match("C", "helicopter")

-- Typo correction (only for words >4 chars)
bench("C", "examin candle",                "examine", "candle")
bench("C", "examnine the match",           "examine", "match")
bench("C", "serach nightstand",            "search",  "nightstand")
bench("C", "brek window",                  "break",   "window")

-- Repeated verb+noun word ("lock lock" scenario)
bench("C", "break break",                  "break",   nil)
bench("C", "match match",                  "ignite",  "match")

-- Input with lots of articles and prepositions (all stop words except key terms)
bench("C", "the candle on the nightstand in the room",  "ignite", "candle")

-- Very long input with noise
bench("C", "i really want to carefully and slowly examine the old dusty dirty worn matchbox sitting on the table please", "examine", "matchbox")

-- Input that partially matches multiple objects — too vague to resolve
bench_no_match("C", "get small")
-- "heavy" gets typo-corrected to "hear" (edit distance 2) — tests that weakness
bench_verb_only("C", "examine heavy", "examine")

-- Substring collision: "pen" vs "pencil" — "pen" is a substring of "pencil"
bench("C", "get the pen",                  "get",     "pen")
bench("C", "get the pencil",              "get",      "pencil")
bench("C", "examine pen",                 "examine",  "pen")
bench("C", "examine pencil",              "examine",  "pencil")

-- "rag" vs "rug" — one letter difference
bench("C", "get the rag",                  "get",     "rag")
bench("C", "get the rug",                  "get",     "rug")

-- "cloth" vs "cloak" — similar words
bench("C", "get cloth",                    "get",     "cloth")
bench("C", "get cloak",                    "get",     "wool-cloak")

-- "pin" vs "pen" — very similar short words
bench("C", "feel the pin",                 "feel",    "pin")
bench("C", "feel the pen",                 "feel",    "pen")

-- Possessive/pronoun forms (stop words stripped, noun should survive)
bench("C", "examine my knife",             "examine", "knife")
bench("C", "drop my candle",               "drop",    "candle")


-- =========================================================================
-- CATEGORY D: State-Dependent Disambiguation
-- The parser has a tiebreaker for base vs suffixed nouns. Test it.
-- =========================================================================
t.suite("Category D: State Disambiguation")

-- Candle: candle vs candle-lit (tiebreaker should prefer base)
bench("D", "examine a tallow candle",       "examine", "candle")
bench("D", "get tallow candle",             "get",     "candle")

-- Match: match vs match-lit
bench("D", "examine wooden match",          "examine", "match")
bench("D", "get wooden match",              "get",     "match")

-- Nightstand: nightstand vs nightstand-open
bench("D", "examine small nightstand",      "examine", "nightstand")
bench("D", "look at nightstand",            "look",    "nightstand")

-- Wardrobe: wardrobe vs wardrobe-open
bench("D", "look at heavy wardrobe",        "look",    "wardrobe")
bench("D", "search wardrobe",              "search",   "wardrobe")

-- Curtains: curtains vs curtains-open
bench("D", "feel the curtains",             "feel",    "curtains")
bench("D", "look at curtains",              "look",    "curtains")

-- Window: window vs window-open
bench("D", "look at window",                "look",    "window")
bench("D", "examine leaded glass window",   "examine", "window")

-- Vanity: 4-way disambiguation (vanity, vanity-open, vanity-mirror-broken, vanity-open-mirror-broken)
bench("D", "examine oak vanity",             "examine", "vanity")
bench("D", "look at the vanity",             "look",    "vanity")

-- Explicit state mentions — should still resolve to base
bench("D", "examine a lit match",           "examine", "match-lit")
bench("D", "get a lit candle",              "get",     "candle-lit")
bench("D", "look at open wardrobe",         "look",    "wardrobe-open")


-- =========================================================================
-- CATEGORY E: Negative/Impossible/Nonsense Inputs
-- Valid grammar but targets that don't exist in the game world.
-- The parser should still match a VERB but might pick a wrong noun,
-- or the score should be low enough to fail the threshold.
-- =========================================================================
t.suite("Category E: Negative/Impossible Inputs")

-- Verb exists but noun is totally made up
bench_no_match("E", "eat the dragon")
bench_no_match("E", "examine the unicorn")
bench_no_match("E", "get the sword")
bench_no_match("E", "teleport to kitchen")
bench_no_match("E", "cast fireball")
bench_no_match("E", "fly north")
bench_no_match("E", "swim across river")

-- Pure gibberish
bench_no_match("E", "xyzzy plugh")
bench_no_match("E", "asdf jkl")
bench_no_match("E", "qqqqq")

-- Empty-ish after stop word removal
bench_no_match("E", "the")
bench_no_match("E", "a")

-- Valid-ish but no phrase should match well
bench_no_match("E", "contemplate existence")
bench_no_match("E", "meditate deeply")
bench_no_match("E", "dance around the room")

-- Verb that exists but object doesn't
bench_no_match("E", "burn the dragon")
bench_no_match("E", "open the portal")


-- =========================================================================
-- CATEGORY G: Complex Multi-Object Interactions
-- Inputs with two or more game-world nouns. The parser must identify the
-- correct PRIMARY target object despite competing noun signals.
-- Most of these use prepositional phrases ("X with Y", "X on Y") that
-- the BM25 scorer was not designed to disambiguate.
-- =========================================================================
t.suite("Category G: Complex Multi-Object Interactions")

-- Prepositional target: "key" is the object, "nightstand" is destination
bench("G", "put the key on the nightstand",            "put",    "brass-key")
-- Tool modifier: "candle" is the target, "match" is the tool
bench("G", "light the candle with the match",          "ignite", "candle")
-- Tool modifier: "cloth" is the target, "knife" is the tool
bench("G", "cut the cloth with the knife",             "cut",    "cloth")
-- Source extraction: "needle" is the target, "pillow" is the source
bench("G", "take the needle out of the pillow",        "take",   "needle")
-- Destination: "candle" is the target, "nightstand" is destination
bench("G", "place the candle on the nightstand",       "place",  "candle")
-- Compound command: only the FIRST action should resolve at Tier 2
bench("G", "drop the knife and pick up the pen",       "drop",   "knife")
-- Multi-noun conjunction: first object should win
bench("G", "get both the pen and the pencil",          "get",    "pen")
-- Non-indexed verb synonym: "stuff" should resolve to "put"
bench("G", "stuff the rag into the sack",              "put",    "rag")
-- Non-indexed verb synonym: "hide" should resolve to "put"
bench("G", "hide the brass key under the rug",         "put",    "brass-key")
-- Source extraction with container: "match" target, "matchbox" source
bench("G", "take the match from inside the matchbox",  "take",   "match")
-- Non-indexed verb: "wrap" should resolve to "put"
bench("G", "wrap the cloth around the knife handle",   "put",    "cloth")


-- =========================================================================
-- CATEGORY H: Ambiguous Pronouns and References
-- Players use pronouns ("it", "that"), ordinals ("first one"), and
-- deictic references ("there", "this") that require context the
-- embedding matcher does not have. Pronouns are stop-words so they
-- vanish during tokenization, leaving bare verbs with no noun signal.
-- =========================================================================
t.suite("Category H: Ambiguous Pronouns/References")

-- Pronoun "it" is a stop word — leaves bare verb "take"
bench_verb_only("H", "take it",                        "take")
-- Pronoun "that" is a stop word — leaves bare verb "drop"
bench_verb_only("H", "drop that",                      "drop")
-- "it" + "there" both stop words — leaves bare verb "put"
bench_verb_only("H", "put it there",                   "put")
-- Ordinal reference: "first" and "one" carry no object signal
bench_verb_only("H", "open the first one",             "open")
-- Adjective reference: "other" + "one" carry no object signal
bench_verb_only("H", "examine the other one",          "examine")
-- "this", "that" are stop words; "use" not in index — total wash
bench_no_match("H", "use this on that")
-- Deictic: "one" + "left" carry no object signal
bench_verb_only("H", "pick the one on the left",       "pick")
-- Non-indexed verb "give" should resolve to "get" equivalent
bench("H", "give me the key",                          "get",    "brass-key")
-- Non-indexed verb "show" should resolve to "look" equivalent
bench("H", "show me the candle",                       "look",   "candle")
-- "do" + "that" are stop words; "other" + "door" remain but verb is gone
bench_verb_only("H", "do that to the other door",      "open")
-- "yes" is a stop word — leaves only "candle" (no verb token)
bench_no_match("H", "yes the candle")


-- =========================================================================
-- CATEGORY I: Natural Language Variations
-- Colloquialisms, contractions, txtspeak, incomplete sentences, and
-- heavy typos that a real mobile player might actually type.
-- The parser should eventually handle all of these gracefully.
-- =========================================================================
t.suite("Category I: Natural Language Variations")

-- Contraction without apostrophe: "whats" is not in any phrase
bench("I", "whats in the nightstand",                  "search", "nightstand")
-- Slang contraction: "lemme" = "let me" — not a stop word
bench("I", "lemme see the knife",                      "look",   "knife")
-- Interjection + slang: "yo" and "check" not indexed
bench("I", "yo check this rag out",                    "examine","rag")
-- Slang future: "gonna" not a stop word, blocks verb resolution
bench("I", "gonna grab the blanket",                   "grab",   "blanket")
-- Txtspeak contraction: "im" not a stop word
bench("I", "im looking for the key",                   "look",   "brass-key")
-- Txtspeak: "u" not expanded to "you"
bench("I", "can u open the wardrobe",                  "open",   "wardrobe")
-- Question form with no game verb: "where" + "is" not indexed
bench("I", "where is the knife",                       "look",   "knife")
-- Question form: "how" not indexed, "do"/"i" are stop words
bench("I", "how do i open this window",                "open",   "window")
-- Double typo: "breka" (edit distance 2 from "break"), "windo" (missing o)
bench("I", "breka the windo",                          "break",  "window")
-- Heavy typos: both verb and noun mangled
bench("I", "srch nighstand",                           "search", "nightstand")
-- Very heavy typos: almost unrecognizable
bench("I", "exmne nife",                               "examine","knife")


-- =========================================================================
-- CATEGORY J: Context-Dependent Commands
-- Commands that only make sense with prior interaction history.
-- Tier 2 has no context window — these should all fail to match,
-- proving that context-awareness (Tier 4+) is needed.
-- =========================================================================
t.suite("Category J: Context-Dependent Commands")

-- Bare repetition command — no semantic content
bench_no_match("J", "again")
-- "do" and "that" are stop words; only "again" survives
bench_no_match("J", "do that again")
-- Meta-command not in any phrase index
bench_no_match("J", "undo")
-- Temporal command not indexed
bench_no_match("J", "wait")
-- "go" is a stop word; only "back" survives — not a direction
bench_no_match("J", "go back")
-- Cancel intent — no game content
bench_no_match("J", "never mind")
-- "same" + "thing" (stop word) + "but" (stop word) + "key" — has a noun but no verb
bench_no_match("J", "same thing but with the key")
-- Meta-reference to prior action
bench_no_match("J", "repeat last command")
-- Meta-reference with no object
bench_no_match("J", "do the opposite")
-- Conversational aside — "what" + "about" not indexed as verbs
bench("J", "what about the candle",                    "examine","candle")


-- =========================================================================
-- CATEGORY K: Adversarial/Tricky Inputs
-- Negation, hypotheticals, questions, and meta-language that the parser
-- should NOT execute as commands. The danger: stop-word stripping removes
-- "not"/"don't" and leaves the affirmative command intact.
-- These test whether the parser can distinguish intent from action.
-- =========================================================================
t.suite("Category K: Adversarial/Tricky Inputs")

-- NEGATION: "don't" survives stop-word stripping but "not" is stripped
-- After tokenization: ["don't", "open", "door"] — parser sees "open door"
bench_no_match("K", "don't open the door")
-- Same negation pattern with different verb
bench_no_match("K", "don't drop the knife")
-- Imperative negation: "stop" not indexed, "hitting" partial match to "strike"
bench_no_match("K", "stop hitting the bed")
-- Fictional intent: "pretend" not indexed, "break window" matches strongly
bench_no_match("K", "pretend to break the window")
-- Past-tense musing: "was" + "thinking" not stop words, "knife" is noun
bench_no_match("K", "I was just thinking about the knife")
-- Hypothetical: "what" not indexed, "if" is stop word, "eat key" matches
bench_no_match("K", "what if I eat the key")
-- Polite question that IS a real command — should resolve
bench("K", "can I look at the candle",                 "look",   "candle")
-- Wordy question: "is" + "possible" are stop words, "open wardrobe" matches
bench_no_match("K", "is it possible to open the wardrobe")
-- Non-game verb "tell" not indexed, "about" not indexed
bench_no_match("K", "tell me about the nightstand")
-- Non-game verb "describe" not indexed
bench_no_match("K", "describe the room")


-- =========================================================================
-- Summary
-- =========================================================================
print("\n" .. string.rep("=", 60))
print("TIER 2 BENCHMARK RESULTS")
print(string.rep("=", 60))

local fail_count = t.summary()

print(string.rep("=", 60))
if fail_count > 0 then
    print(string.format("BENCHMARK: Some cases failed — parser has room to improve"))
else
    print("BENCHMARK: All cases passed — consider adding harder cases")
end
print(string.rep("=", 60))
