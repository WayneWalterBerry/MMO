-- silver-dagger.lua — Tool/weapon/treasure with effects pipeline (Crypt, Sarcophagus 2)
-- Decision: D-EFFECTS-PIPELINE, D-INJURY001
-- Verbs: stab, cut, slash (self-infliction injury sources)
--
-- Effect routing (all paths via effects.process):
--   stab self  → on_stab  → inflict_injury(bleeding, damage=8)
--   cut self   → on_cut   → inflict_injury(minor-cut, damage=4)
--   slash self → on_slash  → inflict_injury(bleeding, damage=6)
return {
    guid = "{2155adb3-839c-451b-8078-892e839013b2}",
    template = "small-item",

    id = "silver-dagger",
    material = "silver",
    keywords = {"dagger", "silver dagger", "knife", "blade", "weapon", "ceremonial dagger"},
    size = 2,
    weight = 0.5,
    categories = {"weapon", "tool", "metal", "treasure", "sharp"},
    portable = true,

    -- Effects pipeline flag (D-EFFECTS-PIPELINE) — all effect declarations
    -- on this object are structured tables routed through effects.process().
    effects_pipeline = true,

    name = "a silver dagger",
    description = "A silver dagger, tarnished but sharp. The blade is leaf-shaped and double-edged, about eight inches long. The hilt is wrapped in wire and set with a small dark stone -- garnet, perhaps. Symbols are etched along the blade -- the same recurring motifs from the altar and walls. This is a ceremonial weapon, not a battlefield one. But it would still cut.",
    on_feel = "Cold metal, smooth. The blade has edges -- sharp, even after centuries. The wire-wrapped hilt fits your hand well. The pommel stone is smooth and cool. Lighter than an iron knife but well-balanced.",
    on_smell = "Tarnished silver. A faint, sweet metallic scent -- different from the iron of the crowbar or the brass of the key.",
    on_listen = "A faint ring when tapped -- silver sings.",

    location = nil,

    provides_tool = {"cutting_edge", "injury_source", "ritual_blade"},

    on_stab = {
        damage = 8,
        injury_type = "bleeding",
        description = "You drive the silver dagger into your %s. Blood wells up immediately.",
        pain_description = "A sharp, deep pain radiates from the wound.",
        -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
        pipeline_effects = {
            { type = "inflict_injury", injury_type = "bleeding",
              source = "silver-dagger", damage = 8,
              message = "You drive the silver dagger into your %s. Blood wells up immediately." },
        },
    },
    on_cut = {
        damage = 4,
        injury_type = "minor-cut",
        description = "You draw the dagger's edge across your %s. A thin red line appears.",
        pain_description = "A stinging line of fire across the skin.",
        -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
        pipeline_effects = {
            { type = "inflict_injury", injury_type = "minor-cut",
              source = "silver-dagger", damage = 4,
              message = "You draw the dagger's edge across your %s. A thin red line appears." },
        },
    },
    on_slash = {
        damage = 6,
        injury_type = "bleeding",
        description = "You slash the dagger across your %s. The wound opens wide and bleeds freely.",
        pain_description = "A burning, tearing sensation.",
        -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
        pipeline_effects = {
            { type = "inflict_injury", injury_type = "bleeding",
              source = "silver-dagger", damage = 6,
              message = "You slash the dagger across your %s. The wound opens wide and bleeds freely." },
        },
    },

    -- GOAP prerequisites (for planner) — warns hints per D-EFFECTS-PIPELINE §3.6
    prerequisites = {
        stab = { warns = { "injury", "bleeding" } },
        cut = { warns = { "injury", "minor-cut" } },
        slash = { warns = { "injury", "bleeding" } },
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
