-- test/meta/test-edge-extractor.lua
-- WAVE-0: Tests for scripts/mutation-edge-check.lua edge extractor.
-- Uses test/parser/test-helpers.lua framework.
--
-- NOTE: assert_gt/assert_gte don't exist in test-helpers.lua.
-- Use assert_truthy(count > N, msg) for threshold assertions.
--
-- Depends on Bart's scripts/mutation-edge-check.lua — tests skip gracefully
-- if the module is not yet available.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. script_dir .. "/../../?.lua;"
             .. script_dir .. "/../../scripts/?.lua;"
             .. package.path

local t = require("test-helpers")
local test = t.test
local suite = t.suite

local SEP = package.config:sub(1, 1)
local REPO_ROOT = script_dir .. SEP .. ".." .. SEP .. ".."
local META_ROOT = REPO_ROOT .. SEP .. "src" .. SEP .. "meta"
local SCRIPT_PATH = REPO_ROOT .. SEP .. "scripts" .. SEP .. "mutation-edge-check.lua"

---------------------------------------------------------------------------
-- Load the extractor's local functions by source injection.
-- The script uses all-local functions and calls main() at the bottom.
-- We strip the final main() call, stub os.exit, and append an export table.
---------------------------------------------------------------------------
local function load_extractor()
    local fh, err = io.open(SCRIPT_PATH, "r")
    if not fh then return nil, "cannot open: " .. tostring(err) end
    local source = fh:read("*a")
    fh:close()

    -- Strip the trailing main() invocation so it doesn't auto-run
    source = source:gsub("[\r\n]+main%(%)[%s]*$", "")

    -- Append an export table that captures the local functions
    source = source .. "\n"
        .. "return {\n"
        .. "  scan_meta_root = scan_meta_root,\n"
        .. "  safe_load = safe_load,\n"
        .. "  extract_edges = extract_edges,\n"
        .. "  resolve_target = resolve_target,\n"
        .. "  main = main,\n"
        .. "}\n"

    -- Load with os.exit stubbed out
    local load_fn = loadstring or load
    local chunk, lerr = load_fn(source, "@" .. SCRIPT_PATH)
    if not chunk then return nil, "load error: " .. tostring(lerr) end

    -- Override os.exit in the chunk's environment so main() won't kill us
    local saved_exit = os.exit
    os.exit = function() end
    local ok2, result = pcall(chunk)
    os.exit = saved_exit

    if not ok2 then return nil, "exec error: " .. tostring(result) end
    if type(result) ~= "table" then return nil, "script did not return a table" end
    return result, nil
end

local extractor, load_err = load_extractor()

if not extractor then
    print("SKIP: scripts/mutation-edge-check.lua not available yet (Bart's deliverable)")
    print("  " .. tostring(load_err))
    print("  Tests will run once the extractor script is ready.")
    print("")
    t.summary()
    os.exit(0)
end

