-- engine/verbs/crafting.lua
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
local add_article = H.add_article
local add_article = H.add_article

local M = {}

function M.register(handlers)
    handlers["write"] = function(ctx, noun)
        if noun == "" then
            print("Write what? (Try: write <text> on <paper> with <pen>)")
            return
        end

        if not has_some_light(ctx) then
            print("It is too dark to see what you're writing.")
            return
        end

        -- Parse: "write {text} on {target} with {tool}"
        local text, target_word, tool_word
        text, target_word, tool_word = noun:match("^(.+)%s+on%s+(.+)%s+with%s+(.+)$")
        if not text then
            -- "write on {target} with {tool}" (no text)
            target_word, tool_word = noun:match("^on%s+(.+)%s+with%s+(.+)$")
        end
        if not target_word then
            -- "write {text} on {target}" (no tool specified)
            text, target_word = noun:match("^(.+)%s+on%s+(.+)$")
        end
        if not target_word then
            -- "write on {target}" (no text, no tool)
            target_word = noun:match("^on%s+(.+)$")
        end

        if not target_word then
            print("Write on what? (Try: write <text> on <paper>)")
            return
        end

        -- Find target -- check visible objects and inventory
        local target = find_visible(ctx, target_word)
        if not target then
            target = find_in_inventory(ctx, target_word)
        end
        if not target then
            err_not_found(ctx)
            return
        end

        if not target.writable then
            print("You can't write on " .. (target.name or "that") .. ".")
            return
        end

        if not text or text == "" then
            local prompt_text
            if context.ui and context.ui.is_enabled() then
                prompt_text = context.ui.prompt("What do you want to write? > ")
            else
                io.write("What do you want to write? > ")
                io.flush()
                prompt_text = io.read()
            end
            text = prompt_text
            if not text or text:match("^%s*$") then
                print("Never mind.")
                return
            end
            text = text:match("^%s*(.-)%s*$")
        end

        -- Find writing instrument
        local tool = nil
        if tool_word then
            tool = find_in_inventory(ctx, tool_word)
            if not tool then
                -- Check if they specified "blood"
                if tool_word:match("blood") and ctx.player.state and ctx.player.state.bloody then
                    tool = find_tool_in_inventory(ctx, "writing_instrument")
                    if tool and not tool._is_blood then tool = nil end
                end
                if not tool then
                    print("You don't have " .. add_article(tool_word) .. ".")
                    return
                end
            end
            if not provides_capability(tool, "writing_instrument") and not (tool._is_blood) then
                print("You can't write with " .. (tool.name or "that") .. ".")
                return
            end
        else
            -- Auto-find writing instrument in inventory
            tool = find_tool_in_inventory(ctx, "writing_instrument")
            if not tool then
                local mut_data = find_mutation(target, "write")
                print(mut_data and mut_data.fail_message or "You have nothing to write with.")
                return
            end
        end

        -- Print tool use message
        if tool.on_tool_use and tool.on_tool_use.use_message then
            print(tool.on_tool_use.use_message)
        end

        -- Build the new written text (append if paper already has writing)
        local written = text
        if target.written_text then
            written = target.written_text .. " " .. text
        end

        -- DYNAMIC MUTATION: generate new Lua source with written text baked in.
        -- This is runtime code generation -- the paper's definition is rewritten
        -- to include the player's words as part of the object's identity.
        local esc_written = string.format("%q", written)
        local new_source = string.format(
            "return {\n"
         .. "    id = %q,\n"
         .. "    name = \"a sheet of paper with writing\",\n"
         .. "    keywords = {\"paper\", \"sheet\", \"page\", \"written paper\", \"note\", \"parchment\"},\n"
         .. "    description = \"A sheet of cream-coloured paper. Words have been written across it in careful strokes.\",\n"
         .. "    writable = true,\n"
         .. "    written_text = %s,\n"
         .. "    size = 1,\n"
         .. "    weight = 0.1,\n"
         .. "    categories = {\"small\", \"writable\", \"flammable\"},\n"
         .. "    portable = true,\n"
         .. "    location = nil,\n"
         .. "    on_look = function(self)\n"
         .. "        if self.written_text then\n"
         .. "            return \"A sheet of paper with writing on it. It reads:\\n\\n  \\\"\" .. self.written_text .. \"\\\"\"\n"
         .. "        end\n"
         .. "        return self.description\n"
         .. "    end,\n"
         .. "    mutations = {\n"
         .. "        write = {\n"
         .. "            requires_tool = \"writing_instrument\",\n"
         .. "            dynamic = true,\n"
         .. "            mutator = \"write_on_surface\",\n"
         .. "            message = \"You add more words to the paper.\",\n"
         .. "            fail_message = \"You have nothing to write with.\",\n"
         .. "        },\n"
         .. "    },\n"
         .. "}\n",
            target.id, esc_written)

        -- Perform the mutation
        local had_writing = target.written_text ~= nil
        local new_obj, err = ctx.mutation.mutate(
            ctx.registry, ctx.loader, target.id, new_source, ctx.templates)
        if not new_obj then
            print("Something goes wrong -- the ink smears illegibly.")
            return
        end

        -- Store new source for future mutations
        ctx.object_sources[target.id] = new_source

        -- Consume tool charge (if applicable)
        consume_tool_charge(ctx, tool)

        -- Success message
        if had_writing then
            print("You add more words to the paper.")
        else
            local mut_data = find_mutation(target, "write")
            print(mut_data and mut_data.message
                or "You write carefully on the paper. The words appear in steady strokes.")
        end
    end

    handlers["inscribe"] = handlers["write"]
    ---------------------------------------------------------------------------
    -- SEW {material} WITH {tool} -- crafting verb (requires sewing skill)
    ---------------------------------------------------------------------------
    handlers["sew"] = function(ctx, noun)
        if noun == "" then
            print("Sew what? (Try: sew cloth with needle)")
            return
        end

        if not has_some_light(ctx) then
            print("It is too dark to sew anything. You'd stab yourself.")
            return
        end

        -- Skill gate: must know sewing
        if not ctx.player.skills or not ctx.player.skills.sewing then
            print("You don't know how to sew. Perhaps you could find instructions somewhere.")
            return
        end

        -- Parse: "sew X with Y" or just "sew X"
        local material_word, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
        if not material_word then material_word = noun end

        -- Strip articles
        material_word = material_word:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        if tool_word then
            tool_word = tool_word:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        end

        -- Find the material (must be visible or in inventory)
        local material = find_in_inventory(ctx, material_word)
        if not material then
            material = find_visible(ctx, material_word)
        end
        if not material then
            print("You don't see any " .. material_word .. " to sew.")
            return
        end

        -- Check if material has crafting.sew recipe
        if not material.crafting or not material.crafting.sew then
            print("You can't sew " .. (material.name or "that") .. ".")
            return
        end

        local recipe = material.crafting.sew

        -- Find the sewing tool (needle)
        local tool = nil
        if tool_word then
            tool = find_in_inventory(ctx, tool_word)
            if not tool then
                print("You don't have " .. add_article(tool_word) .. ".")
                return
            end
            if not provides_capability(tool, recipe.requires_tool or "sewing_tool") then
                print("You can't sew with " .. (tool.name or "that") .. ".")
                return
            end
        else
            tool = find_tool_in_inventory(ctx, recipe.requires_tool or "sewing_tool")
            if not tool then
                print(recipe.fail_message_no_tool or "You have nothing to sew with.")
                return
            end
        end

        -- Check for sewing material (thread)
        local thread = find_tool_in_inventory(ctx, "sewing_material")
        if not thread then
            print("You need thread to sew with.")
            return
        end

        -- Check we have enough materials (recipe.consumes lists required material IDs)
        local consumes = recipe.consumes or {material.id}
        local consumed_objs = {}
        local available = {}

        -- Build list of all reachable objects matching consumed IDs
        for _, need_id in ipairs(consumes) do
            local found = false
            -- Search inventory
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local obj = _hobj(hand, ctx.registry)
                    if obj and obj.id:match("^" .. need_id) and not available[hand_id] then
                        available[hand_id] = obj
                        consumed_objs[#consumed_objs + 1] = obj
                        found = true
                        break
                    end
                    -- Check bag contents
                    if not found and obj and obj.container and obj.contents then
                        for _, item_id in ipairs(obj.contents) do
                            local item = ctx.registry:get(item_id)
                            if item and item.id:match("^" .. need_id) and not available[item_id] then
                                available[item_id] = item
                                consumed_objs[#consumed_objs + 1] = item
                                found = true
                                break
                            end
                        end
                    end
                end
                if found then break end
            end
            -- Search room if not found in inventory
            if not found then
                for _, obj_id in ipairs(ctx.current_room.contents or {}) do
                    local obj = ctx.registry:get(obj_id)
                    if obj and obj.id:match("^" .. need_id) and not available[obj_id] then
                        available[obj_id] = obj
                        consumed_objs[#consumed_objs + 1] = obj
                        found = true
                        break
                    end
                end
            end
            if not found then
                print("You don't have enough " .. need_id .. " to sew with.")
                return
            end
        end

        -- Print tool use message
        if tool.on_tool_use and tool.on_tool_use.use_message then
            print(tool.on_tool_use.use_message)
        end

        -- Consume materials
        for _, obj in ipairs(consumed_objs) do
            remove_from_location(ctx, obj)
            ctx.registry:remove(obj.id)
        end

        -- Spawn the product
        local product_id = recipe.becomes
        if product_id then
            spawn_objects(ctx, {product_id})
        end

        -- Consume tool charge if applicable
        consume_tool_charge(ctx, tool)

        -- Success message
        print(recipe.message or ("You sew the materials together."))
    end

    handlers["stitch"] = handlers["sew"]
    handlers["mend"] = handlers["sew"]

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

        if not item then
            local found = find_visible(ctx, item_word)
            if found then
                print("You need to be holding that to put it somewhere.")
                return
            end
            print("You don't have " .. add_article(item_word) .. ".")
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
