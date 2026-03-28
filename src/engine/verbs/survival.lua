-- engine/verbs/survival.lua
-- Retains: pour, dump/empty, wash handlers.
-- Eat/drink moved to consumption.lua; sleep/rest moved to rest.lua (Phase 3 WAVE-0).
local H = require("engine.verbs.helpers")

local fsm_mod = H.fsm_mod
local effects = H.effects

local err_not_found = H.err_not_found
local find_visible = H.find_visible
local find_in_inventory = H.find_in_inventory
local find_tool_in_inventory = H.find_tool_in_inventory
local provides_capability = H.provides_capability
local find_visible_tool = H.find_visible_tool
local remove_from_location = H.remove_from_location

local M = {}

function M.register(handlers)
    -- Delegate eat/drink to consumption module
    local consumption = require("engine.verbs.consumption")
    consumption.register(handlers)

    -- Delegate sleep/rest/nap to rest module
    local rest = require("engine.verbs.rest")
    rest.register(handlers)

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

        -- #108: "pour X into Y" — transfer liquid to target container
        local pour_target_noun = ctx.pour_target
        if pour_target_noun then
            local target_obj = find_in_inventory(ctx, pour_target_noun)
            if not target_obj then target_obj = find_visible(ctx, pour_target_noun) end
            if not target_obj then
                print("You don't see any " .. pour_target_noun .. " to pour into.")
                return
            end

            -- Check source has a "pour" FSM transition with target support
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
                        print(trans.message or ("You pour " .. (obj.name or obj.id) .. " into " .. (target_obj.name or target_obj.id) .. "."))
                    else
                        print("You can't pour " .. (obj.name or "that") .. ".")
                    end
                    return
                end
            end

            -- #118: Check target has a "pour" FSM transition (e.g. lantern needing oil)
            if target_obj.states then
                local transitions = fsm_mod.get_transitions(target_obj)
                local found_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "pour" then found_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "pour" then found_trans = t; break end
                        end
                        if found_trans then break end
                    end
                end
                if found_trans then
                    if found_trans.requires_tool then
                        if not provides_capability(obj, found_trans.requires_tool) then
                            local tool = find_tool_in_inventory(ctx, found_trans.requires_tool)
                            if not tool then
                                print(found_trans.fail_message or ("You can't pour " .. (obj.name or "that") .. " into " .. (target_obj.name or "that") .. "."))
                                return
                            end
                        end
                    end
                    local trans = fsm_mod.transition(ctx.registry, target_obj.id, found_trans.to, {}, "pour")
                    if trans then
                        print(trans.message or ("You pour " .. (obj.name or obj.id) .. " into " .. (target_obj.name or target_obj.id) .. "."))
                    else
                        print("You can't pour " .. (obj.name or "that") .. " into " .. (target_obj.name or "that") .. ".")
                    end
                    return
                end
            end

            -- Generic liquid transfer message
            print("You pour " .. (obj.name or obj.id) .. " into " .. (target_obj.name or target_obj.id) .. ".")
            return
        end

        -- FSM path: check for "pour" transition (bare pour, no target)
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
    handlers["fill"] = handlers["pour"]
    handlers["fuel"] = handlers["pour"]     -- #398: "fuel lantern" routes to pour
    handlers["refuel"] = handlers["pour"]   -- #398: "refuel lantern" routes to pour

    ---------------------------------------------------------------------------
    -- DUMP / EMPTY — container-aware pour (#182)
    -- If target is a dry container with item contents, spill them into the
    -- room.  Otherwise fall through to pour behavior for liquids.
    ---------------------------------------------------------------------------
    local function dump_container(ctx, noun)
        if noun == "" then print("Dump what?") return end

        local obj = find_in_inventory(ctx, noun)
        if not obj then obj = find_visible(ctx, noun) end
        if not obj then err_not_found(ctx) return end

        -- Container with direct item contents
        if obj.container and obj.contents and #obj.contents > 0 then
            local room = ctx.current_room
            local dumped = {}
            for _, item_id in ipairs(obj.contents) do
                local item = ctx.registry:get(item_id)
                if item then
                    room.contents[#room.contents + 1] = item_id
                    item.location = room.id
                    dumped[#dumped + 1] = item.name or item.id
                end
            end
            obj.contents = {}
            if #dumped == 1 then
                print("You dump " .. dumped[1] .. " out of " .. (obj.name or "that") .. ".")
            else
                print("You dump the contents of " .. (obj.name or "that") .. " onto the floor.")
            end
            return
        end

        -- Container with surface.inside contents
        if obj.surfaces and obj.surfaces.inside then
            local inside = obj.surfaces.inside
            if inside.contents and #inside.contents > 0 then
                if inside.accessible ~= false then
                    local room = ctx.current_room
                    for _, item_id in ipairs(inside.contents) do
                        local item = ctx.registry:get(item_id)
                        if item then
                            room.contents[#room.contents + 1] = item_id
                            item.location = room.id
                        end
                    end
                    inside.contents = {}
                    print("You dump the contents of " .. (obj.name or "that") .. " onto the floor.")
                else
                    print("You turn " .. (obj.name or "that") .. " upside down but nothing falls out.")
                end
                return
            end
        end

        -- Empty container
        if obj.container then
            print("You turn " .. (obj.name or "that") .. " upside down but nothing falls out.")
            return
        end

        -- Not a container — fall through to pour for liquids
        handlers["pour"](ctx, noun)
    end

    handlers["dump"] = dump_container
    handlers["empty"] = dump_container

    ---------------------------------------------------------------------------
    -- WASH -- clean soiled objects using a water source (#112)
    ---------------------------------------------------------------------------
    handlers["wash"] = function(ctx, noun)
        if noun == "" then
            print("Wash what?")
            return
        end

        -- "wash hands" / "wash my hands"
        local hand_noun = noun:gsub("^my%s+", "")
        if hand_noun == "hands" or hand_noun == "hand" then
            -- Find water source nearby
            local water = find_tool_in_inventory(ctx, "water_source")
            if not water then water = find_visible_tool(ctx, "water_source") end
            if not water or (water._state and water._state:match("empty")) then
                print("You need water to wash your hands.")
                return
            end
            print("You plunge your hands into the water and scrub them clean.")
            if ctx.player.state then
                ctx.player.state.bloody = nil
                ctx.player.state.dirty = nil
            end
            return
        end

        local obj = find_in_inventory(ctx, noun)
        if not obj then obj = find_visible(ctx, noun) end
        if not obj then
            err_not_found(ctx)
            return
        end

        -- FSM path: check for "wash" transition
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            local found_trans
            for _, t in ipairs(transitions) do
                if t.verb == "wash" then found_trans = t; break end
                if t.aliases then
                    for _, alias in ipairs(t.aliases) do
                        if alias == "wash" then found_trans = t; break end
                    end
                    if found_trans then break end
                end
            end

            if found_trans then
                if found_trans.requires_tool then
                    -- If player specified "wash X in Y", check the target
                    local water
                    if ctx.wash_target then
                        water = find_in_inventory(ctx, ctx.wash_target)
                        if not water then water = find_visible(ctx, ctx.wash_target) end
                        if water and not provides_capability(water, found_trans.requires_tool) then
                            print((water.name or ctx.wash_target) .. " isn't a water source.")
                            return
                        end
                    end
                    -- Auto-find water source
                    if not water then
                        water = find_tool_in_inventory(ctx, found_trans.requires_tool)
                    end
                    if not water then
                        water = find_visible_tool(ctx, found_trans.requires_tool)
                    end
                    -- Reject empty water sources
                    if water and water._state and water._state:match("empty") then
                        water = nil
                    end
                    if not water then
                        print(found_trans.fail_message or "You need water to wash that.")
                        return
                    end
                end

                local trans = fsm_mod.transition(ctx.registry, obj.id, found_trans.to, {}, "wash")
                if trans then
                    print(trans.message or ("You wash " .. (obj.name or obj.id) .. "."))
                else
                    print("You can't wash " .. (obj.name or "that") .. ".")
                end
                return
            end
        end

        print("You can't wash " .. (obj.name or "that") .. ".")
    end
end

return M
