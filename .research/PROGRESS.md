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

## Current package compatibility repair

The owner reported the removed `grip` package and requested a broader check.
The desktop package list reproduced the GTK2 removal error before changes.
Removed that obsolete entry and replaced deprecated `stdenv.isDarwin/isLinux`
aliases with the supported `stdenv.hostPlatform` fields. Input pins are unchanged.
The existing NixOS CI job now checks package selections and the runner before
full desktop evaluation, preserving its job name and the full evaluation gate.

Actual checks on 2026-10-25:

- All 310 desktop system package derivations evaluate, with no failed entries.
- All 69 Home Manager package names evaluate. All 68 packages other than Doom
  Emacs evaluate their derivations. Doom remains enabled and unmodified.
- NixOS assertions return no failures. Full option warnings, Home Manager
  derivation evaluation and the desktop toplevel require Doom's Linux build.
- The full Mac toplevel evaluates to the same derivation as before the repair:
  `/nix/store/z8ciyac22rp8sk6fajm4dq3jj7v9cql7-darwin-system-26.11.f0ec2b3.drv`.
- The runner configuration check passes after the changes. All nonempty Nix
  files parse. Actionlint 1.7.12 runs through the locked Nix environment and
  passes. The formatted Orca file and diff whitespace checks pass; other touched
  files retain their existing formatting. Graphify refresh succeeds.
- `nix flake check --all-systems --no-build --no-update-lock-file` and direct
  desktop toplevel evaluation both stop at
  `/nix/store/lpr1gm2rgw75vjcbmv1j3lh3krm3zljg-doom-intermediates.drv`, which
  requires x86_64-linux. This Mac is aarch64-darwin. No passing full flake gate or
  Linux runtime build is claimed.

The remaining prerequisite is desktop SSH access or running the full Linux
check locally on that desktop. SSH still rejects the configured key. The public
key bootstrap in `docs/runner.md` does not need a NixOS rebuild, so it can unblock
remote work even while the current desktop configuration fails to rebuild.
Raw audit results are in `/tmp/nix-desktop-*.json`, `/tmp/nix-home-*.json` and the
matching `.log` files. The retained fix is ready for main publication; nothing
has been activated on either host.

## RTL8852AU build repair

The owner's photo supplies the Linux build failure that Mac evaluation cannot
detect. The failure is a callback signature mismatch after Linux 6.12.101
backported an API change. Added one compatibility patch to the existing nixpkgs
driver through the shared kernel package set. Both desktop profiles use it.
The kernel series, NVIDIA driver, generated hardware file and original driver
source remain unchanged.

The flake's Wi-Fi/NVIDIA outputs now use the actual desktop kernel package set;
the Wi-Fi job also builds the runner's selected version. Codex is available in
both profiles. The runner guide checks its Wi-Fi module before the full build.

Checks passed:

- Exact source plus existing nixpkgs patches accepts the compatibility patch
  with zero fuzz and zero offset.
- Clang checks the source's callback signature against actual kernel header
  declarations for 6.12.100, 6.12.101, 6.12.113, 6.12.114 and 6.13. The original
  fails at .101/.113/.114 with the photographed type mismatch; the candidate
  passes every version. The test uses a stub body and does not compile the
  complete module. Inputs and diagnostics are `/tmp/rtl8852au-*.c` and `.log`,
  `/tmp/cfg80211-*.h`, and the patched source directory named in
  `/tmp/rtl8852au-check-dir`.
- CI Wi-Fi derivations equal the configured module derivations for desktop
  6.12.113 and runner 6.12.114. Both include Codex 0.163.0.
- The runner configuration check, touched formatted Nix files, configuration
  parsing, Actionlint and whitespace checks pass. Graphify refresh succeeds.

The owner completed the public-key bootstrap. SSH now succeeds with strict host
key checking. At a93a1e5, both full Wi-Fi builds pass on the desktop; `modinfo`
confirms the corresponding 6.12.113 and 6.12.114 versions. The Linux runner
configuration check passes and the configured desktop Codex starts successfully
(`codex-cli 0.163.0`) through `nix shell`.

