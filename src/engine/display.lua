-- engine/display.lua
-- Word-wrap utility for clean terminal output.
-- Wraps long lines at word boundaries to prevent terminal-level character
-- splitting (which can duplicate characters at wrap points on some terminals).

local display = {}

display.WIDTH = 78

-- word_wrap(text, width) -> string
-- Splits text at word boundaries. Preserves existing newlines and leading
-- whitespace (for indented bullet lists like "  a tallow candle").
function display.word_wrap(text, width)
    width = width or display.WIDTH
    if not text or text == "" then return "" end

    local output = {}
    -- Split on existing newlines, wrap each line independently
    for segment in (text .. "\n"):gmatch("(.-)\n") do
        if segment == "" then
            output[#output + 1] = ""
        else
            local indent = segment:match("^(%s*)") or ""
            local content = segment:sub(#indent + 1)
            if #indent + #content <= width then
                output[#output + 1] = segment
            else
                local line = indent
                for word in content:gmatch("%S+") do
                    if line == indent then
                        line = indent .. word
                    elseif #line + 1 + #word > width then
                        output[#output + 1] = line
                        line = indent .. word
                    else
                        line = line .. " " .. word
                    end
                end
                if line ~= indent then
                    output[#output + 1] = line
                end
            end
        end
    end

    -- The gmatch pattern adds a trailing empty string from the appended "\n";
    -- remove it so we don't inject a phantom blank line.
    if #output > 0 and output[#output] == "" and not text:match("\n$") then
        table.remove(output)
    end

    return table.concat(output, "\n")
end

-- install() — replaces the global print with a word-wrapping version.
-- Call once at startup (before the game loop).
function display.install()
    local original_print = _G.print
    _G.print = function(...)
        local n = select("#", ...)
        local parts = {}
        for i = 1, n do
            parts[i] = tostring(select(i, ...))
        end
        local text = table.concat(parts, "\t")
        original_print(display.word_wrap(text))
    end
end

return display
