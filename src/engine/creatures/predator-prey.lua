-- engine/creatures/predator-prey.lua
-- Predator-prey subsystem: prey detection, predator reactions, source_filter
-- evaluation.  Stub created during WAVE-0 module split (Phase 2).
--
-- WAVE-2 will move the following into this module:
--   - Prey scanning: iterate nearby creatures, match against diet/prey_tags
--   - Predator reaction triggers: aggression drive spike when prey detected
--   - source_filter evaluation: filter stimuli by source creature type
--   - Hunt/stalk behavior scoring integration
--
-- Ownership: Bart (Architecture Lead)

local M = {}

---------------------------------------------------------------------------
-- detect_prey(context, predator, helpers) -> prey_list
-- Scans nearby rooms for creatures matching predator's diet/prey_tags.
-- Stub: returns empty list until WAVE-2 populates this.
---------------------------------------------------------------------------
function M.detect_prey(context, predator, helpers)
    return {}
end

---------------------------------------------------------------------------
-- evaluate_source_filter(creature, stimulus, filter) -> bool
-- Checks whether a stimulus source matches the creature's source_filter
-- criteria (e.g., "only react to prey-type creatures").
-- Stub: returns true (accept all) until WAVE-2 populates this.
---------------------------------------------------------------------------
function M.evaluate_source_filter(creature, stimulus, filter)
    return true
end

---------------------------------------------------------------------------
-- predator_reaction(context, predator, prey_list, helpers) -> messages[]
-- Produces behavior/drive changes when a predator detects prey.
-- Stub: returns empty messages until WAVE-2 populates this.
---------------------------------------------------------------------------
function M.predator_reaction(context, predator, prey_list, helpers)
    return {}
end

return M
