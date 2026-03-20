### 2026-03-20T03:43Z: User directive — Room layout and movable furniture
**By:** Wayne Berry (via Copilot)
**What:**
1. **Movable furniture:** Players should be able to move objects around the room (push bed, pull rug, etc.)
2. **Room layout / spatial relationships:** The bed is ON the rug. The rug COVERS a trap door. This implies layered spatial positioning — objects can be on top of other objects, and moving the top object reveals what's underneath.
3. **Hidden objects:** The trap door is hidden under the rug. Moving the rug reveals it. This is a discovery mechanic tied to spatial manipulation.
4. **Next test pass (pass-003):** Nelson should specifically test moving things around the room — push/pull/move furniture, discover what's underneath, interact with spatial relationships.

5. **Hidden until revealed:** The trap door is INVISIBLE until the rug is moved. You can't see it, feel it, or interact with it while the rug covers it. Moving the rug is the trigger that makes the trap door exist in the player's world.
6. **Stacking rules:** Some objects can be stacked on, some can't. The bed can have things on it (pillows, sheets, a person). The rug can have heavy furniture on it. But you can't stack a wardrobe on a candle. Objects should declare whether they are stackable surfaces and what weight/size they can support.

**Why:** User request — spatial relationships, movable furniture, hidden objects, and stacking rules create discovery puzzles and emergent gameplay. The rug→trap door is the first exit from the bedroom.
