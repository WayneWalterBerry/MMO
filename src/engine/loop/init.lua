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
-- BUG-060: Pronouns that resolve to the last referenced noun
local PRONOUNS = {
  it = true, them = true, that = true, this = true, those = true,
  ["the same"] = true, ["the same thing"] = true,
}

function loop.run(context)
  assert(context and context.registry, "loop: context.registry is required")
  context.verbs = context.verbs or {}

  -- Context tracking for Tier 3 planner
  context.last_tool = context.last_tool or nil
  context.known_objects = context.known_objects or {}

  -- BUG-060: last referenced noun for context retention between commands
  context.last_noun = context.last_noun or nil

  -- Session transcript for "report bug" (last 50 exchanges)
  context.transcript = context.transcript or {}

  print("Type 'look' to look around. Type 'report bug' to report issues. Type 'quit' to exit.")
  if context.ui and context.ui.is_enabled() then
    print("Scroll: /up  /down  /bottom")
  end
  print("")

  while true do
    -- Update status bar if UI is active
    if context.ui and context.ui.is_enabled() and context.update_status then
      context.update_status(context)
    end

    -- If search is active and no input yet, process one search step
    local search_ok, search_mod = pcall(require, "engine.search")
    if search_ok and search_mod and search_mod.is_searching() then
      -- Wait briefly to allow interruption
      -- (In a real async system, this would be event-driven)
      local continue_search = search_mod.tick(context)
      if continue_search then
        -- Search continues - loop back for next tick
        goto continue
      end
      -- Search completed - fall through to normal input
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
    
    -- If search is active and user entered a command, abort search
    if search_ok and search_mod and search_mod.is_searching() then
      search_mod.abort(context)
    end

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

    -- Multi-command splitting: commas, semicolons, "then" (Issue #1)
    -- BUG-066: Added safety limits to prevent infinite loops or hangs
    local command_parts = preprocess.split_commands(trimmed)

    -- Expand each part further with the existing " and " compound split
    local sub_commands = {}
    for _, part in ipairs(command_parts) do
      local remaining = part
      local safety_limit = 0
      while true do
        safety_limit = safety_limit + 1
        if safety_limit > 100 then
          print("Error: Command too complex (infinite loop protection). Try simpler commands.")
          break
        end
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
      -- BUG-084: Resolve pronouns in last sub-command from earlier fragments.
      -- "find a match and light it" → resolve "it" to "match" from first sub-cmd.
      if PRONOUNS[ln] then
        for i = #sub_commands - 1, 1, -1 do
          local pv, pn = preprocess.natural_language(sub_commands[i])
          if not pv then pv, pn = preprocess.parse(sub_commands[i]) end
          if pn and pn ~= "" then
            ln = pn
            break
          end
        end
      end
      local plan = goal_planner.plan(lv, ln, context)
      if plan and #plan > 0 then
        sub_commands = { last }
      end
    end

    local should_quit = false
    -- BUG-066: Safety limit to prevent hanging on pathological multi-command input
    if #sub_commands > 50 then
      print("Error: Too many commands at once (limit: 50). Try breaking them into smaller groups.")
      goto continue
    end
    
    for _, sub_input in ipairs(sub_commands) do
      -- BUG-084: Drain any active search before processing the next sub-command.
      -- "find a match and light it" — search must complete before "light" runs.
      if search_ok and search_mod and search_mod.is_searching() then
        local drain_limit = 0
        while search_mod.is_searching() and drain_limit < 150 do
          search_mod.tick(context)
          drain_limit = drain_limit + 1
        end
      end

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

      -- BUG-060: Context noun resolution — resolve pronouns and empty nouns
      -- Verbs that operate on the room (no noun expected) are excluded.
      local no_noun_verbs = {
        look = true, feel = true, smell = true, listen = true, taste = true,
        inventory = true, i = true, help = true, time = true, quit = true,
        sleep = true, rest = true, nap = true, wait = true, score = true,
        report_bug = true, injuries = true, injury = true, wounds = true, health = true,
        -- Direction verbs should never inherit a context noun
        north = true, south = true, east = true, west = true,
        up = true, down = true, n = true, s = true, e = true, w = true,
        u = true, d = true, go = true, enter = true, walk = true, run = true,
        climb = true, ascend = true, descend = true,
        -- Drop/put verbs inherit noun correctly from their own grammar
        drop = true,
      }
      if noun ~= "" and PRONOUNS[noun] and context.last_noun then
        noun = context.last_noun
      elseif noun == "" and context.last_noun and not no_noun_verbs[verb] then
        noun = context.last_noun
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

      -- Capture print output for transcript recording (BUG-060 / report bug)
      local old_print = _G.print
      local response_lines = {}
      _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
          parts[i] = tostring(select(i, ...))
        end
        local line = table.concat(parts, "\t")
        response_lines[#response_lines + 1] = line
        old_print(...)
      end

      local handler = context.verbs[verb]
      if handler then
        context.current_verb = verb
        handler(context, noun)
        -- BUG-060: Update last_noun after successful handler with a real noun
        if noun ~= "" and not no_noun_verbs[verb] then
          -- Strip prepositions for context: "in wardrobe" → "wardrobe"
          local bare = noun:match("^%a+%s+(.+)$")
          context.last_noun = bare or noun
        end
      elseif context.parser then
        -- Tier 2 fallback: try embedding-based phrase matching
        local parser_fallback = require("engine.parser")
        local handled = parser_fallback.fallback(context.parser, sub_input, context)
        if not handled then
          -- Tier 2 failed — restore print and skip
          _G.print = old_print
          goto next_sub
        end
      else
        -- No Tier 2 available -- original behaviour
        local question_words = { what = true, where = true, how = true, who = true, why = true }
        if question_words[verb] then
          print("Try 'feel' to explore by touch, or 'look' if you have light. Type 'help' for a full list of commands.")
        else
          print("That's not something you can do here. Try 'look', 'examine', 'take', or type 'help' for a full list.")
        end
      end

      -- Restore print and record transcript entry
      _G.print = old_print
      if #response_lines > 0 then
        local entry = {
          input = sub_input,
          output = table.concat(response_lines, "\n"),
        }
        local transcript = context.transcript
        transcript[#transcript + 1] = entry
        -- Keep only last 50 exchanges
        while #transcript > 50 do
          table.remove(transcript, 1)
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
      -- Player hands (extract IDs from object instances)
      if context.player then
        for i = 1, 2 do
          local hand = context.player.hands[i]
          if hand then
            tick_targets[#tick_targets + 1] = type(hand) == "table" and hand.id or hand
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
            print(msg)
          end
        end
      end

      -- Timed events engine: each command tick = 360 game seconds
      -- (consistent with SLEEP: 10 ticks per game hour = 3600s / 10 = 360s)
      local SECONDS_PER_TICK = 360
      local timer_msgs = fsm_mod.tick_timers(reg, SECONDS_PER_TICK)
      for _, entry in ipairs(timer_msgs) do
        print(entry.message)
        -- Remove spent consumables from player's hands after auto-transition
        if context.player then
          local obj = reg:get(entry.obj_id)
          if obj and obj._state then
            local st = obj.states and obj.states[obj._state]
            if st and st.terminal and st.consumable then
              for i = 1, 2 do
                local hand = context.player.hands[i]
                local hand_id = hand and (type(hand) == "table" and hand.id or hand)
                if hand_id == entry.obj_id then
                  context.player.hands[i] = nil
                end
              end
              if context.current_room then
                context.current_room.contents[#context.current_room.contents + 1] = entry.obj_id
                obj.location = context.current_room.id
              end
            end
          end
        end
      end
    end

    -- Post-command tick (flame countdown, candle burn, etc.)
    if context.on_tick then
      context.on_tick(context)
    end

    -- Injury tick: advance injury FSMs, accumulate damage, check death
    if context.player and context.player.injuries and #context.player.injuries > 0 then
      local inj_ok, injury_mod = pcall(require, "engine.injuries")
      if inj_ok and injury_mod then
        local msgs, died = injury_mod.tick(context.player)
        for _, msg in ipairs(msgs) do
          print(msg)
        end
        if died then
          print("")
          print("Your injuries have overwhelmed you.")
          print("YOU HAVE DIED.")
          context.game_over = true
        end
      end
    end

    -- Game over check (death by poison, etc.)
    if context.game_over then
      print("Game over. Thanks for playing.")
      break
    end

    ::continue::
  end
end

return loop
