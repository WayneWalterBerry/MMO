-- engine/effects.lua
-- Unified effect processor. Objects declare effects; this module routes them.
--
-- Ownership: Smithers (UI Engineer) — implementation
--            Bart (Architect) — design (D-EFFECTS-PIPELINE)
--
-- Objects declare WHAT happens (structured effect tables).
-- The engine decides WHEN it happens (hook integration points).
-- This module decides HOW it happens (dispatch to subsystems).
--
-- Supports three declaration formats:
--   1. Legacy string:  effect = "poison"
--   2. Single table:   effect = { type = "inflict_injury", ... }
--   3. Array of tables: effect = { { type = "inflict_injury" }, { type = "narrate" } }

local effects = {}
local handlers = {}

---------------------------------------------------------------------------
-- Handler registry
---------------------------------------------------------------------------

--- Register a handler for an effect type.
-- @param effect_type  string           The type value (e.g. "inflict_injury")
-- @param handler_fn   function(effect, ctx) -> any
function effects.register(effect_type, handler_fn)
    handlers[effect_type] = handler_fn
end

--- Unregister a handler (primarily for testing).
function effects.unregister(effect_type)
    handlers[effect_type] = nil
end

--- Check if a handler is registered for a given effect type.
function effects.has_handler(effect_type)
    return handlers[effect_type] ~= nil
end

---------------------------------------------------------------------------
-- Before/After interceptor infrastructure
---------------------------------------------------------------------------
local interceptors = { before = {}, after = {} }

