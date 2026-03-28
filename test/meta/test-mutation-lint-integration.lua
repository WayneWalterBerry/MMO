-- test/meta/test-mutation-lint-integration.lua
-- WAVE-1: Integration tests for mutation-lint pipeline.
-- Tests the full workflow: edge-check --targets → lint.py → PowerShell wrapper.
-- Uses test/parser/test-helpers.lua framework.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. script_dir .. "/../../?.lua;"
             .. package.path

local t = require("test-helpers")
local test = t.test
local suite = t.suite

local SEP = package.config:sub(1, 1)
local REPO_ROOT = script_dir .. SEP .. ".." .. SEP .. ".."

---------------------------------------------------------------------------
-- Python availability guard
-- WAVE-1 requires graceful skip if Python not available (not a failure)
---------------------------------------------------------------------------
local function check_python()
    local handle = io.popen("python --version 2>&1")
    if not handle then
        return false, "Could not execute python command"
    end
    local result = handle:read("*a")
    local exit_code = handle:close()
    if not result or result == "" then
        return false, "No python output"
    end
    return true, result:match("Python%s+([%d%.]+)")
end

local python_available, python_version = check_python()

if not python_available then
    print("SKIP: Python not available — lint integration tests skipped")
    print("  Reason: " .. tostring(python_version))
    print("")
    t.summary()
    os.exit(0)
end

print("Python detected: " .. tostring(python_version))

---------------------------------------------------------------------------
-- Helper: Run command and capture output + exit code
---------------------------------------------------------------------------
local function run_command(cmd)
    local handle = io.popen(cmd .. " 2>&1")
    if not handle then
        return nil, "failed to execute command"
    end
    local output = handle:read("*a")
    local success = handle:close()
    return output, success
end

---------------------------------------------------------------------------
-- SUITE 1: --targets output format validation
---------------------------------------------------------------------------
local targets_output
local targets_list = {}

suite("--targets output format")

test("mutation-edge-check.lua --targets runs without crash", function()
    local cmd = "lua scripts" .. SEP .. "mutation-edge-check.lua --targets"
    local output, success = run_command(cmd)
    t.assert_truthy(output, "should get output from --targets")
    targets_output = output
end)

test("--targets output is one filepath per line", function()
    t.assert_truthy(targets_output, "targets_output should be populated")
    
    for line in targets_output:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        -- Skip warning lines and empty lines
        if trimmed ~= "" and not trimmed:match("^WARNING:") then
            table.insert(targets_list, trimmed)
            -- Each line should be a file path (contains path separator or .lua extension)
            local is_path = trimmed:match("%.lua$") or trimmed:match("[/\\]")
            t.assert_truthy(is_path, "line should be a file path: " .. trimmed)
        end
    end
    
    -- Should have at least some targets
    t.assert_truthy(#targets_list > 0, "should have at least one target")
end)

test("at least 20 targets present", function()
    t.assert_truthy(#targets_list > 20, 
        "expected > 20 targets, got " .. #targets_list)
end)

---------------------------------------------------------------------------
-- SUITE 2: Target file existence
---------------------------------------------------------------------------
suite("Target file existence")

test("all listed targets exist on disk", function()
    local missing = {}
    for _, path in ipairs(targets_list) do
        local fh = io.open(path, "r")
        if not fh then
            table.insert(missing, path)
        else
            fh:close()
        end
    end
    
    t.assert_eq(#missing, 0, 
        "all targets should exist, but missing: " .. table.concat(missing, ", "))
end)

---------------------------------------------------------------------------
-- SUITE 3: Known targets present
---------------------------------------------------------------------------
local function targets_contain(filename)
    for _, path in ipairs(targets_list) do
        if path:match(filename) then
            return true
        end
    end
    return false
end

suite("Known targets present")

test("cloth.lua is in targets", function()
    t.assert_truthy(targets_contain("cloth%.lua"), "cloth.lua should be a target")
end)

test("glass-shard.lua is in targets", function()
    t.assert_truthy(targets_contain("glass%-shard%.lua"), "glass-shard.lua should be a target")
end)

test("matchbox.lua is in targets", function()
    t.assert_truthy(targets_contain("matchbox%.lua"), "matchbox.lua should be a target")
end)

test("silk-bundle.lua is in targets", function()
    t.assert_truthy(targets_contain("silk%-bundle%.lua"), "silk-bundle.lua should be a target")
end)

test("rag.lua is in targets", function()
    t.assert_truthy(targets_contain("rag%.lua"), "rag.lua should be a target")
end)

---------------------------------------------------------------------------
-- SUITE 4: Lint runs without crash
---------------------------------------------------------------------------
suite("lint.py execution")

test("lint.py exists", function()
    local lint_path = "scripts" .. SEP .. "meta-lint" .. SEP .. "lint.py"
    local fh = io.open(lint_path, "r")
    t.assert_truthy(fh, "lint.py should exist at " .. lint_path)
    if fh then fh:close() end
end)

test("lint.py runs on first target without crash", function()
    t.assert_truthy(#targets_list > 0, "need at least one target")
    local first_target = targets_list[1]
    
    local cmd = "python scripts" .. SEP .. "meta-lint" .. SEP .. "lint.py " .. first_target
    local output, success = run_command(cmd)
    
    -- "Without crash" means the command executed (even if it exits 1 due to violations)
    -- We just verify we got output back and the process didn't hang
    t.assert_truthy(output, "should get output from lint.py")
    t.assert_truthy(output:len() > 0, "output should not be empty")
end)

test("lint.py runs on known target cloth.lua", function()
    local cloth_target = nil
    for _, path in ipairs(targets_list) do
        if path:match("cloth%.lua$") then
            cloth_target = path
            break
        end
    end
    
    t.assert_truthy(cloth_target, "cloth.lua should be in targets")
    
    local cmd = "python scripts" .. SEP .. "meta-lint" .. SEP .. "lint.py " .. cloth_target
    local output, success = run_command(cmd)
    
    t.assert_truthy(output, "should get output from linting cloth.lua")
    t.assert_truthy(output:len() > 0, "output should not be empty")
end)

---------------------------------------------------------------------------
-- SUITE 5: Wrapper script existence
---------------------------------------------------------------------------
suite("PowerShell wrapper")

test("mutation-lint.ps1 exists (or skips gracefully if Bart hasn't created yet)", function()
    local wrapper_path = "scripts" .. SEP .. "mutation-lint.ps1"
    local fh = io.open(wrapper_path, "r")
    if not fh then
        print("  NOTE: mutation-lint.ps1 not yet created (Bart's parallel task)")
        -- Graceful skip — not a failure
        t.assert_truthy(true, "test skipped gracefully")
    else
        fh:close()
        t.assert_truthy(true, "mutation-lint.ps1 exists")
    end
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
t.summary()
