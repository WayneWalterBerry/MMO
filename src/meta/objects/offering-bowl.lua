-- offering-bowl.lua — Puzzle 012 trigger container (Deep Cellar)
-- States: empty → offering-placed
return {
    guid = "b73ejs7q-4e55-486f-a171-c35f34123456",
    template = "container",

    id = "offering-bowl",
    material = "ceramic",
    keywords = {"bowl", "offering bowl", "stone bowl", "basin", "dish", "offering"},
    size = 2,
    weight = 2,
    categories = {"container", "stone", "small"},
    portable = true,

    name = "a stone offering bowl",
    description = "A shallow bowl of dark ceramic, sitting on the altar's surface. The inside is smooth and clean -- almost too clean for this dusty chamber. A faint circular stain marks the center, as if something once sat here. Symbols are painted around the rim in faded gold.",
    on_feel = "Smooth ceramic, cool. Shallow -- your palm fits inside. The rim has raised bumps -- painted symbols, worn almost flat.",
    on_smell = "Clean ceramic. No residue.",

    location = nil,

    surfaces = {
        inside = {
            capacity = 1, max_item_size = 2, weight_capacity = 5,
            contents = {},
            accessible = true,
        },
    },

    initial_state = "empty",
    _state = "empty",

    states = {
        empty = {
            name = "a stone offering bowl",
            description = "A shallow bowl of dark ceramic, sitting on the altar's surface. The inside is smooth and clean -- almost too clean for this dusty chamber. A faint circular stain marks the center, as if something once sat here. Symbols are painted around the rim in faded gold.",
            on_feel = "Smooth ceramic, cool. Shallow -- your palm fits inside. The rim has raised bumps -- painted symbols, worn almost flat.",
            on_smell = "Clean ceramic. No residue.",
        },

        ["offering-placed"] = {
            name = "an offering bowl with contents",
            description = "The bowl holds an offering. The gold symbols around the rim seem to catch the light differently -- or is that your imagination?",
            on_feel = "The object sits in the bowl. The ceramic feels slightly warm -- warmer than it should be.",
            on_smell = "A faint scent of incense, as if triggered by the offering.",
        },
    },

    transitions = {
        {
            from = "empty", to = "offering-placed", verb = "put",
            aliases = {"place", "offer"},
            message = "You place the object in the offering bowl. For a moment, nothing happens. Then -- did the symbols on the rim just flicker? A sound like a sigh echoes through the chamber, and you hear stone grinding against stone somewhere to the west.",
        },
    },

    mutations = {},
}
