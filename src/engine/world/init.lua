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

--- select(worlds)
-- Single-world auto-select (Phase 1).
-- 0 worlds = FATAL. 2+ worlds = not implemented.
function M.select(worlds)
    if #worlds == 0 then
        return nil, "FATAL: no worlds found"
    end
    if #worlds > 1 then
        return nil, "world selection not implemented (multiple worlds found)"
    end
    return worlds[1], nil
end

--- get_starting_room(world)
-- Returns the world's starting room ID.
function M.get_starting_room(world)
    return world.starting_room
end

--- load(worlds_dir, list_lua_files, read_file, load_source)
-- Orchestrator: discover → validate each → select.
-- Returns selected world or nil, error.
function M.load(worlds_dir, list_lua_files, read_file, load_source)
    local worlds = M.discover(worlds_dir, list_lua_files, read_file, load_source)
    -- Validate each discovered world
    local valid = {}
    for _, world in ipairs(worlds) do
        local ok, err = M.validate(world)
        if ok then
            valid[#valid + 1] = world
        end
    end
    return M.select(valid)
end

return M
