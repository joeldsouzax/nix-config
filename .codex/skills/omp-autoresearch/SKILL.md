---
name: omp-autoresearch
description: Operate the repository's OMP autoresearch profile backed by the local Qwen3-Coder-Rust llama.cpp server. Use when the user asks for autoresearch, a long-running scored experiment loop, iterative optimization, or research delegated to the local model.
---

# OMP Autoresearch

1. Define a measurable objective, evaluation command, constraints, and stopping condition with the user. Do not start an open-ended loop without a score or concrete success criterion.
2. Check prerequisites:

   ```bash
   command -v omp
   command -v rust-llm
   curl --fail --silent http://127.0.0.1:8012/health
   ```

3. If the local server is not running, start it with `pueue add -- rust-llm`. This may download roughly 13.4 GB on first use, so obtain user approval before starting when the model is absent.
4. Start the profile from the target repository with `omp --profile autoresearch`, passing the objective, evaluation procedure, allowed files, budget, and stopping condition in the prompt.
5. Use `pueue` for a long-running non-interactive job. Report the task ID and how to inspect or stop it. Do not busy-wait.
6. On completion, independently inspect the diff and rerun the authoritative evaluation before accepting the result.

Keep the loop inside the user-authorized repository. Do not allow it to publish, deploy, alter secrets, or perform destructive Git operations unless separately authorized.
