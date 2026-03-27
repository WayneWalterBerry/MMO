-- engine/creatures/death.lua
-- Creature death reshape: transforms creature instances in-place (D-14).
-- When a creature's health reaches 0 and death_state is declared,
-- the instance metamorphoses into a dead object — same GUID, different shape.
--
-- Ownership: Bart (Architecture Lead)

local M = {}

-- reshape_instance(instance, death_state, registry, room)
-- Transforms a live creature instance into a dead object instance in-place.
-- The creature table is modified directly: template switches, sensory/identity
-- overwrite, creature metadata cleared. GUID is preserved.
function M.reshape_instance(instance, death_state, registry, room)
    -- Switch template (creature -> small-item or furniture)
    instance.template = death_state.template

    -- Overwrite identity
    instance.name = death_state.name
    instance.description = death_state.description
    instance.keywords = death_state.keywords
    instance.room_presence = death_state.room_presence

    -- Overwrite sensory (on_feel is primary dark sense)
    instance.on_feel = death_state.on_feel
    instance.on_smell = death_state.on_smell
    instance.on_listen = death_state.on_listen
    instance.on_taste = death_state.on_taste

    -- Physical properties
    instance.portable = death_state.portable
    instance.size = death_state.size or instance.size
    instance.weight = death_state.weight or instance.weight
    instance.animate = false
    instance.alive = false

    -- Optional metadata overlays
    if death_state.food then instance.food = death_state.food end
    if death_state.crafting then instance.crafting = death_state.crafting end
    if death_state.container then instance.container = death_state.container end

    -- Spoilage FSM (fresh -> bloated -> rotten -> bones)
    if death_state.states then
        instance.states = death_state.states
        instance.initial_state = death_state.initial_state or "fresh"
        instance._state = instance.initial_state
        instance.transitions = death_state.transitions
    end

    -- Register as room object so containment/search/look can find it
    if room then
        room.contents = room.contents or {}
        room.contents[#room.contents + 1] = instance.id or instance.guid
    end

    -- Clear creature-only metadata (no longer animate)
    instance.behavior = nil
    instance.drives = nil
    instance.reactions = nil
    instance.movement = nil
    instance.awareness = nil
    instance.health = nil
    instance.max_health = nil
    instance.body_tree = nil
    instance.combat = nil
end

-- handle_creature_death(creature, context, room) -> bool
-- Orchestrates reshape + byproducts + narration when a creature dies.
-- Returns true if reshape occurred, false if creature has no death_state.
-- Does NOT emit creature_died stimulus — callers handle that separately.
function M.handle_creature_death(creature, context, room)
    if not creature or not creature.death_state then return false end
    local ds = creature.death_state

    M.reshape_instance(creature, ds, context and context.registry, room)

    -- Instantiate byproducts to room floor (e.g., spider silk)
    if ds.byproducts and room then
        room.contents = room.contents or {}
        local reg = context and context.registry
        for _, bp_id in ipairs(ds.byproducts) do
            if reg and type(reg.get) == "function" and reg:get(bp_id) then
                room.contents[#room.contents + 1] = bp_id
            end
        end
    end

    -- Reshape narration (printed after combat death text)
    if ds.reshape_narration then print(ds.reshape_narration) end
    return true
end

return M