The desktop toplevel evaluation passed on Linux. The full runner system first
exposed a second failure: missing Wi-Fi module certificates. H07 fixes the
installer with Kbuild's standard `modules_install` target and shared Nixpkgs
flags. Both full module trees and the complete runner system now build. The
installed modules have PKCS#7 signatures, nonempty certificates, matching kernel
versions and executable sleep helpers. Existing CI now assembles both profiles'
module trees, which rejects the original packaging failure.

Raw logs are `/tmp/nix-desktop-driver-build.log`,
`/tmp/nix-desktop-codex-runner-check.log`, `/tmp/nix-desktop-runner-build.log`
and `/tmp/nix-desktop-toplevel-eval.log` on the Mac. The successful follow-up logs
are `/tmp/nix-desktop-module-trees.log` and `/tmp/nix-desktop-runner-rebuild.log`.
The isolated Linux test checkout is `/tmp/nix-config-wifi-check`.
The desktop checkout is
`/home/joel/nix-config`. No activation or reboot has run. The current 6.12.94
kernel still supplies the Wi-Fi connection carrying SSH. Hardware checks with
the new kernel, runner registration and Codex sign-in remain separate steps.

The owner now requests performance tuning and access while travelling, and
selected Tailscale. Prepare shared host settings and the Mac client, validate
both profiles and preserve the working SSH route. The desktop requires a sudo
password; activation and Tailscale account sign-in need the owner at the machine.

H09 passes full Linux build validation. Both profiles share one
Nix build/four cores, Cargo's job count, SSD scratch space, zram, the performance
governor, disabled sleep/Wi-Fi power saving and a standard Tailscale service.
The private hostname lives in `vars.desktopHost`. The Darwin configuration owns
the official `tailscale-app` cask, a remote SSH alias, the verified desktop host
key and one remote Nix build slot. The local SSH alias remains available.
Both profiles' evaluated settings match. The updated runner check and Linux
`nix flake check --no-build --no-update-lock-file` pass. Darwin evaluates.

The owner installed and signed into Tailscale on the Mac; CLI reports Running
and online, with no peers yet. The desktop daemon is still inactive. Both hosts
require a password for sudo. The owner prefers installation through Darwin Nix;
do not ask for a separate Homebrew installation again.

Both complete Linux systems built, followed by a successful build of the final
operator/hostname changes and runner check in `/tmp/nix-config-wifi-check`:

- Desktop: `/nix/store/b0n9i9x3j2hf2rmvwk4rqmh8x6ad5y1b-nixos-system-nixos-26.11.20261020.02c087f`.
- Runner: `/nix/store/3n97fkaiiirvy59jlgzzqirb9ilbhpq8-nixos-system-nixos-26.11.20261023.3ec6363`.
- Logs on the Mac: `/tmp/nix-desktop-travel-build.log` and
  `/tmp/nix-desktop-travel-final-build.log`.

