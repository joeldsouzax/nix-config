# OpenAI Codex CLI - official native binaries and bundled helpers.
{ pkgs }:

with pkgs;
let
  version = "0.167.0";
  pname = "codex";
  platform =
    {
      aarch64-darwin = {
        npm = "darwin-arm64";
        triple = "aarch64-apple-darwin";
        hash = "sha512-7YtMDZX/jbWH9+fCVQg7BVsov8WvBzu4iuedXJEDlUdZxaTrYX2bEQwHIn3p0gxgSMfm30HGK9+bZm1aGSZaHw==";
      };
      x86_64-linux = {
        npm = "linux-x64";
        triple = "x86_64-unknown-linux-musl";
        hash = "sha512-FNc7danfUng9Sp6w+Fh7kofNHHZpA6VMyNKWsWrS3OwHly69gywTWeiuwrUPXpJSho8Df4xqRsHfHRPzj7zYQg==";
      };
    }
    .${stdenv.hostPlatform.system};

  # Platform tarballs are published as aliases of @openai/codex at
  # version "<ver>-<platform>"; each ships the compiled Rust binary plus
  # its vendored helpers (rg, zsh, code-mode host) under vendor/<triple>/.
  src = fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}-${platform.npm}.tgz";
    inherit (platform) hash;
  };

in
stdenvNoCC.mkDerivation rec {
  inherit pname version src;

  dontUnpack = true;
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    mkdir -p $out/bin $out/libexec

    tar -xzf ${src}

    # Keep the vendor layout intact (bin/, codex-path/, codex-resources/)
    # — codex locates its helpers relative to the executable.
    cp -R package/vendor/${platform.triple}/. $out/libexec/
    chmod +x $out/libexec/bin/codex

    ln -s $out/libexec/bin/codex $out/bin/codex
  '';

  meta = with lib; {
    description = "OpenAI Codex - AI coding agent in your terminal";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    mainProgram = "codex";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
