-- flatbread.lua — Cooked food item (Phase 3 WAVE-3)
-- Product of cooking grain-handful over a fire source
return {
    guid = "{b20bf751-88f9-44c2-97bf-e2d73cb3aa94}",
    template = "small-item",

    id = "flatbread",
    name = "a round of flatbread",
    keywords = {"flatbread", "bread", "flat bread", "cooked grain"},
    description = "A palm-sized disc of unleavened bread, baked brown and spotted with char marks. Dense, dry, and plain -- but it's food.",

    material = "wax",
    size = 1,
    weight = 0.15,
    portable = true,
    categories = {"small-item", "food", "consumable"},

    on_feel = "Warm, dry, and stiff. The surface is rough with tiny blisters from the heat. It bends slightly before it would snap.",
    on_smell = "Toasted grain and a hint of char. Simple and plain. It smells like survival.",
    on_listen = "Silent. It crackles faintly if flexed.",
    on_taste = "Dry and dense, with a nutty, toasted grain flavor. Plain, but it quiets the ache in your stomach.",

    location = nil,

    food = {
        edible = true,
        nutrition = 10,
        effects = {
            { type = "heal", amount = 1 },
            { type = "narrate", message = "Dry and dense, but it quiets your stomach." },
        },
    },

    mutations = {},
}
