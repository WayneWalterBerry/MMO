-- stone-alcove.lua — Hidden alcove revealed by chain mechanism (Deep Cellar puzzle 017)
-- States: hidden → revealed
-- Contains altar candles and incense for the ritual puzzle
return {
    guid = "{03ef4073-c48c-4697-bc6e-2e4e67dbb749}",
    template = "furniture",

    id = "stone-alcove",
    material = "stone",
    keywords = {"alcove", "stone alcove", "niche", "wall niche", "recess"},
    size = 4,
    weight = 500,
    categories = {"furniture", "container", "stone"},
    portable = false,

    container = true,
    openable = false,
    accessible = false,
    capacity = 4,
    weight_capacity = 10,
    max_item_size = 2,

    -- Initial state (hidden — invisible to player)
    name = "a stone alcove",
    description = "",
    room_presence = nil,
    on_feel = "Solid stone wall. Nothing here.",
    on_smell = "Cold stone.",
    on_listen = "Silence.",

    location = nil,

    -- FSM
    initial_state = "hidden",
    _state = "hidden",

    states = {
        hidden = {
            name = "a stone alcove",
            description = "",
            room_presence = nil,
            on_feel = "Solid stone wall. Nothing here -- wait. Your fingertips catch a faint seam in the mortar, almost imperceptible. A hairline crack runs in a rectangle, but the stone won't budge.",
            on_smell = "Cold stone and dust.",
            on_listen = "Silence. But if you press your ear to the wall... a faint draught. Air moving behind the stone.",
            on_taste = "Gritite dust and old mortar.",
            accessible = false,
            discoverable = false,

            on_look = function(self)
                return nil
            end,
        },

        revealed = {
            name = "a stone alcove",
            description = "A narrow alcove has opened in the wall where solid stone stood moments ago. The niche is carved from the same pale granite as the chamber walls, its interior smooth and deliberately shaped. Dust motes swirl in the disturbed air. The back wall bears a carved eye-within-triangle motif -- the same symbol found on the altar. Objects rest inside, undisturbed for what must be centuries.",
            room_presence = "A narrow stone alcove has opened in the wall, its contents visible for the first time in centuries.",
            on_feel = "Smooth carved stone inside the niche. The edges are sharp and precise -- this was built by skilled hands. A faint draught flows from somewhere behind the back wall. Dust coats everything inside.",
            on_smell = "Sealed air -- stale, ancient, tinged with old incense and stone dust. The smell of a space that has been closed for a very long time.",
            on_listen = "A faint sighing of air, as if the alcove is breathing after centuries sealed shut. Stone settling.",
            on_taste = "Ancient dust. Dry, mineral, with a ghost of incense resin.",
            accessible = true,

            on_look = function(self, registry)
                local text = self.description
                local items = self.contents or {}
                if #items == 0 then
                    text = text .. "\n\nThe alcove is empty."
                else
                    text = text .. "\n\nInside the alcove:"
                    for _, id in ipairs(items) do
                        local item = registry and registry:get(id)
                        text = text .. "\n  " .. (item and item.name or id)
                    end
                end
                return text
            end,
        },
    },

    transitions = {
        {
            from = "hidden", to = "revealed", verb = "reveal",
            trigger = "chain_mechanism",
            message = "Stone grinds against stone with a deep, resonant groan. A section of wall slides inward and to the left, revealing a narrow alcove carved into the rock. Sealed air rushes out -- stale and ancient, carrying the ghost of old incense. Dust cascades from the edges. Inside, objects rest undisturbed, waiting.",
        },
    },

    mutations = {},
}
