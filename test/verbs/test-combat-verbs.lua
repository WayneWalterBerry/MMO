-- test/verbs/test-combat-verbs.lua
-- Unit tests for stab/cut/slash combat verb handlers.
-- Tests edge cases: wrong object, no weapon, dark room, verb aliases.
--
-- Usage: lua test/verbs/test-combat-verbs.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")
local injury_mod = require("engine.injuries")

local test = h.test
local suite = h.suite

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function fresh_knife()
    return {
        id = "knife",
        name = "a small knife",
        keywords = {"knife", "blade", "small knife", "dagger"},
        categories = {"small", "tool", "weapon", "sharp", "metal"},
        portable = true,
        provides_tool = {"cutting_edge", "injury_source"},
        on_stab = {
            damage = 5,
            injury_type = "bleeding",
            description = "You stab the knife into your %s. It hurts more than you expected.",
        },
        on_cut = {
            damage = 3,
            injury_type = "minor-cut",
            description = "You nick your %s with the knife. A shallow cut — it stings.",
        },
        mutations = {},
    }
end

local function fresh_pillow()
    return {
        id = "pillow",
        name = "a pillow",
        keywords = {"pillow", "cushion"},
        categories = {"soft"},
        portable = true,
        mutations = {},
    }
end

local function fresh_rag()
    return {
        id = "rag",
        name = "a dirty rag",
        keywords = {"rag", "cloth"},
        categories = {"cloth"},
        portable = true,
        mutations = {
            cut = {
                requires_tool = "cutting_edge",
                message = "You cut the rag into strips.",
                becomes = nil,
                spawns = nil,
            },
        },
    }
end

local function fresh_player()
    return {
        max_health = 100,
        injuries = {},
        hands = { nil, nil },
        worn_items = {},
        bags = {},
        worn = {},
        state = {},
    }
end

local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
        find_by_keyword = function(self, kw)
            local results = {}
            for _, obj in pairs(self._objects) do
                if obj.keywords then
                    for _, k in ipairs(obj.keywords) do
                        if k:lower() == kw:lower() then
                            results[#results + 1] = obj
                            break
                        end
                    end
                end
            end
            return results
        end,
    }
end

local function make_ctx(opts)
    opts = opts or {}
    local knife = opts.knife or fresh_knife()
    local objs = opts.objects or {}
    if opts.knife_in_hand then
        objs.knife = knife
    end
    local reg = make_mock_registry(objs)
    local player = opts.player or fresh_player()
    if opts.knife_in_hand then
        player.hands[1] = knife
    end

    local room = opts.room or {
        id = "test-room",
        name = "Test Room",
        description = "A test room.",
        contents = opts.room_contents or {},
        exits = {},
        light_level = opts.light_level or 0,
    }

    -- Add curtains for light if needed
    if opts.has_light then
        local curtains = {
            id = "curtains", name = "curtains",
            keywords = {"curtains"}, allows_daylight = true, hidden = true,
        }
        reg._objects.curtains = curtains
        room.contents[#room.contents + 1] = "curtains"
    end

    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.has_light and 8 or 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
end

-- Register injury definitions used by the knife
local function setup_injuries()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("bleeding", {
        id = "bleeding", name = "Bleeding Wound",
        category = "physical", damage_type = "over_time",
        initial_state = "active",
        on_inflict = { initial_damage = 5, damage_per_tick = 5, message = "Blood wells." },
        states = {
            active = { name = "bleeding", damage_per_tick = 5 },
            treated = { name = "bandaged", damage_per_tick = 0 },
            healed = { name = "healed", terminal = true },
        },
        healing_interactions = {},
    })
    injury_mod.register_definition("minor-cut", {
        id = "minor-cut", name = "Minor Cut",
        category = "physical", damage_type = "one_time",
        initial_state = "active",
        on_inflict = { initial_damage = 3, damage_per_tick = 0, message = "A thin red line." },
        states = {
            active = { name = "minor cut", damage_per_tick = 0, auto_heal_turns = 5 },
            healed = { name = "healed", terminal = true },
        },
        healing_interactions = {},
    })
end

---------------------------------------------------------------------------
-- STAB verb tests
---------------------------------------------------------------------------
suite("stab — empty noun")

test("stab with no noun prints prompt", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "") end)
    h.assert_truthy(output:find("Stab what"), "Should ask 'Stab what?'")
end)

suite("stab self — with knife in hand")

test("stab self with knife inflicts bleeding injury", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Should inflict an injury")
    h.assert_eq("bleeding", ctx.player.injuries[1].type, "Injury type should be bleeding")
end)

test("stab self with knife sets bloody state", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(ctx.player.state.bloody, "Player should be bloody after stab")
    h.assert_eq(10, ctx.player.state.bleed_ticks, "Bleed ticks should be 10")
end)

