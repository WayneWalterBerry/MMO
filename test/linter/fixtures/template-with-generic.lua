-- Template that uses material = "generic" — XR-05 should fire as INFO
-- on templates but NOT as a warning (templates are allowed generic material).
return {
    guid = "00000000-aaaa-bbbb-cccc-000000000099",
    id = "template-with-generic",
    name = "Generic Template",
    keywords = {"template"},
    description = "A template with generic material for testing XR-05.",
    size = 1,
    weight = 1,
    portable = true,
    material = "generic",
    container = false,
    capacity = 0,
    contents = {}
}
