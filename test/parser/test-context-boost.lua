-- test/parser/test-context-boost.lua
-- Tests for Phase 3 context-aware recency boosting (Section 4.6).
-- Verifies that recently interacted objects get score boosts in Tier 2.

package.path = "src/?.lua;src/?/init.lua;" .. package.path

local t = require("test.parser.test-helpers")
local embedding_matcher = require("engine.parser.embedding_matcher")
local context = require("engine.parser.context")

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
local function match(input)
  return m:match(input)
end

local function push_object(id)
  context.push({ id = id, name = id, keywords = { id } })
end

---------------------------------------------------------------------------
-- Tests: Context-Aware Recency Boost
---------------------------------------------------------------------------

t.suite("Context Boost — Recency Scoring")

t.test("recency_score returns 0 for unknown object", function()
  context.reset()
  t.assert_eq(0, context.recency_score("nonexistent"), "unknown object")
end)

t.test("recency_score returns max for most recent object", function()
  context.reset()
  push_object("candle")
  push_object("knife")
  push_object("match")
  -- match is most recent (index 1), stack max is 5
  t.assert_eq(5, context.recency_score("match"), "most recent = max score")
  t.assert_eq(4, context.recency_score("knife"), "second most recent")
  t.assert_eq(3, context.recency_score("candle"), "third most recent")
end)

t.test("recency_score returns 0 after reset", function()
  context.reset()
  push_object("candle")
  context.reset()
  t.assert_eq(0, context.recency_score("candle"), "after reset")
end)

t.suite("Context Boost — Parser Integration")

t.test("context boost does not change result when context is empty", function()
  context.reset()
  local verb, noun = match("take the candle")
  t.assert_eq("take", verb, "verb should be take")
  t.assert_eq("candle", noun, "noun should be candle")
end)

t.test("context boost increases score for recently examined object", function()
  context.reset()
  -- Score without context
  local _, _, score_without = match("examine candle")
  -- Push candle to context (player just interacted with it)
  push_object("candle")
  local _, _, score_with = match("examine candle")
  t.assert_truthy(score_with > score_without,
    "score with context (" .. string.format("%.4f", score_with) ..
    ") should exceed score without (" .. string.format("%.4f", score_without) .. ")")
  context.reset()
end)

t.test("more recent objects get higher boost", function()
  context.reset()
  push_object("knife")
  push_object("candle")  -- candle is more recent
  local _, _, score_candle = match("examine candle")
  context.reset()
  push_object("candle")
  push_object("knife")  -- knife is more recent now
  local _, _, score_candle2 = match("examine candle")
  -- When candle is more recent, its score should be higher
  t.assert_truthy(score_candle > score_candle2,
    "more recent candle (" .. string.format("%.4f", score_candle) ..
    ") should score higher than less recent (" .. string.format("%.4f", score_candle2) .. ")")
  context.reset()
end)

t.test("context boost does not affect objects not in context", function()
  context.reset()
  push_object("match")
  -- "examine knife" — knife is NOT in context, should not be boosted
  local _, _, score_knife = match("examine knife")
  context.reset()
  local _, _, score_knife2 = match("examine knife")
  t.assert_eq(score_knife, score_knife2,
    "knife score should be identical with/without unrelated context")
  context.reset()
end)

t.test("context boost works for ambiguous input", function()
  context.reset()
  -- "light it" is ambiguous — both match and candle can be "lit"
  -- Without context, the parser picks based on pure scoring
  local verb1, noun1 = match("light it")
  -- Push candle to context
  push_object("candle")
  local verb2, noun2 = match("light candle")
  t.assert_eq("ignite", verb2, "should resolve to ignite verb")
  t.assert_eq("candle", noun2, "should resolve to candle noun")
  context.reset()
end)

t.suite("Context Boost — Phase 3 vs Other Modes")

t.test("context boost only applies in phase3 mode", function()
  context.reset()
  push_object("candle")
  -- Phase 3 without context vs with context
  context.reset()
  m.scoring_mode = "phase3"
  local _, _, score_no_ctx = match("examine candle")
  push_object("candle")
  local _, _, score_with_ctx = match("examine candle")
  t.assert_truthy(score_with_ctx > score_no_ctx,
    "phase3 with context (" .. string.format("%.4f", score_with_ctx) ..
    ") should score higher than without (" .. string.format("%.4f", score_no_ctx) .. ")")
  context.reset()
end)

t.test("maxsim mode ignores context boost", function()
  context.reset()
  push_object("candle")
  m.scoring_mode = "maxsim"
  local _, _, maxsim_score1 = match("examine candle")
  context.reset()
  local _, _, maxsim_score2 = match("examine candle")
  -- MaxSim should give same score regardless of context
  t.assert_eq(maxsim_score1, maxsim_score2,
    "maxsim should ignore context")
  m.scoring_mode = "phase3"
  context.reset()
end)

-- Restore scoring mode
m.scoring_mode = "phase3"

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = t.summary()
os.exit(failures > 0 and 1 or 0)