--- Add an interceptor for a phase ("before" or "after").
-- Before interceptors can return "cancel" to abort the effect.
-- After interceptors cannot cancel (effect already happened).
function effects.add_interceptor(phase, fn)
    interceptors[phase] = interceptors[phase] or {}
    interceptors[phase][#interceptors[phase] + 1] = fn
end

--- Clear all interceptors (primarily for testing).
function effects.clear_interceptors()
    interceptors = { before = {}, after = {} }
end

--- Run interceptors for a phase. Returns true if cancelled (before phase only).
function effects._run_interceptors(phase, effect, ctx)
    for _, fn in ipairs(interceptors[phase] or {}) do
        local result = fn(effect, ctx)
        if phase == "before" and result == "cancel" then
            return true -- cancelled
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Legacy normalization
---------------------------------------------------------------------------

-- Maps legacy string effect tags to structured effect tables.
local legacy_map = {
    poison = { type = "inflict_injury", injury_type = "poisoned-nightshade",
               source = "unknown", damage = 10 },
    cut    = { type = "inflict_injury", injury_type = "minor-cut",
               source = "unknown", damage = 3 },
    burn   = { type = "inflict_injury", injury_type = "burn",
               source = "unknown", damage = 5 },
    bruise = { type = "inflict_injury", injury_type = "bruised",
               source = "unknown", damage = 4 },
    nausea = { type = "add_status", status = "nauseated", duration = 12 },
}

--- Normalize any effect declaration into an array of structured tables.
-- Accepts: string ("poison"), single table ({type=...}), or array of tables.
-- Returns: array of {type=...} tables, or nil if unrecognized.
function effects.normalize(raw)
    if type(raw) == "string" then
        local mapped = legacy_map[raw]
        if mapped then
            -- Return a copy to avoid mutating the template
            local copy = {}
            for k, v in pairs(mapped) do copy[k] = v end
            return { copy }
        end
        return nil
    end
    if type(raw) == "table" then
        if raw.type then return { raw } end   -- single effect → wrap in array
        if raw[1] then return raw end          -- already an array of effects
    end
    return nil
end

---------------------------------------------------------------------------
-- Main processing entry point
---------------------------------------------------------------------------

--- Process an effect declaration.
-- Accepts: string ("poison"), single table ({type=...}), or array of tables.
-- @param raw    string|table   The effect declaration from object metadata
-- @param ctx    table          Game context (player, registry, source object, etc.)
-- @return boolean              true if at least one effect was processed
function effects.process(raw, ctx)
    local effect_list = effects.normalize(raw)
    if not effect_list then return false end

    ctx = ctx or {}
    local any = false

    for _, effect in ipairs(effect_list) do
        -- Phase 1: before_effect interceptors can cancel or modify
        local cancelled = effects._run_interceptors("before", effect, ctx)
        if not cancelled then
            -- Phase 2: dispatch to registered handler
            local handler = handlers[effect.type]
            if handler then
                handler(effect, ctx)
                any = true
            end
            -- Phase 3: after_effect interceptors (cleanup, narration, achievements)
            effects._run_interceptors("after", effect, ctx)

            -- Phase 4: emit loud_noise stimulus for creature reactions
            if effect.loud then
                local room_id = ctx.room_id
                    or (ctx.current_room and ctx.current_room.id)
                    or (ctx.player and ctx.player.location)
                if room_id then
                    local cok, creatures = pcall(require, "engine.creatures")
                    if cok and creatures and creatures.emit_stimulus then
                        creatures.emit_stimulus(room_id, "loud_noise", {
                            source = effect.source or ctx.source_id or "unknown",
                        })
                    end
                end
            end
        end
    end

    return any
end

---------------------------------------------------------------------------
-- Built-in handler: inflict_injury
-- Routes to the existing injuries.inflict() API with zero changes to that system.
---------------------------------------------------------------------------
effects.register("inflict_injury", function(effect, ctx)
    local inj_ok, injury_mod = pcall(require, "engine.injuries")
    if not inj_ok then return nil end

    local instance = injury_mod.inflict(
        ctx.player,
        effect.injury_type,
        effect.source or ctx.source_id or "unknown",
        effect.location,
        effect.damage
    )

    -- Print effect-level message (distinct from transition message)
    if effect.message then
        print(effect.message)
    end

    -- Trigger unconsciousness if the effect declares it
    if effect.causes_unconsciousness and ctx.player and instance then
        local severity = effect.severity or "moderate"
        local conc_def = injury_mod.load_definition("concussion")
        local duration = conc_def and conc_def.unconscious_duration
                         and conc_def.unconscious_duration[severity]
        if not duration then
            duration = effect.unconscious_duration
                       and effect.unconscious_duration.min or 5
        end
        ctx.player.consciousness = ctx.player.consciousness or {}
        ctx.player.consciousness.state = "unconscious"
        ctx.player.consciousness.wake_timer = duration
        ctx.player.consciousness.cause = effect.source or ctx.source_id or "unknown"
        ctx.player.consciousness.unconscious_since = ctx.time_offset or 0
    end

    -- Check for instant death after injury infliction
    if instance and ctx.player then
        local health = injury_mod.compute_health(ctx.player)
        if health <= 0 then
            ctx.game_over = true
        end
    end

    return instance
end)

---------------------------------------------------------------------------
-- Built-in handler: narrate
-- Prints a message to the player. Future: narrator formatting via style field.
---------------------------------------------------------------------------
effects.register("narrate", function(effect, ctx)
    if effect.message then
        print(effect.message)
    end
end)

---------------------------------------------------------------------------
-- Built-in handler: add_status
-- Adds a status condition to the player's state table.
---------------------------------------------------------------------------
effects.register("add_status", function(effect, ctx)
    if not effect.status or not ctx.player then return end
    ctx.player.state = ctx.player.state or {}
    ctx.player.state[effect.status] = {
        active = true,
        duration = effect.duration,
        severity = effect.severity,
    }
    if effect.message then
        print(effect.message)
    end
end)

---------------------------------------------------------------------------
-- Built-in handler: remove_status
-- Removes a status condition from the player's state table.
---------------------------------------------------------------------------
effects.register("remove_status", function(effect, ctx)
    if not effect.status or not ctx.player then return end
    ctx.player.state = ctx.player.state or {}
    ctx.player.state[effect.status] = nil
    if effect.message then
        print(effect.message)
    end
end)

---------------------------------------------------------------------------
-- Built-in handler: mutate
-- Changes a field on an object. target = "self" uses ctx.source object.
---------------------------------------------------------------------------
effects.register("mutate", function(effect, ctx)
    if not effect.field then return end
    local target_obj
    if effect.target == "self" and ctx.source then
        target_obj = ctx.source
    elseif effect.target and ctx.registry then
        target_obj = ctx.registry:get(effect.target)
    elseif ctx.source then
        target_obj = ctx.source
    end
    if target_obj then
        target_obj[effect.field] = effect.value
    end
end)

---------------------------------------------------------------------------
-- Built-in handler: heal
-- Restores player health by reducing injury damage or adding health.
---------------------------------------------------------------------------
effects.register("heal", function(effect, ctx)
    if not ctx.player then return end
    local amount = effect.amount or 0
    if amount > 0 then
        -- Reduce accumulated injury damage (healing)
        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if inj_ok and injury_mod and ctx.player.injuries then
            local healed = 0
            for _, inj in ipairs(ctx.player.injuries) do
                if healed >= amount then break end
                if inj.damage and inj.damage > 0 then
                    local reduce = math.min(inj.damage, amount - healed)
                    inj.damage = inj.damage - reduce
                    healed = healed + reduce
                end
            end
        end
        -- Also boost nutrition as a general health benefit
        if effect.nutrition then
            ctx.player.nutrition = (ctx.player.nutrition or 0) + effect.nutrition
        end
    end
    if effect.message then
        print(effect.message)
    end
end)

---------------------------------------------------------------------------
-- Built-in handler: play_sound
-- Canonical sound dispatch path (v1.1). Objects declare play_sound effects;
-- the effects pipeline routes them to the sound manager via trigger().
---------------------------------------------------------------------------
effects.register("play_sound", function(effect, ctx)
    if not ctx or not ctx.sound_manager then return end
    local obj = effect.source_obj or ctx.source
    local key = effect.key or effect.sound_key
    if key then
        ctx.sound_manager:trigger(obj, key)
    elseif effect.filename then
        ctx.sound_manager:play(effect.filename, {
            owner_id = obj and (obj.guid or obj.id),
        })
    end
end)

return effects
