-- engine/ui/init.lua
-- Split-screen terminal UI using ANSI escape codes.
--
-- Layout (H = terminal height):
--   Line 1        : Status bar (reverse video)
--   Lines 2..H-2  : Output window (scrollable history)
--   Line H-1      : Delimiter (dashes)
--   Line H        : Input line ("> " prompt)
--
-- Pure Lua + ANSI. No external C libs.  Windows 10+ compatible.
-- Falls back to plain print/read when ANSI is unavailable.

local ui = {}

---------------------------------------------------------------------------
-- ANSI helpers
---------------------------------------------------------------------------
local ESC = "\27"

local function csi(...)  return ESC .. "[" .. table.concat({...}) end
local function move_to(r, c) io.write(csi(r, ";", c or 1, "H")) end
local function clear_eol()   io.write(csi("K")) end
local function hide_cursor() io.write(csi("?25l")) end
local function show_cursor() io.write(csi("?25h")) end
local function reverse()     io.write(csi("7m")) end
local function reset_attr()  io.write(csi("0m")) end
local function clear_screen()io.write(csi("2J")) end
local function set_scroll_region(top, bot)
    io.write(csi(top, ";", bot, "r"))
end
local function reset_scroll_region() io.write(csi("r")) end

---------------------------------------------------------------------------
-- State (module-level, single instance)
---------------------------------------------------------------------------
local enabled      = false
local width        = 80
local height       = 24
local buffer       = {}     -- scrollback: array of wrapped lines
local max_buffer   = 500
local scroll_off   = 0     -- 0 = viewing bottom; positive = scrolled up
local stat_left    = ""
local stat_right   = ""

-- Computed geometry (set by compute_regions)
local out_top, out_bot, out_lines
local delim_row, input_row

local function compute_regions()
    out_top    = 2
    out_bot    = height - 2
    out_lines  = out_bot - out_top + 1
    delim_row  = height - 1
    input_row  = height
end

---------------------------------------------------------------------------
-- Terminal size detection
---------------------------------------------------------------------------
local function detect_size()
    local w, h = 80, 24
    if package.config:sub(1, 1) == "\\" then
        -- Windows: parse "mode con" output
        local ok, p = pcall(io.popen, "mode con 2>nul")
        if ok and p then
            local out = p:read("*a")
            p:close()
            local cols  = out:match("Columns:%s*(%d+)")
            local lines = out:match("Lines:%s*(%d+)")
            if cols  then w = tonumber(cols)  end
            if lines then h = tonumber(lines) end
        end
    else
        local ok, p = pcall(io.popen, "stty size 2>/dev/null")
        if ok and p then
            local out = p:read("*l")
            p:close()
            if out then
                local r, c = out:match("(%d+)%s+(%d+)")
                if r then h = tonumber(r) end
                if c then w = tonumber(c) end
            end
        end
    end
    return w, h
end

