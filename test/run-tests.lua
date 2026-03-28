-- test/run-tests.lua
-- Discovers and runs all test-*.lua files under test subdirectories.
-- Returns exit code 1 if any test file fails.
--
-- Usage: lua test/run-tests.lua [--bench] [--shard <name>] [--changed]
--   --bench          Also discover and run bench-*.lua benchmark files
--   --shard <name>   Run only test directories matching shard name (for CI matrix)
--   --changed        Only run tests for directories affected by git-diff changes
-- Must be run from the repository root (C:\Users\wayneb\source\repos\MMO).

local SEP = package.config:sub(1, 1) -- \ on Windows, / on Unix

-- Parse CLI flags
local include_bench = false
local shard_filter = nil
local changed_only = false
for i, a in ipairs(arg or {}) do
    if a == "--bench" then
        include_bench = true
    elseif a == "--shard" and arg[i + 1] then
        shard_filter = arg[i + 1]
    elseif a == "--changed" then
        changed_only = true
    end
end

-- Set package path so test files can require their helpers
local repo_root = "."
package.path = repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. package.path

-- Directories to scan for test files
local test_dirs = {
    repo_root .. SEP .. "test" .. SEP .. "parser",
    repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "pipeline",
    repo_root .. SEP .. "test" .. SEP .. "inventory",
    repo_root .. SEP .. "test" .. SEP .. "injuries",
    repo_root .. SEP .. "test" .. SEP .. "verbs",
    repo_root .. SEP .. "test" .. SEP .. "search",
    repo_root .. SEP .. "test" .. SEP .. "nightstand",
    repo_root .. SEP .. "test" .. SEP .. "integration",
    repo_root .. SEP .. "test" .. SEP .. "ui",
    repo_root .. SEP .. "test" .. SEP .. "rooms",
    repo_root .. SEP .. "test" .. SEP .. "objects",
    repo_root .. SEP .. "test" .. SEP .. "armor",
    repo_root .. SEP .. "test" .. SEP .. "wearables",
    repo_root .. SEP .. "test" .. SEP .. "sensory",
    repo_root .. SEP .. "test" .. SEP .. "fsm",
    repo_root .. SEP .. "test" .. SEP .. "creatures",
    repo_root .. SEP .. "test" .. SEP .. "combat",
    repo_root .. SEP .. "test" .. SEP .. "food",
    repo_root .. SEP .. "test" .. SEP .. "butchery",
    repo_root .. SEP .. "test" .. SEP .. "loot",
    repo_root .. SEP .. "test" .. SEP .. "stress",
    repo_root .. SEP .. "test" .. SEP .. "crafting",
    repo_root .. SEP .. "test" .. SEP .. "engine",
}

-- Source-to-test mapping for --changed flag
local source_to_tests = {
    ["src/engine/verbs/"]       = {"verbs"},
    ["src/engine/parser/"]      = {"parser"},
    ["src/engine/fsm/"]         = {"fsm"},
    ["src/engine/containment/"] = {"inventory", "search"},
    ["src/engine/injuries/"]    = {"injuries", "stress"},
    ["src/engine/creatures/"]   = {"creatures", "combat"},
    ["src/engine/ui/"]          = {"ui"},
    ["src/meta/objects/"]       = {"objects", "sensory"},
    ["src/meta/world/"]         = {"rooms"},
    ["src/meta/injuries/"]      = {"injuries"},
    ["src/engine/effects.lua"]  = {"verbs", "integration"},
    ["src/engine/display.lua"]  = {"ui"},
    -- Engine core changes → run everything (nil = run all)
    ["src/engine/registry/"]    = nil,
    ["src/engine/loader/"]      = nil,
    ["src/engine/loop/"]        = nil,
    ["src/engine/mutation/"]    = nil,
    ["src/main.lua"]            = nil,
    -- Test changes → run the changed test's directory
    ["test/"]                   = "self",
}

