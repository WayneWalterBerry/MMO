-- test/verbs/test-container-verbs.lua
-- Pre-refactoring coverage for open, close, unlock verb handlers.
-- Tests: FSM open/close transitions, mutation paths, already-open/closed,
--        exit door opening/closing, locked exit blocking, unlock with key,
--        unlock wrong key, event_output one-shot, on_open/on_close hooks.
--
-- Usage: lua test/verbs/test-container-verbs.lua
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
        state = {},
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
-- 1. OPEN — FSM transitions
---------------------------------------------------------------------------
suite("open — FSM container transitions")

test("open FSM container transitions from closed to open", function()
    local chest = {
        id = "chest",
        name = "a wooden chest",
        keywords = {"chest", "wooden chest"},
        _state = "closed",
        initial_state = "closed",
        states = {
            closed = { name = "a closed chest" },
            open = { name = "an open chest" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open",
              message = "You lift the lid of the chest." },
        },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["open"](ctx, "chest")
    end)
    h.assert_truthy(output:find("lid") or output:find("open"),
        "Should print open transition message")
    eq("open", chest._state, "Chest should be in open state")
end)

test("open already-open container prints 'already open'", function()
    local chest = {
        id = "chest",
        name = "a wooden chest",
        keywords = {"chest"},
        _state = "open",
        states = {
            closed = { name = "a closed chest" },
            open = { name = "an open chest" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open",
              message = "You lift the lid." },
        },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["open"](ctx, "chest")
    end)
    h.assert_truthy(output:find("already open"),
        "Already-open container should say 'already open'")
end)

test("open triggers on_open hook", function()
    local hook_fired = false
    local chest = {
        id = "chest",
        name = "a chest",
        keywords = {"chest"},
        _state = "closed",
        states = {
            closed = { name = "closed chest" },
            open = { name = "open chest" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open",
              message = "You open the chest." },
        },
        on_open = function(self, ctx)
            hook_fired = true
        end,
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    capture_output(function()
        handlers["open"](ctx, "chest")
    end)
    h.assert_truthy(hook_fired, "on_open hook should fire")
end)

test("open fires event_output and clears it", function()
    local chest = {
        id = "chest",
        name = "a chest",
        keywords = {"chest"},
        _state = "closed",
        states = {
            closed = { name = "closed chest" },
            open = { name = "open chest" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open",
              message = "You open the chest." },
        },
        event_output = { on_open = "A musty smell wafts out." },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["open"](ctx, "chest")
    end)
    h.assert_truthy(output:find("musty"),
        "Should print event_output text")
    h.assert_nil(chest.event_output["on_open"],
        "event_output should be cleared after use")
end)

---------------------------------------------------------------------------
-- 2. CLOSE — FSM transitions
---------------------------------------------------------------------------
suite("close — FSM container transitions")

test("close FSM container transitions from open to closed", function()
    local chest = {
        id = "chest",
        name = "an open chest",
        keywords = {"chest"},
        _state = "open",
        states = {
            closed = { name = "a closed chest" },
            open = { name = "an open chest" },
        },
        transitions = {
            { from = "open", to = "closed", verb = "close",
              message = "You close the chest lid." },
        },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["close"](ctx, "chest")
    end)
    h.assert_truthy(output:find("close") or output:find("lid"),
        "Should print close transition message")
    eq("closed", chest._state, "Chest should be in closed state")
end)

test("close already-closed container prints 'already closed'", function()
    local chest = {
        id = "chest",
        name = "a chest",
        keywords = {"chest"},
        _state = "closed",
        states = {
            closed = { name = "closed chest" },
            open = { name = "open chest" },
        },
        transitions = {
            { from = "open", to = "closed", verb = "close",
              message = "You close it." },
        },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["close"](ctx, "chest")
    end)
    h.assert_truthy(output:find("already closed"),
        "Already-closed container should say 'already closed'")
end)

test("close triggers on_close hook", function()
    local hook_fired = false
    local chest = {
        id = "chest",
        name = "a chest",
        keywords = {"chest"},
        _state = "open",
        states = {
            closed = { name = "closed" },
            open = { name = "open" },
        },
        transitions = {
            { from = "open", to = "closed", verb = "close",
              message = "You close it." },
        },
        on_close = function(self, ctx)
            hook_fired = true
        end,
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    capture_output(function()
        handlers["close"](ctx, "chest")
    end)
    h.assert_truthy(hook_fired, "on_close hook should fire")
end)

---------------------------------------------------------------------------
-- 3. OPEN/CLOSE EXITS (doors)
---------------------------------------------------------------------------
suite("open/close — exit doors")

test("open exit door with mutations transitions it", function()
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a wooden door",
                keywords = {"door", "wooden door"},
                open = false,
                locked = false,
                mutations = {
                    open = {
                        message = "The door swings open with a creak.",
                        becomes_exit = { open = true },
                    },
                },
            },
        },
    })
    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)
    h.assert_truthy(output:find("creak") or output:find("swing") or output:find("open"),
        "Should print door open message")
    h.assert_truthy(ctx.current_room.exits.north.open,
        "Door should be open after opening")
