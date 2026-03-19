# Model Distillation for a Custom Tiny Text Adventure Parser

**Author:** Frink (Researcher)
**Date:** 2026-07-23
**Requested by:** Wayne "Effe" Berry
**Status:** Research Complete — Recommendation Included
**Related Decisions:** D-17 (No per-player LLM token cost), D-19 (Parser: NLP or Rich Synonyms)
**Builds on:** `resources/research/architecture/local-slm-parser.md`

---

## 1. Executive Summary

**Recommendation: Embedding-based intent matching as the smart parser layer, not generative model distillation.**

Our previous research (local-slm-parser.md) identified a hybrid architecture: rule-based parser handles ~85% of commands, with a local SLM fallback for the remaining ~15%. This report examines whether we can shrink that fallback from a 350MB generative SLM (Qwen2.5-0.5B) down to something under 50MB via model distillation — and whether we should.

**The answer:** Yes, we can go far smaller. But the best path isn't classical generative distillation — it's **embedding-based intent matching** with a tiny sentence encoder (~5–10MB). Here's why:

1. **Our domain is tiny.** ~20 verbs, ~100 objects, ~50 synonyms. This is a classification problem with a few hundred possible outputs, not an open-ended generation task.
2. **Embeddings are smaller.** A quantized GTE-tiny or fine-tuned BERT-tiny is 5–10MB vs 350MB for a generative model.
3. **Embeddings are faster.** 10–30ms per parse vs 200–1500ms for text generation.
4. **Embeddings are more reliable.** Cosine similarity against pre-computed command vectors gives deterministic, ranked results — no JSON parsing failures, no hallucinated verbs.
5. **Re-distillation is trivial.** Adding a new verb = generate new embedding vectors. No model retraining. Takes seconds.
6. **Build pipeline integration is natural.** The same LLM that generates room content also generates the canonical command phrases and their embeddings.

The recommended architecture becomes a three-tier parser:
- **Tier 1:** Rule-based synonym parser (~85% of commands, <1ms, 0 bytes)
- **Tier 2:** Embedding similarity matcher (~12% of commands, 10–30ms, ~8MB)
- **Tier 3:** Optional generative SLM for truly complex NLP (~3% of commands, 200–1500ms, 350MB)

This gives us 97%+ coverage at under 10MB mandatory download, with the 350MB SLM remaining a purely optional progressive enhancement.

---

## 2. What Distillation Is (For a Game Team)

### The Cooking Metaphor

Think of distillation like this: you hire a world-class chef (GPT-4) to create recipes. Then you train a line cook (tiny model) to reproduce those specific dishes. The line cook doesn't need to understand food science — they just need to follow the patterns the chef demonstrated.

### Formally

**Knowledge distillation** is a machine learning technique where:

1. **Teacher model** (large, expensive, smart) — e.g., GPT-4, Claude, Gemini
   - Knows everything about language, grammar, context, synonyms
   - Too big and expensive to run per-player
   - Runs at **build time** only

2. **Student model** (tiny, cheap, specialized) — e.g., BERT-tiny, GTE-tiny
   - Learns from the teacher's examples, not from raw internet text
   - Only knows ONE thing: parsing text adventure commands
   - Runs on the **player's device** at zero ongoing cost

3. **Training data** = the bridge between them
   - Teacher generates thousands of (input, correct output) pairs
   - "pick up the shiny thing" → `{verb: "take", noun: "brass-key"}`
   - Student memorizes these patterns and generalizes to similar inputs

### Types of Distillation

| Technique | What Happens | When to Use | Our Relevance |
|-----------|-------------|-------------|---------------|
| **Synthetic data distillation** | Teacher generates labeled training data; student trains on it | When you need a task-specific model | ✅ **Primary technique** |
| **Logit matching** | Student learns to match teacher's probability distributions | When teacher and student share architecture | ❌ Our models are too different |
| **Intermediate layer matching** | Student mimics teacher's internal representations | Fine-grained knowledge transfer | ❌ Overkill for classification |
| **Step-by-step distillation** | Teacher provides reasoning chains, not just answers | Complex reasoning tasks | ⚠️ Maybe for disambiguation |
| **LoRA fine-tuning** | Low-rank adaptation of a pre-trained model's weights | Specializing a general model efficiently | ✅ For the optional SLM tier |
| **Embedding fine-tuning** | Training a sentence encoder on domain-specific similarity pairs | Matching user input to known commands | ✅ **Best for our case** |

