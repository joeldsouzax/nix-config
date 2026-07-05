# Linux builders for nixosTest / Linux derivations on an aarch64-darwin Mac.
#
# Determinate Nix owns the daemon (nix.enable = false), so nix-darwin's
# `nix.linux-builder` module is unusable here — it hard-asserts `nix.enable`.
# We replicate its three moving parts by hand (all independent of nix.enable):
#
#   1. A launchd daemon that boots pkgs.darwin.linux-builder — a lightweight
#      aarch64-linux NixOS VM (Apple Virtualization / QEMU) on localhost:31022.
#      `create-builder` also provisions the client key /etc/nix/builder_ed25519
#      from nixpkgs' fixed throwaway keypair, so no manual key setup is needed.
#   2. /etc/nix/machines listing BOTH builders:
#        • the local VM        → aarch64-linux  (offline fallback, TCG nested VM)
#        • the NixOS desktop   → x86_64-linux   (KVM-accelerated, preferred)
#   3. `builders = @/etc/nix/machines` — wired into Determinate's nix.custom.conf
#      over in darwin/default.nix.
#
# Manual step for the REMOTE desktop only: the Nix daemon connects as root, so
# root's SSH key must be authorised on the desktop and your Mac user must be a
# trusted user there. See the desktop notes at the bottom.
{ config, lib, pkgs, vars, ... }:

let
  workingDirectory = "/var/lib/linux-builder";

  # nixpkgs' fixed public host key for the darwin linux-builder VM
  # (base64 of the ssh-ed25519 line; matches create-builder's baked host key).
  builderPublicHostKey =
    "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpCV2N4Yi9CbGFxdDFhdU90RStGOFFVV3JVb3RpQzVxQkorVXVFV2RWQ2Igcm9vdEBuaXhvcwo=";

  # Remote NixOS desktop — reuses the SSH host you already have (nixos.local).
  desktopHost = "nixos.local";
  desktopUser = vars.user;
in
{
  # Ensure the VM's working directory exists before launchd loads the daemon.
  system.activationScripts.preActivation.text = lib.mkAfter ''
    mkdir -p ${workingDirectory}
  '';

  # 1. Boot the aarch64-linux builder VM and keep it alive.
  launchd.daemons.linux-builder = {
    script = ''
      export TMPDIR=/run/org.nixos.linux-builder USE_TMPDIR=1
      rm -rf "$TMPDIR"
      mkdir -p "$TMPDIR"
      trap 'rm -rf "$TMPDIR"' EXIT
      ${pkgs.darwin.linux-builder}/bin/create-builder
    '';
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      WorkingDirectory = workingDirectory;
      StandardOutPath = "/var/log/linux-builder.log";
      StandardErrorPath = "/var/log/linux-builder.log";
    };
  };

  # 2. SSH config for the local VM (the Nix daemon runs as root and reads this).
  environment.etc."ssh/ssh_config.d/100-linux-builder.conf".text = ''
    Host linux-builder
      User builder
      Hostname localhost
      HostKeyAlias linux-builder
      Port 31022
      IdentityFile /etc/nix/builder_ed25519
      StrictHostKeyChecking accept-new
  '';

  # 3. Distributed build machines. Columns:
  #   URI  systems  sshKey  maxJobs  speedFactor  supportedFeatures  mandatory  base64-hostkey
  environment.etc."nix/machines".text = ''
    ssh-ng://builder@linux-builder aarch64-linux /etc/nix/builder_ed25519 4 1 kvm,benchmark,big-parallel - ${builderPublicHostKey}
    ssh-ng://${desktopUser}@${desktopHost} x86_64-linux - 8 2 kvm,benchmark,big-parallel - -
  '';

  # ── Remote desktop one-time setup (do these on the NixOS desktop) ──────────
  #   1. Mark your user trusted:   nix.settings.trusted-users = [ "@wheel" "${desktopUser}" ];
  #   2. Enable sshd (already on).
  #   3. Authorise the Mac ROOT key on the desktop (daemon connects as root):
  #        sudo ssh-keygen -t ed25519 -f /var/root/.ssh/id_ed25519 -N ""   # on the Mac, if absent
  #        then add /var/root/.ssh/id_ed25519.pub to the desktop user's authorized_keys
  #   4. Prime the host key so root trusts it:
  #        sudo ssh ${desktopUser}@${desktopHost} true
  # ───────────────────────────────────────────────────────────────────────────
}
