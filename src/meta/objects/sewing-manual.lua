return {
    guid = "3f8a1c9d-7e52-4b6f-a831-9d4e6f2c8b71",
    template = "small-item",

    id = "sewing-manual",
    name = "a dog-eared sewing manual",
    keywords = {"manual", "book", "sewing manual", "instructions", "pamphlet", "booklet", "guide"},
    description = "A thin pamphlet bound in faded cloth, its pages dog-eared and stained with what might be tea or blood. The cover reads: 'A Practical Guide to Needlework for the Desperate and Untalented.' Inside, careful diagrams show basic stitches, thread tension, and how to avoid stabbing yourself (mostly).",

    on_feel = "A thin booklet, cloth-bound. The pages are soft from use, the corners rounded.",
    on_smell = "Old paper and faded ink. A faint whiff of lavender pressed between the pages.",

    size = 1,
    weight = 0.1,
    categories = {"small", "readable", "paper"},
    portable = true,

    -- Skill granting: reading this teaches the sewing skill
    grants_skill = "sewing",
    skill_message = "You study the instructions carefully. You now understand basic sewing.",
    already_learned_message = "You flip through the manual again, but you already know this. The diagrams of running stitches and blanket stitches are familiar now.",

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nIt looks like it could be read."
    end,

    mutations = {},
}
