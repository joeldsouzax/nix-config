---
name: devrandom-research
description: Run a repository-independent, evidence-driven research loop that discovers, tests, measures, keeps, or rejects improvements until an adversarially verified fixed point. Use for deep code tightening, architecture review, performance work, dependency replacement, robustness audits, interface reduction, or any request to research and improve a project autonomously without weakening its contract.
---

# Devrandom Research

Discover improvements from evidence. Do not treat operator suggestions, earlier agent conclusions, popular patterns, dependencies, or lower source-line counts as proof.

Read [references/protocol.md](references/protocol.md) completely before the first mutation and after context recovery.

## Initialize

1. Read every applicable repository instruction file.
2. Inspect git status and preserve unrelated work.
3. Run `devrandom-research-init` at the repository root. Resume existing `.research/` files without overwriting them.
4. Write the immutable contract before proposing changes: features, semantics, compatibility, safety, performance, platform, tooling, and operator constraints.
5. Establish reproducible behavioral, performance, allocation, code-size, compile-time, dependency, public-surface, and complexity baselines appropriate to the project.
6. Inventory the whole repository and its custom machinery before choosing a target.

## Research

- Search current primary sources: official documentation and source, specifications, original papers, upstream issue trackers, release histories, and security/advisory databases.
- Record exact versions or commits, URLs, access dates, applicability, limitations, and unresolved uncertainty in `.research/SOURCES.md`.
- Search maintained libraries and platform facilities that could replace custom machinery. Compare semantic fit, ownership, compatibility, transitive cost, licenses, advisories, maintenance, runtime performance, code size, compile time, and total maintenance burden.
- Research approaches the operator and previous agents did not name.
- Treat patterns as candidates, not goals. Accept one only when it removes invalid states, duplicated authority, coupling, machinery, or measurable cost.

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
