-- engine/parser/word_similarity.lua
-- Precomputed sparse word-to-word similarity matrix for soft matching.
-- Built manually from game vocabulary (~200 words).
--
-- Format: word1 -> { word2 = similarity, ... }
-- Only pairs with similarity > 0.3 are stored.
-- Symmetric: if S["a"]["b"] exists, S["b"]["a"] should too.
--
-- Sources:
--   - synonym_table.lua verb mappings (synonym pairs get sim >= 0.8)
--   - Semantic groupings from the phrase index vocabulary
--   - Related-but-not-synonym pairs get moderate similarity (0.3-0.7)

local M = {}

---------------------------------------------------------------------------
-- Helper: define a bidirectional similarity pair
---------------------------------------------------------------------------
local function pair(a, b, sim)
  if not M[a] then M[a] = {} end
  if not M[b] then M[b] = {} end
  M[a][b] = sim
  M[b][a] = sim
end

---------------------------------------------------------------------------
-- VERB SYNONYM GROUPS (from synonym_table.lua — high similarity)
---------------------------------------------------------------------------

-- Acquisition verbs: take/get/grab and their synonyms
pair("take", "get", 0.90)
pair("take", "grab", 0.95)
pair("take", "snatch", 0.90)
pair("take", "acquire", 0.85)
pair("take", "collect", 0.85)
pair("take", "pick", 0.85)
pair("take", "fetch", 0.85)
pair("take", "hold", 0.70)
pair("take", "lift", 0.75)
pair("take", "gimme", 0.80)
pair("get", "grab", 0.90)
pair("get", "obtain", 0.90)
pair("get", "retrieve", 0.85)
pair("get", "fetch", 0.90)
pair("get", "collect", 0.80)
pair("get", "snatch", 0.80)
pair("grab", "seize", 0.90)
pair("grab", "clutch", 0.85)
pair("grab", "nab", 0.85)
pair("grab", "swipe", 0.80)
pair("grab", "snatch", 0.90)
pair("grab", "fumble", 0.60)
pair("grab", "grip", 0.85)
pair("hold", "clutch", 0.80)
pair("hold", "seize", 0.75)
pair("hold", "grip", 0.85)
pair("lift", "pick", 0.80)
pair("take", "yank", 0.80)
pair("grab", "yank", 0.75)
pair("get", "yank", 0.70)

-- Looking verbs: look/examine and synonyms
pair("look", "examine", 0.80)
pair("look", "gaze", 0.85)
pair("look", "survey", 0.85)
pair("look", "glance", 0.85)
pair("look", "peer", 0.75)
pair("look", "observe", 0.80)
pair("examine", "inspect", 0.90)
pair("examine", "study", 0.90)
pair("examine", "check", 0.85)
pair("examine", "observe", 0.90)
pair("examine", "peer", 0.80)
pair("examine", "view", 0.85)
pair("examine", "regard", 0.80)
pair("examine", "peek", 0.75)
pair("inspect", "check", 0.85)
pair("inspect", "study", 0.85)
pair("inspect", "observe", 0.85)
pair("x", "examine", 0.95)
pair("x", "look", 0.80)

-- Open/close verbs
pair("open", "unlock", 0.85)
pair("open", "unseal", 0.80)
pair("open", "unfasten", 0.80)
pair("close", "shut", 0.95)
pair("close", "slam", 0.80)
pair("close", "seal", 0.80)
pair("close", "fasten", 0.80)
pair("close", "lock", 0.75)
pair("shut", "slam", 0.85)

-- Sensory verbs: feel/smell/taste/listen
pair("feel", "touch", 0.95)
pair("feel", "handle", 0.80)
pair("feel", "fondle", 0.80)
pair("feel", "caress", 0.80)
pair("feel", "grope", 0.85)
pair("smell", "sniff", 0.95)
pair("smell", "inhale", 0.80)
pair("smell", "whiff", 0.85)
pair("smell", "breathe", 0.60)
pair("taste", "lick", 0.90)
pair("taste", "sample", 0.85)
pair("taste", "sip", 0.80)
pair("taste", "nibble", 0.75)
pair("listen", "hear", 0.95)

-- Destruction verbs
pair("break", "smash", 0.90)
pair("break", "shatter", 0.90)
pair("break", "destroy", 0.85)
pair("break", "wreck", 0.85)
pair("break", "bash", 0.80)
pair("smash", "shatter", 0.90)
pair("smash", "crush", 0.85)
pair("smash", "demolish", 0.85)
pair("smash", "bash", 0.85)
pair("rip", "tear", 0.95)
pair("rip", "shred", 0.90)
pair("cut", "slice", 0.90)
pair("cut", "chop", 0.85)
pair("cut", "sever", 0.85)
pair("cut", "slash", 0.90)

-- Movement/placement
pair("drop", "discard", 0.85)
pair("drop", "toss", 0.80)
pair("drop", "throw", 0.80)
pair("drop", "dump", 0.80)
pair("drop", "release", 0.80)
pair("put", "place", 0.95)
pair("put", "set", 0.85)
pair("put", "deposit", 0.80)
pair("put", "stash", 0.75)
pair("toss", "throw", 0.90)

