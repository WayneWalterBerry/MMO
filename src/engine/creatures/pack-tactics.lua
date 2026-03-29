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

---------------------------------------------------------------------------
-- WAVE-2: Pack Coordination Engine
-- Shared threat tracking, pack morale, call_pack support.
-- All behavior is metadata-driven (Principle 8): reads pack_animal,
-- pack_morale_bonus, call_pack_range from creature.behavior.
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- share_threat(registry, room_id, creature, data)
-- When a pack member detects a threat, alert same-room pack mates.
-- Sets _pack_threat on allies and transitions idle members to aggressive.
---------------------------------------------------------------------------
function M.share_threat(registry, room_id, creature, data)
    if not creature or not (creature.behavior or {}).pack_animal then return end
    local pack = M.get_pack_in_room(registry, room_id, creature)
    for _, member in ipairs(pack) do
        if member.guid ~= creature.guid then
            member._pack_threat = data and data.attacker_id or true
            local st = member._state
            if st == "alive-idle" or st == "alive-wander" or st == "alive-patrol" then
                member._state = "alive-aggressive"
            end
        end
    end
end

---------------------------------------------------------------------------
-- apply_pack_morale_bonus(creature, registry, room_id) -> number|nil
-- Pack animals flee at a lower health ratio when allies are present.
-- Reads pack_morale_bonus from behavior (default 0.05 per ally).
---------------------------------------------------------------------------
function M.apply_pack_morale_bonus(creature, registry, room_id)
    if not creature or not (creature.behavior or {}).pack_animal then return nil end
    local pack = M.get_pack_in_room(registry, room_id, creature)
    local allies = #pack - 1
    if allies <= 0 then return nil end
    local bonus = creature.behavior.pack_morale_bonus or 0.05
    local base = creature.combat and creature.combat.behavior
        and creature.combat.behavior.flee_threshold
    if not base then
        local raw = creature.behavior.flee_threshold
        if raw and raw > 1 then base = raw / 100 else base = raw end
    end
    if not base then return nil end
    local adjusted = base - (bonus * allies)
    return adjusted < 0.05 and 0.05 or adjusted
end

---------------------------------------------------------------------------
-- check_pack_morale(pack, context) -> "hold" | "scatter"
-- Pack scatters if alpha is critically wounded or all members fled/dead.
---------------------------------------------------------------------------
function M.check_pack_morale(pack, context)
    if not pack or #pack == 0 then return "scatter" end
    local active = 0
    for _, m in ipairs(pack) do
        if m._state ~= "dead" and m._state ~= "alive-flee" then
            active = active + 1
        end
    end
    if active == 0 then return "scatter" end
    local alpha = M.select_alpha(pack, context)
    if not alpha then return "scatter" end
    if alpha.health and alpha.max_health and alpha.max_health > 0
       and (alpha.health / alpha.max_health) < 0.20 then
        for _, m in ipairs(pack) do
            if m.guid ~= alpha.guid and m.drives and m.drives.fear then
                local fear = m.drives.fear
                fear.value = math.min(fear.max or 100, (fear.value or 0) + 40)
            end
        end
        return "scatter"
    end
    return "hold"
end

---------------------------------------------------------------------------
-- WAVE-3: Territory Transfer
-- When alpha dies, next-healthiest pack member inherits territory.
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- transfer_territory(dead_alpha, pack, context)
-- Reassigns behavior.territory from dead_alpha to new alpha.
-- Territory markers stay in place — new alpha claims same territory.
---------------------------------------------------------------------------
function M.transfer_territory(dead_alpha, pack, context)
    if not dead_alpha or not pack or #pack == 0 then return nil end
    local territory = dead_alpha.behavior and
        (dead_alpha.behavior.territory or dead_alpha.behavior.home_territory)
    if not territory then return nil end

    -- Filter out the dead alpha and any dead/fled members
    local candidates = {}
    for _, m in ipairs(pack) do
        if m.guid ~= dead_alpha.guid
           and m._state ~= "dead" and m._state ~= "alive-flee" then
            candidates[#candidates + 1] = m
        end
    end
    if #candidates == 0 then return nil end

    local new_alpha = M.select_alpha(candidates, context)
    if not new_alpha then return nil end

    new_alpha.behavior = new_alpha.behavior or {}
    new_alpha.behavior.territory = territory
    return new_alpha
end

---------------------------------------------------------------------------
-- WAVE-4: Pack Ambush Coordination
-- When alpha springs its ambush, all pack members spring simultaneously.
-- Reads behavior.ambush from each member (Principle 8).
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- coordinate_ambush(pack, context) -> bool
-- If the alpha has sprung, spring all ambush-capable pack members.
---------------------------------------------------------------------------
function M.coordinate_ambush(pack, context)
    if not pack or #pack < 2 then return false end
    local alpha = M.select_alpha(pack, context)
    if not alpha then return false end
    if not alpha._ambush_sprung then return false end

    local coordinated = false
    for _, member in ipairs(pack) do
        if member.guid ~= alpha.guid
           and (member.behavior or {}).ambush
           and not member._ambush_sprung then
            member._ambush_sprung = true
            member.hidden = false
            coordinated = true
        end
    end
    return coordinated
end

return M
