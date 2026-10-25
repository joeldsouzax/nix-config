# Desktop GitHub runner

`nixosConfigurations.main` keeps the graphical desktop and runs one GitHub
Actions job at a time for private `labcast/labcast-server`.
`nixosConfigurations.runner` provides the same service without the desktop.
Both share the runner in `hosts/main/runner.nix`, disk layout, kernel series,
Wi-Fi driver and NVIDIA driver selection. The runner package comes from the
separate `nixpkgs-runner` input in both profiles.

The runner starts at boot and retries after failure. Sleep is disabled. Nix uses
one build slot with four cores; Cargo uses the same compilation limit. The
six-core, 16 GB machine shares these limits with the desktop profile. Both use
the performance CPU governor and 8 GB of compressed swap. Temporary build data
and runner work stay on SSD, with disk swap as a fallback. These settings bound
parallel work; they are not a measured build-speed guarantee. Work files live in
`/var/lib/github-runner/work`; the NixOS module clears that directory whenever
the service starts. Registration state lives separately in
`/var/lib/github-runner/labcast`. A restart interrupts a running job, so wait for
the runner to be idle before maintenance.

## Before activation

Confirm SSH access and a NetworkManager connection that starts without a GUI
login. Existing passwords, SSH keys and connections remain on disk. The profile
keeps `joel` as the administrator and uses a separate `github-runner` service
account. Confirm the machine's current hostname before applying the configured
`nixos` name. Prefer Ethernet while travelling if it is available.

Both desktop profiles authorize this Mac's public key from
`hosts/keys/joel-mac.pub` for `joel`. The private key stays on the Mac. This takes
effect after rebuilding the desktop; pushing Git alone does not grant access.
To enable SSH before rebuilding, run these commands as `joel` on the desktop
from the updated checkout:

```bash
install -d -m 0700 ~/.ssh
cat hosts/keys/joel-mac.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
```

Only trusted repository code may run here. Docker access gives jobs control of
the host; the separate user is not a sandbox for hostile jobs. Keep fork jobs off
this runner. Personal files remain on its disks. Deployment credentials and
production services need a separate decision.

The runner needs outbound HTTPS to GitHub. No inbound port is needed for jobs.
SSH remains available on port 22. `nixos.local` only works on the local network;
use the Tailscale route below while travelling. Check the firmware's power-on-after-
power-loss setting at the machine. Nix cannot configure that setting here.

## Remote access

