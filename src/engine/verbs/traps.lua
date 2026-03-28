-- engine/verbs/traps.lua
-- Verb handlers for environmental trap interactions (#162).
-- Handles: breathe, trigger, step — verbs used by unconsciousness triggers.
--
-- Ownership: Smithers (UI Engineer) — verb registration + dispatch
--            Flanders (Object Designer) — trigger object definitions
local H = require("engine.verbs.helpers")

local find_visible = H.find_visible
local try_fsm_verb = H.try_fsm_verb
local err_not_found = H.err_not_found
local err_nothing_happens = H.err_nothing_happens

local M = {}

---------------------------------------------------------------------------
-- Shared: find an object by noun, trying find_visible then registry
---------------------------------------------------------------------------
local function find_target(ctx, noun)
    local obj = find_visible(ctx, noun)
    if not obj and ctx.registry and ctx.registry.find_by_keyword then
        obj = ctx.registry:find_by_keyword(noun)
    end
    return obj
end

---------------------------------------------------------------------------
-- Shared: generic FSM interaction verb
---------------------------------------------------------------------------
local function fsm_interact(ctx, noun, verb, prompt)
    if not noun or noun == "" then
        print(prompt)
        return
    end

    local target = noun:gsub("^on%s+", ""):gsub("^at%s+", ""):gsub("^into%s+", "")
    local obj = find_target(ctx, target)
    if not obj then
        err_not_found(ctx)
        return
    end

    if try_fsm_verb(ctx, obj, verb) then return end

    err_nothing_happens(obj)
end

---------------------------------------------------------------------------
-- Register verb handlers
---------------------------------------------------------------------------
function M.register(handlers)

    handlers["breathe"] = function(ctx, noun)
        fsm_interact(ctx, noun, "breathe", "Breathe what?")
    end
    handlers["inhale"] = handlers["breathe"]

    handlers["trigger"] = function(ctx, noun)
        fsm_interact(ctx, noun, "trigger", "Trigger what?")
    end
    handlers["activate"] = handlers["trigger"]

    handlers["step"] = function(ctx, noun)
        fsm_interact(ctx, noun, "step", "Step on what?")
    end

    -- #322: unbar/bar verb handlers for door FSM transitions
    handlers["unbar"] = function(ctx, noun)
        fsm_interact(ctx, noun, "unbar", "Unbar what?")
    end
    handlers["lift bar"] = handlers["unbar"]
    handlers["remove bar"] = handlers["unbar"]

    handlers["bar"] = function(ctx, noun)
        fsm_interact(ctx, noun, "bar", "Bar what?")
    end

end

return M
