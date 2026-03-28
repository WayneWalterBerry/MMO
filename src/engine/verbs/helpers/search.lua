-- engine/verbs/helpers/search.lua
-- Keyword matching and visibility search helpers.

local core = require("engine.verbs.helpers.core")

local M = {}

---------------------------------------------------------------------------
-- Helper: keyword matching
---------------------------------------------------------------------------
local function matches_keyword(obj, kw)
    if not obj then return false end
    kw = kw:lower()
    -- Build list: original keyword + BUG-056 singular fallbacks
    local candidates = { kw }
    for _, s in ipairs(core.preprocess.singularize(kw)) do
        candidates[#candidates + 1] = s
    end
    for _, try_kw in ipairs(candidates) do
        if obj.id and obj.id:lower() == try_kw then return true end
        -- Exact keyword match (highest priority)
        if type(obj.keywords) == "table" then
            for _, k in ipairs(obj.keywords) do
                if k:lower() == try_kw then return true end
            end
        end
        -- Word-boundary match on name (avoids "match" matching "matchbox")
        if obj.name then
            local padded = " " .. obj.name:lower() .. " "
            if padded:find(" " .. try_kw .. " ", 1, true) then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Adjective-aware scoring: count how many input tokens appear in an
-- object's keywords, name, or id. Used to break ties when multiple
-- objects share a keyword (e.g. "burlap sack" vs "grain sack"). (#182)
---------------------------------------------------------------------------
local function _score_adjective_match(obj, input_text)
    local score = 0
    for token in input_text:lower():gmatch("%S+") do
        local matched = false
        if type(obj.keywords) == "table" then
            for _, k in ipairs(obj.keywords) do
                if k:lower() == token then
                    score = score + 2
                    matched = true
                    break
                end
            end
        end
        if not matched and obj.name then
            local padded = " " .. obj.name:lower() .. " "
            if padded:find(" " .. token .. " ", 1, true) then
                score = score + 1
                matched = true
            end
        end
        if not matched and obj.id and obj.id:lower() == token then
            score = score + 2
        end
    end
    return score
end

---------------------------------------------------------------------------
-- Verb-dependent search order (see docs/architecture/player/inventory.md)
--
-- Interaction verbs act on something the player controls → search
-- hands/bags first, then fall back to room/surfaces.
-- Everything else (acquisition) reaches for things in the world → search
-- room/surfaces first, then fall back to hands/bags.
---------------------------------------------------------------------------
local interaction_verbs = {
    use = true, light = true, drink = true, open = true, close = true,
    pour = true, eat = true, extinguish = true, wear = true, remove = true,
    apply = true, stab = true, cut = true, slash = true,
    dump = true, empty = true,
    -- aliases that map to interaction verbs
    pry = true, shut = true, jab = true, pierce = true, stick = true,
    slice = true, nick = true, carve = true,
}

---------------------------------------------------------------------------
-- Sub-search: room contents (non-hidden objects sitting in the room)
---------------------------------------------------------------------------
local function _fv_room(kw, reg, room)
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and not obj.hidden and matches_keyword(obj, kw) then
            return obj, "room", nil, nil
        end
    end
end

-- Scored room search: collect ALL keyword matches, score by adjective
-- overlap, return best or set ctx.disambiguation_prompt if tied. (#182)
local function _try_room_scored(kw, reg, room, ctx)
    local matches = {}
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and not obj.hidden and matches_keyword(obj, kw) then
            matches[#matches + 1] = { obj = obj, loc = "room" }
        end
    end
    if #matches == 0 then return nil end
    if #matches == 1 then return matches[1].obj, "room", nil, nil end

    for _, m in ipairs(matches) do
        m.score = _score_adjective_match(m.obj, kw)
    end
    table.sort(matches, function(a, b) return a.score > b.score end)

    if matches[1].score > matches[2].score then
        return matches[1].obj, "room", nil, nil
    end

    -- Identical items bypass: when all top-scoring matches share the same
    -- base id (e.g. multiple silk-bundles from killed spiders), just pick
    -- the first one — no disambiguation needed for fungible items.
    -- Strip loot/craft/numeric suffixes to compare base IDs (#362).
    local function _base_id(id)
        return id:gsub("%-loot%-%d+$", ""):gsub("%-craft%-%d+$", ""):gsub("-%d+$", "")
    end
    local top_score = matches[1].score
    local all_same_id = true
    local first_id = _base_id(matches[1].obj.id)
    for _, m in ipairs(matches) do
        if m.score == top_score and _base_id(m.obj.id) ~= first_id then
            all_same_id = false
            break
        end
    end
    if all_same_id then
        return matches[1].obj, "room", nil, nil
    end

    -- Tied scores — build disambiguation prompt
    local names = {}
    for _, m in ipairs(matches) do
        if m.score == top_score then
            names[#names + 1] = m.obj.name or m.obj.id or "something"
        end
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
    ctx.disambiguation_prompt = prompt
    return nil
end

-- Sub-search: accessible surface contents + non-surface containers in room
local function _fv_surfaces(kw, reg, room)
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.surfaces then
            for sname, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false then
                    for _, item_id in ipairs(zone.contents or {}) do
                        local item = reg:get(item_id)
                        -- Search inside a surface item's contents first
                        -- (e.g., candle inside candle-holder on nightstand)
                        if item and item.contents then
                            for _, inner_id in ipairs(item.contents) do
                                local inner = reg:get(inner_id)
                                if inner and matches_keyword(inner, kw) then
                                    return inner, "container", item, nil
                                end
                            end
                        end
                        if item and matches_keyword(item, kw) then
                            return item, "surface", obj, sname
                        end
                    end
                end
            end
            -- #149: Also search root-level contents of surface-objects.
            -- Handles nightstand.contents → drawer → matchbox → match chain.
            -- The drawer lives in nightstand.contents (not in any surface),
            -- so it was invisible to find_visible before this fix.
            if obj.contents then
                local function _search_accessible_chain(ids, depth)
                    if depth > 3 then return nil end
                    for _, cid in ipairs(ids) do
                        local c = reg:get(cid)
                        if c and c.accessible ~= false then
                            if matches_keyword(c, kw) then
                                return c, "container", obj, nil
                            end
                            if c.contents then
                                for _, inner_id in ipairs(c.contents) do
                                    local inner = reg:get(inner_id)
                                    if inner and matches_keyword(inner, kw) then
                                        return inner, "container", c, nil
                                    end
                                end
                                local f, l, p, s = _search_accessible_chain(c.contents, depth + 1)
                                if f then return f, l, p, s end
                            end
                        end
                    end
                end
                local f, l, p, s = _search_accessible_chain(obj.contents, 0)
                if f then return f, l, p, s end
            end
        end
        -- Also search non-surface container contents (if accessible)
        if obj and not obj.surfaces and obj.container and obj.contents
            and obj.accessible ~= false then
            for _, item_id in ipairs(obj.contents) do
                local item = reg:get(item_id)
                if item and matches_keyword(item, kw) then
                    return item, "container", obj, nil
                end
            end
        end
    end
end

-- Sub-search: parts of room objects and parts of surface-hosted objects
local function _fv_parts(kw, reg, room)
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.parts then
            for part_key, part in pairs(obj.parts) do
                if matches_keyword(part, kw) then
                    -- Return the live registry object matching this part's keywords
                    local live = part.id and reg:get(part.id)
                    if not live and obj.contents then
                        for _, cid in ipairs(obj.contents) do
                            local candidate = reg:get(cid)
                            if candidate and matches_keyword(candidate, kw) then
                                live = candidate; break
                            end
                        end
                    end
                    return live or part, "part", obj, part_key
                end
            end
        end
        -- Also check parts of objects on surfaces
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false then
                    for _, item_id in ipairs(zone.contents or {}) do
                        local item = reg:get(item_id)
                        if item and item.parts then
                            for part_key, part in pairs(item.parts) do
                                if matches_keyword(part, kw) then
                                    local live = part.id and reg:get(part.id)
                                    return live or part, "part", item, part_key
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Sub-search: player hands (direct items only)
local function _fv_hands(kw, reg, player, hobj)
    for i = 1, 2 do
        local hand = player.hands[i]
        if hand then
            local obj = hobj(hand, reg)
            if obj and matches_keyword(obj, kw) then
                return obj, "hand", nil, nil
            end
        end
    end
end

-- Sub-search: contents of containers held in hands
local function _fv_bags(kw, reg, player, hobj)
    for i = 1, 2 do
        local hand = player.hands[i]
        if hand then
            local obj = hobj(hand, reg)
            if obj and obj.container and obj.contents then
                for _, item_id in ipairs(obj.contents) do
                    local item = reg:get(item_id)
                    if item and matches_keyword(item, kw) then
                        return item, "bag", obj, nil
                    end
                end
            end
        end
    end
end

-- Sub-search: worn items and contents of worn containers
local function _fv_worn(kw, reg, player)
    for _, worn_id in ipairs(player.worn or {}) do
        local obj = reg:get(worn_id)
        if obj and matches_keyword(obj, kw) then
            return obj, "worn", nil, nil
        end
        if obj and obj.container and obj.contents then
            for _, item_id in ipairs(obj.contents) do
                local item = reg:get(item_id)
                if item and matches_keyword(item, kw) then
                    return item, "bag", obj, nil
                end
            end
        end
    end
end

local function find_visible(ctx, keyword)
    if not keyword or keyword == "" then return nil end
    local room = ctx.current_room
    local reg = ctx.registry
    local hobj = core.hobj
    if not hobj then
        hobj = function(hand, registry)
            if type(hand) == "table" then return hand end
            if type(hand) == "string" then return registry:get(hand) end
            return nil
        end
    end
    local kw = keyword:lower()
        :gsub("^the%s+", "")
        :gsub("^a%s+", "")
        :gsub("^an%s+", "")

    local verb = ctx.current_verb or ""
    local obj, loc, parent, surface

    if interaction_verbs[verb] then
        -- Interaction: acting on held objects → Hands → Bags → Worn → Room → Surfaces → Parts
        obj, loc, parent, surface = _fv_hands(kw, reg, ctx.player, hobj)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_bags(kw, reg, ctx.player, hobj)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_worn(kw, reg, ctx.player)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _try_room_scored(kw, reg, room, ctx)
        if obj then return obj, loc, parent, surface end
        if ctx.disambiguation_prompt then return nil end
        obj, loc, parent, surface = _fv_surfaces(kw, reg, room)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_parts(kw, reg, room)
        if obj then return obj, loc, parent, surface end
    else
        -- Acquisition / default: reaching for world objects → Room → Surfaces → Parts → Hands → Bags → Worn
        obj, loc, parent, surface = _try_room_scored(kw, reg, room, ctx)
        if obj then return obj, loc, parent, surface end
        if ctx.disambiguation_prompt then return nil end
        obj, loc, parent, surface = _fv_surfaces(kw, reg, room)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_parts(kw, reg, room)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_hands(kw, reg, ctx.player, hobj)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_bags(kw, reg, ctx.player, hobj)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_worn(kw, reg, ctx.player)
        if obj then return obj, loc, parent, surface end
    end

    return nil
end

-- Wrap find_visible with pronoun resolution ("it", "one", "that", "this") and
-- last-object tracking for compound command support.
-- Tier 4: Also resolves "the thing I found" from search discoveries,
-- and pushes found objects to the context window stack.
do
    local _find_visible = find_visible
    find_visible = function(ctx, keyword)
        if not keyword or keyword == "" then return nil end
        local kw = keyword:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        -- Tier 4: try context window resolution first (pronouns + discovery refs)
        if core.context_window then
            local cw_obj = core.context_window.resolve(kw)
            if cw_obj then
                ctx.last_object = cw_obj
                return cw_obj, ctx.last_object_loc or "room",
                       ctx.last_object_parent, ctx.last_object_surface
            end
        end
        -- Legacy pronoun fallback (in case context_window not loaded)
        if (kw == "it" or kw == "one" or kw == "that" or kw == "this") and ctx.last_object then
            return ctx.last_object, ctx.last_object_loc or "room",
                   ctx.last_object_parent, ctx.last_object_surface
        end
        local obj, loc, parent, surface = _find_visible(ctx, keyword)
        if obj then
            ctx.last_object = obj
            ctx.last_object_loc = loc
            ctx.last_object_parent = parent
            ctx.last_object_surface = surface
            ctx.known_objects = ctx.known_objects or {}
            ctx.known_objects[obj.id] = true
            -- Tier 4: push to context window stack
            if core.context_window then
                core.context_window.push(obj)
            end
            return obj, loc, parent, surface
        end

        -- BUG-115: Spatial reference — "thing on X" / "something on X" etc.
        -- Resolves vague references to the first object on a named surface.
        local spatial_surface = kw:match("^thing%s+on%s+(.+)$")
            or kw:match("^something%s+on%s+(.+)$")
            or kw:match("^item%s+on%s+(.+)$")
            or kw:match("^object%s+on%s+(.+)$")
            or kw:match("^stuff%s+on%s+(.+)$")
        if spatial_surface then
            local surface_obj = _find_visible(ctx, spatial_surface)
            if surface_obj and surface_obj.surfaces then
                -- Prefer "top" surface, then any accessible surface
                local check_order = {}
                for zone_name, zone in pairs(surface_obj.surfaces) do
                    if zone_name == "top" then
                        table.insert(check_order, 1, { name = zone_name, zone = zone })
                    elseif zone.accessible ~= false then
                        check_order[#check_order + 1] = { name = zone_name, zone = zone }
                    end
                end
                for _, entry in ipairs(check_order) do
                    if entry.zone.contents and #entry.zone.contents > 0 then
                        if #entry.zone.contents == 1 then
                            local item = ctx.registry:get(entry.zone.contents[1])
                            if item then
                                ctx.last_object = item
                                ctx.last_object_loc = "surface"
                                ctx.last_object_parent = surface_obj
                                ctx.last_object_surface = entry.name
                                ctx.known_objects = ctx.known_objects or {}
                                ctx.known_objects[item.id] = true
                                if core.context_window then
                                    core.context_window.push(item)
                                end
                                return item, "surface", surface_obj, entry.name
                            end
                        else
                            -- Multiple items: disambiguate
                            local names = {}
                            for _, id in ipairs(entry.zone.contents) do
                                local item = ctx.registry:get(id)
                                names[#names + 1] = item and item.name or id
                            end
                            print("Which thing on " .. (surface_obj.name or spatial_surface)
                                .. "? You see: " .. table.concat(names, ", ") .. ".")
                            return nil
                        end
                    end
                end
            end
        end

        -- Tier 5: Fuzzy noun resolution fallback (only when exact match fails)
        -- BUG-146 (#46): Skip fuzzy when caller needs exact-only (e.g., search
        -- scope detection). Fuzzy "match"→"mat" causes search to target the rug
        -- instead of doing a room-wide search for "match".
        if core.fuzzy and not ctx._exact_only then
            local fobj, floc, fparent, fsurface, prompt = core.fuzzy.resolve(ctx, keyword)
            if fobj then
                ctx.last_object = fobj
                ctx.last_object_loc = floc
                ctx.last_object_parent = fparent
                ctx.last_object_surface = fsurface
                ctx.known_objects = ctx.known_objects or {}
                ctx.known_objects[fobj.id] = true
                if core.context_window then
                    core.context_window.push(fobj)
                end
                return fobj, floc, fparent, fsurface
            end
            if prompt then
                -- Store disambiguation prompt for caller to display
                ctx.disambiguation_prompt = prompt
                return nil
            end
        end

        return nil
    end
end

---------------------------------------------------------------------------
-- Helper: find object in player's carried items (hands + bags + worn)
---------------------------------------------------------------------------
local function find_in_inventory(ctx, keyword)
    if not keyword or keyword == "" then return nil end
    local kw = keyword:lower()
        :gsub("^the%s+", "")
        :gsub("^a%s+", "")
        :gsub("^an%s+", "")
    local reg = ctx.registry
    local hobj = core.hobj
    if not hobj then
        hobj = function(hand, registry)
            if type(hand) == "table" then return hand end
            if type(hand) == "string" then return registry:get(hand) end
            return nil
        end
    end
    -- Hands
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = hobj(hand, reg)
            if obj and matches_keyword(obj, kw) then return obj end
        end
    end
    -- Held bag contents
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local bag = hobj(hand, reg)
            if bag and bag.container and bag.contents then
                for _, item_id in ipairs(bag.contents) do
                    local item = reg:get(item_id)
                    if item and matches_keyword(item, kw) then return item end
                end
            end
        end
    end
    -- Worn items
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        local obj = reg:get(worn_id)
        if obj and matches_keyword(obj, kw) then return obj end
    end
    -- Worn bag contents
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        local bag = reg:get(worn_id)
        if bag and bag.container and bag.contents then
            for _, item_id in ipairs(bag.contents) do
                local item = reg:get(item_id)
                if item and matches_keyword(item, kw) then return item end
            end
        end
    end
    return nil
end

M.matches_keyword = matches_keyword
M._score_adjective_match = _score_adjective_match
M.interaction_verbs = interaction_verbs
M._fv_room = _fv_room
M._fv_surfaces = _fv_surfaces
M._fv_parts = _fv_parts
M._fv_hands = _fv_hands
M._fv_bags = _fv_bags
M._fv_worn = _fv_worn
M.find_visible = find_visible
M.find_in_inventory = find_in_inventory

return M
