# Hypotheses

## H01: dependency refresh

Implemented; local checks and full Mac evaluation pass. Full Linux evaluation and flake gate remain unverified, with exact failures recorded in PROGRESS.md. Updates preserve both host definitions and agent integrations. Change budget stayed within dependency pins, required compatibility fixes and their documentation. Linux runtime benchmarks and kernel/VM execution cannot be claimed from Mac assertions or derivation evaluation.

## H02: Finder metadata cleanup

Complete. Matching files were removed, including the tracked editors file. Both spellings are ignored at any depth; a final checkout search is empty and nested git check-ignore succeeds.

## H03: Codex on the desktop runner

Baseline: main at 392abeb has no Codex package in the runner profile. Its locked
nixpkgs input provides Codex 0.163.0 for x86_64-linux, including the code-mode and
voice helpers. The package is available from cache.nixos.org.

Hypothesis: adding that package to the existing system package list supplies
Codex without another derivation or dependency pin. Limit changes to the runner
package list, its usage document and this evidence. Reject the change if runner
evaluation fails, resolves a different package, or requires custom packaging.
Check formatting, the existing runner configuration check and evaluated package
selection. Run the CLI version check on the desktop when SSH access is available;
configuration evaluation alone does not prove installation or runtime behavior.

Retained: the runner check and package selection pass. Codex resolves to the
cached Linux output recorded in SOURCES.md. Live installation remains pending
SSH access and profile activation.

## H04: declarative desktop access from the Mac

Baseline: the desktop's public host key matches its saved SOPS recipient, but
SSH rejects the Mac's key. Neither NixOS profile declares an authorized user key.
Store the existing public key once in `hosts/keys/joel-mac.pub` and reference it
from Joel's existing user declaration in both profiles. Preserve other keys and
SSH settings. Reject the change if the evaluated authorized-key file differs
from this Mac's public key, either profile loses its existing access settings,
or the key is assigned to root or the runner account. Check both evaluated
profiles and the existing runner check. Live access requires applying the
configuration on the desktop first.

Retained: both profiles render the exact public key for Joel, keep home-directory
authorized keys enabled, and leave root and the runner account without added
keys. The runner check passes. The public key file matches the Mac byte for byte.

## H05: current Nix package compatibility

Baseline: main at 67981b6 fails evaluation of desktop system packages because
`grip` was removed with GTK2 support on 2026-07-30. Earlier toplevel evaluation
stopped first at Doom's Linux build, leaving this package list unchecked. SSH
still rejects the Mac key, so desktop execution is unavailable initially.

Hypothesis: remove obsolete direct package references and use supported names
or options for any further reproducible failures. Audit all explicit system and
Home Manager package lists, assertions and available flake outputs. Limit changes
to confirmed compatibility defects and their existing verification owners.
Reject any change that suppresses a failure, removes an unrelated feature, adds
custom machinery or claims an unrun Linux build. Preserve the Linux-only Doom
build as a visible prerequisite rather than disabling it to make evaluation pass.

Retained: removing `grip` fixes the reproduced package-selection failure. All
310 system package derivations and 68 Home Manager derivations evaluate; the
remaining Home Manager package is Doom Emacs, which requires Linux execution.
All 69 Home Manager package names evaluate. Platform aliases now use their
supported fields; the Mac toplevel derivation is unchanged. Existing CI now
checks both package selections and the runner before full desktop evaluation.
The full Linux evaluation and all-system flake check still stop at the explicit
Linux-only Doom prerequisite, without suppressing it.