**For our use case, synthetic data distillation + embedding fine-tuning is the winning combination.** We use the big model to generate training data, then use that data to fine-tune a tiny embedding model.

---

## 3. Step-by-Step Process for Our Use Case

### Step 1: Define the Verb Vocabulary

Our current verb set (from parser-pipeline-and-sandbox-security.md):

```
TAKE, DROP, LOOK, OPEN, CLOSE, FEEL, SMELL, TASTE, LISTEN,
USE, PUT, GIVE, CUT, WRITE, READ, LIGHT, STRIKE, PRICK
+ movement: GO NORTH/SOUTH/EAST/WEST/UP/DOWN
+ meta: INVENTORY, SAVE, LOAD, HELP, QUIT
```

Each verb has known aliases:
- TAKE: grab, pick up, get, snatch, collect, acquire
- LOOK: examine, inspect, study, observe, peer at, check out
- etc.

### Step 2: Define the Object Vocabulary (Per-Room)

Objects come from the game world. For each room, we know:
- Object names: `brass-key`, `nightstand`, `drawer`, `candle`
- Object adjectives: `shiny`, `brass`, `small`, `wooden`
- Object aliases: `key` → `brass-key`, `table` → `nightstand`

This vocabulary is **generated at build time** by the same LLM that creates the rooms (Decision 9/17).

### Step 3: Generate Training Data with a Big Model

Use GPT-4 / Claude at build time to generate command variations.

**Prompt to teacher model:**
```
Given a text adventure room with objects [brass-key, nightstand, drawer, candle, matchbox],
generate 50 different ways a player might express each of these commands:
- take brass-key
- put brass-key on nightstand  
- open drawer
- look at candle
- light candle with matchbox

For each, output:
- The natural language input
- The structured command JSON

Include: synonyms, slang, verbose/terse phrasing, typos, questions,
multi-word references, pronoun usage, prepositional variations.
```

**Example output pairs:**

| Player Input | Structured Output |
|-------------|-------------------|
| "take the brass key" | `{verb: "take", noun: "brass-key"}` |
| "grab that shiny thing" | `{verb: "take", noun: "brass-key"}` |
| "I want to pick up the key" | `{verb: "take", noun: "brass-key"}` |
| "get key off nightstand" | `{verb: "take", noun: "brass-key", target: "nightstand"}` |
| "put key on table" | `{verb: "put", noun: "brass-key", prep: "on", target: "nightstand"}` |
| "stick the shiny key on the wooden table" | `{verb: "put", noun: "brass-key", prep: "on", target: "nightstand"}` |
| "what's on the nightstand?" | `{verb: "look", target: "nightstand"}` |
| "opne drawer" | `{verb: "open", noun: "drawer"}` |
| "light the candle" | `{verb: "light", noun: "candle"}` |

### Step 4a: Embedding Approach (Recommended — Tier 2)

Instead of training a generative model, we use the training data to build an embedding index:

1. **Choose a tiny sentence encoder:** GTE-tiny (ONNX, quantized INT8, ~5MB) or BERT-tiny (~5MB)
2. **Pre-compute embeddings** for all canonical command phrasings from Step 3
3. **At runtime:** Embed the player's input → cosine similarity → nearest known command
4. **Threshold:** If similarity > 0.75, execute the matched command. If 0.5–0.75, present disambiguation options. If < 0.5, fall through to Tier 3 or "I don't understand."

```
Build Time:
  Teacher LLM generates 2000 (phrase, command) pairs
  → Encode all 2000 phrases with GTE-tiny → save embedding vectors (~400KB JSON)
  → Package: GTE-tiny ONNX model (5MB) + embedding index (400KB)

Runtime:
  Player types: "grab that shiny thing on the table"
  → Encode with GTE-tiny → 384-dimensional vector (10ms)
  → Cosine similarity against 2000 pre-computed vectors (1ms)
  → Best match: "pick up the brass key from the nightstand" (similarity: 0.89)
  → Return: {verb: "take", noun: "brass-key", target: "nightstand"}
  → Total: ~12ms
```

### Step 4b: Generative Distillation Approach (Alternative — Tier 3)

If we also want the optional generative SLM (for truly complex NLP):

