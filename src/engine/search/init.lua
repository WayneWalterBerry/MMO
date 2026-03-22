-- engine/search/init.lua
-- Search/Find engine: progressive room traversal and discovery system.
-- Transforms discovery from instant query into time-bound, interruptible exploration.
--
-- Ownership: Bart (Architect)
-- Architecture: docs/architecture/engine/search/

local search = {}

-- Sub-modules
local traverse = require("engine.search.traverse")
local containers = require("engine.search.containers")
local narrator = require("engine.search.narrator")
local goals = require("engine.search.goals")

---------------------------------------------------------------------------
-- Active search state (volatile, not persisted)
---------------------------------------------------------------------------
local _state = {
    active = false,              -- Is a search currently running?
    target = nil,                -- What we're looking for (string or nil)
    scope = nil,                 -- Where we're searching (object ID or nil)
    queue = {},                  -- Ordered list of search queue entries
    current_index = 1,           -- Current position in queue (1-indexed)
    current_step = 0,            -- Number of steps taken this search
    found_items = {},            -- List of discovered object IDs
    room_id = nil,               -- Which room is being searched
    is_goal_search = false,      -- Is this a goal-oriented search?
    goal_type = nil,             -- "action" | "property"
    goal_value = nil,            -- e.g., "light", "sharp", "cut"
    goal_context = nil,          -- Additional context (e.g., "the candle")
}

local function reset_state()
    _state.active = false
    _state.target = nil
    _state.scope = nil
    _state.queue = {}
    _state.current_index = 1
    _state.current_step = 0
    _state.found_items = {}
    _state.room_id = nil
    _state.is_goal_search = false
    _state.goal_type = nil
    _state.goal_value = nil
    _state.goal_context = nil
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Check if a search is currently active
function search.is_searching()
    return _state.active
end

--- Abort current search (called by any new command)
function search.abort(ctx)
    if not _state.active then return end
    
    print("[Search interrupted]")
    
    -- Turn cost: only charge for completed steps
    -- (current_step tracks completed steps, not the one being interrupted)
    
    reset_state()
end

--- Start a search operation
-- @param ctx game context
-- @param target string or nil (nil = undirected sweep)
-- @param scope object ID or nil (nil = full room)
function search.search(ctx, target, scope)
    -- If already searching, abort previous search
    if _state.active then
        search.abort(ctx)
    end
    
    -- Initialize search state
    _state.active = true
    _state.target = target
    _state.scope = scope
    _state.room_id = ctx.current_room and ctx.current_room.id
    _state.current_index = 1
    _state.current_step = 0
    _state.found_items = {}
    
    -- Check for goal-oriented search
    if target then
        local goal = goals.parse_goal(target)
        if goal then
            _state.is_goal_search = true
            _state.goal_type = goal.type
            _state.goal_value = goal.value
            _state.goal_context = goal.context
        end
    end
    
    -- Build search queue
    local room = ctx.current_room
    if not room then
        print("You're nowhere to search.")
        reset_state()
        return
    end
    
    _state.queue = traverse.build_queue(room, scope, target, ctx.registry)
    
    if #_state.queue == 0 then
        if scope then
            print("There's nothing to search there.")
        else
            print("There's nothing to search here.")
        end
        reset_state()
        return
    end
    
    -- Output initial message
    if target then
        print("You begin searching for " .. target .. "...")
    else
        print("You begin searching...")
    end
end

--- Start a find operation (alias for search with target)
-- @param ctx game context
-- @param target string (required)
-- @param scope object ID or nil
function search.find(ctx, target, scope)
    if not target or target == "" then
        print("Find what?")
        return
    end
    
    search.search(ctx, target, scope)
end

--- Process one search step (called by game loop)
-- @param ctx game context
-- @return boolean (true if search continues, false if complete)
function search.tick(ctx)
    if not _state.active then
        return false
    end
    
    -- Check if queue exhausted
    if _state.current_index > #_state.queue then
        -- Search complete - exhausted
        if _state.target then
            if _state.is_goal_search then
                print("You finish searching. Nothing matches what you need.")
            else
                print("You finish searching. No " .. _state.target .. " found.")
            end
        else
            -- Undirected sweep completed
            if #_state.found_items > 0 then
                print("You finish searching the area.")
            else
                print("You finish searching the area. Nothing interesting.")
            end
        end
        reset_state()
        return false
    end
    
    -- Process current queue entry
    local entry = _state.queue[_state.current_index]
    local result = traverse.step(ctx, entry, _state.target, _state.is_goal_search, _state.goal_type, _state.goal_value)
    
    -- Output narrative
    if result.narrative and result.narrative ~= "" then
        print(result.narrative)
    end
    
    -- Track found items
    if result.found and result.item then
        _state.found_items[#_state.found_items + 1] = result.item.id
    end
    
    -- Increment counters
    _state.current_index = _state.current_index + 1
    _state.current_step = _state.current_step + 1
    
    -- Check if target found
    if result.found and _state.target then
        -- Set context for follow-up commands
        if ctx and result.item then
            ctx.last_noun = result.item.id
        end
        
        -- Output completion message
        local item_name = result.item.name or result.item.id
        print("")
        print("You have found: " .. item_name .. ".")
        
        reset_state()
        return false
    end
    
    -- Continue searching
    return true
end

--- Check if an object has been searched before
-- @param room_id string
-- @param object_id string
-- @return boolean
function search.has_been_searched(room_id, object_id)
    -- Search memory is stored on room object
    -- For now, we don't implement persistent memory
    -- (This can be added later as a polish feature)
    return false
end

--- Mark an object as searched
-- @param room_id string
-- @param object_id string
function search.mark_searched(room_id, object_id)
    -- For now, we don't implement persistent memory
    -- (This can be added later as a polish feature)
end

return search
