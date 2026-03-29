-- engine/creatures/morale.lua
-- Creature morale system: flee_threshold checks and cornered fallback.
-- Extracted from creatures/init.lua for WAVE-3 (Phase 2).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

---------------------------------------------------------------------------
-- check(context, creature, combat_result, helpers) -> "flee"|"cornered"|nil
-- Called after combat RESOLVE phase. If health/max_health < flee_threshold,
-- creature attempts to flee. If no valid exits, enters cornered stance.
--
-- helpers must provide:
--   helpers.get_location(registry, creature) -> room_id
--   helpers.get_valid_exits(context, room_id, creature) -> exits[]
--   helpers.get_player_room_id(context) -> room_id|nil
--   helpers.move_creature(context, creature, target_room_id)
---------------------------------------------------------------------------
function M.check(context, creature, combat_result, helpers)
    if not creature or creature._state == "dead" then return nil end

    local health = creature.health
    local max_health = creature.max_health
    if not health or not max_health or max_health <= 0 then return nil end

    -- Read from combat.behavior.flee_threshold (decimal ratio 0.0-1.0)
    local threshold = creature.combat and creature.combat.behavior
        and creature.combat.behavior.flee_threshold
    -- Fallback to behavior.flee_threshold, normalizing integer to ratio
    if not threshold then
        local raw = creature.behavior and creature.behavior.flee_threshold
        if raw and raw > 1 then
            threshold = raw / 100
        else
            threshold = raw
        end
    end
    if not threshold then return nil end

    -- Pack morale override: pack_tactics.apply_pack_morale_bonus sets this
    if creature._pack_flee_threshold then
        threshold = creature._pack_flee_threshold
    end

    local health_ratio = health / max_health
    if health_ratio >= threshold then
        creature._cornered = nil
        return nil
    end

    -- Below threshold: attempt to flee
    local creature_loc = helpers.get_location(context.registry, creature)
    if not creature_loc then return nil end

    local exits = helpers.get_valid_exits(context, creature_loc, creature)
    if #exits > 0 then
        local choice = exits[math.random(#exits)]
        local player_room = helpers.get_player_room_id(context)

        if creature._state and creature._state ~= "dead" then
            creature._state = "alive-flee"
        end
        creature._cornered = nil

        helpers.move_creature(context, creature, choice.target)
        creature._last_exit = choice.direction

        if creature_loc == player_room then
            local name = creature.name or "a creature"
            creature._morale_message = name:sub(1,1):upper() .. name:sub(2) ..
                " panics and flees " .. choice.direction .. "!"
        end

        return "flee"
    else
        -- Cornered: no valid exits — fight harder
        creature._cornered = true
        if creature._state and creature._state ~= "dead" then
            creature._state = "alive-cornered"
        end

        local player_room = helpers.get_player_room_id(context)
        if creature_loc == player_room then
            local name = creature.name or "a creature"
            creature._morale_message = name:sub(1,1):upper() .. name:sub(2) ..
                ", cornered, bares its teeth!"
        end

        return "cornered"
    end
end

return M
