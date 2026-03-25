-- engine/verbs/destruction.lua
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
local exit_matches = H.exit_matches
local sync_linked_exit = H.sync_linked_exit
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
                        -- #216: sync linked exit after FSM break transition
                        sync_linked_exit(ctx, obj, "break")
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

        -- Remember which hand held the object before mutation destroys it (#134)
        local held_hand = which_hand(ctx, obj.id)

        local obj_name = obj.name or obj.id
        if perform_mutation(ctx, obj, mut_data) then
            print(mut_data.message
                or ("You tear " .. obj_name .. " apart."))

            -- Move spawned items from room to player's hands (#134)
            if mut_data.spawns and held_hand then
                local room = ctx.current_room
                for _, spawn_id in ipairs(mut_data.spawns) do
                    -- Find the spawned item in room contents (may have suffixed ID)
                    for i = #room.contents, 1, -1 do
                        local room_id = room.contents[i]
                        if room_id == spawn_id or room_id:sub(1, #spawn_id) == spawn_id then
                            local slot = first_empty_hand(ctx)
                            if slot then
                                ctx.player.hands[slot] = room_id
                                table.remove(room.contents, i)
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    handlers["rip"] = handlers["tear"]
end

return M
