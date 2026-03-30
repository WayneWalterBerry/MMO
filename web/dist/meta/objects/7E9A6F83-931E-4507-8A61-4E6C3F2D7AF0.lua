return {
    guid = "{7E9A6F83-931E-4507-8A61-4E6C3F2D7AF0}",
    template = "furniture",

    id = "arena-clock",
    material = "plastic",
    keywords = {"clock", "arena clock", "wall clock", "ticking clock"},
    size = 2,
    weight = 3,
    categories = {"furniture", "riddle-answer"},
    portable = false,

    name = "a clock on the wall",
    description = "A round clock on the wall. It has two hands and a friendly face painted on the number ring. It ticks steadily. Tick, tock, tick, tock. Hands... face... could this be an answer?",
    room_presence = "A round clock ticks on the wall.",
    on_feel = "Smooth round plastic. The hands are thin metal. You can feel the ticking shake a little!",
    on_smell = "Plastic and a tiny bit of metal. Normal clock smell.",
    on_listen = "Tick. Tock. Tick. Tock. Steady and calm. This clock has HANDS!",
    on_taste = "You lick the clock. Plastic! But hey, this thing has hands AND a face!",

    answers_riddle = "riddle-board-one",

    location = nil,
    mutations = {},
}
