-- Auto-split from sensory.lua
local H = require("engine.verbs.helpers")

local find_visible = H.find_visible
local container_contents_accessible = H.container_contents_accessible

local M = {}

function M.register(handlers)
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
                -- BUG-163: Adapt message to light conditions
                local is_lit = H.has_some_light and H.has_some_light(ctx)
                if is_lit then
                    print("You reach out, feeling around you...")
                else
                    print("You reach out blindly, feeling around you...")
                end
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
        -- Bare "feel inside" / "feel in" ΓåÆ use last-interacted container
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
end


return M
