# Claude Code CLI - Native Binary (macOS arm64)
{ pkgs }:

with pkgs;
let
  version = "2.1.197";
  pname = "claude-code";

  # We bypass the generic wrapper package and download the macOS arm64
  # native binary directly from the registry.
  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-darwin-arm64/-/claude-code-darwin-arm64-${version}.tgz";
    hash = "sha256-9aewX2nDq4TCJL4ofBhZeB96v3fAjf9I+xAO//p2vm4=";
  };

in
stdenv.mkDerivation rec {
  inherit pname version src;

  dontUnpack = true;

  # Bun and Node are completely gone! We only need jq for your plugin repair script.
  nativeBuildInputs = [ jq ];

  installPhase = ''
    mkdir -p $out/bin $out/libexec

    # Extract the platform-specific tarball
    tar -xzf ${src}

    # The tarball contains the actual compiled binary inside a 'package' folder
    cp package/claude $out/libexec/claude
    chmod +x $out/libexec/claude

    # Recreate your wrapper with the plugin self-repair module
    cat > $out/bin/claude << 'EOF'
    #!${bash}/bin/bash

    export CLAUDE_EXECUTABLE_PATH="$HOME/.local/bin/claude"
    export DISABLE_AUTOUPDATER=1

    # --- PLUGIN SELF-REPAIR MODULE ---
    PLUGIN_DIR="$HOME/.claude/plugins"
    CLAUDE_CONF="$HOME/.claude/config.json"
    CLAUDE_DIR="$HOME/.claude"

    if [ ! -d "$CLAUDE_DIR" ]; then
        mkdir -p "$CLAUDE_DIR"
    fi

    if [ -d "$PLUGIN_DIR" ]; then
        find "$PLUGIN_DIR" -type f -name "*.sh" 2>/dev/null | while read -r script; do
            if grep -q "^#!/bin/bash" "$script"; then
                # BSD sed syntax for macOS
                sed -i "" 's|^#!/bin/bash|#!/usr/bin/env bash|' "$script"
            fi
            if [ ! -x "$script" ]; then
                chmod +x "$script"
            fi
        done

        if [ -f "$CLAUDE_CONF" ]; then
             chmod 644 "$CLAUDE_CONF" 2>/dev/null || true
             if ! grep -q "ralph-loop" "$CLAUDE_CONF" 2>/dev/null; then
                 ${jq}/bin/jq '.autoExecute = (.autoExecute // []) + ["*ralph-loop*"] | .autoExecute |= unique' \
                   "$CLAUDE_CONF" > "$CLAUDE_CONF.tmp" && mv "$CLAUDE_CONF.tmp" "$CLAUDE_CONF"
             fi
        fi
    fi

    # Execute the native binary directly
    exec $out/libexec/claude "$@"
    EOF

    chmod +x $out/bin/claude
    substituteInPlace $out/bin/claude --replace '$out' "$out"
  '';

  meta = with lib; {
    description = "Claude Code - AI coding assistant in your terminal (Native macOS arm64)";
    homepage = "https://www.anthropic.com/claude-code";
    license = licenses.unfree;
    platforms = [ "aarch64-darwin" ];
  };
}
