---
name: devrandom-research
description: Run an evidence-driven Rust and Nix research loop that discovers, tests, measures, keeps, or rejects implementation improvements until an adversarially verified fixed point. Use for deep Rust tightening, Nix integration, performance work, crate replacement, robustness audits, interface reduction, or autonomous research that must preserve the repository's architecture, semantics, features, and guarantees.
---

# Devrandom Research

Discover improvements from evidence. Do not treat operator suggestions, earlier agent conclusions, popular patterns, dependencies, or lower source-line counts as proof.

Apply this workflow to Rust projects developed and verified through Nix. Preserve the repository's declared architecture and semantics. Tighten their implementation; do not replace the idea being implemented.

Read [references/protocol.md](references/protocol.md) completely before the first mutation and after context recovery.

## Initialize

1. Read every applicable repository instruction file.
2. Inspect git status and preserve unrelated work.
3. Run `devrandom-research-init` at the repository root. Resume existing `.research/` files without overwriting them.
4. Write the immutable contract before proposing changes: architecture, features, semantics, compatibility, safety, performance, platform, tooling, and operator constraints.
5. Establish reproducible behavioral, performance, allocation, code-size, compile-time, dependency, public-surface, and complexity baselines appropriate to the project.
6. Inventory the whole repository and its custom machinery before choosing a target.

## Research

- Search current primary sources: official documentation and source, specifications, original papers, upstream issue trackers, release histories, and security/advisory databases.
- Record exact versions or commits, URLs, access dates, applicability, limitations, and unresolved uncertainty in `.research/SOURCES.md`.
- Search maintained libraries and platform facilities that could replace custom machinery. Compare semantic fit, ownership, compatibility, transitive cost, licenses, advisories, maintenance, runtime performance, code size, compile time, and total maintenance burden.
- Research approaches the operator and previous agents did not name.
- Treat patterns as candidates, not goals. Accept one only when it removes invalid states, duplicated authority, coupling, machinery, or measurable cost.
- Check current stable Rust, standard-library capabilities, Rust API Guidelines, Rust design patterns, and relevant Gang-of-Four patterns. Prefer algebraic Rust over ceremonial object-oriented translation.

## Rust and Nix conventions

- Run development, formatting, tests, benchmarks, audits, and validation through the repository's Nix shell or flake outputs. Do not install ad hoc host dependencies.
- Model alternatives with sum types and simultaneous data with product types. Do not introduce boolean state, boolean protocol results, boolean mode flags, or boolean parameters; ordinary predicates may return `bool`.
- Use `thiserror` for error definitions unless a measured `no_std`, dependency, compile-time, or compatibility constraint disproves it.
- Minimize the public API to demonstrated consumer capabilities. Keep mechanism, construction details, and proof scaffolding private or under explicit advanced modules.
- Minimize explicit type annotations where inference remains clear and robust. Preserve meaningful domain, identity, generation, and capability types.
- Prefer current stable Rust and standard-library machinery over custom code. Compare maintained crates before retaining handcrafted collections, synchronization, futures, identities, state-machine helpers, error machinery, or model-checking infrastructure.
- Keep all targets warning-free under the repository's rustfmt and Clippy policy.
- Treat runtime performance as mandatory. Define representative workloads and invariants before selecting algorithms or data structures; retain reproducible benchmarks.
- Validate behavior changes with the applicable combination of unit, property, exhaustive, stress, Loom, Miri, fuzz, mutation, doctest, coverage, and benchmark evidence. Record unavailable or inapplicable tools honestly.
- After every retained pass, audit the entire Rust workspace for unnecessary abstractions, duplication, allocations, dependencies, public seams, clones, locks, queues, options, unreachable paths, and `expect`-enforced state.

## Iterate

Perform one independently reviewable experiment at a time:

1. Select the highest-value unresolved hypothesis while rotating repository domains.
2. Record its threatened invariant, workload, change, falsifier, measurements, rollback boundary, and expected value before editing.
3. Add the characterization or adversarial test needed to expose regression before changing subtle behavior.
4. Implement the smallest coherent experiment.
5. Run targeted verification, then relevant full checks and repeated measurements.
6. Keep only an evidence-backed net improvement. Revert failures completely and record the dead end.
7. Commit each retained experiment separately using the repository convention.
8. Re-audit the entire project after every retained batch.

Never weaken a contract, test, workload, or gate to make an experiment pass. Never replace local code with a dependency merely to move maintenance elsewhere. Never optimize a proxy alone.

## Converge

Require two consecutive fresh whole-repository audits to find no credible, untested high-value hypothesis. Then run the complete verification matrix, compare final metrics with baseline, and perform an adversarial review that starts from source and contract rather than prior conclusions. Any credible finding reopens the loop.

Keep `.research/PROGRESS.md` current so a fresh context can resume without conversation history. In endless mode, continue challenging the weakest evidence until the operator stops the loop.
