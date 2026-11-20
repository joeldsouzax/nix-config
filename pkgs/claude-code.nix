# Claude Code CLI - native packages for the Mac and Linux desktop profiles.
{ pkgs }:

with pkgs;
let
  version = "2.1.327";
  pname = "claude-code";

  # We bypass the generic wrapper package and download the macOS arm64
  # native binary directly from the registry.
  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-darwin-arm64/-/claude-code-darwin-arm64-${version}.tgz";
    hash = "sha512-LAK6PYjIZLxLMqhjj/R4bexyKqItk8RXtyUpIHPpgs3opSBzNb7AszbbN3hfdyoyf0VacA2hThVsnDkkpz9R7g==";
  };

in
if stdenv.hostPlatform.isLinux then
  # Keep Nixpkgs' supported loader, search and sandbox integration.
  claude-code.override {
    manifest = {
      inherit version;
      platforms.linux-x64 = {
        binary = "claude.zst";
        checksum = "a7ba3640f5c656d697b743c20bcfa4470e8b4e88aa352be82dafe3041d5f8961";
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
