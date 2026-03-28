-- test/combat/test-bug338-spider-bite-narration.lua
-- Bug #338: Garbled spider bite narration — broken interpolation, incomplete sentences.
-- Issues: dangling prepositions ("into."), material names leaking ("the enamel"),
-- mid-sentence capitalization ("as A large brown spider").
-- TDD: Must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/combat/test-bug338-spider-bite-narration.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

---------------------------------------------------------------------------
-- Load narration module
---------------------------------------------------------------------------
local narr_ok, narration = pcall(require, "engine.combat.narration")
if not narr_ok then
    print("WARNING: engine.combat.narration not loadable — " .. tostring(narration))
    narration = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local spider = {
    id = "spider", name = "a large brown spider",
    body_tree = {
        cephalothorax = { size = 1, vital = true, tissue = { "chitin", "flesh" },
            names = { "cephalothorax", "head cluster", "fused head" } },
        abdomen = { size = 1, vital = true, tissue = { "chitin", "flesh", "organ" },
            names = { "abdomen", "bulbous abdomen", "swollen belly" } },
        legs = { size = 1, vital = false, tissue = { "chitin" },
            names = { "leg", "bristled leg", "spindly leg", "front leg" } },
    },
}

local player = { id = "player", name = "the player", is_player = true }

local function make_spider_bite_result(severity, defender)
    return {
        attacker = spider,
        defender = defender or player,
        weapon = { id = "bite", type = "pierce", material = "tooth-enamel",
                   message = "sinks its fangs into" },
        zone = "legs",
        material_name = "tooth-enamel",
        tissue_hit = "chitin",
        severity = severity,
    }
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #338: Spider bite narration must be clean prose")

test("1. no dangling preposition at end of sentence", function()
    h.assert_truthy(narration, "narration module must load")

    -- Generate many narrations to cover all templates
    for _ = 1, 100 do
        for sev = 0, 4 do
            local result = make_spider_bite_result(sev)
            local text = narration.generate(result, true)

            -- Check for dangling "into." "into," "into;" at sentence boundaries
            h.assert_truthy(not text:find("into%.") and not text:find("into,$")
                and not text:find("into;"),
                "narration must not have dangling preposition, got: " .. text)
        end
    end
end)

test("2. no raw material name 'enamel' or 'tooth-enamel' in narration", function()
    h.assert_truthy(narration, "narration module must load")

    for _ = 1, 100 do
        for sev = 0, 4 do
            local result = make_spider_bite_result(sev)
            local text = narration.generate(result, true)

            -- "enamel" by itself (not part of "tooth-enamel" which is also bad) should not appear
            -- Acceptable: "tooth", "fang", "fangs", "teeth"
            local lower = text:lower()
            h.assert_truthy(not lower:find("enamel") and not lower:find("tooth%-enamel"),
                "narration must not leak raw material name 'enamel'/'tooth-enamel', got: " .. text)
        end
    end
end)

test("3. no double preposition 'into toward' or 'into into'", function()
    h.assert_truthy(narration, "narration module must load")

    for _ = 1, 100 do
        for sev = 0, 4 do
            local result = make_spider_bite_result(sev)
            local text = narration.generate(result, true)

            h.assert_truthy(not text:find("into into") and not text:find("into toward"),
                "narration must not have double prepositions, got: " .. text)
        end
    end
end)

test("4. no mid-sentence 'A large' capitalization after 'as'", function()
    h.assert_truthy(narration, "narration module must load")

    for _ = 1, 100 do
        for sev = 0, 4 do
            local result = make_spider_bite_result(sev)
            local text = narration.generate(result, true)

            -- Check for "as A " mid-sentence (wrong capitalization after conjunction)
            h.assert_truthy(not text:find(" as A "),
                "narration must not have mid-sentence 'as A', got: " .. text)
        end
    end
end)

test("5. spider bite narration produces complete sentences (no trailing preposition)", function()
    h.assert_truthy(narration, "narration module must load")

    for _ = 1, 100 do
        local result = make_spider_bite_result(0)  -- DEFLECT
        local text = narration.generate(result, true)

        -- Sentence should not end with just a preposition before punctuation
        h.assert_truthy(not text:match("into%s*[%.;,]"),
            "sentence must not end with dangling 'into' before punctuation, got: " .. text)
    end
end)

test("6. dark template spider bite is also clean", function()
    h.assert_truthy(narration, "narration module must load")

    for _ = 1, 50 do
        for sev = 0, 4 do
            local result = make_spider_bite_result(sev)
            local text = narration.generate(result, false)  -- dark mode

            h.assert_truthy(not text:find("enamel"),
                "dark narration must not leak 'enamel', got: " .. text)
        end
    end
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