1. **Base model:** Qwen2.5-0.5B-Instruct (from our previous research)
2. **Fine-tune with LoRA** on the ~2000 training pairs from Step 3
3. **Training time:** ~30–60 minutes on a consumer GPU (RTX 3060+)
4. **Output:** LoRA adapter weights (~10–20MB), merged into base model
5. **Quantize:** Q4 quantization → ~350MB total
6. **Deploy:** Via WebLLM with grammar-constrained JSON generation

This remains the "heavy" option for the ~3% of truly ambiguous commands.

### Step 5: Package and Deploy

```
Game bundle:
├── parser-rules.lua          (~50KB)   ← Tier 1: rule-based
├── parser-embeddings/
│   ├── gte-tiny-int8.onnx    (~5MB)    ← Tier 2: embedding model
│   └── command-vectors.json   (~400KB)  ← Pre-computed embeddings
└── [optional background download]
    └── qwen-0.5b-q4.wasm     (~350MB)  ← Tier 3: generative SLM
```

### Step 6: Runtime Flow

```
Player: "grab that shiny thing on the table"
  │
  ├─ Tier 1 (Rule-based): Tokenize → look up "grab" → TAKE
  │  "shiny thing" not in synonym table → FAIL
  │
  ├─ Tier 2 (Embedding): Encode input → similarity search
  │  Match: "pick up the brass key from nightstand" (0.89) → SUCCESS
  │  Return: {verb: "take", noun: "brass-key", target: "nightstand"}
  │
  └─ Tier 3 (SLM): [not needed — Tier 2 handled it]
```

---

## 4. Re-Distillation Frequency and Triggers

### When Do We Need to Update the Parser?

| Trigger | What Changes | Tier 1 Impact | Tier 2 Impact | Tier 3 Impact |
|---------|-------------|---------------|---------------|---------------|
| **New verb** (e.g., SWIM) | New verb + aliases | Add synonym mappings | Generate new embedding pairs | Regenerate LoRA adapter |
| **New objects** (new room) | New nouns + adjectives | Add to object table | Generate new embedding pairs | May need retraining |
| **New synonyms** | Expanded phrasing | Add to synonym table | Add new embedding vectors | No change needed |
| **Design change** (new interaction pattern) | New command structures | Update parser logic | Regenerate embedding pairs | Regenerate LoRA adapter |
| **Bug fix** (parser misunderstands something) | Corrected training data | Fix synonym table | Fix/add embedding pairs | Fix training data, retrain |

### Frequency by Tier

**Tier 1 (Rule-based):** Updated whenever game content changes. This is just code — add entries to a lookup table. **Instant, zero cost.**

**Tier 2 (Embeddings):** Updated whenever objects or verbs change. The process is:
1. LLM generates new (phrase, command) pairs for the changed content (~30 seconds of LLM time)
2. Encode new phrases with GTE-tiny (~5 seconds of computation)
3. Append to or rebuild the embedding index (~instant)
4. **Total: Under 1 minute. Fully automatable. No GPU required.**

**Tier 3 (Generative SLM):** Updated infrequently. The process is:
1. Regenerate full training dataset with LLM (~5 minutes of LLM time)
2. LoRA fine-tune Qwen2.5-0.5B (~30–60 minutes on GPU)
3. Merge and quantize (~10 minutes)
4. **Total: ~1 hour. Requires GPU. Triggered per major update, not per room.**

### Can the Model Be Incrementally Updated?

**Tier 2 (Embeddings): Yes, trivially.** New embedding vectors can be appended to the index without touching the model or existing vectors. This is the killer advantage of the embedding approach.

**Tier 3 (Generative SLM): Partially.** Recent research (CL-LoRA, LoRAX — CVPR 2025) enables incremental LoRA fine-tuning without catastrophic forgetting. However, for a domain this small, retraining from scratch on the full ~2000 examples is fast enough that incremental methods aren't necessary. Full retrain is simpler and more reliable.

---

## 5. Cost/Effort Per Cycle

### Tier 2: Embedding Index Update (The Common Case)

| Step | Time | Cost | Hardware |
|------|------|------|----------|
| Generate 50 new training pairs via LLM (per new verb/object) | 30 seconds | ~$0.02 (GPT-4 API) | Any CPU |
| Encode phrases with GTE-tiny | 5 seconds | Free (local) | Any CPU |
| Update embedding index | Instant | Free | Any CPU |
| **Total per update** | **~35 seconds** | **~$0.02** | **Laptop** |

