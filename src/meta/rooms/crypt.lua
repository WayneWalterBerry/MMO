return {
    guid = "dea3ae62-c67e-4092-a361-fe3911c3fd4e",
    template = "room",

    id = "crypt",
    name = "The Crypt",
    level = { number = 1, name = "The Awakening" },
    sky_visible = false,
    keywords = {"crypt", "tomb", "burial", "burial chamber", "vault", "catacomb"},
    description = "Five stone coffins line the walls of a narrow vault carved from the living rock. Their lids bear the carved likenesses of robed figures, hands folded over chests that will never rise again, faces worn smooth by time until they are almost featureless. Small niches are cut into the walls between the tombs, some holding candle stubs burned down to waxy puddles, others empty. The air is perfectly still, cold, and dry — the kind of stillness that comes from being sealed away from the world for centuries. Dust motes hang motionless in your light. Inscriptions cover every available surface — names, dates, prayers, and symbols that repeat like a chorus.",
    short_description = "A silent vault of five stone coffins and ancient inscriptions.",

    on_feel = "Cold stone on all sides. Your hands find smooth surfaces rising from the floor — coffins, waist-high, their lids carved into shapes that feel like sleeping figures when your fingers trace them. Folded hands. A face, worn smooth, features eroded to suggestions. Between the coffins, small square holes in the wall — niches — containing waxy lumps and grit. The floor is bare rock, cold and gritty. The air is utterly still. No draft, no drip, no breath but your own. It smells of dust and old stone and the faint sweetness of ancient wax. You are in a tomb.",

    on_smell = "Dust — mineral, ancient, the fine powder of stone slowly eroding. Old wax — not fresh beeswax like the hallway, but candle wax burned years ago, its residue soaked into the stone niches. Dry stone — clean, cold, absent of moisture or life. No decay, no rot — whatever remains are in these coffins, they have long since returned to dust. The air smells of endings — not violent ones, but the quiet, patient ending of all things.",

    on_listen = "Nothing. Absolute, profound silence. Not the muffled silence of the deep cellar, but a silence that feels intentional — as if the room was built to contain it. No water drips. No rats scratch. No wind reaches here. When you hold your breath, you hear only the blood in your own ears. This silence is so complete it has weight — it presses against you, reminding you that you are a living thing in a place built for the dead.",

    temperature = 8,
    moisture = 0.1,
    light_level = 0,

    -- BUG-050: These objects are already described in room.description
    embedded_presences = {
        "sarcophagus-1", "sarcophagus-2", "sarcophagus-3",
        "sarcophagus-4", "sarcophagus-5",
        "candle-stub-1", "candle-stub-2",
        "wall-inscription",
    },

    instances = {
        -- Sarcophagi (south wall, west to east: 1, 2, 3)
        { id = "sarcophagus-1",    type = "Stone Sarcophagus", type_id = "f46656fd-02ca-4549-bb0d-e2366c6a43da" },
        { id = "sarcophagus-2",    type = "Stone Sarcophagus", type_id = "f46656fd-02ca-4549-bb0d-e2366c6a43da",
            contents = {
                { id = "bronze-ring",      type = "Bronze Ring",       type_id = "d4f18a63-9e27-4c85-b790-3a6e2f8d1c04" },
            },
        },
        { id = "sarcophagus-3",    type = "Stone Sarcophagus", type_id = "f46656fd-02ca-4549-bb0d-e2366c6a43da",
            contents = {
                { id = "silver-dagger",    type = "Silver Dagger",     type_id = "2155adb3-839c-451b-8078-892e839013b2" },
            },
        },

        -- Sarcophagi (north wall, west to east: 4, 5)
        { id = "sarcophagus-4",    type = "Stone Sarcophagus", type_id = "f46656fd-02ca-4549-bb0d-e2366c6a43da",
            contents = {
                { id = "burial-necklace",  type = "Burial Necklace",   type_id = "5e9b3c71-a284-4df6-8e13-7d0f4a5b2c89" },
            },
        },
        { id = "sarcophagus-5",    type = "Stone Sarcophagus", type_id = "f46656fd-02ca-4549-bb0d-e2366c6a43da",
            contents = {
                { id = "tome",             type = "Tome",              type_id = "7283ca72-a6be-4727-8de2-a7c1998e46cf" },
            },
        },

        -- Wall niches and their contents
        { id = "candle-stub-1",    type = "Candle Stub",       type_id = "076d1bf6-12c3-443f-b88a-85452cb4477c" },
        { id = "candle-stub-2",    type = "Candle Stub",       type_id = "076d1bf6-12c3-443f-b88a-85452cb4477c" },
        { id = "burial-coins",     type = "Burial Coins",      type_id = "76d22caa-0c4e-4671-bdce-7eeb3093b861" },

        -- Wall inscription (east wall, back of crypt)
        { id = "wall-inscription", type = "Wall Inscription",  type_id = "959a08fd-057e-4cf6-b80e-c419d184bcc1" },
        { id = "crypt-deep-cellar-archway-west", type_id = "crypt-deep-cellar-archway-west" },
    },

    exits = {
        west = { portal = "crypt-deep-cellar-archway-west" },
    },

    on_enter = function(self)
        return "You descend worn stone steps into absolute stillness. The passage opens into a narrow vault, and the light of your flame falls upon five stone coffins — carved lids bearing the serene faces of the long dead. The silence here is total, almost sacred. You have reached the deepest and oldest place in the manor."
    end,

    mutations = {},
}
