-- grand-prize-vault.lua — The Grand Prize Vault
-- Final reading comprehension puzzle. Difficulty: ★★★★

return {
    guid = "6ec18103-f363-4b70-a168-c64dfaf6c1bf",
    template = "room",

    id = "grand-prize-vault",
    name = "The Grand Prize Vault",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    keywords = {"grand prize", "vault", "prize vault", "treasure room"},
    description = "Gold and silver streamers hang from the ceiling. "
               .. "A giant treasure chest sits in the middle with a combo lock. "
               .. "A letter on a pedestal says it's from MrBeast!",
    short_description = "A sparkly treasure room with a locked chest.",

    goal = { verb = "read", noun = "letter", label = "open the treasure chest" },

    on_feel = "Streamers brush your face like ribbons. "
           .. "The treasure chest feels heavy and cold.",

    on_smell = "It smells like gold glitter and party streamers. Fancy!",

    on_listen = "Soft victory music plays. This room feels special!",

    instances = {},

    exits = {
        up = { target = "beast-studio" },
    },

    mutations = {},
}
