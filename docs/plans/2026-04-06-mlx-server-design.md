# MLX-LM Inference Server for Darwin

**Date:** 2026-04-06
**Status:** Approved

## Goal

Run a local Qwen3-8B model on Apple Silicon via `mlx-lm serve`, exposed as an OpenAI-compatible API, and wire it to Hermes and Paperclip agents.

## Architecture

```
launchd (com.mlx-server.agent)
  └─ mlx-lm server (port 8800)
       └─ Qwen3-8B-4bit (MLX format, ~5GB VRAM)
            ├─ Hermes → provider: openai, base_url: http://localhost:8800/v1
            └─ Paperclip → OPENAI_BASE_URL=http://localhost:8800/v1
```

## Components (all in `modules/home/ai-agents.nix`)

### 1. MLX Server venv + setup

- Path: `~/.local/share/mlx-server/venv`
- Installed via `uv pip install mlx-lm` in activation script
- Model pre-downloaded via `mlx_lm.download --model mlx-community/Qwen3-8B-4bit`

### 2. launchd agent

- Label: `com.mlx-server.agent`
- Command: `mlx_lm.server --model mlx-community/Qwen3-8B-4bit --port 8800`
- KeepAlive, RunAtLoad
- Logs: `~/Library/Logs/mlx-server.{log,error.log}`

### 3. Hermes config update

```yaml
default_model: Qwen/Qwen3-8B
provider: openai
api_base: http://localhost:8800/v1
```

### 4. Paperclip wiring

Add environment variables to Paperclip wrapper/launchd:
- `OPENAI_BASE_URL=http://localhost:8800/v1`
- `OPENAI_API_KEY=local` (required by client libraries but unused locally)

### 5. Shell aliases

- `mlx-logs` — tail mlx-server log
- `mlx-restart` — kickstart launchd agent

## Constraints

- **Darwin-only** — guarded by `isDarwin` (MLX is Apple Silicon only)
- **Port 8800** — avoids common dev port conflicts
- **Qwen3-8B-4bit** — ~5GB memory, leaves headroom on 16GB+ Macs
- **Standalone venv** — no dependency conflicts with Hermes venv

## Decisions

- Chose `mlx-lm serve` over vllm-metal for minimal overhead (thin HTTP layer only)
- Chose standalone venv over Nix derivation (Python ML packages are painful to package in Nix)
- Pre-download model in activation script so first service start isn't slow
