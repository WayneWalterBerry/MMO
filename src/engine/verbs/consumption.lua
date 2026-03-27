-- engine/verbs/consumption.lua
-- Eat/drink handlers, split from survival.lua in Phase 3 WAVE-0.
--
-- Ownership: Bart (Architect)

local H = require("engine.verbs.helpers")

local fsm_mod = H.fsm_mod
local effects = H.effects

local err_not_found = H.err_not_found
local find_visible = H.find_visible
local find_in_inventory = H.find_in_inventory
local find_tool_in_inventory = H.find_tool_in_inventory
local provides_capability = H.provides_capability
local find_visible_tool = H.find_visible_tool
local remove_from_location = H.remove_from_location
local show_hint = H.show_hint

local M = {}

function M.register(handlers)
    local inj_ok, injury_mod = pcall(require, "engine.injuries")

    ---------------------------------------------------------------------------
    -- EAT -- consume food items (WAVE-5: food.edible + nutrition + restrictions)
    ---------------------------------------------------------------------------
    handlers["eat"] = function(ctx, noun)
        if noun == "" then
            print("Eat what? Try 'eat [item]' if you find something edible.")
            return
        end

        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            err_not_found(ctx)
            return
        end

        -- WAVE-5 food objects require holding; legacy edible objects are grandfathered
        if obj.food and not find_in_inventory(ctx, noun) then
            print("You'll need to pick that up first.")
            return
        end

        -- Check edibility: food.edible (WAVE-5 food table) or legacy obj.edible
        local food = obj.food
        local is_edible = (food and food.edible) or obj.edible
        if not is_edible then
            print("You can't eat " .. (obj.name or "that") .. ".")
            return
        end

        -- Check injury restrictions (e.g. jaw injuries could block eating)
        if inj_ok and injury_mod then
            local restricts = injury_mod.get_restrictions(ctx.player)
            if restricts.eat then
                print("Your injuries prevent you from eating.")
                return
            end
        end

        -- Spoiled food warning
        if obj._state == "spoiled" then
            print("This food looks spoiled... but you eat it anyway.")
        else
            print("You eat " .. (obj.name or "it") .. ".")
        end

        -- Emit on_taste sensory text
        if obj.on_taste then
            print(obj.on_taste)
        end

        -- Apply nutrition to player
        if food and food.nutrition then
            ctx.player.nutrition = (ctx.player.nutrition or 0) + food.nutrition
        end

        if obj.on_eat_message then
            print(obj.on_eat_message)
        end
        -- on_eat hook: fire callback if object declares one
        if obj.on_eat and type(obj.on_eat) == "function" then
            obj.on_eat(obj, ctx)
        end
        -- event_output: one-shot flavor text for on_eat
        if obj.event_output and obj.event_output["on_eat"] then
            print(obj.event_output["on_eat"])
            obj.event_output["on_eat"] = nil
        end
        show_hint(ctx, "eat", "Careful what you eat — not everything is safe to consume.")
        remove_from_location(ctx, obj)
        ctx.registry:remove(obj.id)
    end

    handlers["consume"] = handlers["eat"]
    handlers["devour"] = handlers["eat"]

    ---------------------------------------------------------------------------
    -- DRINK -- consume a liquid (FSM or generic, WAVE-5: restriction check)
    ---------------------------------------------------------------------------
    handlers["drink"] = function(ctx, noun)
        if noun == "" then print("Drink what?") return end

        -- Check injury restrictions before object resolution (rabies hydrophobia)
        if inj_ok and injury_mod then
            local restricts = injury_mod.get_restrictions(ctx.player)
            if restricts.drink then
                print("You can't bring yourself to drink — the mere thought of water fills you with terror.")
                return
            end
        end

        -- Strip "from" preposition: "drink from bottle" → "bottle"
        local target = noun:match("^from%s+(.+)") or noun

        local obj = find_in_inventory(ctx, target)
        if not obj then
            local visible = find_visible(ctx, target)
            if visible then
                print("You'll need to pick that up first.")
            else
                err_not_found(ctx)
            end
            return
        end

        -- FSM path: check for "drink" transition
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            local target_trans
            for _, t in ipairs(transitions) do
                if t.verb == "drink" then target_trans = t; break end
                if t.aliases then
                    for _, alias in ipairs(t.aliases) do
                        if alias == "drink" then target_trans = t; break end
                    end
                    if target_trans then break end
                end
            end
            if target_trans then
                local trans = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {}, "drink")
                if trans then
                    print(trans.message or ("You drink from " .. (obj.name or obj.id) .. "."))
                    if trans.effect then
                        effects.process(trans.effect, {
                            player = ctx.player,
                            registry = ctx.registry,
                            source = obj,
                            source_id = obj.id,
                            game_over = false,
                        })
                        -- Propagate game_over back to the main context
                        local eff_ctx = { player = ctx.player }
                        if inj_ok and injury_mod then
                            local health = injury_mod.compute_health(ctx.player)
                            if health <= 0 then
                                ctx.game_over = true
                            end
                        end
                    end
                    -- on_drink hook: fire callback if object declares one
                    if obj.on_drink and type(obj.on_drink) == "function" then
                        obj.on_drink(obj, ctx)
                    end
                    -- event_output: one-shot flavor text for on_drink
                    if obj.event_output and obj.event_output["on_drink"] then
                        print(obj.event_output["on_drink"])
                        obj.event_output["on_drink"] = nil
                    end
                else
                end
                return
            end
        end

        -- Food-as-drink path (WAVE-5): objects with food.drinkable
        if obj.food and obj.food.drinkable then
            if obj.on_taste then
                print(obj.on_taste)
            end
            if obj.food.nutrition then
                ctx.player.nutrition = (ctx.player.nutrition or 0) + obj.food.nutrition
            end
            print("You drink " .. (obj.name or "it") .. ".")
            remove_from_location(ctx, obj)
            ctx.registry:remove(obj.id)
            return
        end

        if obj.on_drink_reject then
            print(obj.on_drink_reject)
        else
            print("You can't drink " .. (obj.name or "that") .. ".")
        end
    end

    handlers["quaff"] = handlers["drink"]
    handlers["sip"] = handlers["drink"]
end

return M
