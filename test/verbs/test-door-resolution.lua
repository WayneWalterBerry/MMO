-- test/verbs/test-door-resolution.lua
-- Bug #170: Door not found despite just being discovered
-- TDD-FIRST: These tests MUST FAIL on current code to prove the bug exists.
--
-- The bedroom has BOTH a bedroom-door OBJECT (FSM with barred/unbarred/open
-- states) AND an exit door in room.exits. When the player types "open door":
--   1. find_visible("door") finds the bedroom-door OBJECT (matches keyword)
--   2. Handler enters FSM path (obj.states exists)
--   3. Finds "open" transition (from=unbarred) but current state is "barred"
--   4. fsm_mod.transition fails → prints "You can't open a heavy oak door."
--   5. Handler RETURNS without ever checking room.exits
--
-- The door is "found" by find_visible but can't be opened, and the handler
-- never falls through to the exit check. The player sees "can't open" with
-- no explanation that it's BARRED.
--
-- Usage: lua test/verbs/test-door-resolution.lua
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
        worn = {},
        injuries = {},
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
        current_verb = opts.verb or "open",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

-- Realistic door OBJECT with FSM (like bedroom-door.lua)
-- In "barred" state, NO "open" transition exists → FSM fails
local function make_door_object()
    return {
        id = "bedroom-door",
        name = "a heavy oak door",
        keywords = {"door", "oak door", "heavy door", "bedroom door"},
        material = "oak",
        size = 6,
        weight = 120,
        portable = false,
        on_feel = "Rough oak grain, cold iron bands.",
        linked_exit = "north",
        _state = "barred",
        initial_state = "barred",
        states = {
            barred = {
                name = "a heavy oak door",
                description = "Barred from the other side.",
                on_feel = "Solid — no give when you push.",
            },
            unbarred = {
                name = "an unbarred oak door",
                description = "Closed but no longer barred.",
            },
            open = {
                name = "an open oak door",
                description = "Stands open, revealing a corridor beyond.",
            },
        },
        transitions = {
            { from = "barred", to = "unbarred", verb = "unbar",
              message = "The bar is lifted." },
            { from = "unbarred", to = "open", verb = "open",
              message = "You push the door open on groaning hinges." },
            { from = "open", to = "unbarred", verb = "close",
              message = "You push the door shut." },
        },
    }
end

-- Realistic room exit door (matches hallway.lua pattern)
local function make_door_exit(opts)
    opts = opts or {}
    return {
        target = opts.target or "other-room",
        type = "door",
        name = opts.name or "a heavy oak door",
        keywords = opts.keywords or {"door", "oak door", "heavy door"},
        description = "A heavy oak door with iron hinges.",
        open = opts.open or false,
        locked = opts.locked or false,
        key_id = opts.key_id or nil,
        mutations = {
            open = {
                condition = function(self) return not self.locked end,
                becomes_exit = { open = true },
                message = opts.open_message or "The door swings open on groaning hinges.",
            },
        },
    }
end

---------------------------------------------------------------------------
-- Bug #170: Door object intercepts resolution, blocks exit check
---------------------------------------------------------------------------
suite("#170 — door object intercepts: FSM failure blocks exit fallthrough")

test("open door with barred door object — should explain WHY it can't open", function()
    -- Room has bedroom-door OBJECT (barred state, no "open" transition from barred)
    -- AND an exit door to the north. Player types "open door".
    --
    -- BUG: find_visible finds the door OBJECT, FSM path runs but fails
    -- (no open transition from barred), handler prints generic "can't open"
    -- without saying WHY (barred). Should give a meaningful reason.
    local door_obj = make_door_object()

    local ctx = make_ctx({
        room_contents = {"bedroom-door"},
        exits = {
            north = make_door_exit({ locked = false }),
        },
    })
    ctx.registry:register("bedroom-door", door_obj)

    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)

    -- Should explain the door is BARRED (not generic "can't open")
    h.assert_truthy(
        output:find("barred") or output:find("bar") or output:find("other side")
            or output:find("blocked") or output:find("held"),
        "Should explain door is barred, not generic 'can't open'; got: " .. output)
end)

