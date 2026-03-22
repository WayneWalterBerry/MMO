-- engine/search/goals.lua
-- Goal-oriented matching: "find something that can light"
-- Property-based implementation (simpler, faster).
-- GOAP-based approach can be added later if needed.
--
-- Ownership: Bart (Architect)

local goals = {}

---------------------------------------------------------------------------
-- Goal query parsing
---------------------------------------------------------------------------

--- Parse goal-oriented query
-- @param query string (e.g., "something that can light the candle")
-- @return {type: "action", value: "light", context: "candle"} or nil
function goals.parse_goal(query)
    if not query then return nil end
    
    local lower = query:lower()
    
    -- Pattern: "something that can [action]"
    local action = lower:match("something that can (%w+)")
    if action then
        -- Check for context: "something that can [action] [context]"
        local full_action, context = lower:match("something that can (%w+)%s+(.+)")
        if full_action and context then
            return {
                type = "action",
                value = full_action,
                context = context,
                original_query = query,
            }
        end
        return {
            type = "action",
            value = action,
            context = nil,
            original_query = query,
        }
    end
    
    -- Pattern: "something [property]"
    local property = lower:match("something (%w+)")
    if property then
        return {
            type = "property",
            value = property,
            context = nil,
            original_query = query,
        }
    end
    
    -- Pattern: "something to [verb]"
    local verb = lower:match("something to (%w+)")
    if verb then
        return {
            type = "action",
            value = verb,
            context = nil,
            original_query = query,
        }
    end
    
    return nil
end

---------------------------------------------------------------------------
-- Goal matching (property-based)
---------------------------------------------------------------------------

--- Check if object matches goal
-- @param object object to check
-- @param goal_type "action" | "property"
-- @param goal_value e.g., "light" | "sharp"
-- @param registry registry instance
-- @return boolean
function goals.matches_goal(object, goal_type, goal_value, registry)
    if not object or not goal_type or not goal_value then
        return false
    end
    
    if goal_type == "property" then
        -- Property matching: check is_[property] flag
        local prop_key = "is_" .. goal_value
        if object[prop_key] == true then
            return true
        end
        
        -- Also check direct property
        if object[goal_value] == true then
            return true
        end
        
        return false
    end
    
    if goal_type == "action" then
        -- Action matching: check if object can perform action
        
        -- 1. Check fire_source for lighting actions
        if goal_value == "light" or goal_value == "ignite" or goal_value == "burn" then
            if object.fire_source == true then
                return true
            end
            -- Check if object has "light" action
            if object.actions then
                for _, action in ipairs(object.actions) do
                    if action == "light" or action == "ignite" then
                        return true
                    end
                end
            end
        end
        
        -- 2. Check if object has the action in its actions list
        if object.actions then
            for _, action in ipairs(object.actions) do
                if action == goal_value then
                    return true
                end
            end
        end
        
        -- 3. Check verbs table
        if object.verbs then
            for verb_name, _ in pairs(object.verbs) do
                if verb_name == goal_value then
                    return true
                end
            end
        end
        
        return false
    end
    
    return false
end

---------------------------------------------------------------------------
-- Future: GOAP-based matching
---------------------------------------------------------------------------

-- GOAP-based matching would use the existing GOAP planner to check
-- if an object can achieve a goal through a sequence of actions.
-- This is more flexible but computationally heavier.
--
-- Example implementation (commented out for now):
--[[
function goals.matches_goal_goap(object, goal_type, goal_value, registry, ctx)
    if goal_type ~= "action" then
        return false
    end
    
    -- Try to plan: can we use this object to achieve the goal?
    local goap_ok, goap = pcall(require, "engine.goap")
    if not goap_ok then
        return false
    end
    
    local goal_state = { [goal_value] = true }
    local plan = goap.plan(ctx, goal_state, object)
    
    return plan ~= nil and #plan > 0
end
]]--

return goals
