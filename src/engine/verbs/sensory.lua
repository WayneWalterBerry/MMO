-- engine/verbs/sensory.lua
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
local show_hint = H.show_hint

local M = {}

function M.register(handlers)
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
                local sky = ctx.current_room and ctx.current_room.sky_visible
                local desc = time_of_day_desc(hour, sky)
                if desc then
                    print("\n" .. desc .. " It is " .. format_time(hour, minute) .. ".")
                else
                    print("\nIt is " .. format_time(hour, minute) .. ".")
                end
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

            -- Object presences (deduplicated by ID + text)
            -- BUG-050: Skip objects listed in room.embedded_presences — their
            -- presence is already woven into the room description text.
            local embedded = {}
            if room.embedded_presences then
                for _, eid in ipairs(room.embedded_presences) do
                    embedded[eid] = true
                end
            end
            local presences = {}
            local seen_presences = {}
            local seen_ids = {}
            for _, obj_id in ipairs(room.contents or {}) do
                if not seen_ids[obj_id] and not embedded[obj_id] then
                    seen_ids[obj_id] = true
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
            local sky = room and room.sky_visible
            local desc = time_of_day_desc(hour, sky)
            if desc then
                parts[#parts + 1] = desc .. " It is " .. format_time(hour, minute) .. "."
            else
                parts[#parts + 1] = "It is " .. format_time(hour, minute) .. "."
            end

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
            -- Issue #100: Gate "look in/inside" for simple containers
            if (prep == "in" or prep == "inside")
                and (check_obj.container or check_obj.is_container) then
                if not container_contents_accessible(check_obj, "visual") then
                    local cname = (check_obj.name or "that"):gsub("^a ", "the "):gsub("^an ", "the ")
                    print(cname:sub(1,1):upper() .. cname:sub(2) .. " is closed.")
                    return
                end
                if check_obj.contents and #check_obj.contents > 0 then
                    local items = {}
                    for _, id in ipairs(check_obj.contents) do
                        local item = ctx.registry:get(id)
                        items[#items + 1] = item and item.name or id
                    end
                    print("Inside you see:")
                    for _, item_name in ipairs(items) do
                        print("  " .. item_name)
                    end
                else
                    print("There is nothing inside " .. (check_obj.name or "that") .. ".")
                end
                return
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
            -- Bug #181: delegate to examine dark path instead of generic error
            handlers["examine"](ctx, noun)
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
                -- Bug #181: include object name so fuzzy-matched items are identifiable
                print("It's too dark to see " .. (obj.name or "it") .. ", but you feel: " .. feel_text)
            elseif obj.touch_description then
                print("It's too dark to see " .. (obj.name or "it") .. ", but you feel: " .. obj.touch_description)
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
                    -- Issue #100: Explicit "closed" message for closed containers
                    if (cobj.container or cobj.is_container)
                        and not container_contents_accessible(cobj, "tactile") then
                        local cname = (cobj.name or "that"):gsub("^a ", "the "):gsub("^an ", "the ")
                        print(cname:sub(1,1):upper() .. cname:sub(2) .. " is closed.")
                    else
                        print("You can't feel inside " .. (cobj.name or "that") .. ".")
                    end
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
                elseif (cobj.container or cobj.is_container)
                    and not container_contents_accessible(cobj, "tactile") then
                    local cname = (cobj.name or "that"):gsub("^a ", "the "):gsub("^an ", "the ")
                    print(cname:sub(1,1):upper() .. cname:sub(2) .. " is closed.")
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
            -- Issue #100: Gate search on closed simple containers
            if not scope_obj.surfaces
                and (scope_obj.container or scope_obj.is_container)
                and not container_contents_accessible(scope_obj, "tactile") then
                local cname = (scope_obj.name or "that"):gsub("^a ", "the "):gsub("^an ", "the ")
                print(cname:sub(1,1):upper() .. cname:sub(2) .. " is closed.")
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
            -- Issue #100: Gate search on closed simple containers
            if not obj.surfaces
                and (obj.container or obj.is_container)
                and not container_contents_accessible(obj, "tactile") then
                local cname = (obj.name or "that"):gsub("^a ", "the "):gsub("^an ", "the ")
                print(cname:sub(1,1):upper() .. cname:sub(2) .. " is closed.")
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

        if obj.edible then
            show_hint(ctx, "eat", "If it's edible, you can eat it outright with 'eat [item]'.")
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
end

return M