test("open door with barred door object — should NOT say generic 'can't open'", function()
    local door_obj = make_door_object()

    local ctx = make_ctx({
        room_contents = {"bedroom-door"},
        exits = {
            north = make_door_exit({ locked = false }),
        },
    })
    ctx.registry:register("bedroom-door", door_obj)

    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)

    -- The generic "You can't open" message is unhelpful and confusing
    h.assert_truthy(not output:find("You can't open"),
        "Should not give generic 'can't open' for a barred door; got: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #170: "open door with key" when door object AND exit both exist
---------------------------------------------------------------------------
suite("#170 — open door with key: door object + exit coexistence")

test("open door with key when locked exit exists alongside door object", function()
    -- Room has both a door OBJECT and a locked exit. Player has the key.
    -- "open door with key" should unlock and open the exit door.
    -- BUG: door object intercepts find_visible, handler never reaches exits.
    local door_obj = make_door_object()
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
        portable = true,
        on_feel = "Cold metal.",
        size = 1,
    }

    local ctx = make_ctx({
        room_contents = {"bedroom-door"},
        exits = {
            north = make_door_exit({ locked = true, key_id = "brass-key" }),
        },
    })
    ctx.registry:register("bedroom-door", door_obj)
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key
    ctx.tool_noun = "key"

    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)

    -- The door object should not block the exit resolution when it can't be opened
    h.assert_truthy(
        output:find("barred") or output:find("bar") or output:find("unlock")
            or ctx.current_room.exits.north.open,
        "Should either explain barred or fall through to exit; got: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #170: Exit door alone (no object) — baseline
---------------------------------------------------------------------------
suite("#170 — exit-only doors: baseline resolution")

test("open door finds unlocked exit door by keyword 'door'", function()
    local ctx = make_ctx({
        exits = {
            north = make_door_exit({ locked = false }),
        },
    })

    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)

    h.assert_truthy(ctx.current_room.exits.north.open,
        "Door should be open after 'open door'; got output: " .. output)
end)

test("open by direction resolves the exit door", function()
    local ctx = make_ctx({
        exits = {
            north = make_door_exit({ locked = false }),
        },
    })

    local output = capture_output(function()
        handlers["open"](ctx, "north")
    end)

    h.assert_truthy(ctx.current_room.exits.north.open,
        "'open north' should find and open the exit door; got: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #170: "open door with key" on exit-only door (critical path)
---------------------------------------------------------------------------
suite("#170 — exit-only: open door with key unlocks and opens")

test("open door with key unlocks and opens exit in cellar-like room", function()
    -- Room has ONLY an exit door (no door instance object) with key_id.
    -- Player holds the key. "open door with key" should unlock + open.
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
        portable = true,
        on_feel = "Cold metal.",
        size = 1,
    }

    local ctx = make_ctx({
        exits = {
            north = make_door_exit({
                locked = true,
                key_id = "brass-key",
            }),
        },
    })
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key
    ctx.tool_noun = "key"

    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)

    eq(ctx.current_room.exits.north.locked, false,
        "Door should be unlocked; output: " .. output)
    eq(ctx.current_room.exits.north.open, true,
        "Door should be open after 'open door with key'; output: " .. output)
end)

test("open door with wrong key says it doesn't fit", function()
    local wrong_key = {
        id = "silver-key",
        name = "a silver key",
        keywords = {"key", "silver key"},
        portable = true,
        on_feel = "Cool silver.",
        size = 1,
    }

    local ctx = make_ctx({
        exits = {
            north = make_door_exit({
                locked = true,
                key_id = "brass-key",
            }),
        },
    })
    ctx.registry:register("silver-key", wrong_key)
    ctx.player.hands[1] = wrong_key
    ctx.tool_noun = "key"

    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)

    h.assert_truthy(output:find("doesn't fit") or output:find("not fit"),
        "Should say key doesn't fit; got: " .. output)
    eq(ctx.current_room.exits.north.locked, true,
        "Door should remain locked")
end)

---------------------------------------------------------------------------
-- Bug #170: "close door" on exit doors
---------------------------------------------------------------------------
suite("#170 — close door on exit doors")

