-- test/integration/test-phase4-bugfixes.lua
-- TDD failing tests for Phase 4 walkthrough bugs (D-TESTFIRST, D-WAYNE-REGRESSION-TESTS).
-- These tests MUST FAIL until the corresponding code fixes land.
--
-- Bug 1: Silk-bundle disambiguation blocks pickup (identical items)
-- Bug 2: Silk crafting recipes not fully wired (craft silk-rope / silk-bandage)
-- Bug 3: Brass key doesn't unlock cellar storage door (unlock verb is a stub)

print("=== Phase 4 Walkthrough Bug Regression Tests ===")

local passed = 0
local failed = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("  PASS " .. name)
        passed = passed + 1
    else
        print("  FAIL " .. name .. ": " .. tostring(err))
        failed = failed + 1
    end
end

local function assert_contains(haystack, needle, msg)
    if not haystack:find(needle, 1, true) then
        error((msg or "substring not found") .. "\n  expected: " .. needle .. "\n  in: " .. tostring(haystack):sub(1, 400))
    end
end

local function assert_not_contains(haystack, needle, msg)
    if haystack:find(needle, 1, true) then
        error((msg or "unexpected substring found") .. "\n  unexpected: " .. needle .. "\n  in: " .. tostring(haystack):sub(1, 400))
    end
end

local function assert_true(v, msg)
    if not v then error(msg or "expected true") end
end

---------------------------------------------------------------------------
-- Headless game execution (same pattern as test-playtest-bugs.lua)
---------------------------------------------------------------------------
local function run_game(commands)
    local tmpname = "test_phase4_input.txt"
    local f = io.open(tmpname, "w")
    for _, c in ipairs(commands) do
        f:write(c .. "\n")
    end
    f:close()

    local handle = io.popen('lua src/main.lua --headless < "' .. tmpname .. '" 2>nul')
    local output = handle:read("*a")
    handle:close()
    os.remove(tmpname)
    return output
end

