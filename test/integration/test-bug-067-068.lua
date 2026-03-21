-- test/integration/test-bug-067-068.lua
-- Regression test for BUG-067 (rapid commands) and BUG-068 (inventory hang)

local test = {}

function test.run()
    local passed = 0
    local failed = 0

    print("=== BUG-067 / BUG-068 Regression Tests ===")

    -- Test 1: Inventory command doesn't hang
    print("  Testing inventory command...")
    local success = pcall(function()
        -- Create minimal context
        local registry = require("engine.registry")
        local reg = registry.new()
        
        local ctx = {
            registry = reg,
            player = {
                hands = {nil, nil},
                worn = {},
                state = {}
            },
            current_room = {
                id = "test-room",
                name = "Test Room",
                description = "A test room",
                contents = {}
            },
            verbs = {}
        }
        
        -- Load the verb handler
        local verbs = require("engine.verbs")
        verbs.register(ctx)
        
        -- Call inventory - should not hang
        if ctx.verbs.inventory then
            ctx.verbs.inventory(ctx, "")
        end
    end)
    
    if success then
        print("  PASS inventory command executes without hanging")
        passed = passed + 1
    else
        print("  FAIL inventory command failed")
        failed = failed + 1
    end

    -- Test 2: Multiple rapid commands don't cause issues
    print("  Testing rapid command sequence...")
    local success2 = pcall(function()
        local registry = require("engine.registry")
        local reg = registry.new()
        
        local nightstand_def = {
            id = "nightstand",
            name = "nightstand",
            container = true,
            surfaces = {
                inside = {
                    accessible = true,
                    contents = {"matchbox"}
                }
            }
        }
        reg:register(nightstand_def.id, nightstand_def)
        
        local matchbox_def = {
            id = "matchbox",
            name = "matchbox",
            container = true,
            contents = {"match1", "match2"},
            takeable = true,
            location = "nightstand"
        }
        reg:register(matchbox_def.id, matchbox_def)
        
        local match_def = {
            id = "match1",
            name = "match",
            takeable = true,
            location = "matchbox"
        }
        reg:register(match_def.id, match_def)
        
        local ctx = {
            registry = reg,
            player = {
                hands = {nil, nil},
                worn = {},
                state = {}
            },
            current_room = {
                id = "test-room",
                name = "Test Room",
                description = "A test room",
                contents = {"nightstand"}
            },
            verbs = {}
        }
        
        local verbs = require("engine.verbs")
        verbs.register(ctx)
        
        -- Execute rapid sequence: get, open, inventory
        -- These should all execute without hanging
        if ctx.verbs.get then ctx.verbs.get(ctx, "matchbox") end
        if ctx.verbs.open then ctx.verbs.open(ctx, "matchbox") end
        if ctx.verbs.inventory then ctx.verbs.inventory(ctx, "") end
    end)
    
    if success2 then
        print("  PASS rapid command sequence executes without issues")
        passed = passed + 1
    else
        print("  FAIL rapid command sequence failed")
        failed = failed + 1
    end

    print("--- Results ---")
    print("  Passed: " .. passed)
    print("  Failed: " .. failed)
    
    return failed == 0
end

return test