test("close door closes an open exit door", function()
    local ctx = make_ctx({
        exits = {
            north = {
                target = "other-room",
                type = "door",
                name = "a heavy oak door",
                keywords = {"door", "oak door"},
                open = true,
                locked = false,
                mutations = {
                    close = {
                        becomes_exit = { open = false },
                        message = "You push the door shut.",
                    },
                },
            },
        },
    })

    local output = capture_output(function()
        handlers["close"](ctx, "door")
    end)

    eq(ctx.current_room.exits.north.open, false,
        "Door should be closed; output: " .. output)
end)

test("close door on already-closed exit says already closed", function()
    local ctx = make_ctx({
        exits = {
            north = make_door_exit({ locked = false }),
        },
    })

    local output = capture_output(function()
        handlers["close"](ctx, "door")
    end)

    h.assert_truthy(output:lower():find("already closed"),
        "Should say already closed; got: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #170: "unlock door" / "unlock door with key" on exit doors
---------------------------------------------------------------------------
suite("#170 — unlock door on exit doors")

test("unlock door with key unlocks exit door", function()
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
        portable = true,
        on_feel = "Cold metal.",
        size = 1,
    }

    local ctx = make_ctx({
        exits = {
            north = make_door_exit({
                locked = true,
                key_id = "brass-key",
            }),
        },
    })
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key

    local output = capture_output(function()
        handlers["unlock"](ctx, "door with key")
    end)

    eq(ctx.current_room.exits.north.locked, false,
        "Door should be unlocked; output: " .. output)
end)

test("unlock door without specifying key auto-finds key in hands", function()
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
        portable = true,
        on_feel = "Cold metal.",
        size = 1,
    }

    local ctx = make_ctx({
        exits = {
            north = make_door_exit({
                locked = true,
                key_id = "brass-key",
            }),
        },
    })
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key

    local output = capture_output(function()
        handlers["unlock"](ctx, "door")
    end)

    eq(ctx.current_room.exits.north.locked, false,
        "Door should be unlocked even without specifying key; output: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #170: "lock" verb handler (currently missing!)
---------------------------------------------------------------------------
suite("#170 — lock verb handler")

test("lock handler exists", function()
    h.assert_truthy(handlers["lock"],
        "handlers['lock'] should exist")
end)

test("lock open exit door closes and locks it", function()
    if not handlers["lock"] then
        error("lock handler does not exist yet")
    end

    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
        portable = true,
        on_feel = "Cold metal.",
        size = 1,
    }

    local ctx = make_ctx({
        exits = {
            north = {
                target = "other-room",
                type = "door",
                name = "a heavy oak door",
                keywords = {"door", "oak door"},
                open = true,
                locked = false,
                key_id = "brass-key",
                mutations = {
                    close = {
                        becomes_exit = { open = false },
                        message = "You push the door shut.",
                    },
                },
            },
        },
    })
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key

    local output = capture_output(function()
        handlers["lock"](ctx, "door")
    end)

    eq(ctx.current_room.exits.north.locked, true,
        "Door should be locked; output: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #170: noun resolver returns exit doors by various keywords
---------------------------------------------------------------------------
suite("#170 — exit_matches keyword resolution")

test("exit found by keyword 'door'", function()
    local ctx = make_ctx({
        exits = {
            north = make_door_exit({}),
        },
    })

    -- Verify exit_matches works (test through open handler)
    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)

    eq(ctx.current_room.exits.north.open, true,
        "'door' should match exit; output: " .. output)
end)

test("exit found by name substring 'oak door'", function()
    local ctx = make_ctx({
        exits = {
            north = make_door_exit({
                name = "a heavy oak door",
                keywords = {"door", "oak door", "heavy door"},
            }),
        },
    })

    local output = capture_output(function()
        handlers["open"](ctx, "oak door")
    end)

    eq(ctx.current_room.exits.north.open, true,
        "'oak door' should match exit keywords; output: " .. output)
end)

test("exit found by direction 'north'", function()
    local ctx = make_ctx({
        exits = {
            north = make_door_exit({}),
        },
    })

    local output = capture_output(function()
        handlers["open"](ctx, "north")
    end)

    eq(ctx.current_room.exits.north.open, true,
        "'north' should match exit direction; output: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
h.summary()
