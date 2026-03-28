-- engine/creatures/death.lua
-- Creature death reshape: transforms creature instances in-place (D-14).
-- When a creature's health reaches 0 and death_state is declared,
-- the instance metamorphoses into a dead object — same GUID, different shape.
--
-- Ownership: Bart (Architecture Lead)

local M = {}

local inventory_ok, inventory = pcall(require, "engine.creatures.inventory")
if not inventory_ok then inventory = nil end
local loot_ok, loot_engine = pcall(require, "engine.creatures.loot")
if not loot_ok then loot_engine = nil end
local fsm_ok, fsm_mod = pcall(require, "engine.fsm")
if not fsm_ok then fsm_mod = nil end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function normalize_guid(guid)
    if type(guid) ~= "string" then return guid end
    return guid:gsub("^%{(.-)%}$", "%1")
end

local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deep_copy(v) end
    return copy
end

-- Resolve a byproduct object by id, loading on-demand if needed (#281).
local function resolve_byproduct(bp_id, context)
    local reg = context and context.registry
    if reg and type(reg.get) == "function" then
        local obj = reg:get(bp_id)
        if obj then return obj end
    end

    -- On-demand: load from object_sources (keyed by id)
    local sources = context and context.object_sources
    local ldr = context and context.loader
    if sources and sources[bp_id] and ldr and type(ldr.load_source) == "function" then
        local def = ldr.load_source(sources[bp_id])
        if def then
            if reg then reg:register(bp_id, def) end
            return def
        end
    end

    -- Fallback: search base_classes for matching id
    local base_classes = context and context.base_classes
    if base_classes then
        for _, def in pairs(base_classes) do
            if def.id == bp_id then
                local copy = deep_copy(def)
                if reg then reg:register(bp_id, copy) end
                return copy
            end
        end
    end

    return nil
end

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
        -- Start the spoilage timer so timed_events fire
        if fsm_mod and registry then
            fsm_mod.start_timer(registry, instance.id or instance.guid)
        end
    end

    -- Ensure reshaped creature is in room.contents exactly once (#285).
    -- The creature may already be present from initial placement; avoid duplicates.
    if room then
        room.contents = room.contents or {}
        local entry_id = instance.id or instance.guid
        local already_present = false
        for _, eid in ipairs(room.contents) do
            if eid == entry_id then
                already_present = true
                break
            end
        end
        if not already_present then
            room.contents[#room.contents + 1] = entry_id
        end
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

    -- Capture loot_table before reshape (reshape preserves it, but capture
    -- defensively so the engine never depends on field survival order).
    local creature_loot_table = creature.loot_table

    M.reshape_instance(creature, ds, context and context.registry, room)

    -- Instantiate byproducts to room floor, loading on-demand if needed (#281)
    if ds.byproducts and room then
        room.contents = room.contents or {}
        for _, bp_id in ipairs(ds.byproducts) do
            local bp_obj = resolve_byproduct(bp_id, context)
            if bp_obj then
                bp_obj.location = room.id
                room.contents[#room.contents + 1] = bp_obj.id or bp_id
            end
        end
    end

    -- WAVE-2: drop inventory items to room floor (#280)
    if inventory then
        inventory.drop_on_death(creature, room, context)
    end

    -- WAVE-2: roll loot table and place drops on room floor
    if loot_engine and creature_loot_table and room then
        local death_context = {
            kill_method = context and (context.kill_method or context.last_combat_method),
        }
        local drops = loot_engine.roll_loot_table(
            { loot_table = creature_loot_table }, death_context)
        if #drops > 0 then
            loot_engine.instantiate_drops(drops, room, context)
        end
    end

    -- Clear loot_table from reshaped corpse (no longer relevant)
    creature.loot_table = nil

    -- Reshape narration (printed after combat death text)
    if ds.reshape_narration then print(ds.reshape_narration) end
    return true
end

return M
