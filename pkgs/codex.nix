# OpenAI Codex CLI - Native Binary (macOS arm64)
{ pkgs }:

with pkgs;
let
  version = "0.160.0";
  pname = "codex";

  # Platform tarballs are published as aliases of @openai/codex at
  # version "<ver>-<platform>"; each ships the compiled Rust binary plus
  # its vendored helpers (rg, zsh, code-mode host) under vendor/<triple>/.
  src = fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}-darwin-arm64.tgz";
    hash = "sha256-/HibzWVdkD+S4aI8jcUxW6OPQ7NYbq+3vTsZWXC1dGY=";
  };

in
stdenv.mkDerivation rec {
  inherit pname version src;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/libexec

    tar -xzf ${src}

    # Keep the vendor layout intact (bin/, codex-path/, codex-resources/)
    # — codex locates its helpers relative to the executable.
    cp -R package/vendor/aarch64-apple-darwin/. $out/libexec/
    chmod +x $out/libexec/bin/codex

    ln -s $out/libexec/bin/codex $out/bin/codex
  '';

  meta = with lib; {
    description = "OpenAI Codex - AI coding agent in your terminal (Native macOS arm64)";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    mainProgram = "codex";
    platforms = [ "aarch64-darwin" ];
  };
}
