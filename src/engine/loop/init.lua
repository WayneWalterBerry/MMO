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

-- Tier 4: context window for recent interaction memory
local cw_ok, context_window = pcall(require, "engine.parser.context")
if not cw_ok then context_window = nil end

-- run(context)
-- context fields:
--   registry     -- live registry instance
--   current_room -- room table (must have .id, .name, .description)
--   verbs        -- table of { [verb_string] = handler_function }
--   ui           -- (optional) engine.ui module instance
--   on_quit      -- optional callback fired before exit
-- BUG-060: Pronouns that resolve to the last referenced noun
-- Tier 4: Added discovery reference patterns
local PRONOUNS = {
  it = true, them = true, that = true, this = true, those = true,
  ["the same"] = true, ["the same thing"] = true,
  ["thing i found"] = true, ["the thing i found"] = true,
  ["one i found"] = true, ["the one i found"] = true,
  ["what i found"] = true, ["item i found"] = true,
  ["thing i discovered"] = true, ["one i discovered"] = true,
  ["the one i discovered"] = true,
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

  if not context.headless then
    print("Type 'look' to look around. Type 'report bug' to report issues. Type 'quit' to exit.")
    if context.ui and context.ui.is_enabled() then
      print("Scroll: /up  /down  /bottom")
    end
    print("")
  end

  while true do
    -- Update status bar if UI is active
    if context.ui and context.ui.is_enabled() and context.update_status then
      context.update_status(context)
    end

    -- ═══ CONSCIOUSNESS GATE ═══
    -- If unconscious, skip input and run forced ticks until wake or death
    local player = context.player
    if player and player.consciousness
       and player.consciousness.state == "unconscious" then
      local inj_ok2, inj_mod2 = pcall(require, "engine.injuries")

      -- Tick injuries during unconsciousness
      if inj_ok2 and inj_mod2 then
        local msgs, died = inj_mod2.tick(player)
        for _, msg in ipairs(msgs or {}) do
          print(msg)
        end
        if died then
          -- Death during unconsciousness
          local cause = player.consciousness.cause or "your injuries"
          local death_messages = {
            ["blow-to-head"] = "You never wake up. The bleeding was too much.",
            ["poison-gas"]   = "The gas fills your lungs. You stop breathing.",
            ["knockout"]     = "Darkness takes you, and this time it doesn't let go.",
          }
          print("")
          print(death_messages[cause] or "You never wake up. Your injuries were too much.")
          print("")
          print("YOU HAVE DIED.")
          context.game_over = true
          if context.headless then io.write("---END---\n"); io.flush() end
          break
        end
      end

      -- Decrement wake timer
      player.consciousness.wake_timer = player.consciousness.wake_timer - 1

      -- Check wake-up
      if player.consciousness.wake_timer <= 0 then
        -- Transition: waking → conscious
        local cause = player.consciousness.cause or "unknown"
        local wake_narrations = {
          ["blow-to-head"] = "Your eyes flutter open. Your head throbs with a dull, persistent ache. Stars still dance at the edges of your vision.",
          ["poison-gas"]   = "You gasp and cough. Your throat is raw. The poison has run its course.",
          ["knockout"]     = "Pain drags you back to consciousness. Every muscle aches.",
        }
        print("")
        print(wake_narrations[cause] or "You slowly regain consciousness.")

        -- Health status on wake
        if inj_ok2 and inj_mod2 then
          local health = inj_mod2.compute_health(player)
          if health < player.max_health * 0.5 then
            print("You feel weak. Something is very wrong.")
          elseif health < player.max_health * 0.75 then
            print("You feel battered but alive.")
          end
        end
        print("")

        -- Reset consciousness state
        player.consciousness.state = "conscious"
        player.consciousness.wake_timer = 0
        player.consciousness.cause = nil
        player.consciousness.unconscious_since = nil
      else
        -- Still unconscious — emit a brief sensory fragment
        if context.headless then io.write("---END---\n"); io.flush() end
      end
      goto continue
    end

    -- ═══ UNCONSCIOUS INPUT REJECTION ═══
    -- (This is a safety check — normally the gate above handles it)

    -- If search is active and no input yet, process one search step
    local search_ok, search_mod = pcall(require, "engine.search")
    if search_ok and search_mod and search_mod.is_searching() then
      if _G.TRACE then io.stderr:write("[TRACE] search tick (active)\n") end
      -- Safety net: limit consecutive search ticks to prevent infinite spin
      local search_tick_limit = 0
      while search_mod.is_searching() and search_tick_limit < 200 do
        local continue_search = search_mod.tick(context)
        search_tick_limit = search_tick_limit + 1
        if _G.TRACE and search_tick_limit % 10 == 0 then
          io.stderr:write("[TRACE] search tick #" .. search_tick_limit .. " result: " .. tostring(continue_search) .. "\n")
        end
        if not continue_search then break end
      end
      if search_mod.is_searching() then
        -- Search exceeded tick limit — force abort
        if _G.TRACE then io.stderr:write("[TRACE] search force-aborted after " .. search_tick_limit .. " ticks\n") end
        search_mod.abort(context)
      end
      -- Search completed or aborted — fall through to normal input
    end

    -- Read input (UI-aware, headless, or fallback)
    local input
    if context.ui and context.ui.is_enabled() then
      input = context.ui.input()
    elseif context.headless then
      input = io.read()
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

    -- BUG-105/106: Direct transform for common help/confusion phrases.
    -- Safety net: preprocess.natural_language() handles these patterns, but
    -- the live game reportedly hangs on them. This early bailout guarantees
    -- they never reach Tier 2 regardless of pipeline state or input encoding.
    do
      local lc = trimmed:lower()
      if lc == "what do i do" or lc == "what now"
          or lc == "now what" or lc == "what can i do"
          or lc == "what should i do" then
        trimmed = "help"
      end
    end

    -- Multi-command splitting: commas, semicolons, "then" (Issue #1)
    -- BUG-066: Added safety limits to prevent infinite loops or hangs
    local command_parts = preprocess.split_commands(trimmed)

    -- Global safety net: detect CPU-bound hangs in verb handlers.
    -- BUG-105/106/116/117/118: makes it architecturally impossible to hang.
    local _cmd_deadline = os.clock() + 2  -- 2-second timeout
    debug.sethook(function()
      if os.clock() > _cmd_deadline then
        debug.sethook()
        error("__COMMAND_TIMEOUT__")
      end
    end, "", 500000)

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

    -- Issue #16: Detect conditional clauses in compound commands.
    -- "if", "when", "unless" etc. signal clauses we can't handle yet.
    -- Trim everything from the conditional onward and give ONE helpful message.
    if #sub_commands > 1 then
      local conditional_idx = nil
      for ci = 1, #sub_commands do
        local lc = sub_commands[ci]:lower():match("^%s*(.-)%s*$")
        if lc:match("^if%s+") or lc:match("^when%s+") or lc:match("^unless%s+")
            or lc:match("^once%s+") or lc:match("^after%s+you%s+")
            or lc:match("^in%s+case%s+") then
          conditional_idx = ci
          break
        end
      end
      if conditional_idx then
        -- Keep everything before the conditional; drop the rest
        local kept = {}
        for ci = 1, conditional_idx - 1 do
          kept[#kept + 1] = sub_commands[ci]
        end
        if #kept == 0 then
          -- The very first part was conditional — nothing actionable
          print("I can only handle one action at a time. Try the first step on its own.")
          goto continue
        end
        sub_commands = kept
        -- Queue a single helpful message after the kept commands execute
        sub_commands[#sub_commands + 1] = "__conditional_trimmed__"
      end
    end

    local should_quit = false
    -- BUG-066: Safety limit to prevent hanging on pathological multi-command input
    if #sub_commands > 50 then
      print("Error: Too many commands at once (limit: 50). Try breaking them into smaller groups.")
      goto continue
    end
    
    for _, sub_input in ipairs(sub_commands) do
      -- Issue #16: sentinel from conditional trimming
      if sub_input == "__conditional_trimmed__" then
        print("I understood the first part, but I can only do one thing at a time. Try each step separately.")
        goto next_sub
      end

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
      if _G.TRACE then io.stderr:write("[TRACE] parsing: " .. tostring(sub_input) .. "\n") end
      local verb, noun = preprocess.natural_language(sub_input)
      if _G.TRACE then io.stderr:write("[TRACE] natural_language => verb=" .. tostring(verb) .. " noun=" .. tostring(noun) .. "\n") end
      if not verb then
        verb, noun = preprocess.parse(sub_input)
        if _G.TRACE then io.stderr:write("[TRACE] parse fallback => verb=" .. tostring(verb) .. " noun=" .. tostring(noun) .. "\n") end
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
        report_bug = true, injuries = true, injury = true, wounds = true, health = true, appearance = true,
        -- Direction verbs should never inherit a context noun
        north = true, south = true, east = true, west = true,
        up = true, down = true, n = true, s = true, e = true, w = true,
        u = true, d = true, go = true, enter = true, walk = true, run = true,
        climb = true, ascend = true, descend = true,
        -- Tier 4: "back"/"return" handle their own noun semantics
        back = true, ["return"] = true,
        -- Drop/put verbs inherit noun correctly from their own grammar
        drop = true,
        -- BUG-105b: Bare "examine" (no noun) should prompt the player, not
        -- silently fill in a stale context noun that may fail to resolve.
        examine = true, x = true, inspect = true,
      }
      if noun ~= "" and PRONOUNS[noun] and context.last_noun then
        -- Tier 4: discovery references resolve from context window
        if context_window and (noun == "thing i found" or noun == "the thing i found"
            or noun == "one i found" or noun == "the one i found"
            or noun == "what i found" or noun == "item i found"
            or noun == "thing i discovered" or noun == "one i discovered"
            or noun == "the one i discovered") then
          local disc = context_window.last_discovery()
          if disc then
            noun = disc.id
          else
            noun = context.last_noun
          end
        else
          noun = context.last_noun
        end
      elseif noun == "" and not no_noun_verbs[verb] then
        -- Tier 4: bare noun fallback — try last_noun, then context window
        if context.last_noun then
          noun = context.last_noun
        elseif context_window then
          local ctx_obj = context_window.peek()
          if ctx_obj then
            noun = ctx_obj.id
          end
        end
      end

      -- Prepositional parsing: strip "with Y" for verbs that auto-find tools
      if verb == "light" or verb == "ignite" or verb == "burn" then
        local clean_noun = noun:match("^(.-)%s+with%s+.+$")
        if clean_noun and clean_noun ~= "" then noun = clean_noun end
      end

      -- Tier 3: goal-oriented prerequisite planning
      if goal_planner then
        if _G.TRACE then io.stderr:write("[TRACE] GOAP plan: verb=" .. verb .. " noun=" .. noun .. "\n") end
        local goap_ok, plan_or_err = pcall(goal_planner.plan, verb, noun, context)
        if not goap_ok then
          if type(plan_or_err) == "string" and plan_or_err:find("__COMMAND_TIMEOUT__") then
            print("That took longer than expected. Try a simpler command, or type 'help'.")
            _G.print = old_print or _G.print
            debug.sethook()
            goto next_sub
          end
        end
        local plan = goap_ok and plan_or_err or nil
        if _G.TRACE then io.stderr:write("[TRACE] GOAP result: " .. tostring(plan and #plan or "nil") .. " steps\n") end
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
        if _G.TRACE then io.stderr:write("[TRACE] dispatch handler: " .. verb .. "(" .. noun .. ")\n") end
        context.current_verb = verb
        local h_ok, h_err = pcall(handler, context, noun)
        if not h_ok then
          if type(h_err) == "string" and h_err:find("__COMMAND_TIMEOUT__") then
            print("That took longer than expected. Try a simpler command, or type 'help'.")
          elseif _G.TRACE then
            io.stderr:write("[TRACE] handler error: " .. tostring(h_err) .. "\n")
          end
          _G.print = old_print
          debug.sethook()
          goto next_sub
        end
        if _G.TRACE then io.stderr:write("[TRACE] handler complete: " .. verb .. "\n") end
        -- BUG-060: Update last_noun after successful handler with a real noun
        if noun ~= "" and not no_noun_verbs[verb] then
          -- Strip prepositions for context: "in wardrobe" → "wardrobe"
          local bare = noun:match("^%a+%s+(.+)$")
          context.last_noun = bare or noun
        end
      elseif context.parser then
        -- Tier 2 fallback: try embedding-based phrase matching
        if _G.TRACE then io.stderr:write("[TRACE] Tier 2 fallback entry: " .. sub_input .. "\n") end
        local parser_fallback = require("engine.parser")
        local t2_ok, t2_result = pcall(parser_fallback.fallback, context.parser, sub_input, context)
        if not t2_ok then
          if type(t2_result) == "string" and t2_result:find("__COMMAND_TIMEOUT__") then
            print("That took longer than expected. Try a simpler command, or type 'help'.")
          end
          _G.print = old_print
          debug.sethook()
          goto next_sub
        end
        local handled = t2_result
        if _G.TRACE then io.stderr:write("[TRACE] Tier 2 fallback result: " .. tostring(handled) .. "\n") end
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

    -- Clear the command timeout hook
    debug.sethook()

    if should_quit then
      if context.on_quit then context.on_quit() end
      print("Goodbye.")
      if context.headless then io.write("---END---\n"); io.flush() end
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
    -- Issue #29: Skip if game_over already set (e.g., sleep bleedout death)
    if not context.game_over
       and context.player and context.player.injuries and #context.player.injuries > 0 then
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
      if context.headless then io.write("---END---\n"); io.flush() end
      break
    end

    -- Headless response delimiter: marks end of output for this command
    if context.headless then io.write("---END---\n"); io.flush() end

    ::continue::
  end
end

return loop
