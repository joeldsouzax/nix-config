# Shared AI-agent workflow toolkit
# Shared between NixOS and Darwin via home-manager
#
# Tools that make agent-driven development better regardless of project:
# structural search, syntax-aware diffs, JSON, git workflow, verification.
# Project-specific toolchains (cargo-nextest, LSPs, ...) belong in each
# project's flake devShell + direnv, not here.

{ pkgs, vars, ... }:

let
  # Track the latest release with the Darwin grammar fixes and agent extras.
  graphify = pkgs.callPackage ../../pkgs/graphify.nix { };

  # PreToolUse hook for Claude Code (~/.claude/settings.json): denies POSIX
  # classics that have a toolkit replacement, with the replacement named in the
  # deny reason so the agent retries correctly. Permission allow-rules skip the
  # prompt but do NOT bypass this hook.
  toolkit-guard = pkgs.writeShellApplication {
    name = "agent-toolkit-guard";
    runtimeInputs = [
      pkgs.jq
      pkgs.gnugrep
    ];
    text = ''
      cmd=$(jq -r '.tool_input.command // empty')
      [ -z "$cmd" ] && exit 0

      deny() {
        jq -cn --arg r "$1" \
          '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
        exit 0
      }

      sep='(^|[[:space:]|;&(])'
      if grep -Eq "$sep"'grep[[:space:]]+(-[[:alnum:]]+[[:space:]]+)*-[[:alnum:]]*[rR]' <<<"$cmd"; then
        deny "Recursive grep is banned by the agent toolkit — use rg: rg -n 'pattern' [path] (faster, .gitignore-aware)."
      fi
      if grep -Eq "$sep"'find[[:space:]]+[^|;&]*-i?name' <<<"$cmd"; then
        deny "find -name is banned by the agent toolkit — use fd: fd 'pattern' [path] (.gitignore-aware; fd -e rs for extensions)."
      fi
      if grep -Eq "$sep"'diff[[:space:]]' <<<"$cmd" && ! grep -Eq '(git|jj)[[:space:]]+diff' <<<"$cmd"; then
        deny "Plain diff is banned by the agent toolkit — use difft file1 file2, or GIT_EXTERNAL_DIFF=difft git diff for syntax-aware diffs."
      fi
      exit 0
    '';
  };
in
{
  home-manager.users.${vars.user}.home.packages = with pkgs; [
    # --- Core agent search/edit tools ---
    ripgrep # fast, .gitignore-aware text search
    fd # fast file finding
    ast-grep # structural (AST-aware) code search & rewrite — `sg`
    sd # simpler, faster sed replacement

    # --- Git workflow ---
    gh # GitHub CLI for PR/issue operations
    git-lfs # large-file support for git
    lazygit # fast terminal git UI
    jujutsu # modern git-compatible VCS
    difftastic # syntax-aware diffs — `difft`, reviews semantic changes

    # --- Data & HTTP ---
    jq # JSON processing and agent hooks
    xh # friendly HTTP client (HTTPie-style curl)

    # --- Token efficiency ---
    rtk # CLI proxy compressing command output for LLM agents (rtk git status, rtk ls)

    # --- Verification & measurement ---
    watchexec # run commands on file change (test loops)
    hyperfine # statistical CLI benchmarking
    tokei # codebase line/language stats

    # --- Knowledge graphs ---
    graphify # codebase → queryable knowledge graph (`graphify .`, `graphify query`)
    toolkit-guard # agent-toolkit-guard — hook denying grep -r/find -name/diff

    # --- System introspection ---
    dust # tree-view disk usage (nix store investigations)
    pueue # queue & manage long-running shell commands
  ];
}
