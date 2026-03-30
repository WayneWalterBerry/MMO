-- engine/world/init.lua
-- World loader: discovers, loads, validates, and selects worlds.
-- Follows dependency injection — zero require() calls.
-- World is metadata (context.world), NOT a game entity.
-- See: docs/design/worlds.md, D-WORLDS-CONCEPT

local M = {}

-- Required fields every world must have
local REQUIRED_FIELDS = { "guid", "id", "name", "levels", "starting_room", "theme" }

--- discover(worlds_dir, list_lua_files, read_file, load_source)
-- Scan worlds_dir for subdirectories containing world.lua, load each via sandbox.
-- Also supports legacy .lua files directly in worlds_dir for backward compat.
-- Returns array of world tables (may be empty).
function M.discover(worlds_dir, list_lua_files, read_file, load_source)
    local worlds = {}
    local sep = package.config:sub(1, 1)

    -- Phase 1: Scan for subdirectory-based worlds (worlds/{name}/world.lua)
    local is_windows = sep == "\\"
    local dir_cmd
    if is_windows then
        dir_cmd = 'dir /b /ad "' .. worlds_dir .. '" 2>nul'
    else
        dir_cmd = 'ls -d "' .. worlds_dir .. '"/*/ 2>/dev/null'
    end
    local handle = io.popen(dir_cmd)
    if handle then
        for line in handle:lines() do
            local dirname = line:match("([^/\\]+)/?$") or line
            dirname = dirname:match("^%s*(.-)%s*$")  -- trim
            if dirname and dirname ~= "" then
                local world_file = worlds_dir .. sep .. dirname .. sep .. "world.lua"
                local source = read_file(world_file)
                if source then
                    local tbl, err = load_source(source)
                    if tbl then
                        tbl.content_root = "worlds" .. sep .. dirname
                        worlds[#worlds + 1] = tbl
                    end
                end
            end
        end
        handle:close()
    end

    -- Phase 2: Legacy fallback — scan for .lua files directly in worlds_dir
    if #worlds == 0 then
        local files = list_lua_files(worlds_dir)
        for _, filename in ipairs(files) do
            local path = worlds_dir .. sep .. filename
            local source = read_file(path)
            if source then
                local tbl, err = load_source(source)
                if tbl then
                    worlds[#worlds + 1] = tbl
                end
            end
        end
    end

    return worlds
end

--- validate(world)
-- Check that a world table has all required fields.
-- Returns true or false, error_message.
function M.validate(world)
    if type(world) ~= "table" then
        return false, "world is not a table"
    end
    for _, field in ipairs(REQUIRED_FIELDS) do
        if world[field] == nil then
            return false, "missing required field: " .. field
        end
    end
    if type(world.levels) ~= "table" or #world.levels == 0 then
        return false, "levels must be a non-empty array"
    end
    if type(world.starting_room) ~= "string" or world.starting_room == "" then
        return false, "starting_room must be a non-empty string"
    end
    return true
end

--- select(worlds, world_id)
-- If world_id provided, find by ID. If nil and 1 world, auto-select.
-- If nil and 2+ worlds, return error listing available IDs.
function M.select(worlds, world_id)
    if #worlds == 0 then
        return nil, "FATAL: no worlds found"
    end
    if world_id then
        for _, w in ipairs(worlds) do
            if w.id == world_id then return w, nil end
        end
        local ids = {}
        for _, w in ipairs(worlds) do ids[#ids + 1] = w.id end
        return nil, "world '" .. world_id .. "' not found. Available: " .. table.concat(ids, ", ")
    end
    if #worlds == 1 then
        return worlds[1], nil
    end
    local ids = {}
    for _, w in ipairs(worlds) do ids[#ids + 1] = w.id end
    return nil, "multiple worlds found, use --world <id> to select: " .. table.concat(ids, ", ")
end

--- get_starting_room(world)
-- Returns the world's starting room ID.
function M.get_starting_room(world)
    return world.starting_room
end

--- get_content_paths(world, meta_root)
-- Returns a table of resolved directories for the world's content.
-- If world.content_root is set, paths resolve relative to meta_root.
-- Otherwise, falls back to legacy flat paths under meta_root.
function M.get_content_paths(world, meta_root)
    local sep = package.config:sub(1, 1)
    if world.content_root then
        local base = meta_root .. sep .. world.content_root
        return {
            rooms_dir     = base .. sep .. "rooms",
            objects_dir   = base .. sep .. "objects",
            creatures_dir = base .. sep .. "creatures",
            levels_dir    = base .. sep .. "levels",
        }
    end
    -- Legacy fallback (pre-worlds structure)
    return {
        rooms_dir     = meta_root .. sep .. "rooms",
        objects_dir   = meta_root .. sep .. "objects",
        creatures_dir = meta_root .. sep .. "creatures",
        levels_dir    = meta_root .. sep .. "levels",
    }
end

--- load(worlds_dir, list_lua_files, read_file, load_source, world_id)
-- Orchestrator: discover → validate each → select.
-- Returns selected world or nil, error.
function M.load(worlds_dir, list_lua_files, read_file, load_source, world_id)
    local worlds = M.discover(worlds_dir, list_lua_files, read_file, load_source)
    -- Validate each discovered world
    local valid = {}
    for _, world in ipairs(worlds) do
        local ok, err = M.validate(world)
        if ok then
            valid[#valid + 1] = world
        end
    end
    return M.select(valid, world_id)
end

return M
