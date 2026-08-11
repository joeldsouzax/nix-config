# Rust and Nix research protocol

## Durable evidence

Maintain these files under `.research/`:

- `CONTRACT.md`: immutable behavior and constraints.
- `BASELINE.md`: commands, workloads, environment, raw-result locations, and initial metrics.
- `INVENTORY.md`: architecture, public surface, dependencies, custom machinery, risks, and verification coverage.
- `SOURCES.md`: primary-source and candidate-library evidence.
- `HYPOTHESES.md`: ordered experiments with falsifiers and rollback boundaries.
- `EXPERIMENTS.jsonl`: append-only machine-readable experiment outcomes.
- `PROGRESS.md`: current state and exact next actions.
- `DEAD_ENDS.md`: rejected approaches and evidence preventing blind retries.

## Audit lenses

Rotate through:

1. duplicated semantic authority and representations;
2. invalid representable states, sentinels, boolean blindness, and capability leakage;
3. public obligations callers can omit, reorder, duplicate, forge, or mismatch;
4. concurrency, linearization, cancellation, reclamation, panic, and reentrancy;
5. allocations, copies, clones, queues, locks, syscalls, indirection, and cache behavior;
6. adapters, forwarding APIs, aliases, wrappers, generic machinery, and type noise;
7. standard-library or maintained-library replacements for handcrafted code;
8. dependency value, transitive cost, supply chain, licenses, advisories, and maintenance;
9. correctness coverage: unit, property, exhaustive, stress, model checking, sanitizers, fuzzing, and mutation tests as applicable;
10. documentation claims not connected to executable behavior or measurements.
11. Rust API surface: every `pub` item, required type annotation, trait bound, conversion, and construction seam.
12. Rust state modeling: boolean protocols, sentinel values, invalid products, identity confusion, and dynamic ownership that types could enforce.
13. Nix reproducibility: flake purity, locked inputs, derivation coverage, platform evaluation, package metadata, development shells, and host-tool leakage.

## Measurement discipline

- Define representative workloads and invariants before selecting an algorithm or data structure.
- Record hardware, toolchain, build mode, inputs, warmup, samples, dispersion, and raw results.
- Measure the noise floor before accepting small differences.
- Change one causal variable where practical.
- Check runtime, memory, allocations, code size, and compile time when relevant.
- Preserve a reproducible baseline commit or worktree.

## Dependency decision

Require exact semantic and ownership fit, supported toolchains/platforms, acceptable transitive and supply-chain cost, healthy maintenance, compatible licensing, benchmark parity or improvement, and a smaller total correctness/maintenance burden. Popularity alone is not evidence.

Audit current standard-library facilities first. Then compare maintained crates for collections, concurrency, futures, errors, generational identities, state machines, property testing, fuzzing, model checking, benchmarking, and build/audit integration. Include `thiserror` as the default error candidate, but measure and document exceptions.

## Fixed-point falsification

Start a fresh pass that attempts to find at least:

- one duplicated authority;
- one invalid state or misuse seam;
- one avoidable cost or abstraction;
- one missing adversarial interleaving or failure path;
- one credible maintained replacement for custom machinery;
- one workload capable of reversing an earlier decision;
- one public surface item without a demonstrated consumer.
- one Rust or Nix feature that can replace custom machinery;
- one boolean or sentinel protocol better represented by a sum or product type;

Any credible untested finding prevents completion.
