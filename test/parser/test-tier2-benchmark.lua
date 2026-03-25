-- test/parser/test-tier2-benchmark.lua
-- A/B benchmark for Tier 2 parser: compares Jaccard vs BM25+Synonyms scoring.
-- Run: lua test/parser/test-tier2-benchmark.lua [jaccard|bm25]

package.path = "src/?.lua;src/?/init.lua;" .. package.path

local embedding_matcher = require("engine.parser.embedding_matcher")

---------------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------------
local THRESHOLD = 0.40  -- Jaccard threshold (will be overridden for BM25)
local BM25_THRESHOLD = 3.00  -- BM25 threshold (tuned after baseline run)

-- Parse CLI arg for scoring mode
local scoring_mode = arg and arg[1] or "jaccard"
if scoring_mode ~= "jaccard" and scoring_mode ~= "bm25" then
  scoring_mode = "jaccard"
end

---------------------------------------------------------------------------
-- Test cases: {input, expected_verb, expected_noun, category}
-- expected_verb=nil means negative case (should NOT match above threshold)
---------------------------------------------------------------------------
local cases = {
  -- CATEGORY 1: Exact verb+noun with filler words (20 cases)
  -- These use verbs that exist in the index with extra words
  {"please take the candle now",          "take",     "candle",       "filler"},
  {"I want to examine the knife",         "examine",  "knife",        "filler"},
  {"go ahead and open the wardrobe",      "open",     "wardrobe",     "filler"},
  {"try to feel the blanket gently",      "feel",     "blanket",      "filler"},
  {"can you drop the pencil please",      "drop",     "pencil",       "filler"},
  {"let me smell the candle",             "smell",    "candle",       "filler"},
  {"I would like to read the paper",      "read",     "paper",        "filler"},
  {"just close the window now",           "close",    "window",       "filler"},
  {"quickly grab the brass key",          "grab",     "brass-key",    "filler"},
  {"please examine the matchbox",         "examine",  "matchbox",     "filler"},
  {"hurry and take the pillow",           "take",     "pillow",       "filler"},
  {"could you get the needle",            "get",      "needle",       "filler"},
  {"try to cut the cloth here",           "cut",      "cloth",        "filler"},
  {"I need to burn the rag",              "burn",     "rag",          "filler"},
  {"carefully feel the curtains",         "feel",     "curtains",     "filler"},
  {"quickly rip the bed sheets",          "rip",      "bed-sheets",   "filler"},
  {"please mend the sack",               "mend",     "sack",         "filler"},
  {"now taste the poison bottle",         "lick",     "poison-bottle","filler"},
  {"I shall strike the match",            "strike",   "match",        "filler"},
  {"do ignite the candle",               "ignite",   "candle",       "filler"},

  -- CATEGORY 2: Synonym verbs NOT in the index (15 cases)
  -- These verbs are NOT in the phrase index; synonym expansion needed
  {"snatch the candle",                   "take",     "candle",       "synonym"},
  {"collect the brass key",               "take",     "brass-key",    "synonym"},
  {"obtain the needle",                   "get",      "needle",       "synonym"},
  {"retrieve the pencil",                 "get",      "pencil",       "synonym"},
  {"observe the knife",                   "examine",  "knife",        "synonym"},  {"check the matchbox",                  "examine",  "matchbox",     "synonym"},
  {"peer at the window",                  "examine",  "window",       "synonym"},
  {"unlock the wardrobe",                 "open",     "wardrobe",     "synonym"},
  {"toss the pencil",                     "drop",     "pencil",       "synonym"},
  {"discard the rag",                     "drop",     "rag",          "synonym"},
  {"fix the sack",                        "mend",     "sack",         "synonym"},
  {"destroy the candle",                  "break",    "candle",       "synonym"},
  {"slice the cloth",                     "cut",      "cloth",        "synonym"},
  {"kindle the candle",                   "ignite",   "candle",       "synonym"},
  {"stitch the blanket",                  "sew",      "blanket",      "synonym"},

  -- CATEGORY 3: Polite/verbose input (10 cases)
  {"could you please open the wardrobe for me",  "open",    "wardrobe",    "polite"},
  {"would you be so kind as to take the candle",  "take",    "candle",      "polite"},
  {"I really think we should examine the knife closely", "examine", "knife", "polite"},
  {"perhaps you might want to read the paper",    "read",    "paper",       "polite"},
  {"if possible please close the window",         "close",   "window",      "polite"},
  {"I was hoping to feel the wool cloak",         "feel",    "wool-cloak",  "polite"},
  {"it would be great to smell the candle",       "smell",   "candle",      "polite"},
  {"hey can you drop the pen right here",         "drop",    "pen",         "polite"},
  {"try and see if you can cut the rug",          "cut",     "rug",         "polite"},
  {"maybe we should taste the poison bottle",     "lick",   "poison-bottle","polite"},

  -- CATEGORY 4: Negative cases — should NOT match (10 cases)
  -- Either nonsensical combinations or no relevant phrase exists
  {"fly the carpet magically",            nil,        nil,            "negative"},
  {"teleport to the moon",                nil,        nil,            "negative"},
  {"xerox the manifesto",                 nil,        nil,            "negative"},
  {"program the computer",                nil,        nil,            "negative"},
  {"dance on the ceiling",                nil,        nil,            "negative"},
  {"summon a dragon here",                nil,        nil,            "negative"},
  {"hack the mainframe now",              nil,        nil,            "negative"},
  {"google the answer please",            nil,        nil,            "negative"},
  {"photocopy the evidence",              nil,        nil,            "negative"},
  {"microwave the leftovers",             nil,        nil,            "negative"},

  -- CATEGORY 5: Ambiguous/tricky (5 cases)
  -- "light" as verb (ignite) vs noun (candle-lit)
  {"light the match",                     "ignite",   "match",        "ambiguous"},
  -- "match" as noun (the matchstick)
  {"take the match",                      "take",     "match",        "ambiguous"},
  -- "open" + state-variant noun
  {"examine the open nightstand",         "examine",  "nightstand-open", "ambiguous"},
  -- short input
  {"break knife",                         "break",    "knife",        "ambiguous"},
  -- verb that could be noun
  {"strike match",                        "strike",   "match",        "ambiguous"},
}