test("stab self with knife prints body area description", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    math.randomseed(42)
    local output = capture_output(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(output:find("stab the knife"), "Should print stab description")
end)

suite("stab self — no weapon")

test("stab self with no weapon says nothing sharp", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(output:find("nothing sharp"), "Should say nothing sharp to stab with")
end)

suite("stab self — wrong weapon")

test("stab self with pillow fails (no on_stab profile)", function()
    setup_injuries()
    local pillow = fresh_pillow()
    local ctx = make_ctx({
        verb = "stab",
        objects = { pillow = pillow },
        player = fresh_player(),
    })
    ctx.player.hands[1] = pillow
    local output = capture_output(function() handlers["stab"](ctx, "self with pillow") end)
    h.assert_truthy(output:find("can't stab yourself with"), "Should reject pillow as weapon")
end)

suite("stab — world object (non-self target)")

test("stab a non-self target says self-only", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab", has_light = true })
    local output = capture_output(function() handlers["stab"](ctx, "table") end)
    h.assert_truthy(output:find("only stab yourself") or output:find("stab self"),
        "Should indicate stab is self-only")
end)

suite("stab — body area targeting")

test("stab my left arm with knife targets left arm", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "my left arm with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Should inflict injury")
    h.assert_eq("left arm", ctx.player.injuries[1].location, "Injury location should be left arm")
end)

test("stab my torso with knife applies torso damage modifier", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "my torso with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Should inflict injury")
    h.assert_eq("torso", ctx.player.injuries[1].location, "Should target torso")
    -- Torso has 1.5x modifier, base damage 5 → 7
    h.assert_eq(7, ctx.player.injuries[1].damage, "Torso should get 1.5x damage (7)")
end)

suite("stab — weapon specified but not carried")

test("stab self with uncarried weapon prints not-have message", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self with sword") end)
    h.assert_truthy(output:find("don't have sword"), "Should say you don't have that weapon")
end)

---------------------------------------------------------------------------
-- CUT verb tests
---------------------------------------------------------------------------
suite("cut — empty noun")

test("cut with no noun prints prompt", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "cut" })
    local output = capture_output(function() handlers["cut"](ctx, "") end)
    h.assert_truthy(output:find("Cut what"), "Should ask 'Cut what?'")
end)

suite("cut self — with knife in hand")

test("cut self with knife inflicts minor-cut injury", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "cut" })
    local output = capture_output(function() handlers["cut"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Should inflict an injury")
    h.assert_eq("minor-cut", ctx.player.injuries[1].type, "Injury type should be minor-cut")
end)

test("cut self with knife prints description with body area", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "cut" })
    math.randomseed(42)
    local output = capture_output(function() handlers["cut"](ctx, "self with knife") end)
    h.assert_truthy(output:find("nick your"), "Should print cut description")
end)

suite("cut self — no weapon")

test("cut self with no weapon says nothing sharp", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "cut" })
    local output = capture_output(function() handlers["cut"](ctx, "self") end)
    h.assert_truthy(output:find("nothing sharp"), "Should say nothing sharp to cut with")
end)

suite("cut world object — in dark room")

test("cut object in dark room says too dark", function()
    setup_injuries()
    local rag = fresh_rag()
    local ctx = make_ctx({
        knife_in_hand = true, verb = "cut",
        objects = { rag = rag, knife = fresh_knife() },
        room_contents = { "rag" },
        has_light = false,
    })
    ctx.player.hands[1] = fresh_knife()
    local output = capture_output(function() handlers["cut"](ctx, "rag") end)
    h.assert_truthy(output:find("too dark") or output:find("don't notice"),
        "Should fail in darkness")
end)

suite("cut world object — with light and tool")

test("cut rag with knife in lit room uses mutation", function()
    setup_injuries()
    local rag = fresh_rag()
    local knife = fresh_knife()
    local ctx = make_ctx({
        knife_in_hand = true, verb = "cut",
        objects = { rag = rag, knife = knife },
        room_contents = { "rag" },
        has_light = true,
    })
    ctx.player.hands[1] = knife
    -- The cut mutation requires a tool and perform_mutation needs loader/sources;
    -- since mutation.becomes is nil and spawns is nil, it should just print the message
    -- We need object_sources, loader, mutation, templates for the full path.
    -- For this test, we verify the mutation is found and the right message is attempted.
    local output = capture_output(function() handlers["cut"](ctx, "rag with knife") end)
    h.assert_truthy(output:find("cut the rag") or output:find("cut") or output:find("strips"),
        "Should attempt to cut the rag")
end)

suite("cut — uncuttable object")

test("cut an object with no cut mutation says can't cut", function()
    setup_injuries()
    local pillow = fresh_pillow()
    local knife = fresh_knife()
    local ctx = make_ctx({
        knife_in_hand = true, verb = "cut",
        objects = { pillow = pillow, knife = knife },
        room_contents = { "pillow" },
        has_light = true,
    })
    ctx.player.hands[1] = knife
    local output = capture_output(function() handlers["cut"](ctx, "pillow") end)
    h.assert_truthy(output:find("can't cut"), "Should say can't cut pillow")
end)

