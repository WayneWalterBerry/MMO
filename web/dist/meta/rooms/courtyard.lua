return {
    guid = "8fa16d57-41ea-4695-a61b-2ccc3f68c1b6",
    template = "room",

    id = "courtyard",
    name = "The Inner Courtyard",
    level = { number = 1, name = "The Awakening" },
    sky_visible = true,
    keywords = {"courtyard", "yard", "court", "outside", "exterior", "inner courtyard"},
    description = "You stand in a cobblestone courtyard enclosed by the manor's stone walls on all four sides. Above, the sky is open — stars scattered like ice chips across a deep black field, and a half-moon casting silver light over everything. A stone well stands at the center, its iron winch creaking faintly in the breeze. Ivy smothers the east wall in a dark, dense curtain. The air is cold and damp and smells of rain, wet stone, and chimney smoke from somewhere above. High on the south wall, far above your reach, you can see the bedroom window — a dark rectangle in the moonlight.",
    short_description = "A moonlit cobblestone courtyard with a stone well at its center.",

    on_feel = "Uneven ground underfoot — cobblestones, cold and slick with moisture. The air is sharp and open — no walls pressing close, no ceiling above. For the first time, you feel SPACE — open sky, moving air, the chill of night. Your feet splash in puddles between the stones. You reach out: to your left, a stone wall, cold and rough, draped in something leafy and thick — ivy. Ahead, your hands find a circular stone rim at waist height — a well, its lip worn smooth by centuries of rope and bucket. The wind carries the smell of rain and chimney smoke.",

    on_smell = "Rain — recent rain on cobblestones, that clean, mineral scent of wet rock. Chimney smoke, drifting down from somewhere above — the flue of a fireplace in the manor, though no fire seems to burn now. Ivy — the green, faintly bitter smell of living plants. And beneath it all, the cold, open smell of night air — something you've been starved of since waking. It smells like freedom, but the high walls around you say otherwise.",

    on_listen = "Wind. Not strong, but present — a breeze that lifts the ivy and makes the well's winch creak. Water dripping from somewhere — a gutter, a leak, rain running off the roof hours ago. The distant hoot of an owl. Your own footsteps on wet cobblestones, loud and echoless in the open air. And from inside the manor — nothing. The windows above are dark, the doors are shut. The building watches in silence.",

    temperature = 8,
    moisture = 0.7,
    light_level = 1,

    -- BUG-050: These objects are already described in room.description
    embedded_presences = {
        "stone-well", "ivy",
    },

    instances = {
        { id = "stone-well",    type = "Stone Well",         type_id = "096114c9-418d-41df-a5bf-d6a977664f8a",
            contents = {
                { id = "well-bucket",   type = "Well Bucket",        type_id = "d2fcb814-b606-4525-8a03-e031d3800332" },
            },
        },
        { id = "ivy",           type = "Ivy",                type_id = "18723096-bed0-46fa-bcf8-d79514f994ff" },
        { id = "cobblestone",   type = "Loose Cobblestone",  type_id = "4388e944-50e3-4382-9068-646421c0741f" },
        { id = "rain-barrel",   type = "Rain Barrel",        type_id = "ff526b60-83e1-4c82-9d5f-c303bac5bdf3" },
        { id = "courtyard-bedroom-window-in", type_id = "{5d1c820d-679c-4c65-a114-2e921b59b835}" },
        { id = "courtyard-kitchen-door", type_id = "{2c28ab89-693b-4612-b828-b8386f7ad090}" },
        { id = "courtyard-cat", type_id = "{46c2583c-2cec-4842-bfd3-5d56c737996d}" },
    },

    exits = {
        up = { portal = "courtyard-bedroom-window-in" },
        east = { portal = "courtyard-kitchen-door" },
    },

    on_enter = function(self)
        return "You land hard on wet cobblestones. Cold night air hits you like a slap — wind, rain-smell, the vast openness of sky after so many closed rooms. Stars wheel overhead. The manor walls rise on all sides, and somewhere high above, the window you came from stares down like a dark, empty eye."
    end,

    mutations = {},
}
