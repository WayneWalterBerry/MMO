return {
    guid = "{79C6EBDE-8521-41B1-9B11-9ED7072806C1}",
    template = "furniture",

    id = "cold-lamp",
    material = "metal",
    keywords = {"lamp", "cold lamp", "weird lamp", "table lamp", "strange lamp"},
    size = 3,
    weight = 5,
    categories = {"furniture", "fake"},
    portable = false,

    name = "a table lamp",
    description = "A lamp on the side table. The switch says ON, but the bulb is ice cold! It gives off no light at all! A lamp that's \"on\" but makes no light? This lamp is FAKE!",
    room_presence = "A lamp sits on the side table. It says it's on but... is it?",
    on_feel = "The bulb is cold. Ice cold! But the switch says ON. That's not right!",
    on_smell = "Cold metal. No warm-bulb smell at all. Suspicious!",
    on_listen = "No buzzing. A real lamp that's on would hum a tiny bit. This one is silent!",
    on_taste = "Tastes like cold metal. This lamp is definitely broken or fake!",

    is_fake = true,
    fake_reason = "The switch says ON but the bulb is ice cold and gives no light.",

    location = nil,
    mutations = {},
}
