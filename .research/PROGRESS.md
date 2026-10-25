# Progress

The owner requested integration of all pending changes on main on 2026-10-25.
The desktop runner is merged at 890e148. The dependency refresh and Orca setup
are included in the same main checkout. No system activation was performed.

## Retained changes

- Refresh flake inputs and pair stable nixpkgs/Home Manager at 26.05.
- Codex 0.163.0, Claude Code 2.1.306, Graphify 0.9.93; current inactive WiFi source pin and CI actions.
- Remove Finder metadata, including tracked modules/editors/.DS_Store, and ignore both spellings.
- Retain supported English Aspell dictionary after nixpkgs removed the unavailable computer/science add-ons.
- Export Graphify's package and transitive module paths through Nix's supported wrapper so its new restart works. Original update failed with No module named graphify; the fixed command succeeds.
- Handle filenames with spaces in CI's existing advisory formatter command. Remove the duplicated stable version from README.

## Actual checks

- All 73 nonempty Nix files parse; touched formatted files pass nixfmt --check; git diff --check passes.
- actionlint .github/workflows/check.yml passes with the updated actions.
- Native Nix Codex/Claude builds pass; direct binaries report their expected versions. Codex's code-mode and voice helpers remain executable.
- Graphify Nix build, version, graph query and graphify update . pass. Graph refresh reports 194 nodes and 171 edges; it still warns about an existing Dashboard.tsx parsing limitation. Existing read-only installed skills remain at their prior version; tests disable automatic refresh.
- Full Darwin toplevel evaluation passes: /nix/store/8pc1xcbrjfxxgn14lwy3grhj8q188ry8-darwin-system-26.11.f0ec2b3.drv.
- NixOS assertions evaluate to an empty failure list. Full NixOS toplevel evaluation stops at doom-intermediates because x86_64-linux execution is unavailable on this aarch64-darwin host with remote builders disabled. Direct desktop SSH cannot resolve nixos.local.
- nix flake check --all-systems --no-build evaluates the integration test and active kernel-module derivations but fails at the Linux Doom intermediate with an invalid store-path error. Disabling lazy-trees and eval-cache did not resolve that error; do not claim a passing flake gate. Linux VM/kernel execution remains for CI or a reachable builder.
- No Finder metadata files remain in the checkout outside .git; git check-ignore covers root and nested paths.

## Review and delivery

Two fresh reviews checked dependency ownership, exact versions/hashes, preserved agent helpers and extras, stable-input pairing, CI commands, metadata exclusions and unrelated changes. No further scoped code changes identified. Full evaluation used path:/Users/joel/nix-config to include the user's pre-existing untracked Orca module; ordinary Git-flake evaluation excludes that file until it is added to Git.

Next: run the remaining Linux checks in CI/on the desktop and apply the configuration when requested. Homebrew already updates and upgrades on system activation. No sudo rebuild or imperative package installation was performed. Temporary check logs are /tmp/nix-config-*.log; key results are recorded here.

## Combined integration checks

- Restored all pre-existing edits after the runner merge. README and flake
  conflicts retain both changes. Existing lock entries and unrelated tracked
  edits match their saved versions.
- Runner configuration check passes from the combined main checkout.
- Evaluated Darwin settings include the Orca Homebrew cask, work launcher and
  Dock activation. The installed Orca CLI confirms both commands used by the
  launcher, and the generated launcher passes Bash syntax validation.
- Full Darwin evaluation passes with all staged changes:
  `/nix/store/z8ciyac22rp8sk6fajm4dq3jj7v9cql7-darwin-system-26.11.f0ec2b3.drv`.
  This evaluated the configuration and built required Doom intermediates; it
  did not activate the system. Linux runtime checks remain as listed above.
- Staged diff has no whitespace errors. Research records are included because
  the owner requested committing everything, including the pending Orca work.

## Desktop Codex and SSH access

The owner requested Codex on the runner and then requested committing this Mac's
public SSH key and pushing main. The runner now includes the maintained Codex
0.163.0 package from its existing input. Both desktop profiles read Joel's key
from `hosts/keys/joel-mac.pub`. No private key or sign-in credential is included.

Verification:

- The existing runner configuration check passes with both additions.
- Package selection resolves to the cached x86_64-linux Codex output recorded
  in SOURCES.md. No lock update or custom Linux package is needed.
- The committed public key matches `~/.ssh/id_ed25519.pub` byte for byte and
  `ssh-keygen -lf` reports
  `SHA256:gMrpHXjPGSYgUWHw8YnkB7+6AXZnVcJEmScIJKU20jI`.
- Evaluation of both NixOS profiles renders that key for Joel, preserves
  home-directory keys and adds no key for root or the runner service account.
- Runner formatting, desktop configuration parsing and diff whitespace checks
  pass. Graphify updates successfully; its existing JSON-file warnings remain.

The desktop is now reachable at `nixos.local`. Its SSH host key matches the
saved SOPS host recipient, but authentication rejects the Mac's key. No system
activation or live Codex version check has run. The next step is to pull the
published main checkout on the desktop and add the public key using the commands
in `docs/runner.md`, then complete the runner's build and activation prerequisites.
