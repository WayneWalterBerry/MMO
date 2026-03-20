### 2026-03-20T00:16:18Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Chamber-pot is a type of pot (inherits from pot base class). Pots can be worn on your head as improvised head armor. So: chamber-pot is wearable (wear_slot = "head", wear_layer = "outer"). Yes, this means you can wear a chamber pot on your head. It's a terrible helmet but it works. The object hierarchy matters here -- pot is a base type, chamber-pot inherits pot's wearability.
**Why:** User request -- establishes object inheritance (base class → subtype) and confirms pots-as-helmets gameplay. The chamber pot on head is both functional (head protection) and hilarious (it's a chamber pot).
