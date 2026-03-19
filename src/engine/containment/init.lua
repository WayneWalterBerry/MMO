-- engine/containment/init.lua
-- Four-layer containment validator with weight checking and multi-surface support.
--
-- Layers:
--   1. Container identity -- is the target a container at all?
--   2. Physical size -- does the item physically fit?
--   3. Capacity -- is there room (by size and weight)?
--   4. Category accept/reject -- does the container allow this type of item?
--
-- Multi-surface: when a container has `surfaces`, the validator targets a
-- specific surface (top, inside, underneath, etc.) instead of root-level fields.

local containment = {}

-- Helper: get the containment zone (surface or root) for a container.
-- Returns the zone table and nil, or nil and an error string.
local function get_zone(container_obj, surface_name)
  if container_obj.surfaces and surface_name then
    local zone = container_obj.surfaces[surface_name]
    if not zone then
      return nil, "there is no '" .. surface_name .. "' on " .. (container_obj.name or container_obj.id)
    end
    if zone.accessible == false then
      return nil, "the " .. surface_name .. " of " .. (container_obj.name or container_obj.id) .. " is not accessible"
    end
    return zone, nil
  end

  -- No surfaces defined or no surface specified -- fall back to root-level fields
  if container_obj.surfaces and not surface_name then
    return nil, "you need to specify where on " .. (container_obj.name or container_obj.id) .. " (e.g. top, inside)"
  end

  -- Root-level container fields
  return {
    capacity = container_obj.capacity or 0,
    max_item_size = container_obj.max_item_size,
    weight_capacity = container_obj.weight_capacity,
    contents = container_obj.contents or {},
    accept = container_obj.accept,
    reject = container_obj.reject,
  }, nil
end

-- Helper: sum weights of contents in a zone, using the registry to look up each item.
local function contents_weight(zone, registry)
  local total = 0
  if not zone.contents or not registry then return total end
  for _, item_id in ipairs(zone.contents) do
    local obj = registry:get(item_id)
    if obj then
      total = total + (obj.weight or 0)
    end
  end
  return total
end

-- Helper: sum sizes of contents in a zone, using the registry.
local function contents_size(zone, registry)
  local total = 0
  if not zone.contents or not registry then return total end
  for _, item_id in ipairs(zone.contents) do
    local obj = registry:get(item_id)
    if obj then
      total = total + (obj.size or 0)
    end
  end
  return total
end

-- can_contain(item, container_obj, surface_name, registry)
--   -> true, nil  |  false, reason_string
--
-- Validates all four layers. `surface_name` is optional (nil for root-level).
-- `registry` is optional but required for weight checking.
function containment.can_contain(item, container_obj, surface_name, registry)
  -- Layer 1: Container identity
  if container_obj.surfaces then
    -- Multi-surface objects are containers by definition
  elseif not container_obj.container then
    return false, (container_obj.name or container_obj.id) .. " is not a container"
  end

  -- Get the target zone
  local zone, zone_err = get_zone(container_obj, surface_name)
  if not zone then
    return false, zone_err
  end

  -- Layer 2: Physical size
  local item_size = item.size or 1
  if zone.max_item_size and item_size > zone.max_item_size then
    return false, (item.name or item.id) .. " is too large to fit"
  end

  -- Layer 3a: Size capacity
  local used_size = contents_size(zone, registry)
  local capacity = zone.capacity or 0
  if capacity > 0 and (used_size + item_size) > capacity then
    return false, "there is not enough room"
  end

  -- Layer 3b: Weight capacity
  local item_weight = item.weight or 0
  if zone.weight_capacity and zone.weight_capacity > 0 then
    local used_weight = contents_weight(zone, registry)
    if (used_weight + item_weight) > zone.weight_capacity then
      return false, (item.name or item.id) .. " is too heavy"
    end
  end

  -- Layer 4: Category accept/reject
  if item.categories and type(item.categories) == "table" then
    -- Reject list: if item has any rejected category, deny
    if zone.reject and type(zone.reject) == "table" then
      for _, cat in ipairs(item.categories) do
        for _, rejected in ipairs(zone.reject) do
          if cat == rejected then
            return false, (item.name or item.id) .. " cannot be placed there"
          end
        end
      end
    end

    -- Accept list: if specified, item must have at least one accepted category
    if zone.accept and type(zone.accept) == "table" and #zone.accept > 0 then
      local accepted = false
      for _, cat in ipairs(item.categories) do
        for _, allowed in ipairs(zone.accept) do
          if cat == allowed then
            accepted = true
            break
          end
        end
        if accepted then break end
      end
      if not accepted then
        return false, (item.name or item.id) .. " does not belong there"
      end
    end
  end

  return true, nil
end

return containment
