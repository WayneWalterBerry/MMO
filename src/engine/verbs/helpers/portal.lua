-- engine/verbs/helpers/portal.lua
-- Portal-specific helper functions.

local search = require("engine.verbs.helpers.search")

local M = {}

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
                if search.matches_keyword(obj, kw) then return obj end
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

M.find_portal_by_keyword = find_portal_by_keyword
M.sync_bidirectional_portal = sync_bidirectional_portal

return M
