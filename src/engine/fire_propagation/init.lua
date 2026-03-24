-- engine/fire_propagation/init.lua
-- Fire propagation system (#121).
-- When objects burn, fire can spread to nearby flammable objects.
-- Runs once per game tick (post-command), checking all burning objects in the
-- current room for propagation candidates.
--
-- Proximity model:
--   SAME_SURFACE  (items on the same furniture surface)  → highest spread chance
--   SAME_PARENT   (items in the same container/furniture) → medium spread chance
--   SAME_ROOM     (items loose in the same room)          → low spread chance
--
-- Spread chance = proximity_factor × target_flammability × source_intensity
-- A roll below spread_chance means the target ignites.
--
-- Ownership: Bart (Architecture Lead)

local M = {}

-- Lazy-load dependencies to avoid circular requires
local _materials
local function get_materials()
    if _materials then return _materials end
    local ok, mod = pcall(require, "engine.materials")
    if ok then _materials = mod end
    return _materials
end

local _fsm
local function get_fsm()
    if _fsm then return _fsm end
    local ok, mod = pcall(require, "engine.fsm")
    if ok then _fsm = mod end
    return _fsm
end

---------------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------------

-- Minimum material flammability to catch fire (same threshold as burn verb)
M.BURN_THRESHOLD = 0.3

-- Proximity factors: how much proximity contributes to spread chance
M.PROXIMITY = {
    SAME_SURFACE = 0.8,   -- touching on the same shelf/table
    SAME_PARENT  = 0.5,   -- inside the same piece of furniture
    SAME_ROOM    = 0.2,   -- across the room (radiant heat)
}

-- Source intensity: burning objects radiate heat proportional to their
-- material flammability. Higher flammability = fiercer fire = wider spread.
-- Default intensity if the source has no material data.
M.DEFAULT_INTENSITY = 0.6

-- Maximum number of objects that can ignite in a single tick.
-- Prevents runaway chain reactions from consuming the whole room instantly.
M.MAX_IGNITIONS_PER_TICK = 2

---------------------------------------------------------------------------
-- Internal helpers
---------------------------------------------------------------------------

-- Determine whether an object is currently on fire.
-- An object is "burning" if:
--   1. Its FSM state has `casts_light = true` AND it has a burn/fire-related state name, OR
--   2. Its FSM state name contains "burning" or "lit" (convention), OR
--   3. It has `is_burning = true` flag (simple objects).
local function is_burning(obj)
    if not obj then return false end

    -- Explicit flag (set by propagation itself)
    if obj.is_burning then return true end

    -- FSM-based: check current state
    if obj._state and obj.states then
        local state_name = obj._state
        if state_name == "burning" then return true end
        local state_data = obj.states[state_name]
        if state_data and state_data.is_burning then return true end
    end

    return false
end

-- Get the fire intensity of a burning source object.
-- Hotter materials spread fire more aggressively.
local function source_intensity(obj)
    local mats = get_materials()
    if not mats or not obj.material then return M.DEFAULT_INTENSITY end
    local mat = mats.get(obj.material)
    if not mat then return M.DEFAULT_INTENSITY end
    return mat.flammability or M.DEFAULT_INTENSITY
end

-- Get the flammability of a target object from its material.
local function target_flammability(obj)
    local mats = get_materials()
    if not mats or not obj.material then return 0 end
    local mat = mats.get(obj.material)
    if not mat then return 0 end
    return mat.flammability or 0
end

-- Check if an object can catch fire (flammable + not already burning/burnt).
local function can_ignite(obj)
    if not obj then return false end
    if is_burning(obj) then return false end

    -- Already burnt out / terminal state
    if obj._state and obj.states then
        local st = obj.states[obj._state]
        if st and st.terminal then return false end
    end

    local flam = target_flammability(obj)
    return flam >= M.BURN_THRESHOLD
end

-- Compute the spread chance from a burning source to a target at given proximity.
-- Returns a number 0–1.
local function spread_chance(source, target_obj, proximity_factor)
    local intensity = source_intensity(source)
    local flam = target_flammability(target_obj)
    return proximity_factor * flam * intensity
end

-- Deterministic roll: uses ctx.fire_rng if available, else math.random.
-- This allows tests to inject a predictable RNG.
local function roll(ctx)
    if ctx.fire_rng then
        return ctx.fire_rng()
    end
    return math.random()
end

---------------------------------------------------------------------------
-- Ignition logic
---------------------------------------------------------------------------

-- Ignite a target object. Tries in order:
--   1. FSM "burn" transition from current state
--   2. Generic destruction (remove from world)
-- Returns a message string describing what happened, or nil.
local function ignite_object(ctx, obj)
    local fsm = get_fsm()

    -- FSM path: look for a "burn" transition from current state
    if fsm and obj._state and obj.states then
        local transitions = obj.transitions or {}
        for _, t in ipairs(transitions) do
            if t.from == obj._state and (t.verb == "burn" or t.verb == "ignite") then
                local trans = fsm.transition(ctx.registry, obj.id, t.to, {})
                if trans then
                    return trans.message
                        or ("The " .. (obj.id or "object") .. " catches fire!")
                end
            end
            -- Check aliases
            if t.from == obj._state and t.aliases then
                for _, alias in ipairs(t.aliases) do
                    if alias == "burn" or alias == "ignite" then
                        local trans = fsm.transition(ctx.registry, obj.id, t.to, {})
                        if trans then
                            return trans.message
                                or ("The " .. (obj.id or "object") .. " catches fire!")
                        end
                    end
                end
            end
        end
    end

    -- Generic destruction: set burning flag, then mark for removal
    -- For simple objects without FSM burn states, we destroy them
    -- but give them one tick of "burning" before removal so the player
    -- has a chance to react next turn.
    obj.is_burning = true
    obj._burn_ticks_remaining = 1
    return "The " .. (obj.name or obj.id or "object"):gsub("^a%s+", "")
        .. " catches fire from the nearby flames!"
end

-- Remove a burnt-out generic object (no FSM) from the world.
local function remove_burnt_object(ctx, obj)
    local reg = ctx.registry
    local room = ctx.current_room

    -- Remove from room contents
    if room and room.contents then
        for i, id in ipairs(room.contents) do
            if id == obj.id then
                table.remove(room.contents, i)
                break
            end
        end
    end

    -- Remove from surface contents
    if room and room.contents then
        for _, parent_id in ipairs(room.contents) do
            local parent = reg:get(parent_id)
            if parent and parent.surfaces then
                for _, zone in pairs(parent.surfaces) do
                    for i, id in ipairs(zone.contents or {}) do
                        if id == obj.id then
                            table.remove(zone.contents, i)
                            break
                        end
                    end
                end
            end
        end
    end

    -- Remove from player hands
    if ctx.player then
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            local hand_id = hand and (type(hand) == "table" and hand.id or hand)
            if hand_id == obj.id then
                ctx.player.hands[i] = nil
            end
        end
    end

    reg:remove(obj.id)
end

---------------------------------------------------------------------------
-- Collector: find all burning and flammable objects in the room
---------------------------------------------------------------------------

-- Collect all objects in the room with their proximity context.
-- Returns two lists:
--   burning:   { { obj=..., parent_id=..., surface_name=... }, ... }
--   flammable: { { obj=..., parent_id=..., surface_name=... }, ... }
local function collect_room_objects(ctx)
    local reg = ctx.registry
    local room = ctx.current_room
    if not room or not room.contents then return {}, {} end

    local burning = {}
    local flammable = {}

    local function classify(obj_id, parent_id, surface_name)
        local obj = reg:get(obj_id)
        if not obj then return end
        if is_burning(obj) then
            burning[#burning + 1] = {
                obj = obj, parent_id = parent_id, surface_name = surface_name
            }
        end
        if can_ignite(obj) then
            flammable[#flammable + 1] = {
                obj = obj, parent_id = parent_id, surface_name = surface_name
            }
        end
    end

    for _, obj_id in ipairs(room.contents) do
        classify(obj_id, nil, nil)
        local obj = reg:get(obj_id)
        if obj and obj.surfaces then
            for sname, zone in pairs(obj.surfaces) do
                for _, item_id in ipairs(zone.contents or {}) do
                    classify(item_id, obj_id, sname)
                end
            end
        end
        if obj and obj.contents then
            for _, item_id in ipairs(obj.contents) do
                classify(item_id, obj_id, "contents")
            end
        end
    end

    -- Also check player hands (burning item in hand can spread to other hand)
    if ctx.player then
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            local hand_id = hand and (type(hand) == "table" and hand.id or hand)
            if hand_id then
                local obj = reg:get(hand_id)
                if obj then
                    if is_burning(obj) then
                        burning[#burning + 1] = {
                            obj = obj, parent_id = "player_hand", surface_name = "hand"
                        }
                    end
                    if can_ignite(obj) then
                        flammable[#flammable + 1] = {
                            obj = obj, parent_id = "player_hand", surface_name = "hand"
                        }
                    end
                end
            end
        end
    end

    return burning, flammable
end

-- Determine the proximity factor between a burning source and a flammable target.
local function get_proximity(source_entry, target_entry)
    -- Same surface on same parent → highest
    if source_entry.parent_id
       and source_entry.parent_id == target_entry.parent_id
       and source_entry.surface_name
       and source_entry.surface_name == target_entry.surface_name then
        return M.PROXIMITY.SAME_SURFACE
    end

    -- Same parent object (different surfaces or contents)
    if source_entry.parent_id
       and source_entry.parent_id == target_entry.parent_id then
        return M.PROXIMITY.SAME_PARENT
    end

    -- Both loose in the room (no parent)
    if not source_entry.parent_id and not target_entry.parent_id then
        return M.PROXIMITY.SAME_ROOM
    end

    -- Default: across the room
    return M.PROXIMITY.SAME_ROOM
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

-- Check if an object is currently burning. Exported for use by other modules.
M.is_burning = is_burning

-- Main tick function. Call once per game tick after FSM processing.
-- Checks all burning objects in the room and attempts to spread fire to
-- nearby flammable objects.
-- Returns a list of message strings describing what happened.
function M.tick(ctx)
    if not ctx or not ctx.registry or not ctx.current_room then return {} end

    local messages = {}

    -- Phase 0: tick down generic burning objects (no FSM)
    local reg = ctx.registry
    local room = ctx.current_room
    local to_remove = {}
    for _, obj_id in ipairs(room and room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.is_burning and obj._burn_ticks_remaining then
            obj._burn_ticks_remaining = obj._burn_ticks_remaining - 1
            if obj._burn_ticks_remaining <= 0 then
                to_remove[#to_remove + 1] = obj
            end
        end
    end
    for _, obj in ipairs(to_remove) do
        remove_burnt_object(ctx, obj)
        messages[#messages + 1] = "The "
            .. (obj.name or obj.id or "object"):gsub("^a%s+", "")
            .. " crumbles to ash."
    end

    -- Phase 1: collect burning sources and flammable targets
    local burning, flammable = collect_room_objects(ctx)
    if #burning == 0 or #flammable == 0 then return messages end

    -- Phase 2: for each burning source, try to spread to nearby flammable targets
    local ignited_count = 0
    local ignited_ids = {}

    for _, src in ipairs(burning) do
        if ignited_count >= M.MAX_IGNITIONS_PER_TICK then break end

        for _, tgt in ipairs(flammable) do
            if ignited_count >= M.MAX_IGNITIONS_PER_TICK then break end
            if ignited_ids[tgt.obj.id] then goto continue end

            local prox = get_proximity(src, tgt)
            local chance = spread_chance(src.obj, tgt.obj, prox)

            if roll(ctx) < chance then
                local msg = ignite_object(ctx, tgt.obj)
                if msg then
                    messages[#messages + 1] = msg
                    ignited_ids[tgt.obj.id] = true
                    ignited_count = ignited_count + 1
                end
            end

            ::continue::
        end
    end

    return messages
end

return M
