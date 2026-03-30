return {
    guid = "{8BA39B60-D1A4-4D52-93AC-C2D3CE4E726D}",
    template = "furniture",

    id = "riddle-board-two",
    material = "wood",
    keywords = {"riddle board", "second riddle", "board two", "riddle 2", "keys riddle"},
    size = 5,
    weight = 20,
    categories = {"furniture", "readable", "challenge"},
    portable = false,

    name = "the second riddle board",
    description = "A big colorful board with a riddle in bright letters:\n\"I am full of keys but cannot open any door.\nWhat am I?\"\nFind the answer somewhere in this room!",
    room_presence = "The second riddle board shows another riddle.",
    on_feel = "Smooth painted wood. The letters are carved deep. Easy to feel!",
    on_smell = "Paint and wood. Like the first board!",
    on_listen = "Quiet. But the answer might be making music somewhere!",
    on_taste = "You lick the board. Still paint! Try solving the riddle!",

    riddle_answer = "piano",

    location = nil,

    initial_state = "unsolved",
    _state = "unsolved",

    states = {
        unsolved = {
            name = "the second riddle board",
            description = "A riddle board: \"I am full of keys but cannot open any door. What am I?\"",
            on_feel = "Smooth painted wood with carved letters.",
        },
        solved = {
            name = "the second riddle board (SOLVED!)",
            description = "The second riddle board glows green! The answer was: A PIANO! Awesome!",
            on_feel = "Warm wood with a green glow. Two down!",
        },
    },

    transitions = {
        {
            from = "unsolved", to = "solved", trigger = "riddle_solved",
            message = "DING DING DING! The board lights up GREEN! A PIANO has keys! Brilliant!",
        },
    },

    mutations = {},
}
