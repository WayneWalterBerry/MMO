-- level-01.lua — MrBeast's Challenge Arena
-- Level 1 for Wyatt's World. Seven rooms, seven puzzles.

return {
    guid = "c284b536-e542-4429-8d6a-ad0a572fd869",
    template = "level",

    number = 1,
    name = "MrBeast's Challenge Arena",
    description = "Seven rooms. Seven challenges. Can you solve them all?",

    intro = {
        title = "WYATT'S WORLD — MrBeast Challenge Arena",
        subtitle = "A Text Adventure for Wyatt",
        narrative = {
            "You walk through a giant golden door.",
            "A huge room with flashing lights stretches out in front of you.",
            "A booming voice says: Welcome, Wyatt! You are Player #1!",
        },
        help = "Type 'help' for commands. Try 'look' to see the room!",
    },

    rooms = {
        "beast-studio",
        "feastables-factory",
        "money-vault",
        "beast-burger-kitchen",
        "last-to-leave",
        "riddle-arena",
        "grand-prize-vault",
    },

    start_room = "beast-studio",

    completion = {
        {
            type = "all_puzzles_solved",
            message = "You did it! You solved every challenge! "
                   .. "MrBeast is SO impressed!",
        },
    },

    boundaries = {
        entry = { "beast-studio" },
        exit = {},
    },

    restricted_objects = {},
}
