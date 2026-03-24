return {
    guid = "{ecdccb0f-134d-436f-9f1c-d53911ac1445}",
    template = "sheet",
    id = "wool-cloak",
    name = "a moth-eaten wool cloak",
    keywords = {"cloak", "wool cloak", "cape", "mantle", "garment", "wool", "clothing", "apparel"},
    description = "A long wool cloak the color of a bruise -- deep plum fading to grey at the edges. Moths have made lace of the hem, and one clasp is missing, but it still carries a faded sense of authority. Whoever wore this was either important or wanted to seem so.",

    on_feel = "Thick, warm wool. Heavy. The hem is tattered from moths, and one clasp is missing -- but the warmth is real.",
    on_smell = "Old wool, cedar from the wardrobe, and a distant ghost of someone else's perfume.",

    size = 3,
    weight = 3,
    categories = {"fabric", "warm", "wearable"},
    portable = true,
    material = "wool",

    wear = {
        slot = "back",
        layer = "outer",
        provides_warmth = true,
        wear_quality = "normal",
    },

    -- One-shot flavor text (event_output system — fires once, engine nils it out)
    event_output = {
        on_wear = "I need to get better outfits. I look like a peasant.",
    },

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