### Tier 3: Full SLM Retrain (The Rare Case)

| Step | Time | Cost | Hardware |
|------|------|------|----------|
| Generate 2000 training pairs via LLM | 5 minutes | ~$1–3 (GPT-4 API) | Any CPU |
| LoRA fine-tune on 2000 examples (3 epochs) | 30–60 minutes | Free (local) or ~$0.25 (cloud T4) | GPU (RTX 3060+ or cloud) |
| Merge LoRA adapters | 2 minutes | Free | Any CPU |
| Quantize to Q4 | 5 minutes | Free | Any CPU |
| Export to MLC/ONNX format | 5 minutes | Free | Any CPU |
| **Total per retrain** | **~45–75 minutes** | **~$1.50–3.50** | **GPU for training step** |

### How Many Training Examples Are Needed?

| Domain Size | Embedding Approach (Tier 2) | Generative Approach (Tier 3) |
|------------|----------------------------|------------------------------|
| Small (10 verbs, 30 objects) | 500–1000 phrase pairs | 500 (input, JSON) pairs |
| Medium (20 verbs, 100 objects) — **our case** | 1500–2500 phrase pairs | 1000–2000 pairs |
| Large (50 verbs, 500 objects) | 5000–10000 phrase pairs | 3000–5000 pairs |

For our medium domain: **~2000 training pairs is the sweet spot.** A single GPT-4 API call generating 50 variations for 40 commands = 2000 pairs, costing about $1–3 total.

### Can This Be Automated?

**Yes, entirely.** Both tiers can be automated as part of the build pipeline:

```yaml
# In CI/CD pipeline (e.g., GitHub Actions)
- name: Generate parser training data
  run: python scripts/generate_parser_data.py --rooms data/rooms/ --output data/parser/

- name: Build embedding index
  run: python scripts/build_embedding_index.py --data data/parser/ --model gte-tiny --output dist/parser/

- name: (Nightly/Release only) Retrain SLM
  if: github.event_name == 'release'
  run: python scripts/train_slm.py --data data/parser/ --output dist/slm/
```

---

## 6. Minimum Viable Model Size

### Comparison Table

| Approach | Model | ONNX Size (Quantized) | RAM at Runtime | Parse Latency | Accuracy (our domain) | Can Generate JSON? |
|----------|-------|----------------------|----------------|---------------|----------------------|-------------------|
| **Custom ONNX classifier** | Simple MLP | ~1–2MB | ~5MB | <5ms | ~90% (with good features) | ❌ Classify only |
| **BERT-tiny classifier** | prajjwal1/bert-tiny (INT8) | **~5MB** | ~20MB | 10–20ms | ~93% (fine-tuned) | ❌ Classify only |
| **GTE-tiny embeddings** | thenlper/gte-tiny (INT8) | **~5MB** | ~20MB | 10–30ms | ~92% (similarity) | ❌ Similarity only |
| **all-MiniLM-L6-v2** | sentence-transformers (INT8) | ~35MB | ~80MB | 15–40ms | ~95% (similarity) | ❌ Similarity only |
| **SmolLM-135M** | HuggingFace/SmolLM (Q4) | ~80MB | ~250MB | 50–150ms | ~75% (too small for JSON) | ⚠️ Weak |
| **Qwen2.5-0.5B-Instruct** | MLC/Qwen (Q4) | ~350MB | ~700MB | 200–1500ms | ~95% (with fine-tuning) | ✅ Full JSON |

### What Can We Get Away With?

For our constrained domain (~20 verbs, ~100 objects, ~50 synonyms):

**Minimum viable: GTE-tiny at ~5MB.** This is a sentence embedding model that can be quantized to INT8 ONNX and run entirely via ONNX Runtime Web (WASM — no GPU needed). It produces 384-dimensional embeddings, and cosine similarity against our pre-computed command vectors gives reliable matching.

**Sweet spot: BERT-tiny classifier at ~5MB.** If we frame parsing as multi-label classification (verb class + noun class + preposition class), a fine-tuned BERT-tiny can directly output the command structure. This is slightly more accurate than similarity matching for known command patterns.

**Could a non-ML approach work?** Yes — a simple embedding lookup with pre-computed vectors from a *frozen* (not fine-tuned) model works reasonably well. But fine-tuning the embedding model on our domain data improves accuracy by ~5–10% on edge cases (typos, creative phrasing, unusual word order).

