-- level-01.lua
-- Level 1: The Awakening
-- Defines metadata, room membership, completion criteria, and boundaries.
-- See: docs/levels/01/level-01-intro.md (CBG's master plan)
-- See: docs/design/levels/level-design-considerations.md (design rules)

return {
    guid = "c4a71e20-8f3d-4b61-a9c5-2d7e1f03b8a6",
    template = "level",

    number = 1,
    name = "The Awakening",
    description = "The player wakes at 2 AM in a locked bedroom of a medieval manor, "
              .. "trapped and confused. Through exploration they must learn the "
              .. "fundamental systems — sensory interaction in darkness, tool usage, "
              .. "spatial manipulation, resource management — to escape the bedroom, "
              .. "navigate the cellars beneath, and emerge into the manor proper.",

    -- Welcome text shown at game start (read by main.lua and game-adapter.lua)
    intro = {
        title = "THE BEDROOM — A Text Adventure",
        subtitle = "V1 Playtest",
        narrative = {
            "You wake with a start. The darkness is absolute.",
            "You can feel rough linen beneath your fingers.",
        },
        help = "Type 'help' for commands. Try 'feel' to explore the darkness.",
    },

    -- All rooms that belong to this level.
    -- Order follows the critical-path narrative arc.
    rooms = {
        "start-room",       -- Act I:  The Awakening (Bedroom)
        "cellar",           -- Act II: Descent
        "storage-cellar",   -- Act II: Descent
        "deep-cellar",      -- Act III: The Deep Secret
        "crypt",            -- Act III: The Deep Secret (optional)
        "hallway",          -- Act IV: Emergence
        "courtyard",        -- Alternate path (optional, via window escape)
    },

    start_room = "start-room",

    ---------------------------------------------------------------------------
    -- Completion criteria
    -- The engine can check these to determine if the player has "beaten"
    -- this level. Multiple conditions are OR'd (any one triggers completion).
    ---------------------------------------------------------------------------
    completion = {
        -- Primary: player reaches the hallway via the deep cellar staircase
        {
            type = "reach_room",
            room = "hallway",
            from = "deep-cellar",
            message = "You have escaped the cellars. The manor awaits.",
        },
        -- Alternate: player reaches the hallway via courtyard re-entry
        {
            type = "reach_room",
            room = "hallway",
            from = "courtyard",
            message = "You have found your way into the manor. The cellars are behind you now.",
        },
    },

    ---------------------------------------------------------------------------
    -- Boundaries — entry and exit points for this level
    ---------------------------------------------------------------------------
    boundaries = {
        entry = {
            "start-room",  -- Player spawns here at game start
        },
        exit = {
            -- The hallway's NORTH exit leads to Level 2
            {
                room = "hallway",
                exit_direction = "north",
                target_level = 2,
            },
        },
    },

    ---------------------------------------------------------------------------
    -- Objects that must NOT cross to the next level
    -- Per design rule: removal must be diegetic (natural puzzle/task).
    -- Wayne to populate as Level 2 puzzles are designed.
    -- See: docs/design/levels/level-design-considerations.md §1
    ---------------------------------------------------------------------------
    restricted_objects = {
        -- Example (commented out until Level 2 design confirms):
        -- "brass-key",   -- consumed by lock-and-surrender puzzle at hallway exit
        -- "iron-key",    -- consumed by lock-and-surrender puzzle at hallway exit
    },
}
