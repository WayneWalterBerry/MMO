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

    -- "thing I found" / "what I found" / "thing I discovered" / "item I found"
    if kw:match("thing%s+i%s+found")
        or kw:match("what%s+i%s+found")
        or kw:match("thing%s+i%s+discovered")
        or kw:match("item%s+i%s+found")
        or kw:match("thing%s+i%s+just%s+found") then
        return _discoveries[1]
    end

    return nil
end

---------------------------------------------------------------------------
-- Reset (for testing)
---------------------------------------------------------------------------

function context_window.reset()
    _stack = {}
    _discoveries = {}
    _previous_room_id = nil
end

return context_window
