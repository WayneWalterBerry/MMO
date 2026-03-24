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

    return handlers
end

return verbs
