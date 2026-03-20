### 2026-03-19T23:46:13Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** FSM definitions should live INSIDE the object file for ALL objects, not in a separate src/meta/fsms/ directory. Every object file should contain its own finite state machine info -- states, transitions, guards, durations -- all in one place. One file per object, FSM included. No separate FSM definition files. This applies to match, nightstand, matchbox, candle, and every future FSM object. Delete src/meta/fsms/ entirely -- merge FSM definitions back into their object files.
**Why:** User request -- architecture directive. Keeping the FSM separate from the object it describes splits context unnecessarily. The object IS its states. One file = one object = one FSM. Applies globally to all objects.
