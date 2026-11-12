# Linux builds from the aarch64-darwin Mac go to the NixOS desktop.
#
# Determinate Nix owns the daemon (nix.enable = false), so nix-darwin's
# `nix.buildMachines` is not written. We manage the two moving parts by hand:
#
#   1. /etc/nix/machines listing the NixOS desktop (x86_64-linux).
#   2. `builders = @/etc/nix/machines` — wired into Determinate's nix.custom.conf
#      over in darwin/default.nix.
#
# The local pkgs.darwin.linux-builder VM was removed: it crashes under
# QEMU/HVF on this Mac and only held aarch64-linux jobs hostage.
#
# Manual step for the REMOTE desktop only: the Nix daemon connects as root, so
# root's SSH key must be authorised on the desktop and your Mac user must be a
# trusted user there. See the desktop notes at the bottom.
{ vars, ... }:

let
  # Stable private name, including while the Mac is away from the home LAN.
  desktopHost = vars.desktopHost;
  desktopUser = vars.user;
in
{
  programs.ssh.knownHosts.desktop = {
    hostNames = [ "nixos.local" desktopHost ];
    publicKeyFile = ../hosts/keys/desktop.pub;
  };

  # Distributed build machines. Columns:
  #   URI  systems  sshKey  maxJobs  speedFactor  supportedFeatures  mandatory  base64-hostkey
  environment.etc."nix/machines".text = ''
    ssh-ng://${desktopUser}@${desktopHost} x86_64-linux - 1 2 benchmark,big-parallel - -
  '';

  # ── Remote desktop one-time setup (do these on the NixOS desktop) ──────────
  #   1. Mark your user trusted:   nix.settings.trusted-users = [ "@wheel" "${desktopUser}" ];
  #   2. Enable sshd (already on).
  #   3. Authorise the Mac ROOT key on the desktop (daemon connects as root):
  #        sudo ssh-keygen -t ed25519 -f /var/root/.ssh/id_ed25519 -N ""   # on the Mac, if absent
  #        then add /var/root/.ssh/id_ed25519.pub to the desktop user's authorized_keys
  #   4. Test access; this configuration supplies the verified host key:
  #        sudo ssh ${desktopUser}@${desktopHost} true
  # ───────────────────────────────────────────────────────────────────────────
}
