-- engine/verbs/sensory.lua
local M = {}

local look = require("engine.verbs.sensory.look")
local touch = require("engine.verbs.sensory.touch")
local search = require("engine.verbs.sensory.search")
local smell = require("engine.verbs.sensory.smell")
local taste = require("engine.verbs.sensory.taste")
local listen = require("engine.verbs.sensory.listen")

function M.register(handlers)
    look.register(handlers)
    touch.register(handlers)
    search.register(handlers)
    smell.register(handlers)
    taste.register(handlers)
    listen.register(handlers)
end

return M
