-- engine/parser/goal_planner.lua
-- Tier 3: backward-chaining prerequisite resolver.
-- Fires when a verb+object has unmet tool/capability requirements.
-- Builds a plan of preparatory steps, executes them through Tier 1 dispatch.

local goal_planner = {}
local MAX_DEPTH = 5
local preprocess = require("engine.parser.preprocess")

-- Verb synonyms: verbs that should trigger the same GOAP prerequisite chain
local VERB_SYNONYMS = { burn = "light" }

---------------------------------------------------------------------------
-- Helpers: keyword matching (mirrors verbs module)
-- BUG-056: tries singular forms of plural nouns as fallback
---------------------------------------------------------------------------
local function kw_match(obj, kw)
    if not obj then return false end
    kw = kw:lower()
    local candidates = { kw }
    for _, s in ipairs(preprocess.singularize(kw)) do
        candidates[#candidates + 1] = s
    end
    for _, try_kw in ipairs(candidates) do
        if obj.id and obj.id:lower() == try_kw then return true end
        for _, k in ipairs(obj.keywords or {}) do
            if k:lower() == try_kw then return true end
        end
        if obj.name then
            local p = " " .. obj.name:lower() .. " "
            if p:find(" " .. try_kw .. " ", 1, true) then return true end
        end
    end
    return false
end

local function strip_articles(noun)
    return noun:lower():gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
end

--- Comprehensive check: is an object in a terminal/spent/consumed state?
-- Covers _state == "spent", state.terminal, consumable flag, and "useless" category.
local function is_spent_or_terminal(obj)
    if not obj then return true end
    if obj._state == "spent" then return true end
    if obj.consumable == true then return true end
    if obj.states and obj._state then
        local state_data = obj.states[obj._state]
        if state_data and state_data.terminal then return true end
    end
    if obj.categories then
        for _, cat in ipairs(obj.categories) do
            if cat == "useless" then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- State queries
---------------------------------------------------------------------------
local function has_tool(ctx, cap)
    local reg = ctx.registry
    for i = 1, 2 do
        local id = ctx.player.hands[i]
        if id then
            local obj = reg:get(id)
            if obj then
                local pt = obj.provides_tool
                if pt == cap then return true end
                if type(pt) == "table" then
                    for _, c in ipairs(pt) do if c == cap then return true end end
                end
            end
            if obj and obj.container and obj.contents then
                for _, cid in ipairs(obj.contents) do
                    local item = reg:get(cid)
                    if item and item.provides_tool == cap then return true end
                end
            end
        end
    end
    for _, id in ipairs(ctx.current_room.contents or {}) do
        local obj = ctx.registry:get(id)
        if obj and obj.provides_tool == cap then return true end
    end
    if cap == "fire_source" and ctx.player.state.has_flame
        and ctx.player.state.has_flame > 0 then
        return true
    end
    return false
end

local function is_held(ctx, obj_id)
    return ctx.player.hands[1] == obj_id or ctx.player.hands[2] == obj_id
end

---------------------------------------------------------------------------
-- Find all reachable objects matching a keyword
---------------------------------------------------------------------------
local function find_all(ctx, keyword)
    local out = {}
    local reg = ctx.registry
    local kw = strip_articles(keyword)
    for i = 1, 2 do
        local id = ctx.player.hands[i]
        if id then
            local obj = reg:get(id)
            if obj and kw_match(obj, kw) then
                out[#out + 1] = { obj = obj, where = "hand" }
            end
            if obj and obj.container and obj.contents then
                for _, cid in ipairs(obj.contents) do
                    local item = reg:get(cid)
                    if item and kw_match(item, kw) then
                        out[#out + 1] = { obj = item, where = "container",
                            parent = obj, accessible = (obj.accessible ~= false) }
                    end
                end
            end
        end
    end
    for _, id in ipairs(ctx.current_room.contents or {}) do
        local obj = reg:get(id)
        if obj and not obj.hidden and kw_match(obj, kw) then
            out[#out + 1] = { obj = obj, where = "room" }
        end
        if obj and obj.container and obj.contents then
            for _, cid in ipairs(obj.contents) do
                local item = reg:get(cid)
                if item and kw_match(item, kw) then
                    out[#out + 1] = { obj = item, where = "container",
                        parent = obj, accessible = (obj.accessible ~= false) }
                end
            end
        end
        -- Search ALL surfaces (including inaccessible ones for planning)
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                local zone_ok = (zone.accessible ~= false)
                for _, cid in ipairs(zone.contents or {}) do
                    local item = reg:get(cid)
                    if item and kw_match(item, kw) then
                        out[#out + 1] = { obj = item, where = "surface", parent = obj,
                            surface_accessible = zone_ok }
                    end
                    -- Nested: items inside containers on surfaces
                    if item and item.container and item.contents then
                        for _, inner_id in ipairs(item.contents) do
                            local inner = reg:get(inner_id)
                            if inner and kw_match(inner, kw) then
                                out[#out + 1] = { obj = inner, where = "nested",
                                    parent = item, grandparent = obj,
                                    accessible = (item.accessible ~= false),
                                    surface_accessible = zone_ok }
                            end
                        end
                    end
                end
            end
        end
    end
    return out
end

local function find_property(ctx, prop)
    local reg = ctx.registry
    for i = 1, 2 do
        local id = ctx.player.hands[i]
        if id then
            local obj = reg:get(id)
            if obj and obj[prop] then return obj end
        end
    end
    for _, id in ipairs(ctx.current_room.contents or {}) do
        local obj = reg:get(id)
        if obj and obj[prop] then return obj end
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                for _, cid in ipairs(zone.contents or {}) do
                    local item = reg:get(cid)
                    if item and item[prop] then return item end
                end
            end
        end
        if obj and obj.container and obj.contents then
            for _, cid in ipairs(obj.contents) do
                local item = reg:get(cid)
                if item and item[prop] then return item end
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Try to plan fire_source from a single match candidate
---------------------------------------------------------------------------
local function try_plan_match(entry, ctx, visited)
    local m = entry.obj
    if is_spent_or_terminal(m) then return nil end
    local key = m.id .. ":fire"
    if visited[key] then return nil end
    visited[key] = true
    local steps = {}

    -- Already lit — just ensure it's held
    if m._state == "lit" then
        if not is_held(ctx, m.id) then
            steps[#steps + 1] = { verb = "take", noun = "match" }
        end
        return steps
    end

    -- Count spent matches preceding the fresh one in a container.
    -- The take verb grabs the first keyword-matching item, so spent
    -- matches must be removed before the fresh one can be taken.
    local function spent_before_fresh(parent)
        if not parent or not parent.contents then return 0 end
        local count = 0
        for _, cid in ipairs(parent.contents) do
            if cid == m.id then break end
            local item = ctx.registry:get(cid)
            if item and kw_match(item, "match") and is_spent_or_terminal(item) then
                count = count + 1
            end
        end
        return count
    end

    -- Nested match: inside a container that is inside a surface (e.g., matchbox in nightstand)
    if entry.where == "nested" then
        -- Open the grandparent surface if inaccessible (open nightstand drawer)
        if not entry.surface_accessible and entry.grandparent then
            local gn = entry.grandparent.keywords and entry.grandparent.keywords[1]
                or entry.grandparent.id
            steps[#steps + 1] = { verb = "open", noun = gn }
        end
        -- Open the container in place if inaccessible (open matchbox)
        if not entry.accessible and entry.parent then
            local pn = entry.parent.keywords and entry.parent.keywords[1]
                or entry.parent.id
            steps[#steps + 1] = { verb = "open", noun = pn }
        end
        -- Clear spent matches then take the fresh one
        if entry.parent then
            local pn = entry.parent.keywords and entry.parent.keywords[1]
                or entry.parent.id
            for _ = 1, spent_before_fresh(entry.parent) do
                steps[#steps + 1] = { verb = "take", noun = "match from " .. pn }
                steps[#steps + 1] = { verb = "drop", noun = "match" }
            end
            steps[#steps + 1] = { verb = "take", noun = "match from " .. pn }
        end
    elseif entry.where == "container" then
        -- Match in a direct container
        if not entry.accessible and entry.parent then
            local pn = entry.parent.keywords and entry.parent.keywords[1]
                or entry.parent.id
            steps[#steps + 1] = { verb = "open", noun = pn }
        end
        if entry.parent then
            local pn = entry.parent.keywords and entry.parent.keywords[1]
                or entry.parent.id
            -- Clear spent matches then take the fresh one
            for _ = 1, spent_before_fresh(entry.parent) do
                steps[#steps + 1] = { verb = "take", noun = "match from " .. pn }
                steps[#steps + 1] = { verb = "drop", noun = "match" }
            end
            steps[#steps + 1] = { verb = "take", noun = "match from " .. pn }
        else
            steps[#steps + 1] = { verb = "take", noun = "match" }
        end
    elseif entry.where ~= "hand" then
        steps[#steps + 1] = { verb = "take", noun = "match" }
    end

    local striker = find_property(ctx, "has_striker")
    if not striker then return nil end
    local sn = striker.keywords and striker.keywords[1] or striker.id
    steps[#steps + 1] = { verb = "strike", noun = "match on " .. sn }
    return steps
end

---------------------------------------------------------------------------
-- Backward chaining: build steps to obtain a tool capability
---------------------------------------------------------------------------
local function plan_for_tool(capability, ctx, visited, depth)
    if depth > MAX_DEPTH then return nil end
    if has_tool(ctx, capability) then return {} end
    visited = visited or {}

    if capability == "fire_source" then
        -- Drop any spent/terminal matches from hands
        local spent_drops = {}
        for i = 1, 2 do
            local id = ctx.player.hands[i]
            if id then
                local obj = ctx.registry:get(id)
                if obj and kw_match(obj, "match") and is_spent_or_terminal(obj) then
                    spent_drops[#spent_drops + 1] = { verb = "drop", noun = "match" }
                end
            end
        end

        local candidates = find_all(ctx, "match")

        -- Check if any viable candidate needs spent-match container cleanup
        local needs_free_hand = false
        if #spent_drops == 0 and ctx.player.hands[1] and ctx.player.hands[2] then
            for _, entry in ipairs(candidates) do
                if not is_spent_or_terminal(entry.obj)
                    and (entry.where == "container" or entry.where == "nested")
                    and entry.parent and entry.parent.contents then
                    for _, cid in ipairs(entry.parent.contents) do
                        if cid == entry.obj.id then break end
                        local item = ctx.registry:get(cid)
                        if item and kw_match(item, "match") and is_spent_or_terminal(item) then
                            needs_free_hand = true
                            break
                        end
                    end
                    if needs_free_hand then break end
                end
            end
        end

        -- Free a hand by dropping a non-container held item
        if needs_free_hand then
            for i = 1, 2 do
                local id = ctx.player.hands[i]
                if id then
                    local obj = ctx.registry:get(id)
                    if obj and not (obj.container and obj.contents) then
                        local n = obj.keywords and obj.keywords[1] or obj.id
                        spent_drops[#spent_drops + 1] = { verb = "drop", noun = n }
                        break
                    end
                end
            end
        end

        for _, entry in ipairs(candidates) do
            local result = try_plan_match(entry, ctx, visited)
            if result then
                -- Prepend spent-match drops so the hand slot is free
                for j = #spent_drops, 1, -1 do
                    table.insert(result, 1, spent_drops[j])
                end
                return result
            end
        end
    end

    return nil  -- cannot satisfy
end

---------------------------------------------------------------------------
-- Resolve target object from noun string
---------------------------------------------------------------------------
local function resolve_target(ctx, noun)
    local kw = strip_articles(noun)
    local reg = ctx.registry
    for i = 1, 2 do
        local id = ctx.player.hands[i]
        if id then
            local obj = reg:get(id)
            if obj and kw_match(obj, kw) then return obj end
        end
    end
    for _, id in ipairs(ctx.current_room.contents or {}) do
        local obj = reg:get(id)
        if obj and not obj.hidden and kw_match(obj, kw) then return obj end
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false then
                    for _, cid in ipairs(zone.contents or {}) do
                        local item = reg:get(cid)
                        -- Search inside surface item contents first
                        if item and item.contents then
                            for _, inner_id in ipairs(item.contents) do
                                local inner = reg:get(inner_id)
                                if inner and kw_match(inner, kw) then return inner end
                            end
                        end
                        if item and kw_match(item, kw) then return item end
                    end
                end
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Public: plan prerequisite steps for verb + noun
-- Returns: list of {verb, noun} steps, or nil if no planning needed/possible
---------------------------------------------------------------------------
function goal_planner.plan(verb, noun, ctx)
    if not noun or noun == "" or not ctx then return nil end
    local target_noun = noun:match("^(.-)%s+with%s+") or noun
    local target = resolve_target(ctx, target_noun)
    if not target then return nil end

    -- Check explicit prerequisites table on the object
    local canonical = VERB_SYNONYMS[verb] or verb
    local prereqs = target.prerequisites and
        (target.prerequisites[verb] or target.prerequisites[canonical])

    -- Infer from FSM transitions if no explicit prerequisites
    if not prereqs and target.transitions and target._state then
        for _, t in ipairs(target.transitions) do
            if t.from == target._state and t.trigger ~= "auto" then
                local vm = (t.verb == verb) or (t.verb == canonical)
                if not vm and t.aliases then
                    for _, a in ipairs(t.aliases) do
                        if a == verb or a == canonical then vm = true; break end
                    end
                end
                if vm and t.requires_tool then
                    prereqs = { needs_tool = t.requires_tool }
                    break
                end
            end
        end
    end
    if not prereqs then return nil end

    local needed = prereqs.needs_tool or (prereqs.requires and prereqs.requires[1])
    if not needed then return nil end
    return plan_for_tool(needed, ctx, {}, 0)
end

--- Execute planned steps through Tier 1 dispatch. Returns true on success.
function goal_planner.execute(steps, ctx)
    if not steps or #steps == 0 then return true end
    print("\nYou'll need to prepare first...\n")
    for _, step in ipairs(steps) do
        local handler = ctx.verbs[step.verb]
        if not handler then
            print("(You're not sure how to " .. step.verb .. ".)")
            return false
        end
        handler(ctx, step.noun)
    end
    print("")
    return true
end

return goal_planner
