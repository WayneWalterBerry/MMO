-- engine/parser/embedding_matcher.lua
-- Tier 2 parser: loads the embedding index JSON as a phrase dictionary
-- and matches player input via token-overlap similarity (Jaccard index).
--
-- We can't run GTE-tiny inference in Lua, so the embedding vectors are
-- ignored at runtime here. The phrase TEXT is what we match against.
-- Real vector similarity comes later in the browser via ONNX Runtime Web.

local json = require("engine.parser.json")

local matcher = {}
matcher.__index = matcher

-- Stop words stripped from both input and phrase text before comparison
local STOP_WORDS = {
  ["the"] = true, ["a"] = true, ["an"] = true, ["some"] = true,
  ["to"] = true, ["at"] = true, ["on"] = true, ["in"] = true,
  ["of"] = true, ["my"] = true, ["its"] = true, ["this"] = true,
  ["that"] = true, ["is"] = true, ["it"] = true, ["i"] = true,
  ["and"] = true, ["or"] = true, ["with"] = true, ["for"] = true,
  ["up"] = true, ["down"] = true, ["around"] = true,
}

---------------------------------------------------------------------------
-- Tokenizer: lowercase, strip punctuation, remove stop words
---------------------------------------------------------------------------
local function tokenize(text)
  local tokens = {}
  local seen = {}
  for word in text:lower():gsub("[^%a%d%-]", " "):gmatch("%S+") do
    if not STOP_WORDS[word] and not seen[word] then
      tokens[#tokens + 1] = word
      seen[word] = true
    end
  end
  return tokens
end

local function token_set(tokens)
  local s = {}
  for _, t in ipairs(tokens) do s[t] = true end
  return s
end

---------------------------------------------------------------------------
-- Similarity: Jaccard index (|A ∩ B| / |A ∪ B|) with substring bonus
---------------------------------------------------------------------------
local function jaccard_with_bonus(input_tokens, phrase_tokens)
  local set_a = token_set(input_tokens)
  local set_b = token_set(phrase_tokens)

  local intersection = 0
  local union_set = {}

  for t in pairs(set_a) do union_set[t] = true end
  for t in pairs(set_b) do union_set[t] = true end

  -- Exact token matches
  for t in pairs(set_a) do
    if set_b[t] then
      intersection = intersection + 1
    end
  end

  -- Substring/prefix bonus: if an input token is a prefix of a phrase token
  -- (or vice versa), count a partial match
  local partial = 0
  for _, a in ipairs(input_tokens) do
    if not set_b[a] then
      for _, b in ipairs(phrase_tokens) do
        if not set_a[b] then
          if a:sub(1, 3) == b:sub(1, 3) and #a >= 3 and #b >= 3 then
            -- Shared 3+ char prefix → partial credit
            local overlap = 0
            for i = 1, math.min(#a, #b) do
              if a:sub(i, i) == b:sub(i, i) then overlap = overlap + 1
              else break end
            end
            partial = partial + (overlap / math.max(#a, #b)) * 0.5
          end
        end
      end
    end
  end

  local union_size = 0
  for _ in pairs(union_set) do union_size = union_size + 1 end

  if union_size == 0 then return 0 end
  return (intersection + partial) / union_size
end

---------------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------------
function matcher.new(index_path)
  local self = setmetatable({}, matcher)
  self.phrases = {}
  self.loaded = false
  self.diagnostic = true -- diagnostic mode on by default during playtesting

  local f = io.open(index_path, "r")
  if not f then
    io.stderr:write("[Parser] Warning: embedding index not found: " .. index_path .. "\n")
    return self
  end

  local content = f:read("*a")
  f:close()

  local ok, index = pcall(json.decode, content)
  if not ok then
    io.stderr:write("[Parser] Warning: failed to parse embedding index: " .. tostring(index) .. "\n")
    return self
  end

  -- Build phrase dictionary (we skip the embedding vectors — Lua doesn't use them)
  for _, entry in ipairs(index.phrases or {}) do
    self.phrases[#self.phrases + 1] = {
      text = entry.text,
      verb = entry.verb,
      noun = entry.noun,
      tokens = tokenize(entry.text),
    }
  end

  self.loaded = true
  io.stderr:write("[Parser] Tier 2 loaded: " .. #self.phrases .. " phrases from index\n")
  return self
end

---------------------------------------------------------------------------
-- match(input_text) -> verb, noun, score, matched_phrase
-- Returns the best-matching phrase's verb+noun with confidence score.
-- Returns nil if no phrases loaded.
---------------------------------------------------------------------------
function matcher:match(input_text)
  if not self.loaded or #self.phrases == 0 then
    return nil, nil, 0, nil
  end

  local input_tokens = tokenize(input_text)
  if #input_tokens == 0 then
    return nil, nil, 0, nil
  end

  local best_score = -1
  local best_phrase = nil

  for _, phrase in ipairs(self.phrases) do
    local score = jaccard_with_bonus(input_tokens, phrase.tokens)
    if score > best_score then
      best_score = score
      best_phrase = phrase
    end
  end

  if best_phrase then
    return best_phrase.verb, best_phrase.noun, best_score, best_phrase.text
  end

  return nil, nil, 0, nil
end

return matcher
