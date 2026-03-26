-- engine/parser/goal_planner.lua
-- Tier 3→6: backward-chaining prerequisite resolver.
-- Fires when a verb+object has unmet tool/capability requirements.
-- Builds a plan of preparatory steps, executes them through Tier 1 dispatch.
--
-- Tier 6: Generalized GOAP — property-based goal matching.
-- Goals are defined by requirement properties (needs_light, needs_key,
-- needs_tool) rather than hardcoded verb chains. The planner walks
-- backwards from the goal, finding objects that provide required properties.
-- Safety limit: MAX_PLAN_DEPTH (7 steps) prevents runaway chains.

local goal_planner = {}
local MAX_DEPTH = 7
-- BUG-090: Maximum plan steps to prevent infinite prerequisite chains
local MAX_PLAN_STEPS = 20
local preprocess = require("engine.parser.preprocess")

-- Tier 6: Presentation module for light-level checks
local pres_ok, presentation = pcall(require, "engine.ui.presentation")
if not pres_ok then presentation = nil end

-- Verb synonyms: verbs that should trigger the same GOAP prerequisite chain
local VERB_SYNONYMS = { burn = "light" }

-- Tier 6: Verbs that require light (room must not be dark)
local LIGHT_VERBS = {
    read = true, write = true,
}

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

-- Instance-aware hand accessors for goal planner
local function _gp_hid(hand)
    if type(hand) == "table" then return hand.id end
    return hand
end
local function _gp_hobj(hand, reg)
    if type(hand) == "table" then return hand end
    if type(hand) == "string" then return reg:get(hand) end
    return nil
end

---------------------------------------------------------------------------
-- State queries
---------------------------------------------------------------------------
local function has_tool(ctx, cap)
    local reg = ctx.registry
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _gp_hobj(hand, reg)
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
    return _gp_hid(ctx.player.hands[1]) == obj_id or _gp_hid(ctx.player.hands[2]) == obj_id
end

---------------------------------------------------------------------------
-- Find all reachable objects matching a keyword
---------------------------------------------------------------------------
local function find_all(ctx, keyword)
    local out = {}
    local reg = ctx.registry
    local kw = strip_articles(keyword)
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _gp_hobj(hand, reg)
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
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _gp_hobj(hand, reg)
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
-- Tier 6: Find objects that can cast light via FSM state transition
-- Returns list of { obj, transition, entry } candidates
---------------------------------------------------------------------------
local function find_lightable(ctx)
    local reg = ctx.registry
    local candidates = {}

    local function check_obj(obj, entry_info)
        if not obj or not obj.states or not obj._state then return end
        if is_spent_or_terminal(obj) then return end
        for state_name, state_data in pairs(obj.states) do
            if type(state_data) == "table" and state_data.casts_light then
                if obj._state ~= state_name then
                    for _, t in ipairs(obj.transitions or {}) do
                        if t.from == obj._state and t.to == state_name
                            and t.trigger ~= "auto" then
                            candidates[#candidates + 1] = {
                                obj = obj, transition = t, entry = entry_info,
                            }
                        end
                    end
                end
            end
        end
    end

    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _gp_hobj(hand, reg)
            if obj then check_obj(obj, { where = "hand" }) end
        end
    end
    for _, id in ipairs(ctx.current_room.contents or {}) do
        local obj = reg:get(id)
        if obj then
            check_obj(obj, { where = "room" })
            if obj.surfaces then
                for _, zone in pairs(obj.surfaces) do
                    local zone_ok = (zone.accessible ~= false)
                    for _, cid in ipairs(zone.contents or {}) do
                        local item = reg:get(cid)
                        if item then
                            check_obj(item, { where = "surface", parent = obj,
                                surface_accessible = zone_ok })
                        end
                        if item and item.container and item.contents then
                            for _, inner_id in ipairs(item.contents) do
                                local inner = reg:get(inner_id)
                                if inner then
                                    check_obj(inner, { where = "nested",
                                        parent = item, grandparent = obj,
                                        accessible = (item.accessible ~= false),
                                        surface_accessible = zone_ok })
                                end
                            end
                        end
                    end
                end
            end
            if obj.container and obj.contents then
                for _, cid in ipairs(obj.contents) do
                    local item = reg:get(cid)
                    if item then
                        check_obj(item, { where = "container", parent = obj,
                            accessible = (obj.accessible ~= false) })
                    end
                end
            end
        end
    end
    return candidates
