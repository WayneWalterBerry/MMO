-- engine/parser/preprocess/words.lua
-- Word-level helper functions for preprocess.

local words = {}

function words.singularize_word(word)
    if not word or #word < 3 then return {} end
    local forms = {}
    -- -ies → -y (berries → berry, entries → entry)
    local ies_stem = word:match("^(.+)ies$")
    if ies_stem and #ies_stem >= 1 then forms[#forms+1] = ies_stem .. "y" end
    -- -es → strip, only after sibilants: ch, sh, s, x, z
    -- (torches → torch, boxes → box, matches → match)
    local es_stem = word:match("^(.+)es$")
    if es_stem and #es_stem >= 2
        and (es_stem:match("ch$") or es_stem:match("sh$")
             or es_stem:match("[sxz]$")) then
        forms[#forms+1] = es_stem
    end
    -- -s → strip, but not -ss (portraits → portrait, candles → candle)
    local s_stem = word:match("^(.+[^s])s$")
    if s_stem and #s_stem >= 2 then forms[#forms+1] = s_stem end
    return forms
end

return words
