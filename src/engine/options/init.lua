-- engine/options/init.lua
-- Options/Hint System: Goal-driven hybrid generator.
-- Approach C: Room declares goal, engine uses GOAP planner + sensory exploration + dynamic scan.
--
-- Ownership: Bart (Architect) — engine architecture.

local M = {}

local goal_planner = require("engine.parser.goal_planner")
local context_window = require("engine.parser.context")

-- Presentation module for light-level checks
local pres_ok, presentation = pcall(require, "engine.ui.presentation")
if not pres_ok then presentation = nil end

-- Flavor text rotations
local FLAVOR_LINES = {
    "You consider your situation...",
    "You take a moment to think...",
    "You pause and assess what you know...",
    "You weigh your choices...",
}

local REPEAT_FLAVOR = {
    "You ponder what else you might try...",
    "You consider your options again...",
    "You think harder about what to do...",
}

local STUCK_FLAVOR = "Perhaps you should try actually DOING something..."

local DISABLED_MESSAGE = "You need to figure this one out yourself."
local DELAY_MESSAGE = "Give it a moment... look around first."

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function strip_articles(noun)
    if not noun then return "" end
    return noun:lower():gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
end

local function obj_keyword(obj)
    if not obj then return "" end
    if obj.keywords and #obj.keywords > 0 then
        return obj.keywords[1]
    end
    return obj.id
end

local function is_dark(ctx)
    if presentation and presentation.has_some_light then
        return not presentation.has_some_light(ctx)
    end
    -- Fallback: check ctx.light_level if available
    if ctx.light_level == "dark" then return true end
    return false
end

local function command_used_recently(ctx, verb)
    if not ctx.recent_commands then return false end
    for _, cmd in ipairs(ctx.recent_commands) do
        if cmd and cmd.verb == verb then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Phase 1: Goal-directed steps (0-2 items)
---------------------------------------------------------------------------

local function wrap_goal_step(step, ctx)
    local verb = step.verb
    local noun = strip_articles(step.noun or "")
    local display = ""

    if verb == "go" then
        display = "Head " .. noun
    elseif verb == "open" then
        display = "Try to open the " .. noun
    elseif verb == "take" then
        if noun:match("from") then
            display = "Pick up the " .. noun
        else
            display = "Pick up the " .. noun
        end
    elseif verb == "unlock" then
        display = "Try to unlock the " .. noun
    elseif verb == "light" then
        display = "Light the " .. noun
    elseif verb == "feel" then
        if noun == "" then
            display = "Feel around in the darkness"
        else
            display = "Feel the " .. noun
        end
    elseif verb == "examine" or verb == "look" then
        if noun == "" then
            display = "Look around the room"
        else
            display = "Take a closer look at the " .. noun
        end
    elseif verb == "search" then
        if noun == "" then
            display = "Search the area carefully"
        else
            display = "Search the " .. noun
        end
    else
        display = verb .. (noun ~= "" and (" the " .. noun) or "")
    end

    return {
        command = step.verb .. (step.noun and step.noun ~= "" and (" " .. step.noun) or ""),
        display = display,
        source = "goal",
    }
end

