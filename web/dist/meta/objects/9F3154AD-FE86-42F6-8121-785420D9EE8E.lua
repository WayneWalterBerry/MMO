return {
    guid = "{9F3154AD-FE86-42F6-8121-785420D9EE8E}",
    template = "container",

    id = "found-it-box",
    material = "cardboard",
    keywords = {"box", "found it box", "found it", "drop box"},
    size = 4,
    weight = 3,
    categories = {"container", "challenge"},
    portable = false,

    container = true,
    openable = false,
    accessible = true,
    capacity = 3,
    weight_capacity = 10,
    max_item_size = 3,

    name = "the Found It! box",
    description = "A big cardboard box by the door with \"FOUND IT!\" written in bright orange letters. Drop the three fake items in here to win!",
    room_presence = "A box labeled \"FOUND IT!\" sits by the door.",
    on_feel = "Cardboard walls. The box is empty and waiting for the three fakes!",
    on_smell = "Fresh cardboard. Like a new delivery box!",
    on_listen = "Hollow boxy sound when you tap it. Thump!",
    on_taste = "Tastes like cardboard. Fill it with fakes, not your tongue!",

    location = nil,
    mutations = {},
}