The final Mac runner check passes. A separate negative check rejects zero cores
(Nix's unlimited value). Generated SSH configuration selects the correct host,
key and agent-forwarding policy; the system known-host file contains the verified
desktop key. Touched Nix files parse, targeted formatting and whitespace checks
pass, and Graphify refreshes successfully with its existing extraction warnings.

Full Darwin build and the final known-host update both passed. The final output
is `/nix/store/7577pp1cqaldhzmgbq2zwbg4l7asz1r1-darwin-system-26.11.f0ec2b3`;
logs are `/tmp/nix-travel-darwin-build.log` and
`/tmp/nix-travel-darwin-final-build.log`. Mac activation remains pending.
The owner must activate the desktop with sudo before enrollment.
After that, obtain the login link with `tailscale up`, test private SSH and ask
for the off-LAN/reboot travel check. No activation, reboot or new-kernel hardware
test has run yet. H07 and H08 are committed and pushed through 8b0653c.

## Current wait: Wi-Fi reconnection after activation

H09 is published as f73237b and pulled into the desktop's clean main checkout.
The owner ran the requested desktop activation and reported that the network
stopped working. Runtime qualification remains pending. SSH fails through
both `nixos.local` (name resolution) and the last LAN address `10.0.0.5`
(timeout/no route); the Mac tailnet still has no desktop peer.

Initially offered a local rollback. The owner then said to hold off, that Wi-Fi
is taking time to connect and that this is not a Nix problem. No rollback is
confirmed. Leave the configuration unchanged and wait for reconnection, then
verify the active generation and services before Tailscale enrollment. Do not
attribute the delay to Nix without evidence. The full Mac build remains running
independently; it has since completed successfully as recorded above.

## Current recovery: Wi-Fi password and Hyprland Lua configuration

The owner reached tty2 using Control + Option + Fn + F2 on a Mac keyboard.
Photo IMG_4541 shows that NetworkManager sees the Wi-Fi device but connection
activation failed because secrets were required and not provided. The owner
says `nmcli --ask` did not work; asked them to try `sudo nmtui` and report the
result. Never request the Wi-Fi password in chat or put it in Nix/Git. Once
connected, inspect the profile's secret flags (not its secret) to establish
whether unattended reconnection needs a system-owned saved credential.

Photo IMG_4540 confirms the autogenerated Lua config, and locked compositor
source proves the managed Hyprlang file is ignored. H10 now migrates the module
to Home Manager's Lua output, preserves the existing commands and appearance,
and adds a native `Hyprland --verify-config` gate to `system.checks` and CI.
Workspace 10 now uses the actual 0 key instead of an invalid 10 keysym. Nix
rendering succeeds. Native Linux validation and live recovery require SSH;
the desktop is still unreachable. Preserve the autogenerated user Lua file
as a backup before applying Home Manager. Do not claim the desktop is repaired.

H10 checks so far: generated Lua and native-check derivation evaluate; forcing
the old Hyprlang format is rejected with the intended assertion. Targeted
nixfmt, whitespace and actionlint checks pass. Graphify refresh succeeds with
its existing extraction warnings. Full main evaluation on the Mac reached a
Linux-only build and was stopped; run it on the desktop once connected.
IMG_4542 confirms `--ask` was typed correctly but still failed. The next command
shown is `sudo nmcli`, not `nmtui`; the text-menu attempt is not confirmed yet.
The photo shows the RTL8852AU interface detected and disconnected, and a
tailscale0 interface. This does not establish Wi-Fi or Tailscale connectivity.

The owner reports activation still fails after the nmtui instructions. Stop
repeating activation; request the latest NetworkManager journal and running
kernel version. Ask whether temporary Ethernet access is available for direct
diagnosis. The earlier missing-secrets message alone does not establish the
underlying cause of the repeated authentication/activation failure.

## Recovery verified on Linux

SSH is restored through `nixos.local`, now 10.0.0.22, using a second USB adapter
with the in-kernel rtl8xxxu driver. The original rtl8852au adapter remains
disconnected. Logs show association timeouts/rejections before the missing-secret
message. Do not call it a password problem or claim the original driver works.
The owner confirms the working adapter can remain connected for travel. Its
profile autoconnects for all users with system-owned credential flags; no secret
was read. Linux 6.12.113 and the H09 system are running; tailscaled is active but
NeedsLogin. The owner received its sign-in link, usable from the Mac's browser.

H10's native validator passes, and the actual old `.conf` fails the same locked
Hyprland parser with exit 1. The final launcher-fix system builds:
`/nix/store/d2dcy383k24plvxi5qpl3r8rr70y2lmg-nixos-system-nixos-26.11.20261020.02c087f`.
The native configuration check is
`/nix/store/q4b5388828mc10kf6i8rykc80icq0dia-hyprland-configuration`.
Linux flake evaluation passes, excluding incompatible systems. Logs on the Mac:
`/tmp/nix-hyprland-linux-check.log`, `/tmp/nix-hyprland-main-build.log`,
`/tmp/nix-hyprland-menu-build.log`, `/tmp/nix-hyprland-flake-check.log`.

Home Manager activation succeeded as Joel. It preserved the autogenerated Lua
file as `~/.config/hypr/hyprland.lua.before-lua-20261025194828`. The compositor
reloads the managed Lua with no config errors. Foot and Waybar are mapped.
The launcher initially accumulated copies because its actual process name is
`.wofi-wrapped`; the corrected user-scoped toggle now produces exactly 1, 0, 1,
0 menu layers over four invocations. Owner confirmation of choosing an app is
pending. The system generation still needs root activation after publishing;
the live home configuration is repaired without a reboot.

Read-only audit also found independent startup faults: AGS crashes in GNIM's
decorators, the GTK theme name does not match its package, hypridle has no config,
udiskie lacks the UDisks system service, and SwayNC is launched both directly and
by D-Bus/systemd. Keep these separate from H10 and record their contract before
changes. No new graphical session, reboot or off-LAN check is verified yet.

H10 is committed and pushed as 67b4962. H11 corrects the five existing owner
files named in its hypothesis. Main and both native checks build successfully;
the final main output is
`/nix/store/l79q5a1m36kh03w200m481kd9a7cbvsa-nixos-system-nixos-26.11.20261020.02c087f`.
Home Manager activation and Hyprland reload pass. The dashboard is mapped,
the selected theme CSS exists, and hypridle and the single systemd-owned
notification service are active with zero restarts. The old unmanaged SwayNC
process was stopped once during recovery. Udiskie remains failed until the
new UDisks system service is activated with sudo. Logs:
`/tmp/nix-desktop-startup-build.log`, `/tmp/nix-desktop-startup-final-check.log`,
and remote `/tmp/nix-ags-fixed-start.log` (old failing startup at
`/tmp/nix-ags-start.log`). Linux flake evaluation passes. Nonfatal legacy
GTK/backlight warnings remain, outside these startup fixes.

The first manual `tailscale up` reset the initial hostname/DNS preferences.
Reapplied all `services.tailscale.extraSetFlags` from the evaluated repository:
hostname labcast-desktop, CorpDNS=false, RunSSH=false, operator joel. Account
enrollment is still pending. On future first enrollment, preserve those flags
or apply the declared settings afterward; verify actual prefs rather than
assuming the boot oneshot remains authoritative after manual `up`.

Next: publish H11 and fast-forward the desktop main checkout, then have the
owner run the already-built system activation with their sudo password. Verify
UDisks/udiskie and active store path afterward. Complete Tailscale enrollment
and private SSH, then the off-LAN/reboot qualification. The final Mac system
is already built; its sudo activation is also pending. Runner registration
and Codex sign-in remain separate uncompleted operator steps.

H11 system activation is now observed at l79q5a1m36kh03w200m481kd9a7cbvsa;
udisks2 and the user udiskie service are both active. H12 starts in the isolated
fix/desktop-wifi-driver worktree from eb3ff73. Main is unchanged. Source and
firmware match verified; build and runtime qualification are pending. Remote
candidate worktree: /tmp/nix-config-driver-check. Spare Wi-Fi still owns SSH.

H12 build preparation is complete. Candidate desktop system:
`/nix/store/db7k2pzddszy6q22isqxixfaq92f51a5-nixos-system-nixos-26.11.20261020.02c087f`.
Desktop driver output swqf8yfissjingk34xzy356g5wkbzvpg; runner output
v5kan3x96v2hyaqwm9jl4yyfmh7pln0l. Both module trees build, along with the
desktop system and existing native checks. Linux flake evaluation passes.
Nix formatting/parsing, whitespace and Graphify pass (existing extraction
warnings only). Logs on the Mac: /tmp/nix-wifi-candidate-build.log,
/tmp/nix-wifi-system-build.log and /tmp/nix-wifi-final-check.log.

Prepared a one-off /tmp/test-wifi-driver.sh on the desktop, checked with
ShellCheck and bash -n. It guards the kernel, current system and spare route;
temporarily activates the built candidate, unloads only 8852au, then loads
rtw89_8852au_git from the candidate module tree. It attempts rollback if loading
fails. The owner has been asked to run it with sudo; do not assume it ran.
No new boot generation was selected. No candidate code is on main.

Temporary NetworkManager test profile: `RTL8852AU driver test`, UUID
796b49fd-f783-4eed-9722-68e8300a71a9, cloned from the original adapter profile.
It matches permanent MAC 20:23:51:20:3C:23 instead of the USB port name, keeps
autoconnect off, uses route metric 900 and ignores automatic DNS. Original
profile 12fff5e7-6696-4e04-b9c4-36793b1b19b2 has autoconnect disabled only in
memory. The spare remains at 10.0.0.22 with metric 600. No password was exposed.

After the owner runs sudo: verify candidate binding and firmware load, activate
the temporary profile with a bounded timeout, inspect DHCP and interface-bound
traffic, disconnect/reconnect it, and review kernel errors. If rejected, remove
the temporary profile, restore the original profile's in-memory autoconnect,
and use l79q5a1m36kh03w200m481kd9a7cbvsa plus 8852au for rollback. Reboot also
returns to the unchanged default and clears temporary network profiles.

The owner ran the test activation. The candidate loads its expected firmware,
switches the adapter to USB 3 (5000 Mbit/s bus speed), and associates on 5500 MHz
with the original saved credentials. DHCP gives 10.0.0.5. The first probe gets
10/10 router replies, then loses packets during USB removal/reinsertion of the
spare at 20:56:24 and final removal at 20:56:35. The original adapter also
disconnects and reconnects at 20:56:56. Do not treat that interval as a clean
driver stability measurement. The owner reports working Wi-Fi afterward.

With the spare absent, the test profile's ignored automatic DNS no longer has
the spare's DNS to rely on. Re-enabled automatic DNS on the temporary profile
and reapplied it without disconnecting. A fresh stable traffic run is in
/tmp/nix-wifi-runtime-stable.log. Initial interrupted run is in
/tmp/nix-wifi-runtime.log. No new kernel entries after 20:57:00 at inspection.

Tailscale enrollment is now complete. Verified key-authenticated SSH from the
Mac to desktop 100.106.80.23 over Tailscale. Enrollment reset hostname/operator
preferences again; ordinary Joel cannot run the declared tailscale set flags.
Include `sudo systemctl restart tailscaled-set.service` with final persistent
system activation, then verify hostname labcast-desktop, accept-dns=false and
operator joel. This is an overlay test on the home LAN, not an off-LAN test.

H12 runtime checks pass on 5 GHz. Fresh traffic: 20/20 router pings (1.998 ms
mean), 20/20 Internet pings (16.772 ms mean), HTTPS 200 through wlp0s20f0u4.
These are short samples, not a throughput or long-term stability claim. The
saved original profile reconnects successfully in seven seconds, followed by
5/5 Internet pings and HTTPS 200. Autoconnect is restored, credentials remain
system-owned, automatic DNS is present, and the temporary test profile is
deleted. Final log: /tmp/nix-wifi-reconnect.log. No kernel error appears there.
The spare is no longer attached; all current access uses the original adapter.

Retain the candidate and publish through the authorized main workflow. Next,
fast-forward /home/joel/nix-config and build the published desktop/runner
systems. The owner must run the persistent `nixos-rebuild switch` and restart
the existing tailscaled-set unit with sudo. Verify system profile and Tailscale
preferences afterward. Cold boot, 2.4 GHz, extended soak and off-LAN tests are
unverified; do not reboot the owner's active desktop without instruction.

H12 is merged and pushed as 8b61750; the desktop main checkout is updated.
Published main and headless systems build. Main is still only test-activated.
The owner now requests runner setup and remote-development advice, explicitly
keeping the desktop GUI. H13 begins in feat/desktop-ci, local worktree
/Users/joel/nix-config-worktrees/desktop-ci. A final combined main activation
will persist the Wi-Fi change, start the runner and reapply Tailscale settings.
GitHub has no registered runner; scoped PAT installation remains an owner step.

H13 implementation and build checks pass. Main retains Hyprland and now has one
boot-enabled runner under github-runner; trusted Nix users are root and joel,
not the service account. Shared Docker configuration and runner ownership are
in hosts/main/runner.nix; both profiles use runner package 2.338.0. No lock input
changed. Main output fhrnhwvij907g8ksmyz3zdj1qn91q5vg; headless output
14ayjlqfr1w3wzlqzcnmqgh25y45x8a6. Full builds, existing runner/native Hyprland
checks and Linux flake evaluation pass. Final logs:
/tmp/nix-desktop-ci-build.log and /tmp/nix-desktop-ci-final-build.log.

Disk audit: Mac /nix/store 100 GB, Code 49 GB, Library/Developer 22 GB, local
Linux-builder VM 20 GB, Cargo cache 4.4 GB, readable Library caches 4.3 GB.
Some macOS cache folders deny read access; no data was deleted. The Mac still
uses its old builder config (nixos.local, eight slots and unverified KVM); the
already-built Darwin activation is pending. Its user SSH key is encrypted, so
daemon access needs the separate root key setup. Prefer direct remote editing
and building for disk relief; do not claim offloaded Nix outputs stay remote.

Current Labcast main is 057130e; local main remains cbf76b1. Server and Studio
worktrees remain separate and maintenance has unrelated uncommitted changes;
leave all of them intact. Existing workflows still target GitHub-hosted Linux
and macOS. Runner registration, real job qualification and Linux job routing
are not yet complete; do not report the runner as operational from a Nix build.

H13 activation is verified after the owner's sudo handoff. Both the active
system and persistent system profile resolve to fhrnhwvij907g8ksmyz3zdj1qn91q5vg.
The runner service is enabled, active as github-runner, and has zero restarts.
GitHub reports labcast-desktop online and idle with self-hosted/Linux/X64/nixos
labels. Docker, Tailscale and the user graphical session are active. Actual
Tailscale preferences now match the declaration: labcast-desktop, DNS acceptance
off, Tailscale SSH off, operator joel. Ordinary key-authenticated SSH through
100.106.80.23 succeeds. Nix trusts root and joel, not the runner account.
Codex reports 0.163.0. Persistent activation also includes the retained H12
Wi-Fi driver. Cold boot and off-LAN access remain untested.

Linux job qualification is underway through existing Checks/workflow_dispatch
on ci/desktop-runner, based on Labcast main 057130e. The root checkout hosts this
small routing branch; existing Server, Studio and Maintenance worktrees remain
untouched. The first commit 10a2b2f changes manual Linux routing only. Nix's
existing workflow derivation passes, including actionlint. Normal Linux routing
must wait for actual checkout, build, telemetry and artifact evidence. Hosted
macOS billing limits remain a separate gate; do not remove or bypass it.

H13 real Actions qualification completed at Labcast cddcfc1 in run 40231857614:
the Linux flake gate and telemetry job both pass on labcast-desktop. Checkout,
JavaScript actions, Nix, API/telemetry artifact uploads, real stored telemetry
and Compose cleanup are verified. The runner returns to Idle without restarts.
No CI containers or network remain after cleanup. The existing five-minute
manual fuzz workflow has not been run; the Linux flake fuzz smoke test passes.

Actual failures exposed and fixed:

- The runner's UMask=0066 made receiver files unreadable inside non-root
  containers. The workflow sets only those two non-secret files to 0644 and
  gives CI its own labcast-ci Compose project. The original unchanged test
  fails before this fix and passes afterward. Fixed ports still prevent local
  telemetry and CI from occupying them concurrently.
- Linux sandbox test clients lacked native CA roots. The original derivation
  also fails as Joel. Adding only locked cacert through SSL_CERT_FILE passes
  all 13 unit and 12 process tests with unchanged assertions and deadlines.
  The retained setting belongs to Linux testArgs; Darwin stays unchanged.

PR https://github.com/labcast/labcast-server/pull/245 contains the bounded CI
integration. Its final head 074c861 routes normal Linux and manual fuzz jobs to
the desktop, declares its custom label for actionlint and preserves job names,
Mac checks and test commands. Normal push/PR runs 40232173135 and 40232176376
verify the final routing. The final local Mac flake gate passes. One initial
Mac release-test packaging run logged a nonfatal audit-tmpdir shell segmentation
fault after its tests passed; Nix returned success. This diagnostic is retained
in /tmp/labcast-runner-macos-release.log and is not a runner failure.

GitHub still refuses to start hosted macOS jobs because of its billing limit.
Do not merge or remove that gate without the owner's decision; local Mac results
are not a fabricated GitHub check. No feature/maintenance worktree was modified.
The main Labcast checkout remains on the clean ci/desktop-runner branch. No
application code, test assertions, Cargo dependencies or lockfiles changed.
Host H13 is active and persisted; cold boot, service-restart and off-LAN tests
remain unperformed. The Mac's Darwin activation and daemon builder key setup
remain pending. Ordinary user SSH/Nix store access over Tailscale works.

Logs: /tmp/labcast-runner-linux-job.log (original failure),
/tmp/labcast-runner-linux-reproduce.log (outside runner),
/tmp/labcast-runner-certs.log (certificate-only candidate),
/tmp/labcast-runner-linux-passing.log, /tmp/labcast-runner-telemetry-job.log,
/tmp/labcast-runner-telemetry-fixed.log and
/tmp/labcast-runner-routing-push.log. GitHub run links above retain job evidence.

Final normal PR run 40232176376 passes both Linux jobs at 074c861 on
labcast-desktop. Its only failure is hosted macOS, with GitHub's explicit
billing-before-start annotation. PR 245 is ready for review and remains
unmerged. Linux routing becomes the main default only after that PR merges.

H14 owner clarification supersedes the previous Mac gate decision: Joel wants
Orca on the Mac to connect over SSH and perform backend work on Linux. PR 245
removed the hosted Mac job, retained optional Darwin outputs, and documented
the remote development workflow. No tests or assertions changed. Final head
b28596c passes both jobs in PR run 40232902453 and push run 40232897556.
PR 245 merged normally as c79108a; main run 40233091770 also passes both jobs.
The local Labcast root is clean on main. Other active worktrees are untouched.

Prepared /home/joel/Code/labcast/labcast-server as a fresh clone on the desktop
and fast-forwarded it to c79108a. Its Nix development environment loads and
reports Linux, the remote checkout path, Codex on PATH, Cargo 1.99.0 and Just
1.58.0. Git identity is Joel's personal identity and repository access works.
Log: /tmp/labcast-remote-environment.log. No Mac projects or build files were
deleted, and no active agent was migrated.

Orca setup remains pending user authentication. Its existing desktop target
uses local-only nixos.local and is asking for an SSH password. The owner has
the exact Tailscale target and identity-file fields for a separate connection.
Codex is installed but login status is still Not logged in; a device login is
waiting for the owner. Do not copy credentials or claim an end-to-end Orca
session yet. After connection, register the prepared remote path with Orca's
existing Labcast project and verify a remote terminal and Codex session.
Mac Darwin activation is still pending; direct Orca SSH does not require the
separate Mac root-daemon builder key. Cold boot and off-LAN tests remain open.
