-- engine/search/narrator.lua
-- Narrative generation: sensory-aware prose for search actions.
-- Adapts to light level and generates atmospheric discovery text.
--
-- Ownership: Bart (Architect)
-- Fixes: #63 (surface vs inside narration), #64 (opening narration),
--         #65 (plural item aggregation)

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

-- BUG-088: Templates use {object} directly — format_object_name adds articles
local STEP_TEMPLATES = {
    vision = {
        "Your eyes scan {object} — nothing notable.",
        "You look at {object}. Nothing interesting.",
        "You glance at {object}. Nothing there.",
    },
    touch = {
        "You feel {object} — nothing there.",
        "Your fingers explore {object}. Nothing.",
        "You reach out to {object}. Nothing.",
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
        "You feel: {item}.",
        "Your fingers find: {item}.",
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
    
    -- BUG-088: Don't add article if name already has one
    if not name:match("^[Tt]he ") and not name:match("^[Aa]n? ") then
        -- Only add article if name doesn't start with an article-like word
        local lower_name = name:lower()
        if not lower_name:match("^the ") and not lower_name:match("^a ") and not lower_name:match("^an ") then
            local first_char = name:sub(1, 1):lower()
            if first_char == "a" or first_char == "e" or first_char == "i" or first_char == "o" or first_char == "u" then
                name = "an " .. name
            else
                name = "a " .. name
            end
        end
    end
    
    return name
end

---------------------------------------------------------------------------
-- Helpers for #63/#64/#65
---------------------------------------------------------------------------

--- Strip leading article from a name
local function strip_article(name)
    return name:gsub("^[Aa]n? ", ""):gsub("^[Tt]he ", "")
end

--- Simple English pluralisation (covers common game-object nouns)
local function pluralize(name)
    if name:match("ch$") or name:match("sh$") or name:match("x$") or name:match("ss$") then
        return name .. "es"
    elseif name:match("y$") and not name:match("[aeiou]y$") then
        return name:sub(1, -2) .. "ies"
    else
        return name .. "s"
    end
end

--- Look up the part that maps to a given surface name on the parent (#64)
local function get_part_for_surface(parent, surface_name)
    if not parent or not parent.parts then return nil end
    for _, part in pairs(parent.parts) do
        if part.surface == surface_name then
            return part
        end
    end
    return nil
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

--- Generate narrative for peeking inside a container without opening (#24)
-- Bug #47: sensory-aware — uses touch language in darkness
-- @param ctx game context
-- @param container container being peeked into
-- @return string
function narrator.container_peek(ctx, container)
    local name = container.name or container.id or "it"
    -- Strip leading article for "the" prefix
    local display = name:gsub("^[Aa]n? ", ""):gsub("^[Tt]he ", "")
    local sense = get_primary_sense(ctx, ctx.current_room)
    if sense == "touch" then
        return "You feel around inside the " .. display .. "."
    end
    return "You check inside the " .. display .. "."
end

--- Generate narrative for container contents when target not found (#27)
-- Bug #47: sensory-aware — uses feel/touch language in darkness
-- @param ctx game context
-- @param container container that was checked
-- @param items list of item name strings found inside
-- @param target string the player was searching for
-- @return string
function narrator.container_contents_no_target(ctx, container, items, target)
    local name = container.name or container.id or "it"
    local display = name:gsub("^[Aa]n? ", ""):gsub("^[Tt]he ", "")
    local sense = get_primary_sense(ctx, ctx.current_room)
    local see_word = sense == "touch" and "you feel" or "you see"
    if #items == 0 then
        if target then
            return "You check inside the " .. display .. ". It's empty. No " .. target .. " here."
        else
            return "You check inside the " .. display .. ". It's empty."
        end
    else
        -- #65: aggregate duplicate items for natural narration
        local agg = narrator.aggregate_items(items)
        local list = table.concat(agg, ", ")
        if target then
            return "You check inside the " .. display .. ". Inside " .. see_word .. " " .. list .. ", but no " .. target .. "."
        else
            return "You check inside the " .. display .. ". Inside " .. see_word .. " " .. list .. "."
        end
    end
end

--- Generate narrative for search completion (exhausted)
-- @param ctx game context
-- @param found_items list of discovered objects
-- @param target what was being searched for
-- @return string
function narrator.completion(ctx, found_items, target)
    if target then
        return "You finish searching but didn't find anything matching that. Try 'search' to see everything in the area."
    else
        if #found_items > 0 then
            return "You finish searching the area."
        else
            return "You finish searching the area thoroughly, but didn't find anything new. Try 'look' to get your bearings."
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

--- Generate narrative when a direct part search hits a closed/inaccessible surface (#41)
-- @param ctx game context
-- @param surface_name string (e.g., "inside")
-- @param parent object that owns the part
-- @return string
function narrator.part_closed(ctx, surface_name, parent)
    local name = parent and parent.name or "it"
    local display = name:gsub("^[Aa]n? ", ""):gsub("^[Tt]he ", "")
    return "The drawer is closed. You need to open it first."
end

--- Resolve a human-friendly part name.
-- If the parent object has parts, find the part that maps to this surface.
-- e.g. nightstand surface "inside" → part with surface="inside" → "drawer"
local function resolve_part_display(surface_name, parent)
    if parent and parent.parts and surface_name then
        -- First try: find a part with matching surface mapping
        for key, part in pairs(parent.parts) do
            if part.surface == surface_name then
                return key
            end
        end
        -- Second try: find a part with matching key
        if parent.parts[surface_name] then
            local part = parent.parts[surface_name]
            return part.name or surface_name
        end
    end
    return surface_name or "compartment"
end

--- Generate narrative for direct part search contents (#41, #47)
-- @param ctx game context
-- @param surface_name string
-- @param parent object
-- @param items list of item name strings
-- @return string
function narrator.part_contents(ctx, surface_name, parent, items)
    if #items == 0 then
        return narrator.part_empty(ctx, surface_name, parent)
    end
    local list = table.concat(items, ", ")
    local room = ctx and ctx.current_room
    local sense = get_primary_sense(ctx, room)
    local part = resolve_part_display(surface_name, parent)
    local verb = (sense == "touch") and "feel" or "find"
    return "You rummage through the " .. part .. " and " .. verb .. ": " .. list .. "."
end

--- Generate narrative for empty direct part search (#41, #47)
-- @param ctx game context
-- @param surface_name string
-- @param parent object
-- @return string
function narrator.part_empty(ctx, surface_name, parent)
    local part = resolve_part_display(surface_name, parent)
    return "You rummage through the " .. part .. ". It is empty."
end

---------------------------------------------------------------------------
-- #63: Surface-aware content narration
---------------------------------------------------------------------------

--- Aggregate duplicate item names into counted descriptions (#65)
-- "a wooden match" x7 → "several wooden matches"
-- @param items list of item name strings
-- @return list of aggregated name strings
function narrator.aggregate_items(items)
    local counts = {}
    local order = {}
    for _, name in ipairs(items) do
        if not counts[name] then
            counts[name] = 0
            order[#order + 1] = name
        end
        counts[name] = counts[name] + 1
    end
    local result = {}
    for _, name in ipairs(order) do
        local count = counts[name]
        if count == 1 then
            result[#result + 1] = name
        else
            local base = strip_article(name)
            local plural = pluralize(base)
            if count == 2 then
                result[#result + 1] = "a couple of " .. plural
            else
                result[#result + 1] = "several " .. plural
            end
        end
    end
    return result
end

--- Generate narration for surface contents, distinguishing "top" from "inside" (#63, #96)
-- @param ctx game context
-- @param surface_name string ("top", "inside", etc.)
-- @param parent object that owns the surface
-- @param items list of item name strings
-- @param target string or nil — when set, appends "but no <target>" suffix
-- @return string
function narrator.surface_contents(ctx, surface_name, parent, items, target)
    local sense = get_primary_sense(ctx, ctx.current_room)
    local agg = narrator.aggregate_items(items)
    local list = table.concat(agg, ", ")
    local parent_display = strip_article(parent.name or parent.id or "it")
    local suffix = target and (", but no " .. target) or ""

    -- #96: Resolve part name for "inside" surfaces (e.g., "drawer" instead of "nightstand")
    local container_display = parent_display
    if surface_name ~= "top" then
        local part_name = resolve_part_display(surface_name, parent)
        if part_name and part_name ~= surface_name then
            container_display = part_name
        end
    end

    if surface_name == "top" then
        if sense == "touch" then
            return "On top of the " .. parent_display .. ", you feel: " .. list .. suffix .. "."
        else
            return "On top of the " .. parent_display .. ", you find: " .. list .. suffix .. "."
        end
    else
        -- #96: Always include container name in "inside" narration
        if sense == "touch" then
            return "Inside the " .. container_display .. ", you feel: " .. list .. suffix .. "."
        else
            return "Inside the " .. container_display .. ", you find: " .. list .. suffix .. "."
        end
    end
end

---------------------------------------------------------------------------
-- #64: Container discovery / opening narration
---------------------------------------------------------------------------

--- Generate narration for discovering and opening a container part during search (#64)
-- @param ctx game context
-- @param part_name string — display name of the part (e.g., "a small drawer")
-- @return string
function narrator.container_opening(ctx, part_name)
    local sense = get_primary_sense(ctx, ctx.current_room)
    local name = part_name or "a container"
    if sense == "touch" then
        return "You feel " .. name .. ". You pull it open."
    else
        return "You see " .. name .. ". You open it."
    end
end

--- Generate narration for the contents found inside a container part (#64)
-- @param ctx game context
-- @param part object or part table with .name
-- @param items list of item name strings
-- @return string
function narrator.container_part_contents(ctx, part, items)
    local sense = get_primary_sense(ctx, ctx.current_room)
    local agg = narrator.aggregate_items(items)
    local list = table.concat(agg, ", ")
    local display = strip_article(part.name or part.id or "it")
    if sense == "touch" then
        return "Inside the " .. display .. ", you feel: " .. list .. "."
    else
        return "Inside the " .. display .. ", you find: " .. list .. "."
    end
end

--- Generate narration for opening a nested container found during search (#64)
-- @param ctx game context
-- @param container object
-- @return string
function narrator.nested_container_opening(ctx, container)
    local sense = get_primary_sense(ctx, ctx.current_room)
    local name = strip_article(container.name or container.id or "it")
    if sense == "touch" then
        return "You open the " .. name .. "."
    else
        return "You open the " .. name .. "."
    end
end

--- Generate narration for nested container contents (#64, #65, #96)
-- @param ctx game context
-- @param container object
-- @param items list of item name strings
-- @return string
function narrator.nested_container_contents(ctx, container, items)
    local sense = get_primary_sense(ctx, ctx.current_room)
    local agg = narrator.aggregate_items(items)
    local list = table.concat(agg, ", ")
    -- #96: Include container name
    local display = strip_article(container.name or container.id or "it")
    if sense == "touch" then
        return "Inside the " .. display .. ", you feel: " .. list .. "."
    else
        return "Inside the " .. display .. ", you find: " .. list .. "."
    end
end

return narrator
