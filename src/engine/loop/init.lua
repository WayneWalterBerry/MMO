-- engine/loop/init.lua
-- Minimal terminal REPL game loop.
-- Parses player input into verb + noun and routes to verb handlers.
-- Tier 1: rule-based verb dispatch (exact verb match).
-- Tier 2: embedding-based fallback (phrase-text similarity via parser module).

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
    print(room.on_look(room, context.registry))
    return
  end

  local parts = {}

  -- Part 1: Room description (permanent architectural features).
  parts[#parts + 1] = room.description or ""

  -- Part 2: Object presences -- each visible object contributes its room_presence.
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

  -- Question patterns → look in (container queries with noun)
  local container_noun = lower:match("^what'?s%s+in%s+(.+)")
    or lower:match("^what%s+is%s+in%s+(.+)")
    or lower:match("^what'?s%s+inside%s+(.+)")
    or lower:match("^what%s+is%s+inside%s+(.+)")
  if container_noun then
    return "look", "in " .. container_noun
  end

  -- Bare "what's inside" (no noun) → look
  if lower:match("^what'?s%s+inside$")
    or lower:match("^what%s+is%s+inside$") then
    return "look", ""
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

  -- Composite part phrases: "take out X", "pull out X" → pull
  local pull_target = lower:match("^take%s+out%s+(.+)")
    or lower:match("^pull%s+out%s+(.+)")
    or lower:match("^yank%s+out%s+(.+)")
  if pull_target then
    return "pull", pull_target
  end

  -- "uncork X", "pop cork" → uncork
  local uncork_target = lower:match("^pop%s+(.+)")
  if uncork_target and uncork_target:match("cork") then
    return "uncork", "bottle"
  end

  -- "push X back" / "put X back in Y" → put
  local push_back_target = lower:match("^push%s+(.+)%s+back")
  if push_back_target then
    return "put", push_back_target .. " in " .. push_back_target
  end

  -- "put X back" → put X in (context-dependent, let verb handler sort it)
  local put_back_item, put_back_target2 = lower:match("^put%s+(.+)%s+back%s+in%s+(.+)")
  if put_back_item then
    return "put", put_back_item .. " in " .. put_back_target2
  end

  -- Wear/equip phrases: "put on X", "dress in X" → wear
  local wear_target = lower:match("^put%s+on%s+(.+)")
    or lower:match("^dress%s+in%s+(.+)")
  if wear_target then
    return "wear", wear_target
  end

  -- Remove/unequip phrases: "take off X" → remove
  local remove_target = lower:match("^take%s+off%s+(.+)")
  if remove_target then
    return "remove", remove_target
  end

  -- Wear query: "what am i wearing" → inventory
  if lower:match("^what%s+am%s+i%s+wear") then
    return "inventory", ""
  end

  return nil, nil
end

-- run(context)
-- context fields:
--   registry     -- live registry instance
--   current_room -- room table (must have .id, .name, .description)
--   verbs        -- table of { [verb_string] = handler_function }
--   on_quit      -- optional callback fired before exit
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

    -- Strip trailing question marks before parsing
    trimmed = trimmed:gsub("%?+$", ""):match("^%s*(.-)%s*$")
    if trimmed == "" then goto continue end

    -- Split compound commands on " and " (e.g., "get a match and light it")
    local sub_commands = {}
    local remaining = trimmed
    while true do
      local before, after = remaining:match("^(.-)%s+and%s+(.+)$")
      if before and after then
        local b = before:match("^%s*(.-)%s*$")
        if b ~= "" then sub_commands[#sub_commands + 1] = b end
        remaining = after
      else
        local r = remaining:match("^%s*(.-)%s*$")
        if r ~= "" then sub_commands[#sub_commands + 1] = r end
        break
      end
    end

    local should_quit = false
    for _, sub_input in ipairs(sub_commands) do
      -- Try natural language preprocessing first
      local verb, noun = preprocess_natural_language(sub_input)
      if not verb then
        verb, noun = parse(sub_input)
      end

      if verb == "" then goto next_sub end

      if verb == "quit" then
        should_quit = true
        break
      end

      local handler = context.verbs[verb]
      if handler then
        handler(context, noun)
      elseif context.parser then
        -- Tier 2 fallback: try embedding-based phrase matching
        local parser_mod = require("engine.parser")
        local handled = parser_mod.fallback(context.parser, sub_input, context)
        if not handled then
          -- Tier 2 failed -- no graceful fallback past this point
          goto next_sub
        end
      else
        -- No Tier 2 available -- original behaviour
        local question_words = { what = true, where = true, how = true, who = true, why = true }
        if question_words[verb] then
          print("Try 'feel' to explore by touch, or 'look' if you have light. Type 'help' for a full list of commands.")
        else
          print("I don't understand '" .. verb .. "'. Try 'look', 'examine', 'take', 'open', or type 'help' for a full list.")
        end
      end

      ::next_sub::
    end

    if should_quit then
      if context.on_quit then context.on_quit() end
      print("Goodbye.")
      break
    end

    -- Post-command FSM tick phase: process auto-transitions (burn countdown, etc.)
    local fsm_ok, fsm_mod = pcall(require, "engine.fsm")
    if fsm_ok and fsm_mod and context.registry then
      local tick_targets = {}
      local reg = context.registry
      local room = context.current_room
      -- Room contents + their surface/container contents
      for _, obj_id in ipairs(room and room.contents or {}) do
        tick_targets[#tick_targets + 1] = obj_id
        local obj = reg:get(obj_id)
        if obj and obj.surfaces then
          for _, zone in pairs(obj.surfaces) do
            for _, item_id in ipairs(zone.contents or {}) do
              tick_targets[#tick_targets + 1] = item_id
            end
          end
        end
        if obj and obj.contents then
          for _, item_id in ipairs(obj.contents) do
            tick_targets[#tick_targets + 1] = item_id
          end
        end
      end
      -- Player hands
      if context.player then
        for i = 1, 2 do
          if context.player.hands[i] then
            tick_targets[#tick_targets + 1] = context.player.hands[i]
          end
        end
      end
      -- Tick all FSM objects
      for _, obj_id in ipairs(tick_targets) do
        local obj = reg:get(obj_id)
        if obj and obj._state then
          local msg = fsm_mod.tick(reg, obj_id)
          if msg then
            print("")
            print(msg)
          end
        end
      end
    end

    -- Post-command tick (flame countdown, candle burn, etc.)
    if context.on_tick then
      context.on_tick(context)
    end

    -- Game over check (death by poison, etc.)
    if context.game_over then
      print("")
      io.write("Play again? (y/n) > ")
      io.flush()
      local answer = io.read()
      if not answer or not answer:lower():match("^y") then
        print("Goodbye.")
      else
        print("\nRestart the game to play again.")
      end
      break
    end

    ::continue::
  end
end

return loop