end)

test("open locked exit prints 'locked'", function()
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a heavy door",
                keywords = {"door"},
                open = false,
                locked = true,
                mutations = {
                    open = {
                        message = "You open the door.",
                        becomes_exit = { open = true },
                    },
                },
            },
        },
    })
    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)
    h.assert_truthy(output:find("locked"),
        "Should say door is locked")
end)

test("open already-open exit prints 'already open'", function()
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a door",
                keywords = {"door"},
                open = true,
                mutations = {
                    open = {
                        message = "You open the door.",
                        becomes_exit = { open = true },
                    },
                },
            },
        },
    })
    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)
    h.assert_truthy(output:find("already open"),
        "Should say already open")
end)

test("close exit door with mutations transitions it", function()
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a wooden door",
                keywords = {"door"},
                open = true,
                mutations = {
                    close = {
                        message = "The door closes.",
                        becomes_exit = { open = false },
                    },
                },
            },
        },
    })
    local output = capture_output(function()
        handlers["close"](ctx, "door")
    end)
    h.assert_truthy(output:find("close") or output:find("door"),
        "Should print close message")
    h.assert_truthy(ctx.current_room.exits.north.open == false,
        "Door should be closed")
end)

---------------------------------------------------------------------------
-- 4. UNLOCK — key-based exit unlocking
---------------------------------------------------------------------------
suite("unlock — key resolution")

test("unlock with empty noun prints 'Unlock what?'", function()
    local output = capture_output(function()
        handlers["unlock"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Unlock what"),
        "Empty noun should prompt 'Unlock what?'")
end)

test("unlock locked door with correct key succeeds", function()
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
    }
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a heavy door",
                keywords = {"door", "heavy door"},
                open = false,
                locked = true,
                key_id = "brass-key",
            },
        },
    })
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key
    local output = capture_output(function()
        handlers["unlock"](ctx, "door")
    end)
    h.assert_truthy(output:find("click") or output:find("unlock"),
        "Should print unlock success message")
    h.assert_truthy(ctx.current_room.exits.north.locked == false,
        "Door should be unlocked")
end)

test("unlock with wrong key prints 'doesn't fit'", function()
    local wrong_key = {
        id = "iron-key",
        name = "an iron key",
        keywords = {"key", "iron key"},
    }
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a door",
                keywords = {"door"},
                open = false,
                locked = true,
                key_id = "brass-key",
            },
        },
    })
    ctx.registry:register("iron-key", wrong_key)
    ctx.player.hands[1] = wrong_key
    local output = capture_output(function()
        handlers["unlock"](ctx, "door")
    end)
    h.assert_truthy(output:find("doesn't fit") or output:find("wrong"),
        "Wrong key should print 'doesn't fit'")
end)

test("unlock with no key prints 'don't have a key'", function()
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a door",
                keywords = {"door"},
                open = false,
                locked = true,
                key_id = "brass-key",
            },
        },
    })
    local output = capture_output(function()
        handlers["unlock"](ctx, "door")
    end)
    h.assert_truthy(output:find("don't have") or output:find("key"),
        "No key should print 'don't have a key'")
end)

test("unlock unlocked exit prints 'isn't locked'", function()
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a door",
                keywords = {"door"},
                open = false,
                locked = false,
            },
        },
    })
    local output = capture_output(function()
        handlers["unlock"](ctx, "door")
    end)
    h.assert_truthy(output:find("isn't locked") or output:find("not locked"),
        "Unlocked door should say 'isn't locked'")
end)

test("unlock exit with no keyhole prints no-keyhole message", function()
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a wooden barrier",
                keywords = {"barrier"},
                open = false,
                locked = true,
                -- no key_id field
            },
        },
    })
    local output = capture_output(function()
        handlers["unlock"](ctx, "barrier")
    end)
    h.assert_truthy(output:find("keyhole") or output:find("key"),
        "Exit without key_id should say no keyhole")
end)

test("unlock parses 'unlock X with Y' syntax", function()
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key", "brass"},
    }
    local ctx = make_ctx({
        exits = {
            north = {
                name = "a door",
                keywords = {"door"},
                open = false,
                locked = true,
                key_id = "brass-key",
            },
        },
    })
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key
    local output = capture_output(function()
        handlers["unlock"](ctx, "door with brass key")
    end)
    h.assert_truthy(output:find("click") or output:find("unlock"),
        "'unlock X with Y' should work")
end)

print("\nExit code: " .. h.summary())