### Verdict on Model Size

| Budget | Recommendation | Size |
|--------|---------------|------|
| ≤5MB | GTE-tiny (INT8 ONNX) + embedding index | ~5.5MB total |
| ≤10MB | BERT-tiny classifier (INT8 ONNX) | ~5MB + tokenizer |
| ≤50MB | all-MiniLM-L6-v2 embeddings (INT8 ONNX) | ~35MB |
| ≤350MB | Qwen2.5-0.5B-Instruct generative (Q4) | ~350MB |

**Our recommendation: ~5.5MB (GTE-tiny + index) as the default smart parser, with 350MB generative SLM as optional enhancement.**

---

## 7. Distillation vs Embedding-Based Alternatives

### Head-to-Head Comparison

| Criterion | Generative Distillation (SLM) | Embedding Similarity | Hybrid (Embedding + SLM) |
|-----------|------------------------------|---------------------|--------------------------|
| **Model size** | 80–350MB | 5–35MB | 5MB mandatory + 350MB optional |
| **Parse latency** | 200–1500ms | 10–30ms | 10–30ms typical, 200ms fallback |
| **Accuracy (known commands)** | ~95% | ~92–95% | ~97% |
| **Accuracy (novel phrasing)** | ~85% | ~80% | ~90% |
| **Handles typos** | ✅ Good | ✅ Good (embeddings are fuzzy) | ✅ Excellent |
| **Handles pronouns ("take it")** | ✅ With context prompt | ⚠️ Needs game context injection | ✅ SLM handles these |
| **Handles complex prepositional** | ✅ "put X on Y with Z" | ⚠️ Hard to distinguish | ✅ SLM handles these |
| **JSON output guaranteed** | ⚠️ Grammar-constrained only | ✅ Output is looked up, always valid | ✅ Best of both |
| **GPU required (runtime)** | Yes (WebGPU) | No (WASM) | No for Tier 2, yes for Tier 3 |
| **Re-training cost** | ~$2, ~1 hour, needs GPU | ~$0.02, ~35 seconds, CPU only | Tier 2 is cheap; Tier 3 is occasional |
| **Incremental update** | Partial (CL-LoRA research) | ✅ Append vectors trivially | ✅ Best update story |
| **Build pipeline fit** | Heavy (GPU step in CI) | ✅ Trivial (CPU-only) | ✅ CPU default, GPU optional |

### Where Each Shines

**Embedding matching excels at:**
- Simple to moderate commands: "take key", "open drawer", "look at candle"
- Synonym handling: "grab" → matches "take" embedding cluster
- Typo tolerance: "opne" is semantically close to "open" in embedding space
- Speed: 10–30ms is unnoticeable to the player
- Updates: Adding a new room's objects = append new vectors

**Generative SLM excels at:**
- Complex multi-object commands: "use the knife to cut the rope holding the chandelier"
- Context-dependent pronouns: "take it" (requires knowing what "it" refers to)
- Questions: "what's in the drawer?" (requires understanding interrogative structure)
- Completely novel phrasing that doesn't resemble any training data

### The Gap Between Them

For our domain, the gap is small. Our verb vocabulary is constrained, objects are known per-room, and ~85% of commands follow simple patterns. The embedding approach handles the "long tail" of natural language well because embeddings are inherently fuzzy — they don't need exact matches.

The generative SLM adds value primarily for:
1. Pronoun resolution with game state context (~5% of commands)
2. Multi-step prepositional chains (~3% of commands)
3. Creative/novel input from players who ignore conventions (~2% of commands)

These are real but small categories. The embedding tier handles everything else.

---

## 8. Build Pipeline Integration Design

### The Key Insight

The same LLM that generates game content (Decision 9/17) can simultaneously generate parser training data. When the LLM creates a room, it also creates "ways players might refer to objects in this room."

