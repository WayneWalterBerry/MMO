return {
    guid = "8fa16d57-41ea-4695-a61b-2ccc3f68c1b6",
    template = "room",

    id = "courtyard",
    name = "The Inner Courtyard",
    level = { number = 1, name = "The Awakening" },
    keywords = {"courtyard", "yard", "court", "outside", "exterior", "inner courtyard"},
    description = "You stand in a cobblestone courtyard enclosed by the manor's stone walls on all four sides. Above, the sky is open — stars scattered like ice chips across a deep black field, and a half-moon casting silver light over everything. A stone well stands at the center, its iron winch creaking faintly in the breeze. Ivy smothers the east wall in a dark, dense curtain. The air is cold and damp and smells of rain, wet stone, and chimney smoke from somewhere above. High on the south wall, far above your reach, you can see the bedroom window — a dark rectangle in the moonlight.",

    on_feel = "Uneven ground underfoot — cobblestones, cold and slick with moisture. The air is sharp and open — no walls pressing close, no ceiling above. For the first time, you feel SPACE — open sky, moving air, the chill of night. Your feet splash in puddles between the stones. You reach out: to your left, a stone wall, cold and rough, draped in something leafy and thick — ivy. Ahead, your hands find a circular stone rim at waist height — a well, its lip worn smooth by centuries of rope and bucket. The wind carries the smell of rain and chimney smoke.",

    on_smell = "Rain — recent rain on cobblestones, that clean, mineral scent of wet rock. Chimney smoke, drifting down from somewhere above — the flue of a fireplace in the manor, though no fire seems to burn now. Ivy — the green, faintly bitter smell of living plants. And beneath it all, the cold, open smell of night air — something you've been starved of since waking. It smells like freedom, but the high walls around you say otherwise.",

    on_listen = "Wind. Not strong, but present — a breeze that lifts the ivy and makes the well's winch creak. Water dripping from somewhere — a gutter, a leak, rain running off the roof hours ago. The distant hoot of an owl. Your own footsteps on wet cobblestones, loud and echoless in the open air. And from inside the manor — nothing. The windows above are dark, the doors are shut. The building watches in silence.",

    temperature = 8,
    moisture = 0.7,
    light_level = 1,

    instances = {
        -- Room-level objects
        { id = "stone-well",    type = "Stone Well",         type_id = "24alqz4x-b5c2-4fd5-18e8-3a260b890123", location = "room" },
        { id = "well-bucket",   type = "Well Bucket",        type_id = "35bmr05y-c6d3-40e6-29f9-4b371c901234", location = "stone-well" },
        { id = "ivy",           type = "Ivy",                type_id = "46cns16z-d7e4-41f7-3a0a-5c482d012345", location = "room" },
        { id = "cobblestone",   type = "Loose Cobblestone",  type_id = "57dot27a-e8f5-4208-4b1b-6d593e123456", location = "room" },
        { id = "rain-barrel",   type = "Rain Barrel",        type_id = "79fqv49c-0a17-4420-6d3d-8f7b50345678", location = "room" },
    },

    exits = {
        up = {
            target = "start-room",
            type = "window",
            passage_id = "bedroom-courtyard-window",
            name = "the bedroom window high above",
            keywords = {"window", "bedroom window", "up"},
            description = "Far above, the bedroom window is visible — a dark rectangle high on the south wall. The drop was dangerous; climbing back would be harder still.",

            max_carry_size = 2,
            max_carry_weight = 10,
            requires_hands_free = true,
            player_max_size = 4,

            open = false,
            locked = false,
            hidden = false,
            broken = false,
            one_way = false,
            direction_hint = "up",
        },

        east = {
            target = "manor-kitchen",
            type = "door",
            passage_id = "courtyard-kitchen-door",
            name = "a stout wooden door",
            keywords = {"door", "wooden door", "kitchen door", "east door"},
            description = "A stout wooden door, warped with age and damp. The latch is rusted shut. Through the crack beneath it, you smell old cooking fires and grease.",
            on_feel = "Swollen wood, rough and damp. The latch is a simple iron bar, seized with rust. The hinges are on the inside — you'd have to go through it, not around it. The gap beneath the door lets through a draft that smells of grease and cold ash.",

            max_carry_size = 4,
            max_carry_weight = 50,
            requires_hands_free = false,
            player_max_size = 5,

            open = false,
            locked = true,
            key_id = nil,
            hidden = false,
            broken = false,
            one_way = false,
            breakable = true,
            break_difficulty = 3,

            mutations = {
                ["break"] = {
                    becomes_exit = {
                        type = "hole in wall",
                        name = "a splintered doorway",
                        keywords = {"doorway", "splintered doorway", "broken door"},
                        description = "Where the wooden door once stood, only splintered planks and a twisted latch remain. The smell of old cooking grease drifts through the gap.",
                        open = true,
                        locked = false,
                        breakable = false,
                        broken = true,
                        max_carry_size = 4,
                        max_carry_weight = 50,
                    },
                    message = "The warped door gives way with a crack of splintering wood! The rusted latch tears free and clatters across the cobblestones.",
                },
                unlock = {
                    becomes_exit = {
                        locked = false,
                        description = "The wooden door's latch has been forced aside, though the wood is still swollen in its frame.",
                    },
                    message = "With effort, you work the rusted latch free. It scrapes open with a grinding protest.",
                },
                open = {
                    condition = function(self) return not self.locked end,
                    becomes_exit = {
                        open = true,
                        description = "The wooden door stands open, revealing a dim kitchen passage beyond.",
                    },
                    message = "You put your shoulder to the swollen door and shove. It scrapes open, grudging every inch.",
                },
            },
        },
    },

    on_enter = function(self)
        return "You land hard on wet cobblestones. Cold night air hits you like a slap — wind, rain-smell, the vast openness of sky after so many closed rooms. Stars wheel overhead. The manor walls rise on all sides, and somewhere high above, the window you came from stares down like a dark, empty eye."
    end,

    mutations = {},
}
