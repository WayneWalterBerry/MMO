-- glass-shard.lua — Sharp fragile weapon with effects pipeline
-- Decision: D-EFFECTS-PIPELINE, D-INJURY001
-- Verbs: cut (self-infliction injury source)
--
-- Effect routing (all paths via effects.process):
--   cut self  → on_cut  → inflict_injury(minor-cut, damage=3)
--   feel      → on_feel_effect → inflict_injury(minor-cut, damage=1)
return {
    guid = "{1ffa70d5-f81e-49ef-9514-952e8e6b92b8}",
    template = "small-item",
    id = "glass-shard",
    name = "a glass shard",
    keywords = {"shard", "glass", "glass shard", "sliver", "fragment"},
    description = "A long, wicked sliver of mirror glass. One side still holds a ghost of a reflection -- a fragment of a face, perhaps yours. The edge is razor-sharp.",

    on_feel = "SHARP! The edge bites into your finger before you realize what you're holding. Smooth glass on the flat side, razor-keen at the edge.",
    -- Pipeline-routed via effects.process() — contact injury on feel
    on_feel_effect = {
        type = "inflict_injury",
        injury_type = "minor-cut",
        source = "glass-shard",
        location = "hand",
        damage = 1,
        message = "The edge bites into your finger before you realize what you're holding.",
        pipeline_routed = true,
    },
    on_taste = "DO NOT. Seriously. Glass and blood is not a flavor profile anyone should explore.",

    size = 1,
    weight = 0.1,
    portable = true,
    material = "glass",

    -- Effects pipeline flag (D-EFFECTS-PIPELINE) — all effect declarations
    -- on this object are structured tables routed through effects.process().
    effects_pipeline = true,

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"sharp", "fragile", "reflective"},

    provides_tool = {"cutting_edge", "injury_source"},

    on_cut = {
        damage = 3,
        injury_type = "minor-cut",
        description = "You press the glass edge against your %s. The shard bites into skin.",
        pain_description = "A clean, sharp sting.",
        self_damage = true,
        -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
        pipeline_effects = {
            { type = "inflict_injury", injury_type = "minor-cut",
              source = "glass-shard", damage = 3,
              message = "You press the glass edge against your %s. The shard bites into skin." },
        },
    },

    -- GOAP prerequisites (for planner) — warns hints per D-EFFECTS-PIPELINE §3.6
    prerequisites = {
        cut = { warns = { "injury", "minor-cut" } },
        feel = { warns = { "injury", "minor-cut" } },
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
