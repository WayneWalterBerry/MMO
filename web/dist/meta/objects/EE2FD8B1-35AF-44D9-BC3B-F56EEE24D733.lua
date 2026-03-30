return {
    guid = "{EE2FD8B1-35AF-44D9-BC3B-F56EEE24D733}",
    template = "furniture",

    id = "confetti-cannon",
    material = "metal",
    keywords = {"cannon", "confetti cannon", "confetti"},
    size = 4,
    weight = 8,
    categories = {"furniture", "interactive"},
    portable = false,

    name = "a confetti cannon",
    description = "A big silver tube points up at the ceiling. A label says \"CONFETTI CANNON - DO NOT LOOK INSIDE.\" It looks ready to pop!",
    room_presence = "A silver confetti cannon points at the ceiling, ready to fire.",
    on_feel = "Cold smooth metal. You can feel a spring inside. It's loaded!",
    on_smell = "Smells like metal and a hint of paper confetti.",
    on_listen = "A faint creaking. The spring inside is tight and ready.",
    on_taste = "You lick the cannon. Tastes like metal. Not great, not terrible!",

    location = nil,

    initial_state = "loaded",
    _state = "loaded",

    states = {
        loaded = {
            name = "a confetti cannon",
            description = "A big silver tube points up at the ceiling. It looks ready to pop!",
            on_feel = "Cold smooth metal. You can feel a spring inside. It's loaded!",
        },
        fired = {
            name = "a confetti cannon (empty)",
            description = "The confetti cannon is empty now. Paper bits still drift down. That was awesome!",
            on_feel = "Warm metal. The spring inside is relaxed now. All the confetti is gone.",
        },
    },

    transitions = {
        {
            from = "loaded", to = "fired", verb = "press",
            aliases = {"push", "fire", "use", "activate"},
            message = "BOOM! The cannon fires! A huge cloud of colorful confetti fills the air! Red, blue, gold, and green paper rains down everywhere! SO COOL!",
        },
    },

    mutations = {},
}
