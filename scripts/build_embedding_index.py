#!/usr/bin/env python3
"""
Phase 2: Embedding Index Build Script

Loads the training CSV from Phase 1, encodes all phrases using GTE-tiny
(384-dimensional embeddings), and outputs a compressed JSON index for
runtime use by the browser-based parser.

Requirements: pip install -r scripts/requirements.txt
  - sentence-transformers (or transformers + onnxruntime)
  - numpy

Usage:
    python scripts/build_embedding_index.py
    python scripts/build_embedding_index.py --input data/parser/training-pairs.csv
    python scripts/build_embedding_index.py --help
"""

import argparse
import csv
import gzip
import json
import os
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = REPO_ROOT / "data" / "parser" / "training-pairs.csv"
OUTPUT_DIR = REPO_ROOT / "src" / "assets" / "parser"
MODELS_DIR = REPO_ROOT / "models"

MODEL_NAME = "TaylorAI/gte-tiny"
EXPECTED_DIM = 384

# ---------------------------------------------------------------------------
# Model Loading
# ---------------------------------------------------------------------------

def load_model(cache_dir: Path):
    """
    Load GTE-tiny model for encoding. Tries sentence-transformers first,
    falls back to transformers + manual mean-pooling.
    Returns an encode function: encode(texts: list[str]) -> list[list[float]]
    """
    cache_dir.mkdir(parents=True, exist_ok=True)
    cache_str = str(cache_dir)

    # Try sentence-transformers (simplest API)
    try:
        from sentence_transformers import SentenceTransformer
        print(f"  Loading model via sentence-transformers ...")
        model = SentenceTransformer(MODEL_NAME, cache_folder=cache_str)

        def encode_fn(texts: list[str]) -> list[list[float]]:
            embeddings = model.encode(texts, show_progress_bar=True, normalize_embeddings=True)
            return embeddings.tolist()

        return encode_fn

    except ImportError:
        pass

    # Fallback: transformers + torch/onnxruntime
    try:
        from transformers import AutoTokenizer, AutoModel
        import torch
        import numpy as np

        print(f"  Loading model via transformers + torch ...")
        tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, cache_dir=cache_str)
        model = AutoModel.from_pretrained(MODEL_NAME, cache_dir=cache_str)
        model.eval()

        def encode_fn(texts: list[str]) -> list[list[float]]:
            all_embeddings = []
            batch_size = 64
            for i in range(0, len(texts), batch_size):
                batch = texts[i:i + batch_size]
                inputs = tokenizer(batch, padding=True, truncation=True,
                                   max_length=128, return_tensors="pt")
                with torch.no_grad():
                    outputs = model(**inputs)
                # Mean pooling over token embeddings
                attention_mask = inputs["attention_mask"]
                token_embs = outputs.last_hidden_state
                mask_expanded = attention_mask.unsqueeze(-1).expand(token_embs.size()).float()
                sum_embs = torch.sum(token_embs * mask_expanded, dim=1)
                sum_mask = torch.clamp(mask_expanded.sum(dim=1), min=1e-9)
                embeddings = sum_embs / sum_mask
                # L2 normalize
                embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
                all_embeddings.extend(embeddings.cpu().numpy().tolist())

                if (i // batch_size) % 10 == 0 and i > 0:
                    print(f"    Encoded {i}/{len(texts)} phrases ...")

            return all_embeddings

        return encode_fn

    except ImportError as e:
        print(f"[ERROR] Cannot load model. Install dependencies:", file=sys.stderr)
        print(f"  pip install sentence-transformers", file=sys.stderr)
        print(f"  OR: pip install transformers torch", file=sys.stderr)
        print(f"  Import error: {e}", file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# CSV Loading
# ---------------------------------------------------------------------------

def load_training_csv(csv_path: Path) -> list[dict]:
    """Load training pairs CSV. Returns list of row dicts."""
    if not csv_path.is_file():
        print(f"[ERROR] Training CSV not found: {csv_path}", file=sys.stderr)
        print(f"  Run Phase 1 first: python scripts/generate_parser_data.py --mode=local", file=sys.stderr)
        sys.exit(1)

    rows = []
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows


# ---------------------------------------------------------------------------
# Index Building
# ---------------------------------------------------------------------------

def build_index(rows: list[dict], embeddings: list[list[float]]) -> dict:
    """
    Build the embedding index JSON structure.
    Format: { "phrases": [{ "id": N, "text": "...", "verb": "...", "noun": "...", "embedding": [...] }] }
    """
    phrases = []
    for row, emb in zip(rows, embeddings):
        # Round floats to 6 decimal places for reasonable file size
        rounded = [round(x, 6) for x in emb]
        phrases.append({
            "id": int(row["phrase_id"]),
            "text": row["phrase_text"],
            "verb": row["verb"],
            "noun": row["noun"],
            "embedding": rounded,
        })
    return {"phrases": phrases, "dimensions": EXPECTED_DIM, "model": MODEL_NAME}


def save_index(index: dict, output_dir: Path) -> tuple[Path, Path]:
    """Save index as both uncompressed JSON and gzip-compressed."""
    output_dir.mkdir(parents=True, exist_ok=True)

    json_path = output_dir / "embedding-index.json"
    gz_path = output_dir / "embedding-index.json.gz"

    json_str = json.dumps(index, separators=(",", ":"))

    # Uncompressed (for debugging)
    with open(json_path, "w", encoding="utf-8") as f:
        f.write(json_str)

    # Compressed (for production)
    with gzip.open(gz_path, "wt", encoding="utf-8", compresslevel=9) as f:
        f.write(json_str)

    return json_path, gz_path


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Build embedding index from Phase 1 training data.",
        epilog="""
Examples:
  python scripts/build_embedding_index.py
  python scripts/build_embedding_index.py --input data/parser/training-pairs.csv
  python scripts/build_embedding_index.py --model-cache ./my-models
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--input", type=Path, default=DEFAULT_INPUT,
        help=f"Input CSV from Phase 1. Default: {DEFAULT_INPUT.relative_to(REPO_ROOT)}",
    )
    parser.add_argument(
        "--output-dir", type=Path, default=OUTPUT_DIR,
        help=f"Output directory for index files. Default: {OUTPUT_DIR.relative_to(REPO_ROOT)}",
    )
    parser.add_argument(
        "--model-cache", type=Path, default=MODELS_DIR,
        help=f"Directory to cache the GTE-tiny model. Default: {MODELS_DIR.relative_to(REPO_ROOT)}",
    )
    args = parser.parse_args()

    print(f"=== Phase 2: Embedding Index Build ===\n")

    # --- Step 1: Load training data ---
    print(f"[1/4] Loading training data from {args.input.relative_to(REPO_ROOT)} ...")
    rows = load_training_csv(args.input)
    print(f"       Loaded {len(rows)} phrases")

    # --- Step 2: Load model ---
    print(f"\n[2/4] Loading GTE-tiny model ({MODEL_NAME}) ...")
    print(f"       Cache directory: {args.model_cache.relative_to(REPO_ROOT)}")
    t0 = time.time()
    encode_fn = load_model(args.model_cache)
    model_time = time.time() - t0
    print(f"       Model loaded in {model_time:.1f}s")

    # --- Step 3: Encode all phrases ---
    texts = [row["phrase_text"] for row in rows]
    print(f"\n[3/4] Encoding {len(texts)} phrases into {EXPECTED_DIM}-dim vectors ...")
    t0 = time.time()
    embeddings = encode_fn(texts)
    encode_time = time.time() - t0
    print(f"       Encoding complete in {encode_time:.1f}s")

    # Validate dimensions
    if embeddings and len(embeddings[0]) != EXPECTED_DIM:
        actual = len(embeddings[0])
        print(f"[WARN] Expected {EXPECTED_DIM}-dim vectors, got {actual}-dim", file=sys.stderr)

    # --- Step 4: Build and save index ---
    print(f"\n[4/4] Building index and saving ...")
    index = build_index(rows, embeddings)
    json_path, gz_path = save_index(index, args.output_dir)

    json_size = json_path.stat().st_size
    gz_size = gz_path.stat().st_size

    print(f"\n✅ Embedding index built successfully!")
    print(f"\n--- Stats ---")
    print(f"  Phrase count:     {len(index['phrases'])}")
    print(f"  Vector dimensions: {index['dimensions']}")
    print(f"  Model:            {index['model']}")
    print(f"  JSON (debug):     {json_path.relative_to(REPO_ROOT)} ({json_size:,} bytes / {json_size/1024:.0f} KB)")
    print(f"  GZIP (prod):      {gz_path.relative_to(REPO_ROOT)} ({gz_size:,} bytes / {gz_size/1024:.0f} KB)")
    print(f"  Compression ratio: {json_size/max(gz_size,1):.1f}x")
    print(f"  Encode time:      {encode_time:.1f}s ({len(texts)/max(encode_time,0.001):.0f} phrases/sec)")


if __name__ == "__main__":
    main()