local function generate_goal_steps(ctx)
    local room = ctx.current_room
    if not room then return {} end

    -- Check for goal or goals
    local goal = room.goal
    if not goal and room.goals and #room.goals > 0 then
        -- Pick highest priority unmet goal
        for _, g in ipairs(room.goals) do
            goal = g
            break
        end
    end

    if not goal then return {} end

    -- Use GOAP planner to get prerequisite chain
    -- Note: goal_planner.plan signature is (verb, noun, ctx)
    local plan = goal_planner.plan(goal.verb, goal.noun or "", ctx)
    if not plan or #plan == 0 then return {} end

    local results = {}
    -- Show only first step (anti-spoiler Rule 1)
    results[#results + 1] = wrap_goal_step(plan[1], ctx)
    
    -- If first step is trivial movement, show step 2 as well
    if #plan > 1 and plan[1].verb == "go" then
        results[#results + 1] = wrap_goal_step(plan[2], ctx)
    end

    return results
end

---------------------------------------------------------------------------
-- Phase 2: Sensory exploration (1-2 items)
---------------------------------------------------------------------------

local SENSORY_TEMPLATES_DARK = {
    { verb = "feel", display = "Feel around for objects in the darkness" },
    { verb = "feel", display = "Run your hands over nearby surfaces" },
    { verb = "listen", display = "Listen carefully for sounds" },
    { verb = "smell", display = "Sniff the air for clues" },
}

local SENSORY_TEMPLATES_LIT = {
    { verb = "look", display = "Look around the room" },
    { verb = "examine", display = "Examine your surroundings more closely" },
    { verb = "search", display = "Search the area carefully" },
    { verb = "listen", display = "Listen carefully for sounds" },
}

local function pick_sensory_suggestions(ctx)
    local dark = is_dark(ctx)
    local templates = dark and SENSORY_TEMPLATES_DARK or SENSORY_TEMPLATES_LIT
    local results = {}

    -- Filter out recently used verbs
    local candidates = {}
    for _, t in ipairs(templates) do
        if not command_used_recently(ctx, t.verb) then
            candidates[#candidates + 1] = t
        end
    end

    -- If all filtered out, use all
    if #candidates == 0 then
        candidates = templates
    end

    -- Pick 1-2 suggestions
    local count = math.min(2, #candidates)
    for i = 1, count do
        results[#results + 1] = {
            command = candidates[i].verb,
            display = candidates[i].display,
            source = "sensory",
        }
    end

    return results
end

---------------------------------------------------------------------------
-- Phase 3: Dynamic object scan (fill remaining to 4)
---------------------------------------------------------------------------

local function score_object(obj, ctx)
    local score = 0
    if not obj then return 0 end

    -- Unopened container
    if obj.container and obj.open == false then
        score = score + 2
    end

    -- FSM transition available
    if obj.transitions and #obj.transitions > 0 then
        score = score + 3
    end

    -- Locked exit
    if obj.locked then
        score = score + 2
    end

    -- Not yet examined
    if not obj._examined then
        score = score + 1
    end

    return score
end

local function scan_interesting_actions(ctx)
    local room = ctx.current_room
    if not room then return {} end

    local candidates = {}

    -- Scan room contents
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = ctx.registry:get(obj_id)
        if obj then
            local score = score_object(obj, ctx)
            if score > 0 then
                candidates[#candidates + 1] = { obj = obj, score = score }
            end
        end
    end

    -- Sort by score (highest first)
    table.sort(candidates, function(a, b) return a.score > b.score end)

    local results = {}
    for _, c in ipairs(candidates) do
        local obj = c.obj
        local kw = obj_keyword(obj)
        local display = ""
        local command = ""

        if obj.container and obj.open == false then
            command = "open " .. kw
            display = "Try to open the " .. (obj.name or kw)
        elseif obj.locked then
            command = "examine " .. kw
            display = "Examine the " .. (obj.name or kw)
        elseif not obj._examined then
            command = "examine " .. kw
            display = "Take a closer look at the " .. (obj.name or kw)
        else
            command = "examine " .. kw
            display = "Examine the " .. (obj.name or kw)
        end

        results[#results + 1] = {
            command = command,
            display = display,
            source = "dynamic",
        }

        if #results >= 4 then break end
    end

    return results
end

---------------------------------------------------------------------------
-- Phase 4: Fallback — exits and generic suggestions
---------------------------------------------------------------------------

local function generate_fallback_options(ctx)
    local results = {}
    local room = ctx.current_room

    -- Basic sensory verb
    if is_dark(ctx) then
        results[#results + 1] = {
            command = "feel",
            display = "Feel around in the darkness",
            source = "fallback",
        }
    else
        results[#results + 1] = {
            command = "look",
            display = "Look around the room",
            source = "fallback",
        }
    end

    -- Add exits
    if room and room.exits then
        for dir, exit in pairs(room.exits) do
            if not exit.locked then
                results[#results + 1] = {
                    command = "go " .. dir,
                    display = "Head " .. dir,
                    source = "fallback",
                }
            end
            if #results >= 3 then break end
        end
    end

    -- Ultimate fallback
    if #results == 0 then
        results[#results + 1] = {
            command = "wait",
            display = "Wait and see what happens...",
            source = "fallback",
        }
    end

    return results
end

---------------------------------------------------------------------------
-- Main API
---------------------------------------------------------------------------

---@class OptionEntry
---@field command string    -- executable command string
---@field display string    -- player-facing display text
---@field source  string    -- "goal" | "sensory" | "dynamic" | "fallback"

---@class OptionsResult
---@field options OptionEntry[]  -- 1-4 entries, ordered by priority
---@field flavor_text string     -- narrator framing line

--- Generate options list based on current context.
--- @param ctx table Context with current_room, player, registry, etc.
--- @return OptionsResult
function M.generate_options(ctx)
    local room = ctx.current_room
    
    -- Check for disabled rooms
    if room and room.options_disabled then
        return {
            options = {},
            flavor_text = DISABLED_MESSAGE,
        }
    end

    -- Check for delay
    if room and room.options_delay then
        local turns_in_room = ctx.turns_in_room or 0
        if turns_in_room < room.options_delay then
            return {
                options = {},
                flavor_text = DELAY_MESSAGE,
            }
        end
    end

    local opts = {}
    local request_count = ctx.options_request_count or 0

    -- Check for sensory-only mode
    local sensory_only = room and room.options_mode == "sensory_only"

    -- Phase 1: Goal-directed steps (unless sensory-only)
    if not sensory_only then
        local goal_opts = generate_goal_steps(ctx)
        for _, opt in ipairs(goal_opts) do
            opts[#opts + 1] = opt
        end
    end

    -- Phase 2: Sensory exploration
    local sensory_opts = pick_sensory_suggestions(ctx)
    for _, opt in ipairs(sensory_opts) do
        if #opts < 4 then
            opts[#opts + 1] = opt
        end
    end

    -- Phase 3: Dynamic object scan (unless sensory-only)
    if not sensory_only then
        local dynamic_opts = scan_interesting_actions(ctx)
        for _, opt in ipairs(dynamic_opts) do
            if #opts < 4 then
                opts[#opts + 1] = opt
            end
        end
    end

    -- Phase 4: Fallback if we have too few options
    if #opts < 2 then
        local fallback_opts = generate_fallback_options(ctx)
        for _, opt in ipairs(fallback_opts) do
            if #opts < 4 then
                opts[#opts + 1] = opt
            end
        end
    end

    -- Pick flavor text based on request count
    local flavor = ""
    if request_count == 0 then
        flavor = FLAVOR_LINES[math.random(#FLAVOR_LINES)]
    elseif request_count <= 2 then
        flavor = REPEAT_FLAVOR[math.random(#REPEAT_FLAVOR)]
    else
        flavor = STUCK_FLAVOR
    end

    return {
        options = opts,
        flavor_text = flavor,
    }
end

return M
