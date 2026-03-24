-- brass-spittoon.lua — Container + improvised helmet (brass counterpart to chamber pot)
-- Wearable: head slot, makeshift armor, durable brass (fragility 0.1 — dents, never shatters)
-- FSM: clean → stained → dented (cosmetic degradation only)
-- See: docs/objects/brass-spittoon.md
return {
    guid = "{b763fdf9-f7d2-4eac-8952-7c03771c5013}",
    template = "container",
    id = "brass-spittoon",
    material = "brass",
    name = "a brass spittoon",
    keywords = {"spittoon", "brass spittoon", "brass bowl", "cuspidor", "spit bowl",
                "helmet", "improvised helmet"},
    room_presence = "A dull brass spittoon sits on the floor, doing its best to be ignored.",
    description = "A wide-mouthed brass spittoon, the kind once found in every saloon and gentleman's club. The rim is rolled outward for stability, the bowl deep enough to serve its unsavoury purpose. Years of tarnish have dulled the brass to a mottled brown-gold, but the metal is solid and heavy — built to survive being kicked, dropped, and worse.",

    on_feel = "Heavy, cold brass. The rolled rim is smooth; the bowl interior is rough with tarnish and mineral deposits. Solid — you could drop this off a roof and it would survive.",
    on_smell = "Stale tobacco, old saliva, and tarnished brass. A cocktail nobody ordered.",
    on_listen = "A resonant *bong* when flicked — the sound of thick brass, ringing like a dull bell.",
    on_taste = "You put your tongue to a spittoon. The tarnish tastes of pennies and regret. The interior is worse.",
    on_smell_worn = "Tarnished brass and the ghost of a thousand expectorations hover around your temples.",

    size = 2,
    weight = 4,
    categories = {"brass", "container", "metal", "wearable"},
    room_position = "sits on the floor near the wall",
    portable = true,
    container = true,
    capacity = 2,

    -- Engine helmet detection (appearance.lua + concussion reduction)
    wear_slot = "head",
    is_helmet = true,
    reduces_unconsciousness = 1,

    -- Wearable as makeshift head armor — brass is durable (fragility 0.1)
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 0.7,
        fit = "makeshift",
        provides_armor = 2,
        wear_quality = "makeshift",
    },

    -- Mirror/appearance narration when worn on head
    appearance = {
        worn_description = "A tarnished brass spittoon crowns your head like a deeply unfortunate hat.",
    },

    contents = {},
    location = nil,

    -- FSM: cosmetic degradation only (clean → stained → dented)
    initial_state = "clean",
    _state = "clean",

    states = {
        clean = {
            name = "a brass spittoon",
            description = "A wide-mouthed brass spittoon, tarnished but structurally sound. The rolled rim gleams faintly where fingers have worn through the patina.",
            room_presence = "A dull brass spittoon sits on the floor, doing its best to be ignored.",
            on_feel = "Heavy, cold brass. The rolled rim is smooth; the bowl interior is rough with tarnish. Solid and whole.",
            on_smell = "Stale tobacco, old saliva, and tarnished brass. A cocktail nobody ordered.",
            on_listen = "A resonant *bong* when flicked — clear, ringing brass.",
        },

        stained = {
            name = "a stained brass spittoon",
            description = "A wide-mouthed brass spittoon, its interior discoloured by years of use. Dark rings mark high-water lines of accumulated filth. The brass is still solid underneath the grime.",
            room_presence = "A stained brass spittoon sits on the floor, reeking of old tobacco.",
            on_feel = "Heavy brass, the interior sticky with residue. The rolled rim is still smooth, but the bowl is gritty.",
            on_smell = "Concentrated tobacco juice, dried saliva, and something that might once have been chewing tobacco. Deeply unpleasant.",
            on_listen = "A slightly deadened *thunk* when flicked — the residue absorbs some of the ring.",
        },

        dented = {
            name = "a dented brass spittoon",
            description = "A brass spittoon bearing a significant dent in one side. The rolled rim is warped but unbroken. The brass took the hit and lived — which is more than can be said for whatever hit it.",
            room_presence = "A dented brass spittoon sits lopsidedly on the floor.",
            on_feel = "Heavy brass with a deep dent on one side. The rim is warped but the metal holds. Still solid — brass bends but doesn't break.",
            on_smell = "Tarnished brass and old tobacco, now with the sharp metallic edge of freshly stressed metal.",
            on_listen = "A flat *clank* when flicked — the dent has ruined the resonance.",
        },
    },

    transitions = {
        {
            from = "clean", to = "stained", verb = "use",
            aliases = {"spit"},
            message = "You spit into the spittoon. The brass bowl rings with a wet *pting*. A dark stain begins to spread across the interior.",
            mutate = {
                keywords = { add = "stained" },
            },
        },
        {
            from = "stained", to = "dented", verb = "dent",
            aliases = {"kick", "hit", "strike"},
            message = "The spittoon takes a solid hit and caves inward with a deep brass *clang*. The dent is impressive, but the metal holds. Brass doesn't shatter.",
            mutate = {
                keywords = { add = "dented" },
            },
        },
        {
            from = "clean", to = "dented", verb = "dent",
            aliases = {"kick", "hit", "strike"},
            message = "The spittoon takes a solid hit. The brass buckles inward with a resonant *bong* but holds firm. Dented, not broken.",
            mutate = {
                keywords = { add = "dented" },
            },
        },
    },

    on_look = function(self)
        if self.contents and #self.contents > 0 then
            local text = self.description .. "\n\nIt contains:"
            for _, id in ipairs(self.contents) do
                text = text .. "\n  " .. id
            end
            return text
        end
        return self.description .. "\n\nIt is, mercifully, empty."
    end,

    mutations = {},
}
