-- engine/creatures/respawn.lua
-- Respawn manager: tracks dead creatures with respawn metadata,
-- counts down timers, and spawns new instances when conditions are met.
-- Metadata-driven (Principle 8) — creatures declare respawn behavior.
--
-- Ownership: Bart (Architecture Lead)

local M = {}

---------------------------------------------------------------------------
-- Internal state: pending respawns keyed by original creature guid
---------------------------------------------------------------------------
local pending = {}
-- { guid = { type_id, home_room, timer, ticks_remaining, max_population, template_data } }

---------------------------------------------------------------------------
-- register(creature)
-- Called when a creature with respawn metadata dies.
-- Captures the respawn spec and starts the countdown.
---------------------------------------------------------------------------
function M.register(creature)
    if not creature then return false end
    local rs = creature.respawn
    if not rs or not rs.home_room then return false end
    local key = creature.guid or creature.id
    if not key then return false end
    -- Don't double-register
    if pending[key] then return false end
    pending[key] = {
        type_id = creature._original_type_id or creature.type_id or creature.id,
        home_room = rs.home_room,
        timer = rs.timer or 100,
        ticks_remaining = rs.timer or 100,
        max_population = rs.max_population or 1,
        template_data = creature._respawn_template or nil,
    }
    return true
end

---------------------------------------------------------------------------
-- count_population(registry, type_id, room_id, list_fn)
-- Counts living creatures of a given type in a specific room.
---------------------------------------------------------------------------
local function count_population(registry, type_id, room_id, list_fn)
    local count = 0
    local objects = list_fn(registry)
    for _, obj in ipairs(objects) do
        if obj.animate and obj.alive ~= false then
            local obj_type = obj._original_type_id or obj.type_id or obj.id
            local loc = obj.location
            if type(registry.get_location) == "function" then
                loc = registry:get_location(obj.guid) or loc
            end
            if obj_type == type_id and loc == room_id then
                count = count + 1
            end
        end
    end
    return count
end

---------------------------------------------------------------------------
-- spawn_creature(context, entry, list_fn, get_room_fn)
-- Instantiates a new creature in its home room.
-- Returns true if spawn succeeded.
---------------------------------------------------------------------------
local function spawn_creature(context, entry, list_fn, get_room_fn)
    local reg = context.registry
    if not reg then return false end
    local room = get_room_fn(context, entry.home_room)
    if not room then return false end

    -- Population cap check
    local pop = count_population(reg, entry.type_id, entry.home_room, list_fn)
    if pop >= entry.max_population then return false end

    -- Build new instance from template_data or minimal scaffold
    local new_creature
    if entry.template_data then
        new_creature = {}
        for k, v in pairs(entry.template_data) do
            if type(v) == "table" then
                new_creature[k] = {}
                for kk, vv in pairs(v) do new_creature[k][kk] = vv end
            else
                new_creature[k] = v
            end
        end
    else
        new_creature = {
            id = entry.type_id,
            type_id = entry.type_id,
            animate = true,
            alive = true,
        }
    end

    -- Fresh GUID for the new instance
    new_creature.guid = "{respawn-" .. (entry.type_id or "creature")
        .. "-" .. tostring(os.clock()):gsub("%.", "") .. "}"
    new_creature.animate = true
    new_creature.alive = true
    new_creature.location = entry.home_room
    new_creature._original_type_id = entry.type_id

    -- Reset health to max
    if new_creature.max_health then
        new_creature.health = new_creature.max_health
    end

    -- Register in the object registry
    if type(reg.register) == "function" then
        reg:register(new_creature)
    elseif type(reg.add) == "function" then
        reg:add(new_creature)
    elseif reg._objects then
        reg._objects[new_creature.guid] = new_creature
    end

    -- Set location through registry if supported
    if type(reg.set_location) == "function" then
        reg:set_location(new_creature.guid, entry.home_room)
    end

    return true
end

---------------------------------------------------------------------------
-- tick(context, list_fn, get_room_fn, player_room_id)
-- Advances all respawn timers by one tick. Spawns when ready.
-- list_fn(registry) -> objects[]   (registry abstraction)
-- get_room_fn(context, id) -> room (room lookup)
-- player_room_id: string           (prevents spawn-in-face)
---------------------------------------------------------------------------
function M.tick(context, list_fn, get_room_fn, player_room_id)
    if not context or not context.registry then return end
    local spawned = {}
    for key, entry in pairs(pending) do
        entry.ticks_remaining = entry.ticks_remaining - 1
        if entry.ticks_remaining <= 0 then
            -- Don't spawn if player is watching
            if entry.home_room ~= player_room_id then
                spawn_creature(context, entry, list_fn, get_room_fn)
            else
                -- Reset timer — try again next cycle
                entry.ticks_remaining = entry.timer
            end
            spawned[#spawned + 1] = key
        end
    end
    -- Clear completed entries (spawned or not-in-face reset handled above)
    for _, key in ipairs(spawned) do
        if pending[key] and pending[key].ticks_remaining <= 0 then
            pending[key] = nil
        end
    end
end

---------------------------------------------------------------------------
-- Utility / test API
---------------------------------------------------------------------------
function M.get_pending() return pending end
function M.clear() pending = {} end
function M.count_pending()
    local n = 0
    for _ in pairs(pending) do n = n + 1 end
    return n
end
function M.count_population(registry, type_id, room_id, list_fn)
    return count_population(registry, type_id, room_id, list_fn)
end

return M
