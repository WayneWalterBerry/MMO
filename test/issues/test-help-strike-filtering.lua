-- test/issues/test-help-strike-filtering.lua
-- Test Issue #513: "strike match" in E-rated help menu

local t = require("test.parser.test-helpers")

-- Mock a basic registry/context for E-rated world
local function create_e_rated_context()
    local context = {
        registry = {
            _level = {
                number = 1,
                name = "MrBeast's Challenge Arena",
                rating = "E",
            },
        },
        player = {
            hands = { nil, nil },
            worn = {},
        },
        room = {
            id = "test-room",
        },
    }
    return context
end

-- Mock a basic registry/context for T-rated world
local function create_t_rated_context()
    local context = {
        registry = {
            _level = {
                number = 1,
                name = "The Manor",
                rating = "T",
            },
        },
        player = {
            hands = { nil, nil },
            worn = {},
        },
        room = {
            id = "test-room",
        },
    }
    return context
end

-- Capture print output
local captured_output = {}
local original_print = print
local function capture_print(...)
    local args = {...}
    local str = table.concat(args, "\t")
    table.insert(captured_output, str)
end

local function reset_capture()
    captured_output = {}
end

local function get_captured_output()
    return table.concat(captured_output, "\n")
end

t.test("E-rated help does NOT show 'cut self' or 'prick self'", function()
    reset_capture()
    _G.print = capture_print
    
    local meta = require("src.engine.verbs.meta")
    local handlers = {}
    meta.register(handlers)
    
    local ctx = create_e_rated_context()
    handlers["help"](ctx, "")
    
    _G.print = original_print
    
    local output = get_captured_output()
    if output:match("cut self") then
        error("E-rated help should NOT show 'cut self'")
    end
    if output:match("prick self") then
        error("E-rated help should NOT show 'prick self'")
    end
end)

t.test("E-rated help does NOT show combat verbs", function()
    reset_capture()
    _G.print = capture_print
    
    local meta = require("src.engine.verbs.meta")
    local handlers = {}
    meta.register(handlers)
    
    local ctx = create_e_rated_context()
    handlers["help"](ctx, "")
    
    _G.print = original_print
    
    local output = get_captured_output()
    if output:match("== Combat ==") then
        error("E-rated help should NOT show Combat section")
    end
    if output:match("stab") then
        error("E-rated help should NOT show 'stab'")
    end
    if output:match("slash") then
        error("E-rated help should NOT show 'slash'")
    end
end)

t.test("T-rated help DOES show combat and self-harm verbs", function()
    reset_capture()
    _G.print = capture_print
    
    -- Re-require to reset module state
    package.loaded["src.engine.verbs.meta"] = nil
    local meta = require("src.engine.verbs.meta")
    local handlers = {}
    meta.register(handlers)
    
    local ctx = create_t_rated_context()
    handlers["help"](ctx, "")
    
    _G.print = original_print
    
    local output = get_captured_output()
    t.assert_truthy(output:match("cut self"), "T-rated help should show 'cut self'")
    t.assert_truthy(output:match("prick self"), "T-rated help should show 'prick self'")
    t.assert_truthy(output:match("== Combat =="), "T-rated help should show Combat section")
end)

t.test("E-rated help shows 'light match' not 'strike match'", function()
    reset_capture()
    _G.print = capture_print
    
    package.loaded["src.engine.verbs.meta"] = nil
    local meta = require("src.engine.verbs.meta")
    local handlers = {}
    meta.register(handlers)
    
    local ctx_e = create_e_rated_context()
    handlers["help"](ctx_e, "")
    local output_e = get_captured_output()
    
    _G.print = original_print
    
    -- E-rated should show "light match" not "strike match" to avoid violent language
    t.assert_truthy(output_e:match("light match"), "E-rated help should show 'light match'")
    if output_e:match("strike match") then
        error("E-rated help should NOT show 'strike match' (violent connotation)")
    end
end)

t.test("T-rated help shows 'strike match'", function()
    reset_capture()
    _G.print = capture_print
    
    package.loaded["src.engine.verbs.meta"] = nil
    local meta = require("src.engine.verbs.meta")
    local handlers = {}
    meta.register(handlers)
    
    local ctx_t = create_t_rated_context()
    handlers["help"](ctx_t, "")
    local output_t = get_captured_output()
    
    _G.print = original_print
    
    -- T-rated can use "strike match" since combat is allowed
    t.assert_truthy(output_t:match("strike match"), "T-rated help should show 'strike match'")
end)

t.summary()
