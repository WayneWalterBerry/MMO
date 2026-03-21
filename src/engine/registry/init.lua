-- engine/registry/init.lua
-- The universe's object store: id -> live object table.
-- Every live object in a universe is registered here.
-- Supports weight tracking and category-based queries.

local registry = {}
registry.__index = registry

-- new() -> registry instance
function registry.new()
  return setmetatable({ _objects = {}, _guid_index = {} }, registry)
end

-- register(id, object) -- adds or replaces an object; stamps the id onto the object.
-- Also indexes by guid if the object has one.
function registry:register(id, object)
  assert(type(id) == "string" and id ~= "", "registry: id must be a non-empty string")
  assert(type(object) == "table", "registry: object must be a table")
  object.id = id
  self._objects[id] = object
  if type(object.guid) == "string" and object.guid ~= "" then
    self._guid_index[object.guid] = id
  end
end

-- get(id) -> object | nil
function registry:get(id)
  return self._objects[id]
end

-- find_by_guid(guid) -> object | nil
-- Looks up an object by its definition guid using the guid index.
function registry:find_by_guid(guid)
  local id = self._guid_index[guid]
  if id then return self._objects[id] end
  return nil
end

-- remove(id) -> removed object | nil
function registry:remove(id)
  local obj = self._objects[id]
  if obj and type(obj.guid) == "string" then
    self._guid_index[obj.guid] = nil
  end
  self._objects[id] = nil
  return obj
end

-- list() -> array of all live objects (order undefined)
function registry:list()
  local result = {}
  for _, obj in pairs(self._objects) do
    result[#result + 1] = obj
  end
  return result
end

-- find_by_keyword(keyword) -> first matching object | nil
-- Matches against object.keywords (array of strings) and object.name.
-- BUG-056: also tries singular forms of plural nouns.
function registry:find_by_keyword(keyword)
  local preprocess = require("engine.parser.preprocess")
  local kw = keyword:lower()
  local candidates = { kw }
  for _, s in ipairs(preprocess.singularize(kw)) do
    candidates[#candidates + 1] = s
  end
  for _, try_kw in ipairs(candidates) do
    for _, obj in pairs(self._objects) do
      if obj.name and obj.name:lower() == try_kw then
        return obj
      end
      if type(obj.keywords) == "table" then
        for _, k in ipairs(obj.keywords) do
          if k:lower() == try_kw then return obj end
        end
      end
    end
  end
  return nil
end

-- find_by_category(category) -> array of matching objects
-- Returns all objects that have the given category in their categories list.
function registry:find_by_category(category)
  local result = {}
  local cat = category:lower()
  for _, obj in pairs(self._objects) do
    if type(obj.categories) == "table" then
      for _, c in ipairs(obj.categories) do
        if c:lower() == cat then
          result[#result + 1] = obj
          break
        end
      end
    end
  end
  return result
end

-- total_weight(location_id) -> number
-- Sums the weight of all objects at a given location.
-- Useful for room weight limits or structural checks.
function registry:total_weight(location_id)
  local total = 0
  for _, obj in pairs(self._objects) do
    if obj.location == location_id then
      total = total + (obj.weight or 0)
    end
  end
  return total
end

-- contents_weight(container_id, surface_name) -> number
-- Sums the weight of all objects inside a container (or a specific surface).
function registry:contents_weight(container_id, surface_name)
  local container_obj = self._objects[container_id]
  if not container_obj then return 0 end

  local contents = {}
  if surface_name and container_obj.surfaces and container_obj.surfaces[surface_name] then
    contents = container_obj.surfaces[surface_name].contents or {}
  else
    contents = container_obj.contents or {}
  end

  local total = 0
  for _, item_id in ipairs(contents) do
    local obj = self._objects[item_id]
    if obj then
      total = total + (obj.weight or 0)
    end
  end
  return total
end

return registry
