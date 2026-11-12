# Bump the pinned Claude Code and Codex native packages to upstream latest.
update-agents:
    #!/usr/bin/env bash
    set -euo pipefail
    npm_meta() { curl -fsSL "https://registry.npmjs.org/$1" | jq -er "$2"; }

    claude=$(npm_meta @anthropic-ai/claude-code-darwin-arm64 '."dist-tags".latest')
    claude_darwin=$(npm_meta "@anthropic-ai/claude-code-darwin-arm64/$claude" .dist.integrity)
    claude_linux=$(curl -fsSL "https://downloads.claude.ai/claude-code-releases/$claude/manifest.zst.json" \
      | jq -er '.platforms["linux-x64"].checksum')
    sd 'version = "[^"]+";' "version = \"$claude\";" pkgs/claude-code.nix
    sd 'hash = "sha512-[^"]+";' "hash = \"$claude_darwin\";" pkgs/claude-code.nix
    sd 'checksum = "[0-9a-f]+";' "checksum = \"$claude_linux\";" pkgs/claude-code.nix

    codex=$(npm_meta @openai/codex '."dist-tags".latest')
    codex_darwin=$(npm_meta "@openai/codex/$codex-darwin-arm64" .dist.integrity)
    codex_linux=$(npm_meta "@openai/codex/$codex-linux-x64" .dist.integrity)
    sd 'version = "[^"]+";' "version = \"$codex\";" pkgs/codex.nix
    sd '(npm = "darwin-arm64";\s+triple = "[^"]+";\s+hash = )"[^"]+"' "\${1}\"$codex_darwin\"" pkgs/codex.nix
    sd '(npm = "linux-x64";\s+triple = "[^"]+";\s+hash = )"[^"]+"' "\${1}\"$codex_linux\"" pkgs/codex.nix

    echo "claude-code $claude, codex $codex"

# Update every flake input and the pinned agent CLIs, then build the Mac system.
update: update-agents
    nix flake update
    nix build .#darwinConfigurations.joel.config.system.build.toplevel --no-link
