-- engine/combat/npc-behavior.lua
-- NPC combat decision-making: response selection, stance, target zone.
-- Reads creature combat.behavior metadata (Principle 8).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

-- Map creature attack_pattern → engine stance
local PATTERN_TO_STANCE = {
    aggressive  = "aggressive",
    sustained   = "aggressive",
    ambush      = "aggressive",
    hit_and_run = "defensive",
    defensive   = "defensive",
    opportunistic = "balanced",
    random      = "balanced",
    cornered    = "aggressive",
}

---------------------------------------------------------------------------
-- select_response(creature, attacker, combat_state) -> response_type
-- Reads defender's combat.behavior.defense (dodge/block/flee/counter/none).
-- Cornered creatures never select "flee" — they fight.
---------------------------------------------------------------------------
function M.select_response(creature, attacker, combat_state)
    local cb = creature and creature.combat and creature.combat.behavior
    if not cb then return nil end
    local defense = cb.defense
    -- Cornered creatures cannot flee
    if creature._cornered and defense == "flee" then
        return "counter"
    end
    if defense and defense ~= "none" then return defense end
    return nil
end

---------------------------------------------------------------------------
-- select_stance(creature, combat_state) -> stance_string
-- Maps creature's combat.behavior.attack_pattern to engine stance.
-- Cornered creatures always use aggressive stance.
---------------------------------------------------------------------------
function M.select_stance(creature, combat_state)
    if creature._cornered then return "aggressive" end
    local cb = creature and creature.combat and creature.combat.behavior
    if not cb then return "balanced" end
    local pattern = cb.attack_pattern or cb.stance
    if pattern and PATTERN_TO_STANCE[pattern] then
        return PATTERN_TO_STANCE[pattern]
    end
    return "balanced"
end

---------------------------------------------------------------------------
-- select_target_zone(creature, defender, combat_state) -> zone_string|nil
-- Uses combat.behavior.target_priority to bias zone selection.
-- "weakest" → vital zones, "threatening" → largest zone, else nil (random).
---------------------------------------------------------------------------
function M.select_target_zone(creature, defender, combat_state)
    local cb = creature and creature.combat and creature.combat.behavior
    if not cb or not cb.target_priority then return nil end
    local bt = defender and defender.body_tree
    if not bt then return nil end

    local priority = cb.target_priority
    if priority == "weakest" then
        -- Target vital zones (head preferred)
        for zone, info in pairs(bt) do
            if info and info.vital then return zone end
        end
    elseif priority == "threatening" then
        -- Target largest zone
        local best_zone, best_size = nil, 0
        for zone, info in pairs(bt) do
            local sz = (info and info.size) or 1
            if sz > best_size then
                best_zone, best_size = zone, sz
            end
        end
        return best_zone
    end
    -- "closest" or unknown → nil (engine uses random weighted)
    return nil
end

return M
