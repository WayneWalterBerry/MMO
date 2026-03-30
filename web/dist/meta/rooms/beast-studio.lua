-- beast-studio.lua — MrBeast's Challenge Studio (Hub Room)
-- The central hub. Six doors lead to six challenges.

return {
    guid = "91d01b7c-58a4-4fca-827f-bd5a2b77dc65",
    template = "room",

    id = "beast-studio",
    name = "MrBeast's Challenge Studio",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    keywords = {"studio", "challenge studio", "hub", "beast studio"},
    description = "You stand in a huge bright room with flashing lights. "
               .. "Upbeat music thumps from speakers on the walls. "
               .. "Six colorful doors surround you, each one a different color.",
    short_description = "A giant, colorful game show studio.",

    goal = { verb = "go", noun = "north", label = "pick a challenge room" },

    on_feel = "The floor is smooth and shiny under your feet. "
           .. "Cool air blows from vents above you.",

    on_smell = "It smells like new paint and popcorn. Nice!",

    on_listen = "Upbeat music plays. You hear confetti cannons pop!",

    instances = {},

    exits = {
        north = { target = "feastables-factory" },
        south = { target = "money-vault" },
        east  = { target = "beast-burger-kitchen" },
        west  = { target = "last-to-leave" },
        up    = { target = "riddle-arena" },
        down  = { target = "grand-prize-vault" },
    },

    mutations = {},
}
