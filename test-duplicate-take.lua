local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local verbs_mod = require("engine.verbs")

local handlers = verbs_mod.create()

local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
    }
end

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

local function make_take_ctx(room_objects)
    local objs = {}
    local room_contents = {}
    for _, obj in ipairs(room_objects) do
        objs[obj.id] = obj
        room_contents[#room_contents + 1] = obj.id
    end
    local reg = make_mock_registry(objs)
    local room = {
        id = "test-room", name = "Test Room",
        contents = room_contents, exits = {},
        light_level = 1,
    }
    return {
        registry = reg,
        current_room = room,
        player = {
            hands = { nil, nil },
            worn = {},
            state = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
    }
end

local pot = {
    id = "chamber-pot",
    name = "a ceramic chamber pot",
    keywords = {"chamber pot", "pot", "ceramic pot"},
    portable = true,
    container = true,
    contents = {},
    categories = {"ceramic", "container"},
    mutations = {},
}
local ctx = make_take_ctx({ pot })
local output = capture_output(function()
    handlers["get"](ctx, "pot")
end)

print("Output from get pot:")
print(output)
print("\nCount of 'You take':", select(2, output:gsub("You take", "")))
