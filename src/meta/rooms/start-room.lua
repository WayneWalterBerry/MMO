return {
    guid = "44ea2c40-e898-47a6-bb9d-77e5f49b3ba0",
    template = "room",

    id = "start-room",
    name = "The Bedroom",
    level = { number = 1, name = "The Awakening" },
    sky_visible = false,
    keywords = {"bedroom", "room", "chamber", "bedchamber"},
    description = "You stand in a dim bedchamber that smells of tallow, old wool, and the faintest ghost of lavender. The stone walls are bare save for the shadows that cling to them like ivy. Cold flagstones line the floor, and pale grey light filters in from somewhere, barely enough to see by. The air is still and heavy, as though the room has been holding its breath for a very long time.",
    short_description = "A dim bedchamber of cold stone and stale air.",

    -- All objects in this room, defined as deep-nested instance trees.
    -- Relationship keys: on_top, contents, nested, underneath.
    -- room.contents is rebuilt at load time by walking the tree.
    instances = {
        -- === Bed ===
        { id = "bed", type = "Four-Poster Bed", type_id = "b8e37cb6-cba7-48a6-bec9-5bca5f53b73c",
            on_top = {
                { id = "pillow", type = "Pillow", type_id = "f973058d-5410-4c02-b643-b7cab713aaf4",
                    contents = {
                        { id = "pin", type = "Pin", type_id = "f5cd5850-2020-4483-b17f-972eb9242701" },
                    },
                },
                { id = "bed-sheets", type = "Bed Sheets", type_id = "6bb22862-b68a-47bf-a50b-34e6b3d9a724" },
                { id = "blanket", type = "Blanket", type_id = "7eb14362-a55d-4a89-a8ea-ec2098d952ff" },
            },
            underneath = {
                { id = "knife", type = "Knife", type_id = "b0c650c6-497a-440c-a83a-545ee8789284" },
            },
        },

        -- === Nightstand ===
        { id = "nightstand", type = "Nightstand", type_id = "d40b15e6-7d64-489e-9324-ea00fb915602",
            on_top = {
                { id = "candle-holder", type = "Candle Holder", type_id = "0aeaff45-e2d0-4e58-b47c-139874a218df",
                    contents = {
                        { id = "candle", type = "Candle", type_id = "992df7f3-1b8e-4164-939a-3415f8f6ffe3" },
                    },
                },
                { id = "poison-bottle", type = "Poison Bottle", type_id = "a1043287-aeeb-4eb7-91c4-d0fcd11f86e3" },
            },
            nested = {
                { id = "drawer", type = "Drawer", type_id = "83dda7fe-c35c-4af7-94a0-346601e6d864",
                    contents = {
                        { id = "matchbox", type = "Matchbox", type_id = "41eb8a2f-972f-4245-a1fb-bbfdcaad4868",
                            contents = {
                                { id = "match-1", type = "Match", type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9" },
                                { id = "match-2", type = "Match", type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9" },
                                { id = "match-3", type = "Match", type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9" },
                                { id = "match-4", type = "Match", type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9" },
                                { id = "match-5", type = "Match", type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9" },
                                { id = "match-6", type = "Match", type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9" },
                                { id = "match-7", type = "Match", type_id = "009b0347-2ba3-45d1-a733-7a587ad1f5c9" },
                            },
                        },
                    },
                },
            },
        },

        -- === Vanity ===
        { id = "vanity", type = "Oak Vanity", type_id = "eda1257d-8240-4c75-9c1b-a7be349a60f5",
            on_top = {
                { id = "mirror", type = "Mirror", type_id = "1b47a68e-33a7-4d27-8065-4bc94b8f149f" },
                { id = "paper", type = "Paper", type_id = "e7409390-d4c4-4315-9768-72df1b3702e6" },
                { id = "pen", type = "Pen", type_id = "4d35b030-0b8c-4159-b646-d669909133a3" },
            },
            contents = {
                { id = "pencil", type = "Pencil", type_id = "07e76701-ebb5-4b5d-adc0-c8012e7ff809" },
            },
        },

        -- === Wardrobe ===
        { id = "wardrobe", type = "Wardrobe", type_id = "9c4701d1-4cc4-49e7-9c4a-041e1e37caf1",
            contents = {
                { id = "trousers", type = "Moth-Eaten Trousers", type_id = "3c75a0cc-0b60-458b-a533-7ec1c48da76a" },
                { id = "sack", type = "Sack", type_id = "4720ace5-baed-4133-b5db-977257f5b680",
                    contents = {
                        { id = "needle", type = "Needle", type_id = "07b9daaf-ee36-408e-8c66-d794bc175ed1" },
                        { id = "thread", type = "Thread", type_id = "8a7edb7e-9dff-4587-a104-4710cb270058" },
                        { id = "sewing-manual", type = "Sewing Manual", type_id = "3f8a1c9d-7e52-4b6f-a831-9d4e6f2c8b71" },
                    },
                },
            },
        },

        -- === Rug ===
        { id = "rug", type = "Rug", type_id = "7275e1d9-5837-4f39-b3be-d64ee6d667c9",
            underneath = {
                { id = "brass-key", type = "Brass Key", type_id = "4586b2cd-3240-46de-8fb8-5216ad9d4830" },
                { id = "trap-door", type = "Trap Door", type_id = "a3f8c7d1-e592-4b6a-8d3e-f1c7a4b92e05", hidden = true },
            },
        },

        -- === Room-level objects ===
        { id = "window", type = "Window", type_id = "4ecd1058-5cbe-4601-a98e-c994631f7d6b" },
        { id = "curtains", type = "Curtains", type_id = "cc981807-a74e-4ecc-8d52-903cc4fc5bd6" },
        { id = "chamber-pot", type = "Chamber Pot", type_id = "9a9ff109-93a0-4dcf-9d6e-0f0f4b83f4ba" },
        { id = "bedroom-door", type = "Bedroom Door", type_id = "e4a7f3b2-91d6-4c8e-b5a0-3f2d1e8c6a49", location = "room" },
        { id = "bedroom-hallway-door-north", type_id = "{25852832-6f19-48af-a118-20350ac8d243}" },
        { id = "bedroom-courtyard-window-out", type_id = "bedroom-courtyard-window-out" },
        { id = "bedroom-cellar-trapdoor-down", type_id = "bedroom-cellar-trapdoor-down" },
    },

    exits = {
        north = { portal = "bedroom-hallway-door-north" },
        window = { portal = "bedroom-courtyard-window-out" },
        down = { portal = "bedroom-cellar-trapdoor-down" },
    },

    -- No custom on_look: engine composes room view dynamically from
    -- room.description + object room_presence fields + visible exits.

    on_enter = function(self)
        return "You step into the bedchamber. The floorboards creak beneath your feet, and the shadows seem to lean in closer."
    end,

    mutations = {},
}
