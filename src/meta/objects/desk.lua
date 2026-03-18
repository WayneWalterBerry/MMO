return {
    template = "furniture",
    id = "desk",
    name = "a heavy oak desk",
    keywords = {"desk", "table", "oak desk", "drawer", "writing desk"},
    description = "A massive oak writing desk, scarred by years of use. Ink stains bloom across the surface like dark continents. A single drawer sits closed at the front, its brass handle tarnished green.",

    size = 8,
    weight = 50,
    portable = false,
    material = "wood",

    categories = {"furniture", "wooden"},

    surfaces = {
        top = {
            capacity = 6,
            max_item_size = 4,
            weight_capacity = 30,
            contents = {},
        },
        inside = {
            capacity = 5,
            max_item_size = 2,
            weight_capacity = 15,
            accessible = false,
            contents = {},
        },
        underneath = {
            capacity = 3,
            max_item_size = 2,
            weight_capacity = 20,
            contents = {},
        },
    },

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nThe drawer is closed."
    end,

    mutations = {
        open = {
            becomes = "desk-open",
        },
    },
}
