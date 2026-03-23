# Bedroom Door — Object Design

Issue: #57

## Description
A heavy oak door with iron bands, set in the north wall of the bedroom. Barred from the hallway side with an iron bar (not a key lock). No keyhole on the bedroom side. Players can examine, knock, listen, push, pull, and feel it. The door is linked to the north exit in start-room.lua.

## FSM States

```
barred → unbarred → open ↔ (close back to unbarred)
barred → broken (destructive, terminal)
```

- **barred** — Default. Iron bar holds door from hallway side. Cannot be opened from bedroom.
- **unbarred** — Bar removed from other side (triggered externally). Door can be pushed open.
- **open** — Door stands open. Can be closed back to unbarred.
- **broken** — Door destroyed by force. Terminal state.

## Sensory Descriptions

| State | Examine | Feel | Listen | Knock | Push | Pull | Smell |
|-------|---------|------|--------|-------|------|------|-------|
| barred | Iron bands, no keyhole, bar creaks | Rough oak, cold iron, no give | Bar shifting in brackets | Deep dull thud, no answer | Won't budge, bar holds | Hinges open inward, bar holds | Old oak and iron |
| unbarred | Free in frame, can push open | Door shifts, no longer held | Draught through gap | Hollow thud, rattles | Ready to open | Hinges open inward | Dust, cold stone, torch smoke |
| open | Open on iron hinges, corridor beyond | Open door edge, cool air | Corridor sounds: dripping, draught | Door swings on hinges | Already open | Already open, could close | Cold stone, old dust |
| broken | Splintered oak, twisted iron | Jagged splinters, bent iron | Corridor fully exposed | Nothing left to knock | Door is gone | Door is gone | Fresh-split oak |

## Transitions

| From | To | Verb | Notes |
|------|-----|------|-------|
| barred | unbarred | unbar (trigger: exit_unbarred) | Externally triggered when bar is removed from hallway side |
| unbarred | open | open / push | Player pushes door open |
| open | unbarred | close / shut | Player closes door |
| barred | broken | break | Requires strength 3. Destructive. |

## Properties

- **Size:** 6, **Weight:** 120, **Portable:** No
- **Material:** `oak` (hardness 4, flammability 0.45)
- **Categories:** architecture, wooden
- **Keywords:** door, oak door, heavy door, bedroom door, barred door, north door, heavy oak door, iron bands
- **Linked Exit:** `north` (passage_id: `bedroom-hallway-door`)

## Exit Linkage

The door object's state is designed to sync with the exit's locked state:
- `barred` state ↔ `exit.locked = true`
- `unbarred`/`open` states ↔ `exit.locked = false`
- `broken` state ↔ `exit.locked = false, exit.broken = true`

The `linked_exit` and `linked_passage_id` fields tell the engine which exit to update when the door's FSM transitions.

## Design Notes

- Bar mechanism (not key lock) — `key_id = nil` on exit, no unlock transition on object
- Breakable from bedroom side with sufficient force (strength 3)
- Unbar transition is triggered externally (hallway side NPC or puzzle solution)
- All 4 states have full sensory coverage: examine, feel, listen, knock, push, pull, smell