-- Fire verbs
pair("ignite", "light", 0.90)
pair("ignite", "kindle", 0.85)
pair("burn", "incinerate", 0.85)
pair("burn", "inflame", 0.80)
pair("burn", "fire", 0.70)
pair("ignite", "burn", 0.70)
pair("extinguish", "snuff", 0.90)
pair("extinguish", "blow", 0.70)

-- Reading/writing
pair("read", "peruse", 0.90)
pair("read", "skim", 0.80)
pair("read", "scan", 0.80)
pair("write", "inscribe", 0.85)
pair("write", "engrave", 0.80)
pair("write", "etch", 0.80)
pair("write", "scribble", 0.80)
pair("write", "jot", 0.80)
pair("inscribe", "engrave", 0.90)
pair("inscribe", "etch", 0.85)

-- Repair verbs
pair("mend", "repair", 0.95)
pair("mend", "fix", 0.90)
pair("mend", "patch", 0.85)
pair("sew", "stitch", 0.95)
pair("sew", "mend", 0.70)
pair("stitch", "mend", 0.65)

-- Clothing verbs
pair("don", "wear", 0.90)
pair("don", "equip", 0.85)
pair("remove", "doff", 0.85)
pair("remove", "unequip", 0.85)

-- Search/find
pair("search", "rummage", 0.90)
pair("search", "ransack", 0.80)
pair("search", "hunt", 0.75)
pair("find", "locate", 0.90)
pair("find", "discover", 0.85)
pair("find", "spot", 0.80)
pair("search", "find", 0.70)

-- Combat verbs
pair("strike", "hit", 0.90)
pair("strike", "whack", 0.85)
pair("strike", "bash", 0.80)
pair("hit", "whack", 0.85)
pair("hit", "bash", 0.80)
pair("prick", "poke", 0.90)
pair("prick", "jab", 0.85)
pair("poke", "jab", 0.85)

-- Consume verbs
pair("consume", "eat", 0.90)
pair("consume", "devour", 0.85)
pair("consume", "gobble", 0.80)
pair("consume", "ingest", 0.90)
pair("eat", "devour", 0.90)
pair("eat", "gobble", 0.85)
pair("eat", "ingest", 0.85)

---------------------------------------------------------------------------
-- NOUN SIMILARITY GROUPS (related game objects)
---------------------------------------------------------------------------

-- Light sources
pair("candle", "tallow", 0.70)
pair("candle", "match", 0.50)
pair("candle", "lamp", 0.50)
pair("candle", "light", 0.45)
pair("match", "matchbox", 0.70)

-- Writing implements
pair("pen", "pencil", 0.80)
pair("pen", "ink", 0.60)
pair("pencil", "graphite", 0.60)
pair("paper", "sheet", 0.60)
pair("paper", "blank", 0.40)

-- Fabric/cloth items
pair("cloth", "rag", 0.70)
pair("cloth", "blanket", 0.55)
pair("cloth", "cloak", 0.50)
pair("rag", "bandage", 0.50)
pair("blanket", "sheets", 0.60)
pair("blanket", "pillow", 0.45)
pair("thread", "needle", 0.60)
pair("thread", "spool", 0.70)
pair("sack", "burlap", 0.60)
pair("jacket", "cloak", 0.55)
pair("wool", "cloth", 0.55)
pair("wool", "thread", 0.50)

-- Furniture
pair("bed", "pillow", 0.50)
pair("bed", "blanket", 0.50)
pair("bed", "sheets", 0.55)
pair("nightstand", "drawer", 0.55)
pair("wardrobe", "drawer", 0.45)
pair("vanity", "mirror", 0.60)

-- Container nouns
pair("drawer", "nightstand", 0.55)
pair("bottle", "pot", 0.40)
pair("sack", "bag", 0.85)

-- Materials
pair("glass", "mirror", 0.55)
pair("glass", "shard", 0.65)
pair("glass", "window", 0.50)
pair("mirror", "window", 0.40)
pair("brass", "key", 0.40)
pair("oak", "wooden", 0.70)
pair("wood", "oak", 0.75)
pair("wood", "wooden", 0.90)
pair("velvet", "cloth", 0.50)
pair("ceramic", "pot", 0.55)

-- Sharp objects
pair("knife", "blade", 0.80)
pair("knife", "shard", 0.50)
pair("needle", "pin", 0.70)
pair("needle", "knife", 0.35)

-- Door/passage related
pair("door", "gate", 0.60)
pair("door", "window", 0.40)
pair("curtains", "drapes", 0.90)
pair("curtains", "window", 0.45)
pair("rug", "carpet", 0.85)

---------------------------------------------------------------------------
-- CROSS-POS SIMILARITIES (verb-noun overlaps in game context)
---------------------------------------------------------------------------

-- "light" is both a verb (ignite) and noun concept
pair("light", "candle", 0.40)
pair("light", "match", 0.45)
pair("fire", "match", 0.50)
pair("fire", "candle", 0.40)

-- "strike" is both verb and relates to matches
pair("strike", "match", 0.40)

return M
