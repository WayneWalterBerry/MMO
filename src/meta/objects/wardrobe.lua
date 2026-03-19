return {
    guid = "9c4701d1-4cc4-49e7-9c4a-041e1e37caf1",
    id = "wardrobe",
    name = "a heavy wardrobe",
    keywords = {"wardrobe", "armoire", "closet", "cabinet", "clothes"},
    room_presence = "A towering wardrobe lurks in the corner like a dark sentinel, its doors firmly shut.",
    description = "A towering oak wardrobe, dark as a coffin and nearly as inviting. Its double doors are carved with a pattern of acorns and oak leaves, the craftsmanship fine but worn smooth by generations of hands. The doors are firmly closed. Something inside shifts faintly when you lean against it -- settling wood, or something else.",

    on_feel = "A massive wooden frame, smooth and cold. Carved door handles -- acorns and oak leaves under your fingers.",
    on_smell = "Cedar. Sharp and sweet, even through closed doors.",

    size = 9,
    weight = 60,
    categories = {"furniture", "wooden", "large", "container"},
    room_position = "looms in the far corner like a dark sentinel",
    portable = false,

    surfaces = {
        inside = { capacity = 8, max_item_size = 4, contents = {"wool-cloak", "sack"} },
    },

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {
        open = {
            becomes = "wardrobe-open",
        },
    },
}
