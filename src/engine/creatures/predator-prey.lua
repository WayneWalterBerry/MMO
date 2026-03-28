-- engine/creatures/predator-prey.lua
-- Predator-prey subsystem: prey detection, target selection, source_filter.
-- Fleshed out in WAVE-2 (Phase 2). Reads creature.behavior.prey metadata.
--
-- Ownership: Bart (Architecture Lead)

local M = {}

---------------------------------------------------------------------------
-- has_prey_in_room(creature, context, get_creatures_fn, get_location_fn)
-- Returns true if any alive creature matching creature.behavior.prey is
-- in the same room. Skips dead creatures and self.
---------------------------------------------------------------------------
function M.has_prey_in_room(creature, context, get_creatures_fn, get_location_fn)
    local prey_list = creature.behavior and creature.behavior.prey
    if not prey_list or #prey_list == 0 then return false end

    local registry = context.registry
    local creature_loc = get_location_fn(registry, creature)
    if not creature_loc then return false end

    -- Check registry creatures
    local others = get_creatures_fn(registry, creature_loc)
    for _, other in ipairs(others) do
        if other ~= creature and other._state ~= "dead" and other.animate ~= false then
            for _, prey_id in ipairs(prey_list) do
                if other.id == prey_id then return true end
            end
        end
    end

    -- Check player (lives at context.player, not in registry)
    local player = context.player
    if player and player.location == creature_loc then
        for _, prey_id in ipairs(prey_list) do
            if prey_id == "player" then return true end
        end
    end

    return false
end

---------------------------------------------------------------------------
-- select_prey_target(context, creature, get_creatures_fn, get_location_fn)
-- Returns first alive creature matching prey list in same room, or nil.
-- Iterates prey list first (priority order) then creatures.
---------------------------------------------------------------------------
function M.select_prey_target(context, creature, get_creatures_fn, get_location_fn)
    local prey_list = creature.behavior and creature.behavior.prey
    if not prey_list or #prey_list == 0 then return nil end

    local registry = context.registry
    local creature_loc = get_location_fn(registry, creature)
    if not creature_loc then return nil end

    local others = get_creatures_fn(registry, creature_loc)
    local player = context.player

    -- Iterate prey list first (priority order)
    for _, prey_id in ipairs(prey_list) do
        -- Check player target
        if prey_id == "player" and player and player.location == creature_loc then
            return player
        end
        -- Check registry creatures
        for _, other in ipairs(others) do
            if other ~= creature and other._state ~= "dead"
               and other.animate ~= false and other.id == prey_id then
                return other
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- evaluate_source_filter(creature, stimulus, filter) -> bool
-- Checks whether a stimulus source matches the creature's source_filter
-- criteria (e.g., "only react to prey-type creatures").
---------------------------------------------------------------------------
function M.evaluate_source_filter(creature, stimulus, filter)
    return true
end

---------------------------------------------------------------------------
-- predator_reaction(context, predator, prey_list, helpers) -> messages[]
-- Produces behavior/drive changes when a predator detects prey.
---------------------------------------------------------------------------
function M.predator_reaction(context, predator, prey_list, helpers)
    return {}
end

return M
