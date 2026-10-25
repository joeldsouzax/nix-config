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

## H08: preserve settings through current option names

Full desktop evaluation exposes obsolete Avahi publishing options and implicit
cursor enablement. Replace only those names, using the locked modules' explicit
equivalents. Reject changed Avahi settings or cursor behavior. Compare evaluated
Avahi settings before/after and require a warning-free desktop evaluation.

Retained: evaluated Avahi settings are byte-identical, cursor enablement remains
true, and the full Linux desktop toplevel evaluates without the deprecated-option
warnings. No service behavior changed.

## H09: bounded builds and persistent private access

Baseline: i5-9400F, six cores, 15 GiB reported RAM, system and Nix store on SATA
SSDs, source projects on HDD. The desktop profile allows auto parallel builds
with every core per build; the runner already selects one build/four cores.
Both lack Tailscale. The current Wi-Fi connection autoconnects for all users.
The running host uses the performance governor, 8 GiB zram, and has no current
memory pressure. `sudo -n true` needs a password. No Tailscale Mac app is present.

Hypothesis: share the existing conservative runner build limits, Cargo job
count, zram and performance governor between profiles. Keep build scratch space
on SSD; retain existing desktop-specific memory/network settings. Disable sleep
and Wi-Fi power saving for this always-on machine. Enable the supported Tailscale
service in both profiles, with the same identity, existing OpenSSH keys, and
unchanged DNS on the host. Add the official Mac client through existing Homebrew
ownership and a separate remote SSH alias; retain the local alias.

Reject configuration drift, relaxed SSH authentication, secret material in Nix,
broken builds, loss of existing network access or claims of measured speedup
without measurements. Verify both profiles, the Mac configuration, actual full
Linux builds and runtime access after owner activation/sign-in. The original
machine lacks /dev/kvm despite the user's kvm group; no VM qualification is
claimed. Do not change firmware remotely.

Review: the existing bound check accepted `cores = 0`, which Nix interprets as
all cores. Require a positive value as well as the upper bound. The rendered
Mac SSH configuration selects the private name, Mac key and no agent forwarding
for `desktop-remote`. Its system known-host file contains the independently
verified desktop Ed25519 key for both local and private names.

The final runner check passes on aarch64-darwin. A separate evaluation changes
only the core setting to zero and fails with `boundedBuilds` in the assertion;
the test rejects that plausible regression. Logs:
`/tmp/nix-travel-runner-final.log` and `/tmp/nix-travel-unbounded-negative.log`.

Retained configuration: both complete Linux systems, the final Linux runner
check and the complete final Mac system build successfully. This establishes build compatibility and bounded
configuration, not a throughput improvement or working travel access. Desktop
activation, account enrollment and off-LAN/reboot tests remain required.

## H10: validate the configuration actually read by Hyprland

Baseline: the owner cannot open the launcher after entering Hyprland. Photo
`/Users/joel/Downloads/IMG_4540.HEIC` shows the autogenerated-config warning and
`/home/joel/.config/hypr/hyprland.lua`, with the default Kitty shortcut. Our
module explicitly selects `configType = "hyprlang"` and emits `.conf` instead.
Locked Hyprland c7216a9807a2683ce243f6ed14ae01e7e884c426 now only searches for
Lua and only constructs its Lua manager. System builds did not validate that
the compositor reads the generated file. The earlier check was insufficient.

Hypothesis: use Home Manager's supported Lua generator and the locked Hyprland
API, preserving the monitor, colors, effects, launcher, terminal, workspace and
media shortcuts, plus startup services. Correct typed options (NumLock bool,
hardware-cursor integer). Validate the generated file with the installed
compositor's `--verify-config`, included in `system.checks` and flake checks.
Reject parser failures, changed intended shortcuts, an autogenerated config,
lost startup services, or a check that accepts the original format mismatch.

Budget: Hyprland module, one native configuration check, flake/CI wiring and
research evidence. Use supported Home Manager generators and compositor APIs;
do not downgrade the compositor, suppress errors or invent a config converter.
Keep the runner profile independent. Verify on Linux when SSH reconnects; keep
the autogenerated user file as a backup before Home Manager takes ownership.

Runtime counterexample: Wofi's actual Linux process name is `.wofi-wrapped`.
The old `pkill wofi` command and first migration's `pkill -x wofi` did not match
it. Four launcher layers accumulated, and the owner reported that selecting an
application left the menu visible. Match both exact names for Joel's user;
verify that repeated shortcut dispatch alternates between zero and one menu
process/layer, and selecting a real application removes the menu. Close only
the duplicate launcher processes during recovery.

Retained H10 evidence: the real old configuration fails the locked compositor
with exit 1; the managed Lua passes its native check. The complete Linux desktop
build passes, Home Manager activation and compositor reload succeed, and live
config errors are empty. The corrected menu command produces one, zero, one,
zero Wofi layers over four successive invocations. Owner app-selection
confirmation and root activation of the new system generation remain pending.

## H11: restore the existing desktop startup services

Baseline after H10: the managed dashboard exits with GNIM decorator metadata
undefined; its tsconfig enables legacy decorators and targets ES2023. Official
GNIM instructions require standard decorators and ES2020 or earlier. The GTK
package contains `catppuccin-mocha-blue-standard`, while configuration names a
nonexistent title-case theme. Hypridle repeatedly exits because it has no
configuration file. Udiskie fails because UDisks is not enabled. A direct SwayNC
startup competes with its existing D-Bus-activated systemd service.

Hypothesis: correct the two TypeScript compiler settings, use the actual GTK
theme name, give hypridle its existing lock command with no new idle/sleep
timers, enable UDisks under the existing udiskie owner, and use SwayNC's existing
systemd service as its sole startup owner. Preserve existing appearance,
dashboard metrics, notifications, removable-drive mounting and always-on host
policy. No new dependencies, framework, custom daemon or lock update.

Falsifiers: dashboard exits, theme files remain missing, service restarts keep
increasing, more than one notification daemon, new sleep behavior, configuration
errors, changed launcher behavior or failing full-system builds. Test the
dashboard on the live Wayland session, inspect actual service state and restart
counts, check package paths, build main and recheck runner invariants. UDisks
runtime needs root system activation and must not be claimed from evaluation.
Budget: five existing owner files plus evidence. Keep any unexpected additional
widget issue within the demonstrated startup failure; do not redesign widgets.

Retained evidence: before the compiler correction, AGS exits 1 with undefined
GNIM decorator metadata; afterward it survives the eight-second startup probe
and the managed dashboard is mapped in the live session. The configured GTK4
CSS path exists. Hypridle and the single systemd-owned SwayNC process both run
with zero restarts. The full main system, native compositor check and runner
configuration check build. Udiskie's required system service is built but its
runtime qualification awaits root activation. Nonfatal GTK/backlight warnings
remain; no unrelated widget redesign or extra desktop package was introduced.
