-- engine/loader/init.lua
-- Sandboxed loader: accepts a Lua source string, returns a live table.
-- The sandbox deliberately excludes os, io, and other dangerous globals.
-- Also handles template resolution — merging base templates under instances.

local loader = {}

-- Minimal safe environment available to all loaded object code.
local function make_sandbox()
  return {
    ipairs   = ipairs,
    pairs    = pairs,
    next     = next,
    select   = select,
    tonumber = tonumber,
    tostring = tostring,
    type     = type,
    unpack   = unpack or table.unpack,
    error    = error,
    pcall    = pcall,
    math     = math,
    string   = string,
    table    = table,
  }
end

-- deep_merge(base, override) -> merged table
-- Copies all fields from base into a new table, then overlays override on top.
-- Nested tables are recursively merged (arrays are replaced, not appended).
-- The override always wins for any key it defines.
local function deep_merge(base, override)
  local result = {}

  -- Copy base values
  for k, v in pairs(base) do
    if type(v) == "table" then
      result[k] = deep_merge(v, {})
    else
      result[k] = v
    end
  end

  -- Overlay override values
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end

  return result
end

-- load_source(source) -> table, nil  |  nil, error_string
-- Executes `source` inside the sandbox and returns whatever the chunk returns.
-- The source is expected to return a Lua table (the object definition).
function loader.load_source(source)
  local env = make_sandbox()

  -- Lua 5.1 uses loadstring; 5.2+ uses load() with an env argument.
  local chunk, err
  if _VERSION == "Lua 5.1" then
    chunk, err = loadstring(source)
    if chunk then setfenv(chunk, env) end
  else
    chunk, err = load(source, "object", "t", env)
  end

  if not chunk then
    return nil, "compile error: " .. tostring(err)
  end

  local ok, result = pcall(chunk)
  if not ok then
    return nil, "runtime error: " .. tostring(result)
  end

  if type(result) ~= "table" then
    return nil, "object source must return a table, got " .. type(result)
  end

  return result, nil
end

-- resolve_template(object, templates) -> resolved_object, nil | nil, error_string
-- If the object has a `template` field, looks up the template by id in the
-- templates table and merges base properties under the instance's overrides.
-- The instance always wins. The `template` field is removed after resolution.
function loader.resolve_template(object, templates)
  if not object.template then
    return object, nil
  end

  local template_id = object.template
  local tmpl = templates[template_id]
  if not tmpl then
    return nil, "template '" .. tostring(template_id) .. "' not found"
  end

  local resolved = deep_merge(tmpl, object)
  resolved.template = nil  -- consumed; no longer needed at runtime
  return resolved, nil
end

-- load_template(source) -> table, nil | nil, error_string
-- Convenience: loads a template source string. Identical to load_source,
-- but named separately for clarity in calling code.
function loader.load_template(source)
  return loader.load_source(source)
end

return loader
