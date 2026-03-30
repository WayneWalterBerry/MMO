-- beast-studio.lua — MrBeast's Challenge Studio (Hub Room)
-- The central hub. Six doors lead to six challenges.

return {
    guid = "91d01b7c-58a4-4fca-827f-bd5a2b77dc65",
    template = "room",

    id = "beast-studio",
    name = "MrBeast's Challenge Studio",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    light_level = 2,
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

    instances = {
        { id = "welcome-sign", type = "Welcome Sign", type_id = "{8B0A933D-509C-4BE2-86AA-C6F1F53F7F75}" },
        { id = "golden-podium", type = "Golden Podium", type_id = "{23A2835F-B665-4B2C-86B7-CAEE47E93BDF}",
            on_top = {
                { id = "big-red-button", type = "Big Red Button", type_id = "{C4306E29-0AB3-44FB-9687-397730D250F2}" },
            },
        },
        { id = "confetti-cannon", type = "Confetti Cannon", type_id = "{EE2FD8B1-35AF-44D9-BC3B-F56EEE24D733}" },
        { id = "scoreboard", type = "Scoreboard", type_id = "{56B019FA-F6E1-4807-9B9C-796D8A64FCC6}" },
        { id = "giant-screen", type = "Giant Screen", type_id = "{72F80C85-CE94-467C-9B01-1936CE0F06C4}" },
        { id = "speaker", type = "Speaker", type_id = "{0ABBA5B8-D00A-4B09-9C83-EE8B81620ABA}" },
        { id = "mrbeast-banner", type = "MrBeast Banner", type_id = "{CFEE0931-55E0-4DBC-88EF-80FC7A939309}" },
        { id = "camera", type = "Camera", type_id = "{3A38D1DE-B878-461E-8728-92B636401E32}" },
        { id = "studio-confetti", type = "Studio Confetti", type_id = "{F2086EAF-236E-461D-A850-4458570ED4FB}" },
        { id = "challenge-rules-sign", type = "Challenge Rules Sign", type_id = "{9FFB251E-0F73-46B1-A7BD-C0530E73555D}" },
        { id = "tv-screen", type = "TV Screen", type_id = "{7C66F17F-F075-4884-B5DE-D9B45574E93F}" },
    },

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
