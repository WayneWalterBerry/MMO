-- test/sound/test-sound-metadata.lua
-- WAVE-1 Track 1D: Validate all objects/creatures with `sounds` tables.
-- Checks: valid .opus filenames, correct key prefixes, matching on_listen
-- and on_feel text properties, no overlap between sensory text and sound fields.
-- Per sound-implementation-plan.md v1.1 Track 1D.

package.path = "src/?.lua;src/?/init.lua;test/?.lua;test/parser/?.lua;" .. package.path

local t = require("test.parser.test-helpers")

local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------

-- List .lua files in a directory (cross-platform)
local function list_lua_files(dir)
    local files = {}
    local cmd
    if is_windows then
        cmd = 'dir /b "' .. dir .. '\\*.lua" 2>nul'
    else
        cmd = 'ls "' .. dir .. '"/*.lua 2>/dev/null'
    end
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            local fname = line:match("([^/\\]+)$") or line
            if fname:match("%.lua$") then
                files[#files + 1] = fname
            end
        end
        handle:close()
    end
    return files
end

-- Safely load a Lua metadata file that returns a table
local function safe_load(filepath)
    local fn, err = loadfile(filepath)
    if not fn then
        return nil, "loadfile failed: " .. tostring(err)
    end
    local ok, result = pcall(fn)
    if not ok then
        return nil, "pcall failed: " .. tostring(result)
    end
    if type(result) ~= "table" then
        return nil, "file did not return a table"
    end
    return result, nil
end

-- Valid key prefix patterns for sounds table
local VALID_PREFIXES = {
    "^on_state_",    -- FSM state entry
    "^on_verb_",     -- verb action
    "^ambient_",     -- continuous/state loop (ambient_loop, ambient_lit, etc.)
    "^on_mutate$",   -- mutation fires
    "^on_traverse$", -- exit traversal
}

local function is_valid_sound_key(key)
    for _, pattern in ipairs(VALID_PREFIXES) do
        if key:match(pattern) then
            return true
        end
    end
    return false
end

-- Sensory text field names (these must be strings, never filenames)
local SENSORY_TEXT_FIELDS = {
    "on_feel", "on_listen", "on_smell", "on_taste",
}

----------------------------------------------------------------------------
-- Scan directories
----------------------------------------------------------------------------

local objects_dir = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects"
local creatures_dir = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures"

local object_files = list_lua_files(objects_dir)
local creature_files = list_lua_files(creatures_dir)

----------------------------------------------------------------------------
-- Suite 1: Discovery
----------------------------------------------------------------------------

t.suite("sound metadata — file discovery")

t.test("found object files to scan", function()
    t.assert_truthy(#object_files > 0,
        "should find object files in " .. objects_dir .. ", got " .. #object_files)
end)

t.test("found creature files to scan", function()
    t.assert_truthy(#creature_files > 0,
        "should find creature files in " .. creatures_dir .. ", got " .. #creature_files)
end)

----------------------------------------------------------------------------
-- Collect all files with sounds tables
----------------------------------------------------------------------------

local sound_objects = {}   -- { filepath, obj, filename }
local load_errors = {}

local function scan_dir(dir, file_list)
    for _, fname in ipairs(file_list) do
        local filepath = dir .. SEP .. fname
        local obj, err = safe_load(filepath)
        if err then
            load_errors[#load_errors + 1] = { file = fname, err = err }
        elseif obj and type(obj.sounds) == "table" then
            sound_objects[#sound_objects + 1] = {
                filepath = filepath,
                filename = fname,
                obj = obj,
            }
        end
    end
end

scan_dir(objects_dir, object_files)
scan_dir(creatures_dir, creature_files)

----------------------------------------------------------------------------
-- Suite 2: Sound table count
----------------------------------------------------------------------------

t.suite("sound metadata — sound table count")

t.test("at least 15 objects/creatures have sounds tables", function()
    t.assert_truthy(#sound_objects >= 15,
        "expected >= 15 files with sounds, got " .. #sound_objects)
end)

t.test("no load errors in scanned files", function()
    if #load_errors > 0 then
        local msgs = {}
        for _, e in ipairs(load_errors) do
            msgs[#msgs + 1] = e.file .. ": " .. e.err
        end
        error("load errors:\n  " .. table.concat(msgs, "\n  "))
    end
end)

print("  INFO: found " .. #sound_objects .. " files with sounds tables")

----------------------------------------------------------------------------
-- Suite 3: Valid .opus filenames
----------------------------------------------------------------------------

t.suite("sound metadata — .opus filenames")

for _, entry in ipairs(sound_objects) do
    t.test(entry.filename .. " — all sound values end in .opus", function()
        local bad = {}
        for key, value in pairs(entry.obj.sounds) do
            if type(value) ~= "string" then
                bad[#bad + 1] = key .. " (not a string: " .. type(value) .. ")"
            elseif not value:match("%.opus$") then
                bad[#bad + 1] = key .. " = " .. value .. " (missing .opus)"
            end
        end
        if #bad > 0 then
            error("invalid sound values:\n    " .. table.concat(bad, "\n    "))
        end
    end)
end

----------------------------------------------------------------------------
-- Suite 4: Valid key prefixes
----------------------------------------------------------------------------

t.suite("sound metadata — key prefixes")

for _, entry in ipairs(sound_objects) do
    t.test(entry.filename .. " — all sound keys have valid prefixes", function()
        local bad = {}
        for key, _ in pairs(entry.obj.sounds) do
            if not is_valid_sound_key(key) then
                bad[#bad + 1] = key
            end
        end
        if #bad > 0 then
            error("invalid sound keys: " .. table.concat(bad, ", ") ..
                  "\n    valid prefixes: on_state_*, on_verb_*, ambient_*, on_mutate, on_traverse")
        end
    end)
end

----------------------------------------------------------------------------
-- Suite 5: Matching on_listen and on_feel (design rule)
----------------------------------------------------------------------------

t.suite("sound metadata — on_listen and on_feel required")

for _, entry in ipairs(sound_objects) do
    local obj = entry.obj

    t.test(entry.filename .. " — has on_feel (primary dark sense)", function()
        t.assert_truthy(type(obj.on_feel) == "string" and #obj.on_feel > 0,
            "objects with sounds must have on_feel text")
    end)

    t.test(entry.filename .. " — has on_listen (auditory text)", function()
        t.assert_truthy(type(obj.on_listen) == "string" and #obj.on_listen > 0,
            "objects with sounds must have on_listen text")
    end)
end

----------------------------------------------------------------------------
-- Suite 6: No overlap — sensory text fields are NOT filenames
----------------------------------------------------------------------------

t.suite("sound metadata — no sensory/filename overlap")

for _, entry in ipairs(sound_objects) do
    t.test(entry.filename .. " — sensory fields are text, not filenames", function()
        local bad = {}
        for _, field in ipairs(SENSORY_TEXT_FIELDS) do
            local val = entry.obj[field]
            if type(val) == "string" and val:match("%.opus$") then
                bad[#bad + 1] = field .. " = " .. val .. " (looks like a filename!)"
            end
        end
        if #bad > 0 then
            error("sensory fields contain .opus filenames:\n    " ..
                  table.concat(bad, "\n    "))
        end
    end)
end

----------------------------------------------------------------------------
-- Suite 7: Sound filenames are not empty strings
----------------------------------------------------------------------------

t.suite("sound metadata — no empty filenames")

for _, entry in ipairs(sound_objects) do
    t.test(entry.filename .. " — no empty sound values", function()
        local bad = {}
        for key, value in pairs(entry.obj.sounds) do
            if type(value) == "string" and #value == 0 then
                bad[#bad + 1] = key
            end
        end
        if #bad > 0 then
            error("empty sound values for keys: " .. table.concat(bad, ", "))
        end
    end)
end

----------------------------------------------------------------------------
-- Results
----------------------------------------------------------------------------

local failed = t.summary()
os.exit(failed > 0 and 1 or 0)
