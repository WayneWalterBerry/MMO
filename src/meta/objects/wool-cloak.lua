return {
    id = "wool-cloak",
    name = "a moth-eaten wool cloak",
    keywords = {"cloak", "wool cloak", "cape", "mantle", "garment", "wool"},
    description = "A long wool cloak the color of a bruise — deep plum fading to grey at the edges. Moths have made lace of the hem, and one clasp is missing, but it still carries a faded sense of authority. Whoever wore this was either important or wanted to seem so.",

    on_feel = "Thick, warm wool. Heavy. The hem is tattered from moths, and one clasp is missing — but the warmth is real.",
    on_smell = "Old wool, cedar from the wardrobe, and a distant ghost of someone else's perfume.",

    size = 3,
    weight = 3,
    categories = {"fabric", "warm", "wearable"},
    portable = true,
    wearable = true,

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {
        tear = {
            becomes = nil,
            spawns = {"cloth", "cloth"},
        },
    },
}