---------------------------------------------------------------------------
-- Word-wrap (replicates display.word_wrap logic for buffer lines)
---------------------------------------------------------------------------
local function wrap_text(text, w)
    w = w or width
    if not text then return { "" } end
    if text == "" then return { "" } end

    local lines = {}
    for segment in (text .. "\n"):gmatch("(.-)\n") do
        if segment == "" then
            lines[#lines + 1] = ""
        elseif #segment <= w then
            lines[#lines + 1] = segment
        else
            local indent = segment:match("^(%s*)") or ""
            local content = segment:sub(#indent + 1)
            local line = indent
            for word in content:gmatch("%S+") do
                if line == indent then
                    line = indent .. word
                elseif #line + 1 + #word > w then
                    lines[#lines + 1] = line
                    line = indent .. word
                else
                    line = line .. " " .. word
                end
            end
            if line ~= indent or line ~= "" then
                lines[#lines + 1] = line
            end
        end
    end
    -- gmatch artifact: trailing empty string from appended "\n"
    if #lines > 1 and lines[#lines] == "" and not text:match("\n$") then
        table.remove(lines)
    end
    if #lines == 0 then lines = { "" } end
    return lines
end

---------------------------------------------------------------------------
-- Drawing primitives
---------------------------------------------------------------------------

local function draw_status()
    move_to(1, 1)
    reverse()
    local left  = stat_left  or ""
    local right = stat_right or ""
    local pad   = width - #left - #right
    if pad < 1 then pad = 1 end
    local bar = left .. string.rep(" ", pad) .. right
    if #bar > width then bar = bar:sub(1, width) end
    io.write(bar)
    reset_attr()
end

local function draw_delimiter()
    move_to(delim_row, 1)
    clear_eol()
    io.write(string.rep("-", width))
end

local function redraw_output()
    local total   = #buffer
    local visible = out_lines
    local start_idx = total - visible - scroll_off + 1
    if start_idx < 1 then start_idx = 1 end

    for i = 0, visible - 1 do
        local buf_idx = start_idx + i
        local row     = out_top + i
        move_to(row, 1)
        clear_eol()
        if buf_idx >= 1 and buf_idx <= total then
            local line = buffer[buf_idx] or ""
            if #line > width then line = line:sub(1, width) end
            io.write(line)
        end
    end
end

local function draw_input_prompt(text)
    move_to(input_row, 1)
    clear_eol()
    io.write("> " .. (text or ""))
end

local function full_refresh()
    hide_cursor()
    draw_status()
    redraw_output()
    draw_delimiter()
    draw_input_prompt("")
    show_cursor()
    io.flush()
end

---------------------------------------------------------------------------
-- Buffer management
---------------------------------------------------------------------------
local function append_to_buffer(text)
    local lines = wrap_text(text, width)
    for _, line in ipairs(lines) do
        buffer[#buffer + 1] = line
        if #buffer > max_buffer then
            table.remove(buffer, 1)
            if scroll_off > 0 then scroll_off = scroll_off - 1 end
        end
    end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Initialise the split-screen UI.  Returns true on success.
function ui.init()
    width, height = detect_size()
    if height < 8 or width < 20 then
        -- Terminal too small for split-screen
        return false
    end

    compute_regions()
    buffer     = {}
    scroll_off = 0
    stat_left  = ""
    stat_right = ""
    enabled    = true

    -- Enable VT processing on Windows (harmless no-op if already active)
    if package.config:sub(1, 1) == "\\" then
        os.execute("")
    end

    clear_screen()
    -- Set scroll region to output area so Enter on input line won't scroll
    set_scroll_region(out_top, out_bot)
    full_refresh()
    return true
end

function ui.is_enabled()
    return enabled
end

function ui.get_width()
    return width
end

--- Print text into the output window (replaces raw print when UI is active).
function ui.output(text)
    if not enabled then
        io.write((text or "") .. "\n")
        io.flush()
        return
    end

    append_to_buffer(text or "")
    scroll_off = 0  -- snap to bottom on new output

    hide_cursor()
    redraw_output()
    show_cursor()
    io.flush()
end

--- Update the status bar.
function ui.status(left, right)
    stat_left  = left  or stat_left
    stat_right = right or stat_right
    if not enabled then return end
    hide_cursor()
    draw_status()
    show_cursor()
    io.flush()
end

--- Read one line from the input area.
--- Returns nil on EOF.
function ui.input()
    if not enabled then
        io.write("> ")
        io.flush()
        return io.read()
    end

    -- Position cursor at input line
    move_to(input_row, 1)
    clear_eol()
    io.write("> ")
    show_cursor()
    io.flush()

    local text = io.read()
    if not text then return nil end

    -- Immediately clear the input line to prevent stale echo
    move_to(input_row, 1)
    clear_eol()
    io.flush()

    return text
end

--- Sub-prompt (e.g., "What do you want to write? > ").
--- Shows msg in the output window, then reads from input line.
function ui.prompt(msg)
    if not enabled then
        io.write(msg)
        io.flush()
        return io.read()
    end

    ui.output(msg)
    return ui.input()
end

--- Scroll the output window up by n lines (default ≈ one page).
function ui.scroll_up(n)
    if not enabled then return end
    n = n or math.max(1, out_lines - 2)
    local max_scroll = math.max(0, #buffer - out_lines)
    scroll_off = math.min(scroll_off + n, max_scroll)
    hide_cursor()
    redraw_output()
    show_cursor()
    io.flush()
end

--- Scroll the output window down by n lines (default ≈ one page).
function ui.scroll_down(n)
    if not enabled then return end
    n = n or math.max(1, out_lines - 2)
    scroll_off = math.max(0, scroll_off - n)
    hide_cursor()
    redraw_output()
    show_cursor()
    io.flush()
end

--- Returns true (and handles it) if input is a scroll command.
function ui.handle_scroll(input)
    if not enabled then return false end
    local cmd = (input or ""):match("^%s*(.-)%s*$")
    if cmd == "/up" or cmd == "/pgup" then
        ui.scroll_up()
        return true
    elseif cmd == "/down" or cmd == "/pgdn" then
        ui.scroll_down()
        return true
    elseif cmd == "/bottom" then
        scroll_off = 0
        hide_cursor()
        redraw_output()
        show_cursor()
        io.flush()
        return true
    end
    return false
end

--- Full-screen refresh (status + output + delimiter + input prompt).
function ui.refresh()
    if not enabled then return end
    full_refresh()
end

--- Restore terminal to normal state.
function ui.cleanup()
    if not enabled then return end
    enabled = false
    reset_scroll_region()
    reset_attr()
    show_cursor()
    clear_screen()
    move_to(1, 1)
    io.flush()
end

return ui