### Pipeline Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    BUILD PIPELINE                         │
│                                                          │
│  ┌──────────────┐    ┌──────────────────┐               │
│  │ Room Defs    │───▶│ LLM Generation   │               │
│  │ (YAML/Lua)   │    │ (GPT-4 / Claude) │               │
│  └──────────────┘    └────┬────┬────────┘               │
│                           │    │                         │
│              ┌────────────┘    └───────────┐             │
│              ▼                             ▼             │
│  ┌──────────────────┐         ┌──────────────────────┐  │
│  │ Game Content     │         │ Parser Training Data  │  │
│  │ - descriptions   │         │ - command variations  │  │
│  │ - objects        │         │ - synonym phrases     │  │
│  │ - interactions   │         │ - object references   │  │
│  └──────────────────┘         └──────────┬───────────┘  │
│                                          │               │
│                                          ▼               │
│                               ┌──────────────────────┐  │
│                               │ Embedding Pipeline   │  │
│                               │ (CPU-only, fast)     │  │
│                               │ 1. Load GTE-tiny     │  │
│                               │ 2. Encode phrases    │  │
│                               │ 3. Build index       │  │
│                               └──────────┬───────────┘  │
│                                          │               │
│                                          ▼               │
│                               ┌──────────────────────┐  │
│                               │ Game Bundle          │  │
│                               │ - game.lua           │  │
│                               │ - parser-rules.lua   │  │
│                               │ - gte-tiny.onnx (5MB)│  │
│                               │ - vectors.json       │  │
│                               └──────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ OPTIONAL: Nightly / Release SLM retrain            │  │
│  │ - Aggregate all parser training data               │  │
│  │ - LoRA fine-tune Qwen2.5-0.5B (GPU runner)        │  │
│  │ - Quantize + export → CDN for progressive download │  │
│  └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### LLM Prompt for Combined Content + Parser Data

When generating a room, the LLM call includes:

```
Generate a dungeon cell room with the following objects:
- brass-key (small, on nightstand, unlocks cell door)
- nightstand (wooden, beside cot, has one drawer)
- drawer (inside nightstand, contains candle)
- candle (unlit, wax, in drawer)

For each object, also generate:
1. Natural language aliases (5–10 per object)
2. Adjective references players might use
3. 15 command variations per primary interaction

Output both the room Lua code AND a parser-data.json file.
```

**Result:** Every room automatically comes with its own parser training data. Parser accuracy scales with content — more rooms = more training data = better parsing.

### GitHub Actions Integration

```yaml
name: Build Game + Parser

on:
  push:
    branches: [main]
    paths: ['data/rooms/**', 'data/verbs/**']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install deps
        run: pip install onnxruntime sentence-transformers

      - name: Generate parser training data from room definitions
        run: python scripts/generate_parser_data.py
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}

      - name: Build embedding index (CPU, ~30 seconds)
        run: python scripts/build_embedding_index.py

      - name: Run parser accuracy tests
        run: python scripts/test_parser_accuracy.py --threshold 0.90

      - name: Bundle game assets
        run: python scripts/bundle.py

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: game-bundle
          path: dist/

  retrain-slm:
    if: github.event_name == 'release'
    runs-on: ubuntu-latest  # or self-hosted with GPU
    needs: build
    steps:
      - name: Retrain SLM with LoRA
        run: python scripts/train_slm.py
      - name: Upload SLM to CDN
        run: python scripts/upload_slm.py
```

---

## 9. Practical Workflow: Add Verb → Retrain → Ship

### Scenario: Developer Adds SWIM Verb

```
Day 1: Developer Work (5 minutes)
├── Add SWIM to verb definition file (data/verbs/swim.yaml)
│   verbs:
│     swim:
│       aliases: [wade, paddle, float, tread water, dive, submerge]
│       requires: [water]
│       objects: [lake, river, pool, moat, ocean, stream]
│
├── Git commit + push to main
│
└── CI pipeline triggers automatically

Day 1: CI Pipeline (Automated, ~3 minutes)
├── Step 1: LLM generates 100 training pairs for SWIM (30s, ~$0.05)
│   - "swim across the lake" → {verb: "swim", noun: "lake"}
│   - "wade into the river" → {verb: "swim", noun: "river"}  
│   - "can I paddle across?" → {verb: "swim", noun: null}
│   - "jump in the water" → {verb: "swim", noun: "lake"}
│   - "take a dip" → {verb: "swim", noun: null}
│
├── Step 2: Encode new phrases with GTE-tiny (5s, free)
│
├── Step 3: Append to embedding index (instant)
│
├── Step 4: Run parser accuracy tests (10s)
│   - Test all existing verb embeddings still match correctly
│   - Test new SWIM embeddings match correctly
│   - Threshold: >90% top-1 accuracy
│
├── Step 5: Bundle updated game assets (30s)
│
└── Step 6: Deploy to CDN

Day 1: Players Get Update
├── Game checks for asset updates (existing PWA update flow)
├── Downloads updated vectors.json (~5KB delta)
├── SWIM is now parseable
└── Total player-facing download: < 10KB
```

