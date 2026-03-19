-- engine/parser/init.lua
-- Tier 2 parser module: wraps the embedding matcher for use in the game loop.
-- Loads the embedding index at startup and exposes a fallback function
-- that the game loop calls when Tier 1 (rule-based verb dispatch) misses.

local embedding_matcher = require("engine.parser.embedding_matcher")

local parser = {}

-- Minimum score to accept a Tier 2 match.
-- Below this threshold, the command fails with diagnostic output.
parser.THRESHOLD = 0.40

---------------------------------------------------------------------------
-- init(assets_root) -> parser instance with matcher loaded
-- assets_root: path to src/assets (e.g., script_dir .. "/assets")
---------------------------------------------------------------------------
function parser.init(assets_root)
  local SEP = package.config:sub(1, 1)
  local index_path = assets_root .. SEP .. "parser" .. SEP .. "embedding-index.json"
  local instance = {
    matcher = embedding_matcher.new(index_path),
    threshold = parser.THRESHOLD,
    diagnostic = true,
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
  local verb, noun, score, phrase = instance.matcher:match(input_text)

  if verb and score > instance.threshold then
    local handler = context.verbs[verb]
    if handler then
      if instance.diagnostic then
        io.stderr:write(string.format(
          "[Parser] Tier 2 match: \"%s\" → %s %s (score: %.2f, phrase: \"%s\")\n",
          input_text, verb, noun or "", score, phrase or ""
        ))
      end
      handler(context, noun or "")
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
    print("I don't understand that.")
  end

  return false
end

return parser
