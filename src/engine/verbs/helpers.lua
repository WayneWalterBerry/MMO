-- engine/verbs/helpers.lua
-- V1 verb handlers for the bedroom REPL.
-- Each handler has signature: function(context, noun)
-- Context is injected by the game loop at dispatch time.
--
-- Ownership:
--   Smithers (UI Engineer): Text presentation, sensory verb output, help,
--     error message wording, pronoun resolution, light-level-aware display.
--   Bart (Architect): Game state mutations, FSM interactions, containment,
--     tool resolution, core verb logic (take, put, open, close, crafting, etc.)


local H = {}

local fsm_mod = require("engine.fsm")
local presentation = require("engine.ui.presentation")
local preprocess = require("engine.parser.preprocess")
local traverse_effects = require("engine.traverse_effects")
local effects = require("engine.effects")
local materials = require("engine.materials")

-- Tier 4: Context window for recent interaction memory
local cw_ok, context_window = pcall(require, "engine.parser.context")
if not cw_ok then context_window = nil end

-- Tier 5: Fuzzy noun resolution (material, property, partial name, typo tolerance)
local fz_ok, fuzzy = pcall(require, "engine.parser.fuzzy")
if not fz_ok then fuzzy = nil end

---------------------------------------------------------------------------
-- Instance-aware hand accessors: hands store object instances (tables).
-- Backward compatible with string IDs for transitional code.
---------------------------------------------------------------------------
local _next_instance_id = 0
local function next_instance_id()
    _next_instance_id = _next_instance_id + 1
    return _next_instance_id
end

local function _hid(hand)
    if type(hand) == "table" then return hand.id end
    return hand
end

local function _hobj(hand, reg)
    if type(hand) == "table" then return hand end
    if type(hand) == "string" then return reg:get(hand) end
    return nil
end

---------------------------------------------------------------------------
-- Constants (authoritative source: engine/ui/presentation.lua)
---------------------------------------------------------------------------
local GAME_SECONDS_PER_REAL_SECOND = presentation.GAME_SECONDS_PER_REAL_SECOND
local GAME_START_HOUR = presentation.GAME_START_HOUR
local DAYTIME_START = presentation.DAYTIME_START
local DAYTIME_END = presentation.DAYTIME_END

---------------------------------------------------------------------------
-- Prime Directive: Helpful error messages
---------------------------------------------------------------------------
local function err_not_found(ctx)
    -- Tier 5: Show disambiguation prompt if fuzzy matching found multiple candidates
    if ctx and ctx.disambiguation_prompt then
        print(ctx.disambiguation_prompt)
        ctx.disambiguation_prompt = nil
        return
    end
    print("You don't notice anything called that nearby. Try 'search around' to discover what's here.")
end

local function err_cant_do_that()
    print("That doesn't seem to work. Maybe try examining it first, or type 'help' for ideas.")
end

local function err_nothing_happens(obj)
    print("Nothing obvious happens. Try examining it more closely, or try a different approach.")
end

-- One-shot tutorial hint — shows once per player session, tracked in player.state.
local function show_hint(ctx, hint_id, message)
    if not ctx.player or not ctx.player.state then return false end
    if not ctx.player.state.hints_shown then
        ctx.player.state.hints_shown = {}
    end
    if ctx.player.state.hints_shown[hint_id] then return false end
    ctx.player.state.hints_shown[hint_id] = true
    print("(Hint: " .. message .. ")")
    return true
end

---------------------------------------------------------------------------
-- Helper: keyword matching
---------------------------------------------------------------------------
local function matches_keyword(obj, kw)
    if not obj then return false end
    kw = kw:lower()
    -- Build list: original keyword + BUG-056 singular fallbacks
    local candidates = { kw }
    for _, s in ipairs(preprocess.singularize(kw)) do
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
-- Hand inventory helpers
---------------------------------------------------------------------------
local function hands_full(ctx)
    return ctx.player.hands[1] ~= nil and ctx.player.hands[2] ~= nil
end

local function first_empty_hand(ctx)
    if ctx.player.hands[1] == nil then return 1 end
    if ctx.player.hands[2] == nil then return 2 end
    return nil
end

local function which_hand(ctx, obj_id)
    if _hid(ctx.player.hands[1]) == obj_id then return 1 end
    if _hid(ctx.player.hands[2]) == obj_id then return 2 end
    return nil
end

-- Returns flat list of all object IDs the player is carrying
-- (hands + held bag contents + worn items + worn bag contents)
-- Authoritative implementation in engine/ui/presentation.lua
local get_all_carried_ids = presentation.get_all_carried_ids

---------------------------------------------------------------------------
-- Helper: count hands used by carried objects (for two-handed carry)
-- Returns: hands_used, free_hands
---------------------------------------------------------------------------
local function count_hands_used(ctx)
    local used = 0
    local reg = ctx.registry
    for i = 1, 2 do
        if ctx.player.hands[i] then
            local obj = _hobj(ctx.player.hands[i], reg)
            local hr = (obj and obj.hands_required) or 1
            if hr >= 2 then
                return 2, 0  -- two-hand item uses both slots
            end
            used = used + 1
        end
    end
    return used, 2 - used