### Scenario: New Room Added

```
Room definition committed → CI pipeline:
  1. LLM generates room content + parser data simultaneously
  2. New object embeddings added to index
  3. Tests verify all objects parseable
  4. Bundle + deploy

Player download: ~5–20KB (new embedding vectors only)
```

### Scenario: Major Expansion (New Zone with 10 Rooms + 3 Verbs)

```
All room/verb definitions committed → CI pipeline:
  1. LLM generates all content + parser data (~2 minutes, ~$0.50)
  2. Rebuild full embedding index (~30 seconds)
  3. Full parser accuracy test suite
  4. Bundle + deploy
  5. (Release trigger) Retrain SLM with updated full dataset (~1 hour, ~$2)
  6. Upload retrained SLM to CDN

Player download:
  - Embedding index update: ~50KB
  - (Background) Updated SLM: ~350MB (only if they had the SLM already)
```

---

## 10. Recommendation: Distillation vs Embeddings vs Hybrid

### The Verdict: **Hybrid with Embedding-Primary**

```
┌─────────────────────────────────────────────────────┐
│               RECOMMENDED ARCHITECTURE               │
│                                                      │
│  Tier 1: Rule-Based Parser (Phase 1 — build now)    │
│  ├── Handles: ~85% of commands                       │
│  ├── Latency: <1ms                                   │
│  ├── Size: 0 bytes (it's game code)                  │
│  └── Update: Edit synonym tables                     │
│                                                      │
│  Tier 2: Embedding Matcher (Phase 2 — post-MVP)     │
│  ├── Handles: ~12% of commands (Tier 1 failures)     │
│  ├── Latency: 10–30ms                                │
│  ├── Size: ~5.5MB (model + index)                    │
│  ├── Update: Append vectors (seconds, CPU, free)     │
│  ├── Runtime: ONNX Runtime Web (WASM, no GPU)        │
│  └── Progressive: Downloaded on first Tier 1 fail    │
│                                                      │
│  Tier 3: Generative SLM (Phase 3 — stretch goal)    │
│  ├── Handles: ~3% of commands (Tier 2 failures)      │
│  ├── Latency: 200–1500ms                             │
│  ├── Size: ~350MB (background download)              │
│  ├── Update: Retrain (hourly, GPU, ~$2)              │
│  ├── Runtime: WebLLM (WebGPU required)               │
│  └── Progressive: Background WiFi download           │
│                                                      │
│  Coverage: 85% + 12% + 3% = ~100%                   │
│  Mandatory download: 0 → 5.5MB (progressive)        │
│  Optional download: 350MB (background)               │
└─────────────────────────────────────────────────────┘
```

### Why This Over Pure Distillation?

1. **Embedding approach is 70× smaller** than generative distillation (5MB vs 350MB)
2. **Embedding approach is 20× faster** (10ms vs 200ms)
3. **Embedding approach needs no GPU** at runtime (WASM-only)
4. **Embedding approach is trivially updatable** (append vectors vs retrain model)
5. **Embedding approach is automatable** without GPU runners in CI
6. **Generative SLM remains available** for the cases where embeddings fall short

### Why Not Pure Embeddings?

1. **Pronoun resolution** ("take it") requires game state context that embeddings alone can't provide
2. **Complex multi-object commands** ("use knife on rope holding chandelier") benefit from language model understanding
3. **3% of commands** is still potentially 1 in 33 player inputs — noticeable enough to matter

The hybrid gives us the best of all worlds.

### Phase Timeline

| Phase | When | What Ships | Parser Coverage |
|-------|------|-----------|----------------|
| **Phase 1** | MVP (now) | Rule-based synonym parser | ~85% |
| **Phase 2** | Post-MVP (+2–4 weeks) | + Embedding matcher (5.5MB) | ~97% |
| **Phase 3** | Polish (+2–3 months) | + Generative SLM (350MB optional) | ~100% |

---

