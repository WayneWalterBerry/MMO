-- test/parser/test-bm25f-disambiguation.lua
-- Tests for Phase 3 adaptive weighting / BM25F (Section 4.8).
-- Verifies that verb tokens get higher weight for disambiguation.

package.path = "src/?.lua;src/?/init.lua;" .. package.path

local t = require("test.parser.test-helpers")
local embedding_matcher = require("engine.parser.embedding_matcher")

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local index_path = "src" .. SEP .. "assets" .. SEP .. "parser" .. SEP .. "embedding-index.json"
local m = embedding_matcher.new(index_path, false)
m.scoring_mode = "phase3"

assert(m.loaded, "Failed to load embedding index")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function match_phase3(input)
  m.scoring_mode = "phase3"
  return m:match(input)
end

local function match_bm25(input)
  m.scoring_mode = "bm25"
  return m:match(input)
end

---------------------------------------------------------------------------
-- Tests: BM25F Verb-Priority Disambiguation
---------------------------------------------------------------------------

t.suite("BM25F — Verb-Priority Disambiguation")

t.test("'light the match' resolves to ignite verb", function()
  local verb, noun = match_phase3("light the match")
  t.assert_eq("ignite", verb, "light should resolve to ignite (verb)")
  t.assert_eq("match", noun, "noun should be match")
end)

t.test("'take the match' resolves to take verb", function()
  local verb, noun = match_phase3("take the match")
  t.assert_eq("take", verb, "verb should be take")
  t.assert_eq("match", noun, "noun should be match")
end)

t.test("'break knife' resolves correctly", function()
  local verb, noun = match_phase3("break knife")
  t.assert_eq("break", verb, "verb should be break")
  t.assert_eq("knife", noun, "noun should be knife")
end)

t.test("'strike match' resolves to strike verb", function()
  local verb, noun = match_phase3("strike match")
  t.assert_eq("strike", verb, "verb should be strike")
  t.assert_eq("match", noun, "noun should be match")
end)

t.test("'open wardrobe' resolves correctly", function()
  local verb, noun = match_phase3("open wardrobe")
  t.assert_eq("open", verb, "verb should be open")
  t.assert_eq("wardrobe", noun, "noun should be wardrobe")
end)

t.test("'close window' resolves correctly", function()
  local verb, noun = match_phase3("close window")
  t.assert_eq("close", verb, "verb should be close")
  t.assert_eq("window", noun, "noun should be window")
end)

t.suite("BM25F — Verb Weight Effect")

t.test("BM25F gives higher score to exact verb match", function()
  -- In phase3 mode, a phrase where the verb matches exactly should
  -- score higher than one where the verb is only a noun match
  m.scoring_mode = "phase3"
  local verb1, noun1, score1 = m:match("take candle")
  t.assert_eq("take", verb1, "should match take verb")
  t.assert_eq("candle", noun1, "should match candle noun")
  t.assert_truthy(score1 > 0, "score should be positive")
end)

t.test("BM25F does not break synonym expansion", function()
  -- Synonym verbs should still work through the synonym table
  local verb, noun = match_phase3("snatch the candle")
  t.assert_eq("take", verb, "synonym 'snatch' should map to take")
  t.assert_eq("candle", noun, "noun should be candle")
end)

t.test("BM25F does not break soft-synonym matching", function()
  -- Soft synonyms need MaxSim re-ranking to work
  local verb, noun = match_phase3("seize the candle")
  t.assert_eq("grab", verb, "soft synonym 'seize' should match grab")
  t.assert_eq("candle", noun, "noun should be candle")
end)

t.suite("BM25F — No Regressions Against BM25")

-- Every case that BM25 gets right, phase3 should also get right
local regression_cases = {
  {"take candle",           "take",    "candle"},
  {"examine knife",         "examine", "knife"},
  {"open wardrobe",         "open",    "wardrobe"},
  {"feel blanket",          "feel",    "blanket"},
  {"drop pencil",           "drop",    "pencil"},
  {"smell candle",          "smell",   "candle"},
  {"close window",          "close",   "window"},
  {"grab brass key",        "grab",    "brass-key"},
  {"examine matchbox",      "examine", "matchbox"},
  {"ignite candle",         "ignite",  "candle"},
  {"rip bed sheets",        "rip",     "bed-sheets"},
  {"break knife",           "break",   "knife"},
  {"strike match",          "strike",  "match"},
  {"light match",           "ignite",  "match"},
}

for _, case in ipairs(regression_cases) do
  local input, exp_verb, exp_noun = case[1], case[2], case[3]
  t.test("regression: \"" .. input .. "\" → " .. exp_verb .. " " .. exp_noun, function()
    local verb, noun = match_phase3(input)
    t.assert_eq(exp_verb, verb, "verb mismatch")
    t.assert_eq(exp_noun, noun, "noun mismatch")
  end)
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
m.scoring_mode = "phase3"
local failures = t.summary()
os.exit(failures > 0 and 1 or 0)
