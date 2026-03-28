-- Object B: shares keyword "shiny" with keyword-collision-a.lua
-- Used to test XF-03 keyword collision detection.
return {
    guid = "{30000000-aaaa-bbbb-cccc-000000000002}",
    id = "keyword-collision-b",
    template = "small-item",
    name = "a shiny coin",
    keywords = {"coin", "shiny"},
    description = "A worn shiny coin.",
    on_feel = "Thin metal disc with raised edges.",
    material = "wool"
}
