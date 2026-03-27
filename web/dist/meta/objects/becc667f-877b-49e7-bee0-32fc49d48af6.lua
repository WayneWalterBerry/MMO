-- hallway-deep-cellar-stairs-down.lua — Portal object: hallway side of deep cellar stairway
-- Paired with: deep-cellar-hallway-stairs-up.lua (deep cellar side)
-- Replaces: hallway.exits.down (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #203
return {
    guid = "{becc667f-877b-49e7-bee0-32fc49d48af6}",
    template = "portal",

    id = "hallway-deep-cellar-stairs-down",
    name = "stone steps descending",
    material = "stone",
    keywords = {"stairs", "stairway", "staircase", "down", "steps",
                "stone stairs", "descend", "cellar", "stone steps"},
    size = 7,
    weight = 500,
    portable = false,
    categories = {"architecture", "stone", "portal"},

    portal = {
        target = "deep-cellar",
        bidirectional_id = "{2f31b14e-d8f1-4524-b962-1f2b1733c7d2}",
        direction_hint = "down",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "Stone steps descend through an archway in the floor, curving down into the cool darkness of the cellars below. A chill draught rises from the depths.",
    room_presence = "Stone steps descend through an archway in the floor, curving down into cool darkness below.",
    on_examine = "Stone steps descend through a wide archway in the floor, curving down and out of sight. The steps are carved from the living rock — ancient work, older than the manor. The polished oak floor gives way abruptly to bare stone. A chill draught rises from below, carrying the smell of cold limestone, ancient dust, and the ghost of incense.",
    on_feel = "The transition is stark: warm, polished oak gives way to cold, worn stone. The first steps are broad and shallow, but they narrow as they descend. The walls are smooth limestone, cold to the touch. A draught of cold air rises from below.",
    on_smell = "A chill draught rises from below — cold limestone, mineral dust, the ghost of incense or old candle wax. A stark contrast to the warm beeswax and torch smoke of the hallway.",
    on_listen = "Your footsteps change from the hollow tap of oak to the muffled thud of stone. From below: silence. A deep, absorbing silence that swallows sound. The torches behind you crackle, but the sound doesn't carry far down the stairwell.",
    on_taste = "The air changes as you descend — from warm and smoky to cold and mineral. Limestone dust on your tongue.",

    initial_state = "open",
    _state = "open",

    states = {
        open = {
            traversable = true,
            name = "stone steps descending",
            description = "Stone steps descend through an archway in the floor into the cool darkness of the cellars below. A chill draught rises.",
            room_presence = "Stone steps descend through an archway in the floor, curving down into cool darkness below.",
            on_examine = "The stairway is open and clear. Stone steps descend into the deep cellar. Cold air rises.",
            on_feel = "Worn stone steps, cold and smooth. A chill draught from below.",
            on_smell = "Cold limestone, ancient dust, the ghost of incense from below.",
            on_listen = "Silence from below. The stairs descend into absorbing quiet.",
        },
    },

    transitions = {},

    on_traverse = {
        wind_effect = {
            strength = "gust",
            extinguishes = { "candle" },
            spares = { wind_resistant = true },
            message_extinguish = "As you descend, a chill updraft gusts through the stairwell from the cellars below. Your candle flame flattens, sputters — and dies. Cold darkness rushes in.",
            message_spared = "A chill updraft gusts up from below as you descend. Your lantern flame shivers behind its glass but holds.",
            message_no_light = nil,
        },
    },

    mutations = {},
}
