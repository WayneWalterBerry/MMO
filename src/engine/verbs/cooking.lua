-- engine/verbs/cooking.lua
-- Write handler (extracted from crafting.lua) + cook verb handler (WAVE-3).
-- Split from crafting.lua in Phase 3 WAVE-0.
--
-- Ownership: Smithers (UI Engineer) — cook verb; Bart (Architect) — write verb

local H = require("engine.verbs.helpers")

local err_not_found = H.err_not_found
local find_visible = H.find_visible
local find_in_inventory = H.find_in_inventory
local find_tool_in_inventory = H.find_tool_in_inventory
local provides_capability = H.provides_capability
local consume_tool_charge = H.consume_tool_charge
local find_visible_tool = H.find_visible_tool
local perform_mutation = H.perform_mutation
local find_mutation = H.find_mutation
local has_some_light = H.has_some_light
local show_hint = H.show_hint

local M = {}

function M.register(handlers)
    ---------------------------------------------------------------------------
    -- COOK {food} -- transforms raw food into cooked food via D-14 mutation
    -- Requires a fire_source tool in inventory or visible scope.
    -- Recipe declared on food object as obj.crafting.cook (Principle 8).
    ---------------------------------------------------------------------------
    handlers["cook"] = function(ctx, noun)
        if noun == "" then
            print("Cook what? Try 'cook [food]' near a fire source.")
            return
        end

        -- Find food in inventory first, then visible scope
        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            err_not_found(ctx)
            return
        end

        -- Must be holding it to cook
        if not find_in_inventory(ctx, noun) then
            print("You'll need to pick that up first.")
            return
        end

        -- Check crafting.cook recipe on the object
        if not obj.crafting or not obj.crafting.cook then
            print("You can't cook " .. (obj.name or "that") .. ".")
            return
        end

        local recipe = obj.crafting.cook

        -- Find fire_source: inventory first, then visible room objects
        local tool = find_tool_in_inventory(ctx, recipe.requires_tool or "fire_source")
        if not tool then
            tool = find_visible_tool(ctx, recipe.requires_tool or "fire_source")
        end
        if not tool then
            print(recipe.fail_message_no_tool or "You need a fire source to cook this.")
            return
        end

        -- Perform mutation: raw → cooked via recipe.becomes
        if not recipe.becomes then
            print("You hold it over the flames, but nothing useful happens.")
            return
        end

        if not perform_mutation(ctx, obj, recipe) then
            return
        end

        -- Consume tool charge on fire source if applicable
        consume_tool_charge(ctx, tool)

        -- Success
        print(recipe.message or ("You cook " .. (obj.name or "it") .. " over the flames."))
        show_hint(ctx, "cook", "Cooking raw meat makes it safe to eat and more nourishing.")
    end

    handlers["roast"] = handlers["cook"]
    handlers["bake"] = handlers["cook"]
    handlers["grill"] = handlers["cook"]
    ---------------------------------------------------------------------------
    -- WRITE {text} ON {target} WITH {tool} -- inscription verb
    ---------------------------------------------------------------------------
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
                    print("You don't have " .. tool_word .. ".")
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
            ctx.registry, ctx.loader, target.id, new_source, ctx.templates, ctx)
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
end

return M
