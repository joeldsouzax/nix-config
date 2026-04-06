# Paperclip + Hermes AI Agents Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install Paperclip and Hermes Agent as persistent services on both NixOS and Darwin, with SOPS-managed secrets and Slack gateway for Hermes.

**Architecture:** Nix-managed git clones with declarative service wrappers. Runtime deps via `home.packages`, repos cloned during `home.activation`, services via `systemd.user.services` (Linux) and `launchAgents` (Darwin). Secrets injected from SOPS at runtime.

**Tech Stack:** Nix flakes, home-manager, sops-nix, systemd, launchd, Node.js 20, pnpm, Python 3.11, uv

---

### Task 1: Enable SOPS on Darwin

**Files:**
- Modify: `flake.nix:96-112` (darwinConfigurations block)
- Modify: `darwin/default.nix` (add sops block)

**Step 1: Add sops-nix Darwin module to flake.nix**

In `flake.nix`, inside `darwinConfigurations."joel"`, add `sops-nix.darwinModules.sops` to the modules list:

```nix
darwinConfigurations."joel" = nix-darwin.lib.darwinSystem {
  modules = [
    ./darwin
    sops-nix.darwinModules.sops
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
  ];
  specialArgs = {
    inherit inputs vars;
    stable = import nixpkgs-stable {
      system = "aarch64-darwin";
      config.allowUnfree = true;
    };
  };
};
```

**Step 2: Add SOPS config block to darwin/default.nix**

Add after the `nix = { ... };` block (~line 49):

```nix
# ── SOPS Secrets ─────────────────────────────────────────────────────
sops = {
  defaultSopsFile = ../secrets/secrets.yaml;
  defaultSopsFormat = "yaml";
  age.keyFile = "/Users/${vars.user}/.config/sops/age/keys.txt";

  secrets = {
    claude_key = {
      owner = vars.user;
    };
    hermes_slack_bot_token = {
      owner = vars.user;
    };
  };
};
```

**Step 3: Add SOPS secrets to NixOS config**

In `hosts/configuration.nix`, add to the existing `sops.secrets` block (~line 242):

```nix
"hermes_slack_bot_token" = {
  owner = "joel";
};
```

The `claude_key` secret already exists in `modules/programs/others.nix`.

**Step 4: Validate syntax**

Run: `nix-instantiate --parse flake.nix`
Expected: No errors

Run: `nix-instantiate --parse darwin/default.nix`
Expected: No errors

**Step 5: Evaluate Darwin config**

Run: `nix eval .#darwinConfigurations.joel.config.system.build.toplevel --raw 2>&1 | tail -1`
Expected: A store path (no errors)

**Step 6: Commit**

```bash
git add flake.nix darwin/default.nix hosts/configuration.nix
git commit -m "feat: enable sops-nix on Darwin and add new secret entries"
```

---

### Task 2: Create ai-agents.nix — Dependencies and Activation Scripts

**Files:**
- Create: `modules/home/ai-agents.nix`
- Modify: `modules/home/default.nix`

**Step 1: Create the module with dependencies and activation**

Create `modules/home/ai-agents.nix`:

