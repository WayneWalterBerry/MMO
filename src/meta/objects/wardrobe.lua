return {
    id = "wardrobe",
    name = "a heavy wardrobe",
    keywords = {"wardrobe", "armoire", "closet", "cabinet", "clothes"},
    description = "A towering oak wardrobe, dark as a coffin and nearly as inviting. Its double doors are carved with a pattern of acorns and oak leaves, the craftsmanship fine but worn smooth by generations of hands. The doors are firmly closed. Something inside shifts faintly when you lean against it — settling wood, or something else.",

    size = 9,
    weight = 60,
    categories = {"furniture", "wooden", "large", "container"},
    portable = false,

    surfaces = {
        inside = { capacity = 8, max_item_size = 4, contents = {"wool-cloak"} },
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
