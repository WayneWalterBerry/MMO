return {
    guid = "b7d2e3f4-a891-4c56-9e38-d7f1b2c4a605",
    template = "room",

    id = "cellar",
    name = "The Cellar",
    level = { number = 1, name = "The Awakening" },
    keywords = {"cellar", "basement", "underground", "cellar room"},
    description = "You stand at the foot of a narrow stone stairway in a low-ceilinged cellar. The walls are rough-hewn granite, slick with moisture that catches what little light there is. Water drips somewhere in the darkness, a slow and patient rhythm. The air is cold and heavy, thick with the smell of damp earth, old stone, and something faintly metallic. Cobwebs hang in thick curtains from the ceiling, swaying in a draft you cannot feel.",
    short_description = "A cold, damp cellar of rough stone and dripping water.",

    on_smell = "Damp earth, cold stone, and something faintly metallic -- iron, perhaps, or old blood. The air is thick and stale, as if it has not moved in a very long time.",

    instances = {
        { id = "barrel",         type = "Barrel",         type_id = "c3e8f1a2-b4d7-4596-8e23-f9a1b6c5d402", location = "room" },
        { id = "torch-bracket",  type = "Torch Bracket",  type_id = "d9f4a2b3-c5e8-4167-9d34-e8b2c7d6f513", location = "room" },
    },

    exits = {
        up = {
            target = "start-room",
            type = "stairway",
            passage_id = "cellar-bedroom-stairway",
            name = "a narrow stone stairway",
            keywords = {"stairs", "stairway", "staircase", "up", "steps", "stone stairs"},
            description = "A narrow stone stairway spirals upward through the open trap door, back to the bedroom above.",

            max_carry_size = 3,
            max_carry_weight = 30,
            requires_hands_free = false,
            player_max_size = 5,

            open = true,
            locked = false,
            hidden = false,
            broken = false,
            one_way = false,
        },
        north = {
            target = "storage-cellar",
            type = "door",
            passage_id = "cellar-storage-door",
            name = "a heavy iron-bound door",
            keywords = {"door", "iron door", "heavy door", "north door", "iron-bound door"},
            description = "A heavy door of black iron-bound oak stands against the north wall. A massive padlock secures it shut. Whatever lies beyond, someone went to great lengths to keep it sealed.",
            description_unlocked = "A heavy door of black iron-bound oak stands against the north wall. The padlock hangs open, its hasp pulled aside. The door is closed but no longer secured.",
            description_open = "The heavy iron-bound door stands open, revealing a dark passage leading north into deeper darkness.",
            on_feel = "Your hands find cold iron bands wrapped around heavy oak planks. A massive padlock hangs from a thick hasp -- the keyhole is small, meant for a brass key. The door does not budge.",

            max_carry_size = 4,
            max_carry_weight = 50,
            requires_hands_free = false,
            player_max_size = 5,

            open = false,
            locked = true,
            key_id = "brass-key",
            hidden = false,
            broken = false,
            one_way = false,
            breakable = false,

            mutations = {
                open = {
                    becomes_exit = { open = true },
                    message = "You push the heavy door. It swings open with a long, low groan of iron hinges, revealing darkness beyond.",
                },
            },
        },
    },

    on_enter = function(self)
        return "You descend the narrow stone stairway, each step taking you deeper into cold, damp air. The smell of earth and old stone grows stronger with every step."
    end,

    mutations = {},
}