---------------------------------------------------------------------------
-- SLASH verb tests
---------------------------------------------------------------------------
suite("slash — empty noun")

test("slash with no noun prints prompt", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "slash" })
    local output = capture_output(function() handlers["slash"](ctx, "") end)
    h.assert_truthy(output:find("Slash what"), "Should ask 'Slash what?'")
end)

suite("slash self — knife has no on_slash profile")

test("slash self with knife fails (no on_slash profile on knife)", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "slash" })
    local output = capture_output(function() handlers["slash"](ctx, "self with knife") end)
    -- Knife has no on_slash profile, so it should reject
    h.assert_truthy(output:find("can't slash yourself with") or output:find("nothing sharp"),
        "Knife should not support slash (no on_slash profile)")
end)

suite("slash self — with proper slashing weapon")

test("slash self with weapon that has on_slash works", function()
    setup_injuries()
    local dagger = {
        id = "dagger", name = "a silver dagger",
        keywords = {"dagger", "silver dagger"},
        on_slash = {
            damage = 4, injury_type = "bleeding",
            description = "You slash your %s with the dagger. Blood wells up.",
        },
    }
    local ctx = make_ctx({
        verb = "slash",
        objects = { dagger = dagger },
    })
    ctx.player.hands[1] = dagger
    local output = capture_output(function() handlers["slash"](ctx, "self with dagger") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Should inflict an injury")
    h.assert_eq("bleeding", ctx.player.injuries[1].type, "Injury should be bleeding")
end)

suite("slash — falls through to cut for world objects")

test("slash world object delegates to cut handler", function()
    setup_injuries()
    local pillow = fresh_pillow()
    local knife = fresh_knife()
    local ctx = make_ctx({
        knife_in_hand = true, verb = "slash",
        objects = { pillow = pillow, knife = knife },
        room_contents = { "pillow" },
        has_light = true,
    })
    ctx.player.hands[1] = knife
    local output = capture_output(function() handlers["slash"](ctx, "pillow") end)
    h.assert_truthy(output:find("can't cut"), "Slash fallback should use cut logic")
end)

---------------------------------------------------------------------------
-- Verb alias tests
---------------------------------------------------------------------------
suite("verb aliases")

test("jab routes to stab handler", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "jab" })
    local output = capture_output(function() handlers["jab"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "jab should route to stab and inflict injury")
end)

test("pierce routes to stab handler", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "pierce" })
    local output = capture_output(function() handlers["pierce"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "pierce should route to stab")
end)

test("slice routes to cut handler", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "slice" })
    local output = capture_output(function() handlers["slice"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "slice should route to cut")
    h.assert_eq("minor-cut", ctx.player.injuries[1].type, "slice → cut → minor-cut")
end)

test("carve routes to butcher handler", function()
    setup_injuries()
    -- carve → butcher (not slash — butchery alias, see #381)
    local ctx = make_ctx({ verb = "carve" })
    local output = capture_output(function() handlers["carve"](ctx, "") end)
    h.assert_truthy(output:find("Butcher what"), "carve should route to butcher")
end)

---------------------------------------------------------------------------
-- HIT/PUNCH — #278 regression: unresolved noun → not-found (not self-harm)
---------------------------------------------------------------------------
suite("hit — #278: unresolved noun prints not-found")

test("hit rat with no rat present prints not-found, not self-harm suggestion", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "hit" })
    local output = capture_output(function() handlers["hit"](ctx, "rat") end)
    h.assert_truthy(output:find("don't notice anything") or output:find("don't see"),
        "Should print not-found, got: " .. output)
    h.assert_nil(output:find("only hit yourself"),
        "Must NOT suggest self-harm for unresolved noun")
end)

test("punch table with no table present prints not-found", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "punch" })
    local output = capture_output(function() handlers["punch"](ctx, "table") end)
    h.assert_truthy(output:find("don't notice anything") or output:find("don't see"),
        "Should print not-found, got: " .. output)
end)

test("hit with no noun still prints 'Hit what?'", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "hit" })
    local output = capture_output(function() handlers["hit"](ctx, "") end)
    h.assert_truthy(output:find("Hit what"), "Empty noun should prompt, got: " .. output)
end)

test("hit self still triggers self-infliction", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "hit" })
    local output = capture_output(function() handlers["hit"](ctx, "self") end)
    h.assert_truthy(output:find("punch") or output:find("hit") or #ctx.player.injuries > 0,
        "hit self should still work")
end)

test("hit head still triggers self-infliction", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "hit" })
    local output = capture_output(function() handlers["hit"](ctx, "head") end)
    h.assert_truthy(output:find("hit your head") or output:find("punch") or #ctx.player.injuries > 0,
        "hit head should still work")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
