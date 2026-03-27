-- cooked-rat-meat.lua — Cooked food item (Phase 3 WAVE-3)
-- Product of cooking a dead rat over a fire source
return {
    guid = "{971e819c-8ad2-4f6e-934c-48236d7c5660}",
    template = "small-item",

    id = "cooked-rat-meat",
    name = "a piece of cooked rat meat",
    keywords = {"cooked rat", "rat meat", "cooked meat", "meat"},
    description = "A small piece of dark, charred meat. The fur has been singed away, leaving browned flesh scored with grill marks. It smells better than it looks.",

    material = "meat",
    size = 1,
    weight = 0.3,
    portable = true,
    categories = {"small-item", "food", "consumable"},

    on_feel = "Warm and greasy. The surface is firm where it charred, softer underneath. Small bones poke through the flesh.",
    on_smell = "Smoky and rich, with an underlying gamey musk. Not appetizing by choice, but your stomach disagrees.",
    on_listen = "Silent. It cools with a faint tick as the fat contracts.",
    on_taste = "Gamey and tough, with a smoky char. The flavor is strong -- wild, not farmed. Edible, if you don't think about it.",

    location = nil,

    food = {
        edible = true,
        nutrition = 15,
        effects = {
            { type = "heal", amount = 3 },
            { type = "narrate", message = "The rat meat is gamey but filling." },
        },
    },

    mutations = {},
}
