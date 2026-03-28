-- Object A: shares keyword "shiny" with keyword-collision-b.lua
-- Used to test XF-03 keyword collision detection.
return {
    guid = "{30000000-aaaa-bbbb-cccc-000000000001}",
    id = "keyword-collision-a",
    template = "small-item",
    name = "a shiny bauble",
    keywords = {"bauble", "shiny"},
    description = "A small shiny bauble.",
    on_feel = "Smooth glass surface.",
    material = "wool"
}