-- Wrap extractor.main to suppress stdout and prevent os.exit
local _raw_main = extractor.main
extractor.main = function(root)
    local saved_print = print
    local saved_exit = os.exit
    local captured = {}
    print = function(...) captured[#captured + 1] = table.concat({...}, "\t") end
    os.exit = function() end

    local result = _raw_main(root)

    print = saved_print
    os.exit = saved_exit
    return result
end

-- Run the full pipeline using extracted functions and return structured results.
-- main() only prints/exits; this gives us data to assert on.
local function run_pipeline(root)
    root = root or META_ROOT
    local files = extractor.scan_meta_root(root)
    local file_map = {}
    for _, f in ipairs(files) do file_map[f.id] = f.filepath end

    local all_edges, all_dynamics = {}, {}
    for _, f in ipairs(files) do
        local obj, err = extractor.safe_load(f.filepath)
        if obj then
            local edges, dynamics = extractor.extract_edges(obj, f.id, f.filepath)
            for _, e in ipairs(edges) do all_edges[#all_edges + 1] = e end
            for _, d in ipairs(dynamics) do all_dynamics[#all_dynamics + 1] = d end
        end
    end

    local broken, valid_targets = {}, {}
    for _, edge in ipairs(all_edges) do
        if extractor.resolve_target(edge.target, file_map) then
            valid_targets[#valid_targets + 1] = edge
        else
            broken[#broken + 1] = edge
        end
    end

    return {
        files_scanned = #files,
        edges = all_edges,
        broken = broken,
        dynamics = all_dynamics,
        valid_targets = valid_targets,
    }
end

---------------------------------------------------------------------------
-- Helper: build a minimal object table for testing extract_edges
---------------------------------------------------------------------------
local function make_obj(overrides)
    local obj = { id = "test-obj", name = "test object" }
    for k, v in pairs(overrides or {}) do obj[k] = v end
    return obj
end

---------------------------------------------------------------------------
-- Suite 1: File scanning (~7 tests)
---------------------------------------------------------------------------
suite("File scanning")

test("scan_meta_root returns a table", function()
    local files = extractor.scan_meta_root(META_ROOT)
    t.assert_truthy(type(files) == "table", "expected table from scan_meta_root")
end)

test("scan discovers > 150 .lua files", function()
    local files = extractor.scan_meta_root(META_ROOT)
    t.assert_truthy(#files > 150,
        "expected > 150 files, got " .. #files)
end)

test("scan finds files in objects/ subdir", function()
    local files = extractor.scan_meta_root(META_ROOT)
    local found = false
    for _, f in ipairs(files) do
        if f.filepath:match("objects") then found = true; break end
    end
    t.assert_truthy(found, "expected files from objects/ subdir")
end)

test("scan finds files in materials/ subdir", function()
    local files = extractor.scan_meta_root(META_ROOT)
    local found = false
    for _, f in ipairs(files) do
        if f.filepath:match("materials") then found = true; break end
    end
    t.assert_truthy(found, "expected files from materials/ subdir")
end)

test("scan finds files in creatures/ subdir", function()
    local files = extractor.scan_meta_root(META_ROOT)
    local found = false
    for _, f in ipairs(files) do
        if f.filepath:match("creatures") then found = true; break end
    end
    t.assert_truthy(found, "expected files from creatures/ subdir")
end)

test("scan finds files in injuries/ subdir", function()
    local files = extractor.scan_meta_root(META_ROOT)
    local found = false
    for _, f in ipairs(files) do
        if f.filepath:match("injuries") then found = true; break end
    end
    t.assert_truthy(found, "expected files from injuries/ subdir")
end)

test("scan discovers >= 7 subdirectories", function()
    local files, subdirs = extractor.scan_meta_root(META_ROOT)
    t.assert_truthy(type(subdirs) == "table",
        "expected subdirs table as second return value")
    t.assert_truthy(#subdirs >= 7,
        "expected >= 7 subdirs, got " .. #subdirs)
end)

---------------------------------------------------------------------------
-- Suite 2: Sandbox loading (~7 tests)
---------------------------------------------------------------------------
suite("Sandbox loading")

test("safe_load returns a table for valid object file", function()
    local obj, err = extractor.safe_load(META_ROOT .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "candle.lua")
    t.assert_truthy(type(obj) == "table",
        "expected table, got " .. type(tostring(obj)) .. " err=" .. tostring(err))
end)

test("safe_load returns id field from loaded object", function()
    local obj = extractor.safe_load(META_ROOT .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "candle.lua")
    t.assert_truthy(obj and obj.id, "expected object with id field")
end)

test("safe_load returns nil + error for nonexistent file", function()
    local obj, err = extractor.safe_load(META_ROOT .. SEP .. "objects" .. SEP .. "DOES-NOT-EXIST.lua")
    t.assert_nil(obj, "expected nil for missing file")
    t.assert_truthy(err, "expected error message for missing file")
end)

test("safe_load returns nil + error for non-table return", function()
    -- Write a temp file that returns a string instead of a table
    local tmppath = REPO_ROOT .. SEP .. "test" .. SEP .. "meta" .. SEP .. "_tmp_bad_return.lua"
    local fh = io.open(tmppath, "w")
    fh:write('return "not a table"')
    fh:close()
    local obj, err = extractor.safe_load(tmppath)
    os.remove(tmppath)
    t.assert_nil(obj, "expected nil for non-table return")
    t.assert_truthy(err and err:find("table"), "expected error about table, got: " .. tostring(err))
end)

test("safe_load sandboxes os.execute", function()
    local tmppath = REPO_ROOT .. SEP .. "test" .. SEP .. "meta" .. SEP .. "_tmp_sandbox.lua"
    local fh = io.open(tmppath, "w")
    fh:write('return { id = "test", check = os ~= nil }')
    fh:close()
    local obj, err = extractor.safe_load(tmppath)
    os.remove(tmppath)
    if obj then
        t.assert_truthy(not obj.check, "os should not be available in sandbox")
    else
        -- If safe_load rejects it, that's also acceptable sandboxing
        t.assert_truthy(true, "sandbox prevented execution")
    end
end)

test("safe_load handles syntax errors gracefully", function()
    local tmppath = REPO_ROOT .. SEP .. "test" .. SEP .. "meta" .. SEP .. "_tmp_syntax.lua"
    local fh = io.open(tmppath, "w")
    fh:write('return {{{INVALID SYNTAX')
    fh:close()
    local obj, err = extractor.safe_load(tmppath)
    os.remove(tmppath)
    t.assert_nil(obj, "expected nil for syntax error")
    t.assert_truthy(err, "expected error message for syntax error")
end)

test("safe_load allows math/string/table in sandbox", function()
    local tmppath = REPO_ROOT .. SEP .. "test" .. SEP .. "meta" .. SEP .. "_tmp_sandbox_ok.lua"
    local fh = io.open(tmppath, "w")
    fh:write('return { id = "test", val = math.floor(3.7), len = string.len("hi") }')
    fh:close()
    local obj, err = extractor.safe_load(tmppath)
    os.remove(tmppath)
    t.assert_truthy(obj, "expected successful load, err=" .. tostring(err))
    t.assert_eq(3, obj.val, "math.floor should work in sandbox")
    t.assert_eq(2, obj.len, "string.len should work in sandbox")
end)

---------------------------------------------------------------------------
-- Suite 3: Edge extraction (~15 tests)
---------------------------------------------------------------------------
suite("Edge extraction")

test("mutations.becomes produces an edge", function()
    local obj = make_obj({ mutations = { break_verb = { becomes = "broken-thing" } } })
    local edges, dynamics = extractor.extract_edges(obj, "test-obj")
    t.assert_truthy(#edges >= 1, "expected at least 1 edge")
    t.assert_eq("broken-thing", edges[1].target, "edge target should be broken-thing")
end)

test("mutations.spawns produces edges", function()
    local obj = make_obj({ mutations = { tear = { becomes = nil, spawns = {"cloth", "rag"} } } })
    local edges = extractor.extract_edges(obj, "test-obj")
    local targets = {}
    for _, e in ipairs(edges) do targets[e.target] = true end
    t.assert_truthy(targets["cloth"], "expected cloth edge")
    t.assert_truthy(targets["rag"], "expected rag edge")
end)

test("duplicate spawn IDs produce separate edges (blanket.lua cloth x2)", function()
    local obj = make_obj({ mutations = { tear = { becomes = nil, spawns = {"cloth", "cloth"} } } })
    local edges = extractor.extract_edges(obj, "test-obj")
    local cloth_count = 0
    for _, e in ipairs(edges) do
        if e.target == "cloth" then cloth_count = cloth_count + 1 end
    end
    t.assert_eq(2, cloth_count, "expected 2 separate cloth edges")
end)

test("transitions[i].spawns produces edges", function()
    local obj = make_obj({
        transitions = {
            { from = "locked", to = "broken", verb = "break", spawns = {"wood-splinters"} },
        }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "wood-splinters" then found = true; break end
    end
    t.assert_truthy(found, "expected wood-splinters edge from transition spawns")
end)

test("crafting.becomes produces an edge", function()
    local obj = make_obj({ crafting = { cook = { becomes = "cooked-thing" } } })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "cooked-thing" then found = true; break end
    end
    t.assert_truthy(found, "expected cooked-thing edge from crafting")
end)

test("on_tool_use.when_depleted produces an edge (synthetic)", function()
    local obj = make_obj({
        on_tool_use = { when_depleted = "used-up-thing" }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "used-up-thing" then found = true; break end
    end
    t.assert_truthy(found, "expected used-up-thing edge from on_tool_use.when_depleted")
end)

test("on_tool_use WITHOUT when_depleted produces no depletion edge (synthetic)", function()
    local obj = make_obj({
        on_tool_use = { consumes_charge = false, use_message = "You use it." }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    t.assert_eq(0, #edges, "expected zero edges for on_tool_use without when_depleted")
end)

test("becomes = nil is NOT an edge (intentional destruction)", function()
    local obj = make_obj({ mutations = { burn = { becomes = nil, message = "Gone." } } })
    local edges = extractor.extract_edges(obj, "test-obj")
    -- Should have no edges since becomes is nil and no spawns
    t.assert_eq(0, #edges, "expected zero edges for becomes=nil with no spawns")
end)

test("empty mutations = {} produces zero edges", function()
    local obj = make_obj({ mutations = {} })
    local edges = extractor.extract_edges(obj, "test-obj")
    t.assert_eq(0, #edges, "expected zero edges for empty mutations table")
end)

test("dynamic = true goes to dynamics, not edges", function()
    local obj = make_obj({
        mutations = { write = { dynamic = true, mutator = "write_on_surface" } }
    })
    local edges, dynamics = extractor.extract_edges(obj, "test-obj")
    t.assert_eq(0, #edges, "dynamic mutation should not produce edges")
    t.assert_truthy(#dynamics >= 1, "expected at least 1 dynamic entry")
end)

test("loot_table.always[].template produces edges", function()
    local obj = make_obj({
        loot_table = { always = { { template = "gnawed-bone" } } }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "gnawed-bone" then found = true; break end
    end
    t.assert_truthy(found, "expected gnawed-bone edge from loot_table.always")
end)

test("loot_table.on_death[].item.template produces edges", function()
    local obj = make_obj({
        loot_table = {
            on_death = {
                { item = { template = "silver-coin" }, weight = 20 },
                { item = nil, weight = 80 },
            }
        }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "silver-coin" then found = true; break end
    end
    t.assert_truthy(found, "expected silver-coin edge from loot_table.on_death")
end)

test("loot_table.variable[].template produces edges", function()
    local obj = make_obj({
        loot_table = { variable = { { template = "copper-coin", min = 0, max = 3 } } }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "copper-coin" then found = true; break end
    end
    t.assert_truthy(found, "expected copper-coin edge from loot_table.variable")
end)

test("loot_table.conditional.{key}[].template produces edges", function()
    local obj = make_obj({
        loot_table = {
            conditional = {
                fire_kill = { { template = "charred-hide" } },
            }
        }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "charred-hide" then found = true; break end
    end
    t.assert_truthy(found, "expected charred-hide edge from loot_table.conditional")
end)

test("death_state.crafting[verb].becomes produces edges", function()
    local obj = make_obj({
        death_state = {
            crafting = { cook = { becomes = "cooked-bat-meat" } }
        }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "cooked-bat-meat" then found = true; break end
    end
    t.assert_truthy(found, "expected cooked-bat-meat edge from death_state.crafting")
end)

test("death_state.butchery_products.products[].id produces edges", function()
    local obj = make_obj({
        death_state = {
            butchery_products = {
                products = {
                    { id = "wolf-meat", quantity = 3 },
                    { id = "wolf-bone", quantity = 2 },
                }
            }
        }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local targets = {}
    for _, e in ipairs(edges) do targets[e.target] = true end
    t.assert_truthy(targets["wolf-meat"], "expected wolf-meat edge from butchery")
    t.assert_truthy(targets["wolf-bone"], "expected wolf-bone edge from butchery")
end)

test("behavior.creates_object.template produces an edge", function()
    local obj = make_obj({
        behavior = { creates_object = { template = "spider-web" } }
    })
    local edges = extractor.extract_edges(obj, "test-obj")
    local found = false
    for _, e in ipairs(edges) do
        if e.target == "spider-web" then found = true; break end
    end
    t.assert_truthy(found, "expected spider-web edge from behavior.creates_object")
end)

---------------------------------------------------------------------------
-- Suite 4: Broken edge detection (~5 tests)
---------------------------------------------------------------------------
suite("Broken edge detection")

test("resolve_target finds existing file in map", function()
    local file_map = { ["candle"] = "src/meta/worlds/manor/objects/candle.lua" }
    local result = extractor.resolve_target("candle", file_map)
    t.assert_truthy(result, "expected to find candle in file_map")
end)

test("resolve_target returns nil for missing target", function()
    local file_map = { ["candle"] = "src/meta/worlds/manor/objects/candle.lua" }
    local result = extractor.resolve_target("does-not-exist", file_map)
    t.assert_nil(result, "expected nil for missing target")
end)

test("full run detects 0 broken edge entries (all targets created)", function()
    local result = run_pipeline()
    t.assert_truthy(result and result.broken,
        "expected result with broken field")
    t.assert_eq(0, #result.broken,
        "expected 0 broken edges, got " .. #result.broken)
end)

test("poison-gas-vent-plugged resolves as valid target", function()
    local result = run_pipeline()
    local found = false
    for _, v in ipairs(result.valid_targets) do
        if v.target == "poison-gas-vent-plugged" then found = true; break end
    end
    t.assert_truthy(found, "expected poison-gas-vent-plugged in valid_targets")
end)

test("wood-splinters resolves as valid target", function()
    local result = run_pipeline()
    local found = false
    for _, v in ipairs(result.valid_targets) do
        if v.target == "wood-splinters" then found = true; break end
    end
    t.assert_truthy(found, "expected wood-splinters in valid_targets")
end)

---------------------------------------------------------------------------
-- Suite 5: Dynamic flagging (~2 tests)
---------------------------------------------------------------------------
suite("Dynamic flagging")

test("full run detects >= 1 dynamic path", function()
    local result = run_pipeline()
    t.assert_truthy(result and result.dynamics,
        "expected result with dynamics field")
    t.assert_truthy(#result.dynamics >= 1,
        "expected >= 1 dynamic path, got " .. #result.dynamics)
end)

test("paper.lua write mutation flagged as dynamic", function()
    local result = run_pipeline()
    local found = false
    for _, d in ipairs(result.dynamics) do
        if d.source == "paper" or (d.source_id or ""):match("paper") then
            found = true; break
        end
    end
    t.assert_truthy(found, "expected paper.lua dynamic write mutation in dynamics")
end)

---------------------------------------------------------------------------
-- Suite 6: CLI output (~5 tests)
---------------------------------------------------------------------------
suite("CLI output")

local function run_script(extra_args)
    local cmd = 'lua "' .. REPO_ROOT .. SEP .. "scripts" .. SEP
             .. 'mutation-edge-check.lua" ' .. (extra_args or "") .. ' 2>&1'
    local pipe = io.popen(cmd)
    local output = pipe:read("*a")
    local success, exit_type, code = pipe:close()
    return output, code, success
end

test("default mode produces human-readable report", function()
    local output = run_script()
    t.assert_truthy(output and #output > 0, "expected non-empty output")
end)

test("default mode exits with code 0 (no broken edges)", function()
    local output, code = run_script()
    t.assert_truthy(code == 0, "expected exit code 0 (no broken edges), got " .. tostring(code))
end)

test("--targets mode outputs file paths", function()
    local output = run_script("--targets")
    t.assert_truthy(output and output:find("%.lua"), "expected .lua file paths in --targets output")
end)

test("--targets mode produces no WARNING when 0 broken edges", function()
    -- Run with stderr separated: redirect stdout to nul, capture stderr
    local is_windows = package.config:sub(1, 1) == "\\"
    local cmd
    if is_windows then
        cmd = 'lua "' .. REPO_ROOT .. SEP .. "scripts" .. SEP
           .. 'mutation-edge-check.lua" --targets 2>&1 1>nul'
    else
        cmd = 'lua "' .. REPO_ROOT .. SEP .. "scripts" .. SEP
           .. 'mutation-edge-check.lua" --targets 2>&1 1>/dev/null'
    end
    local pipe = io.popen(cmd)
    local stderr_output = pipe:read("*a")
    pipe:close()
    t.assert_truthy(not stderr_output:find("WARNING"), "expected no WARNING in stderr (0 broken edges)")
end)

test("report includes summary footer", function()
    local output = run_script()
    -- Should have some kind of summary (edge count, broken count, etc.)
    t.assert_truthy(output:find("broken") or output:find("Broken") or output:find("BROKEN")
        or output:find("edge") or output:find("Edge"),
        "expected summary footer mentioning broken/edge counts")
end)

---------------------------------------------------------------------------
-- Suite 7: Integration sanity (~4 tests)
---------------------------------------------------------------------------
suite("Integration sanity")

test("full run scans > 150 files", function()
    local result = run_pipeline()
    t.assert_truthy(result and result.files_scanned,
        "expected result with files_scanned")
    t.assert_truthy(result.files_scanned > 150,
        "expected > 150 files scanned, got " .. result.files_scanned)
end)

test("full run finds > 40 edges", function()
    local result = run_pipeline()
    t.assert_truthy(result and result.edges,
        "expected result with edges")
    t.assert_truthy(#result.edges > 40,
        "expected > 40 edges, got " .. #result.edges)
end)

test("creature loot edges >= 10", function()
    local result = run_pipeline()
    local creature_count = 0
    for _, e in ipairs(result.edges) do
        if e.mechanism and (
            e.mechanism:find("loot") or
            e.mechanism:find("butchery") or
            e.mechanism:find("death_state") or
            e.mechanism:find("creates_object")
        ) then
            creature_count = creature_count + 1
        end
    end
    t.assert_truthy(creature_count >= 10,
        "expected >= 10 creature edges, got " .. creature_count)
end)

test("valid_targets list has entries", function()
    local result = run_pipeline()
    t.assert_truthy(result and result.valid_targets,
        "expected result with valid_targets")
    t.assert_truthy(#result.valid_targets > 0,
        "expected at least 1 valid target")
end)

---------------------------------------------------------------------------
-- Suite 8: JSON output (WAVE-2)
-- Tests for --json flag. If not yet implemented (Bart WAVE-2 in progress),
-- tests are SKIPped gracefully.
---------------------------------------------------------------------------
suite("JSON output (WAVE-2)")

local function run_json()
    local output = run_script("--json")
    -- Detect whether --json is actually implemented:
    -- If the output still looks like human-readable text (starts with "==="),
    -- then --json is not yet available.
    if output and output:match("^%s*=== Mutation Edge Report ===") then
        return nil, "json-not-implemented"
    end
    return output, nil
end

-- Minimal JSON key finder: checks whether a key like "summary" appears in
-- typical JSON format (e.g. "summary":)
local function json_has_key(text, key)
    return text:find('"' .. key .. '"') ~= nil
end

-- Extract a numeric value for a given key from JSON-like text
-- Matches patterns like "key": 123 or "key":123
local function json_number(text, key)
    local pat = '"' .. key .. '"%s*:%s*(%d+)'
    local val = text:match(pat)
    return val and tonumber(val) or nil
end

-- Check if a JSON-like text contains a string value somewhere in an array
-- associated with a given top-level key section
local function json_section_contains(text, section_key, needle)
    -- Find the section starting with "section_key": [
    local section_start = text:find('"' .. section_key .. '"')
    if not section_start then return false end
    local rest = text:sub(section_start)
    return rest:find('"[^"]*' .. needle .. '[^"]*"') ~= nil
end

test("--json produces output with summary key", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    t.assert_truthy(json_has_key(output, "summary"),
        "expected 'summary' key in JSON output")
end)

test("--json produces output with broken key", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    t.assert_truthy(json_has_key(output, "broken"),
        "expected 'broken' key in JSON output")
end)

test("--json produces output with dynamic key", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    t.assert_truthy(json_has_key(output, "dynamic"),
        "expected 'dynamic' key in JSON output")
end)

test("--json summary.files_scanned > 150", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    local count = json_number(output, "files_scanned")
    t.assert_truthy(count and count > 150,
        "expected files_scanned > 150, got " .. tostring(count))
end)

test("--json summary.edges_found > 40", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    local count = json_number(output, "edges_found")
    t.assert_truthy(count and count > 40,
        "expected edges_found > 40, got " .. tostring(count))
end)

test("--json summary.broken_edges == 0", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    local count = json_number(output, "broken_edges")
    t.assert_eq(0, count, "expected broken_edges == 0")
end)

test("--json summary.broken_targets == 0 (all targets resolved)", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    local count = json_number(output, "broken_targets")
    t.assert_eq(0, count, "expected broken_targets == 0")
end)

test("--json summary.dynamic_paths >= 1", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    local count = json_number(output, "dynamic_paths")
    t.assert_truthy(count and count >= 1,
        "expected dynamic_paths >= 1, got " .. tostring(count))
end)

test("--json broken array is empty (all targets resolved)", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    t.assert_truthy(json_has_key(output, "broken"),
        "expected 'broken' key in JSON output")
    -- poison-gas-vent-plugged and wood-splinters should NOT appear in broken
    t.assert_truthy(not json_section_contains(output, "broken", "poison%-gas%-vent%-plugged"),
        "poison-gas-vent-plugged should not be in broken array (target exists)")
    t.assert_truthy(not json_section_contains(output, "broken", "wood%-splinters"),
        "wood-splinters should not be in broken array (target exists)")
end)

test("--json dynamic contains paper.lua", function()
    local output, err = run_json()
    if err == "json-not-implemented" then
        print("    SKIP: --json not yet implemented — Bart WAVE-2 in progress")
        return
    end
    t.assert_truthy(json_section_contains(output, "dynamic", "paper"),
        "expected paper.lua reference in dynamic array")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local fail_count = t.summary()
os.exit(fail_count > 0 and 1 or 0)
