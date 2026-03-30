return {
    guid = "{B9A965DD-5FA5-4B0D-8D8B-C7EAE97379E2}",
    template = "furniture",

    id = "prize-chest",
    material = "wood",
    keywords = {"chest", "treasure chest", "prize chest", "big chest", "combination lock"},
    size = 6,
    weight = 40,
    categories = {"furniture", "container", "challenge"},
    portable = false,

    container = true,
    openable = true,
    accessible = false,
    capacity = 5,
    weight_capacity = 20,
    max_item_size = 4,

    name = "a giant treasure chest",
    description = "A HUGE treasure chest in the center of the room! It's made of dark wood with gold bands. A combination lock with three dials sits on the front. Each dial needs a number. The letter has the clues!",
    room_presence = "A giant treasure chest sits in the center with a combination lock.",
    on_feel = "Thick wood with cold metal bands. The three dials spin smoothly. Click, click, click!",
    on_smell = "Old wood and metal. It smells like treasure!",
    on_listen = "The dials click when you turn them. Click. Click. Click. What's the combo?",
    on_taste = "You lick the chest. Wood and metal! The treasure is INSIDE!",

    combination = {13, 50, 7},

    location = nil,

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            name = "a giant treasure chest (locked)",
            description = "A huge treasure chest with a combination lock. Three dials wait for the right numbers. Read the letter for clues!",
            on_feel = "Thick wood with metal bands. The lock won't budge. Enter the right combo!",
            accessible = false,
        },
        unlocked = {
            name = "a giant treasure chest (OPEN!)",
            description = "The treasure chest is OPEN! Golden light pours out! Inside sits the most amazing trophy you've ever seen!",
            on_feel = "The lid is open! Warm golden light shines from inside. Reach in!",
            accessible = true,
        },
    },

    transitions = {
        {
            from = "locked", to = "unlocked", verb = "enter",
            aliases = {"type", "dial", "open", "unlock", "input"},
            message = "You turn the dials: 13... 50... 7... CLICK! The lock pops open! The chest lid flies up! Golden light pours out! A booming voice yells: \"WYATT! YOU DID IT! YOU'RE THE CHAMPION!\"",
        },
    },

    mutations = {},
}
