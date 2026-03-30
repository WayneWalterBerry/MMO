return {
    guid = "{EF762EC2-1C76-4918-B711-7CD70B5B132B}",
    template = "container",

    id = "sorting-bin-nutty",
    material = "plastic",
    keywords = {"nutty bin", "nutty", "nut bin", "gold bin"},
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

    name = "the Nutty bin",
    description = "A big gold plastic bin with a sign that says \"NUTTY\" in bold letters. Drop nutty-flavored chocolate bars in here!",
    room_presence = "A gold bin labeled \"NUTTY\" sits at the end of the belt.",
    on_feel = "Smooth hard plastic. The edges are rounded. It's empty inside.",
    on_smell = "Clean plastic. Waiting for nutty bars!",
    on_listen = "Hollow sound when you tap it. Thunk thunk!",
    on_taste = "You lick the bin. Just plastic! Put chocolate IN it instead!",

    accepts_category = "nutty",

    location = nil,

    initial_state = "empty",
    _state = "empty",

    states = {
        empty = {
            name = "the Nutty bin (empty)",
            description = "A big gold bin labeled \"NUTTY.\" It's empty.",
            on_feel = "Smooth hard plastic. Empty inside.",
        },
        has_correct = {
            name = "the Nutty bin (correct!)",
            description = "The gold bin labeled \"NUTTY\" glows green! Right answer!",
            on_feel = "Smooth plastic. A chocolate bar sits inside. Nice!",
        },
        has_wrong = {
            name = "the Nutty bin (try again!)",
            description = "The gold bin labeled \"NUTTY\" blinks red! Wrong one! Take it out!",
            on_feel = "Smooth plastic. Something's inside but it's the wrong bar!",
        },
    },

    transitions = {
        {
            from = "empty", to = "has_correct", trigger = "correct_sort",
            message = "DING! Green light! That's the right bin! Nice sorting!",
        },
        {
            from = "empty", to = "has_wrong", trigger = "wrong_sort",
            message = "BUZZ! Red light! That's not a nutty flavor. Try again!",
        },
        {
            from = "has_wrong", to = "empty", trigger = "remove_item",
            message = "You take the bar out. Red light off. Try a different bin!",
        },
    },

    mutations = {},
}