local function split_responses(output)
    local responses = {}
    for block in output:gmatch("(.-)\n?%-%-%-END%-%-%-") do
        if block and block ~= "" then
            responses[#responses + 1] = block
        end
    end
    return responses
end

---------------------------------------------------------------------------
-- Unit-test helpers (mock context, capture print)
---------------------------------------------------------------------------
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../../test/parser/?.lua;"
             .. package.path

local function reset_modules()
    for k, _ in pairs(package.loaded) do
        if k:match("^engine%.") or k:match("^meta%.") then
            package.loaded[k] = nil
        end
    end
end

local function capture(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local args = {}
        for i = 1, select("#", ...) do args[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(args, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err) end
    return table.concat(captured, "\n")
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Standard preamble: lit bedroom with candle in hand
local preamble = {
    "feel around",
    "search nightstand",
    "take matchbox",
    "take match",
    "light match",
    "light candle",
    "take candle",
}

---------------------------------------------------------------------------
-- BUG 1: Silk-bundle disambiguation blocks pickup
---------------------------------------------------------------------------
print("")
print("--- BUG: Silk-bundle disambiguation blocks pickup ---")

-- Unit test: create room with 2 silk-bundles, verify take succeeds
test("take silk-bundle with 2 identical silk-bundles should succeed", function()
    reset_modules()

    local registry_mod = require("engine.registry")
    local reg = registry_mod.new()

    -- Two silk-bundles (identical objects, different instance IDs)
    local silk1 = {
        id = "silk-bundle-1",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        template = "small-item",
        size = 1,
        weight = 0.2,
        portable = true,
        material = "silk",
    }
    local silk2 = {
        id = "silk-bundle-2",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        template = "small-item",
        size = 1,
        weight = 0.2,
        portable = true,
        material = "silk",
    }
    reg:register("silk-bundle-1", silk1)
    reg:register("silk-bundle-2", silk2)

    local room = {
        id = "test-room",
        name = "a test room",
        contents = { "silk-bundle-1", "silk-bundle-2" },
        light_level = 1,
    }
    reg:register("test-room", room)

    local ctx = {
        player = { hands = {nil, nil}, worn = {}, bags = {}, state = {} },
        current_room = room,
        registry = reg,
        containment = { can_contain = function() return true end },
    }

    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local output = capture(function()
        handlers["take"](ctx, "silk bundle")
    end)

    -- Player should now hold one silk-bundle. Should NOT get a disambiguation
    -- error or "Which do you mean" prompt that blocks pickup.
    assert_not_contains(output, "Which do you mean",
        "identical silk-bundles should not trigger impossible disambiguation")
    -- Player should have picked up one of them
    local holding = ctx.player.hands[1] or ctx.player.hands[2]
    assert_true(holding ~= nil,
        "player should be holding a silk-bundle after take")
end)

---------------------------------------------------------------------------
-- BUG 2: Silk crafting recipes not fully wired
---------------------------------------------------------------------------
print("")
print("--- BUG: Silk crafting recipes not fully wired ---")

test("craft silk-rope with 2 silk-bundles in hands should produce silk-rope", function()
    reset_modules()

    local registry_mod = require("engine.registry")
    local reg = registry_mod.new()
    local loader = require("engine.loader")

    -- Load real templates from files
    local templates = {}
    local template_dir = "src/meta/templates"
    for _, tname in ipairs({"room", "furniture", "container", "small-item", "sheet"}) do
        local src = read_file(template_dir .. "/" .. tname .. ".lua")
        if src then
            local tmpl = loader.load_source(src)
            if tmpl and tmpl.id then templates[tmpl.id] = tmpl end
        end
    end

    -- Two silk-bundles in player's hands
    local silk1 = {
        id = "silk-bundle-1",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        template = "small-item",
        size = 1,
        weight = 0.2,
        portable = true,
        material = "silk",
    }
    local silk2 = {
        id = "silk-bundle-2",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        template = "small-item",
        size = 1,
        weight = 0.2,
        portable = true,
        material = "silk",
    }
    reg:register("silk-bundle-1", silk1)
    reg:register("silk-bundle-2", silk2)

    local room = {
        id = "test-room",
        name = "a test room",
        contents = {},
        light_level = 1,
    }
    reg:register("test-room", room)

    -- Build object_sources so spawn_objects can find silk-rope definition
    local object_sources = {}
    local silk_rope_src = read_file("src/meta/worlds/manor/objects/silk-rope.lua")
    if silk_rope_src then object_sources["silk-rope"] = silk_rope_src end
    local silk_bandage_src = read_file("src/meta/worlds/manor/objects/silk-bandage.lua")
    if silk_bandage_src then object_sources["silk-bandage"] = silk_bandage_src end

    local ctx = {
        player = { hands = {"silk-bundle-1", "silk-bundle-2"}, worn = {}, bags = {}, state = {} },
        current_room = room,
        registry = reg,
        containment = { can_contain = function() return true end },
        loader = loader,
        templates = templates,
        object_sources = object_sources,
    }

    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local output = capture(function()
        handlers["craft"](ctx, "silk-rope")
    end)

    -- Crafting should succeed: narration printed, silk-bundles consumed, silk-rope created
    assert_not_contains(output, "don't know how",
        "craft silk-rope should be a known recipe")
    assert_not_contains(output, "don't have enough",
        "player holds 2 silk-bundles, should have enough ingredients")
    assert_contains(output, "twist the silk",
        "should print crafting narration on success")

    -- Verify silk-bundles consumed from hands
    local still_holding_silk = false
    for i = 1, 2 do
        local h = ctx.player.hands[i]
        if h then
            local hid = type(h) == "table" and h.id or h
            local obj = reg:get(hid)
            if obj and obj.id and obj.id:match("^silk%-bundle") then
                still_holding_silk = true
            end
        end
    end
    assert_true(not still_holding_silk,
        "silk-bundles should be consumed after crafting silk-rope")

    -- Verify silk-rope exists somewhere (room contents or player hands)
    local rope_found = false
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.id and obj.id:match("silk%-rope") then
            rope_found = true
            break
        end
    end
    if not rope_found then
        for i = 1, 2 do
            local h = ctx.player.hands[i]
            if h then
                local hid = type(h) == "table" and h.id or h
                if hid and hid:match("silk%-rope") then
                    rope_found = true
                    break
                end
            end
        end
    end
    assert_true(rope_found,
        "silk-rope should exist in room or player hands after crafting")
end)

test("craft silk-bandage with 1 silk-bundle should produce 2 silk-bandages", function()
    reset_modules()

    local registry_mod = require("engine.registry")
    local reg = registry_mod.new()
    local loader = require("engine.loader")

    local templates = {}
    local template_dir = "src/meta/templates"
    for _, tname in ipairs({"room", "furniture", "container", "small-item", "sheet"}) do
        local src = read_file(template_dir .. "/" .. tname .. ".lua")
        if src then
            local tmpl = loader.load_source(src)
            if tmpl and tmpl.id then templates[tmpl.id] = tmpl end
        end
    end

    local silk1 = {
        id = "silk-bundle-1",
        name = "a bundle of spider silk",
        keywords = {"silk", "spider silk", "silk bundle", "bundle"},
        template = "small-item",
        size = 1,
        weight = 0.2,
        portable = true,
        material = "silk",
    }
    reg:register("silk-bundle-1", silk1)

    local room = {
        id = "test-room",
        name = "a test room",
        contents = {},
        light_level = 1,
    }
    reg:register("test-room", room)

    local object_sources = {}
    local silk_bandage_src = read_file("src/meta/worlds/manor/objects/silk-bandage.lua")
    if silk_bandage_src then object_sources["silk-bandage"] = silk_bandage_src end

    local ctx = {
        player = { hands = {"silk-bundle-1", nil}, worn = {}, bags = {}, state = {} },
        current_room = room,
        registry = reg,
        containment = { can_contain = function() return true end },
        loader = loader,
        templates = templates,
        object_sources = object_sources,
    }

    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()

    local output = capture(function()
        handlers["craft"](ctx, "silk-bandage")
    end)

    assert_not_contains(output, "don't know how",
        "craft silk-bandage should be a known recipe")
    assert_not_contains(output, "don't have enough",
        "player holds 1 silk-bundle, recipe only needs 1")
    assert_contains(output, "tear the silk",
        "should print bandage crafting narration on success")
end)

---------------------------------------------------------------------------
-- BUG 3: Brass key doesn't unlock cellar storage door
---------------------------------------------------------------------------
print("")
print("--- BUG: Brass key doesn't unlock cellar storage door ---")

-- Integration test: full game path from bedroom to cellar, then unlock
test("unlock door with brass key in cellar should succeed", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    -- Reveal and open the trapdoor
    cmds[#cmds + 1] = "look under rug"  -- Optional: see what's under the rug
    cmds[#cmds + 1] = "push bed"  -- Move bed off rug first
    cmds[#cmds + 1] = "lift rug"  -- Rug lifts, key falls to floor
    cmds[#cmds + 1] = "drop matchbox"  -- Free up a hand
    cmds[#cmds + 1] = "take brass key"  -- Pick up the key from floor
    cmds[#cmds + 1] = "open trapdoor"
    cmds[#cmds + 1] = "down"
    -- Try to unlock the storage door with brass key in hand
    cmds[#cmds + 1] = "unlock door with brass key"
    cmds[#cmds + 1] = "unlock door"

    local output = run_game(cmds)
    local flat = output:gsub("\n", " ")

    -- Expected: FSM transition fires, prints "The brass key slides into the padlock"
    -- Currently: unlock verb is a stub that says "You can't unlock..." without
    -- checking FSM transitions or tool matching. This test MUST FAIL until the
    -- unlock handler is wired to use FSM + requires_tool.
    assert_contains(flat, "brass key slides",
        "unlock should fire FSM transition: 'The brass key slides into the padlock...'")
end)

-- Unit test: verify brass-key provides the capability the door requires
test("brass-key provides_tool should match door requires_tool", function()
    reset_modules()

    local loader = require("engine.loader")

    -- Load real brass-key definition
    local brass_key_src = read_file("src/meta/worlds/manor/objects/brass-key.lua")
    assert_true(brass_key_src ~= nil, "brass-key.lua file should exist")
    local brass_key = loader.load_source(brass_key_src)
    assert_true(brass_key ~= nil, "brass-key should load successfully")

    -- Load the cellar-storage door definition
    local door_src = read_file("src/meta/worlds/manor/objects/cellar-storage-door-north.lua")
    assert_true(door_src ~= nil, "cellar-storage-door-north.lua file should exist")
    local door = loader.load_source(door_src)
    assert_true(door ~= nil, "cellar-storage-door-north should load successfully")

    -- The door's unlock transition requires_tool = "brass-key"
    local unlock_trans = nil
    for _, t in ipairs(door.transitions or {}) do
        if t.verb == "unlock" then
            unlock_trans = t
            break
        end
    end
    assert_true(unlock_trans ~= nil, "door should have an unlock transition")
    assert_true(unlock_trans.requires_tool == "brass-key",
        "door unlock transition requires brass-key tool")

    -- The brass-key MUST declare provides_tool that includes "brass-key"
    -- so find_tool_in_inventory can match it
    local key_provides = brass_key.provides_tool
    assert_true(key_provides ~= nil,
        "brass-key must have provides_tool field (currently missing)")

    local matches = false
    if type(key_provides) == "string" then
        matches = key_provides == "brass-key"
    elseif type(key_provides) == "table" then
        for _, cap in ipairs(key_provides) do
            if cap == "brass-key" then matches = true; break end
        end
    end
    assert_true(matches,
        "brass-key provides_tool must include 'brass-key' to match door requirement")
end)

---------------------------------------------------------------------------
-- Results
---------------------------------------------------------------------------
print("")
print("--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if failed > 0 then
    print("  STATUS: " .. failed .. " bug(s) confirmed (expected failures — bugs not yet fixed)")
end
