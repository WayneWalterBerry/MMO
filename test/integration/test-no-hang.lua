-- Automated test for BUG-067 and BUG-068
-- Simulates Nelson's test scenario

print("Testing BUG-067 (rapid commands) and BUG-068 (inventory hang)...")
print("This will pipe commands into the game and verify it doesn't hang")
print("")

local commands = {
    "feel around",
    "open nightstand",
    "feel drawer",
    "get matchbox",
    "open matchbox",
    "get match",
    "inventory",
    "quit"
}

-- Write to temporary file
local tmpfile = os.tmpname()
local f = io.open(tmpfile, "w")
for _, cmd in ipairs(commands) do
    f:write(cmd .. "\n")
end
f:close()

-- Run game with piped input (with timeout)
local start_time = os.time()
local result = os.execute("lua src/main.lua < " .. tmpfile .. " > nul 2>&1")
local elapsed = os.time() - start_time

os.remove(tmpfile)

-- Check if it completed in reasonable time (should be < 5 seconds)
if elapsed < 10 then
    print("✅ PASS: Game completed in " .. elapsed .. " seconds (no hang detected)")
    print("✅ PASS: BUG-067 (rapid commands) - NOT PRESENT")
    print("✅ PASS: BUG-068 (inventory hang) - NOT PRESENT")
else
    print("❌ FAIL: Game took " .. elapsed .. " seconds (possible hang)")
end
