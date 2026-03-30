-- engine/verbs/crafting.lua
-- Retains: sew/stitch/mend handlers.
-- Write/inscribe moved to cooking.lua; put/place moved to placement.lua (Phase 3 WAVE-0).
-- WAVE-4: craft/make/create handlers (recipe-ID dispatch).
local H = require("engine.verbs.helpers")

local _hobj = H._hobj
local find_visible = H.find_visible
local find_in_inventory = H.find_in_inventory
local find_tool_in_inventory = H.find_tool_in_inventory
local provides_capability = H.provides_capability
local consume_tool_charge = H.consume_tool_charge
local remove_from_location = H.remove_from_location
local spawn_objects = H.spawn_objects
local has_some_light = H.has_some_light

local M = {}

---------------------------------------------------------------------------
-- Recipe table — Tier 1 recipe-ID dispatch (Phase 4 WAVE-4)
-- Player types `craft silk-rope` — noun IS the recipe ID.
-- `craft X from Y` syntax deferred to Phase 5.
---------------------------------------------------------------------------
local crafting_recipes = {
    ["silk-rope"] = {
        ingredients = { { id = "silk-bundle", quantity = 2 } },
        requires_tool = nil,
        result = { id = "silk-rope", quantity = 1 },
        narration = "You twist the silk bundles together into a strong, lightweight rope.",
    },
    ["silk-bandage"] = {
        ingredients = { { id = "silk-bundle", quantity = 1 } },
        requires_tool = nil,
        result = { id = "silk-bandage", quantity = 2 },
        narration = "You tear the silk into strips suitable for bandaging wounds.",
    },
}

function M.register(handlers)
    -- Delegate write/inscribe to cooking module
    local cooking = require("engine.verbs.cooking")
    cooking.register(handlers)

    -- Delegate put/place to placement module
    local placement = require("engine.verbs.placement")
    placement.register(handlers)

    -- Delegate butcher/carve/skin/fillet to butchery module
    local butchery = require("engine.verbs.butchery")
    butchery.register(handlers)

    ---------------------------------------------------------------------------
    -- CRAFT / MAKE / CREATE — recipe-ID dispatch (WAVE-4)
    -- Player types `craft silk-rope`. Noun = recipe ID from crafting_recipes.
    ---------------------------------------------------------------------------
    handlers["craft"] = function(ctx, noun)
        if noun == "" then
            print("Craft what? (Try: craft silk-rope)")
            return
        end

        local recipe_id = noun:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")

        local recipe = crafting_recipes[recipe_id]
        if not recipe then
            print("You don't know how to craft that.")
            return
        end

        -- Check tool requirement
        if recipe.requires_tool then
            local tool = find_tool_in_inventory(ctx, recipe.requires_tool)
            if not tool then
                print("You need the right tool to craft " .. recipe_id .. ".")
                return
            end
        end

        -- Gather ingredients from inventory
        local consumed = {}
        for _, ingredient in ipairs(recipe.ingredients) do
            local remaining = ingredient.quantity
            for _ = 1, ingredient.quantity do
                local found = nil
                -- Search hands
                for i = 1, 2 do
                    local hand = ctx.player.hands[i]
                    if hand then
                        local obj = _hobj(hand, ctx.registry)
                        if obj and obj.id:find(ingredient.id, 1, true) == 1 then
                            local dominated = false
                            for _, c in ipairs(consumed) do
                                if c == obj then dominated = true; break end
                            end
                            if not dominated then found = obj; break end
                        end
                        -- Check bag contents
                        if not found and obj and obj.container and obj.contents then
                            for _, item_id in ipairs(obj.contents) do
                                local item = ctx.registry:get(item_id)
                                if item and item.id:find(ingredient.id, 1, true) == 1 then
                                    local dominated = false
                                    for _, c in ipairs(consumed) do
                                        if c == item then dominated = true; break end
                                    end
                                    if not dominated then found = item; break end
                                end
                            end
                        end
                    end
                end
                -- Search room contents
                if not found then
                    for _, obj_id in ipairs(ctx.current_room.contents or {}) do
                        local obj = ctx.registry:get(obj_id)
                        if obj and obj.id:find(ingredient.id, 1, true) == 1 then
                            local dominated = false
                            for _, c in ipairs(consumed) do
                                if c == obj then dominated = true; break end
                            end
                            if not dominated then found = obj; break end
                        end
                    end
                end
                if found then
                    consumed[#consumed + 1] = found
                    remaining = remaining - 1
                else
                    break
                end
            end
            if remaining > 0 then
                print("You don't have enough " .. ingredient.id .. " to craft " .. recipe_id .. ".")
                return
            end
        end

        -- Consume ingredients
        for _, obj in ipairs(consumed) do
            remove_from_location(ctx, obj)
            ctx.registry:remove(obj.id)
        end

        -- Spawn results into player hands (fall back to room if full)
        local spawns = {}
        for _ = 1, recipe.result.quantity do
            spawns[#spawns + 1] = recipe.result.id
        end

        local placed_any_in_hand = false
        for _, spawn_id in ipairs(spawns) do
            local source = ctx.object_sources and ctx.object_sources[spawn_id]
            local spawn_obj
            if source then
                spawn_obj = ctx.loader.load_source(source)
                if spawn_obj then
                    spawn_obj = ctx.loader.resolve_template(spawn_obj, ctx.templates)
                end
            end
            if not spawn_obj then
                spawn_obj = {
                    id = spawn_id,
                    name = spawn_id,
                    portable = true,
                    on_feel = "A crafted " .. spawn_id .. ".",
                }
            end

            -- Deduplicate ID if already registered
            local actual_id = spawn_id
            if ctx.registry:get(spawn_id) then
                local n = 2
                while ctx.registry:get(spawn_id .. "-" .. n) do n = n + 1 end
                actual_id = spawn_id .. "-" .. n
            end
            spawn_obj.id = actual_id
            ctx.registry:register(actual_id, spawn_obj)

            -- Place in hand if possible, otherwise drop to room
            local slot = nil
            if ctx.player.hands[1] == nil then slot = 1
            elseif ctx.player.hands[2] == nil then slot = 2 end

            if slot then
                spawn_obj.location = "player"
                ctx.player.hands[slot] = spawn_obj
                placed_any_in_hand = true
            else
                local room = ctx.current_room
                spawn_obj.location = room.id
                room.contents[#room.contents + 1] = actual_id
            end
        end

        print(recipe.narration)
    end

    handlers["make"] = handlers["craft"]
    handlers["create"] = handlers["craft"]

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
                print("You don't have " .. tool_word .. ".")
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
                    if obj and obj.id:find(need_id, 1, true) == 1 and not available[hand_id] then
                        available[hand_id] = obj
                        consumed_objs[#consumed_objs + 1] = obj
                        found = true
                        break
                    end
                    -- Check bag contents
                    if not found and obj and obj.container and obj.contents then
                        for _, item_id in ipairs(obj.contents) do
                            local item = ctx.registry:get(item_id)
                            if item and item.id:find(need_id, 1, true) == 1 and not available[item_id] then
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
                    if obj and obj.id:find(need_id, 1, true) == 1 and not available[obj_id] then
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
end

return M