```nix
# AI Agents: Paperclip + Hermes
# Shared between NixOS and Darwin via home-manager
#
# Installs runtime deps, clones repos on activation, and manages services.
# Secrets injected from SOPS at runtime.

{ config, lib, pkgs, vars, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  homeDir = if isDarwin then "/Users/${vars.user}" else "/home/${vars.user}";
  dataDir = "${homeDir}/.local/share";

  paperclipDir = "${dataDir}/paperclip";
  hermesDir = "${dataDir}/hermes";
  hermesVenv = "${hermesDir}/venv";

  # SOPS secret paths (populated by sops-nix at activation)
  claudeKeyPath = lib.attrByPath [ "sops" "secrets" "claude_key" "path" ] "" config;
  slackTokenPath = lib.attrByPath [ "sops" "secrets" "hermes_slack_bot_token" "path" ] "" config;

  # Wrapper script for services — reads SOPS secrets and execs the process
  mkServiceWrapper = name: execCmd: envVars: pkgs.writeShellScript "${name}-wrapper" ''
    set -euo pipefail
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (envName: secretPath: ''
      if [ -f "${secretPath}" ]; then
        export ${envName}="$(cat "${secretPath}")"
      fi
    '') envVars)}
    exec ${execCmd}
  '';

  paperclipWrapper = mkServiceWrapper "paperclip"
    "${pkgs.nodejs_20}/bin/node ${paperclipDir}/dist/index.js"
    { ANTHROPIC_API_KEY = claudeKeyPath; };

  hermesWrapper = mkServiceWrapper "hermes"
    "${hermesVenv}/bin/hermes --headless"
    {
      ANTHROPIC_API_KEY = claudeKeyPath;
      SLACK_BOT_TOKEN = slackTokenPath;
    };

  hermesGatewayWrapper = mkServiceWrapper "hermes-gateway"
    "${hermesVenv}/bin/hermes gateway start"
    {
      ANTHROPIC_API_KEY = claudeKeyPath;
      SLACK_BOT_TOKEN = slackTokenPath;
    };
in
{
  home-manager.users.${vars.user} = {

    # ── Runtime Dependencies ───────────────────────────────────────────
    home.packages = with pkgs; [
      # Paperclip
      pnpm
      postgresql

      # Hermes
      python311
      uv
      ffmpeg
    ];

    # ── Clone & Install on Activation ──────────────────────────────────
    home.activation.setupPaperclip = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "${paperclipDir}" ]; then
        ${pkgs.git}/bin/git clone https://github.com/paperclipai/paperclip.git "${paperclipDir}"
      fi
      cd "${paperclipDir}"
      ${pkgs.git}/bin/git pull --ff-only 2>/dev/null || true
      ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile 2>/dev/null || ${pkgs.pnpm}/bin/pnpm install
    '';

    home.activation.setupHermes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "${hermesDir}" ]; then
        ${pkgs.git}/bin/git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git "${hermesDir}"
      fi
      cd "${hermesDir}"
      ${pkgs.git}/bin/git pull --ff-only 2>/dev/null || true

      # Python venv + install
      if [ ! -d "${hermesVenv}" ]; then
        ${pkgs.python311}/bin/python3.11 -m venv "${hermesVenv}"
      fi
      export VIRTUAL_ENV="${hermesVenv}"
      ${pkgs.uv}/bin/uv pip install -e ".[all]" 2>/dev/null || true

      # Node deps
      ${pkgs.nodejs_20}/bin/npm install 2>/dev/null || true

      # Ensure hermes config dirs exist
      mkdir -p "${homeDir}/.hermes"/{sessions,logs,memories,skills,cron,hooks,pairing,image_cache,audio_cache}
    '';

    # ── Hermes Config ──────────────────────────────────────────────────
    home.file.".hermes/config.yaml".text = ''
      default_model: anthropic/claude-sonnet-4-20250514
      provider: anthropic
      gateway:
        slack:
          enabled: true
    '';
  };
}
```

**Step 2: Add to modules/home/default.nix**

Add `./ai-agents.nix` to the imports list:

```nix
[
  ./shell.nix
  ./programs.nix
  ./git.nix
  ./direnv.nix
  ./ghostty.nix
  ./ssh.nix
  ./ai-agents.nix
]
```

**Step 3: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: No errors

Run: `nix-instantiate --parse modules/home/default.nix`
Expected: No errors

**Step 4: Evaluate Darwin config**

Run: `nix eval .#darwinConfigurations.joel.config.system.build.toplevel --raw 2>&1 | tail -1`
Expected: A store path (no errors)

**Step 5: Commit**

```bash
git add modules/home/ai-agents.nix modules/home/default.nix
git commit -m "feat: add ai-agents module with deps and activation scripts"
```

---

### Task 3: Add Systemd User Services (NixOS)

**Files:**
- Modify: `modules/home/ai-agents.nix`

**Step 1: Add systemd service definitions**

In `modules/home/ai-agents.nix`, inside the `home-manager.users.${vars.user}` block, after the `home.file` section, add:

```nix
    # ── Services (NixOS — systemd user) ────────────────────────────────
    systemd.user.services = lib.mkIf isLinux {
      paperclip = {
        Unit = {
          Description = "Paperclip AI Agent Orchestration";
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${paperclipWrapper}";
          Restart = "on-failure";
          RestartSec = 10;
          WorkingDirectory = paperclipDir;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      hermes = {
        Unit = {
          Description = "Hermes AI Agent";
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${hermesWrapper}";
          Restart = "on-failure";
          RestartSec = 10;
          WorkingDirectory = hermesDir;
          Environment = [
            "HOME=${homeDir}"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      hermes-gateway = {
        Unit = {
          Description = "Hermes Slack Gateway";
          After = [ "hermes.service" "network-online.target" ];
          Requires = [ "hermes.service" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${hermesGatewayWrapper}";
          Restart = "on-failure";
          RestartSec = 10;
          WorkingDirectory = hermesDir;
          Environment = [
            "HOME=${homeDir}"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
```

**Step 2: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: No errors

