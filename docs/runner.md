# Desktop GitHub runner

`nixosConfigurations.runner` turns the existing desktop into a headless runner
for the private `labcast/labcast-server` repository. It runs one job at a time.
The `main` profile remains available for desktop use. Both share the disk layout,
kernel series, Wi-Fi driver and NVIDIA driver selection in `hosts/main/`.

The runner starts at boot and retries after failure. Sleep is disabled. Nix uses
one build slot with four cores; Cargo uses the same compilation limit. Work files live on disk in
`/var/lib/github-runner/work`; the NixOS module clears that directory whenever
the service starts. Registration state lives separately in
`/var/lib/github-runner/labcast`. A restart interrupts a running job, so wait for
the runner to be idle before maintenance.

## Before switching

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
verify a remote access route before leaving. Check the firmware's power-on-after-
power-loss setting at the machine. Nix cannot configure that setting here.

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
nix build .#rtl8852au-runner --no-link --no-update-lock-file
nix build .#nixosConfigurations.runner.config.system.build.toplevel --no-update-lock-file
```

Apply only after the build succeeds and the credential and remote access are ready:

```bash
sudo nixos-rebuild switch --flake .#runner
systemctl status github-runner-labcast docker
journalctl -u github-runner-labcast -n 60 --no-pager
```

On the Mac, the configuration check is
`nix build .#checks.aarch64-darwin.runner --no-update-lock-file`. It checks the
evaluated configuration and NixOS assertions. It does not build the Linux host
or test live hardware.

## Codex

Both desktop profiles include Codex CLI from their locked nixpkgs inputs. After
applying the profile, sign in as `joel`, open a project directory and run
`codex`. Complete the first-run sign-in using your own account. See the
[Codex CLI guide](https://learn.chatgpt.com/docs/cli).

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
existing tests and job names, use an explicit job timeout, and always clean up
Compose services, including after failure. A persistent runner reuses its disk
between jobs. Route a manual test first; only then change the required PR jobs.
This Linux host cannot run the `macos-26` job.

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
