-- test/verbs/test-parser-verb-bugs-305-306-310-318-342.lua
-- TDD tests for 5 parser/verb gameplay bugs discovered in playtesting.
--
-- #318: 'exits' command not recognized
-- #342: 'look the rat' fails — article not stripped by look verb
-- #306: 'stomp spider' not recognized — natural combat phrase
-- #305: 'use bandage' not recognized despite being listed as application verb
-- #310: Parser ignores 'with' tool modifier for unlock/lock verbs
--
-- Usage: lua test/verbs/test-parser-verb-bugs-305-306-310-318-342.lua
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
local fsm_mod = require("engine.fsm")

local test = h.test
local suite = h.suite
local eq = h.assert_eq

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

local function make_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = opts.worn or {},
        injuries = opts.injuries or {},
        bags = {},
        state = opts.state or {},
        max_health = 100,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- #318: 'exits' command not recognized
---------------------------------------------------------------------------
suite("#318 — exits command")

test("exits verb exists as handler", function()
    h.assert_truthy(handlers["exits"], "handlers['exits'] should exist")
end)

test("exits lists available room exits", function()
    local ctx = make_ctx({
        exits = {
            north = { name = "a wooden door", hidden = false },
            south = { name = "a stone archway", hidden = false },
        },
    })
    local output = capture_output(function()
        handlers["exits"](ctx, "")
    end)
    h.assert_truthy(output:find("north"), "Should list north exit")
    h.assert_truthy(output:find("south"), "Should list south exit")
end)

test("exits hides hidden exits", function()
    local ctx = make_ctx({
        exits = {
            north = { name = "a wooden door", hidden = false },
            east = { name = "a secret passage", hidden = true },
        },
    })
    local output = capture_output(function()
        handlers["exits"](ctx, "")
    end)
    h.assert_truthy(output:find("north"), "Should list visible north exit")
    h.assert_truthy(not output:find("secret"), "Should NOT list hidden exit")
end)

test("exits shows locked/closed state", function()
    local ctx = make_ctx({
        exits = {
            north = { name = "a wooden door", open = false, locked = true, hidden = false },
            south = { name = "a hallway", hidden = false },
        },
    })
    local output = capture_output(function()
        handlers["exits"](ctx, "")
    end)
    h.assert_truthy(output:find("locked"), "Should show locked state")
end)

test("exits reports no exits when room has none", function()
    local ctx = make_ctx({ exits = {} })
    local output = capture_output(function()
        handlers["exits"](ctx, "")
    end)
    h.assert_truthy(output:find("[Nn]o") or output:find("exit"),
        "Should indicate no exits or mention exits")
end)

---------------------------------------------------------------------------
-- #342: 'look the rat' fails — article not stripped
---------------------------------------------------------------------------
suite("#342 — look with article prefix")

test("look the <object> finds object (article stripped)", function()
    local ctx = make_ctx({ room_contents = { "rat-1" } })
    ctx.registry:register("rat-1", {
        id = "rat",
        name = "a brown rat",
        keywords = {"rat", "brown rat"},
        description = "A scruffy brown rat.",
        on_feel = "Furry.",
    })
    -- Ensure light
    ctx.time_offset = 50000
    local output = capture_output(function()
        handlers["look"](ctx, "the rat")
    end)
    h.assert_truthy(output:find("rat") or output:find("scruffy"),
        "look the rat should find and describe the rat, got: " .. output)
    h.assert_truthy(not output:find("don't notice"),
        "Should not get 'not found' error, got: " .. output)
end)

test("look the brown rat finds object (multi-word with article)", function()
    local ctx = make_ctx({ room_contents = { "rat-1" } })
    ctx.registry:register("rat-1", {
        id = "rat",
        name = "a brown rat",
        keywords = {"rat", "brown rat"},
        description = "A scruffy brown rat.",
        on_feel = "Furry.",
    })
    ctx.time_offset = 50000
    local output = capture_output(function()
        handlers["look"](ctx, "the brown rat")
    end)
    h.assert_truthy(not output:find("don't notice"),
        "look the brown rat should work, got: " .. output)
end)

---------------------------------------------------------------------------
-- #306: 'stomp spider' not recognized
---------------------------------------------------------------------------
suite("#306 — stomp as combat alias")

test("stomp verb exists as handler", function()
    h.assert_truthy(handlers["stomp"], "handlers['stomp'] should exist")
end)

