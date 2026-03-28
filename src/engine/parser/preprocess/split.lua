-- engine/parser/preprocess/split.lua
-- Command splitting helpers.

local data = require("engine.parser.preprocess.data")

local split = {}

function split.split_commands(input)
    if not input then return {} end
    local trimmed = input:match("^%s*(.-)%s*$")
    if trimmed == "" then return {} end

    local lower = trimmed:lower()

    if not trimmed:find("[,;]")
        and not lower:find("%f[%a]then%f[%A]")
        and not lower:find("%f[%a]and then%f[%A]") then
        return { trimmed }
    end

    local segments = {}
    local current = {}
    local in_quote = false
    local i = 1
    local len = #trimmed

    while i <= len do
        local ch = trimmed:sub(i, i)

        if ch == '"' then
            in_quote = not in_quote
            current[#current + 1] = ch
            i = i + 1

        elseif not in_quote and lower:sub(i, i + 9) == " and then " then
            local seg = table.concat(current):match("^%s*(.-)%s*$")
            if seg ~= "" then segments[#segments + 1] = seg end
            current = {}
            i = i + 10

        elseif not in_quote and lower:sub(i, i + 5) == " then " then
            local seg = table.concat(current):match("^%s*(.-)%s*$")
            if seg ~= "" then segments[#segments + 1] = seg end
            current = {}
            i = i + 6

        elseif not in_quote and (ch == ',' or ch == ';') then
            local seg = table.concat(current):match("^%s*(.-)%s*$")
            if seg ~= "" then segments[#segments + 1] = seg end
            current = {}
            i = i + 1

        else
            current[#current + 1] = ch
            i = i + 1
        end
    end

    local seg = table.concat(current):match("^%s*(.-)%s*$")
    if seg ~= "" then segments[#segments + 1] = seg end

    for si = 1, #segments do
        local s = segments[si]
        local stripped = s:match("^[Aa][Nn][Dd]%s+(.+)$")
        if stripped then
            segments[si] = stripped:match("^%s*(.-)%s*$")
        end
    end

    local cleaned = {}
    for _, s in ipairs(segments) do
        if s ~= "" then cleaned[#cleaned + 1] = s end
    end

    if #cleaned == 0 then return { trimmed } end
    return cleaned
end

function split.split_compound(input)
    if not input then return {} end
    local trimmed = input:match("^%s*(.-)%s*$")
    if trimmed == "" then return {} end

    local lower = trimmed:lower()
    if not lower:find("%s+and%s+") then
        return { trimmed }
    end

    local results = {}
    local remaining = trimmed
    local safety = 0

    while true do
        safety = safety + 1
        if safety > 50 then break end

        local lower_rem = remaining:lower()
        local best_pos = nil

        local search_start = 1
        while true do
            local and_start, and_end = lower_rem:find("%s+and%s+", search_start)
            if not and_start then break end

            local after = remaining:sub(and_end + 1)
            local next_word = after:match("^(%S+)")
            if next_word and data.KNOWN_VERBS[next_word:lower()] then
                best_pos = { start = and_start, finish = and_end }
                break
            end
            search_start = and_end + 1
        end

        if not best_pos then
            local r = remaining:match("^%s*(.-)%s*$")
            if r ~= "" then results[#results + 1] = r end
            break
        end

        local before = remaining:sub(1, best_pos.start - 1):match("^%s*(.-)%s*$")
        if before ~= "" then results[#results + 1] = before end
        remaining = remaining:sub(best_pos.finish + 1)
    end

    if #results == 0 then return { trimmed } end
    return results
end

return split
