-- candle-stub.lua — Short-lived consumable light source (Crypt)
-- States: unlit → lit → spent (terminal)
return {
    guid = "{076d1bf6-12c3-443f-b88a-85452cb4477c}",
    template = "small-item",

    id = "candle-stub",
    material = "tallow",
    keywords = {"candle", "candle stub", "stub", "wax stub", "old candle", "nub"},
    size = 1,
    weight = 0.1,
    categories = {"light source", "small"},
    portable = true,

    name = "a candle stub",
    description = "A candle stub in a wall niche, barely an inch of yellowed tallow clinging to a blackened wick. It's been here for decades -- maybe centuries. The wax is cracked and discolored. But the wick looks intact.",
    room_presence = "Candle stubs sit in wall niches, dark and forgotten.",
    on_feel = "A tiny nub of hard wax, cracked and brittle. The wick protrudes -- stiff and charred. It's been a long time since this burned.",
    on_smell = "Old tallow -- stale, waxy, faintly rancid.",
    casts_light = false,

    location = nil,

    burn_duration = 1800,
    remaining_burn = 1800,

    prerequisites = {
        light = { requires = {"fire_source"} },
    },

    initial_state = "unlit",
    _state = "unlit",

    states = {
        unlit = {
            name = "a candle stub",
            description = "A candle stub in a wall niche, barely an inch of yellowed tallow clinging to a blackened wick. It's been here for decades -- maybe centuries. The wax is cracked and discolored. But the wick looks intact.",
            room_presence = "Candle stubs sit in wall niches, dark and forgotten.",
            on_feel = "A tiny nub of hard wax, cracked and brittle. The wick protrudes -- stiff and charred. It's been a long time since this burned.",
            on_smell = "Old tallow -- stale, waxy, faintly rancid.",
            casts_light = false,
        },

        lit = {
            name = "a burning candle stub",
            description = "The candle stub burns with a small, trembling flame. The old tallow melts quickly -- this won't last long. A thin pool of liquid wax forms around the base. The light is feeble but precious in this dark place.",
            on_feel = "Warm, soft wax. The stub is melting fast -- your fingers get sticky.",
            on_smell = "Burning tallow -- sharper than a fresh candle. Old wax has a rancid edge.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 1,

            timed_events = {
                { event = "transition", delay = 1800, to_state = "spent" },
            },
        },

        spent = {
            name = "a spent candle stub",
            description = "A flat disc of hardened wax and a charred wick. The candle stub is consumed.",
            on_feel = "A thin wafer of hard wax. The wick is a carbon thread.",
            on_smell = "Ghost of tallow.",
            casts_light = false,
            terminal = true,
        },
    },

    transitions = {
        {
            from = "unlit", to = "lit", verb = "light",
            aliases = {"ignite"},
            requires_tool = "fire_source",
            message = "The ancient wick catches -- reluctantly, as if it had forgotten how. A small, trembling flame. It won't last long, but it's light.",
            fail_message = "You have nothing to light it with.",
        },
        {
            from = "lit", to = "spent", trigger = "auto",
            condition = "timer_expired",
            message = "The candle stub sputters and dies. The old tallow is consumed. Darkness returns.",
            mutate = {
                weight = 0.02,
                categories = { remove = "light source" },
                keywords = { add = "spent" },
            },
        },
    },

    mutations = {},
}
