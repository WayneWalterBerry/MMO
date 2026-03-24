-- chamber-pot.lua — Container + improvised helmet (pot-on-head trope)
-- Wearable: head slot, material-derived armor (ceramic → engine armor interceptor)
-- FSM: intact → cracked → shattered (degradation from impact)
-- See: docs/objects/chamber-pot.md, Issue #54, Phase A7
return {
    guid = "{9a9ff109-93a0-4dcf-9d6e-0f0f4b83f4ba}",
    template = "container",
    id = "chamber-pot",
    material = "ceramic",
    name = "a ceramic chamber pot",
    keywords = {"chamber pot", "pot", "ceramic pot", "toilet", "chamberpot", "privy",
                "helmet", "head pot", "improvised helmet"},
    room_presence = "A ceramic chamber pot sits discreetly in the far corner.",
    description = "A squat ceramic chamber pot with the quiet dignity of an object that knows exactly what it is for. It is mercifully empty, glazed in a chipped blue-and-white pattern that suggests someone once thought aesthetics mattered even here.",

    on_feel = "A ceramic bowl, smooth-glazed and cold. The rim is chipped in places.",
    on_smell = "You'd rather not. Even empty, the memory of its purpose lingers.",
    on_smell_worn = "You catch a faint whiff of... you'd rather not think about it.",

    size = 2,
    weight = 3,
    categories = {"ceramic", "container", "fragile", "wearable"},
    room_position = "sits discreetly in the far corner",
    portable = true,
    container = true,
    capacity = 2,

    -- Engine helmet detection — semantic tag only
    -- Armor protection derived from material = "ceramic" via engine armor interceptor
    wear_slot = "head",
    is_helmet = true,

    -- Wearable as makeshift head armor — no hardcoded provides_armor
    -- Engine calculates protection from material (ceramic) properties
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 0.8,
        fit = "makeshift",
        wear_quality = "makeshift",
    },

    -- One-shot flavor text (event_output system — fires once, engine nils it out)
    event_output = {
        on_wear = "This is going to smell worse than I thought.",
    },

    -- Mirror/appearance narration when worn on head
    appearance = {
        worn_description = "A ceramic chamber pot sits absurdly atop your head.",
    },

    contents = {},
    location = nil,

    -- FSM: degradation from impact (intact → cracked → shattered)
    initial_state = "intact",
    _state = "intact",

    states = {
        intact = {
            name = "a ceramic chamber pot",
            description = "A squat ceramic chamber pot with the quiet dignity of an object that knows exactly what it is for. It is mercifully empty, glazed in a chipped blue-and-white pattern that suggests someone once thought aesthetics mattered even here.",
            room_presence = "A ceramic chamber pot sits discreetly in the far corner.",
            on_feel = "A ceramic bowl, smooth-glazed and cold. The rim is chipped in places.",
            on_smell = "You'd rather not. Even empty, the memory of its purpose lingers.",
        },

        cracked = {
            name = "a cracked ceramic chamber pot",
            description = "A squat ceramic chamber pot, now bearing a visible crack that runs from rim to base. The blue-and-white glaze has splintered along the fracture line. It still holds together, but one more good hit would finish it.",
            room_presence = "A cracked ceramic chamber pot sits in the corner, leaking dignity.",
            on_feel = "Your fingers find the crack immediately — a sharp ridge of broken glaze running the length of the bowl. Handle with care.",
            on_smell = "The crack has opened up old residue to the air. The smell is worse now.",
        },

        shattered = {
            name = "shattered remains of a chamber pot",
            description = "What was once a chamber pot is now a scatter of blue-and-white ceramic fragments. The largest piece still shows a bit of the original glaze pattern.",
            room_presence = "Ceramic fragments litter the floor — the remains of a chamber pot.",
            on_feel = "Sharp ceramic edges. Mind your fingers.",
            on_smell = "Clay dust and old memories.",
        },
    },

    transitions = {
        {
            from = "intact", to = "cracked", verb = "hit",
            aliases = {"kick", "strike", "smash"},
            message = "The chamber pot takes a solid hit. A crack spiders across the glaze with a sharp *tink*. It holds together — barely.",
            mutate = {
                keywords = { add = "cracked" },
            },
        },
        {
            from = "cracked", to = "shattered", verb = "hit",
            aliases = {"kick", "strike", "smash"},
            message = "The cracked chamber pot explodes into fragments, sending ceramic shards skittering across the stone floor.",
            mutate = {
                becomes = nil,
                spawns = {"ceramic-shard", "ceramic-shard"},
            },
        },
    },

    on_look = function(self)
        if self.contents and #self.contents > 0 then
            local text = self.description .. "\n\nInexplicably, it contains:"
            for _, id in ipairs(self.contents) do
                text = text .. "\n  " .. id
            end
            return text
        end
        return self.description .. "\n\nIt is, thankfully, empty."
    end,

    mutations = {
        shatter = {
            becomes = nil,
            spawns = {"ceramic-shard", "ceramic-shard"},
            narration = "The ceramic chamber pot shatters on the stone floor, sending fragments skittering across the room.",
        },
    },
}