---------------------------------------------------------------------------
-- Load the matcher
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local index_path = "src" .. SEP .. "assets" .. SEP .. "parser" .. SEP .. "embedding-index.json"
local m = embedding_matcher.new(index_path, false)

if not m.loaded then
  print("ERROR: Could not load embedding index from " .. index_path)
  os.exit(1)
end

-- Set scoring mode
m.scoring_mode = scoring_mode

local threshold = scoring_mode == "bm25" and BM25_THRESHOLD or THRESHOLD

---------------------------------------------------------------------------
-- Run benchmark
---------------------------------------------------------------------------
local correct = 0
local false_positives = 0
local false_negatives = 0
local total = #cases
local category_stats = {}
local details = {}

for i, case in ipairs(cases) do
  local input, exp_verb, exp_noun, category = case[1], case[2], case[3], case[4]
  local verb, noun, score, phrase = m:match(input)

  local above_threshold = score > threshold
  local is_negative = (exp_verb == nil)
  local is_correct = false

  if is_negative then
    -- Negative case: correct if score is below threshold
    is_correct = not above_threshold
    if above_threshold then
      false_positives = false_positives + 1
    end
  else
    -- Positive case: correct if verb+noun match AND score above threshold
    if above_threshold and verb == exp_verb and noun == exp_noun then
      is_correct = true
    elseif above_threshold and verb == exp_verb and not exp_noun then
      is_correct = true  -- noun not specified
    else
      false_negatives = false_negatives + 1
    end
  end

  if is_correct then correct = correct + 1 end

  -- Track per-category stats
  if not category_stats[category] then
    category_stats[category] = {total = 0, correct = 0}
  end
  category_stats[category].total = category_stats[category].total + 1
  if is_correct then
    category_stats[category].correct = category_stats[category].correct + 1
  end

  -- Store details for verbose output
  details[#details + 1] = {
    ok = is_correct,
    input = input,
    exp_verb = exp_verb,
    exp_noun = exp_noun,
    got_verb = verb,
    got_noun = noun,
    score = score,
    phrase = phrase,
    category = category,
  }
end

---------------------------------------------------------------------------
-- Print results
---------------------------------------------------------------------------
local algo_name = scoring_mode == "bm25" and "BM25 + Synonyms (improved)" or "Jaccard (baseline)"

print(string.format("\n=== TIER 2 A/B BENCHMARK ==="))
print(string.format("Algorithm: %s", algo_name))
print(string.format("Threshold: %.2f", threshold))
print(string.format("Correct: %d/%d (%.1f%%)", correct, total, 100 * correct / total))
print(string.format("False positives: %d", false_positives))
print(string.format("False negatives: %d", false_negatives))

print("\n--- Per-Category ---")
local cat_order = {"filler", "synonym", "polite", "negative", "ambiguous"}
for _, cat in ipairs(cat_order) do
  local s = category_stats[cat]
  if s then
    print(string.format("  %-12s %d/%d (%.0f%%)", cat, s.correct, s.total, 100 * s.correct / s.total))
  end
end

-- Print failures for debugging
local show_failures = true
if show_failures then
  print("\n--- Failures ---")
  local fail_count = 0
  for _, d in ipairs(details) do
    if not d.ok then
      fail_count = fail_count + 1
      if d.exp_verb then
        print(string.format("  MISS [%s] \"%s\"", d.category, d.input))
        print(string.format("       expected: %s %s", d.exp_verb, d.exp_noun or ""))
        print(string.format("       got:      %s %s (score: %.4f, phrase: \"%s\")",
          tostring(d.got_verb), tostring(d.got_noun), d.score, tostring(d.phrase)))
      else
        print(string.format("  FP   [%s] \"%s\"", d.category, d.input))
        print(string.format("       should not match, got: %s %s (score: %.4f)",
          tostring(d.got_verb), tostring(d.got_noun), d.score))
      end
    end
  end
  if fail_count == 0 then
    print("  (none)")
  end
end

-- Exit code for CI
if correct < total then
  print(string.format("\n--- %d/%d passed (%.1f%%) ---", correct, total, 100 * correct / total))
end

-- Return results table for programmatic use
return {
  algorithm = algo_name,
  correct = correct,
  total = total,
  false_positives = false_positives,
  false_negatives = false_negatives,
  accuracy = correct / total,
}
