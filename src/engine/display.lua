-- engine/display.lua
-- Word-wrap utility for clean terminal output.
-- Wraps long lines at word boundaries to prevent terminal-level character
-- splitting (which can duplicate characters at wrap points on some terminals).
--
-- When display.ui is set to an active UI module, print() routes through
-- ui.output() instead of the raw terminal.  This lets the split-screen UI
-- own all output without changing any verb handler code.

local display = {}

display.WIDTH = 78

-- Set this to the engine.ui module after ui.init() succeeds.
-- When non-nil and ui.is_enabled(), print() routes through ui.output().
display.ui = nil

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
                local lines = {}
                local line = indent
                for word in content:gmatch("%S+") do
                    if line == indent then
                        line = indent .. word
                    elseif #line + 1 + #word > width then
                        lines[#lines + 1] = line
                        line = indent .. word
                    else
                        line = line .. " " .. word
                    end
                end
                if line ~= indent then
                    lines[#lines + 1] = line
                end

                -- Orphan prevention: if last line is very short (< width/4),
                -- pull the last word from the previous line down so phrases
                -- stay together instead of leaving a single word stranded.
                if #lines >= 2 then
                    local last = lines[#lines]
                    local last_content = last:sub(#indent + 1)
                    if #last_content < width / 4 then
                        local prev = lines[#lines - 1]
                        local sp = prev:match(".*()%s%S+$")
                        if sp and sp > #indent + 1 then
                            local moved = prev:sub(sp + 1)
                            lines[#lines - 1] = prev:sub(1, sp - 1)
                            lines[#lines] = indent .. moved:match("^%s*(.+)") .. " " .. last_content
                        end
                    end
                end

                for _, l in ipairs(lines) do
                    output[#output + 1] = l
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
-- When display.ui is active, output routes through the split-screen UI.
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

        if display.ui and display.ui.is_enabled() then
            -- Route through split-screen UI (it does its own word-wrap)
            display.ui.output(text)
        else
            original_print(display.word_wrap(text))
        end
    end
end

return display
