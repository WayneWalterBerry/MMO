return {
    guid = "{74EA982A-B33E-4F8B-8AA4-5D6A44BE8A0A}",
    template = "container",

    id = "sorting-bin-crunchy",
    material = "plastic",
    keywords = {"crunchy bin", "crunchy", "crunch bin", "red bin"},
    size = 4,
    weight = 5,
    categories = {"container", "challenge"},
    portable = false,

    container = true,
    openable = false,
    accessible = true,
    capacity = 3,
    weight_capacity = 5,
    max_item_size = 2,

    name = "the Crunchy bin",
    description = "A big red plastic bin with a sign that says \"CRUNCHY\" in bold letters. Drop crunchy-flavored chocolate bars in here!",
    room_presence = "A red bin labeled \"CRUNCHY\" sits at the end of the belt.",
    on_feel = "Smooth hard plastic. Rounded edges. Empty inside.",
    on_smell = "Clean plastic. Needs a crunchy bar!",
    on_listen = "Hollow clonk sound when you tap it.",
    on_taste = "You lick the bin. Not crunchy at all. Just plastic! Ha!",

    accepts_category = "crunchy",

    location = nil,

    initial_state = "empty",
    _state = "empty",

    states = {
        empty = {
            name = "the Crunchy bin (empty)",
            description = "A big red bin labeled \"CRUNCHY.\" It's empty.",
            on_feel = "Smooth hard plastic. Empty inside.",
        },
        has_correct = {
            name = "the Crunchy bin (correct!)",
            description = "The red bin labeled \"CRUNCHY\" glows green! Nailed it!",
            on_feel = "Smooth plastic. A crunchy bar sits inside. Perfect!",
        },
        has_wrong = {
            name = "the Crunchy bin (try again!)",
            description = "The red bin labeled \"CRUNCHY\" blinks red! Wrong bar!",
            on_feel = "Smooth plastic. That bar isn't crunchy. Take it out!",
        },
    },

    transitions = {
        {
            from = "empty", to = "has_correct", trigger = "correct_sort",
            message = "DING! Green light! Yes! That one IS crunchy!",
        },
        {
            from = "empty", to = "has_wrong", trigger = "wrong_sort",
            message = "BUZZ! Red light! That's not crunchy. Nope! Try again!",
        },
        {
            from = "has_wrong", to = "empty", trigger = "remove_item",
            message = "You pull the wrong bar out. Red light off. Keep trying!",
        },
    },

    mutations = {},
}
