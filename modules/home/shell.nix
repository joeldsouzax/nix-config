# Shell Configuration (ZSH + Nushell)
# Shared between NixOS and Darwin via home-manager
#
# ZSH: Spaceship prompt + Oh-My-Zsh (matches NixOS system-level config)
# Nushell: Primary shell inside Ghostty

{ config, lib, pkgs, vars, ... }:

let
  # Safely check if SOPS claude_key secret exists (NixOS only)
  claudeKeyPath = lib.attrByPath [ "sops" "secrets" "claude_key" "path" ] "" config;
in
{
  home-manager.users.${vars.user} = {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      history.size = 100000;

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };

      # Modern HM uses unified initContent with ordering via mkBefore/mkAfter
      initContent = lib.mkMerge [
        # Early init (runs first)
        (lib.mkBefore (''
          # Nix daemon (needed on Darwin, harmless on NixOS)
          if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          fi

          export LANG=en_US.UTF-8
          bindkey '^ ' autosuggest-accept
          export HISTIGNORE="pwd:ls:cd"
          # User-level shims (e.g. oh-my-pi's `hypa` CLI) install here; omp's
          # bash tool inherits this PATH, so pi-hypa's command rewriting works.
          export PATH="$HOME/.local/bin:$PATH"

          # Moonshot/Kimi API key for omp's built-in moonshot provider
          # (plain file, chmod 600 — SOPS is not decryptable on Darwin yet)
          if [[ -f "$HOME/.secrets/moonshot-api-key" ]]; then
            export MOONSHOT_API_KEY="$(<"$HOME/.secrets/moonshot-api-key")"
          fi

          # DeepSeek API key for omp's built-in deepseek provider (autoresearch profile)
          if [[ -f "$HOME/.secrets/deepseek-api-key" ]]; then
            export DEEPSEEK_API_KEY="$(<"$HOME/.secrets/deepseek-api-key")"
          fi
        '' + lib.optionalString pkgs.stdenv.isDarwin ''
          # Homebrew paths (Darwin only)
          export PATH="/opt/homebrew/bin:$PATH"
          export PATH="/opt/homebrew/sbin:$PATH"
          # SOPS age key location (Darwin — on NixOS, sops-nix manages this)
          export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
        ''))

        # Main init (default order)
        ''
          # Spaceship prompt (same on NixOS and Darwin)
          source ${pkgs.spaceship-prompt}/share/zsh/site-functions/prompt_spaceship_setup
          autoload -U promptinit; promptinit
        ''
      ];

      shellAliases = {
        ls = "ls --color=auto";
        search = ''rg -p --glob "!node_modules/*" --glob "!vendor/*" "$@"'';
        ec = "emacsclient -nc"; # instant frame from the Emacs daemon
        # Kimi K3 harness = omp default profile (see ~/.omp/agent/HARNESS.md)
        kimi-check = ''omp -p "CHECK: review the working-tree diff (git diff HEAD, plus untracked files) against the engineering rules. Findings table only."'';
        omp-design = "omp --profile design"; # preserved design-partner persona
        # Local Qwen3-Coder-Rust (llama.cpp) — autoresearch only; start `rust-llm` first
        omp-research = "omp --profile autoresearch";
      } // (if pkgs.stdenv.isDarwin then {
        nixswitch = "sudo darwin-rebuild switch --flake ~/.setup#joel";
        nixup = "pushd ~/.setup; nix flake update; nixswitch; popd";
      } else {
        rebuild = "sudo nixos-rebuild switch --flake .#main";
      });
    };

    programs.nushell = {
      enable = true;
      configFile.text = ''
        $env.config = {
          show_banner: false,
          edit_mode: emacs
          ls: { use_ls_colors: true, clickable_links: true }
          table: { mode: rounded }
        }
        # Aliases
        alias ll = ls -l
        alias la = ls -a
        alias cat = bat
        alias find = fd
        alias grep = rg
        # `doom env`/`doom sync` aliases removed — Doom is built by Nix now
        # (nix-doom-emacs-unstraightened); syncing is a rebuild.
        alias ec = emacsclient -nc
        # Kimi K3 harness = omp default profile (see ~/.omp/agent/HARNESS.md)
        def kimi-check [] { omp -p "CHECK: review the working-tree diff (git diff HEAD, plus untracked files) against the engineering rules. Findings table only." }
        def --wrapped omp-design [...args] { omp --profile design ...$args } # design-partner persona
        # Local Qwen3-Coder-Rust (llama.cpp) — autoresearch only; start `rust-llm` first
        def --wrapped omp-research [...args] { omp --profile autoresearch ...$args }
        # Live-watch the newest omp/Kimi session for a devrandom repo.
        # Start AFTER dispatching omp, or it tails the previous session.
        # jq program must stay a raw string: nu double quotes eat jq's \(...) interpolation.
        def kimi-watch [repo: string = "nexus"] {
          let dir = $"($env.HOME)/.omp/agent/sessions/-Code-devrandom-($repo)"
          let f = (ls $dir | where name ends-with ".jsonl" | sort-by modified | last | get name)
          print $"watching: ($f)"
          ^tail -f $f | ^jq -r --unbuffered r#'
            select(.type=="message") | .message | select(.role) | (.content // [])[]? |
            if .type=="toolCall" then "⚙ \(.name): \((.arguments // {}) | tostring | .[0:100])"
            elif .type=="text" then "💬 \(.text | .[0:200])"
            else empty end'#
        }
        let moonshot_key = ($nu.home-dir | path join ".secrets/moonshot-api-key")
        if ($moonshot_key | path exists) {
          $env.MOONSHOT_API_KEY = (open --raw $moonshot_key | str trim)
        }
        let deepseek_key = ($nu.home-dir | path join ".secrets/deepseek-api-key")
        if ($deepseek_key | path exists) {
          $env.DEEPSEEK_API_KEY = (open --raw $deepseek_key | str trim)
        }
      '' + (if pkgs.stdenv.isDarwin then ''
        def nixswitch [] { sudo darwin-rebuild switch --flake ~/.setup#joel }
      '' else ''
        def nixswitch [] { sudo nixos-rebuild switch --flake /home/${vars.user}/.setup#main }
      '') + lib.optionalString (claudeKeyPath != "") ''

        if ("${claudeKeyPath}" | path exists) {
            $env.ANTHROPIC_API_KEY = (open --raw "${claudeKeyPath}" | str trim)
        }
      '';
      envFile.text = ''
        $env.PATH = ($env.PATH | split row (char esep)
          | prepend ($nu.home-dir | path join ".local/bin")  # user shims (omp's hypa CLI)
          | prepend "/etc/profiles/per-user/${vars.user}/bin"
          | prepend "/run/current-system/sw/bin"
          | prepend "/nix/var/nix/profiles/default/bin"
        ${
          if pkgs.stdenv.isDarwin then
            ''| prepend "/opt/homebrew/bin"''
          else
            # NixOS setuid wrappers (sudo, mount, ...) MUST win over the
            # non-setuid copies in /run/current-system/sw/bin — prepend last so
            # it lands at the front of PATH. Without this, `sudo` errors with
            # "must be owned by uid 0 and have the setuid bit set".
            ''| prepend "/run/wrappers/bin"''
        }
          | uniq)

        # 1Password SSH agent. securities.nix only exports SSH_AUTH_SOCK via
        # environment.extraInit (/etc/profile) — which POSIX login shells read
        # but Nushell does NOT. Without mirroring it here, ssh / `git fetch`
        # over the 1Password agent works in zsh but fails in Nushell.
        let op_sock = ($env.HOME | path join ".1password/agent.sock")
        if ($op_sock | path exists) { $env.SSH_AUTH_SOCK = $op_sock }
      '';
      environmentVariables = {
        EDITOR = "vim";
      };
    };
  };
}
