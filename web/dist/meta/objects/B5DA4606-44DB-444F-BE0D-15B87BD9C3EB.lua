return {
    guid = "{B5DA4606-44DB-444F-BE0D-15B87BD9C3EB}",
    template = "furniture",

    id = "ingredient-shelf",
    material = "metal",
    keywords = {"shelf", "shelves", "ingredient shelf", "ingredients"},
    size = 5,
    weight = 20,
    categories = {"furniture"},
    portable = false,

    surfaces = {
        top = { capacity = 8, max_item_size = 2, contents = {} },
    },

    name = "the food shelf",
    description = "A big metal shelf loaded with burger stuff. Buns, patties, cheese, lettuce, tomato -- everything you need to build the Beast Burger!",
    room_presence = "A shelf is loaded with burger stuff.",
    on_feel = "Cool metal bars. The shelf is sturdy and full of soft foam food.",
    on_smell = "A mix of all the fake food smells. Bread, cheese, tomato! Fun!",
    on_listen = "A soft clinking when you touch the shelf. The food pieces are quiet.",
    on_taste = "You lick the shelf. Metal! The food is more fun to taste!",

    location = nil,
    mutations = {},
}
