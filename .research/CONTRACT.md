# Immutable contract

Refresh flake inputs, pinned tools and CI actions; remove Finder metadata and prevent it returning to Git. Preserve both hosts, shared Home Manager ownership, agent integrations, secrets handling and unrelated Orca changes.

Use Nix and existing package builders. Add no project tooling or Python files. Do not apply a sudo rebuild, commit unrelated edits, decrypt secrets or remove files beyond requested Finder metadata. Avoid a full system build on the Mac with 11 GB free. Evaluate both hosts and build updated standalone tools where practical; report unavailable Linux checks honestly.

Owner amendment, 2026-10-25: commit all pending changes to main, including Orca
and the dependency refresh, alongside the merged desktop runner. This authorizes
their integration; it does not request system activation or publication.

Owner amendment, 2026-10-25: add Codex CLI to the desktop runner host. Use the
runner's locked nixpkgs package if it supports Linux and preserves the CLI
helpers. Keep authentication under the administrator's account. This addition
does not require a new package builder, a lock update or CI automation.

Owner amendment, 2026-10-25: commit this Mac's public SSH key and push main.
Authorize that key for Joel on both profiles of the same desktop. Keep the
private key off Git and preserve existing access. Publishing the configuration
does not activate it on the desktop.

Owner amendment, 2026-10-25: repair current package and module compatibility
failures, starting with the removed `grip` package. Check the desktop, runner
and Mac configurations against their locked inputs. Preserve current features
where supported; remove obsolete entries instead of reviving removed packages
or weakening checks. Keep existing pins unless a verified upstream fix requires
an update. Commit and publish the corrections through the established main
workflow. Do not claim live activation or a Linux build from Mac evaluation.

Owner evidence, 2026-10-25: IMG_4539.HEIC shows the desktop RTL8852AU module
failing to compile for Linux 6.12.113 because `set_monitor_channel` now takes
three parameters. Repair the selected driver's compatibility without changing
the kernel series, GPU driver, adapter or generated hardware file. Add Codex to
the regular desktop profile as well as the runner so either selected profile
provides it. Keep actual build and hardware evidence separate from evaluation.

Owner amendment, 2026-10-25: tune this desktop's performance and make it
accessible while travelling to New York. The owner selected Tailscale and will
keep the machine powered on. Preserve SSH key authentication and local access;
do not expose a public deployment endpoint or configure router forwarding.
Keep access and build limits consistent between desktop and runner profiles.
Account sign-in and password-required activation remain owner actions.

Owner amendment, 2026-10-25: test morrownr/rtw89 for the original TP-Link
2357:013f adapter after the existing 8852au driver repeatedly fails association.
Keep Linux 6.12, the GPU configuration and the working rtl8xxxu spare unchanged.
Preserve SSH through the spare. Build and inspect the candidate before loading
it. Use a separate worktree and temporary system activation; do not reboot or
select it for normal boots before hardware evidence. Compilation alone does
not establish connectivity. Password-required root commands remain owner actions.

Owner amendment, 2026-10-25: use the desktop for GitHub Actions and remote
development to reduce Mac disk use. The owner explicitly chose to keep the
graphical desktop while adding the runner. Preserve the existing headless
profile, working Wi-Fi, SSH and Tailscale identity. Reuse the existing runner
service and registration contract for private labcast/labcast-server. Do not
move or delete local projects, expose services publicly, weaken CI checks,
register public/fork jobs, or copy broad personal credentials to the service.

Owner clarification, 2026-10-25: development means Orca on the Mac connecting
over SSH to the Linux desktop. Repositories, Codex, builds and tests run on Linux.
The earlier native Mac CI requirement was an incorrect interpretation and is
superseded. Remove the hosted Mac job from Labcast PR 245; preserve the complete
Linux gate, telemetry assertions and cleanup. Keep optional Darwin flake outputs
for existing users; do not change the separate mobile project's requirements.
Configure Orca through its supported SSH interface over Tailscale. Keep private
keys and account credentials out of Git and the runner account. Prepare a fresh
remote checkout without moving or deleting the active Mac worktrees. Account
sign-in remains Joel's action; do not report an authenticated Codex session until
verified. No public listener, root daemon key or new agent framework is needed.