end

---------------------------------------------------------------------------
-- Tier 6: Find objects by exact ID across all reachable locations
-- Returns list of { obj, where, parent, ... } entries (same format as find_all)
---------------------------------------------------------------------------
local function find_by_id(ctx, target_id)
    local out = {}
    local reg = ctx.registry
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _gp_hobj(hand, reg)
            if obj and obj.id == target_id then
                out[#out + 1] = { obj = obj, where = "hand" }
            end
            if obj and obj.container and obj.contents then
                for _, cid in ipairs(obj.contents) do
                    local item = reg:get(cid)
                    if item and item.id == target_id then
                        out[#out + 1] = { obj = item, where = "container",
                            parent = obj, accessible = (obj.accessible ~= false) }
                    end
                end
            end
        end
    end
    for _, id in ipairs(ctx.current_room.contents or {}) do
        local obj = reg:get(id)
        if obj and obj.id == target_id then
            out[#out + 1] = { obj = obj, where = "room" }
        end
        if obj and obj.container and obj.contents then
            for _, cid in ipairs(obj.contents) do
                local item = reg:get(cid)
                if item and item.id == target_id then
                    out[#out + 1] = { obj = item, where = "container",
                        parent = obj, accessible = (obj.accessible ~= false) }
                end
            end
        end
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                local zone_ok = (zone.accessible ~= false)
                for _, cid in ipairs(zone.contents or {}) do
                    local item = reg:get(cid)
                    if item and item.id == target_id then
                        out[#out + 1] = { obj = item, where = "surface",
                            parent = obj, surface_accessible = zone_ok }
                    end
                    if item and item.container and item.contents then
                        for _, inner_id in ipairs(item.contents) do
                            local inner = reg:get(inner_id)
                            if inner and inner.id == target_id then
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

---------------------------------------------------------------------------
-- Tier 6: Keyword for an object (first keyword or id)
---------------------------------------------------------------------------
local function obj_keyword(obj)
    return obj.keywords and obj.keywords[1] or obj.id
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
-- Backward chaining: build steps to obtain fire_source specifically
-- (Preserved from Tier 3 — handles match/striker complexity)
---------------------------------------------------------------------------
local function plan_fire_source(ctx, visited, depth)
    -- Drop any spent/terminal matches from hands
    local spent_drops = {}
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _gp_hobj(hand, ctx.registry)
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
            local hand = ctx.player.hands[i]
            if hand then
                local obj = _gp_hobj(hand, ctx.registry)
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

    return nil
end

---------------------------------------------------------------------------
-- Tier 6: Plan retrieval steps for an object found at a given location
-- Shared by plan_for_key and plan_generic_tool
---------------------------------------------------------------------------
local function plan_retrieval(entry)
    local steps = {}
    local kn = obj_keyword(entry.obj)

    if entry.where == "nested" then
        if not entry.surface_accessible and entry.grandparent then
            steps[#steps + 1] = { verb = "open", noun = obj_keyword(entry.grandparent) }
        end
        if not entry.accessible and entry.parent then
            steps[#steps + 1] = { verb = "open", noun = obj_keyword(entry.parent) }
        end
        local pn = entry.parent and obj_keyword(entry.parent)
        if pn then
            steps[#steps + 1] = { verb = "take", noun = kn .. " from " .. pn }
        else
            steps[#steps + 1] = { verb = "take", noun = kn }
        end
    elseif entry.where == "container" then
        if not entry.accessible and entry.parent then
            steps[#steps + 1] = { verb = "open", noun = obj_keyword(entry.parent) }
        end
        local pn = entry.parent and obj_keyword(entry.parent)
        if pn then
            steps[#steps + 1] = { verb = "take", noun = kn .. " from " .. pn }
        else
            steps[#steps + 1] = { verb = "take", noun = kn }
        end
    elseif entry.where == "surface" then
        if not entry.surface_accessible and entry.parent then
            steps[#steps + 1] = { verb = "open", noun = obj_keyword(entry.parent) }
        end
        steps[#steps + 1] = { verb = "take", noun = kn }
    elseif entry.where == "room" then
        steps[#steps + 1] = { verb = "take", noun = kn }
    end
    -- "hand" → already held, no retrieval needed
    return steps
end

---------------------------------------------------------------------------
-- Tier 6: Plan to provide light to the room
-- Backward chain: find lightable object → plan its tool requirement
---------------------------------------------------------------------------
local function plan_for_light(ctx, visited, depth)
    if depth > MAX_DEPTH then return nil end
    if presentation and presentation.has_some_light
        and presentation.has_some_light(ctx) then
        return {}
    end

    local cands = find_lightable(ctx)
    for _, cand in ipairs(cands) do
        local vkey = cand.obj.id .. ":light_goal"
        if not visited[vkey] then
            visited[vkey] = true
            local steps = {}

            -- If the lightable object requires a tool, plan for it first
            if cand.transition.requires_tool then
                -- Forward-declare: plan_for_tool is defined below
                local tool_steps = plan_fire_source(ctx, visited, depth + 1)
                if not tool_steps then goto next_light end
                for _, s in ipairs(tool_steps) do steps[#steps + 1] = s end
            end

            -- Add the light step itself
            local kn = obj_keyword(cand.obj)
            steps[#steps + 1] = { verb = "light", noun = kn }
            return steps
        end
        ::next_light::
    end

    return nil
end

---------------------------------------------------------------------------
-- Tier 6: Generic tool resolution — find any object providing the
-- requested capability, plan retrieval if needed
---------------------------------------------------------------------------
local function plan_generic_tool(capability, ctx, visited, depth)
    if depth > MAX_DEPTH then return nil end
    local reg = ctx.registry

    local function check_provides(obj)
        if not obj then return false end
        local pt = obj.provides_tool
        if pt == capability then return true end
        if type(pt) == "table" then
            for _, c in ipairs(pt) do if c == capability then return true end end
        end
        return false
    end

    -- Search hands first
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _gp_hobj(hand, reg)
            if obj and check_provides(obj) then return {} end
        end
    end

    -- Search room, surfaces, containers
    for _, id in ipairs(ctx.current_room.contents or {}) do
        local obj = reg:get(id)
        if obj and check_provides(obj) then
            return { { verb = "take", noun = obj_keyword(obj) } }
        end
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                local zone_ok = (zone.accessible ~= false)
                for _, cid in ipairs(zone.contents or {}) do
                    local item = reg:get(cid)
                    if item and check_provides(item) then
                        local steps = {}
                        if not zone_ok then
                            steps[#steps + 1] = { verb = "open", noun = obj_keyword(obj) }
                        end
                        steps[#steps + 1] = { verb = "take", noun = obj_keyword(item) }
                        return steps
                    end
                end
            end
        end
        if obj and obj.container and obj.contents then
            for _, cid in ipairs(obj.contents) do
                local item = reg:get(cid)
                if item and check_provides(item) then
                    local steps = {}
                    if obj.accessible == false then
                        steps[#steps + 1] = { verb = "open", noun = obj_keyword(obj) }
                    end
                    steps[#steps + 1] = { verb = "take",
                        noun = obj_keyword(item) .. " from " .. obj_keyword(obj) }
                    return steps
                end
            end
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- Backward chaining: build steps to obtain a tool capability
-- Tier 6: dispatches to specialized resolvers by capability type
---------------------------------------------------------------------------
local function plan_for_tool(capability, ctx, visited, depth)
    if depth > MAX_DEPTH then return nil end
    if has_tool(ctx, capability) then return {} end
    visited = visited or {}

    -- BUG-090: Safety limit on visited set size to prevent runaway planning
    local visited_count = 0
    for _ in pairs(visited) do visited_count = visited_count + 1 end
    if visited_count > 50 then return nil end

    -- Specialized resolver: fire_source (match/striker chain)
    if capability == "fire_source" then
        return plan_fire_source(ctx, visited, depth)
    end

    -- Generic: find any reachable object providing this capability
    return plan_generic_tool(capability, ctx, visited, depth + 1)
end

---------------------------------------------------------------------------
-- Resolve target object from noun string
---------------------------------------------------------------------------
local function resolve_target(ctx, noun)
    local kw = strip_articles(noun)
    local reg = ctx.registry
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = _gp_hobj(hand, reg)
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
-- Tier 6: checks verb-level requirements (light, key) before object-level
-- Returns: list of {verb, noun} steps, or nil if no planning needed/possible
---------------------------------------------------------------------------
function goal_planner.plan(verb, noun, ctx)
    if not noun or noun == "" or not ctx then return nil end

    local canonical = VERB_SYNONYMS[verb] or verb

    -- Tier 6: Verb-level requirement — light
    if LIGHT_VERBS[canonical] then
        if presentation and presentation.has_some_light
            and not presentation.has_some_light(ctx) then
            local steps = plan_for_light(ctx, {}, 0)
            if steps and #steps > 0 then return steps end
        end
    end

    -- Object-level: existing prerequisite / FSM tool requirements
    local target_noun = noun:match("^(.-)%s+with%s+") or noun
    local target = resolve_target(ctx, target_noun)
    if not target then return nil end

    -- Check explicit prerequisites table on the object
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

--- Issue #17: Narration templates for GOAP auto-chain steps.
--- Maps verb → function(noun) returning a brief narration prefix.
--- When a verb isn't in the table, the handler's own output suffices.
local STEP_NARRATION = {
    take  = function(noun) return "You look for " .. noun .. "..." end,
    open  = function(noun) return "You need to open " .. noun .. " first." end,
    find  = function(noun) return "You search for " .. noun .. "..." end,
    drop  = function(_)    return nil end,   -- silent helper step
}

--- Execute planned steps through Tier 1 dispatch. Returns true on success.
--- Issue #17: Each step now narrates what's happening so the player sees
--- every intermediate action, not just the final result.
function goal_planner.execute(steps, ctx)
    if not steps or #steps == 0 then return true end
    -- Safety limit: max 7 plan depth → max ~20 individual steps
    if #steps > MAX_PLAN_STEPS then
        print("(That would take too many steps — " .. #steps
            .. " needed, limit is " .. MAX_PLAN_STEPS
            .. ". Try breaking it into simpler steps.)")
        return false
    end
    print("\nYou'll need to prepare first...\n")
    for i, step in ipairs(steps) do
        local handler = ctx.verbs[step.verb]
        if not handler then
            print("(You're not sure how to " .. step.verb .. ".)")
            return false
        end
        -- Issue #17: narrate the step before executing
        local narrator = STEP_NARRATION[step.verb]
        if narrator then
            local msg = narrator(step.noun)
            if msg then print(msg) end
        end
        ctx.current_verb = step.verb
        handler(ctx, step.noun)
    end
    print("")
    return true
end

--- Tier 6: Expose internals for testing
goal_planner._plan_for_light = function(ctx, visited, depth)
    return plan_for_light(ctx, visited or {}, depth or 0)
end
goal_planner._plan_for_tool = function(cap, ctx, visited, depth)
    return plan_for_tool(cap, ctx, visited or {}, depth or 0)
end
goal_planner._find_lightable = function(ctx)
    return find_lightable(ctx)
end
goal_planner._find_by_id = function(ctx, id)
    return find_by_id(ctx, id)
end
goal_planner._MAX_DEPTH = MAX_DEPTH

return goal_planner
