-- grand-prize-vault.lua — The Grand Prize Vault
-- Final reading comprehension puzzle. Difficulty: ★★★★

return {
    guid = "6ec18103-f363-4b70-a168-c64dfaf6c1bf",
    template = "room",

    id = "grand-prize-vault",
    name = "The Grand Prize Vault",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    light_level = 2,
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

    instances = {
        { id = "prize-chest", type = "Prize Chest", type_id = "{B9A965DD-5FA5-4B0D-8D8B-C7EAE97379E2}" },
        { id = "letter-pedestal", type = "Letter Pedestal", type_id = "{81445BAD-B4CF-4504-914F-4CFB1DE487DE}",
            on_top = {
                { id = "mrbeast-letter", type = "MrBeast Letter", type_id = "{3DB289BD-68DC-4530-A659-3C7DF72887E4}" },
            },
        },
        { id = "vault-golden-trophy", type = "Vault Golden Trophy", type_id = "{9CA2AC12-F5B6-4B41-BAEB-43BC44830092}" },
        { id = "vault-streamers", type = "Vault Streamers", type_id = "{2E77BCA5-39D6-4495-9470-53DE5400D2AA}" },
        { id = "victory-confetti-cannon", type = "Victory Confetti Cannon", type_id = "{32DF1F7E-5EAB-4239-A77B-B52B18410B50}" },
        { id = "golden-mrbeast-trophy", type = "Golden MrBeast Trophy", type_id = "{B48E2564-F4BD-4FB6-86D8-EDF46E1B9CEB}" },
    },

    exits = {
        up = { target = "beast-studio" },
    },

    mutations = {},
}
