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

## H06: RTL8852AU and Linux 6.12 backport

Baseline: the owner's desktop build fails in `cfg80211_rtw_set_monitor_channel`
for Linux 6.12.113. The locked driver already contains nixpkgs' upstream patch,
but its new parameter is guarded by kernel >= 6.13. Linux stable commit
4dae80dd259b5c24f6c657f434afd5de1f791d12 backports the new signature. Published
headers confirm two parameters in 6.12.100 and three in 6.12.101.

Hypothesis: extend the existing compatibility guard to >= 6.12.101, preserving
the callback body, other upstream patches and compiler checks. Append that one
patch through the supported kernel package extension in shared hardware config.
Expose the configured driver to CI instead of independently reconstructing the
kernel package set; test both desktop and runner versions. Reject if the patch
does not apply after nixpkgs' patch, changes behavior beyond the signature, or
either configured module still fails compilation. Keep the old two-argument
form for 6.12.100. Do not switch drivers or suppress the type error.

Budget: one compatibility patch, shared hardware package override, flake/CI
package ownership, one Codex package entry and this evidence. Verify exact
configured derivations, patch application and the kernel boundary. Build on
Linux when SSH access is available; a Mac cannot validate this module's runtime.

Retained: the patch applies after nixpkgs' existing
patch with no fuzz or offset. A native compiler checks the extracted callback
signature against the actual published kernel declarations at 6.12.100,
6.12.101, 6.12.113, 6.12.114 and 6.13. The original source fails for all three
affected 6.12 versions; the patched signature passes all five. CI outputs match
the installed module derivations in each profile, and the runner check passes.
After the owner installed the committed public key, both complete modules built
on the desktop at a93a1e5. `modinfo` reports the correct 6.12.113 and 6.12.114
kernel versions. Both builds preserve the upstream compiler warnings; no warning
or type check was disabled. This verifies compilation, not hardware behavior
after booting either new kernel. The running host remains on 6.12.94.

## H07: install Wi-Fi modules with the kernel's supported target

Baseline: at a93a1e5 both Wi-Fi packages and NVIDIA compile, but the full runner
build fails in module aggregation because `8852au.ko.cer` is absent. The driver
copies its `.ko` directly and omits Nixpkgs' standard signing and compression.
The upstream maintainer describes this packaging defect in nixpkgs#575192.

Hypothesis: use `kernelModuleMakeFlags` and Kbuild's `modules_install` target in
the existing package override. Preserve the module location and sleep helper.
Remove store references before signing, and let Kbuild strip before signing.
Reject missing certificates, broken signatures, lost helpers, wrong kernel
metadata or a failing module-tree/system build. Never bypass certificate checks.
Budget: shared package override, existing kernel CI step and research evidence.
Build both actual module trees as the regression check: the baseline fails that
check despite standalone package builds passing. Then rebuild the full runner.

Retained: both complete module trees and the full runner system now build on
Linux. Both installed Wi-Fi modules contain PKCS#7 signatures, nonempty adjacent
certificates, the expected kernel versions and the executable sleep helper.
NVIDIA modules also compile for both kernels. Runtime loading remains untested
until activation and boot. CI now builds both configured module trees directly.
