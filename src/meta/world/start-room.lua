return {
    guid = "44ea2c40-e898-47a6-bb9d-77e5f49b3ba0",
    template = "room",

    id = "start-room",
    name = "The Bedroom",
    keywords = {"bedroom", "room", "chamber", "bedchamber"},
    description = "You stand in a dim bedchamber that smells of tallow, old wool, and the faintest ghost of lavender. The stone walls are bare save for the shadows that cling to them like ivy. Cold flagstones line the floor, and pale grey light filters in from somewhere, barely enough to see by. The air is still and heavy, as though the room has been holding its breath for a very long time.",

    -- All objects in this room, defined as instances referencing base class GUIDs.
    -- room.contents is rebuilt at load time from instance locations.
    instances = {
        -- Room-level furniture
        { id = "bed",           type = "Four-Poster Bed",    type_id = "b8e37cb6-cba7-48a6-bec9-5bca5f53b73c", location = "room" },
        { id = "nightstand",    type = "Nightstand",         type_id = "d40b15e6-7d64-489e-9324-ea00fb915602", location = "room" },
        { id = "vanity",        type = "Oak Vanity",         type_id = "eda1257d-8240-4c75-9c1b-a7be349a60f5", location = "room" },
        { id = "wardrobe",      type = "Wardrobe",           type_id = "9c4701d1-4cc4-49e7-9c4a-041e1e37caf1", location = "room" },
        { id = "rug",           type = "Rug",                type_id = "7275e1d9-5837-4f39-b3be-d64ee6d667c9", location = "room" },
        { id = "trap-door",    type = "Trap Door",          type_id = "a3f8c7d1-e592-4b6a-8d3e-f1c7a4b92e05", location = "room" },
        { id = "window",        type = "Window",             type_id = "4ecd1058-5cbe-4601-a98e-c994631f7d6b", location = "room" },
        { id = "curtains",      type = "Curtains",           type_id = "cc981807-a74e-4ecc-8d52-903cc4fc5bd6", location = "room" },
        { id = "chamber-pot",   type = "Chamber Pot",        type_id = "9a9ff109-93a0-4dcf-9d6e-0f0f4b83f4ba", location = "room" },

        -- Bed surfaces
        { id = "pillow",        type = "Pillow",             type_id = "f973058d-5410-4c02-b643-b7cab713aaf4", location = "bed.top" },
        { id = "bed-sheets",    type = "Bed Sheets",         type_id = "6bb22862-b68a-47bf-a50b-34e6b3d9a724", location = "bed.top" },
        { id = "blanket",       type = "Blanket",            type_id = "7eb14362-a55d-4a89-a8ea-ec2098d952ff", location = "bed.top" },
        { id = "knife",         type = "Knife",              type_id = "b0c650c6-497a-440c-a83a-545ee8789284", location = "bed.underneath" },

        -- Pillow contents (hidden -- accessible = false)
        { id = "pin",           type = "Pin",                type_id = "f5cd5850-2020-4483-b17f-972eb9242701", location = "pillow.inside" },

        -- Nightstand surfaces
        { id = "candle",        type = "Candle",             type_id = "992df7f3-1b8e-4164-939a-3415f8f6ffe3", location = "nightstand.top" },
        { id = "poison-bottle", type = "Poison Bottle",      type_id = "a1043287-aeeb-4eb7-91c4-d0fcd11f86e3", location = "nightstand.top" },
        { id = "matchbox",      type = "Matchbox",           type_id = "41eb8a2f-972f-4245-a1fb-bbfdcaad4868", location = "nightstand.inside" },

        -- Matchbox contents (7 matches)
        { id = "match-1",       type = "Match",              type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9", location = "matchbox" },
        { id = "match-2",       type = "Match",              type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9", location = "matchbox" },
        { id = "match-3",       type = "Match",              type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9", location = "matchbox" },
        { id = "match-4",       type = "Match",              type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9", location = "matchbox" },
        { id = "match-5",       type = "Match",              type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9", location = "matchbox" },
        { id = "match-6",       type = "Match",              type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9", location = "matchbox" },
        { id = "match-7",       type = "Match",              type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9", location = "matchbox" },

        -- Vanity surfaces
        { id = "paper",         type = "Paper",              type_id = "e7409390-d4c4-4315-9768-72df1b3702e6", location = "vanity.top" },
        { id = "pen",           type = "Pen",                type_id = "4d35b030-0b8c-4159-b646-d669909133a3", location = "vanity.top" },
        { id = "pencil",        type = "Pencil",             type_id = "07e76701-ebb5-4b5d-adc0-c8012e7ff809", location = "vanity.inside" },

        -- Wardrobe contents
        { id = "wool-cloak",    type = "Wool Cloak",         type_id = "ecdccb0f-134d-436f-9f1c-d53911ac1445", location = "wardrobe.inside" },
        { id = "sack",          type = "Sack",               type_id = "4720ace5-baed-4133-b5db-977257f5b680", location = "wardrobe.inside" },

        -- Sack contents
        { id = "needle",        type = "Needle",             type_id = "07b9daaf-ee36-408e-8c66-d794bc175ed1", location = "sack" },
        { id = "thread",        type = "Thread",             type_id = "8a7edb7e-9dff-4587-a104-4710cb270058", location = "sack" },

        -- Rug surface (hidden -- must lift rug to find)
        { id = "brass-key",     type = "Brass Key",          type_id = "4586b2cd-3240-46de-8fb8-5216ad9d4830", location = "rug.underneath" },
    },

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
                        description = "Jagged shards of leaded glass cling to the stone frame like broken teeth. Cold air howls through the gap. The courtyard is visible far below -- a dangerous drop.",
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

        down = {
            target = "cellar",
            type = "trap_door",
            passage_id = "bedroom-cellar-trapdoor",
            name = "the trap door",
            keywords = {"trap door", "trapdoor", "hatch", "down", "stairway", "stairs"},
            description = "A narrow stone stairway spirals down into darkness through the open trap door.",

            max_carry_size = 3,
            max_carry_weight = 30,
            requires_hands_free = false,
            player_max_size = 5,

            open = false,
            locked = false,
            key_id = nil,
            hidden = true,
            broken = false,

            one_way = false,
            direction_hint = "down",
            breakable = false,

            mutations = {},
        },
    },

    -- No custom on_look: engine composes room view dynamically from
    -- room.description + object room_presence fields + visible exits.

    on_enter = function(self)
        return "You step into the bedchamber. The floorboards creak beneath your feet, and the shadows seem to lean in closer."
    end,

    mutations = {},
}
