-- engine/verbs/acquisition.lua
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
local try_fsm_verb = H.try_fsm_verb

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
                -- BUG-116: check accessible flag on root-content containers
                if bag.accessible == false then
                    local bag_name = bag.name or "that"
                    print(bag_name:sub(1,1):upper() .. bag_name:sub(2) .. " is closed.")
                    return
                end
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
            -- on_pickup hook: fire callback if object declares one
            if item.on_pickup and type(item.on_pickup) == "function" then
                item.on_pickup(item, ctx)
            end
            -- event_output: one-shot flavor text for on_take
            if item.event_output and item.event_output["on_take"] then
                print(item.event_output["on_take"])
                item.event_output["on_take"] = nil
            end
            return
        end

        local obj, where, parent, sname = find_visible(ctx, target)
        if not obj then
            err_not_found(ctx)
            return
        end

        -- Bug #53 + #180 + #294: Guard against taking the exact same object.
        -- Use table identity (not id string) so different instances of the same
        -- type are not blocked (e.g., two silk-bundles for silk-rope crafting).
        if obj.location == "player" then
            for i = 1, 2 do
                if ctx.player.hands[i] then
                    local hand_obj = _hobj(ctx.player.hands[i], ctx.registry)
                    if hand_obj == obj then
                        print("You already have that.")
                        return
                    end
                end
            end
            for _, worn_id in ipairs(ctx.player.worn or {}) do
                if ctx.registry:get(worn_id) == obj then
                    print("You're wearing that. You'll need to remove it first.")
                    return
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

        -- "bag" or "container" means item is inside a container (held or in the room).
        -- Allow extracting it to a free hand (e.g., pulling a match from a matchbox,
        -- or taking a candle from a holder on a surface). (#215)
        if (where == "bag" or where == "container") and parent then
            if not obj.portable then
                print(obj.not_portable_reason or ("You can't carry " .. (obj.name or "that") .. "."))
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
            -- on_pickup hook: fire callback if object declares one
            if obj.on_pickup and type(obj.on_pickup) == "function" then
                obj.on_pickup(obj, ctx)
            end
            -- event_output: one-shot flavor text for on_take
            if obj.event_output and obj.event_output["on_take"] then
                print(obj.event_output["on_take"])
                obj.event_output["on_take"] = nil
            end
            return
        end

        if not obj.portable then
            print(obj.not_portable_reason or ("You can't carry " .. (obj.name or "that") .. "."))
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
            -- on_pickup hook: fire callback if object declares one
            if obj.on_pickup and type(obj.on_pickup) == "function" then
                obj.on_pickup(obj, ctx)
            end
            -- event_output: one-shot flavor text for on_take
            if obj.event_output and obj.event_output["on_take"] then
                print(obj.event_output["on_take"])
                obj.event_output["on_take"] = nil
            end
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
        -- on_pickup hook: fire callback if object declares one
        if obj.on_pickup and type(obj.on_pickup) == "function" then
            obj.on_pickup(obj, ctx)
        end
        -- event_output: one-shot flavor text for on_take
        if obj.event_output and obj.event_output["on_take"] then
            print(obj.event_output["on_take"])
            obj.event_output["on_take"] = nil
        end
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

        -- Registry fallback for objects not in standard search paths (traps, etc.)
        if not obj and ctx.registry and ctx.registry.find_by_keyword then
            obj = ctx.registry:find_by_keyword(target)
        end

        if not obj then
            err_not_found(ctx)
            return
        end

        -- Check for FSM transitions first (traps, mechanisms, etc.)
        if try_fsm_verb(ctx, obj, "push") then
            return
        end

        move_spatial_object(ctx, obj, "push")
    end

    handlers["shove"] = handlers["push"]
    handlers["nudge"] = handlers["push"]
    handlers["press"] = handlers["push"]
    handlers["click"] = handlers["push"]

    ---------------------------------------------------------------------------
    -- MOVE / SHIFT / DRAG — general spatial movement
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
    handlers["drag"]  = handlers["move"]

    ---------------------------------------------------------------------------
    -- SLIDE — slide objects sideways (#111)
    ---------------------------------------------------------------------------
    handlers["slide"] = function(ctx, noun)
        if noun == "" then print("Slide what?") return end

        -- Strip trailing "aside" / "away" / "over"
        local target = noun:gsub("%s+aside$", ""):gsub("%s+away$", ""):gsub("%s+over$", "")

        local obj = find_visible(ctx, target)
        if not obj then
            err_not_found(ctx)
            return
        end

        move_spatial_object(ctx, obj, "slide")
    end

    ---------------------------------------------------------------------------
    -- LIFT / HEAVE — pick up or reveal what's under something
    ---------------------------------------------------------------------------
    handlers["lift"] = function(ctx, noun)
        if noun == "" then print("Lift what?") return end

        -- Strip trailing "up"
        local target = noun:gsub("%s+up$", "")

        local obj = find_visible(ctx, target)
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

    handlers["heave"] = handlers["lift"]

    ---------------------------------------------------------------------------
    -- TYPE / INPUT — for entering codes/text into objects (keypads, dials, etc.)
    -- Triggers FSM transition with verb "enter" or "type"
    ---------------------------------------------------------------------------
    handlers["type"] = function(ctx, noun)
        if noun == "" then 
            print("Type what?")
            return 
        end

        -- First check: is there an object in the room that accepts "type" or "enter"?
        -- Look for objects with transitions matching verb = "type" or verb = "enter"
        local room = ctx.current_room
        if room and room.contents then
            for _, obj_id in ipairs(room.contents) do
                local obj = ctx.registry:get(obj_id)
                if obj and obj.transitions then
                    -- Try FSM transition with "type" or "enter" verbs
                    if try_fsm_verb(ctx, obj, "type") then
                        return
                    end
                    if try_fsm_verb(ctx, obj, "enter") then
                        return
                    end
                end
            end
        end

        print("There's nothing here to type on.")
    end

    handlers["input"] = handlers["type"]
    handlers["dial"] = handlers["type"]

    ---------------------------------------------------------------------------
    -- TURN — for rotating objects (dials, knobs, etc.)
    -- Triggers FSM transition with verb "turn"
    ---------------------------------------------------------------------------
    handlers["turn"] = function(ctx, noun)
        if noun == "" then 
            print("Turn what?")
            return 
        end

        -- Strip trailing "on" / "off" (those are different actions)
        local target = noun:gsub("%s+on$", ""):gsub("%s+off$", "")

        -- Try to find the object
        local obj = find_visible(ctx, target)

        if not obj then
            -- Check room contents directly for objects with "turn" transitions
            local room = ctx.current_room
            if room and room.contents then
                for _, obj_id in ipairs(room.contents) do
                    local room_obj = ctx.registry:get(obj_id)
                    if room_obj and room_obj.transitions then
                        if try_fsm_verb(ctx, room_obj, "turn") then
                            return
                        end
                    end
                end
            end
            err_not_found(ctx)
            return
        end

        -- Check for FSM transitions first
        if try_fsm_verb(ctx, obj, "turn") then
            return
        end

        print("You can't turn " .. (obj.name or "that") .. ".")
    end

    handlers["rotate"] = handlers["turn"]
    handlers["spin"] = handlers["turn"]

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

        -- #139: "drop all" / "drop everything" — bulk drop all held items
        local kw_raw = noun:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        if kw_raw == "all" or kw_raw == "everything" then
            local dropped_any = false
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local held_obj = _hobj(hand, ctx.registry)
                    if held_obj then
                        ctx.player.hands[i] = nil
                        ctx.current_room.contents[#ctx.current_room.contents + 1] = held_obj.id
                        held_obj.location = ctx.current_room.id
                        print("You drop " .. (held_obj.name or held_obj.id) .. ".")
                        -- on_drop hook: fire callback if object declares one
                        if held_obj.on_drop and type(held_obj.on_drop) == "function" then
                            held_obj.on_drop(held_obj, ctx)
                        end
                        dropped_any = true
                    end
                end
            end
            if not dropped_any then
                print("You aren't holding anything.")
            end
            return
        end

        -- Only drop items directly in hands (not bag contents or worn)
        local obj = nil
        local hand_slot = nil
        local kw = kw_raw
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

        -- Bug #181: Fuzzy fallback when exact keyword match fails on hands
        if not obj and fuzzy then
            local parsed = fuzzy.parse_noun_phrase(kw)
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local candidate = _hobj(hand, ctx.registry)
                    if candidate then
                        local score = fuzzy.score_object(candidate, parsed)
                        if score > 0 then
                            obj = candidate
                            hand_slot = i
                            break
                        end
                    end
                end
            end
        end

        if not obj then
            -- #137: Check if it's a worn item — give appropriate message
            local kw_check = noun:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            local is_worn = false
            for _, worn_id in ipairs(ctx.player.worn or {}) do
                local worn_obj = ctx.registry and ctx.registry:get(worn_id)
                if worn_obj and matches_keyword(worn_obj, kw_check) then
                    is_worn = true
                    break
                end
            end
            -- Bug #181: Fuzzy fallback for worn item check
            if not is_worn and fuzzy then
                local parsed = fuzzy.parse_noun_phrase(kw_check)
                for _, worn_id in ipairs(ctx.player.worn or {}) do
                    local worn_obj = ctx.registry and ctx.registry:get(worn_id)
                    if worn_obj then
                        local score = fuzzy.score_object(worn_obj, parsed)
                        if score > 0 then
                            is_worn = true
                            break
                        end
                    end
                end
            end
            if is_worn then
                print("You're wearing that. You'll need to remove it first.")
            else
                -- Check if it's in a bag -- give a helpful message
                local bag_item = find_in_inventory(ctx, noun)
                if bag_item then
                    print("You'll need to get that out of the bag first, or drop the bag itself.")
                else
                    print("You aren't holding that.")
                end
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

        -- on_drop hook: fire callback if object declares one
        if obj.on_drop and type(obj.on_drop) == "function" then
            obj.on_drop(obj, ctx)
        end
        -- event_output: one-shot flavor text for on_drop
        if obj.event_output and obj.event_output["on_drop"] then
            print(obj.event_output["on_drop"])
            obj.event_output["on_drop"] = nil
        end
    end
end

return M
