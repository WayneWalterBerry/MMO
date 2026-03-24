-- engine/parser/context.lua
-- Context Window (Tier 4): Tracks recent interactions so the game remembers
-- what the player just did. Maintains a stack of recently referenced objects,
-- search discoveries, and previous room for "go back" support.
--
-- Ownership: Smithers (UI Engineer) — parser pipeline component.
-- Architecture: Module-level state (same pattern as engine/search/init.lua).
--
-- Integration points:
--   verbs/init.lua   — push() on find_visible, set_previous_room on movement
--   search/init.lua  — push_discovery() when search finds an item
--   loop/init.lua    — resolve() for pronoun and bare-noun fallback

local context_window = {}

---------------------------------------------------------------------------
-- Internal state (volatile, not persisted)
---------------------------------------------------------------------------
local _stack = {}               -- Recent interacted objects (most recent first)
local _max_stack = 5
local _previous_room_id = nil   -- Room ID before last room transition
local _discoveries = {}         -- Objects found via search (most recent first)
local _max_discoveries = 5
local _last_command = nil       -- { verb, noun, raw } for "again" support
local _last_direction = nil     -- Last movement direction for "continue" support

---------------------------------------------------------------------------
-- Context stack operations
---------------------------------------------------------------------------

--- Push an object to the context stack (most recent interaction).
--- Deduplicates: if the object is already in the stack, moves it to top.
function context_window.push(obj)
    if not obj or not obj.id then return end
    -- Already at top — skip
    if _stack[1] and _stack[1].id == obj.id then return end
    -- Remove duplicate if present (move to top)
    for i = #_stack, 1, -1 do
        if _stack[i].id == obj.id then
            table.remove(_stack, i)
            break
        end
    end
    table.insert(_stack, 1, obj)
    while #_stack > _max_stack do table.remove(_stack) end
end

--- Push a search discovery to both the discovery list and context stack.
--- Called by search/init.lua when an item is found during search.
function context_window.push_discovery(obj)
    if not obj or not obj.id then return end
    -- Deduplicate in discovery list
    for i = #_discoveries, 1, -1 do
        if _discoveries[i].id == obj.id then
            table.remove(_discoveries, i)
            break
        end
    end
    table.insert(_discoveries, 1, obj)
    while #_discoveries > _max_discoveries do table.remove(_discoveries) end
    -- Also push to main context stack
    context_window.push(obj)
end

--- Get the most recent context object (top of stack).
function context_window.peek()
    return _stack[1]
end

--- Get the most recent search discovery.
function context_window.last_discovery()
    return _discoveries[1]
end

--- Get the full context stack (for debugging/testing).
function context_window.get_stack()
    return _stack
end

--- Get the discovery list (for debugging/testing).
function context_window.get_discoveries()
    return _discoveries
end

---------------------------------------------------------------------------
-- Room history for "go back"
---------------------------------------------------------------------------

--- Record the current room before a room transition.
function context_window.set_previous_room(room_id)
    _previous_room_id = room_id
end

--- Get the previous room ID (for "go back").
function context_window.get_previous_room()
    return _previous_room_id
end

---------------------------------------------------------------------------
-- Resolution: resolve noun references from context
---------------------------------------------------------------------------

--- Resolve a noun reference using the context window.
--- Handles pronouns ("it", "that", "this"), discovery references
--- ("the thing I found"), and returns the resolved object or nil.
function context_window.resolve(noun)
    if not noun then return nil end
    local kw = noun:lower()
        :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")

    -- Direct pronouns → most recent context object
    if kw == "it" or kw == "that" or kw == "this" or kw == "one" then
        return _stack[1]
    end

    -- Tier 4: "the other one" → second most recent context object
    if kw == "other one" or kw == "other" then
        if #_stack >= 2 then return _stack[2] end
        return nil
    end

    -- BUG-114: "thing I found" / "one I found" / "what I found" etc. → last discovery
    if kw:match("thing%s+i%s+found")
        or kw:match("one%s+i%s+found")
        or kw:match("what%s+i%s+found")
        or kw:match("thing%s+i%s+discovered")
        or kw:match("one%s+i%s+discovered")
        or kw:match("item%s+i%s+found")
        or kw:match("thing%s+i%s+just%s+found")
        or kw:match("one%s+i%s+just%s+found") then
        return _discoveries[1]
    end

    return nil
end

---------------------------------------------------------------------------
-- Tier 4: Command repeat ("again" / "do it again")
---------------------------------------------------------------------------

--- Record the last executed command (called after successful dispatch).
function context_window.set_last_command(verb, noun, raw)
    _last_command = { verb = verb, noun = noun, raw = raw }
end

--- Resolve repeat phrases. Returns last command table or nil.
function context_window.resolve_repeat(text)
    if not text then return nil end
    local kw = text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if kw == "again" or kw == "do it again" or kw == "repeat"
        or kw == "do that again" or kw == "same thing"
        or kw == "one more time" then
        return _last_command
    end
    return nil
end

---------------------------------------------------------------------------
-- Tier 4: Direction history
---------------------------------------------------------------------------

--- Record the last movement direction.
function context_window.set_last_direction(dir)
    _last_direction = dir
end

--- Get the last movement direction.
function context_window.get_last_direction()
    return _last_direction
end

---------------------------------------------------------------------------
-- Tier 4: Recency scoring (for Tier 5 fuzzy integration)
---------------------------------------------------------------------------

--- Score an object by recency in the context stack.
--- Returns 0 for unknown objects, higher for more recent.
function context_window.recency_score(obj_id)
    if not obj_id then return 0 end
    for i, obj in ipairs(_stack) do
        if obj.id == obj_id then
            return _max_stack - i + 1
        end
    end
    return 0
end

---------------------------------------------------------------------------
-- Reset (for testing)
---------------------------------------------------------------------------

function context_window.reset()
    _stack = {}
    _discoveries = {}
    _previous_room_id = nil
    _last_command = nil
    _last_direction = nil
end

return context_window
