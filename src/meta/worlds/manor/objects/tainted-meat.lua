return {
    guid = "{8aefbd0d-112c-4209-b124-e38475ad5e38}",
    template = "small-item",

    id = "tainted-meat",
    name = "a lump of tainted meat",
    keywords = {"tainted meat", "meat", "poisoned meat", "tainted", "bad meat"},
    description = "A dark, discolored chunk of raw meat with a faint greenish sheen. It smells wrong — chemical, not just rotten.",

    material = "flesh",
    size = "small",
    weight = 0.3,
    portable = true,

    on_feel = "Cold and slick. The surface has an oily film that won't wipe off.",
    on_smell = "A sweet chemical reek beneath the raw meat smell. Unmistakably wrong.",
    on_listen = "Silent.",
    on_taste = "DO NOT. The smell alone warns you — this meat would kill.",

    -- Poisoned food
    food = {
        category = "meat",
        raw = true,
        edible = true,
        cookable = false,
        on_eat = {
            inflict = "food-poisoning",
            message = "The meat burns going down. Within seconds, your gut twists violently.",
        },
    },

    mutations = {},
}
