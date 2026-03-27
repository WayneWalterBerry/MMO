-- engine/verbs/placement.lua
-- Put/place handler, split from crafting.lua in Phase 3 WAVE-0.
--
-- Ownership: Bart (Architect)

local H = require("engine.verbs.helpers")

local context_window = H.context_window
local fuzzy = H.fuzzy

local _hid = H._hid
local _hobj = H._hobj
local matches_keyword = H.matches_keyword
local find_visible = H.find_visible
local reattach_part = H.reattach_part

local M = {}

function M.register(handlers)
    ---------------------------------------------------------------------------
    -- PUT X IN/ON Y -- supports furniture surfaces AND held/worn bags
    ---------------------------------------------------------------------------
    handlers["put"] = function(ctx, noun)
        if noun == "" then
            print("Put what where? (Try: put <item> in/on <target>)")
            return
        end

        -- "put on X" → wear X (intercepted before container logic)
        local wear_target = noun:match("^on%s+(.+)")
        if wear_target then
            -- Check if it's actually "put X on Y" by seeing if there's an "on" in the middle
            -- "put on cloak" vs "put sword on table" — if noun starts with "on ", it's wear
            handlers["wear"](ctx, wear_target)
            return
        end

        -- #82: Parse "X in/on/under/underneath/beneath/inside Y"
        local item_word, prep, target_word
        item_word, target_word = noun:match("^(.+)%s+in%s+(.+)$")
        if item_word then
            prep = "in"
        else
            item_word, target_word = noun:match("^(.+)%s+on%s+(.+)$")
            if item_word then
                prep = "on"
            end
        end
        if not item_word then
            item_word, target_word = noun:match("^(.+)%s+underneath%s+(.+)$")
            if item_word then
                prep = "under"
            end
        end
        if not item_word then
            item_word, target_word = noun:match("^(.+)%s+beneath%s+(.+)$")
            if item_word then
                prep = "under"
            end
        end
        if not item_word then
            item_word, target_word = noun:match("^(.+)%s+under%s+(.+)$")
            if item_word then
                prep = "under"
            end
        end
        if not item_word then
            item_word, target_word = noun:match("^(.+)%s+inside%s+(.+)$")
            if item_word then
                prep = "in"
            end
        end

        if not item_word or not target_word then
            print("Put what where? (Try: put <item> in/on <target>)")
            return
        end

        -- "put X on {body_part}" → route to wear handler
        if prep == "on" then
            local body_parts = {
                head = true, back = true, hands = true, feet = true,
                torso = true, body = true, arms = true, legs = true,
                wrist = true, finger = true, neck = true, waist = true,
                face = true, shoulders = true, chest = true,
            }
            local tw = target_word:lower():gsub("^my%s+", "")
            if body_parts[tw] then
                handlers["wear"](ctx, item_word .. " on " .. tw)
                return
            end
        end

        -- #81: Resolve pronouns ("it", "that", etc.) via context window
        local resolved_item_word = item_word
        if context_window then
            local item_kw = item_word:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            local cw_item = context_window.resolve(item_kw)
            if cw_item then
                resolved_item_word = cw_item.id
            end
        end

        -- Find item -- must be in hands
        local item = nil
        local item_hand = nil
        local kw = resolved_item_word:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local candidate = _hobj(hand, ctx.registry)
                if candidate and matches_keyword(candidate, kw) then
                    item = candidate
                    item_hand = i
                    break
                end
            end
        end

        -- #267: Fuzzy fallback when exact keyword match fails on hands
        if not item and fuzzy then
            local parsed = fuzzy.parse_noun_phrase(kw)
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local candidate = _hobj(hand, ctx.registry)
                    if candidate then
                        local score = fuzzy.score_object(candidate, parsed)
                        if score > 0 then
                            item = candidate
                            item_hand = i
                            break
                        end
                    end
                end
            end
        end

        if not item then
            local found = find_visible(ctx, item_word)
            if found then
                -- #267: Check if the item is already inside the target container
                local target_check = find_visible(ctx, target_word)
                if target_check and target_check.contents then
                    for _, cid in ipairs(target_check.contents) do
                        if cid == found.id then
                            print((found.name or item_word) .. " is already in "
                                .. (target_check.name or target_word) .. ".")
                            return
                        end
                    end
                end
                print("You need to be holding " .. (found.name or item_word)
                    .. " to put it somewhere.")
                return
            end
            print("You don't have " .. item_word .. ".")
            return
        end

        -- Find target -- could be a held bag, worn bag, or room object
        local target = find_visible(ctx, target_word)
        if not target then
            -- #109: "put X on Y" where Y isn't a room object but player has
            -- injuries → delegate to apply handler (e.g. "put salve on wound")
            if prep == "on" and ctx.player.injuries and #ctx.player.injuries > 0 then
                local apply_handler = handlers["apply"]
                if apply_handler then
                    ctx.apply_target = target_word
                    apply_handler(ctx, item_word)
                    return
                end
            end
            print("You don't see " .. target_word .. " here.")
            return
        end

        -- Reattachment check: if item has reattach_to and target matches
        if item.reattach_to and target.parts and item.reattach_to == target.id then
            local ok, msg = reattach_part(ctx, item, target)
            if ok then
                -- Clear hand slots (handle two-handed items)
                for i = 1, 2 do
                    if _hid(ctx.player.hands[i]) == item.id then
                        ctx.player.hands[i] = nil
                    end
                end
                print(msg)
            else
                print(msg or "You can't put that back.")
            end
            return
        end

        -- If target is a held/worn bag (simple container, no surfaces)
        if target.container and not target.surfaces then
            local ok, reason = ctx.containment.can_contain(
                item, target, nil, ctx.registry)
            if not ok then
                print(reason or "You can't put that there.")
                return
            end
            ctx.player.hands[item_hand] = nil
            target.contents = target.contents or {}
            target.contents[#target.contents + 1] = item.id
            item.location = target.id
            local narration_prep = target.container_preposition or prep
            print("You put " .. (item.name or item.id) ..
                " " .. narration_prep .. " " .. (target.name or target.id) .. ".")
            return
        end

        -- Determine surface name (furniture)
        local surface_name = nil
        if target.surfaces then
            if prep == "on" and target.surfaces.top then
                surface_name = "top"
            elseif prep == "in" and target.surfaces.inside then
                surface_name = "inside"
            elseif prep == "under" and target.surfaces.underneath then
                surface_name = "underneath"
            elseif prep == "on" then
                for sname, _ in pairs(target.surfaces) do
                    surface_name = sname
                    break
                end
            elseif prep == "in" then
                -- #80: no inside surface -> reject (solid furniture has no inside)
                print("You can't put anything inside " .. (target.name or target.id) .. ".")
                return
            elseif prep == "under" then
                for sname, _ in pairs(target.surfaces) do
                    surface_name = sname
                    break
                end
            end
        end

        -- For "under" without surfaces, use target.underneath as a flat container
        if prep == "under" and not surface_name and not target.surfaces then
            target.underneath = target.underneath or {}
            ctx.player.hands[item_hand] = nil
            if item.hands_required and item.hands_required >= 2 then
                for i = 1, 2 do
                    if _hid(ctx.player.hands[i]) == item.id then
                        ctx.player.hands[i] = nil
                    end
                end
            end
            target.underneath[#target.underneath + 1] = item.id
            item.location = target.id
            print("You put " .. (item.name or item.id) ..
                " " .. prep .. " " .. (target.name or target.id) .. ".")
            return
        end

        -- Validate with containment engine
        local ok, reason = ctx.containment.can_contain(
            item, target, surface_name, ctx.registry)
        if not ok then
            -- #222: If surface is full but item has reattach_to, check if the
            -- reattach target is on this surface and redirect to reattach.
            if item.reattach_to and surface_name and target.surfaces
                    and target.surfaces[surface_name] then
                local zone = target.surfaces[surface_name]
                for _, content_id in ipairs(zone.contents or {}) do
                    local content_obj = ctx.registry:get(content_id)
                    if content_obj and content_obj.id == item.reattach_to
                            and content_obj.parts then
                        local reattach_ok, reattach_msg = reattach_part(ctx, item, content_obj)
                        if reattach_ok then
                            ctx.player.hands[item_hand] = nil
                            if item.hands_required and item.hands_required >= 2 then
                                for i = 1, 2 do
                                    if _hid(ctx.player.hands[i]) == item.id then
                                        ctx.player.hands[i] = nil
                                    end
                                end
                            end
                            print(reattach_msg)
                            return
                        end
                    end
                end
            end
            print(reason or "You can't put that there.")
            return
        end

        -- Move
        ctx.player.hands[item_hand] = nil
        -- Clear both hands for two-handed items
        if item.hands_required and item.hands_required >= 2 then
            for i = 1, 2 do
                if _hid(ctx.player.hands[i]) == item.id then
                    ctx.player.hands[i] = nil
                end
            end
        end

        if surface_name and target.surfaces and target.surfaces[surface_name] then
            local zone = target.surfaces[surface_name]
            zone.contents = zone.contents or {}
            zone.contents[#zone.contents + 1] = item.id
        elseif target.contents then
            target.contents[#target.contents + 1] = item.id
        else
            target.contents = { item.id }
        end

        item.location = target.id

        print("You put " .. (item.name or item.id) ..
            " " .. prep .. " " .. (target.name or target.id) .. ".")
    end

    handlers["place"] = handlers["put"]
end

return M
