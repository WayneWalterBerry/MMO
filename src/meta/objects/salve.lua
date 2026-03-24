-- salve.lua — Healing consumable (clay pot of ointment)
-- States: sealed → open → empty (terminal)
-- Apply to wounds to heal injuries (parser support: #109)
return {
    guid = "{b05f1c4d-0a3f-4f8a-aae4-2aae6e171ddf}",
    template = "small-item",

    id = "salve",
    material = "ceramic",
    keywords = {"salve", "ointment", "balm", "healing salve", "pot", "clay pot", "medicine"},
    size = 1,
    weight = 0.3,
    categories = {"small-item", "medical", "consumable", "ceramic"},
    portable = true,

    is_consumable = true,
    consumable_type = "ointment",
    reusable = false,
    cures = {"bleeding", "minor-cut", "bruise"},
    healing_boost = 3,

    name = "a small clay pot of salve",
    description = "A squat clay pot, thumb-sized, sealed with a disc of wax. The rough ceramic is stamped with a crude mortar-and-pestle mark -- an apothecary's seal. Whatever is inside smells faintly herbal, even through the wax.",
    room_presence = "A small clay pot sits here, sealed with wax.",
    on_feel = "A small clay pot of thick, waxy ointment. The ceramic is rough and cool. A wax disc seals the top.",
    on_smell = "Herbal -- rosemary, maybe comfrey. Medicinal but not unpleasant.",
    on_listen = "Nothing. The contents are too thick to slosh.",

    location = nil,

    initial_state = "sealed",
    _state = "sealed",

    states = {
        sealed = {
            name = "a small clay pot of salve",
            description = "A squat clay pot, thumb-sized, sealed with a disc of wax. The rough ceramic is stamped with a crude mortar-and-pestle mark -- an apothecary's seal. Whatever is inside smells faintly herbal, even through the wax.",
            on_feel = "A small clay pot of thick, waxy ointment. The ceramic is rough and cool. A wax disc seals the top.",
            on_smell = "Herbal -- rosemary, maybe comfrey. Medicinal but not unpleasant, even through the wax seal.",
            on_taste = "You lick the wax seal. Beeswax and dust. You'd need to open it first.",
            on_listen = "Nothing. The contents are too thick to slosh.",
        },

        open = {
            name = "an open pot of salve",
            description = "A small clay pot, the wax seal broken away. Inside is a thick, pale-green ointment that glistens in the light. It smells strongly of herbs -- comfrey and rosemary, with a sharp camphor bite underneath.",
            on_feel = "The ointment is thick and cool, slightly grainy between your fingers. It leaves a waxy film on your skin.",
            on_smell = "Strong herbal scent -- comfrey, rosemary, and sharp camphor. Medicinal.",
            on_taste = "Bitter herbs and wax. Not meant to be eaten, but not harmful.",
            on_listen = "Silence. The salve is too thick to make any sound.",
        },

        empty = {
            name = "an empty clay pot",
            description = "A small clay pot, scraped clean inside. A faint green residue and the ghost of herbal scent are all that remain of the salve.",
            on_feel = "Rough clay, empty and light. A faint waxy residue inside.",
            on_smell = "The faintest trace of herbs. Nearly gone.",
            on_taste = "Clay and a whisper of old ointment. Nothing useful left.",
            on_listen = "A hollow tap when you flick the rim.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "sealed", to = "open", verb = "open",
            aliases = {"unseal", "break seal", "pry"},
            requires_free_hands = true,
            message = "You dig your thumbnail under the wax disc and pry it free. The seal cracks away in flakes, revealing a thick, pale-green ointment underneath. A sharp herbal smell rises.",
            mutate = {
                weight = function(w) return w - 0.02 end,
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "empty", verb = "apply",
            aliases = {"use", "rub", "spread", "smear"},
            requires_target_injury = true,
            message = "You scoop the thick ointment with your fingers and spread it across the wound. It stings briefly, then a cool numbness spreads. The salve soaks in quickly, leaving a thin waxy film over the injury.",
            effect = {
                type = "heal_injury",
                source = "salve",
                healing = 3,
                message = "The salve draws the pain out. The wound already looks better.",
            },
            mutate = {
                weight = 0.15,
                is_consumable = false,
                keywords = { add = "empty" },
            },
        },
    },

    prerequisites = {
        apply = { requires_state = "open", requires_target_injury = true },
        open = { requires_state = "sealed", requires_free_hands = true },
    },

    mutations = {},
}
