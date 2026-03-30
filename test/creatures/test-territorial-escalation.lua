-- test/creatures/test-territorial-escalation.lua
-- WAVE-3: Territorial intrusion detection — escalation from warning → threat → attack,
-- intrusion counter reset on player leaving, and territory transfer on alpha death.
-- Must be run from repository root: lua test/creatures/test-territorial-escalation.lua

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
-- Load engine modules
---------------------------------------------------------------------------
local terr_ok, territorial = pcall(require, "engine.creatures.territorial")
if not terr_ok then
    print("FATAL: engine.creatures.territorial not loadable — " .. tostring(territorial))
    os.exit(1)
end

local pack_ok, pack_tactics = pcall(require, "engine.creatures.pack-tactics")
if not pack_ok then
    print("FATAL: engine.creatures.pack-tactics not loadable — " .. tostring(pack_tactics))
    os.exit(1)
end

---------------------------------------------------------------------------
-- Load wolf definition for metadata verification
---------------------------------------------------------------------------
local wolf_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "wolf.lua"
local ok_wolf, wolf_def = pcall(dofile, wolf_path)
if not ok_wolf then
    print("WARNING: wolf.lua not found — metadata tests will skip")
    wolf_def = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-terr-esc-" .. guid_counter .. "}"
end

local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deep_copy(v) end
    return copy
end

local function make_wolf(overrides)
    local w = {
        guid = next_guid(),
        id = "wolf",
        name = "a grey wolf",
        animate = true,
        _state = "alive-idle",
        location = "hallway",
        health = 22,
        max_health = 22,
        behavior = {
            territorial = { marks_territory = true },
            territory = "hallway",
            aggression = 70,
            intrusion_escalation = { warning = 1, threat = 2, attack = 3 },
        },
        reactions = {
            intrusion_warning = {
                action = "patrol",
                fear_delta = 0,
                message = "The wolf growls territorially.",
            },
        },
        drives = {
            fear = { value = 0, decay_rate = -5, max = 100, min = 0 },
        },
    }
    if overrides then
        for k, v in pairs(overrides) do w[k] = v end
    end
    return w
end

