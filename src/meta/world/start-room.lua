return {
    template = "room",

    id = "start-room",
    name = "The Bedroom",
    keywords = {"bedroom", "room", "chamber", "bedchamber"},
    description = "You stand in a dim bedchamber that smells of tallow, old wool, and the faintest ghost of lavender. The stone walls are bare save for the shadows that cling to them like ivy. Cold flagstones line the floor, and pale grey light filters in from somewhere, barely enough to see by. The air is still and heavy, as though the room has been holding its breath for a very long time.",

    contents = {"bed", "nightstand", "vanity", "wardrobe", "rug", "window", "curtains", "chamber-pot"},

    exits = {
        north = {
            target = "hallway",
            type = "door",
            passage_id = "bedroom-hallway-door",
            name = "a heavy oak door",
            keywords = {"door", "oak door", "heavy door", "north door"},
            description = "A heavy oak door with iron hinges and a simple latch. It stands slightly ajar, revealing a sliver of dim corridor beyond.",

            max_carry_size = 4,
            max_carry_weight = 50,
            requires_hands_free = false,
            player_max_size = 5,

            open = true,
            locked = false,
            key_id = nil,
            hidden = false,
            broken = false,

            one_way = false,
            breakable = true,
            break_difficulty = 3,

            mutations = {
                close = {
                    becomes_exit = {
                        open = false,
                        description = "A heavy oak door with iron hinges, shut tight against its frame.",
                    },
                    message = "You push the door shut. It closes with a heavy thud that echoes down the corridor.",
                },
                open = {
                    becomes_exit = {
                        open = true,
                        description = "A heavy oak door with iron hinges, standing open to the corridor beyond.",
                    },
                    message = "The door swings open on groaning iron hinges.",
                },
                lock = {
                    requires = "brass-key",
                    becomes_exit = {
                        open = false,
                        locked = true,
                        description = "The heavy oak door is shut and locked. The iron lock plate shows a keyhole shaped like a grinning face.",
                    },
                    message = "You turn the brass key. The lock clicks into place with grim finality.",
                },
                unlock = {
                    requires = "brass-key",
                    becomes_exit = {
                        locked = false,
                        description = "The heavy oak door is closed but unlocked. The keyhole grins at you.",
                    },
                    message = "The key turns with a satisfying click. The lock releases.",
                },
                ["break"] = {
                    becomes_exit = {
                        type = "hole in wall",
                        name = "a splintered doorframe",
                        keywords = {"doorframe", "splintered doorframe", "broken door"},
                        description = "Where the oak door once stood, only splintered wood and twisted iron hinges remain. Splinters litter the floor.",
                        open = true,
                        locked = false,
                        breakable = false,
                        broken = true,
                        max_carry_size = 4,
                        max_carry_weight = 50,
                    },
                    spawns = {"wood-splinters"},
                    message = "The door bursts inward with a crack of splintering oak! Fragments scatter across the stone floor.",
                },
            },
        },

        window = {
            target = "courtyard",
            type = "window",
            passage_id = "bedroom-courtyard-window",
            name = "the leaded glass window",
            keywords = {"window", "glass", "leaded window", "pane"},
            description = "A tall window of diamond-paned leaded glass, set deep in the stone wall. Through the warped glass you glimpse rooftops and a moonlit courtyard far below.",

            max_carry_size = 2,
            max_carry_weight = 10,
            requires_hands_free = true,
            player_max_size = 4,

            open = false,
            locked = true,
            key_id = nil,
            hidden = false,
            broken = false,

            one_way = false,
            direction_hint = "down",
            breakable = true,
            break_difficulty = 2,

            mutations = {
                unlock = {
                    becomes_exit = {
                        locked = false,
                        description = "The iron latch is open. The window could be pushed outward.",
                    },
                    message = "You slide the iron latch aside. It moves reluctantly, shedding flakes of rust.",
                },
                open = {
                    condition = function(self) return not self.locked end,
                    becomes_exit = {
                        open = true,
                        description = "The window stands open. Cold night air drifts in, carrying the scent of rain and chimney smoke from the courtyard below.",
                    },
                    message = "You push the window open. Cold air rushes in, guttering the candle flame.",
                },
                close = {
                    becomes_exit = {
                        open = false,
                        description = "The window is closed. Through the warped glass you glimpse rooftops and a moonlit courtyard.",
                    },
                    message = "You pull the window shut. The sounds of the night are muffled once more.",
                },
                ["break"] = {
                    becomes_exit = {
                        type = "hole in wall",
                        name = "a shattered window frame",
                        keywords = {"window", "broken window", "shattered window", "window frame"},
                        description = "Jagged shards of leaded glass cling to the stone frame like broken teeth. Cold air howls through the gap. The courtyard is visible far below — a dangerous drop.",
                        open = true,
                        locked = false,
                        breakable = false,
                        broken = true,
                        requires_hands_free = true,
                        max_carry_size = 3,
                    },
                    spawns = {"glass-shard", "glass-shard"},
                    message = "The window explodes inward in a shower of glass! Shards skitter across the stone floor.",
                },
            },
        },
    },

    -- No custom on_look: engine composes room view dynamically from
    -- room.description + object room_presence fields + visible exits.

    on_enter = function(self)
        return "You step into the bedchamber. The floorboards creak beneath your feet, and the shadows seem to lean in closer."
    end,

    mutations = {},
}
