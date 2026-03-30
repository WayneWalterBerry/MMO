-- world.lua — Wyatt's World
-- A MrBeast-inspired challenge course for kids. E-rated.
-- See: projects/wyatt-world/plan.md

return {
    guid = "6f129cce-4798-446d-9cd8-198b36f04ef0",
    template = "world",

    id = "wyatt-world",
    name = "Wyatt's World",
    rating = "E",  -- Everyone (engine-enforced: no combat/harm verbs)
    content_root = "worlds/wyatt-world",
    start_level = "level-01",
    description = "A MrBeast challenge course! Seven rooms. Seven puzzles. "
               .. "Can you solve them all and win the grand prize?",

    starting_room = "beast-studio",

    levels = {
        1,  -- Level 1: The Challenge Course
    },

    theme = {
        pitch = "Kid-friendly puzzle challenge. Modern setting, bright and fun. "
             .. "Player competes in a game-show-style obstacle course.",

        era = "Modern (2020s)",

        aesthetic = {
            materials = {
                "plastic", "foam", "rubber", "metal", "wood",
                "glass", "fabric", "cardboard", "paint", "tape",
            },
            forbidden = {
                "bone", "blood", "rust", "decay",
                "rot", "corpse", "poison",
            },
            colors = {
                "red", "blue", "green", "yellow",
                "orange", "purple", "pink", "white",
            },
        },

        atmosphere = "Bright, energetic, and exciting. Every room is a new challenge. "
                  .. "The vibe is a game show set — colorful, loud, and fun.",

        mood = "Excited. Competitive. Every puzzle feels like winning a prize. "
            .. "Failure is funny, not scary.",

        tone = "Playful. Encouraging. Kid-friendly humor throughout.",

        constraints = {
            "No combat or violence of any kind.",
            "No poison, injury, or harm mechanics.",
            "No scary or disturbing content.",
            "All puzzles use logic, observation, and creativity.",
            "Encouraging feedback on wrong answers.",
            "E-rating enforced at engine level.",
        },

        design_notes = "Wyatt's World is a MrBeast challenge course. "
                    .. "Seven rooms, each with a unique puzzle. Solve them all "
                    .. "to win the grand prize. Designed for ages 6+ with "
                    .. "simple vocabulary and encouraging feedback.",
    },

    mutations = {},
}
