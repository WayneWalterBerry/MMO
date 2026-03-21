-- incense-burner.lua — Static environmental storytelling object (Deep Cellar)
return {
    guid = "{2fce1fb5-94ad-44f7-9036-4332a62d3405}",
    template = "container",

    id = "incense-burner",
    material = "brass",
    keywords = {"incense burner", "burner", "censer", "incense", "brass burner", "brazier"},
    size = 2,
    weight = 1.5,
    categories = {"container", "metal", "small"},
    portable = true,

    name = "a brass incense burner",
    description = "A small brass incense burner, its bowl dark with carbon and half-filled with grey ash. The lid is perforated with geometric patterns -- stars and hexagons -- that once let fragrant smoke spiral upward. The brass is tarnished to a dull greenish-brown. Whatever ceremony last used this was a long time ago.",
    on_feel = "Ornate brass, cold. The pierced lid has sharp geometric cutouts -- stars and hexagons. Inside: fine, silky ash. Weightless between your fingers.",
    on_smell = "Old incense -- the ghost of sandalwood and myrrh. The ash itself smells of nothing, but the brass retains the memory.",
    on_listen = "The ash whispers when disturbed -- a soft sifting sound.",

    location = nil,

    surfaces = {
        inside = {
            capacity = 1, max_item_size = 1, weight_capacity = 0.5,
            contents = {},
            accessible = true,
        },
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
