-- engine/parser/init.lua
-- Tier 2 parser module: wraps the embedding matcher for use in the game loop.
-- Loads the embedding index at startup and exposes a fallback function
-- that the game loop calls when Tier 1 (rule-based verb dispatch) misses.

local embedding_matcher = require("engine.parser.embedding_matcher")

local parser = {}

-- Minimum score to accept a Tier 2 match.
-- Jaccard scores are 0-1 ratios; BM25 scores are IDF-weighted sums.
parser.THRESHOLD_JACCARD = 0.40
parser.THRESHOLD_BM25 = 3.00
parser.THRESHOLD_HYBRID = 0.20  -- MaxSim, soft cosine, phase3 (normalized 0-1 scores)

---------------------------------------------------------------------------
-- init(assets_root) -> parser instance with matcher loaded
-- assets_root: path to src/assets (e.g., script_dir .. "/assets")
---------------------------------------------------------------------------
function parser.init(assets_root, debug)
  local SEP = package.config:sub(1, 1)
  local index_path = assets_root .. SEP .. "parser" .. SEP .. "embedding-index.json"
  local m = embedding_matcher.new(index_path, debug)
  local scoring_mode = m.scoring_mode or "jaccard"
  local threshold
  if scoring_mode == "bm25" then
    threshold = parser.THRESHOLD_BM25
  elseif scoring_mode == "maxsim" or scoring_mode == "softcosine" or scoring_mode == "phase3" then
    threshold = parser.THRESHOLD_HYBRID
  else
    threshold = parser.THRESHOLD_JACCARD
  end
  local instance = {
    matcher = m,
    threshold = threshold,
    diagnostic = debug or false,
  }
  return instance
end

---------------------------------------------------------------------------
-- fallback(instance, input_text, verb_handlers) -> handled (bool)
-- Called by the game loop when Tier 1 has no handler for the parsed verb.
-- If a match is found above threshold AND a verb handler exists, executes it.
-- Returns true if handled, false if the command should fail.
---------------------------------------------------------------------------
function parser.fallback(instance, input_text, context)
  if _G.TRACE then io.stderr:write("[TRACE] embedding_matcher:match entry: " .. tostring(input_text) .. "\n") end
  local verb, noun, score, phrase = instance.matcher:match(input_text)
  if _G.TRACE then io.stderr:write("[TRACE] embedding_matcher:match exit: verb=" .. tostring(verb) .. " noun=" .. tostring(noun) .. " score=" .. tostring(score) .. "\n") end

  if verb and score > instance.threshold then
    local handler = context.verbs[verb]
    if handler then
      context.current_verb = verb
      if _G.TRACE then io.stderr:write("[TRACE] Tier 2 dispatch: " .. verb .. "(" .. tostring(noun) .. ")\n") end
      if instance.diagnostic then
        io.stderr:write(string.format(
          "[Parser] Tier 2 match: \"%s\" → %s %s (score: %.2f, phrase: \"%s\")\n",
          input_text, verb, noun or "", score, phrase or ""
        ))
      end
      handler(context, noun or "")
      if _G.TRACE then io.stderr:write("[TRACE] Tier 2 handler complete: " .. verb .. "\n") end
      return true
    end
  end

  -- Failed: show diagnostic output so Wayne can see what the parser tried
  if instance.diagnostic then
    if verb and phrase then
      print(string.format(
        '[Parser] No match found. Input: "%s" | Best: "%s %s" via "%s" (score: %.2f)',
        input_text, verb, noun or "", phrase, score
      ))
    else
      print(string.format('[Parser] No match found. Input: "%s" | No candidates.', input_text))
    end
  else
    print("I'm not sure what you mean. Try 'help' to see what you can do, or describe what you're trying to accomplish.")
  end

  return false
end

return parser
