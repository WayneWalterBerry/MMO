-- cooked-wolf-meat.lua — Cooked food item (Phase 4 WAVE-1)
-- Product of cooking raw wolf-meat over a fire source
return {
    guid = "{58ab2833-46cd-4e16-b0db-38132ce83884}",
    template = "small-item",

    id = "cooked-wolf-meat",
    name = "a piece of cooked wolf meat",
    keywords = {"cooked wolf", "wolf meat", "cooked wolf meat", "cooked meat", "meat"},
    description = "A thick piece of wolf meat, seared dark on the outside. Juices pool where the fat has rendered. It smells rich and gamey — better than anything else you've found down here.",

    material = "meat",
    size = 1,
    weight = 0.6,
    portable = true,
    categories = {"small-item", "food", "consumable"},

    on_feel = "Warm and firm. The charred surface is rough, the inside softer where the juices run. Greasy fingers.",
    on_smell = "Rich, smoky, and deeply gamey. Rendered fat and char. Your stomach growls.",
    on_listen = "Silent. The meat cools with faint ticks as the fat sets.",
    on_taste = "Gamey and rich, with a deep smoky char. Tough but satisfying. Wild meat — the best meal you've had in this place.",

    location = nil,

    food = {
        edible = true,
        nutrition = 35,
        effects = {
            { type = "heal", amount = 8 },
            { type = "narrate", message = "The wolf meat is tough but filling. Warmth spreads through your chest." },
        },
    },

    mutations = {},
}
