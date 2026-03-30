return {
    guid = "{80714F5B-258A-417D-8139-6DCE7E4A8764}",
    template = "furniture",

    id = "stage-hole",
    material = "wood",
    keywords = {"hole", "stage hole", "pit", "gap", "opening"},
    size = 3,
    weight = 0,
    categories = {"furniture", "riddle-answer"},
    portable = false,

    name = "a hole in the stage floor",
    description = "A round hole in the wooden stage floor. It's really dark down below. The more you dig, the bigger a hole gets! The more you take from it... the bigger it gets!",
    room_presence = "A round hole sits in the stage floor.",
    on_feel = "Rough wooden edges around the opening. Cool air blows up from below. The more you take, the bigger it gets!",
    on_smell = "Cool, dusty air rises from below. Smells like under a stage.",
    on_listen = "A faint echo when you shout into it. Helloooo! ...ellooo!",
    on_taste = "You lick the edge of the hole. Dusty wood! Don't fall in!",

    answers_riddle = "riddle-board-three",

    location = nil,
    mutations = {},
}
