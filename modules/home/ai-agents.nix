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

  pgDataDir = "${dataDir}/paperclip/pgdata";
  pgPort = "5433"; # avoid conflict with any system postgres
  pg = pkgs.postgresql.withPackages (ps: [ ps.pgvector ]);

  mlxServerDir = "${dataDir}/mlx-server";
  mlxServerVenv = "${mlxServerDir}/venv";
  mlxModel = "mlx-community/Qwen3-14B-4bit";
  mlxPort = "8800";

  embeddingServerDir = "${dataDir}/embedding-server";
  embeddingServerVenv = "${embeddingServerDir}/venv";
  embeddingModel = "BAAI/bge-base-en-v1.5";
  embeddingPort = "8801";

  knowledgeDir = "${dataDir}/knowledge-mcp";
  knowledgeVenv = "${knowledgeDir}/venv";

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

  # Paperclip wrapper — sets HOME and PATH so launchd can find node/pnpm
  paperclipWrapper = pkgs.writeShellScript "paperclip-wrapper" ''
    set -euo pipefail
    export HOME="${homeDir}"
    export PATH="${hermesVenv}/bin:${pkgs.nodejs_20}/bin:${pkgs.pnpm}/bin:$PATH"
    export DATABASE_URL="postgres://localhost:${pgPort}/paperclip"
    export PORT="3100"
    export SERVE_UI="true"
    exec ${pkgs.pnpm}/bin/pnpm dev
  '';

  hermesWrapper = mkServiceWrapper "hermes"
    "${hermesVenv}/bin/hermes chat"
    { ANTHROPIC_API_KEY = claudeKeyPath; };

  mlxServerWrapper = pkgs.writeShellScript "mlx-server-wrapper" ''
    set -euo pipefail
    export PATH="${mlxServerVenv}/bin:$PATH"
    exec ${mlxServerVenv}/bin/python -m mlx_lm server \
      --model ${mlxModel} \
      --port ${mlxPort}
  '';

  embeddingServerWrapper = pkgs.writeShellScript "embedding-server-wrapper" ''
    set -euo pipefail
    export PATH="${embeddingServerVenv}/bin:$PATH"
    cd "${embeddingServerDir}"
    exec ${embeddingServerVenv}/bin/python server.py
  '';

  # Clone/install script as a derivation (runs as user via sudo -u)
  setupScript = pkgs.writeShellScript "setup-ai-agents" ''
    set -euo pipefail
    USER_HOME="${homeDir}"

    export HOME="${homeDir}"
    export PATH="${pkgs.nodejs_20}/bin:${pkgs.pnpm}/bin:$PATH"

    echo "Setting up PostgreSQL for Paperclip..."
    if [ ! -d "${pgDataDir}" ]; then
      ${pg}/bin/initdb -D "${pgDataDir}" --no-locale --encoding=UTF8
      # Configure to listen on custom port
      echo "port = ${pgPort}" >> "${pgDataDir}/postgresql.conf"
      echo "unix_socket_directories = '/tmp'" >> "${pgDataDir}/postgresql.conf"
    fi
    # Start postgres temporarily to create the database if needed
    if ! ${pg}/bin/pg_isready -h localhost -p ${pgPort} -q 2>/dev/null; then
      ${pg}/bin/pg_ctl -D "${pgDataDir}" -l "${pgDataDir}/setup.log" start -w -t 10 2>/dev/null || true
      STARTED_PG=1
    fi
    ${pg}/bin/createdb -h localhost -p ${pgPort} paperclip 2>/dev/null || true
    ${pg}/bin/createdb -h localhost -p ${pgPort} knowledge 2>/dev/null || true
    ${pg}/bin/psql -h localhost -p ${pgPort} -d knowledge -c "CREATE EXTENSION IF NOT EXISTS vector" 2>/dev/null || true
    if [ "''${STARTED_PG:-}" = "1" ]; then
      ${pg}/bin/pg_ctl -D "${pgDataDir}" stop -m fast 2>/dev/null || true
    fi

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

      echo "Setting up embedding server..."
      mkdir -p "${embeddingServerDir}"
      if [ ! -d "${embeddingServerVenv}" ]; then
        ${pkgs.python311}/bin/python3.11 -m venv "${embeddingServerVenv}"
      fi
      ${pkgs.uv}/bin/uv pip install --python "${embeddingServerVenv}/bin/python" \
        sentence-transformers fastapi "uvicorn[standard]" 2>/dev/null || true
      echo "Pre-downloading embedding model ${embeddingModel}..."
      ${embeddingServerVenv}/bin/python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('${embeddingModel}')" 2>/dev/null || true
    fi

    echo "Setting up knowledge MCP server..."
    mkdir -p "${knowledgeDir}"
    if [ ! -d "${knowledgeVenv}" ]; then
      ${pkgs.python311}/bin/python3.11 -m venv "${knowledgeVenv}"
    fi
    ${pkgs.uv}/bin/uv pip install --python "${knowledgeVenv}/bin/python" \
      "psycopg[binary]" httpx pymupdf "mcp>=1.2.0,<2" 2>/dev/null || true

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
      python311
      uv
      ffmpeg
      llm
    ] ++ [ pg ];

    # ── Paperclip Config ────────────────────────────────────────────────
    home.file."${paperclipDir}/.env" = {
      text = ''
        DATABASE_URL=postgres://localhost:${pgPort}/paperclip
        PORT=3100
        SERVE_UI=true
      '';
      force = true;
    };

    # ── Hermes Config ──────────────────────────────────────────────────
    home.file.".hermes/config.yaml".text = ''
      model:
        default: ${mlxModel}
        provider: custom
        base_url: http://localhost:${mlxPort}/v1
      ui:
        show_reasoning: false
      mcp_servers:
        knowledge:
          command: "${knowledgeVenv}/bin/python"
          args: ["-m", "server"]
          env:
            DATABASE_URL: "postgres://localhost:${pgPort}/knowledge"
            EMBEDDING_URL: "http://localhost:${embeddingPort}/v1"
      memory:
        provider: knowledge
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
      paperclip-postgres = {
        enable = true;
        config = {
          Label = "com.paperclip.postgres";
          ProgramArguments = [
            "${pg}/bin/postgres"
            "-D" pgDataDir
            "-p" pgPort
            "-k" "/tmp"
          ];
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "${homeDir}/Library/Logs/paperclip-postgres.log";
          StandardErrorPath = "${homeDir}/Library/Logs/paperclip-postgres.error.log";
        };
      };

      paperclip = {
        enable = true;
        config = {
          Label = "com.paperclip.agent";
          ProgramArguments = [ "${paperclipWrapper}" ];
          WorkingDirectory = paperclipDir;
          KeepAlive = false;
          RunAtLoad = false;
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

      embedding-server = {
        enable = true;
        config = {
          Label = "com.embedding-server.agent";
          ProgramArguments = [ "${embeddingServerWrapper}" ];
          WorkingDirectory = embeddingServerDir;
          KeepAlive = true;
          RunAtLoad = true;
          EnvironmentVariables = {
            EMBEDDING_MODEL = embeddingModel;
            PORT = embeddingPort;
          };
          StandardOutPath = "${homeDir}/Library/Logs/embedding-server.log";
          StandardErrorPath = "${homeDir}/Library/Logs/embedding-server.error.log";
        };
      };
    };

    # ── Shell Aliases ──────────────────────────────────────────────────
    programs.zsh.shellAliases = {
      hermes = "${hermesVenv}/bin/hermes";
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
      paperclip-db-logs =
        if isDarwin
        then "tail -f ~/Library/Logs/paperclip-postgres.log"
        else "journalctl --user -u paperclip-postgres -f";
      mlx-logs =
        if isDarwin
        then "tail -f ~/Library/Logs/mlx-server.log"
        else "echo 'MLX server is Darwin-only'";
      mlx-restart =
        if isDarwin
        then ''launchctl kickstart -k gui/"$(id -u)"/com.mlx-server.agent''
        else "echo 'MLX server is Darwin-only'";
      embedding-logs =
        if isDarwin
        then "tail -f ~/Library/Logs/embedding-server.log"
        else "echo 'Embedding server is Darwin-only'";
      embedding-restart =
        if isDarwin
        then ''launchctl kickstart -k gui/"$(id -u)"/com.embedding-server.agent''
        else "echo 'Embedding server is Darwin-only'";
      knowledge-db = "psql -h localhost -p ${pgPort} -d knowledge";
    };

    programs.nushell.configFile.text = lib.mkAfter ''
      # ── qwen: chat with local Qwen model via MLX server ──
      def qwen [...prompt: string] {
        let url = "http://localhost:${mlxPort}/v1/chat/completions"
        let model = "${mlxModel}"
        if ($prompt | is-empty) {
          print "Qwen Chat (Ctrl-C to quit)"
          print "──────────────────────────"
          mut messages = []
          loop {
            let line = (input $"\n(ansi blue_bold)you>(ansi reset) ")
            if ($line | is-empty) { continue }
            $messages = ($messages | append {role: "user", content: $line})
            let body = ({model: $model, messages: $messages} | to json -r)
            let reply = (^curl -sN $url -H "Content-Type: application/json" -d $body
              | lines
              | where {|l| ($l | str starts-with "data: ") and ($l != "data: [DONE]")}
              | each {|l| $l | str substring 6.. | from json | get choices.0.delta.content? | default ""}
              | str join "")
            print $reply
            $messages = ($messages | append {role: "assistant", content: $reply})
          }
        } else {
          let prompt_text = ($prompt | str join " ")
          let body = ({model: $model, messages: [{role: "user", content: $prompt_text}]} | to json -r)
          let reply = (^curl -sN $url -H "Content-Type: application/json" -d $body
            | lines
            | where {|l| ($l | str starts-with "data: ") and ($l != "data: [DONE]")}
            | each {|l| $l | str substring 6.. | from json | get choices.0.delta.content? | default ""}
            | str join "")
          print $reply
        }
      }
    '';

    programs.zsh.initContent = lib.mkAfter ''
      # ── qwen: chat with local Qwen model via MLX server ──
      qwen() {
        local model="${mlxModel}"
        local url="http://localhost:${mlxPort}/v1/chat/completions"

        if [[ $# -eq 0 ]]; then
          # Interactive REPL mode
          echo "Qwen Chat (Ctrl-D to quit)"
          echo "──────────────────────────"
          local messages='[]'
          while printf "\n\033[1;34myou>\033[0m " && IFS= read -r line; do
            [[ -z "$line" ]] && continue
            messages=$(printf '%s' "$messages" | ${pkgs.jq}/bin/jq -c --arg m "$line" '. + [{"role":"user","content":$m}]')
            local reply=""
            reply=$(curl -sN "$url" \
              -H "Content-Type: application/json" \
              -d "$(${pkgs.jq}/bin/jq -nc --arg model "$model" --argjson msgs "$messages" \
                '{model:$model,messages:$msgs,stream:true}')" \
              | while IFS= read -r chunk; do
                  chunk="''${chunk#data: }"
                  [[ "$chunk" == "[DONE]" || -z "$chunk" ]] && continue
                  printf '%s' "$chunk" | ${pkgs.jq}/bin/jq -rj '.choices[0].delta.content // empty' 2>/dev/null
                done)
            printf '\n'
            messages=$(printf '%s' "$messages" | ${pkgs.jq}/bin/jq -c --arg m "$reply" '. + [{"role":"assistant","content":$m}]')
          done
        else
          # One-shot mode: qwen "your question here"
          curl -sN "$url" \
            -H "Content-Type: application/json" \
            -d "$(${pkgs.jq}/bin/jq -nc --arg model "$model" --arg prompt "$*" \
              '{model:$model,messages:[{role:"user",content:$prompt}],stream:true}')" \
            | while IFS= read -r chunk; do
                chunk="''${chunk#data: }"
                [[ "$chunk" == "[DONE]" || -z "$chunk" ]] && continue
                printf '%s' "$chunk" | ${pkgs.jq}/bin/jq -rj '.choices[0].delta.content // empty' 2>/dev/null
              done
          printf '\n'
        fi
      }
    '';
  };
}
