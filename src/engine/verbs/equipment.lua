-- engine/verbs/equipment.lua
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

        -- Reject wearing items in non-wearable states (shattered armor, shredded clothing)
        local armor_mod_ok, armor_mod = pcall(require, "engine.armor")
        if armor_mod_ok and armor_mod.is_wearable_state
           and not armor_mod.is_wearable_state(obj) then
            print("You can't wear " .. (obj.name or "that") .. ". It's too damaged.")
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
        -- Bug #180: Defensive sweep — clear ALL hand slots holding this item,
        -- not just the slot we found it in. Prevents stale references from
        -- leaving the item in both hand and worn after edge-case dispatches.
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local hid = type(hand) == "table" and hand.id or hand
                if hid == obj.id then
                    ctx.player.hands[i] = nil
                end
            end
        end
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

        -- on_wear hook: fire callback if object declares one
        if obj.on_wear and type(obj.on_wear) == "function" then
            obj.on_wear(obj, ctx)
        end

        -- event_output: one-shot flavor text for on_wear
        if obj.event_output and obj.event_output["on_wear"] then
            print(obj.event_output["on_wear"])
            obj.event_output["on_wear"] = nil
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

        -- on_remove_worn hook: fire callback if object declares one
        if obj.on_remove_worn and type(obj.on_remove_worn) == "function" then
            obj.on_remove_worn(obj, ctx)
        end

        -- event_output: one-shot flavor text for on_remove_worn
        if obj.event_output and obj.event_output["on_remove_worn"] then
            print(obj.event_output["on_remove_worn"])
            obj.event_output["on_remove_worn"] = nil
        end
    end

    handlers["doff"] = handlers["remove"]
end

return M
