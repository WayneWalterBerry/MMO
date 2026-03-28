-- Auto-split from sensory.lua
local H = require("engine.verbs.helpers")

local preprocess = H.preprocess
local find_visible = H.find_visible
local container_contents_accessible = H.container_contents_accessible

local M = {}

function M.register(handlers)
    -- SEARCH / FIND -- Progressive traverse system (turn-based, interruptible)
    -- Wayne directive 2026-03-22T12:25, 12:31: Search is a progressive TRAVERSE
    -- NOT instant query. Engine walks objects nearΓåÆfar, narrating as it goes.
    -- Auto-opens containers, costs 1 turn per step, can be interrupted.
    ---------------------------------------------------------------------------
    local search_mod = require("engine.search")
    
    handlers["search"] = function(ctx, noun)
        -- Parse search syntax patterns
        local target = nil
        local scope = nil
        
        -- BUG-081: Strip articles from bare noun before further processing
        local stripped_noun = preprocess.strip_articles(noun)
        
        -- BUG-073: Treat "the room", "the area" as sweep keywords
        -- BUG-078: "everything", "anything", "all" ΓåÆ undirected sweep
        local sweep_words = { [""] = true, ["around"] = true, ["room"] = true, ["here"] = true,
                              ["around me"] = true, ["surroundings"] = true,
                              ["the room"] = true, ["the area"] = true, ["area"] = true,
                              ["everywhere"] = true, ["this place"] = true,
                              ["everything"] = true, ["anything"] = true, ["all"] = true }
        
        if sweep_words[noun] or sweep_words[stripped_noun] then
            -- Bare search - undirected room sweep
            search_mod.search(ctx, nil, nil)
            return
        end
        
        -- Pattern: "search [scope] for [target]"
        local scope_part, target_part = stripped_noun:match("^(.-)%s+for%s+(.+)$")
        if scope_part and target_part then
            -- BUG-081: strip articles from scope and target
            scope_part = preprocess.strip_articles(scope_part)
            target_part = preprocess.strip_articles(target_part)
            -- Resolve scope to object ID
            -- BUG-082: Try find_visible ΓÇö if scope is a part (drawer), use parent
            local scope_obj, scope_loc, scope_parent = find_visible(ctx, scope_part)
            if not scope_obj then
                print("You don't see " .. scope_part .. " here.")
                return
            end
            -- BUG-082: If scope resolves to a part, use its parent for search
            -- #41: Pass part's surface mapping so search restricts to that surface
            if scope_loc == "part" and scope_parent then
                local part_surface = scope_obj.surface
                scope_obj = scope_parent
                search_mod.search(ctx, target_part, scope_obj.id, part_surface)
                return
            end
            -- Issue #100: Gate search on closed simple containers
            if not scope_obj.surfaces
                and (scope_obj.container or scope_obj.is_container)
                and not container_contents_accessible(scope_obj, "tactile") then
                local cname = (scope_obj.name or "that"):gsub("^a ", "the "):gsub("^an ", "the ")
                print(cname:sub(1,1):upper() .. cname:sub(2) .. " is closed.")
                return
            end
            search_mod.search(ctx, target_part, scope_obj.id)
            return
        end
        
        -- Pattern: "search for [target]" (already stripped by preprocess.lua if present)
        -- If noun doesn't contain "for", treat as either:
        --   1. A scope to search ("search nightstand")
        --   2. A target to find ("search matchbox")
        -- Prefer scope interpretation (search a specific object)
        
        -- BUG-146 (#46): Use exact-only matching for scope detection.
        -- Fuzzy matching can produce false positives (e.g., "match" ΓåÆ rug's
        -- keyword "mat" via Levenshtein distance 2) that hijack the search
        -- into treating the wrong object as scope instead of doing a targeted
        -- room-wide search.
        ctx._exact_only = true
        local obj, obj_loc, obj_parent = find_visible(ctx, stripped_noun)
        ctx._exact_only = nil
        if obj then
            -- BUG-082: If obj is a part (drawer), use its parent for search
            -- #41: Pass part's surface mapping so search restricts to that surface
            if obj_loc == "part" and obj_parent then
                local part_surface = obj.surface
                obj = obj_parent
                search_mod.search(ctx, nil, obj.id, part_surface)
                return
            end
            -- Issue #100: Gate search on closed simple containers
            if not obj.surfaces
                and (obj.container or obj.is_container)
                and not container_contents_accessible(obj, "tactile") then
                local cname = (obj.name or "that"):gsub("^a ", "the "):gsub("^an ", "the ")
                print(cname:sub(1,1):upper() .. cname:sub(2) .. " is closed.")
                return
            end
            -- Found an object - treat as scope (BUG-079: scoped undirected search)
            search_mod.search(ctx, nil, obj.id)
        else
            -- Not found as object - treat as target (room-wide search)
            search_mod.search(ctx, stripped_noun, nil)
        end
    end
    
    handlers["find"] = function(ctx, noun)
        if not noun or noun == "" then
            print("Find what?")
            return
        end
        
        -- BUG-081: Strip articles from noun
        local stripped_noun = preprocess.strip_articles(noun)
        
        -- BUG-078: "find everything/anything/all" ΓåÆ undirected sweep
        if stripped_noun == "everything" or stripped_noun == "anything" or stripped_noun == "all" then
            search_mod.search(ctx, nil, nil)
            return
        end
        
        -- Pattern: "find [target] in [scope]"
        local target_part, scope_part = stripped_noun:match("^(.-)%s+in%s+(.+)$")
        if target_part and scope_part then
            -- BUG-081: strip articles
            target_part = preprocess.strip_articles(target_part)
            scope_part = preprocess.strip_articles(scope_part)
            -- Resolve scope to object ID
            local scope_obj = find_visible(ctx, scope_part)
            if not scope_obj then
                print("You don't see " .. scope_part .. " here.")
                return
            end
            search_mod.find(ctx, target_part, scope_obj.id)
            return
        end
        
        -- Simple "find [target]" - room-wide targeted search
        search_mod.find(ctx, stripped_noun, nil)
    end

    ---------------------------------------------------------------------------
end


return M
