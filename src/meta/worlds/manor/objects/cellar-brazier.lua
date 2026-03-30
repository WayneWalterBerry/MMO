-- cellar-brazier.lua — Stationary fire source in the cellar (Phase 3 WAVE-3)
-- Always lit in Level 1; provides fire_source for cooking
-- States: lit (permanent for Level 1)
return {
    guid = "{22b77e90-8407-427a-a272-6b88277ba1fc}",
    template = "furniture",

    id = "cellar-brazier",
    name = "an iron brazier",
    keywords = {"brazier", "iron brazier", "fire", "coals"},
    description = "A squat iron brazier, blackened with soot. Dull orange coals glow in the bowl, radiating steady heat. The iron legs are bolted to the flagstone floor. Ash and cinder drift around its base.",

    material = "iron",
    size = 3,
    weight = 40,
    portable = false,
    not_portable_reason = "The brazier is bolted to the floor. It isn't going anywhere.",
    categories = {"furniture", "metal", "heat source"},

    room_presence = "An iron brazier glows with dull coals, radiating warmth.",
    on_feel = "Rough iron, warm to the touch. The coals glow faintly.",
    on_smell = "Charcoal and ash.",
    on_listen = "A low, patient crackle from the coals. Occasional soft pops as embers shift.",
    on_taste = "You lick the brazier. Hot iron and soot. Not your finest moment.",

    location = nil,

    casts_light = true,
    light_radius = 2,
    provides_tool = "fire_source",
    capabilities = { "fire_source" },

    initial_state = "lit",
    _state = "lit",

    states = {
        lit = {
            name = "an iron brazier",
            description = "A squat iron brazier, blackened with soot. Dull orange coals glow in the bowl, radiating steady heat. The iron legs are bolted to the flagstone floor. Ash and cinder drift around its base.",
            room_presence = "An iron brazier glows with dull coals, radiating warmth.",
            on_feel = "Rough iron, warm to the touch. The coals glow faintly.",
            on_smell = "Charcoal and ash.",
            on_listen = "A low, patient crackle from the coals. Occasional soft pops as embers shift.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 2,
        },
    },

    transitions = {},
    mutations = {},
}
