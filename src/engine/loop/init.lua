-- engine/loop/init.lua
-- Minimal terminal REPL game loop.
-- Parses player input into verb + noun and routes to verb handlers.

local loop = {}

-- Built-in verb: look
-- Composes the room view dynamically from three sources:
--   1. Room description (permanent features only)
--   2. Object presences (room_presence field on each object in contents)
--   3. Visible exits with current state
local function cmd_look(context)
  local room = context.current_room
  if not room then
    print("You are nowhere.")
    return
  end

  -- If the room defines a custom on_look, use it (escape hatch for special rooms).
  if room.on_look then
    print(room.name or "Unnamed room")
    print(room.on_look(room))
    return
  end

  local parts = {}

  -- Part 1: Room description (permanent architectural features).
  parts[#parts + 1] = room.description or ""

  -- Part 2: Object presences — each visible object contributes its room_presence.
  local presences = {}
  local contents_list = room.contents or {}
  for _, obj_id in ipairs(contents_list) do
    local obj = context.registry:get(obj_id)
    if obj and not obj.hidden then
      if obj.room_presence then
        presences[#presences + 1] = obj.room_presence
      else
        presences[#presences + 1] = "There is " .. (obj.name or obj.id) .. " here."
      end
    end
  end
  if #presences > 0 then
    parts[#parts + 1] = table.concat(presences, " ")
  end

  -- Part 3: Visible exits.
  local exit_lines = {}
  for dir, exit in pairs(room.exits or {}) do
    local e = type(exit) == "string" and {name = dir, hidden = false} or exit
    if not e.hidden then
      local state = ""
      if e.open == false and e.locked then
        state = " (locked)"
      elseif e.open == false then
        state = " (closed)"
      end
      exit_lines[#exit_lines + 1] = "  " .. dir .. ": " .. (e.name or dir) .. state
    end
  end
  if #exit_lines > 0 then
    parts[#parts + 1] = "Exits:\n" .. table.concat(exit_lines, "\n")
  end

  print(room.name or "Unnamed room")
  print(table.concat(parts, "\n\n"))
end

-- parse(input) -> verb, noun
-- Splits a raw input string into the first word (verb) and the rest (noun).
local function parse(input)
  input = input:match("^%s*(.-)%s*$") -- trim
  local verb, noun = input:match("^(%S+)%s*(.*)")
  return (verb or ""):lower(), (noun or ""):lower()
end

-- preprocess_natural_language(input) -> verb, noun or nil, nil
-- Converts common question patterns and multi-word phrases into known verbs.
local function preprocess_natural_language(input)
  local lower = input:lower():match("^%s*(.-)%s*$")
  if not lower or lower == "" then return nil, nil end

  -- Question patterns → look
  if lower:match("^what%s+is%s+around")
    or lower:match("^what%s+do%s+i%s+see")
    or lower:match("^what%s+can%s+i%s+see")
    or lower:match("^where%s+am%s+i")
    or lower:match("^look%s+around$") then
    return "look", ""
  end

  -- Question patterns → time
  if lower:match("^what%s+time")
    or lower:match("^what%s+is%s+the%s+time") then
    return "time", ""
  end

  -- Question patterns → inventory
  if lower:match("^what%s+am%s+i%s+carry")
    or lower:match("^what%s+do%s+i%s+have") then
    return "inventory", ""
  end

  -- Question patterns → help
  if lower:match("^what%s+can%s+i%s+do")
    or lower:match("^how%s+do%s+i") then
    return "help", ""
  end

  -- Grope/feel compound phrases → feel (room sweep)
  if lower:match("^grope%s+around%s+")
    or lower:match("^feel%s+around%s+") then
    return "feel", ""
  end

  return nil, nil
end

-- run(context)
-- context fields:
--   registry     — live registry instance
--   current_room — room table (must have .id, .name, .description)
--   verbs        — table of { [verb_string] = handler_function }
--   on_quit      — optional callback fired before exit
function loop.run(context)
  assert(context and context.registry, "loop: context.registry is required")
  context.verbs = context.verbs or {}

  -- Register built-ins (can be overridden by context.verbs).
  if not context.verbs["look"] then
    context.verbs["look"] = cmd_look
  end

  print("Type 'look' to look around. Type 'quit' to exit.")
  print("")

  while true do
    io.write("> ")
    io.flush()
    local input = io.read()
    if not input then break end -- EOF / piped input exhausted

    local trimmed = input:match("^%s*(.-)%s*$")
    if trimmed == "" then goto continue end

    -- Try natural language preprocessing first
    local verb, noun = preprocess_natural_language(trimmed)
    if not verb then
      verb, noun = parse(trimmed)
    end

    if verb == "" then goto continue end

    if verb == "quit" then
      if context.on_quit then context.on_quit() end
      print("Goodbye.")
      break
    end

    local handler = context.verbs[verb]
    if handler then
      handler(context, noun)
    else
      -- Helpful hints for natural-language question words
      local question_words = { what = true, where = true, how = true, who = true, why = true }
      if question_words[verb] then
        print("Try 'feel' to explore by touch, or 'look' if you have light. Type 'help' for a full list of commands.")
      else
        print("I don't understand '" .. verb .. "'. Try 'look', 'examine', 'take', 'open', or type 'help' for a full list.")
      end
    end

    -- Post-command tick (flame countdown, candle burn, etc.)
    if context.on_tick then
      context.on_tick(context)
    end

    ::continue::
  end
end

return loop
