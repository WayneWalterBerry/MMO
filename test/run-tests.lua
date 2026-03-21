-- test/run-tests.lua
-- Discovers and runs all test-*.lua files under test subdirectories.
-- Returns exit code 1 if any test file fails.
--
-- Usage: lua test/run-tests.lua
-- Must be run from the repository root (C:\Users\wayneb\source\repos\MMO).

local SEP = package.config:sub(1, 1) -- \ on Windows, / on Unix

-- Set package path so test files can require their helpers
local repo_root = "."
package.path = repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. package.path

print("========================================")
print("  MMO Test Suite")
print("========================================")

-- Directories to scan for test files
local test_dirs = {
    repo_root .. SEP .. "test" .. SEP .. "parser",
    repo_root .. SEP .. "test" .. SEP .. "inventory",
    repo_root .. SEP .. "test" .. SEP .. "injuries",
}

local is_windows = SEP == "\\"

-- Discover test files across all test directories
local test_entries = {}  -- { filepath, display_name }

for _, test_dir in ipairs(test_dirs) do
    local list_cmd
    if is_windows then
        list_cmd = 'dir /b "' .. test_dir .. '\\test-*.lua" 2>nul'
    else
        list_cmd = 'ls "' .. test_dir .. '"/test-*.lua 2>/dev/null'
    end

    local handle = io.popen(list_cmd)
    if handle then
        for line in handle:lines() do
            local fname = line:match("([^/\\]+)$") or line
            if fname:match("^test%-") and fname:match("%.lua$") and not fname:match("helpers") then
                local subdir = test_dir:match("([^/\\]+)$")
                test_entries[#test_entries + 1] = {
                    filepath = test_dir .. SEP .. fname,
                    display = subdir .. "/" .. fname,
                }
            end
        end
        handle:close()
    end
end

table.sort(test_entries, function(a, b) return a.display < b.display end)

if #test_entries == 0 then
    print("\nNo test files found")
    os.exit(1)
end

print("\nFound " .. #test_entries .. " test file(s):\n")

local total_failed = 0
for _, entry in ipairs(test_entries) do
    local filepath = entry.filepath
    print(">> Running: " .. entry.display)

    -- Run each test file as a subprocess so failures are isolated
    local cmd
    if is_windows then
        cmd = 'lua "' .. filepath .. '" 2>&1'
    else
        cmd = 'lua "' .. filepath .. '" 2>&1'
    end

    local pipe = io.popen(cmd)
    local output = pipe:read("*a")
    local ok, exit_type, code = pipe:close()

    io.write(output)

    -- Check exit code
    if not ok or (code and code ~= 0) then
        total_failed = total_failed + 1
        print(">> " .. entry.display .. " — FAILED\n")
    else
        print(">> " .. entry.display .. " — OK\n")
    end
end

print("========================================")
if total_failed > 0 then
    print("  RESULT: " .. total_failed .. " test file(s) FAILED")
    print("========================================")
    os.exit(1)
else
    print("  RESULT: All " .. #test_entries .. " test file(s) PASSED")
    print("========================================")
    os.exit(0)
end
