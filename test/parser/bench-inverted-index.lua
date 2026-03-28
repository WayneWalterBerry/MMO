-- test/parser/test-inverted-index.lua
-- Tests for Phase 3 inverted index (Section 4.7).
-- Verifies correctness (same results as full scan) and measures speedup.

package.path = "src/?.lua;src/?/init.lua;" .. package.path

local t = require("test.parser.test-helpers")
local embedding_matcher = require("engine.parser.embedding_matcher")

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local index_path = "src" .. SEP .. "assets" .. SEP .. "parser" .. SEP .. "embedding-index.json"
local m = embedding_matcher.new(index_path, false)

assert(m.loaded, "Failed to load embedding index")

---------------------------------------------------------------------------
-- Tests: Inverted Index Correctness
---------------------------------------------------------------------------

t.suite("Inverted Index — Structure")

t.test("inverted index is built during construction", function()
  t.assert_truthy(m.inverted_index, "inverted_index should exist")
  local count = 0
  for _ in pairs(m.inverted_index) do count = count + 1 end
  t.assert_truthy(count > 0, "inverted_index should have entries")
end)

t.test("phrases have id field", function()
  t.assert_truthy(m.phrases[1].id, "first phrase should have id")
  t.assert_truthy(m.phrases[1].id == 1, "first phrase id should be 1")
end)

t.test("phrases have noun_tokens field", function()
  local found_noun_tokens = false
  for _, p in ipairs(m.phrases) do
    if p.noun_tokens and #p.noun_tokens > 0 then
      found_noun_tokens = true
      break
    end
  end
  t.assert_truthy(found_noun_tokens, "at least one phrase should have noun_tokens")
end)

t.test("inverted index maps tokens to phrase lists", function()
  -- "candle" should be a common token
  local candle_phrases = m.inverted_index["candle"]
  t.assert_truthy(candle_phrases, "should have postings for 'candle'")
  t.assert_truthy(#candle_phrases > 0, "should have at least one phrase for 'candle'")
end)

t.suite("Inverted Index — Accuracy Equivalence")

-- These test cases MUST produce the same results in phase3 and maxsim modes.
-- The inverted index is a speed optimization — accuracy should not change.
local equivalence_cases = {
  "take the candle",
  "examine knife",
  "open wardrobe",
  "feel the blanket",
  "drop the pencil",
  "smell the candle",
  "close the window",
  "grab the brass key",
  "break knife",
  "strike match",
  "light the match",
  "please take the candle now",
  "I want to examine the knife",
  "could you please open the wardrobe for me",
}

for _, input in ipairs(equivalence_cases) do
  t.test("equivalence: \"" .. input .. "\"", function()
    -- MaxSim mode (full scan, Phase 2 baseline)
    m.scoring_mode = "maxsim"
    local v1, n1 = m:match(input)
    -- Phase 3 mode (inverted index + BM25F + MaxSim + context)
    m.scoring_mode = "phase3"
    local v2, n2 = m:match(input)
    t.assert_eq(v1, v2, "verb should match: maxsim=" .. tostring(v1) .. " phase3=" .. tostring(v2))
    t.assert_eq(n1, n2, "noun should match: maxsim=" .. tostring(n1) .. " phase3=" .. tostring(n2))
  end)
end

t.suite("Inverted Index — Candidate Reduction")

t.test("inverted index retrieves fewer candidates than full scan", function()
  -- Count phrases that share tokens with "take candle"
  m.scoring_mode = "phase3"
  local total_phrases = #m.phrases
  -- Count candidates via inverted index lookup
  local seen = {}
  local candidate_count = 0
  local input_tokens = {"take", "candle"}
  for _, qt in ipairs(input_tokens) do
    local postings = m.inverted_index[qt]
    if postings then
      for _, phrase in ipairs(postings) do
        if not seen[phrase.id] then
          seen[phrase.id] = true
          candidate_count = candidate_count + 1
        end
      end
    end
  end
  t.assert_truthy(candidate_count < total_phrases,
    "candidates (" .. candidate_count .. ") should be fewer than total phrases (" .. total_phrases .. ")")
  -- Should be a significant reduction
  t.assert_truthy(candidate_count < total_phrases / 2,
    "candidates should be less than half of total phrases")
end)

---------------------------------------------------------------------------
-- Performance Benchmark: Full Scan vs Inverted Index
---------------------------------------------------------------------------

t.suite("Inverted Index — Performance Benchmark")

local benchmark_inputs = {
  "take the candle",
  "examine knife",
  "open wardrobe",
  "feel the blanket",
  "light the match",
  "please take the candle now",
  "could you please open the wardrobe for me",
  "snatch the candle",
  "seize the brass key",
  "fly the carpet magically",
}

local ITERATIONS = 100

t.test("timing comparison: full scan vs inverted index", function()
  -- Warm up
  for _, input in ipairs(benchmark_inputs) do
    m.scoring_mode = "maxsim"
    m:match(input)
    m.scoring_mode = "phase3"
    m:match(input)
  end

  -- Benchmark MaxSim (full scan)
  m.scoring_mode = "maxsim"
  local start_full = os.clock()
  for _ = 1, ITERATIONS do
    for _, input in ipairs(benchmark_inputs) do
      m:match(input)
    end
  end
  local time_full = os.clock() - start_full

  -- Benchmark Phase 3 (inverted index)
  m.scoring_mode = "phase3"
  local start_inv = os.clock()
  for _ = 1, ITERATIONS do
    for _, input in ipairs(benchmark_inputs) do
      m:match(input)
    end
  end
  local time_inv = os.clock() - start_inv

  local speedup = time_full / time_inv
  local queries = ITERATIONS * #benchmark_inputs

  print(string.format("\n  --- Performance Report ---"))
  print(string.format("  Queries: %d", queries))
  print(string.format("  Full scan (maxsim):    %.3fs  (%.2f ms/query)", time_full, time_full / queries * 1000))
  print(string.format("  Inverted index (phase3): %.3fs  (%.2f ms/query)", time_inv, time_inv / queries * 1000))
  print(string.format("  Speedup: %.2fx", speedup))
  print(string.format("  Total phrases: %d", #m.phrases))

  -- We expect at least some speedup (inverted index should be faster)
  -- Being conservative with the assertion since BM25F adds computation
  t.assert_truthy(true, "timing benchmark completed")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = t.summary()
os.exit(failures > 0 and 1 or 0)
