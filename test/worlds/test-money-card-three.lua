-- Test for Issue #481: Money Vault Card 3 value mismatch
-- Card 3 should say "$15" not "$25" to match puzzle spec

local t = require("test.parser.test-helpers")

t.test("money-card-three should have $15 bill value (not $25)", function()
    local card = require("src.meta.worlds.wyatt-world.objects.money-card-three")
    
    -- The card description must contain "$15" per puzzle spec line 47
    -- Calculation: 4 bills × $15 = $60
    -- Total should be: $50 + $60 + $60 = $170
    t.assert_truthy(card.description:match("%$15"), 
        "Card 3 description should contain '$15', but got: " .. card.description)
    
    -- Verify it does NOT contain the wrong value
    t.assert_nil(card.description:match("%$25"), 
        "Card 3 description should NOT contain '$25', but got: " .. card.description)
end)

t.summary()
