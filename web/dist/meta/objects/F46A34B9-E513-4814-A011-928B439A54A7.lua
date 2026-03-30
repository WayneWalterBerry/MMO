return {
    guid = "{F46A34B9-E513-4814-A011-928B439A54A7}",
    template = "furniture",

    id = "money-table-three",
    material = "wood",
    keywords = {"table three", "third table", "table 3", "right table"},
    size = 5,
    weight = 30,
    categories = {"furniture"},
    portable = false,

    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {} },
    },

    name = "the third counting table",
    description = "A sturdy table with the last stack of play money. A card in front tells you the value of this stack.",
    room_presence = "The third counting table has a stack of play money on it.",
    on_feel = "Smooth wood. The last stack of money and its card are on top.",
    on_smell = "Wood and paper. The whole room smells like a treasure vault!",
    on_listen = "Quiet as a bank vault. Just money waiting to be counted.",
    on_taste = "You lick the table. Still wood! Go count the money already!",

    location = nil,
    mutations = {},
}
