-- test/run-tests.lua
-- Discovers and runs all test-*.lua files under test/parser/.
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
print("  MMO Parser Test Suite")
print("========================================")

-- Discover test files using a portable approach
local test_dir = repo_root .. SEP .. "test" .. SEP .. "parser"
local test_files = {}

-- Use os.execute + dir/ls to list files
local is_windows = SEP == "\\"
local list_cmd
if is_windows then
    list_cmd = 'dir /b "' .. test_dir .. '\\test-*.lua" 2>nul'
else
    list_cmd = 'ls "' .. test_dir .. '"/test-*.lua 2>/dev/null'
end

local handle = io.popen(list_cmd)
if handle then
    for line in handle:lines() do
        -- On Windows, dir /b returns just filenames
        local fname = line:match("([^/\\]+)$") or line
        if fname:match("^test%-") and fname:match("%.lua$") and not fname:match("helpers") then
            test_files[#test_files + 1] = fname
        end
    end
    handle:close()
end

table.sort(test_files)

if #test_files == 0 then
    print("\nNo test files found in " .. test_dir)
    os.exit(1)
end

print("\nFound " .. #test_files .. " test file(s):\n")

local total_failed = 0
for _, fname in ipairs(test_files) do
    local filepath = test_dir .. SEP .. fname
    print(">> Running: " .. fname)

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
        print(">> " .. fname .. " — FAILED\n")
    else
        print(">> " .. fname .. " — OK\n")
    end
end

print("========================================")
if total_failed > 0 then
    print("  RESULT: " .. total_failed .. " test file(s) FAILED")
    print("========================================")
    os.exit(1)
else
    print("  RESULT: All " .. #test_files .. " test file(s) PASSED")
    print("========================================")
    os.exit(0)
end
