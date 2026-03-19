return {
    guid = "009b0347-2ba3-45d1-a733-7a587ad1f5c9",
    template = "small-item",

    id = "match",
    name = "a wooden match",
    keywords = {"match", "stick", "matchstick", "lucifer", "wooden match"},
    description = "A small wooden match with a bulbous red-brown tip. The head is slightly rough to the touch and smells faintly of sulphur. Unlit and inert -- it needs a striker surface to ignite.",

    on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
    on_smell = "Faintly sulfurous.",

    size = 1,
    weight = 0.01,
    categories = {"small", "consumable"},
    portable = true,

    location = nil,

    on_look = function(self)
        return self.description
    end,

    -- A match is NOT a fire_source by default. It must be STRUCK on a
    -- striker surface (the matchbox) to ignite. This is a compound action:
    -- STRIKE match ON matchbox → match mutates to match-lit.
    mutations = {
        strike = {
            becomes = "match-lit",
            requires = "matchbox",
            requires_property = "has_striker",
            message = "You drag the match head across the striker strip. It sputters once, twice -- then catches with a sharp hiss and a curl of sulphur smoke. A tiny flame dances at the tip.",
            fail_message = "You need a rough surface to strike it on. A matchbox striker, perhaps.",
        },
    },
}
