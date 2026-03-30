return {
    guid = "{0D5E44BB-D5E6-4191-9ADF-84841DDEC5C2}",
    template = "furniture",

    id = "bookshelf",
    material = "wood",
    keywords = {"bookshelf", "shelf", "book shelf", "books"},
    size = 6,
    weight = 40,
    categories = {"furniture"},
    portable = false,

    name = "a wooden bookshelf",
    description = "A tall bookshelf with lots of books on it. Most of them look totally normal. Regular bookshelf! ...Or is it?",
    room_presence = "A tall bookshelf full of books stands against the wall.",
    on_feel = "Smooth wood shelves. Books of different sizes line up neatly.",
    on_smell = "Old books and wood. Smells like a library!",
    on_listen = "Quiet. Books don't make much noise. Unless you drop one!",
    on_taste = "You lick the bookshelf. Wood! Read the books instead!",

    is_fake = false,

    surfaces = {
        top = { capacity = 4, max_item_size = 2, contents = {} },
    },

    location = nil,
    mutations = {},
}
