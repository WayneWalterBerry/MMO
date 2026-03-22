-- engine/search/narrator.lua
-- Narrative generation: sensory-aware prose for search actions.
-- Adapts to light level and generates atmospheric discovery text.
--
-- Ownership: Bart (Architect)

local narrator = {}

---------------------------------------------------------------------------
-- Sensory selection
---------------------------------------------------------------------------

--- Determine primary sense for current conditions
-- @param ctx game context
-- @param room room object
-- @return "vision" | "touch" | "hearing"
local function get_primary_sense(ctx, room)
    -- Check light level
    if room and room.light_level and room.light_level > 0 then
        return "vision"
    end
    
    -- In darkness, use touch
    return "touch"
end

---------------------------------------------------------------------------
-- Narrative templates
---------------------------------------------------------------------------

local STEP_TEMPLATES = {
    vision = {
        "Your eyes scan the {object} — nothing notable.",
        "You look at the {object}. Nothing interesting.",
        "You glance at the {object}. Nothing there.",
    },
    touch = {
        "You feel the {object} — nothing there.",
        "Your fingers explore the {object}. Nothing.",
        "You reach out to the {object}. Nothing.",
    },
}

local CONTAINER_OPEN_TEMPLATES = {
    touch = {
        "It has a drawer... you pull it open.",
        "You find a compartment. You open it.",
        "It has a container. You open it.",
    },
}

local CONTAINER_LOCKED_TEMPLATES = {
    touch = {
        "You find it's locked. You can't open it without a key.",
        "It's locked tight.",
        "You try to open it, but it's locked.",
    },
    vision = {
        "You spot a lock. It's secured.",
        "It's locked.",
        "You notice it's locked.",
    },
}

local FOUND_TEMPLATES = {
    touch = {
        "Inside, you feel: {item}.",
        "Your fingers find: {item}.",
        "You feel: {item}.",
    },
    vision = {
        "You spot: {item}.",
        "You see: {item}.",
        "You notice: {item}.",
    },
}

--- Format object name for narrative
-- @param object object instance
-- @return string
local function format_object_name(object)
    if not object then return "something" end
    
    local name = object.name or object.id or "object"
    
    -- Add article if not present
    if not name:match("^[Tt]he ") and not name:match("^[Aa]n? ") then
        local first_char = name:sub(1, 1):lower()
        if first_char == "a" or first_char == "e" or first_char == "i" or first_char == "o" or first_char == "u" then
            name = "an " .. name
        else
            name = "a " .. name
        end
    end
    
    return name
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Generate narrative for a search step (nothing found)
-- @param ctx game context
-- @param object current object being searched
-- @param found_target was the target found? (boolean)
-- @return string (prose output)
function narrator.step_narrative(ctx, object, found_target)
    if found_target then
        return ""  -- Handled by found_target()
    end
    
    local sense = get_primary_sense(ctx, ctx.current_room)
    local templates = STEP_TEMPLATES[sense] or STEP_TEMPLATES.touch
    
    -- Pick a template (simple rotation for now)
    local template = templates[1]
    
    -- Format object name
    local obj_name = format_object_name(object)
    
    -- Substitute
    local narrative = template:gsub("{object}", obj_name)
    
    return narrative
end

--- Generate narrative for container open
-- @param ctx game context
-- @param container container being opened
-- @return string
function narrator.container_open(ctx, container)
    local sense = get_primary_sense(ctx, ctx.current_room)
    local templates = CONTAINER_OPEN_TEMPLATES[sense] or CONTAINER_OPEN_TEMPLATES.touch
    
    local template = templates[1]
    return template
end

--- Generate narrative for locked container
-- @param ctx game context
-- @param container locked container
-- @return string
function narrator.container_locked(ctx, container)
    local sense = get_primary_sense(ctx, ctx.current_room)
    local templates = CONTAINER_LOCKED_TEMPLATES[sense] or CONTAINER_LOCKED_TEMPLATES.touch
    
    local template = templates[1]
    return template
end

--- Generate narrative for target found
-- @param ctx game context
-- @param item found item
-- @param container container it was found in (or nil)
-- @return string
function narrator.found_target(ctx, item, container)
    local sense = get_primary_sense(ctx, ctx.current_room)
    local templates = FOUND_TEMPLATES[sense] or FOUND_TEMPLATES.touch
    
    local template = templates[1]
    
    -- Format item name
    local item_name = format_object_name(item)
    
    -- Substitute
    local narrative = template:gsub("{item}", item_name)
    
    return narrative
end

--- Generate narrative for search completion (exhausted)
-- @param ctx game context
-- @param found_items list of discovered objects
-- @param target what was being searched for
-- @return string
function narrator.completion(ctx, found_items, target)
    if target then
        return "You finish searching. No " .. target .. " found."
    else
        if #found_items > 0 then
            return "You finish searching the area."
        else
            return "You finish searching the area. Nothing interesting."
        end
    end
end

--- Generate narrative for search interruption
-- @param ctx game context
-- @param steps_taken number
-- @return string
function narrator.interruption(ctx, steps_taken)
    return "[Search interrupted]"
end

return narrator
