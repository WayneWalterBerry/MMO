-- engine/verbs/containers.lua
local H = require("engine.verbs.helpers")

local fsm_mod = H.fsm_mod
local presentation = H.presentation
local preprocess = H.preprocess
local traverse_effects = H.traverse_effects
local effects = H.effects
local materials = H.materials
local context_window = H.context_window
local fuzzy = H.fuzzy

local GAME_SECONDS_PER_REAL_SECOND = H.GAME_SECONDS_PER_REAL_SECOND
local GAME_START_HOUR = H.GAME_START_HOUR
local DAYTIME_START = H.DAYTIME_START
local DAYTIME_END = H.DAYTIME_END

local next_instance_id = H.next_instance_id
local _hid = H._hid
local _hobj = H._hobj
local err_not_found = H.err_not_found
local err_cant_do_that = H.err_cant_do_that
local err_nothing_happens = H.err_nothing_happens
local matches_keyword = H.matches_keyword
local interaction_verbs = H.interaction_verbs
local hands_full = H.hands_full
local first_empty_hand = H.first_empty_hand
local which_hand = H.which_hand
local get_all_carried_ids = H.get_all_carried_ids
local count_hands_used = H.count_hands_used
local find_part = H.find_part
local detach_part = H.detach_part
local reattach_part = H.reattach_part
local _fv_room = H._fv_room
local _fv_surfaces = H._fv_surfaces
local _fv_parts = H._fv_parts
local _fv_hands = H._fv_hands
local _fv_bags = H._fv_bags
local _fv_worn = H._fv_worn
local find_visible = H.find_visible
local find_in_inventory = H.find_in_inventory
local find_tool_in_inventory = H.find_tool_in_inventory
local provides_capability = H.provides_capability
local find_visible_tool = H.find_visible_tool
local consume_tool_charge = H.consume_tool_charge
local remove_from_location = H.remove_from_location
local container_contents_accessible = H.container_contents_accessible
local find_mutation = H.find_mutation
local spawn_objects = H.spawn_objects
local perform_mutation = H.perform_mutation
local inventory_weight = H.inventory_weight
local move_spatial_object = H.move_spatial_object

local get_game_time = H.get_game_time
local is_daytime = H.is_daytime
local format_time = H.format_time
local time_of_day_desc = H.time_of_day_desc
local get_light_level = H.get_light_level
local has_some_light = H.has_some_light
local vision_blocked_by_worn = H.vision_blocked_by_worn

local M = {}

function M.register(handlers)
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
                        -- on_open hook: fire callback if object declares one
                        if obj.on_open and type(obj.on_open) == "function" then
                            obj.on_open(obj, ctx)
                        end
                        -- event_output: one-shot flavor text for on_open
                        if obj.event_output and obj.event_output["on_open"] then
                            print(obj.event_output["on_open"])
                            obj.event_output["on_open"] = nil
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
                        -- #170: State-specific message — explain WHY the object can't be opened.
                        -- Check state's on_push (physical action for "open"), then state name.
                        local state_info = obj.states and obj._state and obj.states[obj._state]
                        if state_info and state_info.on_push then
                            print(state_info.on_push)
                        elseif obj._state and obj._state ~= "closed" then
                            local article_name = obj.name or "that"
                            -- Capitalize: "a heavy oak door" → "A heavy oak door"
                            local cap_name = article_name:sub(1,1):upper() .. article_name:sub(2)
                            print(cap_name .. " is " .. obj._state
                                .. ". It won't budge.")
                        else
                            print("You can't open " .. (obj.name or "that") .. ".")
                        end
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
                        -- on_close hook: fire callback if object declares one
                        if obj.on_close and type(obj.on_close) == "function" then
                            obj.on_close(obj, ctx)
                        end
                        -- event_output: one-shot flavor text for on_close
                        if obj.event_output and obj.event_output["on_close"] then
                            print(obj.event_output["on_close"])
                            obj.event_output["on_close"] = nil
                        end
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

        if obj then
            print("You can't close " .. (obj.name or "that") .. ".")
        else
            err_not_found(ctx)
        end
    end

    handlers["shut"] = handlers["close"]

    ---------------------------------------------------------------------------
    -- UNLOCK
    ---------------------------------------------------------------------------
    handlers["unlock"] = function(ctx, noun)
        if noun == "" then print("Unlock what?") return end

        local obj, loc_type, parent_obj = find_visible(ctx, noun)
        if loc_type == "part" and parent_obj then obj = parent_obj end

        if obj then
            if obj.states then
                local transitions = fsm_mod.get_transitions(obj)
                local target_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "unlock" then target_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "unlock" then target_trans = t; break end
                        end
                        if target_trans then break end
                    end
                end
                if target_trans then
                    if target_trans.requires_tool then
                        local tool = find_tool_in_inventory(ctx, target_trans.requires_tool)
                        if not tool then
                            tool = find_visible_tool(ctx, target_trans.requires_tool)
                        end
                        if not tool then
                            print("You don't have the right key.")
                            return
                        end
                    end
                    local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                    if trans then
                        print(trans.message or ("You unlock " .. (obj.name or obj.id) .. "."))
                    else
                        print("You can't unlock " .. (obj.name or "that") .. ".")
                    end
                else
                    if obj._state and obj._state ~= "locked" then
                        print("It isn't locked.")
                    else
                        print("You can't unlock " .. (obj.name or "that") .. ".")
                    end
                end
                return
            end

            print("You can't unlock " .. (obj.name or "that") .. ".")
        else
            err_not_found(ctx)
        end
    end

    ---------------------------------------------------------------------------
    -- LOCK
    ---------------------------------------------------------------------------
    handlers["lock"] = function(ctx, noun)
        if noun == "" then print("Lock what?") return end

        local obj, loc_type, parent_obj = find_visible(ctx, noun)
        if loc_type == "part" and parent_obj then obj = parent_obj end

        if obj then
            if obj.states then
                local transitions = fsm_mod.get_transitions(obj)
                local target_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "lock" then target_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "lock" then target_trans = t; break end
                        end
                        if target_trans then break end
                    end
                end
                if target_trans then
                    if target_trans.requires_tool then
                        local tool = find_tool_in_inventory(ctx, target_trans.requires_tool)
                        if not tool then
                            tool = find_visible_tool(ctx, target_trans.requires_tool)
                        end
                        if not tool then
                            print("You don't have the right key.")
                            return
                        end
                    end
                    local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                    if trans then
                        print(trans.message or ("You lock " .. (obj.name or obj.id) .. "."))
                    else
                        print("You can't lock " .. (obj.name or "that") .. ".")
                    end
                else
                    if obj._state and obj._state == "locked" then
                        print("It is already locked.")
                    else
                        print("You can't lock " .. (obj.name or "that") .. ".")
                    end
                end
                return
            end

            print("You can't lock " .. (obj.name or "that") .. ".")
        else
            err_not_found(ctx)
        end
    end
end

return M
