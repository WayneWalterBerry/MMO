# Local Small Language Model (SLM) for Game Parser

**Author:** Frink (Researcher)
**Date:** 2026-07-22
**Requested by:** Wayne "Effe" Berry
**Status:** Research Complete — Recommendation Included
**Related Decisions:** D-17 (No per-player LLM token cost), D-19 (Parser: NLP or Rich Synonyms)

---

## 1. Executive Summary

**Recommendation: Hybrid approach — rule-based parser primary, local SLM fallback.**

A local SLM can run entirely in the browser with zero cloud tokens, satisfying Decision 17. However, the technology is not yet ready to be the *primary* parser for a text adventure on mobile. The winning strategy is:

1. **Rule-based rich synonym parser handles ~85% of commands** — instant, zero download, zero battery cost, deterministic.
2. **Optional local SLM handles the remaining ~15%** — ambiguous natural language, questions, multi-object commands, pronoun resolution.
3. **SLM is a progressive enhancement** — game works perfectly without it. Players on capable devices get a smarter parser. Players on low-end devices get the standard parser.

The smallest viable browser SLM for structured command parsing is **Qwen2.5-0.5B-Instruct (Q4 quantized)** at ~350MB download, running via **WebLLM** with WebGPU acceleration. On flagship phones (2024+), it can parse a command in **200–500ms**. On mid-range phones, **500–1500ms**. On low-end phones, it's too slow.

This is a **stretch goal**, not a launch blocker. Build the rule-based parser first. Add the SLM layer when the game is playable.

---

## 2. Candidate Models

| Model | Parameters | Q4 Size | RAM Required | Browser Runtime | Command Parse Latency (Phone) | Structured Output? | Verdict |
|-------|-----------|---------|-------------|-----------------|-------------------------------|--------------------|---------| 
| **SmolLM2-135M** | 135M | ~80MB | ~250MB | WASM (no GPU needed) | 50–150ms | Weak — too small for reliable JSON | ❌ Too dumb for parsing |
| **Qwen2.5-0.5B-Instruct** | 500M | ~350MB | ~700MB | WebLLM (WebGPU) or transformers.js | 200–500ms flagship, 500–1500ms mid | ✅ Good with instruction tuning | ✅ **Best candidate** |
| **PhoneLM-0.5B** | 500M | ~350MB | ~700MB | ONNX Runtime Web | 200–400ms (NPU-optimized) | Moderate | ⚠️ NPU-only advantage |
| **Gemma 3 1B** | 1B | ~530MB | ~1GB | WebLLM / Google AI Edge | 300–800ms flagship | ✅ Strong | ⚠️ Heavier download |
| **TinyLlama 1.1B** | 1.1B | ~600MB | ~1.2GB | WebLLM | 400–1000ms | ✅ Good | ⚠️ Heavier, older model |
| **SmolLM2-1.7B** | 1.7B | ~1GB | ~2GB | WebLLM (WebGPU required) | 500–1500ms | ✅ Strong | ⚠️ Too large for mobile |
| **Phi-3 Mini (3.8B)** | 3.8B | ~2.2GB | ~4GB | WebLLM (desktop only) | 1–3s desktop | ✅ Excellent | ❌ Desktop only |
| **Gemini Nano** | ~1.8B | Pre-installed | ~0MB extra | Chrome Prompt API | 100–300ms | ✅ Good | ⚠️ Chrome-only, not customizable |

### Recommendation: Qwen2.5-0.5B-Instruct (Q4)

**Why Qwen2.5-0.5B?**
- Smallest model that reliably produces structured JSON output from instructions
- Available pre-quantized in ONNX and MLC formats for both transformers.js and WebLLM
- 350MB is a tolerable download for a "smart parser" progressive enhancement
- Instruction-tuned variant follows schemas reliably with proper prompting
- Active community, frequent updates, good browser inference ecosystem

**Why not SmolLM-135M?**
- At 135M parameters, it cannot reliably map natural language to structured commands. It can do simple classification but fails on multi-object commands, prepositions, and disambiguation. Our parser needs to understand "put the key on the nightstand" vs "put the key in the drawer" — that requires at least 500M parameters with instruction tuning.

**Why not Gemini Nano?**
- It's free and pre-installed — amazing! But it's Chrome-only, not available on Firefox/Safari (our PWA must work cross-browser), and we can't fine-tune it for our verb vocabulary. It's a nice bonus but not a primary strategy.

