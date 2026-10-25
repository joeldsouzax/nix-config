# Hypotheses

## H01: dependency refresh

Implemented; local checks and full Mac evaluation pass. Full Linux evaluation and flake gate remain unverified, with exact failures recorded in PROGRESS.md. Updates preserve both host definitions and agent integrations. Change budget stayed within dependency pins, required compatibility fixes and their documentation. Linux runtime benchmarks and kernel/VM execution cannot be claimed from Mac assertions or derivation evaluation.

## H02: Finder metadata cleanup

Complete. Matching files were removed, including the tracked editors file. Both spellings are ignored at any depth; a final checkout search is empty and nested git check-ignore succeeds.
