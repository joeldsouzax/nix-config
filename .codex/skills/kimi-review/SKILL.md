---
name: kimi-review
description: Run an independent review of a working-tree diff with the configured OMP/Kimi coding harness. Use when the user asks for Kimi delegation, a Kimi check, a second-model opinion, or an independent review before committing or opening a pull request.
---

# Kimi Review

1. Confirm `omp` is available with `command -v omp`. If unavailable, report that the Homebrew-managed OMP installation must be applied first.
2. Inspect `git status --short`, `git diff --stat`, `git diff`, and relevant untracked files. Do not stage or modify files.
3. Run OMP non-interactively from the repository root:

   ```bash
   omp -p "CHECK: review the working-tree diff (git diff HEAD, plus untracked files) against AGENTS.md and the repository's engineering rules. Return findings only, ordered by severity, with file and line references. Do not modify files."
   ```

4. Treat Kimi's output as an independent review, not ground truth. Verify every material finding against the source and tests.
5. Report verified findings first. Clearly label rejected or uncertain Kimi findings if they are useful to mention.

Never expose secrets to OMP or include decrypted SOPS content in the prompt.
