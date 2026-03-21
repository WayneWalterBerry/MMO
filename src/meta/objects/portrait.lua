-- portrait.lua — Static decorative/lore object (Hallway)
-- Multiple instances with description overrides for different subjects
return {
    guid = "e06hmv0t-7188-4b91-d4a4-f68267456789",
    template = "furniture",

    id = "portrait",
    material = "wood",
    keywords = {"portrait", "painting", "picture", "face", "frame", "art"},
    size = 4,
    weight = 5,
    categories = {"decorative", "wooden"},
    portable = false,

    name = "a portrait",
    description = "A portrait in a heavy gilded frame, depicting a stern figure in dark clothing. The paint is dark with age and varnish, but the face is clear -- stern eyes that seem to follow you. A small brass plate at the bottom bears a name.",
    room_presence = "Portraits of stern-faced figures line the walls, their eyes following you in the torchlight.",
    on_feel = "Heavy wooden frame, carved and gilded -- the gold leaf is flaking. The canvas is rough under your fingers. The frame is bolted to the wall.",
    on_smell = "Old varnish and linseed oil. Dust in the frame's crevices.",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
