# Claude Code / AI-agent workflow toolkit
# Shared between NixOS and Darwin via home-manager
#
# Tools that make agent-driven development better regardless of project:
# structural search, syntax-aware diffs, JSON, git workflow, verification.
# Project-specific toolchains (cargo-nextest, LSPs, ...) belong in each
# project's flake devShell + direnv, not here.

{ pkgs, vars, ... }:

{
  home-manager.users.${vars.user}.home.packages = with pkgs; [
    # --- Core agent search/edit tools ---
    ripgrep # fast text search (Claude Code's bread and butter)
    fd # fast file finding
    ast-grep # structural (AST-aware) code search & rewrite — `sg`
    sd # simpler, faster sed replacement

    # --- Git workflow ---
    gh # GitHub CLI — Claude Code drives this for PR/issue operations
    git-lfs # large-file support for git
    lazygit # fast terminal git UI
    jujutsu # modern git-compatible VCS
    difftastic # syntax-aware diffs — `difft`, reviews semantic changes

    # --- Data & HTTP ---
    jq # JSON processing (also used by the claude-code wrapper)
    xh # friendly HTTP client (HTTPie-style curl)

    # --- Token efficiency ---
    rtk # CLI proxy compressing command output for LLM agents (rtk git status, rtk ls)

    # --- Verification & measurement ---
    watchexec # run commands on file change (test loops)
    hyperfine # statistical CLI benchmarking
    tokei # codebase line/language stats

    # --- System introspection ---
    dust # tree-view disk usage (nix store investigations)
    pueue # queue & manage long-running shell commands
  ];
}
