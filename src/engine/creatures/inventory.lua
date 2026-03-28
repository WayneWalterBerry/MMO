-- engine/creatures/inventory.lua
-- Creature inventory: validation, death drops, sensory integration.
-- WAVE-2 implementation (Phase 3).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

local VALID_WORN_SLOTS = { head = true, torso = true, arms = true, legs = true, feet = true }
local MAX_HANDS = 2

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

-- Resolve an inventory item GUID to a live object, instantiating from
-- base_classes on demand if the item isn't pre-registered (#280).
local function resolve_item_guid(guid, context)
    local registry = context and context.registry

    -- Try registry GUID index first
    if registry and type(registry.find_by_guid) == "function" then
        local obj = registry:find_by_guid(guid)
        if obj then return obj end
    end

    -- On-demand: instantiate from base_classes (keyed by normalized GUID)
    local base_classes = context and context.base_classes
    if base_classes then
        local norm = normalize_guid(guid)
        local base = base_classes[norm]
        if base then
            local instance = deep_copy(base)
            if registry and type(registry.register) == "function" then
                local item_id = instance.id or norm
                registry:register(item_id, instance)
            end
            return instance
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- Validation (INV-01 through INV-03)
---------------------------------------------------------------------------

function M.validate(creature, registry)
    if not creature then return false, { "creature is nil" } end
    local inv = creature.inventory
    if not inv then return true, {} end
    if type(inv) ~= "table" then return false, { "inventory must be a table" } end

    local errs = {}
    local id = creature.id or creature.guid or "unknown"

    -- INV-01: hands max 2
    if inv.hands then
        if type(inv.hands) ~= "table" then
            errs[#errs + 1] = "inventory.hands must be a table"
        elseif #inv.hands > MAX_HANDS then
            errs[#errs + 1] = string.format(
                "INV-01: creature %s has %d items in hands; max is %d",
                id, #inv.hands, MAX_HANDS)
        end
    end

    -- INV-02: worn slots valid
    if inv.worn then
        if type(inv.worn) ~= "table" then
            errs[#errs + 1] = "inventory.worn must be a table"
        else
            for slot, _ in pairs(inv.worn) do
                if not VALID_WORN_SLOTS[slot] then
                    errs[#errs + 1] = string.format(
                        "INV-02: creature %s has invalid worn slot '%s'; valid slots are: head, torso, arms, legs, feet",
                        id, tostring(slot))
                end
            end
        end
    end

    -- INV-03: GUID resolution
    if registry and type(registry.get) == "function" then
        local function check_guid(guid)
            if guid and not registry:get(guid) then
                errs[#errs + 1] = string.format(
                    "INV-03: creature %s inventory references non-existent GUID %s",
                    id, tostring(guid))
            end
        end
        if inv.hands then
            for _, guid in ipairs(inv.hands) do check_guid(guid) end
        end
        if inv.worn then
            for _, guid in pairs(inv.worn) do
                if guid then check_guid(guid) end
            end
        end
        if inv.carried then
            for _, guid in ipairs(inv.carried) do check_guid(guid) end
        end
    end

    return #errs == 0, errs
end

---------------------------------------------------------------------------
-- Death drop: scatter inventory items to room floor (#280)
---------------------------------------------------------------------------

function M.drop_on_death(creature, room, context)
    local inv = creature.inventory
    if not inv then return {} end

    local dropped = {}

    -- Collect all item GUIDs from hands, worn, carried
    if inv.hands then
        for _, guid in ipairs(inv.hands) do
            dropped[#dropped + 1] = guid
        end
    end
    if inv.worn then
        for _, guid in pairs(inv.worn) do
            if guid then dropped[#dropped + 1] = guid end
        end
    end
    if inv.carried then
        for _, guid in ipairs(inv.carried) do
            dropped[#dropped + 1] = guid
        end
    end

    -- Resolve each GUID and place item on the room floor
    if room and #dropped > 0 then
        room.contents = room.contents or {}
        for _, guid in ipairs(dropped) do
            local item = resolve_item_guid(guid, context)
            if item then
                item.location = room.id
                room.contents[#room.contents + 1] = item.id or guid
            end
        end
    end

    -- Clear creature inventory (items now on floor)
    creature.inventory = nil

    return dropped
end

---------------------------------------------------------------------------
-- Sensory integration: inventory presence hint
---------------------------------------------------------------------------

function M.presence_hint(creature)
    local inv = creature.inventory
    if not inv then return nil end

    local has_items = false
    if inv.hands and #inv.hands > 0 then has_items = true end
    if not has_items and inv.carried and #inv.carried > 0 then has_items = true end
    if not has_items and inv.worn then
        for _, v in pairs(inv.worn) do
            if v then has_items = true; break end
        end
    end

    if not has_items then return nil end
    return creature.inventory_presence or "something glinting at its feet"
end

---------------------------------------------------------------------------
-- Constants exposed for tests
---------------------------------------------------------------------------
M.VALID_WORN_SLOTS = VALID_WORN_SLOTS
M.MAX_HANDS = MAX_HANDS

return M
