# In-Game Bug Reporting System

## Overview

Players can type `report bug` or `report a bug` during gameplay to file a GitHub issue directly from the game. The system captures the current game state, recent session transcript, and contextual metadata, then opens a pre-filled issue form in the public issues repository. This enables seamless bug reporting without leaving the game or breaking immersion.

## Architecture

### Verb Recognition

The bug reporting system is triggered via the parser as a special command verb:

- **Recognized patterns:** `report bug` / `report a bug`
- **Handler location:** `src/engine/verbs/init.lua`
- **Parser integration:** Registered as a built-in verb alongside other commands
- **Execution:** When matched, immediately initiates the issue generation and delivery flow

### Transcript Capture

The engine maintains a rolling buffer of recent game output to provide context in bug reports:

- **Buffer size:** Last 50 lines of displayed output
- **Content:** All output text, including:
  - Game responses and narration
  - NPC dialogue
  - System messages
  - Room descriptions
  - NOT just player commands
- **Maintenance:** `src/engine/loop/init.lua` continuously updates the buffer as new output is generated
- **Purpose:** Provides enough session history for developers to understand the context and reproduce the issue

### Issue Metadata

Each generated issue includes contextual metadata about the player's current state:

- **Level name** — Human-readable level identifier (e.g., "Level 1: The Awakening")
- **Room name** — Current location (e.g., "The Bedroom")
- **Build timestamp** — When the game version was compiled/deployed
- **Browser/platform info** — Web platform only (e.g., Chrome 120, Safari on iOS)
  - CLI builds omit this field
- **Player session ID** — Tracking identifier for correlating multiple issues from the same session

### Issue Body Format

The GitHub issue is pre-filled with structured markdown:

```markdown
## Session Context
- **Level:** {level_name}
- **Room:** {room_name}
- **Build:** {build_timestamp}
- **Platform:** {platform_info}

## Transcript
{transcript_last_50_lines}

---

## Description
_Please describe the bug you encountered:_
```

The markdown structure separates:
1. **Session Context** — Metadata section for quick triage
2. **Transcript** — Game output leading to the bug
3. **Description** — Blank section for the player to fill in

### Issue Delivery

The system opens a pre-filled GitHub issue URL using platform-specific mechanisms:

**Web:**
- Calls `window._openUrl()` JavaScript bridge defined in `web/bootstrapper.js`
- Executes `window.open()` to launch the issue form in a new browser tab
- Triggered via Lua bridge in `web/game-adapter.lua`

**CLI:**
- Prints the full GitHub URL to stdout
- Players copy the URL and paste into their browser
- No JavaScript bridge available in CLI environment

## Target Repository

### Repository Details
- **URL:** `https://github.com/WayneWalterBerry/MMO-Issues`
- **Type:** Public repository dedicated to bug reports
- **Access:** No authentication required — anyone with a GitHub account can file an issue
- **Important:** This is NOT the private MMO code repository

### Why a Separate Public Repo
- Decouples issue tracking from game code
- Allows transparent bug reporting without revealing implementation details
- Players can comment and track resolution without access to source code
- Prevents accidental information disclosure from the private repo

### Sharing the URL
The game URL itself is intentionally kept private/hidden. Access to the bug reporting feature is granted by:
- Sharing the game link directly with players
- Game players discover the `report bug` command through gameplay
- Only players with the game URL can file issues

## URL Construction

The bug reporting system constructs a pre-filled GitHub issue URL:

```
https://github.com/WayneWalterBerry/MMO-Issues/issues/new
  ?title=[Bug Report] {room_name} - {timestamp}
  &body={url_encoded_body}
```

**Parameters:**
- `title` — Formatted as `[Bug Report] {room_name} - {ISO_timestamp}`
  - Example: `[Bug Report] The Bedroom - 2024-01-15T14:23:45Z`
- `body` — URL-encoded markdown body (described above)
- Query string encoding — All special characters properly escaped

**Example generated URL:**
```
https://github.com/WayneWalterBerry/MMO-Issues/issues/new?title=%5BBug%20Report%5D%20The%20Bedroom%20-%202024-01-15T14%3A23%3A45Z&body=...
```

## Security Considerations

### No Secrets in Client Code
- No GitHub tokens or API keys stored client-side
- All communication happens through public GitHub URL construction
- No server-side authentication needed

### Public Repository Model
- Anyone can file issues without providing credentials
- No risk of exposing private infrastructure
- GitHub handles spam/abuse filtering

### Game URL Privacy
- The game URL is not published in the issues repository
- Security is maintained through obscurity — players must have direct access
- Session transcripts do not leak the game URL

### Session Transcript Safety
- Transcripts contain room descriptions and game state
- No passwords, tokens, or sensitive player data stored
- All content is generated game text, safe for public viewing

## Implementation Files

### Lua-Side Implementation

**`src/engine/verbs/init.lua`**
- Registers the `report_bug` verb handler
- Calls the transcript capture and metadata collection functions
- Initiates the issue URL construction and delivery

**`src/engine/loop/init.lua`**
- Maintains the rolling 50-line transcript buffer
- Updates buffer on each output cycle
- Provides clean/formatted transcript on demand

### Web/JS-Side Implementation

**`web/bootstrapper.js`**
- Exposes `window._openUrl(url)` JavaScript function
- Implements `window.open(url, '_blank')` to launch issues in new tab
- Called by Lua bridge when delivering the issue URL

**`web/game-adapter.lua`**
- Bridges `open_url()` Lua function to JavaScript
- Marshals the constructed GitHub URL across the Lua-JS boundary
- Handles platform detection for web vs. CLI execution

## Future Enhancements

### Screenshot Capture
- Canvas-based screenshot of current game state
- Append to issue body or attach as separate image file
- Would require additional permissions in web environment

### Automatic Issue Labels
- Auto-apply labels based on metadata:
  - `level-{level_number}` for level filtering
  - `room-{room_name}` for location tracking
  - `platform-web` or `platform-cli` for environment
- Facilitates issue organization and triage

### Duplicate Detection
- Client-side check for similar open issues in the repo
- Warning dialog if a duplicate issue is likely
- Reduces clutter in issue tracker
- May require GitHub API read access

### User Identification
- Optional: Allow players to provide email or username
- Enables follow-up communication from maintainers
- Would require form extension or secondary dialog

### Screenshot Attachments
- Auto-capture game canvas state when `report bug` is issued
- Store as temporary blob and attach to issue submission
- Provides visual context without relying solely on transcript

## Workflow Example

1. **Player encounters issue:** Game displays unexpected behavior
2. **Player types:** `report bug`
3. **System captures:** Current level, room, metadata, and recent transcript
4. **URL generated:** Pre-filled issue template constructed
5. **Web player:** New tab opens with issue form pre-populated
6. **CLI player:** URL printed to stdout for manual copy/paste
7. **Player files issue:** Clicks "Submit new issue" on GitHub
8. **Maintainer triage:** Receives issue with full context for investigation

## References

- GitHub Issues documentation: https://docs.github.com/en/issues/tracking-your-work-with-issues
- URL encoding standards: RFC 3986
- Markdown formatting: https://docs.github.com/en/get-started/writing-on-github
