return {
    guid = "64da418f-1fb2-4898-a016-50a5c0a6f4da",
    template = "room",

    id = "deep-cellar",
    name = "The Deep Cellar",
    level = { number = 1, name = "The Awakening" },
    sky_visible = false,
    keywords = {"deep cellar", "cellar", "chamber", "deep", "vault", "underground"},
    description = "The architecture changes here. Where the cellars above were rough-hewn and practical, this chamber is built from massive limestone blocks, dry-stacked with a precision that speaks of older and more deliberate hands. The ceiling rises into a ribbed vault, its central boss carved into a face that stares downward with blank stone eyes. Iron sconces line the walls, unlit and cold. Against the south wall stands a stone altar, its surface inscribed with symbols you cannot read. The air is still and heavy with the smell of ancient dust, old wax, and something fainter — incense, or the memory of incense, burned decades or centuries ago. From the north wall, where stone steps ascend into shadow, a faint draught of warmer air descends — just enough to stir the dust motes and remind you that a world above still exists.",
    short_description = "A vaulted limestone chamber with a stone altar and the ghost of incense.",

    on_feel = "Smooth stone — worked, polished, precise. Not the rough granite of the cellars. Your fingers find joints between massive blocks, fitted so tightly a knife blade wouldn't pass between them. The ceiling is higher here; you reach up and find only air. The floor is flat and even — large flagstones, some with raised edges that feel like carved borders. Against one wall, your hands find a broad stone surface at waist height — an altar or table, cold as ice, its surface covered in grooves and ridges that might be letters or symbols. The air smells of dust and something older — wax and incense, faint and ancient.",

    on_smell = "Dust — not the organic dust of the storage cellar, but mineral dust, the slow erosion of stone on stone. Old wax, from candles burned out years ago, their residue soaked into the stone. And beneath it, a ghost of incense — frankincense or myrrh, the kind burned in churches and temples. It clings to the stone like a memory that refuses to fade.",

    on_listen = "Silence. A deeper silence than the cellar — no dripping water, no scratching rats. The stone walls absorb sound; your own breathing seems muffled, as if the room is swallowing it. When you speak, there's a faint echo from the vaulted ceiling, delayed and hollow, like a cathedral whisper. The silence feels intentional, curated — this is a place built for quiet contemplation or prayer.",

    temperature = 9,
    moisture = 0.3,
    light_level = 0,

    instances = {
        -- === Stone Altar ===
        { id = "stone-altar",        type = "Stone Altar",       type_id = "a5fbf32f-530b-49af-9a19-255575a5eb77",
            on_top = {
                { id = "incense-burner",     type = "Incense Burner",    type_id = "2fce1fb5-94ad-44f7-9036-4332a62d3405" },
                { id = "tattered-scroll",    type = "Tattered Scroll",   type_id = "08d903bb-98fa-4c75-a986-26502479d12f" },
                { id = "offering-bowl",      type = "Offering Bowl",     type_id = "dfea4690-5a7c-406d-ba4e-20388319ea0e" },
            },
        },

        -- === Sconces ===
        { id = "unlit-sconce-east",  type = "Unlit Sconce",      type_id = "fd0fb6ed-a643-4b1a-96fd-ad1d520e4f75" },
        { id = "unlit-sconce-west",  type = "Unlit Sconce",      type_id = "fd0fb6ed-a643-4b1a-96fd-ad1d520e4f75" },

        -- === Stone Sarcophagus ===
        { id = "stone-sarcophagus",  type = "Stone Sarcophagus", type_id = "3fd2ce07-0c8b-421e-8e56-fa4687c815de",
            contents = {
                { id = "silver-key",         type = "Silver Key",        type_id = "336a1fce-6bfb-405d-a59e-c55faf83dd9d" },
            },
        },

        -- === Room-level ===
        { id = "chain",              type = "Chain",             type_id = "5f18202e-220f-4a16-b75e-170595f22845" },
        { id = "deep-cellar-storage-door-south", type_id = "{3f4dbb18-131f-46f6-83d5-99aa5b4eb98f}" },
        { id = "deep-cellar-hallway-stairs-up", type_id = "{cf6f88b2-ea66-4b9a-b28e-f01a4203d632}" },
        { id = "deep-cellar-crypt-archway-west", type_id = "{8be0ec4e-f5a2-4538-8e9e-2893264a50c5}" },
    },

    exits = {
        south = { portal = "deep-cellar-storage-door-south" },
        up = { portal = "deep-cellar-hallway-stairs-up" },
        west = { portal = "deep-cellar-crypt-archway-west" },
    },

    on_enter = function(self)
        return "You step through the doorway and the world changes. The rough granite gives way to massive, precisely fitted limestone blocks. The ceiling soars into a ribbed vault. The air is colder, drier, and carries the ghost of ancient incense. You have entered somewhere older than the manor above — somewhere built with purpose and reverence."
    end,

    mutations = {},
}
