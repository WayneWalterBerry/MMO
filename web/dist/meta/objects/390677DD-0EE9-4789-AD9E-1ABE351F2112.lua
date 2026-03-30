return {
    guid = "{390677DD-0EE9-4789-AD9E-1ABE351F2112}",
    template = "container",

    id = "sorting-bin-fruity",
    material = "plastic",
    keywords = {"fruity bin", "fruity", "fruit bin", "purple bin"},
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

    name = "the Fruity bin",
    description = "A big purple plastic bin with a sign that says \"FRUITY\" in bold letters. Drop fruity-flavored chocolate bars in here!",
    room_presence = "A purple bin labeled \"FRUITY\" sits at the end of the belt.",
    on_feel = "Smooth hard plastic. The edges are rounded. It's empty inside.",
    on_smell = "Clean plastic. No smell yet. Waiting for chocolate!",
    on_listen = "Hollow sound when you tap it. Bong bong!",
    on_taste = "You lick the bin. Plastic! Not nearly as good as chocolate!",

    accepts_category = "fruity",

    location = nil,

    initial_state = "empty",
    _state = "empty",

    states = {
        empty = {
            name = "the Fruity bin (empty)",
            description = "A big purple bin labeled \"FRUITY.\" It's empty.",
            on_feel = "Smooth hard plastic. Empty inside.",
        },
        has_correct = {
            name = "the Fruity bin (correct!)",
            description = "The purple bin labeled \"FRUITY\" glows green! You sorted it right!",
            on_feel = "Smooth plastic. There's a chocolate bar inside. The bin feels warm from the green light.",
        },
        has_wrong = {
            name = "the Fruity bin (try again!)",
            description = "The purple bin labeled \"FRUITY\" blinks red! That bar doesn't go here!",
            on_feel = "Smooth plastic. Something's inside but the red light says it's wrong!",
        },
    },

    transitions = {
        {
            from = "empty", to = "has_correct", trigger = "correct_sort",
            message = "DING! The green light turns on! That's the right bin!",
        },
        {
            from = "empty", to = "has_wrong", trigger = "wrong_sort",
            message = "BUZZ! The red light blinks! Oops! That flavor doesn't go here. Take it out and try a different bin!",
        },
        {
            from = "has_wrong", to = "empty", trigger = "remove_item",
            message = "You take the bar out of the bin. The red light turns off. Try another bin!",
        },
    },

    mutations = {},
}
