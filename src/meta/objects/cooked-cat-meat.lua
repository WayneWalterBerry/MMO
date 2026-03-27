-- cooked-cat-meat.lua — Cooked food item (Phase 3 WAVE-3)
-- Product of cooking a dead cat over a fire source
return {
    guid = "{91d7e699-edd7-4fd5-9fcd-7a9df9871571}",
    template = "small-item",

    id = "cooked-cat-meat",
    name = "a piece of cooked cat meat",
    keywords = {"cooked cat", "cat meat", "cooked meat", "meat"},
    description = "A portion of pale, lean meat, roasted until the edges have crisped brown. The fur burned away cleanly. It looks almost like rabbit.",

    material = "meat",
    size = 1,
    weight = 0.4,
    portable = true,
    categories = {"small-item", "food", "consumable"},

    on_feel = "Warm and slightly oily. The meat is lean and firm, with a thin crispy layer where it seared against the heat.",
    on_smell = "Clean roasted meat, mild and almost pleasant. Less pungent than you expected.",
    on_listen = "Silent.",
    on_taste = "Surprisingly tender. Lean, mild, faintly sweet. You try not to think about what it was.",

    location = nil,

    food = {
        edible = true,
        nutrition = 20,
        effects = {
            { type = "heal", amount = 4 },
            { type = "narrate", message = "The cat meat is surprisingly tender." },
        },
    },

    mutations = {},
}
