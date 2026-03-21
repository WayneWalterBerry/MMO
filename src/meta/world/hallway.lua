return {
    guid = "bb964e65-2233-4624-8757-9ec31d278530",
    template = "room",

    id = "hallway",
    name = "The Manor Hallway",
    level = { number = 1, name = "The Awakening" },
    keywords = {"hallway", "corridor", "hall", "manor", "passage", "manor hallway"},
    description = "Warmth. After the cellars, the warmth is the first thing you notice. You stand in a wide, wood-paneled corridor lit by torches in iron brackets. The floor is polished oak that gleams in the firelight, and the walls are plastered white above dark wainscoting. Portraits hang at regular intervals — stern faces in heavy frames, watching. Doors lead off to left and right, all of them closed. The air smells of beeswax, old wood, and the faint char of torch smoke. At the far end, a grand staircase ascends into shadow.",

    on_feel = "Smooth wood underfoot — not stone, not earth, but warm, polished boards that creak beneath your weight. The walls are smooth plaster above and carved wood below — wainscoting, you think, running your fingers along the grooves. The air is warm. You smell beeswax and wood smoke. Ahead and to both sides, your hands find closed doors — smooth oak, latched. The corridor is wide; you can stretch both arms without touching the walls.",

    on_smell = "Beeswax polish on the wooden floor and paneling — the warm, honey-sweet scent of a well-maintained home. Torch smoke, acrid but not unpleasant, curling from the iron brackets. Old wood — oak, seasoned and oiled. And beneath it all, the faintest trace of absence: dust settling on surfaces that were recently clean, the smell of a house where the fires have been tended but the people have gone.",

    on_listen = "The crackle and hiss of the torches in their brackets — living fire, the first you've heard since the bedroom. Your footsteps on the oak floor, loud and hollow after the muffled earth of the cellars. The creak of old timbers above. And silence where there should be people: no voices, no footsteps, no doors opening. The manor is warm and lit, but utterly empty.",

    temperature = 18,
    moisture = 0.15,
    light_level = 3,

    instances = {
        -- Torches and brackets
        { id = "torch-lit-west",          type = "Lit Torch",     type_id = "85c0daf7-7bf3-450c-930e-22fea3ec881a", location = "room" },
        { id = "torch-lit-east",          type = "Lit Torch",     type_id = "85c0daf7-7bf3-450c-930e-22fea3ec881a", location = "room" },

        -- Portraits
        { id = "portrait-1",              type = "Portrait",      type_id = "e4b50ef9-e997-4d7b-8a8a-5b6c04a6c790", location = "room" },
        { id = "portrait-2",              type = "Portrait",      type_id = "e4b50ef9-e997-4d7b-8a8a-5b6c04a6c790", location = "room" },
        { id = "portrait-3",              type = "Portrait",      type_id = "e4b50ef9-e997-4d7b-8a8a-5b6c04a6c790", location = "room" },

        -- Furniture
        { id = "side-table",              type = "Side Table",    type_id = "7289f77a-f37a-4348-9c53-8996b247432e", location = "room" },
        { id = "vase",                    type = "Vase",          type_id = "c5e8ae7e-1895-4836-a194-011c82f746e2", location = "side-table.top" },
    },

    exits = {
        south = {
            target = "start-room",
            type = "door",
            passage_id = "bedroom-hallway-door",
            name = "a heavy oak door",
            keywords = {"door", "oak door", "heavy door", "south door", "bedroom door"},
            description = "A heavy oak door with iron hinges. Through it lies the bedchamber where you woke.",

            max_carry_size = 4,
            max_carry_weight = 50,
            requires_hands_free = false,
            player_max_size = 5,

            open = true,
            locked = false,
            key_id = "brass-key",
            hidden = false,
            broken = false,
            one_way = false,
            breakable = true,
            break_difficulty = 3,

            mutations = {
                close = {
                    becomes_exit = {
                        open = false,
                        description = "A heavy oak door with iron hinges, shut tight.",
                    },
                    message = "You push the door shut. It closes with a heavy thud.",
                },
                open = {
                    becomes_exit = {
                        open = true,
                        description = "The heavy oak door stands open, revealing the dim bedchamber beyond.",
                    },
                    message = "The door swings open on groaning iron hinges.",
                },
                lock = {
                    requires = "brass-key",
                    becomes_exit = {
                        open = false,
                        locked = true,
                        description = "The heavy oak door is shut and locked.",
                    },
                    message = "You turn the brass key. The lock clicks into place.",
                },
                unlock = {
                    requires = "brass-key",
                    becomes_exit = {
                        locked = false,
                        description = "The heavy oak door is closed but unlocked.",
                    },
                    message = "The key turns with a satisfying click. The lock releases.",
                },
            },
        },

        down = {
            target = "deep-cellar",
            type = "stairway",
            passage_id = "deep-cellar-hallway-stairway",
            name = "stone steps descending",
            keywords = {"stairs", "stairway", "staircase", "down", "steps", "stone stairs", "descend", "cellar"},
            description = "Stone steps descend through an archway in the floor, curving down into the cool darkness of the cellars below.",

            max_carry_size = 4,
            max_carry_weight = 50,
            requires_hands_free = false,
            player_max_size = 5,

            open = true,
            locked = false,
            hidden = false,
            broken = false,
            one_way = false,
        },

        north = {
            target = "level-2",
            type = "stairway",
            passage_id = "hallway-level2-staircase",
            name = "a grand staircase",
            keywords = {"staircase", "stairs", "grand staircase", "up", "north", "grand stairs", "bannister"},
            description = "A grand staircase of polished oak ascends to the upper floors. The bannister is carved with the same symbols you saw in the deep cellar — familiar now, unsettling. The stairs curve upward out of sight.",

            max_carry_size = 5,
            max_carry_weight = 50,
            requires_hands_free = false,
            player_max_size = 5,

            open = true,
            locked = false,
            hidden = false,
            broken = false,
            one_way = false,
        },

        west = {
            target = "manor-west",
            type = "door",
            passage_id = "hallway-west-door",
            name = "a heavy oak door",
            keywords = {"door", "west door", "oak door", "locked door"},
            description = "A heavy oak door, closed and locked. Through the keyhole, you glimpse a darkened room beyond — bookshelves? A study?",

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
            breakable = false,

            mutations = {},
        },

        east = {
            target = "manor-east",
            type = "door",
            passage_id = "hallway-east-door",
            name = "a lighter oak door",
            keywords = {"door", "east door", "oak door", "kitchen door", "locked door"},
            description = "A lighter oak door, closed and latched. A warm smell seeps from underneath — old cooking fires, herbs, grease. The kitchen, perhaps.",

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
            breakable = false,

            mutations = {},
        },
    },

    on_enter = function(self)
        return "You emerge from the stairway into warmth and light. Torchlight flickers across polished oak floorboards and whitewashed walls. After the cold darkness below, the hallway feels almost impossibly welcoming — warm air, the crackle of fire, the sweet smell of beeswax. You've made it out."
    end,

    mutations = {},
}
