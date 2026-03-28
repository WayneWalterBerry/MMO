-- engine/creatures/loot.lua
-- Loot table engine: probabilistic drops from creature metadata.
-- Reads loot_table blocks declared in creature definitions (Principle 8).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

local _loot_counter = 0

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deep_copy(v) end
    return copy
end

-- Resolve a template definition by id, following the same 3-tier pattern
-- used by resolve_byproduct in death.lua: registry → object_sources → base_classes.
local function resolve_template(template_id, context)
    if not template_id or not context then return nil end

    local reg = context.registry
    if reg and type(reg.get) == "function" then
        local obj = reg:get(template_id)
        if obj then return deep_copy(obj) end
    end

    local sources = context.object_sources
    local ldr = context.loader
    if sources and sources[template_id] and ldr and type(ldr.load_source) == "function" then
        local def = ldr.load_source(sources[template_id])
        if def then return deep_copy(def) end
    end

    local base_classes = context.base_classes
    if base_classes then
        for _, def in pairs(base_classes) do
            if def.id == template_id then
                return deep_copy(def)
            end
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- weighted_select(options) -> option | nil
-- Weighted random selection from array of {weight, ...} entries.
-- Sum weights, roll random, walk cumulative. Return selected option.
---------------------------------------------------------------------------
function M.weighted_select(options)
    if not options or #options == 0 then return nil end

    local total = 0
    for _, opt in ipairs(options) do
        total = total + (opt.weight or 0)
    end
    if total == 0 then return nil end

    local roll = math.random() * total
    local cumulative = 0
    for _, opt in ipairs(options) do
        cumulative = cumulative + (opt.weight or 0)
        if roll <= cumulative then
            return opt
        end
    end

    return options[#options]
end

---------------------------------------------------------------------------
-- roll_loot_table(creature, death_context) -> drops[]
-- Main entry point. Reads creature.loot_table metadata and returns array
-- of {template, quantity} drop descriptors.
---------------------------------------------------------------------------
function M.roll_loot_table(creature, death_context)
    local loot = creature and creature.loot_table
    if not loot then return {} end

    local drops = {}

    -- 1. Always drops (100% guaranteed)
    for _, item in ipairs(loot.always or {}) do
        drops[#drops + 1] = { template = item.template, quantity = item.quantity or 1 }
    end

    -- 2. Weighted roll (pick ONE from on_death)
    if loot.on_death then
        local selected = M.weighted_select(loot.on_death)
        if selected and selected.item then
            drops[#drops + 1] = { template = selected.item.template, quantity = 1 }
        end
    end

    -- 3. Variable quantity rolls
    for _, v in ipairs(loot.variable or {}) do
        local qty = math.random(v.min, v.max)
        if qty > 0 then
            drops[#drops + 1] = { template = v.template, quantity = qty }
        end
    end

    -- 4. Conditional drops (based on kill method)
    if death_context and death_context.kill_method then
        local cond = loot.conditional and loot.conditional[death_context.kill_method]
        if cond then
            for _, item in ipairs(cond) do
                drops[#drops + 1] = { template = item.template, quantity = item.quantity or 1 }
            end
        end
    end

    return drops
end

---------------------------------------------------------------------------
-- instantiate_drops(drops, room, context) -> instances[]
-- Takes drops array from roll_loot_table, instantiates each item via
-- context resolution, places on room floor. Handles quantity > 1.
---------------------------------------------------------------------------
function M.instantiate_drops(drops, room, context)
    if not drops or #drops == 0 then return {} end

    local instances = {}
    local reg = context and context.registry

    for _, drop in ipairs(drops) do
        for _ = 1, drop.quantity do
            local obj = resolve_template(drop.template, context)
            if obj then
                _loot_counter = _loot_counter + 1
                local instance_id = drop.template .. "-loot-" .. _loot_counter
                obj.id = instance_id

                if reg and type(reg.register) == "function" then
                    reg:register(instance_id, obj)
                end

                if room then
                    obj.location = room.id
                    room.contents = room.contents or {}
                    room.contents[#room.contents + 1] = instance_id
                end

                instances[#instances + 1] = obj
            end
        end
    end

    return instances
end

-- Reset counter (for deterministic testing)
function M._reset_counter()
    _loot_counter = 0
end

return M
