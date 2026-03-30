-- cheese.lua — Food item (WAVE-5 Track 5A)
-- States: fresh → stale → spoiled
-- Bait for rats and bats; edible consumable
return {
    guid = "{6236981b-d89f-42df-93e7-b806f0a3dd0c}",
    template = "small-item",

    id = "cheese",
    material = "wax",
    keywords = {"cheese", "wedge", "food"},
    size = 1,
    weight = 0.3,
    categories = {"small-item", "food", "consumable"},
    portable = true,

    name = "a wedge of cheese",
    description = "A wedge of hard yellow cheese, slightly crumbly at the edges. A rind of pale wax coats the outside, cracked where it has dried.",
    room_presence = "A wedge of cheese sits here.",
    on_feel = "Firm and waxy. The rind is smooth, but the cut face is slightly oily and crumbles under your thumb.",
    on_smell = "Sharp and tangy -- unmistakably cheese. A sour, salty bite underneath.",
    on_listen = "Silent.",
    on_taste = "Sharp, salty, rich. Crumbly on the tongue. Satisfying.",

    location = nil,

    food = {
        edible = true,
        nutrition = 20,
        bait_value = 3,
        bait_targets = {"rat", "bat"},
    },

    initial_state = "fresh",
    _state = "fresh",

    states = {
        fresh = {
            name = "a wedge of cheese",
            description = "A wedge of hard yellow cheese, slightly crumbly at the edges. A rind of pale wax coats the outside, cracked where it has dried.",
            room_presence = "A wedge of cheese sits here.",
            on_feel = "Firm and waxy. The rind is smooth, but the cut face is slightly oily and crumbles under your thumb.",
            on_smell = "Sharp and tangy -- unmistakably cheese. A sour, salty bite underneath.",
            on_taste = "Sharp, salty, rich. Crumbly on the tongue. Satisfying.",
            timed_events = {
                { event = "transition", delay = 10800, to_state = "stale" },
            },
        },

        stale = {
            name = "a dried-out wedge of cheese",
            description = "A wedge of cheese, going dry and hard at the edges. The cut face has darkened to a dull amber. Still edible, but not appetizing.",
            room_presence = "A dried-out wedge of cheese sits here.",
            on_feel = "Hard and dry. The surface has lost its oiliness -- it feels chalky under your fingers.",
            on_smell = "Still cheesy, but fading. A faint sourness creeps in.",
            on_taste = "Bland and rubbery. Edible, but barely.",
            timed_events = {
                { event = "transition", delay = 7200, to_state = "spoiled" },
            },
        },

        spoiled = {
            name = "a moldy wedge of cheese",
            description = "A moldy, green-spotted lump that was once cheese. White fuzz and dark veins of mold cover most of the surface. It is well past eating.",
            room_presence = "A moldy lump of something organic festers here.",
            on_feel = "Soft and slimy. The mold is fuzzy and damp under your fingers. Revolting.",
            on_smell = "An aggressive, sour stink. Ammonia and rot. Definitely off.",
            on_taste = "You gag. That is NOT food anymore.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "fresh", to = "stale", trigger = "auto",
            condition = "timer_expired",
            message = "The cheese has dried out at the edges. It is still edible, but losing its appeal.",
        },
        {
            from = "stale", to = "spoiled", trigger = "auto",
            condition = "timer_expired",
            message = "The cheese has spoiled. Green mold covers the surface and a sour stink rises from it.",
            mutate = {
                keywords = { add = "moldy" },
            },
        },
    },

    mutations = {},
}
