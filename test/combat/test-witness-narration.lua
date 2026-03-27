-- test/combat/test-witness-narration.lua
-- WAVE-3 TDD: Combat witness narration — light-dependent, adjacency-based,
-- severity-keyed, narration budget cap, player exemption.
-- Engine module under test: src/engine/combat/narration.lua
-- TDD red phase — tests written to spec, may fail until Smithers finishes.
-- Must be run from repository root: lua test/combat/test-witness-narration.lua

math.randomseed(42)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load engine modules (pcall-guarded — TDD)
---------------------------------------------------------------------------
local ok_combat, combat = pcall(require, "engine.combat")
if not ok_combat then
    print("WARNING: engine.combat failed to load — " .. tostring(combat))
    combat = nil
end

local ok_narr, narration = pcall(require, "engine.combat.narration")
if not ok_narr then
    print("WARNING: engine.combat.narration failed to load — " .. tostring(narration))
    narration = nil
end

---------------------------------------------------------------------------
-- Fixture helpers
---------------------------------------------------------------------------
local function make_exchange_result(overrides)
    local r = {
        attacker = { id = "cat", name = "the cat" },
        defender = { id = "rat", name = "the rat" },
        severity = 2,  -- HIT
        zone = "body",
        weapon = { id = "claw", name = "cat claw", material = "keratin",
                   combat = { type = "slash", message = "claws" } },
        material_name = "keratin",
        tissue_hit = "flesh",
        action_verb = "claws",
        damage = 3,
        defender_dead = false,
    }
    if overrides then
        for k, v in pairs(overrides) do r[k] = v end
    end
    return r
end

-- Call whichever witness narration function is available
local function call_witness_narrate(result, opts)
    -- Witness-specific API (WAVE-3 — Smithers)
    local fn = narration and (narration.describe_exchange
        or narration.witness_narrate or narration.emit_witness)
    if fn then return fn(result, opts) end

    -- Fall back to general narration with light param
    if narration and narration.generate then
        return narration.generate(result, opts and opts.light)
    end
    if narration and narration.narrate then
        return narration.narrate(result, opts and opts.light)
    end
    if combat and combat.narrate then
        return combat.narrate(result, opts and opts.light)
    end
    return nil
end

-- Call budget-aware emit function
local function call_emit(result, budget_state, opts)
    local fn = narration and (narration.emit or narration.emit_narration)
    if fn then return fn(result, budget_state, opts) end
    return nil, "emit function not found"
end

---------------------------------------------------------------------------
-- SUITE 1: Light-Dependent Witness Narration
---------------------------------------------------------------------------
suite("WITNESS NARRATION: light-dependent (WAVE-3)")

