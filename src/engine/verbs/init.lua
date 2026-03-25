-- engine/verbs/init.lua
-- Registry for verb handlers.

local verbs = {}

function verbs.create()
    local handlers = {}

    local sensory = require("engine.verbs.sensory")
    local acquisition = require("engine.verbs.acquisition")
    local containers = require("engine.verbs.containers")
    local destruction = require("engine.verbs.destruction")
    local fire = require("engine.verbs.fire")
    local combat = require("engine.verbs.combat")
    local crafting = require("engine.verbs.crafting")
    local equipment = require("engine.verbs.equipment")
    local survival = require("engine.verbs.survival")
    local movement = require("engine.verbs.movement")
    local meta = require("engine.verbs.meta")
    local traps = require("engine.verbs.traps")

    sensory.register(handlers)
    acquisition.register(handlers)
    containers.register(handlers)
    destruction.register(handlers)
    fire.register(handlers)
    combat.register(handlers)
    crafting.register(handlers)
    equipment.register(handlers)
    survival.register(handlers)
    movement.register(handlers)
    meta.register(handlers)
    traps.register(handlers)

    -- Consciousness gate: block all verbs while the player is unconscious.
    -- Cache wrappers by original function to preserve alias identity
    -- (e.g., handlers["i"] == handlers["inventory"]).
    local raw = {}
    for k, v in pairs(handlers) do raw[k] = v end
    local wrapper_cache = {}
    for verb, fn in pairs(raw) do
        if not wrapper_cache[fn] then
            wrapper_cache[fn] = function(ctx, noun)
                if ctx.player and ctx.player.consciousness
                   and ctx.player.consciousness.state == "unconscious" then
                    print("You are unconscious.")
                    return
                end
                return fn(ctx, noun)
            end
        end
        handlers[verb] = wrapper_cache[fn]
    end

    return handlers
end

return verbs
