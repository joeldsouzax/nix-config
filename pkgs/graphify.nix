# Graphify — turn a codebase/corpus into a queryable knowledge graph for AI agents.
# Tracks upstream 0.9.93 ahead of nixpkgs 0.9.91, with the existing agent
# integrations and Darwin grammar fixes retained.
# Drop this file and use pkgs.graphify once nixpkgs catches up.
{
  lib,
  python3Packages,
  fetchFromGitHub,
  python3,
  stdenv,
  tree-sitter-grammars,
}:

let
  # nixpkgs darwin bug: the unbundled python grammar bindings record their
  # external grammar dylib dependency as the bare install name "parser", so
  # dyld binds every grammar to whichever parser dylib loaded FIRST and all
  # other grammars fail with "Symbol not found". Rewrite each binding's
  # relative deps to the absolute store path of its own grammar dylib.
  fixDarwinGrammar =
    name: pyPkg:
    if !stdenv.hostPlatform.isDarwin then
      pyPkg
    else
      pyPkg.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          for so in $out/lib/python*/site-packages/*/_binding*.so; do
            otool -L "$so" | awk 'NR>1 {print $1}' | while read -r dep; do
              case "$dep" in
                /*) continue ;;
              esac
              target=$(find ${tree-sitter-grammars.${name}} -type f -path "*''${dep}" | head -1)
              if [ -n "$target" ]; then
                install_name_tool -change "$dep" "$target" "$so"
              fi
            done
          done
        '';
      });

  grammarNames = [
    "tree-sitter-bash"
    "tree-sitter-c"
    "tree-sitter-c-sharp"
    "tree-sitter-cpp"
    "tree-sitter-elixir"
    "tree-sitter-fortran"
    "tree-sitter-go"
    "tree-sitter-groovy"
    "tree-sitter-java"
    "tree-sitter-javascript"
    "tree-sitter-json"
    "tree-sitter-julia"
    "tree-sitter-kotlin"
    "tree-sitter-lua"
    "tree-sitter-objc"
    "tree-sitter-php"
    "tree-sitter-powershell"
    "tree-sitter-python"
    "tree-sitter-ruby"
    "tree-sitter-rust"
    "tree-sitter-scala"
    "tree-sitter-swift"
    "tree-sitter-typescript"
    "tree-sitter-verilog"
    "tree-sitter-zig"
  ];

  pyGrammars = map (n: fixDarwinGrammar n python3.pkgs.tree-sitter-grammars.${n}) grammarNames;
in

python3Packages.buildPythonApplication rec {
  __structuredAttrs = true;
  pname = "graphify";
  version = "0.9.93";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Graphify-Labs";
    repo = "graphify";
    tag = "v${version}";
    hash = "sha256-SaQYg8oKqoUnkq4d0gG2YVSmnXjCtmG+EiWGbUatc4M=";
  };

  build-system = [
    python3.pkgs.setuptools
  ];

  # Upstream pins tight `<x.y` caps on tree-sitter and every grammar;
  # nixpkgs grammar versions move independently of those caps.
  pythonRelaxDeps = true;

  # `graphify update` restarts through `python -m graphify`; its child process
  # needs the same module paths as the Nix-wrapped entry point.
  makeWrapperArgs = [
    "--prefix"
    "PYTHONPATH"
    ":"
    "${placeholder "out"}/${python3.sitePackages}:${python3.pkgs.makePythonPath dependencies}"
  ];

  dependencies =
    (with python3.pkgs; [
      networkx
      numpy
      rapidfuzz
      tree-sitter
      # extras baked in: kimi/openai/gemini backends, anthropic backend,
      # pdf ingestion, file watching
      openai
      tiktoken
      anthropic
      pypdf
      markdownify
      watchdog
    ])
    ++ pyGrammars;

  meta = {
    description = "AI coding assistant skill. Turn any folder of code, docs, papers, images, or videos into a queryable knowledge graph.";
    homepage = "https://github.com/Graphify-Labs/graphify";
    changelog = "https://github.com/Graphify-Labs/graphify/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "graphify";
  };
}
