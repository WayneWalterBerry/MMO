-- engine/materials/init.lua
-- Material registry: loads individual material definitions from src/meta/materials/.
-- Objects reference materials by name (e.g., material = "wax").
-- The engine resolves properties at runtime via materials.get(name).
-- Adding new materials requires only a new .lua file in src/meta/materials/.

local materials = {}
materials.registry = {}

-- Discover and load material files from src/meta/materials/
local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"
local materials_dir = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "materials"

local list_cmd
if is_windows then
    list_cmd = 'dir /b "' .. materials_dir .. SEP .. '*.lua" 2>nul'
else
    list_cmd = 'ls -1 "' .. materials_dir .. '"/*.lua 2>/dev/null'
end

local handle = io.popen(list_cmd)
if handle then
    for line in handle:lines() do
        local fname = line:match("([^/\\]+)$") or line
        if fname:match("%.lua$") then
            local path = materials_dir .. SEP .. fname
            local ok, mat = pcall(dofile, path)
            if ok and type(mat) == "table" and mat.name then
                local name = mat.name
                mat.name = nil
                materials.registry[name] = mat
            end
        end
    end
    handle:close()
end

-- Look up a material's property table by name.
-- Returns the property table or nil if not found.
function materials.get(name)
    if not name then return nil end
    return materials.registry[name]
end

-- Look up a specific property for a material.
-- Returns the property value or nil.
function materials.get_property(name, property)
    local mat = materials.registry[name]
    if not mat then return nil end
    return mat[property]
end

return materials
