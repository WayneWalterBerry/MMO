-- engine/traverse_effects/registry.lua
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

--- Normalize an on_traverse table into { type = ..., ...fields }.
-- Accepts two formats:
--   1. Flat:   { type = "wind_effect", extinguishes = {...}, ... }
--   2. Nested: { wind_effect = { extinguishes = {...}, ... } }
-- Returns the normalized effect table, or nil if unrecognized.
local function normalize_effect(raw)
    if raw.type then return raw end

    -- Nested format: single key whose value is the effect payload
    local effect_type, payload
    for k, v in pairs(raw) do
        if type(v) == "table" then
            if effect_type then return nil end  -- ambiguous: multiple keys
            effect_type = k
            payload = v
        end
    end
    if not effect_type then return nil end

    -- Merge into flat format expected by handlers
    local flat = { type = effect_type }
    for k, v in pairs(payload) do flat[k] = v end
    return flat
end

--- Process an exit's on_traverse effects, if any.
-- Called by the movement handler BEFORE the player is moved.
-- @param exit  table|string  The exit definition from room metadata.
-- @param ctx   table         The game context (registry, player, etc.)
function traverse_effects.process(exit, ctx)
    if type(exit) ~= "table" then return end
    local raw = exit.on_traverse
    if not raw then return end

    local effect = normalize_effect(raw)
    if not effect then return end

    local handler = handlers[effect.type]
    if not handler then return end

    handler(effect, ctx)
end

return traverse_effects