---

## 3. Browser/PWA Integration Options

### Option A: WebLLM (@mlc-ai/web-llm) — **RECOMMENDED**

| Aspect | Detail |
|--------|--------|
| NPM Package | `@mlc-ai/web-llm` (~5MB JS) |
| Model delivery | Downloaded on-demand, cached in IndexedDB |
| Acceleration | WebGPU (GPU-accelerated inference) |
| Structured output | ✅ Grammar-constrained JSON generation via XGrammar |
| Streaming | ✅ OpenAI-compatible chat/completions API |
| Browser support | Chrome 121+ (Android 12+), Safari 26+ (iOS 26+), Edge, Firefox (desktop) |
| Worker support | ✅ Runs in Web Worker (won't block UI) |

**Key advantage:** WebLLM's grammar-constrained generation means we can **guarantee** the output is valid JSON matching our command schema. No parsing failures from malformed LLM output.

```javascript
// Pseudocode: WebLLM parser integration
import { CreateMLCEngine } from "@mlc-ai/web-llm";

const engine = await CreateMLCEngine("Qwen2.5-0.5B-Instruct-q4f16_1-MLC");

const schema = {
  type: "object",
  properties: {
    verb: { type: "string", enum: ["take", "drop", "look", "open", "close", "feel", "smell", "taste", "listen", "use", "put", "give", "cut", "write", "read", "light", "strike", "prick"] },
    noun: { type: "string" },
    preposition: { type: "string", enum: ["on", "in", "with", "to", "from", "at"] },
    indirect_object: { type: "string" }
  },
  required: ["verb"]
};

const result = await engine.chat.completions.create({
  messages: [
    { role: "system", content: "Parse text adventure commands into JSON. Available objects: brass-key, nightstand, drawer, candle, matchbox, match, knife, pen, paper, poison-bottle. Context: player is in cell, holding brass-key." },
    { role: "user", content: "I want to put the shiny thing on the table" }
  ],
  response_format: { type: "json_object", schema: schema }
});
// → { "verb": "put", "noun": "brass-key", "preposition": "on", "indirect_object": "nightstand" }
```

### Option B: transformers.js (@huggingface/transformers)

| Aspect | Detail |
|--------|--------|
| NPM Package | `@huggingface/transformers` (~2MB JS) |
| Model delivery | Downloaded from HuggingFace Hub, cached |
| Acceleration | WebGPU or WASM fallback |
| Structured output | Prompt-based only (no grammar constraint) |
| Broader ecosystem | Supports BERT, classification, embeddings too |

**Trade-off:** More flexible (could do token classification instead of generation), but lacks grammar-constrained output. Would need post-processing JSON validation.

### Option C: Chrome Prompt API (Gemini Nano) — Opportunistic Bonus

| Aspect | Detail |
|--------|--------|
| Package | None — built into Chrome 137+ |
| Model delivery | Pre-installed with Chrome (0MB extra) |
| Requirements | 16GB RAM, 22GB storage, 4GB VRAM |
| Structured output | Via prompt engineering only |
| Limitation | Chrome-only, not customizable, high hardware floor |

**Use as:** Free bonus for Chrome desktop users. Not a primary strategy.

### Compatibility with Wasmoon (Lua WASM)

Both WebLLM and Wasmoon run as WASM/WebGPU modules. Key concerns:

- **Memory:** Wasmoon uses ~2–5MB. Qwen2.5-0.5B uses ~700MB. Total ~705MB — within budget for 4GB+ devices.
- **GPU contention:** WebLLM uses WebGPU for inference; Wasmoon uses CPU (Lua is CPU-only). No GPU contention.
- **Threading:** WebLLM runs in a Web Worker. Wasmoon runs on main thread (or its own worker). They don't block each other.
- **Verdict:** ✅ Compatible. No architectural conflicts.

---

## 4. What the SLM Does vs Doesn't Do

### ✅ SLM DOES (Parser Role Only):

| Capability | Example Input | Example Output |
|-----------|---------------|----------------|
| Natural language → structured command | "I want to pick up the shiny thing on the table" | `{verb: "take", noun: "brass-key", surface: "nightstand"}` |
| Pronoun resolution | "take it" (after looking at key) | `{verb: "take", noun: "brass-key"}` |
| Sensory query mapping | "what does it smell like?" | `{verb: "smell", noun: "brass-key"}` |
| Multi-object commands | "put the key on the nightstand" | `{verb: "put", noun: "brass-key", prep: "on", indirect: "nightstand"}` |
| Disambiguation | "open" (multiple openable things) | `{verb: "open", ambiguous: true, candidates: ["drawer", "matchbox"]}` |
| Synonym understanding | "grab", "snatch", "pick up", "take" → all map to TAKE | `{verb: "take", ...}` |
| Typo tolerance | "opne the drawer" | `{verb: "open", noun: "drawer"}` |

### ❌ SLM DOES NOT:

| Not This | Why Not |
|----------|---------|
| Generate descriptions or story text | That's build-time LLM work (Decision 17) |
| Create new objects or rooms | That's the mutation engine |
| Run game logic | That's Lua in Wasmoon |
| Make narrative decisions | That's the procedural variation system |
| Talk to the player conversationally | This is a parser, not a chatbot |
| Access the internet | Everything local, always |

The SLM is a **translation layer**: human language → machine-readable command struct. Nothing more.

---

## 5. Fine-Tuning Feasibility

### Can We Fine-Tune for Text Adventure Parsing?

**Yes, and it's practical.**

| Aspect | Detail |
|--------|--------|
| Method | LoRA (Low-Rank Adaptation) — trains ~1-2% of parameters |
| Base model | Qwen2.5-0.5B-Instruct |
| Training data needed | 200–500 high-quality (input, JSON output) pairs |
| Training time | 30–60 minutes on a single consumer GPU (RTX 3060+) |
| Training cost | Free (local GPU) or ~$2–5 on cloud GPU |
| Output | LoRA adapter weights (~5–20MB), merged into base model |

### Training Data Strategy

We can **generate training data using our build-time LLM** (Decision 9 — LLM writes the code):

```
Step 1: Define our verb set (18 verbs) and object vocabulary (~50 objects)
Step 2: Use GPT-4/Claude at build time to generate 500+ command variations:
  - "take the brass key" → {verb: "take", noun: "brass-key"}
  - "grab that shiny thing" → {verb: "take", noun: "brass-key"}  
  - "I want to pick up the key on the nightstand" → {verb: "take", noun: "brass-key", surface: "nightstand"}
  - "what's that smell?" → {verb: "smell", noun: null}
  - "feel around in the dark" → {verb: "feel", noun: null}
Step 3: Fine-tune Qwen2.5-0.5B on these pairs
Step 4: Export quantized model (Q4) for browser deployment
```

**This aligns perfectly with Decision 17:** LLM generates training data at build time. The fine-tuned model runs locally at zero per-player cost.

### How Many Examples?

| Command Type | Examples Needed | Notes |
|-------------|----------------|-------|
| Standard verbs (take, drop, look, etc.) | 10–20 per verb | ~200 total |
| Prepositional commands (put X on Y) | 30–50 | Key for spatial reasoning |
| Sensory verbs (feel, smell, taste, listen) | 10–15 per verb | ~50 total |
| Ambiguous/pronoun commands | 50–100 | "take it", "open that" |
| Typos and misspellings | 50–100 | "opne", "tak", "loko" |
| Edge cases and failures | 30–50 | "dance", "fly away" → {verb: null, error: "unknown"} |
| **Total** | **~500** | Buildable in an afternoon with LLM assistance |

---

## 6. Hybrid Approach Design

### The Recommended Architecture

```
Player Input
    │
    ▼
┌─────────────────────────┐
│  Stage 1: Rule-Based    │  < 1ms
│  Rich Synonym Parser    │  
│  (always runs first)    │  
└────────┬────────────────┘
         │
    ┌────┴────┐
    │ Parsed? │
    └────┬────┘
     yes │         no
         │          │
         ▼          ▼
    ┌─────────┐  ┌─────────────────────┐
    │ Execute │  │ Stage 2: SLM Parse  │  200–1500ms
    │ Command │  │ (if model loaded)   │
    └─────────┘  └────────┬────────────┘
                          │
                     ┌────┴────┐
                     │ Parsed? │
                     └────┬────┘
                   yes │        no
                       │         │
                       ▼         ▼
                  ┌─────────┐  ┌──────────────────┐
                  │ Execute │  │ Stage 3: Ask      │
                  │ Command │  │ Player to Rephrase│
                  └─────────┘  └──────────────────┘
```

### Stage 1: Rule-Based Rich Synonym Parser

This is the **current plan** from Decision 19. It handles:
- Standard verb + noun commands: "take key", "open drawer", "look"
- Synonym mapping: "grab" → TAKE, "examine" → LOOK
- Preposition handling: "put X on Y", "give X to Y"
- Abbreviations: "n" → GO NORTH, "i" → INVENTORY, "x key" → EXAMINE KEY

**Latency:** < 1ms. **Download:** 0 bytes (it's code). **Battery:** negligible.

This handles ~85% of what players type in a text adventure. Most players learn the verb vocabulary quickly.

### Stage 2: Local SLM (Progressive Enhancement)

Activated only when:
1. Stage 1 fails to parse the input
2. The SLM model has been downloaded and loaded
3. Device has sufficient capability (WebGPU available)

Handles:
- "I want to pick up the shiny thing" (natural language)
- "what does this smell like?" (sensory questions)
- "use the knife on the rope" (complex multi-object)
- "take it" (pronoun resolution with game context)
- "opne drawer" (typo correction beyond synonym tables)

**Latency:** 200–1500ms depending on device. **Download:** ~350MB one-time. **Battery:** moderate per-parse.

### Stage 3: Disambiguation / Rephrase

If neither parser succeeds:
- "I don't understand. Try: TAKE KEY, OPEN DRAWER, LOOK AROUND"
- Offer command suggestions based on available verbs + visible objects

### Progressive Loading Strategy

```
Game loads → Rule-based parser active immediately (0ms)
            │
            ├─ If WebGPU available AND WiFi detected:
            │    → Background-download SLM model (~350MB)
            │    → Cache in IndexedDB
            │    → Initialize Web Worker with WebLLM
            │    → SLM parser becomes available (~30–60s after page load)
            │
            ├─ If WebGPU NOT available OR mobile data:
            │    → Skip SLM download
            │    → Rule-based parser only (works great!)
            │
            └─ If model already cached:
                 → Load from IndexedDB (~2–5s)
                 → SLM parser available almost immediately
```

---

## 7. Install-as-Package Paths

### Path A: WebLLM via NPM (Recommended)

```bash
npm install @mlc-ai/web-llm
```

```javascript
// In your PWA's parser module
import { CreateMLCEngine } from "@mlc-ai/web-llm";

// Model weights downloaded at runtime from HuggingFace/CDN
// Cached in IndexedDB for offline use
const engine = await CreateMLCEngine("Qwen2.5-0.5B-Instruct-q4f16_1-MLC", {
  initProgressCallback: (progress) => {
    // Show "Downloading smart parser..." to player
    updateProgressBar(progress.progress);
  }
});
```

| Component | Size |
|-----------|------|
| `@mlc-ai/web-llm` JS bundle | ~5MB |
| Qwen2.5-0.5B Q4 model weights | ~350MB |
| WebAssembly runtime (XGrammar etc.) | ~2MB |
| **Total first-time download** | **~357MB** |
| **Subsequent loads (cached)** | **~5MB** (JS only) |

### Path B: transformers.js via NPM

```bash
npm install @huggingface/transformers
```

```javascript
import { pipeline } from "@huggingface/transformers";

const generator = await pipeline("text-generation", 
  "onnx-community/Qwen2.5-0.5B-Instruct", 
  { dtype: "q4" }
);
```

| Component | Size |
|-----------|------|
| `@huggingface/transformers` JS bundle | ~2MB |
| ONNX Runtime Web WASM | ~8MB |
| Qwen2.5-0.5B Q4 ONNX weights | ~350MB |
| **Total first-time download** | **~360MB** |

### Path C: CDN (No NPM Required)

```html
<script type="module">
  import { CreateMLCEngine } from "https://esm.run/@mlc-ai/web-llm";
  // Works without any build step
</script>
```

### Path D: Self-Hosted Model Weights

For players who can't reach HuggingFace CDN, we could host model weights on our own CDN. Adds infrastructure cost but guarantees availability.

---

## 8. Performance Projections

### By Device Class

| Device Class | Example | WebGPU? | Parse Latency | RAM Available | Model Download | Verdict |
|-------------|---------|---------|--------------|---------------|----------------|---------|
| **Flagship phone (2024+)** | iPhone 16, Pixel 9, Galaxy S24 | ✅ | 200–400ms | 6–12GB | WiFi: OK | ✅ Great experience |
| **Mid-range phone (2023+)** | Pixel 7a, Galaxy A54 | ✅ (Android 12+) | 500–1500ms | 4–6GB | WiFi: OK | ⚠️ Noticeable but usable |
| **Budget phone (2022)** | Galaxy A13, Redmi Note 11 | ❌ | N/A | 3–4GB | Too slow | ❌ Rule-based only |
| **Modern laptop** | M2 MacBook, i7 w/ GPU | ✅ | 100–300ms | 8–32GB | Fast | ✅ Excellent |
| **Older laptop** | 2019 i5, no discrete GPU | WASM only | 1–3s | 4–8GB | OK | ⚠️ Marginal |
| **Chromebook Plus** | Modern Chromebook | ✅ | 200–500ms | 8GB | OK | ✅ Good |

### Battery Impact

| Usage Pattern | Battery Impact | Notes |
|---------------|---------------|-------|
| Occasional SLM parse (fallback only) | < 1% per hour of play | Most commands parsed by rules |
| Every command through SLM | ~3–5% per hour on phone | Not recommended |
| Model sitting idle (loaded but unused) | ~0.5% per hour | WebGPU context idle |
| **Recommended hybrid approach** | **< 1% per hour** | Negligible |

### Latency Budget Analysis

| Component | Time | Cumulative |
|-----------|------|-----------|
| Player presses Enter | 0ms | 0ms |
| Rule-based parser attempt | < 1ms | 1ms |
| If failed: SLM tokenization | 10–20ms | 21ms |
| SLM inference (Qwen2.5-0.5B Q4, WebGPU) | 150–400ms | 421ms |
| JSON parse result | < 1ms | 422ms |
| Execute command in Lua | 1–5ms | 427ms |
| Render response to player | 5–10ms | 437ms |
| **Total (SLM path)** | | **~200–450ms on flagship** |

This is under the 500ms budget for flagship phones. Mid-range phones may hit 800–1500ms, which is noticeable but acceptable for the fallback path (most commands parse instantly via rules).

---

## 9. Risks and Mitigations

| # | Risk | Severity | Mitigation |
|---|------|----------|-----------|
| 1 | **Model too large for mobile download** | HIGH | Progressive enhancement: SLM is optional. Download only on WiFi. Cache aggressively. Rule-based parser is the baseline. |
| 2 | **WebGPU not available on target device** | MEDIUM | Graceful degradation: if no WebGPU, don't load SLM. Rule-based parser works everywhere. WebGPU adoption is accelerating (Safari 26+, Chrome 121+). |
| 3 | **SLM produces wrong parse** | MEDIUM | Grammar-constrained generation (XGrammar) guarantees valid JSON structure. Fine-tuning on our verb set improves accuracy. Worst case: falls through to "rephrase" prompt. |
| 4 | **Latency too high on some devices** | MEDIUM | Measure per-device capability at load time. If first SLM parse takes > 2s, disable SLM and stay rule-based. |
| 5 | **SLM conflicts with Wasmoon WASM** | LOW | Different resource domains: WebLLM uses WebGPU, Wasmoon uses CPU WASM. Both run in Web Workers. Tested compatible in similar setups. |
| 6 | **Fine-tuned model hallucinates verbs/objects** | LOW | Constrain output to known verb enum and known object list via grammar schema. Model literally cannot output a verb we don't support. |
| 7 | **IndexedDB cache evicted by browser** | LOW | Detect missing model, re-download in background. Game still works via rule-based parser during re-download. |
| 8 | **Technology moves too fast** | LOW | Architecture is framework-agnostic. If a better model or runtime appears in 6 months, swap the model. The hybrid design insulates us. |
| 9 | **Player confused by variable parse quality** | LOW | Never expose "smart parser" vs "dumb parser" distinction. Both return the same command structs. Player just sees better understanding. |

---

## 10. Recommendation

### Primary Recommendation: Build the Hybrid Parser

**Phase 1 (Now):** Build the rule-based rich synonym parser as the primary parser. This is the MVP. It handles the standard text adventure command vocabulary, it's instant, it's free, it works everywhere.

**Phase 2 (Post-MVP):** Add local SLM as a progressive enhancement:
1. Integrate `@mlc-ai/web-llm` as an optional dependency
2. Fine-tune Qwen2.5-0.5B-Instruct on 500 text adventure command pairs (generated by build-time LLM)
3. Load SLM in background on capable devices
4. Route failed rule-based parses to SLM
5. Grammar-constrain SLM output to valid command JSON

### Why Not SLM-First?

1. **350MB download** is a hard sell for a text adventure. Players should be playing in seconds, not waiting for a model download.
2. **200–1500ms latency** per parse is acceptable as fallback, not as primary. Text adventures should feel *instant*.
3. **Device coverage** — rule-based works on every device. SLM excludes budget phones and older browsers.
4. **Complexity** — adding WebLLM, model hosting, background downloading, worker management is significant engineering for a feature that improves ~15% of commands.

### Why Not Rule-Based Only?

The SLM handles real player frustrations that rule-based can't:
- "I want to pick up the shiny thing on the table" → rule-based chokes on this
- "what does it smell like?" → rule-based needs specific synonym mapping for every phrasing
- "take it" → pronoun resolution requires game context that rules can't easily access
- Typos beyond simple synonyms → SLM handles gracefully

### Decision 19 Resolution

This research supports resolving Decision 19 as:

> **Primary: Rich synonym parser (Option B). Secondary: Local SLM (the "stretch goal" from the original decision). The hybrid gives us the best of both worlds with acceptable trade-offs.**

### Cost Model (Decision 17 Compliance)

| Cost Item | Per-Player Cost | Notes |
|-----------|----------------|-------|
| Cloud LLM tokens | **$0.00** | Zero. All local. |
| Model hosting (CDN) | ~$0.001 per new player | One-time 350MB transfer |
| Fine-tuning (build-time) | $0.00 per player | Done once, amortized |
| Player device battery | Negligible | Hybrid approach: < 1%/hour |

**Decision 17 is fully satisfied.** No per-player LLM token cost. The SLM runs on the player's device using the player's hardware. Our only cost is CDN bandwidth for the model weights.

---

## Appendix A: Technology Timeline

| When | What |
|------|------|
| **Now** | Build rule-based rich synonym parser |
| **Month 2** | Generate 500 training pairs using build-time LLM |
| **Month 3** | Fine-tune Qwen2.5-0.5B, export Q4 ONNX/MLC model |
| **Month 3** | Integrate WebLLM, build background loader, wire up fallback chain |
| **Month 4** | Playtest hybrid parser, measure accuracy + latency on real devices |
| **Ongoing** | As device capabilities improve, the SLM path handles more players |

## Appendix B: Emerging Alternatives to Watch

| Technology | Status | Why It Matters |
|-----------|--------|---------------|
| **Chrome Prompt API (Gemini Nano)** | Available Chrome 137+ | Free, pre-installed, but Chrome-only |
| **Osmosis-Structure-0.6B** | New (2025) | Purpose-built for structured extraction, 600M params |
| **PhoneLM** | Research (2024) | Optimized for phone NPUs, impressive speed |
| **WASM SIMD improvements** | Ongoing | Could make CPU-only inference fast enough |
| **Smaller fine-tuned specialist models** | Emerging | 100–300M models fine-tuned on narrow tasks |

## Appendix C: References

- WebLLM: https://webllm.mlc.ai / https://github.com/mlc-ai/web-llm
- transformers.js: https://huggingface.co/docs/transformers.js
- Qwen2.5 models: https://huggingface.co/Qwen
- SmolLM2: https://huggingface.co/HuggingFaceTB/SmolLM2-135M
- Chrome Prompt API: https://developer.chrome.com/docs/ai/prompt-api
- WebGPU browser support: https://caniuse.com/webgpu
- LoRA fine-tuning SmolLM: https://github.com/Soham-Raj-Jain/LORA-FINE-TUNING-WITH-SMOLLM2-135M
- PhoneLM paper: https://arxiv.org/html/2411.05046v1
- Gemma 3 on mobile: https://developers.googleblog.com/en/gemma-3-on-mobile-and-web-with-google-ai-edge/
- WebLLM structured generation (XGrammar): https://github.com/mlc-ai/web-llm/releases
- Practical GGUF quantization guide: https://enclaveai.app/blog/2025/11/12/practical-quantization-guide-iphone-mac-gguf/
