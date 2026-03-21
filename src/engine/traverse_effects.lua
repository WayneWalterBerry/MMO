-- engine/traverse_effects.lua
-- Extensible on_traverse exit-effect engine.
--
-- When a player moves through an exit, the engine checks for an optional
-- on_traverse table on that exit. If present, it dispatches to a registered
-- handler based on the effect's `type` field.
--
-- Ownership: Bart (Architect)
-- Decision: D-TRAVERSE001 — on_traverse exit-effect pattern
--
-- Usage in room metadata:
--   exits = {
--     up = {
--       target = "storage-cellar",
--       on_traverse = {
--         type = "wind_effect",
--         description = "A cold draft rushes up the stairway...",
--         extinguishes = { "candle" }
--       }
--     }
--   }

local traverse_effects = {}

-- Registry of effect handlers keyed by type string.
-- Each handler: function(effect, ctx) -> nil
-- Handlers print their own messages and mutate state via ctx.
local handlers = {}

--- Register a new on_traverse effect handler.
-- @param effect_type  string   The `type` value that triggers this handler.
-- @param handler_fn   function(effect, ctx)  Called when the effect fires.
function traverse_effects.register(effect_type, handler_fn)
    handlers[effect_type] = handler_fn
end

--- Process an exit's on_traverse effects, if any.
-- Called by the movement handler BEFORE the player is moved.
-- @param exit  table|string  The exit definition from room metadata.
-- @param ctx   table         The game context (registry, player, etc.)
function traverse_effects.process(exit, ctx)
    if type(exit) ~= "table" then return end
    local effect = exit.on_traverse
    if not effect then return end
    if not effect.type then return end

    local handler = handlers[effect.type]
    if not handler then return end

    handler(effect, ctx)
end

---------------------------------------------------------------------------
-- Built-in handler: wind_effect
--
-- Checks player inventory for items in the `extinguishes` list.
-- If a matching item is found AND is in a "lit" state AND is NOT
-- wind_resistant, transitions it to "extinguished" (or "unlit") state.
---------------------------------------------------------------------------
local function wind_effect_handler(effect, ctx)
    local fsm_mod = require("engine.fsm")
    local presentation = require("engine.ui.presentation")

    local carried_ids = presentation.get_all_carried_ids(ctx)
    local extinguish_set = {}
    for _, name in ipairs(effect.extinguishes or {}) do
        extinguish_set[name:lower()] = true
    end

    local something_extinguished = false
    local something_spared = false

    for _, obj_id in ipairs(carried_ids) do
        local obj = ctx.registry:get(obj_id)
        if obj then
            -- Check if this object is in the extinguishes list (by id or keywords)
            local targeted = false
            if obj.id and extinguish_set[obj.id:lower()] then
                targeted = true
            end
            if not targeted and type(obj.keywords) == "table" then
                for _, kw in ipairs(obj.keywords) do
                    if extinguish_set[kw:lower()] then
                        targeted = true
                        break
                    end
                end
            end

            if targeted and obj._state == "lit" then
                if obj.wind_resistant then
                    something_spared = true
                else
                    -- Try extinguished first, then unlit
                    local trans, err = fsm_mod.transition(
                        ctx.registry, obj_id, "extinguished", nil, "extinguish"
                    )
                    if not trans then
                        trans, err = fsm_mod.transition(
                            ctx.registry, obj_id, "unlit", nil, "extinguish"
                        )
                    end
                    if trans then
                        something_extinguished = true
                    end
                end
            elseif not targeted and obj._state == "lit" and obj.wind_resistant then
                -- Not in extinguish list but lit and wind-resistant — spared
                something_spared = true
            end
        end
    end

    -- Print messages: effect description first, then outcome
    if something_extinguished or something_spared then
        if effect.description then
            print(effect.description)
        end
    end
    if something_extinguished then
        print(effect.message_extinguish or "The draft snuffs out your flame!")
    end
    if something_spared and not something_extinguished then
        if effect.message_spared then
            print(effect.message_spared)
        end
    end
end

traverse_effects.register("wind_effect", wind_effect_handler)

return traverse_effects
