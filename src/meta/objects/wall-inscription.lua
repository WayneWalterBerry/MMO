-- wall-inscription.lua — Static readable lore object (Crypt)
return {
    guid = "f7ny3c7k-8295-4ca8-e5b5-075338123456",
    template = "furniture",

    id = "wall-inscription",
    material = "stone",
    keywords = {"inscription", "writing", "carving", "text", "words", "engraving", "epitaph"},
    size = 6,
    categories = {"readable", "architecture"},
    portable = false,

    name = "a wall inscription",
    description = "Carved text covers a section of the crypt's south wall. The letters are deep-cut and filled with faded gold paint. The text is in Latin, with some words in the common tongue. Names, dates, blessings -- and warnings.",
    room_presence = "Carved inscriptions cover the south wall in deep-cut gold letters.",
    on_feel = "Deep-carved letters in stone. Your fingers trace the grooves -- each letter is about an inch tall, precise and deliberate. Gold paint flakes away at your touch.",
    on_smell = "Old stone and dust.",
    on_read = "HERE LIE THE CUSTODES -- THE KEEPERS OF THE COVENANT\n\nALDRIC BLACKWOOD -- FOUNDER -- 1138-1197\n\"I built this house upon the secret, and the secret kept us all.\"\n\nELEANOR BLACKWOOD -- KEEPER OF THE WORD -- 1165-1221\n\"She wrote the truth when others would forget.\"\n\nEDMUND BLACKWOOD -- SHIELD OF THE FAMILY -- 1142-1189\n\"He stood between the world and what lies below.\"\n\nTHOMAS BLACKWOOD -- TAKEN TOO SOON -- 1168-1172\n\"The innocent see what the wise refuse to.\"\n\n[A fifth name has been chiseled away. Only fragments remain:\n\"------- BLACKWOOD -- THE L---T -- 11---12--\"\n\"Struck from the record by order of the K------\"]",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
