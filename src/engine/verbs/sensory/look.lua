-- Auto-split from sensory.lua
local H = require("engine.verbs.helpers")

local preprocess = H.preprocess
local find_visible = H.find_visible
local find_in_inventory = H.find_in_inventory
local container_contents_accessible = H.container_contents_accessible
local get_all_carried_ids = H.get_all_carried_ids
local get_light_level = H.get_light_level
local has_some_light = H.has_some_light
local vision_blocked_by_worn = H.vision_blocked_by_worn
local get_game_time = H.get_game_time
local format_time = H.format_time
local time_of_day_desc = H.time_of_day_desc
local err_not_found = H.err_not_found

local M = {}

function M.register(handlers)
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

            local l_ok, light = pcall(get_light_level, ctx)
            if not l_ok then light = "dark" end
            if light == "dark" then
                print("**" .. (ctx.current_room.name or "Unknown room") .. "**")
                print("It is too dark to see. You need a light source. Try 'feel' to explore by touch.")
                local t_ok, hour, minute = pcall(get_game_time, ctx)
                if t_ok then
                    local sky = ctx.current_room and ctx.current_room.sky_visible
                    local desc = time_of_day_desc(hour, sky)
                    if desc then
                        print("")
                        print(desc .. " It is " .. format_time(hour, minute) .. ".")
                    else
                        print("")
                        print("It is " .. format_time(hour, minute) .. ".")
                    end
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
            -- BUG-050: Skip objects listed in room.embedded_presences ΓÇö their
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
            -- Build set of carried object IDs so held items don't appear in room
            local carried = {}
            if ctx.player and ctx.player.hands then
                local ok, all_ids = pcall(get_all_carried_ids, ctx)
                if ok then
                    for _, cid in ipairs(all_ids) do
                        carried[cid] = true
                    end
                end
            end
            for _, obj_id in ipairs(room.contents or {}) do
                if not seen_ids[obj_id] and not embedded[obj_id] and not carried[obj_id] then
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

            -- Creature presences (WAVE-3: NPC room presence)
            local cr_ok, cr_mod = pcall(require, "engine.creatures")
            if cr_ok and cr_mod then
                local room_creatures = cr_mod.get_creatures_in_room(ctx.registry, room.id)
                local creature_presences = {}
                for _, c in ipairs(room_creatures) do
                    if not c.hidden then
                        local st = c.states and c.states[c._state]
                        local text = st and st.room_presence
                        if not text then
                            text = "There is " .. (c.name or c.id) .. " here."
                        end
                        if not seen_presences[text] then
                            seen_presences[text] = true
                            creature_presences[#creature_presences + 1] = text
                        end
                    end
                end
                if #creature_presences > 0 then
                    parts[#parts + 1] = table.concat(creature_presences, " ")
                end
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

            -- Time (pcall-guarded for headless/test contexts without game_start_time)
            local t_ok, hour, minute = pcall(get_game_time, ctx)
            if t_ok then
                local sky = room and room.sky_visible
                local desc = time_of_day_desc(hour, sky)
                if desc then
                    parts[#parts + 1] = desc .. " It is " .. format_time(hour, minute) .. "."
                else
                    parts[#parts + 1] = "It is " .. format_time(hour, minute) .. "."
                end
            end

            print("**" .. (room.name or "Unnamed room") .. "**")
            print("")
            print(table.concat(parts, "\n\n"))
            return
        end

        -- "look at X" ΓåÆ examine
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
                err_not_found(ctx)
                return
            end
            -- Mirror integration: is_mirror flag ΓåÆ appearance subsystem
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

        -- "look in/under/on X" ΓåÆ inspect surface
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

        -- "look X" ΓåÆ examine (shorthand for "look at X")
        -- #342: Strip leading articles for consistency with "look at X" path
        local look_target = noun:gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        local blocked2 = vision_blocked_by_worn(ctx)
        if blocked2 then
            print("You can't see anything with your vision blocked.")
            return
        end
        if not has_some_light(ctx) then
            -- Bug #181: delegate to examine dark path instead of generic error
            handlers["examine"](ctx, look_target)
            return
        end
        local obj = find_visible(ctx, look_target)
        if not obj then
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

        -- Check if object is readable (categories contains "readable" or "writable")
        -- BUG-155: Writable objects (blank paper) should be readable, not rejected
        local is_readable = false
        if obj.categories and type(obj.categories) == "table" then
            for _, cat in ipairs(obj.categories) do
                if cat == "readable" or cat == "writable" then is_readable = true; break end
            end
        end
        if not is_readable and obj.writable then is_readable = true end

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
end


return M
