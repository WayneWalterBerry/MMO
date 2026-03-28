-- engine/creatures/pack-tactics.lua
-- Simplified pack awareness: stagger attacks, alpha selection, defensive retreat.
-- Phase 4 WAVE-5 — full alpha/beta/omega roles deferred to Phase 5.
-- Q4 resolved: alpha = highest health wolf (not highest aggression).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

---------------------------------------------------------------------------
-- select_alpha(pack, ctx) -> creature
-- Alpha is the wolf with highest current health. Ties broken by max_health.
---------------------------------------------------------------------------
function M.select_alpha(pack, ctx)
    if not pack or #pack == 0 then return nil end
    if #pack == 1 then return pack[1] end

    local alpha = pack[1]
    for i = 2, #pack do
        local c = pack[i]
        local c_hp = c.health or 0
        local a_hp = alpha.health or 0
        if c_hp > a_hp or (c_hp == a_hp and (c.max_health or 0) > (alpha.max_health or 0)) then
            alpha = c
        end
    end
    return alpha
end

---------------------------------------------------------------------------
-- plan_attack(pack, ctx) -> array of { creature, attacker, delay }
-- Alpha attacks on turn 0; others stagger by 1 game-turn each.
-- Single wolf: no stagger, immediate attack (delay 0).
---------------------------------------------------------------------------
function M.plan_attack(pack, ctx)
    if not pack or #pack == 0 then return {} end
    if #pack == 1 then
        return { { creature = pack[1], attacker = pack[1].guid, delay = 0 } }
    end

    local alpha = M.select_alpha(pack, ctx)
    local plan = {}
    local delay_counter = 0

    -- Alpha attacks first
    plan[#plan + 1] = { creature = alpha, attacker = alpha.guid, delay = 0 }

    -- Others stagger by 1 turn each
    for _, c in ipairs(pack) do
        if c ~= alpha then
            delay_counter = delay_counter + 1
            plan[#plan + 1] = { creature = c, attacker = c.guid, delay = delay_counter }
        end
    end

    return plan
end

---------------------------------------------------------------------------
-- should_retreat(creature, ctx) -> bool
-- Defensive retreat when health < 20% of max.
---------------------------------------------------------------------------
function M.should_retreat(creature, ctx)
    if not creature then return false end
    local hp = creature.health or 0
    local max_hp = creature.max_health or 1
    if max_hp <= 0 then return false end
    return (hp / max_hp) < 0.20
end

---------------------------------------------------------------------------
-- get_pack_in_room(registry, room_id, creature_id) -> array of same-species creatures
-- Finds all alive creatures sharing the same base id (e.g. "wolf") in a room.
---------------------------------------------------------------------------
function M.get_pack_in_room(registry, room_id, creature)
    if not registry or not room_id or not creature then return {} end
    local base_id = creature.id or ""
    local list_fn = registry.list or registry.all
    if not list_fn then return {} end

    local pack = {}
    for _, obj in ipairs(list_fn(registry)) do
        if obj.animate and obj._state ~= "dead"
           and obj.id == base_id
           and obj.location == room_id then
            pack[#pack + 1] = obj
        end
    end
    return pack
end

---------------------------------------------------------------------------
-- prefers_doorway(creature, ctx, get_room_fn) -> bool
-- Smart positioning: creature near an exit blocks player escape.
-- Returns true if creature is in a room with exits (positional advantage).
---------------------------------------------------------------------------
function M.prefers_doorway(creature, ctx, get_room_fn)
    if not creature or not ctx then return false end
    local loc = creature.location
    if not loc then return false end
    local room = get_room_fn and get_room_fn(ctx, loc)
    if not room or not room.exits then return false end

    local exit_count = 0
    for _ in pairs(room.exits) do exit_count = exit_count + 1 end
    return exit_count > 0
end

return M
