# Immutable contract

## Objective

<!-- State the outcome being optimized. -->

## Preserved behavior and guarantees

<!-- List architecture, features, semantics, safety properties, compatibility, and ownership rules that may not weaken. -->

## Performance contract

<!-- Define representative workloads and acceptable regression bounds. -->

## Operator constraints

<!-- Record explicit technology, architecture, tooling, and scope constraints. -->

## Rust and Nix conventions

- Use Nix for development and verification.
- Prefer sum/product modeling over boolean or sentinel protocols.
- Use `thiserror` unless an evidenced constraint prevents it.
- Minimize public API and redundant type specification without erasing domain types.
- Preserve or improve representative performance.
