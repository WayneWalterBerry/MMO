-- engine/verbs/helpers/inventory.lua
-- Inventory and placement helpers.

local core = require("engine.verbs.helpers.core")
local search = require("engine.verbs.helpers.search")

local M = {}

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
-- Helper: total carried weight (hands + worn)
---------------------------------------------------------------------------
local function inventory_weight(ctx)
    local total = 0
    local reg = ctx.registry
    for _, id in ipairs(core.get_all_carried_ids(ctx)) do
        local obj = reg:get(id)
        if obj then total = total + (obj.weight or 0) end
    end
    return total
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
                if search.matches_keyword(part, kw) then
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
                                if search.matches_keyword(part, kw) then
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
                    if search.matches_keyword(part, kw) then
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

M.next_instance_id = next_instance_id
M._hid = _hid
M._hobj = _hobj
M.hands_full = hands_full
M.first_empty_hand = first_empty_hand
M.which_hand = which_hand
M.count_hands_used = count_hands_used
M.inventory_weight = inventory_weight
M.remove_from_location = remove_from_location
M.find_part = find_part
M.detach_part = detach_part
M.reattach_part = reattach_part
return M
