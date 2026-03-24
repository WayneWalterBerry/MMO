-- engine/factory/init.lua
-- Object instancing factory (Core Principle 5).
-- Creates multiple independent instances from a single base object definition.
-- Each instance gets a unique instance_guid, deep-copied state, and optional
-- per-instance overrides. Instances share the base template's shape but
-- maintain fully independent runtime state.

local factory = {}

---------------------------------------------------------------------------
-- Pure-Lua GUID generator (v4-style, no external dependencies)
---------------------------------------------------------------------------
local guid_seeded = false

local function ensure_seed()
    if not guid_seeded then
        math.randomseed(os.time() + math.floor(os.clock() * 1000))
        -- Burn a few values to improve randomness on some Lua implementations
        for _ = 1, 10 do math.random() end
        guid_seeded = true
    end
end

local function hex4()
    return string.format("%04x", math.random(0, 0xFFFF))
end

-- generate_guid() -> string  e.g. "a1b2c3d4-e5f6-4a7b-8c9d-e0f1a2b3c4d5"
function factory.generate_guid()
    ensure_seed()
    -- UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    -- where y is one of 8, 9, a, b
    local y = string.format("%x", 8 + math.random(0, 3))
    return hex4() .. hex4() .. "-" .. hex4() .. "-4" .. hex4():sub(2)
        .. "-" .. y .. hex4():sub(2) .. "-" .. hex4() .. hex4() .. hex4():sub(1, 4)
end

---------------------------------------------------------------------------
-- Deep merge (local copy — keeps factory self-contained)
---------------------------------------------------------------------------
local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deep_copy(v)
    end
    return copy
end

local function deep_merge(base, override)
    local result = deep_copy(base)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = deep_merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

---------------------------------------------------------------------------
-- factory.create_instances(base, count, options) -> array of instance tables
--
-- Parameters:
--   base    — The base object table (e.g., loaded from match.lua).
--   count   — How many instances to create (>= 1).
--   options — Optional table:
--     id_prefix  : string — prefix for generated ids (default: base.id)
--     overrides  : table  — applied to ALL instances
--     per_instance_overrides : array of tables — per_instance_overrides[i]
--                              is merged onto instance i (1-indexed)
--     location   : string — default location for all instances
--
-- Returns:
--   Array of instance tables, each with:
--     instance_guid — unique runtime GUID
--     id            — "prefix-1", "prefix-2", etc.
--     type_id       — base.guid (traceability back to base definition)
--     All base properties deep-copied (independent state)
--     Overrides applied on top
---------------------------------------------------------------------------
function factory.create_instances(base, count, options)
    assert(type(base) == "table", "factory: base must be a table")
    assert(type(count) == "number" and count >= 1,
           "factory: count must be a number >= 1")

    options = options or {}
    local prefix = options.id_prefix or base.id or "instance"
    local global_overrides = options.overrides or {}
    local per_overrides = options.per_instance_overrides or {}
    local location = options.location

    local instances = {}

    for i = 1, count do
        -- Deep-copy all base properties for independent state
        local inst = deep_copy(base)

        -- Stamp instance identity
        inst.instance_guid = factory.generate_guid()
        inst.id = prefix .. "-" .. tostring(i)
        inst.type_id = base.guid  -- links back to the base definition

        -- The base guid belongs to the definition, not the instance
        inst.guid = nil

        -- Apply global overrides (shared across all instances)
        if next(global_overrides) then
            inst = deep_merge(inst, global_overrides)
        end

        -- Apply per-instance overrides
        if per_overrides[i] then
            inst = deep_merge(inst, per_overrides[i])
        end

        -- Apply location if provided and not overridden
        if location and not inst.location then
            inst.location = location
        end

        instances[#instances + 1] = inst
    end

    return instances
end

---------------------------------------------------------------------------
-- factory.create_one(base, overrides) -> single instance table
-- Convenience wrapper for creating exactly one instance.
---------------------------------------------------------------------------
function factory.create_one(base, overrides)
    local instances = factory.create_instances(base, 1, {
        overrides = overrides or {},
    })
    return instances[1]
end

return factory
