return {
    guid = "{C4306E29-0AB3-44FB-9687-397730D250F2}",
    template = "small-item",

    id = "big-red-button",
    material = "plastic",
    keywords = {"button", "red button", "big red button", "big button"},
    size = 2,
    weight = 1,
    categories = {"interactive", "challenge"},
    portable = false,

    name = "a big red button",
    description = "A shiny red button the size of your fist. It sits on top of the golden stand. It looks like it wants to be pushed!",
    room_presence = "A big shiny red button sits on top of the stand.",
    on_feel = "Smooth and round. It clicks when you press down a little. So fun!",
    on_smell = "Smells like clean plastic. Nothing special.",
    on_listen = "You hear a tiny click when you tap it. Ready to go!",
    on_taste = "You lick the button. Tastes like plastic and fun!",

    location = nil,

    initial_state = "unpressed",
    _state = "unpressed",

    states = {
        unpressed = {
            name = "a big red button",
            description = "A shiny red button the size of your fist. It sits on top of the golden stand. It looks like it wants to be pushed!",
            on_feel = "Smooth and round. It clicks when you press down a little. So fun!",
        },
        pressed = {
            name = "a big red button (pressed)",
            description = "The big red button is pushed down. Confetti is flying everywhere! You did it!",
            on_feel = "The button is pushed down flat. You can feel the click still shaking.",
        },
    },

    transitions = {
        {
            from = "unpressed", to = "pressed", verb = "press",
            aliases = {"push", "hit", "smash", "tap"},
            message = "You press the big red button. BOOM! Confetti shoots from the ceiling! Lights flash! A booming voice says: \"LET THE CHALLENGES BEGIN!\"",
        },
    },

    mutations = {},
}
