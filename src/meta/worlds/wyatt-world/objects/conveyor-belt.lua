return {
    guid = "{19AE105D-DE0E-44A6-AF0C-65C321F4B353}",
    template = "furniture",

    id = "conveyor-belt",
    material = "rubber",
    keywords = {"conveyor", "belt", "conveyor belt"},
    size = 8,
    weight = 100,
    categories = {"furniture"},
    portable = false,

    surfaces = {
        top = { capacity = 6, max_item_size = 2, contents = {} },
    },

    name = "a long conveyor belt",
    description = "A long rubber belt rolls through the middle of the room. Chocolate bars in shiny wrappers sit on top, slowly moving along.",
    room_presence = "A conveyor belt runs through the room with chocolate bars on it.",
    on_feel = "Rubber surface, bumpy and warm. It moves slowly under your hand.",
    on_smell = "Rubber and chocolate! The belt smells like a candy factory!",
    on_listen = "A steady humming sound. Whrrrrr. The belt keeps rolling.",
    on_taste = "You lick the conveyor belt. Tastes like rubber. Stick to the chocolate!",

    location = nil,
    mutations = {},
}
