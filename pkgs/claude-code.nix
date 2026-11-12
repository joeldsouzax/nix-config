# Claude Code CLI - native packages for the Mac and Linux desktop profiles.
{ pkgs }:

with pkgs;
let
  version = "2.1.322";
  pname = "claude-code";

  # We bypass the generic wrapper package and download the macOS arm64
  # native binary directly from the registry.
  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-darwin-arm64/-/claude-code-darwin-arm64-${version}.tgz";
    hash = "sha512-OAx5Y7V7tGCi0tWuDV3lwcDWmIua512NgpClLbqvwC9m+mbLiaytgVLXf4unTXBjMf+QbQiIUO1Kus90PklDhA==";
  };

in
if stdenv.hostPlatform.isLinux then
  # Keep Nixpkgs' supported loader, search and sandbox integration.
  claude-code.override {
    manifest = {
      inherit version;
      platforms.linux-x64 = {
        binary = "claude.zst";
        checksum = "9bb7558bd992ca457e6458bf1686572f7a3156b8331dd8443391dbfe590c1eed";
      };
    };
  }
else
  stdenvNoCC.mkDerivation rec {
    inherit pname version src;

    dontUnpack = true;
    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin $out/libexec
      tar -xzf ${src}
      install -m755 package/claude $out/libexec/claude
      makeWrapper $out/libexec/claude $out/bin/claude --set DISABLE_AUTOUPDATER 1
    '';

    meta = with lib; {
      description = "Claude Code - AI coding assistant in your terminal (Native macOS arm64)";
      homepage = "https://www.anthropic.com/claude-code";
      license = licenses.unfree;
      platforms = [ "aarch64-darwin" ];
    };
  }
