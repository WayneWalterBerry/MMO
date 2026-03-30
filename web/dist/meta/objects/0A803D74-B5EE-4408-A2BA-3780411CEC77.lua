return {
    guid = "{0A803D74-B5EE-4408-A2BA-3780411CEC77}",
    template = "furniture",

    id = "money-table-two",
    material = "wood",
    keywords = {"table two", "second table", "table 2", "middle table"},
    size = 5,
    weight = 30,
    categories = {"furniture"},
    portable = false,

    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {} },
    },

    name = "the second counting table",
    description = "A sturdy table with another stack of play money on it. A card in front tells you how much this stack is worth.",
    room_presence = "The second counting table has a stack of play money on it.",
    on_feel = "Smooth wood. Another stack of money and a card sit on top.",
    on_smell = "Wood and paper money. Smells like you're getting rich!",
    on_listen = "Quiet. The money just sits there looking important.",
    on_taste = "You lick the table. Yep, still wood. Count the money instead!",

    location = nil,
    mutations = {},
}
