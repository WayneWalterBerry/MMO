-- ivy.lua — Climbable environmental object (Courtyard)
-- States: growing → climbed / growing → torn
return {
    guid = "{18723096-bed0-46fa-bcf8-d79514f994ff}",
    template = "furniture",

    id = "ivy",
    material = "plant",
    keywords = {"ivy", "vines", "vine", "climbing ivy", "creeper", "plant", "growth"},
    size = 6,
    categories = {"environmental", "plant"},
    portable = false,

    name = "thick ivy",
    description = "Thick, dark ivy blankets the manor's east wall from ground to roofline. The stems are as thick as your wrist at the base, woody and gnarled from decades of growth. Leaves rustle faintly in the night air. Higher up, near the bedroom window, the ivy thins -- but it looks climbable. Maybe.",
    room_presence = "Thick ivy blankets the east wall, climbing to the bedroom window far above.",
    on_feel = "Thick stems, rough and woody. Leaves -- smooth on top, rough underneath. The vine grips the stonework tightly. You can tug it -- it holds. Strong, but how strong?",
    on_smell = "Green and vegetal. Crushed leaf smell when you grip. Damp earth at the base.",
    on_listen = "Leaves whisper in the breeze. Insects rustle in the deeper growth.",

    location = nil,

    initial_state = "growing",
    _state = "growing",

    states = {
        growing = {
            name = "thick ivy",
            description = "Thick, dark ivy blankets the manor's east wall from ground to roofline. The stems are as thick as your wrist at the base, woody and gnarled from decades of growth. Leaves rustle faintly in the night air. Higher up, near the bedroom window, the ivy thins -- but it looks climbable. Maybe.",
            room_presence = "Thick ivy blankets the east wall, climbing to the bedroom window far above.",
            on_feel = "Thick stems, rough and woody. Leaves -- smooth on top, rough underneath. The vine grips the stonework tightly. You can tug it -- it holds. Strong, but how strong?",
            on_smell = "Green and vegetal. Crushed leaf smell when you grip. Damp earth at the base.",
            on_listen = "Leaves whisper in the breeze. Insects rustle in the deeper growth.",
        },

        climbed = {
            name = "damaged ivy",
            description = "The ivy has been climbed -- broken leaves and snapped tendrils mark a rough path up the wall. The vine still holds, but it's damaged.",
            on_feel = "Broken stems, snapped tendrils. The vine is weaker where climbed -- some stems have pulled free from the stone.",
            on_smell = "Crushed green sap. Damaged plant.",
            on_listen = "Wind through damaged leaves.",
        },

        torn = {
            name = "torn ivy",
            description = "A section of ivy has been ripped from the wall, exposing bare stone and leaving a trail of broken stems and torn roots.",
            on_feel = "Bare stone where the ivy was. Loose stems and leaves in your hand.",
            on_smell = "Strong green sap, torn roots, damp stone.",
        },
    },

    transitions = {
        {
            from = "growing", to = "climbed", verb = "climb",
            message = "You grab the ivy and climb. Halfway up, a stem snaps. You lunge, catch another -- it holds. Barely. Your heart hammers as you reach the windowsill.",
        },
        {
            from = "growing", to = "torn", verb = "tear",
            aliases = {"pull", "rip"},
            message = "You grab a fistful of ivy and pull. It comes away from the wall with a ripping sound, trailing roots and mortar dust. A few feet of woody vine in your hands.",
        },
    },

    mutations = {},
}
