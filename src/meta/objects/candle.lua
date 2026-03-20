-- candle.lua — FSM-managed consumable light source
-- States: unlit → lit (100 turns) → stub (20 turns, dim) → spent (terminal)
return {
    guid = "992df7f3-1b8e-4164-939a-3415f8f6ffe3",

    id = "candle",
    keywords = {"candle", "tallow", "candle stub", "tallow candle"},
    size = 1,
    weight = 1,
    categories = {"light source"},
    portable = true,

    -- Initial state (unlit)
    name = "a tallow candle",
    description = "A stubby tallow candle, melted into a brass dish crusted with old wax. The wick is blackened but intact, curling like a burnt finger. It is not lit.",
    on_feel = "A smooth wax cylinder, slightly greasy. It tapers to a blackened wick at the top. The brass dish beneath is cold.",
    on_smell = "Faintly waxy -- old tallow and a memory of smoke.",
    casts_light = false,

    location = nil,

    -- FSM
    initial_state = "unlit",
    _state = "unlit",

    states = {
        unlit = {
            name = "a tallow candle",
            description = "A stubby tallow candle, melted into a brass dish crusted with old wax. The wick is blackened but intact, curling like a burnt finger. It is not lit.",
            on_feel = "A smooth wax cylinder, slightly greasy. It tapers to a blackened wick at the top. The brass dish beneath is cold.",
            on_smell = "Faintly waxy -- old tallow and a memory of smoke.",
            casts_light = false,

            on_look = function(self)
                return self.description .. "\n\nIt could be lit, if you had the means."
            end,
        },

        lit = {
            name = "a lit tallow candle",
            description = "A stubby tallow candle gutters in its brass dish, throwing wild shadows that dance across the walls like drunken puppets. The flame is small but fierce, painting everything in shades of amber and coal.",
            room_presence = "A candle burns in its brass dish, casting a warm amber glow.",
            on_feel = "Warm wax, softening near the flame. The brass dish beneath is hot to the touch -- careful.",
            on_smell = "Burning wick and melting tallow. Thin smoke curls upward, acrid and animal.",
            on_listen = "A gentle crackling, and the soft hiss of melting wax. The flame whispers to itself.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 2,
            burn_remaining = 100,

            on_tick = function(obj)
                obj.burn_remaining = obj.burn_remaining - 1
                if obj.burn_remaining <= 0 then
                    return { trigger = "burn_to_stub" }
                elseif obj.burn_remaining == 5 then
                    return { warning = "The candle flame gutters low..." }
                end
            end,

            on_look = function(self)
                return self.description .. "\n\nThe flame shivers with each breath you take."
            end,
        },

        stub = {
            name = "a candle stub",
            description = "A nub of tallow candle, barely more than a wick drowning in a puddle of melted wax in its brass dish. A feeble flame clings to life, casting a dim, flickering glow that barely reaches the walls.",
            room_presence = "A candle stub flickers dimly in its brass dish.",
            on_feel = "A pool of warm wax surrounding a tiny flame. The brass dish is warm.",
            on_smell = "Acrid smoke and the last of the tallow. The end is near.",
            on_listen = "A sputtering hiss. The flame fights for its life.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 1,
            stub_remaining = 20,

            on_tick = function(obj)
                obj.stub_remaining = obj.stub_remaining - 1
                if obj.stub_remaining <= 0 then
                    return { trigger = "stub_expired" }
                elseif obj.stub_remaining == 5 then
                    return { warning = "The candle flame gutters low... it won't last much longer." }
                end
            end,

            on_look = function(self)
                return self.description .. "\n\nIt's almost spent. You should hurry."
            end,
        },

        spent = {
            name = "a spent candle",
            description = "A brass dish holding nothing but a black nub of carbon and a pool of hardened tallow. The candle is gone, consumed entirely. Not even the wick remains.",
            on_feel = "Cold brass dish. A hard nub of carbon in a pool of hardened wax. Dead.",
            on_smell = "The ghost of burnt tallow. Nothing more.",
            casts_light = false,
            terminal = true,

            on_look = function(self)
                return self.description
            end,
        },
    },

    transitions = {
        {
            from = "unlit", to = "lit", verb = "light",
            aliases = {"ignite"},
            requires_tool = "fire_source",
            message = "The wick catches the flame and curls to life, throwing a warm amber glow across the room. Shadows retreat to the corners like startled cats.",
            fail_message = "You have nothing to light it with. The wick stares back at you, cold and uncooperative.",
        },
        {
            from = "lit", to = "unlit", verb = "extinguish",
            message = "You pinch the candle flame between your fingers. A thin ribbon of smoke spirals upward, and then -- darkness.",
        },
        {
            from = "stub", to = "unlit", verb = "extinguish",
            message = "You pinch out the dying candle flame. The last light dies between your fingers.",
        },
        {
            from = "lit", to = "stub", trigger = "auto",
            condition = "burn_to_stub",
            message = "The candle sputters and collapses to a nub. The light dims to a feeble flicker.",
        },
        {
            from = "stub", to = "spent", trigger = "auto",
            condition = "stub_expired",
            message = "The candle flame dies with a final hiss. Darkness returns, absolute and complete.",
        },
    },
}
