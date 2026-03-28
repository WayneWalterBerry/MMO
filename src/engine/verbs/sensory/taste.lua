-- Auto-split from sensory.lua
local H = require("engine.verbs.helpers")

local effects = H.effects
local find_visible = H.find_visible
local show_hint = H.show_hint

local M = {}

function M.register(handlers)
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
end


return M
