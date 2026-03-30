return {
    guid = "{32DF1F7E-5EAB-4239-A77B-B52B18410B50}",
    template = "furniture",

    id = "victory-confetti-cannon",
    material = "metal",
    keywords = {"cannon", "confetti cannon", "victory cannon", "confetti"},
    size = 5,
    weight = 10,
    categories = {"furniture", "interactive"},
    portable = false,

    name = "a golden confetti cannon",
    description = "A huge golden confetti cannon points straight up at the ceiling. It's bigger than the one in the studio! A sign says: \"GRAND FINALE CANNON - Opens with the chest!\"",
    room_presence = "A huge golden confetti cannon stands ready for the big moment.",
    on_feel = "Cold smooth gold metal. WAY bigger than the studio cannon. This one means business!",
    on_smell = "Metal and paper confetti. Ready to celebrate!",
    on_listen = "A deep creaking. The spring inside is MASSIVE. This is going to be epic!",
    on_taste = "You lick the cannon. Gold metal! Save your taste buds for the celebration!",

    location = nil,

    initial_state = "loaded",
    _state = "loaded",

    states = {
        loaded = {
            name = "a golden confetti cannon",
            description = "A huge golden confetti cannon. It's loaded and waiting for the big moment!",
            on_feel = "Cold gold metal. The spring is tight. Ready to BLOW!",
        },
        fired = {
            name = "a golden confetti cannon (FIRED!)",
            description = "The golden cannon is empty! Gold and silver confetti is EVERYWHERE! The whole room sparkles!",
            on_feel = "Warm gold metal. The spring is loose. Confetti floats everywhere!",
        },
    },

    transitions = {
        {
            from = "loaded", to = "fired", trigger = "chest_opened",
            message = "KA-BOOM!!! The golden cannon EXPLODES with confetti! Gold! Silver! Red! Blue! The whole room fills with sparkles! Streamers fly! Lights flash! THIS IS THE GREATEST MOMENT EVER!!!",
        },
    },

    mutations = {},
}