-- Git-diff-based incremental test filtering
local changed_run_all = false
local changed_needed_dirs = {}
if changed_only then
    local changed_files = {}

    -- Staged changes (committed vs HEAD)
    local staged_pipe = io.popen("git diff --name-only HEAD 2>nul")
    if staged_pipe then
        for line in staged_pipe:lines() do
            changed_files[#changed_files + 1] = line
        end
        staged_pipe:close()
    end

    -- Unstaged changes (working tree vs index)
    local unstaged_pipe = io.popen("git diff --name-only 2>nul")
    if unstaged_pipe then
        for line in unstaged_pipe:lines() do
            changed_files[#changed_files + 1] = line
        end
        unstaged_pipe:close()
    end

    for _, file in ipairs(changed_files) do
        -- Normalize backslashes to forward slashes for matching
        local norm = file:gsub("\\", "/")
        local matched = false
        for prefix, test_dirs_for_prefix in pairs(source_to_tests) do
            if norm:find(prefix, 1, true) == 1 then
                matched = true
                if test_dirs_for_prefix == nil then
                    changed_run_all = true
                    break
                elseif test_dirs_for_prefix == "self" then
                    local dir = norm:match("test/([^/]+)/")
                    if dir then changed_needed_dirs[dir] = true end
                else
                    for _, d in ipairs(test_dirs_for_prefix) do
                        changed_needed_dirs[d] = true
                    end
                end
            end
        end
        if changed_run_all then break end
        -- Unmatched files outside safe-to-skip paths → conservative, run all
        if not matched and not norm:match("^docs/")
                       and not norm:match("^plans/")
                       and not norm:match("^%.squad/")
                       and not norm:match("^resources/")
                       and not norm:match("^web/")
                       and not norm:match("^scripts/") then
            changed_run_all = true
            break
        end
    end

    if not changed_run_all and next(changed_needed_dirs) then
        -- Filter test_dirs to only needed directories
        local filtered = {}
        for _, dir in ipairs(test_dirs) do
            local dir_name = dir:match("([^/\\]+)$")
            if changed_needed_dirs[dir_name] then
                filtered[#filtered + 1] = dir
            end
        end
        test_dirs = filtered
    end
    -- If changed_run_all or no changes found, run everything (safe default)
end

-- Shard group definitions for CI matrix sharding
-- Each named shard maps to the directory basenames it covers.
-- Subdirectories (e.g., parser/pipeline) are matched via parent_name.
-- "other" catches everything not covered by any named shard.
local shard_groups = {
    parser    = {"parser"},
    verbs     = {"verbs"},
    creatures = {"creatures", "combat"},
    rooms     = {"rooms", "integration"},
    search    = {"search", "inventory", "nightstand"},
}

-- Filter directories by shard name
if shard_filter then
    if shard_filter == "other" then
        -- Collect all directory names covered by named shards
        local covered = {}
        for _, group in pairs(shard_groups) do
            for _, name in ipairs(group) do
                covered[name] = true
            end
        end
        local filtered = {}
        for _, dir in ipairs(test_dirs) do
            local dir_name = dir:match("([^/\\]+)$")
            local parent_name = dir:match("([^/\\]+)[/\\][^/\\]+$")
            if not covered[dir_name] and not covered[parent_name or ""] then
                filtered[#filtered + 1] = dir
            end
        end
        test_dirs = filtered
    else
        -- Build match set from shard group (or use shard name directly)
        local group = shard_groups[shard_filter]
        local match_set = {}
        if group then
            for _, name in ipairs(group) do match_set[name] = true end
        else
            match_set[shard_filter] = true
        end
        local filtered = {}
        for _, dir in ipairs(test_dirs) do
            local dir_name = dir:match("([^/\\]+)$")
            local parent_name = dir:match("([^/\\]+)[/\\][^/\\]+$")
            if match_set[dir_name] or match_set[parent_name or ""] then
                filtered[#filtered + 1] = dir
            end
        end
        if #filtered == 0 then
            print("No test directories match shard: " .. shard_filter)
            os.exit(1)
        end
        test_dirs = filtered
    end
end

-- Print suite header (after all filtering is resolved)
print("========================================")
print("  MMO Test Suite")
if include_bench then
    print("  (including benchmarks)")
end
if shard_filter then
    print("  (shard: " .. shard_filter .. ")")
end
if changed_only then
    if changed_run_all then
        print("  (--changed: core change detected, running all)")
    elseif next(changed_needed_dirs) then
        local dirs = {}
        for d in pairs(changed_needed_dirs) do dirs[#dirs + 1] = d end
        table.sort(dirs)
        print("  (--changed: " .. table.concat(dirs, ", ") .. ")")
    else
        print("  (--changed: no changes detected, running all)")
    end
end
print("========================================")

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

    -- Discover bench-*.lua files when --bench is set
    if include_bench then
        local bench_cmd
        if is_windows then
            bench_cmd = 'dir /b "' .. test_dir .. '\\bench-*.lua" 2>nul'
        else
            bench_cmd = 'ls "' .. test_dir .. '"/bench-*.lua 2>/dev/null'
        end
        local bench_handle = io.popen(bench_cmd)
        if bench_handle then
            for line in bench_handle:lines() do
                local fname = line:match("([^/\\]+)$") or line
                if fname:match("^bench%-") and fname:match("%.lua$") then
                    local subdir = test_dir:match("([^/\\]+)$")
                    test_entries[#test_entries + 1] = {
                        filepath = test_dir .. SEP .. fname,
                        display = subdir .. "/" .. fname,
                    }
                end
            end
            bench_handle:close()
        end
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
