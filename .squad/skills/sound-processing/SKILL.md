---
name: "Sound File Processing Pipeline"
description: "Convert audio files (WAV/MP3) to OGG Opus format and integrate them into the game engine"
domain: "asset-pipeline, audio-engineering, devops"
confidence: "high"
source: "earned"
tools:
  - name: "ffmpeg"
    description: "Audio encoding and processing utility"
    when: "Converting and trimming audio files to Opus format"
  - name: "powershell"
    description: "Build automation and metadata generation"
    when: "Running build-meta.ps1 to auto-discover and register audio files"
---

## Context

Sound files are core gameplay assets — ambient loops set atmosphere, creature sounds reveal hidden objects, combat sfx provide feedback. The pipeline ensures all audio is optimized (Opus @ 48kbps mono), consistent in naming, and discoverable by the game engine via auto-generated metadata.

**Trigger:** Developer places raw WAV/MP3 files in `assets/sounds/{category}/` and runs the processing pipeline.

**Outcome:** Game-ready .opus files registered in metadata and deployed via web-publish skill.

## Prerequisites

1. **ffmpeg installed:**
   - Windows (winget): `winget install Gyan.FFmpeg`
   - Windows (choco): `choco install ffmpeg`
   - Verify: `ffmpeg -version`

2. **Directory structure ready:**
   ```
   assets/sounds/
   ├── ambient/
   ├── creatures/
   ├── objects/
   └── combat/
   ```

3. **Git configured to ignore source audio:**
   - `.gitignore` already includes `*.wav` and `*.mp3` (source files too large)
   - Only `.opus` files commit to git

## Patterns

### Step 1: Rename Source Files

Replace generic machine names with descriptive identifiers matching metadata sound IDs:
- ❌ `07067038.wav` 
- ✅ `water-drip.wav`

Naming convention: `{sound-id}.{extension}`

Example mappings:
- `ambient/water-drip` → `water-drip.wav` (source) + `water-drip.opus` (output)
- `creatures/rat-squeak` → `rat-squeak.wav` → `rat-squeak.opus`
- `combat/sword-clang` → `sword-clang.mp3` → `sword-clang.opus`

### Step 2: Classify by Sound Type

**Ambient Loops (10–30s trimmed segments):**
- Background atmosphere (water, wind, fire)
- Should loop seamlessly with no dead air
- Trim to clean loop boundary: `ffmpeg -i input.wav -ss START -t DURATION -c:a libopus -b:a 48k -ac 1 -vn output.opus`
- Example: 18s water loop starting at 2.5s:
  ```powershell
  ffmpeg -i raw-water.wav -ss 2.5 -t 18 -c:a libopus -b:a 48k -ac 1 -vn water-drip.opus
  ```

**One-Shot Sounds (full duration, silence trimmed):**
- Creature calls, object interactions, combat impact
- Keep full duration but strip leading/trailing silence
- Standard conversion:
  ```powershell
  ffmpeg -i input.wav -c:a libopus -b:a 48k -ac 1 -vn output.opus
  ```

### Step 3: Convert to OGG Opus

**Standard conversion command:**
```powershell
ffmpeg -i input.wav -c:a libopus -b:a 48k -ac 1 -vn output.opus
```

**Parameters:**
- `-i input.wav` — input file (WAV or MP3)
- `-c:a libopus` — audio codec (OGG Opus)
- `-b:a 48k` — bitrate (48 kbps, mono-safe)
- `-ac 1` — force mono (reduces file size, suitable for game sfx)
- `-vn` — no video stream (audio-only)

**Batch conversion example:**
```powershell
cd assets/sounds/ambient
Get-ChildItem *.wav | ForEach-Object {
    ffmpeg -i $_.Name -c:a libopus -b:a 48k -ac 1 -vn $($_.BaseName).opus
}
```

### Step 4: Register Audio Files

**Auto-discovery via build-meta.ps1:**
```powershell
powershell -File web/build-meta.ps1
```

This script:
- Scans `assets/sounds/{category}/*.opus` files
- Generates `web/public/meta/sounds.json` with file paths and metadata
- Registers sounds in engine loader for runtime playback

**Manual verification:**
```bash
cat web/public/meta/sounds.json | grep -i "water-drip"
```

Expected output:
```json
{
  "id": "ambient/water-drip",
  "file": "assets/sounds/ambient/water-drip.opus",
  "duration": 18000,
  "type": "ambient"
}
```

### Step 5: Deploy via Web Build

Use the web-publish skill to deploy processed audio:
```powershell
powershell -File web/web-publish.ps1
```

Or with specific target:
```powershell
powershell -File web/web-publish.ps1 -Target "production"
```

### Step 6: Verify in Game

1. **Open browser dev tools** (F12)
2. **Add debug flag:** `http://localhost:8000?debug`
3. **Check console for sound registration:**
   ```
   [sound] play: ambient/water-drip (18.0s)
   ```
