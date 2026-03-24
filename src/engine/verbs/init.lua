-- engine/verbs/init.lua
-- V1 verb handlers for the bedroom REPL.
-- Each handler has signature: function(context, noun)
-- Context is injected by the game loop at dispatch time.
--
-- Ownership:
--   Smithers (UI Engineer): Text presentation, sensory verb output, help,
--     error message wording, pronoun resolution, light-level-aware display.
--   Bart (Architect): Game state mutations, FSM interactions, containment,
--     tool resolution, core verb logic (take, put, open, close, crafting, etc.)

local verbs = {}

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
        obj, loc, parent, surface = _fv_room(kw, reg, room)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_surfaces(kw, reg, room)
        if obj then return obj, loc, parent, surface end
        obj, loc, parent, surface = _fv_parts(kw, reg, room)
        if obj then return obj, loc, parent, surface end
    else
        -- Acquisition / default: reaching for world objects → Room → Surfaces → Parts → Hands → Bags → Worn
        obj, loc, parent, surface = _fv_room(kw, reg, room)
        if obj then return obj, loc, parent, surface end
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
-- Helper: match an exit by keyword
---------------------------------------------------------------------------
local function exit_matches(exit, dir, keyword)
    local kw = keyword:lower()
    if dir:lower() == kw then return true end
    if type(exit) ~= "table" then return false end
    if exit.name and exit.name:lower():find(kw, 1, true) then return true end
    if exit.keywords then
        for _, k in ipairs(exit.keywords) do
            if k:lower() == kw or k:lower():find(kw, 1, true) then return true end
        end
    end
    return false
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

    -- Print movement message
    if verb == "push" and obj.push_message then
        print(obj.push_message)
    elseif obj.move_message then
        print(obj.move_message)
    else
        print("You " .. verb .. " " .. (obj.name or "it") .. " aside.")
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
            if covered and covered.hidden then
                -- FSM reveal transition
                if covered.states and covered._state == "hidden" then
                    for _, t in ipairs(covered.transitions or {}) do
                        if t.from == "hidden" and t.to == "revealed" then
                            fsm_mod.transition(reg, covered_id, "revealed", {})
                            break
                        end
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
-- Verb handler creation
---------------------------------------------------------------------------
function verbs.create()
    local handlers = {}

    ---------------------------------------------------------------------------
    -- LOOK (room view) / LOOK AT / LOOK IN / LOOK UNDER / EXAMINE
    ---------------------------------------------------------------------------
    handlers["look"] = function(ctx, noun)
        -- Bare "look" -- show room
        if noun == "" then
            -- Vision blocked by worn item (sack on head, etc.)
            local blocked, blocker = vision_blocked_by_worn(ctx)
            if blocked then
                print("You can't see a thing -- " .. (blocker.name or "something") .. " is covering your eyes.")
                return
            end

            local light = get_light_level(ctx)
            if light == "dark" then
                print("**" .. (ctx.current_room.name or "Unknown room") .. "**")
                print("It is too dark to see. You need a light source. Try 'feel' to grope around in the darkness.")
                local hour, minute = get_game_time(ctx)
                print("\n" .. time_of_day_desc(hour) .. " It is " .. format_time(hour, minute) .. ".")
                return
            end

            local room = ctx.current_room
            local parts = {}

            -- Dim light preamble
            if light == "dim" then
                parts[#parts + 1] = "Dim light seeps through the curtains -- enough to make out shapes, but details are lost in shadow."
            end

            -- Room description (permanent features)
            parts[#parts + 1] = room.description or ""

            -- Object presences (deduplicated — identical room_presence strings shown once)
            local presences = {}
            local seen_presences = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = ctx.registry:get(obj_id)
                if obj and not obj.hidden then
                    local text = obj.room_presence
                        or ("There is " .. (obj.name or obj.id) .. " here.")
                    if not seen_presences[text] then
                        seen_presences[text] = true
                        presences[#presences + 1] = text
                    end
                end
            end
            if #presences > 0 then
                parts[#parts + 1] = table.concat(presences, " ")
            end

            -- Exits
            local exit_lines = {}
            for dir, exit in pairs(room.exits or {}) do
                local e = type(exit) == "string"
                    and { name = dir, hidden = false }
                    or exit
                if not e.hidden then
                    local state = ""
                    if e.open == false and e.locked then
                        state = " (locked)"
                    elseif e.open == false then
                        state = " (closed)"
                    end
                    exit_lines[#exit_lines + 1] =
                        "  " .. dir .. ": " .. (e.name or dir) .. state
                end
            end
            if #exit_lines > 0 then
                parts[#parts + 1] = "Exits:\n" .. table.concat(exit_lines, "\n")
            end

            -- Time
            local hour, minute = get_game_time(ctx)
            parts[#parts + 1] = time_of_day_desc(hour) ..
                " It is " .. format_time(hour, minute) .. "."

            print("**" .. (room.name or "Unnamed room") .. "**")
            print("")
            print(table.concat(parts, "\n\n"))
            return
        end

        -- "look at X" → examine
        local target = noun:match("^at%s+(.+)")
        if target then
            local blocked = vision_blocked_by_worn(ctx)
            if blocked then
                print("You can't see anything with your vision blocked.")
                return
            end
            if not has_some_light(ctx) then
                print("It is too dark to see anything. Try 'feel' to explore by touch.")
                return
            end
            local obj = find_visible(ctx, target)
            if not obj then
                -- BUG-029: check exits (iron door, etc.)
                local room = ctx.current_room
                for dir, exit in pairs(room.exits or {}) do
                    if type(exit) == "table" and not exit.hidden
                        and exit_matches(exit, dir, target) then
                        local desc
                        if exit.locked then
                            desc = exit.description or ("A " .. (exit.name or "passage") .. ".")
                        elseif not exit.open and exit.description_unlocked then
                            desc = exit.description_unlocked
                        elseif exit.open and exit.description_open then
                            desc = exit.description_open
                        else
                            desc = exit.description or ("A " .. (exit.name or "passage") .. ".")
                        end
                        print(desc)
                        return
                    end
                end
                err_not_found(ctx)
                return
            end
            -- Mirror integration: is_mirror flag → appearance subsystem
            if obj.is_mirror then
                local app_ok, app_mod = pcall(require, "engine.player.appearance")
                if app_ok and app_mod then
                    print(app_mod.describe(ctx.player, ctx.registry))
                else
                    -- Fallback if appearance module fails to load
                    if obj.on_look then
                        print(obj.on_look(obj, ctx.registry))
                    else
                        print(obj.description or "You see nothing special.")
                    end
                end
                return
            end

            if obj.on_look then
                print(obj.on_look(obj, ctx.registry))
            else
                print(obj.description or "You see nothing special.")
            end

            -- BUG-064: Enumerate accessible surface contents visually (if no on_look)
            if not obj.on_look and obj.surfaces then
                for zone_name, zone in pairs(obj.surfaces) do
                    if zone.accessible ~= false and #(zone.contents or {}) > 0 then
                        local items = {}
                        for _, id in ipairs(zone.contents) do
                            local item = ctx.registry:get(id)
                            items[#items + 1] = item and item.name or id
                        end
                        print("You see " .. zone_name .. ":")
                        for _, item_name in ipairs(items) do
                            print("  " .. item_name)
                        end
                    end
                end
            end

            -- BUG-064: Enumerate simple container contents visually (if no on_look)
            -- Sensory gating: only show contents if container is open (or transparent)
            if not obj.on_look and obj.container and obj.contents and #obj.contents > 0
                and container_contents_accessible(obj, "visual") then
                local items = {}
                for _, id in ipairs(obj.contents) do
                    local item = ctx.registry:get(id)
                    items[#items + 1] = item and item.name or id
                end
                print("Inside you see:")
                for _, item_name in ipairs(items) do
                    print("  " .. item_name)
                end
            end
            return
        end

        -- "look in/under/on X" → inspect surface
        local prep, surface_target = noun:match("^(under)%s+(.+)$")
        if not prep then prep, surface_target = noun:match("^(underneath)%s+(.+)$") end
        if not prep then prep, surface_target = noun:match("^(beneath)%s+(.+)$") end
        if not prep then prep, surface_target = noun:match("^(in)%s+(.+)$") end
        if not prep then prep, surface_target = noun:match("^(inside)%s+(.+)$") end
        if not prep then prep, surface_target = noun:match("^(on)%s+(.+)$") end
        if not prep then prep, surface_target = noun:match("^(behind)%s+(.+)$") end

        if prep and surface_target then
            local blocked = vision_blocked_by_worn(ctx)
            if blocked then
                print("You can't see anything with your vision blocked.")
                return
            end
            if not has_some_light(ctx) then
                print("It is too dark to see anything. Try 'feel' to explore by touch.")
                return
            end
            local obj, loc_type, parent_obj = find_visible(ctx, surface_target)
            if not obj then
                err_not_found(ctx)
                return
            end
            -- Mirror integration: "look in mirror" triggers appearance subsystem
            if (prep == "in" or prep == "inside") and obj.is_mirror then
                local app_ok, app_mod = pcall(require, "engine.player.appearance")
                if app_ok and app_mod then
                    print(app_mod.describe(ctx.player, ctx.registry))
                else
                    print("You see your reflection, but can't make out details.")
                end
                return
            end
            -- BUG-097: If we found a part, redirect to the parent for surface access
            local target_name = obj.name or obj.id
            local check_obj = obj
            if loc_type == "part" and parent_obj then
                check_obj = parent_obj
            end
            if check_obj.surfaces then
                local surface_name =
                    (prep == "under" or prep == "underneath" or prep == "beneath") and "underneath"
                    or (prep == "in" or prep == "inside") and "inside"
                    or (prep == "on" or prep == "top") and "top"
                    or (prep == "behind") and "behind"
                    or nil
                local zone = surface_name and check_obj.surfaces[surface_name]
                if zone then
                    if zone.accessible == false then
                        local closed_name = target_name:gsub("^a ", "the "):gsub("^an ", "the ")
                        print("The " .. (closed_name:gsub("^[Tt]he ", "")) .. " is closed.")
                        return
                    end
                    if #(zone.contents or {}) == 0 then
                        print("There is nothing " .. prep .. " " .. (check_obj.name or check_obj.id) .. ".")
                    else
                        print("You find " .. prep .. " " .. (check_obj.name or check_obj.id) .. ":")
                        for _, id in ipairs(zone.contents) do
                            local item = ctx.registry:get(id)
                            print("  " .. (item and item.name or id))
                        end
                    end
                    return
                end
            end
            -- No matching surface -- fall through to general examine
            if obj.on_look then
                print(obj.on_look(obj, ctx.registry))
            else
                print(obj.description or "You see nothing special.")
            end
            return
        end

        -- "look X" → examine (shorthand for "look at X")
        local blocked2 = vision_blocked_by_worn(ctx)
        if blocked2 then
            print("You can't see anything with your vision blocked.")
            return
        end
        if not has_some_light(ctx) then
            print("It is too dark to see anything. Try 'feel' to explore by touch.")
            return
        end
        local obj = find_visible(ctx, noun)
        if not obj then
            -- BUG-029: check exits
            local room = ctx.current_room
            for dir, exit in pairs(room.exits or {}) do
                if type(exit) == "table" and not exit.hidden
                    and exit_matches(exit, dir, noun) then
                    local desc
                    if exit.locked then
                        desc = exit.description or ("A " .. (exit.name or "passage") .. ".")
                    elseif not exit.open and exit.description_unlocked then
                        desc = exit.description_unlocked
                    elseif exit.open and exit.description_open then
                        desc = exit.description_open
                    else
                        desc = exit.description or ("A " .. (exit.name or "passage") .. ".")
                    end
                    print(desc)
                    return
                end
            end
            err_not_found(ctx)
            return
        end
        if obj.on_look then
            print(obj.on_look(obj, ctx.registry))
        else
            print(obj.description or "You see nothing special.")
        end

        -- BUG-064: Enumerate accessible surface contents visually (if no on_look)
        if not obj.on_look and obj.surfaces then
            for zone_name, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false and #(zone.contents or {}) > 0 then
                    local items = {}
                    for _, id in ipairs(zone.contents) do
                        local item = ctx.registry:get(id)
                        items[#items + 1] = item and item.name or id
                    end
                    print("You see " .. zone_name .. ":")
                    for _, item_name in ipairs(items) do
                        print("  " .. item_name)
                    end
                end
            end
        end

        -- BUG-064: Enumerate simple container contents visually (if no on_look)
        -- Sensory gating: only show contents if container is open (or transparent)
        if not obj.on_look and obj.container and obj.contents and #obj.contents > 0
            and container_contents_accessible(obj, "visual") then
            local items = {}
            for _, id in ipairs(obj.contents) do
                local item = ctx.registry:get(id)
                items[#items + 1] = item and item.name or id
            end
            print("Inside you see:")
            for _, item_name in ipairs(items) do
                print("  " .. item_name)
            end
        end
    end

    handlers["examine"] = function(ctx, noun)
        if noun == "" then print("Examine what? Try 'look' to see what's around you.") return end
        local blocked = vision_blocked_by_worn(ctx)
        if blocked then
            -- Vision blocked but player knows what they're holding
            local obj = find_in_inventory(ctx, noun)
            if obj then
                print("You know " .. (obj.name or "it") .. " is there, but you can't see it.")
            else
                print("You can't see anything with your vision blocked.")
            end
            return
        end
        if has_some_light(ctx) then
            handlers["look"](ctx, "at " .. noun)
        else
            -- Dark: fall back to feel description
            local obj, loc_type, parent_obj, surface_key = find_visible(ctx, noun)
            if not obj then
                -- BUG-029: check exits by feel in darkness
                local room = ctx.current_room
                for dir, exit in pairs(room.exits or {}) do
                    if type(exit) == "table" and not exit.hidden
                        and exit_matches(exit, dir, noun) then
                        if exit.on_feel then
                            local feel = type(exit.on_feel) == "function"
                                and exit.on_feel(exit) or exit.on_feel
                            print("It's too dark to see, but you feel: " .. feel)
                        else
                            print("You sense " .. (exit.name or "a passage") .. " leading " .. dir .. ".")
                        end
                        return
                    end
                end
                print("You can't find anything like that in the darkness. Try 'feel' to explore by touch.")
                return
            end
            if obj.on_feel then
                local feel_text = type(obj.on_feel) == "function" and obj.on_feel(obj) or obj.on_feel
                print("It's too dark to see, but you feel: " .. feel_text)
            elseif obj.touch_description then
                print("It's too dark to see, but you feel: " .. obj.touch_description)
            else
                print("It's too dark to see, and you can't make out much by touch.")
            end

            -- BUG-065: If examining a part that carries contents, check parent's surfaces
            local check_obj = obj
            local check_inside_only = false
            if loc_type == "part" and parent_obj and obj.carries_contents then
                check_obj = parent_obj
                check_inside_only = true
            end

            -- BUG-064: Enumerate accessible surface contents by touch
            if check_obj.surfaces then
                for zone_name, zone in pairs(check_obj.surfaces) do
                    -- For parts with carries_contents, only show "inside" surface
                    if (not check_inside_only or zone_name == "inside") then
                        if zone.accessible ~= false and #(zone.contents or {}) > 0 then
                            local items = {}
                            for _, id in ipairs(zone.contents) do
                                local item = ctx.registry:get(id)
                                items[#items + 1] = item and item.name or id
                            end
                            print("Your fingers find " .. zone_name .. ":")
                            for _, item_name in ipairs(items) do
                                print("  " .. item_name)
                            end
                        end
                    end
                end
            end

            -- BUG-064: Enumerate simple container contents by touch
            -- Sensory gating: only show contents if container is open
            if check_obj.container and check_obj.contents and #check_obj.contents > 0
                and container_contents_accessible(check_obj, "tactile") then
                local items = {}
                for _, id in ipairs(check_obj.contents) do
                    local item = ctx.registry:get(id)
                    items[#items + 1] = item and item.name or id
                end
                print("Inside you feel:")
                for _, item_name in ipairs(items) do
                    print("  " .. item_name)
                end
            end
        end
    end
    handlers["x"] = handlers["examine"]
    handlers["find"] = handlers["examine"]
    handlers["check"] = handlers["examine"]
    handlers["inspect"] = handlers["examine"]
    handlers["read"] = function(ctx, noun)
        if noun == "" then print("Read what? Try 'look' to see what's here, then 'read [item]'.") return end
        if not has_some_light(ctx) then
            print("It is too dark to read anything. You'll need a light source first.")
            return
        end

        -- Find the object: inventory first (more natural), then room
        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end

        if not obj then
            print("You don't see anything called that to read. Try 'look' to see what's around you.")
            return
        end

        -- Check if object is on fire
        if obj._state and obj._state == "burning" then
            print("The flames make it impossible to read!")
            return
        end

        -- Check if object is readable (categories contains "readable")
        local is_readable = false
        if obj.categories and type(obj.categories) == "table" then
            for _, cat in ipairs(obj.categories) do
                if cat == "readable" then is_readable = true; break end
            end
        end

        if not is_readable and not obj.grants_skill then
            print("That's not something you can read.")
            return
        end

        -- Skill-granting readable
        if obj.grants_skill then
            local skill = obj.grants_skill
            if obj.skill_granted or (ctx.player.skills and ctx.player.skills[skill]) then
                print(obj.already_learned_message
                    or ("You read it again, but you already know this."))
            else
                ctx.player.skills[skill] = true
                obj.skill_granted = true
                print(obj.skill_message
                    or ("You read carefully and learn something new."))
            end
            return
        end

        -- Readable but no skill: delegate to examine for description
        handlers["look"](ctx, "at " .. noun)
    end
    handlers["search"] = function(ctx, noun)
        if noun == "" then
            handlers["look"](ctx, "")
        else
            handlers["examine"](ctx, noun)
        end
    end

    ---------------------------------------------------------------------------
    -- FEEL / TOUCH / GROPE -- works even in total darkness
    ---------------------------------------------------------------------------
    handlers["feel"] = function(ctx, noun)
        -- Treat "around", "room", "here" the same as bare feel (room sweep)
        local sweep_words = { [""] = true, ["around"] = true, ["room"] = true, ["here"] = true,
                              ["around me"] = true, ["surroundings"] = true }
        if sweep_words[noun] then
            -- Feel around the room
            local room = ctx.current_room
            local found = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = ctx.registry:get(obj_id)
                if obj and not obj.hidden then
                    local desc = obj.name or obj.id
                    found[#found + 1] = desc
                end
            end
            if #found > 0 then
                print("You reach out in the darkness, feeling around you...")
                for _, entry in ipairs(found) do
                    print("  " .. entry)
                end
            else
                print("You feel around but find nothing within reach.")
            end
            return
        end

        -- Handle "feel in/inside/under/underneath/beneath {target}" prepositional phrases
        -- BUG-089: Track the preposition so "feel inside X" limits to interior only
        local container_noun = nil
        local surface_prep = nil
        local in_match = noun:match("^in%s+(.+)") or noun:match("^inside%s+(.+)")
        if in_match then
            container_noun = in_match
            surface_prep = "inside"
        end
        if not container_noun then
            local p, t = noun:match("^(under)%s+(.+)")
            if not p then p, t = noun:match("^(underneath)%s+(.+)") end
            if not p then p, t = noun:match("^(beneath)%s+(.+)") end
            if p then
                surface_prep = "underneath"
                container_noun = t
            end
        end
        -- Bare "feel inside" / "feel in" → use last-interacted container
        if not container_noun and (noun == "inside" or noun == "in") then
            if ctx.last_object and (ctx.last_object.surfaces or (ctx.last_object.container and ctx.last_object.contents)) then
                container_noun = ctx.last_object.id
            else
                print("Feel inside what? Try 'feel' to explore your surroundings by touch.")
                return
            end
        end
        if container_noun then
            local cobj, loc_type, parent_obj = find_visible(ctx, container_noun)
            if not cobj then
                print("You can't feel anything like that nearby. Try 'feel' to explore what's around you.")
                return
            end
            -- BUG-058: If we found a part, redirect to the parent for surface access
            -- BUG-096: Preserve the target name for gating messages
            -- #88: Don't redirect when the part itself is a container (e.g., drawer)
            local target_name = cobj.name or "that"
            if loc_type == "part" and parent_obj and not cobj.container then
                cobj = parent_obj
            end
            local found_anything = false
            -- BUG-089: If a specific surface prep was given, check only that surface
            if surface_prep and cobj.surfaces and cobj.surfaces[surface_prep] then
                local zone = cobj.surfaces[surface_prep]
                if zone.accessible == false then
                    print("You can't reach " .. noun:match("^(%S+)") .. " " .. target_name .. ".")
                    return
                end
                if #(zone.contents or {}) > 0 then
                    print("Your fingers find " .. surface_prep .. " " .. (cobj.name or "that") .. ":")
                    for _, id in ipairs(zone.contents) do
                        local item = ctx.registry:get(id)
                        print("  " .. (item and item.name or id))
                    end
                    found_anything = true
                else
                    print("You feel " .. noun:match("^(%S+)") .. " " .. (cobj.name or "that") .. " but find nothing.")
                end
                -- Also check simple container contents for "inside" prep
                -- Sensory gating: only show contents if container is open
                if surface_prep == "inside" and cobj.container and cobj.contents and #cobj.contents > 0
                    and container_contents_accessible(cobj, "tactile") then
                    local items = {}
                    for _, id in ipairs(cobj.contents) do
                        local item = ctx.registry:get(id)
                        items[#items + 1] = item and item.name or id
                    end
                    print("Inside you feel:")
                    for _, item_name in ipairs(items) do
                        print("  " .. item_name)
                    end
                    found_anything = true
                end
                if not found_anything then
                    print("You feel " .. noun:match("^(%S+)") .. " " .. (cobj.name or "that") .. " but find nothing.")
                end
                return
            end
            -- When surface_prep is set but the specific surface doesn't exist,
            -- only check simple container contents (don't show unrelated surfaces)
            if surface_prep then
                if cobj.container and cobj.contents and #cobj.contents > 0
                    and container_contents_accessible(cobj, "tactile") then
                    local items = {}
                    for _, id in ipairs(cobj.contents) do
                        local item = ctx.registry:get(id)
                        items[#items + 1] = item and item.name or id
                    end
                    print("Inside you feel:")
                    for _, item_name in ipairs(items) do
                        print("  " .. item_name)
                    end
                    found_anything = true
                end
                if not found_anything then
                    print("You can't feel inside " .. (cobj.name or "that") .. ".")
                end
                return
            end
            -- Check surface contents (e.g., nightstand "inside" zone)
            if cobj.surfaces then
                for zone_name, zone in pairs(cobj.surfaces) do
                    if zone.accessible ~= false and #(zone.contents or {}) > 0 then
                        local items = {}
                        for _, id in ipairs(zone.contents) do
                            local item = ctx.registry:get(id)
                            items[#items + 1] = item and item.name or id
                        end
                        print("Your fingers find " .. zone_name .. ":")
                        for _, item_name in ipairs(items) do
                            print("  " .. item_name)
                        end
                        found_anything = true
                    end
                end
            end
            -- Check simple container contents
            -- Sensory gating: only show contents if container is open
            if cobj.container and cobj.contents and #cobj.contents > 0
                and container_contents_accessible(cobj, "tactile") then
                local items = {}
                for _, id in ipairs(cobj.contents) do
                    local item = ctx.registry:get(id)
                    items[#items + 1] = item and item.name or id
                end
                print("Inside you feel:")
                for _, item_name in ipairs(items) do
                    print("  " .. item_name)
                end
                found_anything = true
            end
            if not found_anything then
                if cobj.surfaces then
                    local any_inaccessible = false
                    for _, zone in pairs(cobj.surfaces) do
                        if zone.accessible == false then any_inaccessible = true; break end
                    end
                    if any_inaccessible then
                        print("You can't reach inside " .. (cobj.name or "that") .. ". It seems closed.")
                    else
                        print("You feel around inside " .. (cobj.name or "that") .. " but find nothing.")
                    end
                else
                    print("You can't feel inside " .. (cobj.name or "that") .. ".")
                end
            end
            return
        end

        local obj, loc_type, parent_obj, surface_key = find_visible(ctx, noun)
        if not obj then
            -- BUG-029: check exits by touch (iron door, etc.)
            local room = ctx.current_room
            for dir, exit in pairs(room.exits or {}) do
                if type(exit) == "table" and not exit.hidden
                    and exit_matches(exit, dir, noun) then
                    if exit.on_feel then
                        local feel = type(exit.on_feel) == "function"
                            and exit.on_feel(exit) or exit.on_feel
                        print(feel)
                    else
                        print("You feel " .. (exit.name or "a passage") .. ". It leads " .. dir .. ".")
                    end
                    return
                end
            end
            print("You can't feel anything like that nearby. Try 'feel' to explore what's around you.")
            return
        end

        -- Prefer on_feel (rich sensory), fall back to touch_description, then generic
        if obj.on_feel then
            local feel_text = type(obj.on_feel) == "function" and obj.on_feel(obj) or obj.on_feel
            print(feel_text)
        elseif obj.touch_description then
            print(obj.touch_description)
        else
            print("You run your hands over " .. (obj.name or "it") ..
                ". " .. (obj.description or "It feels ordinary."))
        end

        -- BUG-065: If feeling a part that carries contents, check parent's surfaces
        local check_obj = obj
        local check_inside_only = false
        if loc_type == "part" and parent_obj and obj.carries_contents then
            check_obj = parent_obj
            check_inside_only = true
        end

        -- Enumerate accessible surface contents by touch
        if check_obj.surfaces then
            for zone_name, zone in pairs(check_obj.surfaces) do
                -- For parts with carries_contents, only show "inside" surface
                if (not check_inside_only or zone_name == "inside") then
                    if zone.accessible ~= false and #(zone.contents or {}) > 0 then
                        local items = {}
                        for _, id in ipairs(zone.contents) do
                            local item = ctx.registry:get(id)
                            items[#items + 1] = item and item.name or id
                        end
                        print("Your fingers find " .. zone_name .. ":")
                        for _, item_name in ipairs(items) do
                            print("  " .. item_name)
                        end
                    end
                end
            end
        end

        -- Enumerate simple container contents by touch
        -- Sensory gating: only show contents if container is open
        if check_obj.container and check_obj.contents and #check_obj.contents > 0
            and container_contents_accessible(check_obj, "tactile") then
            local items = {}
            for _, id in ipairs(check_obj.contents) do
                local item = ctx.registry:get(id)
                items[#items + 1] = item and item.name or id
            end
            print("Inside you feel:")
            for _, item_name in ipairs(items) do
                print("  " .. item_name)
            end
        end
    end
    handlers["touch"] = handlers["feel"]
    handlers["grope"] = handlers["feel"]

    ---------------------------------------------------------------------------
    -- SEARCH / FIND -- Progressive traverse system (turn-based, interruptible)
    -- Wayne directive 2026-03-22T12:25, 12:31: Search is a progressive TRAVERSE
    -- NOT instant query. Engine walks objects near→far, narrating as it goes.
    -- Auto-opens containers, costs 1 turn per step, can be interrupted.
    ---------------------------------------------------------------------------
    local search_mod = require("engine.search")
    
    handlers["search"] = function(ctx, noun)
        -- Parse search syntax patterns
        local target = nil
        local scope = nil
        
        -- BUG-081: Strip articles from bare noun before further processing
        local stripped_noun = preprocess.strip_articles(noun)
        
        -- BUG-073: Treat "the room", "the area" as sweep keywords
        -- BUG-078: "everything", "anything", "all" → undirected sweep
        local sweep_words = { [""] = true, ["around"] = true, ["room"] = true, ["here"] = true,
                              ["around me"] = true, ["surroundings"] = true,
                              ["the room"] = true, ["the area"] = true, ["area"] = true,
                              ["everywhere"] = true, ["this place"] = true,
                              ["everything"] = true, ["anything"] = true, ["all"] = true }
        
        if sweep_words[noun] or sweep_words[stripped_noun] then
            -- Bare search - undirected room sweep
            search_mod.search(ctx, nil, nil)
            return
        end
        
        -- Pattern: "search [scope] for [target]"
        local scope_part, target_part = stripped_noun:match("^(.-)%s+for%s+(.+)$")
        if scope_part and target_part then
            -- BUG-081: strip articles from scope and target
            scope_part = preprocess.strip_articles(scope_part)
            target_part = preprocess.strip_articles(target_part)
            -- Resolve scope to object ID
            -- BUG-082: Try find_visible — if scope is a part (drawer), use parent
            local scope_obj, scope_loc, scope_parent = find_visible(ctx, scope_part)
            if not scope_obj then
                print("You don't see " .. scope_part .. " here.")
                return
            end
            -- BUG-082: If scope resolves to a part, use its parent for search
            -- #41: Pass part's surface mapping so search restricts to that surface
            if scope_loc == "part" and scope_parent then
                local part_surface = scope_obj.surface
                scope_obj = scope_parent
                search_mod.search(ctx, target_part, scope_obj.id, part_surface)
                return
            end
            search_mod.search(ctx, target_part, scope_obj.id)
            return
        end
        
        -- Pattern: "search for [target]" (already stripped by preprocess.lua if present)
        -- If noun doesn't contain "for", treat as either:
        --   1. A scope to search ("search nightstand")
        --   2. A target to find ("search matchbox")
        -- Prefer scope interpretation (search a specific object)
        
        -- BUG-146 (#46): Use exact-only matching for scope detection.
        -- Fuzzy matching can produce false positives (e.g., "match" → rug's
        -- keyword "mat" via Levenshtein distance 2) that hijack the search
        -- into treating the wrong object as scope instead of doing a targeted
        -- room-wide search.
        ctx._exact_only = true
        local obj, obj_loc, obj_parent = find_visible(ctx, stripped_noun)
        ctx._exact_only = nil
        if obj then
            -- BUG-082: If obj is a part (drawer), use its parent for search
            -- #41: Pass part's surface mapping so search restricts to that surface
            if obj_loc == "part" and obj_parent then
                local part_surface = obj.surface
                obj = obj_parent
                search_mod.search(ctx, nil, obj.id, part_surface)
                return
            end
            -- Found an object - treat as scope (BUG-079: scoped undirected search)
            search_mod.search(ctx, nil, obj.id)
        else
            -- Not found as object - treat as target (room-wide search)
            search_mod.search(ctx, stripped_noun, nil)
        end
    end
    
    handlers["find"] = function(ctx, noun)
        if not noun or noun == "" then
            print("Find what?")
            return
        end
        
        -- BUG-081: Strip articles from noun
        local stripped_noun = preprocess.strip_articles(noun)
        
        -- BUG-078: "find everything/anything/all" → undirected sweep
        if stripped_noun == "everything" or stripped_noun == "anything" or stripped_noun == "all" then
            search_mod.search(ctx, nil, nil)
            return
        end
        
        -- Pattern: "find [target] in [scope]"
        local target_part, scope_part = stripped_noun:match("^(.-)%s+in%s+(.+)$")
        if target_part and scope_part then
            -- BUG-081: strip articles
            target_part = preprocess.strip_articles(target_part)
            scope_part = preprocess.strip_articles(scope_part)
            -- Resolve scope to object ID
            local scope_obj = find_visible(ctx, scope_part)
            if not scope_obj then
                print("You don't see " .. scope_part .. " here.")
                return
            end
            search_mod.find(ctx, target_part, scope_obj.id)
            return
        end
        
        -- Simple "find [target]" - room-wide targeted search
        search_mod.find(ctx, stripped_noun, nil)
    end

    ---------------------------------------------------------------------------
    -- SMELL / SNIFF -- works in darkness AND light
    ---------------------------------------------------------------------------
    handlers["smell"] = function(ctx, noun)
        if noun == "" then
            -- Room-level smell sweep (like feel does for touch)
            local room = ctx.current_room
            if room.on_smell then
                print("You smell the air around you.")
                print(room.on_smell)
            else
                print("You smell the air around you. Dust and stillness.")
            end
            -- Sweep objects for individual smells
            local reg = ctx.registry
            local found = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = reg:get(obj_id)
                if obj and not obj.hidden and obj.on_smell then
                    found[#found + 1] = { name = obj.name or obj.id, smell = obj.on_smell }
                end
                if obj and obj.surfaces then
                    for _, zone in pairs(obj.surfaces) do
                        if zone.accessible ~= false then
                            for _, item_id in ipairs(zone.contents or {}) do
                                local item = reg:get(item_id)
                                if item and item.on_smell then
                                    found[#found + 1] = { name = item.name or item.id, smell = item.on_smell }
                                end
                            end
                        end
                    end
                end
            end
            -- Also check player hands
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local h_obj = _hobj(hand, reg)
                    if h_obj and h_obj.on_smell then
                        found[#found + 1] = { name = h_obj.name or h_obj.id, smell = h_obj.on_smell }
                    end
                end
            end
            if #found > 0 then
                print("Your nose picks up:")
                for _, entry in ipairs(found) do
                    print("  " .. entry.name .. " -- " .. entry.smell)
                end
            end
            return
        end

        local obj = find_visible(ctx, noun)
        if not obj then
            print("You can't find anything like that to smell.")
            return
        end

        if obj.on_smell then
            print(obj.on_smell)
        else
            print("You don't smell anything distinctive.")
        end
    end
    handlers["sniff"] = handlers["smell"]

    ---------------------------------------------------------------------------
    -- TASTE / LICK -- works in darkness AND light (DANGEROUS)
    ---------------------------------------------------------------------------
    handlers["taste"] = function(ctx, noun)
        if noun == "" then
            print("You're not going to lick the floor... are you?")
            return
        end

        local obj = find_visible(ctx, noun)
        if not obj then
            print("You can't find anything like that to taste.")
            return
        end

        if obj.on_taste then
            print(obj.on_taste)
        else
            print("You give " .. (obj.name or "it") .. " a cautious lick. Nothing remarkable.")
        end

        -- Check for taste effects AFTER printing the taste description
        if obj.on_taste_effect then
            effects.process(obj.on_taste_effect, {
                player = ctx.player,
                registry = ctx.registry,
                source = obj,
                source_id = obj.id,
            })
        end
    end
    handlers["lick"] = handlers["taste"]

    ---------------------------------------------------------------------------
    -- LISTEN / HEAR -- works in darkness AND light
    ---------------------------------------------------------------------------
    handlers["listen"] = function(ctx, noun)
        if noun == "" then
            -- Room-level listen sweep (like feel does for touch)
            local room = ctx.current_room
            if room.on_listen then
                print(room.on_listen)
            else
                print("You hold your breath and listen. Silence -- save for your own heartbeat.")
            end
            -- Sweep objects for individual sounds
            local reg = ctx.registry
            local found = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = reg:get(obj_id)
                if obj and not obj.hidden and obj.on_listen then
                    found[#found + 1] = { name = obj.name or obj.id, sound = obj.on_listen }
                end
                if obj and obj.surfaces then
                    for _, zone in pairs(obj.surfaces) do
                        if zone.accessible ~= false then
                            for _, item_id in ipairs(zone.contents or {}) do
                                local item = reg:get(item_id)
                                if item and item.on_listen then
                                    found[#found + 1] = { name = item.name or item.id, sound = item.on_listen }
                                end
                            end
                        end
                    end
                end
            end
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local h_obj = _hobj(hand, reg)
                    if h_obj and h_obj.on_listen then
                        found[#found + 1] = { name = h_obj.name or h_obj.id, sound = h_obj.on_listen }
                    end
                end
            end
            if #found > 0 then
                print("You catch faint sounds:")
                for _, entry in ipairs(found) do
                    print("  " .. entry.name .. " -- " .. entry.sound)
                end
            end
            return
        end

        -- "listen to X"
        local target = noun:match("^to%s+(.+)") or noun

        local obj = find_visible(ctx, target)
        if not obj then
            print("You can't hear anything like that.")
            return
        end

        if obj.on_listen then
            print(obj.on_listen)
        else
            print("You listen closely. " .. (obj.name or "It") .. " makes no sound.")
        end
    end
    handlers["hear"] = handlers["listen"]

    ---------------------------------------------------------------------------
    -- TAKE / GET / PICK UP / GET X FROM Y
    ---------------------------------------------------------------------------
    handlers["take"] = function(ctx, noun)
        if noun == "" then print("Take what?") return end

        -- "take off X" → remove (unequip worn item)
        local off_target = noun:match("^off%s+(.+)")
        if off_target then
            handlers["remove"](ctx, off_target)
            return
        end

        -- "pick up X"
        local target = noun:match("^up%s+(.+)") or noun

        -- "get X from Y" -- extract from a bag/container (carried or visible)
        local from_item, from_container = target:match("^(.+)%s+from%s+(.+)$")
        if from_item then
            local bag = find_in_inventory(ctx, from_container)
            if not bag then
                -- Also check visible containers (detached drawer on floor, etc.)
                local visible_bag = find_visible(ctx, from_container)
                if visible_bag and (visible_bag.container and visible_bag.contents) then
                    bag = visible_bag
                elseif visible_bag and visible_bag.surfaces then
                    -- Surface-based container (wardrobe, etc.)
                    bag = visible_bag
                elseif visible_bag then
                    print((visible_bag.name or "That") .. " is not a container.")
                    return
                else
                    print("You don't see " .. from_container .. " here.")
                    return
                end
            end

            -- Determine where to search: regular contents or surfaces
            local search_lists = {}
            if bag.container and bag.contents then
                search_lists[#search_lists + 1] = { source = bag.contents, type = "contents" }
            end
            if bag.surfaces then
                for sname, zone in pairs(bag.surfaces) do
                    if zone.accessible ~= false and zone.contents then
                        search_lists[#search_lists + 1] = { source = zone.contents, type = "surface", name = sname }
                    end
                end
            end

            if #search_lists == 0 then
                print((bag.name or "That") .. " is not a container.")
                return
            end

            local kw = from_item:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            local found_idx, found_id, found_list
            for _, sl in ipairs(search_lists) do
                for i, item_id in ipairs(sl.source) do
                    local item = ctx.registry:get(item_id)
                    if item and matches_keyword(item, kw) then
                        found_idx = i
                        found_id = item_id
                        found_list = sl.source
                        break
                    end
                end
                if found_id then break end
            end
            if not found_id then
                print("There is no " .. from_item .. " in " .. (bag.name or "that") .. ".")
                return
            end
            local slot = first_empty_hand(ctx)
            if not slot then
                print("Your hands are full. Drop something first.")
                return
            end
            table.remove(found_list, found_idx)
            local item = ctx.registry:get(found_id)
            item.location = "player"
            if not item.instance_id then item.instance_id = next_instance_id() end
            ctx.player.hands[slot] = item
            print("You take " .. (item and item.name or found_id) .. " from " .. (bag.name or "the container") .. ".")
            return
        end

        local obj, where, parent, sname = find_visible(ctx, target)
        if not obj then
            err_not_found(ctx)
            return
        end

        -- Bug #53: Guard against duplicate take — if already in player's hands, skip
        if obj.location == "player" then
            for i = 1, 2 do
                if ctx.player.hands[i] then
                    local hid = _hid(ctx.player.hands[i])
                    if hid == obj.id then
                        print("You already have that.")
                        return
                    end
                end
            end
        end

        -- BUG-091: Prefer non-spent items from containers over terminal items on floor.
        -- Checks hand-held containers first, then visible containers in the room.
        if where == "room" and obj._state and obj.states then
            local cur_state = obj.states[obj._state]
            if cur_state and cur_state.terminal then
                local reg = ctx.registry
                local kw = target:lower()
                    :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
                local alt_obj, alt_parent
                -- 1) Search carried containers (bags in hands)
                for i = 1, 2 do
                    local hand = ctx.player.hands[i]
                    if hand then
                        local bag = _hobj(hand, reg)
                        if bag and bag.container and bag.contents then
                            for _, item_id in ipairs(bag.contents) do
                                local item = reg:get(item_id)
                                if item and matches_keyword(item, kw) then
                                    local istate = item.states and item._state
                                        and item.states[item._state]
                                    if not istate or not istate.terminal then
                                        alt_obj = item
                                        alt_parent = bag
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if alt_obj then break end
                end
                -- 2) Search visible containers in the room (surfaces, open containers)
                if not alt_obj then
                    local room = ctx.current_room
                    for _, room_obj_id in ipairs(room.contents or {}) do
                        local room_obj = reg:get(room_obj_id)
                        if room_obj then
                            -- Check accessible surface containers (e.g. matchbox on nightstand)
                            if room_obj.surfaces then
                                for _, zone in pairs(room_obj.surfaces) do
                                    if zone.accessible ~= false then
                                        for _, item_id in ipairs(zone.contents or {}) do
                                            local item = reg:get(item_id)
                                            if item and item.container and item.contents
                                                    and item.accessible ~= false then
                                                for _, inner_id in ipairs(item.contents) do
                                                    local inner = reg:get(inner_id)
                                                    if inner and matches_keyword(inner, kw) then
                                                        local ist = inner.states and inner._state
                                                            and inner.states[inner._state]
                                                        if not ist or not ist.terminal then
                                                            alt_obj = inner
                                                            alt_parent = item
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                            if alt_obj then break end
                                        end
                                    end
                                    if alt_obj then break end
                                end
                            end
                            -- Check non-surface containers in room
                            if not alt_obj and room_obj.container and room_obj.contents
                                    and room_obj.accessible ~= false then
                                for _, item_id in ipairs(room_obj.contents) do
                                    local item = reg:get(item_id)
                                    if item and matches_keyword(item, kw) then
                                        local ist = item.states and item._state
                                            and item.states[item._state]
                                        if not ist or not ist.terminal then
                                            alt_obj = item
                                            alt_parent = room_obj
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if alt_obj then break end
                    end
                end
                if alt_obj then
                    obj = alt_obj
                    where = "bag"
                    parent = alt_parent
                    sname = nil
                end
            end
        end

        if where == "hand" or where == "worn" then
            print("You already have that.")
            return
        end

        -- "bag" means item is inside a container the player is holding.
        -- Allow extracting it to a free hand (e.g., pulling a match from a matchbox).
        if where == "bag" and parent then
            if not obj.portable then
                print("You can't carry " .. (obj.name or "that") .. ".")
                return
            end
            local slot = first_empty_hand(ctx)
            if not slot then
                print("Your hands are full. Drop something first.")
                return
            end
            if parent.contents then
                for i, cid in ipairs(parent.contents) do
                    if cid == obj.id then
                        table.remove(parent.contents, i)
                        break
                    end
                end
            end
            if not obj.instance_id then obj.instance_id = next_instance_id() end
            ctx.player.hands[slot] = obj
            obj.location = "player"
            print("You take " .. (obj.name or obj.id) .. " from " .. (parent.name or "the container") .. ".")
            return
        end

        if not obj.portable then
            print("You can't carry " .. (obj.name or "that") .. ".")
            return
        end

        -- Two-handed carry check
        local hr = obj.hands_required or 1
        if hr >= 2 then
            local used, free = count_hands_used(ctx)
            if free < 2 then
                print("You need both hands free to carry " .. (obj.name or "that") .. ".")
                return
            end
            remove_from_location(ctx, obj)
            if not obj.instance_id then obj.instance_id = next_instance_id() end
            ctx.player.hands[1] = obj
            ctx.player.hands[2] = obj
            obj.location = "player"
            print("You take " .. (obj.name or obj.id) .. " with both hands.")
            return
        end

        local slot = first_empty_hand(ctx)
        if not slot then
            print("Your hands are full. Drop something first.")
            return
        end

        remove_from_location(ctx, obj)
        if not obj.instance_id then obj.instance_id = next_instance_id() end
        ctx.player.hands[slot] = obj
        obj.location = "player"

        print("You take " .. (obj.name or obj.id) .. ".")
    end

    handlers["get"] = function(ctx, noun)
        -- "get X from Y" and regular get both go through take
        handlers["take"](ctx, noun)
    end
    handlers["pick"] = function(ctx, noun)
        -- "pick lock" → lockpicking (stub)
        if noun:match("^lock") then
            print("You don't know how to pick locks.")
            return
        end
        -- Otherwise fall through to take ("pick up X", "pick X")
        handlers["take"](ctx, noun)
    end
    handlers["grab"] = handlers["take"]

    ---------------------------------------------------------------------------
    -- PULL / YANK / TUG / EXTRACT — detach composite parts
    ---------------------------------------------------------------------------
    handlers["pull"] = function(ctx, noun)
        if noun == "" then print("Pull what?") return end

        -- Strip "out" preposition: "pull out drawer" → "drawer"
        local target = noun:match("^out%s+(.+)") or noun
        -- "pull X out of Y" → just use X
        target = target:match("^(.+)%s+out%s+of%s+") or target
        -- "pull X from Y" → just use X
        target = target:match("^(.+)%s+from%s+") or target

        -- First: check if the noun matches a detachable part
        local part, parent_obj, part_key = find_part(ctx, target)
        if part and part.detachable then
            -- Check if this verb is valid for this part
            local valid_verb = false
            if part.detach_verbs then
                for _, v in ipairs(part.detach_verbs) do
                    if v == "pull" then valid_verb = true; break end
                end
            else
                valid_verb = true  -- default: PULL always works
            end

            if valid_verb then
                local new_obj, msg = detach_part(ctx, parent_obj, part_key)
                if new_obj then
                    print(msg)
                else
                    print(msg or "You can't pull that out.")
                end
                return
            end
        end

        -- Non-detachable part: descriptive response
        if part and not part.detachable then
            print("You pull at " .. (part.name or "it") .. ", but it won't budge. It's firmly attached.")
            return
        end

        -- Fall through: try FSM "pull" transition on a visible object
        local obj = find_visible(ctx, target)
        if obj then
            -- Spatial movement for movable objects
            if obj.movable then
                move_spatial_object(ctx, obj, "pull")
                return
            end

            if obj.states then
                local transitions = fsm_mod.get_transitions(obj)
                local target_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "pull" then target_trans = t; break end
                    if t.verb == "open" then target_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "pull" then target_trans = t; break end
                        end
                        if target_trans then break end
                    end
                end
                if target_trans then
                    local trans = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                    if trans then
                        print(trans.message or ("You pull " .. (obj.name or obj.id) .. "."))
                    else
                        print("You can't pull " .. (obj.name or "that") .. ".")
                    end
                    return
                end
            end
            err_nothing_happens(obj)
            return
        end

        err_not_found(ctx)
    end

    handlers["yank"] = handlers["pull"]
    handlers["tug"] = handlers["pull"]
    handlers["extract"] = handlers["pull"]

    ---------------------------------------------------------------------------
    -- PUSH / SHOVE — move heavy objects aside
    ---------------------------------------------------------------------------
    handlers["push"] = function(ctx, noun)
        if noun == "" then print("Push what?") return end

        -- Strip trailing "aside" / "away" / "over"
        local target = noun:gsub("%s+aside$", ""):gsub("%s+away$", ""):gsub("%s+over$", "")

        local obj = find_visible(ctx, target)
        if not obj then
            err_not_found(ctx)
            return
        end

        move_spatial_object(ctx, obj, "push")
    end

    handlers["shove"] = handlers["push"]

    ---------------------------------------------------------------------------
    -- MOVE / SHIFT — general spatial movement
    ---------------------------------------------------------------------------
    handlers["move"] = function(ctx, noun)
        if noun == "" then print("Move what?") return end

        -- Strip trailing "aside" / "away" / "over"
        local target = noun:gsub("%s+aside$", ""):gsub("%s+away$", ""):gsub("%s+over$", "")

        local obj = find_visible(ctx, target)
        if not obj then
            err_not_found(ctx)
            return
        end

        move_spatial_object(ctx, obj, "move")
    end

    handlers["shift"] = handlers["move"]
    handlers["slide"] = handlers["move"]

    ---------------------------------------------------------------------------
    -- LIFT — pick up or reveal what's under something
    ---------------------------------------------------------------------------
    handlers["lift"] = function(ctx, noun)
        if noun == "" then print("Lift what?") return end

        local obj = find_visible(ctx, noun)
        if not obj then
            err_not_found(ctx)
            return
        end

        -- If it's movable, treat like pull
        if obj.movable then
            move_spatial_object(ctx, obj, "lift")
            return
        end

        -- If portable, try to pick it up
        if obj.portable then
            handlers["take"](ctx, noun)
            return
        end

        if obj.weight and obj.weight >= 50 then
            print("You strain to lift " .. (obj.name or "it") .. ", but it won't budge. It's far too heavy.")
        else
            print("You can't lift " .. (obj.name or "that") .. ".")
        end
    end

    ---------------------------------------------------------------------------
    -- UNCORK / UNSTOP / UNSEAL — shorthand for detaching cork-type parts
    ---------------------------------------------------------------------------
    handlers["uncork"] = function(ctx, noun)
        if noun == "" then print("Uncork what?") return end

        local obj = find_visible(ctx, noun)
        if not obj then
            err_not_found(ctx)
            return
        end

        -- Check if the object has a cork part we can detach
        if obj.parts then
            for part_key, part in pairs(obj.parts) do
                if part.detachable and part.detach_verbs then
                    for _, v in ipairs(part.detach_verbs) do
                        if v == "uncork" then
                            local new_obj, msg = detach_part(ctx, obj, part_key)
                            if new_obj then
                                print(msg)
                            else
                                print(msg or "You can't uncork that.")
                            end
                            return
                        end
                    end
                end
            end
        end

        -- Fall through: try FSM "open" transition with uncork alias
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            local target_trans
            for _, t in ipairs(transitions) do
                if t.verb == "uncork" then target_trans = t; break end
                if t.aliases then
                    for _, alias in ipairs(t.aliases) do
                        if alias == "uncork" then target_trans = t; break end
                    end
                    if target_trans then break end
                end
            end
            if target_trans then
                local trans = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                if trans then
                    print(trans.message or ("You uncork " .. (obj.name or obj.id) .. "."))
                else
                    print("You can't uncork " .. (obj.name or "that") .. ".")
                end
                return
            end
        end

        print("You can't uncork " .. (obj.name or "that") .. ".")
    end

    handlers["unstop"] = handlers["uncork"]
    handlers["unseal"] = handlers["uncork"]

    ---------------------------------------------------------------------------
    -- DROP
    ---------------------------------------------------------------------------
    handlers["drop"] = function(ctx, noun)
        if noun == "" then print("Drop what?") return end

        -- Only drop items directly in hands (not bag contents or worn)
        local obj = nil
        local hand_slot = nil
        local kw = noun:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local candidate = _hobj(hand, ctx.registry)
                if candidate and matches_keyword(candidate, kw) then
                    obj = candidate
                    hand_slot = i
                    break
                end
            end
        end

        if not obj then
            -- Check if it's in a bag -- give a helpful message
            local bag_item = find_in_inventory(ctx, noun)
            if bag_item then
                print("You'll need to get that out of the bag first, or drop the bag itself.")
            else
                print("You aren't holding that.")
            end
            return
        end

        -- Clear both hands if two-handed item
        ctx.player.hands[hand_slot] = nil
        if obj.hands_required and obj.hands_required >= 2 then
            for i = 1, 2 do
                if _hid(ctx.player.hands[i]) == obj.id then
                    ctx.player.hands[i] = nil
                end
            end
        end
        ctx.current_room.contents[#ctx.current_room.contents + 1] = obj.id
        obj.location = ctx.current_room.id

        -- on_drop: material fragility check
        local mat = obj.material and materials.get(obj.material)
        local floor_mat_name = ctx.current_room.floor_material or "stone"
        local floor_mat = materials.get(floor_mat_name)
        local surface_hardness = floor_mat and floor_mat.hardness or 7
        if mat and mat.fragility >= 0.5 and surface_hardness >= 5 then
            -- Object shatters on impact
            local shatter_mut = obj.mutations and obj.mutations.shatter
            if shatter_mut and shatter_mut.narration then
                print(shatter_mut.narration)
            else
                print("The " .. (obj.name or obj.id):gsub("^a%s+", ""):gsub("^an%s+", "")
                    .. " shatters on the " .. floor_mat_name .. " floor"
                    .. ", sending fragments skittering across the room.")
            end

            -- Fire FSM shatter/break transition if available
            if obj.states then
                local shatter_target = nil
                for _, t in ipairs(obj.transitions or {}) do
                    if (t.verb == "shatter" or t.verb == "break")
                       and (not t.from or t.from == obj._state) then
                        shatter_target = t.to
                        break
                    end
                end
                if shatter_target then
                    fsm_mod.transition(ctx.registry, obj.id, shatter_target, ctx, "break")
                end
            end

            -- Spawn debris from mutations.shatter.spawns
            if shatter_mut and shatter_mut.spawns then
                for _, shard_id in ipairs(shatter_mut.spawns) do
                    local shard_def = ctx.registry:get(shard_id)
                    if shard_def then
                        -- Shard already registered; place a copy in room
                        local shard_copy = {}
                        for k, v in pairs(shard_def) do shard_copy[k] = v end
                        shard_copy._instance_id = next_instance_id()
                        shard_copy.location = ctx.current_room.id
                        ctx.registry:register(shard_id .. "-" .. shard_copy._instance_id, shard_copy)
                        ctx.current_room.contents[#ctx.current_room.contents + 1] =
                            shard_id .. "-" .. shard_copy._instance_id
                    else
                        -- Attempt to load definition from disk
                        local SEP = package.config:sub(1, 1)
                        local shard_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP
                            .. "objects" .. SEP .. shard_id .. ".lua"
                        local load_ok, shard_data = pcall(dofile, shard_path)
                        if load_ok and shard_data then
                            shard_data._instance_id = next_instance_id()
                            shard_data.location = ctx.current_room.id
                            local inst_id = shard_id .. "-" .. shard_data._instance_id
                            shard_data.id = inst_id
                            ctx.registry:register(inst_id, shard_data)
                            ctx.current_room.contents[#ctx.current_room.contents + 1] = inst_id
                        end
                    end
                end
            end

            -- Remove original object from room
            for i = #ctx.current_room.contents, 1, -1 do
                if ctx.current_room.contents[i] == obj.id then
                    table.remove(ctx.current_room.contents, i)
                    break
                end
            end
            obj.location = nil
        else
            -- Object survives the drop
            if mat and mat.hardness and mat.hardness >= 5 then
                print("The " .. (obj.name or obj.id):gsub("^a%s+", ""):gsub("^an%s+", "")
                    .. " hits the floor with a resonant clang.")
            else
                print("You drop " .. (obj.name or obj.id) .. ".")
            end
        end
    end

    ---------------------------------------------------------------------------
    -- OPEN
    ---------------------------------------------------------------------------
    handlers["open"] = function(ctx, noun)
        if noun == "" then print("Open what?") return end

        -- Check room objects first
        local obj, loc_type, parent_obj = find_visible(ctx, noun)

        -- If we found a part, redirect to the parent object
        if loc_type == "part" and parent_obj then
            obj = parent_obj
        end

        if obj then
            -- FSM path: object managed by FSM engine
            if obj.states then
                local transitions = fsm_mod.get_transitions(obj)
                local target_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "open" then target_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "open" then target_trans = t; break end
                        end
                        if target_trans then break end
                    end
                end
                if target_trans then
                    local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                    if trans then
                        print(trans.message or ("You open " .. (obj.name or obj.id) .. "."))
                        if trans.spawns then spawn_objects(ctx, trans.spawns) end
                        -- Reveal exits when opening spatial objects (e.g., trap door)
                        if obj.reveals_exit then
                            local room = ctx.current_room
                            if room.exits and room.exits[obj.reveals_exit] then
                                room.exits[obj.reveals_exit].hidden = false
                                room.exits[obj.reveals_exit].open = true
                            end
                        end
                    else
                        print("You can't open " .. (obj.name or "that") .. ".")
                    end
                else
                    if obj._state and (obj._state:match("^open") or obj._state == "open_broken") then
                        print("It is already open.")
                    elseif obj._state and obj._state:match("without_drawer") then
                        print("The drawer is gone. There's nothing to open.")
                    else
                        print("You can't open " .. (obj.name or "that") .. ".")
                    end
                end
                return
            end

            local mut_data = find_mutation(obj, "open")
            if mut_data then
                if perform_mutation(ctx, obj, mut_data) then
                    local mutated = ctx.registry:get(obj.id)
                    print(mut_data.message
                        or ("You open " .. (mutated and mutated.name or obj.id) .. "."))
                end
                return
            end
        end

        -- Check exits (doors, etc.)
        local room = ctx.current_room
        for dir, exit in pairs(room.exits or {}) do
            if type(exit) == "table" and exit_matches(exit, dir, noun) then
                if not exit.mutations or not exit.mutations.open then
                    -- Already open or not openable
                    if exit.open then
                        print("It is already open.")
                    else
                        print("You can't open that.")
                    end
                    return
                end
                if exit.open then
                    print("It is already open.")
                    return
                end
                if exit.locked then
                    print("It is locked.")
                    return
                end
                local mut = exit.mutations.open
                if mut.condition and not mut.condition(exit) then
                    print("You can't open that right now.")
                    return
                end
                if mut.becomes_exit then
                    for k, v in pairs(mut.becomes_exit) do
                        exit[k] = v
                    end
                end
                print(mut.message or "You open it.")
                return
            end
        end

        if obj then
            print("You can't open " .. (obj.name or "that") .. ".")
        else
            err_not_found(ctx)
        end
    end

    handlers["pry"] = handlers["open"]  -- BUG-049: "pry crate" → open

    ---------------------------------------------------------------------------
    -- CLOSE
    ---------------------------------------------------------------------------
    handlers["close"] = function(ctx, noun)
        if noun == "" then print("Close what?") return end

        -- Check room objects first
        local obj, loc_type, parent_obj = find_visible(ctx, noun)

        -- If we found a part, redirect to the parent object
        if loc_type == "part" and parent_obj then
            obj = parent_obj
        end

        if obj then
            -- FSM path
            if obj.states then
                local transitions = fsm_mod.get_transitions(obj)
                local target_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "close" then target_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "close" then target_trans = t; break end
                        end
                        if target_trans then break end
                    end
                end
                if target_trans then
                    local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                    if trans then
                        print(trans.message or ("You close " .. (obj.name or obj.id) .. "."))
                        if trans.spawns then spawn_objects(ctx, trans.spawns) end
                    else
                        print("You can't close " .. (obj.name or "that") .. ".")
                    end
                else
                    if obj._state and (obj._state:match("^closed") or obj._state == "closed_broken") then
                        print("It is already closed.")
                    elseif obj._state and obj._state:match("without_drawer") then
                        print("The drawer is gone. There's nothing to close.")
                    else
                        print("You can't close " .. (obj.name or "that") .. ".")
                    end
                end
                return
            end

            local mut_data = find_mutation(obj, "close")
            if mut_data then
                if perform_mutation(ctx, obj, mut_data) then
                    local mutated = ctx.registry:get(obj.id)
                    print(mut_data.message
                        or ("You close " .. (mutated and mutated.name or obj.id) .. "."))
                end
                return
            end
        end

        -- Check exits
        local room = ctx.current_room
        for dir, exit in pairs(room.exits or {}) do
            if type(exit) == "table" and exit_matches(exit, dir, noun) then
                if not exit.mutations or not exit.mutations.close then
                    if exit.open == false then
                        print("It is already closed.")
                    else
                        print("You can't close that.")
                    end
                    return
                end
                if exit.open == false then
                    print("It is already closed.")
                    return
                end
                local mut = exit.mutations.close
                if mut.becomes_exit then
                    for k, v in pairs(mut.becomes_exit) do
                        exit[k] = v
                    end
                end
                print(mut.message or "You close it.")
                return
            end
        end

        if obj then
            print("You can't close " .. (obj.name or "that") .. ".")
        else
            err_not_found(ctx)
        end
    end

    handlers["shut"] = handlers["close"]

    ---------------------------------------------------------------------------
    -- UNLOCK — unlock a locked exit (door) with the correct key (BUG-030)
    ---------------------------------------------------------------------------
    handlers["unlock"] = function(ctx, noun)
        if noun == "" then print("Unlock what?") return end

        -- Parse "unlock X with Y"
        local target_word, key_word = noun:match("^(.+)%s+with%s+(.+)$")
        if not target_word then target_word = noun end

        -- Search exits for a matching locked door
        local room = ctx.current_room
        for dir, exit in pairs(room.exits or {}) do
            if type(exit) == "table" and exit_matches(exit, dir, target_word) then
                if not exit.locked then
                    if exit.open then
                        print("It is already open.")
                    else
                        print("It isn't locked.")
                    end
                    return
                end
                if not exit.key_id then
                    print((exit.name or "The lock") .. " has no visible keyhole.")
                    return
                end

                -- Find the key
                local key_obj
                if key_word then
                    key_obj = find_in_inventory(ctx, key_word)
                else
                    key_obj = find_in_inventory(ctx, "key")
                end
                if not key_obj then
                    print("You don't have a key for that.")
                    return
                end
                if key_obj.id ~= exit.key_id then
                    print("That key doesn't fit this lock.")
                    return
                end

                -- Unlock
                exit.locked = false
                local door_name = exit.name or "The door"
                local nice_name = door_name:sub(1,1):upper() .. door_name:sub(2)
                print("You insert " .. (key_obj.name or "the key")
                    .. " into the lock. *click* " .. nice_name .. " unlocks.")
                return
            end
        end

        -- Check objects (future: locked chests)
        local obj = find_visible(ctx, target_word)
        if obj then
            print("You can't unlock " .. (obj.name or "that") .. ".")
        else
            err_not_found(ctx)
        end
    end

    ---------------------------------------------------------------------------
    -- BREAK
    ---------------------------------------------------------------------------
    handlers["break"] = function(ctx, noun)
        if noun == "" then print("Break what?") return end

        -- Check objects first
        local obj = find_visible(ctx, noun)
        if obj then
            -- FSM path: check for "break" transition
            if obj.states then
                local transitions = fsm_mod.get_transitions(obj)
                local target_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "break" then target_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "break" or alias == noun:lower() then target_trans = t; break end
                        end
                        if target_trans then break end
                    end
                end
                if target_trans then
                    local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                    if trans then
                        print(trans.message or ("You break " .. (obj.name or obj.id) .. "."))
                        if trans.spawns then spawn_objects(ctx, trans.spawns) end
                    else
                        print("You can't break " .. (obj.name or "that") .. ".")
                    end
                    return
                end
            end

            -- Mutation path
            local mut_data = find_mutation(obj, "break")
            if not mut_data then
                -- Try break_mirror alias
                mut_data = find_mutation(obj, "break_mirror")
            end
            if mut_data then
                if perform_mutation(ctx, obj, mut_data) then
                    print(mut_data.message
                        or ("You break " .. (obj.name or obj.id) .. "."))
                end
                return
            end
        end

        -- Check exits
        local room = ctx.current_room
        for dir, exit in pairs(room.exits or {}) do
            if type(exit) == "table" and exit_matches(exit, dir, noun) then
                if exit.broken then
                    print("It is already broken.")
                    return
                end
                if not exit.breakable then
                    print("You can't break that.")
                    return
                end
                if not exit.mutations or not exit.mutations["break"] then
                    print("You can't break that.")
                    return
                end
                local mut = exit.mutations["break"]
                if mut.becomes_exit then
                    for k, v in pairs(mut.becomes_exit) do
                        exit[k] = v
                    end
                end
                -- Sync the room object so "look at" reflects the broken state
                for _, obj_id in ipairs(room.contents or {}) do
                    if exit_matches(exit, dir, obj_id) then
                        local robj = ctx.registry:get(obj_id)
                        if robj then
                            if mut.becomes_exit.name then robj.name = mut.becomes_exit.name end
                            if mut.becomes_exit.description then robj.description = mut.becomes_exit.description end
                            if mut.becomes_exit.keywords then robj.keywords = mut.becomes_exit.keywords end
                            if mut.becomes_exit.room_presence then robj.room_presence = mut.becomes_exit.room_presence end
                            robj.on_look = function(self) return self.description end
                        end
                        break
                    end
                end
                if mut.spawns then
                    spawn_objects(ctx, mut.spawns)
                end
                print(mut.message or "You break it.")
                return
            end
        end

        if obj then
            print("You can't break " .. (obj.name or "that") .. ".")
        else
            err_not_found(ctx)
        end
    end

    handlers["smash"] = handlers["break"]
    handlers["shatter"] = handlers["break"]

    ---------------------------------------------------------------------------
    -- TEAR
    ---------------------------------------------------------------------------
    handlers["tear"] = function(ctx, noun)
        if noun == "" then print("Tear what?") return end

        local obj = find_visible(ctx, noun)
        if not obj then
            err_not_found(ctx)
            return
        end

        local mut_data = find_mutation(obj, "tear")
        if not mut_data then
            print("You can't tear " .. (obj.name or "that") .. ".")
            return
        end

        local obj_name = obj.name or obj.id
        if perform_mutation(ctx, obj, mut_data) then
            print(mut_data.message
                or ("You tear " .. obj_name .. " apart."))
        end
    end

    handlers["rip"] = handlers["tear"]

    ---------------------------------------------------------------------------
    -- INVENTORY -- shows hands, worn items, and bag contents
    ---------------------------------------------------------------------------
    handlers["inventory"] = function(ctx, noun)
        local reg = ctx.registry

        -- Hands
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local obj = _hobj(hand, reg)
                local label = (i == 1) and "Left hand" or "Right hand"
                print("  " .. label .. ": " .. (obj and obj.name or _hid(hand)))
                -- Show bag contents
                if obj and obj.container and obj.contents and #obj.contents > 0 then
                    print("    (contains:)")
                    for _, item_id in ipairs(obj.contents) do
                        local item = reg:get(item_id)
                        print("      " .. (item and item.name or item_id))
                    end
                end
            else
                local label = (i == 1) and "Left hand" or "Right hand"
                print("  " .. label .. ": (empty)")
            end
        end

        -- Worn items (grouped by slot when wear metadata is available)
        if #(ctx.player.worn or {}) > 0 then
            print("  Worn:")
            for _, worn_id in ipairs(ctx.player.worn) do
                local obj = reg:get(worn_id)
                local label = obj and obj.name or worn_id
                if obj and obj.wear and obj.wear.slot then
                    label = label .. " (" .. obj.wear.slot .. ")"
                end
                print("    " .. label)
                if obj and obj.container and obj.contents and #obj.contents > 0 then
                    print("    (contains:)")
                    for _, item_id in ipairs(obj.contents) do
                        local item = reg:get(item_id)
                        print("      " .. (item and item.name or item_id))
                    end
                end
            end
        end

        -- Flame status
        if ctx.player.state.has_flame and ctx.player.state.has_flame > 0 then
            print("")
            print("  You hold a flickering match flame.")
        end
    end

    handlers["i"] = handlers["inventory"]

    ---------------------------------------------------------------------------
    -- LIGHT
    ---------------------------------------------------------------------------
    handlers["light"] = function(ctx, noun)
        if noun == "" then print("Light what?") return end

        -- Allow lighting things even in darkness (you can feel what you hold)
        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            print("You don't have anything like that.")
            return
        end

        -- Issue #15: Check if already lit (Prime Directive — describe world state)
        if obj._state and obj.states then
            local cur = obj.states[obj._state]
            if cur and cur.casts_light then
                local desc = cur.description or ""
                local short = desc:match("^([^.]+%.)") or desc
                if short ~= "" then
                    print(short)
                else
                    print((obj.name or "It") .. " is already alight.")
                end
                return
            end
        end

        local mut_data = find_mutation(obj, "light")
        if not mut_data then
            -- FSM path: check for "light" or "strike" transitions
            if obj.states then
                local transitions = fsm_mod.get_transitions(obj)
                local found_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "light" then found_trans = t; break end
                    if t.verb == "strike" then found_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "light" then found_trans = t; break end
                        end
                        if found_trans then break end
                    end
                end

                if found_trans then
                    -- "strike" verb → redirect to STRIKE handler (match-on-matchbox)
                    if found_trans.verb == "strike" then
                        handlers["strike"](ctx, noun)
                        return
                    end

                    -- "light" verb → direct FSM transition (candle, etc.)
                    if found_trans.requires_tool then
                        -- Check player flame first (legacy struck match)
                        if ctx.player.state.has_flame and ctx.player.state.has_flame > 0 then
                            ctx.player.state.has_flame = 0
                            local trans = fsm_mod.transition(ctx.registry, obj.id, found_trans.to, {})
                            if trans then
                                print("You touch the match flame to the wick...")
                                print(trans.message or ("You light " .. (obj.name or obj.id) .. "."))
                            end
                            return
                        end

                        -- Find fire_source tool in inventory or room
                        local tool = find_tool_in_inventory(ctx, found_trans.requires_tool)
                        if not tool then
                            tool = find_visible_tool(ctx, found_trans.requires_tool)
                        end
                        if not tool then
                            print(found_trans.fail_message or "You have nothing to light it with.")
                            return
                        end

                        local trans = fsm_mod.transition(ctx.registry, obj.id, found_trans.to, {})
                        if trans then
                            print(trans.message or ("You light " .. (obj.name or obj.id) .. "."))
                        else
                            print("You can't light " .. (obj.name or "that") .. ".")
                        end
                        return
                    end

                    -- No tool required
                    local trans = fsm_mod.transition(ctx.registry, obj.id, found_trans.to, {})
                    if trans then
                        print(trans.message or ("You light " .. (obj.name or obj.id) .. "."))
                    else
                        print("You can't light " .. (obj.name or "that") .. ".")
                    end
                    return
                end
            end
            print("You can't light " .. (obj.name or "that") .. ".")
            return
        end

        -- Tool check: does this mutation require a fire source?
        if mut_data.requires_tool then
            -- Check struck match flame first
            if ctx.player.state.has_flame and ctx.player.state.has_flame > 0 then
                print("You touch the match flame to the wick...")
                ctx.player.state.has_flame = 0  -- match consumed
                if perform_mutation(ctx, obj, mut_data) then
                    local mutated = ctx.registry:get(obj.id)
                    print(mut_data.message
                        or ("You light " .. (mutated and mutated.name or obj.id) .. ". It casts a warm glow."))
                    print("The match, spent, curls into ash between your fingers.")
                end
                return
            end

            -- Fall through to tool search
            local tool = find_tool_in_inventory(ctx, mut_data.requires_tool)
            if not tool then
                print(mut_data.fail_message or "You have nothing to light it with.")
                return
            end
            if tool.on_tool_use and tool.on_tool_use.use_message then
                print(tool.on_tool_use.use_message)
            end
            if perform_mutation(ctx, obj, mut_data) then
                consume_tool_charge(ctx, tool)
                local mutated = ctx.registry:get(obj.id)
                print(mut_data.message
                    or ("You light " .. (mutated and mutated.name or obj.id) .. ". It casts a warm glow."))
            end
            return
        end

        -- No tool required -- original behavior
        if perform_mutation(ctx, obj, mut_data) then
            local mutated = ctx.registry:get(obj.id)
            print(mut_data.message
                or ("You light " .. (mutated and mutated.name or obj.id) .. ". It casts a warm glow."))
        end
    end

    handlers["ignite"] = handlers["light"]
    handlers["relight"] = handlers["light"]

    ---------------------------------------------------------------------------
    -- EXTINGUISH
    ---------------------------------------------------------------------------
    handlers["extinguish"] = function(ctx, noun)
        if noun == "" then print("Extinguish what?") return end

        local obj = find_in_inventory(ctx, noun)
        if not obj then obj = find_visible(ctx, noun) end
        if not obj then
            err_not_found(ctx)
            return
        end

        -- FSM path
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            local target_trans
            for _, t in ipairs(transitions) do
                if t.verb == "extinguish" then target_trans = t; break end
                if t.aliases then
                    for _, alias in ipairs(t.aliases) do
                        if alias == "extinguish" then target_trans = t; break end
                    end
                    if target_trans then break end
                end
            end
            if target_trans then
                local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                if trans then
                    print(trans.message or ("You extinguish " .. (obj.name or obj.id) .. "."))
                else
                    print("You can't extinguish " .. (obj.name or "that") .. ".")
                end
            else
                -- BUG-106b: Check if object CAN be extinguished but just isn't lit
                local has_extinguish = false
                for _, t in ipairs(obj.transitions or {}) do
                    if t.verb == "extinguish" then has_extinguish = true; break end
                    if t.aliases then
                        for _, a in ipairs(t.aliases) do
                            if a == "extinguish" or a == "blow" or a == "put out" or a == "snuff" then
                                has_extinguish = true; break
                            end
                        end
                    end
                    if has_extinguish then break end
                end
                if has_extinguish then
                    local display = (obj.name or "that"):gsub("^a%s+", ""):gsub("^an%s+", "")
                    print("The " .. display .. " isn't lit.")
                else
                    print("You can't extinguish " .. (obj.name or "that") .. ".")
                end
            end
            return
        end

        local mut_data = find_mutation(obj, "extinguish")
        if not mut_data then
            print("You can't extinguish " .. (obj.name or "that") .. ".")
            return
        end

        if perform_mutation(ctx, obj, mut_data) then
            print(mut_data.message
                or ("You extinguish " .. (obj.name or obj.id) .. "."))
        end
    end

    handlers["snuff"] = handlers["extinguish"]

    ---------------------------------------------------------------------------
    -- WRITE {text} ON {target} [WITH {tool}]
    -- Dynamic mutation: generates new Lua source at runtime with the
    -- player's words baked into the object definition. This is the first
    -- true runtime code-generation in the engine.
    ---------------------------------------------------------------------------
    handlers["write"] = function(ctx, noun)
        if noun == "" then
            print("Write what? (Try: write <text> on <paper> with <pen>)")
            return
        end

        if not has_some_light(ctx) then
            print("It is too dark to see what you're writing.")
            return
        end

        -- Parse: "write {text} on {target} with {tool}"
        local text, target_word, tool_word
        text, target_word, tool_word = noun:match("^(.+)%s+on%s+(.+)%s+with%s+(.+)$")
        if not text then
            -- "write on {target} with {tool}" (no text)
            target_word, tool_word = noun:match("^on%s+(.+)%s+with%s+(.+)$")
        end
        if not target_word then
            -- "write {text} on {target}" (no tool specified)
            text, target_word = noun:match("^(.+)%s+on%s+(.+)$")
        end
        if not target_word then
            -- "write on {target}" (no text, no tool)
            target_word = noun:match("^on%s+(.+)$")
        end

        if not target_word then
            print("Write on what? (Try: write <text> on <paper>)")
            return
        end

        -- Find target -- check visible objects and inventory
        local target = find_visible(ctx, target_word)
        if not target then
            target = find_in_inventory(ctx, target_word)
        end
        if not target then
            err_not_found(ctx)
            return
        end

        if not target.writable then
            print("You can't write on " .. (target.name or "that") .. ".")
            return
        end

        if not text or text == "" then
            local prompt_text
            if context.ui and context.ui.is_enabled() then
                prompt_text = context.ui.prompt("What do you want to write? > ")
            else
                io.write("What do you want to write? > ")
                io.flush()
                prompt_text = io.read()
            end
            text = prompt_text
            if not text or text:match("^%s*$") then
                print("Never mind.")
                return
            end
            text = text:match("^%s*(.-)%s*$")
        end

        -- Find writing instrument
        local tool = nil
        if tool_word then
            tool = find_in_inventory(ctx, tool_word)
            if not tool then
                -- Check if they specified "blood"
                if tool_word:match("blood") and ctx.player.state and ctx.player.state.bloody then
                    tool = find_tool_in_inventory(ctx, "writing_instrument")
                    if tool and not tool._is_blood then tool = nil end
                end
                if not tool then
                    print("You don't have " .. tool_word .. ".")
                    return
                end
            end
            if not provides_capability(tool, "writing_instrument") and not (tool._is_blood) then
                print("You can't write with " .. (tool.name or "that") .. ".")
                return
            end
        else
            -- Auto-find writing instrument in inventory
            tool = find_tool_in_inventory(ctx, "writing_instrument")
            if not tool then
                local mut_data = find_mutation(target, "write")
                print(mut_data and mut_data.fail_message or "You have nothing to write with.")
                return
            end
        end

        -- Print tool use message
        if tool.on_tool_use and tool.on_tool_use.use_message then
            print(tool.on_tool_use.use_message)
        end

        -- Build the new written text (append if paper already has writing)
        local written = text
        if target.written_text then
            written = target.written_text .. " " .. text
        end

        -- DYNAMIC MUTATION: generate new Lua source with written text baked in.
        -- This is runtime code generation -- the paper's definition is rewritten
        -- to include the player's words as part of the object's identity.
        local esc_written = string.format("%q", written)
        local new_source = string.format(
            "return {\n"
         .. "    id = %q,\n"
         .. "    name = \"a sheet of paper with writing\",\n"
         .. "    keywords = {\"paper\", \"sheet\", \"page\", \"written paper\", \"note\", \"parchment\"},\n"
         .. "    description = \"A sheet of cream-coloured paper. Words have been written across it in careful strokes.\",\n"
         .. "    writable = true,\n"
         .. "    written_text = %s,\n"
         .. "    size = 1,\n"
         .. "    weight = 0.1,\n"
         .. "    categories = {\"small\", \"writable\", \"flammable\"},\n"
         .. "    portable = true,\n"
         .. "    location = nil,\n"
         .. "    on_look = function(self)\n"
         .. "        if self.written_text then\n"
         .. "            return \"A sheet of paper with writing on it. It reads:\\n\\n  \\\"\" .. self.written_text .. \"\\\"\"\n"
         .. "        end\n"
         .. "        return self.description\n"
         .. "    end,\n"
         .. "    mutations = {\n"
         .. "        write = {\n"
         .. "            requires_tool = \"writing_instrument\",\n"
         .. "            dynamic = true,\n"
         .. "            mutator = \"write_on_surface\",\n"
         .. "            message = \"You add more words to the paper.\",\n"
         .. "            fail_message = \"You have nothing to write with.\",\n"
         .. "        },\n"
         .. "    },\n"
         .. "}\n",
            target.id, esc_written)

        -- Perform the mutation
        local had_writing = target.written_text ~= nil
        local new_obj, err = ctx.mutation.mutate(
            ctx.registry, ctx.loader, target.id, new_source, ctx.templates)
        if not new_obj then
            print("Something goes wrong -- the ink smears illegibly.")
            return
        end

        -- Store new source for future mutations
        ctx.object_sources[target.id] = new_source

        -- Consume tool charge (if applicable)
        consume_tool_charge(ctx, tool)

        -- Success message
        if had_writing then
            print("You add more words to the paper.")
        else
            local mut_data = find_mutation(target, "write")
            print(mut_data and mut_data.message
                or "You write carefully on the paper. The words appear in steady strokes.")
        end
    end

    handlers["inscribe"] = handlers["write"]

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
    -- STAB {target} WITH {tool}  /  STAB SELF
    ---------------------------------------------------------------------------
    handlers["stab"] = function(ctx, noun)
        if handle_self_infliction(ctx, noun, "stab", "on_stab") then return end
        -- Stab is only for self-infliction — there are no world objects to stab
        print("You can only stab yourself. (Try: stab self with <weapon>)")
    end
    handlers["jab"] = handlers["stab"]
    handlers["pierce"] = handlers["stab"]
    handlers["stick"] = handlers["stab"]

    ---------------------------------------------------------------------------
    -- HIT {body area}  /  PUNCH / STRIKE / BASH / BONK / SMASH / THUMP
    -- Self-infliction for blunt trauma: head → unconsciousness, limbs → bruise
    ---------------------------------------------------------------------------
    handlers["hit"] = function(ctx, noun)
        if noun == "" then
            print("Hit what?")
            return
        end

        local is_self, body_area, tool_word = parse_self_infliction(noun)
        if not is_self then
            -- Not self — in V1, hit is self-only
            print("You can only hit yourself right now. (Try: hit head)")
            return
        end

        -- Resolve body area (default to random if "self")
        if not body_area then
            body_area = random_body_area()
        end

        -- Load injury module
        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if not inj_ok then
            print("Something goes wrong.")
            return
        end

        -- Head hit → concussion (unconsciousness)
        if body_area == "head" then
            local base_duration = 5  -- bare fist: 5 turns

            -- Check for helmet (worn head armor) — reduces duration
            local helmet = nil
            if ctx.player.worn then
                for _, worn_id in ipairs(ctx.player.worn) do
                    local obj = ctx.registry and ctx.registry.get and ctx.registry:get(worn_id)
                    if not obj then
                        obj = _hobj(worn_id, ctx.registry)
                    end
                    if obj and (obj.wear_slot == "head" or obj.is_helmet) then
                        helmet = obj
                        break
                    end
                end
            end

            local reduction = 0
            if helmet then
                reduction = helmet.reduces_unconsciousness or 0.5
            end

            local final_duration = math.max(1, math.floor(base_duration * (1 - reduction)))

            -- Suppress inflict message (we print our own narration)
            local old_print = _G.print
            _G.print = function() end
            local instance = injury_mod.inflict(ctx.player, "concussion", "self-inflicted (bare fist, hit)", "head", 5)
            _G.print = old_print

            if not instance then
                print("You hit your head, but it doesn't seem to have much effect.")
                return
            end

            -- Trigger unconsciousness
            ctx.player.consciousness = ctx.player.consciousness or {}
            ctx.player.consciousness.state = "unconscious"
            ctx.player.consciousness.wake_timer = final_duration
            ctx.player.consciousness.cause = "blow-to-head"
            ctx.player.consciousness.unconscious_since = ctx.time_offset or 0

            if helmet then
                if final_duration <= 1 then
                    print("You punch your helmeted head. It clangs metallically. Your ears ring, but the helmet took most of the impact.")
                else
                    print("You slam your fist against your helmeted head. The impact rattles you even through the protection. Stars flash across your vision...")
                end
            else
                print("You slam your fist hard against the side of your head. Stars explode across your vision. The world tilts and fades...")
            end
            return
        end

        -- Non-head hit → bruise
        local old_print = _G.print
        _G.print = function() end
        local instance = injury_mod.inflict(ctx.player, "bruised", "self-inflicted (bare fist, hit)", body_area, 4)
        _G.print = old_print

        if not instance then
            print("You punch yourself, but it doesn't seem to have much effect.")
            return
        end

        -- Narration by body area
        local narrations = {
            ["left arm"]   = "You punch yourself in the left arm. Sharp pain blooms across the muscle.",
            ["right arm"]  = "You punch yourself in the right arm. Sharp pain blooms across the muscle.",
            ["left hand"]  = "You drive your fist into your left hand. The knuckles ache.",
            ["right hand"] = "You drive your fist into your right hand. The knuckles ache.",
            ["left leg"]   = "You drive your fist down against your left leg. Intense pain shoots through the limb.",
            ["right leg"]  = "You drive your fist down against your right leg. Intense pain shoots through the limb.",
            ["torso"]      = "You drive your fist into your ribs. Air explodes from your lungs.",
            ["stomach"]    = "You punch yourself in the stomach. You double over, gasping.",
        }
        print(narrations[body_area] or ("You punch your " .. body_area .. ". That hurt."))
    end
    handlers["punch"]  = handlers["hit"]
    handlers["bash"]   = handlers["hit"]
    handlers["bonk"]   = handlers["hit"]
    handlers["thump"]  = handlers["hit"]

    ---------------------------------------------------------------------------
    -- CUT {target} WITH {tool}  /  CUT SELF WITH {tool}
    ---------------------------------------------------------------------------
    handlers["cut"] = function(ctx, noun)
        if noun == "" then
            print("Cut what? (Try: cut <thing> with <tool>)")
            return
        end

        -- Try self-infliction first
        if handle_self_infliction(ctx, noun, "cut", "on_cut") then return end

        -- CUT {object} — world object cutting (existing logic)
        local target_word, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
        if not target_word then target_word = noun end

        if not has_some_light(ctx) then
            print("It is too dark to see what you're doing.")
            return
        end

        local obj = find_visible(ctx, target_word)
        if not obj then
            err_not_found(ctx)
            return
        end

        local mut_data = find_mutation(obj, "cut")
        if mut_data then
            if mut_data.requires_tool then
                local tool = nil
                if tool_word then
                    tool = find_in_inventory(ctx, tool_word)
                    if not tool then
                        print("You don't have " .. tool_word .. ".")
                        return
                    end
                    if not provides_capability(tool, mut_data.requires_tool) then
                        print(mut_data.fail_message or "That tool won't work for cutting this.")
                        return
                    end
                else
                    tool = find_tool_in_inventory(ctx, mut_data.requires_tool)
                    if not tool then
                        print(mut_data.fail_message or "You have nothing to cut with.")
                        return
                    end
                end
            end
            if perform_mutation(ctx, obj, mut_data) then
                print(mut_data.message or "You cut " .. (obj.name or "that") .. ".")
            end
            return
        end

        print("You can't cut " .. (obj.name or "that") .. ".")
    end
    handlers["slice"] = handlers["cut"]
    handlers["nick"] = handlers["cut"]

    ---------------------------------------------------------------------------
    -- SLASH {target} WITH {tool}  /  SLASH SELF WITH {tool}
    ---------------------------------------------------------------------------
    handlers["slash"] = function(ctx, noun)
        if noun == "" then
            print("Slash what?")
            return
        end

        -- Try self-infliction first
        if handle_self_infliction(ctx, noun, "slash", "on_slash") then return end

        -- Fall through to cut logic for world objects
        handlers["cut"](ctx, noun)
    end
    handlers["carve"] = handlers["slash"]

    ---------------------------------------------------------------------------
    -- PRICK SELF WITH {tool}
    ---------------------------------------------------------------------------
    handlers["prick"] = function(ctx, noun)
        if noun == "" then
            print("Prick what? (Try: prick self with <pin>)")
            return
        end

        local target_word, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
        if not target_word then target_word = noun end

        -- PRICK SELF -- minor self-injury with any sharp point
        if target_word == "self" or target_word == "myself"
           or target_word == "me" or target_word == "finger"
           or target_word == "thumb" then

            local tool = nil
            if tool_word then
                tool = find_in_inventory(ctx, tool_word)
                if not tool then
                    print("You don't have " .. tool_word .. ".")
                    return
                end
                if not provides_capability(tool, "injury_source") then
                    print("You can't prick yourself with " .. (tool.name or "that") .. ".")
                    return
                end
            else
                tool = find_tool_in_inventory(ctx, "injury_source")
                if not tool then
                    print("You have nothing sharp enough to prick yourself with.")
                    return
                end
            end

            ctx.player.state = ctx.player.state or {}
            ctx.player.state.bloody = true
            ctx.player.state.bleed_ticks = 8
            print("You prick your finger with " .. (tool.name or "the sharp point") .. ". A bead of blood forms.")
            print("Your hands are now bloody.")
            return
        end

        print("You can only prick yourself. (Try: prick self with <pin>)")
    end

    ---------------------------------------------------------------------------
    -- SEW {material} WITH {tool} -- crafting verb (requires sewing skill)
    ---------------------------------------------------------------------------
    handlers["sew"] = function(ctx, noun)
        if noun == "" then
            print("Sew what? (Try: sew cloth with needle)")
            return
        end

        if not has_some_light(ctx) then
            print("It is too dark to sew anything. You'd stab yourself.")
            return
        end

        -- Skill gate: must know sewing
        if not ctx.player.skills or not ctx.player.skills.sewing then
            print("You don't know how to sew. Perhaps you could find instructions somewhere.")
            return
        end

        -- Parse: "sew X with Y" or just "sew X"
        local material_word, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
        if not material_word then material_word = noun end

        -- Strip articles
        material_word = material_word:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        if tool_word then
            tool_word = tool_word:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        end

        -- Find the material (must be visible or in inventory)
        local material = find_in_inventory(ctx, material_word)
        if not material then
            material = find_visible(ctx, material_word)
        end
        if not material then
            print("You don't see any " .. material_word .. " to sew.")
            return
        end

        -- Check if material has crafting.sew recipe
        if not material.crafting or not material.crafting.sew then
            print("You can't sew " .. (material.name or "that") .. ".")
            return
        end

        local recipe = material.crafting.sew

        -- Find the sewing tool (needle)
        local tool = nil
        if tool_word then
            tool = find_in_inventory(ctx, tool_word)
            if not tool then
                print("You don't have " .. tool_word .. ".")
                return
            end
            if not provides_capability(tool, recipe.requires_tool or "sewing_tool") then
                print("You can't sew with " .. (tool.name or "that") .. ".")
                return
            end
        else
            tool = find_tool_in_inventory(ctx, recipe.requires_tool or "sewing_tool")
            if not tool then
                print(recipe.fail_message_no_tool or "You have nothing to sew with.")
                return
            end
        end

        -- Check for sewing material (thread)
        local thread = find_tool_in_inventory(ctx, "sewing_material")
        if not thread then
            print("You need thread to sew with.")
            return
        end

        -- Check we have enough materials (recipe.consumes lists required material IDs)
        local consumes = recipe.consumes or {material.id}
        local consumed_objs = {}
        local available = {}

        -- Build list of all reachable objects matching consumed IDs
        for _, need_id in ipairs(consumes) do
            local found = false
            -- Search inventory
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local obj = _hobj(hand, ctx.registry)
                    if obj and obj.id:match("^" .. need_id) and not available[hand_id] then
                        available[hand_id] = obj
                        consumed_objs[#consumed_objs + 1] = obj
                        found = true
                        break
                    end
                    -- Check bag contents
                    if not found and obj and obj.container and obj.contents then
                        for _, item_id in ipairs(obj.contents) do
                            local item = ctx.registry:get(item_id)
                            if item and item.id:match("^" .. need_id) and not available[item_id] then
                                available[item_id] = item
                                consumed_objs[#consumed_objs + 1] = item
                                found = true
                                break
                            end
                        end
                    end
                end
                if found then break end
            end
            -- Search room if not found in inventory
            if not found then
                for _, obj_id in ipairs(ctx.current_room.contents or {}) do
                    local obj = ctx.registry:get(obj_id)
                    if obj and obj.id:match("^" .. need_id) and not available[obj_id] then
                        available[obj_id] = obj
                        consumed_objs[#consumed_objs + 1] = obj
                        found = true
                        break
                    end
                end
            end
            if not found then
                print("You don't have enough " .. need_id .. " to sew with.")
                return
            end
        end

        -- Print tool use message
        if tool.on_tool_use and tool.on_tool_use.use_message then
            print(tool.on_tool_use.use_message)
        end

        -- Consume materials
        for _, obj in ipairs(consumed_objs) do
            remove_from_location(ctx, obj)
            ctx.registry:remove(obj.id)
        end

        -- Spawn the product
        local product_id = recipe.becomes
        if product_id then
            spawn_objects(ctx, {product_id})
        end

        -- Consume tool charge if applicable
        consume_tool_charge(ctx, tool)

        -- Success message
        print(recipe.message or ("You sew the materials together."))
    end

    handlers["stitch"] = handlers["sew"]
    handlers["mend"] = handlers["sew"]

    ---------------------------------------------------------------------------
    -- PUT X IN/ON Y -- supports furniture surfaces AND held/worn bags
    ---------------------------------------------------------------------------
    handlers["put"] = function(ctx, noun)
        if noun == "" then
            print("Put what where? (Try: put <item> in/on <target>)")
            return
        end

        -- "put on X" → wear X (intercepted before container logic)
        local wear_target = noun:match("^on%s+(.+)")
        if wear_target then
            -- Check if it's actually "put X on Y" by seeing if there's an "on" in the middle
            -- "put on cloak" vs "put sword on table" — if noun starts with "on ", it's wear
            handlers["wear"](ctx, wear_target)
            return
        end

        -- #82: Parse "X in/on/under/underneath/beneath/inside Y"
        local item_word, prep, target_word
        item_word, target_word = noun:match("^(.+)%s+in%s+(.+)$")
        if item_word then
            prep = "in"
        else
            item_word, target_word = noun:match("^(.+)%s+on%s+(.+)$")
            if item_word then
                prep = "on"
            end
        end
        if not item_word then
            item_word, target_word = noun:match("^(.+)%s+underneath%s+(.+)$")
            if item_word then
                prep = "under"
            end
        end
        if not item_word then
            item_word, target_word = noun:match("^(.+)%s+beneath%s+(.+)$")
            if item_word then
                prep = "under"
            end
        end
        if not item_word then
            item_word, target_word = noun:match("^(.+)%s+under%s+(.+)$")
            if item_word then
                prep = "under"
            end
        end
        if not item_word then
            item_word, target_word = noun:match("^(.+)%s+inside%s+(.+)$")
            if item_word then
                prep = "in"
            end
        end

        if not item_word or not target_word then
            print("Put what where? (Try: put <item> in/on <target>)")
            return
        end

        -- "put X on {body_part}" → route to wear handler
        if prep == "on" then
            local body_parts = {
                head = true, back = true, hands = true, feet = true,
                torso = true, body = true, arms = true, legs = true,
                wrist = true, finger = true, neck = true, waist = true,
                face = true, shoulders = true, chest = true,
            }
            local tw = target_word:lower():gsub("^my%s+", "")
            if body_parts[tw] then
                handlers["wear"](ctx, item_word .. " on " .. tw)
                return
            end
        end

        -- #81: Resolve pronouns ("it", "that", etc.) via context window
        local resolved_item_word = item_word
        if context_window then
            local item_kw = item_word:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            local cw_item = context_window.resolve(item_kw)
            if cw_item then
                resolved_item_word = cw_item.id
            end
        end

        -- Find item -- must be in hands
        local item = nil
        local item_hand = nil
        local kw = resolved_item_word:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local candidate = _hobj(hand, ctx.registry)
                if candidate and matches_keyword(candidate, kw) then
                    item = candidate
                    item_hand = i
                    break
                end
            end
        end

        if not item then
            local found = find_visible(ctx, item_word)
            if found then
                print("You need to be holding that to put it somewhere.")
                return
            end
            print("You don't have " .. item_word .. ".")
            return
        end

        -- Find target -- could be a held bag, worn bag, or room object
        local target = find_visible(ctx, target_word)
        if not target then
            print("You don't see " .. target_word .. " here.")
            return
        end

        -- Reattachment check: if item has reattach_to and target matches
        if item.reattach_to and target.parts and item.reattach_to == target.id then
            local ok, msg = reattach_part(ctx, item, target)
            if ok then
                -- Clear hand slots (handle two-handed items)
                for i = 1, 2 do
                    if _hid(ctx.player.hands[i]) == item.id then
                        ctx.player.hands[i] = nil
                    end
                end
                print(msg)
            else
                print(msg or "You can't put that back.")
            end
            return
        end

        -- If target is a held/worn bag (simple container, no surfaces)
        if target.container and not target.surfaces then
            local ok, reason = ctx.containment.can_contain(
                item, target, nil, ctx.registry)
            if not ok then
                print(reason or "You can't put that there.")
                return
            end
            ctx.player.hands[item_hand] = nil
            target.contents = target.contents or {}
            target.contents[#target.contents + 1] = item.id
            item.location = target.id
            print("You put " .. (item.name or item.id) ..
                " " .. prep .. " " .. (target.name or target.id) .. ".")
            return
        end

        -- Determine surface name (furniture)
        local surface_name = nil
        if target.surfaces then
            if prep == "on" and target.surfaces.top then
                surface_name = "top"
            elseif prep == "in" and target.surfaces.inside then
                surface_name = "inside"
            elseif prep == "under" and target.surfaces.underneath then
                surface_name = "underneath"
            elseif prep == "on" then
                for sname, _ in pairs(target.surfaces) do
                    surface_name = sname
                    break
                end
            elseif prep == "in" then
                -- #80: no inside surface -> reject (solid furniture has no inside)
                print("You can't put anything inside " .. (target.name or target.id) .. ".")
                return
            elseif prep == "under" then
                for sname, _ in pairs(target.surfaces) do
                    surface_name = sname
                    break
                end
            end
        end

        -- For "under" without surfaces, use target.underneath as a flat container
        if prep == "under" and not surface_name and not target.surfaces then
            target.underneath = target.underneath or {}
            ctx.player.hands[item_hand] = nil
            if item.hands_required and item.hands_required >= 2 then
                for i = 1, 2 do
                    if _hid(ctx.player.hands[i]) == item.id then
                        ctx.player.hands[i] = nil
                    end
                end
            end
            target.underneath[#target.underneath + 1] = item.id
            item.location = target.id
            print("You put " .. (item.name or item.id) ..
                " " .. prep .. " " .. (target.name or target.id) .. ".")
            return
        end

        -- Validate with containment engine
        local ok, reason = ctx.containment.can_contain(
            item, target, surface_name, ctx.registry)
        if not ok then
            print(reason or "You can't put that there.")
            return
        end

        -- Move
        ctx.player.hands[item_hand] = nil
        -- Clear both hands for two-handed items
        if item.hands_required and item.hands_required >= 2 then
            for i = 1, 2 do
                if _hid(ctx.player.hands[i]) == item.id then
                    ctx.player.hands[i] = nil
                end
            end
        end

        if surface_name and target.surfaces and target.surfaces[surface_name] then
            local zone = target.surfaces[surface_name]
            zone.contents = zone.contents or {}
            zone.contents[#zone.contents + 1] = item.id
        elseif target.contents then
            target.contents[#target.contents + 1] = item.id
        else
            target.contents = { item.id }
        end

        item.location = target.id

        print("You put " .. (item.name or item.id) ..
            " " .. prep .. " " .. (target.name or target.id) .. ".")
    end

    handlers["place"] = handlers["put"]

    ---------------------------------------------------------------------------
    -- STRIKE {A} ON {B} -- compound tool verb for fire-making
    -- Also handles "strike head", "strike arm" as hit synonyms.
    -- FSM path: A is a match with inline states, B is something with has_striker.
    -- Legacy path: matchbox with fire_source charges.
    ---------------------------------------------------------------------------
    handlers["strike"] = function(ctx, noun)
        if noun == "" then
            print("Strike what? (Try: strike match on matchbox)")
            return
        end

        -- Try body area self-hit first (e.g., "strike arm", "strike head")
        local is_self, body_area = parse_self_infliction(noun)
        if is_self and body_area then
            handlers["hit"](ctx, noun)
            return
        end

        -- Parse "strike A on B"
        local a_word, b_word = noun:match("^(.+)%s+on%s+(.+)$")
        if not a_word then a_word = noun end

        -- Find the object to strike (A) -- check carried then visible
        local match_obj = find_in_inventory(ctx, a_word)
        if not match_obj then
            match_obj = find_visible(ctx, a_word)
        end

        -- FSM path: A is an FSM object with a "strike" transition
        if match_obj and match_obj.states then
            local transitions = fsm_mod.get_transitions(match_obj)
            local strike_trans
            for _, t in ipairs(transitions) do
                if t.verb == "strike" then strike_trans = t; break end
            end

            if not strike_trans then
                if match_obj._state == "spent" then
                    print("The match is spent. It cannot be relit.")
                elseif match_obj._state == "lit" then
                    print("The match is already lit.")
                else
                    print("You can't strike " .. (match_obj.name or "that") .. ".")
                end
                return
            end

            -- Find the striker surface (B)
            local striker
            if b_word then
                striker = find_in_inventory(ctx, b_word)
                if not striker then striker = find_visible(ctx, b_word) end
            else
                -- Auto-find: search carried then visible for has_striker
                for _, id in ipairs(get_all_carried_ids(ctx)) do
                    local o = ctx.registry:get(id)
                    if o and o.has_striker then striker = o; break end
                end
                if not striker then
                    local room = ctx.current_room
                    for _, obj_id in ipairs(room.contents or {}) do
                        local o = ctx.registry:get(obj_id)
                        if o and o.has_striker then striker = o; break end
                        if o and o.surfaces then
                            for _, zone in pairs(o.surfaces) do
                                if zone.accessible ~= false then
                                    for _, item_id in ipairs(zone.contents or {}) do
                                        local item = ctx.registry:get(item_id)
                                        if item and item.has_striker then striker = item; break end
                                    end
                                end
                                if striker then break end
                            end
                        end
                        if striker then break end
                    end
                end
            end

            if not striker then
                print(strike_trans.fail_message or "You need a rough surface to strike it on. A matchbox striker, perhaps.")
                return
            end

            local trans, err = fsm_mod.transition(
                ctx.registry, match_obj.id, strike_trans.to, { target = striker })
            if trans then
                print(trans.message)
            elseif err == "requires_property" then
                print("You can't strike a match on " .. (striker.name or "that") .. ".")
            elseif err == "terminal" then
                print("The match is spent. It cannot be relit.")
            else
                print("You can't strike " .. (match_obj.name or "that") .. ".")
            end
            return
        end

        -- Legacy path: matchbox with fire_source charges
        local matchbox = nil
        if b_word then
            matchbox = find_in_inventory(ctx, b_word)
            if not matchbox then
                matchbox = find_visible(ctx, b_word)
            end
        else
            matchbox = find_in_inventory(ctx, a_word)
            if not matchbox or not provides_capability(matchbox, "fire_source") then
                matchbox = find_visible(ctx, a_word)
                if not matchbox or not provides_capability(matchbox, "fire_source") then
                    matchbox = find_tool_in_inventory(ctx, "fire_source")
                    if not matchbox then
                        matchbox = find_visible_tool(ctx, "fire_source")
                    end
                end
            end
        end

        if not matchbox then
            print("You don't see anything to strike against.")
            return
        end

        if not provides_capability(matchbox, "fire_source") then
            print("You can't strike a match on " .. (matchbox.name or "that") .. ".")
            return
        end

        if matchbox.charges and matchbox.charges <= 0 then
            print((matchbox.name or "The matchbox") .. " is empty. No matches remain.")
            return
        end

        if matchbox.on_tool_use and matchbox.on_tool_use.use_message then
            print(matchbox.on_tool_use.use_message)
        else
            print("You strike a match. It flares to life with a hiss of sulphur.")
        end

        consume_tool_charge(ctx, matchbox)
        ctx.player.state.has_flame = 3
        print("You hold the small flame carefully. It won't last long.")
    end

    ---------------------------------------------------------------------------
    -- WEAR / PUT ON / DON -- equip an item from hand to worn slot
    -- Checks object wear metadata for slot/layer conflicts.
    ---------------------------------------------------------------------------
    handlers["wear"] = function(ctx, noun)
        if noun == "" then
            print("Wear what?")
            return
        end

        -- Strip leading "on " for "put on X" passthrough
        local target = noun:lower():match("^on%s+(.+)") or noun

        -- Parse "wear X on Y" for slot selection (e.g., "wear sack on head")
        local slot_override = nil
        local item_kw, slot_spec = target:match("^(.+)%s+on%s+(%S+)$")
        if item_kw then
            slot_override = slot_spec:lower()
            target = item_kw
        end

        -- Find item in hands
        local obj = nil
        local hand_slot = nil
        local kw = target:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local candidate = _hobj(hand, ctx.registry)
                if candidate and matches_keyword(candidate, kw) then
                    obj = candidate
                    hand_slot = i
                    break
                end
            end
        end

        if not obj then
            -- #69/#70: Auto-pickup from room (Infocom pattern) — "wear it" after
            -- examining an item should pick it up and put it on in one action.
            local room_obj, fv_loc, fv_parent, fv_surface = find_visible(ctx, kw)
            if room_obj and (room_obj.wear or room_obj.wearable) then
                local slot = first_empty_hand(ctx)
                if not slot then
                    print("Your hands are full. Drop something first.")
                    return
                end
                local room = ctx.current_room
                local reg = ctx.registry
                -- Remove from wherever find_visible found it
                if fv_loc == "room" then
                    for i, id in ipairs(room.contents or {}) do
                        if id == room_obj.id then
                            table.remove(room.contents, i)
                            break
                        end
                    end
                elseif fv_loc == "surface" and fv_parent and fv_surface then
                    local zone = fv_parent.surfaces and fv_parent.surfaces[fv_surface]
                    if zone and zone.contents then
                        for i, id in ipairs(zone.contents) do
                            if id == room_obj.id then
                                table.remove(zone.contents, i)
                                break
                            end
                        end
                    end
                elseif fv_loc == "container" and fv_parent then
                    for i, id in ipairs(fv_parent.contents or {}) do
                        if id == room_obj.id then
                            table.remove(fv_parent.contents, i)
                            break
                        end
                    end
                else
                    -- Fallback: try removing from room and all surfaces
                    for i, id in ipairs(room.contents or {}) do
                        if id == room_obj.id then
                            table.remove(room.contents, i)
                            break
                        end
                    end
                    for _, room_id in ipairs(room.contents or {}) do
                        local furniture = reg:get(room_id)
                        if furniture and furniture.surfaces then
                            for sname, zone in pairs(furniture.surfaces) do
                                for i, id in ipairs(zone.contents or {}) do
                                    if id == room_obj.id then
                                        table.remove(zone.contents, i)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                room_obj.location = "player"
                if not room_obj.instance_id then room_obj.instance_id = next_instance_id() end
                ctx.player.hands[slot] = room_obj
                obj = room_obj
                hand_slot = slot
                print("You pick up " .. (obj.name or obj.id) .. ".")
            end
        end

        -- #86: Check inside containers in the room (open wardrobe, open drawer, etc.)
        if not obj then
            local room = ctx.current_room
            local reg = ctx.registry
            local found_obj, found_parent, found_surface, is_accessible
            for _, obj_id in ipairs(room.contents or {}) do
                local room_item = reg:get(obj_id)
                if room_item then
                    -- Check surface contents (e.g., wardrobe "inside")
                    if room_item.surfaces then
                        for sname, zone in pairs(room_item.surfaces) do
                            for _, item_id in ipairs(zone.contents or {}) do
                                local item = reg:get(item_id)
                                if item and matches_keyword(item, kw) and (item.wear or item.wearable) then
                                    found_obj = item
                                    found_parent = room_item
                                    found_surface = sname
                                    -- Determine accessibility from FSM state
                                    local state_zone = zone
                                    if room_item._state and room_item.states and room_item.states[room_item._state] then
                                        local st = room_item.states[room_item._state]
                                        if st.surfaces and st.surfaces[sname] then
                                            state_zone = st.surfaces[sname]
                                        end
                                    end
                                    is_accessible = state_zone.accessible ~= false
                                    break
                                end
                            end
                            if found_obj then break end
                        end
                    end
                    -- Check root container contents
                    if not found_obj and room_item.contents then
                        for _, item_id in ipairs(room_item.contents) do
                            local item = reg:get(item_id)
                            if item and matches_keyword(item, kw) and (item.wear or item.wearable) then
                                found_obj = item
                                found_parent = room_item
                                found_surface = nil
                                is_accessible = true
                                break
                            end
                        end
                    end
                end
                if found_obj then break end
            end
            if found_obj and is_accessible then
                local slot = first_empty_hand(ctx)
                if not slot then
                    print("Your hands are full. Drop something first.")
                    return
                end
                -- Remove from container
                if found_surface then
                    local zone = found_parent.surfaces[found_surface]
                    if zone and zone.contents then
                        for i, id in ipairs(zone.contents) do
                            if id == found_obj.id then
                                table.remove(zone.contents, i)
                                break
                            end
                        end
                    end
                else
                    for i, id in ipairs(found_parent.contents or {}) do
                        if id == found_obj.id then
                            table.remove(found_parent.contents, i)
                            break
                        end
                    end
                end
                found_obj.location = "player"
                if not found_obj.instance_id then found_obj.instance_id = next_instance_id() end
                ctx.player.hands[slot] = found_obj
                obj = found_obj
                hand_slot = slot
                print("You take " .. (obj.name or obj.id) .. " from " .. (found_parent.name or found_parent.id) .. ".")
            elseif found_obj and not is_accessible then
                local item_name = (found_obj.name or kw):gsub("^a%s+", ""):gsub("^an%s+", ""):gsub("^the%s+", "")
                print("You need to take the " .. item_name .. " first.")
                return
            end
        end

        if not obj then
            print("You aren't holding that.")
            return
        end

        -- Check wearability: object must have a wear table or legacy wearable flag
        local wear = obj.wear
        if not wear and not obj.wearable then
            print("You can't wear " .. (obj.name or "that") .. ".")
            return
        end

        -- Legacy support: objects with wearable=true but no wear table
        -- get a minimal default (torso/outer) so they still work
        if not wear then
            wear = { slot = "torso", layer = "outer" }
        end

        -- Apply alternate slot if requested and available
        if slot_override and obj.wear_alternate and obj.wear_alternate[slot_override] then
            local alt = obj.wear_alternate[slot_override]
            wear = {}
            for k, v in pairs(obj.wear) do wear[k] = v end
            for k, v in pairs(alt) do wear[k] = v end
        elseif slot_override and not (obj.wear_alternate and obj.wear_alternate[slot_override]) then
            print("You can't wear " .. (obj.name or "that") .. " on your " .. slot_override .. ".")
            return
        end

        local slot = wear.slot or "torso"
        local layer = wear.layer or "outer"
        local max_per_slot = wear.max_per_slot or 1

        -- Slot/layer conflict check against currently worn items
        local reg = ctx.registry
        for _, worn_id in ipairs(ctx.player.worn or {}) do
            local worn_obj = reg:get(worn_id)
            if worn_obj then
                local worn_wear = worn_obj.wear or {}
                local worn_slot = worn_wear.slot or "torso"
                local worn_layer = worn_wear.layer or "outer"

                if worn_slot == slot then
                    if layer == "accessory" and worn_layer == "accessory" then
                        -- Count accessories already on this slot
                        local count = 0
                        for _, wid in ipairs(ctx.player.worn) do
                            local w = reg:get(wid)
                            if w and w.wear and w.wear.slot == slot
                               and w.wear.layer == "accessory" then
                                count = count + 1
                            end
                        end
                        if count >= max_per_slot then
                            print("You're already wearing too many things on your " .. slot .. ".")
                            return
                        end
                        break -- accessories don't conflict further
                    elseif layer == "accessory" or worn_layer == "accessory" then
                        -- Accessories don't conflict with inner/outer layers
                    elseif worn_layer == layer then
                        -- Same layer on same slot = conflict
                        print("You're already wearing " .. (worn_obj.name or worn_id) .. ". Remove it first.")
                        return
                    end
                    -- Different layers on same slot (inner vs outer) = OK
                end
            end
        end

        -- Equip: move from hand to worn list
        ctx.player.hands[hand_slot] = nil
        ctx.player.worn = ctx.player.worn or {}
        ctx.player.worn[#ctx.player.worn + 1] = obj.id
        obj.location = "player"

        -- Store the active wear config on the object (for slot overrides)
        -- Save original wear for restoration on remove
        if not obj._base_wear then
            obj._base_wear = obj.wear
        end
        obj.wear = wear

        -- Flavor messages based on wear metadata
        if wear.blocks_vision then
            print("You pull " .. (obj.name or obj.id) .. " over your head. Everything goes dark.")
        elseif slot == "back" then
            if obj.container then
                print("You sling " .. (obj.name or obj.id) .. " over your shoulder. It makes a serviceable, if ugly, backpack.")
            else
                print("You put " .. (obj.name or obj.id) .. " on your back.")
            end
        elseif wear.provides_armor and wear.provides_armor > 0 then
            if wear.wear_quality == "makeshift" then
                print("You place " .. (obj.name or obj.id) .. " on your " .. slot .. ". It makes a ridiculous helmet, but you feel... slightly tougher?")
            else
                print("You put on " .. (obj.name or obj.id) .. ". You feel better protected.")
            end
        elseif wear.provides_warmth then
            print("You put on " .. (obj.name or obj.id) .. ". Its warmth immediately envelops you.")
        else
            print("You put on " .. (obj.name or obj.id) .. ".")
        end
    end

    handlers["don"] = handlers["wear"]

    ---------------------------------------------------------------------------
    -- REMOVE / TAKE OFF / DOFF -- worn items, detachable parts, OR bandages
    ---------------------------------------------------------------------------
    handlers["remove"] = function(ctx, noun)
        if noun == "" then
            print("Remove what?")
            return
        end

        -- Strip leading "off " for "take off X" passthrough
        local target = noun:lower():match("^off%s+(.+)") or noun

        -- Strip "from ..." suffix for "remove bandage from left arm"
        local base_target = target:match("^(.-)%s+from%s+") or target

        -- Check for bandage removal (treatment objects with applied_to)
        local kw_check = base_target:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        local bandage_obj = find_in_inventory(ctx, kw_check)
        if bandage_obj and bandage_obj.applied_to then
            local inj_ok, injury_mod = pcall(require, "engine.injuries")
            if inj_ok then
                local ok, err = injury_mod.remove_treatment(ctx.player, bandage_obj)
                if ok then
                    -- Print the remove transition message from bandage FSM
                    local msg = nil
                    if bandage_obj.transitions then
                        for _, t in ipairs(bandage_obj.transitions) do
                            if t.verb == "remove" and t.to == "soiled" then
                                msg = t.message
                                break
                            end
                        end
                    end
                    if not msg then
                        msg = "You remove " .. (bandage_obj.name or "the bandage") .. "."
                    end
                    print(msg)
                else
                    print(err or "You can't remove that.")
                end
                return
            end
        end

        -- First: check if this matches a detachable part (remove cork, remove drawer)
        local part, parent_obj, part_key = find_part(ctx, target)
        if part and part.detachable then
            local valid_verb = false
            if part.detach_verbs then
                for _, v in ipairs(part.detach_verbs) do
                    if v == "remove" then valid_verb = true; break end
                end
            else
                valid_verb = true
            end
            if valid_verb then
                local new_obj, msg = detach_part(ctx, parent_obj, part_key)
                if new_obj then
                    print(msg)
                else
                    print(msg or "You can't remove that.")
                end
                return
            end
        end

        -- Then: check worn items
        local kw = target:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        local obj = nil
        local worn_idx = nil
        for i, worn_id in ipairs(ctx.player.worn or {}) do
            local candidate = ctx.registry:get(worn_id)
            if candidate and matches_keyword(candidate, kw) then
                obj = candidate
                worn_idx = i
                break
            end
        end

        if not obj then
            -- Check if the player is holding it (not worn)
            local held = find_in_inventory(ctx, target)
            if held then
                print("You're not wearing " .. (held.name or "that") .. ".")
            else
                print("You don't see anything to remove.")
            end
            return
        end

        local slot = first_empty_hand(ctx)
        if not slot then
            print("Your hands are full. Drop something first.")
            return
        end

        local had_vision_block = obj.wear and obj.wear.blocks_vision

        table.remove(ctx.player.worn, worn_idx)
        if not obj.instance_id then obj.instance_id = next_instance_id() end
        ctx.player.hands[slot] = obj

        -- Restore original wear config if it was overridden by slot selection
        if obj._base_wear then
            obj.wear = obj._base_wear
            obj._base_wear = nil
        end

        if had_vision_block then
            print("You pull " .. (obj.name or obj.id) .. " off your head. Light floods back in.")
        else
            print("You remove " .. (obj.name or obj.id) .. ".")
        end
    end

    handlers["doff"] = handlers["remove"]

    ---------------------------------------------------------------------------
    -- EAT -- stub for consumables
    ---------------------------------------------------------------------------
    handlers["eat"] = function(ctx, noun)
        if noun == "" then
            print("Eat what?")
            return
        end

        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            err_not_found(ctx)
            return
        end

        if obj.edible then
            print("You eat " .. (obj.name or "it") .. ".")
            if obj.on_eat_message then
                print(obj.on_eat_message)
            end
            remove_from_location(ctx, obj)
            ctx.registry:remove(obj.id)
        else
            print("You can't eat " .. (obj.name or "that") .. ".")
        end
    end

    handlers["consume"] = handlers["eat"]
    handlers["devour"] = handlers["eat"]

    ---------------------------------------------------------------------------
    -- DRINK -- consume a liquid (FSM or generic)
    ---------------------------------------------------------------------------
    handlers["drink"] = function(ctx, noun)
        if noun == "" then print("Drink what?") return end

        -- Strip "from" preposition: "drink from bottle" → "bottle"
        local target = noun:match("^from%s+(.+)") or noun

        local obj = find_in_inventory(ctx, target)
        if not obj then
            local visible = find_visible(ctx, target)
            if visible then
                print("You'll need to pick that up first.")
            else
                err_not_found(ctx)
            end
            return
        end

        -- FSM path: check for "drink" transition
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            local target_trans
            for _, t in ipairs(transitions) do
                if t.verb == "drink" then target_trans = t; break end
                if t.aliases then
                    for _, alias in ipairs(t.aliases) do
                        if alias == "drink" then target_trans = t; break end
                    end
                    if target_trans then break end
                end
            end
            if target_trans then
                local trans = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {}, "drink")
                if trans then
                    print(trans.message or ("You drink from " .. (obj.name or obj.id) .. "."))
                    if trans.effect then
                        effects.process(trans.effect, {
                            player = ctx.player,
                            registry = ctx.registry,
                            source = obj,
                            source_id = obj.id,
                            game_over = false,
                        })
                        -- Propagate game_over back to the main context
                        local eff_ctx = { player = ctx.player }
                        local inj_ok, injury_mod = pcall(require, "engine.injuries")
                        if inj_ok then
                            local health = injury_mod.compute_health(ctx.player)
                            if health <= 0 then
                                ctx.game_over = true
                            end
                        end
                    end
                else
                    print("You can't drink from " .. (obj.name or "that") .. ".")
                end
                return
            end
        end

        if obj.on_drink_reject then
            print(obj.on_drink_reject)
        else
            print("You can't drink " .. (obj.name or "that") .. ".")
        end
    end

    handlers["quaff"] = handlers["drink"]
    handlers["sip"] = handlers["drink"]

    ---------------------------------------------------------------------------
    -- POUR -- pour out a liquid (FSM or generic)
    ---------------------------------------------------------------------------
    handlers["pour"] = function(ctx, noun)
        if noun == "" then print("Pour what?") return end

        local obj = find_in_inventory(ctx, noun)
        if not obj then obj = find_visible(ctx, noun) end
        if not obj then
            err_not_found(ctx)
            return
        end

        -- FSM path: check for "pour" transition
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            local target_trans
            for _, t in ipairs(transitions) do
                if t.verb == "pour" then target_trans = t; break end
                if t.aliases then
                    for _, alias in ipairs(t.aliases) do
                        if alias == "pour" then target_trans = t; break end
                    end
                    if target_trans then break end
                end
            end
            if target_trans then
                local trans = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {}, "pour")
                if trans then
                    print(trans.message or ("You pour out " .. (obj.name or obj.id) .. "."))
                else
                    print("You can't pour " .. (obj.name or "that") .. ".")
                end
                return
            end
        end

        print("You can't pour " .. (obj.name or "that") .. ".")
    end

    handlers["spill"] = handlers["pour"]
    handlers["dump"] = handlers["pour"]

    ---------------------------------------------------------------------------
    -- BURN -- stub for consumables
    ---------------------------------------------------------------------------
    handlers["burn"] = function(ctx, noun)
        if noun == "" then
            print("Burn what?")
            return
        end

        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            err_not_found(ctx)
            return
        end

        -- If the object has a "light" FSM transition, redirect to the light handler
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            for _, t in ipairs(transitions) do
                if t.from == obj._state and (t.verb == "light" or t.verb == "ignite") then
                    handlers["light"](ctx, noun)
                    return
                end
            end
        end

        -- Need a flame
        local has_fire = (ctx.player.state.has_flame and ctx.player.state.has_flame > 0)
            or find_tool_in_inventory(ctx, "fire_source") ~= nil
        if not has_fire then
            print("You have no flame to burn anything with.")
            return
        end

        if obj.flammable or (obj.categories and type(obj.categories) == "table") then
            local is_flammable = obj.flammable
            if not is_flammable and obj.categories then
                for _, cat in ipairs(obj.categories) do
                    if cat == "flammable" then is_flammable = true break end
                end
            end
            if is_flammable then
                print("You hold the flame to " .. (obj.name or "it") .. ". It catches fire and burns away to ash.")
                remove_from_location(ctx, obj)
                ctx.registry:remove(obj.id)
                return
            end
        end

        print("You can't burn " .. (obj.name or "that") .. ".")
    end

    ---------------------------------------------------------------------------
    -- TIME
    ---------------------------------------------------------------------------
    handlers["time"] = function(ctx, noun)
        local hour, minute = get_game_time(ctx)
        print(time_of_day_desc(hour))
        print("It is " .. format_time(hour, minute) .. ".")
    end

    ---------------------------------------------------------------------------
    -- SLEEP / REST / NAP — clock-advance mechanic
    ---------------------------------------------------------------------------
    local function do_sleep(ctx, noun)
        -- Parse duration from noun
        local sleep_hours = nil

        if noun == "" or noun == nil then
            -- Default: 1 hour nap
            sleep_hours = 1
        else
            -- "for X hours" / "for X minutes" OR "X hours" / "X minutes" (optional "for")
            local num, unit = noun:match("for%s+(%d+)%s*(%a+)")
            if not num then
                -- Try without "for" keyword
                num, unit = noun:match("^(%d+)%s*(%a+)")
            end
            if num then
                num = tonumber(num)
                unit = unit:lower()
                if unit:match("^hour") then
                    sleep_hours = num
                elseif unit:match("^min") then
                    sleep_hours = num / 60
                else
                    sleep_hours = num  -- assume hours
                end
            end

            -- "until dawn" / "until morning"
            if not sleep_hours then
                if noun:match("until%s+dawn") or noun:match("until%s+morning") then
                    local cur_h, cur_m = get_game_time(ctx)
                    local cur_total = cur_h + cur_m / 60
                    local target = DAYTIME_START  -- 6:00 AM
                    if cur_total >= target and cur_total < DAYTIME_END then
                        -- BUG-069: It's already daytime — dawn has passed
                        print("It's already past dawn.")
                        return
                    elseif cur_total >= target then
                        -- Evening/night: wrap to next dawn
                        sleep_hours = (24 - cur_total) + target
                    else
                        sleep_hours = target - cur_total
                    end
                    if sleep_hours < 0.167 then
                        print("It's already nearly dawn — just wait a few minutes.")
                        return
                    end
                end
            end

            -- "until night" / "until dark" / "until dusk"
            if not sleep_hours then
                if noun:match("until%s+night") or noun:match("until%s+dark")
                   or noun:match("until%s+dusk") or noun:match("until%s+evening") then
                    local cur_h, cur_m = get_game_time(ctx)
                    local cur_total = cur_h + cur_m / 60
                    local target = DAYTIME_END  -- 6:00 PM
                    if cur_total >= target then
                        -- BUG-069: It's already nighttime
                        print("It's already nighttime.")
                        return
                    else
                        sleep_hours = target - cur_total
                    end
                    if sleep_hours < 0.167 then
                        print("It's already nighttime.")
                        return
                    end
                end
            end

            -- "for a bit" / "for a while"
            if not sleep_hours then
                if noun:match("a%s+bit") or noun:match("a%s+while") then
                    sleep_hours = 1
                elseif noun:match("a%s+long%s+time") then
                    sleep_hours = 4
                end
            end

            -- Couldn't parse
            if not sleep_hours then
                print("Sleep how long? Try 'sleep for 2 hours' or 'sleep until dawn'.")
                return
            end
        end

        -- Enforce limits
        if sleep_hours < 10 / 60 then
            print("That's barely a nap. You close your eyes for a moment, but don't really sleep.")
            return
        end
        if sleep_hours > 12 then
            print("You can't sleep that long. Try 12 hours or less.")
            return
        end

        -- Snapshot time before sleep
        local before_h, before_m = get_game_time(ctx)

        -- Advance game clock
        ctx.time_offset = (ctx.time_offset or 0) + sleep_hours

        -- Compute ticks to process (roughly 10 ticks per game hour)
        local sleep_ticks = math.floor(sleep_hours * 10)
        if sleep_ticks < 1 then sleep_ticks = 1 end

        -- Build tick targets (same logic as game loop)
        local reg = ctx.registry
        local room = ctx.current_room
        local tick_targets = {}
        for _, obj_id in ipairs(room and room.contents or {}) do
            tick_targets[#tick_targets + 1] = obj_id
            local obj = reg:get(obj_id)
            if obj and obj.surfaces then
                for _, zone in pairs(obj.surfaces) do
                    for _, item_id in ipairs(zone.contents or {}) do
                        tick_targets[#tick_targets + 1] = item_id
                    end
                end
            end
            if obj and obj.contents then
                for _, item_id in ipairs(obj.contents) do
                    tick_targets[#tick_targets + 1] = item_id
                end
            end
        end
        if ctx.player then
            for i = 1, 2 do
                if ctx.player.hands[i] then
                    tick_targets[#tick_targets + 1] = _hid(ctx.player.hands[i])
                end
            end
        end

        -- Tick all FSM objects for elapsed ticks, collecting messages
        local sleep_messages = {}
        -- Each sleep tick = 1/10 game hour = 360 game seconds
        local SLEEP_SECONDS_PER_TICK = 360
        for tick = 1, sleep_ticks do
            for _, obj_id in ipairs(tick_targets) do
                local obj = reg:get(obj_id)
                if obj and obj._state then
                    local msg = fsm_mod.tick(reg, obj_id)
                    if msg then
                        sleep_messages[#sleep_messages + 1] = msg
                    end
                end
            end
            -- Tick timed events engine during sleep
            local timer_msgs = fsm_mod.tick_timers(reg, SLEEP_SECONDS_PER_TICK)
            for _, entry in ipairs(timer_msgs) do
                sleep_messages[#sleep_messages + 1] = entry.message
            end
            -- Also fire on_tick for non-FSM burnables
            if ctx.on_tick then
                ctx.on_tick(ctx)
            end
            -- Tick blood
            local p = ctx.player
            if p and p.state and p.state.bloody and p.state.bleed_ticks then
                p.state.bleed_ticks = p.state.bleed_ticks - 1
                if p.state.bleed_ticks <= 0 then
                    p.state.bloody = false
                    p.state.bleed_ticks = nil
                    sleep_messages[#sleep_messages + 1] = "The bleeding stopped while you slept."
                end
            end
            -- Tick injuries during sleep (bleeding can kill you in your sleep)
            local sleep_inj_ok, sleep_injury_mod = pcall(require, "engine.injuries")
            if sleep_inj_ok and sleep_injury_mod and ctx.player
               and ctx.player.injuries and #ctx.player.injuries > 0 then
                local inj_msgs, died = sleep_injury_mod.tick(ctx.player)
                for _, msg in ipairs(inj_msgs or {}) do
                    sleep_messages[#sleep_messages + 1] = msg
                end
                if died then
                    -- Player bled out during sleep
                    print("")
                    print("You drift deeper into sleep. The pain fades. Everything fades.")
                    print("You never wake up.")
                    print("")
                    print("YOU HAVE DIED.")
                    ctx.game_over = true
                    return
                end
            end
        end

        -- Compute time after sleep
        local after_h, after_m = get_game_time(ctx)

        -- Format duration for display
        local dur_str
        local total_minutes = math.floor(sleep_hours * 60 + 0.5)
        if total_minutes >= 60 then
            local h = math.floor(total_minutes / 60)
            local m = total_minutes % 60
            if m == 0 then
                dur_str = h .. (h == 1 and " hour" or " hours")
            else
                dur_str = h .. (h == 1 and " hour" or " hours") .. " and " .. m .. " minutes"
            end
        else
            dur_str = total_minutes .. " minutes"
        end

        -- Opening text
        print("")
        print("You close your eyes and rest for " .. dur_str .. ".")

        -- Check for notable events during sleep
        local candle_died = false
        for _, msg in ipairs(sleep_messages) do
            if msg:lower():match("candle") and (msg:lower():match("out") or msg:lower():match("gutter")) then
                candle_died = true
            end
        end

        -- Daylight check: did we sleep past dawn with curtains open?
        local crossed_dawn = (before_h < DAYTIME_START or before_h >= DAYTIME_END) and
                             (after_h >= DAYTIME_START and after_h < DAYTIME_END)
        local curtains_open = false
        for _, obj_id in ipairs(room and room.contents or {}) do
            local obj = reg:get(obj_id)
            if obj and obj.allows_daylight then
                curtains_open = true
                break
            end
        end

        -- Wake-up flavor text
        if candle_died then
            print("You drift off... When you wake, the candle has guttered out. Darkness surrounds you.")
        elseif crossed_dawn and curtains_open then
            print("You wake to pale morning light filtering through the window.")
        elseif crossed_dawn then
            print("You sense the world brightening beyond the curtains.")
        end

        -- Print time
        print("It is now " .. format_time(after_h, after_m) .. ". " .. time_of_day_desc(after_h))

        -- Update status bar
        if ctx.ui and ctx.ui.is_enabled() and ctx.update_status then
            ctx.update_status(ctx)
        end
    end

    handlers["sleep"] = do_sleep
    handlers["rest"]  = do_sleep
    handlers["nap"]   = do_sleep

    ---------------------------------------------------------------------------
    -- MOVEMENT -- direction commands, go, enter, descend, ascend, climb
    ---------------------------------------------------------------------------
    local DIRECTION_ALIASES = {
        n = "north", s = "south", e = "east", w = "west",
        u = "up",    d = "down",
        north = "north", south = "south", east = "east", west = "west",
        up = "up", down = "down",
        upstairs = "up", downstairs = "down",
        above = "up", below = "down",
    }

    local function handle_movement(ctx, direction)
        -- Strip common prepositions
        local clean = direction:lower()
            :gsub("^through%s+", "")
            :gsub("^to%s+the%s+", "")
            :gsub("^to%s+", "")
            :gsub("^into%s+", "")
            :gsub("^towards?%s+", "")
        if clean == "" then
            print("Go where?")
            return
        end

        -- Tier 4: "go back" → return to previous room
        if clean == "back" or clean == "back to where i was" then
            if not context_window then
                print("You can't go back — you haven't been anywhere else.")
                return
            end
            local prev_id = context_window.get_previous_room()
            if not prev_id then
                print("You can't go back — you haven't been anywhere else.")
                return
            end
            local prev_room = ctx.rooms and ctx.rooms[prev_id]
            if not prev_room then
                print("You can't go back — that place is no longer accessible.")
                return
            end
            -- Record current room as previous before moving
            if context_window and ctx.current_room then
                context_window.set_previous_room(ctx.current_room.id)
            end
            ctx.player.location = prev_id
            ctx.current_room = prev_room
            ctx.visited_rooms = ctx.visited_rooms or {}
            ctx.visited_rooms[prev_id] = true
            print("")
            print("You retrace your steps.")
            print("**" .. (prev_room.name or "Unnamed room") .. "**")
            if prev_room.short_description then
                print(prev_room.short_description)
            end
            return
        end

        -- Resolve direction alias
        local dir = DIRECTION_ALIASES[clean]

        -- If not a known direction, search exits by keyword
        if not dir then
            local room = ctx.current_room
            for d, exit in pairs(room.exits or {}) do
                if type(exit) == "table" and exit_matches(exit, d, clean) then
                    dir = d
                    break
                end
            end
        end
        if not dir then
            print("You can't go that way.")
            return
        end

        local room = ctx.current_room
        local exit = room.exits and room.exits[dir]
        if not exit then
            print("You can't go that way.")
            return
        end

        if type(exit) == "table" then
            if exit.hidden then
                print("You can't go that way.")
                return
            end
            if not exit.open then
                if exit.locked then
                    print((exit.name or "The way") .. " is locked.")
                else
                    print((exit.name or "The exit") .. " is closed.")
                end
                return
            end
        end

        local target_id = type(exit) == "table" and exit.target or exit
        local target_room = ctx.rooms and ctx.rooms[target_id]
        if not target_room then
            print("That way leads somewhere you cannot yet reach.")
            return
        end

        -- Fire on_traverse exit effects BEFORE moving the player
        traverse_effects.process(exit, ctx)

        -- Tier 4: record current room before moving (for "go back")
        if context_window and ctx.current_room then
            context_window.set_previous_room(ctx.current_room.id)
        end

        -- Move player
        ctx.player.location = target_id
        ctx.current_room = target_room

        -- Track visited rooms for short-description-on-revisit
        ctx.visited_rooms = ctx.visited_rooms or {}
        local first_visit = not ctx.visited_rooms[target_id]
        ctx.visited_rooms[target_id] = true

        -- Print arrival
        print("")
        if target_room.on_enter then
            print(target_room.on_enter(target_room))
        else
            print("You arrive at " .. (target_room.name or "a new area") .. ".")
        end

        -- First visit: full auto-look; revisit: short description only
        if first_visit then
            ctx.verbs["look"](ctx, "")
        else
            print("**" .. (target_room.name or "Unnamed room") .. "**")
            if target_room.short_description then
                print(target_room.short_description)
            end
        end
    end

    -- Cardinal and vertical directions
    for _, dir in ipairs({"north", "south", "east", "west", "up", "down"}) do
        handlers[dir] = function(ctx, noun) handle_movement(ctx, dir) end
    end
    handlers["n"] = handlers["north"]
    handlers["s"] = handlers["south"]
    handlers["e"] = handlers["east"]
    handlers["w"] = handlers["west"]
    handlers["u"] = handlers["up"]
    handlers["d"] = handlers["down"]

    -- GO {direction}
    handlers["go"] = function(ctx, noun)
        if noun == "" then
            print("Go where?")
            return
        end
        handle_movement(ctx, noun)
    end
    handlers["walk"]   = handlers["go"]
    handlers["run"]    = handlers["go"]
    handlers["head"]   = handlers["go"]
    handlers["travel"] = handlers["go"]

    -- BUG-124 (#32): "move" must disambiguate between navigation and object interaction.
    -- If the noun is a direction, treat as "go"; otherwise delegate to the spatial move handler.
    local _move_object = handlers["move"]  -- spatial handler defined earlier (line ~2617)
    handlers["move"] = function(ctx, noun)
        if noun == "" then print("Move what?") return end
        local clean = noun:lower()
            :gsub("^through%s+", "")
            :gsub("^to%s+the%s+", "")
            :gsub("^to%s+", "")
            :gsub("^into%s+", "")
            :gsub("^towards?%s+", "")
        if DIRECTION_ALIASES[clean] or clean == "back" then
            handle_movement(ctx, noun)
        else
            _move_object(ctx, noun)
        end
    end

    -- Tier 4: "back" and "return" as standalone verbs
    handlers["back"] = function(ctx, noun)
        handle_movement(ctx, "back")
    end
    handlers["return"] = function(ctx, noun)
        if noun == "" then
            handle_movement(ctx, "back")
        else
            handle_movement(ctx, noun)
        end
    end

    -- ENTER {thing} -- move through an exit matched by keyword
    handlers["enter"] = function(ctx, noun)
        if noun == "" then
            print("Enter what?")
            return
        end
        handle_movement(ctx, noun)
    end

    -- DESCEND / ASCEND / CLIMB
    handlers["descend"] = function(ctx, noun) handle_movement(ctx, "down") end
    handlers["ascend"]  = function(ctx, noun) handle_movement(ctx, "up") end
    handlers["climb"]   = function(ctx, noun)
        local n = (noun or ""):lower()
        if n == "down" or n == "downstairs" or n:match("down%s+") then
            handle_movement(ctx, "down")
        elseif n == "up" or n == "upstairs" or n:match("up%s+") or n == "" then
            handle_movement(ctx, "up")
        else
            handle_movement(ctx, noun)
        end
    end

    ---------------------------------------------------------------------------
    -- SET / ADJUST — advance adjustable clocks (puzzle mechanic)
    ---------------------------------------------------------------------------
    handlers["set"] = function(ctx, noun)
        if noun == "" then print("Set what?") return end

        -- Find the target object (room or inventory)
        local obj = find_visible(ctx, noun)
        if not obj then obj = find_in_inventory(ctx, noun) end
        if not obj then
            print("You don't see any " .. noun .. " to set.")
            return
        end

        -- Only adjustable clocks respond to SET
        if not obj.adjustable then
            print("You can't set that.")
            return
        end

        -- Must have light to fiddle with clock hands
        if not has_some_light(ctx) then
            print("It is too dark to see the clock face.")
            return
        end

        -- Extract current hour from state name (hour_N)
        local cur_hour = obj._state and tonumber(obj._state:match("hour_(%d+)"))
        if not cur_hour then
            print("You can't figure out how to set that.")
            return
        end

        -- Advance to next hour
        local next_hour = (cur_hour % 24) + 1
        local next_state = "hour_" .. next_hour

        -- Apply the state change directly (manual adjustment, not timed)
        local fsm_set = require("engine.fsm")
        fsm_set.stop_timer(obj.id or "wall-clock")
        local old_state = obj._state
        if obj.states and obj.states[next_state] then
            -- Apply new state properties
            if obj.states[old_state] then
                for k in pairs(obj.states[old_state]) do
                    if k ~= "on_tick" and k ~= "terminal" and k ~= "timed_events" then
                        obj[k] = nil
                    end
                end
            end
            for k, v in pairs(obj.states[next_state]) do
                if k ~= "on_tick" and k ~= "terminal" and k ~= "timed_events" then
                    obj[k] = v
                end
            end
            obj._state = next_state
        end

        -- Restart the hourly timer for the new state
        fsm_set.start_timer(ctx.registry, obj.id or "wall-clock")

        -- Display the new hour
        local display_h = ((next_hour - 1) % 12) + 1
        local number_words = {
            "one", "two", "three", "four", "five", "six",
            "seven", "eight", "nine", "ten", "eleven", "twelve",
        }
        print("You turn the clock hands. The clock now reads " .. number_words[display_h] .. " o'clock.")

        -- Check if puzzle target_hour is reached
        if obj.target_hour and next_hour == obj.target_hour then
            if obj.on_correct_time then
                obj.on_correct_time(obj, ctx)
            end
        end
    end
    handlers["adjust"] = handlers["set"]

    ---------------------------------------------------------------------------
    -- REPORT BUG — opens a pre-filled GitHub issue URL
    ---------------------------------------------------------------------------
    handlers["report_bug"] = function(ctx, noun)
        -- Build transcript text from recent output (last 50 exchanges)
        local transcript = ctx.transcript or {}
        local lines = {}
        for _, entry in ipairs(transcript) do
            lines[#lines + 1] = "> " .. entry.input
            lines[#lines + 1] = entry.output
            lines[#lines + 1] = ""
        end
        local transcript_text = table.concat(lines, "\n")

        -- Level name (stored on room object as level = { number, name })
        local level_name = "Unknown"
        if ctx.current_room and ctx.current_room.level then
            local lv = ctx.current_room.level
            if lv.number and lv.name then
                level_name = "Level " .. lv.number .. ": " .. lv.name
            elseif lv.name then
                level_name = lv.name
            end
        end

        -- Room name
        local room_name = "Unknown"
        if ctx.current_room then
            room_name = ctx.current_room.name or ctx.current_room.id or "Unknown"
        end

        -- Build timestamp (read from src/.build-timestamp if available)
        local build_timestamp = "dev"
        local ts_file = io.open("src/.build-timestamp", "r")
        if ts_file then
            local content = ts_file:read("*a")
            ts_file:close()
            if content and #content > 0 then
                build_timestamp = content:match("^%s*(.-)%s*$") or "dev"
            end
        end

        -- URL-encode helper
        local function url_encode(str)
            str = str:gsub("\r\n", "\n")
            str = str:gsub("([^%w%-%.%_%~ ])", function(c)
                return string.format("%%%02X", string.byte(c))
            end)
            str = str:gsub(" ", "+")
            return str
        end

        local timestamp = os.date and os.date("%Y-%m-%d %H:%M") or "unknown"
        local title = "[Bug Report] " .. room_name .. " - " .. timestamp
        local body = "## Bug Report\n\n"
            .. "**Level:** " .. level_name .. "\n"
            .. "**Room:** " .. room_name .. "\n"
            .. "**Build:** " .. build_timestamp .. "\n\n"
            .. "### What happened?\n"
            .. "_[Please describe the bug here]_\n\n"
            .. "### Session Transcript (last " .. #transcript .. " lines)\n\n"
            .. "```\n" .. transcript_text .. "```\n"

        local url = "https://github.com/WayneWalterBerry/MMO-Issues/issues/new"
            .. "?title=" .. url_encode(title)
            .. "&body=" .. url_encode(body)

        -- Try web bridge first (opens in new tab), fall back to printing URL
        if ctx.open_url then
            ctx.open_url(url)
            print("Opening bug report in a new tab...")
        else
            print("To report a bug, open this URL:")
            print(url)
        end
        print("Thank you for helping improve the game!")
    end

    ---------------------------------------------------------------------------
    -- HELP
    ---------------------------------------------------------------------------
    handlers["help"] = function(ctx, noun)
        print("== Movement ==")
        print("  north/south/east/west    Move in a direction (n/s/e/w)")
        print("  up/down                  Move up or down (u/d)")
        print("  go <direction>           Move (go north, go through door)")
        print("  enter <thing>            Enter through an exit")
        print("  climb up/down            Climb stairs or ladders")
        print("")
        print("== Observation ==")
        print("  look                     Look around the room (vision only, needs light)")
        print("  look at <thing>          Examine something closely (needs light)")
        print("  look in/on/under         Inspect a surface (needs light)")
        print("  search                   Search around (all senses, works in darkness)")
        print("  search <thing>           Search for something (all senses)")
        print("  find <thing>             Find something (all senses, works in darkness)")
        print("  read <thing>             Read text on an object (may teach skills)")
        print("  feel                     Grope around (works in darkness)")
        print("  feel <thing>             Feel an object by touch")
        print("  smell                    Smell the air (works in darkness)")
        print("  smell <thing>            Smell a specific object")
        print("  taste <thing>            Taste something (risky! works in darkness)")
        print("  listen                   Listen to ambient sounds (works in darkness)")
        print("  listen to <thing>        Listen closely to something")
        print("")
        print("== Item Interaction ==")
        print("  take <thing>             Pick something up (needs a free hand)")
        print("  get <x> from <y>         Take something from a bag or container")
        print("  drop <thing>             Drop something you're holding")
        print("  put <x> in <y>           Put something in a container")
        print("  put <x> on <y>           Put something on a surface")
        print("  open <thing>             Open a container or door")
        print("  close <thing>            Close something")
        print("  unlock <thing>           Unlock a locked door")
        print("  pull <thing>             Pull a part free (drawer, cork, etc.)")
        print("")
        print("== Equipment ==")
        print("  wear <thing>             Put on a wearable item (cloak, hat, armor)")
        print("  remove <thing>           Take off a worn item")
        print("  inventory (i)            See what you're carrying / wearing")
        print("")
        print("== Tools & Crafting ==")
        print("  break <thing>            Break something breakable")
        print("  tear <thing>             Tear fabric apart")
        print("  cut <thing> with <tool>  Cut something (or 'cut self' for blood)")
        print("  prick self with <tool>   Prick yourself with something sharp")
        print("  strike match on <x>      Strike a match")
        print("  light <thing>            Light a candle or torch (needs fire)")
        print("  extinguish <thing>       Put out a flame")
        print("  write <text> on <thing>  Write on a writable surface")
        print("  sew <thing> with <tool>  Sew materials together (requires skill)")
        print("")
        print("== Combat ==")
        print("  stab <target>            Attack with a stabbing weapon")
        print("  slash <target>           Attack with a slashing weapon")
        print("")
        print("== Health & Survival ==")
        print("  health                   Check your injuries and health")
        print("  injuries                 List your injuries")
        print("  apply <item>             Apply a healing item to an injury")
        print("  eat <thing>              Eat something edible")
        print("  drink <thing>            Drink from a container")
        print("  pour <thing>             Pour out a liquid")
        print("  burn <thing>             Set something flammable on fire")
        print("  sleep                    Sleep for 1 hour (or: sleep for 2 hours)")
        print("")
        print("== Information ==")
        print("  time                     Check the time of day")
        print("  help                     Show this list")
        print("  report bug               Report a bug (opens GitHub issue)")
        print("  quit                     Leave the game")
    end

    ---------------------------------------------------------------------------
    -- INJURIES -- examine active injuries and derived health
    ---------------------------------------------------------------------------
    handlers["injuries"] = function(ctx, noun)
        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if not inj_ok then
            print("You feel fine.")
            return
        end

        injury_mod.list(ctx.player)

        -- Show derived health
        local health = injury_mod.compute_health(ctx.player)
        local max = ctx.player.max_health or 100
        if ctx.player.injuries and #ctx.player.injuries > 0 then
            print("")
            print("Health: " .. health .. "/" .. max)
        end
    end
    handlers["injury"] = handlers["injuries"]
    handlers["wounds"] = handlers["injuries"]
    handlers["health"] = handlers["injuries"]

    ---------------------------------------------------------------------------
    -- APPLY -- apply a healing item to an injury ("apply bandage", "apply bandage to wound")
    -- Supports bandage dual-binding via injury_targeting + injury_treatment
    ---------------------------------------------------------------------------
    handlers["apply"] = function(ctx, noun)
        if noun == "" then
            print("Apply what? Try 'examine' to check what you're carrying.")
            return
        end

        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if not inj_ok then
            err_cant_do_that()
            return
        end

        if not ctx.player.injuries or #ctx.player.injuries == 0 then
            print("You don't have any injuries to treat.")
            return
        end

        -- Parse "apply X to Y" or just "apply X"
        local item_kw = noun
        local target_kw = nil
        local to_match = noun:match("^(.-)%s+to%s+(.+)$")
        if to_match then
            item_kw = noun:match("^(.-)%s+to%s+")
            target_kw = noun:match("%s+to%s+(.+)$")
        end

        -- Strip articles
        item_kw = item_kw:lower():gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        if target_kw then
            target_kw = target_kw:lower():gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", ""):gsub("^my%s+", "")
        end

        -- Find healing item in inventory (hands, worn, etc.)
        local obj = find_in_inventory(ctx, item_kw)
        if not obj then
            print("You don't have " .. item_kw .. ".")
            return
        end

        -- Check if this is a bandage-type item with cures list and FSM
        if obj.cures and obj._state then
            -- Bandage-style treatment: use dual-binding system
            if obj.applied_to then
                print((obj.name or "That") .. " is already applied to a wound.")
                return
            end

            -- Resolve which injury to target
            local injury, err = injury_mod.resolve_target(ctx.player, target_kw, obj.cures)
            if not injury then
                print(err)
                return
            end

            -- Apply the treatment (dual binding)
            injury_mod.apply_treatment(ctx.player, obj, injury)

            -- Find and print the transition message from the bandage's transitions
            local msg = nil
            if obj.transitions then
                for _, t in ipairs(obj.transitions) do
                    if t.verb == "apply" and t.to == "applied" then
                        msg = t.message
                        break
                    end
                end
            end
            if not msg then
                msg = "You apply " .. (obj.name or item_kw) .. " to the wound."
            end
            print(msg)
            return
        end

        -- Fallback: legacy healing via on_apply/on_use/on_drink
        local healing_effect = nil
        local healing_verb = nil
        for _, v in ipairs({"apply", "use", "drink"}) do
            local eff = obj["on_" .. v]
            if eff and eff.cures then
                healing_effect = eff
                healing_verb = v
                break
            end
        end

        if not healing_effect then
            print("You can't use " .. (obj.name or item_kw) .. " to treat injuries.")
            return
        end

        -- Attempt healing
        local healed = injury_mod.try_heal(ctx.player, obj, healing_verb)
        if healed and healing_effect.consumable then
            -- Consume the item from hands
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local hand_id = type(hand) == "table" and hand.id or hand
                    if hand_id == obj.id then
                        ctx.player.hands[i] = nil
                        break
                    end
                end
            end
        end
    end
    handlers["treat"] = handlers["apply"]

    -- #39: "wait" — pass a turn without acting (BUG-131)
    -- Post-command injury tick and time advance happen automatically in the loop.
    handlers["wait"] = function(ctx, noun)
        print("Time passes.")
    end
    handlers["pass"] = handlers["wait"]

    -- #39/#37: "appearance" — show player appearance description (BUG-131/BUG-129)
    handlers["appearance"] = function(ctx, noun)
        local app_ok, app_mod = pcall(require, "engine.player.appearance")
        if app_ok and app_mod then
            print(app_mod.describe(ctx.player, ctx.registry))
        else
            print("You can't see yourself without a mirror.")
        end
    end

    return handlers
end

return verbs