Both profiles run Tailscale at boot and keep the same device identity on disk.
They disable sleep and Wi-Fi power saving. The existing NetworkManager connection
must autoconnect without a desktop login. Keep the machine powered and connected.
No public IP, router port forwarding or exit node is required. See
[Tailscale connection types](https://tailscale.com/docs/reference/connection-types).

The Mac client is owned by the Darwin configuration through Homebrew. Apply the
configuration with the normal `nixswitch` command, then open the app:

```bash
open -a Tailscale
```

Approve the macOS VPN configuration and sign in. After applying either NixOS
profile on the desktop, enroll it with the declared settings and open the login link:

```bash
sudo tailscale up --hostname=labcast-desktop --accept-dns=false --ssh=false --operator=joel
sudo systemctl restart tailscaled-set.service
```

Use the same Tailscale account on both devices. The desktop appears as
`labcast-desktop`. The service keeps the desktop's existing DNS settings; the Mac
can use Tailscale's MagicDNS name. SSH still uses the committed Mac public key.
Connect from the Mac with `ssh joel@labcast-desktop`. After applying the Mac's Home
Manager configuration, `ssh desktop-remote` is the equivalent saved alias.
`ssh desktop` continues to use the local `nixos.local` address.

Before travelling, put the Mac on a phone hotspot and verify SSH, including after
a desktop reboot. Check that the desktop's Tailscale key remains valid for the
trip; disable key expiry for this trusted desktop in the Tailscale console if
needed. Account sign-in and this connection test are required before claiming
remote access works. See [Linux setup and key expiry](https://tailscale.com/docs/install/linux).

The Mac's Nix builder also uses the private name and one build slot. Apply the
Darwin configuration and complete its separate root SSH key setup as documented
in `darwin/linux-builder.nix`; the user's passphrase-protected key and agent do
not automatically grant the Mac's Nix daemon access.
The desktop currently lacks `/dev/kvm`; enable Intel virtualization in firmware
and verify KVM before advertising that capability or running VM-based jobs.

## Registration credential

Create a fine-grained GitHub PAT with resource owner `labcast`, access only to
`labcast-server`, and repository **Administration: read and write**. Complete
organization approval if GitHub requests it. Choose an expiry that covers the
trip, and rotate it before expiry. GitHub documents this permission for
[runner registration](https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository).

Store it on the desktop as a root-owned file. The following prompt does not echo
the token or put its value in shell history. Do not paste it into chat or Nix.

```bash
sudo install -d -m 0700 /var/lib/secrets
sudo bash -c 'umask 077; read -r -s -p "Runner PAT: " runner_token; printf "\n"; printf "%s" "$runner_token" > /var/lib/secrets/github-runner-token'
sudo chmod 0600 /var/lib/secrets/github-runner-token
```

This is the initial runtime credential. Any repository backup of it must use
the existing SOPS rules in `.sops.yaml`; never commit the plaintext file.
The module keeps its registration identity across ordinary restarts. Changes
to the name, URL, labels or credential can cause registration again, which is
why this profile uses a PAT rather than an expiring one-hour registration token.

## Build and apply

Transfer the reviewed branch to the desktop. Run these commands from its checkout:

```bash
nix build .#checks.x86_64-linux.runner --no-update-lock-file
nix build .#rtw89-morrownr --no-link --no-update-lock-file
nix build .#nixosConfigurations.main.config.system.build.toplevel --no-update-lock-file
```

Apply only after the build succeeds and the credential and remote access are ready:

```bash
sudo nixos-rebuild switch --flake .#main
sudo systemctl restart tailscaled-set.service
systemctl status github-runner-labcast docker
journalctl -u github-runner-labcast -n 60 --no-pager
```

Use `.#runner` instead of `.#main` only when choosing a headless machine.
That profile has its own complete build and `.#rtw89-morrownr-runner` package.

On the Mac, the configuration check is
`nix build .#checks.aarch64-darwin.runner --no-update-lock-file`. It checks the
evaluated configuration and NixOS assertions. It does not build the Linux host
or test live hardware.

## Remote development

Keep working repositories under `/home/joel/Code`, the desktop's separate project
disk. Use Orca on the Mac to open projects over SSH. The editor stays on the Mac;
agents, terminals, development shells, containers and tests run on the desktop.
This keeps Cargo targets, Nix outputs and service data off the Mac. Ordinary
distributed Nix builds can still copy completed outputs back to the Mac.

Both desktop profiles provide Node.js and npm through Nix for Orca's remote
helper. Apply the host configuration before connecting. In a fresh SSH session,
`node --version` and `npm --version` must succeed. Orca 1.4.222 requires Node.js
18 or later; it cannot start the helper when these commands are missing.

In Orca, open **Settings → SSH Hosts → Add Target**. Use `labcast-desktop`, user
`joel`, port `22` and the Mac's `~/.ssh/id_ed25519` identity. The desktop's
Tailscale address also works when MagicDNS or the saved SSH alias is unavailable.
Test and connect, then add the remote folder `/home/joel/Code/labcast/labcast-server`
to the Labcast project. Choose this SSH host when creating new worktrees.
See [Orca SSH worktrees](https://www.onorca.dev/docs/ssh).

Open a remote terminal and run `pwd` and `uname -s`. They must show the Linux
checkout and `Linux`. Run `direnv allow` in that checkout, then use its existing
Nix and Just commands. Codex authentication belongs to this Linux user account.
An existing Mac chat or worktree does not move merely because a host was added.

For a separate persistent SSH terminal, after applying the Mac's SSH config:

```bash
ssh -t desktop-remote 'tmux new-session -A -s dev'
```

Tmux keeps the session running when the SSH connection closes. Keep development
repositories separate from `/var/lib/github-runner/work`, which the runner
clears at startup. Clone or transfer projects deliberately; this configuration
does not move or delete existing Mac projects. Keep project tools in their
repository Nix environment.

Forward a development HTTP port privately when needed:

```bash
ssh -N -L 8080:127.0.0.1:8080 desktop-remote
```

The Mac can then open `http://localhost:8080`. The service stays on the desktop.
Linux CI and backend builds run here. Native mobile tools such as Xcode still
run on the Mac; the separate mobile repository owns its requirements.

## Codex

Both desktop profiles include Codex CLI from their locked nixpkgs inputs. In an
Orca terminal on the SSH host, run `codex login --device-auth` and complete the
printed sign-in flow in the Mac browser. Then run `codex login status`. Open a
Codex agent in the remote project after sign-in succeeds. See
[Codex authentication](https://learn.chatgpt.com/docs/auth).

Keep Codex credentials in your user account; do not put them in Nix or the
GitHub runner service account. Updating the profile's nixpkgs input also updates
Codex.

## Route and qualify jobs

Wait for `labcast-desktop` to show **Idle** in the repository's Actions runner
settings. Route Linux jobs with:

```yaml
runs-on: [self-hosted, Linux, X64, labcast-desktop]
```

Nix is already installed. Skip Nix installer actions on this runner. Keep the
existing tests, use an explicit job timeout, and always clean up
Compose services, including after failure. A persistent runner reuses its disk
between jobs. Route a manual test first; only then change the required PR jobs.
The Labcast backend gate targets Linux. Optional native Darwin flake outputs do
not require a hosted macOS job for this remote development workflow.

Qualification must include checkout and a JavaScript action, a Nix build, Docker
Compose startup and cleanup, a service restart, and a cold boot with no login.
Confirm the runner returns to Idle and SSH still works after each restart. Check
free space on both `/` and `/nix/store`; they are different filesystems here.

The NVIDIA toolkit exposes the GTX 1070 through CDI, a standard container device
description. Test it on the host, then run Studio's real GPU suite. Do not label
this runner as GPU-qualified or set `STUDIO_GPU_RUNNER` until that suite passes.
The driver's presence does not prove codec or workload compatibility. Workflows
that request the older Docker `--gpus` interface need a separate compatibility
check; this profile enables the current CDI interface.

## Updates and recovery

The `nixpkgs-runner` input owns runner packages independently of desktop and Mac
packages. Check runner releases weekly and update this input through a reviewed
change, then build, apply while idle, and run a small job:

```bash
nix flake update nixpkgs-runner
```

NixOS disables the runner's own updater. GitHub normally requires an update
within 30 days of a runner release and can require security updates sooner.
See [GitHub's update policy](https://docs.github.com/en/actions/reference/runners/self-hosted-runners#runner-software-updates-on-self-hosted-runners).
This profile does not apply unattended OS upgrades.

Nix garbage collection and Docker pruning run weekly. Docker logs rotate and
journald has a disk limit. These are retention rules, not disk quotas: review
free space after representative builds and remove abandoned work only while idle.

For immediate recovery, use `sudo nixos-rebuild switch --rollback`, or select the
previous generation at boot. To return to desktop use from this checkout, build
and switch `.#main`. Keep a known working generation until the cold-boot and job
checks pass. The profile does not create a public deployment endpoint or replace
GCP; that needs service, storage, backup and network decisions first.
