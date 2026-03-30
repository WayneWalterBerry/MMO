-- riddle-arena.lua — The Riddle Arena
-- Riddle solving puzzle. Difficulty: ★★★★

return {
    guid = "08e07f66-a94d-4d35-ab98-f862772ea66b",
    template = "room",

    id = "riddle-arena",
    name = "The Riddle Arena",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    light_level = 2,
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

    instances = {
        { id = "riddle-board-one", type = "Riddle Board One", type_id = "{9FAC1EAA-4132-4040-ACE1-1C4FBE12197A}" },
        { id = "riddle-board-two", type = "Riddle Board Two", type_id = "{8BA39B60-D1A4-4D52-93AC-C2D3CE4E726D}" },
        { id = "riddle-board-three", type = "Riddle Board Three", type_id = "{83B21387-7C76-45F8-9104-F0AE58720737}" },
        { id = "riddle-podium", type = "Riddle Podium", type_id = "{EB791BB6-29FA-49FB-9196-A219CB4F4600}" },
        { id = "arena-clock", type = "Arena Clock", type_id = "{7E9A6F83-931E-4507-8A61-4E6C3F2D7AF0}" },
        { id = "arena-piano", type = "Arena Piano", type_id = "{4169EFC2-C01B-4F0A-BDBA-520D03CA2EFC}" },
        { id = "stage-hole", type = "Stage Hole", type_id = "{80714F5B-258A-417D-8139-6DCE7E4A8764}" },
        { id = "spotlight", type = "Spotlight", type_id = "{B74B8CBC-0F98-41C6-965E-1378E2F4F347}" },
        { id = "riddle-prize-trophy", type = "Riddle Prize Trophy", type_id = "{8275700D-B0C9-416B-858A-7CBE176F67C4}" },
    },

    exits = {
        down = { target = "beast-studio" },
    },

    mutations = {},
}
