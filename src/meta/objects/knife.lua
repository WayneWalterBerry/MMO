-- knife.lua — Small weapon/tool with effects pipeline
-- Decision: D-EFFECTS-PIPELINE, D-INJURY001
-- Verbs: stab, cut (self-infliction injury sources)
--
-- Effect routing (all paths via effects.process):
--   stab self → on_stab → inflict_injury(bleeding, damage=5)
--   cut self  → on_cut  → inflict_injury(minor-cut, damage=3)
return {
    guid = "{b0c650c6-497a-440c-a83a-545ee8789284}",
    template = "small-item",

    id = "knife",
    name = "a small knife",
    keywords = {"knife", "small knife", "shiv", "paring knife"},
    description = "A small knife with a bone handle and a blade no longer than your finger. The edge is still keen -- it nicks the air when you turn it. The kind of knife used for peeling apples, cutting twine, or less wholesome things.",

    on_feel = "A bone handle, smooth and cold. The blade -- SHARP. Leather wrapping on the grip. Handle one end, blade the other. Mind which is which.",
    on_smell = "Oiled metal and old leather.",

    size = 1,
    weight = 0.3,
    categories = {"small", "tool", "weapon", "sharp", "metal"},
    portable = true,
    material = "steel",

    -- Effects pipeline flag (D-EFFECTS-PIPELINE) — all effect declarations
    -- on this object are structured tables routed through effects.process().
    effects_pipeline = true,

    -- Multi-capability tool: provides both cutting and injury capabilities.
    -- The engine resolves which capability to use by verb context:
    --   CUT <object> WITH knife  → cutting_edge
    --   CUT SELF WITH knife      → injury_source
    --   PRICK SELF WITH knife    → injury_source
    provides_tool = {"cutting_edge", "injury_source"},
    on_tool_use = {
        consumes_charge = false,
        use_message = "You grip the bone handle and draw the blade.",
    },

    on_stab = {
        damage = 5,
        injury_type = "bleeding",
        description = "You stab the knife into your %s. It hurts more than you expected.",
        pain_description = "A blunt, throbbing pain. The blade is not as sharp as a dagger.",
        -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
        pipeline_effects = {
            { type = "inflict_injury", injury_type = "bleeding",
              source = "knife", damage = 5,
              message = "You stab the knife into your %s. It hurts more than you expected." },
        },
    },
    on_cut = {
        damage = 3,
        injury_type = "minor-cut",
        description = "You nick your %s with the knife. A shallow cut — it stings.",
        pain_description = "A thin sting, like a paper cut but deeper.",
        -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
        pipeline_effects = {
            { type = "inflict_injury", injury_type = "minor-cut",
              source = "knife", damage = 3,
              message = "You nick your %s with the knife. A shallow cut — it stings." },
        },
    },

    -- GOAP prerequisites (for planner) — warns hints per D-EFFECTS-PIPELINE §3.6
    prerequisites = {
        stab = { warns = { "injury", "bleeding" } },
        cut = { warns = { "injury", "minor-cut" } },
    },

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nThe edge catches the light. It could cut almost anything -- including you, if you were desperate enough."
    end,

    mutations = {},
}
