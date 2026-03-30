return {
    guid = "{63032BC1-E9B5-4B41-9E29-BC268291EE8B}",
    template = "furniture",

    id = "money-table-one",
    material = "wood",
    keywords = {"table one", "first table", "table 1", "left table"},
    size = 5,
    weight = 30,
    categories = {"furniture"},
    portable = false,

    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {} },
    },

    name = "the first counting table",
    description = "A sturdy table with a stack of play money on it. A card in front of the stack tells you how much it's worth.",
    room_presence = "The first counting table has a stack of play money on it.",
    on_feel = "Smooth wood. There's a stack of paper money and a card on top.",
    on_smell = "Wood and fresh paper. Like a bank!",
    on_listen = "The table is quiet. Just stacks of money waiting to be counted.",
    on_taste = "You lick the table. Wood flavor. Money tastes better. Just kidding!",

    location = nil,
    mutations = {},
}
