-- test/sensory/test-bug346-rat-ambient.lua
-- Bug #346: Ambient smell/listen room scan excludes rat.
-- Additional TDD tests beyond the existing test-bug346-creature-scan.lua.
-- Specifically tests: state-aware sensory for creatures in room.contents,
-- and deduplication between object loop and creature loop.
-- Must be run from repository root: lua test/sensory/test-bug346-rat-ambient.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")

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
    for _, obj in ipairs(opts.objects or {}) do
        reg:register(obj.id or obj.guid, obj)
    end
    local room = {
        id = "test-room", name = "Test Room", description = "A plain test room.",
        on_smell = opts.room_smell or nil, on_listen = opts.room_listen or nil,
        contents = opts.room_contents or {}, exits = opts.exits or {},
    }
    local player = {
        hands = opts.hands or { nil, nil }, worn = opts.worn or {},
        injuries = {}, bags = {}, state = {}, skills = {},
        max_health = 100, consciousness = { state = "conscious" },
        visited_rooms = { ["test-room"] = true },
    }
    return {
        registry = reg, current_room = room, player = player,
        time_offset = opts.time_offset or 0, game_start_time = os.time(),
        current_verb = opts.verb or "", known_objects = {},
        last_object = nil, verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #346: Rat must appear in ambient smell/listen scans")

test("1. rat in room.contents appears in ambient smell scan", function()
    local rat = {
        guid = "{rat-346-rc}", id = "rat", name = "a brown rat",
        keywords = {"rat"}, animate = true, location = "test-room",
        _state = "alive-idle",
        on_smell = "Musty rodent — damp fur and ammonia.",
        on_listen = "Skittering claws on stone.",
        on_feel = "Coarse fur.",
        states = { ["alive-idle"] = { room_presence = "A rat crouches near the wall." } },
    }

    -- Put rat in room.contents AND registry — simulating real game state
    local ctx = make_ctx({
        objects = { rat },
        room_contents = { "rat" },
    })

    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)

    h.assert_truthy(output:find("rodent") or output:find("ammonia") or output:find("rat"),
        "rat in room.contents must appear in ambient smell scan, got: " .. output:sub(1, 300))
end)

test("2. rat NOT in room.contents but with location set still appears via creature scan", function()
    local rat = {
        guid = "{rat-346-loc}", id = "rat", name = "a brown rat",
        keywords = {"rat"}, animate = true, location = "test-room",
        _state = "alive-idle",
        on_smell = "Musty rodent — damp fur and ammonia.",
        on_listen = "Skittering claws on stone.",
        on_feel = "Coarse fur.",
        states = { ["alive-idle"] = { room_presence = "A rat crouches near the wall." } },
    }

    -- Rat is NOT in room.contents but has location set
    local ctx = make_ctx({ objects = { rat } })

    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)

    h.assert_truthy(output:find("rodent") or output:find("ammonia") or output:find("rat"),
        "rat with matching location must appear via creature scan, got: " .. output:sub(1, 300))
end)

test("3. creature not duplicated when in BOTH room.contents and creature scan", function()
    local spider = {
        guid = "{spider-346-dup}", id = "spider", name = "a large brown spider",
        keywords = {"spider"}, animate = true, location = "test-room",
        _state = "alive-idle",
        on_smell = "A faint, musty odor — old silk and dry insect husks.",
        on_listen = "Faint scratching.",
        on_feel = "Bristled legs.",
        states = { ["alive-idle"] = { room_presence = "A spider sits in its web." } },
    }

    -- Spider in BOTH room.contents AND has location set
    local ctx = make_ctx({
        objects = { spider },
        room_contents = { "spider" },
    })

    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)

    -- Count occurrences of spider smell
    local count = 0
    for _ in output:gmatch("musty odor") do count = count + 1 end
    for _ in output:gmatch("silk") do count = count + 1 end

    h.assert_truthy(count <= 2,
        "creature should not appear more than once in smell scan, found " .. count .. " matches in: " .. output:sub(1, 400))
end)

test("4. rat listen scan works alongside spider", function()
    local rat = {
        guid = "{rat-346-listen}", id = "rat", name = "a brown rat",
        keywords = {"rat"}, animate = true, location = "test-room",
        _state = "alive-idle",
        on_smell = "Musty rodent.", on_listen = "Skittering claws on stone.", on_feel = "Coarse fur.",
        states = { ["alive-idle"] = { room_presence = "A rat crouches." } },
    }
    local spider = {
        guid = "{spider-346-listen}", id = "spider", name = "a large brown spider",
        keywords = {"spider"}, animate = true, location = "test-room",
        _state = "alive-idle",
        on_smell = "Musty silk.", on_listen = "Faint scratching on stone.", on_feel = "Bristles.",
        states = { ["alive-idle"] = { room_presence = "A spider waits." } },
    }

    local ctx = make_ctx({ objects = { rat, spider } })

    local output = capture_output(function()
        handlers["listen"](ctx, "")
    end)

    h.assert_truthy(output:find("[Ss]kittering") or output:find("claws"),
        "listen must include rat, got: " .. output:sub(1, 300))
    h.assert_truthy(output:find("scratching"),
        "listen must include spider, got: " .. output:sub(1, 300))
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
