-- engine/parser/synonym_table.lua
-- Manual POS-filtered synonyms for Tier 2 matching.
-- Format: canonical_verb = { synonym1, synonym2, ... }
-- Per D2 decision: conservative 2-3 synonyms per term.
--
-- These synonyms map NON-INDEX verbs to canonical forms that exist in the
-- phrase index. If the phrase index already has "grab candle" indexed under
-- verb=grab, we don't need grab→take here. We only need synonyms for words
-- the player might type that do NOT appear as verbs in the index.

local M = {}

-- Verb synonyms: player_word → canonical verb in phrase index
-- Only words NOT already in the embedding index as verbs
M.verbs = {
  -- Acquisition synonyms (take/get/grab are in index, these are NOT)
  snatch    = "take",
  acquire   = "take",
  collect   = "take",
  obtain    = "get",
  retrieve  = "get",
  pick      = "take",   -- "pick up" after preprocess strips "up"
  nab       = "grab",
  swipe     = "grab",
  gimme     = "get",    -- #174: casual pickup
  hold      = "get",    -- #174: "hold X" → acquire
  lift      = "get",    -- #174: "lift X" → acquire

  -- Looking synonyms (look/examine are in index)
  gaze      = "look",
  peer      = "examine",  -- #242: "peer at X" → examine (close inspection)
  check     = "examine",  -- #242: "check X" → examine
  observe   = "examine",
  inspect   = "examine",  -- #174: confirmed
  view      = "examine",
  study     = "examine",
  regard    = "examine",
  survey    = "look",
  glance    = "look",
  peek      = "examine",

  -- Open/close synonyms (open/close/shut are in index)
  unlock    = "open",
  unseal    = "open",
  unfasten  = "open",
  seal      = "close",
  fasten    = "close",
  lock      = "close",

  -- Sensory synonyms (feel/smell/taste/listen are in index)
  touch     = "feel",
  handle    = "feel",
  fondle    = "feel",
  caress    = "feel",
  inhale    = "smell",
  whiff     = "smell",
  sample    = "taste",
  sip       = "taste",
  nibble    = "taste",

  -- Destruction synonyms (break/smash/shatter/rip/tear/cut are in index)
  destroy   = "break",
  wreck     = "break",
  crush     = "smash",
  demolish  = "smash",
  slice     = "cut",
  chop      = "cut",
  sever     = "cut",
  shred     = "rip",

  -- Movement/placement (drop/put are in index)
  discard   = "drop",
  toss      = "drop",
  throw     = "drop",
  dump      = "drop",
  set       = "put",
  deposit   = "put",
  stash     = "put",

  -- Fire synonyms (ignite/burn/strike/extinguish/snuff are in index)
  kindle    = "ignite",
  inflame   = "burn",
  use       = "ignite",   -- #174: "use candle" → ignite

  -- Reading/writing (read/write are in index)
  peruse    = "read",
  skim      = "read",
  scribble  = "write",
  jot       = "write",

  -- Repair (mend/sew are in index)
  fix       = "mend",
  repair    = "mend",
  patch     = "mend",
  stitch    = "sew",

  -- Clothing (don/remove are in index)
  wear      = "don",
  equip     = "don",
  doff      = "remove",
  unequip   = "remove",

  -- Search (search/find are in index)
  rummage   = "search",
  ransack   = "search",
  locate    = "find",
  discover  = "find",
  hunt      = "search",
}

-- Reverse lookup: given a synonym, return the canonical verb
function M.canonical_verb(word)
  return M.verbs[word]
end

-- Expand input tokens: replace synonyms with canonical forms for matching
function M.expand_tokens(tokens)
  local expanded = {}
  local mappings = {}
  local seen = {}

  for _, t in ipairs(tokens) do
    local canonical = M.verbs[t]
    if canonical then
      -- Replace synonym with canonical form (don't keep the unknown original)
      if not seen[canonical] then
        expanded[#expanded + 1] = canonical
        seen[canonical] = true
      end
      mappings[t] = canonical
    else
      if not seen[t] then
        expanded[#expanded + 1] = t
        seen[t] = true
      end
    end
  end

  return expanded, mappings
end

return M
