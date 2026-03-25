return {
    guid = "a1aa73d3-cd9d-4d13-9361-bd510cf0d46d",
    template = "room",

    id = "storage-cellar",
    name = "The Storage Cellar",
    level = { number = 1, name = "The Awakening" },
    keywords = {"storage", "cellar", "vault", "pantry", "provisions", "storage cellar"},
    description = "A long, narrow vault stretches before you, its barrel-vaulted ceiling disappearing into shadow at both ends. Heavy oak shelves line both walls from floor to ceiling, most sagging under the weight of years. Dust covers everything — the flagstone floor, the collapsed crates, the remnants of rope and sacking scattered like shed skin. The air tastes of old wood, stale grain, and the sweet-sour tang of decay. Something scurries in the darkness beyond the reach of your light.",
    short_description = "A dusty storage vault with sagging shelves and the sound of rats.",

    on_feel = "A long space. Your outstretched hands find wooden shelves on both sides — rough, splintery, sagging. The floor is stone under a layer of grit and something that crunches underfoot — old straw? Broken glass? The air is cold but drier than the cellar behind you. Dust tickles your nose. You smell old grain, wood rot, and something sweetly rotten. From deeper in the room: a scratching sound, small and quick, like tiny claws on stone.",

    on_smell = "Stale grain — the ghost of flour and barley, long turned to dust and mold. Old wood, dried out and crumbling. The sweet-sour smell of fruit or vegetables that rotted years ago and left their essence in the stone. And beneath it all, the sharp, musky tang of rodent: droppings, fur, and the faint ammonia of urine in corners.",

    on_listen = "Scratching. Small, quick, furtive — rats in the walls or under the shelving. The creak of old wood under its own weight. Your footsteps crunching on grit and straw. And occasionally, from the north end of the room, a faint draft that makes the cobwebs sway — air moving through the gap around the far door.",

    temperature = 11,
    moisture = 0.5,
    light_level = 0,

    instances = {
        -- === Large Crate ===
        { id = "large-crate",   type = "Large Crate",    type_id = "b7c3d1a2-4e5f-4890-ab12-cdef34567890",
            on_top = {
                { id = "small-crate",   type = "Small Crate",    type_id = "c8d4e2b3-5f60-4901-bc23-def045678901",
                    contents = {
                        { id = "cloth-scraps",  type = "Cloth Scraps",   type_id = "7cb2e194-3d80-4a51-bf63-e8d1c5a40927" },
                        { id = "candle-stubs",  type = "Candle Stub",    type_id = "076d1bf6-12c3-443f-b88a-85452cb4477c" },
                    },
                },
            },
            contents = {
                { id = "iron-key",      type = "Iron Key",       type_id = "438f3f05-00d9-4b5a-b50d-bd46012b27c7" },
            },
        },

        -- === Wine Rack ===
        { id = "wine-rack",     type = "Wine Rack",      type_id = "ea06f4d5-7182-4b23-de45-f02167890123",
            contents = {
                { id = "wine-bottle",   type = "Wine Bottle",    type_id = "1143ab52-ba47-4610-bd1f-6c9aa6167287" },
            },
        },

        -- === Room-level objects ===
        { id = "grain-sack",    type = "Grain Sack",     type_id = "d9e5f3c4-6071-4a12-cd34-ef1056789012" },
        { id = "oil-lantern",   type = "Oil Lantern",    type_id = "675d14a9-6ab6-40c2-bc74-90308232c5e1" },
        { id = "rope-coil",     type = "Rope Coil",      type_id = "9aaf7810-427b-428e-9902-34ab5d1c2fbe" },
        { id = "crowbar",       type = "Crowbar",        type_id = "b30076fe-7931-4089-8ea2-2cac139b022c" },
        { id = "oil-flask",     type = "Oil Flask",      type_id = "ae5df831-7c42-4b19-8e60-f9a3c7d21b54" },
        { id = "brass-spittoon", type = "Brass Spittoon", type_id = "{b763fdf9-f7d2-4eac-8952-7c03771c5013}" },
    },

    exits = {
        south = {
            target = "cellar",
            type = "door",
            passage_id = "cellar-storage-door",
            name = "the iron-bound door",
            keywords = {"door", "iron door", "south door", "iron-bound door"},
            description = "The heavy iron-bound door stands open behind you, revealing the cellar stairway beyond.",

            max_carry_size = 4,
            max_carry_weight = 50,
            requires_hands_free = false,
            player_max_size = 5,

            open = true,
            locked = false,
            hidden = false,
            broken = false,
            one_way = false,

            mutations = {
                close = {
                    becomes_exit = {
                        open = false,
                        description = "The heavy iron-bound door is shut, its iron bands dark against the oak.",
                    },
                    message = "You push the heavy door shut. It closes with a deep, resonant thud.",
                },
                open = {
                    becomes_exit = {
                        open = true,
                        description = "The heavy iron-bound door stands open, revealing the cellar stairway beyond.",
                    },
                    message = "The door groans open on protesting hinges.",
                },
            },
        },

        north = {
            target = "deep-cellar",
            type = "door",
            passage_id = "storage-deep-door",
            name = "a second iron-bound door",
            keywords = {"door", "iron door", "north door", "heavy door", "second door"},
            description = "A second iron-bound door blocks the north end of the vault. This one is different — heavier, older, with a lock plate of black iron. A large keyhole waits, dark and empty.",
            on_feel = "Cold iron bands over oak. Heavier than the door behind you. The keyhole is large — meant for an iron key, not the delicate brass one. The door does not yield to pushing.",

            max_carry_size = 4,
            max_carry_weight = 50,
            requires_hands_free = false,
            player_max_size = 5,

            open = false,
            locked = true,
            key_id = "iron-key",
            hidden = false,
            broken = false,
            one_way = false,
            breakable = false,

            mutations = {
                unlock = {
                    requires = "iron-key",
                    becomes_exit = {
                        locked = false,
                        description = "The iron-bound door stands unlocked, its heavy lock plate hanging loose.",
                    },
                    message = "The iron key turns with a grinding reluctance, and the lock plate falls open with a heavy clank.",
                },
                open = {
                    condition = function(self) return not self.locked end,
                    becomes_exit = {
                        open = true,
                        description = "The iron door stands open, revealing a passage into older, darker stone beyond.",
                    },
                    message = "You put your shoulder to the door. It yields slowly, grinding against the flagstones, and swings open into darkness.",
                },
                close = {
                    becomes_exit = {
                        open = false,
                        description = "The iron-bound door is closed. Its black lock plate stares at you like an empty eye socket.",
                    },
                    message = "You heave the door shut. It closes with a boom that echoes through the vault.",
                },
                lock = {
                    requires = "iron-key",
                    becomes_exit = {
                        open = false,
                        locked = true,
                        description = "A second iron-bound door blocks the north end of the vault. The lock plate is engaged, the keyhole dark and empty.",
                    },
                    message = "You turn the iron key. The lock engages with a heavy, final sound.",
                },
            },
        },
    },

    on_enter = function(self)
        return "You step through the doorway into a long, narrow vault. The air shifts — drier, colder, thick with the ghost of old grain and the sweet tang of something long rotted. Shelves crowd in on both sides. Something skitters away from your light."
    end,

    mutations = {},
}
