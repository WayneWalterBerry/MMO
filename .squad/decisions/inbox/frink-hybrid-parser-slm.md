# Decision Proposal: Hybrid Parser Architecture (Rule-Based + Local SLM)

**Proposed by:** Frink (Researcher)
**Date:** 2026-07-22
**Status:** Proposed
**Requested by:** Wayne "Effe" Berry
**Related Decisions:** D-17 (No per-player LLM cost), D-19 (Parser: NLP or Rich Synonyms)

## Summary

Resolves Decision 19 (Parser approach — currently "Deferred/SOFT") with a hybrid architecture:

1. **Primary:** Rule-based rich synonym parser handles ~85% of commands instantly (<1ms). Zero download, zero battery cost, works on all devices.
2. **Secondary (progressive enhancement):** Local SLM (Qwen2.5-0.5B-Instruct, Q4 quantized, ~350MB) handles ambiguous natural language as fallback, running entirely in-browser via WebLLM + WebGPU. Zero cloud tokens.

## Rationale

- Satisfies Decision 17: no per-player LLM token cost (everything on-device)
- Rule-based parser is the MVP; SLM is the stretch goal from D-19
- 350MB model download is only for capable devices on WiFi — game works without it
- Grammar-constrained JSON generation guarantees valid command output
- Fine-tuning via LoRA on 500 build-time-generated training pairs is cheap (~1 hour, ~$2–5)

## Impact

- Parser engine needs a fallback chain: rule-based → SLM → ask player to rephrase
- WebLLM dependency added as optional (not required for gameplay)
- Need to generate 500 training pairs for fine-tuning (build-time LLM cost)
- CDN hosting for model weights (~350MB, one-time per player)

## Full Research

See `resources/research/architecture/local-slm-parser.md` for complete analysis including model benchmarks, integration code examples, performance projections, and risk mitigations.
