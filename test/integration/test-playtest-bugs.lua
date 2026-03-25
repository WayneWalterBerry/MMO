-- test/integration/test-playtest-bugs.lua
-- Regression tests from Nelson's LLM playtest session.
-- These test real game behavior via headless pipe-based execution.
-- Bugs: BUG-149 through BUG-164

print("=== LLM Playtest Bug Regression Tests ===")

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
        error((msg or "substring not found") .. "\n  expected: " .. needle .. "\n  in: " .. tostring(haystack):sub(1, 300))
    end
end

local function assert_not_contains(haystack, needle, msg)
    if haystack:find(needle, 1, true) then
        error((msg or "unexpected substring found") .. "\n  unexpected: " .. needle .. "\n  in: " .. tostring(haystack):sub(1, 300))
    end
end

local function run_game(commands)
    local tmpname = "test_playtest_input.txt"
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

-- Split output into individual responses by ---END--- delimiter
local function split_responses(output)
    local responses = {}
    for block in output:gmatch("(.-)\n?%-%-%-END%-%-%-") do
        if block and block ~= "" then
            responses[#responses + 1] = block
        end
    end
    return responses
end

-- Standard preamble: get to lit bedroom with candle in hand
local preamble = {
    "feel around",
    "search nightstand",
    "take matchbox",
    "take match",
    "light match",
    "light candle",
    "take candle",
}

print("")
print("--- BUG-149: Breaking door should unlock north exit ---")

test("BUG-149: break door then go north should succeed", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "break door"
    cmds[#cmds + 1] = "north"
    local output = run_game(cmds)
    -- Word wrapping may split text across lines; normalize for matching
    local flat = output:gsub("\n", " ")
    assert_contains(flat, "bursts inward", "break should succeed")
    -- After breaking the door, north should NOT say locked
    local after_break = flat:match("bursts inward(.+)$") or ""
    assert_not_contains(after_break, "is locked", "north exit should not be locked after breaking door")
end)

print("")
print("--- BUG-150: Taking candle holder should not kill light ---")

test("BUG-150: take candle holder should preserve room light", function()
    local cmds = {
        "feel around", "search nightstand", "take matchbox",
        "take match", "light match", "light candle",
        "take candle holder",
        "look around",
    }
    local output = run_game(cmds)
    local responses = split_responses(output)
    local last_look = responses[#responses] or ""
    -- After taking candle holder, room should still be lit (candle should come with holder)
    -- This test will FAIL until the bug is fixed
    assert_not_contains(last_look, "too dark", "room should still be lit after taking candle holder")
end)

print("")
print("--- BUG-151: Window exit should unlock after opening window ---")

test("BUG-151: go window after open window should not say locked", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "open window"
    cmds[#cmds + 1] = "go window"
    local output = run_game(cmds)
    assert_contains(output, "push the window open", "open window should succeed")
    -- After opening the window, 'go window' should not say locked
    -- Note: may still be blocked for story reasons, but not 'locked'
    local after_open = output:match("push the window open(.+)$") or ""
    assert_not_contains(after_open, "is locked", "window should not be locked after opening")
end)

print("")
print("--- BUG-152: Search pillow should find the pin ---")

test("BUG-152: search pillow should find pin", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "examine pillow"
    cmds[#cmds + 1] = "search pillow"
    local output = run_game(cmds)
    assert_contains(output, "pin", "pillow description mentions pin")
    -- search pillow should find the pin, not say 'nothing to search'
    assert_not_contains(output, "nothing to search", "search pillow should find the pin")
end)

print("")
print("--- BUG-153: Put candle on nightstand should have room ---")

test("BUG-153: put candle back on nightstand should work", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "put candle on nightstand"
    local output = run_game(cmds)
    assert_not_contains(output, "not enough room", "nightstand should have room for candle")
end)

print("")
print("--- BUG-155: Read blank paper should say it's blank ---")

test("BUG-155: read paper should not say 'not something you can read'", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "read paper"
    local output = run_game(cmds)
    assert_not_contains(output, "not something you can read", "blank paper should not say unreadable")
end)

print("")
print("--- BUG-156: 'jump out window' should not be extinguish ---")

test("BUG-156: jump out window should not trigger extinguish", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "open window"
    cmds[#cmds + 1] = "jump out window"
    local output = run_game(cmds)
    assert_not_contains(output, "extinguish", "jump out should not be parsed as extinguish")
end)

print("")
print("--- BUG-159: Injury description should match weapon ---")

test("BUG-159: cut self with knife injury should reference knife not glass", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "drop matchbox"
    cmds[#cmds + 1] = "take knife"
    cmds[#cmds + 1] = "cut self with knife"
    cmds[#cmds + 1] = "injuries"
    local output = run_game(cmds)
    -- Injury description should not reference 'glass' when cut was from knife
    local injury_output = output:match("injuries(.+)$") or output
    assert_not_contains(injury_output, "glass caught you", "injury from knife should not mention glass")
end)

print("")
print("--- BUG-160: Pour should require holding ---")

test("BUG-160: pour bottle without holding should require pickup", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "pour bottle"
    local output = run_game(cmds)
    -- Pour should require holding the bottle, like drink does
    assert_not_contains(output, "pours out", "pour should require holding the bottle")
end)

print("")
print("--- BUG-161: Disambiguation of identical objects ---")

test("BUG-161: identical spent matches should not ask impossible disambiguation", function()
    local cmds = {
        "feel around", "search nightstand", "take matchbox",
        "take match", "light match", "light candle",
        "take candle", "examine match",
    }
    local output = run_game(cmds)
    -- Should not present an impossible choice between identical items
    assert_not_contains(output, "Which do you mean: a spent match or a spent match",
        "should not ask player to choose between identically-named objects")
end)

print("")
print("--- BUG-163: Feel around text in lit room ---")

test("BUG-163: feel around in lit room should not say 'in the darkness'", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "look around"
    cmds[#cmds + 1] = "feel around"
    local output = run_game(cmds)
    -- The room is lit (look around works). Feel around should not say "in the darkness"
    local feel_output = output:match("feel around.-(You reach.-)%-%-%-END%-%-%-") or
                        output:match("(You reach[^\n]*darkness[^\n]*)") or ""
    -- This is a low-severity text issue but still a regression test
    if feel_output:find("in the darkness", 1, true) then
        error("feel around says 'in the darkness' but the room is lit")
    end
end)

print("")
print("--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if failed > 0 then
    print("  STATUS: " .. failed .. " bugs confirmed (expected failures — bugs not yet fixed)")
    -- Exit 0: these are KNOWN BUG confirmations, not test regressions.
    -- When a bug is fixed, remove it from this file or flip the assertion.
    -- If a bug test starts passing unexpectedly, that's a GOOD thing.
end
