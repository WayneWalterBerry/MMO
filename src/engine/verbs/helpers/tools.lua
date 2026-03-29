-- engine/verbs/helpers/tools.lua
-- Tool capability resolution helpers.

local core = require("engine.verbs.helpers.core")

local M = {}

---------------------------------------------------------------------------
-- Helper: find a tool in carried items that provides a given capability.
-- Also checks blood as writing instrument when player has bloody state.
---------------------------------------------------------------------------
local function find_tool_in_inventory(ctx, required_capability)
    local reg = ctx.registry
    local all_ids = core.get_all_carried_ids(ctx)
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
            ctx.mutation.mutate(ctx.registry, ctx.loader, tool.id, source, ctx.templates, ctx)
        end
    end
end

M.find_tool_in_inventory = find_tool_in_inventory
M.provides_capability = provides_capability
M.find_visible_tool = find_visible_tool
M.consume_tool_charge = consume_tool_charge

return M
