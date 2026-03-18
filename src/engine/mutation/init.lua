-- engine/mutation/init.lua
-- The rewrite engine: replaces a live object definition with a new one.
-- This is the only place in the engine that performs a hot-swap.
-- Supports template-based objects and multi-surface containment preservation.

local mutation = {}

-- mutate(registry, loader, object_id, new_source, templates)
--   -> new_object, nil  |  nil, error_string
--
-- Loads new_source into a fresh table, carries over containment references
-- from the old object (location, container, surface contents), then replaces
-- the registry entry. If `templates` is provided and the new object has a
-- `template` field, resolves it before registration.
function mutation.mutate(reg, ldr, object_id, new_source, templates)
  local old = reg:get(object_id)
  if not old then
    return nil, "mutation: object '" .. tostring(object_id) .. "' not found in registry"
  end

  local new_obj, err = ldr.load_source(new_source)
  if not new_obj then
    return nil, err
  end

  -- Resolve template if present
  if new_obj.template and templates then
    new_obj, err = ldr.resolve_template(new_obj, templates)
    if not new_obj then
      return nil, err
    end
  end

  -- Preserve containment references so the object stays in the world.
  new_obj.location  = old.location
  new_obj.container = old.container

  -- Preserve surface contents across mutations.
  -- If both old and new objects have surfaces, carry contents from matching zones.
  if old.surfaces and new_obj.surfaces then
    for surface_name, old_zone in pairs(old.surfaces) do
      if new_obj.surfaces[surface_name] and old_zone.contents then
        new_obj.surfaces[surface_name].contents = old_zone.contents
      end
    end
  end

  -- If old had root contents and new has root contents, preserve them.
  if old.contents and #old.contents > 0 and not new_obj.surfaces then
    new_obj.contents = old.contents
  end

  reg:register(object_id, new_obj)
  return new_obj, nil
end

return mutation
