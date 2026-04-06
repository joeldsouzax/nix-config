# AI Agents: Paperclip + Hermes
# Shared between NixOS and Darwin via home-manager
#
# Installs runtime deps, clones repos on activation, and manages services.
# Secrets injected from SOPS at runtime via wrapper scripts.
# Hermes runs as CLI-only (no gateway).

{ config, lib, pkgs, vars, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  homeDir = if isDarwin then "/Users/${vars.user}" else "/home/${vars.user}";
  dataDir = "${homeDir}/.local/share";

  paperclipDir = "${dataDir}/paperclip";
  hermesDir = "${dataDir}/hermes";
  hermesVenv = "${hermesDir}/venv";

  mlxServerDir = "${dataDir}/mlx-server";
  mlxServerVenv = "${mlxServerDir}/venv";
  mlxModel = "mlx-community/Qwen3-14B-4bit";
  mlxPort = "8800";

  # SOPS secret paths (populated by sops-nix at activation)
  claudeKeyPath = lib.attrByPath [ "sops" "secrets" "claude_key" "path" ] "" config;

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
    "${pkgs.pnpm}/bin/pnpm dev"
    { ANTHROPIC_API_KEY = claudeKeyPath; };

  hermesWrapper = mkServiceWrapper "hermes"
    "${hermesVenv}/bin/hermes --headless"
    { ANTHROPIC_API_KEY = claudeKeyPath; };

  mlxServerWrapper = pkgs.writeShellScript "mlx-server-wrapper" ''
    set -euo pipefail
    export PATH="${mlxServerVenv}/bin:$PATH"
    exec ${mlxServerVenv}/bin/python -m mlx_lm server \
      --model ${mlxModel} \
      --port ${mlxPort}
  '';

  # Clone/install script as a derivation (runs as user via sudo -u)
  setupScript = pkgs.writeShellScript "setup-ai-agents" ''
    set -euo pipefail
    USER_HOME="${homeDir}"

    echo "Setting up Paperclip..."
    if [ ! -d "${paperclipDir}" ]; then
      ${pkgs.git}/bin/git clone https://github.com/paperclipai/paperclip.git "${paperclipDir}"
    fi
    cd "${paperclipDir}"
    ${pkgs.git}/bin/git pull --ff-only 2>/dev/null || true
    ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile 2>/dev/null || ${pkgs.pnpm}/bin/pnpm install || true

    echo "Setting up Hermes Agent..."
    if [ ! -d "${hermesDir}" ]; then
      ${pkgs.git}/bin/git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git "${hermesDir}"
    fi
    cd "${hermesDir}"
    ${pkgs.git}/bin/git pull --ff-only 2>/dev/null || true

    if [ ! -d "${hermesVenv}" ]; then
      ${pkgs.python311}/bin/python3.11 -m venv "${hermesVenv}"
    fi
    export VIRTUAL_ENV="${hermesVenv}"
    ${pkgs.uv}/bin/uv pip install -e ".[all]" 2>/dev/null || true
    ${pkgs.nodejs_20}/bin/npm install 2>/dev/null || true

    mkdir -p "$USER_HOME/.hermes"/{sessions,logs,memories,skills,cron,hooks,pairing,image_cache,audio_cache}

    if [ "$(uname)" = "Darwin" ]; then
      echo "Setting up MLX inference server..."
      mkdir -p "${mlxServerDir}"
      if [ ! -d "${mlxServerVenv}" ]; then
        ${pkgs.python311}/bin/python3.11 -m venv "${mlxServerVenv}"
      fi
      ${pkgs.uv}/bin/uv pip install --python "${mlxServerVenv}/bin/python" mlx-lm 2>/dev/null || true

      echo "Pre-downloading model ${mlxModel} (this may take a while on first run)..."
      ${mlxServerVenv}/bin/python -c "from huggingface_hub import snapshot_download; snapshot_download('${mlxModel}')" 2>/dev/null || true
    fi

    echo "AI agents setup complete."
  '';
in
{
  # ── Clone & Install on Activation ──────────────────────────────────
  # nix-darwin only runs hardcoded script names (postActivation, etc.)
  # so we append to postActivation on Darwin, custom name on NixOS.
  system.activationScripts = if isDarwin then {
    postActivation.text = lib.mkAfter ''
      echo "Setting up AI agents for ${vars.user}..."
      sudo -u ${vars.user} ${setupScript}
    '';
  } else {
    setupAiAgents = ''
      echo "Setting up AI agents for ${vars.user}..."
      sudo -u ${vars.user} ${setupScript}
    '';
  };

  home-manager.users.${vars.user} = {

    # ── Runtime Dependencies ───────────────────────────────────────────
    home.packages = with pkgs; [
      pnpm
      postgresql
      python311
      uv
      ffmpeg
    ];

    # ── Hermes Config ──────────────────────────────────────────────────
    home.file.".hermes/config.yaml".text = ''
      default_model: ${mlxModel}
      provider: openai
      api_base: http://localhost:${mlxPort}/v1
    '';

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
    };

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
          EnvironmentVariables = {
            OPENAI_BASE_URL = "http://localhost:${mlxPort}/v1";
            OPENAI_API_KEY = "local";
          };
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
    };

    # ── Shell Aliases ──────────────────────────────────────────────────
    programs.zsh.shellAliases = {
      paperclip-logs =
        if isDarwin
        then "tail -f ~/Library/Logs/paperclip.log"
        else "journalctl --user -u paperclip -f";
      hermes-logs =
        if isDarwin
        then "tail -f ~/Library/Logs/hermes.log"
        else "journalctl --user -u hermes -f";
      paperclip-restart =
        if isDarwin
        then ''launchctl kickstart -k gui/"$(id -u)"/com.paperclip.agent''
        else "systemctl --user restart paperclip";
      hermes-restart =
        if isDarwin
        then ''launchctl kickstart -k gui/"$(id -u)"/com.hermes.agent''
        else "systemctl --user restart hermes";
      mlx-logs =
        if isDarwin
        then "tail -f ~/Library/Logs/mlx-server.log"
        else "echo 'MLX server is Darwin-only'";
      mlx-restart =
        if isDarwin
        then ''launchctl kickstart -k gui/"$(id -u)"/com.mlx-server.agent''
        else "echo 'MLX server is Darwin-only'";
    };
  };
}
