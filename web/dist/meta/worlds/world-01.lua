-- world-01.lua
-- World 1: The Manor
-- Gothic domestic horror. Late medieval manor, 2 AM, isolation, candlelight.
-- See: docs/design/worlds.md (full specification)
-- See: .squad/decisions.md — D-WORLDS-CONCEPT

return {
    guid = "fbfaf0de-c263-4c05-b827-209fac43bb20",
    template = "world",

    id = "world-1",
    name = "The Manor",
    description = "A crumbling gothic estate of cold stone and long shadows. "
              .. "You wake at 2 AM, trapped and alone. The darkness is absolute.",

    starting_room = "start-room",

    levels = {
        1,  -- Level 1: The Awakening (level-01.lua)
    },

    theme = {
        pitch = "Gothic domestic horror. Late medieval manor, 1450s-style. "
             .. "Player wakes imprisoned at 2 AM and must escape.",

        era = "Medieval (1400–1500)",

        aesthetic = {
            materials = {
                "stone", "iron", "wood", "tallow", "wool",
                "leather", "glass", "rope", "wax", "bone",
                "clay", "linen", "brass", "copper", "tin",
            },
            forbidden = {
                "steel", "concrete", "plastic", "neon",
                "electrical", "rubber", "aluminum",
            },
            colors = {
                "ochre", "grey", "brown", "black",
                "cream", "rust", "charcoal", "ivory",
            },
        },

        atmosphere = "Claustrophobic. Player is trapped and must find a way out. "
                  .. "Light is scarce; darkness is the default state. "
                  .. "Sounds are organic — creaking wood, howling wind, "
                  .. "animal calls in the distance, and oppressive silence.",

        mood = "Paranoid. Vulnerable. Every shadow could hide danger. "
            .. "The manor is not hostile — it is indifferent, and that is worse.",

        tone = "Serious. Dark humor is rare and earned. "
            .. "Moments of beauty exist amid the decay.",

        constraints = {
            "No magic. All puzzles use real-world physics.",
            "No NPCs with dialogue (Phase 5+).",
            "No projectile weapons (melee only).",
            "No modern technology (electricity, firearms, etc.).",
            "Scarcity of light is the core mechanic.",
            "Two-hand inventory limits force strategic choices.",
        },

        design_notes = "The Manor is a trap. The player wakes imprisoned in a locked "
                    .. "bedroom at 2 AM. Escaping teaches the game's core systems: "
                    .. "darkness navigation, tool usage, resource scarcity, FSM states. "
                    .. "Each level deepens the mystery — from bedroom to cellar to hallway, "
                    .. "the manor reveals itself slowly, reluctantly.",
    },

    -- Optional: theme subsections (lazy-loaded for designer reference)
    -- Uncomment and populate as theme files are created in src/meta/worlds/themes/
    -- theme_files = {
    --     architecture = "src/meta/worlds/themes/manor-architecture.lua",
    --     creatures    = "src/meta/worlds/themes/manor-creatures.lua",
    --     history      = "src/meta/worlds/themes/manor-history.lua",
    -- },

    mutations = {},
}
