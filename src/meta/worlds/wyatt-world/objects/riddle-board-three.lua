return {
    guid = "{83B21387-7C76-45F8-9104-F0AE58720737}",
    template = "furniture",

    id = "riddle-board-three",
    material = "wood",
    keywords = {"riddle board", "third riddle", "board three", "riddle 3", "bigger riddle"},
    size = 5,
    weight = 20,
    categories = {"furniture", "readable", "challenge"},
    portable = false,

    name = "the third riddle board",
    description = "A big colorful board with a riddle in bright letters:\n\"The more you take from me, the bigger I get.\nWhat am I?\"\nThe answer is somewhere in this room!",
    room_presence = "The third riddle board shows the trickiest riddle yet.",
    on_feel = "Smooth painted wood. The carved letters feel deep. This one is tricky!",
    on_smell = "Paint and wood. Same as the others.",
    on_listen = "Quiet. Think hard! The answer might be hiding in plain sight!",
    on_taste = "You lick the board. Paint! Solve the riddle instead!",

    riddle_answer = "hole",

    location = nil,

    initial_state = "unsolved",
    _state = "unsolved",

    states = {
        unsolved = {
            name = "the third riddle board",
            description = "A riddle board: \"The more you take from me, the bigger I get. What am I?\"",
            on_feel = "Smooth painted wood with carved letters.",
        },
        solved = {
            name = "the third riddle board (SOLVED!)",
            description = "The third riddle board glows green! The answer was: A HOLE! All three solved!",
            on_feel = "Warm wood with a green glow. All three boards are lit!",
        },
    },

    transitions = {
        {
            from = "unsolved", to = "solved", trigger = "riddle_solved",
            message = "DING DING DING! GREEN LIGHT! A HOLE gets bigger when you take from it! You solved all three! AMAZING!",
        },
    },

    mutations = {},
}
