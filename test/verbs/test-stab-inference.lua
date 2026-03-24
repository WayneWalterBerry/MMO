-- test/verbs/test-stab-inference.lua
-- Issue #49 verification: "stab yourself" infers weapon from hand contents.
--
-- Covers:
--   1. Player holding knife + "stab yourself" → uses knife, creates injury
--   2. Player holding nothing + "stab yourself" → helpful error
--   3. Player holding non-weapon + "stab yourself" → appropriate message
--   4. Multiple self-reference phrasings (self, myself, yourself, me)
--   5. Weapon inference for cut/slash verbs too (shared logic)
--
-- Usage: lua test/verbs/test-stab-inference.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
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
        keywords = {"knife", "blade", "small knife"},
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

local function fresh_candle()
    return {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        categories = {"small"},
        portable = true,
        on_feel = "Waxy cylinder, cool to the touch.",
        mutations = {},
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
    local objs = opts.objects or {}
    local reg = make_mock_registry(objs)
    local player = opts.player or fresh_player()

    if opts.hand1 then player.hands[1] = opts.hand1 end
    if opts.hand2 then player.hands[2] = opts.hand2 end

    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A test room.",
        contents = {},
        exits = {},
        light_level = 0,
    }

    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
end

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
-- 1. Holding weapon + "stab yourself" → weapon inferred, injury created
---------------------------------------------------------------------------
suite("#49 weapon inference: knife in hand → auto-infer")

test("'stab self' with knife in hand infers knife", function()
    setup_injuries()
    local knife = fresh_knife()
    local ctx = make_ctx({ hand1 = knife, objects = { knife = knife }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "'stab self' must auto-infer knife and create injury")
    h.assert_eq("bleeding", ctx.player.injuries[1].type,
        "Inferred knife stab must produce bleeding injury")
end)

test("'stab myself' with knife in hand infers knife", function()
    setup_injuries()
    local knife = fresh_knife()
    local ctx = make_ctx({ hand1 = knife, objects = { knife = knife }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "myself") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "'stab myself' must auto-infer knife")
end)

test("'stab yourself' with knife in hand infers knife", function()
    setup_injuries()
    local knife = fresh_knife()
    local ctx = make_ctx({ hand1 = knife, objects = { knife = knife }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "yourself") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "'stab yourself' must auto-infer knife")
end)

test("'stab me' with knife in hand infers knife", function()
    setup_injuries()
    local knife = fresh_knife()
    local ctx = make_ctx({ hand1 = knife, objects = { knife = knife }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "me") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "'stab me' must auto-infer knife")
end)

test("inferred stab prints weapon description with body area", function()
    setup_injuries()
    local knife = fresh_knife()
    local ctx = make_ctx({ hand1 = knife, objects = { knife = knife }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(output:find("stab the knife"),
        "Output must include knife's on_stab description")
end)

test("inferred stab sets bloody state", function()
    setup_injuries()
    local knife = fresh_knife()
    local ctx = make_ctx({ hand1 = knife, objects = { knife = knife }, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(ctx.player.state.bloody,
        "Player should be bloody after inferred stab")
end)

test("knife in second hand still gets inferred", function()
    setup_injuries()
    local knife = fresh_knife()
    local ctx = make_ctx({ hand2 = knife, objects = { knife = knife }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "Knife in hand slot 2 must still be inferred")
end)

---------------------------------------------------------------------------
-- 2. Holding nothing + "stab yourself" → error message
---------------------------------------------------------------------------
suite("#49 weapon inference: empty hands → error")

test("'stab self' with empty hands says nothing sharp", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT create injury with empty hands")
    h.assert_truthy(output:find("nothing sharp"),
        "Must tell player they have nothing sharp")
end)

test("'stab myself' with empty hands says nothing sharp", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "myself") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT create injury")
    h.assert_truthy(output:find("nothing sharp"),
        "Must say nothing sharp")
end)

test("'stab yourself' with empty hands says nothing sharp", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "yourself") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT create injury")
    h.assert_truthy(output:find("nothing sharp"),
        "Must say nothing sharp")
end)

---------------------------------------------------------------------------
-- 3. Holding non-weapon + "stab yourself" → appropriate message
---------------------------------------------------------------------------
suite("#49 weapon inference: non-weapon in hand → appropriate error")

test("'stab self' holding pillow (no on_stab) says nothing sharp", function()
    setup_injuries()
    local pillow = fresh_pillow()
    local ctx = make_ctx({ hand1 = pillow, objects = { pillow = pillow }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT create injury with pillow")
    h.assert_truthy(output:find("nothing sharp"),
        "Pillow has no on_stab → must say nothing sharp")
end)

test("'stab self' holding candle (no on_stab) says nothing sharp", function()
    setup_injuries()
    local candle = fresh_candle()
    local ctx = make_ctx({ hand1 = candle, objects = { candle = candle }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT create injury with candle")
    h.assert_truthy(output:find("nothing sharp"),
        "Candle has no on_stab → must say nothing sharp")
end)

test("non-weapon specified explicitly says can't stab with it", function()
    setup_injuries()
    local pillow = fresh_pillow()
    local ctx = make_ctx({ hand1 = pillow, objects = { pillow = pillow }, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self with pillow") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT create injury")
    h.assert_truthy(output:find("can't stab yourself with"),
        "Explicit non-weapon must say can't stab with it")
end)

---------------------------------------------------------------------------
-- 4. Weapon inference for CUT verb (shared logic)
---------------------------------------------------------------------------
suite("#49 weapon inference: cut verb also infers weapon")

test("'cut self' with knife in hand infers knife", function()
    setup_injuries()
    local knife = fresh_knife()
    local ctx = make_ctx({ hand1 = knife, objects = { knife = knife }, verb = "cut" })
    local output = capture_output(function() handlers["cut"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "'cut self' must auto-infer knife for on_cut")
    h.assert_eq("minor-cut", ctx.player.injuries[1].type,
        "Inferred knife cut must produce minor-cut injury")
end)

test("'cut self' with empty hands says nothing sharp", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "cut" })
    local output = capture_output(function() handlers["cut"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT create injury")
    h.assert_truthy(output:find("nothing sharp"),
        "Must say nothing sharp to cut with")
end)

test("'cut self' holding non-weapon says nothing sharp", function()
    setup_injuries()
    local pillow = fresh_pillow()
    local ctx = make_ctx({ hand1 = pillow, objects = { pillow = pillow }, verb = "cut" })
    local output = capture_output(function() handlers["cut"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT create injury")
    h.assert_truthy(output:find("nothing sharp"),
        "Pillow has no on_cut → nothing sharp")
end)

---------------------------------------------------------------------------
-- 5. Two weapons → disambiguation (not auto-pick)
---------------------------------------------------------------------------
suite("#49 weapon inference: two weapons → disambiguation")

test("'stab self' with two stab-capable weapons asks which", function()
    setup_injuries()
    local knife = fresh_knife()
    local dagger = {
        id = "silver-dagger",
        name = "a silver dagger",
        keywords = {"dagger", "silver dagger"},
        categories = {"weapon", "sharp"},
        portable = true,
        on_stab = {
            damage = 8,
            injury_type = "bleeding",
            description = "You drive the dagger into your %s.",
        },
        mutations = {},
    }
    local ctx = make_ctx({
        hand1 = knife, hand2 = dagger,
        objects = { knife = knife, ["silver-dagger"] = dagger },
        verb = "stab",
    })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Must NOT auto-pick when ambiguous")
    h.assert_truthy(output:find("with what") or output:find("holding"),
        "Must prompt disambiguation listing held weapons")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
