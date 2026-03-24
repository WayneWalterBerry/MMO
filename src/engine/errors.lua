-- engine/errors.lua
-- Tier 2: Structured Error Context System (Prime Directive #106)
-- Owned by Smithers (UI Engineer). Pure functions, no side effects.
--
-- Provides category-based error messages that are helpful, in-world,
-- and never generic. Each error category has a template function that
-- renders context into a player-facing message.
--
-- API:
--   errors.CATEGORY — table of string constants
--   errors.context(category, fields) → error context table
--   errors.format(err_ctx) → player-facing message string
--   errors.TEMPLATES — externally extensible template registry

local M = {}

-- Error categories
M.CATEGORY = {
    NOT_FOUND    = "not_found",
    WRONG_TARGET = "wrong_target",
    MISSING_TOOL = "missing_tool",
    IMPOSSIBLE   = "impossible",
    DARK         = "dark",
    NO_VERB      = "no_verb",
    AMBIGUOUS    = "ambiguous",
}

--- Build an error context table from a category and field overrides.
function M.context(category, fields)
    fields = fields or {}
    return {
        category = category,
        verb = fields.verb or nil,
        noun = fields.noun or nil,
        object = fields.object or nil,
        reason = fields.reason or nil,
        suggestions = fields.suggestions or {},
        close_match = fields.close_match or nil,
    }
end

-- Message templates keyed by category.
-- Each template: function(err_ctx) → string
M.TEMPLATES = {
    [M.CATEGORY.NOT_FOUND] = function(e)
        if e.close_match then
            return string.format(
                "You don't see '%s' nearby. Did you mean '%s'? Type 'look' to see what's around.",
                e.noun or "that", e.close_match)
        end
        return string.format(
            "You don't see anything called '%s' here. Try 'look' to see what's in the room.",
            e.noun or "that")
    end,

    [M.CATEGORY.WRONG_TARGET] = function(e)
        local obj_name = e.object and (e.object.name or e.object.id) or e.noun or "that"
        if e.suggestions and #e.suggestions > 0 then
            return string.format(
                "You can't %s %s. Try: %s",
                e.verb or "do that to", obj_name,
                table.concat(e.suggestions, ", "))
        end
        return string.format(
            "You can't %s %s. Try 'examine %s' to learn more about it.",
            e.verb or "do that to", obj_name, e.noun or "it")
    end,

    [M.CATEGORY.MISSING_TOOL] = function(e)
        return string.format(
            "You need %s to %s %s.%s",
            e.reason or "the right tool",
            e.verb or "do that to",
            e.object and (e.object.name or e.object.id) or e.noun or "that",
            e.close_match and (" Maybe " .. e.close_match .. "?") or "")
    end,

    [M.CATEGORY.DARK] = function(e)
        return string.format(
            "It's too dark to %s. Try 'feel %s' to explore by touch, or find a light source.",
            e.verb or "do that", e.noun or "around")
    end,

    [M.CATEGORY.NO_VERB] = function(e)
        if e.close_match then
            return string.format(
                "I don't recognize '%s'. Did you mean '%s'? Type 'help' for commands.",
                e.verb or "that", e.close_match)
        end
        return string.format(
            "I'm not sure what '%s' means. Try phrasing as verb + object (e.g., 'open drawer'). Type 'help' for commands.",
            e.verb or "that")
    end,

    [M.CATEGORY.IMPOSSIBLE] = function(e)
        local obj_name = e.object and (e.object.name or e.object.id) or e.noun or "that"
        local suggestion_text = ""
        if e.suggestions and #e.suggestions > 0 then
            suggestion_text = " Try: " .. table.concat(e.suggestions, ", ")
        end
        return string.format("The %s %s%s", obj_name, e.reason or "won't budge.", suggestion_text)
    end,

    [M.CATEGORY.AMBIGUOUS] = function(e)
        if e.suggestions and #e.suggestions > 0 then
            if #e.suggestions == 2 then
                return string.format(
                    "Which do you mean: %s or %s?",
                    e.suggestions[1], e.suggestions[2])
            end
            return "Which do you mean: " .. table.concat(e.suggestions, ", ") .. "?"
        end
        return "Could you be more specific?"
    end,
}

--- Format an error context into a player-facing message.
function M.format(err_ctx)
    local template = M.TEMPLATES[err_ctx.category]
    if template then
        return template(err_ctx)
    end
    return "Something went wrong. Type 'help' for guidance."
end

return M
