-- bread.lua — Food item (WAVE-5 Track 5A)
-- States: fresh → stale
-- Bait for rats; edible consumable
return {
    guid = "{05991055-601c-4976-abdd-1ab411c9875e}",
    template = "small-item",

    id = "bread",
    material = "wax",
    keywords = {"bread", "crust", "food"},
    size = 1,
    weight = 0.2,
    categories = {"small-item", "food", "consumable"},
    portable = true,

    name = "a crust of bread",
    description = "A hard crust of dark bread, torn from a larger loaf. The outside is rough and browned, the inside pale and dense. A few crumbs cling to the edges.",
    room_presence = "A crust of bread lies here.",
    on_feel = "Rough and hard on the outside, the crust resists your thumbnail. The torn face is denser than you expected -- peasant bread, heavy with rye.",
    on_smell = "Yeasty and faintly sour -- good honest bread, if a bit stale already.",
    on_listen = "Silent. It crackles faintly if you squeeze it.",
    on_taste = "Dense and chewy, with a slight sourness. Plain, but filling.",

    location = nil,

    food = {
        edible = true,
        nutrition = 15,
        bait_value = 2,
        bait_targets = {"rat"},
    },

    initial_state = "fresh",
    _state = "fresh",

    states = {
        fresh = {
            name = "a crust of bread",
            description = "A hard crust of dark bread, torn from a larger loaf. The outside is rough and browned, the inside pale and dense. A few crumbs cling to the edges.",
            room_presence = "A crust of bread lies here.",
            on_feel = "Rough and hard on the outside, the crust resists your thumbnail. The torn face is denser than you expected -- peasant bread, heavy with rye.",
            on_smell = "Yeasty and faintly sour -- good honest bread, if a bit stale already.",
            on_taste = "Dense and chewy, with a slight sourness. Plain, but filling.",
            timed_events = {
                { event = "transition", delay = 7200, to_state = "stale" },
            },
        },

        stale = {
            name = "a stale crust of bread",
            description = "A rock-hard crust of bread, dried out and cracking at the edges. It has gone from merely tough to genuinely difficult to chew. A mouse might still want it.",
            room_presence = "A stale crust of bread sits here, hard as a stone.",
            on_feel = "Hard as wood. The crust has dried completely -- it would take real effort to break. More weapon than food at this point.",
            on_smell = "Dusty and flat. The yeast smell is gone, replaced by a dry, cardboard staleness.",
            on_taste = "Like chewing sawdust. You could eat it, but you would not enjoy it.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "fresh", to = "stale", trigger = "auto",
            condition = "timer_expired",
            message = "The bread has gone stale. It is rock-hard and barely worth eating.",
            mutate = {
                keywords = { add = "stale" },
            },
        },
    },

    mutations = {},
}
