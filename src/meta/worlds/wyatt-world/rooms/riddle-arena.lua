-- riddle-arena.lua — The Riddle Arena
-- Riddle solving puzzle. Difficulty: ★★★★

return {
    guid = "08e07f66-a94d-4d35-ab98-f862772ea66b",
    template = "room",

    id = "riddle-arena",
    name = "The Riddle Arena",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    keywords = {"riddle arena", "arena", "riddle room", "stage"},
    description = "Bright spotlights shine down on a small stage. "
               .. "Three big boards stand in a row with riddles in colorful letters. "
               .. "A screen above flashes: Solve all three riddles to win!",
    short_description = "A game show stage with three riddle boards.",

    goal = { verb = "examine", noun = "board", label = "solve the three riddles" },

    on_feel = "The stage floor is smooth wood under your feet. "
           .. "Warm spotlights shine on your face.",

    on_smell = "It smells clean, like a brand new stage. A little dusty too.",

    on_listen = "You hear a game show jingle playing and the crowd cheering!",

    instances = {},

    exits = {
        down = { target = "beast-studio" },
    },

    mutations = {},
}