## 11. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Embedding model too dumb for our domain** | Low | Medium | Fine-tune GTE-tiny on our data (adds 30 min to build). Extensive testing with real player phrases. Fall back to bigger model (MiniLM-L6) if needed (+30MB). |
| **Similarity threshold hard to tune** | Medium | Low | Use a validation set of 200+ edge cases. Adaptive thresholding per verb category. Disambiguation UI for low-confidence matches. |
| **ONNX Runtime Web too slow on old phones** | Low | Low | WASM inference for tiny models is fast (~10ms) even on 2020-era phones. If truly too slow, skip Tier 2 and fall through to "rephrase" prompt. |
| **Training data doesn't cover real player language** | Medium | Medium | Collect anonymized Tier-1-failure logs (what players typed that the rule parser didn't catch). Use as feedback for next training data cycle. Opt-in only, privacy-respecting. |
| **LLM-generated training data has biases** | Low | Low | Validate with human review of random 10% sample. Test with adversarial inputs. Training data is deterministic and auditable. |
| **Embedding index grows too large** | Low | Low | Even 10,000 vectors × 384 dimensions × 4 bytes = ~15MB. Well within budget. Can prune by deduplicating near-identical embeddings. |
| **CL-LoRA incremental update causes drift** | Medium | Low | For our domain size, full retrain is cheap enough (~1 hour). Only use incremental methods if retraining starts taking hours. |
| **GPT-4 API costs spike** | Low | Low | Training data generation is a one-time cost per content change. ~$1–3 per full regeneration. Budget $50/year covers all cycles. Open-source LLMs (Llama, Mistral) can substitute if needed. |
| **Browser ONNX compatibility** | Low | Low | ONNX Runtime Web uses WASM — works on all modern browsers. No WebGPU dependency for Tier 2. Only Tier 3 (SLM) needs WebGPU. |

### Open Questions for Future Research

1. **Fine-tuned vs frozen embeddings:** Is a frozen GTE-tiny sufficient, or does fine-tuning on our domain data meaningfully improve accuracy? (Quick experiment: ~2 hours.)
2. **Optimal embedding dimensions:** Can we reduce from 384 to 128 dimensions with Matryoshka embedding truncation? (Would shrink index by 3×.)
3. **Hybrid scoring:** Can we combine embedding similarity with rule-based features (verb detected? object name substring match?) for better accuracy?
4. **Player telemetry feedback loop:** Can anonymized Tier-1 failures become automatic training data for the next build cycle?

---

## Appendix A: Key Reference Models

| Model | Use | Size (ONNX INT8) | Where to Get |
|-------|-----|-------------------|--------------|
| GTE-tiny | Sentence embeddings | ~5MB | `thenlper/gte-tiny` on HuggingFace |
| BERT-tiny | Classification | ~5MB | `prajjwal1/bert-tiny` on HuggingFace |
| all-MiniLM-L6-v2 | Sentence embeddings (higher quality) | ~35MB | `sentence-transformers/all-MiniLM-L6-v2` |
| GTE-small | Sentence embeddings (mid-tier) | ~8MB | `thenlper/gte-small` on HuggingFace |
| Qwen2.5-0.5B-Instruct | Generative parsing (SLM) | ~350MB (Q4) | `Qwen/Qwen2.5-0.5B-Instruct` |

## Appendix B: Technology Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Embedding model runtime | ONNX Runtime Web (WASM) | Run GTE-tiny in browser, no GPU |
| Generative SLM runtime | WebLLM (@mlc-ai/web-llm) | Run Qwen2.5-0.5B with WebGPU |
| Fine-tuning | Hugging Face Transformers + PEFT | LoRA fine-tuning on training data |
| Quantization | ONNX Runtime quantization tools | INT8 for embeddings, Q4 for SLM |
| Training data generation | GPT-4 / Claude API | Build-time LLM generates command pairs |
| Embedding index | Custom JSON (or FAISS-lite for scale) | Pre-computed vectors for similarity |
| CI/CD | GitHub Actions | Automated parser data + embedding build |
| Tokenizer (browser) | tokenizers-wasm or Transformers.js | Tokenize player input for model |

## Appendix C: Cost Summary

| Activity | Frequency | Cost per Cycle | Annual Estimate |
|----------|-----------|---------------|----------------|
| Training data generation (LLM API) | Per content change | $0.02–$3.00 | ~$50 |
| Embedding index build | Per content change | Free (CPU) | $0 |
| SLM LoRA fine-tuning (cloud GPU) | Per release (~monthly) | $0.25–$1.00 | ~$12 |
| Model hosting / CDN bandwidth | Ongoing | ~$0.001/player | Scales with players |
| **Total annual infrastructure** | | | **~$65 + CDN** |
