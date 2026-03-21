-- engine/loop/init.lua
-- Terminal REPL game loop.
-- Routes player input through the parser pipeline and dispatches to verb handlers.
--
-- Ownership:
--   Smithers (UI Engineer): REPL I/O, parse pipeline (Tier 1→2→3), scroll, quit
--   Bart (Architect): Post-command FSM tick phase, timed events
--
-- Parser pipeline lives in engine/parser/preprocess.lua (Smithers owns).

local loop = {}

-- Parser preprocessing (Smithers owns — see engine/parser/preprocess.lua)
local preprocess = require("engine.parser.preprocess")

-- Tier 3: goal-oriented prerequisite planner (optional module)
local planner_ok, goal_planner = pcall(require, "engine.parser.goal_planner")
if not planner_ok then goal_planner = nil end

-- run(context)
-- context fields:
--   registry     -- live registry instance
--   current_room -- room table (must have .id, .name, .description)
--   verbs        -- table of { [verb_string] = handler_function }
--   ui           -- (optional) engine.ui module instance
--   on_quit      -- optional callback fired before exit
function loop.run(context)
  assert(context and context.registry, "loop: context.registry is required")
  context.verbs = context.verbs or {}

  -- Context tracking for Tier 3 planner
  context.last_tool = context.last_tool or nil
  context.known_objects = context.known_objects or {}

  print("Type 'look' to look around. Type 'quit' to exit.")
  if context.ui and context.ui.is_enabled() then
    print("Scroll: /up  /down  /bottom")
  end
  print("")

  while true do
    -- Update status bar if UI is active
    if context.ui and context.ui.is_enabled() and context.update_status then
      context.update_status(context)
    end

    -- Read input (UI-aware or fallback)
    local input
    if context.ui and context.ui.is_enabled() then
      input = context.ui.input()
    else
      io.write("> ")
      io.flush()
      input = io.read()
    end
    if not input then break end -- EOF / piped input exhausted

    local trimmed = input:match("^%s*(.-)%s*$")
    if trimmed == "" then goto continue end

    -- Handle scroll commands before game processing
    if context.ui and context.ui.handle_scroll(trimmed) then
      goto continue
    end

    -- Echo command into the output window
    if context.ui and context.ui.is_enabled() then
      context.ui.output("> " .. trimmed)
    end

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

    -- If compound command's last part has a GOAP plan, let GOAP handle everything.
    -- e.g. "get match from matchbox and light candle" → GOAP plans "light candle"
    -- end-to-end, making the first part redundant.
    if #sub_commands > 1 and goal_planner then
      local last = sub_commands[#sub_commands]
      local lv, ln = preprocess.natural_language(last)
      if not lv then lv, ln = preprocess.parse(last) end
      if lv == "light" or lv == "ignite" or lv == "burn" then
        local clean = ln:match("^(.-)%s+with%s+.+$")
        if clean and clean ~= "" then ln = clean end
      end
      local plan = goal_planner.plan(lv, ln, context)
      if plan and #plan > 0 then
        sub_commands = { last }
      end
    end

    local should_quit = false
    for _, sub_input in ipairs(sub_commands) do
      -- Try natural language preprocessing first (Smithers's parser pipeline)
      local verb, noun = preprocess.natural_language(sub_input)
      if not verb then
        verb, noun = preprocess.parse(sub_input)
      end

      if verb == "" then goto next_sub end

      if verb == "quit" then
        should_quit = true
        break
      end

      -- Prepositional parsing: strip "with Y" for verbs that auto-find tools
      if verb == "light" or verb == "ignite" or verb == "burn" then
        local clean_noun = noun:match("^(.-)%s+with%s+.+$")
        if clean_noun and clean_noun ~= "" then noun = clean_noun end
      end

      -- Tier 3: goal-oriented prerequisite planning
      if goal_planner then
        local plan = goal_planner.plan(verb, noun, context)
        if plan then
          if not goal_planner.execute(plan, context) then
            goto next_sub
          end
        end
      end

      local handler = context.verbs[verb]
      if handler then
        handler(context, noun)
      elseif context.parser then
        -- Tier 2 fallback: try embedding-based phrase matching
        local parser_fallback = require("engine.parser")
        local handled = parser_fallback.fallback(context.parser, sub_input, context)
        if not handled then
          -- Tier 2 failed — no graceful fallback past this point
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
      -- Tick all FSM objects (legacy on_tick callbacks + threshold checks)
      -- Build environment context from room properties for threshold evaluation
      local env_context = {
          temperature = room and room.temperature or 20,
          wetness = room and room.wetness or 0,
          moisture = room and room.moisture or 0,
          light_level = room and room.light_level or 0,
      }
      for _, obj_id in ipairs(tick_targets) do
        local obj = reg:get(obj_id)
        if obj and obj._state then
          local msg = fsm_mod.tick(reg, obj_id, env_context)
          if msg then
            print("")
            print(msg)
          end
        end
      end

      -- Timed events engine: each command tick = 360 game seconds
      -- (consistent with SLEEP: 10 ticks per game hour = 3600s / 10 = 360s)
      local SECONDS_PER_TICK = 360
      local timer_msgs = fsm_mod.tick_timers(reg, SECONDS_PER_TICK)
      for _, entry in ipairs(timer_msgs) do
        print("")
        print(entry.message)
      end
    end

    -- Post-command tick (flame countdown, candle burn, etc.)
    if context.on_tick then
      context.on_tick(context)
    end

    -- Game over check (death by poison, etc.)
    if context.game_over then
      print("")
      print("Game over. Thanks for playing.")
      break
    end

    ::continue::
  end
end

return loop
