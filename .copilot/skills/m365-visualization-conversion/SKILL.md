# Skill: M365 Copilot Visualization Conversion

**Confidence:** medium
**Domain:** documentation, research
**Discovered by:** Squad Coordinator (2026-03-25)
**Validated by:** Wayne Berry (manual review of converted output)

## Problem

Microsoft 365 Copilot Deep Research mode generates markdown documents with inline base64-encoded PNG visualizations using this pattern:

```markdown
<!-- Copilot-Researcher-Visualization -->

![Visualization](data:image/png;base64,iVBORw0KGgo...)
```

These images are:
- Not viewable in most code editors or git diffs
- Massive (300-900 KB each as base64 text, bloating the markdown file)
- Not searchable or indexable
- Lost when the document is processed by text-only tools

The images are typically styled info-cards with dark backgrounds containing text content: summaries, prioritized lists, comparison cards, or callout boxes.

## Solution

Convert each base64 PNG visualization to an equivalent markdown text block. Do NOT guess at the content — decode and view each image first.

### Step-by-Step Process

1. **Extract images to temp files:**
   ```powershell
   $content = Get-Content "path/to/file.md" -Raw
   $matches = [regex]::Matches($content, '!\[Visualization\]\(data:image/png;base64,([^\)]+)\)')
   for ($i = 0; $i -lt $matches.Count; $i++) {
       $bytes = [Convert]::FromBase64String($matches[$i].Groups[1].Value)
       [System.IO.File]::WriteAllBytes("$PWD\temp\viz-$($i+1).png", $bytes)
   }
   ```

2. **View each image** using the `view` tool on each PNG file. The tool returns the image content for visual inspection.

3. **Transcribe accurately.** For each image, create a markdown equivalent that preserves ALL text content. Common M365 visualization types:

   | Image Type | Markdown Replacement |
   |-----------|---------------------|
   | Executive summary card | `> **Executive Summary**` blockquote with bold headings |
   | Numbered priority list | Numbered markdown list with `**bold titles**` and descriptions |
   | Side-by-side comparison cards | Markdown table or two blockquotes |
   | Callout/insight box | `> 💡 **Title**` blockquote |
   | Flow diagram | ASCII art or numbered steps |

4. **Replace in the file.** Replace each `<!-- Copilot-Researcher-Visualization -->` + `![Visualization](data:...)` block with the text equivalent. Remove the HTML comment tag too.

5. **Clean up temp files** after conversion.

### Example Conversions

**Executive Summary Card → Blockquote:**
```markdown
> ### Executive Summary
>
> **Hybrid Retrieval**
> Combine lexical scoring (e.g. BM25) with semantic cues (pre-computed synonyms
> or embeddings) to catch paraphrased commands without runtime neural models.
>
> **Soft Matching**
> Use synonym expansion (e.g. via WordNet) and a word similarity matrix (from
> offline embeddings) to allow partial token overlaps and fuzzy matches, boosting
> recognition of novel phrasings.
>
> **Contextual Heuristics**
> Leverage game context (recent objects, locations) to narrow search space and
> disambiguate commands, similar to coding assistants using workspace context.
```

**Side-by-Side Insight Cards → Table:**
```markdown
| 💡 Hybrid Retrieval Boosts Recall | 📊 Hierarchical Search (GraphRAG) |
|---|---|
| Combining lexical and semantic search yields more robust matching than either alone. For our parser, using a BM25 lexical pass followed by a soft semantic rerank can catch ~10–20% more paraphrased commands without a neural model. | Multi-stage retrieval (like GraphRAG) first narrows the search space (e.g., by verb or context) then finds the best match. This could improve precision in our 5-tier parser by focusing on likely verbs before matching nouns. |
```

**Numbered Priority List → Ordered List:**
```markdown
### Effort-to-Impact Priority

1. **Synonym & Slang Expansion (Offline)** — Use WordNet, thesauri, or LLMs at build-time to expand each verb and noun with common synonyms, slang, and paraphrase templates. This directly addresses the "novel phrasing" gap. Impact: High improvement in recall (5–15% overall). Effort: Moderate (one-time corpus curation).

2. **BM25 Lexical Scoring** — Replace or augment Jaccard with a TF-IDF/BM25 based similarity for matching commands. Better handling of extra words and differing lengths. Impact: Moderate (~5% gain in accuracy; more robust matching). Effort: Low (simple formula in Lua).

3. **Soft Matching via Word Similarity** — Implement soft cosine/Jaccard using a precomputed word similarity matrix from embeddings. This allows partial credit for similar words ("grab" ≈ "get"). Impact: High on previously missed synonyms (~10% gain, particularly in paraphrase cases). Effort: Moderate (compute matrix offline; small runtime cost).

4. **Context-Aware Filtering** — Leverage game context and recent references to filter and rank candidate commands (e.g., focus on current room's items, last mentioned object) similar to how Copilot uses the @workspace context. Impact: Low-to-moderate (improves precision, resolves ambiguities). Effort: Low (use existing game state info).

5. **Inverted Index & Fuzzy Search** — Build an inverted index of tokens to candidate phrases to limit search scope (only consider phrases sharing a rare token with input). Integrate a secondary fuzzy match for when no good match is found. Impact: Low (mainly performance & backup for edge cases). Effort: Low.
```

## When to Apply

- Any time a file from `resources/research/` contains `![Visualization](data:image/png;base64,` patterns
- After receiving M365 Copilot Deep Research output
- Before committing research documents to the repo (base64 images bloat git history)

## Key Rules

- **NEVER guess** at image content. Always decode → save → view → transcribe.
- Preserve ALL text from the image — don't summarize or omit.
- Match the visual hierarchy (headings, bold, numbering) from the image.
- Delete the `<!-- Copilot-Researcher-Visualization -->` comment along with the image.
- Clean up temp PNG files after conversion.