4. **Trigger the sound in gameplay and listen for audio output**

## Examples

### Example: Processing Water Drip Ambient Loop

**Raw file:** `assets/sounds/ambient/raw-water-recording.wav` (45s, unedited)

**Process:**
1. Identify clean 18s loop segment (starts at 2.5s marker)
2. Convert with trimming:
   ```powershell
   ffmpeg -i raw-water-recording.wav -ss 2.5 -t 18 -c:a libopus -b:a 48k -ac 1 -vn water-drip.opus
   ```
3. Result: `water-drip.opus` (18s, ~108 KB)
4. Verify file size and format:
   ```powershell
   ls assets/sounds/ambient/water-drip.opus
   # Output: 108 KB, OGG audio
   ```

### Example: Processing Creature One-Shot (Rat Squeak)

**Raw file:** `assets/sounds/creatures/rat-raw.mp3` (2.3s, with silence)

**Process:**
1. Standard conversion (no trimming needed):
   ```powershell
   ffmpeg -i rat-raw.mp3 -c:a libopus -b:a 48k -ac 1 -vn rat-squeak.opus
   ```
2. Result: `rat-squeak.opus` (~14 KB)
3. Test in game with `?debug` flag to confirm registration

### Example: Batch Processing Combat Sounds

**Scenario:** 3 weapon impact files ready to process

**Files:**
- `sword-clang.wav`
- `axe-thud.wav`
- `arrow-hit.wav`

**Batch script:**
```powershell
cd assets/sounds/combat
foreach ($file in @("sword-clang.wav", "axe-thud.wav", "arrow-hit.wav")) {
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($file)
    ffmpeg -i $file -c:a libopus -b:a 48k -ac 1 -vn "${basename}.opus"
}
```

**Register and deploy:**
```powershell
powershell -File web/build-meta.ps1
powershell -File web/web-publish.ps1
```

## Anti-Patterns

### ❌ Don't: Store raw WAV/MP3 in Git

- **Why:** Uncompressed audio (44.1 kHz, 16-bit stereo) = 10+ MB per file. Bloats repository.
- **Do instead:** Only commit `.opus` files. Git-ignore WAV/MP3 via `.gitignore`.

### ❌ Don't: Skip Mono Conversion (`-ac 1`)

- **Why:** Stereo Opus @ 48kbps will distort. Mono is appropriate for game sfx (player hears from single perspective).
- **Do instead:** Always use `-ac 1` flag.

### ❌ Don't: Use Higher Bitrates (>48kbps)

- **Why:** Game sounds don't need high fidelity. 48kbps is transparent for compressed audio and cuts file size by 60%.
- **Do instead:** Stick to `-b:a 48k`.

### ❌ Don't: Forget to Run `build-meta.ps1`

- **Why:** Engine won't discover audio files without metadata registry. Sounds exist but don't play.
- **Do instead:** Always run `powershell -File web/build-meta.ps1` after converting files, before deploy.

### ❌ Don't: Place Ambients > 30 Seconds

- **Why:** Long loops cause memory bloat. Clean loops repeat naturally and feel organic.
- **Do instead:** Trim ambient sounds to 10–30s sweet spot.

### ❌ Don't: Use Stereo for Combat/Creature Sounds

- **Why:** Removes spatial directional cues (player hearing from first-person perspective, no 3D audio panning yet).
- **Do instead:** Convert to mono. Keeps focus on sound quality (impact, texture) over spatialization.

## Troubleshooting

### Issue: ffmpeg not found

**Solution:**
```powershell
ffmpeg -version
```
If command not found, reinstall:
```powershell
winget install Gyan.FFmpeg
# Restart terminal after install
```

### Issue: Sound doesn't play in game after deploy

**Checklist:**
1. ✅ File exists in `assets/sounds/{category}/` with correct name
2. ✅ File is `.opus` format (not WAV/MP3)
3. ✅ `build-meta.ps1` was run and `web/public/meta/sounds.json` includes sound ID
4. ✅ Metadata sound ID matches filename (e.g., `ambient/water-drip` ↔ `water-drip.opus`)
5. ✅ Browser console shows `[sound] play: ...` debug line with `?debug` flag
6. ✅ Web server restarted after metadata update

### Issue: Audio distortion or poor quality

**Solutions:**
- Verify source file quality: `ffmpeg -i input.wav` (check sample rate, bit depth)
- Don't re-encode already-compressed audio multiple times (source loss)
- Use best source available (16-bit, 44.1 kHz or higher)
- 48kbps Opus will always be lossy — audition in-game to confirm acceptable quality

---

**Written by:** Gil (DevOps/Web Build Engineer)  
**Last updated:** [deployment date]  
**Related skills:** web-publish, binary-discovery-skill
