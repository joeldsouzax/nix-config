# Orca is the primary macOS project workspace; Ghostty remains the shell terminal.
{
  pkgs,
  vars,
  ...
}:

{
  home-manager.users.${vars.user} =
    { lib, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      home.file.".local/bin/work" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          if (( $# > 1 )); then
            echo "Usage: work [project-directory]" >&2
            exit 2
          fi
          project_dir=$(cd -- "''${1:-.}" && pwd -P)
          # Open the repository root when invoked from one of its subdirectories.
          project_dir=$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null || echo "$project_dir")
          /opt/homebrew/bin/orca open --json >/dev/null
          /opt/homebrew/bin/orca repo add --path "$project_dir" >/dev/null
          printf 'Project ready in Orca: %s\n' "$project_dir"
        '';
      };

      # One task = one Orca worktree of the current repo with an agent in it.
      home.file.".local/bin/task" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          agent=codex
          case "''${1:-}" in
            --claude) agent=claude; shift ;;
            --codex) shift ;;
          esac
          if (( $# < 1 )); then
            echo "Usage: task [--codex|--claude] <name> [prompt...]" >&2
            exit 2
          fi
          name=$1
          shift
          repo=$(git rev-parse --show-toplevel)
          args=(worktree create --repo "path:$repo" --name "$name" --agent "$agent" --activate)
          if (( $# > 0 )); then
            args+=(--prompt "$*")
          fi
          /opt/homebrew/bin/orca open --json >/dev/null
          /opt/homebrew/bin/orca repo add --path "$repo" >/dev/null
          exec /opt/homebrew/bin/orca "''${args[@]}"
        '';
      };

      # Preserve the rest of the user's Dock, and put the work app first.
      home.activation.orcaDock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d /Applications/Orca.app ]; then
          run ${pkgs.dockutil}/bin/dockutil --add /Applications/Orca.app --replacing Orca --position 1
        fi
      '';
    };
}
