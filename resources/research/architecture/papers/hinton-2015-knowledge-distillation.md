# Hinton, Vinyals & Dean (2015) — Knowledge Distillation

**Category:** SHOULD DOWNLOAD

## Citation

Hinton, G., Vinyals, O. & Dean, J. (2015). "Distilling the Knowledge in a Neural Network." arXiv: [1503.02531](https://arxiv.org/abs/1503.02531). Originally presented at NIPS 2014 Deep Learning Workshop.

## Abstract

A very simple way to improve the performance of almost any machine learning algorithm is to train many different models on the same data and then to average their predictions. Unfortunately, making predictions using a whole ensemble of models is cumbersome and may be too computationally expensive to allow deployment to a large number of users, especially if the individual models are large neural nets. We develop an approach using a different compression technique to compress the knowledge in an ensemble into a single model which is much easier to deploy. We achieve some surprising results on MNIST and we show that we can significantly improve the acoustic model of a heavily used commercial system by distilling the knowledge in an ensemble of models into a single model. We also introduce a new type of ensemble composed of one or more full models and many specialist models which learn to distinguish fine-grained classes that the full models confuse.

## Key Findings Relevant to MMO Parser

- **"Soft targets" from teacher models** encode richer information about class relationships than hard labels — this is conceptually what our GTE-tiny similarity matrix captures: soft relationships between words
- **Small student models can capture most of a large model's behavior** — motivates the idea that a precomputed word similarity matrix (our "student") can approximate runtime GTE-tiny inference (the "teacher")
- **Knowledge can be compressed into simpler representations** — our approach of distilling GTE-tiny's 384-d vectors into a word-pair similarity lookup table is a form of knowledge distillation

## Why It Matters to MMO's Tier 2 Parser

This paper provides theoretical backing for our strategy of extracting knowledge from GTE-tiny embeddings into lightweight data structures (similarity matrices, synonym lists) usable in pure Lua. It's also relevant if we ever explore training a tiny domain-specific classifier for verb identification — distillation could make such a model small enough to embed as Lua tables.

## Access

- arXiv: <https://arxiv.org/abs/1503.02531>
