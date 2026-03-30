return {
    guid = "{211076C8-3A5B-4777-A9EA-80415B57EE37}",
    template = "container",

    id = "sorting-bin-creamy",
    material = "plastic",
    keywords = {"creamy bin", "creamy", "cream bin", "blue bin"},
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

    name = "the Creamy bin",
    description = "A big blue plastic bin with a sign that says \"CREAMY\" in bold letters. Drop creamy-flavored chocolate bars in here!",
    room_presence = "A blue bin labeled \"CREAMY\" sits at the end of the belt.",
    on_feel = "Smooth hard plastic. Rounded edges. Empty inside.",
    on_smell = "Clean plastic. Ready for creamy bars!",
    on_listen = "Hollow bong sound when you tap it.",
    on_taste = "You lick the bin. Plastic flavor! Not creamy at all!",

    accepts_category = "creamy",

    location = nil,

    initial_state = "empty",
    _state = "empty",

    states = {
        empty = {
            name = "the Creamy bin (empty)",
            description = "A big blue bin labeled \"CREAMY.\" It's empty.",
            on_feel = "Smooth hard plastic. Empty inside.",
        },
        has_correct = {
            name = "the Creamy bin (correct!)",
            description = "The blue bin labeled \"CREAMY\" glows green! You got it!",
            on_feel = "Smooth plastic. There's a bar inside. The light feels warm!",
        },
        has_wrong = {
            name = "the Creamy bin (try again!)",
            description = "The blue bin labeled \"CREAMY\" blinks red! Not that one!",
            on_feel = "Smooth plastic. Wrong bar inside. Take it out!",
        },
    },

    transitions = {
        {
            from = "empty", to = "has_correct", trigger = "correct_sort",
            message = "DING! Green light! Correct! That one IS creamy!",
        },
        {
            from = "empty", to = "has_wrong", trigger = "wrong_sort",
            message = "BUZZ! Red light! That's not creamy. Try another bin!",
        },
        {
            from = "has_wrong", to = "empty", trigger = "remove_item",
            message = "You grab the bar back out. Red light off. Try again!",
        },
    },

    mutations = {},
}
