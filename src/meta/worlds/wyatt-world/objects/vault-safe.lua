return {
    guid = "{5143D970-B69E-4475-B0CF-ACBE61046C0E}",
    template = "furniture",

    id = "vault-safe",
    material = "metal",
    keywords = {"safe", "vault safe", "big safe", "number pad", "keypad", "combination"},
    size = 7,
    weight = 200,
    categories = {"furniture", "container", "challenge"},
    portable = false,

    container = true,
    openable = true,
    accessible = false,
    capacity = 3,
    weight_capacity = 10,
    max_item_size = 3,

    name = "an enormous safe",
    description = "A giant metal safe against the back wall. It has a number pad with buttons 0 through 9. A sign above says: \"Count it up! The total opens the safe.\" Type the right number to open it!",
    room_presence = "An enormous safe stands against the back wall with a number pad.",
    on_feel = "Cold, heavy metal. The number pad buttons are clicky and fun to press.",
    on_smell = "Cold metal and a tiny bit of oil. Like a bank vault!",
    on_listen = "The buttons beep when you press them. Beep beep beep!",
    on_taste = "You lick the safe. Cold metal! The treasure is INSIDE, silly!",

    combination = 210,

    location = nil,

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            name = "an enormous safe (locked)",
            description = "A giant metal safe. The number pad glows red. It's locked! You need to enter the right number.",
            on_feel = "Cold heavy metal. The door won't budge. Enter the code!",
            accessible = false,
        },
        unlocked = {
            name = "an enormous safe (open!)",
            description = "The safe door swings open! Green lights flash! Inside sits a beautiful golden trophy!",
            on_feel = "The heavy door is open. Warm air flows out. Something shiny is inside!",
            accessible = true,
        },
    },

    transitions = {
        {
            from = "locked", to = "unlocked", verb = "enter",
            aliases = {"type", "input", "dial", "open"},
            message = "You type 210 on the keypad. CLICK! The safe door swings open! Green lights flash everywhere! A booming voice says: \"YOU DID THE MATH!\"",
        },
    },

    mutations = {},
}
