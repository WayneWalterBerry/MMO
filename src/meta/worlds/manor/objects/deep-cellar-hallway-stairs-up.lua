-- deep-cellar-hallway-stairs-up.lua — Portal object: deep cellar side of hallway stairway
-- Paired with: hallway-deep-cellar-stairs-down.lua (hallway side)
-- Replaces: deep-cellar.exits.up (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #203
return {
    guid = "{cf6f88b2-ea66-4b9a-b28e-f01a4203d632}",
    template = "portal",

    id = "deep-cellar-hallway-stairs-up",
    name = "a wide stone stairway",
    material = "stone",
    keywords = {"stairs", "stairway", "staircase", "up", "steps",
                "stone stairs", "stone stairway", "ascend"},
    size = 7,
    weight = 500,
    portable = false,
    categories = {"architecture", "stone", "portal"},

    portal = {
        target = "hallway",
        bidirectional_id = "{2f31b14e-d8f1-4524-b962-1f2b1733c7d2}",
        direction_hint = "up",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "Wide stone steps ascend through the north wall, curving upward toward a faint warmth and the suggestion of light. The stairway is older than the cellars above — carved from the living rock, worn smooth by centuries of passage.",
    room_presence = "Wide stone steps ascend through the north wall, curving upward toward warmth and distant light.",
    on_examine = "Wide stone steps, each one worn into a gentle hollow by centuries of feet, curve upward through the north wall. The stairway is carved from the living rock — not built, but excavated. The walls are smooth limestone, and the steps are broad enough for two to walk abreast. A draught of warmer air gusts intermittently down the stairwell — the manor above is heated. At the top, just out of sight: the faint flicker of torchlight.",
    on_feel = "The stone steps are wide, smooth, and worn into gentle hollows. The walls are close but not confining — smooth limestone, cold and dry. Warmer air gusts down intermittently from above, carrying the promise of heat and light.",
    on_smell = "A draught of warmer air from above carries beeswax, old wood, and the faint char of torch smoke. Below: incense, cold limestone, and ancient dust.",
    on_listen = "Your footsteps echo in the stairwell — each step producing a hollow, cathedral-like sound. From above: the distant crackle of torches. The warm air gusts down in pulses, as if the manor above is breathing.",
    on_taste = "Mineral dust on your tongue. The air tastes of limestone and the faintest trace of torch smoke from above.",

    initial_state = "open",
    _state = "open",

    states = {
        open = {
            traversable = true,
            name = "a wide stone stairway ascending",
            description = "Wide stone steps ascend toward warmth and distant torchlight. A draught of warm air gusts down from above.",
            room_presence = "Wide stone steps ascend through the north wall, curving upward toward warmth and distant light.",
            on_examine = "The stairway is open and clear. Wide stone steps, worn smooth, curve upward toward the manor hallway. Warm air drifts down.",
            on_feel = "Smooth, worn stone steps. Warm air from above.",
            on_smell = "Beeswax, wood, torch smoke from the hallway above.",
            on_listen = "The crackle of distant torches. Warm air gusting down.",
        },
    },

    transitions = {},

    on_traverse = {
        wind_effect = {
            strength = "gust",
            extinguishes = { "candle" },
            spares = { wind_resistant = true },
            message_extinguish = "Halfway up the stairway, a gust of warm air rushes down from above. Your candle flame gutters, flickers wildly — and goes out. Darkness swallows the stairwell.",
            message_spared = "A gust of warm air rushes down the stairway. Your lantern flame dances behind its glass chimney but holds steady.",
            message_no_light = nil,
        },
    },

    mutations = {},
}