test("stomp is same handler function as attack or kick/hit", function()
    h.assert_truthy(
        handlers["stomp"] == handlers["attack"]
        or handlers["stomp"] == handlers["kick"]
        or handlers["stomp"] == handlers["hit"],
        "stomp should alias attack, kick, or hit"
    )
end)

---------------------------------------------------------------------------
-- #305: 'use bandage' not recognized
---------------------------------------------------------------------------
suite("#305 — use bandage routes to apply")

test("use bandage with cures triggers apply handler", function()
    local bandage = {
        id = "silk-bandage",
        name = "a silk bandage",
        keywords = {"bandage", "silk bandage"},
        cures = {"bleeding", "minor-cut"},
        _state = "unused",
        initial_state = "unused",
        applied_to = nil,
        states = {
            unused = { description = "A clean silk bandage." },
            applied = { description = "The bandage is wrapped around a wound." },
        },
        transitions = {
            { from = "unused", to = "applied", verb = "apply",
              message = "You carefully wrap the silk bandage around the wound." },
        },
        on_feel = "Soft silk strip.",
        portable = true,
    }
    local ctx = make_ctx({
        hands = { bandage, nil },
        injuries = {
            { type = "bleeding", body_area = "left arm", severity = 3,
              ticks_remaining = 10, source = "rat bite" },
        },
    })
    ctx.registry:register("silk-bandage", bandage)
    local output = capture_output(function()
        handlers["use"](ctx, "bandage")
    end)
    -- Should NOT get "don't know how to use" — should route to apply
    h.assert_truthy(not output:find("don't know how to use"),
        "use bandage should work, got: " .. output)
end)

---------------------------------------------------------------------------
-- #310: Parser ignores 'with' tool modifier for unlock/lock verbs
---------------------------------------------------------------------------
suite("#310 — unlock/lock with tool modifier")

test("unlock <object> with <key> strips 'with' and finds object", function()
    local padlock = {
        id = "padlock",
        name = "a brass padlock",
        keywords = {"padlock", "lock", "brass padlock"},
        _state = "locked",
        initial_state = "locked",
        states = {
            locked = { description = "A locked brass padlock." },
            unlocked = { description = "The padlock hangs open." },
        },
        transitions = {
            { from = "locked", to = "unlocked", verb = "unlock",
              requires_tool = "brass_key",
              message = "You unlock the padlock with a click." },
        },
        on_feel = "Cold metal.",
    }
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
        portable = true,
        provides_tool = {"brass_key"},
        on_feel = "Small metal key.",
    }
    local ctx = make_ctx({
        verb = "unlock",
        room_contents = { "padlock-1" },
        hands = { key, nil },
    })
    ctx.registry:register("padlock-1", padlock)
    ctx.registry:register("brass-key-1", key)
    local output = capture_output(function()
        handlers["unlock"](ctx, "padlock with brass key")
    end)
    -- Should NOT get "don't notice anything" — the 'with brass key' should be stripped
    h.assert_truthy(not output:find("don't notice"),
        "unlock padlock with brass key should find padlock, got: " .. output)
end)

test("lock <object> with <key> strips 'with' and finds object", function()
    local padlock = {
        id = "padlock",
        name = "a brass padlock",
        keywords = {"padlock", "lock", "brass padlock"},
        _state = "unlocked",
        initial_state = "unlocked",
        states = {
            locked = { description = "A locked brass padlock." },
            unlocked = { description = "The padlock hangs open." },
        },
        transitions = {
            { from = "unlocked", to = "locked", verb = "lock",
              requires_tool = "brass_key",
              message = "You lock the padlock with a click." },
        },
        on_feel = "Cold metal.",
    }
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
        portable = true,
        provides_tool = {"brass_key"},
        on_feel = "Small metal key.",
    }
    local ctx = make_ctx({
        verb = "lock",
        room_contents = { "padlock-1" },
        hands = { key, nil },
    })
    ctx.registry:register("padlock-1", padlock)
    ctx.registry:register("brass-key-1", key)
    local output = capture_output(function()
        handlers["lock"](ctx, "padlock with brass key")
    end)
    h.assert_truthy(not output:find("don't notice"),
        "lock padlock with brass key should find padlock, got: " .. output)
end)

---------------------------------------------------------------------------
local fail_count = h.summary()
os.exit(fail_count == 0 and 0 or 1)
