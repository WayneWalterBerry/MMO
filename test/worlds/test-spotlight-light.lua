-- Test for Issue #462: spotlight.lua missing casts_light
-- In a kids' game, spotlights should cast light

local t = require("test.parser.test-helpers")

t.test("spotlight should have casts_light = true", function()
    local spotlight = require("src.meta.worlds.wyatt-world.objects.spotlight")
    
    -- Spotlights are light sources and should cast light
    t.assert_eq(true, spotlight.casts_light, 
        "Spotlight should have casts_light = true")
end)

t.test("spotlight should be recognized as a light source", function()
    local spotlight = require("src.meta.worlds.wyatt-world.objects.spotlight")
    
    -- The object should explicitly declare it casts light
    t.assert_truthy(spotlight.casts_light, 
        "Spotlight should have casts_light property defined")
end)

t.summary()
