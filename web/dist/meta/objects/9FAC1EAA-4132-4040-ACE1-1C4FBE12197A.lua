return {
    guid = "{9FAC1EAA-4132-4040-ACE1-1C4FBE12197A}",
    template = "furniture",

    id = "riddle-board-one",
    material = "wood",
    keywords = {"riddle board", "first riddle", "board one", "riddle 1", "hands riddle"},
    size = 5,
    weight = 20,
    categories = {"furniture", "readable", "challenge"},
    portable = false,

    name = "the first riddle board",
    description = "A big colorful board with a riddle in bright letters:\n\"I have hands but cannot clap.\nI have a face but cannot smile.\nWhat am I?\"\nLook around the room for the answer!",
    room_presence = "The first riddle board shows a riddle in bright letters.",
    on_feel = "Smooth painted wood. The letters are carved in. You can feel each word!",
    on_smell = "Paint and wood. Like an art project!",
    on_listen = "The board is quiet. But the answer might make sounds!",
    on_taste = "You lick the board. Paint! Read the riddle instead!",

    riddle_answer = "clock",

    location = nil,

    initial_state = "unsolved",
    _state = "unsolved",

    states = {
        unsolved = {
            name = "the first riddle board",
            description = "A riddle board with bright letters: \"I have hands but cannot clap. I have a face but cannot smile. What am I?\"",
            on_feel = "Smooth painted wood with carved letters.",
        },
        solved = {
            name = "the first riddle board (SOLVED!)",
            description = "The first riddle board glows green! The answer was: A CLOCK! You got it!",
            on_feel = "Warm wood. The green light makes it feel toasty!",
        },
    },

    transitions = {
        {
            from = "unsolved", to = "solved", trigger = "riddle_solved",
            message = "DING DING DING! The board lights up GREEN! The answer is a CLOCK! Nice thinking!",
        },
    },

    mutations = {},
}
