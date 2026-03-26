return {
    guid = "a1aa73d3-cd9d-4d13-9361-bd510cf0d46d",
    template = "room",

    id = "storage-cellar",
    name = "The Storage Cellar",
    level = { number = 1, name = "The Awakening" },
    sky_visible = false,
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
        { id = "storage-cellar-door-south", type_id = "storage-cellar-door-south" },
        { id = "storage-deep-cellar-door-north", type_id = "storage-deep-cellar-door-north" },
    },

    exits = {
        south = { portal = "storage-cellar-door-south" },
        north = { portal = "storage-deep-cellar-door-north" },
    },

    on_enter = function(self)
        return "You step through the doorway into a long, narrow vault. The air shifts — drier, colder, thick with the ghost of old grain and the sweet tang of something long rotted. Shelves crowd in on both sides. Something skitters away from your light."
    end,

    mutations = {},
}
