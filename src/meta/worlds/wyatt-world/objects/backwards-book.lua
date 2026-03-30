return {
    guid = "{A9C3354C-0E29-4397-8688-785C6CD9EDBD}",
    template = "small-item",

    id = "backwards-book",
    material = "paper",
    keywords = {"book", "backwards book", "weird book", "strange book"},
    size = 1,
    weight = 1,
    categories = {"small", "readable", "fake"},
    portable = true,

    name = "a book on the shelf",
    description = "A thick book with a red cover. The title says: \"SERUTNEVDA NI GNITIRW\" ...wait. That's written BACKWARDS! If you read it the right way, it says: \"WRITING IN ADVENTURES.\" This book is FAKE!",
    room_presence = "A red book sits on the bookshelf with a strange title.",
    on_feel = "Smooth cover. Normal weight. But flip it around -- the title feels raised and backwards!",
    on_smell = "Paper and ink. Smells like a regular book.",
    on_listen = "Pages flip normally. Nothing sounds wrong.",
    on_taste = "Tastes like paper. The cover is a little dusty! Achoo!",

    is_fake = true,
    fake_reason = "The title is written backwards.",

    location = nil,
    mutations = {},
}
