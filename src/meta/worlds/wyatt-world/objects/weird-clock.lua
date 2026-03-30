return {
    guid = "{7720927E-D162-4983-B685-581F748A784A}",
    template = "furniture",

    id = "weird-clock",
    material = "plastic",
    keywords = {"clock", "wall clock", "weird clock", "strange clock"},
    size = 2,
    weight = 3,
    categories = {"furniture", "fake"},
    portable = false,

    name = "a wall clock",
    description = "A round clock on the wall. Wait... look closely. It has FIFTEEN numbers on it instead of twelve! That's not right! This clock is FAKE!",
    room_presence = "A clock hangs on the wall. Something seems off about it.",
    on_feel = "Smooth round plastic. The hands move but something feels wrong. Too many bumps around the edge!",
    on_smell = "Plastic. Smells like a normal clock.",
    on_listen = "Tick, tick, tick... but the ticks sound funny. Like they're too fast!",
    on_taste = "Tastes like plastic. But this clock is definitely weird!",

    is_fake = true,
    fake_reason = "It has 15 numbers instead of 12.",

    location = nil,
    mutations = {},
}
