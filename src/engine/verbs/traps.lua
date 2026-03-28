-- engine/verbs/traps.lua
-- Verb handlers for environmental trap interactions (#162).
-- Handles: breathe, trigger, step, unbar, bar — verbs used by
-- unconsciousness triggers and FSM-only door/portal interactions.
--
-- Ownership: Smithers (UI Engineer) — verb registration + dispatch
--            Flanders (Object Designer) — trigger object definitions
local H = require("engine.verbs.helpers")

local fsm_mod = H.fsm_mod
local effects = H.effects
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
-- #402: Uses fsm.transition() to actually apply state changes, keyword
-- mutations, and bidirectional portal sync — not just try_fsm_verb which
-- only prints the message without mutating state.
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

    -- #402: Proper FSM transition path — find matching transition and
    -- call fsm.transition() to apply state change + mutations
    if obj.states and obj.transitions then
        local transitions = fsm_mod.get_transitions(obj)
        local target_trans
        for _, t in ipairs(transitions) do
            if t.verb == verb then target_trans = t; break end
            if t.aliases then
                for _, a in ipairs(t.aliases) do
                    if a == verb then target_trans = t; break end
                end
                if target_trans then break end
            end
        end
        if target_trans then
            local trans, err = fsm_mod.transition(
                ctx.registry, obj.id, target_trans.to, {}, verb)
            if trans then
                print(trans.message or ("You " .. verb .. " " .. (obj.name or obj.id) .. "."))
                -- Process pipeline effects (injuries, unconsciousness, etc.)
                local fx = trans.pipeline_effects or trans.effect
                if fx and effects and ctx.player then
                    effects.process(fx, {
                        player = ctx.player,
                        source = obj,
                        source_id = obj.id,
                        registry = ctx.registry,
                        time_offset = ctx.time_offset or 0,
                    })
                end
                return
            end
        end
    end

    -- Fallback: try_fsm_verb for effect-only transitions (traps, unconsciousness)
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
