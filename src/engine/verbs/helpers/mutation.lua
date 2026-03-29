-- engine/verbs/helpers/mutation.lua
-- Mutation and spatial movement helpers.

local core = require("engine.verbs.helpers.core")
local inventory = require("engine.verbs.helpers.inventory")

local M = {}

---------------------------------------------------------------------------
-- Container sensory gating: check if a container's contents are accessible
-- to a given sense.  Uses _state (FSM) — "open" in state name means open.
-- sense: "visual" or "tactile"
-- Returns true if contents should be revealed to that sense.
---------------------------------------------------------------------------
local function container_contents_accessible(obj, sense)
    if not obj._state then return true end
    if obj._state:find("open") then return true end
    -- Closed: transparent containers still allow visual access
    if sense == "visual" and obj.transparent then return true end
    return false
end

---------------------------------------------------------------------------
-- Helper: find a mutation entry on an object for a given verb
-- Checks exact match first, then verb_* patterns (e.g. "break" → "break_mirror")
---------------------------------------------------------------------------
local function find_mutation(obj, verb)
    if not obj or not obj.mutations then return nil end
    if obj.mutations[verb] then return obj.mutations[verb] end
    for key, mut in pairs(obj.mutations) do
        if key:sub(1, #verb + 1) == verb .. "_" then
            return mut
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: spawn objects from a mutation's spawns list
---------------------------------------------------------------------------
local function spawn_objects(ctx, spawns)
    local room = ctx.current_room
    for _, spawn_id in ipairs(spawns) do
        local source = ctx.object_sources[spawn_id]
        if source then
            local spawn_obj, err = ctx.loader.load_source(source)
            if spawn_obj then
                spawn_obj, err = ctx.loader.resolve_template(spawn_obj, ctx.templates)
                if spawn_obj then
                    local actual_id = spawn_id
                    if ctx.registry:get(spawn_id) then
                        local n = 2
                        while ctx.registry:get(spawn_id .. "-" .. n) do n = n + 1 end
                        actual_id = spawn_id .. "-" .. n
                    end
                    spawn_obj.id = actual_id
                    spawn_obj.location = room.id
                    ctx.registry:register(actual_id, spawn_obj)
                    room.contents[#room.contents + 1] = actual_id
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Helper: perform an object mutation (swap or destroy + spawn)
---------------------------------------------------------------------------
local function perform_mutation(ctx, obj, mut_data)
    if mut_data.becomes then
        local source = ctx.object_sources[mut_data.becomes]
        if not source then
            print("Something strange happens, but nothing changes.")
            return false
        end
        local new_obj, err = ctx.mutation.mutate(
            ctx.registry, ctx.loader, obj.id, source, ctx.templates, ctx)
        if not new_obj then
            print("Error: " .. tostring(err))
            return false
        end
        -- Sync hand slot references: mutation replaces the registry entry
        -- but hand slots may still hold the old object table reference.
        if ctx.player then
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local hid = type(hand) == "table" and hand.id or hand
                    if hid == obj.id then
                        ctx.player.hands[i] = new_obj
                    end
                end
            end
        end
    elseif mut_data.spawns then
        -- Destruction: object ceases to exist, spawns replace it
        inventory.remove_from_location(ctx, obj)
        ctx.registry:remove(obj.id)
    end

    if mut_data.spawns then
        spawn_objects(ctx, mut_data.spawns)
    end

    return true
end

---------------------------------------------------------------------------
-- Spatial movement: push/pull/move objects with spatial relationships
---------------------------------------------------------------------------
local function move_spatial_object(ctx, obj, verb)
    local room = ctx.current_room
    local reg = ctx.registry

    -- Not movable
    if not obj.movable then
        if obj.weight and obj.weight >= 50 then
            print("You strain against " .. (obj.name or "it") .. ", but it won't budge. It's far too heavy to move.")
        else
            print("You can't move " .. (obj.name or "that") .. ".")
        end
        return
    end

    -- Already moved
    if obj.moved then
        print("You've already moved " .. (obj.name or "that") .. ".")
        return
    end

    -- Check if anything is resting on this object (prevents movement)
    for _, obj_id in ipairs(room.contents or {}) do
        local other = reg:get(obj_id)
        if other and other.resting_on == obj.id and not other.moved then
            print((other.name or "Something") .. " is sitting on " .. (obj.name or "it") .. ". You need to move it first.")
            return
        end
    end

    -- Perform the move
    obj.moved = true

    -- Print movement message (verb-specific → generic → fallback)
    local verb_msg_key = verb .. "_message"
    if obj[verb_msg_key] then
        print(obj[verb_msg_key])
    elseif obj.move_message then
        print(obj.move_message)
    else
        print("You " .. verb .. " " .. (obj.name or "it") .. " aside.")
    end

    -- Fire on_move callback if the object declares one (#111)
    if obj.on_move and type(obj.on_move) == "function" then
        obj:on_move(ctx, verb)
    end

    -- Clear resting_on relationship
    if obj.resting_on then
        obj.resting_on = nil
    end

    -- Update description/presence for moved state
    if obj.moved_room_presence then
        obj.room_presence = obj.moved_room_presence
    end
    if obj.moved_description then
        obj.description = obj.moved_description
    end
    if obj.moved_on_feel then
        obj.on_feel = obj.moved_on_feel
    end

    -- If this is a covering object, dump underneath surface items to floor
    if obj.covering and obj.surfaces and obj.surfaces.underneath then
        local underneath = obj.surfaces.underneath
        underneath.accessible = true   -- reveal surface after move (#26)
        for i = #(underneath.contents or {}), 1, -1 do
            local item_id = underneath.contents[i]
            room.contents[#room.contents + 1] = item_id
            local item = reg:get(item_id)
            if item then
                item.location = room.id
                print("Something clatters to the floor -- " .. (item.name or item_id) .. "!")
            end
            table.remove(underneath.contents, i)
        end
    end

    -- Reveal covered objects
    if obj.covering then
        for _, covered_id in ipairs(obj.covering) do
            local covered = reg:get(covered_id)
            local is_hidden = covered and (covered.hidden or (covered.states and covered._state == "hidden"))
            if is_hidden then
                -- FSM reveal transition
                if covered.states and covered._state == "hidden" then
                    local transitioned = false
                    for _, t in ipairs(covered.transitions or {}) do
                        if t.from == "hidden" then
                            core.fsm_mod.transition(reg, covered_id, t.to, {})
                            transitioned = true
                            break
                        end
                    end
                    if not transitioned then
                        covered.hidden = false
                    end
                else
                    covered.hidden = false
                end
                -- Discovery message
                if covered.discovery_message then
                    print("")
                    print(covered.discovery_message)
                end
            end
        end
    end
end

M.container_contents_accessible = container_contents_accessible
M.find_mutation = find_mutation
M.spawn_objects = spawn_objects
M.perform_mutation = perform_mutation
M.move_spatial_object = move_spatial_object

return M
