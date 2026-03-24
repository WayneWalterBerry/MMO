-- engine/parser/fuzzy.lua
-- Tier 5: Fuzzy Noun Resolution
-- Owned by Smithers (UI Engineer). Pure functions, no side effects.
--
-- Provides fallback noun matching when exact keyword matching fails:
--   1. Material matching: "the wooden thing" → objects with material="wood"
--   2. Property matching: "the heavy one" → match by weight/size
--   3. Partial name match: "that bottle" → "small glass bottle" (unambiguous)
--   4. Typo tolerance: "nighstand" → "nightstand" via Levenshtein distance
--   5. Disambiguation prompt: multiple matches → ask the player
--
-- Only fires when exact matching fails (don't slow down the happy path).

local fuzzy = {}

---------------------------------------------------------------------------
-- Levenshtein edit distance
-- Reuses the algorithm from embedding_matcher.lua for consistency.
---------------------------------------------------------------------------
function fuzzy.levenshtein(a, b)
    local la, lb = #a, #b
    if la == 0 then return lb end
    if lb == 0 then return la end
    local prev = {}
    local curr = {}
    for j = 0, lb do prev[j] = j end
    for i = 1, la do
        curr[0] = i
        for j = 1, lb do
            local cost = (a:sub(i, i) == b:sub(j, j)) and 0 or 1
            curr[j] = math.min(
                prev[j] + 1,
                curr[j - 1] + 1,
                prev[j - 1] + cost
            )
        end
        prev, curr = curr, prev
    end
    return prev[lb]
end

---------------------------------------------------------------------------
-- Typo tolerance thresholds (per D-BUG018: no fuzzy on short words)
-- ≤3 chars: exact only. 4 chars: distance ≤1. 5-7: distance ≤2. 8+: distance ≤2.
-- Tier 5 enhancement: allow single typo for 4-char words (e.g., "dor" → "door")
---------------------------------------------------------------------------
function fuzzy.max_typo_distance(word_len)
    if word_len <= 3 then return 0 end
    if word_len == 4 then return 1 end
    if word_len <= 7 then return 2 end
    return 2
end

---------------------------------------------------------------------------
-- Material adjective → material value mapping
---------------------------------------------------------------------------
local MATERIAL_ADJECTIVES = {
    wooden = "wood", wood = "wood",
    metal = "metal", metallic = "metal",
    brass = "brass", bronze = "bronze",
    iron = "iron", steel = "steel",
    glass = "glass", crystal = "crystal",
    stone = "stone", rocky = "stone",
    cloth = "cloth", fabric = "cloth",
    leather = "leather",
    paper = "paper", parchment = "parchment",
    wax = "wax", waxen = "wax",
    ceramic = "ceramic", clay = "ceramic",
    silver = "silver", gold = "gold",
    copper = "copper", tin = "tin",
    bone = "bone",
    rubber = "rubber",
    silk = "silk",
    wool = "wool", woolen = "wool",
    cotton = "cotton",
    linen = "linen",
    velvet = "velvet",
    rope = "rope",
    porcelain = "porcelain",
}

fuzzy.MATERIAL_ADJECTIVES = MATERIAL_ADJECTIVES

---------------------------------------------------------------------------
-- Property adjective → property/comparator mapping
---------------------------------------------------------------------------
local PROPERTY_ADJECTIVES = {
    heavy  = { field = "weight", compare = "high" },
    light  = { field = "weight", compare = "low" },
    big    = { field = "size",   compare = "high" },
    large  = { field = "size",   compare = "high" },
    small  = { field = "size",   compare = "low" },
    tiny   = { field = "size",   compare = "low" },
    little = { field = "size",   compare = "low" },
}

fuzzy.PROPERTY_ADJECTIVES = PROPERTY_ADJECTIVES

---------------------------------------------------------------------------
-- Parse a fuzzy noun phrase into components:
--   "the wooden thing" → { material_adj = "wooden", base_noun = "thing" }
--   "the heavy one"    → { property_adj = "heavy", base_noun = "one" }
--   "that bottle"      → { base_noun = "bottle" }
---------------------------------------------------------------------------
function fuzzy.parse_noun_phrase(noun)
    if not noun or noun == "" then return nil end
    local kw = noun:lower()
        :gsub("^the%s+", "")
        :gsub("^a%s+", "")
        :gsub("^an%s+", "")
        :gsub("^that%s+", "")
        :gsub("^this%s+", "")

    if kw == "" then return nil end

    local result = { raw = kw }

    -- Check for material adjective as first word
    local first, rest = kw:match("^(%S+)%s+(.+)$")
    if first then
        if MATERIAL_ADJECTIVES[first] then
            result.material_adj = first
            result.material_value = MATERIAL_ADJECTIVES[first]
            result.base_noun = rest
            return result
        end
        if PROPERTY_ADJECTIVES[first] then
            result.property_adj = first
            result.property_spec = PROPERTY_ADJECTIVES[first]
            result.base_noun = rest
            return result
        end
    end

    result.base_noun = kw
    return result
end

---------------------------------------------------------------------------
-- Gather all visible objects from context (room + surfaces + hands + bags + worn)
-- Returns flat list of { obj = <table>, loc = <string>, parent = <obj|nil>, surface = <string|nil> }
---------------------------------------------------------------------------
function fuzzy.gather_visible(ctx)
    local results = {}
    local room = ctx.current_room
    local reg = ctx.registry
    local seen = {}

    local function add(obj, loc, parent, surface)
        if obj and not seen[obj.id or tostring(obj)] then
            seen[obj.id or tostring(obj)] = true
            results[#results + 1] = { obj = obj, loc = loc, parent = parent, surface = surface }
        end
    end

    -- Room contents (non-hidden)
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and not obj.hidden then
            add(obj, "room", nil, nil)
            -- Surface contents
            if obj.surfaces then
                for sname, zone in pairs(obj.surfaces) do
                    if zone.accessible ~= false then
                        for _, item_id in ipairs(zone.contents or {}) do
                            local item = reg:get(item_id)
                            if item then
                                add(item, "surface", obj, sname)
                                -- Nested container contents
                                if item.contents then
                                    for _, inner_id in ipairs(item.contents) do
                                        local inner = reg:get(inner_id)
                                        if inner then add(inner, "container", item, nil) end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            -- Parts
            if obj.parts then
                for part_key, part in pairs(obj.parts) do
                    add(part, "part", obj, part_key)
                end
            end
        end
    end

    -- Player hands
    local player = ctx.player
    for i = 1, 2 do
        local hand = player.hands[i]
        if hand then
            local obj = type(hand) == "table" and hand or reg:get(hand)
            if obj then
                add(obj, "hand", nil, nil)
                -- Bag contents
                if obj.container and obj.contents then
                    for _, item_id in ipairs(obj.contents) do
                        local item = reg:get(item_id)
                        if item then add(item, "bag", obj, nil) end
                    end
                end
                -- Parts of held objects
                if obj.parts then
                    for pk, part in pairs(obj.parts) do
                        add(part, "part", obj, pk)
                    end
                end
            end
        end
    end

    -- Worn items
    for _, worn_id in ipairs(player.worn or {}) do
        local obj = reg:get(worn_id)
        if obj then
            add(obj, "worn", nil, nil)
            if obj.container and obj.contents then
                for _, item_id in ipairs(obj.contents) do
                    local item = reg:get(item_id)
                    if item then add(item, "bag", obj, nil) end
                end
            end
        end
    end

    return results
end

---------------------------------------------------------------------------
-- Build a flat list of matchable strings for an object (name + keywords + id)
---------------------------------------------------------------------------
local function matchable_strings(obj)
    local strings = {}
    if obj.name then strings[#strings + 1] = obj.name:lower() end
    if obj.id then strings[#strings + 1] = obj.id:lower() end
    if type(obj.keywords) == "table" then
        for _, k in ipairs(obj.keywords) do
            strings[#strings + 1] = k:lower()
        end
    end
    return strings
end

---------------------------------------------------------------------------
-- Score a single object against a fuzzy noun phrase.
-- Returns: score (0 = no match, higher = better), match_reason (string)
---------------------------------------------------------------------------
function fuzzy.score_object(obj, parsed)
    if not obj or not parsed then return 0, nil end
    local base = parsed.base_noun or parsed.raw

    -- Generic nouns that match by adjective alone
    local generic_nouns = { thing = true, one = true, object = true, item = true, stuff = true }

    ---------------------------------------------------------------------------
    -- 1. Material matching: "the wooden thing"
    ---------------------------------------------------------------------------
    if parsed.material_value then
        local obj_material = obj.material and obj.material:lower() or nil
        local obj_cats = obj.categories or {}

        local material_match = false
        if obj_material == parsed.material_value then
            material_match = true
        end
        -- Also check categories for material
        if not material_match then
            for _, cat in ipairs(obj_cats) do
                if cat:lower() == parsed.material_value
                    or cat:lower() == parsed.material_adj then
                    material_match = true
                    break
                end
            end
        end

        if material_match then
            if generic_nouns[base] then
                return 3, "material"
            end
            -- Material + partial name
            for _, s in ipairs(matchable_strings(obj)) do
                if s:find(base, 1, true) then
                    return 5, "material+name"
                end
            end
            return 2, "material_only"
        end
        return 0, nil
    end

    ---------------------------------------------------------------------------
    -- 2. Property matching: "the heavy one"
    ---------------------------------------------------------------------------
    if parsed.property_spec then
        local spec = parsed.property_spec
        local val = obj[spec.field]
        if val and type(val) == "number" then
            if generic_nouns[base] then
                return 3, "property"
            end
            -- Property + partial name
            for _, s in ipairs(matchable_strings(obj)) do
                if s:find(base, 1, true) then
                    return 5, "property+name"
                end
            end
            return 0, nil
        end
        return 0, nil
    end

    ---------------------------------------------------------------------------
    -- 3. Partial name match: "bottle" → "small glass bottle"
    -- Requires base noun ≥3 chars to avoid spurious substring matches.
    -- #71: Check exact keyword/id match first (priority over partial).
    ---------------------------------------------------------------------------
    if #base >= 3 then
        -- Pass 1: exact match on any keyword/id/name (highest priority)
        for _, s in ipairs(matchable_strings(obj)) do
            if s == base then return 10, "exact" end
        end
        -- Pass 2: substring match (lower priority)
        for _, s in ipairs(matchable_strings(obj)) do
            if s:find(base, 1, true) then
                return 4, "partial"
            end
        end
    end

    ---------------------------------------------------------------------------
    -- 4. Typo tolerance via Levenshtein distance
    -- #71: Tighten length ratio check — the shorter word must be at least 75%
    -- of the longer word's length. Prevents "cloak"→"oak" false positives
    -- (3/5=60% < 75% → rejected).
    ---------------------------------------------------------------------------
    local max_dist = fuzzy.max_typo_distance(#base)
    if max_dist > 0 then
        local best_dist = max_dist + 1
        for _, s in ipairs(matchable_strings(obj)) do
            -- Compare against each word in multi-word strings too
            for word in s:gmatch("%S+") do
                local shorter = math.min(#word, #base)
                local longer = math.max(#word, #base)
                if math.abs(#word - #base) <= max_dist
                    and shorter / longer >= 0.75 then
                    local d = fuzzy.levenshtein(base, word)
                    if d < best_dist then best_dist = d end
                end
            end
            -- Also compare against full string for single-word keywords
            if not s:find(" ") then
                local shorter = math.min(#s, #base)
                local longer = math.max(#s, #base)
                if math.abs(#s - #base) <= max_dist
                    and shorter / longer >= 0.75 then
                    local d = fuzzy.levenshtein(base, s)
                    if d < best_dist then best_dist = d end
                end
            end
        end
        if best_dist <= max_dist then
            -- Tier 5: Score relative to max_dist so all accepted typos meet MIN_CONFIDENCE
            return max_dist - best_dist + 3, "typo"
        end
    end

    return 0, nil
end

---------------------------------------------------------------------------
-- Rank visible objects by fuzzy match quality for property comparisons.
-- For "heavy one": pick the highest-weight object among matches.
-- For "light one": pick the lowest-weight object.
---------------------------------------------------------------------------
local function rank_by_property(matches, spec)
    if #matches <= 1 then return matches end
    table.sort(matches, function(a, b)
        local va = a.obj[spec.field] or 0
        local vb = b.obj[spec.field] or 0
        if spec.compare == "high" then return va > vb end
        return va < vb
    end)
    -- If top two have different values, the top one is clearly "the heavy one"
    local top_val = matches[1].obj[spec.field] or 0
    local second_val = matches[2].obj[spec.field] or 0
    if top_val ~= second_val then
        return { matches[1] }
    end
    return matches
end

---------------------------------------------------------------------------
-- resolve(ctx, keyword) -> obj, loc, parent, surface, prompt_text
-- Main entry point. Called as fallback when exact matching fails.
-- Returns:
--   Single match: obj, loc, parent, surface, nil
--   Multiple matches: nil, nil, nil, nil, disambiguation_prompt
--   No match: nil, nil, nil, nil, nil
---------------------------------------------------------------------------
function fuzzy.resolve(ctx, keyword)
    if not keyword or keyword == "" then return nil end

    local parsed = fuzzy.parse_noun_phrase(keyword)
    if not parsed then return nil end

    local visible = fuzzy.gather_visible(ctx)
    if #visible == 0 then return nil end

    -- Score all visible objects
    local scored = {}
    for _, entry in ipairs(visible) do
        local score, reason = fuzzy.score_object(entry.obj, parsed)
        if score > 0 then
            scored[#scored + 1] = {
                obj = entry.obj, loc = entry.loc,
                parent = entry.parent, surface = entry.surface,
                score = score, reason = reason,
            }
        end
    end

    if #scored == 0 then return nil end

    -- Sort by score descending
    table.sort(scored, function(a, b) return a.score > b.score end)

    -- Filter to top-scoring tier
    local top_score = scored[1].score
    local top_matches = {}
    for _, m in ipairs(scored) do
        if m.score == top_score then
            top_matches[#top_matches + 1] = m
        end
    end

    -- Property-based: use ranking to pick best
    if parsed.property_spec and #top_matches > 1 then
        top_matches = rank_by_property(top_matches, parsed.property_spec)
    end

    -- Single unambiguous match
    if #top_matches == 1 then
        local m = top_matches[1]
        return m.obj, m.loc, m.parent, m.surface, nil
    end

    -- Multiple matches → disambiguation prompt (Prime Directive friendly)
    local names = {}
    for _, m in ipairs(top_matches) do
        local name = m.obj.name or m.obj.id or "something"
        names[#names + 1] = name
    end

    local prompt
    if #names == 2 then
        prompt = "Which do you mean: " .. names[1] .. " or " .. names[2] .. "?"
    else
        local parts = {}
        for i, n in ipairs(names) do
            if i == #names then
                parts[#parts + 1] = "or " .. n
            else
                parts[#parts + 1] = n
            end
        end
        prompt = "Which do you mean: " .. table.concat(parts, ", ") .. "?"
    end

    return nil, nil, nil, nil, prompt
end

---------------------------------------------------------------------------
-- correct_typo(keyword, visible_objects) -> corrected_keyword or nil
-- Standalone typo correction: given a keyword and list of visible objects,
-- returns the corrected keyword if a close Levenshtein match is found.
-- Used for providing "Did you mean...?" suggestions.
---------------------------------------------------------------------------
function fuzzy.correct_typo(keyword, visible)
    if not keyword or keyword == "" then return nil end
    local kw = keyword:lower()
    local max_dist = fuzzy.max_typo_distance(#kw)
    if max_dist == 0 then return nil end

    local best_word = nil
    local best_dist = max_dist + 1

    for _, entry in ipairs(visible) do
        for _, s in ipairs(matchable_strings(entry.obj)) do
            for word in s:gmatch("%S+") do
                if math.abs(#word - #kw) <= max_dist then
                    local d = fuzzy.levenshtein(kw, word)
                    if d > 0 and d < best_dist then
                        best_dist = d
                        best_word = word
                    end
                end
            end
        end
    end

    if best_word then return best_word end
    return nil
end

---------------------------------------------------------------------------
-- Tier 5 Enhancement: Confidence scoring
---------------------------------------------------------------------------
local MAX_SCORE = 10

--- Normalize a raw match score to 0.0–1.0 confidence.
function fuzzy.confidence(raw_score)
    if not raw_score or raw_score <= 0 then return 0.0 end
    return math.min(raw_score / MAX_SCORE, 1.0)
end

-- Minimum confidence to accept a fuzzy match (below = reject)
fuzzy.MIN_CONFIDENCE = 0.3

-- Minimum confidence to auto-accept without disambiguation
fuzzy.AUTO_ACCEPT = 0.7

---------------------------------------------------------------------------
-- Tier 5 Enhancement: Context-integrated scoring
-- Adds recency bonus from context_window as a tiebreaker.
---------------------------------------------------------------------------
function fuzzy.score_with_context(obj, parsed, context_window)
    local base_score, reason = fuzzy.score_object(obj, parsed)
    if base_score == 0 then return 0, nil end

    local recency = 0
    if context_window and context_window.recency_score and obj and obj.id then
        recency = context_window.recency_score(obj.id)
    end

    -- Recency adds up to 0.5 bonus (tiebreaker, never overrides a better match)
    return base_score + (recency * 0.1), reason
end

return fuzzy
