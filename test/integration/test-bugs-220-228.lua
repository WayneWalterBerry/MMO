-- test/integration/test-bugs-220-228.lua
-- TDD regression tests for gameplay bugs #220-#228.
-- Each test reproduces the bug scenario and verifies the fix.
-- Run from repo root: lua test/integration/test-bugs-220-228.lua

print("=== Gameplay Bug Fixes #220-#228 ===")

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

local function run_game(commands)
    local tmpname = "test_bugs_220_228_input.txt"
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

---------------------------------------------------------------------------
-- #220: 'search pillow' can't find pin described in pillow description
---------------------------------------------------------------------------
print("")
print("--- #220: Search pillow should find the pin ---")

test("#220: search pillow finds pin inside", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "search pillow"
    cmds[#cmds + 1] = "wait"  -- progressive search needs ticks to complete
    cmds[#cmds + 1] = "wait"
    local output = run_game(cmds)
    local flat = output:gsub("\n", " ")
    -- Search should find the pin inside the pillow
    assert_contains(flat, "pin", "search pillow should find the pin")
    assert_not_contains(flat, "nothing to search", "should not say nothing to search")
end)

test("#220: search pillow for pin finds it", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "search pillow for pin"
    cmds[#cmds + 1] = "wait"
    cmds[#cmds + 1] = "wait"
    local output = run_game(cmds)
    local flat = output:gsub("\n", " ")
    assert_contains(flat, "pin", "targeted search should find the pin")
end)

---------------------------------------------------------------------------
-- #221: 'cut curtains with knife' parser failure
---------------------------------------------------------------------------
print("")
print("--- #221: 'cut curtains with knife' should work ---")

test("#221: cut curtains with knife should not say can't cut", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "drop matchbox"
    cmds[#cmds + 1] = "take knife"
    cmds[#cmds + 1] = "cut curtains with knife"
    local output = run_game(cmds)
    local flat = output:gsub("\n", " ")
    -- Should either cut (mutation) or give a tool-specific failure, not generic "can't cut"
    assert_not_contains(flat, "can't cut", "cut with knife should work on curtains")
end)

test("#221: cut verb extracts with-tool in loop", function()
    -- Unit test: verify cut is in the loop's tool extraction list
    local SEP = package.config:sub(1, 1)
    package.path = "." .. SEP .. "src" .. SEP .. "?.lua;"
                 .. "." .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
                 .. "." .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
                 .. package.path
    local preprocess = require("engine.parser.preprocess")
    local verb, noun = preprocess.parse("cut curtains with knife")
    assert(verb == "cut", "verb should be 'cut', got: " .. tostring(verb))
    assert(noun == "curtains with knife", "noun should preserve 'with knife', got: " .. tostring(noun))
end)

---------------------------------------------------------------------------
-- #223: 'pour bottle' works without holding — inconsistent with drink
---------------------------------------------------------------------------
print("")
print("--- #223: Pour should require holding the object ---")

test("#223: pour bottle without holding should require pickup", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "pour bottle"
    local output = run_game(cmds)
    local flat = output:gsub("\n", " ")
    -- Should require picking up the bottle first
    assert_not_contains(flat, "pour out", "pour should not work without holding")
    assert_not_contains(flat, "pours out", "pour should not work without holding")
end)

test("#223: pour bottle while holding should work", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "drop matchbox"
    cmds[#cmds + 1] = "take bottle"
    cmds[#cmds + 1] = "pour bottle"
    local output = run_game(cmds)
    local flat = output:gsub("\n", " ")
    -- Should succeed when holding
    assert_not_contains(flat, "pick that up", "pour should work when holding")
end)

---------------------------------------------------------------------------
-- #224: 'jump out window' parsed as extinguish command
---------------------------------------------------------------------------
print("")
print("--- #224: 'jump out window' should not trigger extinguish ---")

test("#224: jump out window should not extinguish anything", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "open window"
    cmds[#cmds + 1] = "jump out window"
    local output = run_game(cmds)
    local responses = split_responses(output)
    -- Check only the last response (the "jump out window" response)
    local jump_response = responses[#responses] or ""
    local flat = jump_response:gsub("\n", " ")
    assert_not_contains(flat, "extinguish", "jump out should not be extinguish")
    assert_not_contains(flat, "blow out", "jump out should not be blow out")
end)

test("#224: jump out should give a sensible response", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "open window"
    cmds[#cmds + 1] = "jump out window"
    local output = run_game(cmds)
    local flat = output:gsub("\n", " ")
    -- Should give a response about jumping, not about extinguishing
    local has_jump = flat:lower():find("jump") or flat:lower():find("leap")
        or flat:lower():find("not something") or flat:lower():find("can't do")
    assert(has_jump, "should give a jump-related or can't-do response, not extinguish")
end)

---------------------------------------------------------------------------
-- #225: Injury description says 'glass' when cut was from knife
---------------------------------------------------------------------------
print("")
print("--- #225: Injury from knife should not mention 'glass' ---")

test("#225: cut self with knife injury should not reference glass", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "drop matchbox"
    cmds[#cmds + 1] = "take knife"
    cmds[#cmds + 1] = "cut self with knife"
    cmds[#cmds + 1] = "injuries"
    local output = run_game(cmds)
    local injury_section = output:match("You examine yourself:(.+)$") or output
    local flat = injury_section:gsub("\n", " ")
    assert_not_contains(flat, "glass caught you", "injury from knife should not mention glass")
end)

test("#225: minor-cut description should be source-neutral", function()
    local SEP = package.config:sub(1, 1)
    package.path = "." .. SEP .. "src" .. SEP .. "?.lua;"
                 .. "." .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
                 .. package.path
    local def = require("meta.injuries.minor-cut")
    local desc = def.states.active.description
    -- Description should not hardcode "glass"
    assert(not desc:find("glass", 1, true),
        "minor-cut active description should not mention 'glass': " .. desc)
end)

---------------------------------------------------------------------------
-- #226: 'eat match' disambiguation fails — identical spent match names
---------------------------------------------------------------------------
print("")
print("--- #226: Identical spent match disambiguation ---")

test("#226: identical names should not produce impossible disambiguation", function()
    local cmds = {
        "feel around", "search nightstand", "take matchbox",
        "take match", "light match", "light candle",
        "take candle", "examine match",
    }
    local output = run_game(cmds)
    assert_not_contains(output, "Which do you mean: a spent match or a spent match",
        "should not ask to choose between identically-named objects")
end)

---------------------------------------------------------------------------
-- #227: 'light candle' with full hands shows error but succeeds
---------------------------------------------------------------------------
print("")
print("--- #227: Light candle with full hands ---")

test("#227: light candle with full hands should not succeed", function()
    local cmds = {
        "feel around", "search nightstand", "take matchbox",
        "take match",
        "take candle",     -- hand 1: candle
        "light match",     -- need match in hand to light
        "light candle",    -- both hands full — should fail cleanly
    }
    local output = run_game(cmds)
    local responses = split_responses(output)
    -- Find the "light candle" response
    local light_response = responses[#responses] or ""
    local flat = light_response:gsub("\n", " ")
    -- Should not show BOTH an error message AND a success message
    local has_error = flat:find("nothing to light") or flat:find("hands are full")
        or flat:find("no fire") or flat:find("have nothing")
    local has_success = flat:find("catches") or flat:find("casts a warm glow")
        or flat:find("light the") or flat:find("lit")
    if has_error and has_success then
        error("light candle shows BOTH error and success messages")
    end
end)

---------------------------------------------------------------------------
-- #228: 'read paper' says not readable — blank paper should say 'it's blank'
---------------------------------------------------------------------------
print("")
print("--- #228: Read paper should not say unreadable ---")

test("#228: read blank paper should not say 'not something you can read'", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "read paper"
    local output = run_game(cmds)
    assert_not_contains(output, "not something you can read",
        "blank paper should not say unreadable")
end)

test("#228: read blank paper should indicate it's blank", function()
    local cmds = {}
    for _, c in ipairs(preamble) do cmds[#cmds + 1] = c end
    cmds[#cmds + 1] = "read paper"
    local output = run_game(cmds)
    local flat = output:gsub("\n", " ")
    -- Should indicate the paper is blank or has nothing written
    local has_blank = flat:find("blank") or flat:find("nothing written")
        or flat:find("nothing to read") or flat:find("empty")
        or flat:find("no writing")
    assert(has_blank, "read blank paper should indicate it's blank or has no writing")
end)

---------------------------------------------------------------------------
-- Results
---------------------------------------------------------------------------
print("")
print("--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if failed > 0 then
    os.exit(1)
end