test("1. lit room: visual narration emitted (third-person)", function()
    math.randomseed(42)
    local result = make_exchange_result()
    local text = call_witness_narrate(result, { light = true, witness = true })
    h.assert_truthy(text, "lit room must produce narration text")
    h.assert_eq("string", type(text), "narration must be a string")
    h.assert_truthy(#text > 0, "narration must be non-empty")

    -- Third-person framing: should reference attacker/defender by name, not "you"
    local lower = text:lower()
    local has_third_person = lower:find("the cat") or lower:find("cat")
        or lower:find("the rat") or lower:find("rat")
        or lower:find("pounce") or lower:find("claw") or lower:find("bite")
        or lower:find("slash") or lower:find("strike") or lower:find("attack")
    h.assert_truthy(has_third_person,
        "lit room narration must use third-person framing, got: " .. text)
end)

test("2. dark room: audio-only narration emitted", function()
    math.randomseed(42)
    local result = make_exchange_result()
    local text = call_witness_narrate(result, { light = false, witness = true })
    h.assert_truthy(text, "dark room must produce narration text")
    h.assert_eq("string", type(text), "narration must be a string")

    local lower = text:lower()
    local has_audio = lower:find("hear") or lower:find("sound") or lower:find("thud")
        or lower:find("crack") or lower:find("squeal") or lower:find("hiss")
        or lower:find("scrape") or lower:find("crunch") or lower:find("screech")
        or lower:find("rip") or lower:find("tear") or lower:find("squelch")
        or lower:find("snap") or lower:find("shriek") or lower:find("scratch")
        or lower:find("scuffle") or lower:find("yelp") or lower:find("whimper")
        or lower:find("thump") or lower:find("impact") or lower:find("wet")
    h.assert_truthy(has_audio,
        "dark room narration must use audio-only language, got: " .. text)
end)

test("3. dark room narration differs from lit room narration", function()
    math.randomseed(42)
    local result = make_exchange_result()
    local text_lit = call_witness_narrate(result, { light = true, witness = true })
    math.randomseed(42)
    local text_dark = call_witness_narrate(result, { light = false, witness = true })
    h.assert_truthy(text_lit and text_dark, "both light/dark must produce text")
    h.assert_truthy(text_lit ~= text_dark,
        "dark narration must differ from lit narration")
end)

---------------------------------------------------------------------------
-- SUITE 2: Adjacency-Based Narration
---------------------------------------------------------------------------
suite("WITNESS NARRATION: adjacency (WAVE-3)")

test("4. adjacent room: distant audio narration (1 line max)", function()
    math.randomseed(42)
    local result = make_exchange_result({ severity = 2 })
    local text = call_witness_narrate(result, {
        light = true, witness = true, distance = "adjacent",
    })

    if text then
        h.assert_eq("string", type(text), "adjacent narration must be a string")
        -- 1 line max — no newlines
        local newline_count = 0
        for _ in text:gmatch("\n") do newline_count = newline_count + 1 end
        h.assert_truthy(newline_count <= 0,
            "adjacent room narration must be 1 line max, got "
            .. (newline_count + 1) .. " lines")
        -- Should reference distant/muffled/faint sounds
        local lower = text:lower()
        local has_distant = lower:find("distant") or lower:find("hear")
            or lower:find("somewhere") or lower:find("nearby")
            or lower:find("faint") or lower:find("muffled")
            or lower:find("sound") or lower:find("commotion")
            or lower:find("from the") or lower:find("next room")
        h.assert_truthy(has_distant,
            "adjacent narration must reference distance, got: " .. text)
    else
        h.assert_truthy(false,
            "adjacent room narration must return text (TDD: Smithers must implement)")
    end
end)

test("5. out of range: no narration emitted", function()
    math.randomseed(42)
    local result = make_exchange_result()
    local text = call_witness_narrate(result, {
        light = true, witness = true, distance = "out_of_range",
    })

    -- Out of range should return nil or empty string
    local is_silent = (text == nil) or (type(text) == "string" and #text == 0)
    h.assert_truthy(is_silent,
        "out-of-range narration must be nil or empty, got: " .. tostring(text))
end)

---------------------------------------------------------------------------
-- SUITE 3: Severity-Keyed Narration Text
---------------------------------------------------------------------------
suite("WITNESS NARRATION: severity-keyed text (WAVE-3)")

test("6. GRAZE severity → scuffle-type text", function()
    math.randomseed(42)
    local result = make_exchange_result({
        severity = 1,  -- GRAZE
        tissue_hit = "hide",
    })
    local text = call_witness_narrate(result, { light = true, witness = true })
    h.assert_truthy(text, "GRAZE must produce narration")
    local lower = text:lower()
    local has_scuffle = lower:find("scuffle") or lower:find("scratch")
        or lower:find("graze") or lower:find("glance") or lower:find("scrape")
        or lower:find("miss") or lower:find("brush") or lower:find("nick")
        or lower:find("swipe") or lower:find("shallow") or lower:find("barely")
        or lower:find("light")
    h.assert_truthy(has_scuffle,
        "GRAZE narration should use scuffle-type language, got: " .. text)
end)

test("7. HIT severity → yelp/impact text", function()
    math.randomseed(42)
    local result = make_exchange_result({
        severity = 2,  -- HIT
        tissue_hit = "flesh",
    })
    local text = call_witness_narrate(result, { light = true, witness = true })
    h.assert_truthy(text, "HIT must produce narration")
    local lower = text:lower()
    local has_impact = lower:find("yelp") or lower:find("hit") or lower:find("strike")
        or lower:find("cut") or lower:find("slash") or lower:find("claw")
        or lower:find("bite") or lower:find("blood") or lower:find("wound")
        or lower:find("pierce") or lower:find("into") or lower:find("connect")
        or lower:find("flesh") or lower:find("draw")
    h.assert_truthy(has_impact,
        "HIT narration should use impact language, got: " .. text)
end)

test("8. CRITICAL severity → death/lethal text", function()
    math.randomseed(42)
    local result = make_exchange_result({
        severity = 4,  -- CRITICAL
        tissue_hit = "organ",
        defender_dead = true,
    })
    local text = call_witness_narrate(result, { light = true, witness = true })
    h.assert_truthy(text, "CRITICAL must produce narration")
    local lower = text:lower()
    local has_lethal = lower:find("death") or lower:find("dead") or lower:find("kill")
        or lower:find("fatal") or lower:find("lethal") or lower:find("collapse")
        or lower:find("falls") or lower:find("vital") or lower:find("organ")
        or lower:find("limp") or lower:find("still") or lower:find("crumple")
        or lower:find("die") or lower:find("end") or lower:find("life")
        or lower:find("crush") or lower:find("destroy")
    h.assert_truthy(has_lethal,
        "CRITICAL narration should use death/lethal language, got: " .. text)
end)

test("9. severity levels produce distinct narration strings", function()
    math.randomseed(42)
    local texts = {}
    local severity_names = { [1] = "GRAZE", [2] = "HIT", [4] = "CRITICAL" }
    local tissue_map = { [1] = "hide", [2] = "flesh", [4] = "organ" }
    for _, sev in ipairs({ 1, 2, 4 }) do
        local text = call_witness_narrate(
            make_exchange_result({
                severity = sev,
                tissue_hit = tissue_map[sev],
                defender_dead = (sev == 4),
            }),
            { light = true, witness = true })
        if text then texts[sev] = text end
    end
    -- At least 2 of 3 should be unique
    local unique = {}
    for _, t in pairs(texts) do unique[t] = true end
    local count = 0
    for _ in pairs(unique) do count = count + 1 end
    h.assert_truthy(count >= 2,
        "3 severity levels must produce ≥2 distinct narration strings, got " .. count)
end)

---------------------------------------------------------------------------
-- SUITE 4: Narration Budget (≤6 NPC Lines Per Round)
---------------------------------------------------------------------------
suite("WITNESS NARRATION: budget cap (WAVE-3)")

test("10. narration budget: ≤6 NPC lines per round", function()
    -- Simulate 10 exchange narrations in one round
    local emit_fn = narration and (narration.emit or narration.emit_narration)
    local budget_fn = narration and (narration.new_budget or narration.create_budget)

    if emit_fn and budget_fn then
        local budget = budget_fn(6)  -- cap at 6
        local emitted = 0
        for i = 1, 10 do
            local result = make_exchange_result({ severity = 1 })  -- GRAZE (non-critical)
            local text = emit_fn(result, budget, { light = true, witness = true })
            if text and #text > 0 then emitted = emitted + 1 end
        end
        h.assert_truthy(emitted <= 6,
            "narration budget must cap NPC lines at ≤6 per round, got " .. emitted)
    else
        -- Verify narration module has budget awareness
        local has_budget = narration and (narration.emit or narration.narration_budget
            or narration.new_budget or narration.create_budget)
        h.assert_truthy(has_budget,
            "narration module must support budget tracking (TDD: Smithers must implement)")
    end
end)

test("11. budget enforcement: non-critical suppressed after cap", function()
    local emit_fn = narration and (narration.emit or narration.emit_narration)
    local budget_fn = narration and (narration.new_budget or narration.create_budget)

    if emit_fn and budget_fn then
        local budget = budget_fn(6)
        -- Burn through budget with 6 non-critical exchanges
        for i = 1, 6 do
            emit_fn(make_exchange_result({ severity = 1 }), budget,
                { light = true, witness = true })
        end
        -- 7th non-critical should be suppressed
        local text = emit_fn(
            make_exchange_result({ severity = 1 }), budget,
            { light = true, witness = true })
        local is_suppressed = (text == nil) or (type(text) == "string" and #text == 0)
            or (type(text) == "string" and text:find("%[.*continues"))
        h.assert_truthy(is_suppressed,
            "non-critical narration after budget cap must be suppressed, got: "
            .. tostring(text))
    else
        h.assert_truthy(false,
            "budget-aware emit function not found (TDD: Smithers must implement)")
    end
end)

test("12. critical narration always shown (even over budget)", function()
    local emit_fn = narration and (narration.emit or narration.emit_narration)
    local budget_fn = narration and (narration.new_budget or narration.create_budget)

    if emit_fn and budget_fn then
        local budget = budget_fn(6)
        -- Exhaust budget
        for i = 1, 6 do
            emit_fn(make_exchange_result({ severity = 1 }), budget,
                { light = true, witness = true })
        end
        -- Critical (severity=4) must still emit even over budget
        local text = emit_fn(
            make_exchange_result({ severity = 4, tissue_hit = "organ", defender_dead = true }),
            budget, { light = true, witness = true })
        h.assert_truthy(text and #text > 0,
            "CRITICAL narration must always be shown even over budget, got: "
            .. tostring(text))
    else
        h.assert_truthy(false,
            "budget-aware emit function not found (TDD: Smithers must implement)")
    end
end)

test("13. player's own combat exempt from narration cap", function()
    local emit_fn = narration and (narration.emit or narration.emit_narration)
    local budget_fn = narration and (narration.new_budget or narration.create_budget)

    if emit_fn and budget_fn then
        local budget = budget_fn(6)
        -- Exhaust NPC budget
        for i = 1, 6 do
            emit_fn(make_exchange_result({ severity = 2 }), budget,
                { light = true, witness = true })
        end
        -- Player's own combat should be exempt
        local player_result = make_exchange_result({
            attacker = { id = "player", name = "you" },
            severity = 2,
        })
        local text = emit_fn(player_result, budget,
            { light = true, witness = false, player_combat = true })
        h.assert_truthy(text and #text > 0,
            "player's own combat narration must be exempt from NPC cap, got: "
            .. tostring(text))
    else
        h.assert_truthy(false,
            "budget-aware emit function not found (TDD: Smithers must implement)")
    end
end)

test("14. morale break narration counts toward budget cap", function()
    local emit_fn = narration and (narration.emit or narration.emit_narration)
    local budget_fn = narration and (narration.new_budget or narration.create_budget)

    if emit_fn and budget_fn then
        local budget = budget_fn(6)
        -- Emit 5 normal narrations
        for i = 1, 5 do
            emit_fn(make_exchange_result({ severity = 1 }), budget,
                { light = true, witness = true })
        end
        -- Morale break narration (flee) should count as line 6
        local morale_result = make_exchange_result({
            severity = 0,
            action_verb = "flees",
            morale_break = true,
        })
        local text = emit_fn(morale_result, budget,
            { light = true, witness = true, morale_break = true })
        -- This is the 6th line — should be emitted
        h.assert_truthy(text, "morale break narration on line 6 must be emitted")

        -- 7th line (non-critical) should now be suppressed
        local overflow = emit_fn(
            make_exchange_result({ severity = 1 }), budget,
            { light = true, witness = true })
        local is_suppressed = (overflow == nil) or
            (type(overflow) == "string" and #overflow == 0) or
            (type(overflow) == "string" and overflow:find("%[.*continues"))
        h.assert_truthy(is_suppressed,
            "narration after morale break + budget must be suppressed")
    else
        h.assert_truthy(false,
            "budget-aware emit function not found (TDD: Smithers must implement)")
    end
end)

---------------------------------------------------------------------------
-- SUITE 5: Edge Cases & Robustness
---------------------------------------------------------------------------
suite("WITNESS NARRATION: edge cases (WAVE-3)")

test("15. narration does not crash with nil severity", function()
    local result = make_exchange_result({ severity = nil })
    local ok_call, text = pcall(call_witness_narrate, result,
        { light = true, witness = true })
    h.assert_truthy(ok_call,
        "narration with nil severity must not crash: " .. tostring(text))
end)

test("16. narration does not crash with missing attacker name", function()
    local result = make_exchange_result({ attacker = { id = "unknown" } })
    local ok_call, text = pcall(call_witness_narrate, result,
        { light = true, witness = true })
    h.assert_truthy(ok_call,
        "narration with missing attacker name must not crash: " .. tostring(text))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
