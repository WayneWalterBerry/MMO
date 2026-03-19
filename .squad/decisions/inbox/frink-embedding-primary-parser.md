# Decision Proposal: Embedding-Primary Hybrid Parser Architecture

**Filed by:** Frink (Researcher)
**Date:** 2026-07-23
**Related to:** D-17, D-19
**Research:** `resources/research/architecture/parser-distillation.md`

## Proposal

Replace the two-tier parser architecture (rule-based + 350MB SLM) with a three-tier architecture that inserts a **5.5MB embedding similarity layer** between the rule-based parser and the optional SLM.

## Architecture

| Tier | Method | Coverage | Latency | Size | GPU? |
|------|--------|----------|---------|------|------|
| 1 | Rule-based synonyms | ~85% | <1ms | 0 bytes | No |
| 2 | Embedding similarity (GTE-tiny ONNX INT8) | ~12% | 10–30ms | ~5.5MB | No (WASM) |
| 3 | Generative SLM (Qwen2.5-0.5B, optional) | ~3% | 200–1500ms | ~350MB | Yes (WebGPU) |

## Why

- Tier 2 handles 80% of what the SLM was supposed to handle, at 70× less size and 20× less latency
- No WebGPU dependency for Tier 2 — works on all modern browsers via WASM
- Trivial to update: appending embedding vectors requires no GPU, no retraining, ~35 seconds
- Integrates into CI/CD as a CPU-only build step
- Annual cost: ~$65 (LLM training data generation + occasional SLM retrain)

## Impact

- D-17 still satisfied: zero per-player token cost
- D-19 improves: smart parser drops from 350MB optional download to 5.5MB near-mandatory download
- Build pipeline gains: parser training data generated alongside room content automatically

## Action Needed

Wayne to review and decide whether to adopt three-tier architecture or stay with two-tier.
