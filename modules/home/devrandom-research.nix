{ config, lib, pkgs, vars, ... }:

let
  cfg = config.devrandom.research;
  skill = ./devrandom-research/skill;
  prompt = ./devrandom-research/devrandom-research.md;
  template = ./devrandom-research/template;
  init = pkgs.writeShellApplication {
    name = "devrandom-research-init";
    runtimeInputs = [ pkgs.coreutils pkgs.git ];
    text = ''
      root="$(git rev-parse --show-toplevel)"
      destination="$root/.research"
      mkdir -p "$destination"

      for source in ${template}/*.md; do
        target="$destination/$(basename "$source")"
        if [ ! -e "$target" ]; then
          cp "$source" "$target"
          chmod u+w "$target"
        fi
      done

      touch "$destination/EXPERIMENTS.jsonl"
      printf 'Research ledger ready: %s\n' "$destination"
    '';
  };
in
{
  options.devrandom.research.enable = lib.mkEnableOption "the reusable devrandom research-convergence workflow" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${vars.user} = {
      home.packages = [ init ];

      home.file = {
        ".omp/agent/skills/devrandom-research" = {
          source = skill;
          recursive = true;
        };
        ".omp/agent/prompts/devrandom-research.md".source = prompt;
        ".omp/profiles/kimi/agent/skills/devrandom-research" = {
          source = skill;
          recursive = true;
        };
        ".omp/profiles/kimi/agent/prompts/devrandom-research.md".source = prompt;
        ".codex/skills/devrandom-research" = {
          source = skill;
          recursive = true;
        };
        ".config/devrandom/research-template" = {
          source = template;
          recursive = true;
        };
      };
    };
  };
}