local function make_context(player_room, rooms)
    return {
        current_room = player_room or "hallway",
        registry = {
            _objects = {},
            list = function(self)
                local r = {}
                for _, o in pairs(self._objects) do r[#r + 1] = o end
                return r
            end,
            get = function(self, id)
                return self._objects[id]
            end,
        },
        rooms = rooms or {
            hallway = { id = "hallway", exits = { north = { target = "bedroom" } } },
            bedroom = { id = "bedroom", exits = { south = { target = "hallway" } } },
        },
    }
end

---------------------------------------------------------------------------
-- Suite 1: detect_intrusion escalation
---------------------------------------------------------------------------
suite("detect_intrusion — escalation levels")

test("turn 1 in territory → warning", function()
    local wolf = make_wolf()
    local ctx = make_context("hallway")
    local result = territorial.detect_intrusion(wolf, ctx)
    h.assert_eq(result, "warning")
    h.assert_eq(wolf._intrusion_turns, 1)
end)

test("turn 2 in territory → threat", function()
    local wolf = make_wolf()
    wolf._intrusion_turns = 1
    local ctx = make_context("hallway")
    local result = territorial.detect_intrusion(wolf, ctx)
    h.assert_eq(result, "threat")
    h.assert_eq(wolf._intrusion_turns, 2)
end)

test("turn 3 in territory → attack", function()
    local wolf = make_wolf()
    wolf._intrusion_turns = 2
    local ctx = make_context("hallway")
    local result = territorial.detect_intrusion(wolf, ctx)
    h.assert_eq(result, "attack")
    h.assert_eq(wolf._intrusion_turns, 3)
end)

test("turn 4+ stays attack", function()
    local wolf = make_wolf()
    wolf._intrusion_turns = 5
    local ctx = make_context("hallway")
    local result = territorial.detect_intrusion(wolf, ctx)
    h.assert_eq(result, "attack")
    h.assert_eq(wolf._intrusion_turns, 6)
end)

---------------------------------------------------------------------------
-- Suite 2: counter reset
---------------------------------------------------------------------------
suite("detect_intrusion — counter reset")

test("player leaves territory → counter resets", function()
    local wolf = make_wolf()
    wolf._intrusion_turns = 3
    local ctx = make_context("bedroom")
    local result = territorial.detect_intrusion(wolf, ctx)
    h.assert_eq(result, nil)
    h.assert_eq(wolf._intrusion_turns, nil)
end)

test("creature not in same room as player → nil", function()
    local wolf = make_wolf({ location = "bedroom" })
    wolf._intrusion_turns = 2
    local ctx = make_context("hallway")
    local result = territorial.detect_intrusion(wolf, ctx)
    h.assert_eq(result, nil)
    h.assert_eq(wolf._intrusion_turns, nil)
end)

test("player in non-territory room → nil + reset", function()
    local wolf = make_wolf({ location = "bedroom" })
    local ctx = make_context("bedroom")
    local result = territorial.detect_intrusion(wolf, ctx)
    h.assert_eq(result, nil)
    h.assert_eq(wolf._intrusion_turns, nil)
end)

---------------------------------------------------------------------------
-- Suite 3: edge cases
---------------------------------------------------------------------------
suite("detect_intrusion — edge cases")

test("nil creature → nil", function()
    local ctx = make_context("hallway")
    h.assert_eq(territorial.detect_intrusion(nil, ctx), nil)
end)

test("non-territorial creature → nil", function()
    local wolf = make_wolf()
    wolf.behavior.territorial = nil
    local ctx = make_context("hallway")
    h.assert_eq(territorial.detect_intrusion(wolf, ctx), nil)
end)

test("no territory declared → nil", function()
    local wolf = make_wolf()
    wolf.behavior.territory = nil
    local ctx = make_context("hallway")
    h.assert_eq(territorial.detect_intrusion(wolf, ctx), nil)
end)

test("custom escalation thresholds", function()
    local wolf = make_wolf()
    wolf.behavior.intrusion_escalation = { warning = 2, threat = 4, attack = 6 }
    local ctx = make_context("hallway")
    -- Turn 1: below warning
    h.assert_eq(territorial.detect_intrusion(wolf, ctx), nil)
    -- Turn 2: warning
    h.assert_eq(territorial.detect_intrusion(wolf, ctx), "warning")
    -- Turn 3: still warning
    h.assert_eq(territorial.detect_intrusion(wolf, ctx), "warning")
    -- Turn 4: threat
    h.assert_eq(territorial.detect_intrusion(wolf, ctx), "threat")
    -- Turn 5: still threat
    h.assert_eq(territorial.detect_intrusion(wolf, ctx), "threat")
    -- Turn 6: attack
    h.assert_eq(territorial.detect_intrusion(wolf, ctx), "attack")
end)

test("territory as table of rooms", function()
    local wolf = make_wolf()
    wolf.behavior.territory = {"hallway", "bedroom"}
    wolf.location = "bedroom"
    local ctx = make_context("bedroom")
    local result = territorial.detect_intrusion(wolf, ctx)
    h.assert_eq(result, "warning")
end)

---------------------------------------------------------------------------
-- Suite 4: transfer_territory
---------------------------------------------------------------------------
suite("transfer_territory — alpha death inheritance")

test("dead alpha transfers territory to next healthiest", function()
    local alpha = make_wolf({ health = 0, _state = "dead" })
    alpha.behavior.territory = "hallway"
    local beta = make_wolf({ health = 20 })
    beta.behavior.territory = nil
    local omega = make_wolf({ health = 10 })
    omega.behavior.territory = nil
    local pack = { alpha, beta, omega }

    local new_alpha = pack_tactics.transfer_territory(alpha, pack, {})
    h.assert_eq(new_alpha, beta)
    h.assert_eq(beta.behavior.territory, "hallway")
end)

test("no candidates → nil (all dead/fled)", function()
    local alpha = make_wolf({ health = 0, _state = "dead" })
    alpha.behavior.territory = "hallway"
    local beta = make_wolf({ health = 0, _state = "dead" })
    local pack = { alpha, beta }
    h.assert_eq(pack_tactics.transfer_territory(alpha, pack, {}), nil)
end)

test("no territory on alpha → nil", function()
    local alpha = make_wolf({ health = 0, _state = "dead" })
    alpha.behavior.territory = nil
    local beta = make_wolf({ health = 20 })
    local pack = { alpha, beta }
    h.assert_eq(pack_tactics.transfer_territory(alpha, pack, {}), nil)
end)

test("empty pack → nil", function()
    local alpha = make_wolf({ health = 0, _state = "dead" })
    alpha.behavior.territory = "hallway"
    h.assert_eq(pack_tactics.transfer_territory(alpha, {}, {}), nil)
end)

test("fled members excluded from inheritance", function()
    local alpha = make_wolf({ health = 0, _state = "dead" })
    alpha.behavior.territory = "hallway"
    local beta = make_wolf({ health = 20, _state = "alive-flee" })
    local omega = make_wolf({ health = 10, _state = "alive-idle" })
    omega.behavior.territory = nil
    local pack = { alpha, beta, omega }

    local new_alpha = pack_tactics.transfer_territory(alpha, pack, {})
    h.assert_eq(new_alpha, omega)
    h.assert_eq(omega.behavior.territory, "hallway")
end)

---------------------------------------------------------------------------
-- Suite 5: Wolf metadata verification
---------------------------------------------------------------------------
suite("wolf metadata — WAVE-3 territorial fields")

test("wolf has intrusion_escalation", function()
    if not wolf_def then h.skip("wolf.lua not available"); return end
    local esc = wolf_def.behavior.intrusion_escalation
    h.assert_eq(type(esc), "table")
    h.assert_eq(esc.warning, 1)
    h.assert_eq(esc.threat, 2)
    h.assert_eq(esc.attack, 3)
end)

test("wolf has intrusion_warning reaction", function()
    if not wolf_def then h.skip("wolf.lua not available"); return end
    local react = wolf_def.reactions.intrusion_warning
    h.assert_eq(type(react), "table")
    h.assert_eq(type(react.message), "string")
    h.assert_eq(react.action, "patrol")
end)

test("wolf behavior.territory is hallway", function()
    if not wolf_def then h.skip("wolf.lua not available"); return end
    h.assert_eq(wolf_def.behavior.territory, "hallway")
end)

h.summary()
