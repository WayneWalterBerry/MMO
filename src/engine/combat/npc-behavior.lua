-- engine/combat/npc-behavior.lua
-- NPC combat decision-making: response selection, stance, target zone.
-- Stub created during WAVE-0 module split (Phase 2).
--
-- WAVE-2 will move the following into this module:
--   - NPC response auto-select: choose block/dodge/counter/flee based on
--     creature combat stats, health, and fear level
--   - NPC stance management: aggressive/defensive/balanced selection based
--     on creature personality and combat state
--   - NPC target zone selection: weighted zone picking using creature
--     combat.preferred_zones and body_tree awareness
--
-- Ownership: Bart (Architecture Lead)

local M = {}

---------------------------------------------------------------------------
-- select_response(creature, attacker, combat_state) -> response_type
-- Chooses a defensive response for an NPC creature.
-- Stub: returns nil (engine falls through to default) until WAVE-2.
---------------------------------------------------------------------------
function M.select_response(creature, attacker, combat_state)
    return nil
end

---------------------------------------------------------------------------
-- select_stance(creature, combat_state) -> stance_string
-- Chooses a combat stance for an NPC creature.
-- Stub: returns "balanced" until WAVE-2.
---------------------------------------------------------------------------
function M.select_stance(creature, combat_state)
    return "balanced"
end

---------------------------------------------------------------------------
-- select_target_zone(creature, defender, combat_state) -> zone_string|nil
-- Chooses a target body zone for an NPC attacker.
-- Stub: returns nil (random weighted zone) until WAVE-2.
---------------------------------------------------------------------------
function M.select_target_zone(creature, defender, combat_state)
    return nil
end

return M
