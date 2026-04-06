# MLX-LM Inference Server Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a local MLX-LM inference server as a Darwin launchd service running Qwen3-8B-4bit, wired to Hermes and Paperclip.

**Architecture:** Standalone Python venv at `~/.local/share/mlx-server/venv` with `mlx-lm` installed. launchd agent runs `mlx_lm.server` on port 8800. Hermes and Paperclip configs point at the local OpenAI-compatible endpoint.

**Tech Stack:** Nix (darwin), home-manager launchd agents, Python/uv, mlx-lm, MLX/Metal

---

### Task 1: Add MLX server variables to the let block

**Files:**
- Modify: `modules/home/ai-agents.nix:17-19` (after `hermesVenv` definition)

**Step 1: Add variables**

After line 19 (`hermesVenv = "${hermesDir}/venv";`), add:

```nix
  mlxServerDir = "${dataDir}/mlx-server";
  mlxServerVenv = "${mlxServerDir}/venv";
  mlxModel = "mlx-community/Qwen3-8B-4bit";
  mlxPort = "8800";
```

**Step 2: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: Parsed output, no errors

**Step 3: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(ai-agents): add mlx-server variables"
```

---

### Task 2: Add MLX server wrapper script

**Files:**
- Modify: `modules/home/ai-agents.nix:39-41` (after `hermesWrapper` definition)

**Step 1: Add the wrapper script**

After the `hermesWrapper` definition (line 41), add:

```nix
  mlxServerWrapper = pkgs.writeShellScript "mlx-server-wrapper" ''
    set -euo pipefail
    export PATH="${mlxServerVenv}/bin:$PATH"
    exec ${mlxServerVenv}/bin/python -m mlx_lm.server \
      --model ${mlxModel} \
      --port ${mlxPort}
  '';
```

**Step 2: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: Parsed output, no errors

**Step 3: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(ai-agents): add mlx-server wrapper script"
```

---

### Task 3: Add MLX server setup to activation script

**Files:**
- Modify: `modules/home/ai-agents.nix:44-72` (the `setupScript` derivation)

**Step 1: Add mlx-server setup block**

Inside the `setupScript` string, after the Hermes setup block (after line 70, the `mkdir -p` line), add:

```nix
    echo "Setting up MLX inference server..."
    mkdir -p "${mlxServerDir}"
    if [ ! -d "${mlxServerVenv}" ]; then
      ${pkgs.python311}/bin/python3.11 -m venv "${mlxServerVenv}"
    fi
    ${pkgs.uv}/bin/uv pip install --python "${mlxServerVenv}/bin/python" mlx-lm 2>/dev/null || true

    echo "Pre-downloading model ${mlxModel} (this may take a while on first run)..."
    ${mlxServerVenv}/bin/python -c "from mlx_lm import load; load('${mlxModel}')" 2>/dev/null || true
```

Note: We use `mlx_lm.load()` to trigger the HuggingFace download + MLX conversion in one step, rather than a separate download command.

**Step 2: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: Parsed output, no errors

**Step 3: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(ai-agents): add mlx-lm venv setup and model pre-download"
```

---

### Task 4: Add MLX server launchd agent

**Files:**
- Modify: `modules/home/ai-agents.nix:146-175` (inside `launchd.agents` block)

**Step 1: Add the launchd agent**

Inside `launchd.agents = lib.mkIf isDarwin { ... }`, after the `hermes` agent block (after line 174), add:

```nix
      mlx-server = {
        enable = true;
        config = {
          Label = "com.mlx-server.agent";
          ProgramArguments = [ "${mlxServerWrapper}" ];
          WorkingDirectory = mlxServerDir;
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "${homeDir}/Library/Logs/mlx-server.log";
          StandardErrorPath = "${homeDir}/Library/Logs/mlx-server.error.log";
        };
      };
```

**Step 2: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: Parsed output, no errors

**Step 3: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(ai-agents): add mlx-server launchd agent"
```

---

### Task 5: Wire Hermes to local MLX endpoint

**Files:**
- Modify: `modules/home/ai-agents.nix:100-103` (the `.hermes/config.yaml` block)

**Step 1: Update Hermes config**

Replace the current Hermes config (lines 100-103):

```nix
    home.file.".hermes/config.yaml".text = ''
      default_model: anthropic/claude-sonnet-4-20250514
      provider: anthropic
    '';
```

With:

```nix
    home.file.".hermes/config.yaml".text = ''
      default_model: Qwen/Qwen3-8B
      provider: openai
      api_base: http://localhost:${mlxPort}/v1
    '';
```

**Step 2: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: Parsed output, no errors

**Step 3: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(ai-agents): wire hermes to local mlx endpoint"
```

---

### Task 6: Wire Paperclip to local MLX endpoint

**Files:**
- Modify: `modules/home/ai-agents.nix:35-37` (the `paperclipWrapper` definition)
- Modify: `modules/home/ai-agents.nix:148-158` (Paperclip launchd agent)

**Step 1: Add OpenAI env vars to Paperclip wrapper**

Replace the `paperclipWrapper` (lines 35-37):

```nix
  paperclipWrapper = mkServiceWrapper "paperclip"
    "${pkgs.pnpm}/bin/pnpm dev"
    { ANTHROPIC_API_KEY = claudeKeyPath; };
```

With:

```nix
  paperclipWrapper = mkServiceWrapper "paperclip"
    "${pkgs.pnpm}/bin/pnpm dev"
    { ANTHROPIC_API_KEY = claudeKeyPath; };

  paperclipEnv = {
    OPENAI_BASE_URL = "http://localhost:${mlxPort}/v1";
    OPENAI_API_KEY = "local";
  };
```

**Step 2: Add env vars to Paperclip launchd agent**

Inside the Paperclip launchd config block, add `EnvironmentVariables`:

```nix
      paperclip = {
        enable = true;
        config = {
          Label = "com.paperclip.agent";
          ProgramArguments = [ "${paperclipWrapper}" ];
          WorkingDirectory = paperclipDir;
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "${homeDir}/Library/Logs/paperclip.log";
          StandardErrorPath = "${homeDir}/Library/Logs/paperclip.error.log";
          EnvironmentVariables = paperclipEnv;
        };
      };
```

**Step 3: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: Parsed output, no errors

**Step 4: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(ai-agents): wire paperclip to local mlx endpoint"
```

---

### Task 7: Add shell aliases for MLX server

**Files:**
- Modify: `modules/home/ai-agents.nix:178-195` (the `programs.zsh.shellAliases` block)

**Step 1: Add mlx aliases**

Inside `programs.zsh.shellAliases`, add after the existing aliases:

```nix
      mlx-logs =
        if isDarwin
        then "tail -f ~/Library/Logs/mlx-server.log"
        else "echo 'MLX server is Darwin-only'";
      mlx-restart =
        if isDarwin
        then ''launchctl kickstart -k gui/"$(id -u)"/com.mlx-server.agent''
        else "echo 'MLX server is Darwin-only'";
```

**Step 2: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: Parsed output, no errors

**Step 3: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(ai-agents): add mlx-server shell aliases"
```

---

### Task 8: Full evaluation check

**Step 1: Evaluate Darwin configuration**

Run: `nix eval .#darwinConfigurations.joel.config.system.build.toplevel --raw`
Expected: Nix store path, no errors

**Step 2: Final commit if any fixups needed**

```bash
git add modules/home/ai-agents.nix
git commit -m "fix(ai-agents): fixups from evaluation check"
```