**Step 3: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat: add systemd user services for paperclip and hermes"
```

---

### Task 4: Add LaunchAgents (Darwin)

**Files:**
- Modify: `modules/home/ai-agents.nix`

**Step 1: Add launchd agent definitions**

In `modules/home/ai-agents.nix`, inside the `home-manager.users.${vars.user}` block, after the systemd section, add:

```nix
    # ── Services (Darwin — launchd) ────────────────────────────────────
    launchd.agents = lib.mkIf isDarwin {
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
        };
      };

      hermes = {
        enable = true;
        config = {
          Label = "com.hermes.agent";
          ProgramArguments = [ "${hermesWrapper}" ];
          WorkingDirectory = hermesDir;
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "${homeDir}/Library/Logs/hermes.log";
          StandardErrorPath = "${homeDir}/Library/Logs/hermes.error.log";
          EnvironmentVariables = {
            HOME = homeDir;
          };
        };
      };

      hermes-gateway = {
        enable = true;
        config = {
          Label = "com.hermes.gateway";
          ProgramArguments = [ "${hermesGatewayWrapper}" ];
          WorkingDirectory = hermesDir;
          KeepAlive = {
            OtherJobEnabled = {
              "com.hermes.agent" = true;
            };
          };
          RunAtLoad = true;
          StandardOutPath = "${homeDir}/Library/Logs/hermes-gateway.log";
          StandardErrorPath = "${homeDir}/Library/Logs/hermes-gateway.error.log";
          EnvironmentVariables = {
            HOME = homeDir;
          };
        };
      };
    };
```

**Step 2: Validate syntax**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: No errors

**Step 3: Evaluate Darwin config**

Run: `nix eval .#darwinConfigurations.joel.config.system.build.toplevel --raw 2>&1 | tail -1`
Expected: A store path

**Step 4: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat: add launchd agents for paperclip and hermes on Darwin"
```

---

### Task 5: Add Slack Bot Token to SOPS Secrets

**Files:**
- Modify: `secrets/secrets.yaml`

**Step 1: Add placeholder secret**

This is a manual step. The user must:

```bash
nix-shell -p sops --run "sops secrets/secrets.yaml"
```

Add line:
```yaml
hermes_slack_bot_token: xoxb-your-slack-bot-token-here
```

Save and exit. SOPS encrypts automatically.

**Step 2: Verify encryption**

Run: `head -1 secrets/secrets.yaml`
Expected: Should NOT show plaintext — should show `ENC[AES256_GCM,data:...]`

**Step 3: Commit**

```bash
git add secrets/secrets.yaml
git commit -m "feat: add hermes slack bot token to SOPS secrets"
```

---

### Task 6: Shell Aliases and Final Validation

**Files:**
- Modify: `modules/home/ai-agents.nix`

**Step 1: Add convenience aliases**

In `modules/home/ai-agents.nix`, inside the `home-manager.users.${vars.user}` block, add:

```nix
    # ── Shell Aliases ──────────────────────────────────────────────────
    programs.zsh.shellAliases = {
      paperclip-logs = if isDarwin
        then "tail -f ~/Library/Logs/paperclip.log"
        else "journalctl --user -u paperclip -f";
      hermes-logs = if isDarwin
        then "tail -f ~/Library/Logs/hermes.log"
        else "journalctl --user -u hermes -f";
      paperclip-restart = if isDarwin
        then "launchctl kickstart -k gui/$(id -u)/com.paperclip.agent"
        else "systemctl --user restart paperclip";
      hermes-restart = if isDarwin
        then "launchctl kickstart -k gui/$(id -u)/com.hermes.agent && launchctl kickstart -k gui/$(id -u)/com.hermes.gateway"
        else "systemctl --user restart hermes hermes-gateway";
    };
```

**Step 2: Full syntax validation**

Run: `nix-instantiate --parse modules/home/ai-agents.nix`
Expected: No errors

**Step 3: Full Darwin evaluation**

Run: `nix eval .#darwinConfigurations.joel.config.system.build.toplevel --raw 2>&1 | tail -1`
Expected: A store path

**Step 4: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat: add convenience aliases for ai-agent log viewing and restarts"
```

---

### Task 7: Apply and Verify (Darwin)

**Step 1: Apply the configuration**

Run: `sudo darwin-rebuild switch --flake ~/.setup#joel`
Expected: Build succeeds, activation runs clone scripts

**Step 2: Verify repos cloned**

Run: `ls ~/.local/share/paperclip/package.json && ls ~/.local/share/hermes/setup.py`
Expected: Both files exist

**Step 3: Verify SOPS secrets decrypted**

Run: `ls -la /run/user/$(id -u)/secrets/ 2>/dev/null || ls -la /run/secrets/ 2>/dev/null`
Expected: `claude_key` and `hermes_slack_bot_token` files present

**Step 4: Verify services running**

Run: `launchctl list | grep -E "paperclip|hermes"`
Expected: Three services listed (paperclip, hermes, hermes-gateway)

**Step 5: Check Paperclip web UI**

Run: `curl -s http://localhost:3100 | head -5`
Expected: HTML response from Paperclip

**Step 6: Check logs**

Run: `tail -20 ~/Library/Logs/paperclip.log`
Run: `tail -20 ~/Library/Logs/hermes.log`
Expected: Startup logs, no fatal errors