end

---------------------------------------------------------------------------
-- Helper: find a detachable part on any reachable object matching keyword
-- Returns: part_def, parent_obj, part_key  (or nil)
---------------------------------------------------------------------------
local function find_part(ctx, keyword)
    if not keyword or keyword == "" then return nil end
    local room = ctx.current_room
    local reg = ctx.registry
    local kw = keyword:lower()
        :gsub("^the%s+", "")
        :gsub("^a%s+", "")
        :gsub("^an%s+", "")

    -- Search room objects for parts
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.parts then
            for part_key, part in pairs(obj.parts) do
                if matches_keyword(part, kw) then
                    return part, obj, part_key
                end
            end
        end
        -- Also search surface contents of room objects for composite parts
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false then
                    for _, item_id in ipairs(zone.contents or {}) do
                        local item = reg:get(item_id)
                        if item and item.parts then
                            for part_key, part in pairs(item.parts) do
                                if matches_keyword(part, kw) then
                                    return part, item, part_key
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- Search held objects for parts
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _hobj(hand, reg)
            if obj and obj.parts then
                for part_key, part in pairs(obj.parts) do
                    if matches_keyword(part, kw) then
                        return part, obj, part_key
                    end
                end
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: detach a part from its parent — factory + FSM + room placement
-- Returns: new_obj (or nil, error_msg)
---------------------------------------------------------------------------
local function detach_part(ctx, parent, part_key)
    local part = parent.parts and parent.parts[part_key]
    if not part then return nil, "No such part." end
    if not part.detachable then return nil, "That can't be removed." end
    if not part.factory then return nil, "That can't be separated." end

    -- Check state precondition
    if part.requires_state_match then
        if parent._state ~= part.requires_state_match then
            return nil, part.blocked_message or ("You can't remove that right now.")
        end
    end

    -- Find the detach_part transition on the parent
    local detach_trans = nil
    for _, t in ipairs(parent.transitions or {}) do
        if t.verb == "detach_part" and t.part_id == part_key then
            if t.from == parent._state then
                detach_trans = t
                break
            end
        end
    end

    -- Create the new independent object via factory
    local new_obj = part.factory(parent)
    if not new_obj then return nil, "Something went wrong." end

    -- Set location to same room as parent
    local room = ctx.current_room
    new_obj.location = room.id

    -- Register the new object
    local new_id = new_obj.id
    if ctx.registry:get(new_id) then
        local n = 2
        while ctx.registry:get(new_id .. "-" .. n) do n = n + 1 end
        new_id = new_id .. "-" .. n
        new_obj.id = new_id
    end
    ctx.registry:register(new_id, new_obj)
    room.contents[#room.contents + 1] = new_id

    -- If the part carries contents, clear the parent's surface
    if part.carries_contents and parent.surfaces and parent.surfaces.inside then
        parent.surfaces.inside.contents = {}
    end

    -- Transition the parent's FSM state directly (bypass fsm.transition to use our specific transition)
    local message = part.detach_message or ("You remove " .. (part.name or part_key) .. ".")
    if detach_trans then
        -- Apply state change directly using the detach_part transition we found
        local fsm_m = require("engine.fsm")
        -- Use the FSM's apply_state through a transition call, but only if our exact
        -- detach_part transition matches. Since fsm.transition picks the first from→to,
        -- we must set the state directly when we already know the target.
        local old_state = parent._state
        if parent.states and parent.states[detach_trans.to] then
            -- Apply new state properties
            for k, v in pairs(parent.states[detach_trans.to]) do
                if k ~= "on_tick" and k ~= "terminal" then
                    if k == "surfaces" then
                        -- Preserve surface contents
                        local saved = {}
                        if parent.surfaces then
                            for sname, zone in pairs(parent.surfaces) do
                                saved[sname] = zone.contents or {}
                            end
                        end
                        parent.surfaces = {}
                        for sname, zone in pairs(v) do
                            parent.surfaces[sname] = {}
                            for zk, zv in pairs(zone) do
                                if zk ~= "contents" then
                                    parent.surfaces[sname][zk] = zv
                                end
                            end
                            parent.surfaces[sname].contents = saved[sname] or {}
                        end
                    else
                        parent[k] = v
                    end
                end
            end
            parent._state = detach_trans.to
        end
        message = detach_trans.message or message
    end

    return new_obj, message
end

---------------------------------------------------------------------------
-- Helper: reattach a part to its parent
-- Returns: true, message (or nil, error_msg)
---------------------------------------------------------------------------
local function reattach_part(ctx, drawer_obj, parent)
    if not parent or not parent.parts then return nil, "That doesn't go there." end

    -- Find which part this object can reattach as
    local part_key = nil
    for pk, part in pairs(parent.parts) do
        if part.reversible and part.id == drawer_obj.id then
            part_key = pk
            break
        end
        -- Also check by reattach_to on the detached object
        if part.reversible and drawer_obj.reattach_to == parent.id then
            part_key = pk
            break
        end
    end
    if not part_key then return nil, "That doesn't fit there." end

    -- Find the reattach transition
    local reattach_trans = nil
    for _, t in ipairs(parent.transitions or {}) do
        if t.verb == "reattach_part" and t.part_id == part_key then
            if t.from == parent._state then
                reattach_trans = t
                break
            end
        end
    end
    if not reattach_trans then return nil, "You can't put that back right now." end

    -- Transfer contents back to parent if applicable
    local part = parent.parts[part_key]
    if part.carries_contents and drawer_obj.contents then
        if parent.surfaces then
            parent.surfaces.inside = parent.surfaces.inside or { capacity = 2, max_item_size = 1, contents = {} }
            parent.surfaces.inside.contents = {}
            for _, id in ipairs(drawer_obj.contents) do
                parent.surfaces.inside.contents[#parent.surfaces.inside.contents + 1] = id
            end
        end
    end

    -- Remove drawer from world (inline to avoid forward-reference)
    local room = ctx.current_room
    for i, id in ipairs(room.contents or {}) do
        if id == drawer_obj.id then
            table.remove(room.contents, i)
            break
        end
    end
    -- Also check player hands
    for i = 1, 2 do
        if _hid(ctx.player.hands[i]) == drawer_obj.id then
            ctx.player.hands[i] = nil
        end
    end
    ctx.registry:remove(drawer_obj.id)

    -- Transition parent directly using the reattach transition
    if parent.states and parent.states[reattach_trans.to] then
        -- Save surface contents BEFORE cleanup (prevents BUG-017 data loss)
        local saved_surface_contents = {}
        if parent.surfaces then
            for sname, zone in pairs(parent.surfaces) do
                saved_surface_contents[sname] = zone.contents or {}
            end
        end

        -- Remove old state keys
        if parent._state and parent.states[parent._state] then
            for k in pairs(parent.states[parent._state]) do
                if k ~= "on_tick" and k ~= "terminal" then
                    parent[k] = nil
                end
            end
        end
        -- Apply new state properties
        for k, v in pairs(parent.states[reattach_trans.to]) do
            if k ~= "on_tick" and k ~= "terminal" then
                if k == "surfaces" then
                    parent.surfaces = {}
                    for sname, zone in pairs(v) do
                        parent.surfaces[sname] = {}
                        for zk, zv in pairs(zone) do
                            if zk ~= "contents" then
                                parent.surfaces[sname][zk] = zv
                            end
                        end
                        parent.surfaces[sname].contents = saved_surface_contents[sname] or {}
                    end
                else
                    parent[k] = v
                end
            end
        end
        parent._state = reattach_trans.to
    end
    local message = reattach_trans.message or "You put it back."
    return true, message
end

---------------------------------------------------------------------------
-- Helper: find an object the player can see or reach
-- Returns: obj, location_type, parent_obj, surface_name
--   location_type: "room" | "surface" | "hand" | "bag" | "worn" | "part"
--
-- Search order is VERB-DEPENDENT (see docs/architecture/player/inventory.md):
--   Interaction verbs (use, light, drink, …): Hands → Bags → Worn → Room → Surfaces → Parts
--   Acquisition verbs (take, examine, look, …): Room → Surfaces → Parts → Hands → Bags → Worn
---------------------------------------------------------------------------

-- Sub-search: room contents (non-hidden objects sitting in the room)
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
    local top_score = matches[1].score
    local all_same_id = true
    local first_id = matches[1].obj.id
    for _, m in ipairs(matches) do
        if m.score == top_score and m.obj.id ~= first_id then
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
local function _fv_hands(kw, reg, player)
    for i = 1, 2 do
        local hand = player.hands[i]
        if hand then
            local obj = _hobj(hand, reg)
            if obj and matches_keyword(obj, kw) then
                return obj, "hand", nil, nil
            end
        end
    end
end

-- Sub-search: contents of containers held in hands
local function _fv_bags(kw, reg, player)
    for i = 1, 2 do
        local hand = player.hands[i]
        if hand then
            local obj = _hobj(hand, reg)
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
    local kw = keyword:lower()
        :gsub("^the%s+", "")
        :gsub("^a%s+", "")
        :gsub("^an%s+", "")

    local verb = ctx.current_verb or ""
    local obj, loc, parent, surface

    if interaction_verbs[verb] then
        -- Interaction: acting on held objects → Hands → Bags → Worn → Room → Surfaces → Parts
        obj, loc, parent, surface = _fv_hands(kw, reg, ctx.player)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_bags(kw, reg, ctx.player)
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
        obj, loc, parent, surface = _fv_hands(kw, reg, ctx.player)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_bags(kw, reg, ctx.player)
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
        if context_window then
            local cw_obj = context_window.resolve(kw)
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
            if context_window then
                context_window.push(obj)
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
                                if context_window then
                                    context_window.push(item)
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
        if fuzzy and not ctx._exact_only then
            local fobj, floc, fparent, fsurface, prompt = fuzzy.resolve(ctx, keyword)
            if fobj then
                ctx.last_object = fobj
                ctx.last_object_loc = floc
                ctx.last_object_parent = fparent
                ctx.last_object_surface = fsurface
                ctx.known_objects = ctx.known_objects or {}
                ctx.known_objects[fobj.id] = true
                if context_window then
                    context_window.push(fobj)
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
    -- Hands
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _hobj(hand, reg)
            if obj and matches_keyword(obj, kw) then return obj end
        end
    end
    -- Held bag contents
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local bag = _hobj(hand, reg)
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

---------------------------------------------------------------------------
-- Helper: find a tool in carried items that provides a given capability.
-- Also checks blood as writing instrument when player has bloody state.
---------------------------------------------------------------------------
local function find_tool_in_inventory(ctx, required_capability)
    local reg = ctx.registry
    local all_ids = get_all_carried_ids(ctx)
    for _, obj_id in ipairs(all_ids) do
        local obj = reg:get(obj_id)
        if obj and obj.provides_tool then
            local provides = obj.provides_tool
            if type(provides) == "string" and provides == required_capability then
                return obj
            elseif type(provides) == "table" then
                for _, cap in ipairs(provides) do
                    if cap == required_capability then
                        return obj
                    end
                end
            end
        end
    end
    -- Blood as writing instrument when player is injured
    if required_capability == "writing_instrument" then
        local state = ctx.player.state or {}
        if state.bloody then
            return {
                id = "blood", name = "your blood",
                provides_tool = "writing_instrument",
                _is_blood = true,
                on_tool_use = {
                    consumes_charge = false,
                    use_message = "You press your bleeding finger to the surface, leaving dark crimson marks.",
                },
            }
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: check if an object provides a specific tool capability
---------------------------------------------------------------------------
local function provides_capability(obj, capability)
    if not obj or not obj.provides_tool then return false end
    local provides = obj.provides_tool
    if type(provides) == "string" then return provides == capability end
    if type(provides) == "table" then
        for _, cap in ipairs(provides) do
            if cap == capability then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: find a tool that is visible (in room/surfaces) but not carried
---------------------------------------------------------------------------
local function find_visible_tool(ctx, required_capability)
    local room = ctx.current_room
    local reg = ctx.registry
    -- Room contents
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.provides_tool then
            if provides_capability(obj, required_capability) then
                return obj
            end
        end
    end
    -- Surface contents
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false then
                    for _, item_id in ipairs(zone.contents or {}) do
                        local item = reg:get(item_id)
                        if item and provides_capability(item, required_capability) then
                            return item
                        end
                    end
                end
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: consume a charge from a tool, mutate to depleted if empty
---------------------------------------------------------------------------
local function consume_tool_charge(ctx, tool)
    if not tool or not tool.on_tool_use or not tool.on_tool_use.consumes_charge then
        return
    end
    if not tool.charges then return end
    tool.charges = tool.charges - 1
    if tool.charges <= 0 and tool.on_tool_use.when_depleted then
        if tool.on_tool_use.depleted_message then
            print(tool.on_tool_use.depleted_message)
        end
        local source = ctx.object_sources[tool.on_tool_use.when_depleted]
        if source then
            ctx.mutation.mutate(ctx.registry, ctx.loader, tool.id, source, ctx.templates)
        end
    end
end

---------------------------------------------------------------------------
-- Helper: remove an object from wherever it currently lives
---------------------------------------------------------------------------
local function remove_from_location(ctx, obj)
    local room = ctx.current_room
    local reg = ctx.registry

    -- Player hands
    for i = 1, 2 do
        if _hid(ctx.player.hands[i]) == obj.id then
            ctx.player.hands[i] = nil
            return true
        end
    end

    -- Bags in player's hands
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local bag = _hobj(hand, reg)
            if bag and bag.container and bag.contents then
                for j, item_id in ipairs(bag.contents) do
                    if item_id == obj.id then
                        table.remove(bag.contents, j)
                        return true
                    end
                end
            end
        end
    end

    -- Worn items
    for i, worn_id in ipairs(ctx.player.worn or {}) do
        if worn_id == obj.id then
            table.remove(ctx.player.worn, i)
            return true
        end
    end

    -- Worn bag contents
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        local bag = reg:get(worn_id)
        if bag and bag.container and bag.contents then
            for j, item_id in ipairs(bag.contents) do
                if item_id == obj.id then
                    table.remove(bag.contents, j)
                    return true
                end
            end
        end
    end

    -- Room contents
    for i, id in ipairs(room.contents or {}) do
        if id == obj.id then
            table.remove(room.contents, i)
            return true
        end
    end

    -- Surface contents of room objects
    for _, parent_id in ipairs(room.contents or {}) do
        local parent = reg:get(parent_id)
        if parent and parent.surfaces then
            for _, zone in pairs(parent.surfaces) do
                for i, id in ipairs(zone.contents or {}) do
                    if id == obj.id then
                        table.remove(zone.contents, i)
                        return true
                    end
                end
            end
        end
        -- Non-surface container contents
        if parent and not parent.surfaces and parent.container and parent.contents then
            for i, id in ipairs(parent.contents) do
                if id == obj.id then
                    table.remove(parent.contents, i)
                    return true
                end
            end
        end
    end

    return false
end

---------------------------------------------------------------------------
-- Presentation helpers (authoritative source: engine/ui/presentation.lua)
---------------------------------------------------------------------------
local get_game_time = presentation.get_game_time

local is_daytime = presentation.is_daytime

local format_time = presentation.format_time

local time_of_day_desc = presentation.time_of_day_desc

---------------------------------------------------------------------------
-- Light system (authoritative source: engine/ui/presentation.lua)
---------------------------------------------------------------------------
local get_light_level = presentation.get_light_level

-- Convenience: can the player see enough to interact?
local has_some_light = presentation.has_some_light

---------------------------------------------------------------------------
-- Vision check (authoritative source: engine/ui/presentation.lua)
---------------------------------------------------------------------------
local vision_blocked_by_worn = presentation.vision_blocked_by_worn

---------------------------------------------------------------------------
-- Container sensory gating: check if a container's contents are accessible
-- to a given sense.  Uses _state (FSM) — "open" in state name means open.
-- sense: "visual" or "tactile"
-- Returns true if contents should be revealed to that sense.
---------------------------------------------------------------------------
local function container_contents_accessible(obj, sense)
    if not obj._state then return true end
    if obj._state:find("open") then return true end
    -- Closed: transparent containers still allow visual access
    if sense == "visual" and obj.transparent then return true end
    return false
end

---------------------------------------------------------------------------
-- Helper: find a mutation entry on an object for a given verb
-- Checks exact match first, then verb_* patterns (e.g. "break" → "break_mirror")
---------------------------------------------------------------------------
local function find_mutation(obj, verb)
    if not obj or not obj.mutations then return nil end
    if obj.mutations[verb] then return obj.mutations[verb] end
    for key, mut in pairs(obj.mutations) do
        if key:sub(1, #verb + 1) == verb .. "_" then
            return mut
        end
    end
    return nil
end



---------------------------------------------------------------------------
-- Helper: spawn objects from a mutation's spawns list
---------------------------------------------------------------------------
local function spawn_objects(ctx, spawns)
    local room = ctx.current_room
    for _, spawn_id in ipairs(spawns) do
        local source = ctx.object_sources[spawn_id]
        if source then
            local spawn_obj, err = ctx.loader.load_source(source)
            if spawn_obj then
                spawn_obj, err = ctx.loader.resolve_template(spawn_obj, ctx.templates)
                if spawn_obj then
                    local actual_id = spawn_id
                    if ctx.registry:get(spawn_id) then
                        local n = 2
                        while ctx.registry:get(spawn_id .. "-" .. n) do n = n + 1 end
                        actual_id = spawn_id .. "-" .. n
                    end
                    spawn_obj.id = actual_id
                    spawn_obj.location = room.id
                    ctx.registry:register(actual_id, spawn_obj)
                    room.contents[#room.contents + 1] = actual_id
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Helper: perform an object mutation (swap or destroy + spawn)
---------------------------------------------------------------------------
local function perform_mutation(ctx, obj, mut_data)
    if mut_data.becomes then
        local source = ctx.object_sources[mut_data.becomes]
        if not source then
            print("Something strange happens, but nothing changes.")
            return false
        end
        local new_obj, err = ctx.mutation.mutate(
            ctx.registry, ctx.loader, obj.id, source, ctx.templates)
        if not new_obj then
            print("Error: " .. tostring(err))
            return false
        end
        -- Sync hand slot references: mutation replaces the registry entry
        -- but hand slots may still hold the old object table reference.
        if ctx.player then
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local hid = type(hand) == "table" and hand.id or hand
                    if hid == obj.id then
                        ctx.player.hands[i] = new_obj
                    end
                end
            end
        end
    elseif mut_data.spawns then
        -- Destruction: object ceases to exist, spawns replace it
        remove_from_location(ctx, obj)
        ctx.registry:remove(obj.id)
    end

    if mut_data.spawns then
        spawn_objects(ctx, mut_data.spawns)
    end

    return true
end

---------------------------------------------------------------------------
-- Helper: total carried weight (hands + worn)
---------------------------------------------------------------------------
local function inventory_weight(ctx)
    local total = 0
    local reg = ctx.registry
    for _, id in ipairs(get_all_carried_ids(ctx)) do
        local obj = reg:get(id)
        if obj then total = total + (obj.weight or 0) end
    end
    return total
end

---------------------------------------------------------------------------
-- Spatial movement: push/pull/move objects with spatial relationships
---------------------------------------------------------------------------
local function move_spatial_object(ctx, obj, verb)
    local room = ctx.current_room
    local reg = ctx.registry

    -- Not movable
    if not obj.movable then
        if obj.weight and obj.weight >= 50 then
            print("You strain against " .. (obj.name or "it") .. ", but it won't budge. It's far too heavy to move.")
        else
            print("You can't move " .. (obj.name or "that") .. ".")
        end
        return
    end

    -- Already moved
    if obj.moved then
        print("You've already moved " .. (obj.name or "that") .. ".")
        return
    end

    -- Check if anything is resting on this object (prevents movement)
    for _, obj_id in ipairs(room.contents or {}) do
        local other = reg:get(obj_id)
        if other and other.resting_on == obj.id and not other.moved then
            print((other.name or "Something") .. " is sitting on " .. (obj.name or "it") .. ". You need to move it first.")
            return
        end
    end

    -- Perform the move
    obj.moved = true

    -- Print movement message (verb-specific → generic → fallback)
    local verb_msg_key = verb .. "_message"
    if obj[verb_msg_key] then
        print(obj[verb_msg_key])
    elseif obj.move_message then
        print(obj.move_message)
    else
        print("You " .. verb .. " " .. (obj.name or "it") .. " aside.")
    end

    -- Fire on_move callback if the object declares one (#111)
    if obj.on_move and type(obj.on_move) == "function" then
        obj:on_move(ctx, verb)
    end

    -- Clear resting_on relationship
    if obj.resting_on then
        obj.resting_on = nil
    end

    -- Update description/presence for moved state
    if obj.moved_room_presence then
        obj.room_presence = obj.moved_room_presence
    end
    if obj.moved_description then
        obj.description = obj.moved_description
    end
    if obj.moved_on_feel then
        obj.on_feel = obj.moved_on_feel
    end

    -- If this is a covering object, dump underneath surface items to floor
    if obj.covering and obj.surfaces and obj.surfaces.underneath then
        local underneath = obj.surfaces.underneath
        underneath.accessible = true   -- reveal surface after move (#26)
        for i = #(underneath.contents or {}), 1, -1 do
            local item_id = underneath.contents[i]
            room.contents[#room.contents + 1] = item_id
            local item = reg:get(item_id)
            if item then
                item.location = room.id
                print("Something clatters to the floor -- " .. (item.name or item_id) .. "!")
            end
            table.remove(underneath.contents, i)
        end
    end

    -- Reveal covered objects
    if obj.covering then
        for _, covered_id in ipairs(obj.covering) do
            local covered = reg:get(covered_id)
            local is_hidden = covered and (covered.hidden or (covered.states and covered._state == "hidden"))
            if is_hidden then
                -- FSM reveal transition
                if covered.states and covered._state == "hidden" then
                    local transitioned = false
                    for _, t in ipairs(covered.transitions or {}) do
                        if t.from == "hidden" then
                            fsm_mod.transition(reg, covered_id, t.to, {})
                            transitioned = true
                            break
                        end
                    end
                    if not transitioned then
                        covered.hidden = false
                    end
                else
                    covered.hidden = false
                end
                -- Discovery message
                if covered.discovery_message then
                    print("")
                    print(covered.discovery_message)
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Self-infliction: shared logic for stab/cut/slash self
---------------------------------------------------------------------------
local BODY_AREA_WEIGHTS = {
    { area = "left arm",   weight = 3 },
    { area = "right arm",  weight = 3 },
    { area = "left hand",  weight = 2 },
    { area = "right hand", weight = 2 },
    { area = "left leg",   weight = 2 },
    { area = "right leg",  weight = 2 },
    { area = "torso",      weight = 1 },
    { area = "stomach",    weight = 1 },
}
local BODY_AREA_TOTAL_WEIGHT = 16

local BODY_AREA_DAMAGE_MODS = {
    ["left arm"]   = 1.0, ["right arm"]  = 1.0,
    ["left hand"]  = 1.0, ["right hand"] = 1.0,
    ["left leg"]   = 1.0, ["right leg"]  = 1.0,
    ["torso"]      = 1.5, ["stomach"]    = 1.5,
    ["head"]       = 2.0,
}

-- Body area aliases the parser recognizes
local BODY_AREA_ALIASES = {
    ["arm"]      = "left arm",
    ["hand"]     = "left hand",
    ["leg"]      = "left leg",
    ["left arm"] = "left arm",  ["right arm"]  = "right arm",
    ["left hand"]= "left hand", ["right hand"] = "right hand",
    ["left leg"] = "left leg",  ["right leg"]  = "right leg",
    ["torso"]    = "torso",     ["chest"]      = "torso",   ["side"] = "torso",
    ["stomach"]  = "stomach",   ["belly"]      = "stomach", ["gut"]  = "stomach",
    ["head"]     = "head",      ["forehead"]   = "head",    ["face"] = "head",
}

local function random_body_area()
    local roll = math.random(1, BODY_AREA_TOTAL_WEIGHT)
    local acc = 0
    for _, entry in ipairs(BODY_AREA_WEIGHTS) do
        acc = acc + entry.weight
        if roll <= acc then return entry.area end
    end
    return "left arm"
end

-- Parse self-infliction noun into body_area and weapon keyword
-- Returns: is_self, body_area_or_nil, weapon_kw_or_nil
local function parse_self_infliction(noun)
    local target_part, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
    if not target_part then target_part = noun; tool_word = nil end

    -- Strip possessive prefix ("my", "your")
    local cleaned = target_part:lower():gsub("^my%s+", ""):gsub("^your%s+", "")

    -- Check if targeting self or a body part
    if cleaned == "self" or cleaned == "myself" or cleaned == "me"
        or cleaned == "yourself" or cleaned == "you" or cleaned == "" then
        return true, nil, tool_word
    end

    -- Check if it's a recognized body area
    local area = BODY_AREA_ALIASES[cleaned]
    if area then
        return true, area, tool_word
    end

    return false, nil, tool_word
end

local function handle_self_infliction(ctx, noun, verb_name, profile_field)
    if noun == "" then
        print(verb_name:sub(1,1):upper() .. verb_name:sub(2) .. " what?")
        return true
    end

    local is_self, body_area, tool_word = parse_self_infliction(noun)
    if not is_self then return false end

    -- Find weapon
    local weapon = nil
    if tool_word then
        weapon = find_in_inventory(ctx, tool_word)
        if not weapon then
            print("You don't have " .. tool_word .. ".")
            return true
        end
    else
        -- Search hands for any item with the right damage profile
        local candidates = {}
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local obj = _hobj(hand, ctx.registry)
                if obj and obj[profile_field] then
                    candidates[#candidates + 1] = obj
                end
            end
        end
        if #candidates == 0 then
            print("You have nothing sharp to " .. verb_name .. " with.")
            return true
        elseif #candidates > 1 then
            local names = {}
            for _, c in ipairs(candidates) do names[#names + 1] = c.name or c.id end
            print(verb_name:sub(1,1):upper() .. verb_name:sub(2) .. " yourself with what? You're holding " .. table.concat(names, " and ") .. ".")
            return true
        end
        weapon = candidates[1]
    end

    -- Validate weapon has the right profile
    local profile = weapon[profile_field]
    if not profile then
        print("You can't " .. verb_name .. " yourself with " .. (weapon.name or "that") .. ".")
        return true
    end

    -- Resolve body area
    if not body_area then
        body_area = random_body_area()
    end

    -- Apply body area damage modifier
    local base_damage = profile.damage or 5
    local modifier = BODY_AREA_DAMAGE_MODS[body_area] or 1.0
    local effective_damage = math.floor(base_damage * modifier)

    -- Inflict the injury — route through effects pipeline when available (#66)
    local source = "self-inflicted (" .. (weapon.id or "weapon") .. ", " .. verb_name .. ")"
    local instance = nil

    if weapon.effects_pipeline and profile.pipeline_effects then
        -- Build contextualized effect list with body_area and damage overrides
        local fx_list = {}
        for _, fx in ipairs(profile.pipeline_effects) do
            local copy = {}
            for k, v in pairs(fx) do copy[k] = v end
            copy.damage = effective_damage
            copy.location = body_area
            copy.source = source
            -- Substitute body area in message
            if copy.message then
                copy.message = string.format(copy.message, body_area)
            end
            fx_list[#fx_list + 1] = copy
        end
        local fx_ctx = { player = ctx.player, registry = ctx.registry, source = weapon }
        -- Suppress default infliction messages — we print our own narration
        local old_print = _G.print
        local _captured = {}
        _G.print = function(...) _captured[#_captured + 1] = table.pack(...) end
        effects.process(fx_list, fx_ctx)
        _G.print = old_print
        -- Check if injury was created
        if ctx.player.injuries then
            for _, inj in ipairs(ctx.player.injuries) do
                if inj.source == source then
                    instance = inj
                end
            end
        end
        if fx_ctx.game_over then ctx.game_over = true end
    else
        -- Legacy direct path (weapons without pipeline_effects)
        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if not inj_ok then
            print("Something goes wrong.")
            return true
        end
        local _captured = {}
        local old_print = _G.print
        _G.print = function(...) _captured[#_captured + 1] = true end
        instance = injury_mod.inflict(ctx.player, profile.injury_type, source, body_area, effective_damage)
        _G.print = old_print
    end

    if not instance then
        print("The wound doesn't take hold.")
        return true
    end

    -- Set bloody state
    ctx.player.state = ctx.player.state or {}
    ctx.player.state.bloody = true
    ctx.player.state.bleed_ticks = 10

    -- Print the weapon's description with body area substituted
    if profile.description then
        print(string.format(profile.description, body_area))
    else
        print("You " .. verb_name .. " your " .. body_area .. " with " .. (weapon.name or "the weapon") .. ".")
    end

    return true
end

---------------------------------------------------------------------------
-- try_fsm_verb: Execute an FSM transition on an object for a given verb.
-- Returns true if a matching transition was found and executed.
-- Processes pipeline_effects (injuries, narration, mutations) through
-- the effects pipeline, including unconsciousness triggers.
-- NOTE: Does NOT mutate obj._state directly — FSM state management is
-- handled by the game loop via fsm_mod.transition in live play.
-- This function only evaluates the transition and routes its effects.
---------------------------------------------------------------------------
local function try_fsm_verb(ctx, obj, verb)
    if not obj or not obj.states or not obj.transitions then return false end

    local matched = nil
    for _, t in ipairs(obj.transitions) do
        if t.from == (obj._state or obj.initial_state) and t.trigger ~= "auto" then
            if t.verb == verb then
                matched = t
                break
            end
            if t.aliases then
                for _, a in ipairs(t.aliases) do
                    if a == verb then matched = t; break end
                end
                if matched then break end
            end
        end
    end

    if not matched then return false end

    -- Print transition message
    if matched.message and matched.message ~= "" then
        print(matched.message)
    end

    -- Process effects through the pipeline (injuries, unconsciousness, etc.)
    local fx = matched.pipeline_effects or matched.effect
    if fx and ctx.player then
        effects.process(fx, {
            player = ctx.player,
            source = obj,
            source_id = obj.id,
            registry = ctx.registry,
            time_offset = ctx.time_offset or 0,
        })
    end

    return true
end

H.try_fsm_verb = try_fsm_verb
H.fsm_mod = fsm_mod
H.presentation = presentation
H.preprocess = preprocess
H.traverse_effects = traverse_effects
H.effects = effects
H.materials = materials
H.context_window = context_window
H.fuzzy = fuzzy
H.GAME_SECONDS_PER_REAL_SECOND = GAME_SECONDS_PER_REAL_SECOND
H.GAME_START_HOUR = GAME_START_HOUR
H.DAYTIME_START = DAYTIME_START
H.DAYTIME_END = DAYTIME_END
H.interaction_verbs = interaction_verbs
H.get_all_carried_ids = get_all_carried_ids
H.next_instance_id = next_instance_id
H._hid = _hid
H._hobj = _hobj
H.err_not_found = err_not_found
H.err_cant_do_that = err_cant_do_that
H.err_nothing_happens = err_nothing_happens
H.show_hint = show_hint
H.matches_keyword = matches_keyword
H.hands_full = hands_full
H.first_empty_hand = first_empty_hand
H.which_hand = which_hand
H.count_hands_used = count_hands_used
H.find_part = find_part
H.detach_part = detach_part
H.reattach_part = reattach_part
H._fv_room = _fv_room
H._fv_surfaces = _fv_surfaces
H._fv_parts = _fv_parts
H._fv_hands = _fv_hands
H._fv_bags = _fv_bags
H._fv_worn = _fv_worn
H.find_visible = find_visible
H.find_in_inventory = find_in_inventory
H.find_tool_in_inventory = find_tool_in_inventory
H.provides_capability = provides_capability
H.find_visible_tool = find_visible_tool
H.consume_tool_charge = consume_tool_charge
H.remove_from_location = remove_from_location
H.container_contents_accessible = container_contents_accessible
H.find_mutation = find_mutation
H.spawn_objects = spawn_objects
H.perform_mutation = perform_mutation
H.inventory_weight = inventory_weight
H.move_spatial_object = move_spatial_object
H.random_body_area = random_body_area
H.parse_self_infliction = parse_self_infliction
H.handle_self_infliction = handle_self_infliction
H.get_game_time = get_game_time
H.is_daytime = is_daytime
H.format_time = format_time
H.time_of_day_desc = time_of_day_desc
H.get_light_level = get_light_level
H.has_some_light = has_some_light
H.vision_blocked_by_worn = vision_blocked_by_worn



---------------------------------------------------------------------------
-- Helper: find a portal object in the current room by keyword or direction.
-- Searches room.contents for objects with categories containing "portal"
-- and matches against keywords, name, id, or portal.direction_hint.
-- Returns the portal object if found, nil otherwise.
---------------------------------------------------------------------------
local function find_portal_by_keyword(ctx, keyword)
    if not keyword or keyword == "" then return nil end
    local room = ctx.current_room
    if not room or not room.contents then return nil end
    local kw = keyword:lower()
    for _, obj_id in ipairs(room.contents) do
        local obj = ctx.registry:get(obj_id)
        if obj and not obj.hidden and type(obj.categories) == "table" then
            local is_portal = false
            for _, cat in ipairs(obj.categories) do
                if cat == "portal" then is_portal = true; break end
            end
            if is_portal then
                -- Match by keyword (reuses existing matches_keyword)
                if matches_keyword(obj, kw) then return obj end
                -- Match by direction_hint (for "go north" → portal with hint "north")
                if obj.portal and obj.portal.direction_hint
                   and obj.portal.direction_hint:lower() == kw then
                    return obj
                end
            end
        end
    end
    return nil
end
H.find_portal_by_keyword = find_portal_by_keyword

---------------------------------------------------------------------------
-- Helper: sync bidirectional portal pair after an FSM state change.
-- When a portal transitions state, find its paired portal (same
-- bidirectional_id in another room) and apply the same state.
---------------------------------------------------------------------------
local function sync_bidirectional_portal(ctx, portal)
    if not portal or not portal.portal then return end
    local bid = portal.portal.bidirectional_id
    if not bid then return end
    local new_state = portal._state
    if not new_state then return end

    -- Search all rooms for the paired portal
    for _, room in pairs(ctx.rooms or {}) do
        for _, obj_id in ipairs(room.contents or {}) do
            local obj = ctx.registry:get(obj_id)
            if obj and obj ~= portal and obj.portal
               and obj.portal.bidirectional_id == bid then
                -- Apply the same state to the paired portal
                if obj.states and obj.states[new_state] and obj._state ~= new_state then
                    local old_state = obj._state
                    obj._state = new_state
                    -- Apply state properties from the new state
                    if obj.states[old_state] then
                        for k in pairs(obj.states[old_state]) do
                            if k ~= "on_tick" and k ~= "terminal" then
                                obj[k] = nil
                            end
                        end
                    end
                    for k, v in pairs(obj.states[new_state]) do
                        if k ~= "on_tick" and k ~= "terminal" then
                            obj[k] = v
                        end
                    end
                end
                return
            end
        end
    end
end
H.sync_bidirectional_portal = sync_bidirectional_portal

return H
