return {
    guid = "64da418f-1fb2-4898-a016-50a5c0a6f4da",
    template = "room",

    id = "deep-cellar",
    name = "The Deep Cellar",
    level = { number = 1, name = "The Awakening" },
    keywords = {"deep cellar", "cellar", "chamber", "deep", "vault", "underground"},
    description = "The architecture changes here. Where the cellars above were rough-hewn and practical, this chamber is built from massive limestone blocks, dry-stacked with a precision that speaks of older and more deliberate hands. The ceiling rises into a ribbed vault, its central boss carved into a face that stares downward with blank stone eyes. Iron sconces line the walls, unlit and cold. Against the south wall stands a stone altar, its surface inscribed with symbols you cannot read. The air is still and heavy with the smell of ancient dust, old wax, and something fainter — incense, or the memory of incense, burned decades or centuries ago.",
    short_description = "A vaulted limestone chamber with a stone altar and the ghost of incense.",

    on_feel = "Smooth stone — worked, polished, precise. Not the rough granite of the cellars. Your fingers find joints between massive blocks, fitted so tightly a knife blade wouldn't pass between them. The ceiling is higher here; you reach up and find only air. The floor is flat and even — large flagstones, some with raised edges that feel like carved borders. Against one wall, your hands find a broad stone surface at waist height — an altar or table, cold as ice, its surface covered in grooves and ridges that might be letters or symbols. The air smells of dust and something older — wax and incense, faint and ancient.",

    on_smell = "Dust — not the organic dust of the storage cellar, but mineral dust, the slow erosion of stone on stone. Old wax, from candles burned out years ago, their residue soaked into the stone. And beneath it, a ghost of incense — frankincense or myrrh, the kind burned in churches and temples. It clings to the stone like a memory that refuses to fade.",

    on_listen = "Silence. A deeper silence than the cellar — no dripping water, no scratching rats. The stone walls absorb sound; your own breathing seems muffled, as if the room is swallowing it. When you speak, there's a faint echo from the vaulted ceiling, delayed and hollow, like a cathedral whisper. The silence feels intentional, curated — this is a place built for quiet contemplation or prayer.",

    temperature = 9,
    moisture = 0.3,
    light_level = 0,

    instances = {
        -- Room-level objects
        { id = "stone-altar",        type = "Stone Altar",       type_id = "5178dm1k-e8f9-420a-451b-6798de567890", location = "room" },
        { id = "unlit-sconce-east",  type = "Unlit Sconce",      type_id = "6289en2l-f900-431b-562c-780aef678901", location = "room" },
        { id = "unlit-sconce-west",  type = "Unlit Sconce",      type_id = "6289en2l-f900-431b-562c-780aef678901", location = "room" },
        { id = "stone-sarcophagus",  type = "Stone Sarcophagus", type_id = "a62dir6p-3d44-475f-9060-b24e23012345", location = "room" },
        { id = "chain",              type = "Chain",             type_id = "c84fkt8r-5f66-497f-b282-d46045234567", location = "room" },

        -- Altar surfaces
        { id = "incense-burner",     type = "Incense Burner",    type_id = "739afo3m-0a11-442c-673d-891bf0789012", location = "stone-altar.top" },
        { id = "tattered-scroll",    type = "Tattered Scroll",   type_id = "840bgp4n-1b22-453d-784e-902c01890123", location = "stone-altar.top" },
        { id = "offering-bowl",      type = "Offering Bowl",     type_id = "b73ejs7q-4e55-486f-a171-c35f34123456", location = "stone-altar.top" },

        -- Hidden inside sarcophagus (accessible once lid pushed aside)
        { id = "silver-key",         type = "Silver Key",        type_id = "951chq5o-2c33-464e-895f-a13d12901234", location = "stone-sarcophagus.inside" },
    },

    exits = {
        south = {
            target = "storage-cellar",
            type = "door",
            passage_id = "storage-deep-door",
            name = "the iron door",
            keywords = {"door", "iron door", "south door", "iron-bound door"},
            description = "The iron door stands open behind you, leading back to the narrow storage vault.",

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
                        description = "The iron door is shut, cutting off the storage vault behind you.",
                    },
                    message = "You push the heavy door shut. It booms closed, and the echoes take a long time to die in this vaulted space.",
                },
                open = {
                    becomes_exit = {
                        open = true,
                        description = "The iron door stands open, leading back to the narrow storage vault.",
                    },
                    message = "The door groans open, and a faint draught of warmer air drifts in from the storage vault.",
                },
            },
        },

        up = {
            target = "hallway",
            type = "stairway",
            passage_id = "deep-cellar-hallway-stairway",
            name = "a wide stone stairway",
            keywords = {"stairs", "stairway", "staircase", "up", "steps", "stone stairs", "stone stairway"},
            description = "Wide stone steps ascend through the north wall, curving upward toward a faint warmth and the suggestion of light. The stairway is older than the cellars above — carved from the living rock, worn smooth by centuries of passage.",

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

        west = {
            target = "crypt",
            type = "archway",
            passage_id = "deep-cellar-crypt-archway",
            name = "a stone archway with an iron gate",
            keywords = {"archway", "arch", "gate", "iron gate", "west", "crypt", "passage"},
            description = "A stone archway is set into the west wall, its rounded top carved with symbols that match those on the altar. An iron gate blocks the passage, secured with a silver padlock that gleams dully in the light. Beyond the gate, stone steps descend into darkness.",
            on_feel = "Iron bars, closely spaced, cold to the touch. A padlock — small, silver, finely made, unlike the crude iron locks above. The bars are solid; this gate was built to last. Through the gaps, you feel colder air and smell something older — dust and dry stone.",

            max_carry_size = 3,
            max_carry_weight = 30,
            requires_hands_free = false,
            player_max_size = 5,

            open = false,
            locked = true,
            key_id = "silver-key",
            hidden = false,
            broken = false,
            one_way = false,
            breakable = false,

            mutations = {
                unlock = {
                    requires = "silver-key",
                    becomes_exit = {
                        locked = false,
                        description = "The stone archway stands open, its iron gate unlocked. The silver padlock hangs loose from the hasp. Beyond, worn stone steps descend into darkness.",
                    },
                    message = "The silver key slips into the padlock with a precise click. The mechanism turns smoothly — finely made, even after centuries. The padlock falls open.",
                },
                open = {
                    condition = function(self) return not self.locked end,
                    becomes_exit = {
                        open = true,
                        description = "The iron gate stands open in the stone archway. Beyond it, worn stone steps descend into a narrow passage that leads west into profound darkness.",
                    },
                    message = "The gate swings open on silent hinges — oiled once, long ago, and preserved by the dry air. A breath of cold, ancient stillness washes over you from the passage beyond.",
                },
                close = {
                    becomes_exit = {
                        open = false,
                        description = "The iron gate is closed in the stone archway, though the silver padlock hangs open.",
                    },
                    message = "You push the gate shut. It closes with a soft, precise click.",
                },
            },
        },
    },

    on_enter = function(self)
        return "You step through the doorway and the world changes. The rough granite gives way to massive, precisely fitted limestone blocks. The ceiling soars into a ribbed vault. The air is colder, drier, and carries the ghost of ancient incense. You have entered somewhere older than the manor above — somewhere built with purpose and reverence."
    end,

    mutations = {},
}
