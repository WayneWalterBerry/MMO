-- scripts/mutation-edge-check.lua
-- Mutation edge extractor: scans src/meta/, extracts mutation edges, verifies targets exist.
-- WAVE-0 deliverable for the mutation-graph linter.
-- 12 extraction mechanisms (5 original + 7 creature-specific).

local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

-- Sandbox matching src/engine/loader/init.lua make_sandbox()
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
        print    = function() end,
        require  = function() return {} end,
    }
end

-- scan_meta_root(root) -> [{filepath, id}]
-- Two-pass: discover subdirs, then scan each for .lua files.
local function scan_meta_root(root)
    local files = {}
    local subdirs = {}

    -- Pass 1: discover subdirectories
    local dir_cmd
    if is_windows then
        dir_cmd = 'dir /b /ad "' .. root .. '" 2>nul'
    else
        dir_cmd = 'ls -d "' .. root .. '"/*/ 2>/dev/null'
    end
    local handle = io.popen(dir_cmd)
    if handle then
        for line in handle:lines() do
            local name = line:match("([^/\\]+)/?$") or line
            if name ~= "" then subdirs[#subdirs + 1] = name end
        end
        handle:close()
    end

    -- Pass 2: scan root + each subdirectory for .lua files
    local scan_dirs = { root }
    for _, sub in ipairs(subdirs) do
        scan_dirs[#scan_dirs + 1] = root .. SEP .. sub
    end

    for _, dir in ipairs(scan_dirs) do
        local file_cmd
        if is_windows then
            file_cmd = 'dir /b "' .. dir .. '\\*.lua" 2>nul'
        else
            file_cmd = 'ls "' .. dir .. '"/*.lua 2>/dev/null'
        end
        local fh = io.popen(file_cmd)
        if fh then
            for line in fh:lines() do
                local fname = line:match("([^/\\]+)$") or line
                local id = fname:gsub("%.lua$", "")
                files[#files + 1] = {
                    filepath = dir .. SEP .. fname,
                    id = id,
                }
            end
            fh:close()
        end
    end

    return files, subdirs
end

-- safe_load(filepath) -> table, nil | nil, error_string
local function safe_load(filepath)
    local env = make_sandbox()
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadfile(filepath)
        if chunk then setfenv(chunk, env) end
    else
        chunk, err = loadfile(filepath, "t", env)
    end
    if not chunk then return nil, "compile error: " .. tostring(err) end

    local ok, result = pcall(chunk)
    if not ok then return nil, "runtime error: " .. tostring(result) end
    if type(result) ~= "table" then return nil, "did not return a table" end
    return result, nil
end

-- extract_edges(obj, source_id, source_filepath) -> edges[], dynamics[]
-- 12 mechanisms: 5 original + 7 creature-specific.
local function extract_edges(obj, source_id, source_filepath)
    local edges = {}
    local dynamics = {}

    local function add_edge(target_id, mechanism, verb)
        edges[#edges + 1] = {
            source = source_id, source_filepath = source_filepath,
            target = target_id, mechanism = mechanism, verb = verb,
        }
    end
    local function add_dynamic(verb, mechanism)
        dynamics[#dynamics + 1] = {
            source = source_id, source_filepath = source_filepath,
            verb = verb, mechanism = mechanism,
        }
    end

    -- Core extraction logic — runs on top-level obj AND on death_state
    local function extract_from(o, pfx)
        -- [1] mutations[verb].becomes  [2] mutations[verb].spawns
        if type(o.mutations) == "table" then
            for verb, mut in pairs(o.mutations) do
                if type(mut) == "table" then
                    if mut.dynamic then
                        add_dynamic(verb, pfx .. "mutations")
                    else
                        if mut.becomes ~= nil then
                            add_edge(mut.becomes, pfx .. "mutations.becomes", verb)
                        end
                        if type(mut.spawns) == "table" then
                            for _, sp in ipairs(mut.spawns) do
                                add_edge(sp, pfx .. "mutations.spawns", verb)
                            end
                        end
                    end
                end
            end
        end

        -- [3] transitions[i].spawns[]
        if type(o.transitions) == "table" then
            for _, tr in ipairs(o.transitions) do
                if type(tr) == "table" and type(tr.spawns) == "table" then
                    for _, sp in ipairs(tr.spawns) do
                        add_edge(sp, pfx .. "transitions.spawns", tr.verb or "?")
                    end
                end
            end
        end

        -- [4] crafting[verb].becomes
        if type(o.crafting) == "table" then
            for verb, recipe in pairs(o.crafting) do
                if type(recipe) == "table" and recipe.becomes ~= nil then
                    add_edge(recipe.becomes, pfx .. "crafting.becomes", verb)
                end
            end
        end

        -- [5] on_tool_use.when_depleted
        if type(o.on_tool_use) == "table" and o.on_tool_use.when_depleted ~= nil then
            add_edge(o.on_tool_use.when_depleted, pfx .. "on_tool_use.when_depleted", "deplete")
        end

        -- [6] loot_table.always[].template
        -- [7] loot_table.on_death[].item.template
        -- [8] loot_table.variable[].template
        -- [9] loot_table.conditional.{key}[].template
        if type(o.loot_table) == "table" then
            local lt = o.loot_table
            if type(lt.always) == "table" then
                for _, e in ipairs(lt.always) do
                    if type(e) == "table" and e.template then
                        add_edge(e.template, pfx .. "loot_table.always", "loot")
                    end
                end
            end
            if type(lt.on_death) == "table" then
                for _, e in ipairs(lt.on_death) do
                    if type(e) == "table" and type(e.item) == "table" and e.item.template then
                        add_edge(e.item.template, pfx .. "loot_table.on_death", "loot")
                    end
                end
            end
            if type(lt.variable) == "table" then
                for _, e in ipairs(lt.variable) do
                    if type(e) == "table" and e.template then
                        add_edge(e.template, pfx .. "loot_table.variable", "loot")
                    end
                end
            end
            if type(lt.conditional) == "table" then
                for key, items in pairs(lt.conditional) do
                    if type(items) == "table" then
                        for _, e in ipairs(items) do
                            if type(e) == "table" and e.template then
                                add_edge(e.template, pfx .. "loot_table.conditional." .. key, "loot")
                            end
                        end
                    end
                end
            end
        end

        -- [10] butchery_products.products[].id (death_state.butchery_products)
        if type(o.butchery_products) == "table" and type(o.butchery_products.products) == "table" then
            for _, prod in ipairs(o.butchery_products.products) do
                if type(prod) == "table" and prod.id then
                    add_edge(prod.id, pfx .. "butchery_products", "butchery")
                end
            end
        end

        -- [11] behavior.creates_object.template
        if type(o.behavior) == "table" and type(o.behavior.creates_object) == "table" then
            if o.behavior.creates_object.template then
                add_edge(o.behavior.creates_object.template, pfx .. "behavior.creates_object", "creates")
            end
        end
    end

    -- Top-level extraction
    extract_from(obj, "")
    -- death_state recursive pass for nested crafting/butchery
    if type(obj.death_state) == "table" then
        extract_from(obj.death_state, "death_state.")
    end

    return edges, dynamics
end

-- resolve_target(target_id, file_map) -> filepath | nil
local function resolve_target(target_id, file_map)
    return file_map[target_id]
end

-- main(root) — orchestrator
local function main(root)
    root = root or ("src" .. SEP .. "meta")

    local targets_mode = false
    if arg then
        for i = 1, #arg do
            if arg[i] == "--targets" then targets_mode = true end
        end
    end

    -- Scan all .lua files
    local files, subdirs = scan_meta_root(root)

    -- Build file_map: id -> filepath (O(1) lookups)
    local file_map = {}
    for _, f in ipairs(files) do file_map[f.id] = f.filepath end

    -- Load each file, extract edges
    local all_edges, all_dynamics, load_errors = {}, {}, {}
    for _, f in ipairs(files) do
        local obj, err = safe_load(f.filepath)
        if obj then
            local edges, dynamics = extract_edges(obj, f.id, f.filepath)
            for _, e in ipairs(edges) do all_edges[#all_edges + 1] = e end
            for _, d in ipairs(dynamics) do all_dynamics[#all_dynamics + 1] = d end
        elseif err then
            load_errors[#load_errors + 1] = { filepath = f.filepath, error = err }
        end
    end

    -- Resolve targets
    local broken, valid_targets = {}, {}
    for _, edge in ipairs(all_edges) do
        if resolve_target(edge.target, file_map) then
            valid_targets[#valid_targets + 1] = edge
        else
            broken[#broken + 1] = edge
        end
    end

    -- Output
    if targets_mode then
        -- Valid target filepaths to stdout (deduplicated)
        local seen = {}
        for _, vt in ipairs(valid_targets) do
            local path = file_map[vt.target]
            if not seen[path] then
                print(path)
                seen[path] = true
            end
        end
        -- Broken edges to stderr
        for _, b in ipairs(broken) do
            io.stderr:write(string.format("WARNING: %s -> %s (via %s, verb: %s) -- target file not found\n",
                b.source_filepath, b.target, b.mechanism, b.verb))
        end
    else
        -- Human-readable report
        print("=== Mutation Edge Report ===")
        print("")
        print(string.format("Files scanned:    %d", #files))
        print(string.format("Subdirs found:    %d", #subdirs))
        print(string.format("Edges found:      %d", #all_edges))
        print(string.format("Valid targets:    %d", #valid_targets))
        print(string.format("Broken edges:     %d", #broken))
        print(string.format("Dynamic paths:    %d", #all_dynamics))
        if #load_errors > 0 then
            print(string.format("Load errors:      %d", #load_errors))
        end

        if #broken > 0 then
            print("")
            print("--- Broken Edges ---")
            for _, b in ipairs(broken) do
                print(string.format("  %s -> %s", b.source_filepath, b.target))
                print(string.format("    via: %s (verb: %s)", b.mechanism, b.verb))
            end
        end

        if #all_dynamics > 0 then
            print("")
            print("--- Dynamic Mutations (not followed) ---")
            for _, d in ipairs(all_dynamics) do
                print(string.format("  %s (verb: %s, mechanism: %s)", d.source_filepath, d.verb, d.mechanism))
            end
        end

        if #load_errors > 0 then
            print("")
            print("--- Load Errors ---")
            for _, e in ipairs(load_errors) do
                print(string.format("  %s: %s", e.filepath, e.error))
            end
        end

        print("")
        if #broken == 0 then
            print("All mutation edges resolve to existing files.")
        else
            print(string.format("%d broken edge(s) found.", #broken))
        end
    end

    os.exit(#broken > 0 and 1 or 0)
end

main()
