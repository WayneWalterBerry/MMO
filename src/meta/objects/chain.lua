-- chain.lua — Mechanical puzzle element (Deep Cellar)
-- States: hanging → pulled
return {
    guid = "c84fkt8r-5f66-497f-b282-d46045234567",
    template = "furniture",

    id = "chain",
    material = "iron",
    keywords = {"chain", "iron chain", "hanging chain", "pull chain", "chains"},
    size = 4,
    weight = 5,
    categories = {"metal", "furniture"},
    portable = false,

    name = "an iron chain",
    description = "A heavy iron chain hangs from the vaulted ceiling, dangling to about chest height. The links are thick and rust-spotted. It ends in a large ring -- clearly meant to be pulled. The chain disappears into a dark slot in the ceiling, connected to some mechanism above.",
    room_presence = "An iron chain hangs from the ceiling, ending in a heavy ring at chest height.",
    on_feel = "Heavy iron links, rough with rust. The chain sways slightly when touched. A large ring at the bottom -- meant to be grasped. The chain is taut, connected to something above.",
    on_smell = "Rust and old iron.",
    on_listen = "The chain clinks softly when disturbed. A faint creaking from above -- the mechanism.",

    location = nil,

    initial_state = "hanging",
    _state = "hanging",

    states = {
        hanging = {
            name = "an iron chain",
            description = "A heavy iron chain hangs from the vaulted ceiling, dangling to about chest height. The links are thick and rust-spotted. It ends in a large ring -- clearly meant to be pulled. The chain disappears into a dark slot in the ceiling, connected to some mechanism above.",
            room_presence = "An iron chain hangs from the ceiling, ending in a heavy ring at chest height.",
            on_feel = "Heavy iron links, rough with rust. The chain sways slightly when touched. A large ring at the bottom -- meant to be grasped. The chain is taut, connected to something above.",
            on_smell = "Rust and old iron.",
            on_listen = "The chain clinks softly when disturbed. A faint creaking from above -- the mechanism.",
        },

        pulled = {
            name = "a pulled chain",
            description = "The chain has been pulled down about two feet and holds there with a click. Above, something heavy shifts and groans in the ceiling. The sound of stone grinding against stone echoes from the west wall.",
            room_presence = "An iron chain hangs from the ceiling, pulled taut and locked in position.",
            on_feel = "The chain is extended, taut. The ring is lower now. Something clicked into place -- you can't push it back up.",
            on_smell = "Rust and old iron.",
            on_listen = "Echoing grinding from the west -- stone on stone. Then silence.",
        },
    },

    transitions = {
        {
            from = "hanging", to = "pulled", verb = "pull",
            aliases = {"yank", "tug"},
            message = "You grasp the iron ring and pull. The chain resists, then gives with a heavy CLUNK. Something mechanical shifts in the ceiling above. From the west wall comes the sound of stone grinding against stone -- slow, deliberate, final.",
            mutate = {
                keywords = { add = "pulled" },
            },
        },
    },

    mutations = {},
}
