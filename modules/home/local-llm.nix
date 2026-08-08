# Local LLM inference (llama.cpp) for omp autoresearch ONLY
# Shared between NixOS and Darwin via home-manager
#
# Serves Em-80/Qwen3-coder-REAP-25B-A3B-Rust-GGUF (Apache-2.0) — a
# REAP-pruned Qwen3-Coder-30B-A3B MoE fine-tuned for Rust. IQ4_XS was
# chosen for the 24 GB M4 Pro: 13.4 GB weights + q8_0 KV cache at 32k
# context stays under the ~18 GB Metal wired-memory limit. nixpkgs
# builds llama-cpp with Metal on aarch64-darwin; on the NixOS desktop
# (8 GB GTX 1070) this is a CPU-only fallback — usable, but slow.
#
# Scoped to long-running autoresearch sessions — the default omp
# profile (Kimi K3) stays the coding harness. 49k context
# (13.4 + ~2.5 KV + ~1.2 compute ≈ 17 GB) lets research chains go
# long before compaction. Start under pueue so the server outlives
# the terminal: `pueue add -- rust-llm`
#
# Usage: `rust-llm` starts the server (downloads the model on first
# run), then `omp --profile autoresearch` (alias: omp-research)
# talks to it. Profile config: ~/.omp/profiles/autoresearch/agent/

{ pkgs, vars, ... }:

let
  modelRepo = "Em-80/Qwen3-coder-REAP-25B-A3B-Rust-GGUF";
  modelFile = "Qwen3-Coder-REAP-25B-A3B-Rust-IQ4_XS.gguf";
  modelAlias = "qwen3-coder-rust"; # must match the model id in ~/.omp/profiles/autoresearch/agent/models.json
  port = "8012";

  rust-llm = pkgs.writeShellScriptBin "rust-llm" ''
    set -euo pipefail
    model_dir="$HOME/.models/gguf"
    model="$model_dir/${modelFile}"

    if [ ! -f "$model" ]; then
      echo "Downloading ${modelFile} (~13.4 GB, resumable)..."
      mkdir -p "$model_dir"
      ${pkgs.curl}/bin/curl -L -C - --fail --progress-bar \
        -o "$model.partial" \
        "https://huggingface.co/${modelRepo}/resolve/main/${modelFile}"
      mv "$model.partial" "$model"
    fi

    # --jinja enables the model's chat-template tool calling (required
    # for omp's edit/bash tools). KV cache at q8_0 halves cache memory
    # so 32k context fits the Metal wired limit on 24 GB.
    # Sampling defaults per Qwen3-Coder model card.
    exec ${pkgs.llama-cpp}/bin/llama-server \
      --model "$model" \
      --alias ${modelAlias} \
      --host 127.0.0.1 --port ${port} \
      --ctx-size 49152 \
      --n-gpu-layers 99 \
      --jinja \
      --cache-type-k q8_0 --cache-type-v q8_0 \
      --temp 0.7 --top-p 0.8 --top-k 20 --repeat-penalty 1.05 \
      "$@"
  '';
in
{
  home-manager.users.${vars.user}.home.packages = [
    pkgs.llama-cpp # llama-server / llama-cli (Metal on Apple Silicon)
    rust-llm
  ];
}
