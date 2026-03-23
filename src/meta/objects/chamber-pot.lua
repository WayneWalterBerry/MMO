-- chamber-pot.lua — Container + improvised helmet (pot-on-head trope)
-- Wearable: head slot, makeshift armor, reduces unconsciousness duration
-- See: docs/objects/chamber-pot.md, Issue #54
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

    -- Engine helmet detection (appearance.lua + concussion reduction)
    wear_slot = "head",
    is_helmet = true,
    reduces_unconsciousness = 1,

    -- Wearable as makeshift head armor (pot-on-head trope)
    wear = {
        slot = "head",
        layer = "outer",
        provides_armor = 1,
        wear_quality = "makeshift",
    },

    -- Mirror/appearance narration when worn on head
    appearance = {
        worn_description = "A ceramic chamber pot sits absurdly atop your head.",
    },

    contents = {},
    location = nil,

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
