-- engine/verbs/helpers/core.lua
-- Core helper utilities and shared dependencies.

local M = {}

M.fsm_mod = require("engine.fsm")
M.presentation = require("engine.ui.presentation")
M.preprocess = require("engine.parser.preprocess")
M.traverse_effects = require("engine.traverse_effects")
M.effects = require("engine.effects")
M.materials = require("engine.materials")

-- Tier 4: Context window for recent interaction memory
local cw_ok, context_window = pcall(require, "engine.parser.context")
if not cw_ok then context_window = nil end
M.context_window = context_window

-- Tier 5: Fuzzy noun resolution (material, property, partial name, typo tolerance)
local fz_ok, fuzzy = pcall(require, "engine.parser.fuzzy")
if not fz_ok then fuzzy = nil end
M.fuzzy = fuzzy

-- Constants (authoritative source: engine/ui/presentation.lua)
M.GAME_SECONDS_PER_REAL_SECOND = M.presentation.GAME_SECONDS_PER_REAL_SECOND
M.GAME_START_HOUR = M.presentation.GAME_START_HOUR
M.DAYTIME_START = M.presentation.DAYTIME_START
M.DAYTIME_END = M.presentation.DAYTIME_END

-- Presentation helpers (authoritative source: engine/ui/presentation.lua)
M.get_game_time = M.presentation.get_game_time
M.is_daytime = M.presentation.is_daytime
M.format_time = M.presentation.format_time
M.time_of_day_desc = M.presentation.time_of_day_desc

-- Light system (authoritative source: engine/ui/presentation.lua)
M.get_light_level = M.presentation.get_light_level
M.has_some_light = M.presentation.has_some_light

-- Vision check (authoritative source: engine/ui/presentation.lua)
M.vision_blocked_by_worn = M.presentation.vision_blocked_by_worn

-- Returns flat list of all object IDs the player is carrying
-- (hands + held bag contents + worn items + worn bag contents)
-- Authoritative implementation in engine/ui/presentation.lua
M.get_all_carried_ids = M.presentation.get_all_carried_ids

-- Hand object resolver: returns object table from hand slot.
function M.hobj(hand, reg)
    if type(hand) == "table" then return hand end
    if type(hand) == "string" then return reg:get(hand) end
    return nil
end

return M
